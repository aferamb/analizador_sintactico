
% sintactico.pl

% Este archivo implementa una gramática de cláusulas definidas (DCG)
% en Prolog para analizar sintácticamente oraciones y construir su árbol de constituyentes.


:- consult(draw).

% =========================================================
% REGLA PRINCIPAL

% Esta es la "puerta de entrada" del parser.
% Si alguien llama a: phrase(oracion(Arbol), Lista)
% intentaremos reconocer la Lista completa como una oración.
%
% En vez de saltar directamente a "oracion_simple", vamos a una
% capa superior llamada "oracion_compuesta", porque así cubrimos:
%   - simples
%   - coordinadas
%   - relativas
%   - compuestas
%
% =========================================================

oracion(O) -->
    oracion_compuesta(O).

% =========================================================
% TIPOS DE ORACION
%   o   = oración simple
%   oc  = oración coordinada simple
%   or  = oración de relativo (base simplificada)
%   ocm = oración compuesta/mixta
%
% IDEA PRÁCTICA:
% Queremos distinguir estos casos:
% 1) "Juan analiza el sistema"  -> o(...)
% 2) "Juan analiza el sistema y María evalúa el modelo"  -> oc(...)
% 3) "Juan, que analiza el sistema, presenta el resultado"  -> or(...)
% 4) "Juan, que analiza el sistema, presenta el resultado, pero María evalúa el modelo"  -> ocm(...)
% =========================================================

% ---------------------------------------------------------
% Caso 1: oración coordinada simple

% Este caso representa SOLO: oración simple + conjunción + oración simple
% Ejemplo: "Juan analiza el sistema y María evalúa el modelo"
% Árbol: oc(O1, Conj, O2)

% Lo ponemos antes que otros casos para que, cuando algo sea una
% coordinada simple "limpia", Prolog la clasifique así y no como ocm.
% ---------------------------------------------------------
oracion_compuesta(oc(O1, Conj, O2)) -->
    oracion_simple(O1),
    conjuncion_oracional(Conj),
    oracion_simple(O2).

% ---------------------------------------------------------
% Caso 2: oración compuesta mixta / encadenada

% Aquí queremos capturar combinaciones más complejas.
% Ejemplo: "Juan, que analiza el sistema, presenta el resultado, pero María evalúa el modelo"

% La idea es:
%   - la parte izquierda no es una simple pura
%   - o la parte derecha no es una simple pura

% Para evitar que todo se clasifique como ocm, usamos una condición auxiliar: al menos una de las partes debe NO ser simple.
% NOTA: es_oracion_simple/1 se define más abajo.
% ---------------------------------------------------------
oracion_compuesta(ocm(O1, Conj, O2)) -->
    oracion_no_coordinada(O1),
    conjuncion_oracional(Conj),
    oracion_compuesta(O2),
    {
        \+ es_oracion_simple(O1)
    }.

oracion_compuesta(ocm(O1, Conj, O2)) -->
    oracion_simple(O1),
    conjuncion_oracional(Conj),
    oracion_compuesta(O2),
    {
        \+ es_oracion_simple(O2)
    }.

% ---------------------------------------------------------
% Caso 3: si no es coordinada ni compuesta mixta, intentamos parsearla como oración no coordinada.
% ---------------------------------------------------------
oracion_compuesta(O) -->
    oracion_no_coordinada(O).

% =========================================================
% ORACIONES NO COORDINADAS
% Aquí metemos dos grandes casos:
%   - oración relativa (or)
%   - oración simple normal (o)
% =========================================================

% ---------------------------------------------------------
% Caso relativo (versión base simplificada)
% Patrón: GN + relativo + GV
% Ejemplo: "Juan que analiza el sistema presenta el resultado"
% Lo representamos como: or(GN, Rel, GV)
%
% IMPORTANTE:
% Esto no modela toda la teoría sintáctica real de las relativas;
% aquí hacemos una simplificación práctica útil para la práctica.
% ---------------------------------------------------------
oracion_no_coordinada(or(GN, Rel, GV)) -->
    g_nominal(GN),
    pausa_opcional,
    relativo_simple(Rel),
    pausa_opcional,
    g_verbal(GV).

% Si no es relativa, intentamos oración simple.
oracion_no_coordinada(O) -->
    oracion_simple(O).

% =========================================================
% ORACION SIMPLE
%
% Dos casos básicos:
% 1) Con sujeto explícito: GN + GV
%    Ejemplo: "Juan analiza el sistema"
% 2) Impersonal / sin sujeto explícito: GV impersonal
%    Ejemplo: "Llueve" / "Nunca llueve en el laboratorio"
% =========================================================

% Oración simple con sujeto explícito
oracion_simple(o(GN, GV)) -->
    g_nominal(GN),
    g_verbal(GV).

% ---------------------------------------------------------
% Oración simple impersonal
%
% Ejemplo: "Llueve" / "Nunca llueve en el laboratorio"
% Aquí el árbol queda como: o(GV)  porque no hay GN explícito.
% ---------------------------------------------------------
oracion_simple(o(GV)) -->
    g_verbal_impersonal(GV).

% =========================================================
% RELATIVO (BASE)
%
% Este bloque reconoce la parte: que + grupo verbal
% Ejemplo: "que analiza el sistema"
% Árbol: rel(relat(que), gv(...))
% =========================================================

relativo_simple(rel(R, GV)) -->
    relativo(R),
    g_verbal(GV).

% =========================================================
% ALIASES DE GRUPOS SINTACTICOS
% Para:
%   - mantener compatibilidad con vuestro estilo
%   - hacer consultas más cómodas
% Ejemplo:
%   ?- phrase(gn(X), [el,sistema], []).
%
% =========================================================

gn(GN) -->
    g_nominal(GN).

gv(GV) -->
    g_verbal(GV).

gp(GP) -->
    g_preposicional(GP).

gadj(GAdj) -->
    g_adjetival(GAdj).

gadv(GAdv) -->
    g_adverbial(GAdv).

% =========================================================
% GRUPO NOMINAL (GN)
%
% Un grupo nominal es el "bloque nominal" que suele hacer de sujeto u objeto.
% =========================================================

% ---------------------------------------------------------
% Coordinación nominal
%
% Ejemplo: "Juan y María"
% NOTA:
%   Solo coordinamos dos grupos nominales simples. Esto nos vale muy bien para una primera versión.
% ---------------------------------------------------------
g_nominal(gn_lista(GN1, GN2, Conj, GN3)) -->
    g_nominal_simple(GN1),
    [','],
    g_nominal_simple(GN2),
    conjuncion_nominal(Conj),
    g_nominal_simple(GN3).

g_nominal(gn(GN1, Conj, GN2)) -->
    g_nominal_simple(GN1),
    conjuncion_nominal(Conj),
    g_nominal_simple(GN2).

% Si no es coordinación nominal, es un GN simple.
g_nominal(GN) -->
    g_nominal_simple(GN).

% ---------------------------------------------------------
% GN = determinante + nombre + grupo adjetival + grupo prep.
% Ejemplo:"el sistema digital de control"
% ---------------------------------------------------------
g_nominal_simple(gn(Base, Mods)) -->
    g_nominal_base(Base),
    modificadores_nominales(Mods).

g_nominal_base(base(D, GAdj, N)) -->
    determinante(D),
    g_adjetival(GAdj),
    nombre(N).

g_nominal_base(base(D, N)) -->
    determinante(D),
    nombre(N).

g_nominal_base(base(N)) -->
    nombre(N).

modificadores_nominales(mods([Mod|Resto])) -->
    modificador_nominal(Mod),
    modificadores_nominales_restantes(Resto).

modificadores_nominales(mods([])) -->
    [].

modificadores_nominales_restantes([Mod|Resto]) -->
    modificador_nominal(Mod),
    modificadores_nominales_restantes(Resto).

modificadores_nominales_restantes([]) -->
    [].

modificador_nominal(mod_gadj(GAdj)) -->
    g_adjetival(GAdj).

modificador_nominal(mod_gp(GP)) -->
    g_preposicional(GP).

modificador_nominal(mod_rel(Rel)) -->
    relativo_simple(Rel).

modificador_nominal(mod_n(N)) -->
    nombre(N).

% =========================================================
% GRUPO ADJETIVAL (GADJ)
% Un grupo adjetival describe o modifica a un nombre o aparece en predicados copulativos.
% =========================================================

% ---------------------------------------------------------
% GADJ = adjetivo solo
% Ejemplo:"estable"
% ---------------------------------------------------------
g_adjetival(gadj(Adj)) -->
    adjetivo(Adj).

% ---------------------------------------------------------
% GADJ = grupo adverbial + adjetivo
% Ejemplo: "muy estable"  "muy lejos"
% ---------------------------------------------------------
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
% Ejemplo: "muy"  "nunca"  "rápidamente"
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
%
% Un grupo preposicional es: preposición + grupo nominal
% Ejemplos:
%   "de Madrid"
%   "en el laboratorio"
%   "con un sensor"
% Árbol: gp(p(en), gn(det(el), n(laboratorio)))
% =========================================================

g_preposicional(gp(P, GN)) -->
    preposicion(P),
    g_nominal(GN).

g_preposicional(gp(P, INF)) -->
    preposicion(P),
    infinitivo_frase(INF).

% =========================================================
% GRUPO VERBAL (GV)
% Esta parte es el "corazón del predicado".
% En vez de meter todas las variantes directamente en g_verbal/1, hacemos dos niveles:
%   1) g_verbal/1
%      -> puede ser coordinación verbal
%      -> o un grupo verbal simple
%   2) g_verbal_simple/1
%      -> contiene los patrones verbales concretos
%
% Esto es mejor porque así podemos reconocer: "Juan come y bebe"
% como: o(gn(n(juan)), gv_coord(gv(v(come)), conj(y), gv(v(bebe))))
% y luego simplificarlo como: "Juan come"  "Juan bebe"
% =========================================================

% ---------------------------------------------------------
% Coordinación verbal con sujeto compartido
% Ejemplo:
%   "Juan come y bebe"
%   "Juan analiza el sistema y evalúa el modelo"
%
% Esto NO es lo mismo que una coordinación de oraciones completas:
%   "Juan come y María bebe"    -> oc(...)
%   "Juan come y bebe"          -> o(..., gv_coord(...))
% ---------------------------------------------------------
g_verbal(gv_coord(GV1, Conj, GV2)) -->
    g_verbal_simple(GV1),
    conjuncion_verbal(Conj),
    g_verbal_simple(GV2).

% Si no hay coordinación verbal, usamos un GV simple.
g_verbal(GV) -->
    g_verbal_simple(GV).

% =========================================================
% GRUPO VERBAL SIMPLE
% El orden de las reglas importa.
% Vamos de patrones más específicos a más simples para reducir:
%   - ambigüedad
%   - backtracking innecesario
% =========================================================

g_verbal_simple(gv(Se, V, Comps)) -->
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps).

g_verbal_simple(gv(Modal, Inf, Comps)) -->
    modal(Modal),
    infinitivo(Inf),
    complementos_verbales(Comps).

g_verbal_simple(gv(Modal, Aux, Part, Comps)) -->
    modal(Modal),
    auxiliar_ser(Aux),
    participio(Part),
    complementos_verbales(Comps).

g_verbal_simple(gv(VC, Inf, Comps)) -->
    verbo_copulativo(VC),
    infinitivo(Inf),
    complementos_verbales(Comps).

% ---------------------------------------------------------
% verbo + gn + gp
% Ejemplo:
%   "analiza el sistema con precisión"
%   "trabaja el modelo en laboratorio" (artificial)
% ---------------------------------------------------------
g_verbal_simple(gv(V, GN, GP)) -->
    verbo(V),
    g_nominal(GN),
    g_preposicional(GP).

% ---------------------------------------------------------
% verbo + gn + gadv
% Ejemplo: "analiza los datos rápidamente"
% ---------------------------------------------------------
g_verbal_simple(gv(V, GN, GAdv)) -->
    verbo(V),
    g_nominal(GN),
    g_adverbial(GAdv).

% ---------------------------------------------------------
% gadv + verbo + gn
% Ejemplo: "rápidamente analiza los datos"
% ---------------------------------------------------------
g_verbal_simple(gv(GAdv, V, GN)) -->
    g_adverbial(GAdv),
    verbo(V),
    g_nominal(GN).

% ---------------------------------------------------------
% gadv + verbo + gp
% Ejemplo: "rápidamente trabaja en el laboratorio"
% ---------------------------------------------------------
g_verbal_simple(gv(GAdv, V, GP)) -->
    g_adverbial(GAdv),
    verbo(V),
    g_preposicional(GP).

% ---------------------------------------------------------
% verbo + gp
% Ejemplo:
%   "trabaja en el laboratorio"
%   "depende de la muestra"
% ---------------------------------------------------------
g_verbal_simple(gv(V, GP)) -->
    verbo(V),
    g_preposicional(GP).

% ---------------------------------------------------------
% verbo + gn
% Ejemplo:
%   "analiza el sistema"
%   "evalúa el modelo"
% ---------------------------------------------------------
g_verbal_simple(gv(V, GN)) -->
    verbo(V),
    g_nominal(GN).

% ---------------------------------------------------------
% verbo + gadj
% Ejemplo: "resulta estable" 
% ---------------------------------------------------------
g_verbal_simple(gv(V, GAdj)) -->
    verbo(V),
    g_adjetival(GAdj).

% ---------------------------------------------------------
% verbo + gadv
% Ejemplo: "trabaja bien"
% ---------------------------------------------------------
g_verbal_simple(gv(V, GAdv)) -->
    verbo(V),
    g_adverbial(GAdv).

% ---------------------------------------------------------
% gadv + verbo
% Ejemplo: "nunca falla"
% ---------------------------------------------------------
g_verbal_simple(gv(GAdv, V)) -->
    g_adverbial(GAdv),
    verbo(V).

% ---------------------------------------------------------
% verbo copulativo + gadj + gp
% Ejemplo: "está muy lejos de Madrid"
% Árbol esperado: gv(vc(esta), gadj(gadv(adv(muy)), adj(lejos)), gp(p(de), gn(n(madrid))))
% ---------------------------------------------------------
g_verbal_simple(gv(VC, GAdj, GP)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj),
    g_preposicional(GP).

% ---------------------------------------------------------
% verbo copulativo + gadj
% Ejemplo:
%   "está estable"
%   "está muy estable"
% ---------------------------------------------------------
g_verbal_simple(gv(VC, GAdj)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj).

% ---------------------------------------------------------
% verbo copulativo + gn
% Ejemplo: "es un sistema"
% ---------------------------------------------------------
g_verbal_simple(gv(VC, GN)) -->
    verbo_copulativo(VC),
    g_nominal(GN).

% ---------------------------------------------------------
% auxiliar + participio + gp
% Ejemplo: "fue ayudada por un enfermero"
% ---------------------------------------------------------
g_verbal_simple(gv(Aux, Part, GP)) -->
    auxiliar(Aux),
    participio(Part),
    g_preposicional(GP).

g_verbal_simple(gv(Aux, Part, GN)) -->
    auxiliar(Aux),
    participio(Part),
    g_nominal(GN).

% ---------------------------------------------------------
% auxiliar + participio
% Ejemplo: "fue detectado"
% ---------------------------------------------------------
g_verbal_simple(gv(Aux, Part)) -->
    auxiliar(Aux),
    participio(Part).

% ---------------------------------------------------------
% verbo solo
% Ejemplo: "come"  "bebe"  "lee"
% ---------------------------------------------------------
g_verbal_simple(gv(V)) -->
    verbo(V).

g_verbal_simple(gv(V, Comps)) -->
    verbo(V),
    complementos_verbales_no_vacios(Comps).

% =========================================================
% VERBOS IMPERSONALES (BASE)
% Esto se usa para oraciones sin sujeto expreso.
% Ejemplos:
%   "llueve"
%   "nunca llueve"
%   "llueve en Madrid"
%   "nunca llueve en el laboratorio"
% =========================================================

% gadv + verbo impersonal + gp
g_verbal_impersonal(gv(GAdv, VI, GP)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI),
    g_preposicional(GP).

% verbo impersonal + gp
g_verbal_impersonal(gv(VI, GP)) -->
    verbo_impersonal(VI),
    g_preposicional(GP).

% gadv + verbo impersonal
g_verbal_impersonal(gv(GAdv, VI)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI).

% verbo impersonal solo
g_verbal_impersonal(gv(VI)) -->
    verbo_impersonal(VI).

g_verbal_impersonal(gv(Se, V, Comps)) -->
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps).

complementos_verbales_no_vacios(comps([Comp|Resto])) -->
    complemento_verbal(Comp),
    complementos_verbales_restantes(Resto).

complementos_verbales(comps([Comp|Resto])) -->
    complemento_verbal(Comp),
    complementos_verbales_restantes(Resto).

complementos_verbales(comps([])) -->
    [].

complementos_verbales_restantes([Comp|Resto]) -->
    complemento_verbal(Comp),
    complementos_verbales_restantes(Resto).

complementos_verbales_restantes([]) -->
    [].

complemento_verbal(comp_sub(Sub)) -->
    subordinada(Sub).

complemento_verbal(comp_inf(Inf)) -->
    infinitivo_frase(Inf).

complemento_verbal(comp_gp(GP)) -->
    g_preposicional(GP).

complemento_verbal(comp_gn(GN)) -->
    g_nominal(GN).

complemento_verbal(comp_gadj(GAdj)) -->
    g_adjetival(GAdj).

complemento_verbal(comp_gadv(GAdv)) -->
    g_adverbial(GAdv).

infinitivo_frase(inf_frase(Inf, Comps)) -->
    infinitivo(Inf),
    complementos_verbales(Comps).

subordinada(sub(Comp, O)) -->
    subordinante(Comp),
    oracion_compuesta(O).

% =========================================================
% LEXICO: CONVERSION DE PALABRAS A CATEGORIAS
% Aquí conectamos la lista de entrada con los "hechos léxicos".
%
% Ejemplo: determinante(det(el)) --> [el], {det_word(el)}.
% Es decir:
%   - consumimos el átomo "el" de la lista
%   - comprobamos que existe como determinante en el diccionario
%   - construimos el árbol det(el)
% ESTRUCTURA GENERAL: categoria(Arbol) --> [Token], {hecho_lexico(Token)}.
% =========================================================

determinante(det(X)) -->
    [X],
    {det_word(X)}.

nombre(n(X)) -->
    [X],
    {nombre_word(X)}.

verbo(v(X)) -->
    [X],
    {verbo_word(X)}.

verbo_copulativo(vc(X)) -->
    [X],
    {vc_word(X)}.

verbo_impersonal(vi(X)) -->
    [X],
    {vi_word(X)}.

auxiliar(aux(X)) -->
    [X],
    {aux_word(X)}.

participio(part(X)) -->
    [X],
    {part_word(X)}.

modal(mod(X)) -->
    [X],
    {modal_word(X)}.

auxiliar_ser(aux(X)) -->
    [X],
    {aux_ser_word(X)}.

infinitivo(inf(X)) -->
    [X],
    {inf_word(X)}.

adjetivo(adj(X)) -->
    [X],
    {adj_word(X)}.

adverbio(adv(X)) -->
    [X],
    {adv_word(X)}.

preposicion(p(X)) -->
    [X],
    {prep_word(X)}.

conjuncion(conj(X)) -->
    [X],
    {conj_word(X)}.

relativo(relat(X)) -->
    [X],
    {rel_word(X)}.

subordinante(subord(X)) -->
    [X],
    {subord_word(X)}.

pronombre_se(se(X)) -->
    [X],
    {se_word(X)}.

% =========================================================
% CONJUNCIONES
% No todas las conjunciones se usan igual.
% Distinguimos:
%   - conjuncion_oracional:
%       une oraciones completas
%       ejemplo: "Juan estudia pero María trabaja"
%   - conjuncion_nominal:
%       une grupos nominales
%       ejemplo: "Juan y María"
%   - conjuncion_verbal:
%       une grupos verbales con sujeto compartido
%       ejemplo: "come y bebe"
% Para nominal y verbal restringimos a coordinantes típicas: y, o, ni
% Así reducimos ambigüedad.
% =========================================================

% Une oraciones completas. Aquí dejamos un conjunto más amplio.
conjuncion_oracional(Conj) -->
    conjuncion(Conj),
    { Conj \= conj(si) }.

% ---------------------------------------------------------
% Une grupos nominales.
% Ejemplo: "Juan y María"
% ---------------------------------------------------------
conjuncion_nominal(Conj) -->
    conjuncion_coordinante(Conj).

% ---------------------------------------------------------
% Une grupos verbales con sujeto compartido.
% Ejemplo: "come y bebe"
% ---------------------------------------------------------
conjuncion_verbal(Conj) -->
    conjuncion_coordinante(Conj).

% Conjunciones coordinantes "limpias".
conjuncion_coordinante(conj(X)) -->
    [X],
    {conj_coord_word(X)}.

% =========================================================
% PAUSA 

% Esta regla permite aceptar comas en puntos donde la oración
% puede llevar una pausa escrita, por ejemplo en incisos de relativo.
%
% Las comas se conservan al tokenizar, por lo que una frase como: "Juan, que analiza el sistema, presenta el resultado"
% se convierte en: [juan, ',', que, analiza, el, sistema, ',', presenta, el, resultado]
% (Si no se tokenizan comas: [juan, que, analiza, el, sistema, presenta, el, resultado])
%
% La regla pausa_opcional/0 permite dos posibilidades:
%   1) consumir una coma, si está presente en la lista;
%   2) no consumir nada, para seguir aceptando también versiones sin coma o casos donde esa pausa no aparezca en el token actual.
% Esta solución da flexibilidad al parser y evita obligar a que todas las relativas o incisos lleven siempre coma en la entrada.
% =========================================================

%"si el siguiente token es una coma, la acepto y la consumo".
pausa_opcional -->
    [','].

%"también puedo no consumir nada y continuar".
pausa_opcional -->
    [].

% =========================================================
% DICCIONARIO / LEXICO BASE

% ESTE BLOQUE ES SOLO UNA BASE GENÉRICA.
% Cuando esté el corpus real, aquí habrá que:
% 1) añadir las palabras que aparecen en las frases;
% 2) clasificar cada palabra en su categoría correcta;
% 3) si una palabra puede pertenecer a varias categorías,
%    decidir si:
%       - permitir ambigüedad
%       - o desambiguar más adelante con semántica.
% =========================================================

% DETERMINANTES
det_word(el).
det_word(la).
det_word(los).
det_word(las).
det_word(un).
det_word(una).
det_word(unos).
det_word(unas).
det_word(este).
det_word(esta).
det_word(estos).
det_word(estas).
det_word(mi).
det_word(su).
det_word(sus).
det_word(mis).
det_word(algunos).
det_word(algunas).
det_word(estas).
det_word(varias).
det_word(ciertos).

% NOMBRES GENERALES
nombre_word(juan).
nombre_word(maria).
nombre_word(hombre).
nombre_word(mujer).
nombre_word(estudiante).
nombre_word(profesor).
nombre_word(sistema).
nombre_word(modelo).
nombre_word(proceso).
nombre_word(resultado).
nombre_word(problema).
nombre_word(dato).
nombre_word(datos).
nombre_word(prueba).
nombre_word(analisis).
nombre_word(pelo).
nombre_word(filosofia).
nombre_word(derecho).
nombre_word(madrid).
nombre_word(clase).

% NOMBRES DEL CORPUS (computación cuántica)
nombre_word(presente).
nombre_word(trabajo).
nombre_word(introduccion).
nombre_word(medidas).
nombre_word(qnd).
nombre_word(caracteristicas).
nombre_word(qubit).
nombre_word(qubits).
nombre_word(oscilador).
nombre_word(formalismo).
nombre_word(teoria).
nombre_word(computacion).
nombre_word(flujo).
nombre_word(interferometros).
nombre_word(superconductores).
nombre_word(componente).
nombre_word(base).
nombre_word(informacion).
nombre_word(objetivo).
nombre_word(procesamiento).
nombre_word(sistemas).
nombre_word(comunidad).
nombre_word(utilidad).
nombre_word(idea).
nombre_word(aportes).
nombre_word(ramas).
nombre_word(ciencia).
nombre_word(mecanica).
nombre_word(luz).
nombre_word(teorema).
nombre_word(cloning).
nombre_word(estados).
nombre_word(bit).
nombre_word(analogo).
nombre_word(objeto).
nombre_word(matematico).
nombre_word(perspectivas).
nombre_word(limitaciones).
nombre_word(desarrollo).
nombre_word(algoritmo).
nombre_word(algoritmos).
nombre_word(tiempo).
nombre_word(polinomico).
nombre_word(exponencial).
nombre_word(maquina).
nombre_word(turing).
nombre_word(universal).
nombre_word(computadores).
nombre_word(computadoras).
nombre_word(analogicos).
nombre_word(problemas).
nombre_word(ruido).
nombre_word(rendimiento).
nombre_word(correccion).
nombre_word(errores).
nombre_word(tolerancia).
nombre_word(busqueda).
nombre_word(proceso).
nombre_word(medicion).
nombre_word(interaccion).
nombre_word(perturbacion).
nombre_word(principio).
nombre_word(incertidumbre).
nombre_word(precision).
nombre_word(mediciones).
nombre_word(auxiliar).
nombre_word(observable).
nombre_word(hamiltoniano).
nombre_word(electron).
nombre_word(metodos).
nombre_word(condiciones).
nombre_word(relatividad).
nombre_word(shor).
nombre_word(grover).
nombre_word(feynman).
nombre_word(cientificos).
nombre_word('no-cloning').



% ---------------------------------------------------------
% VERBOS
% Aquí van verbos léxicos "normales".
% NO metemos aquí los copulativos ni los impersonales,porque los tratamos por separado.
% ---------------------------------------------------------
verbo_word(analiza).
verbo_word(procesa).
verbo_word(mide).
verbo_word(detecta).
verbo_word(evalua).
verbo_word(genera).
verbo_word(mejora).
verbo_word(controla).
verbo_word(estudia).
verbo_word(utiliza).
verbo_word(reduce).
verbo_word(aumenta).
verbo_word(compra).
verbo_word(vende).
verbo_word(depende).
verbo_word(presenta).
verbo_word(lee).
verbo_word(tiene).
verbo_word(realiza).
verbo_word(describe).
verbo_word(basa).
verbo_word(introducen).
verbo_word(desarrollaron).
verbo_word(permite).
verbo_word(define).
verbo_word(requiere).
verbo_word(supera).
verbo_word(propusieron).
verbo_word(transmitir).
verbo_word(impide).
verbo_word(copiar).
verbo_word(resolvian).
verbo_word(afecta).
verbo_word(garantizaron).
verbo_word(demostro).
verbo_word(resuelven).
verbo_word(propuso).
verbo_word(sugirio).
verbo_word(construir).
verbo_word(implica).
verbo_word(produce).
verbo_word(limita).
verbo_word(pueden).
verbo_word(alterar).
verbo_word(permiten).
verbo_word(obtener).
verbo_word(destruir).
verbo_word(ayudar).
verbo_word(dar).
verbo_word(ejecuta).
verbo_word(incluyen).
verbo_word(tardo).
verbo_word(reconocer).
verbo_word(fueron).
verbo_word(atrapar).
verbo_word(desarrollo).
verbo_word(tratado).
verbo_word(basadas).
verbo_word(utilizan).
verbo_word(procesar).

% ---------------------------------------------------------
% VERBOS COPULATIVOS
% Ejemplo: "es estable"  "está muy lejos"
% ---------------------------------------------------------
vc_word(es).
vc_word(esta).
vc_word(son).
vc_word(estan).
vc_word(fue).
vc_word(fueron).
vc_word(puede).

% VERBOS IMPERSONALES
vi_word(llueve).
vi_word(nieva).

% ---------------------------------------------------------
% AUXILIARES / PARTICIPIOS
% Ejemplo:
%   "fue ayudada"
%   "fue detectado"
% ---------------------------------------------------------
aux_word(fue).
aux_word(fueron).
aux_word(se).

part_word(ayudado).
part_word(ayudada).
part_word(detectado).
part_word(detectada).
part_word(analizado).
part_word(analizada).
part_word(desarrollado).
part_word(desarrollada).
part_word(acoplado).
part_word(acoplada).
part_word(tratado).
part_word(tratada).
part_word(basadas).
part_word(basados).
part_word(considerada).
part_word(considerado).
part_word(desmentida).

% ADJETIVOS
adj_word(breve).
adj_word(presente).
adj_word(acoplado).
adj_word(acoplada).
adj_word(armonico).
adj_word(armonica).
adj_word(cuantico).
adj_word(cuantica).
adj_word(cuanticos).
adj_word(cuanticas).
adj_word(desarrollado).
adj_word(desarrollada).
adj_word(cientifica).
adj_word(cientifico).
adj_word(varias).
adj_word(cientificos).
adj_word(mas).
adj_word(rapido).
adj_word(rapida).
adj_word(desmentida).
adj_word(especificos).
adj_word(especifica).
adj_word(especificas).
adj_word(fisicos).
adj_word(fisica).
adj_word(qnd).
adj_word(tratado).
adj_word(tratada).
adj_word(base).
adj_word(analogo).
adj_word(matematico).
adj_word(matematica).
adj_word(diferentes).
adj_word(polinomico).
adj_word(exponencial).
adj_word(clasica).
adj_word(clasico).
adj_word(clasicas).
adj_word(fundamental).
adj_word(eficiente).
adj_word(ineficiente).
adj_word(analogicos).
adj_word(analogicas).
adj_word(considerada).
adj_word(considerado).
adj_word(universal).
adj_word(basadas).
adj_word(basados).
adj_word(auxiliar).
adj_word(auxiliares).
adj_word(especificas).
adj_word(repetidas).
adj_word(repetidos).
adj_word(mismo).
adj_word(misma).
adj_word(mismos).
adj_word(mismas).
adj_word(utiles).
adj_word(util).
adj_word(unico).
adj_word(unica).
adj_word(solo).
adj_word(sola).
adj_word(superconductores).
adj_word(no-cloning).


% ADVERBIOS
adv_word(muy).
adv_word(nunca).
adv_word(bien).
adv_word(mal).
adv_word(rapidamente).
adv_word(lentamente).
adv_word(hoy).
adv_word(ayer).
adv_word(teoricamente).
adv_word(siempre).
adv_word(eficientemente).
adv_word(como).
adv_word(sin).
adv_word(usando).
adv_word(desde).
adv_word(mas).

% PREPOSICIONES
prep_word(a).
prep_word(al).
prep_word(en).
prep_word(de).
prep_word(del).
prep_word(con).
prep_word(por).
prep_word(para).
prep_word(sin).
prep_word(sobre).
prep_word(desde).
prep_word(entre).
prep_word(hasta).
prep_word(durante).
prep_word(como).
prep_word(usando).

% ---------------------------------------------------------
% CONJUNCIONES ORACIONALES GENERALES
% Las dejamos amplias para unir oraciones completas.
% ---------------------------------------------------------
conj_word(y).
conj_word(o).
conj_word(pero).
conj_word(aunque).
conj_word(mientras).
conj_word(ni).
conj_word(pues).
conj_word(luego).
conj_word(porque).
conj_word(si).

% ---------------------------------------------------------
% CONJUNCIONES COORDINANTES "LIMPIAS"
% Estas son las que usamos para coordinar:
%   - grupos nominales
%   - grupos verbales
% Así evitamos usar "pero" o "mientras" dentro de un GV compartido
% si no queremos introducir más ambigüedad.
% ---------------------------------------------------------
conj_coord_word(y).
conj_coord_word(o).
conj_coord_word(ni).

% RELATIVOS
rel_word(que).

subord_word(que).
subord_word(si).

se_word(se).

modal_word(puede).
modal_word(pueden).
modal_word(debe).
modal_word(deben).

aux_ser_word(ser).

inf_word(transmitir).
inf_word(copiar).
inf_word(construir).
inf_word(atrapar).
inf_word(procesar).
inf_word(reconocer).
inf_word(caracterizar).
inf_word(estudiar).
inf_word(alterar).
inf_word(obtener).
inf_word(destruir).
inf_word(ayudar).
inf_word(dar).
inf_word(conmutar).
inf_word(ejecutar).



% =========================================================
% PREDICADOS AUXILIARES (NO DCG)
% Estos ya no consumen listas de palabras.
% Son utilidades normales de Prolog.
% =========================================================

% ---------------------------------------------------------
% es_oracion_simple/1
%
% Sirve para distinguir:
%   o(...)   -> simple
%   oc(...)  -> no simple
%   or(...)  -> no simple
%   ocm(...) -> no simple
%
% Esto se usa en las reglas de oracion_compuesta/1 para decidir
% cuándo algo debe etiquetarse como oc y cuándo como ocm.
% ---------------------------------------------------------
es_oracion_simple(o(_, _)).
es_oracion_simple(o(_)).

% ---------------------------------------------------------
% tipo_oracion/2
%
% Dado un árbol, devuelve su etiqueta principal.
%
% Ejemplos:
%   ?- tipo_oracion(o(gn(n(juan)), gv(v(come))), T).
%   T = o.
%
%   ?- tipo_oracion(oc(o(...), conj(y), o(...)), T).
%   T = oc.
% ---------------------------------------------------------
tipo_oracion(o(_, _), o).
tipo_oracion(o(_), o).
tipo_oracion(oc(_, _, _), oc).
tipo_oracion(or(_, _, _), or).
tipo_oracion(ocm(_, _, _), ocm).

% ---------------------------------------------------------
% simplificar/2
%
% Convertir una oración compleja en una lista de oraciones simples.
%
% 1) Si ya es simple, la lista resultado tiene un único elemento.
% 2) Si es una coordinación de oraciones (oc): simplificamos cada parte y concatenamos.
% 3) Si es una compuesta mixta (ocm): igual, simplificamos recursivamente ambas partes.
% 4) Si es una relativa (or):
%       "Juan, que analiza el sistema, presenta el resultado"
%       ->
%       "Juan analiza el sistema"
%       "Juan presenta el resultado"
% 5) Si el predicado está coordinado y comparte sujeto:
%       "Juan come y bebe"
%       ->
%       "Juan come"
%       "Juan bebe"

% El orden de las reglas importa.
% Ponemos ANTES el caso de coordinación verbal, para que no quede
% absorbido por la regla genérica simplificar(o(GN,GV), ...).
% ---------------------------------------------------------

% ---------------------------------------------------------
% Caso especial: sujeto + predicado coordinado
%
% Ejemplo: o(gn(n(juan)), gv_coord(gv(v(come)), conj(y), gv(v(bebe))))
% Resultado:
%   [o(gn(n(juan)), gv(v(come))),
%    o(gn(n(juan)), gv(v(bebe)))]
%
% Esta regla es recursiva de forma natural:
% si GV2 vuelve a ser una coordinación, seguirá simplificando.
% ---------------------------------------------------------
simplificar(o(GN, gv_coord(GV1, _, GV2)), Resultado) :-
    simplificar(o(GN, GV1), R1),
    simplificar(o(GN, GV2), R2),
    append(R1, R2, Resultado).

% Caso base: oración simple con sujeto explícito
simplificar(o(GN, GV), [o(GN, GV)]).

% Caso base: oración impersonal
simplificar(o(GV), [o(GV)]).

% ---------------------------------------------------------
% Coordinación de oraciones completas
% Ejemplo: "Juan analiza el sistema y María evalúa el modelo"
% ---------------------------------------------------------
simplificar(oc(O1, _, O2), Resultado) :-
    simplificar(O1, R1),
    simplificar(O2, R2),
    append(R1, R2, Resultado).


% Compuesta mixta / encadenada
simplificar(ocm(O1, _, O2), Resultado) :-
    simplificar(O1, R1),
    simplificar(O2, R2),
    append(R1, R2, Resultado).

% ---------------------------------------------------------
% Relativa
%
% Ejemplo:
%   or(gn(n(juan)),
%      rel(relat(que), gv(v(analiza), gn(det(el), n(sistema)))),
%      gv(v(presenta), gn(det(el), n(resultado))))
%
% Queremos generar:
%   "Juan analiza el sistema"
%   "Juan presenta el resultado"
%
% Además, si alguno de esos GV está coordinado internamente, también queremos que se simplifique bien.
% ---------------------------------------------------------
simplificar(or(GN, rel(_, GVRel), GVPrinc), Resultado) :-
    simplificar(o(GN, GVRel), RRel),
    simplificar(o(GN, GVPrinc), RPrinc),
    append(RRel, RPrinc, Resultado).

% ---------------------------------------------------------
% analiza_lista/2
% Predicado cómodo para lanzar el parser sobre una lista.
%
% Ejemplo:
%   ?- analiza_lista([juan, analiza, el, sistema], X).
%   X = o(gn(n(juan)), gv(v(analiza), gn(det(el), n(sistema)))).
%
% Equivale a:
%   phrase(oracion(X), [juan, analiza, el, sistema]).
% ---------------------------------------------------------
analiza_lista(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).

% =========================================================
% EJEMPLOS RAPIDOS DE USO
% =========================================================
%
% 1) Oración simple:
%    ?- analiza_lista([juan, analiza, el, sistema], X).
%
% 2) Coordinada:
%    ?- analiza_lista([juan, analiza, el, sistema, y, maria, evalua, el, modelo], X).
%
% 3) Relativa:
%    ?- analiza_lista([juan, que, analiza, el, sistema, presenta, el, resultado], X).
%
% 4) Compuesta mixta:
%    ?- analiza_lista([juan, que, analiza, el, sistema, presenta, el, resultado, pero, maria, evalua, el, modelo], X).
%
% 5) Coordinación verbal con sujeto compartido:
%    ?- analiza_lista([juan, come, y, bebe], X).
%
% 6) Simplificación:
%    ?- analiza_lista([juan, come, y, bebe], X), simplificar(X, S).
%
% 7) Dibujar árbol:
%    ?- analiza_lista([juan, analiza, el, sistema], X), draw(X).
%
% =========================================================
