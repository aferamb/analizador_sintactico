% gramatica.pl
% Reglas DCG y predicados auxiliares del analizador sintáctico.
% El diccionario está en lexico.pl.

:- consult(draw).
:- consult(lexico).

% =========================================================
% REGLA PRINCIPAL
% =========================================================

oracion(O) -->
    oracion_compuesta(O).

% =========================================================
% TIPOS DE ORACION
%   o   = oración simple
%   oc  = oración coordinada
%   or  = oración de relativo
%   ocm = oración compuesta/mixta
% =========================================================

oracion_compuesta(oc(O1, Conj, O2)) -->
    oracion_simple(O1),
    conjuncion_oracional(Conj),
    oracion_simple(O2).

oracion_compuesta(ocm(O1, Conj, O2)) -->
    oracion_no_coordinada(O1),
    conjuncion_oracional(Conj),
    oracion_compuesta(O2),
    { \+ es_oracion_simple(O1) }.

oracion_compuesta(ocm(O1, Conj, O2)) -->
    oracion_simple(O1),
    conjuncion_oracional(Conj),
    oracion_compuesta(O2),
    { \+ es_oracion_simple(O2) }.

oracion_compuesta(O) -->
    oracion_no_coordinada(O).

% =========================================================
% ORACIONES NO COORDINADAS
% =========================================================

oracion_no_coordinada(or(GN, Rel, GV)) -->
    g_nominal(GN),
    pausa_opcional,
    relativo_simple(Rel),
    pausa_opcional,
    g_verbal(GV).

oracion_no_coordinada(O) -->
    oracion_simple(O).

% =========================================================
% ORACION SIMPLE
% =========================================================

oracion_simple(o(GN, GV)) -->
    g_nominal(GN),
    g_verbal(GV).

oracion_simple(o(GV)) -->
    g_verbal_impersonal(GV).

% =========================================================
% RELATIVO
% =========================================================

relativo_simple(rel(R, GV)) -->
    relativo(R),
    g_verbal(GV).

% =========================================================
% ALIASES
% =========================================================

gn(GN)     --> g_nominal(GN).
gv(GV)     --> g_verbal(GV).
gp(GP)     --> g_preposicional(GP).
gadj(GAdj) --> g_adjetival(GAdj).
gadv(GAdv) --> g_adverbial(GAdv).

% =========================================================
% GRUPO NOMINAL (GN)
% =========================================================

% Coordinación con coma: "Juan, María y Pedro"
g_nominal(gn_lista(GN1, GN2, Conj, GN3)) -->
    g_nominal_simple(GN1),
    [','],
    g_nominal_simple(GN2),
    conjuncion_nominal(Conj),
    g_nominal_simple(GN3).

% Coordinación simple: "Juan y María"
g_nominal(gn(GN1, Conj, GN2)) -->
    g_nominal_simple(GN1),
    conjuncion_nominal(Conj),
    g_nominal_simple(GN2).

g_nominal(GN) -->
    g_nominal_simple(GN).

% ---------------------------------------------------------
% GN simple: núcleo nominal + modificadores encadenados.
% Los modificadores se encadenan: mod(Mod1, mod(Mod2, none))
% ---------------------------------------------------------

g_nominal_simple(gn(D, Adj, N, Mods)) -->
    determinante(D),
    g_adjetival(Adj),
    nombre(N),
    modificadores_nominales(Mods).

g_nominal_simple(gn(D, N, Mods)) -->
    determinante(D),
    nombre(N),
    modificadores_nominales(Mods).

g_nominal_simple(gn(N, Mods)) -->
    nombre(N),
    modificadores_nominales(Mods).

% ---------------------------------------------------------
% Modificadores nominales como árbol binario encadenado.
% mod(Mod_actual, Resto)  o  none  si no hay más.
% ---------------------------------------------------------

modificadores_nominales(mod(Mod, Resto)) -->
    modificador_nominal(Mod),
    modificadores_nominales(Resto).

modificadores_nominales(none) -->
    [].

modificador_nominal(gadj(GAdj)) --> g_adjetival(GAdj).
modificador_nominal(gp(GP))     --> g_preposicional(GP).
modificador_nominal(rel(Rel))   --> relativo_simple(Rel).
modificador_nominal(n(N))       --> nombre(N).

% =========================================================
% GRUPO ADJETIVAL (GADJ)
% =========================================================

g_adjetival(gadj(Adj)) -->
    adjetivo(Adj).

g_adjetival(gadj(GAdv, Adj)) -->
    g_adverbial(GAdv),
    adjetivo(Adj).

g_adjetival(gadj(Adj1, Adj2)) -->
    adjetivo(Adj1),
    adjetivo(Adj2).

g_adjetival(gadj(GAdv, Adj, GP)) -->
    g_adverbial(GAdv),
    adjetivo(Adj),
    g_preposicional(GP).

% =========================================================
% GRUPO ADVERBIAL (GADV)
% =========================================================

g_adverbial(gadv(Adv)) -->
    adverbio(Adv).

g_adverbial(gadv(Adv, Adj, GN)) -->
    adverbio(Adv),
    adjetivo(Adj),
    [que],
    g_nominal(GN).

% =========================================================
% GRUPO PREPOSICIONAL (GP)
% =========================================================

g_preposicional(gp(P, GN)) -->
    preposicion(P),
    g_nominal(GN).

g_preposicional(gp(P, Inf)) -->
    preposicion(P),
    infinitivo_frase(Inf).

% =========================================================
% GRUPO VERBAL (GV)
% =========================================================

g_verbal(gv_coord(GV1, Conj, GV2)) -->
    g_verbal_simple(GV1),
    conjuncion_verbal(Conj),
    g_verbal_simple(GV2).

g_verbal(GV) -->
    g_verbal_simple(GV).

% =========================================================
% GRUPO VERBAL SIMPLE
%
% Complementos opcionales se gestionan con helpers:
%   gv_comp/4  -> para patrones con 2 args fijos
%   gv_comp3/5 -> para patrones con 3 args fijos
%   gv_comp_v/3 -> para verbo solo vs verbo+comps
% Estos colapsan none para no introducir nodos vacíos en el árbol.
% =========================================================

gv_comp(A, B, none,  gv(A, B)).
gv_comp(A, B, Comps, gv(A, B, Comps)) :- Comps \= none.

gv_comp3(A, B, C, none,  gv(A, B, C)).
gv_comp3(A, B, C, Comps, gv(A, B, C, Comps)) :- Comps \= none.

gv_comp_v(V, none,  gv(V)).
gv_comp_v(V, Comps, gv(V, Comps)) :- Comps \= none.

% se + verbo + complementos opcionales
g_verbal_simple(Nodo) -->
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp(Se, V, Comps, Nodo) }.

% modal + infinitivo + complementos opcionales
g_verbal_simple(Nodo) -->
    modal(Modal),
    infinitivo(Inf),
    complementos_verbales(Comps),
    { gv_comp(Modal, Inf, Comps, Nodo) }.

% modal + ser + participio + complementos opcionales
g_verbal_simple(Nodo) -->
    modal(Modal),
    auxiliar_ser(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(Modal, Aux, Part, Comps, Nodo) }.

% verbo copulativo + infinitivo
g_verbal_simple(gv(VC, Inf)) -->
    verbo_copulativo(VC),
    infinitivo(Inf).

% verbo + gn + gp
g_verbal_simple(gv(V, GN, GP)) -->
    verbo(V),
    g_nominal(GN),
    g_preposicional(GP).

% verbo + gn + gadv
g_verbal_simple(gv(V, GN, GAdv)) -->
    verbo(V),
    g_nominal(GN),
    g_adverbial(GAdv).

% gadv + verbo + gn
g_verbal_simple(gv(GAdv, V, GN)) -->
    g_adverbial(GAdv),
    verbo(V),
    g_nominal(GN).

% gadv + verbo + gp
g_verbal_simple(gv(GAdv, V, GP)) -->
    g_adverbial(GAdv),
    verbo(V),
    g_preposicional(GP).

% verbo + gp
g_verbal_simple(gv(V, GP)) -->
    verbo(V),
    g_preposicional(GP).

% verbo + gn
g_verbal_simple(gv(V, GN)) -->
    verbo(V),
    g_nominal(GN).

% verbo + gadj
g_verbal_simple(gv(V, GAdj)) -->
    verbo(V),
    g_adjetival(GAdj).

% verbo + gadv
g_verbal_simple(gv(V, GAdv)) -->
    verbo(V),
    g_adverbial(GAdv).

% gadv + verbo
g_verbal_simple(gv(GAdv, V)) -->
    g_adverbial(GAdv),
    verbo(V).

% verbo copulativo + gadj + gp
g_verbal_simple(gv(VC, GAdj, GP)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj),
    g_preposicional(GP).

% verbo copulativo + gadj
g_verbal_simple(gv(VC, GAdj)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj).

% verbo copulativo + gn
g_verbal_simple(gv(VC, GN)) -->
    verbo_copulativo(VC),
    g_nominal(GN).

% auxiliar + participio + gp
g_verbal_simple(gv(Aux, Part, GP)) -->
    auxiliar(Aux),
    participio(Part),
    g_preposicional(GP).

% auxiliar + participio + gn
g_verbal_simple(gv(Aux, Part, GN)) -->
    auxiliar(Aux),
    participio(Part),
    g_nominal(GN).

% auxiliar + participio
g_verbal_simple(gv(Aux, Part)) -->
    auxiliar(Aux),
    participio(Part).

% verbo + complementos opcionales (patrón general, al final para no
% interferir con los patrones específicos anteriores)
g_verbal_simple(Nodo) -->
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp_v(V, Comps, Nodo) }.

% =========================================================
% VERBOS IMPERSONALES
% =========================================================

g_verbal_impersonal(gv(GAdv, VI, GP)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI),
    g_preposicional(GP).

g_verbal_impersonal(gv(VI, GP)) -->
    verbo_impersonal(VI),
    g_preposicional(GP).

g_verbal_impersonal(gv(GAdv, VI)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI).

g_verbal_impersonal(gv(VI)) -->
    verbo_impersonal(VI).

% se + verbo + complementos opcionales (impersonal)
g_verbal_impersonal(Nodo) -->
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp(Se, V, Comps, Nodo) }.

% =========================================================
% COMPLEMENTOS VERBALES — ÁRBOL BINARIO ENCADENADO
%
% comps(Comp_actual, Resto)  donde Resto es comps(...) o none.
% Equivale a la lista [C1,C2,C3] pero en forma de árbol
% que draw.pl puede dibujar sin problemas.
% =========================================================

complementos_verbales(comps(Comp, Resto)) -->
    complemento_verbal(Comp),
    complementos_verbales(Resto).

complementos_verbales(none) -->
    [].

complemento_verbal(sub(Sub))   --> subordinada(Sub).
complemento_verbal(inf(Inf))   --> infinitivo_frase(Inf).
complemento_verbal(gp(GP))     --> g_preposicional(GP).
complemento_verbal(gn(GN))     --> g_nominal(GN).
complemento_verbal(gadj(GAdj)) --> g_adjetival(GAdj).
complemento_verbal(gadv(GAdv)) --> g_adverbial(GAdv).

% =========================================================
% INFINITIVO FRASE
% =========================================================

inf_nodo(Inf, none,  inf(Inf)).
inf_nodo(Inf, Comps, inf(Inf, Comps)) :- Comps \= none.

infinitivo_frase(Nodo) -->
    infinitivo(Inf),
    complementos_verbales(Comps),
    { inf_nodo(Inf, Comps, Nodo) }.

% =========================================================
% SUBORDINADA
% =========================================================

subordinada(sub(Comp, O)) -->
    subordinante(Comp),
    oracion_compuesta(O).

% =========================================================
% LÉXICO: CONVERSIÓN DE PALABRAS A CATEGORÍAS
% =========================================================

determinante(det(X))    --> [X], {det_word(X)}.
nombre(n(X))            --> [X], {nombre_word(X)}.
verbo(v(X))             --> [X], {verbo_word(X)}.
verbo_copulativo(vc(X)) --> [X], {vc_word(X)}.
verbo_impersonal(vi(X)) --> [X], {vi_word(X)}.
auxiliar(aux(X))        --> [X], {aux_word(X)}.
participio(part(X))     --> [X], {part_word(X)}.
modal(mod(X))           --> [X], {modal_word(X)}.
auxiliar_ser(aux(X))    --> [X], {aux_ser_word(X)}.
infinitivo(inf(X))      --> [X], {inf_word(X)}.
adjetivo(adj(X))        --> [X], {adj_word(X)}.
adverbio(adv(X))        --> [X], {adv_word(X)}.
preposicion(p(X))       --> [X], {prep_word(X)}.
conjuncion(conj(X))     --> [X], {conj_word(X)}.
relativo(relat(X))      --> [X], {rel_word(X)}.
subordinante(subord(X)) --> [X], {subord_word(X)}.
pronombre_se(se(X))     --> [X], {se_word(X)}.

% =========================================================
% CONJUNCIONES
% =========================================================

conjuncion_oracional(Conj) -->
    conjuncion(Conj),
    { Conj \= conj(si) }.

conjuncion_nominal(Conj) --> conjuncion_coordinante(Conj).
conjuncion_verbal(Conj)  --> conjuncion_coordinante(Conj).

conjuncion_coordinante(conj(X)) --> [X], {conj_coord_word(X)}.

% =========================================================
% PAUSA OPCIONAL (coma)
% =========================================================

pausa_opcional --> [','].
pausa_opcional --> [].

% =========================================================
% PREDICADOS AUXILIARES
% =========================================================

% ---------------------------------------------------------
% es_oracion_simple/1
% ---------------------------------------------------------
es_oracion_simple(o(_, _)).
es_oracion_simple(o(_)).

% ---------------------------------------------------------
% tipo_oracion/2
% ---------------------------------------------------------
tipo_oracion(o(_, _),    o).
tipo_oracion(o(_),       o).
tipo_oracion(oc(_,_,_),  oc).
tipo_oracion(or(_,_,_),  or).
tipo_oracion(ocm(_,_,_), ocm).

% ---------------------------------------------------------
% simplificar/2
% Convierte una oración compleja en lista de oraciones simples.
% ---------------------------------------------------------

% Predicado coordinado con sujeto compartido
simplificar(o(GN, gv_coord(GV1, _, GV2)), Resultado) :-
    simplificar(o(GN, GV1), R1),
    simplificar(o(GN, GV2), R2),
    append(R1, R2, Resultado).

% Oración simple con sujeto
simplificar(o(GN, GV), [o(GN, GV)]).

% Oración impersonal
simplificar(o(GV), [o(GV)]).

% Coordinación de oraciones
simplificar(oc(O1, _, O2), Resultado) :-
    simplificar(O1, R1),
    simplificar(O2, R2),
    append(R1, R2, Resultado).

% Compuesta mixta
simplificar(ocm(O1, _, O2), Resultado) :-
    simplificar(O1, R1),
    simplificar(O2, R2),
    append(R1, R2, Resultado).

% Relativa
simplificar(or(GN, rel(_, GVRel), GVPrinc), Resultado) :-
    simplificar(o(GN, GVRel), RRel),
    simplificar(o(GN, GVPrinc), RPrinc),
    append(RRel, RPrinc, Resultado).

% ---------------------------------------------------------
% analiza_lista/2
% ---------------------------------------------------------
analiza_lista(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).
