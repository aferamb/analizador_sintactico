% =========================================
% Práctica 2 - Parte 2 (árbol sintáctico)
% =========================================

:- consult(draw).

% -------------------------
% Regla principal
% -------------------------

oracion(o(GN,GV)) --> g_nominal(GN), g_verbal(GV).

% -------------------------
% Grupo nominal
% -------------------------

g_nominal(gn(N)) --> nombre(N).
g_nominal(gn(D,N)) --> determinante(D), nombre(N).
g_nominal(gn(N,Adj)) --> nombre(N), adjetivo(Adj).
g_nominal(gn(D,N,Adj)) --> determinante(D), nombre(N), adjetivo(Adj).

% -------------------------
% Grupo verbal
% -------------------------

g_verbal(gv(V)) --> verbo(V).
g_verbal(gv(V,GN)) --> verbo(V), g_nominal(GN).
g_verbal(gv(V,Prep)) --> verbo(V), g_preposicional(Prep).
g_verbal(gv(VC,Adj)) --> verbo_copulativo(VC), adjetivo(Adj).

% -------------------------
% Grupo preposicional
% -------------------------

g_preposicional(gp(P,GN)) --> preposicion(P), g_nominal(GN).

% -------------------------
% Diccionario
% -------------------------

determinante(det(X)) --> [X], {det_word(X)}.
det_word(el).
det_word(la).
det_word(un).
det_word(una).

nombre(n(X)) --> [X], {nombre_word(X)}.
nombre_word(hombre).
nombre_word(mujer).
nombre_word(juan).
nombre_word(maria).
nombre_word(manzana).
nombre_word(manzanas).
nombre_word(gato).
nombre_word(raton).
nombre_word(ratones).
nombre_word(alumno).
nombre_word(universidad).

verbo(v(X)) --> [X], {verbo_word(X)}.
verbo_word(ama).
verbo_word(come).
verbo_word(estudia).

verbo_copulativo(vc(X)) --> [X], {vc_word(X)}.
vc_word(es).

adjetivo(adj(X)) --> [X], {adj_word(X)}.
adj_word(roja).
adj_word(negro).
adj_word(grande).
adj_word(gris).
adj_word(pequeno).

preposicion(p(X)) --> [X], {prep_word(X)}.
prep_word(a).
prep_word(en).