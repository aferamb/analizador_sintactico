:- encoding(utf8).

% gramatica.pl
% Reglas DCG y predicados auxiliares del analizador sintáctico.
% El diccionario está en lexico.pl.

:- consult(draw).



/**
 * En muchas partes del código se usan reglas DCG para definir la gramática de las oraciones.
 * DCG significa Definite Clause Grammar. Se escribe con --> en vez de :-
 * 
 * Por ejemplo: 
 * oracion(o(GN, GV)) -->
 * g_nominal(GN),
 * g_verbal(GV).
 * 
 * Se traduce internamente a una regla con listas de tokens. Algo así:
 * oracion(o(GN, GV), TokensEntrada, TokensSalida) :-
 * g_nominal(GN, TokensEntrada, TokensIntermedios),
 * g_verbal(GV, TokensIntermedios, TokensSalida). 
 * 
 * Por eso una DCG sirve para ir consumiendo palabras de una lista.
 *  
 * Las llaves { ... } en DCG significan: Esto no consume tokens; solo ejecuta código Prolog normal.
 * 
 * phrase es el predicado que ejecuta una DCG.
 * 
 * Cuando escribes: phrase(oracion(Arbol), [la, araña, muere]).
 * estás diciendo: Analiza la lista [la, araña, muere] usando la regla oracion(Arbol).
 * Si la lista encaja con la gramática, Prolog devuelve el árbol.
 * 
 * phrase/2 exige que la regla consuma toda la lista. Si sobra algo, falla.
 * phrase/3 es más flexible: phrase(oracion(Arbol), [la, araña, muere], Resto). Esto permite ver qué parte ha consumido y qué parte ha sobrado.
 * 
 * 
 * 
 * 
 * **/

% =========================================================
% REGLA PRINCIPAL
% =========================================================

% La regla principal de análisis sintáctico es oracion/3, 
% que intenta analizar una secuencia de tokens como una oración completa, 
% devolviendo el árbol sintáctico y el resto de tokens no analizados (si los hay).
oracion(O, Tokens, Resto) :-
    tokens_conocidos(Tokens), % Asegura que todos los tokens estén en el léxico o sean números, % ...
    oracion_compuesta(O, Tokens, Resto). % Inicia el análisis con la regla de oración compuesta, que a su vez llama a otras reglas según la estructura detectada.

% =========================================================
% TIPOS DE ORACION
%   o   = oración simple
%   oc  = oración coordinada
%   or  = oración de relativo
%   ocm = oración compuesta/mixta
% =========================================================

% Coordinación de dos oraciones simples:
%   "El efector puede usarse ... , y se camufla ..."
%   "Reutilizamos ... y creamos ..."
oracion_compuesta_coord_simple(oc(O1, Conj, O2)) -->
    oracion_simple(O1),
    pausa_opcional,
    conjuncion_oracional(Conj),
    oracion_simple(O2).

% Coordinación donde alguno de los lados ya es complejo
% Reconoce coordinaciones donde al menos una parte no es una oración simple básica
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
    oracion_compuesta_coord_simple(O2). % La segunda parte tiene que ser una coordinación simple.

% versión más general de yuxtaposición
oracion_compuesta_yuxtapuesta(ocm(O1, pausa, O2)) -->
    oracion_simple(O1),
    pausa_obligatoria,
    oracion_compuesta(O2). % La segunda parte puede ser cualquier tipo de oración compuesta, no solo coordinación simple.

% Oración simple con complementos/subordinadas internas.
% Si la oración simple contiene subordinadas o relativas, puede clasificarse como ocm.
% una oración con complemento inicial, aunque estructuralmente sea simple, saldrá como ocm
oracion_compuesta_ocm_interna(ocm(O)) -->
    oracion_simple(O),
    { contiene_complejidad(O) }.

% Oración no coordinada:
% Antes de intentar parsear, mira si hay una coma seguida de conjunción: ..., y ...
% Si detecta ese patrón, intenta directamente la coordinación simple.
oracion_compuesta(O, Tokens, Resto) :-
    hay_coma_conjuncion(Tokens),
    phrase(oracion_compuesta_coord_simple(O), Tokens, Resto).

% Distinguir una y que coordina complementos nominales de una y que coordina oraciones.
% En 'geometrías, volúmenes y masas variados' , la y no es oracional
% Pero en 'las patas se accionan extendiéndose hacia fuera y la pinza se abre', sí hay coordinación oracional
oracion_compuesta(O, Tokens, Resto) :-
    hay_y_oracional(Tokens),
    phrase(oracion_compuesta_coord_simple(O), Tokens, Resto).

% Busca palabras como motivos o razones seguidas de coma.
% Está pensada para este tipo de frase: Elegimos el prosoma por dos motivos, la presión ... y el exoesqueleto ...
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
% Reconoce frases con un GN seguido de relativa y luego un verbo principal.
oracion_no_coordinada_relativa(or(GN, Rel, GV)) -->
    g_nominal(GN),
    pausa_opcional,
    relativo_ampliado(Rel),
    pausa_opcional,
    g_verbal(GV).


% Primero intenta oración simple; 
oracion_no_coordinada(O) -->
    oracion_simple(O).

% luego oración relativa.
oracion_no_coordinada(O) -->
    oracion_no_coordinada_relativa(O).

% =========================================================
% ORACION SIMPLE y aposiciones
% (Una aposición suele ser un grupo nominal que explica o renombra otro elemento. ej: Madrid, la capital de España, tiene muchos habitantes)
% =========================================================

% Aquí el sujeto no es un GN normal, sino una oración de infinitivo
%   "Estudiar la fuerza ... podria conducir..."
oracion_simple(o(Inf, GV)) -->
    infinitivo_frase(Inf),
    g_verbal(GV).

% Oracion con sujeto omitido.
% CI = subordinada inicial : Cuando no se aplica presión...
% GN = las patas
% GV = permanecen flexionadas hacia adentro ,
% Apos = estado que denominamos neutro...
oracion_simple(o(CI, GN, GV, Apos), Tokens, Resto) :-
    hay_coma_estado(Tokens),
    phrase((
        complemento_inicial(CI),
        pausa_obligatoria,
        g_nominal(GN),
        g_verbal(GV),
        aposicion_final(Apos)
    ), Tokens, Resto).

% Oracion con sujeto omitido
%    demostramos la capacidad ...
%    Construimos un circuito...
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

% Oración con sujeto + verbo + inciso/complementos posteriores
%   "El sistema funciona correctamente, según los resultados"
% Reconoce frases donde el inciso va después del verbo.
oracion_simple(o(GN, GV, IncisoFinal)) -->
    g_nominal(GN),
    g_verbal(GV),
    inciso_oracional(IncisoFinal).

% Complemento inicial + oración con sujeto explícito
% Reconoce frases con dos elementos antepuestos
%    Sin embargo, en este trabajo, los materiales...
oracion_simple(o(CI1, CI2, GN, GV)) -->
    complemento_inicial(CI1),
    pausa_obligatoria,
    complemento_inicial(CI2),
    pausa_opcional,
    g_nominal(GN),
    g_verbal(GV).

% Complemento inicial + oración con sujeto explícito
%    Además, el efector puede usarse...
oracion_simple(o(CI, GN, GV)) -->
    complemento_inicial(CI),
    pausa_opcional,
    g_nominal(GN),
    g_verbal(GV).

% 2 complementos iniciales + oración con sujeto omitido:
%   Además, en este trabajo, demostramos...
oracion_simple(o(CI1, CI2, sujeto_eliptico, GV)) -->
    complemento_inicial(CI1),
    pausa_obligatoria,
    complemento_inicial(CI2),
    pausa_opcional,
    g_verbal(GV).

% Complemento inicial + oración con sujeto omitido:
%   "Además, demostramos..."
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
%   "Se eutanasió una araña..."
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

% Aposición final introducida por coma, con nombre y relativo.
%    , estado que denominamos neutro
aposicion_final(apos_estado(N, Rel)) -->
    [','],
    nombre(N),
    relativo_ampliado(Rel).

% Aposición final introducida por coma.
%   , una técnica sencilla
%   , un actuador listo para usar
aposicion_final(apos(GN)) -->
    [','],
    g_nominal(GN).

% =========================================================
% COMPLEMENTO INICIAL
% =========================================================
% Un complemento inicial puede ser:
% - un adverbio o locución adverbial (además, sin embargo, por el contrario...)
% - un grupo preposicional (en este trabajo, por el contrario...)
% - un marcador discursivo (sin embargo, no obstante...)
% - una subordinada (cuando una araña muere, dado que las patas...)

complemento_inicial(ci_adv(GAdv)) -->
    g_adverbial(GAdv).

complemento_inicial(ci_g_preposicional(GP)) -->
    g_preposicional(GP).

complemento_inicial(ci_marcador(M)) -->
    marcador_discursivo(M).

complemento_inicial(ci_sub(Sub)) -->
    subordinada_inicial(Sub).

% Marcadores discursivos frecuentes del corpus.
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

% Primero intenta una relativa normal.
relativo_ampliado(Rel) -->
    relativo_base(Rel).

% Se intenta una relativa coordinada, con dos relativos unidos por una conjunción coordinante:
%   "que denominamos neutro y que corresponde al agarre"
relativo_ampliado(rel_coord(Rel1, Conj, Rel2)) -->
    relativo_base(Rel1),
    conjuncion_coordinante(Conj),
    relativo_base(Rel2).

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

% Relativa con sujeto explícito:
%   que requiere una etapa sencilla
% que se interpreta como relativo y luego viene un grupo verbal sin sujeto explícito.
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


% =========================================================
% Auxiliares para detección de estructuras específicas en el análisis de oraciones compuestas.
% =========================================================

g_nominal_antes_de_para(GN, Tokens, Resto) :-
    partir_antes_de_para(Tokens, Prefix, Resto),
    phrase(g_nominal(GN), Prefix),
    !.

partir_antes_de_para([para|Resto], [], [para|Resto]) :- !.
partir_antes_de_para([Token|Tokens], [Token|Prefix], Resto) :-
    Token \= para,
    partir_antes_de_para(Tokens, Prefix, Resto).


% INCISOS ORACIONALES
% Reconoce fragmentos entre comas

%   Todo el proceso, desde la inserción de la aguja, puede realizarse...
inciso_oracional(inciso(GP)) -->
    [','],
    g_preposicional(GP),
    [','].

%   dan lugar, respectivamente, a la apertura...
inciso_oracional(inciso(GAdv)) -->
    [','],
    g_adverbial(GAdv),
    [','].

%   Ambos sistemas, sin embargo, se enfrentan...
inciso_oracional(inciso(M)) -->
    [','],
    marcador_discursivo(M),
    [','].

%   ..., basado en material biótico, ...
inciso_oracional(inciso(PartF)) -->
    [','],
    participio_frase(PartF),
    [','].

%   ..., completando así el proceso, ...
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

% Coordinación con coma: "Juan, María y Pedro"
g_nominal(gn_lista(GN1, GN2, Conj, GN3)) -->
    g_nominal_simple(GN1),
    [','],
    g_nominal_simple(GN2),
    conjuncion_nominal(Conj),
    g_nominal_simple(GN3).

% Coordinación simple: "Juan y María"
g_nominal(g_nominal(GN1, Conj, GN2)) -->
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
g_nominal_simple(g_nominal(D, Adj, N, Mods)) -->
    determinante(D),
    adjetivo_antepuesto(Adj),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + nombre + adjetivo:
%   "la pinza necrobótica"
%   "el material biótico"
g_nominal_simple(g_nominal(D, N, Adj, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

% Determinante + nombre + modificadores:
%   "la pinza con forma de garra"
%   "el prosoma"
g_nominal_simple(g_nominal(D, N, Mods)) -->
    determinante(D),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + adjetivo antepuesto + nombre + modificadores
%   una muy fina capa (muy fina como g_adjetival.)
g_nominal_simple(g_nominal(D, Adj, N, Mods)) -->
    determinante(D),
    g_adjetival(Adj),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + nombre + dos adjetivos:
%   "el efector final necrobotico"
%   "el material biotico bruto"
%   "una araña inanimada concreta"
g_nominal_simple(g_nominal(D, N, Adj1, Adj2, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj1),
    adjetivo(Adj2),
    modificadores_nominales(Mods).

% Determinante + nombre + adjetivo:
%   "la pinza necrobotica"
%   "el efector final"
%   "el material biotico"
g_nominal_simple(g_nominal(D, N, Adj, Mods)) -->
    determinante(D),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

% Predeterminante + determinante + nombre:
%   "todo el proceso"
%   "todas las patas"
%   "todos los materiales"
g_nominal_simple(g_nominal(D1, D2, N, Mods)) -->
    determinante(D1),
    determinante(D2),
    nombre(N),
    modificadores_nominales(Mods).

% Predeterminante + determinante + nombre + adjetivo:
%   "todas las patas flexionadas"
g_nominal_simple(g_nominal(D1, D2, N, Adj, Mods)) -->
    determinante(D1),
    determinante(D2),
    nombre(N),
    adjetivo(Adj),
    modificadores_nominales(Mods).

% Determinante + nombre:
%   "la pinza"
%   "el prosoma"
g_nominal_simple(g_nominal(D, N, Mods)) -->
    determinante(D),
    nombre(N),
    modificadores_nominales(Mods).

% Determinante + cantidad:
%   "el 130 %"
%   "los 1000 ciclos"
g_nominal_simple(g_nominal(D, Cant, Mods)) -->
    determinante(D),
    cantidad(Cant),
    modificadores_nominales(Mods).

% Determinante + grupo preposicional:
%   "el de la araña"
g_nominal_simple(g_nominal(D, GP, Mods)) -->
    determinante(D),
    g_preposicional(GP),
    modificadores_nominales(Mods).

% Cantidad como núcleo nominal:
%   "130 %"
%   "17 veces"
%   "5 dias"
g_nominal_simple(g_nominal(Cant, Mods)) -->
    cantidad(Cant),
    modificadores_nominales(Mods).

% Nombre sin determinante:
%   "araña"
%   "objetos"
%   "geometrias"
g_nominal_simple(g_nominal(N, Mods)) -->
    nombre(N),
    modificadores_nominales(Mods).

% g adjetival + nombre:
%   "pequeños actuadores"
g_nominal_simple(g_nominal(Adj, N, Mods)) -->
    g_adjetival(Adj),
    nombre(N),
    modificadores_nominales(Mods).

% Solo acepta como antepuestos ciertos adjetivos.
adjetivo_antepuesto(adj(X)) --> % DCG que consume una palabra X.
    [X], %Consume un token de la lista y llámalo X.
    { adj_word(X), adjetivo_antepuesto_word(X) }. % Verifica que X sea un adjetivo válido y esté en la lista de adjetivos antepuestos.

adjetivo_antepuesto_word(alta).
adjetivo_antepuesto_word(elevada).
adjetivo_antepuesto_word(fina).
adjetivo_antepuesto_word(unica).
adjetivo_antepuesto_word(mera).
adjetivo_antepuesto_word(reducido).

% ---------------------------------------------------------
% Modificadores nominales como árbol binario encadenado.
% mod(Mod_actual, Resto)  o  none  si no hay más.
% ---------------------------------------------------------

% Esto crea una lista encadenada:
% mod(Mod1, mod(Mod2, mod(Mod3, none)))
% en vez de una lista Prolog normal.
modificadores_nominales(mod(Mod, Resto)) -->
    modificador_nominal(Mod),
    modificadores_nominales(Resto).

modificadores_nominales(none) -->
    [].

% Adjetivos o grupos adjetivales: necrobótico , de alta potencia
% Grupos preposicionales: con geometrías irregulares, de la araña
% Relativos: que denominamos neutro, que se interpreta como relativo   
% Cantidad: 17 veces, 130 %
% Adverbios, pero con filtro: completamente funcional, todavía no
% Participios: flexionadas hacia adentro, recubierta de material biótico
% Nombres como modificadores de otros nombres: araña lobo (lobo es mod.)
% Participios nominales con filtro: recubierta, flexionada
modificador_nominal(g_adjetival(GAdj))    --> g_adjetival(GAdj).
modificador_nominal(g_preposicional(GP))  --> g_preposicional(GP).
modificador_nominal(rel(Rel))             --> relativo_ampliado(Rel).
modificador_nominal(cant(Cant))           --> cantidad(Cant).
modificador_nominal(g_adverbial(GAdv))    --> g_adverbial(GAdv), { gadv_nominal_valido(GAdv) }.
modificador_nominal(partf(PartF))         --> participio_frase_nominal(PartF).
modificador_nominal(n(n(X)))              --> [X], {nombre_word(X), \+ verbo_word(X), \+ modal_word(X)}.
modificador_nominal(part(part(X)))        --> [X], {participio_nominal_valido(X)}.

% ---------------------------------------------------------
% Filtro de adverbios nominales
% Evita que ciertos adverbios se peguen como modificadores nominales, lo que daría lugar a estructuras sintácticas no deseadas.
% ---------------------------------------------------------
gadv_nominal_valido(g_adverbial(adv(X))) :-
    \+ adverbio_bloqueado_como_mod_nominal(X).

gadv_nominal_valido(g_adverbial(adv(X), adv(Y))) :-
    \+ adverbio_bloqueado_como_mod_nominal(X),
    \+ adverbio_bloqueado_como_mod_nominal(Y).

adverbio_bloqueado_como_mod_nominal(no).
adverbio_bloqueado_como_mod_nominal(aun).
adverbio_bloqueado_como_mod_nominal(todavia).
adverbio_bloqueado_como_mod_nominal(tambien).

% =========================================================
% GRUPO ADJETIVAL (GADJ)
% =========================================================

% Adverbio + adjetivo:
%  "completamente funcional"
g_adjetival(g_adjetival(GAdv, Adj)) -->
    g_adverbial(GAdv),
    adjetivo(Adj).

% Dos adjetivos seguidos:
%  "final necrobótico"
g_adjetival(g_adjetival(Adj1, Adj2)) -->
    adjetivo(Adj1),
    adjetivo(Adj2).

% Adverbio + adjetivo + grupo preposicional:
%  "más susceptible a la fractura"
g_adjetival(g_adjetival(GAdv, Adj, GP)) -->
    g_adverbial(GAdv),
    adjetivo(Adj),
    g_preposicional(GP).

% Adverbio + adjetivo + de + infinitivo:
%  "más fácil de obtener"
g_adjetival(g_adjetival(GAdv, Adj, p(de), Inf)) -->
    g_adverbial(GAdv),
    adjetivo(Adj),
    [de],
    infinitivo_frase(Inf).

% Coordinación adjetival
%    "complicados o incluso imposibles de replicar"
%     Aquí complicados se coordina con imposibles de replicar.
g_adjetival(gadj_coord(Adj1, Conj, GAdj2)) -->
    adjetivo(Adj1),
    conjuncion_coordinante(Conj),
    g_adjetival(GAdj2).

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
g_adjetival(g_adjetival(Adj, p(de), Inf)) -->
    adjetivo(Adj),
    [de],
    infinitivo_frase(Inf).

% adjetivo + para + infinitivo:
%   "listo para usar"
%   "útil para aplicaciones"
g_adjetival(g_adjetival(Adj, p(para), inf(Inf))) -->
    adjetivo(Adj),
    [para],
    infinitivo(Inf).

% adjetivo + para + infinitivo con frase de infinitivo más compleja:
%   "útil para agarrar objetos"
g_adjetival(g_adjetival(Adj, p(para), Inf)) -->
    adjetivo(Adj),
    [para],
    infinitivo_frase(Inf).

% adjetivo + grupo preposicional:
%   "sensible a la presión"
g_adjetival(g_adjetival(Adj, GP)) -->
    adjetivo(Adj),
    g_preposicional(GP).

% adjetivo solo:
%   "flexionada"
g_adjetival(g_adjetival(Adj)) -->
    adjetivo(Adj).



% =========================================================
% GRUPO ADVERBIAL (GADV)
% =========================================================

% Adverbio solo:
%   "completamente"
%   "todavía"
g_adverbial(g_adverbial(Adv)) -->
    adverbio(Adv).

% Dos adverbios seguidos:
%   "todavia no"
%   "muy bien"
g_adverbial(g_adverbial(Adv1, Adv2)) -->
    adverbio(Adv1),
    adverbio(Adv2).

% Comparativa:
%   "mas rigido que el abdomen"
g_adverbial(g_adverbial(Adv, Adj, GN)) -->
    adverbio(Adv),
    adjetivo(Adj),
    [que],
    g_nominal(GN).

% =========================================================
% GRUPO PREPOSICIONAL (GP)
% =========================================================

% de que + oración simple:
%   "de que las patas se curvan..."
g_preposicional(g_preposicional(p(de_que), O)) -->
    [de, que],
    oracion_compuesta(O).

% Locución preposicional + GN:
%   "a través de la jeringuilla"
%   "gracias a la presión"
g_preposicional(g_preposicional(Loc, GN)) -->
    locucion_preposicional(Loc),
    g_nominal(GN).

% Locución preposicional + GN + conjunción coordinante + GP:
%   "al margen de la seda de araña y de los exoesqueletos mudados"
g_preposicional(g_preposicional(Loc, GN, Conj, GP)) -->
    locucion_preposicional(Loc),
    g_nominal(GN),
    conjuncion_coordinante(Conj),
    g_preposicional(GP).

% Locución preposicional + infinitivo:
%   "con el fin de comprender..."
%   "en lugar de diseñar..."
g_preposicional(g_preposicional(Loc, Inf)) -->
    locucion_preposicional(Loc),
    infinitivo_frase(Inf).

% Preposición + GN:
%   "de la araña"
%   "con geometrías irregulares"
g_preposicional(g_preposicional(P, GN)) -->
    preposicion(P),
    g_nominal(GN).

% Preposición + adverbio + GN:
%    de aproximadamente diez minutos
g_preposicional(g_preposicional(P, GAdv, GN)) -->
    preposicion(P),
    g_adverbial(GAdv),
    g_nominal(GN).

% Preposición sin + infinitivo simple:
%   "sin aplicar presión"
g_preposicional(g_preposicional(P, inf(Inf))) -->
    preposicion(P),
    { P = p(sin) },
    infinitivo(Inf).

% Preposición + infinitivo:
%   "para agarrar objetos"
%   "al incorporar materiales"
g_preposicional(g_preposicional(P, Inf)) -->
    preposicion(P),
    infinitivo_frase(Inf).

% Preposición + preposición + GN:
%   "de hasta el 130 %"
%   "por sobre el sistema" 
g_preposicional(g_preposicional(P1, P2, GN)) -->
    preposicion(P1),
    preposicion(P2),
    g_nominal(GN).

% =========================================================
% LOCUCIONES PREPOSICIONALES
% =========================================================
% El analizador trata estas secuencias como una sola preposición compleja.
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

% grupo verbal simple
g_verbal(GV) -->
    g_verbal_simple(GV).

% Coordinación verbal con inciso entre comas:
%   produce X y, además, genera Y
g_verbal(gv_coord(GV1, Conj, Inciso, GV2)) -->
    g_verbal_simple(GV1),
    conjuncion_verbal(Conj),
    inciso_oracional(Inciso),
    g_verbal_simple(GV2).

% Coordinación verbal simple:
%   puede usarse y se camufla
%   reutilizamos el cuerpo y creamos una pinza
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
% Estos colapsan none para no introducir nodos vacíos en el árbol (evitar árboles con none innecesario)
% =========================================================

gv_comp(A, B, none,  g_verbal(A, B)).
gv_comp(A, B, Comps, g_verbal(A, B, Comps)) :- Comps \= none.

gv_comp3(A, B, C, none,  g_verbal(A, B, C)).
gv_comp3(A, B, C, Comps, g_verbal(A, B, C, Comps)) :- Comps \= none.

gv_comp_v(V, none,  g_verbal(V)).
gv_comp_v(V, Comps, g_verbal(V, Comps)) :- Comps \= none.


% se + verbo + complementos opcionales
%  "se reutiliza una araña..."
g_verbal_simple(Nodo) -->
    pronombre_se(Se),
    verbo(V),
    complementos_verbales(Comps),
    { gv_comp(Se, V, Comps, Nodo) }.

% modal + infinitivo + complementos opcionales
%  "pueden reutilizarse..."
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
g_verbal_simple(g_verbal(VC, GAdj, GN)) -->
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
%  "pueden ser utilizados..."
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
%   "Se ha explorado..."
g_verbal_simple(Nodo) -->
    pronombre_se(Se),
    auxiliar(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp3(Se, Aux, Part, Comps, Nodo) }.

% Locucion verbal "dar lugar a...":
%   "dan lugar, respectivamente, a la apertura..."
% Sin esta regla, lugar podía analizarse como objeto directo normal
g_verbal_simple(Nodo) -->
    verbo_dar_lugar(V),
    [lugar],
    complementos_verbales(Comps),
    { gv_comp(V, n(lugar), Comps, Nodo) }.

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
%   "Es usar..."
g_verbal_simple(g_verbal(VC, Inf)) -->
    verbo_copulativo(VC),
    infinitivo(Inf).

% verbo + gn + gp
%   "colocamos un peso, destinado a ser agarrado..., sobre la balanza..."
%    dan lugar, respectivamente, a la apertura...
g_verbal_simple(g_verbal(V, GN, Inciso, GP, Comps), Tokens, Resto) :-
    hay_coma_inciso(Tokens),
    phrase((
        verbo(V),
        g_nominal(GN),
        inciso_oracional(Inciso),
        g_preposicional(GP),
        complementos_verbales(Comps)
    ), Tokens, Resto).

% verbo + gn antes de para + gp + complementos opcionales
% para que 'para' no se absorba dentro del GN.
g_verbal_simple(g_verbal(V, GN, GP, Comps)) -->
    verbo(V),
    g_nominal_antes_de_para(GN),
    g_preposicional(GP),
    complementos_verbales(Comps).

% verbo + gn + gp
%   "colocamos un peso sobre la balanza"
g_verbal_simple(g_verbal(V, GN, GP)) -->
    verbo(V),
    g_nominal(GN),
    g_preposicional(GP).

% verbo + gn + gadv
%   alcanza un rango completo rápidamente
g_verbal_simple(g_verbal(V, GN, GAdv)) -->
    verbo(V),
    g_nominal(GN),
    g_adverbial(GAdv).

% gadv + verbo + gn
%   también demostramos la capacidad
g_verbal_simple(g_verbal(GAdv, V, GN)) -->
    g_adverbial(GAdv),
    verbo(V),
    g_nominal(GN).

% gadv + verbo + gp
%  "no está en el sistema"
g_verbal_simple(g_verbal(GAdv, V, GP)) -->
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
            Nodo = g_verbal(GAdv, V)
        ;
            Nodo = g_verbal(GAdv, V, Comps)
        )
    }.

% verbo + gp
%    consiste en...
g_verbal_simple(g_verbal(V, GP)) -->
    verbo(V),
    g_preposicional(GP).

% verbo + gn
%   "colocamos un peso..."
g_verbal_simple(g_verbal(V, GN)) -->
    verbo(V),
    g_nominal(GN).

% verbo + gadj
%   "permanece flexionada"
g_verbal_simple(g_verbal(V, GAdj)) -->
    verbo(V),
    g_adjetival(GAdj).

% verbo + gadv
%   "actúa eficazmente"
g_verbal_simple(g_verbal(V, GAdv)) -->
    verbo(V),
    g_adverbial(GAdv).

% gadv + verbo
%  "también observamos"
g_verbal_simple(g_verbal(GAdv, V)) -->
    g_adverbial(GAdv),
    verbo(V).

% gadv + verbo copulativo + gadj:
%   "no es injustificada"
%   "no están disponibles"
g_verbal_simple(g_verbal(GAdv, VC, GAdj)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_adjetival(GAdj).

% gadv + verbo copulativo + gn:
%   "no es un problema"
g_verbal_simple(g_verbal(GAdv, VC, GN)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_nominal(GN).

% gadv + verbo copulativo + gp:
%   "no está en el sistema"
g_verbal_simple(g_verbal(GAdv, VC, GP)) -->
    g_adverbial(GAdv),
    verbo_copulativo(VC),
    g_preposicional(GP).

% verbo copulativo + gadj + gp
%   "es útil para aplicaciones"
g_verbal_simple(g_verbal(VC, GAdj, GP)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj),
    g_preposicional(GP).

% verbo copulativo + gadj
%   "es completamente funcional"
g_verbal_simple(g_verbal(VC, GAdj)) -->
    verbo_copulativo(VC),
    g_adjetival(GAdj).

% verbo copulativo + gn
%  "es un problema"
g_verbal_simple(g_verbal(VC, GN)) -->
    verbo_copulativo(VC),
    { VC \= vc(esta) }, % evitar que está se use con GN de forma rara
    g_nominal(GN).

% verbo copulativo + gp
%   "está en el sistema"
g_verbal_simple(Nodo) -->
    verbo_copulativo(VC),
    g_preposicional(GP),
    complementos_verbales(Comps),
    { gv_comp(VC, GP, Comps, Nodo) }.

% auxiliar + participio + complementos opcionales:
%   "han inspirado robots..."
%   "ha inspirado el diseño..."
g_verbal_simple(Nodo) -->
    auxiliar(Aux),
    participio(Part),
    complementos_verbales(Comps),
    { gv_comp(Aux, Part, Comps, Nodo) }.

% auxiliar + participio + gp
g_verbal_simple(g_verbal(Aux, Part, GP)) -->
    auxiliar(Aux),
    participio(Part),
    g_preposicional(GP).

% auxiliar + participio + gn
g_verbal_simple(g_verbal(Aux, Part, GN)) -->
    auxiliar(Aux),
    participio(Part),
    g_nominal(GN).

% auxiliar + participio
g_verbal_simple(g_verbal(Aux, Part)) -->
    auxiliar(Aux),
    participio(Part).

% verbo + complementos opcionales 
% (patrón general, al final para no interferir con los patrones específicos anteriores)
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

g_verbal_impersonal(g_verbal(GAdv, VI, GP)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI),
    g_preposicional(GP).

g_verbal_impersonal(g_verbal(VI, GP)) -->
    verbo_impersonal(VI),
    g_preposicional(GP).

g_verbal_impersonal(g_verbal(GAdv, VI)) -->
    g_adverbial(GAdv),
    verbo_impersonal(VI).

g_verbal_impersonal(g_verbal(VI)) -->
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

% Si aparece una coma en medio de complementos, la consumimos y seguimos buscando complementos. 
% Esto permite incisos y frases científicas largas sin bloquear todo el análisis.
%   Ejemplo: "dan lugar, respectivamente, a la apertura..."
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

% Coordinación de complementos con conjunción entre dos complementos:
%   "geometrías, volúmenes y masas variables"
complementos_verbales(comps_coord(Comp, Conj, Resto)) -->
    complemento_verbal(Comp),
    pausa_opcional,
    conjuncion_coordinante(Conj),
    complementos_verbales(Resto).

% Sin más complementos.
% Permite empezar una secuencia de complementos directamente con y.
%   y de hasta el 130 %
complementos_verbales(comps_coord_cont(Conj, Comp, Resto)) -->
    conjuncion_coordinante(Conj),
    { Conj = conj(y) },
    complemento_verbal(Comp),
    complementos_verbales(Resto).

complementos_verbales(none) -->
    [].

complemento_verbal(g_preposicional(GP)) --> g_preposicional(GP).
complemento_verbal(subc(Sub))           --> subordinada_completiva(Sub).
complemento_verbal(rel(Rel))            --> relativo_ampliado(Rel).
complemento_verbal(ger(Ger))            --> gerundio_frase(Ger).
complemento_verbal(inf(Inf))            --> infinitivo_frase(Inf).
complemento_verbal(g_nominal(GN))       --> g_nominal(GN).
complemento_verbal(partf(PartF))        --> participio_frase(PartF).
complemento_verbal(g_adjetival(GAdj))   --> g_adjetival(GAdj).
complemento_verbal(g_adverbial(GAdv))   --> g_adverbial(GAdv).
complemento_verbal(sub(Sub))            --> subordinada(Sub).
complemento_verbal(cant(Cant))          --> cantidad(Cant).

% Complemento predicativo simple:
%   "denominamos neutro"
%   en 'estado que denominamos neutro'; neutro no es un objeto normal, sino un atributo/predicativo del objeto.
complemento_verbal(pred_adj(Adj)) -->
    adjetivo(Adj).

complemento_verbal(pred_nom(N)) -->
    nombre(N).

complemento_verbal_poscoma(rel(Rel))            --> relativo_ampliado(Rel).
complemento_verbal_poscoma(ger(Ger))            --> gerundio_frase(Ger).
complemento_verbal_poscoma(partf(PartF))        --> participio_incidental(PartF).
complemento_verbal_poscoma(sub(Sub))            --> subordinada(Sub).
complemento_verbal_poscoma(g_preposicional(GP)) --> g_preposicional_incidental(GP).
complemento_verbal_poscoma(g_adverbial(GAdv))   --> g_adverbial_incidental(GAdv).

subordinada_completiva(comp_que(O)) -->
    [que],
    oracion_compuesta(O).

% Solo permite ciertas preposiciones después de coma
g_preposicional_incidental(GP) -->
    preposicion(P),
    { preposicion_incidental_word(P) },
    g_nominal(GN),
    { GP = g_preposicional(P, GN) }.

preposicion_incidental_word(p(entre)).
preposicion_incidental_word(p(debido)).
preposicion_incidental_word(p(a)).
preposicion_incidental_word(p(de)).
preposicion_incidental_word(p(sobre)).


% Reconoce adverbios incidentales que pueden aparecer entre comas como modificadores
%   "... , respectivamente,... "
g_adverbial_incidental(g_adverbial(Adv)) -->
    adverbio(Adv),
    { adverbio_incidental_word(Adv) }.

adverbio_incidental_word(adv(respectivamente)).

% Reconoce participios incidentales que pueden aparecer entre comas como modificadores
%   , destinado a ser agarrado...
participio_incidental(PartF) -->
    participio(Part),
    { Part \= part(estado) },
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, PartF) }.

% =========================================================
% INFINITIVO FRASE
% =========================================================
% Auxiliar para crear nodos limpios sin none
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

% Auxiliar para crear nodos limpios sin none
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

% Auxiliar para crear nodos limpios sin none
part_nodo(Part, none, partf(Part)).
part_nodo(Part, Comps, partf(Part, Comps)) :- Comps \= none.

% Reconoce construcciones como:
%   "destinado a ser agarrado por la pinza"
%   "compuesto por una maquina"
%   "basado en material biotico"
%   "relacionadas con la longevidad"
participio_frase(Nodo) -->
    participio(Part),
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, Nodo) }.

% Permite participios como modificadores nominales.
participio_frase_nominal(Nodo) -->
    [X],
    { participio_nominal_valido(X), Part = part(X) },
    complementos_verbales(Comps),
    { part_nodo(Part, Comps, Nodo) }.

% Solo si está en el léxico como participio y no está bloqueado.
participio_nominal_valido(X) :-
    part_word(X),
    \+ participio_finito_bloqueado(X).

participio_finito_bloqueado(aprovecha).
participio_finito_bloqueado(experimento).
participio_finito_bloqueado(presento).
participio_finito_bloqueado(personalizado).

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

% Una vez + participio:
% "Una vez fraguado el pegamento"
subordinada_inicial(sub_ini(una_vez, PartF)) -->
    [una, vez],
    participio_frase(PartF).

% Tras + GN:
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
% Estas reglas convierten tokens en nodos de árbol.
determinante(det(X))    --> [X], {det_word(X)}.
nombre(n(X))            --> [X], {nombre_word(X)}.
verbo(v(X))             --> [X], {verbo_word(X)}.
verbo_dar_lugar(v(X))   --> [X], {verbo_dar_lugar_word(X)}.
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

% Permite reconocer expresiones como:
%   130 %
%   0.35 mn
%   33.5 mg
%   5.5 kpa
%   1000 ciclos
%   17 veces

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

% Reconoce conjunciones para unir oraciones
conjuncion_oracional(Conj) -->
    conjuncion(Conj),
    { Conj \= conj(si), Conj \= conj(o), Conj \= conj(u) }.

conjuncion_nominal(Conj) --> conjuncion_coordinante(Conj).
conjuncion_verbal(Conj)  --> conjuncion_coordinante(Conj).

conjuncion_coordinante(conj(X)) --> [X], {conj_coord_word(X)}.

% =========================================================
% PAUSA (coma)
% =========================================================

pausa_opcional --> [','].
pausa_opcional --> [].

pausa_obligatoria --> [','].

% =========================================================
% PREDICADOS AUXILIARES
% =========================================================

% Comprueba todos los tokens.
tokens_conocidos([]).

tokens_conocidos([Token|Resto]) :-
    token_conocido(Token),
    tokens_conocidos(Resto).

% El corte ! evita seguir probando más categorías una vez reconocida una.
%   Esto no significa que la palabra tenga una sola categoría en el análisis. 
%   Solo significa que para la fase de validación basta con que esté en alguna categoría.
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

% Sirve exclusivamente para la locución: dar lugar a
verbo_dar_lugar_word(da).
verbo_dar_lugar_word(dan).

% Busca una coma seguida de conjunción coordinante:
hay_coma_conjuncion([',', Conj|_]) :-
    conj_coord_word(Conj),
    !.
hay_coma_conjuncion([_|Resto]) :-
    hay_coma_conjuncion(Resto).

% Busca una coma seguida de "y" o "se" (para detectar incisos como "y, además, ...")
hay_y_oracional([y, se|_]) :- !. % Detecta: y se ...
hay_y_oracional([y, Det, _, se|_]) :- % y + determinante + algo + se
    det_word(Det),
    !.
hay_y_oracional([_|Resto]) :- % Si no se encuentra el patrón, sigue buscando en el resto de la lista.
    hay_y_oracional(Resto).

% Busca una coma seguida de un marcador enumerativo como "motivos" o "razones" para yuxtapuesta explicativa
hay_coma_explicativa([Marcador, ','|_]) :-
    marcador_enumerativo(Marcador),
    !.
hay_coma_explicativa([_|Resto]) :-
    hay_coma_explicativa(Resto).

marcador_enumerativo(motivos).
marcador_enumerativo(razones).

% Se usa para forzar la regla con aposición final.
hay_coma_estado([',', estado|_]) :- !.
hay_coma_estado([_|Resto]) :-
    hay_coma_estado(Resto).

% Busca una coma seguida de un verbo, adverbio, preposición o participio para detectar incisos 
hay_coma_inciso([',', Token|_]) :-
    ( part_word(Token) ; ger_word(Token) ; adv_word(Token) ; prep_word(Token) ),
    !.
hay_coma_inciso([_|Resto]) :-
    hay_coma_inciso(Resto).

% Reconoce tokens con guion medio -, como "130-150" 
% Código ASCII 45 es -
% Comprueba que antes y después del guion haya dígitos.
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
es_nodo_complejo(ci_g_preposicional(_)).
es_nodo_complejo(ci_marcador(_)).
es_nodo_complejo(ci_sub(_)).


% ---------------------------------------------------------
% contiene_relativo/1
% Detecta si una oración contiene relativo para clasificarla como or 
% ---------------------------------------------------------

contiene_relativo(Term) :-
    sub_term(Sub, Term),
    es_nodo_relativo(Sub),
    !.

es_nodo_relativo(rel(_, _)).
es_nodo_relativo(rel_prep(_, _, _, _)).
es_nodo_relativo(rel_lo_que(_)).
es_nodo_relativo(rel_coord(_, _, _)).


% ---------------------------------------------------------
% es_oracion_simple/1
% ---------------------------------------------------------
% una oración con complemento inicial ya no es “simple” a efectos de coordinación mixta.
es_oracion_simple(o(_, _)).
es_oracion_simple(o(_)).

% ---------------------------------------------------------
% tipo_oracion/2
% ---------------------------------------------------------

tipo_oracion(oc(_,_,_),  oc).
tipo_oracion(ocm(_,_,_), ocm).
tipo_oracion(ocm(_),     ocm).

% Oración de relativo explícita, si el árbol ya tiene forma or(...)
tipo_oracion(or(_,_,_),  or).

% Oración simple cuyo SUJETO contiene una relativa:
%   "Los datos que respaldan los hallazgos están disponibles"
tipo_oracion(o(GN, _GV), or) :-
    contiene_relativo(GN),
    !.

% Complemento inicial + sujeto con relativa:
%   "En este documento, los datos que respaldan... están disponibles"
tipo_oracion(o(_CI, GN, _GV), or) :-
    contiene_relativo(GN),
    !.

% Dos complementos iniciales + sujeto con relativa
tipo_oracion(o(_CI1, _CI2, GN, _GV), or) :-
    contiene_relativo(GN),
    !.

% Si contiene complejidad interna, pero no es relativa de sujeto, es ocm
tipo_oracion(O, ocm) :-
    contiene_complejidad(O),
    !.

% Casos simples
tipo_oracion(o(_, _), o).
tipo_oracion(o(_),    o).
tipo_oracion(o(_,_,_), o).
tipo_oracion(o(_,_,_,_), o).

% ---------------------------------------------------------
% Convierte una oración compleja en lista de oraciones simples.
% ---------------------------------------------------------

% Compuesta mixta de una sola oración con complejidad interna:
% Se simplifica simplificando su contenido interno.

% Oración simple con sujeto

% Oración impersonal

% Coordinación de oraciones

% Compuesta mixta

% Relativa

% Complemento inicial + sujeto compartido + predicado coordinado

% Complemento inicial + sujeto elíptico + predicado coordinado

% Sujeto elíptico + predicado coordinado

% ---------------------------------------------------------
% analiza_lista/2
% ---------------------------------------------------------
% Entrada sencilla para analizar una lista de tokens.
% Devuelve el árbol si la oración es aceptada.
analiza_lista(Lista, Arbol) :-
    phrase(oracion(Arbol), Lista).

