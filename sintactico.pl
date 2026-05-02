:- encoding(utf8).

% gramatica.pl
% Reglas DCG y predicados auxiliares del analizador sintáctico.
% El diccionario está en lexico.pl.

:- consult(draw).


% =========================================================
% REGLA PRINCIPAL
% =========================================================

oracion(O, Tokens, Resto) :-
    tokens_conocidos(Tokens),
    oracion_compuesta(O, Tokens, Resto).

% =========================================================
% TIPOS DE ORACION
%   o   = oración simple
%   oc  = oración coordinada
%   or  = oración de relativo
%   ocm = oración compuesta/mixta
% =========================================================

% Coordinación de dos oraciones simples:
%   "El efector puede usarse ... y se camufla ..."
%   "Reutilizamos ... y creamos ..."
oracion_compuesta_coord_simple(oc(O1, Conj, O2)) -->
    oracion_simple(O1),
    pausa_opcional,
    conjuncion_oracional(Conj),
    oracion_simple(O2).

% Coordinación donde alguno de los lados ya es complejo:
oracion_compuesta_coord_mixta(ocm(O1, Conj, O2)) -->
    oracion_no_coordinada(O1),
    pausa_opcional,
    conjuncion_oracional(Conj),
    oracion_compuesta(O2),
    {
        \+ es_oracion_simple(O1)
        ;
        \+ es_oracion_simple(O2)
    }.

% Yuxtaposicion con coma explicativa:
%   "Elegimos X por dos motivos, la presion ... y el exoesqueleto ..."
oracion_compuesta_yuxtapuesta(ocm(O1, pausa, O2)) -->
    oracion_simple(O1),
    pausa_obligatoria,
    oracion_compuesta_coord_simple(O2).

oracion_compuesta_yuxtapuesta(ocm(O1, pausa, O2)) -->
    oracion_simple(O1),
    pausa_obligatoria,
    oracion_compuesta(O2).

% Oración simple con complementos/subordinadas internas.
% Si la oración simple contiene subordinadas o relativas, puede clasificarse como ocm.
% una oración con complemento inicial, aunque estructuralmente sea simple, saldrá como ocm
oracion_compuesta_ocm_interna(ocm(O)) -->
    oracion_simple(O),
    { contiene_complejidad(O) }.

% Oración no coordinada:
oracion_compuesta(O, Tokens, Resto) :-
    hay_coma_conjuncion(Tokens),
    phrase(oracion_compuesta_coord_simple(O), Tokens, Resto).

oracion_compuesta(O, Tokens, Resto) :-
    hay_y_oracional(Tokens),
    phrase(oracion_compuesta_coord_simple(O), Tokens, Resto).

oracion_compuesta(O, Tokens, Resto) :-
    hay_coma_explicativa(Tokens),
    phrase(oracion_compuesta_yuxtapuesta(O), Tokens, Resto).

oracion_compuesta(O) -->
    oracion_no_coordinada(O).

oracion_compuesta(O) -->
    oracion_compuesta_ocm_interna(O).

oracion_compuesta(O) -->
    oracion_compuesta_coord_simple(O).

oracion_compuesta(O) -->
    oracion_compuesta_coord_mixta(O).

% =========================================================
% ORACIONES NO COORDINADAS
% =========================================================

% Oración de relativo:
%   "Los diseños que imitan la locomoción inspiran robots"
%   "Los datos que respaldan los hallazgos están disponibles"
oracion_no_coordinada_relativa(or(GN, Rel, GV)) -->
    g_nominal(GN),
    pausa_opcional,
    relativo_ampliado(Rel),
    pausa_opcional,
    g_verbal(GV).

oracion_no_coordinada(O) -->
    oracion_simple(O).

oracion_no_coordinada(O) -->
    oracion_no_coordinada_relativa(O).

% =========================================================
% ORACION SIMPLE (y aposición)
% =========================================================

% Oracion con sujeto omitido.
oracion_simple(o(CI, GN, GV, Apos), Tokens, Resto) :-
    hay_coma_estado(Tokens),
    phrase((
        complemento_inicial(CI),
        pausa_obligatoria,
        g_nominal(GN),
        g_verbal(GV),
        aposicion_final(Apos)
    ), Tokens, Resto).

oracion_simple(o(sujeto_eliptico, GV)) -->
    g_verbal(GV).

% Oracion simple normal con sujeto explícito.
oracion_simple(o(GN, GV)) -->
    g_nominal(GN),
    g_verbal(GV).

% Oración con sujeto + inciso entre comas + verbo:
%   "Todo el proceso, desde la insercion..., puede realizarse..."
%   "La presurizacion y la despresurizacion dan lugar, respectivamente, a..."
oracion_simple(o(GN, Inciso, GV)) -->
    g_nominal(GN),
    inciso_oracional(Inciso),
    g_verbal(GV).

% Oración con sujeto + verbo + inciso/complementos posteriores:
%   "La presurizacion ... dan lugar, respectivamente, a la apertura..."
oracion_simple(o(GN, GV, IncisoFinal)) -->
    g_nominal(GN),
    g_verbal(GV),
    inciso_oracional(IncisoFinal).

% Complemento inicial + oración con sujeto explícito:
%   "Además, el efector puede usarse..."
%   "En este trabajo, se reutiliza una araña..."
%   "Para estudiar la durabilidad, realizamos ensayos..."
oracion_simple(o(CI1, CI2, GN, GV)) -->
    complemento_inicial(CI1),
    pausa_obligatoria,
    complemento_inicial(CI2),
    pausa_opcional,
    g_nominal(GN),
    g_verbal(GV).

oracion_simple(o(CI, GN, GV)) -->
    complemento_inicial(CI),
    pausa_opcional,
    g_nominal(GN),
    g_verbal(GV).

% Complemento inicial + oración con sujeto omitido:
%   "Además, demostramos..."
%   "A continuación, repetimos..."
oracion_simple(o(CI1, CI2, sujeto_eliptico, GV)) -->
    complemento_inicial(CI1),
    pausa_obligatoria,
    complemento_inicial(CI2),
    pausa_opcional,
    g_verbal(GV).

oracion_simple(o(CI, sujeto_eliptico, GV)) -->
    complemento_inicial(CI),
    pausa_opcional,
    g_verbal(GV).

% Complemento inicial + impersonal:
%   "En este trabajo, se reutiliza una araña..."
%   "Por el contrario, se introduce presión..."
oracion_simple(o(CI, GV)) -->
    complemento_inicial(CI),
    pausa_opcional,
    g_verbal_impersonal(GV).


% Oración impersonal:
oracion_simple(o(GV)) -->
    g_verbal_impersonal(GV).


% Oración con complemento inicial, oración principal y aposición final:
%   "Cuando no se aplica presión ..., las patas permanecen ..., estado que denominamos neutro..."
oracion_simple(o(CI, GN, GV, Apos)) -->
    complemento_inicial(CI),
    pausa_obligatoria,
    g_nominal(GN),
    g_verbal(GV),
    aposicion_final(Apos).

% Oración normal con aposición final:
%   "Las patas permanecen flexionadas ..., estado que denominamos neutro..."
oracion_simple(o(GN, GV, Apos)) -->
    g_nominal(GN),
    g_verbal(GV),
    aposicion_final(Apos).

aposicion_final(apos_estado(N, Rel)) -->
    [','],
    nombre(N),
    relativo_ampliado(Rel).


% Aposición final introducida por coma.
aposicion_final(apos(GN)) -->
    [','],
    g_nominal(GN).

% =========================================================
% COMPLEMENTO INICIAL
% =========================================================
%
% Reconoce elementos antepuestos:
%   Además,
%   En este trabajo,
%   Por el contrario,
%   A continuación,
%   Para estudiar...
%   Cuando una araña muere,
%   Aunque...
%   Dado que...

complemento_inicial(ci_adv(GAdv)) -->
    g_adverbial(GAdv).

complemento_inicial(ci_gp(GP)) -->
    g_preposicional(GP).

complemento_inicial(ci_marcador(M)) -->
    marcador_discursivo(M).

complemento_inicial(ci_sub(Sub)) -->
    subordinada_inicial(Sub).

% Marcadores discursivos frecuentes del corpus.
marcador_discursivo(md(ademas)) --> [ademas].
marcador_discursivo(md(tambien)) --> [tambien].
marcador_discursivo(md(sin_embargo)) --> [sin, embargo].
marcador_discursivo(md(no_obstante)) --> [no, obstante].
marcador_discursivo(md(por_el_contrario)) --> [por, el, contrario].
marcador_discursivo(md(en_primer_lugar)) --> [en, primer, lugar].
marcador_discursivo(md(a_continuacion)) --> [a, continuacion].
marcador_discursivo(md(de_este_modo)) --> [de, este, modo].
marcador_discursivo(md(con_ello)) --> [con, ello].
marcador_discursivo(md(en_cambio)) --> [en, cambio].


% =========================================================
% RELATIVO
% =========================================================

% Mantengo el nombre relativo_simple/1 para no romper reglas antiguas.
relativo_simple(Rel) -->
    relativo_ampliado(Rel).

relativo_ampliado(Rel) -->
    relativo_base(Rel).

% Primero se intenta una relativa coordinada, pero sin recursión izquierda.
% Ejemplo:
%   "que denominamos neutro y que corresponde al agarre"
relativo_ampliado(rel_coord(Rel1, Conj, Rel2)) -->
    relativo_base(Rel1),
    conjuncion_coordinante(Conj),
    relativo_base(Rel2).

% Si no hay coordinación, se acepta una relativa base.
relativo_ampliado(Rel) -->
    relativo_base(Rel).

% Relativa simple sin sujeto explícito:
%   "que imitan la locomoción"
%   "que actúa como interruptor"
%   "que requiere un paso"
relativo_base(rel_lo_que(O)) -->
    [lo, que],
    oracion_simple(O).

relativo_base(rel_lo_que(GV)) -->
    [lo, que],
    g_verbal(GV).

relativo_base(rel(R, GV)) -->
    relativo(R),
    g_verbal(GV).

% Relativa con sujeto explícito:
%   "que los materiales bióticos emplean..."
%   "que la presión produce..."
relativo_base(rel(R, O)) -->
    relativo(R),
    oracion_simple(O).

% Relativa preposicional:
%   "en la que los materiales se emplean..."
%   "mediante el cual las arañas controlan..."
%   "durante los cuales medimos..."
relativo_base(rel_prep(P, Det, R, O)) -->
    preposicion(P),
    determinante(Det),
    relativo(R),
    oracion_simple(O).

% Relativa con "lo que":
%   "lo que provoca..."
%   "lo que permite..."
%   "lo que hizo..."
relativo_base(rel_lo_que(O)) -->
    [lo, que],
    oracion_simple(O).

% Relativa con "lo que" + verbo sin sujeto:
%   "lo que provoca que..."
%   "lo que permite evitar..."
relativo_base(rel_lo_que(GV)) -->
    [lo, que],
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
% INCISOS ORACIONALES
% =========================================================
%
% Reconoce fragmentos entre comas. No busca una interpretación
% perfecta del inciso, solo evita que la coma rompa la oración.

inciso_oracional(inciso(GP)) -->
    [','],
    g_preposicional(GP),
    [','].

inciso_oracional(inciso(GAdv)) -->
    [','],
    g_adverbial(GAdv),
    [','].

inciso_oracional(inciso(M)) -->
    [','],
    marcador_discursivo(M),
    [','].

inciso_oracional(inciso(PartF)) -->
    [','],
    participio_frase(PartF),
    [','].

inciso_oracional(inciso(Ger)) -->
    [','],
    gerundio_frase(Ger),
    [','].

% =========================================================
% GRUPO NOMINAL (GN)
% =========================================================

% Coordinación con coma: "Juan, María y Pedro"
g_nominal(GN) -->
    g_nominal_simple(GN).

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

% ---------------------------------------------------------
% GN simple: núcleo nominal + modificadores encadenados.
% Los modificadores se encadenan: mod(Mod1, mod(Mod2, none))
% ---------------------------------------------------------

% Determinante + adjetivo antepuesto + nombre:
%   "esta alta densidad"
%   "una fina capa"
g_nominal_simple(gn(D, N, Adj, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

g_nominal_simple(gn(D, N, Mods)) -->
    determinante(D),
    nombre(N),
    modificadores_nominales(Mods).

g_nominal_simple(gn(D, Adj, N, Mods)) -->
    determinante(D),
    g_adjetival(Adj),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + nombre + dos adjetivos:
%   "el efector final necrobotico"
%   "el material biotico bruto"
%   "una araña inanimada concreta"
g_nominal_simple(gn(D, N, Adj1, Adj2, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj1),
    adjetivo(Adj2),
    modificadores_nominales(Mods).

% Determinante + nombre + adjetivo:
%   "la pinza necrobotica"
%   "el efector final"
%   "el material biotico"
g_nominal_simple(gn(D, N, Adj, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

% Predeterminante + determinante + nombre:
%   "todo el proceso"
%   "todas las patas"
%   "todos los materiales"
g_nominal_simple(gn(D1, D2, N, Mods)) -->
    determinante(D1),
    determinante(D2),
    nombre(N),
    modificadores_nominales(Mods).

% Predeterminante + determinante + nombre + adjetivo:
%   "todas las patas flexionadas"
g_nominal_simple(gn(D1, D2, N, Adj, Mods)) -->
    determinante(D1),
    determinante(D2),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

% Determinante + nombre:
%   "la pinza"
%   "el prosoma"
g_nominal_simple(gn(D, N, Mods)) -->
    determinante(D),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + cantidad:
%   "el 130 %"
%   "los 1000 ciclos"
g_nominal_simple(gn(D, Cant, Mods)) -->
    determinante(D),
    cantidad(Cant),
    modificadores_nominales(Mods).

g_nominal_simple(gn(D, GP, Mods)) -->
    determinante(D),
    g_preposicional(GP),
    modificadores_nominales(Mods).

% Cantidad como núcleo nominal:
%   "130 %"
%   "17 veces"
%   "5 dias"
g_nominal_simple(gn(Cant, Mods)) -->
    cantidad(Cant),
    modificadores_nominales(Mods).

% Nombre sin determinante:
%   "araña"
%   "objetos"
%   "geometrias"
g_nominal_simple(gn(N, Mods)) -->
    nombre(N),
    modificadores_nominales(Mods).

g_nominal_simple(gn(Adj, N, Mods)) -->
    g_adjetival(Adj),
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
modificador_nominal(cant(Cant)) --> cantidad(Cant).
modificador_nominal(gadv(GAdv)) --> g_adverbial(GAdv).
modificador_nominal(partf(PartF)) --> participio_frase_nominal(PartF).
modificador_nominal(ger(Ger))   --> gerundio_frase(Ger).
modificador_nominal(n(n(X)))    --> [X], {nombre_word(X), \+ verbo_word(X)}.
modificador_nominal(part(part(X))) --> [X], {participio_nominal_valido(X)}.

% =========================================================
% GRUPO ADJETIVAL (GADJ)
% =========================================================

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

g_adjetival(gadj(GAdv, Adj, p(de), Inf)) -->
    g_adverbial(GAdv),
    adjetivo(Adj),
    [de],
    infinitivo_frase(Inf).

g_adjetival(gadj_coord(Adj1, Conj, GAdj2)) -->
    adjetivo(Adj1),
    conjuncion_coordinante(Conj),
    g_adjetival(GAdj2).

% adjetivo + grupo preposicional:
%   "capaz de agarrar objetos"
%   "susceptible a la fractura"
%   "similar a un extensor"
% Comparativa:
%   "más rígido que el abdomen"
%   "más duraderas que ..."
%   "mayor que ..."
g_adjetival(gadj_comp(Adv, Adj, que, GN)) -->
    adverbio(Adv),
    adjetivo(Adj),
    [que],
    g_nominal(GN).

% Comparativa con cantidad:
%   "17 veces mayor que la araña recubierta"
g_adjetival(gadj_comp_cant(Cant, Adj, que, GN)) -->
    cantidad(Cant),
    adjetivo(Adj),
    [que],
    g_nominal(GN).

% adjetivo + de + infinitivo:
%   "capaz de agarrar objetos"
%   "capaces de producir fuerzas"
g_adjetival(gadj(Adj, p(de), Inf)) -->
    adjetivo(Adj),
    [de],
    infinitivo_frase(Inf).

% adjetivo + para + infinitivo:
%   "listo para usar"
%   "útil para aplicaciones"
g_adjetival(gadj(Adj, p(para), inf(Inf))) -->
    adjetivo(Adj),
    [para],
    infinitivo(Inf).

g_adjetival(gadj(Adj, p(para), Inf)) -->
    adjetivo(Adj),
    [para],
    infinitivo_frase(Inf).

g_adjetival(gadj(Adj, GP)) -->
    adjetivo(Adj),
    g_preposicional(GP).

g_adjetival(gadj(Adj)) -->
    adjetivo(Adj).



% =========================================================
% GRUPO ADVERBIAL (GADV)
% =========================================================

g_adverbial(gadv(Adv)) -->
    adverbio(Adv).

% Dos adverbios seguidos:
%   "todavia no"
%   "muy bien"
g_adverbial(gadv(Adv1, Adv2)) -->
    adverbio(Adv1),
    adverbio(Adv2).

% Adverbio + adjetivo:
%   "plenamente operativa"
%   "completamente funcional"
%   "eficazmente como..." se tratará aparte como complemento
g_adverbial(gadv(Adv, Adj)) -->
    adverbio(Adv),
    adjetivo(Adj).

% Comparativa:
%   "mas rigido que el abdomen"
g_adverbial(gadv(Adv, Adj, GN)) -->
    adverbio(Adv),
    adjetivo(Adj),
    [que],
    g_nominal(GN).

% =========================================================
% GRUPO PREPOSICIONAL (GP)
% =========================================================

% Locución preposicional + GN:
%   "a través de la jeringuilla"
%   "debido a la deshidratación"
%   "gracias a los patrones"
%   "a diferencia de nuestra pinza"
g_preposicional(gp(p(de_que), O)) -->
    [de, que],
    oracion_compuesta(O).

g_preposicional(gp(Loc, GN)) -->
    locucion_preposicional(Loc),
    g_nominal(GN).

g_preposicional(gp(Loc, GN, Conj, GP)) -->
    locucion_preposicional(Loc),
    g_nominal(GN),
    conjuncion_coordinante(Conj),
    g_preposicional(GP).

% Locución preposicional + infinitivo:
%   "con el fin de comprender..."
%   "en lugar de diseñar..."
g_preposicional(gp(Loc, Inf)) -->
    locucion_preposicional(Loc),
    infinitivo_frase(Inf).

% Preposición + GN:
%   "de la araña"
%   "con geometrías irregulares"
g_preposicional(gp(P, GN)) -->
    preposicion(P),
    g_nominal(GN).

g_preposicional(gp(P, GAdv, GN)) -->
    preposicion(P),
    g_adverbial(GAdv),
    g_nominal(GN).

% Preposición + infinitivo:
%   "para agarrar objetos"
%   "al incorporar materiales"
g_preposicional(gp(P, inf(Inf))) -->
    preposicion(P),
    { P = p(sin) },
    infinitivo(Inf).

g_preposicional(gp(P, Inf)) -->
    preposicion(P),
    infinitivo_frase(Inf).

% Preposición + preposición + GN:
%   "de hasta el 130 %"
%   "por sobre el sistema" 
g_preposicional(gp(P1, P2, GN)) -->
    preposicion(P1),
    preposicion(P2),
    g_nominal(GN).

% =========================================================
% LOCUCIONES PREPOSICIONALES
% =========================================================

locucion_preposicional(p(a_traves_de)) --> [a, traves, de].
locucion_preposicional(p(debido_a)) --> [debido, a].
locucion_preposicional(p(despues_de)) --> [despues, de].
locucion_preposicional(p(gracias_a)) --> [gracias, a].
locucion_preposicional(p(al_margen_de)) --> [al, margen, de].
locucion_preposicional(p(a_diferencia_de)) --> [a, diferencia, de].
locucion_preposicional(p(en_contraste_con)) --> [en, contraste, con].
locucion_preposicional(p(al_final_de)) --> [al, final, de].
locucion_preposicional(p(en_menos_de)) --> [en, menos, de].
locucion_preposicional(p(del_orden_de)) --> [del, orden, de].
locucion_preposicional(p(en_lugar_de)) --> [en, lugar, de].
locucion_preposicional(p(con_el_fin_de)) --> [con, el, fin, de].
locucion_preposicional(p(a_partir_de)) --> [a, partir, de].
locucion_preposicional(p(mas_alla_de)) --> [mas, alla, de].
locucion_preposicional(p(aparte_de)) --> [aparte, de].
locucion_preposicional(p(a_pequenas_escalas_de)) --> [a, pequeñas, escalas, de].
locucion_preposicional(p(a_pequena_escala_de)) --> [a, pequeña, escala, de].

% =========================================================
% GRUPO VERBAL (GV)
% =========================================================

g_verbal(GV) -->
    g_verbal_simple(GV).

g_verbal(gv_coord(GV1, Conj, Inciso, GV2)) -->
    g_verbal_simple(GV1),
    conjuncion_verbal(Conj),
    inciso_oracional(Inciso),
    g_verbal_simple(GV2).

g_verbal(gv_coord(GV1, Conj, GV2)) -->
    g_verbal_simple(GV1),
    conjuncion_verbal(Conj),
    g_verbal_simple(GV2).

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

% gadv + se + auxiliar + participio + complementos:
%   "todavia no se ha explorado..."
g_verbal_simple(Nodo) -->
    g_adverbial(GAdv),
    pronombre_se(Se),
    auxiliar(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(GAdv, Se, Aux, comps(part(Part), Comps), Nodo) }.

% gadv + se + verbo + complementos:
%   "no se aplica presion..."
g_verbal_simple(Nodo) -->
    g_adverbial(GAdv),
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp3(GAdv, Se, V, Comps, Nodo) }.

% verbo copulativo + adjetivo + GN:
%   "es posible la actuacion manual"
g_verbal_simple(gv(VC, GAdj, GN)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj),
    g_nominal(GN).

% verbo copulativo + adjetivo + complementos opcionales:
%   "es capaz de agarrar..."
%   "estan disponibles en..."
g_verbal_simple(Nodo) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj),
    complementos_verbales(Comps),
    { gv_comp(VC, GAdj, Comps, Nodo) }.

% modal + ser + participio + complementos opcionales
g_verbal_simple(Nodo) -->
    modal(Modal),
    auxiliar_ser(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(Modal, Aux, Part, Comps, Nodo) }.

% modal + ser + grupo adjetival:
%   "pueden ser complicados o incluso imposibles de reproducir"
g_verbal_simple(Nodo) -->
    modal(Modal),
    auxiliar_ser(Aux),
    g_adjetival(GAdj),
    complementos_verbales(Comps),
    { gv_comp3(Modal, Aux, GAdj, Comps, Nodo) }.

% se + auxiliar + participio + complementos
g_verbal_simple(Nodo) -->
    pronombre_se(Se),
    auxiliar(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(Se, Aux, Part, Comps, Nodo) }.

% auxiliar + ser/sido + participio + complementos:
%   "han sido utilizados..."
%   "ha sido explorada..."
g_verbal_simple(Nodo) -->
    auxiliar(Aux),
    auxiliar_ser(AuxSer),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(Aux, AuxSer, Part, Comps, Nodo) }.

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

% gadv + verbo + complementos opcionales:
%   "solo requiere una etapa de fabricacion sencilla"
%   "tambien demostramos la capacidad..."
g_verbal_simple(Nodo) -->
    g_adverbial(GAdv),
    verbo(V),
    complementos_verbales(Comps),
    {
        ( Comps == none ->
            Nodo = gv(GAdv, V)
        ;
            Nodo = gv(GAdv, V, Comps)
        )
    }.

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

% gadv + verbo copulativo + gadj:
%   "no es injustificada"
%   "no están disponibles"
g_verbal_simple(gv(GAdv, VC, GAdj)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_adjetival(GAdj).

% gadv + verbo copulativo + gn:
%   "no es un problema"
g_verbal_simple(gv(GAdv, VC, GN)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_nominal(GN).

% gadv + verbo copulativo + gp:
%   "no está en el sistema"
g_verbal_simple(gv(GAdv, VC, GP)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_preposicional(GP).

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

g_verbal_simple(Nodo) -->
    verbo_copulativo(VC),
    g_preposicional(GP),
    complementos_verbales(Comps),
    { gv_comp(VC, GP, Comps, Nodo) }.

% auxiliar + participio + complementos opcionales:
%   "han inspirado robots..."
%   "ha inspirado el diseño..."
%   "han sido utilizados..." se cubre con otra regla más arriba
g_verbal_simple(Nodo) -->
    auxiliar(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp(Aux, Part, Comps, Nodo) }.

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

% pronombre personal atono + verbo + complementos:
%   "nos permite evitar..."
g_verbal_simple(Nodo) -->
    pronombre_personal(P),
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp(P, V, Comps, Nodo) }.

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

% ej: agarrar objetos con geometrías irregulares   y   de hasta el 130 % de su propia masa
% =========================================================
% COMPLEMENTOS VERBALES
% =========================================================

% Si aparece una coma en medio de complementos, la consumimos
% y seguimos buscando complementos. Esto permite incisos y
% frases científicas largas sin bloquear todo el análisis.
complementos_verbales(comps(Comp, Resto)) -->
    [','],
    complemento_verbal_poscoma(Comp),
    complementos_verbales(Resto).

% Coordinación de complementos:
%   "objetos con geometrias irregulares y de hasta el 130 %..."
%   "geometrias, volumenes y masas variables"
complementos_verbales(comps(Comp, Resto)) -->
    complemento_verbal(Comp),
    complementos_verbales(Resto).

complementos_verbales(comps_coord(Comp, Conj, Resto)) -->
    complemento_verbal(Comp),
    pausa_opcional,
    conjuncion_coordinante(Conj),
    complementos_verbales(Resto).

% Sin más complementos.
complementos_verbales(none) -->
    [].

complemento_verbal(gp(GP))       --> g_preposicional(GP).
complemento_verbal(rel(Rel))     --> relativo_ampliado(Rel).
complemento_verbal(ger(Ger))     --> gerundio_frase(Ger).
complemento_verbal(inf(Inf))     --> infinitivo_frase(Inf).
complemento_verbal(gn(GN))       --> g_nominal(GN).
complemento_verbal(partf(PartF)) --> participio_frase(PartF).
complemento_verbal(gadj(GAdj))   --> g_adjetival(GAdj).
complemento_verbal(gadv(GAdv))   --> g_adverbial(GAdv).
complemento_verbal(sub(Sub))     --> subordinada(Sub).
complemento_verbal(cant(Cant))   --> cantidad(Cant).

% Complemento predicativo simple:
%   "denominamos neutro"
%   "consideramos útil"
complemento_verbal(pred_adj(Adj)) -->
    adjetivo(Adj).

complemento_verbal(pred_nom(N)) -->
    nombre(N).

complemento_verbal_poscoma(rel(Rel))     --> relativo_ampliado(Rel).
complemento_verbal_poscoma(ger(Ger))     --> gerundio_frase(Ger).
complemento_verbal_poscoma(partf(PartF)) --> participio_incidental(PartF).
complemento_verbal_poscoma(sub(Sub))     --> subordinada(Sub).
complemento_verbal_poscoma(gp(GP))       --> g_preposicional_incidental(GP).
complemento_verbal_poscoma(gadv(GAdv))   --> g_adverbial_incidental(GAdv).

g_preposicional_incidental(GP) -->
    preposicion(P),
    { preposicion_incidental_word(P) },
    g_nominal(GN),
    { GP = gp(P, GN) }.

preposicion_incidental_word(p(entre)).
preposicion_incidental_word(p(debido)).
preposicion_incidental_word(p(a)).
preposicion_incidental_word(p(de)).
preposicion_incidental_word(p(sobre)).

g_adverbial_incidental(gadv(Adv)) -->
    adverbio(Adv),
    { adverbio_incidental_word(Adv) }.

adverbio_incidental_word(adv(respectivamente)).

participio_incidental(PartF) -->
    participio(Part),
    { participio_incidental_word(Part) },
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, PartF) }.

participio_incidental_word(Part) :-
    Part \= part(estado).

% =========================================================
% INFINITIVO FRASE
% =========================================================

inf_nodo(Inf, none,  inf(Inf)).
inf_nodo(Inf, Comps, inf(Inf, Comps)) :- Comps \= none.

infinitivo_frase(Nodo) -->
    infinitivo(Inf),
    complementos_verbales(Comps),
    { inf_nodo(Inf, Comps, Nodo) }.

infinitivo_frase(inf(AuxSer, Part, Comps)) -->
    auxiliar_ser(AuxSer),
    participio(Part),
    complementos_verbales(Comps).

% =========================================================
% GERUNDIO FRASE
% =========================================================
% Reconoce construcciones como:
%   "dando inicio al area..."
%   "completando asi el proceso..."
%   "contrayendo activamente musculos..."
%   "sacrificando una araña..."
%   "siguiendo un procedimiento..."

ger_nodo(Ger, none, ger(Ger)).
ger_nodo(Ger, Comps, ger(Ger, Comps)) :- Comps \= none.

gerundio_frase(Nodo) -->
    gerundio(Ger),
    complementos_verbales(Comps),
    { ger_nodo(Ger, Comps, Nodo) }.

% Gerundio + adverbio + complementos:
%   "contrayendo activamente musculos..."
%   "actuando efectivamente como..."
gerundio_frase(ger(Ger, GAdv, Comps)) -->
    gerundio(Ger),
    g_adverbial(GAdv),
    complementos_verbales(Comps).

% =========================================================
% PARTICIPIO FRASE
% =========================================================
% Reconoce construcciones como:
%   "destinado a ser agarrado por la pinza"
%   "compuesto por una maquina"
%   "basado en material biotico"
%   "relacionadas con la longevidad"

part_nodo(Part, none, partf(Part)).
part_nodo(Part, Comps, partf(Part, Comps)) :- Comps \= none.

participio_frase(Nodo) -->
    participio(Part),
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, Nodo) }.

participio_frase_nominal(Nodo) -->
    [X],
    { participio_nominal_valido(X), Part = part(X) },
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, Nodo) }.

participio_nominal_valido(X) :-
    part_word(X),
    \+ participio_finito_bloqueado(X).

participio_finito_bloqueado(aprovecha).
participio_finito_bloqueado(experimento).
participio_finito_bloqueado(presento).

% =========================================================
% SUBORDINADA
% =========================================================

% Subordinada normal:
%   "que las patas se curven..."
%   "aunque el sistema..."
subordinada(sub(Comp, O)) -->
    subordinante(Comp),
    pausa_opcional,
    oracion_compuesta(O).

% Subordinadas iniciales:
%   "Cuando una araña muere, ..."
%   "Aunque el uso de materiales..."
%   "Dado que las patas..."
%   "Si bien el uso..."
subordinada_inicial(sub_ini(Comp, O)) -->
    subordinante_inicial(Comp),
    oracion_compuesta(O).

% "Una vez fraguado el pegamento"
subordinada_inicial(sub_ini(una_vez, PartF)) -->
    [una, vez],
    participio_frase(PartF).

% "Tras la muerte"
subordinada_inicial(sub_ini(tras, GN)) -->
    [tras],
    g_nominal(GN).

% Algunos subordinantes iniciales aparecen en una sola palabra.
subordinante_inicial(subord(cuando)) --> [cuando].
subordinante_inicial(subord(aunque)) --> [aunque].
subordinante_inicial(subord(como)) --> [como].
subordinante_inicial(subord(mientras)) --> [mientras].

% Otros son compuestos.
subordinante_inicial(subord(si_bien)) --> [si, bien].
subordinante_inicial(subord(dado_que)) --> [dado, que].
subordinante_inicial(subord(ya_que)) --> [ya, que].
subordinante_inicial(subord(debido_a_que)) --> [debido, a, que].
subordinante_inicial(subord(en_cuanto)) --> [en, cuanto].
subordinante_inicial(subord(a_medida_que)) --> [a, medida, que].

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
gerundio(ger(X))        --> [X], {ger_word(X)}.
auxiliar_ser(aux(X))    --> [X], {aux_ser_word(X)}.
infinitivo(inf(X))      --> [X], {inf_word(X)}.
adjetivo(adj(X))        --> [X], {adj_word(X), \+ verbo_word(X)}.
adverbio(adv(X))        --> [X], {adv_word(X)}.
preposicion(p(X))       --> [X], {prep_word(X)}.
conjuncion(conj(X))     --> [X], {conj_word(X)}.
relativo(relat(X))      --> [X], {rel_word(X)}.
subordinante(subord(tal_y_como)) --> [tal, y, como].
subordinante(subord(X)) --> [X], {subord_word(X)}.
pronombre_se(se(X))     --> [X], {se_word(X)}.
pronombre_personal(pron(X)) --> [X], {pron_personal_word(X)}.

% =========================================================
% CANTIDADES, NÚMEROS Y UNIDADES
% =========================================================
%
% Permite reconocer expresiones como:
%   130 %
%   0.35 mn
%   33.5 mg
%   5.5 kpa
%   1000 ciclos
%   17 veces
%
% El tokenizador debe haber convertido "0,35" en "0.35".

numero(num(X)) -->
    [X],
    { atom_number(X, _) }.

numero(num(X)) -->
    [X],
    { rango_numerico_atom(X) }.

unidad(unidad(X)) -->
    [X],
    { unidad_word(X) }.

cantidad(cant(Num)) -->
    numero(Num).

cantidad(cant(Num, Unidad)) -->
    numero(Num),
    unidad(Unidad).

cantidad(cant(Num, porcentaje)) -->
    numero(Num),
    ['%'].

cantidad(cant(Num, por_ciento)) -->
    numero(Num),
    [por, ciento].

cantidad(cant(Num, veces)) -->
    numero(Num),
    [veces].


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

pausa_obligatoria --> [','].

% =========================================================
% PREDICADOS AUXILIARES
% =========================================================

tokens_conocidos([]).

tokens_conocidos([Token|Resto]) :-
    token_conocido(Token),
    tokens_conocidos(Resto).

token_conocido(',') :- !.
token_conocido('%') :- !.
token_conocido(Token) :- atom_number(Token, _), !.
token_conocido(Token) :- rango_numerico_atom(Token), !.
token_conocido(Token) :- det_word(Token), !.
token_conocido(Token) :- nombre_word(Token), !.
token_conocido(Token) :- verbo_word(Token), !.
token_conocido(Token) :- vc_word(Token), !.
token_conocido(Token) :- vi_word(Token), !.
token_conocido(Token) :- aux_word(Token), !.
token_conocido(Token) :- aux_ser_word(Token), !.
token_conocido(Token) :- part_word(Token), !.
token_conocido(Token) :- modal_word(Token), !.
token_conocido(Token) :- ger_word(Token), !.
token_conocido(Token) :- inf_word(Token), !.
token_conocido(Token) :- adj_word(Token), !.
token_conocido(Token) :- adv_word(Token), !.
token_conocido(Token) :- prep_word(Token), !.
token_conocido(Token) :- conj_word(Token), !.
token_conocido(Token) :- conj_coord_word(Token), !.
token_conocido(Token) :- rel_word(Token), !.
token_conocido(Token) :- subord_word(Token), !.
token_conocido(Token) :- se_word(Token), !.
token_conocido(Token) :- pron_personal_word(Token), !.
token_conocido(Token) :- unidad_word(Token), !.

hay_coma_conjuncion([',', Conj|_]) :-
    conj_coord_word(Conj),
    !.

hay_coma_conjuncion([_|Resto]) :-
    hay_coma_conjuncion(Resto).

hay_y_oracional([y, se|_]) :- !.
hay_y_oracional([y, Det, _, se|_]) :-
    det_word(Det),
    !.
hay_y_oracional([_|Resto]) :-
    hay_y_oracional(Resto).

hay_coma_explicativa([Marcador, ','|_]) :-
    marcador_enumerativo(Marcador),
    !.

hay_coma_explicativa([_|Resto]) :-
    hay_coma_explicativa(Resto).

marcador_enumerativo(motivos).
marcador_enumerativo(razones).

hay_coma_estado([',', estado|_]) :- !.
hay_coma_estado([_|Resto]) :-
    hay_coma_estado(Resto).

rango_numerico_atom(Token) :-
    atom(Token),
    atom_codes(Token, Codes),
    append(A, [45|B], Codes),
    A \= [],
    B \= [],
    todos_digitos(A),
    todos_digitos(B).

todos_digitos([]).

todos_digitos([C|Resto]) :-
    code_type(C, digit),
    todos_digitos(Resto).

% ---------------------------------------------------------
% contiene_complejidad/1
% Detecta si una oración simple contiene subordinación,
% relativa, complemento inicial o coordinación verbal.
% Sirve para clasificar como ocm frases que formalmente
% son o(...), pero tienen estructura interna compleja.
% ---------------------------------------------------------

contiene_complejidad(Term) :-
    sub_term(Sub, Term),
    es_nodo_complejo(Sub),
    !.

es_nodo_complejo(gv_coord(_,_,_)).
es_nodo_complejo(sub(_,_)).
es_nodo_complejo(sub_ini(_,_)).
es_nodo_complejo(rel(_,_)).
es_nodo_complejo(rel_prep(_,_,_,_)).
es_nodo_complejo(rel_lo_que(_)).
es_nodo_complejo(ci_adv(_)).
es_nodo_complejo(ci_gp(_)).
es_nodo_complejo(ci_marcador(_)).
es_nodo_complejo(ci_sub(_)).

% ---------------------------------------------------------
% es_oracion_simple/1
% ---------------------------------------------------------
es_oracion_simple(o(_, _)).
es_oracion_simple(o(_)).

% ---------------------------------------------------------
% tipo_oracion/2
% ---------------------------------------------------------
tipo_oracion(oc(_,_,_),  oc).
tipo_oracion(or(_,_,_),  or).
tipo_oracion(ocm(_,_,_), ocm).
tipo_oracion(ocm(_),     ocm).

tipo_oracion(O, ocm) :-
    contiene_complejidad(O),
    !.

tipo_oracion(o(_, _), o).
tipo_oracion(o(_),    o).
tipo_oracion(o(_,_,_), o).

% ---------------------------------------------------------
% simplificar/2
% Convierte una oración compleja en lista de oraciones simples.
% ---------------------------------------------------------

% Compuesta mixta de una sola oración con complejidad interna:
%   ocm(o(...))
% Se simplifica simplificando su contenido interno.
simplificar(ocm(O), Resultado) :-
    simplificar(O, Resultado).

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

% Complemento inicial + sujeto compartido + predicado coordinado
simplificar(o(CI, GN, gv_coord(GV1, _, GV2)), Resultado) :-
    simplificar(o(CI, GN, GV1), R1),
    simplificar(o(CI, GN, GV2), R2),
    append(R1, R2, Resultado).

% Complemento inicial + sujeto elíptico + predicado coordinado
simplificar(o(CI, sujeto_eliptico, gv_coord(GV1, _, GV2)), Resultado) :-
    simplificar(o(CI, sujeto_eliptico, GV1), R1),
    simplificar(o(CI, sujeto_eliptico, GV2), R2),
    append(R1, R2, Resultado).

% Sujeto elíptico + predicado coordinado
simplificar(o(sujeto_eliptico, gv_coord(GV1, _, GV2)), Resultado) :-
    simplificar(o(sujeto_eliptico, GV1), R1),
    simplificar(o(sujeto_eliptico, GV2), R2),
    append(R1, R2, Resultado).

% ---------------------------------------------------------
% analiza_lista/2
% ---------------------------------------------------------
analiza_lista(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).
