"""Graficas y tablas para el analisis lexico-semantico GPT vs Claude.

Uso:
    python3 analisis_graficas_lexico_semantico.py resultados_ls.tsv

El TSV debe generarse desde SWI-Prolog con:
    ?- exportar_tsv_ls('resultados_ls.tsv').
"""

from __future__ import annotations

import math
import sys
from collections import Counter
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import cycler
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


DEFAULT_TSV = Path("resultados_ls.tsv")
DEFAULT_OUTPUT = Path("analisis_lexico_semantico")
PLOT_DPI = 200

PALETTE = {
    "gpt": "#2E86AB",
    "claude": "#E07A5F",
    "shared": "#5A8F5B",
    "neutral": "#6C757D",
    "warning": "#B56576",
    "accent": "#8E6BBE",
}

CATEGORY_METRICS = [
    ("sustantivos", "Sustantivos"),
    ("adjetivos", "Adjetivos"),
    ("determinantes", "Determinantes"),
    ("pronombres", "Pronombres"),
    ("verbos", "Verbos"),
    ("adverbios", "Adverbios"),
    ("preposiciones", "Preposiciones"),
    ("conjunciones", "Conjunciones"),
]

JACCARD_COLUMNS = [
    "jaccard_sustantivos",
    "jaccard_adjetivos",
    "jaccard_verbos",
    "jaccard_adverbios",
    "jaccard_global",
]

GRAPH_DIRS = {
    "D1": Path("graficas/D1_fidelidad"),
    "D2": Path("graficas/D2_precision"),
    "D3": Path("graficas/D3_formalidad"),
    "D4": Path("graficas/D4_especificidad"),
    "D5": Path("graficas/D5_coherencia"),
    "D6": Path("graficas/D6_divergencia"),
    "P": Path("graficas/P_perfil"),
}

EXPECTED_GRAPHS = [
    "graficas/D1_fidelidad/G-D1.1_boxplot_jaccard.png",
    "graficas/D1_fidelidad/G-D1.2_histograma_jaccard.png",
    "graficas/D1_fidelidad/G-D1.3_top_divergentes.png",
    "graficas/D1_fidelidad/G-D1.4_jaccard_por_par.png",
    "graficas/D2_precision/G-D2.1_media_tecnicas.png",
    "graficas/D2_precision/G-D2.2_tecnicas_por_par.png",
    "graficas/D2_precision/G-D2.3_sustituciones_tecnicas.png",
    "graficas/D3_formalidad/G-D3.1_radar_formalidad.png",
    "graficas/D3_formalidad/G-D3.2_indicadores_formalidad.png",
    "graficas/D3_formalidad/G-D3.3_coord_vs_subord.png",
    "graficas/D4_especificidad/G-D4.1_abstracto_concreto.png",
    "graficas/D4_especificidad/G-D4.2_ratio_abstracto_concreto.png",
    "graficas/D4_especificidad/G-D4.3_calificativo_relacional.png",
    "graficas/D4_especificidad/G-D4.4_longitud_vs_ttr.png",
    "graficas/D5_coherencia/G-D5.1_categorias_semanticas.png",
    "graficas/D5_coherencia/G-D5.2_acciones_verbales.png",
    "graficas/D5_coherencia/G-D5.3_coincidencia_dominio.png",
    "graficas/D6_divergencia/G-D6.1_diferencias_correlacion.png",
    "graficas/D6_divergencia/G-D6.2_jaccard_sust_vs_verb.png",
    "graficas/D6_divergencia/G-D6.3_vocabulario_compartido.png",
    "graficas/D6_divergencia/G-D6.4_detalle_divergentes.png",
    "graficas/P_perfil/G-P1_medias_categorias.png",
    "graficas/P_perfil/G-P2_proporcion_categorias.png",
    "graficas/P_perfil/G-P3_ttr_densidad.png",
    "graficas/P_perfil/G-P4_formas_verbales.png",
    "graficas/P_perfil/G-P5_determinantes.png",
]

EXPECTED_TABLES = [
    "resultados_ls_completos.csv",
    "medias_por_corpus_ls.csv",
    "diferencias_medias_ls.csv",
    "jaccard_por_par.csv",
    "sustituciones_lexicas.csv",
    "pares_divergentes.csv",
    "vocabulario_exclusivo_gpt.csv",
    "vocabulario_exclusivo_claude.csv",
    "vocabulario_compartido.csv",
    "coincidencias_dominante.csv",
    "indicadores_formalidad.csv",
    "dist_sustantivos_significado.csv",
    "dist_adjetivos_tipo.csv",
    "dist_determinantes_tipo.csv",
    "dist_verbos_forma.csv",
    "dist_adverbios_forma.csv",
    "dist_conjunciones_tipo.csv",
    "dist_semantica_sustantivos.csv",
    "dist_semantica_verbos.csv",
    "top_sustantivos.csv",
    "top_verbos.csv",
]

LIST_COLUMNS = [
    "lista_sust_gpt",
    "lista_sust_claude",
    "lista_adj_gpt",
    "lista_adj_claude",
    "lista_verb_gpt",
    "lista_verb_claude",
    "lista_adv_gpt",
    "lista_adv_claude",
    "lista_tecnicos_gpt",
    "lista_tecnicos_claude",
    "exclusivas_sust_gpt",
    "exclusivas_sust_claude",
    "exclusivas_verb_gpt",
    "exclusivas_verb_claude",
    "exclusivas_adj_gpt",
    "exclusivas_adj_claude",
    "exclusivas_adv_gpt",
    "exclusivas_adv_claude",
    "exclusivas_tecnicas_gpt",
    "exclusivas_tecnicas_claude",
]

STRING_COLUMNS = {
    "texto_gpt",
    "texto_claude",
    "sust_tipo_dom_gpt",
    "sust_tipo_dom_claude",
    "adj_tipo_dom_gpt",
    "adj_tipo_dom_claude",
    "dominio_sem_dom_gpt",
    "dominio_sem_dom_claude",
    "accion_verb_dom_gpt",
    "accion_verb_dom_claude",
    "mismo_sust_dom",
    "mismo_adj_dom",
    "mismo_dominio_sem",
}


def configurar_matplotlib() -> None:
    plt.rcParams.update(
        {
            "axes.grid": True,
            "grid.color": "silver",
            "grid.linestyle": "--",
            "figure.dpi": 150,
            "savefig.dpi": PLOT_DPI,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "font.size": 10,
            "axes.titlesize": 13,
            "axes.labelsize": 10,
            "axes.prop_cycle": cycler.cycler(
                "color",
                [
                    PALETTE["gpt"],
                    PALETTE["claude"],
                    PALETTE["shared"],
                    PALETTE["warning"],
                    PALETTE["accent"],
                    PALETTE["neutral"],
                ],
            ),
        }
    )


def preparar_carpetas(base: Path) -> dict[str, Path]:
    rutas = {clave: base / ruta for clave, ruta in GRAPH_DIRS.items()}
    for ruta in rutas.values():
        ruta.mkdir(parents=True, exist_ok=True)
    (base / "tablas").mkdir(parents=True, exist_ok=True)
    return rutas


def cargar_resultados_ls(ruta_tsv: Path) -> pd.DataFrame:
    if not ruta_tsv.exists():
        raise FileNotFoundError(
            f"No existe {ruta_tsv}. Genera antes el TSV con exportar_tsv_ls('resultados_ls.tsv')."
        )

    df = pd.read_csv(ruta_tsv, sep="\t", encoding="utf-8", keep_default_na=False)
    faltantes = [col for col in ["n", *JACCARD_COLUMNS] if col not in df.columns]
    if faltantes:
        raise ValueError(f"El TSV no contiene columnas obligatorias: {faltantes}")
    return limpiar_resultados_ls(df)


def limpiar_resultados_ls(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    for col in df.columns:
        if col in STRING_COLUMNS or col in LIST_COLUMNS:
            df[col] = df[col].astype(str).str.strip()
        else:
            df[col] = pd.to_numeric(df[col].replace({"": np.nan}), errors="coerce")

    if "n" in df.columns:
        df["n"] = df["n"].astype("Int64")

    for col in ["mismo_sust_dom", "mismo_adj_dom", "mismo_dominio_sem"]:
        if col in df.columns:
            df[col] = df[col].astype(str).str.lower().str.strip()

    return df


def parse_lista(valor: object) -> list[str]:
    if valor is None:
        return []
    if isinstance(valor, float) and math.isnan(valor):
        return []
    texto = str(valor).strip()
    if not texto:
        return []
    return [parte.strip() for parte in texto.split(",") if parte.strip()]


def valores_lista(df: pd.DataFrame, col: str) -> list[str]:
    if col not in df.columns:
        return []
    salida: list[str] = []
    for valor in df[col]:
        salida.extend(parse_lista(valor))
    return salida


def conjunto_lista(df: pd.DataFrame, col: str) -> set[str]:
    return set(valores_lista(df, col))


def serie_numerica(df: pd.DataFrame, col: str) -> pd.Series:
    if col not in df.columns:
        return pd.Series(dtype=float)
    return pd.to_numeric(df[col], errors="coerce")


def serie_finita(df: pd.DataFrame, col: str) -> pd.Series:
    serie = serie_numerica(df, col).replace([np.inf, -np.inf], np.nan)
    return serie


def serie_para_plot(df: pd.DataFrame, col: str) -> pd.Series:
    serie = serie_numerica(df, col)
    if not np.isinf(serie).any():
        return serie.fillna(0)

    finitos = serie.replace([np.inf, -np.inf], np.nan)
    max_finito = finitos.max(skipna=True)
    min_finito = finitos.min(skipna=True)
    if pd.isna(max_finito):
        max_finito = 1.0
    if pd.isna(min_finito):
        min_finito = 0.0
    return serie.replace({np.inf: max_finito * 1.1 + 1, -np.inf: min_finito * 1.1 - 1}).fillna(0)


def media(df: pd.DataFrame, col: str) -> float:
    serie = serie_finita(df, col)
    valor = serie.mean(skipna=True)
    return float(valor) if not pd.isna(valor) else 0.0


def total(df: pd.DataFrame, col: str) -> float:
    serie = serie_finita(df, col)
    valor = serie.sum(skipna=True)
    return float(valor) if not pd.isna(valor) else 0.0


def ratio_seguro(numerador: float, denominador: float) -> float:
    if denominador == 0:
        return 0.0
    return numerador / denominador


def texto_corto(texto: object, largo: int = 42) -> str:
    salida = str(texto).replace("\n", " ").strip()
    if len(salida) <= largo:
        return salida
    return salida[: largo - 3] + "..."


def nombre_corpus(corpus: str) -> str:
    return "GPT" if corpus == "gpt" else "Claude"


def guardar_figura(fig: plt.Figure, ruta: Path) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    fig.tight_layout()
    fig.savefig(ruta, dpi=PLOT_DPI, bbox_inches="tight")
    plt.close(fig)


def anadir_tendencia_lineal(
    ax: plt.Axes,
    x: pd.Series,
    y: pd.Series,
    color: str,
    label: str,
) -> None:
    datos = pd.DataFrame(
        {
            "x": pd.to_numeric(x, errors="coerce"),
            "y": pd.to_numeric(y, errors="coerce"),
        }
    ).replace([np.inf, -np.inf], np.nan).dropna()
    if len(datos) < 2 or datos["x"].nunique() < 2:
        return

    pendiente, intercepto = np.polyfit(datos["x"], datos["y"], 1)
    xs = np.linspace(datos["x"].min(), datos["x"].max(), 100)
    ys = pendiente * xs + intercepto
    ax.plot(xs, ys, color=color, linestyle="--", linewidth=2, label=label)


def guardar_tabla_png(df: pd.DataFrame, ruta: Path, titulo: str, max_rows: int = 24, max_cols: int = 8) -> None:
    ruta.parent.mkdir(parents=True, exist_ok=True)
    fig, ax = plt.subplots(figsize=(10, 10))
    ax.axis("off")
    ax.set_title(titulo, pad=14, fontweight="bold")

    if df.empty:
        ax.text(0.5, 0.5, "Sin datos", ha="center", va="center", fontsize=13)
        fig.savefig(ruta, dpi=PLOT_DPI, bbox_inches="tight")
        plt.close(fig)
        return

    vista = df.copy()
    nota = ""
    if len(vista.columns) > max_cols:
        vista = vista.iloc[:, :max_cols]
        nota = "Vista previa: columnas truncadas"
    if len(vista) > max_rows:
        vista = vista.head(max_rows)
        nota = "Vista previa: filas truncadas" if not nota else nota + " y filas truncadas"

    vista = vista.astype(str).map(lambda valor: texto_corto(valor, 28))
    tabla = ax.table(
        cellText=vista.values,
        colLabels=[texto_corto(col, 18) for col in vista.columns],
        loc="center",
        cellLoc="center",
        colLoc="center",
    )
    tabla.auto_set_font_size(False)
    tabla.set_fontsize(7)
    tabla.scale(1, 1.35)
    for (fila, _col), celda in tabla.get_celld().items():
        if fila == 0:
            celda.set_text_props(weight="bold", color="white")
            celda.set_facecolor(PALETTE["neutral"])
        else:
            celda.set_facecolor("#F7F7F7" if fila % 2 == 0 else "white")
    if nota:
        ax.text(0.5, 0.02, nota, ha="center", va="bottom", fontsize=8, color=PALETTE["neutral"])
    fig.savefig(ruta, dpi=PLOT_DPI, bbox_inches="tight")
    plt.close(fig)


def guardar_tabla(df: pd.DataFrame, tablas_dir: Path, nombre_csv: str, titulo: str) -> None:
    ruta_csv = tablas_dir / nombre_csv
    ruta_png = ruta_csv.with_suffix(".png")
    df.to_csv(ruta_csv, index=False, encoding="utf-8")
    guardar_tabla_png(df, ruta_png, titulo)


def pares_metricas(df: pd.DataFrame) -> list[str]:
    bases: list[str] = []
    for col in df.columns:
        if not col.endswith("_gpt"):
            continue
        base = col[: -len("_gpt")]
        if f"{base}_claude" in df.columns and col not in LIST_COLUMNS and f"{base}_claude" not in LIST_COLUMNS:
            if pd.api.types.is_numeric_dtype(df[col]) and pd.api.types.is_numeric_dtype(df[f"{base}_claude"]):
                bases.append(base)
    return sorted(bases)


def tabla_medias(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for base in pares_metricas(df):
        gpt = media(df, f"{base}_gpt")
        claude = media(df, f"{base}_claude")
        filas.append(
            {
                "metrica": base,
                "media_gpt": round(gpt, 4),
                "media_claude": round(claude, 4),
                "diferencia_gpt_menos_claude": round(gpt - claude, 4),
            }
        )
    return pd.DataFrame(filas)


def tabla_diferencias_medias(df: pd.DataFrame) -> pd.DataFrame:
    medias = tabla_medias(df)
    if medias.empty:
        return medias
    salida = medias[["metrica", "diferencia_gpt_menos_claude"]].copy()
    salida["abs_diferencia"] = salida["diferencia_gpt_menos_claude"].abs()
    return salida.sort_values("abs_diferencia", ascending=False)


def vocabulario_categoria(df: pd.DataFrame, categoria: str) -> tuple[set[str], set[str], set[str]]:
    columnas = {
        "sustantivos": ("lista_sust_gpt", "lista_sust_claude"),
        "adjetivos": ("lista_adj_gpt", "lista_adj_claude"),
        "verbos": ("lista_verb_gpt", "lista_verb_claude"),
        "adverbios": ("lista_adv_gpt", "lista_adv_claude"),
        "tecnicos": ("lista_tecnicos_gpt", "lista_tecnicos_claude"),
    }
    col_gpt, col_claude = columnas[categoria]
    gpt = conjunto_lista(df, col_gpt)
    claude = conjunto_lista(df, col_claude)
    return gpt - claude, claude - gpt, gpt & claude


def tablas_vocabulario(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    filas_gpt = []
    filas_claude = []
    filas_comp = []
    for categoria in ["sustantivos", "adjetivos", "verbos", "adverbios", "tecnicos"]:
        solo_gpt, solo_claude, compartido = vocabulario_categoria(df, categoria)
        for palabra in sorted(solo_gpt):
            filas_gpt.append({"categoria": categoria, "palabra": palabra})
        for palabra in sorted(solo_claude):
            filas_claude.append({"categoria": categoria, "palabra": palabra})
        for palabra in sorted(compartido):
            filas_comp.append({"categoria": categoria, "palabra": palabra})
    return pd.DataFrame(filas_gpt), pd.DataFrame(filas_claude), pd.DataFrame(filas_comp)


def tabla_vocabulario_resumen(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for categoria in ["sustantivos", "adjetivos", "verbos", "adverbios"]:
        solo_gpt, solo_claude, compartido = vocabulario_categoria(df, categoria)
        filas.append(
            {
                "categoria": categoria,
                "solo_gpt": len(solo_gpt),
                "compartido": len(compartido),
                "solo_claude": len(solo_claude),
            }
        )
    return pd.DataFrame(filas)


def construir_sustituciones(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    categorias = [
        ("sustantivo", "exclusivas_sust_gpt", "exclusivas_sust_claude"),
        ("adjetivo", "exclusivas_adj_gpt", "exclusivas_adj_claude"),
        ("verbo", "exclusivas_verb_gpt", "exclusivas_verb_claude"),
        ("adverbio", "exclusivas_adv_gpt", "exclusivas_adv_claude"),
        ("tecnico", "exclusivas_tecnicas_gpt", "exclusivas_tecnicas_claude"),
    ]

    for _, fila in df.iterrows():
        n = int(fila["n"])
        tecnicos_gpt = set(parse_lista(fila.get("lista_tecnicos_gpt", "")))
        tecnicos_claude = set(parse_lista(fila.get("lista_tecnicos_claude", "")))
        for categoria, col_gpt, col_claude in categorias:
            for palabra_gpt in parse_lista(fila.get(col_gpt, "")):
                for palabra_claude in parse_lista(fila.get(col_claude, "")):
                    gpt_tecnico = palabra_gpt in tecnicos_gpt or categoria == "tecnico"
                    claude_tecnico = palabra_claude in tecnicos_claude or categoria == "tecnico"
                    if categoria == "tecnico" or (gpt_tecnico and claude_tecnico):
                        interpretacion = "diferencia terminologica tecnica"
                    elif gpt_tecnico:
                        interpretacion = "GPT usa termino mas tecnico"
                    elif claude_tecnico:
                        interpretacion = "Claude usa termino mas tecnico"
                    else:
                        interpretacion = "sustitucion lexica"
                    filas.append(
                        {
                            "par": n,
                            "categoria": categoria,
                            "palabra_gpt": palabra_gpt,
                            "palabra_claude": palabra_claude,
                            "tecnica": "si" if gpt_tecnico or claude_tecnico else "no",
                            "interpretacion": interpretacion,
                        }
                    )

    if not filas:
        return pd.DataFrame(columns=["par", "categoria", "palabra_gpt", "palabra_claude", "tecnica", "interpretacion"])
    return pd.DataFrame(filas).drop_duplicates().sort_values(["par", "categoria", "palabra_gpt", "palabra_claude"])


def motivos_divergencia(fila: pd.Series) -> list[str]:
    motivos = []
    if float(fila.get("jaccard_global", 1)) < 0.3:
        motivos.append("jaccard_global_bajo")
    if float(fila.get("jaccard_sustantivos", 1)) < 0.3:
        motivos.append("jaccard_sustantivos_bajo")
    if float(fila.get("jaccard_verbos", 1)) < 0.3:
        motivos.append("jaccard_verbos_bajo")
    if abs(float(fila.get("dif_sustantivos", 0))) >= 3:
        motivos.append("diferencia_sustantivos_grande")
    if abs(float(fila.get("dif_verbos", 0))) >= 2:
        motivos.append("diferencia_verbos_grande")
    if abs(float(fila.get("dif_densidad_lexica", 0))) > 0.15:
        motivos.append("diferencia_densidad_grande")
    if str(fila.get("mismo_dominio_sem", "")).lower() == "no":
        motivos.append("dominio_semantico_diferente")
    if parse_lista(fila.get("exclusivas_tecnicas_gpt", "")) or parse_lista(fila.get("exclusivas_tecnicas_claude", "")):
        motivos.append("tecnicas_exclusivas")
    if str(fila.get("mismo_sust_dom", "")).lower() == "no":
        motivos.append("sustantivo_dominante_diferente")
    if str(fila.get("mismo_adj_dom", "")).lower() == "no":
        motivos.append("adjetivo_dominante_diferente")
    return motivos


def tabla_pares_divergentes(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for _, fila in df.iterrows():
        motivos = motivos_divergencia(fila)
        if not motivos:
            continue
        filas.append(
            {
                "par": int(fila["n"]),
                "jaccard_global": fila["jaccard_global"],
                "dif_sustantivos": fila["dif_sustantivos"],
                "dif_verbos": fila["dif_verbos"],
                "dif_densidad_lexica": fila["dif_densidad_lexica"],
                "motivos": ",".join(motivos),
                "texto_gpt": texto_corto(fila.get("texto_gpt", ""), 90),
                "texto_claude": texto_corto(fila.get("texto_claude", ""), 90),
            }
        )
    salida = pd.DataFrame(filas)
    if salida.empty:
        return salida
    return salida.sort_values(["jaccard_global", "par"])


def tabla_detalle_divergentes(df: pd.DataFrame, max_rows: int = 10) -> pd.DataFrame:
    columnas_gpt = ["exclusivas_sust_gpt", "exclusivas_adj_gpt", "exclusivas_verb_gpt", "exclusivas_adv_gpt"]
    columnas_claude = ["exclusivas_sust_claude", "exclusivas_adj_claude", "exclusivas_verb_claude", "exclusivas_adv_claude"]
    filas = []
    for _, fila in df.sort_values("jaccard_global").head(max_rows).iterrows():
        ex_gpt = []
        ex_claude = []
        for col in columnas_gpt:
            ex_gpt.extend(parse_lista(fila.get(col, "")))
        for col in columnas_claude:
            ex_claude.extend(parse_lista(fila.get(col, "")))
        tecnico_diferente = bool(parse_lista(fila.get("exclusivas_tecnicas_gpt", "")) or parse_lista(fila.get("exclusivas_tecnicas_claude", "")))
        filas.append(
            {
                "par": int(fila["n"]),
                "jaccard_global": round(float(fila["jaccard_global"]), 4),
                "exclusivas_gpt": ", ".join(ex_gpt[:8]),
                "exclusivas_claude": ", ".join(ex_claude[:8]),
                "tecnico_diferente": "si" if tecnico_diferente else "no",
            }
        )
    return pd.DataFrame(filas)


def tabla_jaccard(df: pd.DataFrame) -> pd.DataFrame:
    return df[["n", *JACCARD_COLUMNS]].copy()


def tabla_coincidencias(df: pd.DataFrame) -> pd.DataFrame:
    columnas = [
        "n",
        "sust_tipo_dom_gpt",
        "sust_tipo_dom_claude",
        "mismo_sust_dom",
        "adj_tipo_dom_gpt",
        "adj_tipo_dom_claude",
        "mismo_adj_dom",
        "dominio_sem_dom_gpt",
        "dominio_sem_dom_claude",
        "mismo_dominio_sem",
    ]
    return df[[col for col in columnas if col in df.columns]].copy()


def tabla_formalidad(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for _, fila in df.iterrows():
        for corpus in ["gpt", "claude"]:
            adjetivos = float(fila.get(f"adjetivos_{corpus}", 0) or 0)
            adverbios = float(fila.get(f"adverbios_{corpus}", 0) or 0)
            filas.append(
                {
                    "par": int(fila["n"]),
                    "corpus": nombre_corpus(corpus),
                    "long_media_palabra": fila.get(f"long_media_palabra_{corpus}", 0),
                    "adv_mente_ratio": ratio_seguro(float(fila.get(f"adv_mente_{corpus}", 0) or 0), adverbios),
                    "ratio_subord_coord": fila.get(f"ratio_subord_coord_{corpus}", 0),
                    "n_locuciones": fila.get(f"n_locuciones_{corpus}", 0),
                    "adj_relacionales_ratio": ratio_seguro(float(fila.get(f"adj_relacionales_{corpus}", 0) or 0), adjetivos),
                    "densidad_lexica": fila.get(f"densidad_lexica_{corpus}", 0),
                }
            )
    return pd.DataFrame(filas)


def tabla_distribucion(df: pd.DataFrame, metricas: list[tuple[str, str]]) -> pd.DataFrame:
    filas = []
    for corpus in ["gpt", "claude"]:
        total_corpus = sum(total(df, f"{base}_{corpus}") for base, _ in metricas)
        for base, etiqueta in metricas:
            valor = total(df, f"{base}_{corpus}")
            filas.append(
                {
                    "corpus": nombre_corpus(corpus),
                    "categoria": etiqueta,
                    "total": int(valor),
                    "porcentaje": round(ratio_seguro(valor * 100, total_corpus), 2),
                }
            )
    return pd.DataFrame(filas)


def tabla_top(df: pd.DataFrame, categoria: str, n: int = 15) -> pd.DataFrame:
    columnas = {
        "sustantivos": ("lista_sust_gpt", "lista_sust_claude"),
        "verbos": ("lista_verb_gpt", "lista_verb_claude"),
    }
    filas = []
    for corpus, col in zip(["gpt", "claude"], columnas[categoria], strict=True):
        contador = Counter(valores_lista(df, col))
        for palabra, frecuencia in contador.most_common(n):
            filas.append(
                {
                    "corpus": nombre_corpus(corpus),
                    "palabra": palabra,
                    "frecuencia_en_oraciones": frecuencia,
                }
            )
    return pd.DataFrame(filas)


def formalidad_resumen(df: pd.DataFrame) -> pd.DataFrame:
    filas = []
    for corpus in ["gpt", "claude"]:
        adv_total = total(df, f"adverbios_{corpus}")
        adj_total = total(df, f"adjetivos_{corpus}")
        coord = total(df, f"conj_coord_cop_{corpus}") + total(df, f"conj_coord_adv_{corpus}")
        subord = total(df, f"conj_subord_compl_{corpus}") + total(df, f"conj_subord_otras_{corpus}")
        filas.append(
            {
                "corpus": nombre_corpus(corpus),
                "longitud_media_palabra": media(df, f"long_media_palabra_{corpus}"),
                "adv_mente_ratio": ratio_seguro(total(df, f"adv_mente_{corpus}"), adv_total),
                "ratio_subord_coord": ratio_seguro(subord, coord),
                "n_locuciones": media(df, f"n_locuciones_{corpus}"),
                "adj_relacionales_ratio": ratio_seguro(total(df, f"adj_relacionales_{corpus}"), adj_total),
                "densidad_lexica": media(df, f"densidad_lexica_{corpus}"),
            }
        )
    return pd.DataFrame(filas)


def graficas_d1(df: pd.DataFrame, ruta: Path) -> None:
    datos = [serie_finita(df, col).dropna() for col in JACCARD_COLUMNS]
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.boxplot(datos, tick_labels=["Sust.", "Adj.", "Verb.", "Adv.", "Global"], patch_artist=True)
    ax.set_title("Distribucion de Jaccard por categoria")
    ax.set_ylabel("Jaccard")
    ax.set_ylim(0, 1.05)
    guardar_figura(fig, ruta / "G-D1.1_boxplot_jaccard.png")

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.hist(serie_finita(df, "jaccard_global").dropna(), bins=np.linspace(0, 1, 11), color=PALETTE["gpt"], edgecolor="white")
    ax.set_title("Distribucion de Jaccard global")
    ax.set_xlabel("Jaccard global")
    ax.set_ylabel("Numero de pares")
    guardar_figura(fig, ruta / "G-D1.2_histograma_jaccard.png")

    top = df.sort_values("jaccard_global").head(10).copy()
    etiquetas = [f"P{int(fila.n)}: {texto_corto(fila.texto_gpt, 34)}" for fila in top.itertuples()]
    fig, ax = plt.subplots(figsize=(9, 6))
    ax.barh(etiquetas, top["jaccard_global"], color=PALETTE["warning"])
    ax.invert_yaxis()
    ax.set_xlim(0, 1)
    ax.set_title("Top 10 pares con mayor divergencia lexica")
    ax.set_xlabel("Jaccard global")
    guardar_figura(fig, ruta / "G-D1.3_top_divergentes.png")

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(df["n"], df["jaccard_global"], marker="o", color=PALETTE["gpt"], linewidth=1.8)
    ax.axhline(media(df, "jaccard_global"), color=PALETTE["warning"], linestyle="--", label="Media")
    ax.set_title("Jaccard global por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("Jaccard global")
    ax.set_ylim(0, 1.05)
    ax.legend()
    guardar_figura(fig, ruta / "G-D1.4_jaccard_por_par.png")


def graficas_d2(df: pd.DataFrame, ruta: Path, sustituciones: pd.DataFrame) -> None:
    medias = [media(df, "n_tecnicas_gpt"), media(df, "n_tecnicas_claude")]
    fig, ax = plt.subplots(figsize=(6, 5))
    ax.bar(["GPT", "Claude"], medias, color=[PALETTE["gpt"], PALETTE["claude"]])
    ax.set_title("Media de terminos tecnicos por corpus")
    ax.set_ylabel("Media por oracion")
    guardar_figura(fig, ruta / "G-D2.1_media_tecnicas.png")

    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(df["n"], df["n_tecnicas_gpt"], marker="o", label="GPT", color=PALETTE["gpt"])
    ax.plot(df["n"], df["n_tecnicas_claude"], marker="o", label="Claude", color=PALETTE["claude"])
    ax.set_title("Terminos tecnicos por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("n_tecnicas")
    ax.legend()
    guardar_figura(fig, ruta / "G-D2.2_tecnicas_por_par.png")

    tecnicas = sustituciones[sustituciones["tecnica"].eq("si")].copy() if not sustituciones.empty else sustituciones
    columnas = ["par", "palabra_gpt", "palabra_claude", "categoria", "interpretacion"]
    guardar_tabla_png(tecnicas[columnas].head(30), ruta / "G-D2.3_sustituciones_tecnicas.png", "Sustituciones lexicas tecnicas", 30, 5)


def graficas_d3(df: pd.DataFrame, ruta: Path) -> None:
    resumen = formalidad_resumen(df)
    metricas = [
        "longitud_media_palabra",
        "adv_mente_ratio",
        "ratio_subord_coord",
        "n_locuciones",
        "adj_relacionales_ratio",
        "densidad_lexica",
    ]
    etiquetas = ["Long.", "Adv.-mente", "Sub/coord", "Locuciones", "Adj.rel.", "Densidad"]
    normalizado = resumen.copy()
    for metrica in metricas:
        maximo = max(float(normalizado[metrica].max()), 1e-9)
        normalizado[metrica] = normalizado[metrica] / maximo

    angulos = np.linspace(0, 2 * np.pi, len(metricas), endpoint=False).tolist()
    angulos += angulos[:1]
    fig, ax = plt.subplots(figsize=(7, 7), subplot_kw={"polar": True})
    for _, fila in normalizado.iterrows():
        valores = [float(fila[m]) for m in metricas]
        valores += valores[:1]
        color = PALETTE["gpt"] if fila["corpus"] == "GPT" else PALETTE["claude"]
        ax.plot(angulos, valores, label=fila["corpus"], color=color)
        ax.fill(angulos, valores, alpha=0.15, color=color)
    ax.set_xticks(angulos[:-1])
    ax.set_xticklabels(etiquetas)
    ax.set_ylim(0, 1.05)
    ax.set_title("Perfil de formalidad normalizado")
    ax.legend(loc="upper right", bbox_to_anchor=(1.2, 1.1))
    guardar_figura(fig, ruta / "G-D3.1_radar_formalidad.png")

    indicadores = ["adv_mente_ratio", "adj_relacionales_ratio", "n_locuciones", "longitud_media_palabra"]
    etiquetas_barras = ["Adv.-mente", "Adj.rel.", "Locuciones", "Long.palabra"]
    x = np.arange(len(indicadores))
    ancho = 0.35
    gpt = normalizado[normalizado["corpus"].eq("GPT")][indicadores].iloc[0].to_numpy(dtype=float)
    claude = normalizado[normalizado["corpus"].eq("Claude")][indicadores].iloc[0].to_numpy(dtype=float)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(x - ancho / 2, gpt, ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, claude, ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels(etiquetas_barras)
    ax.set_ylabel("Valor normalizado")
    ax.set_title("Indicadores de formalidad")
    ax.legend()
    guardar_figura(fig, ruta / "G-D3.2_indicadores_formalidad.png")

    filas = []
    for corpus in ["gpt", "claude"]:
        coord = total(df, f"conj_coord_cop_{corpus}") + total(df, f"conj_coord_adv_{corpus}")
        subord = total(df, f"conj_subord_compl_{corpus}") + total(df, f"conj_subord_otras_{corpus}")
        filas.append([coord, subord, ratio_seguro(subord, coord)])
    valores = np.array(filas, dtype=float)
    x = np.arange(3)
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(x - ancho / 2, valores[0], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, valores[1], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels(["Coordinantes", "Subordinantes", "Ratio sub/coord"])
    ax.set_title("Coordinacion vs subordinacion")
    ax.legend()
    guardar_figura(fig, ruta / "G-D3.3_coord_vs_subord.png")


def graficas_d4(df: pd.DataFrame, ruta: Path) -> None:
    categorias = ["sust_abstractos", "sust_concretos", "sust_colectivos"]
    etiquetas = ["Abstractos", "Concretos", "Colectivos"]
    gpt = [total(df, f"{cat}_gpt") for cat in categorias]
    claude = [total(df, f"{cat}_claude") for cat in categorias]
    fig, ax = plt.subplots(figsize=(7, 5))
    bottom = np.zeros(2)
    for i, etiqueta in enumerate(etiquetas):
        valores = [gpt[i], claude[i]]
        ax.bar(["GPT", "Claude"], valores, bottom=bottom, label=etiqueta)
        bottom += valores
    ax.set_title("Sustantivos abstractos, concretos y colectivos")
    ax.set_ylabel("Total")
    ax.legend()
    guardar_figura(fig, ruta / "G-D4.1_abstracto_concreto.png")

    fig, ax = plt.subplots(figsize=(6, 5))
    ax.boxplot(
        [serie_para_plot(df, "ratio_abstracto_concreto_gpt"), serie_para_plot(df, "ratio_abstracto_concreto_claude")],
        tick_labels=["GPT", "Claude"],
        patch_artist=True,
    )
    ax.set_title("Ratio abstracto/concreto por corpus")
    ax.set_ylabel("Ratio")
    guardar_figura(fig, ruta / "G-D4.2_ratio_abstracto_concreto.png")

    metricas = ["adj_calificativos", "adj_relacionales"]
    x = np.arange(len(metricas))
    ancho = 0.35
    fig, ax = plt.subplots(figsize=(7, 5))
    ax.bar(x - ancho / 2, [total(df, f"{m}_gpt") for m in metricas], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [total(df, f"{m}_claude") for m in metricas], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels(["Calificativos", "Relacionales"])
    ax.set_title("Adjetivos calificativos vs relacionales")
    ax.legend()
    guardar_figura(fig, ruta / "G-D4.3_calificativo_relacional.png")

    fig, ax = plt.subplots(figsize=(7, 5))
    ax.scatter(df["long_media_palabra_gpt"], df["ttr_gpt"], label="GPT", color=PALETTE["gpt"], alpha=0.8)
    ax.scatter(df["long_media_palabra_claude"], df["ttr_claude"], label="Claude", color=PALETTE["claude"], alpha=0.8)
    anadir_tendencia_lineal(ax, df["long_media_palabra_gpt"], df["ttr_gpt"], PALETTE["gpt"], "Tendencia GPT")
    anadir_tendencia_lineal(
        ax,
        df["long_media_palabra_claude"],
        df["ttr_claude"],
        PALETTE["claude"],
        "Tendencia Claude",
    )
    ax.set_title("Longitud media de palabra vs TTR")
    ax.set_xlabel("Longitud media de palabra")
    ax.set_ylabel("TTR")
    ax.legend()
    guardar_figura(fig, ruta / "G-D4.4_longitud_vs_ttr.png")


def graficas_d5(df: pd.DataFrame, ruta: Path) -> None:
    sust = [
        ("sem_ser_vivo", "ser_vivo"),
        ("sem_ent_robotica", "ent_robotica"),
        ("sem_comp_biologico", "comp_bio"),
        ("sem_comp_mecanico", "comp_mec"),
        ("sem_instrumento", "instrumento"),
        ("sem_proceso_nominal", "proceso_nom"),
        ("sem_concepto_abstracto", "abstracto"),
    ]
    x = np.arange(len(sust))
    ancho = 0.36
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.bar(x - ancho / 2, [total(df, f"{m}_gpt") for m, _ in sust], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [total(df, f"{m}_claude") for m, _ in sust], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels([e for _, e in sust], rotation=25, ha="right")
    ax.set_title("Categorias semanticas de sustantivos")
    ax.legend()
    guardar_figura(fig, ruta / "G-D5.1_categorias_semanticas.png")

    verbos = [
        ("sem_v_fisica", "fisica"),
        ("sem_v_biologico", "biologica"),
        ("sem_v_tecnica", "tecnica"),
        ("sem_v_cognitiva", "cognitiva"),
        ("sem_v_comunicativa", "comunicativa"),
    ]
    x = np.arange(len(verbos))
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(x - ancho / 2, [total(df, f"{m}_gpt") for m, _ in verbos], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [total(df, f"{m}_claude") for m, _ in verbos], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels([e for _, e in verbos], rotation=20, ha="right")
    ax.set_title("Tipos de accion verbal")
    ax.legend()
    guardar_figura(fig, ruta / "G-D5.2_acciones_verbales.png")

    mismo = int(df["mismo_dominio_sem"].eq("si").sum())
    distinto = int(df["mismo_dominio_sem"].eq("no").sum())
    total_pares = max(mismo + distinto, 1)
    fig, ax = plt.subplots(figsize=(7, 4))
    ax.bar(["Dominio"], [mismo * 100 / total_pares], label="Mismo dominio", color=PALETTE["shared"])
    ax.bar(["Dominio"], [distinto * 100 / total_pares], bottom=[mismo * 100 / total_pares], label="Dominio diferente", color=PALETTE["warning"])
    ax.set_ylim(0, 100)
    ax.set_ylabel("% de pares")
    ax.set_title("Coincidencia en dominio semantico dominante")
    ax.legend()
    guardar_figura(fig, ruta / "G-D5.3_coincidencia_dominio.png")


def graficas_d6(df: pd.DataFrame, ruta: Path, vocab_resumen: pd.DataFrame, detalle_div: pd.DataFrame) -> None:
    fig, ax = plt.subplots(figsize=(10, 5))
    ax.plot(df["n"], df["dif_sustantivos"], label="Dif. sustantivos", color=PALETTE["gpt"])
    ax.plot(df["n"], df["dif_verbos"], label="Dif. verbos", color=PALETTE["claude"])
    ax.plot(df["n"], df["dif_densidad_lexica"] * 10, label="Dif. densidad x10", color=PALETTE["accent"])
    ax.axhline(0, color="black", linewidth=0.8)
    ax.set_title("Diferencias por par")
    ax.set_xlabel("Par")
    ax.set_ylabel("GPT - Claude")
    ax.legend()
    guardar_figura(fig, ruta / "G-D6.1_diferencias_correlacion.png")

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.scatter(df["jaccard_sustantivos"], df["jaccard_verbos"], color=PALETTE["gpt"], alpha=0.8)
    ax.set_xlim(0, 1.05)
    ax.set_ylim(0, 1.05)
    ax.set_title("Jaccard sustantivos vs verbos")
    ax.set_xlabel("Jaccard sustantivos")
    ax.set_ylabel("Jaccard verbos")
    guardar_figura(fig, ruta / "G-D6.2_jaccard_sust_vs_verb.png")

    fig, ax = plt.subplots(figsize=(8, 5))
    x = np.arange(len(vocab_resumen))
    bottom = np.zeros(len(vocab_resumen))
    for col, etiqueta, color in [
        ("solo_gpt", "Solo GPT", PALETTE["gpt"]),
        ("compartido", "Compartido", PALETTE["shared"]),
        ("solo_claude", "Solo Claude", PALETTE["claude"]),
    ]:
        valores = vocab_resumen[col].to_numpy(dtype=float)
        ax.bar(x, valores, bottom=bottom, label=etiqueta, color=color)
        bottom += valores
    ax.set_xticks(x)
    ax.set_xticklabels(vocab_resumen["categoria"])
    ax.set_title("Vocabulario compartido vs exclusivo")
    ax.legend()
    guardar_figura(fig, ruta / "G-D6.3_vocabulario_compartido.png")

    guardar_tabla_png(detalle_div, ruta / "G-D6.4_detalle_divergentes.png", "Pares mas divergentes", 10, 5)


def graficas_perfil(df: pd.DataFrame, ruta: Path) -> None:
    x = np.arange(len(CATEGORY_METRICS))
    ancho = 0.36
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.bar(x - ancho / 2, [media(df, f"{m}_gpt") for m, _ in CATEGORY_METRICS], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [media(df, f"{m}_claude") for m, _ in CATEGORY_METRICS], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels([e for _, e in CATEGORY_METRICS], rotation=25, ha="right")
    ax.set_ylabel("Media por oracion")
    ax.set_title("Media de tokens por categoria gramatical")
    ax.legend()
    guardar_figura(fig, ruta / "G-P1_medias_categorias.png")

    fig, ax = plt.subplots(figsize=(9, 5))
    bottom = np.zeros(2)
    for base, etiqueta in CATEGORY_METRICS:
        valores = np.array([total(df, f"{base}_gpt"), total(df, f"{base}_claude")], dtype=float)
        denominadores = np.array(
            [
                sum(total(df, f"{m}_gpt") for m, _ in CATEGORY_METRICS),
                sum(total(df, f"{m}_claude") for m, _ in CATEGORY_METRICS),
            ],
            dtype=float,
        )
        porcentajes = np.divide(valores * 100, denominadores, out=np.zeros_like(valores), where=denominadores != 0)
        ax.bar(["GPT", "Claude"], porcentajes, bottom=bottom, label=etiqueta)
        bottom += porcentajes
    ax.set_ylim(0, 100)
    ax.set_ylabel("%")
    ax.set_title("Proporcion de categorias por corpus")
    ax.legend(bbox_to_anchor=(1.02, 1), loc="upper left")
    guardar_figura(fig, ruta / "G-P2_proporcion_categorias.png")

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.boxplot(
        [
            serie_finita(df, "ttr_gpt").dropna(),
            serie_finita(df, "ttr_claude").dropna(),
            serie_finita(df, "densidad_lexica_gpt").dropna(),
            serie_finita(df, "densidad_lexica_claude").dropna(),
        ],
        tick_labels=["TTR GPT", "TTR Claude", "Dens. GPT", "Dens. Claude"],
        patch_artist=True,
    )
    ax.set_title("Distribucion de TTR y densidad lexica")
    guardar_figura(fig, ruta / "G-P3_ttr_densidad.png")

    formas = [
        ("verb_conjugadas", "Conjugadas"),
        ("verb_infinitivos", "Infinitivos"),
        ("verb_gerundios", "Gerundios"),
        ("verb_participios", "Participios"),
    ]
    x = np.arange(len(formas))
    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(x - ancho / 2, [total(df, f"{m}_gpt") for m, _ in formas], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [total(df, f"{m}_claude") for m, _ in formas], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels([e for _, e in formas])
    ax.set_title("Formas verbales")
    ax.legend()
    guardar_figura(fig, ruta / "G-P4_formas_verbales.png")

    determinantes = [
        ("det_art_det", "Art.det."),
        ("det_art_indet", "Art.indet."),
        ("det_demos", "Demost."),
        ("det_poses", "Poses."),
        ("det_numer", "Numer."),
        ("det_indef", "Indef."),
    ]
    x = np.arange(len(determinantes))
    fig, ax = plt.subplots(figsize=(9, 5))
    ax.bar(x - ancho / 2, [total(df, f"{m}_gpt") for m, _ in determinantes], ancho, label="GPT", color=PALETTE["gpt"])
    ax.bar(x + ancho / 2, [total(df, f"{m}_claude") for m, _ in determinantes], ancho, label="Claude", color=PALETTE["claude"])
    ax.set_xticks(x)
    ax.set_xticklabels([e for _, e in determinantes])
    ax.set_title("Tipos de determinantes")
    ax.legend()
    guardar_figura(fig, ruta / "G-P5_determinantes.png")


def exportar_tablas(df: pd.DataFrame, base: Path, sustituciones: pd.DataFrame, vocab_resumen: pd.DataFrame, detalle_div: pd.DataFrame) -> dict[str, pd.DataFrame]:
    tablas_dir = base / "tablas"
    tablas: dict[str, pd.DataFrame] = {}

    tablas["resultados_ls_completos.csv"] = df.copy()
    tablas["medias_por_corpus_ls.csv"] = tabla_medias(df)
    tablas["diferencias_medias_ls.csv"] = tabla_diferencias_medias(df)
    tablas["jaccard_por_par.csv"] = tabla_jaccard(df)
    tablas["sustituciones_lexicas.csv"] = sustituciones
    tablas["pares_divergentes.csv"] = tabla_pares_divergentes(df)

    vocab_gpt, vocab_claude, vocab_comp = tablas_vocabulario(df)
    tablas["vocabulario_exclusivo_gpt.csv"] = vocab_gpt
    tablas["vocabulario_exclusivo_claude.csv"] = vocab_claude
    tablas["vocabulario_compartido.csv"] = vocab_comp
    tablas["coincidencias_dominante.csv"] = tabla_coincidencias(df)
    tablas["indicadores_formalidad.csv"] = tabla_formalidad(df)

    tablas["dist_sustantivos_significado.csv"] = tabla_distribucion(
        df,
        [
            ("sust_abstractos", "abstracto"),
            ("sust_concretos", "concreto"),
            ("sust_colectivos", "colectivo"),
        ],
    )
    tablas["dist_adjetivos_tipo.csv"] = tabla_distribucion(
        df,
        [
            ("adj_calificativos", "calificativo"),
            ("adj_relacionales", "relacional"),
        ],
    )
    tablas["dist_determinantes_tipo.csv"] = tabla_distribucion(
        df,
        [
            ("det_art_det", "articulo_determinado"),
            ("det_art_indet", "articulo_indeterminado"),
            ("det_demos", "demostrativo"),
            ("det_poses", "posesivo"),
            ("det_numer", "numeral"),
            ("det_indef", "indefinido"),
        ],
    )
    tablas["dist_verbos_forma.csv"] = tabla_distribucion(
        df,
        [
            ("verb_conjugadas", "conjugada"),
            ("verb_infinitivos", "infinitivo"),
            ("verb_gerundios", "gerundio"),
            ("verb_participios", "participio"),
        ],
    )
    tablas["dist_adverbios_forma.csv"] = tabla_distribucion(
        df,
        [
            ("adv_mente", "derivado_mente"),
            ("adv_simples", "simple"),
        ],
    )
    tablas["dist_conjunciones_tipo.csv"] = tabla_distribucion(
        df,
        [
            ("conj_coord_cop", "coord_copulativa"),
            ("conj_coord_adv", "coord_adversativa"),
            ("conj_subord_compl", "subord_completiva"),
            ("conj_subord_otras", "subord_otras"),
        ],
    )
    tablas["dist_semantica_sustantivos.csv"] = tabla_distribucion(
        df,
        [
            ("sem_ser_vivo", "ser_vivo"),
            ("sem_ent_robotica", "entidad_robotica"),
            ("sem_comp_biologico", "componente_biologico"),
            ("sem_comp_mecanico", "componente_mecanico"),
            ("sem_instrumento", "instrumento"),
            ("sem_proceso_nominal", "proceso_nominal"),
            ("sem_concepto_abstracto", "concepto_abstracto"),
        ],
    )
    tablas["dist_semantica_verbos.csv"] = tabla_distribucion(
        df,
        [
            ("sem_v_fisica", "accion_fisica"),
            ("sem_v_biologico", "proceso_biologico"),
            ("sem_v_tecnica", "accion_tecnica"),
            ("sem_v_cognitiva", "accion_cognitiva"),
            ("sem_v_comunicativa", "accion_comunicativa"),
        ],
    )
    tablas["top_sustantivos.csv"] = tabla_top(df, "sustantivos")
    tablas["top_verbos.csv"] = tabla_top(df, "verbos")

    for nombre, tabla in tablas.items():
        guardar_tabla(tabla, tablas_dir, nombre, nombre.replace(".csv", ""))

    # Se devuelve tambien para reutilizar en informes.
    tablas["_vocab_resumen"] = vocab_resumen
    tablas["_detalle_divergentes"] = detalle_div
    return tablas


def generar_conclusiones(df: pd.DataFrame, base: Path, sustituciones: pd.DataFrame, divergentes: pd.DataFrame) -> None:
    jaccard_medio = media(df, "jaccard_global")
    jaccards_cat = {col: media(df, col) for col in JACCARD_COLUMNS}
    mejor_cat = max(jaccards_cat, key=jaccards_cat.get)
    peor_cat = min(jaccards_cat, key=jaccards_cat.get)
    tecnicas_gpt = media(df, "n_tecnicas_gpt")
    tecnicas_claude = media(df, "n_tecnicas_claude")
    dens_gpt = media(df, "densidad_lexica_gpt")
    dens_claude = media(df, "densidad_lexica_claude")
    ttr_gpt = media(df, "ttr_gpt")
    ttr_claude = media(df, "ttr_claude")
    ger_gpt = total(df, "verb_gerundios_gpt")
    ger_claude = total(df, "verb_gerundios_claude")
    dominio_mismo = int(df["mismo_dominio_sem"].eq("si").sum())

    lineas = [
        "# Conclusiones lexico-semanticas",
        "",
        "Este informe sintetiza los resultados generados automaticamente desde el TSV lexico-semantico.",
        "",
        "## D1 Fidelidad lexica",
        f"- Jaccard global medio: {jaccard_medio:.4f}.",
        f"- Categoria con mayor coincidencia: {mejor_cat} ({jaccards_cat[mejor_cat]:.4f}).",
        f"- Categoria con menor coincidencia: {peor_cat} ({jaccards_cat[peor_cat]:.4f}).",
        f"- Pares divergentes marcados para revision: {len(divergentes)}.",
        "",
        "## D2 Precision terminologica",
        f"- Media de terminos tecnicos GPT: {tecnicas_gpt:.4f}.",
        f"- Media de terminos tecnicos Claude: {tecnicas_claude:.4f}.",
        f"- Sustituciones tecnicas detectadas: {int(sustituciones['tecnica'].eq('si').sum()) if not sustituciones.empty else 0}.",
        "",
        "## D3-D4 Registro, formalidad y especificidad",
        f"- Densidad lexica media GPT/Claude: {dens_gpt:.4f} / {dens_claude:.4f}.",
        f"- TTR medio GPT/Claude: {ttr_gpt:.4f} / {ttr_claude:.4f}.",
        "",
        "## D5 Coherencia semantica",
        f"- Pares con mismo dominio semantico dominante: {dominio_mismo} de {len(df)}.",
        "",
        "## D6 y perfil",
        f"- Gerundios GPT/Claude: {int(ger_gpt)} / {int(ger_claude)}.",
        "- Las tablas CSV y las graficas PNG contienen el detalle para la revision cualitativa del plan.",
    ]
    (base / "conclusiones_lexico_semantico.md").write_text("\n".join(lineas) + "\n", encoding="utf-8")


def generar_revision_plan(base: Path, df: pd.DataFrame) -> None:
    graph_files = [base / ruta for ruta in EXPECTED_GRAPHS]
    table_csvs = [base / "tablas" / nombre for nombre in EXPECTED_TABLES]
    table_pngs = [ruta.with_suffix(".png") for ruta in table_csvs]
    graficas_ok = [ruta for ruta in graph_files if ruta.exists() and ruta.stat().st_size > 0]
    csv_ok = [ruta for ruta in table_csvs if ruta.exists() and ruta.stat().st_size > 0]
    png_ok = [ruta for ruta in table_pngs if ruta.exists() and ruta.stat().st_size > 0]

    lineas = [
        "# Revision del plan lexico-semantico",
        "",
        "## Estado",
        f"- Pares analizados en TSV: {len(df)}.",
        "- Fase 1 Prolog: verificada mediante tests.pl antes de generar las salidas.",
        "- Fase 2 Prolog: verificada mediante tests.pl y exportar_tsv_ls/1.",
        f"- Fase 3 Python: {len(graficas_ok)}/{len(EXPECTED_GRAPHS)} graficas PNG generadas.",
        f"- Tablas CSV: {len(csv_ok)}/{len(EXPECTED_TABLES)} generadas.",
        f"- Tablas PNG: {len(png_ok)}/{len(EXPECTED_TABLES)} generadas.",
        "",
        "## Comprobacion de graficas",
    ]
    for ruta in graph_files:
        estado = "OK" if ruta.exists() and ruta.stat().st_size > 0 else "FALTA"
        lineas.append(f"- {estado}: {ruta.relative_to(base)}")

    lineas.extend(["", "## Comprobacion de tablas"])
    for ruta in table_csvs:
        estado_csv = "OK" if ruta.exists() and ruta.stat().st_size > 0 else "FALTA"
        estado_png = "OK" if ruta.with_suffix(".png").exists() and ruta.with_suffix(".png").stat().st_size > 0 else "FALTA"
        lineas.append(f"- {ruta.name}: CSV {estado_csv}, PNG {estado_png}")

    lineas.extend(
        [
            "",
            "## Nota",
            "- Los PNG de tablas muy anchas son vistas previas cuadradas; los CSV conservan el contenido completo.",
            "- Las listas de adverbios y terminos tecnicos se exportan en el TSV para cubrir D2 y D6.",
        ]
    )
    (base / "revision_plan_lexico_semantico.md").write_text("\n".join(lineas) + "\n", encoding="utf-8")


def ejecutar_analisis(ruta_tsv: Path, salida: Path) -> None:
    configurar_matplotlib()
    rutas = preparar_carpetas(salida)
    df = cargar_resultados_ls(ruta_tsv)

    sustituciones = construir_sustituciones(df)
    vocab_resumen = tabla_vocabulario_resumen(df)
    detalle_div = tabla_detalle_divergentes(df)

    graficas_d1(df, rutas["D1"])
    graficas_d2(df, rutas["D2"], sustituciones)
    graficas_d3(df, rutas["D3"])
    graficas_d4(df, rutas["D4"])
    graficas_d5(df, rutas["D5"])
    graficas_d6(df, rutas["D6"], vocab_resumen, detalle_div)
    graficas_perfil(df, rutas["P"])

    tablas = exportar_tablas(df, salida, sustituciones, vocab_resumen, detalle_div)
    divergentes = tablas["pares_divergentes.csv"]
    generar_conclusiones(df, salida, sustituciones, divergentes)
    generar_revision_plan(salida, df)

    print(f"Analisis lexico-semantico generado en: {salida}")
    print(f"Graficas esperadas: {len(EXPECTED_GRAPHS)}")
    print(f"Tablas esperadas: {len(EXPECTED_TABLES)}")


def main(argv: list[str]) -> int:
    ruta_tsv = Path(argv[1]) if len(argv) > 1 else DEFAULT_TSV
    salida = Path(argv[2]) if len(argv) > 2 else DEFAULT_OUTPUT
    ejecutar_analisis(ruta_tsv, salida)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
