% comparativo.pl
% Comparación automática entre corpus GPT y corpus Claude.

:- encoding(utf8).

% =========================================================
% ANALISIS POR CORPUS
% =========================================================

resultado_gpt(N, Texto, Resultado) :-
    obtener_oracion_gpt(N, Texto),
    once(analizar_resultado(Texto, Resultado)).

resultado_claude(N, Texto, Resultado) :-
    obtener_oracion_claude(N, Texto),
    once(analizar_resultado(Texto, Resultado)).

obtener_oracion_gpt(N, Texto) :-
    nonvar(N),
    !,
    once(oracion_gpt(N, Texto)).

obtener_oracion_gpt(N, Texto) :-
    oracion_gpt(N, Texto).

obtener_oracion_claude(N, Texto) :-
    nonvar(N),
    !,
    once(oracion_claude(N, Texto)).

obtener_oracion_claude(N, Texto) :-
    oracion_claude(N, Texto).

% =========================================================
% COMPARACION INDIVIDUAL
% =========================================================

% ---------------------------------------------------------
% comparar(+N)
% Muestra por pantalla la comparación de la frase N.
% ---------------------------------------------------------

comparar(N) :-
    resultado_gpt(N, TextoGPT, RGPT),
    resultado_claude(N, TextoClaude, RClaude),
    comparacion_resultados(RGPT, RClaude, Comp),
    nl,
    write('================================================='), nl,
    write('PAR '), write(N), nl,
    write('================================================='), nl,
    nl,
    write('GPT:'), nl,
    write(TextoGPT), nl,
    imprimir_resultado(RGPT),
    nl,
    write('CLAUDE:'), nl,
    write(TextoClaude), nl,
    imprimir_resultado(RClaude),
    nl,
    write('COMPARACION:'), nl,
    imprimir_comparacion(Comp),
    nl.

imprimir_resultado(resultado(Aceptada, Tipo, Longitud, Comas, Conectores, Relativos, Tecnicos, NumSimples, Profundidad, Nodos)) :-
    write('  Aceptada: '), write(Aceptada), nl,
    write('  Tipo: '), write(Tipo), nl,
    write('  Longitud tokens: '), write(Longitud), nl,
    write('  Comas: '), write(Comas), nl,
    write('  Conectores: '), write(Conectores), nl,
    write('  Relativos: '), write(Relativos), nl,
    write('  Terminos tecnicos: '), write(Tecnicos), nl,
    write('  Oraciones simples tras simplificar: '), write(NumSimples), nl,
    write('  Profundidad arbol: '), write(Profundidad), nl,
    write('  Nodos arbol: '), write(Nodos), nl.

imprimir_comparacion(comparacion(AmbasAceptadas, SoloGPT, SoloClaude, Ninguna, MismoTipo, DiferenciaLongitud)) :-
    write('  Ambas aceptadas: '), write(AmbasAceptadas), nl,
    write('  Solo GPT aceptada: '), write(SoloGPT), nl,
    write('  Solo Claude aceptada: '), write(SoloClaude), nl,
    write('  Ninguna aceptada: '), write(Ninguna), nl,
    write('  Mismo tipo: '), write(MismoTipo), nl,
    write('  Diferencia longitud GPT-Claude: '), write(DiferenciaLongitud), nl.

% ---------------------------------------------------------
% comparacion_resultados(+RGPT, +RClaude, -Comparacion)
% ---------------------------------------------------------

comparacion_resultados(
    resultado(AceptaGPT, TipoGPT, LongGPT, _, _, _, _, _, _, _),
    resultado(AceptaClaude, TipoClaude, LongClaude, _, _, _, _, _, _, _),
    comparacion(AmbasAceptadas, SoloGPT, SoloClaude, Ninguna, MismoTipo, DiferenciaLongitud)
) :-
    valor_ambas_aceptadas(AceptaGPT, AceptaClaude, AmbasAceptadas),
    valor_solo_gpt(AceptaGPT, AceptaClaude, SoloGPT),
    valor_solo_claude(AceptaGPT, AceptaClaude, SoloClaude),
    valor_ninguna(AceptaGPT, AceptaClaude, Ninguna),
    valor_mismo_tipo(TipoGPT, TipoClaude, MismoTipo),
    DiferenciaLongitud is LongGPT - LongClaude.

valor_ambas_aceptadas(si, si, si) :- !.
valor_ambas_aceptadas(_, _, no).

valor_solo_gpt(si, no, si) :- !.
valor_solo_gpt(_, _, no).

valor_solo_claude(no, si, si) :- !.
valor_solo_claude(_, _, no).

valor_ninguna(no, no, si) :- !.
valor_ninguna(_, _, no).

valor_mismo_tipo(Tipo, Tipo, si) :- !.
valor_mismo_tipo(_, _, no).

% =========================================================
% COMPARACION DE TODOS LOS PARES
% =========================================================

comparar_todos :-
    findall(N, par_disponible(N), Ns0),
    sort(Ns0, Ns),
    comparar_lista(Ns).

comparar_lista([]).

comparar_lista([N|Resto]) :-
    nl,
    write('>>> Analizando par '), write(N), write('...'), nl,
    flush_output,
    (
        catch(
            call_with_time_limit(60, once(comparar(N))),
            time_limit_exceeded,
            (
                write('*** Par '), write(N),
                write(' omitido por timeout.'), nl
            )
        )
    ->
        true
    ;
        write('*** Par '), write(N),
        write(' falló sin resultado.'), nl
    ),
    comparar_lista(Resto).

par_disponible(N) :-
    oracion_gpt(N, _),
    oracion_claude(N, _).

% =========================================================
% RESUMEN GLOBAL
% =========================================================

resumen_comparativo :-
    findall(N, par_disponible(N), Ns),
    length(Ns, Total),

    contar_aceptadas(gpt, AceptadasGPT),
    contar_aceptadas(claude, AceptadasClaude),

    porcentaje(AceptadasGPT, Total, PorcGPT),
    porcentaje(AceptadasClaude, Total, PorcClaude),

    media_metrica(gpt, longitud, MediaLongGPT),
    media_metrica(claude, longitud, MediaLongClaude),

    media_metrica(gpt, comas, MediaComasGPT),
    media_metrica(claude, comas, MediaComasClaude),

    media_metrica(gpt, conectores, MediaConGPT),
    media_metrica(claude, conectores, MediaConClaude),

    media_metrica(gpt, relativos, MediaRelGPT),
    media_metrica(claude, relativos, MediaRelClaude),

    media_metrica(gpt, tecnicos, MediaTecGPT),
    media_metrica(claude, tecnicos, MediaTecClaude),

    contar_pares(ambas_aceptadas, Ambas),
    contar_pares(solo_gpt, SoloGPT),
    contar_pares(solo_claude, SoloClaude),
    contar_pares(ninguna, Ninguna),
    contar_pares(mismo_tipo, MismoTipo),

    nl,
    write('================ RESUMEN COMPARATIVO ================'), nl,
    write('Total de pares: '), write(Total), nl,
    nl,

    write('--- Aceptacion sintactica ---'), nl,
    write('GPT aceptadas: '), write(AceptadasGPT), write(' / '), write(Total), write(' ('), write(PorcGPT), write(' %)'), nl,
    write('Claude aceptadas: '), write(AceptadasClaude), write(' / '), write(Total), write(' ('), write(PorcClaude), write(' %)'), nl,
    nl,

    write('--- Comparacion por pares ---'), nl,
    write('Ambas aceptadas: '), write(Ambas), nl,
    write('Solo GPT aceptada: '), write(SoloGPT), nl,
    write('Solo Claude aceptada: '), write(SoloClaude), nl,
    write('Ninguna aceptada: '), write(Ninguna), nl,
    write('Mismo tipo sintactico: '), write(MismoTipo), nl,
    nl,

    write('--- Medias ---'), nl,
    write('Longitud media GPT: '), write(MediaLongGPT), nl,
    write('Longitud media Claude: '), write(MediaLongClaude), nl,
    write('Comas medias GPT: '), write(MediaComasGPT), nl,
    write('Comas medias Claude: '), write(MediaComasClaude), nl,
    write('Conectores medios GPT: '), write(MediaConGPT), nl,
    write('Conectores medios Claude: '), write(MediaConClaude), nl,
    write('Relativos medios GPT: '), write(MediaRelGPT), nl,
    write('Relativos medios Claude: '), write(MediaRelClaude), nl,
    write('Terminos tecnicos medios GPT: '), write(MediaTecGPT), nl,
    write('Terminos tecnicos medios Claude: '), write(MediaTecClaude), nl,
    nl,

    write('--- Distribucion de tipos GPT ---'), nl,
    imprimir_distribucion_tipos(gpt),
    nl,
    write('--- Distribucion de tipos Claude ---'), nl,
    imprimir_distribucion_tipos(claude),
    nl.

% ---------------------------------------------------------
% contar_aceptadas(+Corpus, -N)
% ---------------------------------------------------------

contar_aceptadas(Corpus, N) :-
    findall(
        1,
        (
            resultado_corpus(Corpus, _, _, resultado(si, _, _, _, _, _, _, _, _, _))
        ),
        Lista
    ),
    length(Lista, N).

% ---------------------------------------------------------
% resultado_corpus(+Corpus, -N, -Texto, -Resultado)
% ---------------------------------------------------------

resultado_corpus(gpt, N, Texto, Resultado) :-
    resultado_gpt(N, Texto, Resultado).

resultado_corpus(claude, N, Texto, Resultado) :-
    resultado_claude(N, Texto, Resultado).

% ---------------------------------------------------------
% porcentaje(+Parte, +Total, -PorcentajeRedondeado)
% ---------------------------------------------------------

porcentaje(_, 0, 0) :- !.

porcentaje(Parte, Total, PorcentajeRedondeado) :-
    Porcentaje is (Parte * 100.0) / Total,
    redondear2(Porcentaje, PorcentajeRedondeado).

redondear2(X, R) :-
    R is round(X * 100) / 100.

% ---------------------------------------------------------
% media_metrica(+Corpus, +Metrica, -Media)
% ---------------------------------------------------------

media_metrica(Corpus, Metrica, Media) :-
    findall(
        Valor,
        (
            resultado_corpus(Corpus, _, _, Resultado),
            valor_metrica(Resultado, Metrica, Valor)
        ),
        Valores
    ),
    media_lista(Valores, Media).

valor_metrica(resultado(_, _, Longitud, _, _, _, _, _, _, _), longitud, Longitud).
valor_metrica(resultado(_, _, _, Comas, _, _, _, _, _, _), comas, Comas).
valor_metrica(resultado(_, _, _, _, Conectores, _, _, _, _, _), conectores, Conectores).
valor_metrica(resultado(_, _, _, _, _, Relativos, _, _, _, _), relativos, Relativos).
valor_metrica(resultado(_, _, _, _, _, _, Tecnicos, _, _, _), tecnicos, Tecnicos).
valor_metrica(resultado(_, _, _, _, _, _, _, Simples, _, _), simples, Simples).
valor_metrica(resultado(_, _, _, _, _, _, _, _, Profundidad, _), profundidad, Profundidad).
valor_metrica(resultado(_, _, _, _, _, _, _, _, _, Nodos), nodos, Nodos).

media_lista([], 0).

media_lista(Lista, MediaRedondeada) :-
    sum_list(Lista, Suma),
    length(Lista, N),
    N > 0,
    Media is Suma / N,
    redondear2(Media, MediaRedondeada).

% ---------------------------------------------------------
% contar_pares(+TipoConteo, -N)
% ---------------------------------------------------------

contar_pares(TipoConteo, N) :-
    findall(
        1,
        (
            par_disponible(Num),
            resultado_gpt(Num, _, RGPT),
            resultado_claude(Num, _, RClaude),
            comparacion_resultados(RGPT, RClaude, Comparacion),
            cumple_comparacion(TipoConteo, Comparacion)
        ),
        Lista
    ),
    length(Lista, N).

cumple_comparacion(ambas_aceptadas, comparacion(si, _, _, _, _, _)).
cumple_comparacion(solo_gpt, comparacion(_, si, _, _, _, _)).
cumple_comparacion(solo_claude, comparacion(_, _, si, _, _, _)).
cumple_comparacion(ninguna, comparacion(_, _, _, si, _, _)).
cumple_comparacion(mismo_tipo, comparacion(_, _, _, _, si, _)).

% ---------------------------------------------------------
% Distribucion de tipos
% ---------------------------------------------------------

imprimir_distribucion_tipos(Corpus) :-
    contar_tipo(Corpus, o, NO),
    contar_tipo(Corpus, oc, NOC),
    contar_tipo(Corpus, or, NOR),
    contar_tipo(Corpus, ocm, NOCM),
    contar_tipo(Corpus, no_analizada, NNO),
    write('o: '), write(NO), nl,
    write('oc: '), write(NOC), nl,
    write('or: '), write(NOR), nl,
    write('ocm: '), write(NOCM), nl,
    write('no_analizada: '), write(NNO), nl.

contar_tipo(Corpus, Tipo, N) :-
    findall(
        1,
        (
            resultado_corpus(Corpus, _, _, resultado(_, Tipo, _, _, _, _, _, _, _, _))
        ),
        Lista
    ),
    length(Lista, N).

% =========================================================
% EXPORTACION TSV
% =========================================================

% ---------------------------------------------------------
% exportar_tsv(+Archivo)
%
% Ejemplo:
%   ?- exportar_tsv('resultados_comparacion.tsv').
% ---------------------------------------------------------

exportar_tsv(Archivo) :-
    open(Archivo, write, Stream, [encoding(utf8)]),
    escribir_cabecera_tsv(Stream),
    findall(N, par_disponible(N), Ns0),
    sort(Ns0, Ns),
    escribir_filas_tsv(Stream, Ns),
    close(Stream),
    write('Archivo TSV generado: '), write(Archivo), nl.

escribir_filas_tsv(_, []).

escribir_filas_tsv(Stream, [N|Resto]) :-
    once(escribir_fila_tsv(Stream, N)),
    escribir_filas_tsv(Stream, Resto).

escribir_cabecera_tsv(Stream) :-
    writeln(Stream, 'n\ttexto_gpt\ttexto_claude\tacepta_gpt\tacepta_claude\ttipo_gpt\ttipo_claude\tmismo_tipo\tlong_gpt\tlong_claude\tdif_long_gpt_menos_claude\tcomas_gpt\tcomas_claude\tconectores_gpt\tconectores_claude\trelativos_gpt\trelativos_claude\ttecnicos_gpt\ttecnicos_claude\tsimples_gpt\tsimples_claude\tprofundidad_gpt\tprofundidad_claude\tnodos_gpt\tnodos_claude').

escribir_fila_tsv(Stream, N) :-
    resultado_gpt(N, TextoGPT0, resultado(AceptaGPT, TipoGPT, LongGPT, ComasGPT, ConGPT, RelGPT, TecGPT, SimplesGPT, ProfGPT, NodosGPT)),
    resultado_claude(N, TextoClaude0, resultado(AceptaClaude, TipoClaude, LongClaude, ComasClaude, ConClaude, RelClaude, TecClaude, SimplesClaude, ProfClaude, NodosClaude)),
    valor_mismo_tipo(TipoGPT, TipoClaude, MismoTipo),
    DifLong is LongGPT - LongClaude,
    limpiar_texto_tsv(TextoGPT0, TextoGPT),
    limpiar_texto_tsv(TextoClaude0, TextoClaude),
    format(
        Stream,
        '~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w\t~w~n',
        [
            N,
            TextoGPT,
            TextoClaude,
            AceptaGPT,
            AceptaClaude,
            TipoGPT,
            TipoClaude,
            MismoTipo,
            LongGPT,
            LongClaude,
            DifLong,
            ComasGPT,
            ComasClaude,
            ConGPT,
            ConClaude,
            RelGPT,
            RelClaude,
            TecGPT,
            TecClaude,
            SimplesGPT,
            SimplesClaude,
            ProfGPT,
            ProfClaude,
            NodosGPT,
            NodosClaude
        ]
    ).

% ---------------------------------------------------------
% limpiar_texto_tsv(+TextoEntrada, -TextoSalida)
% Quita tabuladores y saltos de línea para no romper el TSV.
% ---------------------------------------------------------

limpiar_texto_tsv(TextoEntrada, TextoSalida) :-
    string_codes(TextoEntrada, Codigos),
    limpiar_codigos_tsv(Codigos, Limpios),
    string_codes(TextoSalida, Limpios).

limpiar_codigos_tsv([], []).

limpiar_codigos_tsv([9|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv(Resto, Salida).

limpiar_codigos_tsv([10|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv(Resto, Salida).

limpiar_codigos_tsv([13|Resto], [32|Salida]) :-
    !,
    limpiar_codigos_tsv(Resto, Salida).

limpiar_codigos_tsv([C|Resto], [C|Salida]) :-
    limpiar_codigos_tsv(Resto, Salida).
