import os

os.environ.setdefault("MPLBACKEND", "Agg")

import pandas as pd

from analisis_graficas import (
    distribucion_tipos,
    limpiar_resultados,
    medias_por_corpus,
    pares_problematicos,
    resumen_global,
)


def resultados_sintacticos_minimos() -> pd.DataFrame:
    return pd.DataFrame(
        [
            {
                "n": "1",
                "texto_gpt": "Texto GPT 1",
                "texto_claude": "Texto Claude 1",
                "acepta_gpt": " SI ",
                "acepta_claude": " no ",
                "tipo_gpt": "o",
                "tipo_claude": "no_analizada",
                "mismo_tipo": " No ",
                "long_gpt": "10",
                "long_claude": "8",
                "dif_long_gpt_menos_claude": "2",
                "comas_gpt": "1",
                "comas_claude": "0",
                "conectores_gpt": "2",
                "conectores_claude": "1",
                "relativos_gpt": "0",
                "relativos_claude": "0",
                "tecnicos_gpt": "1",
                "tecnicos_claude": "1",
                "simples_gpt": "1",
                "simples_claude": "0",
                "profundidad_gpt": "4",
                "profundidad_claude": "0",
                "nodos_gpt": "25",
                "nodos_claude": "0",
            },
            {
                "n": "2",
                "texto_gpt": "Texto GPT 2",
                "texto_claude": "Texto Claude 2",
                "acepta_gpt": "si",
                "acepta_claude": "si",
                "tipo_gpt": "o",
                "tipo_claude": "o",
                "mismo_tipo": "si",
                "long_gpt": "6",
                "long_claude": "4",
                "dif_long_gpt_menos_claude": "2",
                "comas_gpt": "0",
                "comas_claude": "0",
                "conectores_gpt": "0",
                "conectores_claude": "0",
                "relativos_gpt": "0",
                "relativos_claude": "0",
                "tecnicos_gpt": "0",
                "tecnicos_claude": "0",
                "simples_gpt": "1",
                "simples_claude": "1",
                "profundidad_gpt": "3",
                "profundidad_claude": "3",
                "nodos_gpt": "12",
                "nodos_claude": "11",
            },
        ]
    )


def test_limpieza_crea_columnas_derivadas_y_diferencias() -> None:
    df = limpiar_resultados(resultados_sintacticos_minimos())

    assert df["n"].tolist() == [1, 2]
    assert df["acepta_gpt"].tolist() == ["si", "si"]
    assert df["acepta_claude"].tolist() == ["no", "si"]
    assert df["gpt_aceptada"].tolist() == [True, True]
    assert df["claude_aceptada"].tolist() == [False, True]
    assert df["solo_gpt_aceptada"].tolist() == [True, False]
    assert df["dif_nodos_gpt_menos_claude"].tolist() == [25, 1]


def test_resumenes_sintacticos_basicos() -> None:
    df = limpiar_resultados(resultados_sintacticos_minimos())

    resumen = resumen_global(df).iloc[0]
    assert resumen["total_pares"] == 2
    assert resumen["gpt_aceptadas"] == 2
    assert resumen["claude_aceptadas"] == 1
    assert resumen["ambas_aceptadas"] == 1
    assert resumen["solo_gpt_aceptada"] == 1
    assert resumen["mismo_tipo"] == 1

    medias = medias_por_corpus(df).set_index("corpus")
    assert medias.loc["GPT", "long"] == 8
    assert medias.loc["CLAUDE", "long"] == 6

    tipos = distribucion_tipos(df)
    cantidad_o_gpt = tipos.loc[(tipos["corpus"] == "GPT") & (tipos["tipo"] == "o"), "cantidad"].iloc[0]
    assert cantidad_o_gpt == 2


def test_pares_problematicos_detecta_no_aceptados() -> None:
    df = limpiar_resultados(resultados_sintacticos_minimos())

    problematicos = pares_problematicos(df)

    assert problematicos["n"].tolist() == [1]
    assert problematicos.iloc[0]["acepta_claude"] == "no"
