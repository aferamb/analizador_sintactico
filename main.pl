
% main.pl
% Este archivo es el punto de entrada del proyecto.
%
% Su función principal es:
%   - cargar el módulo sintáctico;
%   - ofrecer predicados cómodos de prueba;
%   - permitir analizar listas de tokens o texto plano;
%   - mostrar el árbol, el tipo de oración y su simplificación.

% Este archivo añade funciones cómodas como:
%   acepta/1
%   analizar/2
%   dibujar/1
%   tipo/2
%   simplificar_oracion/2
% y además una tokenización básica para poder escribir:
%   ?- analizar_texto("Juan analiza el sistema", X).
% en vez de tener que pasar siempre:
%   ?- analizar([juan,analiza,el,sistema], X).


% Cargamos el archivo del analizador sintáctico
:- consult('sintactico.pl').


% ---------------------------------------------------------
% acepta(+Lista)
% Devuelve true si la lista puede analizarse como una oración según la gramática.
% Ejemplo: ?- acepta([juan, analiza, el, sistema]).
% ---------------------------------------------------------
acepta(Lista) :-
    phrase(oracion(_), Lista).

% ---------------------------------------------------------
% analizar(+Lista, -Arbol)
% Analiza una lista de tokens y devuelve su árbol sintáctico.
% Ejemplo:
%   ?- analizar([juan, analiza, el, sistema], X).
%   X = o(gn(n(juan)), gv(v(analiza), gn(det(el), n(sistema)))).
% ---------------------------------------------------------
analizar(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).

% ---------------------------------------------------------
% analizar(+Lista)
% Versión cómoda que imprime directamente el árbol.
% Ejemplo: ?- analizar([juan, analiza, el, sistema]).
% ---------------------------------------------------------
analizar(Lista) :-
    analizar(Lista, Arbol),
    write(Arbol), nl.

% ---------------------------------------------------------
% dibujar(+Lista)
% Analiza la lista y dibuja el árbol usando draw.pl.
% Ejemplo: ?- dibujar([juan, analiza, el, sistema]).
% ---------------------------------------------------------
dibujar(Lista) :-
    analizar(Lista, Arbol),
    draw(Arbol).

% ---------------------------------------------------------
% tipo(+Lista, -Tipo)
% Devuelve el tipo principal de la oración:
%   o   -> simple
%   oc  -> coordinada
%   or  -> relativa
%   ocm -> compuesta mixta
% Ejemplo: ?- tipo([juan, analiza, el, sistema, y, maria, evalua, el, modelo], T).   T = oc.
% ---------------------------------------------------------
tipo(Lista, Tipo) :-
    analizar(Lista, Arbol),
    tipo_oracion(Arbol, Tipo).

% ---------------------------------------------------------
% simplificar_oracion(+Lista, -Simples)
% Analiza la oración y la transforma en una lista de oraciones simples.
% Ejemplo:
%   ?- simplificar_oracion( [juan, que, analiza, el, sistema, presenta, el, resultado],S).
%   S = [ o(gn(n(juan)), gv(v(analiza), gn(det(el), n(sistema)))),
%         o(gn(n(juan)), gv(v(presenta), gn(det(el), n(resultado)))) ].
% ---------------------------------------------------------
simplificar_oracion(Lista, Simples) :-
    analizar(Lista, Arbol),
    simplificar(Arbol, Simples).

% simplificar_e_imprimir(+Lista)
% Igual que simplificar_oracion/2, pero imprime el resultado
simplificar_e_imprimir(Lista) :-
    simplificar_oracion(Lista, Simples),
    write(Simples), nl.

% =========================================================
% tokenizar_basico(+Texto, -Lista)

% Convertir un texto normal en una lista de átomos.
% Ejemplo: "Juan analiza el sistema" -> [juan, analiza, el, sistema]
% Se mantienen las comas. Así: "Juan, que analiza el sistema, presenta el resultado"
% se convertirá en: [juan, ',', que, analiza, el, sistema, ',', presenta, el, resultado]

% LIMITACIONES: //TODO si es necesario más adelante
% - No hace lematización
% - No resuelve tildes automáticamente
% - No separa toda la puntuación posible con precisión lingüística real
% - Es una tokenización práctica, no una tokenización NLP avanzada
% =========================================================

% Caso 1: el texto llega como string
% Ejemplo: ?- tokenizar_basico("Juan, que analiza el sistema, presenta el resultado", L).
tokenizar_basico(Texto, Lista) :-
    string(Texto), !,
    string_lower(Texto, TextoMinus), % 1) convertir a minúsculas;
    rodear_comas(TextoMinus, TextoConComasSeparadas), % 2) insertar espacios alrededor de la coma;
    split_string( % 3) separar por espacios;
        TextoConComasSeparadas,
        " ",
        " \t\n\r.;:!?¡¿()[]{}\"'",
        Partes0
    ),
    quitar_vacias(Partes0, Partes1), % 4) eliminar vacíos;
    pasar_a_atomos(Partes1, Lista). % 5) pasar a átomos.


% Caso 2: el texto llega como átomo
% Esto permite consultas como: ?- tokenizar_basico('Juan analiza el sistema', L).
% Internamente lo convertimos a string y reutilizamos la otra versión
tokenizar_basico(Texto, Lista) :-
    atom(Texto), !,
    atom_string(Texto, TextoString),
    tokenizar_basico(TextoString, Lista).


% Caso 3: error de tipo
% Si se pasa algo que no es string ni átomo, falla.
tokenizar_basico(Texto, _) :-
    write('Error: tokenizar_basico/2 espera un string o un atomo. Recibido: '),
    write(Texto), nl,
    fail.

% ---------------------------------------------------------
% rodear_comas(+TextoEntrada, -TextoSalida)
% Inserta espacios alrededor de cada coma.
% Ejemplo: "juan,que analiza" -> "juan , que analiza"
% Eso nos permite que split_string trate la coma como un token separado.
% La coma se conserva como texto "," y luego pasa a átomo ','.
% ---------------------------------------------------------
rodear_comas(TextoEntrada, TextoSalida) :-
    split_string(TextoEntrada, ",", "", Fragmentos),
    atomic_list_concat(Fragmentos, ' , ', TextoSalida).

% ---------------------------------------------------------
% quitar_vacias(+ListaStrings, -ListaLimpia)
% Elimina strings vacíos que puedan aparecer tras el split.
% Ejemplo: ["juan", "", ",", "maria"] -> ["juan", ",", "maria"]
% ---------------------------------------------------------
quitar_vacias([], []).

quitar_vacias([""|Resto], Salida) :-
    quitar_vacias(Resto, Salida).

quitar_vacias([X|Resto], [X|Salida]) :-
    X \= "",
    quitar_vacias(Resto, Salida).

% ---------------------------------------------------------
% pasar_a_atomos(+ListaStrings, -ListaAtomos)
% Convierte cada string a átomo Prolog.
% Ejemplo: ["juan", ",", "maria"] -> [juan, ',', maria]
% ---------------------------------------------------------
pasar_a_atomos([], []).

pasar_a_atomos([X|Resto], [A|Salida]) :-
    atom_string(A, X),
    pasar_a_atomos(Resto, Salida).

% =========================================================
% VERSIONES DESDE TEXTO
% Estas funciones permiten trabajar directamente con una frase escrita como texto, sin tener que tokenizarla a mano.
% Ejemplo: ?- analizar_texto("Juan analiza el sistema", X).
% =========================================================


% acepta_texto(+Texto)
% Tokeniza y comprueba si la oración se acepta.
acepta_texto(Texto) :-
    tokenizar_basico(Texto, Lista),
    acepta(Lista).


% analizar_texto(+Texto, -Arbol)
% Tokeniza y devuelve el árbol.
analizar_texto(Texto, Arbol) :-
    tokenizar_basico(Texto, Lista),
    analizar(Lista, Arbol).


% analizar_texto(+Texto)
% Tokeniza e imprime el árbol.
analizar_texto(Texto) :-
    analizar_texto(Texto, Arbol),
    write(Arbol), nl.

% dibujar_texto(+Texto)
% Tokeniza, analiza y dibuja el árbol.
dibujar_texto(Texto) :-
    analizar_texto(Texto, Arbol),
    draw(Arbol).

% tipo_texto(+Texto, -Tipo)
% Tokeniza, analiza y devuelve el tipo de oración.
tipo_texto(Texto, Tipo) :-
    analizar_texto(Texto, Arbol),
    tipo_oracion(Arbol, Tipo).

% simplificar_texto(+Texto, -Simples)
% Tokeniza, analiza y simplifica.
simplificar_texto(Texto, Simples) :-
    analizar_texto(Texto, Arbol),
    simplificar(Arbol, Simples).

% =========================================================
% EJEMPLOS GENÉRICOS DE PRUEBA
% Estos ejemplos NO son el corpus final.
% Son solo pruebas rápidas para comprobar que el parser funciona.
% =========================================================

ejemplo(1, [juan, analiza, el, sistema]).
ejemplo(2, [el, algoritmo, procesa, los, datos]).
ejemplo(3, [el, paciente, esta, muy, estable]).
ejemplo(4, [juan, analiza, el, sistema, y, maria, evalua, el, modelo]).
ejemplo(5, [juan, ',', que, analiza, el, sistema, ',', presenta, el, resultado]).
ejemplo(6, [juan, ',', que, analiza, el, sistema, ',', presenta, el, resultado, pero, maria, evalua, el, modelo]).
ejemplo(7, [nunca, llueve, en, el, laboratorio]).
ejemplo(8, [juan, come, y, bebe]).

% =========================================================
% PREDICADOS DE PRUEBA
% =========================================================

% ---------------------------------------------------------
% probar_ejemplo(+N)
% Muestra:
%   - la lista original
%   - el árbol
%   - el tipo de oración
%   - la simplificación
%
% IMPORTANTE:
% Aquí usamos once(analizar(...)) para quedarnos con el primer análisis
% válido y evitar reparseos innecesarios o múltiples soluciones cuando no nos interesan.
% ---------------------------------------------------------
probar_ejemplo(N) :-
    ejemplo(N, Lista),
    write('Lista: '), write_term(Lista, [quoted(true)]), nl,
    ( once(analizar(Lista, Arbol)) ->
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
% Recorre todos los ejemplos definidos y los prueba uno a uno.
% Usamos forall/2 porque queda más limpio que el esquema con fail.
% ---------------------------------------------------------
probar_todos :-
    forall(
        ejemplo(N, _),
        (
            write('=============================='), nl,
            write('Ejemplo '), write(N), nl,
            probar_ejemplo(N)
        )
    ).

% =========================================================
% EJEMPLOS DE CONSULTAS ÚTILES

% 1) Sobre listas:
% ?- acepta([juan,analiza,el,sistema]).
% ?- analizar([juan,analiza,el,sistema], X).
% ?- dibujar([juan,analiza,el,sistema]).
% ?- tipo([juan,analiza,el,sistema,y,maria,evalua,el,modelo], T).
% ?- simplificar_oracion([juan,come,y,bebe], S).
%
% 2) Sobre texto:
% ?- acepta_texto("Juan analiza el sistema").
% ?- analizar_texto("Juan analiza el sistema", X).
% ?- dibujar_texto("Juan analiza el sistema").
%
% 3) Con comas:
% ?- tokenizar_basico("Juan, que analiza el sistema, presenta el resultado", L).
% ?- analizar_texto("Juan, que analiza el sistema, presenta el resultado", X).
%
% =========================================================