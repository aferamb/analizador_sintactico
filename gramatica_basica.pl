% =========================================
% Práctica 2 - Fase 1
% Gramática ampliada para aceptar las 10 frases
% =========================================

% -------------------------
% Regla principal
% -------------------------

oracion --> g_nominal, g_verbal.

% -------------------------
% Grupo nominal
% -------------------------

g_nominal --> nombre.
g_nominal --> determinante, nombre.
g_nominal --> nombre, adjetivo.
g_nominal --> determinante, nombre, adjetivo.

% -------------------------
% Grupo verbal
% -------------------------

g_verbal --> verbo.
g_verbal --> verbo, g_nominal.
g_verbal --> verbo, adjetivo.
g_verbal --> verbo, g_nominal, g_preposicional.
g_verbal --> verbo, g_preposicional.
g_verbal --> verbo_copulativo, adjetivo.

% -------------------------
% Grupo preposicional
% -------------------------

g_preposicional --> preposicion, g_nominal.

% -------------------------
% Diccionario
% -------------------------

% Determinantes
determinante --> [el].
determinante --> [la].
determinante --> [un].
determinante --> [una].

% Nombres
nombre --> [hombre].
nombre --> [mujer].
nombre --> [juan].
nombre --> [maria].
nombre --> [manzana].
nombre --> [manzanas].
nombre --> [gato].
nombre --> [raton].
nombre --> [ratones].
nombre --> [alumno].
nombre --> [universidad].

% Verbos
verbo --> [ama].
verbo --> [come].
verbo --> [estudia].

% Verbos copulativos
verbo_copulativo --> [es].

% Adjetivos
adjetivo --> [roja].
adjetivo --> [negro].
adjetivo --> [grande].
adjetivo --> [gris].
adjetivo --> [pequeno].

% Preposiciones
preposicion --> [a].
preposicion --> [en].