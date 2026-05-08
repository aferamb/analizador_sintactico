# Revision del plan lexico-semantico

## Estado
- Pares analizados en TSV: 50.
- Fase 1 Prolog: verificada mediante tests.pl antes de generar las salidas.
- Fase 2 Prolog: verificada mediante tests.pl y exportar_tsv_ls/1.
- Fase 3 Python: 26/26 graficas PNG generadas.
- Tablas CSV: 21/21 generadas.
- Tablas PNG: 21/21 generadas.

## Comprobacion de graficas
- OK: graficas/D1_fidelidad/G-D1.1_boxplot_jaccard.png
- OK: graficas/D1_fidelidad/G-D1.2_histograma_jaccard.png
- OK: graficas/D1_fidelidad/G-D1.3_top_divergentes.png
- OK: graficas/D1_fidelidad/G-D1.4_jaccard_por_par.png
- OK: graficas/D2_precision/G-D2.1_media_tecnicas.png
- OK: graficas/D2_precision/G-D2.2_tecnicas_por_par.png
- OK: graficas/D2_precision/G-D2.3_sustituciones_tecnicas.png
- OK: graficas/D3_formalidad/G-D3.1_radar_formalidad.png
- OK: graficas/D3_formalidad/G-D3.2_indicadores_formalidad.png
- OK: graficas/D3_formalidad/G-D3.3_coord_vs_subord.png
- OK: graficas/D4_especificidad/G-D4.1_abstracto_concreto.png
- OK: graficas/D4_especificidad/G-D4.2_ratio_abstracto_concreto.png
- OK: graficas/D4_especificidad/G-D4.3_calificativo_relacional.png
- OK: graficas/D4_especificidad/G-D4.4_longitud_vs_ttr.png
- OK: graficas/D5_coherencia/G-D5.1_categorias_semanticas.png
- OK: graficas/D5_coherencia/G-D5.2_acciones_verbales.png
- OK: graficas/D5_coherencia/G-D5.3_coincidencia_dominio.png
- OK: graficas/D6_divergencia/G-D6.1_diferencias_correlacion.png
- OK: graficas/D6_divergencia/G-D6.2_jaccard_sust_vs_verb.png
- OK: graficas/D6_divergencia/G-D6.3_vocabulario_compartido.png
- OK: graficas/D6_divergencia/G-D6.4_detalle_divergentes.png
- OK: graficas/P_perfil/G-P1_medias_categorias.png
- OK: graficas/P_perfil/G-P2_proporcion_categorias.png
- OK: graficas/P_perfil/G-P3_ttr_densidad.png
- OK: graficas/P_perfil/G-P4_formas_verbales.png
- OK: graficas/P_perfil/G-P5_determinantes.png

## Comprobacion de tablas
- resultados_ls_completos.csv: CSV OK, PNG OK
- medias_por_corpus_ls.csv: CSV OK, PNG OK
- diferencias_medias_ls.csv: CSV OK, PNG OK
- jaccard_por_par.csv: CSV OK, PNG OK
- sustituciones_lexicas.csv: CSV OK, PNG OK
- pares_divergentes.csv: CSV OK, PNG OK
- vocabulario_exclusivo_gpt.csv: CSV OK, PNG OK
- vocabulario_exclusivo_claude.csv: CSV OK, PNG OK
- vocabulario_compartido.csv: CSV OK, PNG OK
- coincidencias_dominante.csv: CSV OK, PNG OK
- indicadores_formalidad.csv: CSV OK, PNG OK
- dist_sustantivos_significado.csv: CSV OK, PNG OK
- dist_adjetivos_tipo.csv: CSV OK, PNG OK
- dist_determinantes_tipo.csv: CSV OK, PNG OK
- dist_verbos_forma.csv: CSV OK, PNG OK
- dist_adverbios_forma.csv: CSV OK, PNG OK
- dist_conjunciones_tipo.csv: CSV OK, PNG OK
- dist_semantica_sustantivos.csv: CSV OK, PNG OK
- dist_semantica_verbos.csv: CSV OK, PNG OK
- top_sustantivos.csv: CSV OK, PNG OK
- top_verbos.csv: CSV OK, PNG OK

## Nota
- Los PNG de tablas muy anchas son vistas previas cuadradas; los CSV conservan el contenido completo.
- Las listas de adverbios y terminos tecnicos se exportan en el TSV para cubrir D2 y D6.
