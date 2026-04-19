% =========================================
% PARTE 2 - Gramática ampliada con árbol
% =========================================

:- consult(draw).

% -------------------------
% Oración
% -------------------------

oracion(o(GN,GV)) --> g_nominal(GN), g_verbal(GV).
oracion(o(GV)) --> g_verbal(GV).   % para frases tipo "llueve"

% -------------------------
% Grupo nominal
% -------------------------

g_nominal(gn(N)) --> nombre(N).
g_nominal(gn(D,N)) --> determinante(D), nombre(N).
g_nominal(gn(D,N,Adj)) --> determinante(D), nombre(N), adjetivo(Adj).

% coordinación: Juan y María
g_nominal(gn(GN1,conj(Y),GN2)) -->
    g_nominal(GN1), conjuncion(Y), g_nominal(GN2).

% con complemento preposicional: "práctica de Juan"
g_nominal(gn(N,GP)) -->
    nombre(N), g_preposicional(GP).

g_nominal(gn(D,N,GP)) -->
    determinante(D), nombre(N), g_preposicional(GP).

% -------------------------
% Grupo verbal
% -------------------------

g_verbal(gv(V)) --> verbo(V).

g_verbal(gv(V,GN)) --> verbo(V), g_nominal(GN).

g_verbal(gv(V,GP)) --> verbo(V), g_preposicional(GP).

g_verbal(gv(V,GN,GP)) --> verbo(V), g_nominal(GN), g_preposicional(GP).

% copulativo + atributo + adverbio
g_verbal(gv(VC,Adv,Adj)) -->
    verbo_copulativo(VC), adverbio(Adv), adjetivo(Adj).

g_verbal(gv(VC,Adj)) -->
    verbo_copulativo(VC), adjetivo(Adj).

% pasiva
g_verbal(gv(Aux,Part,GP)) -->
    auxiliar(Aux), participio(Part), g_preposicional(GP).

% verbo con adverbio
g_verbal(gv(Adv,V)) -->
    adverbio(Adv), verbo(V).

g_verbal(gv(V,Adv)) -->
    verbo(V), adverbio(Adv).

g_verbal(gv(Adv,V,GP)) -->
    adverbio(Adv), verbo(V), g_preposicional(GP).

% -------------------------
% Grupo preposicional
% -------------------------

g_preposicional(gp(P,GN)) -->
    preposicion(P), g_nominal(GN).

% -------------------------
% Léxico
% -------------------------

determinante(det(X)) --> [X], {det_word(X)}.
det_word(el). det_word(la). det_word(un). det_word(una).
det_word(mi). det_word(esta).

nombre(n(X)) --> [X], {nombre_word(X)}.
nombre_word(juan). 
nombre_word(maria). 
nombre_word(hombre).
nombre_word(mujer). 
nombre_word(manzana). 
nombre_word(gato).
nombre_word(raton). 
nombre_word(alumno). 
nombre_word(universidad).
nombre_word(practica). 
nombre_word(casa).
nombre_word(madrid).
nombre_word(enfermero). 
nombre_word(desierto). 
nombre_word(clase).
nombre_word(noche). 
nombre_word(alcala). 
nombre_word(esperanza).
nombre_word(vida). 
nombre_word(nino). 
nombre_word(lugar).
nombre_word(nacimiento). 
nombre_word(tenedor). 
nombre_word(cuchillo).

verbo(v(X)) --> [X], {verbo_word(X)}.
verbo_word(ama). 
verbo_word(come). 
verbo_word(estudia).
verbo_word(hace). 
verbo_word(llueve). 
verbo_word(depende).
verbo_word(saldre). 
verbo_word(comen).

verbo_copulativo(vc(X)) --> [X], {vc_word(X)}.
vc_word(es). 
vc_word(esta).

auxiliar(aux(X)) --> [X], {aux_word(X)}.
aux_word(fue).

participio(part(X)) --> [X], {part_word(X)}.
part_word(ayudada).

adjetivo(adj(X)) --> [X], {adj_word(X)}.
adj_word(roja). adj_word(grande). adj_word(lejos).

adverbio(adv(X)) --> [X], {adv_word(X)}.
adv_word(muy). adv_word(nunca). adv_word(bien).

preposicion(p(X)) --> [X], {prep_word(X)}.
prep_word(a). prep_word(en). prep_word(de). prep_word(con). prep_word(por).

conjuncion(conj(y)) --> [y].