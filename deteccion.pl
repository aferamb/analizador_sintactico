:- encoding(utf8).
:- use_module(library(apply)).
:- use_module(library(lists)).

% deteccion.pl
% Módulo de detección de problemas de interpretación (Apartado 2.3).
% Detecta:
%   2.3.1 - Ambigüedad léxica
%   2.3.2 - Incoherencia semántica
%   2.3.3 - Uso no literal o metafórico

% =========================================================
% AUXILIAR: ANÁLISIS SINTÁCTICO SEGURO

% analisis_seguro(+Texto, -Arbol)
% Intenta analizar el texto sin lanzar excepciones.
analisis_seguro(Texto, Arbol) :-
    catch(analizar_texto(Texto, Arbol), _, fail), !.

% =========================================================
% AUXILIARES: IDENTIFICACIÓN Y NAVEGACIÓN DEL ÁRBOL

% Comprueba si un término es un Grupo Nominal
es_grupo_nominal(T) :- compound(T), functor(T, g_nominal, _).
es_grupo_nominal(T) :- compound(T), functor(T, gn_lista, _).

% Comprueba si un término es un Grupo Verbal
es_grupo_verbal(T) :- compound(T), functor(T, g_verbal, _).
es_grupo_verbal(T) :- compound(T), functor(T, gv_coord, _).

% nucleo_nominal(+GN, -Atomo)
% Busca el primer n(Atomo) en el subárbol del grupo nominal.
nucleo_nominal(GN, Atomo) :-
    sub_term(n(Atomo), GN),
    atom(Atomo), !.

% nucleo_verbal(+GV, -Atomo)
% Busca el primer verbo finito, copulativo, infinitivo o impersonal en el GV.
nucleo_verbal(GV, Atomo) :-
    sub_term(v(Atomo),   GV), atom(Atomo), !.
nucleo_verbal(GV, Atomo) :-
    sub_term(vc(Atomo),  GV), atom(Atomo), !.
nucleo_verbal(GV, Atomo) :-
    sub_term(inf(Atomo), GV), atom(Atomo), !.
nucleo_verbal(GV, Atomo) :-
    sub_term(vi(Atomo),  GV), atom(Atomo), !.

% =========================================================
% EXTRACCIÓN DE PARES SUJETO–VERBO DEL ÁRBOL SINTÁCTICO

% extraer_pares(+Arbol, -Pares)
% Recorre todo el árbol y devuelve todos los pares Sujeto-Verbo,
% sin repeticiones.
extraer_pares(Arbol, Pares) :-
    findall(S-V, extraer_par(Arbol, S, V), Pares0),
    sort(Pares0, Pares).

% extraer_par(+Arbol, -Sujeto, -Verbo)
% Desciende por el árbol (incluyendo subordinadas) buscando nodos o/or.
extraer_par(Arbol, Sujeto, Verbo) :-
    sub_term(SubNodo, Arbol),
    extraer_par_nodo(SubNodo, Sujeto, Verbo).

% extraer_par_nodo(+Nodo, -Sujeto, -Verbo)
% Maneja todos los patrones de nodo o(...) usando =.. para desempaquetar
% los argumentos, localizar el GV y el GN (o la marca de sujeto elíptico).
extraer_par_nodo(Nodo, Sujeto, Verbo) :-
    compound(Nodo),
    functor(Nodo, o, _),
    Nodo =.. [o | Args],
    member(GV, Args),
    es_grupo_verbal(GV),
    (   member(GN, Args), es_grupo_nominal(GN)
    ->  nucleo_nominal(GN, Sujeto)
    ;   member(sujeto_eliptico, Args)
    ->  Sujeto = eliptico
    ;   Sujeto = impersonal
    ),
    nucleo_verbal(GV, Verbo).

% Oraciones de relativo: or(GN, Rel, GV)
extraer_par_nodo(or(GN, _Rel, GV), Sujeto, Verbo) :-
    es_grupo_nominal(GN),
    es_grupo_verbal(GV),
    nucleo_nominal(GN, Sujeto),
    nucleo_verbal(GV, Verbo).


% =========================================================
% 2.3.1 DETECCIÓN DE AMBIGÜEDAD LÉXICA

% palabras_ambiguas(+Texto, -Ambiguas)
% Devuelve la lista de tokens del texto que tienen más de un tipo semántico
% registrado en semantico.pl.
palabras_ambiguas(Texto, Ambiguas) :-
    tokenizar_basico(Texto, Tokens),
    include(es_ambiguo, Tokens, Ambiguas).

% tiene_ambiguedad(+Texto, -Info)
% Tiene éxito si el texto contiene palabras léxicamente ambiguas.
% Info es una lista de pares Palabra-[Tipo1,Tipo2,...].
tiene_ambiguedad(Texto, Info) :-
    palabras_ambiguas(Texto, Ambiguas),
    Ambiguas \= [],
    maplist(info_ambiguedad, Ambiguas, Info).

info_ambiguedad(Palabra, Palabra-Tipos) :-
    tipos_de(Palabra, Tipos).


% =========================================================
% 2.3.2 DETECCIÓN DE INCOHERENCIA SEMÁNTICA

% par_incoherente(+Sujeto, +Verbo)
% Hay incoherencia semántica si:
%   - la palabra tiene tipo registrado como sustantivo,
%   - el verbo tiene tipo registrado,
%   - no existe ningún par de tipos compatible, y
%   - el problema no es de uso no literal (que tiene su propia categoría).
par_incoherente(Sujeto, Verbo) :-
    tipo(Sujeto, _),
    tipo_verbo(Verbo, _),
    \+ compatibles_sujeto_verbo(Sujeto, Verbo),
    \+ par_no_literal(Sujeto, Verbo).

% tiene_incoherencia(+Texto, +Arbol, -Info)
% Detecta todos los pares sujeto-verbo incoherentes del árbol.
tiene_incoherencia(Texto, Arbol, incoherencia(Texto, Pares)) :-
    extraer_pares(Arbol, TodosPares),
    include(par_incoherente_wrap, TodosPares, Pares),
    Pares \= [].

par_incoherente_wrap(S-V) :- par_incoherente(S, V).


% =========================================================
% 2.3.3 DETECCIÓN DE USO NO LITERAL / METAFÓRICO

% Tipos de sujeto que representan entidades inanimadas o artificiales.
% Si estas entidades usan verbos de agente animado, el uso es no literal.
tipo_sujeto_inanimado(entidad_robotica).
tipo_sujeto_inanimado(componente_mecanico).
tipo_sujeto_inanimado(instrumento).
tipo_sujeto_inanimado(objeto_fisico).
tipo_sujeto_inanimado(material_sintetico).
tipo_sujeto_inanimado(sustancia).

% Tipos de acción que en sentido literal requieren un agente animado.
tipo_verbo_para_animados(accion_fisica).
tipo_verbo_para_animados(proceso_biologico).
tipo_verbo_para_animados(accion_cognitiva).
tipo_verbo_para_animados(accion_comunicativa).

% par_no_literal(+Sujeto, +Verbo)
% El sujeto es inanimado/artificial y realiza una acción propia de animados,
% lo que sugiere uso metafórico o no literal en el texto científico.
par_no_literal(Sujeto, Verbo) :-
    tipo(Sujeto, TipoS),
    tipo_sujeto_inanimado(TipoS),
    tipo_verbo(Verbo, TipoV),
    tipo_verbo_para_animados(TipoV),
    \+ compatibles_sujeto_verbo(Sujeto, Verbo).

% tiene_uso_no_literal(+Texto, +Arbol, -Info)
tiene_uso_no_literal(Texto, Arbol, no_literal(Texto, Pares)) :-
    extraer_pares(Arbol, TodosPares),
    include(par_no_literal_wrap, TodosPares, Pares),
    Pares \= [].

par_no_literal_wrap(S-V) :- par_no_literal(S, V).


% =========================================================
% CLASIFICACIÓN GLOBAL DE UNA ORACIÓN

% clasificar_oracion(+Texto, -Clase, -Info)
% Clase detallada: correcta | ambigua | no_literal | incoherente | no_analizable
%
% Prioridad: incoherente > no_literal > ambigua > correcta.
% La incoherencia es el problema más grave; la ambigüedad es el más leve.
clasificar_oracion(Texto, Clase, Info) :-
    (   analisis_seguro(Texto, Arbol)
    ->  clasificar_con_arbol(Texto, Arbol, Clase, Info)
    ;   Clase = no_analizable,
        Info  = no_analizable(Texto)
    ).

clasificar_con_arbol(Texto, Arbol, Clase, Info) :-
    (   tiene_incoherencia(Texto, Arbol, InfoInc)
    ->  Clase = incoherente, Info = InfoInc
    ;   tiene_uso_no_literal(Texto, Arbol, InfoNL)
    ->  Clase = no_literal, Info = InfoNL
    ;   tiene_ambiguedad(Texto, InfoAmb)
    ->  Clase = ambigua, Info = InfoAmb
    ;   Clase = correcta, Info = correcta(Texto)
    ).

% clasificar_oracion_enunciado(+Texto, -Clase)
% Clasificación según las tres categorías del enunciado (sección 3.4):
%   correcta | ambigua | problematica
% Las clases internas incoherente y no_literal se agrupan en problematica.
clasificar_oracion_enunciado(Texto, Clase) :-
    clasificar_oracion(Texto, ClaseInterna, _),
    (   ClaseInterna = incoherente -> Clase = problematica
    ;   ClaseInterna = no_literal  -> Clase = problematica
    ;   Clase = ClaseInterna
    ).


% =========================================================
% INTERFAZ PRINCIPAL: ANÁLISIS SEMÁNTICO COMPLETO

% analizar_semanticamente(+Texto)
% Muestra en pantalla el análisis semántico completo de un texto.
% Detecta y reporta ambigüedad, incoherencia y uso no literal.
analizar_semanticamente(Texto) :-
    write('--------------------------------------------------'), nl,
    write('Texto: '), write(Texto), nl,

    % 2.3.1 Ambigüedad léxica
    (   tiene_ambiguedad(Texto, InfoAmb)
    ->  write('  [AMBIGUEDAD LEXICA]'), nl,
        forall(
            member(Pal-Tipos, InfoAmb),
            format("    '~w' puede ser: ~w~n", [Pal, Tipos])
        )
    ;   true
    ),

    % 2.3.2 y 2.3.3: Requieren el árbol sintáctico
    (   analisis_seguro(Texto, Arbol)
    ->  extraer_pares(Arbol, Pares),
        (   Pares \= []
        ->  write('  Pares sujeto-verbo detectados: '),
            write(Pares), nl
        ;   true
        ),
        (   tiene_incoherencia(Texto, Arbol, incoherencia(_, PInc))
        ->  write('  [INCOHERENCIA SEMANTICA]'), nl,
            forall(
                member(S-V, PInc),
                format("    sujeto '~w' + verbo '~w' son incompatibles~n", [S, V])
            )
        ;   true
        ),
        (   tiene_uso_no_literal(Texto, Arbol, no_literal(_, PNL))
        ->  write('  [USO NO LITERAL / METAFORICO]'), nl,
            forall(
                member(S-V, PNL),
                format("    '~w' (inanimado) realiza accion propia de animados: '~w'~n", [S, V])
            )
        ;   true
        ),
        clasificar_con_arbol(Texto, Arbol, Clase, _),
        write('  Clasificacion: '), write(Clase), nl
    ;   write('  [No analizable sintacticamente]'), nl
    ).


% =========================================================
% PREDICADOS SOBRE EL CORPUS

% analizar_semanticamente_gpt(+N)
% Analiza semánticamente la oración N del corpus GPT.
analizar_semanticamente_gpt(N) :-
    oracion_gpt(N, Texto),
    format("~n=== GPT #~w ===~n", [N]),
    analizar_semanticamente(Texto).

% analizar_semanticamente_claude(+N)
% Analiza semánticamente la oración N del corpus Claude.
analizar_semanticamente_claude(N) :-
    oracion_claude(N, Texto),
    format("~n=== Claude #~w ===~n", [N]),
    analizar_semanticamente(Texto).

% analizar_todos_semanticamente_gpt/0
% Analiza semánticamente todas las oraciones del corpus GPT.
analizar_todos_semanticamente_gpt :-
    forall(
        oracion_gpt(N, _),
        analizar_semanticamente_gpt(N)
    ).

% analizar_todos_semanticamente_claude/0
% Analiza semánticamente todas las oraciones del corpus Claude.
analizar_todos_semanticamente_claude :-
    forall(
        oracion_claude(N, _),
        analizar_semanticamente_claude(N)
    ).

% analizar_todos_semanticamente/0
% Analiza ambos corpus completos.
analizar_todos_semanticamente :-
    write('========== CORPUS GPT =========='), nl,
    analizar_todos_semanticamente_gpt,
    nl,
    write('========== CORPUS CLAUDE =========='), nl,
    analizar_todos_semanticamente_claude.

% resumen_corpus/0
% Clasifica todas las oraciones según las tres categorías del enunciado (3.4):
%   correcta | ambigua | problematica
resumen_corpus :-
    write('=== CLASIFICACION DEL CORPUS (correcta / ambigua / problematica) ==='), nl,
    nl,
    write('--- CORPUS GPT ---'), nl,
    forall(
        oracion_gpt(N, Texto),
        (
            clasificar_oracion_enunciado(Texto, Clase),
            format("GPT #~w [~w]~n", [N, Clase])
        )
    ),
    nl,
    write('--- CORPUS CLAUDE ---'), nl,
    forall(
        oracion_claude(N, Texto),
        (
            clasificar_oracion_enunciado(Texto, Clase),
            format("Claude #~w [~w]~n", [N, Clase])
        )
    ).

% resumen_problemas/0
% Muestra únicamente las oraciones con problemas (ambigua o problematica).
resumen_problemas :-
    write('=== ORACIONES CON PROBLEMAS SEMANTICOS ==='), nl,
    nl,
    write('--- CORPUS GPT ---'), nl,
    forall(
        oracion_gpt(N, Texto),
        (
            clasificar_oracion(Texto, Clase, _),
            Clase \= correcta,
            Clase \= no_analizable
        ->  format("GPT #~w [~w]: ~w~n", [N, Clase, Texto])
        ;   true
        )
    ),
    nl,
    write('--- CORPUS CLAUDE ---'), nl,
    forall(
        oracion_claude(N, Texto),
        (
            clasificar_oracion(Texto, Clase, _),
            Clase \= correcta,
            Clase \= no_analizable
        ->  format("Claude #~w [~w]: ~w~n", [N, Clase, Texto])
        ;   true
        )
    ).
