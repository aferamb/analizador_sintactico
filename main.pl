% main.pl
% Punto de entrada del proyecto.

:- consult('sintactico.pl').
:- consult('conjunto_oraciones.pl').

% ---------------------------------------------------------
% acepta(+Lista)
% Devuelve true si la lista puede analizarse como una oracion.
% ---------------------------------------------------------
acepta(Lista) :-
    phrase(oracion(_), Lista).

% ---------------------------------------------------------
% analizar(+Lista, -Arbol)
% Analiza una lista de tokens y devuelve su arbol sintactico.
% ---------------------------------------------------------
analizar(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).

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
% tipo(+Lista, -Tipo)
% Devuelve el tipo principal de la oracion.
% ---------------------------------------------------------
tipo(Lista, Tipo) :-
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
    normalizar_acentos(TextoMinus, TextoNormalizado),
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
% PREDICADOS DE PRUEBA SOBRE EL CORPUS EN TEXTO
% =========================================================

% ---------------------------------------------------------
% probar_ejemplo(+N)
% Muestra:
%   - el texto original
%   - los tokens
%   - el arbol
%   - el tipo de oracion
%   - la simplificacion
% ---------------------------------------------------------
probar_ejemplo(N) :-
    oracion_corpus(N, Texto),
    tokenizar_basico(Texto, Lista),
    write('Texto: '), write(Texto), nl,
    write('Tokens: '), write_term(Lista, [quoted(true)]), nl,
    ( once(analizar_texto(Texto, Arbol)) ->
        write('Arbol: '), write(Arbol), nl,
        tipo_oracion(Arbol, Tipo),
        write('Tipo: '), write(Tipo), nl,
        simplificar(Arbol, Simples),
        write('Simplificacion: '), write(Simples), nl
    ;
        write('No aceptada por la gramatica.'), nl
    ).

% ---------------------------------------------------------
% probar_todos
% Recorre todas las oraciones del corpus y las prueba una a una.
% ---------------------------------------------------------
probar_todos :-
    forall(
        oracion_corpus(N, _),
        (
            write('=============================='), nl,
            write('Ejemplo '), write(N), nl,
            probar_ejemplo(N)
        )
    ).
