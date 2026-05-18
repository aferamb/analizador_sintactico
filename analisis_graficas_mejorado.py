# analisis_graficas_mejorado.py
# ============================================================
# Análisis y gráficas mejoradas para los resultados del analizador Prolog
# ============================================================

#   Este script espera un archivo TSV generado desde Prolog con:
#   ?- exportar_tsv('resultados_comparacion.tsv').

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

# Uso:
#   python analisis_graficas_mejorado.py resultados_comparacion.tsv
#
# Si no se pasa ruta, intenta leer resultados_comparacion.tsv.

# Detalles:
#   1. Las frases no aceptadas no se cuentan como árboles de profundidad/nodos 0,
#      sino como NaN en métricas estructurales. Así no distorsionan medias ni gráficas.
#   2. Las métricas pequeñas y grandes se separan en gráficas distintas.
#   3. Las diferencias GPT-Claude se separan por métrica para evitar que nodos o outliers
#      oculten longitud/profundidad.
#   4. Se añaden etiquetas numéricas sobre barras.
#   5. Se exportan tablas limpias y tablas específicas para memoria.

# Requisitos:
#   pip install pandas matplotlib

from __future__ import annotations

import sys
from pathlib import Path
from typing import Iterable

import pandas as pd
import matplotlib.pyplot as plt


# ============================================================
# CONFIGURACIÓN
# ============================================================

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

# Métricas de conteo pequeño: conviene graficarlas separadas de nodos/profundidad.
METRICAS_PEQUENAS = ["long", "comas", "conectores", "relativos", "tecnicos", "simples"]

# Métricas estructurales calculadas sobre el árbol sintáctico.
# Si una oración no se analiza, estas métricas no son 0 reales: se sustituyen por NaN.
METRICAS_ESTRUCTURALES = ["simples", "profundidad", "nodos"]

ORDEN_TIPOS = ["o", "oc", "or", "ocm", "no_analizada"]


# ============================================================
# CARGA Y LIMPIEZA
# ============================================================

def cargar_resultados(ruta_tsv: str | Path) -> pd.DataFrame:
    """Carga el TSV exportado por Prolog."""
    ruta_tsv = Path(ruta_tsv)
    if not ruta_tsv.exists():
        raise FileNotFoundError(
            f"No existe el archivo: {ruta_tsv}\n"
            "Genera primero el TSV desde Prolog con exportar_tsv('resultados_comparacion.tsv')."
        )
    return pd.read_csv(ruta_tsv, sep="\t", encoding="utf-8")


def limpiar_resultados(df: pd.DataFrame) -> pd.DataFrame:
    """
    Limpia tipos, crea booleanos y calcula diferencias.

    Punto importante:
    - En Prolog, una oración no analizada suele tener profundidad=0 y nodos=0.
      Para análisis estadístico eso es engañoso, porque no representa un árbol pequeño,
      sino ausencia de árbol. Por eso esas métricas se convierten a NaN.
    """
    df = df.copy()

    if "n" in df.columns:
        df["n"] = pd.to_numeric(df["n"], errors="coerce").astype("Int64")

    # Normalizar columnas textuales de estado.
    for col in ["acepta_gpt", "acepta_claude", "mismo_tipo", "tipo_gpt", "tipo_claude"]:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip().str.lower()

    # Convertir columnas numéricas.
    for metrica in METRICAS_BASE:
        for corpus in ["gpt", "claude"]:
            col = f"{metrica}_{corpus}"
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors="coerce")

    # Booleanos de aceptación.
    df["gpt_aceptada"] = df["acepta_gpt"].eq("si")
    df["claude_aceptada"] = df["acepta_claude"].eq("si")
    df["ambas_aceptadas"] = df["gpt_aceptada"] & df["claude_aceptada"]
    df["solo_gpt_aceptada"] = df["gpt_aceptada"] & ~df["claude_aceptada"]
    df["solo_claude_aceptada"] = ~df["gpt_aceptada"] & df["claude_aceptada"]
    df["ninguna_aceptada"] = ~df["gpt_aceptada"] & ~df["claude_aceptada"]
    df["mismo_tipo_bool"] = df["mismo_tipo"].eq("si")

    # Sustituir métricas estructurales por NaN si no hay análisis.
    for corpus in ["gpt", "claude"]:
        mask_no_aceptada = ~df[f"{corpus}_aceptada"]
        for metrica in METRICAS_ESTRUCTURALES:
            col = f"{metrica}_{corpus}"
            if col in df.columns:
                df.loc[mask_no_aceptada, col] = pd.NA

    # Calcular diferencias GPT-Claude ya con NaN aplicado.
    for metrica in METRICAS_BASE:
        col_gpt = f"{metrica}_gpt"
        col_claude = f"{metrica}_claude"
        if col_gpt in df.columns and col_claude in df.columns:
            df[f"dif_{metrica}_gpt_menos_claude"] = df[col_gpt] - df[col_claude]

    return df


# ============================================================
# RESÚMENES Y TABLAS
# ============================================================

def resumen_global(df: pd.DataFrame) -> pd.DataFrame:
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
    for key in ["gpt_aceptadas", "claude_aceptadas", "ambas_aceptadas", "mismo_tipo"]:
        datos[f"porc_{key}"] = round(datos[key] * 100 / total, 2) if total else 0
    return pd.DataFrame([datos])


def medias_por_corpus(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for corpus in ["gpt", "claude"]:
        fila = {"corpus": corpus.upper()}
        for metrica in METRICAS_BASE:
            col = f"{metrica}_{corpus}"
            if col in df.columns:
                fila[metrica] = round(df[col].mean(skipna=True), 2)
        filas.append(fila)
    return pd.DataFrame(filas)


def distribucion_tipos(df: pd.DataFrame) -> pd.DataFrame:
    partes = []
    for corpus in ["gpt", "claude"]:
        conteo = (
            df[f"tipo_{corpus}"]
            .value_counts()
            .reindex(ORDEN_TIPOS, fill_value=0)
            .rename_axis("tipo")
            .reset_index(name="cantidad")
        )
        conteo["corpus"] = corpus.upper()
        partes.append(conteo)
    return pd.concat(partes, ignore_index=True)


def pares_problematicos(df: pd.DataFrame) -> pd.DataFrame:
    """Casos útiles para revisar en la memoria."""
    df = df.copy()
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
        "n", "acepta_gpt", "acepta_claude", "tipo_gpt", "tipo_claude", "mismo_tipo",
        "long_gpt", "long_claude", "dif_long_gpt_menos_claude",
        "profundidad_gpt", "profundidad_claude", "dif_profundidad_gpt_menos_claude",
        "nodos_gpt", "nodos_claude", "dif_nodos_gpt_menos_claude",
        "texto_gpt", "texto_claude",
    ]
    columnas = [c for c in columnas if c in df.columns]

    # Primero ordenamos usando el DataFrame completo, donde todavía existen
    # las columnas auxiliares como ambas_aceptadas, mismo_tipo_bool,
    # abs_dif_nodos y abs_dif_profundidad.
    resultado = df.loc[filtro].sort_values(
        by=[
            "ambas_aceptadas",
            "mismo_tipo_bool",
            "abs_dif_nodos",
            "abs_dif_profundidad",
        ],
        ascending=[True, True, False, False],
    )

    # Después seleccionamos solo las columnas que queremos exportar/mostrar.
    return resultado[columnas]


# ============================================================
# UTILIDADES DE GRÁFICAS
# ============================================================

def guardar_figura(ruta_salida: Path) -> None:
    ruta_salida.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(ruta_salida, dpi=220, bbox_inches="tight")
    plt.close()


def etiquetar_barras(ax, formato: str = "{:.0f}") -> None:
    """Añade el valor encima de cada barra."""
    for contenedor in ax.containers:
        etiquetas = []
        for barra in contenedor:
            alto = barra.get_height()
            if pd.isna(alto):
                etiquetas.append("")
            else:
                etiquetas.append(formato.format(alto))
        ax.bar_label(contenedor, labels=etiquetas, padding=3, fontsize=9)


def aplicar_estetica(ax) -> None:
    ax.grid(axis="y", alpha=0.25)
    ax.set_axisbelow(True)


# ============================================================
# GRÁFICAS MEJORADAS
# ============================================================

def grafica_aceptacion_porcentual(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Aceptación por corpus en porcentaje.
    Mejor que barras absolutas, porque cuando casi todo se acepta la barra de rechazadas no desaparece visualmente.
    """
    total = len(df)
    tabla = pd.DataFrame({
        "Aceptadas": [df["gpt_aceptada"].sum(), df["claude_aceptada"].sum()],
        "No aceptadas": [(~df["gpt_aceptada"]).sum(), (~df["claude_aceptada"]).sum()],
    }, index=["GPT", "Claude"])

    porcentajes = tabla.div(total).mul(100)

    ax = porcentajes.plot(kind="barh", stacked=True, figsize=(8, 3.6))
    ax.set_title("Aceptación sintáctica por corpus (%)")
    ax.set_xlabel("Porcentaje de frases")
    ax.set_ylabel("Corpus")
    ax.set_xlim(0, 100)
    ax.legend(title="Resultado", loc="lower right")
    aplicar_estetica(ax)

    # Etiquetas internas con cuenta y porcentaje.
    for i, corpus in enumerate(tabla.index):
        acumulado = 0
        for resultado in tabla.columns:
            valor = tabla.loc[corpus, resultado]
            pct = porcentajes.loc[corpus, resultado]
            if valor > 0:
                ax.text(acumulado + pct / 2, i, f"{int(valor)} ({pct:.1f}%)", ha="center", va="center", fontsize=9)
            acumulado += pct

    guardar_figura(carpeta / "01_aceptacion_porcentual.png")


def grafica_rechazos(df: pd.DataFrame, carpeta: Path) -> None:
    """Gráfica específica de rechazos, útil cuando solo hay uno o dos."""
    tabla = pd.Series({
        "GPT": int((~df["gpt_aceptada"]).sum()),
        "Claude": int((~df["claude_aceptada"]).sum()),
    })

    ax = tabla.plot(kind="bar", figsize=(5, 3.5))
    ax.set_title("Oraciones no aceptadas por corpus")
    ax.set_xlabel("Corpus")
    ax.set_ylabel("Número de frases")
    ax.set_ylim(0, max(2, int(tabla.max()) + 1))
    etiquetar_barras(ax)
    aplicar_estetica(ax)

    guardar_figura(carpeta / "02_rechazos_por_corpus.png")


def grafica_tipos(df: pd.DataFrame, carpeta: Path) -> None:
    """Distribución de tipos sintácticos con etiquetas."""
    tipos_gpt = df["tipo_gpt"].value_counts().reindex(ORDEN_TIPOS, fill_value=0)
    tipos_claude = df["tipo_claude"].value_counts().reindex(ORDEN_TIPOS, fill_value=0)
    tabla = pd.DataFrame({"GPT": tipos_gpt, "Claude": tipos_claude})

    ax = tabla.plot(kind="bar", figsize=(8, 4.5))
    ax.set_title("Distribución de tipos sintácticos")
    ax.set_xlabel("Tipo de oración")
    ax.set_ylabel("Número de frases")
    ax.tick_params(axis="x", rotation=0)
    ax.legend(title="Corpus")
    etiquetar_barras(ax)
    aplicar_estetica(ax)

    guardar_figura(carpeta / "03_distribucion_tipos.png")


def grafica_medias_pequenas(df: pd.DataFrame, carpeta: Path) -> None:
    """
    Medias de métricas de escala pequeña.
    Se separan de nodos/profundidad para que comas, relativos o técnicos no queden aplastados.
    """
    medias = medias_por_corpus(df).set_index("corpus")
    ax = medias[METRICAS_PEQUENAS].T.plot(kind="bar", figsize=(9, 4.5))
    ax.set_title("Medias de métricas superficiales y léxicas")
    ax.set_xlabel("Métrica")
    ax.set_ylabel("Media")
    ax.tick_params(axis="x", rotation=35)
    ax.legend(title="Corpus")
    etiquetar_barras(ax, "{:.1f}")
    aplicar_estetica(ax)

    guardar_figura(carpeta / "04_medias_metricas_pequenas.png")


def grafica_medias_estructurales(df: pd.DataFrame, carpeta: Path) -> None:
    """Medias de profundidad y nodos por separado de las métricas pequeñas."""
    medias = medias_por_corpus(df).set_index("corpus")
    metricas = ["profundidad", "nodos"]
    ax = medias[metricas].T.plot(kind="bar", figsize=(7, 4.5))
    ax.set_title("Medias de complejidad estructural")
    ax.set_xlabel("Métrica")
    ax.set_ylabel("Media")
    ax.tick_params(axis="x", rotation=0)
    ax.legend(title="Corpus")
    etiquetar_barras(ax, "{:.1f}")
    aplicar_estetica(ax)

    guardar_figura(carpeta / "05_medias_metricas_estructurales.png")


def grafica_profundidad_por_par(df: pd.DataFrame, carpeta: Path) -> None:
    """Profundidad del árbol por par. Las no aceptadas quedan como huecos por ser NaN."""
    ax = df.plot(x="n", y=["profundidad_gpt", "profundidad_claude"], kind="line", marker="o", figsize=(11, 4.5))
    ax.set_title("Profundidad del árbol por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Profundidad")
    aplicar_estetica(ax)
    guardar_figura(carpeta / "06_profundidad_por_par.png")


def grafica_nodos_por_par(df: pd.DataFrame, carpeta: Path) -> None:
    """Número de nodos por par. Las no aceptadas quedan como huecos por ser NaN."""
    ax = df.plot(x="n", y=["nodos_gpt", "nodos_claude"], kind="line", marker="o", figsize=(11, 4.5))
    ax.set_title("Número de nodos del árbol por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Nodos")
    aplicar_estetica(ax)
    guardar_figura(carpeta / "07_nodos_por_par.png")


def grafica_diferencia_individual(df: pd.DataFrame, carpeta: Path, metrica: str, titulo: str, ylabel: str) -> None:
    """Diferencia GPT-Claude para una única métrica."""
    col = f"dif_{metrica}_gpt_menos_claude"
    if col not in df.columns:
        return

    ax = df.plot(x="n", y=col, kind="bar", figsize=(11, 4.2), legend=False)
    ax.axhline(0, linewidth=1)
    ax.set_title(titulo)
    ax.set_xlabel("Par")
    ax.set_ylabel(ylabel)
    aplicar_estetica(ax)
    guardar_figura(carpeta / f"08_diferencia_{metrica}.png")


def grafica_scatter(df: pd.DataFrame, carpeta: Path, y: str, titulo: str, ylabel: str, nombre: str) -> None:
    """Dispersión longitud vs métrica estructural, excluyendo NaN."""
    plt.figure(figsize=(7, 5))

    for corpus in ["gpt", "claude"]:
        xcol = f"long_{corpus}"
        ycol = f"{y}_{corpus}"
        datos = df[[xcol, ycol]].dropna()
        plt.scatter(datos[xcol], datos[ycol], label=corpus.upper(), alpha=0.85)

    plt.title(titulo)
    plt.xlabel("Longitud en tokens")
    plt.ylabel(ylabel)
    plt.legend()
    plt.grid(axis="both", alpha=0.25)
    guardar_figura(carpeta / nombre)


def grafica_top_diferencias(df: pd.DataFrame, carpeta: Path, metrica: str, top_n: int = 10) -> None:
    """Top pares con mayor diferencia absoluta en una métrica."""
    col = f"dif_{metrica}_gpt_menos_claude"
    if col not in df.columns:
        return

    tmp = df[["n", col]].dropna().copy()
    tmp["abs_dif"] = tmp[col].abs()
    tmp = tmp.sort_values("abs_dif", ascending=False).head(top_n)
    if tmp.empty:
        return

    ax = tmp.set_index("n")[col].plot(kind="bar", figsize=(9, 4.2))
    ax.axhline(0, linewidth=1)
    ax.set_title(f"Pares con mayor diferencia de {metrica} (GPT - Claude)")
    ax.set_xlabel("Par")
    ax.set_ylabel(f"Diferencia de {metrica}")
    ax.tick_params(axis="x", rotation=0)
    etiquetar_barras(ax, "{:.0f}")
    aplicar_estetica(ax)

    guardar_figura(carpeta / f"11_top_diferencias_{metrica}.png")


def generar_graficas(df: pd.DataFrame, carpeta_salida: str | Path) -> None:
    carpeta = Path(carpeta_salida)
    carpeta.mkdir(parents=True, exist_ok=True)

    grafica_aceptacion_porcentual(df, carpeta)
    grafica_rechazos(df, carpeta)
    grafica_tipos(df, carpeta)
    grafica_medias_pequenas(df, carpeta)
    grafica_medias_estructurales(df, carpeta)
    grafica_profundidad_por_par(df, carpeta)
    grafica_nodos_por_par(df, carpeta)

    # Diferencias separadas: así nodos no aplasta a longitud/profundidad.
    grafica_diferencia_individual(
        df, carpeta, "long",
        "Diferencia de longitud por par (GPT - Claude)",
        "Diferencia de tokens",
    )
    grafica_diferencia_individual(
        df, carpeta, "profundidad",
        "Diferencia de profundidad por par (GPT - Claude)",
        "Diferencia de profundidad",
    )
    grafica_diferencia_individual(
        df, carpeta, "nodos",
        "Diferencia de nodos por par (GPT - Claude)",
        "Diferencia de nodos",
    )

    grafica_scatter(
        df, carpeta, "nodos",
        "Relación entre longitud y número de nodos",
        "Nodos del árbol",
        "09_scatter_longitud_nodos.png",
    )
    grafica_scatter(
        df, carpeta, "profundidad",
        "Relación entre longitud y profundidad",
        "Profundidad del árbol",
        "10_scatter_longitud_profundidad.png",
    )

    grafica_top_diferencias(df, carpeta, "nodos", top_n=10)
    grafica_top_diferencias(df, carpeta, "profundidad", top_n=10)


# ============================================================
# EXPORTACIÓN
# ============================================================

def exportar_tablas(df: pd.DataFrame, carpeta_salida: str | Path) -> None:
    carpeta = Path(carpeta_salida)
    carpeta.mkdir(parents=True, exist_ok=True)

    resumen_global(df).to_csv(carpeta / "resumen_global.csv", index=False, encoding="utf-8-sig")
    medias_por_corpus(df).to_csv(carpeta / "medias_por_corpus.csv", index=False, encoding="utf-8-sig")
    distribucion_tipos(df).to_csv(carpeta / "distribucion_tipos.csv", index=False, encoding="utf-8-sig")
    pares_problematicos(df).to_csv(carpeta / "pares_problematicos.csv", index=False, encoding="utf-8-sig")
    df.to_csv(carpeta / "resultados_limpios_con_diferencias.csv", index=False, encoding="utf-8-sig")


def imprimir_resumen_consola(df: pd.DataFrame) -> None:
    print("\n================ RESUMEN GLOBAL ================")
    print(resumen_global(df).to_string(index=False))

    print("\n================ MEDIAS POR CORPUS ================")
    print(medias_por_corpus(df).to_string(index=False))

    print("\n================ DISTRIBUCIÓN DE TIPOS ================")
    print(distribucion_tipos(df).to_string(index=False))

    print("\n================ PARES PROBLEMÁTICOS ================")
    prob = pares_problematicos(df)
    if prob.empty:
        print("No se han detectado pares problemáticos según los criterios definidos.")
    else:
        cols = [
            "n", "acepta_gpt", "acepta_claude", "tipo_gpt", "tipo_claude", "mismo_tipo",
            "dif_long_gpt_menos_claude", "dif_profundidad_gpt_menos_claude", "dif_nodos_gpt_menos_claude",
        ]
        cols = [c for c in cols if c in prob.columns]
        print(prob[cols].to_string(index=False))


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    ruta_tsv = Path(sys.argv[1]) if len(sys.argv) >= 2 else Path("resultados_comparacion.tsv")

    carpeta_salida = Path("analisis_python_mejorado")
    carpeta_tablas = carpeta_salida / "tablas"
    carpeta_graficas = carpeta_salida / "graficas"

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
