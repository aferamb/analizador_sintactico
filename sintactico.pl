
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
g_nominal_simple(gn(D, N, GAdj, GP)) -->
    determinante(D),
    nombre(N),
    g_adjetival(GAdj),
    g_preposicional(GP).

% ---------------------------------------------------------
% GN = determinante + nombre + grupo preposicional
% Ejemplo: "el sistema de control"
% ---------------------------------------------------------
g_nominal_simple(gn(D, N, GP)) -->
    determinante(D),
    nombre(N),
    g_preposicional(GP).

% ---------------------------------------------------------
% GN = nombre + grupo preposicional
% Ejemplo:
%   "Juan de Madrid"   (artificial, pero estructuralmente válido)
%   "software de control"
% ---------------------------------------------------------
g_nominal_simple(gn(N, GP)) -->
    nombre(N),
    g_preposicional(GP).

% ---------------------------------------------------------
% GN = determinante + nombre + grupo adjetival
% Ejemplo: "el sistema digital"
% ---------------------------------------------------------
g_nominal_simple(gn(D, N, GAdj)) -->
    determinante(D),
    nombre(N),
    g_adjetival(GAdj).

% ---------------------------------------------------------
% GN = nombre + grupo adjetival
% Ejemplo: "software digital"
% ---------------------------------------------------------
g_nominal_simple(gn(N, GAdj)) -->
    nombre(N),
    g_adjetival(GAdj).

% ---------------------------------------------------------
% GN = determinante + nombre
% Ejemplo: "el sistema"
% ---------------------------------------------------------
g_nominal_simple(gn(D, N)) -->
    determinante(D),
    nombre(N).

% ---------------------------------------------------------
% GN = nombre solo
% Ejemplo: "Juan"  "María"  "software"
% ---------------------------------------------------------
g_nominal_simple(gn(N)) -->
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

% =========================================================
% GRUPO ADVERBIAL (GADV)
% Ejemplo: "muy"  "nunca"  "rápidamente"
% =========================================================

g_adverbial(gadv(Adv)) -->
    adverbio(Adv).

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
    conjuncion(Conj).

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

% NOMBRES DE TECNOLOGIA (ejemplo genérico)
nombre_word(sensor).
nombre_word(red).
nombre_word(robot).
nombre_word(algoritmo).
nombre_word(servidor).
nombre_word(usuario).
nombre_word(software).
nombre_word(hardware).
nombre_word(dispositivo).
nombre_word(plataforma).

% NOMBRES DE ECONOMIA (ejemplo genérico)
nombre_word(mercado).
nombre_word(empresa).
nombre_word(banco).
nombre_word(inflacion).
nombre_word(precio).
nombre_word(inversion).
nombre_word(cliente).

% NOMBRES CIENTIFICOS (ejemplo genérico)
nombre_word(particula).
nombre_word(electron).
nombre_word(foton).
nombre_word(laboratorio).
nombre_word(muestra).

% NOMBRES CLINICOS (ejemplo genérico)
nombre_word(paciente).
nombre_word(hospital).
nombre_word(diagnostico).
nombre_word(tratamiento).
nombre_word(ensayo).
nombre_word(enfermero).

% ---------------------------------------------------------
% VERBOS GENERALES
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
verbo_word(come).
verbo_word(bebe).
verbo_word(lee).
verbo_word(tiene).

% ---------------------------------------------------------
% VERBOS COPULATIVOS
% Ejemplo: "es estable"  "está muy lejos"
% ---------------------------------------------------------
vc_word(es).
vc_word(esta).
vc_word(son).
vc_word(estan).

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

part_word(ayudado).
part_word(ayudada).
part_word(detectado).
part_word(detectada).
part_word(analizado).
part_word(analizada).

% ADJETIVOS
adj_word(grande).
adj_word(pequeno).
adj_word(pequena).
adj_word(rapido).
adj_word(rapida).
adj_word(lento).
adj_word(lenta).
adj_word(estable).
adj_word(inestable).
adj_word(clinico).
adj_word(clinica).
adj_word(cuantico).
adj_word(cuantica).
adj_word(digital).
adj_word(preciso).
adj_word(precisa).
adj_word(lejos).
adj_word(alto).
adj_word(alta).
adj_word(rubio).
adj_word(rubia).
adj_word(moreno).
adj_word(morena).


% ADVERBIOS
adv_word(muy).
adv_word(nunca).
adv_word(bien).
adv_word(mal).
adv_word(rapidamente).
adv_word(lentamente).
adv_word(hoy).
adv_word(ayer).

% PREPOSICIONES
prep_word(a).
prep_word(en).
prep_word(de).
prep_word(con).
prep_word(por).
prep_word(para).
prep_word(sin).
prep_word(sobre).

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