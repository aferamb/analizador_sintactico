% metricas_lexico_semanticas.pl
% Extraccion de metricas lexico-semanticas por oracion.

:- encoding(utf8).

:- use_module(library(lists)).

:- ensure_loaded('main.pl').
:- ensure_loaded('lexico_semantico.pl').
:- ensure_loaded('semantico.pl').

% =========================================================
% API PUBLICA
% =========================================================

% ---------------------------------------------------------
% analizar_lexico_semantico(+Texto, -ResultadoLS)
%
% Calcula todas las metricas de la fase 1 del plan
% lexico-semantico sobre una unica oracion.
% ---------------------------------------------------------

analizar_lexico_semantico(Texto, ResultadoLS) :-
    tokenizar_basico(Texto, Tokens),
    tokens_lexicos(Tokens, TokensLexicos),
    detectar_locuciones(Tokens, TokensConLocuciones),
    clasificar_elementos(TokensConLocuciones, Clasificados),

    contar_categorias(
        Clasificados,
        NSust, NAdj, NDet, NPron, NVerb, NAdv, NPrep, NConj,
        NNoClasificados
    ),
    length(TokensLexicos, NTokensTotal),

    calcular_ratios(
        NSust, NAdj, NDet, NVerb, NAdv, NTokensTotal,
        RatioSust, RatioAdj, RatioVerb, RatioAdjSust, RatioDetSust,
        DensidadLexica
    ),

    subclasificar_sustantivos(Clasificados, SubSust),
    subclasificar_adjetivos(Clasificados, SubAdj),
    subclasificar_determinantes(Clasificados, SubDet),
    subclasificar_verbos(Clasificados, SubVerb),
    subclasificar_adverbios(Clasificados, SubAdv),
    subclasificar_preposiciones(Clasificados, SubPrep),
    subclasificar_conjunciones(Clasificados, SubConj),

    calcular_riqueza_lexica(
        TokensLexicos, TokensConLocuciones,
        TTR, Hapax, LongitudMediaPalabra, NTecnicas, NLocuciones
    ),

    calcular_semantica_sustantivos(Clasificados, SemSust, DominioDominante),
    calcular_semantica_verbos(Clasificados, SemVerb, TipoAccionDominante),
    contar_palabras_ambiguas(TokensLexicos, NAmbiguos),

    listas_por_categoria(
        Clasificados, TokensLexicos,
        ListaSust, ListaAdj, ListaVerb, ListaAdv, ListaTec
    ),

    ResultadoLS = resultado_ls(
        n_sustantivos(NSust), n_adjetivos(NAdj), n_determinantes(NDet),
        n_pronombres(NPron), n_verbos(NVerb), n_adverbios(NAdv),
        n_preposiciones(NPrep), n_conjunciones(NConj),
        n_no_clasificados(NNoClasificados), n_tokens_total(NTokensTotal),

        ratio_sustantivos(RatioSust), ratio_adjetivos(RatioAdj),
        ratio_verbos(RatioVerb), ratio_adj_sust(RatioAdjSust),
        ratio_det_sust(RatioDetSust), densidad_lexica(DensidadLexica),

        sub_sustantivos(SubSust), sub_adjetivos(SubAdj),
        sub_determinantes(SubDet), sub_verbos(SubVerb),
        sub_adverbios(SubAdv), sub_preposiciones(SubPrep),
        sub_conjunciones(SubConj),

        ttr(TTR), hapax(Hapax),
        longitud_media_palabra(LongitudMediaPalabra),
        n_tecnicas(NTecnicas), n_locuciones(NLocuciones),

        sem_sustantivos(SemSust), sem_verbos(SemVerb),
        n_ambiguos(NAmbiguos), dominio_dominante(DominioDominante),
        tipo_accion_dominante(TipoAccionDominante),

        lista_sustantivos(ListaSust), lista_adjetivos(ListaAdj),
        lista_verbos(ListaVerb), lista_adverbios(ListaAdv),
        lista_tecnicos(ListaTec)
    ),
    !.

% ---------------------------------------------------------
% detectar_locuciones(+Tokens, -TokensConLocuciones)
%
% Agrupa locuciones registradas en lexico_semantico.pl antes
% de clasificar palabra a palabra. Siempre elige la locucion
% mas larga que comienza en la posicion actual.
% ---------------------------------------------------------

detectar_locuciones([], []) :- !.

detectar_locuciones(Tokens, [locucion(Patron, Clase, Rasgos)|Salida]) :-
    mejor_locucion_en_inicio(Tokens, Patron, Clase, Rasgos),
    !,
    length(Patron, Longitud),
    quitar_n(Longitud, Tokens, Resto),
    detectar_locuciones(Resto, Salida).

detectar_locuciones([Token|Resto], [Token|Salida]) :-
    !,
    detectar_locuciones(Resto, Salida).

% ---------------------------------------------------------
% clasificar_tokens(+Tokens, -Clasificados)
%
% Clasificados contiene clasificado(Palabra, Clase, Rasgos)
% o no_clasificado(Palabra). Las locuciones no se reclasifican
% por sus tokens internos.
% ---------------------------------------------------------

clasificar_tokens(Tokens, Clasificados) :-
    detectar_locuciones(Tokens, TokensConLocuciones),
    clasificar_elementos(TokensConLocuciones, Clasificados).

% ---------------------------------------------------------
% valor_resultado_ls(+ResultadoLS, +Clave, -Valor)
% valor_submetrica_ls(+ResultadoLS, +Bloque, +Clave, -Valor)
%
% Utilidades de consulta para pruebas y para la fase comparativa.
% ---------------------------------------------------------

valor_resultado_ls(ResultadoLS, Clave, Valor) :-
    ResultadoLS =.. [resultado_ls|Campos],
    member(Campo, Campos),
    Campo =.. [Clave, Valor],
    !.

valor_submetrica_ls(ResultadoLS, Bloque, Clave, Valor) :-
    valor_resultado_ls(ResultadoLS, Bloque, Submetricas),
    member(Metrica, Submetricas),
    Metrica =.. [Clave, Valor],
    !.

% =========================================================
% TOKENIZACION, LOCUCIONES Y CLASIFICACION
% =========================================================

tokens_lexicos(Tokens, TokensLexicos) :-
    excluir_tokens_no_lexicos_ls(Tokens, TokensLexicos).

excluir_tokens_no_lexicos_ls([], []).

excluir_tokens_no_lexicos_ls([Token|Resto], Salida) :-
    token_no_lexico_ls(Token),
    !,
    excluir_tokens_no_lexicos_ls(Resto, Salida).

excluir_tokens_no_lexicos_ls([Token|Resto], [Token|Salida]) :-
    excluir_tokens_no_lexicos_ls(Resto, Salida).

token_no_lexico_ls(',').

mejor_locucion_en_inicio(Tokens, Patron, Clase, Rasgos) :-
    findall(
        Longitud-Patron0-Clase0-Rasgos0,
        (
            locucion_lexico_semantica(Patron0, Clase0, Rasgos0),
            empieza_por_ls(Tokens, Patron0),
            length(Patron0, Longitud)
        ),
        Candidatas
    ),
    Candidatas \= [],
    seleccionar_mayor_longitud(Candidatas, _-Patron-Clase-Rasgos).

seleccionar_mayor_longitud([Candidata], Candidata) :- !.

seleccionar_mayor_longitud([Longitud-Patron-Clase-Rasgos|Resto], Mejor) :-
    seleccionar_mayor_longitud(Resto, MejorResto),
    MejorResto = LongitudResto-_-_-_,
    (
        Longitud >= LongitudResto
    ->  Mejor = Longitud-Patron-Clase-Rasgos
    ;   Mejor = MejorResto
    ).

empieza_por_ls(_, []) :- !.

empieza_por_ls([Token|RestoTokens], [Token|RestoPatron]) :-
    empieza_por_ls(RestoTokens, RestoPatron).

quitar_n(0, Lista, Lista) :- !.

quitar_n(N, [_|Resto], Salida) :-
    N > 0,
    N1 is N - 1,
    quitar_n(N1, Resto, Salida).

clasificar_elementos([], []).

clasificar_elementos([Elemento|Resto], Clasificados) :-
    clasificar_elemento(Elemento, ClasificadosElemento),
    clasificar_elementos(Resto, ClasificadosResto),
    append(ClasificadosElemento, ClasificadosResto, Clasificados).

clasificar_elemento(locucion(Tokens, Clase, Rasgos), [
    clasificado(locucion(Tokens), Clase, Rasgos)
]) :-
    !.

clasificar_elemento(Token, [no_clasificado(Token)]) :-
    token_no_lexico_ls(Token),
    !.

clasificar_elemento(Token, Clasificados) :-
    findall(
        clasificado(Token, Clase, Rasgos),
        lexico_semantico(Token, Clase, Rasgos),
        Encontrados0
    ),
    sort(Encontrados0, Encontrados),
    (
        Encontrados = []
    ->  Clasificados = [no_clasificado(Token)]
    ;   Clasificados = Encontrados
    ).

% =========================================================
% CONTEOS PRINCIPALES Y RATIOS
% =========================================================

contar_categorias(
    Clasificados,
    NSust, NAdj, NDet, NPron, NVerb, NAdv, NPrep, NConj,
    NNoClasificados
) :-
    contar_clase(Clasificados, sustantivo, NSust),
    contar_clase(Clasificados, adjetivo, NAdj),
    contar_clase(Clasificados, determinante, NDet),
    contar_clase(Clasificados, pronombre, NPron),
    contar_clase(Clasificados, verbo, NVerb),
    contar_clase(Clasificados, adverbio, NAdv),
    contar_clase(Clasificados, preposicion, NPrep),
    contar_clase(Clasificados, conjuncion, NConj),
    contar_no_clasificados(Clasificados, NNoClasificados).

contar_clase(Clasificados, Clase, N) :-
    findall(1, member(clasificado(_, Clase, _), Clasificados), Unos),
    length(Unos, N).

contar_no_clasificados(Clasificados, N) :-
    findall(
        1,
        (
            member(no_clasificado(Token), Clasificados),
            \+ token_no_lexico_ls(Token)
        ),
        Unos
    ),
    length(Unos, N).

calcular_ratios(
    NSust, NAdj, NDet, NVerb, NAdv, NTokensTotal,
    RatioSust, RatioAdj, RatioVerb, RatioAdjSust, RatioDetSust,
    DensidadLexica
) :-
    ratio_seguro(NSust, NTokensTotal, RatioSust),
    ratio_seguro(NAdj, NTokensTotal, RatioAdj),
    ratio_seguro(NVerb, NTokensTotal, RatioVerb),
    ratio_seguro(NAdj, NSust, RatioAdjSust),
    ratio_seguro(NDet, NSust, RatioDetSust),
    ContenidoLexico is NSust + NVerb + NAdj + NAdv,
    ratio_seguro(ContenidoLexico, NTokensTotal, DensidadLexica).

ratio_seguro(_, 0, 0) :- !.

ratio_seguro(Numerador, Denominador, RatioRedondeado) :-
    Ratio is Numerador / Denominador,
    redondear4(Ratio, RatioRedondeado).

ratio_con_inf(0, 0, 0) :- !.
ratio_con_inf(_, 0, inf) :- !.

ratio_con_inf(Numerador, Denominador, RatioRedondeado) :-
    ratio_seguro(Numerador, Denominador, RatioRedondeado).

redondear4(Numero, Redondeado) :-
    Redondeado is round(Numero * 10000) / 10000.

% =========================================================
% SUBCLASIFICACIONES
% =========================================================

subclasificar_sustantivos(Clasificados, SubSust) :-
    contar_clase_rasgo(Clasificados, sustantivo, significado(concreto), NConcretos),
    contar_clase_rasgo(Clasificados, sustantivo, significado(abstracto), NAbstractos),
    contar_clase_rasgo(Clasificados, sustantivo, significado(colectivo), NColectivos),
    contar_clase_rasgo(Clasificados, sustantivo, contabilidad(contable), NContables),
    contar_clase_rasgo(Clasificados, sustantivo, contabilidad(no_contable), NNoContables),
    contar_clase_rasgo(Clasificados, sustantivo, referente(propio), NPropios),
    contar_clase_rasgo(Clasificados, sustantivo, referente(comun), NComunes),
    ratio_con_inf(NAbstractos, NConcretos, RatioAbstractoConcreto),
    dominante_desde_pares(
        [concreto-NConcretos, abstracto-NAbstractos, colectivo-NColectivos],
        Dominante
    ),
    SubSust = [
        sust_concretos(NConcretos),
        sust_abstractos(NAbstractos),
        sust_colectivos(NColectivos),
        sust_contables(NContables),
        sust_no_contables(NNoContables),
        sust_propios(NPropios),
        sust_comunes(NComunes),
        ratio_abstracto_concreto(RatioAbstractoConcreto),
        sust_significado_dominante(Dominante)
    ].

subclasificar_adjetivos(Clasificados, SubAdj) :-
    contar_clase_rasgo(Clasificados, adjetivo, tipo_propiedad(calificativo), NCalif),
    contar_clase_rasgo(Clasificados, adjetivo, tipo_propiedad(relacional), NRel),
    contar_clase_rasgo(Clasificados, adjetivo, tipo_propiedad(adverbial), NAdv),
    contar_clase_rasgo(Clasificados, adjetivo, grado(positivo), NPos),
    contar_clase_rasgo(Clasificados, adjetivo, grado(comparativo), NComp),
    contar_clase_rasgo(
        Clasificados, adjetivo, grado(superlativo_absoluto), NSup
    ),
    dominante_desde_pares(
        [calificativo-NCalif, relacional-NRel, adverbial-NAdv],
        Dominante
    ),
    SubAdj = [
        adj_calificativos(NCalif),
        adj_relacionales(NRel),
        adj_adverbiales(NAdv),
        adj_grado_positivo(NPos),
        adj_grado_comparativo(NComp),
        adj_grado_superlativo(NSup),
        adj_tipo_dominante(Dominante)
    ].

subclasificar_determinantes(Clasificados, SubDet) :-
    contar_rasgos(Clasificados, determinante, rasgos_articulo_determinado, NDet),
    contar_rasgos(Clasificados, determinante, rasgos_articulo_indeterminado, NIndet),
    contar_rasgos(Clasificados, determinante, rasgos_demostrativo, NDemo),
    contar_rasgos(Clasificados, determinante, rasgos_posesivo, NPos),
    contar_rasgos(Clasificados, determinante, rasgos_numeral, NNum),
    contar_rasgos(Clasificados, determinante, rasgos_indefinido, NIndef),
    SubDet = [
        det_articulos_determinados(NDet),
        det_articulos_indeterminados(NIndet),
        det_demostrativos(NDemo),
        det_posesivos(NPos),
        det_numerales(NNum),
        det_indefinidos(NIndef)
    ].

subclasificar_verbos(Clasificados, SubVerb) :-
    contar_rasgos(Clasificados, verbo, rasgos_forma_conjugada, NConj),
    contar_rasgos(Clasificados, verbo, rasgos_forma_infinitivo, NInf),
    contar_rasgos(Clasificados, verbo, rasgos_forma_gerundio, NGer),
    contar_rasgos(Clasificados, verbo, rasgos_forma_participio, NPart),
    contar_clase_rasgo(Clasificados, verbo, transitividad(transitivo), NTrans),
    contar_clase_rasgo(Clasificados, verbo, transitividad(intransitivo), NIntrans),
    contar_clase_rasgo(Clasificados, verbo, transitividad(ditransitivo), NDitrans),
    contar_clase_rasgo(Clasificados, verbo, transitividad(contextual), NContext),
    contar_clase_rasgo(Clasificados, verbo, funcion_predicativa(copulativo), NCop),
    contar_clase_rasgo(
        Clasificados, verbo, funcion_predicativa(semicopulativo), NSemiCop
    ),
    contar_clase_rasgo(Clasificados, verbo, funcion_predicativa(predicativo), NPred),
    contar_clase_rasgo(Clasificados, verbo, tipo_especial(auxiliar), NAux),
    contar_clase_rasgo(Clasificados, verbo, tipo_especial(modal), NModal),
    contar_clase_rasgo(Clasificados, verbo, tipo_especial(pronominal), NPron),
    contar_clase_rasgo(Clasificados, verbo, regularidad(regular), NReg),
    contar_clase_rasgo(Clasificados, verbo, regularidad(irregular), NIrr),
    SubVerb = [
        verb_conjugadas(NConj),
        verb_infinitivos(NInf),
        verb_gerundios(NGer),
        verb_participios(NPart),
        verb_transitivos(NTrans),
        verb_intransitivos(NIntrans),
        verb_ditransitivos(NDitrans),
        verb_contextuales(NContext),
        verb_copulativos(NCop),
        verb_semicopulativos(NSemiCop),
        verb_predicativos(NPred),
        verb_auxiliares(NAux),
        verb_modales(NModal),
        verb_pronominales(NPron),
        verb_regulares(NReg),
        verb_irregulares(NIrr)
    ].

subclasificar_adverbios(Clasificados, SubAdv) :-
    contar_clase_rasgo(Clasificados, adverbio, significado(modo), NModo),
    contar_clase_rasgo(Clasificados, adverbio, significado(lugar), NLugar),
    contar_clase_rasgo(Clasificados, adverbio, significado(tiempo), NTiempo),
    contar_clase_rasgo(
        Clasificados, adverbio, significado(cantidad_grado), NCantidad
    ),
    contar_clase_rasgo(Clasificados, adverbio, significado(negacion), NNeg),
    contar_clase_rasgo(Clasificados, adverbio, significado(orden), NOrden),
    contar_clase_rasgo(
        Clasificados, adverbio, funcion_discursiva(conector_discursivo), NCon
    ),
    contar_clase_rasgo(Clasificados, adverbio, forma(derivado_mente), NMente),
    contar_clase_rasgo(Clasificados, adverbio, forma(simple), NSimples),
    contar_clase_rasgo(
        Clasificados, adverbio, forma(locucion_adverbial), NLocAdv
    ),
    SubAdv = [
        adv_modo(NModo),
        adv_lugar(NLugar),
        adv_tiempo(NTiempo),
        adv_cantidad_grado(NCantidad),
        adv_negacion(NNeg),
        adv_orden(NOrden),
        adv_conector_discursivo(NCon),
        adv_derivados_mente(NMente),
        adv_simples(NSimples),
        adv_locuciones(NLocAdv)
    ].

subclasificar_preposiciones(Clasificados, SubPrep) :-
    contar_rasgos(Clasificados, preposicion, rasgos_prep_propia, NPropias),
    contar_clase_rasgo(Clasificados, preposicion, tipo(contraccion), NContr),
    contar_clase_rasgo(
        Clasificados, preposicion, tipo(locucion_preposicional), NLoc
    ),
    contar_clase_rasgo(
        Clasificados, preposicion, tipo(impropia_o_contextual), NImpropias
    ),
    SubPrep = [
        prep_propias(NPropias),
        prep_contracciones(NContr),
        prep_locuciones(NLoc),
        prep_impropias_contextuales(NImpropias)
    ].

subclasificar_conjunciones(Clasificados, SubConj) :-
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(coordinante(copulativa)), NCop
    ),
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(coordinante(disyuntiva)), NDisy
    ),
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(coordinante(adversativa)), NAdv
    ),
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(subordinante(completiva)), NCompl
    ),
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(subordinante(temporal)), NTemp
    ),
    contar_rasgos(Clasificados, conjuncion, rasgos_conj_subord_otras, NOtras),
    contar_rasgos(Clasificados, conjuncion, rasgos_conj_coordinante, NCoord),
    contar_rasgos(Clasificados, conjuncion, rasgos_conj_subordinante, NSub),
    contar_clase_rasgo(
        Clasificados, conjuncion, tipo(locucion_conjuntiva), NLoc
    ),
    ratio_con_inf(NSub, NCoord, RatioSubCoord),
    SubConj = [
        conj_coord_copulativas(NCop),
        conj_coord_disyuntivas(NDisy),
        conj_coord_adversativas(NAdv),
        conj_subord_completivas(NCompl),
        conj_subord_temporales(NTemp),
        conj_subord_otras(NOtras),
        conj_coordinantes(NCoord),
        conj_subordinantes(NSub),
        conj_locuciones(NLoc),
        ratio_subord_coord(RatioSubCoord)
    ].

contar_clase_rasgo(Clasificados, Clase, Rasgo, N) :-
    findall(
        1,
        (
            member(clasificado(_, Clase, Rasgos), Clasificados),
            memberchk(Rasgo, Rasgos)
        ),
        Unos
    ),
    length(Unos, N).

contar_rasgos(Clasificados, Clase, Predicado, N) :-
    findall(
        1,
        (
            member(clasificado(_, Clase, Rasgos), Clasificados),
            call(Predicado, Rasgos)
        ),
        Unos
    ),
    length(Unos, N).

rasgos_articulo_determinado(Rasgos) :-
    memberchk(tipo(articulo(determinado)), Rasgos).

rasgos_articulo_indeterminado(Rasgos) :-
    memberchk(tipo(articulo(indeterminado)), Rasgos).

rasgos_demostrativo(Rasgos) :-
    member(tipo(demostrativo(_)), Rasgos).

rasgos_posesivo(Rasgos) :-
    member(tipo(posesivo(_)), Rasgos).

rasgos_numeral(Rasgos) :-
    member(tipo(numeral(_)), Rasgos).

rasgos_indefinido(Rasgos) :-
    memberchk(tipo(indefinido), Rasgos).

rasgos_forma_conjugada(Rasgos) :-
    rasgos_forma_verbal(Rasgos, conjugada).

rasgos_forma_infinitivo(Rasgos) :-
    rasgos_forma_verbal(Rasgos, infinitivo).

rasgos_forma_gerundio(Rasgos) :-
    rasgos_forma_verbal(Rasgos, gerundio).

rasgos_forma_participio(Rasgos) :-
    rasgos_forma_verbal(Rasgos, participio).

rasgos_forma_verbal(Rasgos, Forma) :-
    memberchk(formas(Formas), Rasgos),
    memberchk(Forma, Formas).

rasgos_prep_propia(Rasgos) :-
    member(tipo(propia(_)), Rasgos).

rasgos_conj_coordinante(Rasgos) :-
    member(tipo(coordinante(_)), Rasgos).

rasgos_conj_subordinante(Rasgos) :-
    ( member(tipo(subordinante(_)), Rasgos)
    ; member(subtipo(subordinante(_)), Rasgos)
    ),
    !.

rasgos_conj_subord_otras(Rasgos) :-
    rasgos_conj_subordinante(Rasgos),
    \+ memberchk(tipo(subordinante(completiva)), Rasgos),
    \+ memberchk(tipo(subordinante(temporal)), Rasgos).

% =========================================================
% RIQUEZA LEXICA Y LISTAS
% =========================================================

calcular_riqueza_lexica(
    TokensLexicos, TokensConLocuciones,
    TTR, Hapax, LongitudMediaPalabra, NTecnicas, NLocuciones
) :-
    tipos_unicos(TokensLexicos, TiposUnicos),
    length(TiposUnicos, NTiposUnicos),
    length(TokensLexicos, NTokens),
    ratio_seguro(NTiposUnicos, NTokens, TTR),
    contar_hapax(TokensLexicos, Hapax),
    longitud_media_tokens(TokensLexicos, LongitudMediaPalabra),
    contar_tecnicos(TokensLexicos, NTecnicas),
    contar_locuciones(TokensConLocuciones, NLocuciones).

tipos_unicos(Tokens, TiposUnicos) :-
    sort(Tokens, TiposUnicos).

contar_hapax(Tokens, Hapax) :-
    msort(Tokens, Ordenados),
    contar_hapax_ordenados(Ordenados, Hapax).

contar_hapax_ordenados([], 0).

contar_hapax_ordenados([Token|Resto], Hapax) :-
    consumir_iguales(Token, Resto, 1, RestoDistinto, Frecuencia),
    contar_hapax_ordenados(RestoDistinto, HapaxResto),
    (
        Frecuencia =:= 1
    ->  Hapax is HapaxResto + 1
    ;   Hapax = HapaxResto
    ).

consumir_iguales(Token, [Token|Resto], Acum, RestoDistinto, Frecuencia) :-
    !,
    Acum1 is Acum + 1,
    consumir_iguales(Token, Resto, Acum1, RestoDistinto, Frecuencia).

consumir_iguales(_, RestoDistinto, Frecuencia, RestoDistinto, Frecuencia).

longitud_media_tokens([], 0) :- !.

longitud_media_tokens(Tokens, LongitudMedia) :-
    findall(Longitud, (member(Token, Tokens), atom_length(Token, Longitud)), Longitudes),
    sum_list(Longitudes, Suma),
    length(Longitudes, N),
    Media is Suma / N,
    redondear4(Media, LongitudMedia).

contar_tecnicos(Tokens, N) :-
    findall(1, (member(Token, Tokens), termino_tecnico_normalizado(Token)), Unos),
    length(Unos, N).

contar_locuciones(TokensConLocuciones, N) :-
    findall(1, member(locucion(_, _, _), TokensConLocuciones), Unos),
    length(Unos, N).

listas_por_categoria(
    Clasificados, TokensLexicos,
    ListaSust, ListaAdj, ListaVerb, ListaAdv, ListaTec
) :-
    lista_palabras_clase(Clasificados, sustantivo, ListaSust),
    lista_palabras_clase(Clasificados, adjetivo, ListaAdj),
    lista_palabras_clase(Clasificados, verbo, ListaVerb),
    lista_palabras_clase(Clasificados, adverbio, ListaAdv),
    findall(Token, (member(Token, TokensLexicos), termino_tecnico_normalizado(Token)), Tec0),
    sort(Tec0, ListaTec).

lista_palabras_clase(Clasificados, Clase, Lista) :-
    findall(Palabra, member(clasificado(Palabra, Clase, _), Clasificados), Palabras0),
    sort(Palabras0, Lista).

termino_tecnico_normalizado(Token) :-
    atom(Token),
    termino_tecnico(Token),
    !.

termino_tecnico_normalizado(Token) :-
    atom(Token),
    atom_codes(Token, Codigos),
    reemplazar_codigo(Codigos, 241, 110, CodigosNormalizados),
    Codigos \= CodigosNormalizados,
    atom_codes(TokenNormalizado, CodigosNormalizados),
    termino_tecnico(TokenNormalizado).

reemplazar_codigo([], _, _, []).

reemplazar_codigo([Codigo|Resto], Codigo, Sustituto, [Sustituto|Salida]) :-
    !,
    reemplazar_codigo(Resto, Codigo, Sustituto, Salida).

reemplazar_codigo([Codigo|Resto], Buscado, Sustituto, [Codigo|Salida]) :-
    reemplazar_codigo(Resto, Buscado, Sustituto, Salida).

% =========================================================
% SEMANTICA DE DOMINIO
% =========================================================

calcular_semantica_sustantivos(Clasificados, SemSust, DominioDominante) :-
    categorias_semanticas_sustantivo(Categorias),
    findall(
        Categoria,
        (
            member(clasificado(Palabra, sustantivo, _), Clasificados),
            atom(Palabra),
            tipo(Palabra, Categoria)
        ),
        Encontradas
    ),
    conteos_por_categorias(Categorias, Encontradas, Pares),
    pares_a_terminos(n_sust_, Pares, SemSust),
    dominante_desde_pares(Pares, DominioDominante).

calcular_semantica_verbos(Clasificados, SemVerb, TipoAccionDominante) :-
    categorias_semanticas_verbo(Categorias),
    findall(
        Categoria,
        (
            member(clasificado(Palabra, verbo, _), Clasificados),
            atom(Palabra),
            tipo_verbo(Palabra, Categoria)
        ),
        Encontradas
    ),
    conteos_por_categorias(Categorias, Encontradas, Pares),
    pares_a_terminos(n_verb_, Pares, SemVerb),
    dominante_desde_pares(Pares, TipoAccionDominante).

categorias_semanticas_sustantivo([
    ser_vivo,
    organismo_biologico,
    entidad_robotica,
    componente_biologico,
    componente_mecanico,
    material_biotico,
    material_sintetico,
    sustancia,
    instrumento,
    objeto_fisico,
    proceso_nominal,
    concepto_abstracto,
    lugar,
    persona
]).

categorias_semanticas_verbo([
    accion_fisica,
    proceso_biologico,
    accion_tecnica,
    proceso_mecanico,
    accion_cognitiva,
    accion_comunicativa
]).

conteos_por_categorias([], _, []).

conteos_por_categorias([Categoria|Resto], Encontradas, [Categoria-N|Salida]) :-
    contar_ocurrencias(Categoria, Encontradas, N),
    conteos_por_categorias(Resto, Encontradas, Salida).

contar_ocurrencias(_, [], 0).

contar_ocurrencias(X, [X|Resto], N) :-
    !,
    contar_ocurrencias(X, Resto, N0),
    N is N0 + 1.

contar_ocurrencias(X, [_|Resto], N) :-
    contar_ocurrencias(X, Resto, N).

pares_a_terminos(_, [], []).

pares_a_terminos(Prefijo, [Categoria-N|Resto], [Termino|Salida]) :-
    atom_concat(Prefijo, Categoria, Functor),
    Termino =.. [Functor, N],
    pares_a_terminos(Prefijo, Resto, Salida).

contar_palabras_ambiguas(TokensLexicos, N) :-
    findall(1, (member(Token, TokensLexicos), es_ambiguo(Token)), Unos),
    length(Unos, N).

dominante_desde_pares(Pares, Dominante) :-
    maximo_conteo(Pares, Maximo),
    (
        Maximo =:= 0
    ->  Dominante = ninguno
    ;   member(Dominante-Maximo, Pares),
        !
    ).

maximo_conteo([], 0).

maximo_conteo([_-N|Resto], Maximo) :-
    maximo_conteo(Resto, MaxResto),
    (
        N >= MaxResto
    ->  Maximo = N
    ;   Maximo = MaxResto
    ).
