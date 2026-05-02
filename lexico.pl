% lexico.pl
% Diccionario del analizador sintáctico.
% Cada palabra aparece en su propia línea para evitar errores de carga en SWI-Prolog.

% =========================================================
% UNIDADES Y MARCADORES CUANTITATIVOS
% =========================================================

unidad_word(mn).
unidad_word(micronewtons).
unidad_word(micronewtonios).
unidad_word(mg).
unidad_word(g).
unidad_word(kg).
unidad_word(kpa).
unidad_word(psi).
unidad_word(mm).
unidad_word(cm).
unidad_word(dias).
unidad_word(dia).
unidad_word(ciclos).
unidad_word(veces).
unidad_word(segundo).
unidad_word(segundos).
unidad_word(minutos).
unidad_word(porcentaje).



% =========================================================
% DETERMINANTES
% =========================================================
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
det_word(varias).
det_word(ciertos).

% =========================================================
% NOMBRES
% =========================================================
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
% Corpus cuántica
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

% =========================================================
% VERBOS LÉXICOS
% =========================================================
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
verbo_word(utilizan).
verbo_word(procesar).

% =========================================================
% VERBOS COPULATIVOS
% =========================================================
vc_word(es).
vc_word(esta).
vc_word(son).
vc_word(estan).
vc_word(fue).
vc_word(fueron).
vc_word(puede).

% =========================================================
% VERBOS IMPERSONALES
% =========================================================
vi_word(llueve).
vi_word(nieva).

% =========================================================
% AUXILIARES
% =========================================================
aux_word(fue).
aux_word(fueron).
aux_word(se).

% =========================================================
% AUXILIAR SER (pasiva perifrástica)
% =========================================================
aux_ser_word(ser).

% =========================================================
% PARTICIPIOS
% =========================================================
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
part_word(perfeccionados).
part_word(derivados).
part_word(inspirados).
part_word(generados).
part_word(accionado).
part_word(accionada).
part_word(utilizado).
part_word(utilizada).
part_word(mostradas).
part_word(refinados).
part_word(creados).
part_word(propuesto).
part_word(recubierta).
part_word(insertada).
part_word(pegada).

% =========================================================
% MODALES
% =========================================================
modal_word(puede).
modal_word(pueden).
modal_word(debe).
modal_word(deben).

% =========================================================
% INFINITIVOS
% =========================================================
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
% ADJETIVOS
% =========================================================
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
adj_word('no-cloning').

% =========================================================
% ADVERBIOS
% =========================================================
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

% =========================================================
% PREPOSICIONES
% =========================================================
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

% =========================================================
% CONJUNCIONES ORACIONALES
% =========================================================
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

% =========================================================
% CONJUNCIONES COORDINANTES
% =========================================================
conj_coord_word(y).
conj_coord_word(o).
conj_coord_word(ni).

% =========================================================
% RELATIVOS Y SUBORDINANTES
% =========================================================
rel_word(que).
subord_word(que).
subord_word(cuando).
subord_word(aunque).
subord_word(si).

% =========================================================
% PRONOMBRE SE
% =========================================================
se_word(se).
