:- encoding(utf8).

% simplificar.pl
% Simplificacion recursiva de arboles sintacticos.
%
% La gramatica construye arboles Prolog; este modulo los transforma en una
% lista de oraciones mas simples y proporciona una realizacion textual legible.

% =========================================================
% NORMALIZACION DE ORACIONES
% =========================================================

normalizar_oracion(o(CI1, CI2, GN, GV), oracion_norm([CI1, CI2], GN, GV, [])) :-
    es_complemento_inicial(CI1),
    es_complemento_inicial(CI2),
    !.

normalizar_oracion(o(CI1, CI2, GN, GV, Extra), oracion_norm([CI1, CI2], GN, GV, [Extra])) :-
    es_complemento_inicial(CI1),
    es_complemento_inicial(CI2),
    es_extra_oracional(Extra),
    !.

normalizar_oracion(o(CI, GN, GV, Extra), oracion_norm([CI], GN, GV, [Extra])) :-
    es_complemento_inicial(CI),
    es_extra_oracional(Extra),
    !.

normalizar_oracion(o(CI, GN, GV), oracion_norm([CI], GN, GV, [])) :-
    es_complemento_inicial(CI),
    !.

normalizar_oracion(o(GN, Extra, GV), oracion_norm([], GN, GV, [Extra])) :-
    es_extra_oracional(Extra),
    !.

normalizar_oracion(o(GN, GV, Extra), oracion_norm([], GN, GV, [Extra])) :-
    es_extra_oracional(Extra),
    !.

normalizar_oracion(o(CI, GV), oracion_norm([CI], sujeto_impersonal, GV, [])) :-
    es_complemento_inicial(CI),
    !.

normalizar_oracion(o(sujeto_eliptico, GV), oracion_norm([], sujeto_eliptico, GV, [])) :- !.

normalizar_oracion(o(GN, GV), oracion_norm([], GN, GV, [])) :- !.

normalizar_oracion(o(GV), oracion_norm([], sujeto_impersonal, GV, [])).

construir_oracion_norm(oracion_norm([], sujeto_impersonal, GV, []), o(GV)) :- !.
construir_oracion_norm(oracion_norm([CI], sujeto_impersonal, GV, []), o(CI, GV)) :- !.
construir_oracion_norm(oracion_norm([], GN, GV, []), o(GN, GV)) :- !.
construir_oracion_norm(oracion_norm([CI], GN, GV, []), o(CI, GN, GV)) :- !.
construir_oracion_norm(oracion_norm([CI1, CI2], GN, GV, []), o(CI1, CI2, GN, GV)) :- !.
construir_oracion_norm(oracion_norm([], GN, GV, [Extra]), o(GN, GV, Extra)) :- !.
construir_oracion_norm(oracion_norm([CI], GN, GV, [Extra]), o(CI, GN, GV, Extra)) :- !.
construir_oracion_norm(oracion_norm([CI1, CI2], GN, GV, [Extra]), o(CI1, CI2, GN, GV, Extra)) :- !.

% =========================================================
% MOTOR RECURSIVO
% =========================================================

simplificar(Oracion, Resultado) :-
    simplificar_pendientes([Oracion], [], Resultado).

simplificar_pendientes([], _Visitadas, []).

simplificar_pendientes([Oracion|Resto], Visitadas, Resultado) :-
    \+ memberchk(Oracion, Visitadas),
    once(paso_simplificacion(Oracion, Nuevas0)),
    limpiar_paso(Oracion, Nuevas0, Nuevas),
    !,
    append(Nuevas, Resto, Pendientes),
    simplificar_pendientes(Pendientes, [Oracion|Visitadas], Resultado).

simplificar_pendientes([Oracion|Resto], Visitadas, [Oracion|Resultado]) :-
    simplificar_pendientes(Resto, [Oracion|Visitadas], Resultado).

limpiar_paso(Original, Nuevas0, Nuevas) :-
    excluir_iguales(Original, Nuevas0, Nuevas),
    Nuevas \= [].

excluir_iguales(_Original, [], []).

excluir_iguales(Original, [Original|Resto], Salida) :-
    !,
    excluir_iguales(Original, Resto, Salida).

excluir_iguales(Original, [X|Resto], [X|Salida]) :-
    excluir_iguales(Original, Resto, Salida).

% =========================================================
% PASOS DE SIMPLIFICACION
% =========================================================

% 1. Nodos compuestos de la gramatica.
paso_simplificacion(ocm(O), [O]).

paso_simplificacion(oc(O1, _, O2), [O1, O2ConSujeto]) :-
    normalizar_oracion(O1, oracion_norm(_CIs1, Sujeto1, _GV1, _Extras1)),
    normalizar_oracion(O2, oracion_norm(CIs2, sujeto_eliptico, GV2, Extras2)),
    construir_oracion_norm(oracion_norm(CIs2, Sujeto1, GV2, Extras2), O2ConSujeto),
    !.

paso_simplificacion(oc(O1, _, O2), [O1, O2]).
paso_simplificacion(ocm(O1, _, O2), [O1, O2]).

% 2. Relativas.
paso_simplificacion(or(GN, rel(_, GVRel), GVPrinc), [o(GN, GVRel), o(GN, GVPrinc)]).

paso_simplificacion(O, [OPrincipal, ORelativa]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, GV, Extras)),
    extraer_relativa_de_gv(GV, GVSinRel, Antecedente, Rel),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GVSinRel, Extras), OPrincipal),
    oracion_de_relativa(Antecedente, Rel, ORelativa).

% 3. Subordinadas iniciales capaces de convertirse en oracion.
paso_simplificacion(O, [OSub, OPrincipal]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, GV, Extras)),
    extraer_subordinada_inicial(CIs, CIsSinSub, OSub),
    construir_oracion_norm(oracion_norm(CIsSinSub, Sujeto, GV, Extras), OPrincipal).

% 4. Distribuciones combinatorias controladas. Se prueban antes de las
% coordinaciones internas pequenas para no perder combinaciones.
paso_simplificacion(O, Resultado) :-
    normalizar_oracion(O, oracion_norm(_CIs, Sujeto, GV, _Extras)),
    distribucion_coordinaciones_anidadas(GV, OracionesTexto),
    tokens_de_arbol(Sujeto, TokensSujeto),
    prefijar_sujeto(TokensSujeto, OracionesTexto, Resultado).

% 5. Coordinacion verbal o predicativa.
paso_simplificacion(O, [O1, O2]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, gv_coord(GV1, _, GV2), Extras)),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV1, Extras), O1),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV2, Extras), O2).

paso_simplificacion(O, [O1, O2]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, gv_coord(GV1, _, Inciso, GV2), Extras)),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV1, Extras), O1),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV2, [Inciso|Extras]), O2).

paso_simplificacion(O, [O1, O2]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, GV, Extras)),
    dividir_adjetivo_coord(GV, GV1, GV2),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV1, Extras), O1),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV2, Extras), O2).

% 6. Complementos iniciales coordinados.
paso_simplificacion(O, [O1, O2]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, GV, Extras)),
    dividir_complemento_inicial_coord(CIs, CIs1, CIs2),
    construir_oracion_norm(oracion_norm(CIs1, Sujeto, GV, Extras), O1),
    construir_oracion_norm(oracion_norm(CIs2, Sujeto, GV, Extras), O2).

% 7. Division binaria de complementos coordinados.
paso_simplificacion(O, [O1, O2]) :-
    normalizar_oracion(O, oracion_norm(CIs, Sujeto, GV, Extras)),
    dividir_gv_por_complemento_coord(GV, GV1, GV2),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV1, Extras), O1),
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV2, Extras), O2).

% =========================================================
% DISTRIBUCION DE VARIANTES
% =========================================================

construir_oraciones_variantes(_CIs, _Sujeto, _Extras, [], []).

construir_oraciones_variantes(CIs, Sujeto, Extras, [GV|Resto], [O|Salida]) :-
    construir_oracion_norm(oracion_norm(CIs, Sujeto, GV, Extras), O),
    construir_oraciones_variantes(CIs, Sujeto, Extras, Resto, Salida).

generar_variantes_gv(GV, Variantes) :-
    variantes_term(GV, Variantes0),
    quitar_duplicados(Variantes0, Variantes),
    Variantes = [_,_|_].

variantes_term(Term, Variantes) :-
    alternativa_directa(Term, Alternativas),
    !,
    Variantes = Alternativas.

variantes_term(Term, Variantes) :-
    compound(Term),
    Term =.. [Functor|Args],
    variantes_args(Args, ArgsVariantes),
    combinar_args(ArgsVariantes, Combinaciones),
    construir_terms(Functor, Combinaciones, Variantes0),
    quitar_duplicados(Variantes0, Variantes).

variantes_term(Term, [Term]).

variantes_args([], []).

variantes_args([Arg|Resto], [VariantesArg|VariantesResto]) :-
    variantes_term(Arg, VariantesArg),
    variantes_args(Resto, VariantesResto).

combinar_args([], [[]]).

combinar_args([Opciones|Resto], Combinaciones) :-
    combinar_args(Resto, CombinacionesResto),
    findall([Opcion|Comb], (member(Opcion, Opciones), member(Comb, CombinacionesResto)), Combinaciones).

construir_terms(_Functor, [], []).

construir_terms(Functor, [Args|Resto], [Term|Salida]) :-
    Term =.. [Functor|Args],
    construir_terms(Functor, Resto, Salida).

quitar_duplicados([], []).

quitar_duplicados([X|Resto], Salida) :-
    memberchk(X, Resto),
    !,
    quitar_duplicados(Resto, Salida).

quitar_duplicados([X|Resto], [X|Salida]) :-
    quitar_duplicados(Resto, Salida).

% Alternativas estructurales frecuentes en los arboles de la gramatica.
alternativa_directa(g_adjetival(gadj_coord(Adj1, conj(_), g_adjetival(Adj2))), [
    g_adjetival(g_adjetival(Adj1)),
    g_adjetival(g_adjetival(Adj2))
]).

alternativa_directa(g_nominal(g_nominal(GN1, conj(_), GN2)), [
    g_nominal(GN1),
    g_nominal(GN2)
]).

alternativa_directa(gn_lista(GN1, GN2, Conj, GN3), [
    GN1,
    g_nominal(g_nominal(GN2, Conj, GN3))
]).

alternativa_directa(comps_coord(Comp1, conj(_), Resto), Variantes) :-
    variantes_comps(Resto, RestoVariantes),
    append([Comp1], RestoVariantes, Variantes).

alternativa_directa(comps_coord_cont(conj(_), Comp, Resto), Variantes) :-
    variantes_comps(Resto, RestoVariantes),
    append([Comp], RestoVariantes, Variantes).

alternativa_directa(comps(Comp1, comps_coord_cont(conj(_), Comp2, Resto)), [
    comps(Comp1, none),
    comps(Comp1ConComp2, Resto)
]) :-
    complemento_nominal_desnudo(Comp2),
    reemplazar_gp_mas_interno(Comp1, Comp2, Comp1ConComp2),
    !.

alternativa_directa(comps(Comp1, comps_coord_cont(conj(_), Comp2, Resto)), [
    comps(Comp1, none),
    comps(Base, comps(Comp2, Resto))
]) :-
    \+ complemento_nominal_desnudo(Comp2),
    base_complemento_coord(Comp1, Base),
    !.

alternativa_directa(comps(Comp1, comps_coord_cont(conj(_), Comp2, Resto)), [
    comps(Comp1, none),
    comps(Comp2, Resto)
]).

% Caso distributivo frecuente: "celulas y tejidos naturales o de ingenieria".
alternativa_directa(
    comps(
        g_nominal(g_nominal(N1, none)),
        comps_coord_cont(
            conj(_),
            g_nominal(g_nominal(N2, none)),
            comps_coord(g_nominal(g_nominal(_Mod1, none)), conj(_), Resto)
        )
    ),
    Variantes
) :-
    variantes_comps(Resto, RestoVariantes),
    findall(
        comps(g_nominal(g_nominal(N, mod_nominal_simple(_Mod), none)), RV),
        ( member(N, [N1, N2]), member(RV, [none|RestoVariantes]) ),
        Variantes0
    ),
    quitar_duplicados(Variantes0, Variantes).

variantes_comps(none, []) :- !.

variantes_comps(comps(Comp, Resto), Variantes) :-
    variantes_comps(Resto, RestoVariantes),
    append([Comp], RestoVariantes, Variantes).

variantes_comps(comps_coord(Comp, _Conj, Resto), Variantes) :-
    variantes_comps(Resto, RestoVariantes),
    append([Comp], RestoVariantes, Variantes).

variantes_comps(comps_coord_cont(_Conj, Comp, Resto), Variantes) :-
    variantes_comps(Resto, RestoVariantes),
    append([Comp], RestoVariantes, Variantes).

distribucion_coordinaciones_anidadas(g_verbal(v(V), Comps), Oraciones) :-
    extraer_distribucion_comps(Comps, Sujetos, Modificadores, Comun, Objetos),
    combinar_distribucion([V], Sujetos, Modificadores, Comun, Objetos, Oraciones).

distribucion_coordinaciones_anidadas(g_verbal(v(V), GN, GP), Oraciones) :-
    extraer_distribucion_gn_gp(GN, GP, Sujetos, Modificadores, Comun, Objetos),
    combinar_distribucion([V], Sujetos, Modificadores, Comun, Objetos, Oraciones).

distribucion_coordinaciones_anidadas(g_verbal(v(V), GN, GP, _Comps), Oraciones) :-
    extraer_distribucion_gn_gp(GN, GP, Sujetos, Modificadores, Comun, Objetos),
    combinar_distribucion([V], Sujetos, Modificadores, Comun, Objetos, Oraciones).

extraer_distribucion_comps(
    comps(
        g_nominal(g_nominal(N1, none)),
        comps_coord_cont(
            conj(_),
            g_nominal(g_nominal(N2, none)),
            comps_coord(Mod1, conj(_), comps(GPMod2, comps_coord_cont(conj(_), Obj2, none)))
        )
    ),
    [S1, S2],
    [M1, M2],
    Comun,
    [Obj1Completo, Obj2Tokens]
) :-
    tokens_limpios(g_nominal(g_nominal(N1, none)), S1),
    tokens_limpios(g_nominal(g_nominal(N2, none)), S2),
    tokens_limpios(Mod1, M1),
    extraer_modificador_con_comun(GPMod2, M2, Comun, Obj1),
    objeto_con_mod_compartido(Obj1, Obj2, Obj1Completo, Obj2Tokens).

extraer_distribucion_gn_gp(GN, GP, Sujetos, Modificadores, Comun, Objetos) :-
    extraer_sujetos_modificadores_gn(GN, Sujetos, Modificadores, ComunGN),
    extraer_objetos_gp(GP, ComunGP, Objetos),
    append(ComunGN, ComunGP, Comun).

extraer_sujetos_modificadores_gn(
    g_nominal(GN1, conj(_), GN2),
    [S1, S2],
    [M1, M2],
    Comun
) :-
    sub_term(gadj_coord(Adj1, conj(_), g_adjetival(Adj2A, GPComun)), GN2),
    base_gn_coord(GN2, GN2Base),
    tokens_limpios(GN1, S1),
    tokens_limpios(GN2Base, S2),
    tokens_limpios(g_adjetival(g_adjetival(Adj1)), M1),
    extraer_adj_con_comun(g_adjetival(Adj2A, GPComun), M2, Comun),
    !.

extraer_sujetos_modificadores_gn(
    g_nominal(g_nominal(N1, none), conj(_), g_nominal(N2, mod(g_adjetival(gadj_coord(Adj1, conj(_), g_adjetival(Adj2))), none))),
    [S1, S2],
    [M1, M2],
    Comun
) :-
    tokens_limpios(g_nominal(g_nominal(N1, none)), S1),
    tokens_limpios(g_nominal(g_nominal(N2, none)), S2),
    tokens_limpios(g_adjetival(g_adjetival(Adj1)), M1),
    extraer_adj_con_comun(Adj2, M2, Comun).

extraer_objetos_gp(
    g_preposicional(p(para), inf(inf(Inf), comps(Obj1, comps_coord_cont(conj(_), Obj2, none)))),
    Comun,
    [Obj1Completo, Obj2Tokens]
) :-
    tokens_limpios(inf(Inf), InfTokens),
    InfConPrep = [para|InfTokens],
    tokens_limpios(Obj1, Obj1Base),
    objeto_con_mod_compartido_tokens(Obj1Base, Obj2, Obj1CompletoSinInf, Obj2SinInf),
    append(InfConPrep, Obj1CompletoSinInf, Obj1Completo),
    append(InfConPrep, Obj2SinInf, Obj2Tokens),
    Comun = [].

extraer_objetos_gp(
    g_preposicional(p(para), inf(inf(Inf), comps(Obj1, comps_coord_cont(conj(_), Obj2, none))), none),
    Comun,
    Objetos
) :-
    extraer_objetos_gp(
        g_preposicional(p(para), inf(inf(Inf), comps(Obj1, comps_coord_cont(conj(_), Obj2, none)))),
        Comun,
        Objetos
    ).

extraer_modificador_con_comun(
    g_preposicional(g_preposicional(p(P), g_nominal(N, mod(GPComun, none)))),
    ModTokens,
    ComunTokens,
    Obj1Tokens
) :-
    tokens_limpios(g_nominal(N, none), NTokens),
    ModTokens = [P|NTokens],
    extraer_comun_y_objeto(GPComun, ComunTokens, Obj1Tokens).

extraer_comun_y_objeto(GPComun, ComunSinObj, ObjTokens) :-
    tokens_limpios(GPComun, ComunConObj),
    sub_term(mod(n(n(Obj)), none), GPComun),
    tokens_limpios(n(n(Obj)), ObjTokens),
    append(ComunSinObj, ObjTokens, ComunConObj),
    !.

extraer_adj_con_comun(g_adjetival(Adj, GPComun), AdjTokens, ComunTokens) :-
    tokens_limpios(g_adjetival(g_adjetival(Adj)), AdjTokens),
    tokens_limpios(GPComun, ComunTokens).

objeto_con_mod_compartido(Obj1Tokens, Obj2Term, Obj1Completo, Obj2Tokens) :-
    tokens_limpios(Obj2Term, Obj2Tokens),
    extraer_modificador_objeto(Obj2Term, ModTokens),
    append(Obj1Tokens, ModTokens, Obj1Completo).

objeto_con_mod_compartido_tokens(Obj1Base, Obj2Term, Obj1Completo, Obj2Tokens) :-
    tokens_limpios(Obj2Term, Obj2Tokens),
    extraer_modificador_objeto(Obj2Term, ModTokens),
    append(Obj1Base, ModTokens, Obj1Completo).

extraer_modificador_objeto(g_nominal(g_nominal(_, mod(Mod, none))), ModTokens) :-
    tokens_limpios(Mod, ModTokens),
    !.

extraer_modificador_objeto(_, []).

combinar_distribucion(Verbo, Sujetos, Modificadores, Comun, Objetos, Oraciones) :-
    findall(
        Oracion,
        (
            member(S, Sujetos),
            member(M, Modificadores),
            member(O, Objetos),
            append([Verbo, S, M, Comun, O], Oracion)
        ),
        Oraciones
    ).

tokens_limpios(Term, Tokens) :-
    tokens_de_arbol(Term, Tokens0),
    excluir_tokens_no_textuales(Tokens0, Tokens1),
    expandir_locuciones(Tokens1, Tokens).

prefijar_sujeto(_, [], []).

prefijar_sujeto(TokensSujeto, [Tokens|Resto], [oracion_texto(Completa)|Salida]) :-
    append(TokensSujeto, Tokens, Completa),
    prefijar_sujeto(TokensSujeto, Resto, Salida).

% =========================================================
% DIVISIONES BINARIAS ESTRUCTURALES
% =========================================================

dividir_gv_por_complemento_coord(GV, GV1, GV2) :-
    dividir_complemento_coord_en_term(GV, GV1, GV2).

dividir_complemento_coord_en_term(g_verbal(A, B, Extra), g_verbal(A, B1), g_verbal(A, B2, Extra)) :-
    dividir_complemento_coord_en_term(B, B1, B2),
    !.

dividir_complemento_coord_en_term(
    comps(Comp1, comps_coord_cont(_Conj, Comp2, Resto)),
    comps(Comp1, none),
    comps(Comp1ConComp2, Resto)
) :-
    complemento_nominal_desnudo(Comp2),
    reemplazar_gp_mas_interno(Comp1, Comp2, Comp1ConComp2),
    !.

dividir_complemento_coord_en_term(
    comps(Comp1, comps_coord_cont(_Conj, Comp2, Resto)),
    comps(Comp1, none),
    comps(Base, comps(Comp2, Resto))
) :-
    \+ complemento_nominal_desnudo(Comp2),
    base_complemento_coord(Comp1, Base),
    !.

dividir_complemento_coord_en_term(
    g_nominal(g_nominal(GN1, conj(_), GN2)),
    g_nominal(GN1),
    g_nominal(GN2)
) :- !.

dividir_complemento_coord_en_term(
    gn_lista(GN1, GN2, Conj, GN3),
    GN1,
    g_nominal(g_nominal(GN2, Conj, GN3))
) :- !.

dividir_complemento_coord_en_term(
    g_nominal(D, N, mod(g_preposicional(g_preposicional(P, g_nominal(GN1, conj(_), GN2))), Resto)),
    g_nominal(D, N, mod(g_preposicional(g_preposicional(P, GN1)), Resto)),
    g_nominal(D, N, mod(g_preposicional(g_preposicional(P, GN2)), Resto))
) :-
    N = n(facilidad),
    !.

dividir_complemento_coord_en_term(
    g_nominal(D, N, mod(g_preposicional(g_preposicional(P, g_nominal(GN1, conj(_), GN2))), none)),
    g_nominal(D, N, mod(g_preposicional(g_preposicional(P, GN1)), none)),
    g_nominal(GN2)
) :- !.

dividir_complemento_coord_en_term(
    g_nominal(D, N, Adj, mod(g_preposicional(g_preposicional(P, g_nominal(GN1, conj(_), GN2))), none)),
    g_nominal(D, N, Adj, mod(g_preposicional(g_preposicional(P, GN1)), none)),
    g_nominal(GN2)
) :- !.

dividir_complemento_coord_en_term(rel(_, _), _, _) :- !, fail.
dividir_complemento_coord_en_term(rel_prep(_, _, _, _), _, _) :- !, fail.
dividir_complemento_coord_en_term(rel_lo_que(_), _, _) :- !, fail.

dividir_complemento_coord_en_term(Term, Term1, Term2) :-
    compound(Term),
    Term =.. [Functor|Args],
    dividir_complemento_coord_en_args(Args, Args1, Args2),
    Term1 =.. [Functor|Args1],
    Term2 =.. [Functor|Args2].

dividir_complemento_coord_en_args([Arg|Resto], [Arg1|Resto], [Arg2|Resto]) :-
    dividir_complemento_coord_en_term(Arg, Arg1, Arg2),
    !.

dividir_complemento_coord_en_args([Arg|Resto], [Arg|Resto1], [Arg|Resto2]) :-
    dividir_complemento_coord_en_args(Resto, Resto1, Resto2).

dividir_adjetivo_coord(Term, Term1, Term2) :-
    dividir_adjetivo_coord_en_term(Term, Term1, Term2).

dividir_adjetivo_coord_en_term(
    g_adjetival(gadj_coord(Adj1, conj(_), g_adjetival(Adj2))),
    g_adjetival(g_adjetival(Adj1)),
    g_adjetival(g_adjetival(Adj2))
) :- !.

dividir_adjetivo_coord_en_term(Term, Term1, Term2) :-
    compound(Term),
    Term =.. [Functor|Args],
    dividir_adjetivo_coord_en_args(Args, Args1, Args2),
    Term1 =.. [Functor|Args1],
    Term2 =.. [Functor|Args2].

dividir_adjetivo_coord_en_args([Arg|Resto], [Arg1|Resto], [Arg2|Resto]) :-
    dividir_adjetivo_coord_en_term(Arg, Arg1, Arg2),
    !.

dividir_adjetivo_coord_en_args([Arg|Resto], [Arg|Resto1], [Arg|Resto2]) :-
    dividir_adjetivo_coord_en_args(Resto, Resto1, Resto2).

% =========================================================
% RELATIVAS Y SUBORDINADAS
% =========================================================

extraer_relativa_de_gv(GV, GVSinRel, Antecedente, Rel) :-
    extraer_relativa_de_complemento_en_term(GV, GVSinRel, Antecedente, Rel).

extraer_relativa_de_complemento_en_term(g_nominal(GN), g_nominal(GNSinRel), g_nominal(GNSinRel), Rel) :-
    contiene_relativo_local(GN),
    quitar_primera_relativa(GN, GNSinRel, Rel),
    !.

extraer_relativa_de_complemento_en_term(Term, TermSinRel, Antecedente, Rel) :-
    compound(Term),
    Term =.. [Functor|Args],
    extraer_relativa_de_complemento_en_args(Args, ArgsSinRel, Antecedente, Rel),
    TermSinRel =.. [Functor|ArgsSinRel].

extraer_relativa_de_complemento_en_args([Arg|Resto], [ArgSinRel|Resto], Antecedente, Rel) :-
    extraer_relativa_de_complemento_en_term(Arg, ArgSinRel, Antecedente, Rel),
    !.

extraer_relativa_de_complemento_en_args([Arg|Resto], [Arg|RestoSinRel], Antecedente, Rel) :-
    extraer_relativa_de_complemento_en_args(Resto, RestoSinRel, Antecedente, Rel).

oracion_de_relativa(Antecedente, rel(_, GV), o(Antecedente, GV)) :- !.

oracion_de_relativa(Antecedente, rel(_, O), ORelativa) :-
    normalizar_oracion(O, oracion_norm(CIs, sujeto_eliptico, GV, Extras)),
    !,
    construir_oracion_norm(oracion_norm(CIs, Antecedente, GV, Extras), ORelativa).

contiene_relativo_local(Term) :-
    sub_term(Sub, Term),
    es_relativa_extraible(Sub),
    !.

es_relativa_extraible(rel(_, _)).

quitar_primera_relativa(Term, SinRel, Rel) :-
    quitar_relativa_mod(Term, SinRel, Rel),
    !.

quitar_primera_relativa(Term, SinRel, Rel) :-
    compound(Term),
    Term =.. [Functor|Args],
    quitar_primera_relativa_args(Args, ArgsSinRel, Rel),
    SinRel =.. [Functor|ArgsSinRel].

quitar_relativa_mod(mod(rel(Rel), Resto), Resto, Rel) :- !.

quitar_relativa_mod(mod(Otro, Resto), mod(Otro, RestoSinRel), Rel) :-
    quitar_primera_relativa(Resto, RestoSinRel, Rel).

quitar_primera_relativa_args([Arg|Resto], [ArgSinRel|Resto], Rel) :-
    quitar_primera_relativa(Arg, ArgSinRel, Rel),
    !.

quitar_primera_relativa_args([Arg|Resto], [Arg|RestoSinRel], Rel) :-
    quitar_primera_relativa_args(Resto, RestoSinRel, Rel).

extraer_subordinada_inicial([ci_sub(sub_ini(_Subord, OSub))|Resto], Resto, OSub) :- !.

extraer_subordinada_inicial([CI|Resto], [CI|RestoSinSub], OSub) :-
    extraer_subordinada_inicial(Resto, RestoSinSub, OSub).

% =========================================================
% COMPLEMENTOS INICIALES
% =========================================================

dividir_complemento_inicial_coord([CI|Resto], [CI1|Resto], [CI2|Resto]) :-
    dividir_ci_coord(CI, CI1, CI2),
    !.

dividir_complemento_inicial_coord([CI|Resto], [CI|Resto1], [CI|Resto2]) :-
    dividir_complemento_inicial_coord(Resto, Resto1, Resto2).

dividir_ci_coord(
    ci_g_preposicional(g_preposicional(P, GN, Conj, GP2)),
    ci_g_preposicional(g_preposicional(P, GN)),
    ci_g_preposicional(g_preposicional(P, GN2))
) :-
    Conj = conj(_),
    gp_a_gn(GP2, GN2),
    !.

gp_a_gn(g_preposicional(p(de), GN), GN) :- !.
gp_a_gn(g_preposicional(_, GN), GN).

% =========================================================
% AUXILIARES DE RECONSTRUCCION
% =========================================================

base_complemento_coord(g_nominal(GN), g_nominal(BaseGN)) :-
    base_gn_coord(GN, BaseGN).

base_gn_coord(g_nominal(N, mod(_, _)), g_nominal(N, none)) :- !.
base_gn_coord(g_nominal(D, N, mod(_, _)), g_nominal(D, N, none)) :- !.
base_gn_coord(g_nominal(D, Adj, N, mod(_, _)), g_nominal(D, Adj, N, none)) :- !.
base_gn_coord(g_nominal(D, N, Adj, mod(_, _)), g_nominal(D, N, Adj, none)) :- !.
base_gn_coord(GN, GN).

complemento_nominal_desnudo(g_nominal(g_nominal(_))).
complemento_nominal_desnudo(g_nominal(g_nominal(_, _, _))).
complemento_nominal_desnudo(g_nominal(g_nominal(_, _, _, _))).

reemplazar_gp_mas_interno(Term, NuevoGN, Salida) :-
    compound(Term),
    Term =.. [Functor|Args],
    reemplazar_gp_mas_interno_args(Args, ArgsSalida, NuevoGN),
    !,
    Salida =.. [Functor|ArgsSalida].

reemplazar_gp_mas_interno(
    g_preposicional(g_preposicional(P, _GN)),
    g_nominal(NuevoGN),
    g_preposicional(g_preposicional(P, NuevoGN))
) :- !.

reemplazar_gp_mas_interno_args([Arg|Resto], [ArgSalida|Resto], NuevoGN) :-
    reemplazar_gp_mas_interno(Arg, NuevoGN, ArgSalida),
    !.

reemplazar_gp_mas_interno_args([Arg|Resto], [Arg|RestoSalida], NuevoGN) :-
    reemplazar_gp_mas_interno_args(Resto, RestoSalida, NuevoGN).

% =========================================================
% CLASIFICADORES
% =========================================================

es_complemento_inicial(ci_adv(_)).
es_complemento_inicial(ci_g_preposicional(_)).
es_complemento_inicial(ci_marcador(_)).
es_complemento_inicial(ci_sub(_)).

es_extra_oracional(inciso(_)).
es_extra_oracional(apos(_)).
es_extra_oracional(apos_estado(_, _)).

% =========================================================
% REALIZACION TEXTUAL
% =========================================================

simplificaciones_a_texto(Simples, Textos) :-
    maplist(oracion_a_texto, Simples, Textos).

oracion_a_texto(Oracion, Texto) :-
    tokens_de_arbol(Oracion, Tokens0),
    excluir_tokens_no_textuales(Tokens0, Tokens1),
    expandir_locuciones(Tokens1, Tokens),
    atomic_list_concat(Tokens, ' ', Base0),
    capitalizar_inicio(Base0, Base),
    asegurar_punto_final(Base, Texto).

tokens_de_arbol(Term, []) :-
    var(Term),
    !.

tokens_de_arbol(oracion_texto(Tokens), Tokens) :- !.

tokens_de_arbol(comp_que(O), [que|Tokens]) :-
    tokens_de_arbol(O, Tokens),
    !.

tokens_de_arbol(porcentaje, ['%']) :- !.
tokens_de_arbol(a_pequenas_escalas_de, [a, pequenas, escalas, de]) :- !.
tokens_de_arbol(a_pequena_escala_de, [a, pequena, escala, de]) :- !.
tokens_de_arbol(mas_alla_de, [mas, alla, de]) :- !.
tokens_de_arbol(sin_embargo, [sin, embargo]) :- !.
tokens_de_arbol(aparte_de, [aparte, de]) :- !.
tokens_de_arbol(al_margen_de, [al, margen, de]) :- !.
tokens_de_arbol(por_el_contrario, [por, el, contrario]) :- !.
tokens_de_arbol(en_cuanto, [en, cuanto]) :- !.
tokens_de_arbol(en_menos_de, [en, menos, de]) :- !.
tokens_de_arbol(al_final_de, [al, final, de]) :- !.
tokens_de_arbol(gracias_a, [gracias, a]) :- !.
tokens_de_arbol(debido_a, [debido, a]) :- !.
tokens_de_arbol(dado_que, [dado, que]) :- !.
tokens_de_arbol(una_vez, [una, vez]) :- !.
tokens_de_arbol(a_diferencia_de, [a, diferencia, de]) :- !.
tokens_de_arbol(de_que, [de, que]) :- !.
tokens_de_arbol(despues_de, [despues, de]) :- !.
tokens_de_arbol(del_orden_de, [del, orden, de]) :- !.

tokens_de_arbol(mod_nominal_simple(n(X)), [X]) :- !.

tokens_de_arbol(Term, [Term]) :-
    atomic(Term),
    !.

tokens_de_arbol(Term, Tokens) :-
    Term =.. [_Functor|Args],
    tokens_de_lista(Args, Tokens).

tokens_de_lista([], []).

tokens_de_lista([Arg|Resto], Tokens) :-
    tokens_de_arbol(Arg, TokensArg),
    tokens_de_lista(Resto, TokensResto),
    append(TokensArg, TokensResto, Tokens).

excluir_tokens_no_textuales([], []).

excluir_tokens_no_textuales([Token|Resto], Salida) :-
    token_no_textual(Token),
    !,
    excluir_tokens_no_textuales(Resto, Salida).

excluir_tokens_no_textuales([Token|Resto], [Token|Salida]) :-
    excluir_tokens_no_textuales(Resto, Salida).

token_no_textual(none).
token_no_textual(',').
token_no_textual(pausa).
token_no_textual(sujeto_eliptico).
token_no_textual(sujeto_impersonal).

expandir_locuciones([], []).

expandir_locuciones([Token|Resto], Salida) :-
    locucion_textual(Token, Expansion),
    !,
    expandir_locuciones(Resto, SalidaResto),
    append(Expansion, SalidaResto, Salida).

expandir_locuciones([Token|Resto], [Token|Salida]) :-
    expandir_locuciones(Resto, Salida).

locucion_textual(debido_a, [debido, a]).
locucion_textual(gracias_a, [gracias, a]).
locucion_textual(mas_alla_de, [mas, alla, de]).
locucion_textual(sin_embargo, [sin, embargo]).
locucion_textual(aparte_de, [aparte, de]).
locucion_textual(al_margen_de, [al, margen, de]).
locucion_textual(a_pequenas_escalas_de, [a, pequenas, escalas, de]).
locucion_textual(a_pequena_escala_de, [a, pequena, escala, de]).

capitalizar_inicio(Atom, Texto) :-
    atom_string(Atom, String),
    string_chars(String, Chars),
    capitalizar_chars(Chars, Capitalizadas),
    string_chars(Texto, Capitalizadas).

capitalizar_chars([], []).

capitalizar_chars([C|Resto], [Mayus|Resto]) :-
    char_type(C, alpha),
    !,
    upcase_atom(C, Mayus).

capitalizar_chars([C|Resto], [C|Salida]) :-
    capitalizar_chars(Resto, Salida).

asegurar_punto_final(Texto, Texto) :-
    sub_string(Texto, _, 1, 0, Final),
    member(Final, [".", "?", "!"]),
    !.

asegurar_punto_final(Texto, ConPunto) :-
    string_concat(Texto, ".", ConPunto).
