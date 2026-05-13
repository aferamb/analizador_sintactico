import os

os.environ.setdefault("MPLBACKEND", "Agg")

import numpy as np
import pandas as pd
import pytest

from analisis_graficas_lexico_semantico import (
    JACCARD_COLUMNS,
    cargar_resultados_ls,
    limpiar_resultados_ls,
    parse_lista,
)


def test_parse_lista_limpia_valores_vacios() -> None:
    assert parse_lista(None) == []
    assert parse_lista(float("nan")) == []
    assert parse_lista("") == []
    assert parse_lista(" pinza, efector , , araña ") == ["pinza", "efector", "araña"]


def test_limpieza_lexico_semantica_convierte_tipos() -> None:
    df = pd.DataFrame(
        [
            {
                "n": "1",
                "jaccard_sustantivos": "0.5",
                "jaccard_adjetivos": "0.25",
                "jaccard_verbos": "",
                "jaccard_adverbios": "1",
                "jaccard_global": "0.75",
                "texto_gpt": " Texto GPT ",
                "lista_sust_gpt": " pinza, araña ",
                "mismo_sust_dom": " SI ",
            }
        ]
    )

    limpio = limpiar_resultados_ls(df)

    assert limpio.loc[0, "n"] == 1
    assert limpio.loc[0, "jaccard_sustantivos"] == 0.5
    assert np.isnan(limpio.loc[0, "jaccard_verbos"])
    assert limpio.loc[0, "texto_gpt"] == "Texto GPT"
    assert limpio.loc[0, "lista_sust_gpt"] == "pinza, araña"
    assert limpio.loc[0, "mismo_sust_dom"] == "si"


def test_carga_tsv_lexico_semantico_minimo(tmp_path) -> None:
    ruta = tmp_path / "resultados_ls.tsv"
    columnas = ["n", *JACCARD_COLUMNS]
    ruta.write_text(
        "\t".join(columnas) + "\n" + "\t".join(["1", "0.1", "0.2", "0.3", "0.4", "0.5"]) + "\n",
        encoding="utf-8",
    )

    df = cargar_resultados_ls(ruta)

    assert df.shape == (1, len(columnas))
    assert df.loc[0, "jaccard_global"] == 0.5


def test_carga_tsv_lexico_semantico_exige_columnas_obligatorias(tmp_path) -> None:
    ruta = tmp_path / "resultados_ls_incompleto.tsv"
    ruta.write_text("n\tjaccard_global\n1\t0.5\n", encoding="utf-8")

    with pytest.raises(ValueError, match="columnas obligatorias"):
        cargar_resultados_ls(ruta)
