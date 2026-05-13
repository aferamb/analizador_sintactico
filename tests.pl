:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module(library(time)).

:- consult('main.pl').
:- consult('metricas_lexico_semanticas.pl').
:- consult('comparativo_lexico_semantico.pl').

analisis_timeout(5).

con_tiempo(Goal) :-
    analisis_timeout(Segundos),
    call_with_time_limit(Segundos, once(Goal)).

tipo_corpus(PredicadoCorpus, N, Tipo) :-
    call(PredicadoCorpus, N, Texto),
    con_tiempo(analizar_texto_seguro(Texto, Arbol)),
    tipo_oracion(Arbol, Tipo).

resultado_sintactico_valido(resultado(
    Aceptada, Tipo, Longitud, Comas, Conectores, Relativos, Tecnicos,
    NumSimples, Profundidad, Nodos
)) :-
    memberchk(Aceptada, [si, no]),
    memberchk(Tipo, [o, oc, or, ocm, no_analizada]),
    maplist(entero_no_negativo, [
        Longitud, Comas, Conectores, Relativos, Tecnicos,
        NumSimples, Profundidad, Nodos
    ]).

entero_no_negativo(N) :-
    integer(N),
    N >= 0.

resultado_corpus_valido(PredicadoCorpus, N) :-
    call(PredicadoCorpus, N, Texto),
    con_tiempo(analizar_resultado(Texto, Resultado)),
    resultado_sintactico_valido(Resultado).

:- begin_tests(tokenizacion).

test(normaliza_mayusculas_tildes_y_comas) :-
    once(tokenizar_basico('Presión, Araña.', Tokens)),
    assertion(Tokens == [presion, ',', araña]).

test(mantiene_coma_decimal) :-
    once(tokenizar_basico('0,35 mN', Tokens)),
    assertion(Tokens == ['0.35', mn]).

:- end_tests(tokenizacion).

:- begin_tests(aceptacion).

test(acepta_oracion_corpus_gpt) :-
    oracion_gpt(3, Texto),
    con_tiempo(acepta_texto(Texto)).

test(rechaza_token_fuera_de_lexico, [fail]) :-
    con_tiempo(acepta([token_inexistente, analiza, sistema])).

:- end_tests(aceptacion).

:- begin_tests(corpus_completo).

test(resultado_sintactico_valido_para_todo_gpt) :-
    forall(
        between(1, 50, N),
        resultado_corpus_valido(oracion_gpt, N)
    ).

test(resultado_sintactico_valido_para_todo_claude) :-
    forall(
        between(1, 50, N),
        resultado_corpus_valido(oracion_claude, N)
    ).

:- end_tests(corpus_completo).

:- begin_tests(clasificacion_gpt).

test(gpt_1_simple) :-
    assertion(tipo_corpus(oracion_gpt, 1, o)).

test(gpt_2_coordinada) :-
    assertion(tipo_corpus(oracion_gpt, 2, oc)).

test(gpt_3_simple) :-
    assertion(tipo_corpus(oracion_gpt, 3, o)).

test(gpt_12_mixta) :-
    assertion(tipo_corpus(oracion_gpt, 12, ocm)).

test(gpt_18_coordinada) :-
    assertion(tipo_corpus(oracion_gpt, 18, oc)).

test(gpt_26_mixta) :-
    assertion(tipo_corpus(oracion_gpt, 26, ocm)).

test(gpt_48_relativa) :-
    assertion(tipo_corpus(oracion_gpt, 48, or)).

:- end_tests(clasificacion_gpt).

:- begin_tests(clasificacion_claude).

test(claude_1_simple) :-
    assertion(tipo_corpus(oracion_claude, 1, o)).

test(claude_2_coordinada) :-
    assertion(tipo_corpus(oracion_claude, 2, oc)).

test(claude_3_simple) :-
    assertion(tipo_corpus(oracion_claude, 3, o)).

test(claude_12_mixta) :-
    assertion(tipo_corpus(oracion_claude, 12, ocm)).

test(claude_18_coordinada) :-
    assertion(tipo_corpus(oracion_claude, 18, oc)).

test(claude_26_mixta) :-
    assertion(tipo_corpus(oracion_claude, 26, ocm)).

test(claude_48_relativa) :-
    assertion(tipo_corpus(oracion_claude, 48, or)).

:- end_tests(clasificacion_claude).

:- begin_tests(simplificacion).

test(oracion_simple_gpt_genera_una_simple) :-
    oracion_gpt(3, Texto),
    con_tiempo(simplificar_texto(Texto, Simples)),
    assertion(Simples = [_]).

test(arbol_coordinado_genera_dos_simples) :-
    Arbol = oc(
        o(gn(n(a)), gv(v(b))),
        conj(y),
        o(gn(n(c)), gv(v(d)))
    ),
    simplificar(Arbol, Simples),
    assertion(Simples == [
        o(gn(n(a)), gv(v(b))),
        o(gn(n(c)), gv(v(d)))
    ]).

:- end_tests(simplificacion).

:- begin_tests(deteccion_semantica).

test(clasifica_oracion_correcta) :-
    oracion_claude(1, Texto),
    clasificar_oracion(Texto, Clase, Info),
    assertion(Clase == correcta),
    assertion(Info = correcta(_)).

test(clasifica_oracion_ambigua) :-
    oracion_gpt(1, Texto),
    clasificar_oracion(Texto, Clase, Info),
    assertion(Clase == ambigua),
    assertion(memberchk(pinza-[entidad_robotica, instrumento], Info)).

test(clasifica_oracion_incoherente_como_problematica) :-
    oracion_gpt(7, Texto),
    clasificar_oracion(Texto, ClaseInterna, Info),
    clasificar_oracion_enunciado(Texto, ClaseEnunciado),
    assertion(ClaseInterna == incoherente),
    assertion(Info = incoherencia(_, Pares)),
    assertion(memberchk(araña-reutiliza, Pares)),
    assertion(ClaseEnunciado == problematica).

test(clasifica_uso_no_literal_como_problematica) :-
    oracion_gpt(33, Texto),
    clasificar_oracion(Texto, ClaseInterna, Info),
    clasificar_oracion_enunciado(Texto, ClaseEnunciado),
    assertion(ClaseInterna == no_literal),
    assertion(Info = no_literal(_, Pares)),
    assertion(memberchk(pinza-biodegrada, Pares)),
    assertion(ClaseEnunciado == problematica).

test(clasifica_texto_no_analizable) :-
    clasificar_oracion('zzzz yyyy', Clase, Info),
    clasificar_oracion_enunciado('zzzz yyyy', ClaseEnunciado),
    assertion(Clase == no_analizable),
    assertion(Info == no_analizable('zzzz yyyy')),
    assertion(ClaseEnunciado == no_analizable).

:- end_tests(deteccion_semantica).

:- begin_tests(metricas_lexico_semanticas).

test(detecta_locucion_sin_embargo) :-
    detectar_locuciones([sin, embargo, la, pinza], Tokens),
    assertion(Tokens = [locucion([sin, embargo], adverbio, _), la, pinza]).

test(clasifica_todas_las_clases_ambiguas) :-
    clasificar_tokens([la, que], Clasificados),
    findall(ClaseLa, member(clasificado(la, ClaseLa, _), Clasificados), La0),
    findall(ClaseQue, member(clasificado(que, ClaseQue, _), Clasificados), Que0),
    sort(La0, La),
    sort(Que0, Que),
    assertion(La == [determinante, pronombre]),
    assertion(Que == [conjuncion, pronombre]).

test(oracion_plan_metricas_basicas) :-
    analizar_lexico_semantico(
        "La pinza necrobótica es capaz de agarrar objetos.",
        Resultado
    ),
    valor_resultado_ls(Resultado, n_tokens_total, NTokens),
    valor_resultado_ls(Resultado, n_tecnicas, NTecnicas),
    valor_resultado_ls(Resultado, lista_tecnicos, Tecnicos),
    valor_resultado_ls(Resultado, dominio_dominante, Dominio),
    valor_submetrica_ls(Resultado, sub_verbos, verb_infinitivos, Infinitivos),
    assertion(NTokens == 8),
    assertion(NTecnicas == 2),
    assertion(Tecnicos == [necrobotica, pinza]),
    assertion(Dominio == entidad_robotica),
    assertion(Infinitivos == 1).

test(cuenta_no_clasificados_sin_contar_comas) :-
    analizar_lexico_semantico("La pinza, 0,35.", Resultado),
    valor_resultado_ls(Resultado, n_tokens_total, NTokens),
    valor_resultado_ls(Resultado, n_no_clasificados, NNoClasificados),
    assertion(NTokens == 3),
    assertion(NNoClasificados == 1).

test(analiza_oracion_real_gpt) :-
    oracion_gpt(1, Texto),
    con_tiempo(analizar_lexico_semantico(Texto, Resultado)),
    valor_resultado_ls(Resultado, n_tokens_total, NTokens),
    assertion(NTokens > 0).

test(analiza_oracion_real_claude) :-
    oracion_claude(1, Texto),
    con_tiempo(analizar_lexico_semantico(Texto, Resultado)),
    valor_resultado_ls(Resultado, n_tokens_total, NTokens),
    assertion(NTokens > 0).

:- end_tests(metricas_lexico_semanticas).

:- begin_tests(comparativo_sintactico).

test(comparacion_resultados_casos_base) :-
    RGPT = resultado(si, o, 12, 1, 2, 0, 1, 1, 4, 15),
    RClaude = resultado(no, no_analizada, 7, 0, 0, 0, 0, 0, 0, 0),
    comparacion_resultados(RGPT, RClaude, Comparacion),
    assertion(Comparacion == comparacion(no, si, no, no, no, 5)).

test(resultado_sintactico_por_corpus) :-
    resultado_gpt(1, TextoGPT, RGPT),
    resultado_claude(1, TextoClaude, RClaude),
    once(sub_string(TextoGPT, _, _, _, "pinza")),
    once(sub_string(TextoClaude, _, _, _, "efector")),
    resultado_sintactico_valido(RGPT),
    resultado_sintactico_valido(RClaude).

test(exportar_tsv_temporal) :-
    tmp_file_stream(text, Archivo, Stream),
    close(Stream),
    setup_call_cleanup(
        true,
        (
            with_output_to(string(_), exportar_tsv(Archivo)),
            read_file_to_string(Archivo, Contenido, []),
            split_string(Contenido, "\n", "\n", Lineas),
            Lineas = [Cabecera|_],
            length(Lineas, NLineas),
            assertion(NLineas == 51),
            assertion(sub_string(Cabecera, _, _, _, "acepta_gpt")),
            assertion(sub_string(Cabecera, _, _, _, "acepta_claude")),
            assertion(sub_string(Cabecera, _, _, _, "tipo_gpt")),
            assertion(sub_string(Cabecera, _, _, _, "tipo_claude")),
            assertion(sub_string(Cabecera, _, _, _, "dif_long_gpt_menos_claude"))
        ),
        borrar_si_existe(Archivo)
    ).

:- end_tests(comparativo_sintactico).

:- begin_tests(comparativo_lexico_semantico).

test(resultado_ls_por_corpus) :-
    resultado_ls_gpt(1, TextoGPT, RGPT),
    resultado_ls_claude(1, TextoClaude, RClaude),
    once(sub_string(TextoGPT, _, _, _, "pinza")),
    once(sub_string(TextoClaude, _, _, _, "efector")),
    valor_resultado_ls(RGPT, n_tokens_total, TokensGPT),
    valor_resultado_ls(RClaude, n_tokens_total, TokensClaude),
    assertion(TokensGPT > 0),
    assertion(TokensClaude > 0).

test(jaccard_casos_base) :-
    jaccard_ls([a, b], [b, c], J1),
    jaccard_ls([], [], J2),
    jaccard_ls([], [a], J3),
    assertion(J1 == 0.3333),
    assertion(J2 == 1),
    assertion(J3 == 0).

test(comparacion_par_1_exclusivas) :-
    comparacion_ls(1, Comparacion),
    valor_comparacion_ls(Comparacion, jaccard_global, JGlobal),
    valor_comparacion_ls(Comparacion, exclusivas_sust_gpt, SustGPT),
    valor_comparacion_ls(Comparacion, exclusivas_sust_claude, SustClaude),
    valor_comparacion_ls(Comparacion, interesante, Interesante),
    assertion(JGlobal > 0),
    assertion(memberchk(pinza, SustGPT)),
    assertion(memberchk(efector, SustClaude)),
    assertion(Interesante == si).

test(sustituciones_lexicas_por_combinaciones) :-
    comparacion_ls(1, Comparacion),
    valor_comparacion_ls(Comparacion, sustituciones, Sustituciones),
    assertion(memberchk(sustitucion(1, sustantivo, pinza, efector), Sustituciones)),
    assertion(memberchk(sustitucion(1, tecnico, pinza, efector), Sustituciones)).

test(top_palabras_usa_frecuencia_absoluta) :-
    top_palabras_ls(gpt, sustantivo, 3, Top),
    assertion(memberchk(araña-25, Top)),
    assertion(memberchk(pinza-23, Top)).

test(exportar_tsv_ls_temporal) :-
    tmp_file_stream(text, Archivo, Stream),
    close(Stream),
    setup_call_cleanup(
        true,
        (
            with_output_to(string(_), exportar_tsv_ls(Archivo)),
            read_file_to_string(Archivo, Contenido, []),
            split_string(Contenido, "\n", "\n", Lineas),
            Lineas = [Cabecera|_],
            length(Lineas, NLineas),
            assertion(NLineas == 51),
            assertion(sub_string(Cabecera, _, _, _, "jaccard_global")),
            assertion(sub_string(Cabecera, _, _, _, "lista_sust_gpt")),
            assertion(sub_string(Cabecera, _, _, _, "lista_adv_gpt")),
            assertion(sub_string(Cabecera, _, _, _, "lista_tecnicos_gpt")),
            assertion(sub_string(Cabecera, _, _, _, "exclusivas_tecnicas_gpt"))
        ),
        borrar_si_existe(Archivo)
    ).

test(resumen_lexico_semantico_ejecuta) :-
    with_output_to(string(Salida), resumen_lexico_semantico),
    assertion(sub_string(Salida, _, _, _, "RESUMEN LEXICO-SEMANTICO")).

:- end_tests(comparativo_lexico_semantico).

borrar_si_existe(Archivo) :-
    exists_file(Archivo),
    !,
    delete_file(Archivo).

borrar_si_existe(_).
