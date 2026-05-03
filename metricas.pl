% metricas.pl
% Métricas automáticas para comparar las dos traducciones.

:- encoding(utf8).

% =========================================================
% ANALISIS INDIVIDUAL DE UNA ORACION
% =========================================================

% ---------------------------------------------------------
% analizar_texto_seguro(+Texto, -Arbol)
%
% Intenta analizar una oración, pero evita que una frase
% bloquee todo el comparador por explosión de backtracking.
% Si tarda demasiado, falla y la oración se marca como no_analizada.
% ---------------------------------------------------------

analisis_timeout_segundos(60).

analizar_texto_seguro(Texto, Arbol) :-
    analisis_timeout_segundos(Segundos),
    catch(
        call_with_time_limit(
            Segundos,
            once(analizar_texto(Texto, Arbol))
        ),
        time_limit_exceeded,
        (
            write('*** TIMEOUT analizando la oración: '),
            write(Texto),
            nl,
            fail
        )
    ).


% ---------------------------------------------------------
% analizar_resultado(+Texto, -Resultado)
%
% Devuelve un término:
%
% resultado(
%   Aceptada,
%   Tipo,
%   Longitud,
%   Comas,
%   Conectores,
%   Relativos,
%   TerminosTecnicos,
%   NumSimples,
%   Profundidad,
%   Nodos
% )
%
% Aceptada = si/no
% Tipo = o/oc/or/ocm/no_analizada
% ---------------------------------------------------------

analizar_resultado(Texto, resultado(Aceptada, Tipo, Longitud, Comas, Conectores, Relativos, Tecnicos, NumSimples, Profundidad, Nodos)) :-
    tokenizar_basico(Texto, Tokens),
    longitud_tokens(Tokens, Longitud),
    contar_token(Tokens, ',', Comas),
    contar_conectores(Tokens, Conectores),
    contar_relativos(Tokens, Relativos),
    contar_terminos_tecnicos(Tokens, Tecnicos),
    (
        analizar_texto_seguro(Texto, Arbol) ->
            Aceptada = si,
            tipo_oracion(Arbol, Tipo),
            contar_simples(Arbol, NumSimples),
            profundidad_arbol(Arbol, Profundidad),
            numero_nodos(Arbol, Nodos)
    ;
            Aceptada = no,
            Tipo = no_analizada,
            NumSimples = 0,
            Profundidad = 0,
            Nodos = 0
    ).



% =========================================================
% LONGITUD Y CONTEOS BASICOS
% =========================================================

% ---------------------------------------------------------
% longitud_tokens(+Tokens, -N)
% Cuenta tokens útiles. No cuenta comas.
% ---------------------------------------------------------

longitud_tokens(Tokens, N) :-
    excluir_tokens_no_lexicos(Tokens, Limpios),
    length(Limpios, N).

excluir_tokens_no_lexicos([], []).

excluir_tokens_no_lexicos([','|Resto], Salida) :-
    !,
    excluir_tokens_no_lexicos(Resto, Salida).

excluir_tokens_no_lexicos([Token|Resto], [Token|Salida]) :-
    excluir_tokens_no_lexicos(Resto, Salida).

% ---------------------------------------------------------
% contar_token(+Lista, +Token, -N)
% ---------------------------------------------------------

contar_token([], _, 0).

contar_token([Token|Resto], Token, N) :-
    !,
    contar_token(Resto, Token, N0),
    N is N0 + 1.

contar_token([_|Resto], Token, N) :-
    contar_token(Resto, Token, N).

% =========================================================
% CONECTORES
% =========================================================

% ---------------------------------------------------------
% contar_conectores(+Tokens, -N)
% Cuenta conectores simples y algunos compuestos.
% ---------------------------------------------------------

contar_conectores(Tokens, N) :-
    contar_conectores_simples(Tokens, N1),
    contar_patron(Tokens, [sin, embargo], N2),
    contar_patron(Tokens, [no, obstante], N3),
    contar_patron(Tokens, [por, el, contrario], N4),
    contar_patron(Tokens, [a, continuacion], N5),
    contar_patron(Tokens, [en, cambio], N6),
    contar_patron(Tokens, [dado, que], N7),
    contar_patron(Tokens, [en, cuanto], N8),
    N is N1 + N2 + N3 + N4 + N5 + N6 + N7 + N8.

contar_conectores_simples([], 0).

contar_conectores_simples([Token|Resto], N) :-
    conector_simple(Token),
    !,
    contar_conectores_simples(Resto, N0),
    N is N0 + 1.

contar_conectores_simples([_|Resto], N) :-
    contar_conectores_simples(Resto, N).

conector_simple(y).
conector_simple(o).
conector_simple(pero).
conector_simple(aunque).
conector_simple(cuando).
conector_simple(porque).
conector_simple(que).
conector_simple(ademas).
conector_simple(tambien).
conector_simple(mientras).
conector_simple(si).

% =========================================================
% RELATIVOS
% =========================================================

% ---------------------------------------------------------
% contar_relativos(+Tokens, -N)
% Cuenta relativos simples y compuestos.
% ---------------------------------------------------------

contar_relativos(Tokens, N) :-
    contar_relativos_simples(Tokens, N1),
    contar_patron(Tokens, [lo, que], N2),
    contar_patron(Tokens, [en, la, que], N3),
    contar_patron(Tokens, [en, el, que], N4),
    contar_patron(Tokens, [mediante, el, cual], N5),
    contar_patron(Tokens, [durante, los, cuales], N6),
    N is N1 + N2 + N3 + N4 + N5 + N6.

contar_relativos_simples([], 0).

contar_relativos_simples([Token|Resto], N) :-
    relativo_simple_token(Token),
    !,
    contar_relativos_simples(Resto, N0),
    N is N0 + 1.

contar_relativos_simples([_|Resto], N) :-
    contar_relativos_simples(Resto, N).

relativo_simple_token(que).
relativo_simple_token(cual).
relativo_simple_token(cuales).
relativo_simple_token(quien).
relativo_simple_token(quienes).
relativo_simple_token(donde).

% =========================================================
% TERMINOS TECNICOS
% =========================================================

% ---------------------------------------------------------
% contar_terminos_tecnicos(+Tokens, -N)
% Cuenta términos técnicos frecuentes del dominio.
% ---------------------------------------------------------

contar_terminos_tecnicos([], 0).

contar_terminos_tecnicos([Token|Resto], N) :-
    termino_tecnico(Token),
    !,
    contar_terminos_tecnicos(Resto, N0),
    N is N0 + 1.

contar_terminos_tecnicos([_|Resto], N) :-
    contar_terminos_tecnicos(Resto, N).

termino_tecnico(necrobotica).
termino_tecnico(necrobotico).
termino_tecnico(necrobotica).
termino_tecnico(biotico).
termino_tecnico(biotica).
termino_tecnico(bioticos).
termino_tecnico(bioticas).
termino_tecnico(biohibrido).
termino_tecnico(biohibridos).
termino_tecnico(biomimetico).
termino_tecnico(bioinspirado).
termino_tecnico(bioinspirados).
termino_tecnico(actuador).
termino_tecnico(actuadores).
termino_tecnico(actuacion).
termino_tecnico(pinza).
termino_tecnico(efector).
termino_tecnico(agarre).
termino_tecnico(arana).
termino_tecnico(aranas).
termino_tecnico(prosoma).
termino_tecnico(hemolinfa).
termino_tecnico(exoesqueleto).
termino_tecnico(hidraulica).
termino_tecnico(hidraulico).
termino_tecnico(neumatica).
termino_tecnico(neumatico).
termino_tecnico(presion).
termino_tecnico(patelofemoral).
termino_tecnico(trocanter).
termino_tecnico(microscopia).
termino_tecnico(barrido).
termino_tecnico(jeringa).
termino_tecnico(jeringuilla).
termino_tecnico(aguja).
termino_tecnico(hipodermica).
termino_tecnico(cuticula).
termino_tecnico(biomaterial).
termino_tecnico(deshidratacion).
termino_tecnico(flexores).
termino_tecnico(hidrostática).
termino_tecnico(hidrostatica).

% =========================================================
% PATRONES DE TOKENS
% =========================================================

% ---------------------------------------------------------
% contar_patron(+Tokens, +Patron, -N)
% Cuenta cuántas veces aparece una secuencia de tokens.
% ---------------------------------------------------------

contar_patron([], _, 0).

contar_patron(Tokens, Patron, N) :-
    empieza_por(Tokens, Patron),
    !,
    Tokens = [_|Resto],
    contar_patron(Resto, Patron, N0),
    N is N0 + 1.

contar_patron([_|Resto], Patron, N) :-
    contar_patron(Resto, Patron, N).

empieza_por(_, []).

empieza_por([X|RestoTokens], [X|RestoPatron]) :-
    empieza_por(RestoTokens, RestoPatron).

% =========================================================
% SIMPLIFICACION
% =========================================================

% ---------------------------------------------------------
% contar_simples(+Arbol, -N)
% Número de oraciones simples resultantes de simplificar.
% Si no se puede simplificar, devuelve 1.
% ---------------------------------------------------------

contar_simples(Arbol, N) :-
    (
        once(simplificar(Arbol, Simples)),
        is_list(Simples)
    ->
        length(Simples, N)
    ;
        N = 1
    ).

% =========================================================
% METRICAS DEL ARBOL
% =========================================================

% ---------------------------------------------------------
% profundidad_arbol(+Termino, -Profundidad)
% ---------------------------------------------------------

profundidad_arbol(Termino, 1) :-
    atomic(Termino),
    !.

profundidad_arbol(Termino, Profundidad) :-
    Termino =.. [_|Args],
    profundidades_lista(Args, Profundidades),
    max_lista(Profundidades, Max),
    Profundidad is Max + 1.

profundidades_lista([], [0]).

profundidades_lista([X|Resto], [PX|PResto]) :-
    profundidad_arbol(X, PX),
    profundidades_lista(Resto, PResto).

max_lista([X], X).

max_lista([X|Resto], Max) :-
    max_lista(Resto, MaxResto),
    (
        X >= MaxResto ->
            Max = X
    ;
            Max = MaxResto
    ).

% ---------------------------------------------------------
% numero_nodos(+Termino, -N)
% Cuenta nodos del árbol sintáctico.
% ---------------------------------------------------------

numero_nodos(Termino, 1) :-
    atomic(Termino),
    !.

numero_nodos(Termino, N) :-
    Termino =.. [_|Args],
    numero_nodos_lista(Args, NArgs),
    N is NArgs + 1.

numero_nodos_lista([], 0).

numero_nodos_lista([X|Resto], N) :-
    numero_nodos(X, NX),
    numero_nodos_lista(Resto, NResto),
    N is NX + NResto.