:- encoding(utf8).

% main.pl
% Punto de entrada del proyecto.

:- consult('sintactico.pl').
:- consult('conjunto_oraciones_gpt.pl').
:- consult('conjunto_oraciones_claude.pl').
%:- consult('lexico-claude.pl').
%:- consult('lexico-gpt.pl').
:- consult('lexico.pl').
:- consult('semantico.pl').
:- consult('deteccion.pl').
:- consult('metricas.pl').
:- consult('comparativo.pl').

% ---------------------------------------------------------
% acepta(+Lista)
% Devuelve true si la lista puede analizarse como una oracion.
% ---------------------------------------------------------
acepta(Lista) :-
    once(phrase(oracion(_), Lista)).

% ---------------------------------------------------------
% analizar(+Lista, -Arbol)
% Analiza una lista de tokens y devuelve su arbol sintactico.
% ---------------------------------------------------------
analizar(Lista, Arbol) :-
    once(phrase(oracion(Arbol), Lista)).

% ---------------------------------------------------------
% analizar(+Lista)
% Version comoda que imprime directamente el arbol.
% ---------------------------------------------------------
analizar(Lista) :-
    analizar(Lista, Arbol),
    write(Arbol), nl.

% ---------------------------------------------------------
% dibujar(+Lista)
% Analiza la lista y dibuja el arbol usando draw.pl.
% ---------------------------------------------------------
dibujar(Lista) :-
    analizar(Lista, Arbol),
    draw(Arbol).

% ---------------------------------------------------------
% tipo_lista(+Lista, -Tipo)
% Devuelve el tipo principal de la oracion dada como lista de tokens.
% (Renombrado de tipo/2 para evitar conflicto con tipo/2 de semantico.pl)
% ---------------------------------------------------------
tipo_lista(Lista, Tipo) :-
    analizar(Lista, Arbol),
    tipo_oracion(Arbol, Tipo).

% ---------------------------------------------------------
% simplificar_oracion(+Lista, -Simples)
% Analiza la oracion y la transforma en una lista de oraciones simples.
% ---------------------------------------------------------
simplificar_oracion(Lista, Simples) :-
    analizar(Lista, Arbol),
    simplificar(Arbol, Simples).

% ---------------------------------------------------------
% simplificar_e_imprimir(+Lista)
% Igual que simplificar_oracion/2, pero imprime el resultado.
% ---------------------------------------------------------
simplificar_e_imprimir(Lista) :-
    simplificar_oracion(Lista, Simples),
    write(Simples), nl.

% =========================================================
% TOKENIZACION BASICA DESDE TEXTO
% =========================================================

% ---------------------------------------------------------
% tokenizar_basico(+Texto, -Lista)
% Convierte un texto normal en una lista de atomos.
% Se mantienen las comas como token independiente.
% ---------------------------------------------------------
tokenizar_basico(Texto, Lista) :-
    string(Texto), !,
    string_lower(Texto, TextoMinus),
    normalizar_acentos(TextoMinus, TextoNormalizado0),
    normalizar_comas_decimales(TextoNormalizado0, TextoNormalizado),
    rodear_comas(TextoNormalizado, TextoConComasSeparadas),
    split_string(
        TextoConComasSeparadas,
        " ",
        " \t\n\r.;:!?¡¿()[]{}\"'",
        Partes0
    ),
    quitar_vacias(Partes0, Partes1),
    pasar_a_atomos(Partes1, Lista).

tokenizar_basico(Texto, Lista) :-
    atom(Texto), !,
    atom_string(Texto, TextoString),
    tokenizar_basico(TextoString, Lista).

tokenizar_basico(Texto, _) :-
    write('Error: tokenizar_basico/2 espera un string o un atomo. Recibido: '),
    write(Texto), nl,
    fail.

% ---------------------------------------------------------
% normalizar_acentos(+TextoEntrada, -TextoSalida)
% Elimina tildes de vocales y dieresis. Mantiene la ñ.
% ---------------------------------------------------------
normalizar_acentos(TextoEntrada, TextoSalida) :-
    string_codes(TextoEntrada, Codigos),
    normalizar_codigos(Codigos, Normalizados),
    string_codes(TextoSalida, Normalizados).

normalizar_codigos([], []).

normalizar_codigos([C|Resto], [N|Salida]) :-
    normalizar_codigo(C, N),
    normalizar_codigos(Resto, Salida).

normalizar_codigo(225, 97).  % a con tilde
normalizar_codigo(233, 101). % e con tilde
normalizar_codigo(237, 105). % i con tilde
normalizar_codigo(243, 111). % o con tilde
normalizar_codigo(250, 117). % u con tilde
normalizar_codigo(252, 117). % u con dieresis
normalizar_codigo(C, C).

% ---------------------------------------------------------
% normalizar_comas_decimales(+TextoEntrada, -TextoSalida)
% Convierte comas decimales entre números en puntos:
%   "0,35 mN" -> "0.35 mN"
%   "5,5 kPa" -> "5.5 kPa"
% Así rodear_comas/2 no rompe los números decimales.
% ---------------------------------------------------------

normalizar_comas_decimales(TextoEntrada, TextoSalida) :-
    string_codes(TextoEntrada, Codigos),
    normalizar_comas_decimales_codigos(Codigos, Normalizados),
    string_codes(TextoSalida, Normalizados).

normalizar_comas_decimales_codigos([], []).

normalizar_comas_decimales_codigos([A,44,B|Resto], [A,46,B|Salida]) :-
    code_type(A, digit),
    code_type(B, digit),
    !,
    normalizar_comas_decimales_codigos(Resto, Salida).

normalizar_comas_decimales_codigos([C|Resto], [C|Salida]) :-
    normalizar_comas_decimales_codigos(Resto, Salida).


% ---------------------------------------------------------
% rodear_comas(+TextoEntrada, -TextoSalida)
% Inserta espacios alrededor de cada coma.
% ---------------------------------------------------------
rodear_comas(TextoEntrada, TextoSalida) :-
    split_string(TextoEntrada, ",", "", Fragmentos),
    atomic_list_concat(Fragmentos, ' , ', TextoSalida).

% ---------------------------------------------------------
% quitar_vacias(+ListaStrings, -ListaLimpia)
% Elimina strings vacios.
% ---------------------------------------------------------
quitar_vacias([], []).

quitar_vacias([""|Resto], Salida) :-
    quitar_vacias(Resto, Salida).

quitar_vacias([X|Resto], [X|Salida]) :-
    X \= "",
    quitar_vacias(Resto, Salida).

% ---------------------------------------------------------
% pasar_a_atomos(+ListaStrings, -ListaAtomos)
% Convierte cada string a atomo Prolog.
% ---------------------------------------------------------
pasar_a_atomos([], []).

pasar_a_atomos([X|Resto], [A|Salida]) :-
    atom_string(A, X),
    pasar_a_atomos(Resto, Salida).

% =========================================================
% VERSIONES DESDE TEXTO
% =========================================================

acepta_texto(Texto) :-
    tokenizar_basico(Texto, Lista),
    acepta(Lista).

analizar_texto(Texto, Arbol) :-
    tokenizar_basico(Texto, Lista),
    analizar(Lista, Arbol).

analizar_texto(Texto) :-
    analizar_texto(Texto, Arbol),
    write(Arbol), nl.

dibujar_texto(Texto) :-
    analizar_texto(Texto, Arbol),
    draw(Arbol).

tipo_texto(Texto, Tipo) :-
    analizar_texto(Texto, Arbol),
    tipo_oracion(Arbol, Tipo).

simplificar_texto(Texto, Simples) :-
    analizar_texto(Texto, Arbol),
    simplificar(Arbol, Simples).
% =========================================================
% PREDICADOS DE PRUEBA SOBRE LOS CORPUS EN TEXTO
% =========================================================

% ---------------------------------------------------------
% probar_gpt(+N)
% Prueba la oración N del corpus GPT.
% ---------------------------------------------------------
probar_gpt(N) :-
    oracion_gpt(N, Texto),
    probar_texto(Texto).

% ---------------------------------------------------------
% probar_claude(+N)
% Prueba la oración N del corpus Claude.
% ---------------------------------------------------------
probar_claude(N) :-
    oracion_claude(N, Texto),
    probar_texto(Texto).

% ---------------------------------------------------------
% probar_texto(+Texto)
% Muestra:
%   - el texto original
%   - los tokens
%   - el árbol, si se acepta
%   - el tipo de oración
%   - la simplificación
% ---------------------------------------------------------
probar_texto(Texto) :-
    tokenizar_basico(Texto, Lista),
    write('Texto: '), write(Texto), nl,
    write('Tokens: '), write_term(Lista, [quoted(true)]), nl,
    (
        analizar_texto_seguro(Texto, Arbol) ->
            write('Arbol: '), write(Arbol), nl,
            tipo_oracion(Arbol, Tipo),
            write('Tipo: '), write(Tipo), nl,
            (
                once(simplificar(Arbol, Simples)) ->
                    write('Simplificacion: '), write(Simples), nl
            ;
                    write('Simplificacion: no disponible'), nl
            )
    ;
            write('No aceptada por la gramatica.'), nl
    ).

% ---------------------------------------------------------
% probar_todos_gpt/0
% Recorre todas las oraciones del corpus GPT.
% ---------------------------------------------------------
probar_todos_gpt :-
    forall(
        oracion_gpt(N, _),
        (
            write('=============================='), nl,
            write('GPT - Ejemplo '), write(N), nl,
            probar_gpt(N)
        )
    ).

% ---------------------------------------------------------
% probar_todos_claude/0
% Recorre todas las oraciones del corpus Claude.
% ---------------------------------------------------------
probar_todos_claude :-
    forall(
        oracion_claude(N, _),
        (
            write('=============================='), nl,
            write('Claude - Ejemplo '), write(N), nl,
            probar_claude(N)
        )
    ).

% ---------------------------------------------------------
% probar_todos/0
% Mantenemos este nombre como atajo: prueba ambos corpus.
% ---------------------------------------------------------
probar_todos :-
    write('========== CORPUS GPT =========='), nl,
    probar_todos_gpt,
    nl,
    write('========== CORPUS CLAUDE =========='), nl,
    probar_todos_claude.



% =========================================================
% PRUEBAS DE DIAGNOSTICO
% =========================================================

probar_gn(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    ( phrase(g_nominal(GN), Tokens) ->
        write('GN aceptado: '), write(GN), nl
    ;
        write('GN no aceptado'), nl
    ).

probar_gv(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    ( phrase(g_verbal(GV), Tokens) ->
        write('GV aceptado: '), write(GV), nl
    ;
        write('GV no aceptado'), nl
    ).

probar_gp(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    ( phrase(g_preposicional(GP), Tokens) ->
        write('GP aceptado: '), write(GP), nl
    ;
        write('GP no aceptado'), nl
    ).

probar_inf(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    ( phrase(infinitivo_frase(Inf), Tokens) ->
        write('Infinitivo aceptado: '), write(Inf), nl
    ;
        write('Infinitivo no aceptado'), nl
    ).

probar_oracion_tokens(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    ( phrase(oracion(Arbol), Tokens) ->
        write('Oracion aceptada: '), write(Arbol), nl
    ;
        write('Oracion no aceptada'), nl
    ).


% ---------------------------------------------------------
% probar_rapido(+Texto)
%
% Igual que probar_texto/1, pero muestra solo si acepta,
% tipo y árbol. Útil para probar frases problemáticas sin
% imprimir demasiada información.
% ---------------------------------------------------------

probar_rapido(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,
    (
        analizar_texto_seguro(Texto, Arbol) ->
            write('Aceptada: si'), nl,
            tipo_oracion(Arbol, Tipo),
            write('Tipo: '), write(Tipo), nl,
            write('Arbol: '), write(Arbol), nl
    ;
            write('Aceptada: no'), nl
    ).

% ---------------------------------------------------------
% probar_gpt_rapido(+N)
% ---------------------------------------------------------

probar_gpt_rapido(N) :-
    oracion_gpt(N, Texto),
    probar_rapido(Texto).

% ---------------------------------------------------------
% probar_claude_rapido(+N)
% ---------------------------------------------------------

probar_claude_rapido(N) :-
    oracion_claude(N, Texto),
    probar_rapido(Texto).

% ---------------------------------------------------------
% probar_partes_basicas(+Texto)
%
% Prueba una misma cadena como GN, GV, GP, GAdj e infinitivo.
% Sirve para ver qué subcomponente se ha roto.
% ---------------------------------------------------------

probar_partes_basicas(Texto) :-
    tokenizar_basico(Texto, Tokens),
    write('Tokens: '), write_term(Tokens, [quoted(true)]), nl,

    ( phrase(g_nominal(GN), Tokens) ->
        write('GN: si -> '), write(GN), nl
    ;
        write('GN: no'), nl
    ),

    ( phrase(g_verbal(GV), Tokens) ->
        write('GV: si -> '), write(GV), nl
    ;
        write('GV: no'), nl
    ),

    ( phrase(g_preposicional(GP), Tokens) ->
        write('GP: si -> '), write(GP), nl
    ;
        write('GP: no'), nl
    ),

    ( phrase(g_adjetival(GAdj), Tokens) ->
        write('GAdj: si -> '), write(GAdj), nl
    ;
        write('GAdj: no'), nl
    ),

    ( phrase(infinitivo_frase(Inf), Tokens) ->
        write('Inf: si -> '), write(Inf), nl
    ;
        write('Inf: no'), nl
    ).