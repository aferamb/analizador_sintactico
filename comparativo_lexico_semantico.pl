% comparativo_lexico_semantico.pl
% Comparacion lexico-semantica entre las traducciones GPT y Claude.

:- encoding(utf8).

:- use_module(library(lists)).

:- ensure_loaded('metricas_lexico_semanticas.pl').

% =========================================================
% ANALISIS POR CORPUS
% =========================================================

resultado_ls_gpt(N, Texto, ResultadoLS) :-
    obtener_oracion_gpt(N, Texto),
    once(analizar_lexico_semantico(Texto, ResultadoLS)).

resultado_ls_claude(N, Texto, ResultadoLS) :-
    obtener_oracion_claude(N, Texto),
    once(analizar_lexico_semantico(Texto, ResultadoLS)).

resultado_ls_corpus(gpt, N, Texto, ResultadoLS) :-
    resultado_ls_gpt(N, Texto, ResultadoLS).

resultado_ls_corpus(claude, N, Texto, ResultadoLS) :-
    resultado_ls_claude(N, Texto, ResultadoLS).

par_ls_disponible(N) :-
    oracion_gpt(N, _),
    oracion_claude(N, _).

% =========================================================
% COMPARACION INDIVIDUAL
% =========================================================

comparacion_ls(N, Comparacion) :-
    resultado_ls_gpt(N, _, RGPT),
    resultado_ls_claude(N, _, RClaude),

    listas_comparables(RGPT, RClaude, Listas),
    calcular_jaccards(Listas, JSust, JAdj, JVerb, JAdv, JGlobal),
    calcular_exclusivas(Listas, Exclusivas),
    calcular_diferencias(RGPT, RClaude, Diferencias),
    calcular_coincidencias_dominantes(RGPT, RClaude, Coincidencias),
    sustituciones_desde_exclusivas(N, Exclusivas, Sustituciones),
    criterios_interes(N, JSust, JVerb, Exclusivas, Diferencias, Coincidencias, Motivos),
    valor_interes(Motivos, Interesante),

    Exclusivas = exclusivas_ls(
        ESG, ESC, EAG, EAC, EVG, EVC, EAdvG, EAdvC, ETG, ETC
    ),
    Diferencias = diferencias_ls(DS, DA, DV, DDens, DTTR, DTec, DLong),
    Coincidencias = coincidencias_ls(MismoSust, MismoAdj, MismoDom),

    Comparacion = comparacion_ls(
        jaccard_sustantivos(JSust),
        jaccard_adjetivos(JAdj),
        jaccard_verbos(JVerb),
        jaccard_adverbios(JAdv),
        jaccard_global(JGlobal),

        exclusivas_sust_gpt(ESG),
        exclusivas_sust_claude(ESC),
        exclusivas_adj_gpt(EAG),
        exclusivas_adj_claude(EAC),
        exclusivas_verb_gpt(EVG),
        exclusivas_verb_claude(EVC),
        exclusivas_adv_gpt(EAdvG),
        exclusivas_adv_claude(EAdvC),
        exclusivas_tecnicas_gpt(ETG),
        exclusivas_tecnicas_claude(ETC),

        dif_sustantivos(DS),
        dif_adjetivos(DA),
        dif_verbos(DV),
        dif_densidad_lexica(DDens),
        dif_ttr(DTTR),
        dif_tecnicas(DTec),
        dif_longitud_media(DLong),

        mismo_sust_dom(MismoSust),
        mismo_adj_dom(MismoAdj),
        mismo_dominio_sem(MismoDom),

        sustituciones(Sustituciones),
        interesante(Interesante),
        motivos(Motivos)
    ),
    !.

valor_comparacion_ls(Comparacion, Clave, Valor) :-
    Comparacion =.. [comparacion_ls|Campos],
    member(Campo, Campos),
    Campo =.. [Clave, Valor],
    !.

comparar_ls(N) :-
    resultado_ls_gpt(N, TextoGPT, RGPT),
    resultado_ls_claude(N, TextoClaude, RClaude),
    comparacion_ls(N, Comparacion),
    nl,
    write('================================================='), nl,
    write('PAR LS '), write(N), nl,
    write('================================================='), nl,
    write('GPT: '), write(TextoGPT), nl,
    imprimir_resumen_resultado_ls(RGPT),
    write('CLAUDE: '), write(TextoClaude), nl,
    imprimir_resumen_resultado_ls(RClaude),
    imprimir_comparacion_ls(Comparacion).

imprimir_resumen_resultado_ls(Resultado) :-
    valor_resultado_ls(Resultado, n_sustantivos, NS),
    valor_resultado_ls(Resultado, n_adjetivos, NA),
    valor_resultado_ls(Resultado, n_verbos, NV),
    valor_resultado_ls(Resultado, densidad_lexica, Dens),
    valor_resultado_ls(Resultado, n_tecnicas, NTec),
    valor_resultado_ls(Resultado, dominio_dominante, Dominio),
    write('  Sustantivos: '), write(NS), nl,
    write('  Adjetivos: '), write(NA), nl,
    write('  Verbos: '), write(NV), nl,
    write('  Densidad lexica: '), write(Dens), nl,
    write('  Terminos tecnicos: '), write(NTec), nl,
    write('  Dominio dominante: '), write(Dominio), nl.

imprimir_comparacion_ls(Comparacion) :-
    valor_comparacion_ls(Comparacion, jaccard_sustantivos, JSust),
    valor_comparacion_ls(Comparacion, jaccard_verbos, JVerb),
    valor_comparacion_ls(Comparacion, jaccard_global, JGlobal),
    valor_comparacion_ls(Comparacion, interesante, Interesante),
    valor_comparacion_ls(Comparacion, motivos, Motivos),
    write('COMPARACION LS:'), nl,
    write('  Jaccard sustantivos: '), write(JSust), nl,
    write('  Jaccard verbos: '), write(JVerb), nl,
    write('  Jaccard global: '), write(JGlobal), nl,
    write('  Par interesante: '), write(Interesante), nl,
    write('  Motivos: '), write(Motivos), nl.

% =========================================================
% JACCARD, EXCLUSIVAS Y DIFERENCIAS
% =========================================================

listas_comparables(RGPT, RClaude, listas_ls(
    SustGPT, SustClaude,
    AdjGPT, AdjClaude,
    VerbGPT, VerbClaude,
    AdvGPT, AdvClaude,
    TecGPT, TecClaude,
    GlobalGPT, GlobalClaude
)) :-
    valor_resultado_ls(RGPT, lista_sustantivos, SustGPT),
    valor_resultado_ls(RClaude, lista_sustantivos, SustClaude),
    valor_resultado_ls(RGPT, lista_adjetivos, AdjGPT),
    valor_resultado_ls(RClaude, lista_adjetivos, AdjClaude),
    valor_resultado_ls(RGPT, lista_verbos, VerbGPT),
    valor_resultado_ls(RClaude, lista_verbos, VerbClaude),
    valor_resultado_ls(RGPT, lista_adverbios, AdvGPT),
    valor_resultado_ls(RClaude, lista_adverbios, AdvClaude),
    valor_resultado_ls(RGPT, lista_tecnicos, TecGPT),
    valor_resultado_ls(RClaude, lista_tecnicos, TecClaude),
    unir_listas_lexicas([SustGPT, AdjGPT, VerbGPT, AdvGPT], GlobalGPT),
    unir_listas_lexicas([SustClaude, AdjClaude, VerbClaude, AdvClaude], GlobalClaude).

calcular_jaccards(
    listas_ls(
        SustGPT, SustClaude,
        AdjGPT, AdjClaude,
        VerbGPT, VerbClaude,
        AdvGPT, AdvClaude,
        _, _, GlobalGPT, GlobalClaude
    ),
    JSust, JAdj, JVerb, JAdv, JGlobal
) :-
    jaccard_ls(SustGPT, SustClaude, JSust),
    jaccard_ls(AdjGPT, AdjClaude, JAdj),
    jaccard_ls(VerbGPT, VerbClaude, JVerb),
    jaccard_ls(AdvGPT, AdvClaude, JAdv),
    jaccard_ls(GlobalGPT, GlobalClaude, JGlobal).

jaccard_ls(ListaA, ListaB, 1) :-
    conjunto_ordenado(ListaA, []),
    conjunto_ordenado(ListaB, []),
    !.

jaccard_ls(ListaA, ListaB, 0) :-
    conjunto_ordenado(ListaA, A),
    conjunto_ordenado(ListaB, B),
    (A = [], B \= [] ; A \= [], B = []),
    !.

jaccard_ls(ListaA, ListaB, Jaccard) :-
    conjunto_ordenado(ListaA, A),
    conjunto_ordenado(ListaB, B),
    intersection(A, B, Interseccion),
    union(A, B, Union),
    length(Interseccion, NInter),
    length(Union, NUnion),
    Ratio is NInter / NUnion,
    redondear4_ls(Ratio, Jaccard).

calcular_exclusivas(
    listas_ls(
        SustGPT, SustClaude,
        AdjGPT, AdjClaude,
        VerbGPT, VerbClaude,
        AdvGPT, AdvClaude,
        TecGPT, TecClaude,
        _, _
    ),
    exclusivas_ls(ESG, ESC, EAG, EAC, EVG, EVC, EAdvG, EAdvC, ETG, ETC)
) :-
    diferencia_conjuntos(SustGPT, SustClaude, ESG),
    diferencia_conjuntos(SustClaude, SustGPT, ESC),
    diferencia_conjuntos(AdjGPT, AdjClaude, EAG),
    diferencia_conjuntos(AdjClaude, AdjGPT, EAC),
    diferencia_conjuntos(VerbGPT, VerbClaude, EVG),
    diferencia_conjuntos(VerbClaude, VerbGPT, EVC),
    diferencia_conjuntos(AdvGPT, AdvClaude, EAdvG),
    diferencia_conjuntos(AdvClaude, AdvGPT, EAdvC),
    diferencia_conjuntos(TecGPT, TecClaude, ETG),
    diferencia_conjuntos(TecClaude, TecGPT, ETC).

calcular_diferencias(RGPT, RClaude, diferencias_ls(DS, DA, DV, DDens, DTTR, DTec, DLong)) :-
    diferencia_metrica(RGPT, RClaude, n_sustantivos, DS),
    diferencia_metrica(RGPT, RClaude, n_adjetivos, DA),
    diferencia_metrica(RGPT, RClaude, n_verbos, DV),
    diferencia_metrica(RGPT, RClaude, densidad_lexica, DDens),
    diferencia_metrica(RGPT, RClaude, ttr, DTTR),
    diferencia_metrica(RGPT, RClaude, n_tecnicas, DTec),
    diferencia_metrica(RGPT, RClaude, longitud_media_palabra, DLong).

diferencia_metrica(RGPT, RClaude, Metrica, Diferencia) :-
    valor_resultado_ls(RGPT, Metrica, VGPT),
    valor_resultado_ls(RClaude, Metrica, VClaude),
    Diferencia0 is VGPT - VClaude,
    redondear4_ls(Diferencia0, Diferencia).

calcular_coincidencias_dominantes(RGPT, RClaude, coincidencias_ls(MismoSust, MismoAdj, MismoDom)) :-
    valor_submetrica_ls(RGPT, sub_sustantivos, sust_significado_dominante, SustGPT),
    valor_submetrica_ls(RClaude, sub_sustantivos, sust_significado_dominante, SustClaude),
    valor_submetrica_ls(RGPT, sub_adjetivos, adj_tipo_dominante, AdjGPT),
    valor_submetrica_ls(RClaude, sub_adjetivos, adj_tipo_dominante, AdjClaude),
    valor_resultado_ls(RGPT, dominio_dominante, DomGPT),
    valor_resultado_ls(RClaude, dominio_dominante, DomClaude),
    mismo_valor_si_no(SustGPT, SustClaude, MismoSust),
    mismo_valor_si_no(AdjGPT, AdjClaude, MismoAdj),
    mismo_valor_si_no(DomGPT, DomClaude, MismoDom).

mismo_valor_si_no(Valor, Valor, si) :- !.
mismo_valor_si_no(_, _, no).

sustituciones_desde_exclusivas(
    N,
    exclusivas_ls(ESG, ESC, EAG, EAC, EVG, EVC, EAdvG, EAdvC, ETG, ETC),
    Sustituciones
) :-
    sustituciones_categoria(N, sustantivo, ESG, ESC, SustS),
    sustituciones_categoria(N, adjetivo, EAG, EAC, SustA),
    sustituciones_categoria(N, verbo, EVG, EVC, SustV),
    sustituciones_categoria(N, adverbio, EAdvG, EAdvC, SustAdv),
    sustituciones_categoria(N, tecnico, ETG, ETC, SustTec),
    append([SustS, SustA, SustV, SustAdv, SustTec], Sustituciones).

sustituciones_categoria(N, Categoria, ExclusivasGPT, ExclusivasClaude, Sustituciones) :-
    findall(
        sustitucion(N, Categoria, PalabraGPT, PalabraClaude),
        (
            member(PalabraGPT, ExclusivasGPT),
            member(PalabraClaude, ExclusivasClaude)
        ),
        Sustituciones
    ).

criterios_interes(
    _N, JSust, JVerb,
    exclusivas_ls(_, _, _, _, _, _, _, _, ETG, ETC),
    diferencias_ls(DS, _, DV, DDens, _, _, _),
    coincidencias_ls(MismoSust, MismoAdj, MismoDom),
    Motivos
) :-
    findall(
        Motivo,
        criterio_interes_cumplido(
            JSust, JVerb, ETG, ETC,
            DS, DV, DDens,
            MismoSust, MismoAdj, MismoDom,
            Motivo
        ),
        Motivos
    ).

criterio_interes_cumplido(JSust, _, _, _, _, _, _, _, _, _, jaccard_sustantivos_bajo) :-
    JSust < 0.3.
criterio_interes_cumplido(_, JVerb, _, _, _, _, _, _, _, _, jaccard_verbos_bajo) :-
    JVerb < 0.3.
criterio_interes_cumplido(_, _, _, _, DS, _, _, _, _, _, diferencia_sustantivos_grande) :-
    abs(DS) >= 3.
criterio_interes_cumplido(_, _, _, _, _, DV, _, _, _, _, diferencia_verbos_grande) :-
    abs(DV) >= 2.
criterio_interes_cumplido(_, _, _, _, _, _, DDens, _, _, _, diferencia_densidad_grande) :-
    abs(DDens) > 0.15.
criterio_interes_cumplido(_, _, _, _, _, _, _, _, _, no, dominio_semantico_diferente).
criterio_interes_cumplido(_, _, ETG, ETC, _, _, _, _, _, _, tecnicas_exclusivas) :-
    once((ETG \= [] ; ETC \= [])).
criterio_interes_cumplido(_, _, _, _, _, _, _, no, _, _, sustantivo_dominante_diferente).
criterio_interes_cumplido(_, _, _, _, _, _, _, _, no, _, adjetivo_dominante_diferente).

valor_interes([], no) :- !.
valor_interes(_, si).

% =========================================================
% RESUMEN GLOBAL
% =========================================================

resumen_lexico_semantico :-
    findall(N, par_ls_disponible(N), Ns0),
    sort(Ns0, Ns),
    length(Ns, Total),
    media_metrica_ls(gpt, n_sustantivos, MediaSustGPT),
    media_metrica_ls(claude, n_sustantivos, MediaSustClaude),
    media_metrica_ls(gpt, n_verbos, MediaVerbGPT),
    media_metrica_ls(claude, n_verbos, MediaVerbClaude),
    media_metrica_ls(gpt, densidad_lexica, MediaDensGPT),
    media_metrica_ls(claude, densidad_lexica, MediaDensClaude),
    media_metrica_ls(gpt, n_tecnicas, MediaTecGPT),
    media_metrica_ls(claude, n_tecnicas, MediaTecClaude),
    media_jaccard_global(MediaJaccard),
    contar_jaccard_global(alto, Altos),
    contar_jaccard_global(bajo, Bajos),
    sustituciones_lexicas_ls(Sustituciones),
    length(Sustituciones, NSustituciones),
    pares_interesantes_ls(ParesInteresantes),
    length(ParesInteresantes, NInteresantes),
    nl,
    write('========== RESUMEN LEXICO-SEMANTICO =========='), nl,
    write('Total de pares: '), write(Total), nl,
    nl,
    write('--- Medias principales ---'), nl,
    write('Sustantivos GPT/Claude: '), write(MediaSustGPT), write(' / '), write(MediaSustClaude), nl,
    write('Verbos GPT/Claude: '), write(MediaVerbGPT), write(' / '), write(MediaVerbClaude), nl,
    write('Densidad lexica GPT/Claude: '), write(MediaDensGPT), write(' / '), write(MediaDensClaude), nl,
    write('Terminos tecnicos GPT/Claude: '), write(MediaTecGPT), write(' / '), write(MediaTecClaude), nl,
    nl,
    write('--- Fidelidad lexica ---'), nl,
    write('Jaccard global medio: '), write(MediaJaccard), nl,
    write('Pares con solapamiento alto (> 0.6): '), write(Altos), nl,
    write('Pares con solapamiento bajo (< 0.3): '), write(Bajos), nl,
    nl,
    write('--- Revision manual ---'), nl,
    write('Sustituciones lexicas candidatas: '), write(NSustituciones), nl,
    write('Pares interesantes: '), write(NInteresantes), write(' '), write(ParesInteresantes), nl.

media_metrica_ls(Corpus, Metrica, Media) :-
    findall(
        Valor,
        (
            resultado_ls_corpus(Corpus, _, _, Resultado),
            valor_metrica_ls(Resultado, Metrica, Valor),
            number(Valor)
        ),
        Valores
    ),
    media_lista_ls(Valores, Media).

sumar_metrica_ls(Corpus, Metrica, Total) :-
    findall(
        Valor,
        (
            resultado_ls_corpus(Corpus, _, _, Resultado),
            valor_metrica_ls(Resultado, Metrica, Valor),
            number(Valor)
        ),
        Valores
    ),
    sum_list(Valores, Total0),
    redondear4_ls(Total0, Total).

distribucion_global_ls(Corpus, Metricas, Distribucion) :-
    findall(
        Metrica-Total,
        (member(Metrica, Metricas), sumar_metrica_ls(Corpus, Metrica, Total)),
        Distribucion
    ).

top_palabras_ls(Corpus, Categoria, N, Top) :-
    findall(
        Palabra,
        (
            oracion_ls_corpus(Corpus, _, Texto),
            palabras_categoria_texto_ls(Categoria, Texto, Palabras),
            member(Palabra, Palabras)
        ),
        Palabras
    ),
    frecuencias_ordenadas(Palabras, Frecuencias),
    tomar_n(N, Frecuencias, Top).

vocabulario_global_ls(Corpus, Categoria, Vocabulario) :-
    lista_categoria_resultado(Categoria, ClaveLista),
    findall(
        Palabra,
        (
            resultado_ls_corpus(Corpus, _, _, Resultado),
            valor_resultado_ls(Resultado, ClaveLista, Lista),
            member(Palabra, Lista)
        ),
        Palabras
    ),
    sort(Palabras, Vocabulario).

vocabulario_global_exclusivo_ls(Categoria, SoloGPT, SoloClaude, Compartido) :-
    vocabulario_global_ls(gpt, Categoria, VocabGPT),
    vocabulario_global_ls(claude, Categoria, VocabClaude),
    diferencia_conjuntos(VocabGPT, VocabClaude, SoloGPT),
    diferencia_conjuntos(VocabClaude, VocabGPT, SoloClaude),
    intersection(VocabGPT, VocabClaude, Compartido).

sustituciones_lexicas_ls(Sustituciones) :-
    findall(
        Sustitucion,
        (
            par_ls_disponible(N),
            comparacion_ls(N, Comparacion),
            valor_comparacion_ls(Comparacion, sustituciones, SustitucionesPar),
            member(Sustitucion, SustitucionesPar)
        ),
        Sustituciones
    ).

pares_interesantes_ls(Pares) :-
    findall(
        par(N, Motivos),
        (
            par_ls_disponible(N),
            comparacion_ls(N, Comparacion),
            valor_comparacion_ls(Comparacion, interesante, si),
            valor_comparacion_ls(Comparacion, motivos, Motivos)
        ),
        Pares
    ).

media_jaccard_global(Media) :-
    findall(
        J,
        (
            par_ls_disponible(N),
            comparacion_ls(N, Comparacion),
            valor_comparacion_ls(Comparacion, jaccard_global, J)
        ),
        Valores
    ),
    media_lista_ls(Valores, Media).

contar_jaccard_global(alto, N) :-
    contar_jaccard_global_condicion(>(0.6), N).

contar_jaccard_global(bajo, N) :-
    contar_jaccard_global_condicion(<(0.3), N).

contar_jaccard_global_condicion(Condicion, N) :-
    findall(
        1,
        (
            par_ls_disponible(Num),
            comparacion_ls(Num, Comparacion),
            valor_comparacion_ls(Comparacion, jaccard_global, J),
            cumple_comparacion_num(Condicion, J)
        ),
        Unos
    ),
    length(Unos, N).

cumple_comparacion_num(>(Limite), Valor) :-
    Valor > Limite.
cumple_comparacion_num(<(Limite), Valor) :-
    Valor < Limite.

% =========================================================
% EXPORTACION TSV
% =========================================================

exportar_tsv_ls(Archivo) :-
    open(Archivo, write, Stream, [encoding(utf8)]),
    cabecera_tsv_ls(Cabecera),
    escribir_fila_tsv_ls(Stream, Cabecera),
    findall(N, par_ls_disponible(N), Ns0),
    sort(Ns0, Ns),
    escribir_filas_tsv_ls(Stream, Ns),
    close(Stream),
    write('Archivo TSV lexico-semantico generado: '), write(Archivo), nl.

escribir_filas_tsv_ls(_, []).

escribir_filas_tsv_ls(Stream, [N|Resto]) :-
    once(escribir_fila_par_tsv_ls(Stream, N)),
    escribir_filas_tsv_ls(Stream, Resto).

escribir_fila_par_tsv_ls(Stream, N) :-
    resultado_ls_gpt(N, TextoGPT0, RGPT),
    resultado_ls_claude(N, TextoClaude0, RClaude),
    comparacion_ls(N, Comparacion),
    limpiar_texto_tsv_ls(TextoGPT0, TextoGPT),
    limpiar_texto_tsv_ls(TextoClaude0, TextoClaude),
    valores_resultado_tsv_ls(RGPT, gpt, ValoresGPT),
    valores_resultado_tsv_ls(RClaude, claude, ValoresClaude),
    intercalar_por_pares(ValoresGPT, ValoresClaude, ValoresResultados),
    valores_dominantes_tsv_ls(RGPT, gpt, DomGPT),
    valores_dominantes_tsv_ls(RClaude, claude, DomClaude),
    intercalar_por_pares(DomGPT, DomClaude, ValoresDominantes),
    valores_comparacion_tsv_ls(Comparacion, ValoresComparacion),
    valores_listas_tsv_ls(RGPT, RClaude, Comparacion, ValoresListas),
    append(
        [[N, TextoGPT, TextoClaude], ValoresResultados, ValoresDominantes,
         ValoresComparacion, ValoresListas],
        Valores
    ),
    escribir_fila_tsv_ls(Stream, Valores).

cabecera_tsv_ls(Cabecera) :-
    metricas_resultado_tsv_ls(Metricas),
    nombres_metricas_corpus_tsv(Metricas, CabeceraMetricas),
    dominantes_tsv_ls(Dominantes),
    nombres_metricas_corpus_tsv(Dominantes, CabeceraDominantes),
    metricas_comparacion_tsv_ls(CabeceraComparacion),
    listas_tsv_ls(CabeceraListas),
    append(
        [[n, texto_gpt, texto_claude], CabeceraMetricas, CabeceraDominantes,
         CabeceraComparacion, CabeceraListas],
        Cabecera
    ).

metricas_resultado_tsv_ls([
    sustantivos-n_sustantivos,
    adjetivos-n_adjetivos,
    determinantes-n_determinantes,
    pronombres-n_pronombres,
    verbos-n_verbos,
    adverbios-n_adverbios,
    preposiciones-n_preposiciones,
    conjunciones-n_conjunciones,
    no_clasificados-n_no_clasificados,
    tokens_total-n_tokens_total,
    ratio_sustantivos-ratio_sustantivos,
    ratio_adjetivos-ratio_adjetivos,
    ratio_verbos-ratio_verbos,
    ratio_adj_sust-ratio_adj_sust,
    ratio_det_sust-ratio_det_sust,
    densidad_lexica-densidad_lexica,
    sust_abstractos-sust_abstractos,
    sust_concretos-sust_concretos,
    sust_colectivos-sust_colectivos,
    sust_contables-sust_contables,
    sust_no_contables-sust_no_contables,
    ratio_abstracto_concreto-ratio_abstracto_concreto,
    adj_calificativos-adj_calificativos,
    adj_relacionales-adj_relacionales,
    adj_positivo-adj_grado_positivo,
    adj_comparativo-adj_grado_comparativo,
    adj_superlativo-adj_grado_superlativo,
    det_art_det-det_articulos_determinados,
    det_art_indet-det_articulos_indeterminados,
    det_demos-det_demostrativos,
    det_poses-det_posesivos,
    det_numer-det_numerales,
    det_indef-det_indefinidos,
    verb_conjugadas-verb_conjugadas,
    verb_infinitivos-verb_infinitivos,
    verb_gerundios-verb_gerundios,
    verb_participios-verb_participios,
    verb_transitivos-verb_transitivos,
    verb_intransitivos-verb_intransitivos,
    verb_copulativos-verb_copulativos,
    verb_predicativos-verb_predicativos,
    verb_auxiliares-verb_auxiliares,
    verb_modales-verb_modales,
    verb_regulares-verb_regulares,
    verb_irregulares-verb_irregulares,
    adv_modo-adv_modo,
    adv_lugar-adv_lugar,
    adv_tiempo-adv_tiempo,
    adv_cantidad-adv_cantidad_grado,
    adv_negacion-adv_negacion,
    adv_conector-adv_conector_discursivo,
    adv_mente-adv_derivados_mente,
    adv_simples-adv_simples,
    conj_coord_cop-conj_coord_copulativas,
    conj_coord_adv-conj_coord_adversativas,
    conj_subord_compl-conj_subord_completivas,
    conj_subord_otras-conj_subord_otras,
    ratio_subord_coord-ratio_subord_coord,
    prep_propias-prep_propias,
    prep_contracciones-prep_contracciones,
    ttr-ttr,
    hapax-hapax,
    long_media_palabra-longitud_media_palabra,
    n_tecnicas-n_tecnicas,
    n_locuciones-n_locuciones,
    sem_ser_vivo-n_sust_ser_vivo,
    sem_ent_robotica-n_sust_entidad_robotica,
    sem_comp_biologico-n_sust_componente_biologico,
    sem_comp_mecanico-n_sust_componente_mecanico,
    sem_instrumento-n_sust_instrumento,
    sem_proceso_nominal-n_sust_proceso_nominal,
    sem_concepto_abstracto-n_sust_concepto_abstracto,
    sem_v_fisica-n_verb_accion_fisica,
    sem_v_biologico-n_verb_proceso_biologico,
    sem_v_tecnica-n_verb_accion_tecnica,
    sem_v_cognitiva-n_verb_accion_cognitiva,
    sem_v_comunicativa-n_verb_accion_comunicativa,
    n_ambiguos-n_ambiguos
]).

dominantes_tsv_ls([
    sust_tipo_dom-sust_significado_dominante,
    adj_tipo_dom-adj_tipo_dominante,
    dominio_sem_dom-dominio_dominante,
    accion_verb_dom-tipo_accion_dominante
]).

metricas_comparacion_tsv_ls([
    jaccard_sustantivos, jaccard_adjetivos, jaccard_verbos,
    jaccard_adverbios, jaccard_global,
    dif_sustantivos, dif_adjetivos, dif_verbos,
    dif_densidad_lexica, dif_ttr, dif_tecnicas, dif_longitud_media,
    mismo_sust_dom, mismo_adj_dom, mismo_dominio_sem
]).

listas_tsv_ls([
    lista_sust_gpt, lista_sust_claude,
    lista_adj_gpt, lista_adj_claude,
    lista_verb_gpt, lista_verb_claude,
    exclusivas_sust_gpt, exclusivas_sust_claude,
    exclusivas_verb_gpt, exclusivas_verb_claude,
    exclusivas_adj_gpt, exclusivas_adj_claude
]).

nombres_metricas_corpus_tsv([], []).

nombres_metricas_corpus_tsv([Nombre-_|Resto], [NombreGPT, NombreClaude|Salida]) :-
    atom_concat(Nombre, '_gpt', NombreGPT),
    atom_concat(Nombre, '_claude', NombreClaude),
    nombres_metricas_corpus_tsv(Resto, Salida).

valores_resultado_tsv_ls(Resultado, _Corpus, Valores) :-
    metricas_resultado_tsv_ls(Metricas),
    valores_metricas_resultado(Resultado, Metricas, Valores).

valores_dominantes_tsv_ls(Resultado, _Corpus, Valores) :-
    dominantes_tsv_ls(Metricas),
    valores_metricas_resultado(Resultado, Metricas, Valores).

valores_metricas_resultado(_, [], []).

valores_metricas_resultado(Resultado, [_Nombre-Metrica|Resto], [Valor|Salida]) :-
    valor_metrica_ls(Resultado, Metrica, Valor),
    valores_metricas_resultado(Resultado, Resto, Salida).

valores_comparacion_tsv_ls(Comparacion, Valores) :-
    metricas_comparacion_tsv_ls(Metricas),
    valores_metricas_comparacion(Comparacion, Metricas, Valores).

valores_metricas_comparacion(_, [], []).

valores_metricas_comparacion(Comparacion, [Metrica|Resto], [Valor|Salida]) :-
    valor_comparacion_ls(Comparacion, Metrica, Valor),
    valores_metricas_comparacion(Comparacion, Resto, Salida).

valores_listas_tsv_ls(RGPT, RClaude, Comparacion, [
    SustGPT, SustClaude,
    AdjGPT, AdjClaude,
    VerbGPT, VerbClaude,
    ESG, ESC,
    EVG, EVC,
    EAG, EAC
]) :-
    valor_resultado_ls(RGPT, lista_sustantivos, SustGPT),
    valor_resultado_ls(RClaude, lista_sustantivos, SustClaude),
    valor_resultado_ls(RGPT, lista_adjetivos, AdjGPT),
    valor_resultado_ls(RClaude, lista_adjetivos, AdjClaude),
    valor_resultado_ls(RGPT, lista_verbos, VerbGPT),
    valor_resultado_ls(RClaude, lista_verbos, VerbClaude),
    valor_comparacion_ls(Comparacion, exclusivas_sust_gpt, ESG),
    valor_comparacion_ls(Comparacion, exclusivas_sust_claude, ESC),
    valor_comparacion_ls(Comparacion, exclusivas_verb_gpt, EVG),
    valor_comparacion_ls(Comparacion, exclusivas_verb_claude, EVC),
    valor_comparacion_ls(Comparacion, exclusivas_adj_gpt, EAG),
    valor_comparacion_ls(Comparacion, exclusivas_adj_claude, EAC).

% =========================================================
% UTILIDADES
% =========================================================

valor_metrica_ls(Resultado, Metrica, Valor) :-
    valor_resultado_ls(Resultado, Metrica, Valor),
    !.

valor_metrica_ls(Resultado, Metrica, Valor) :-
    bloque_submetricas_ls(Bloque),
    valor_submetrica_ls(Resultado, Bloque, Metrica, Valor),
    !.

bloque_submetricas_ls(sub_sustantivos).
bloque_submetricas_ls(sub_adjetivos).
bloque_submetricas_ls(sub_determinantes).
bloque_submetricas_ls(sub_verbos).
bloque_submetricas_ls(sub_adverbios).
bloque_submetricas_ls(sub_preposiciones).
bloque_submetricas_ls(sub_conjunciones).
bloque_submetricas_ls(sem_sustantivos).
bloque_submetricas_ls(sem_verbos).

lista_categoria_resultado(sustantivo, lista_sustantivos).
lista_categoria_resultado(adjetivo, lista_adjetivos).
lista_categoria_resultado(verbo, lista_verbos).
lista_categoria_resultado(adverbio, lista_adverbios).
lista_categoria_resultado(tecnico, lista_tecnicos).

oracion_ls_corpus(gpt, N, Texto) :-
    oracion_gpt(N, Texto).

oracion_ls_corpus(claude, N, Texto) :-
    oracion_claude(N, Texto).

palabras_categoria_texto_ls(tecnico, Texto, Palabras) :-
    !,
    tokenizar_basico(Texto, Tokens),
    findall(Token, (member(Token, Tokens), once(termino_tecnico_normalizado(Token))), Palabras).

palabras_categoria_texto_ls(Categoria, Texto, Palabras) :-
    tokenizar_basico(Texto, Tokens),
    once(clasificar_tokens(Tokens, Clasificados)),
    findall(
        Palabra,
        member(clasificado(Palabra, Categoria, _), Clasificados),
        Palabras
    ),
    !.

unir_listas_lexicas(Listas, Unida) :-
    append(Listas, Todas),
    sort(Todas, Unida).

conjunto_ordenado(Lista, Conjunto) :-
    sort(Lista, Conjunto).

diferencia_conjuntos(ListaA, ListaB, Diferencia) :-
    conjunto_ordenado(ListaA, A),
    conjunto_ordenado(ListaB, B),
    subtract(A, B, Diferencia).

intercalar_por_pares([], [], []).

intercalar_por_pares([A|RestoA], [B|RestoB], [A, B|Salida]) :-
    intercalar_por_pares(RestoA, RestoB, Salida).

media_lista_ls([], 0) :- !.

media_lista_ls(Lista, Media) :-
    sum_list(Lista, Suma),
    length(Lista, N),
    N > 0,
    Media0 is Suma / N,
    redondear4_ls(Media0, Media).

redondear4_ls(Numero, Redondeado) :-
    Redondeado is round(Numero * 10000) / 10000.

frecuencias_ordenadas(Palabras, FrecuenciasOrdenadas) :-
    msort(Palabras, Ordenadas),
    frecuencias_ordenadas_(Ordenadas, Frecuencias0),
    predsort(comparar_frecuencias, Frecuencias0, FrecuenciasOrdenadas).

frecuencias_ordenadas_([], []).

frecuencias_ordenadas_([Palabra|Resto], [Palabra-Frecuencia|Salida]) :-
    consumir_iguales_ls(Palabra, Resto, 1, RestoDistinto, Frecuencia),
    frecuencias_ordenadas_(RestoDistinto, Salida).

consumir_iguales_ls(Palabra, [Palabra|Resto], Acum, RestoDistinto, Frecuencia) :-
    !,
    Acum1 is Acum + 1,
    consumir_iguales_ls(Palabra, Resto, Acum1, RestoDistinto, Frecuencia).

consumir_iguales_ls(_, RestoDistinto, Frecuencia, RestoDistinto, Frecuencia).

comparar_frecuencias(Orden, PalabraA-NA, PalabraB-NB) :-
    (
        NA > NB
    ->  Orden = <
    ;   NA < NB
    ->  Orden = >
    ;   compare(Orden, PalabraA, PalabraB)
    ).

tomar_n(0, _, []) :- !.
tomar_n(_, [], []) :- !.

tomar_n(N, [X|Resto], [X|Salida]) :-
    N > 0,
    N1 is N - 1,
    tomar_n(N1, Resto, Salida).

limpiar_texto_tsv_ls(TextoEntrada, TextoSalida) :-
    string(TextoEntrada),
    !,
    string_codes(TextoEntrada, Codigos),
    limpiar_codigos_tsv_ls(Codigos, Limpios),
    string_codes(TextoSalida, Limpios).

limpiar_texto_tsv_ls(TextoEntrada, TextoSalida) :-
    atom(TextoEntrada),
    atom_string(TextoEntrada, TextoString),
    limpiar_texto_tsv_ls(TextoString, TextoSalida).

limpiar_codigos_tsv_ls([], []).

limpiar_codigos_tsv_ls([9|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv_ls(Resto, Salida).

limpiar_codigos_tsv_ls([10|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv_ls(Resto, Salida).

limpiar_codigos_tsv_ls([13|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv_ls(Resto, Salida).

limpiar_codigos_tsv_ls([C|Resto], [C|Salida]) :-
    limpiar_codigos_tsv_ls(Resto, Salida).

escribir_fila_tsv_ls(Stream, Valores) :-
    escribir_valores_tsv_ls(Stream, Valores),
    nl(Stream).

escribir_valores_tsv_ls(_, []).

escribir_valores_tsv_ls(Stream, [Valor]) :-
    !,
    escribir_valor_tsv_ls(Stream, Valor).

escribir_valores_tsv_ls(Stream, [Valor|Resto]) :-
    escribir_valor_tsv_ls(Stream, Valor),
    put_char(Stream, '\t'),
    escribir_valores_tsv_ls(Stream, Resto).

escribir_valor_tsv_ls(Stream, Valor) :-
    valor_a_campo_tsv_ls(Valor, Campo),
    write(Stream, Campo).

valor_a_campo_tsv_ls(Valor, Campo) :-
    string(Valor),
    !,
    limpiar_texto_tsv_ls(Valor, Campo).

valor_a_campo_tsv_ls(Valor, Campo) :-
    is_list(Valor),
    !,
    lista_a_campo_tsv_ls(Valor, Campo).

valor_a_campo_tsv_ls(Valor, Campo) :-
    atom(Valor),
    !,
    atom_string(Valor, Campo).

valor_a_campo_tsv_ls(Valor, Campo) :-
    number(Valor),
    !,
    term_string(Valor, Campo).

valor_a_campo_tsv_ls(Valor, Campo) :-
    term_string(Valor, Campo).

lista_a_campo_tsv_ls([], "") :- !.

lista_a_campo_tsv_ls(Lista, Campo) :-
    maplist(elemento_lista_a_atom_ls, Lista, Atomos),
    atomic_list_concat(Atomos, ',', Atom),
    atom_string(Atom, Campo).

elemento_lista_a_atom_ls(locucion(Tokens), Atom) :-
    !,
    atomic_list_concat(Tokens, '_', Atom).

elemento_lista_a_atom_ls(Atom, Atom) :-
    atom(Atom),
    !.

elemento_lista_a_atom_ls(Termino, Atom) :-
    term_to_atom(Termino, Atom).
