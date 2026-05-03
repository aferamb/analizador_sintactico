# analisis_graficas.py
# ============================================================
# Análisis y gráficas para los resultados del analizador Prolog
# ============================================================
#
# Este script espera un archivo TSV generado desde Prolog con:
#
#   ?- exportar_tsv('resultados_comparacion.tsv').
#
# El TSV debe tener columnas como:
#   n, texto_gpt, texto_claude,
#   acepta_gpt, acepta_claude,
#   tipo_gpt, tipo_claude, mismo_tipo,
#   long_gpt, long_claude, dif_long_gpt_menos_claude,
#   comas_gpt, comas_claude,
#   conectores_gpt, conectores_claude,
#   relativos_gpt, relativos_claude,
#   tecnicos_gpt, tecnicos_claude,
#   simples_gpt, simples_claude,
#   profundidad_gpt, profundidad_claude,
#   nodos_gpt, nodos_claude
#
# El objetivo es:
#   1. Cargar los resultados.
#   2. Limpiar tipos de datos.
#   3. Calcular resúmenes globales.
#   4. Detectar pares problemáticos.
#   5. Generar gráficas automáticamente.
#   6. Exportar tablas CSV con resultados útiles para la memoria.
#
# Requisitos:
#   pip install pandas matplotlib
#
# Uso:
#   python analisis_graficas.py resultados_comparacion.tsv
#
# Si no pasas ruta, intenta leer:
#   resultados_comparacion.tsv

import sys
from pathlib import Path

import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# CONFIGURACIÓN GENERAL
# ============================================================

# Métricas numéricas que se comparan entre GPT y Claude.
METRICAS_BASE = [
    "long",
    "comas",
    "conectores",
    "relativos",
    "tecnicos",
    "simples",
    "profundidad",
    "nodos",
]

# Orden lógico de los tipos sintácticos.
ORDEN_TIPOS = ["o", "oc", "or", "ocm", "no_analizada"]


# ============================================================
# FUNCIONES DE CARGA Y LIMPIEZA
# ============================================================

def cargar_resultados(ruta_tsv: str | Path) -> pd.DataFrame:
    """
    Carga el archivo TSV generado por Prolog.

    Parámetros
    ----------
    ruta_tsv:
        Ruta al archivo resultados_comparacion.tsv.

    Devuelve
    --------
    DataFrame de pandas con los resultados cargados.
    """
    ruta_tsv = Path(ruta_tsv)

    if not ruta_tsv.exists():
        raise FileNotFoundError(
            f"No existe el archivo: {ruta_tsv}\n"
            "Primero genera el TSV desde Prolog con:\n"
            "?- exportar_tsv('resultados_comparacion.tsv')."
        )

    df = pd.read_csv(ruta_tsv, sep="\t", encoding="utf-8")

    # Aseguramos que el identificador del par sea entero.
    if "n" in df.columns:
        df["n"] = pd.to_numeric(df["n"], errors="coerce").astype("Int64")

    return df


def limpiar_resultados(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpia tipos de datos y añade columnas derivadas.

    Esta función no modifica el DataFrame original; devuelve una copia.
    """
    df = df.copy()

    # Columnas numéricas esperadas.
    columnas_numericas = ["n"]

    for metrica in METRICAS_BASE:
        columnas_numericas.append(f"{metrica}_gpt")
        columnas_numericas.append(f"{metrica}_claude")

    columnas_numericas.append("dif_long_gpt_menos_claude")

    # Convertimos a numérico todo lo que exista.
    # errors='coerce' convierte valores raros en NaN.
    for col in columnas_numericas:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")

    # Normalizamos columnas si/no.
    for col in ["acepta_gpt", "acepta_claude", "mismo_tipo"]:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip().str.lower()

    # Booleanos cómodos para análisis.
    df["gpt_aceptada"] = df["acepta_gpt"].eq("si")
    df["claude_aceptada"] = df["acepta_claude"].eq("si")
    df["ambas_aceptadas"] = df["gpt_aceptada"] & df["claude_aceptada"]
    df["solo_gpt_aceptada"] = df["gpt_aceptada"] & ~df["claude_aceptada"]
    df["solo_claude_aceptada"] = ~df["gpt_aceptada"] & df["claude_aceptada"]
    df["ninguna_aceptada"] = ~df["gpt_aceptada"] & ~df["claude_aceptada"]
    df["mismo_tipo_bool"] = df["mismo_tipo"].eq("si")

    # Diferencias GPT - Claude para todas las métricas numéricas.
    for metrica in METRICAS_BASE:
        col_gpt = f"{metrica}_gpt"
        col_claude = f"{metrica}_claude"
        if col_gpt in df.columns and col_claude in df.columns:
            df[f"dif_{metrica}_gpt_menos_claude"] = df[col_gpt] - df[col_claude]

    return df


# ============================================================
# RESÚMENES NUMÉRICOS
# ============================================================

def resumen_global(df: pd.DataFrame) -> pd.DataFrame:
    """
    Crea un resumen global de aceptación y coincidencia de tipo.
    """
    total = len(df)

    datos = {
        "total_pares": total,
        "gpt_aceptadas": int(df["gpt_aceptada"].sum()),
        "claude_aceptadas": int(df["claude_aceptada"].sum()),
        "ambas_aceptadas": int(df["ambas_aceptadas"].sum()),
        "solo_gpt_aceptada": int(df["solo_gpt_aceptada"].sum()),
        "solo_claude_aceptada": int(df["solo_claude_aceptada"].sum()),
        "ninguna_aceptada": int(df["ninguna_aceptada"].sum()),
        "mismo_tipo": int(df["mismo_tipo_bool"].sum()),
    }

    # Añadimos porcentajes.
    if total > 0:
        datos["porc_gpt_aceptadas"] = round(datos["gpt_aceptadas"] * 100 / total, 2)
        datos["porc_claude_aceptadas"] = round(datos["claude_aceptadas"] * 100 / total, 2)
        datos["porc_ambas_aceptadas"] = round(datos["ambas_aceptadas"] * 100 / total, 2)
        datos["porc_mismo_tipo"] = round(datos["mismo_tipo"] * 100 / total, 2)

    return pd.DataFrame([datos])


def medias_por_corpus(df: pd.DataFrame) -> pd.DataFrame:
    """
    Calcula medias de las métricas principales para GPT y Claude.
    """
    filas = []

    for corpus in ["gpt", "claude"]:
        fila = {"corpus": corpus.upper()}

        for metrica in METRICAS_BASE:
            col = f"{metrica}_{corpus}"
            if col in df.columns:
                fila[metrica] = round(df[col].mean(), 2)

        filas.append(fila)

    return pd.DataFrame(filas)


def distribucion_tipos(df: pd.DataFrame) -> pd.DataFrame:
    """
    Calcula cuántas oraciones hay de cada tipo para GPT y Claude.
    """
    partes = []

    for corpus in ["gpt", "claude"]:
        col = f"tipo_{corpus}"

        conteo = (
            df[col]
            .value_counts()
            .reindex(ORDEN_TIPOS, fill_value=0)
            .rename_axis("tipo")
            .reset_index(name="cantidad")
        )

        conteo["corpus"] = corpus.upper()
        partes.append(conteo)

    return pd.concat(partes, ignore_index=True)


def pares_problematicos(df: pd.DataFrame) -> pd.DataFrame:
    """
    Extrae pares que conviene revisar manualmente.

    Criterios:
    - Alguna versión no aceptada.
    - Tipos sintácticos distintos.
    - Profundidad o nodos muy diferentes.
    """
    df = df.copy()

    # Diferencias absolutas útiles para ordenar.
    df["abs_dif_profundidad"] = df["dif_profundidad_gpt_menos_claude"].abs()
    df["abs_dif_nodos"] = df["dif_nodos_gpt_menos_claude"].abs()
    df["abs_dif_long"] = df["dif_long_gpt_menos_claude"].abs()

    filtro = (
        ~df["ambas_aceptadas"]
        | ~df["mismo_tipo_bool"]
        | (df["abs_dif_profundidad"] >= 5)
        | (df["abs_dif_nodos"] >= 20)
    )

    columnas = [
        "n",
        "acepta_gpt",
        "acepta_claude",
        "tipo_gpt",
        "tipo_claude",
        "mismo_tipo",
        "long_gpt",
        "long_claude",
        "dif_long_gpt_menos_claude",
        "profundidad_gpt",
        "profundidad_claude",
        "dif_profundidad_gpt_menos_claude",
        "nodos_gpt",
        "nodos_claude",
        "dif_nodos_gpt_menos_claude",
        "texto_gpt",
        "texto_claude",
    ]

    columnas = [c for c in columnas if c in df.columns]

    return (
        df.loc[filtro, columnas]
        .sort_values(
            by=[
                "acepta_gpt",
                "acepta_claude",
                "mismo_tipo",
                "dif_nodos_gpt_menos_claude",
            ],
            ascending=[True, True, True, False],
        )
    )


# ============================================================
# FUNCIONES AUXILIARES PARA GRÁFICAS
# ============================================================

def guardar_figura(ruta_salida: Path) -> None:
    """
    Guarda la figura actual con márgenes ajustados y la cierra.
    """
    plt.tight_layout()
    plt.savefig(ruta_salida, dpi=200)
    plt.close()


def grafica_aceptacion(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Gráfica de barras con número de aceptadas/no aceptadas por corpus.
    """
    conteos = pd.DataFrame({
        "GPT": [
            int(df["gpt_aceptada"].sum()),
            int((~df["gpt_aceptada"]).sum()),
        ],
        "Claude": [
            int(df["claude_aceptada"].sum()),
            int((~df["claude_aceptada"]).sum()),
        ],
    }, index=["Aceptadas", "No aceptadas"])

    ax = conteos.plot(kind="bar", figsize=(7, 4))
    ax.set_title("Aceptación sintáctica por corpus")
    ax.set_xlabel("Resultado")
    ax.set_ylabel("Número de frases")
    ax.legend(title="Corpus")

    guardar_figura(carpeta / "01_aceptacion_por_corpus.png")


def grafica_tipos(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Distribución de tipos sintácticos: o, oc, or, ocm, no_analizada.
    """
    tipos_gpt = df["tipo_gpt"].value_counts().reindex(ORDEN_TIPOS, fill_value=0)
    tipos_claude = df["tipo_claude"].value_counts().reindex(ORDEN_TIPOS, fill_value=0)

    tabla = pd.DataFrame({
        "GPT": tipos_gpt,
        "Claude": tipos_claude,
    })

    ax = tabla.plot(kind="bar", figsize=(8, 4))
    ax.set_title("Distribución de tipos sintácticos")
    ax.set_xlabel("Tipo de oración")
    ax.set_ylabel("Número de frases")
    ax.legend(title="Corpus")

    guardar_figura(carpeta / "02_distribucion_tipos.png")


def grafica_medias_metricas(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Gráfica de medias para métricas numéricas principales.

    Se excluye longitud si quieres centrarte en complejidad sintáctica;
    aquí la mantenemos porque ayuda a comparar con profundidad/nodos.
    """
    medias = medias_por_corpus(df).set_index("corpus")

    ax = medias[METRICAS_BASE].T.plot(kind="bar", figsize=(10, 5))
    ax.set_title("Media de métricas por corpus")
    ax.set_xlabel("Métrica")
    ax.set_ylabel("Media")
    ax.legend(title="Corpus")

    guardar_figura(carpeta / "03_medias_metricas.png")


def grafica_profundidad_por_par(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Línea por par: profundidad del árbol GPT frente a Claude.
    """
    ax = df.plot(
        x="n",
        y=["profundidad_gpt", "profundidad_claude"],
        kind="line",
        marker="o",
        figsize=(11, 4),
    )
    ax.set_title("Profundidad del árbol por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Profundidad")

    guardar_figura(carpeta / "04_profundidad_por_par.png")


def grafica_nodos_por_par(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Línea por par: número de nodos GPT frente a Claude.
    """
    ax = df.plot(
        x="n",
        y=["nodos_gpt", "nodos_claude"],
        kind="line",
        marker="o",
        figsize=(11, 4),
    )
    ax.set_title("Número de nodos del árbol por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Nodos")

    guardar_figura(carpeta / "05_nodos_por_par.png")


def grafica_diferencias(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Gráfica de diferencias GPT - Claude por par.

    Valores positivos:
        GPT tiene más valor que Claude.

    Valores negativos:
        Claude tiene más valor que GPT.
    """
    columnas = [
        "dif_long_gpt_menos_claude",
        "dif_profundidad_gpt_menos_claude",
        "dif_nodos_gpt_menos_claude",
    ]

    columnas = [c for c in columnas if c in df.columns]

    ax = df.plot(
        x="n",
        y=columnas,
        kind="line",
        marker="o",
        figsize=(11, 5),
    )
    ax.axhline(0, linewidth=1)
    ax.set_title("Diferencias GPT - Claude por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Diferencia")

    guardar_figura(carpeta / "06_diferencias_gpt_menos_claude.png")


def grafica_scatter_longitud_nodos(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Dispersión longitud vs nodos.

    Sirve para ver si las frases más largas generan árboles más grandes.
    """
    plt.figure(figsize=(7, 5))

    plt.scatter(df["long_gpt"], df["nodos_gpt"], label="GPT")
    plt.scatter(df["long_claude"], df["nodos_claude"], label="Claude")

    plt.title("Relación entre longitud y número de nodos")
    plt.xlabel("Longitud en tokens")
    plt.ylabel("Nodos del árbol")
    plt.legend()

    guardar_figura(carpeta / "07_scatter_longitud_nodos.png")


def grafica_scatter_longitud_profundidad(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Dispersión longitud vs profundidad.

    Ayuda a detectar frases cortas con árboles muy profundos,
    que suelen indicar análisis demasiado encadenados.
    """
    plt.figure(figsize=(7, 5))

    plt.scatter(df["long_gpt"], df["profundidad_gpt"], label="GPT")
    plt.scatter(df["long_claude"], df["profundidad_claude"], label="Claude")

    plt.title("Relación entre longitud y profundidad")
    plt.xlabel("Longitud en tokens")
    plt.ylabel("Profundidad del árbol")
    plt.legend()

    guardar_figura(carpeta / "08_scatter_longitud_profundidad.png")


def grafica_pares_problematicos(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Barras de pares con mayor diferencia de nodos.

    Útil para encontrar frases donde un análisis se ha vuelto mucho
    más complejo que el otro.
    """
    df_tmp = df.copy()
    df_tmp["abs_dif_nodos"] = df_tmp["dif_nodos_gpt_menos_claude"].abs()

    top = df_tmp.sort_values("abs_dif_nodos", ascending=False).head(12)

    if top.empty:
        return

    plt.figure(figsize=(10, 5))
    plt.bar(top["n"].astype(str), top["dif_nodos_gpt_menos_claude"])
    plt.axhline(0, linewidth=1)
    plt.title("Pares con mayor diferencia de nodos GPT - Claude")
    plt.xlabel("Par")
    plt.ylabel("Diferencia de nodos")

    guardar_figura(carpeta / "09_top_diferencias_nodos.png")


def generar_graficas(df: pd.DataFrame, carpeta_salida: str | Path) -> None:
    """
    Genera todas las gráficas en una carpeta.
    """
    carpeta = Path(carpeta_salida)
    carpeta.mkdir(parents=True, exist_ok=True)

    grafica_aceptacion(df, carpeta)
    grafica_tipos(df, carpeta)
    grafica_medias_metricas(df, carpeta)
    grafica_profundidad_por_par(df, carpeta)
    grafica_nodos_por_par(df, carpeta)
    grafica_diferencias(df, carpeta)
    grafica_scatter_longitud_nodos(df, carpeta)
    grafica_scatter_longitud_profundidad(df, carpeta)
    grafica_pares_problematicos(df, carpeta)


# ============================================================
# EXPORTACIÓN DE TABLAS
# ============================================================

def exportar_tablas(df: pd.DataFrame, carpeta_salida: str | Path) -> None:
    """
    Exporta tablas CSV útiles para revisar resultados y pegarlas en memoria.
    """
    carpeta = Path(carpeta_salida)
    carpeta.mkdir(parents=True, exist_ok=True)

    resumen_global(df).to_csv(carpeta / "resumen_global.csv", index=False, encoding="utf-8-sig")
    medias_por_corpus(df).to_csv(carpeta / "medias_por_corpus.csv", index=False, encoding="utf-8-sig")
    distribucion_tipos(df).to_csv(carpeta / "distribucion_tipos.csv", index=False, encoding="utf-8-sig")
    pares_problematicos(df).to_csv(carpeta / "pares_problematicos.csv", index=False, encoding="utf-8-sig")

    # Tabla completa ya limpiada y con diferencias añadidas.
    df.to_csv(carpeta / "resultados_limpios_con_diferencias.csv", index=False, encoding="utf-8-sig")


# ============================================================
# INFORME POR CONSOLA
# ============================================================

def imprimir_resumen_consola(df: pd.DataFrame) -> None:
    """
    Imprime un resumen rápido para comprobar que todo está bien.
    """
    print("\n================ RESUMEN GLOBAL ================")
    print(resumen_global(df).to_string(index=False))

    print("\n================ MEDIAS POR CORPUS ================")
    print(medias_por_corpus(df).to_string(index=False))

    print("\n================ DISTRIBUCIÓN DE TIPOS ================")
    print(distribucion_tipos(df).to_string(index=False))

    problematicos = pares_problematicos(df)
    print("\n================ PARES PROBLEMÁTICOS ================")

    if problematicos.empty:
        print("No se han detectado pares problemáticos según los criterios definidos.")
    else:
        columnas_cortas = [
            "n",
            "acepta_gpt",
            "acepta_claude",
            "tipo_gpt",
            "tipo_claude",
            "mismo_tipo",
            "dif_long_gpt_menos_claude",
            "dif_profundidad_gpt_menos_claude",
            "dif_nodos_gpt_menos_claude",
        ]
        columnas_cortas = [c for c in columnas_cortas if c in problematicos.columns]
        print(problematicos[columnas_cortas].to_string(index=False))


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    """
    Punto de entrada del script.
    """
    if len(sys.argv) >= 2:
        ruta_tsv = Path(sys.argv[1])
    else:
        ruta_tsv = Path("resultados_comparacion.tsv")

    carpeta_salida = Path("analisis_python")
    carpeta_graficas = carpeta_salida / "graficas"
    carpeta_tablas = carpeta_salida / "tablas"

    print(f"Leyendo resultados desde: {ruta_tsv}")

    df = cargar_resultados(ruta_tsv)
    df = limpiar_resultados(df)

    imprimir_resumen_consola(df)
    exportar_tablas(df, carpeta_tablas)
    generar_graficas(df, carpeta_graficas)

    print("\nArchivos generados:")
    print(f"- Tablas:   {carpeta_tablas.resolve()}")
    print(f"- Gráficas: {carpeta_graficas.resolve()}")


if __name__ == "__main__":
    main()