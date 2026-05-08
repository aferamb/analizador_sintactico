% lexico_semantico.pl
% Inventario lexico-semantico del corpus GPT/Claude.
%
% Este archivo no sustituye a lexico.pl. Lo reutiliza como inventario de
% formas reconocidas y anade una clasificacion mas rica segun las clases de
% palabras del espanol. Las formas son las normalizadas por tokenizar_basico/2.

:- encoding(utf8).

:- ensure_loaded('lexico.pl').

% =========================================================
% API PUBLICA
% =========================================================

lexico_semantico(Palabra, sustantivo, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_lexica(Palabra, nombre_word),
    rasgos_sustantivo(Palabra, Rasgos).

lexico_semantico(Palabra, adjetivo, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_lexica(Palabra, adj_word),
    rasgos_adjetivo(Palabra, Rasgos).

lexico_semantico(Palabra, determinante, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_lexica(Palabra, det_word),
    rasgos_determinante(Palabra, Rasgos).

lexico_semantico(Palabra, pronombre, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_pronominal(Palabra),
    rasgos_pronombre(Palabra, Rasgos).

lexico_semantico(Palabra, verbo, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_verbal(Palabra),
    rasgos_verbo(Palabra, Rasgos).

lexico_semantico(Palabra, adverbio, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_lexica(Palabra, adv_word),
    rasgos_adverbio(Palabra, Rasgos).

lexico_semantico(Palabra, preposicion, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_lexica(Palabra, prep_word),
    rasgos_preposicion(Palabra, Rasgos).

lexico_semantico(Palabra, conjuncion, Rasgos) :-
    palabra_lexico_semantica(Palabra),
    categoria_conjuntiva(Palabra),
    rasgos_conjuncion(Palabra, Rasgos).

clase_lexico_semantica(Palabra, Clase) :-
    lexico_semantico(Palabra, Clase, _).

rasgos_lexico_semanticos(Palabra, Clase, Rasgos) :-
    lexico_semantico(Palabra, Clase, Rasgos).

palabra_lexico_semantica(Palabra) :-
    palabra_corpus(Palabra).

% =========================================================
% VOCABULARIO NORMALIZADO DEL CORPUS
% =========================================================

palabra_corpus(Palabra) :-
    memberchk(Palabra, [
        a, abdomen, abre, accionada, accionado, accionan, acopla, acrilica,
        acrilico, activamente, actua, actuacion, actuador, actuadores, actuan,
        actuando, actue, ademas, adentro, adhesiva, adhesivo, adicional,
        adicionales, afuera, agarrado, agarrar, agarre, agua, aguja,
        'aguja-araña', al, alcanza, alimentar, alla, alta, ambito, ambos,
        ampliarse, analitica, anclaje, angulo, animal, animales, antagonicos,
        antagonistas, apariencia, aparte, apertura, aplica, aplicacion,
        aplicaciones, aplicada, aplicando, aportar, aprovecha, aprovechar,
        aproximadamente, araña, arañas, area, articulacion, articulaciones,
        articular, articulo, artificiales, artificialmente, asi, aumentar, aun,
        ausencia, autonoma, baja, balanza, barrido, basada, basado,
        biocompatibles, biodegrada, biohibridos, bioinspirado, biologicos,
        biomaterial, biomimetico, biomimeticos, biotico, bioticos, blandas,
        bruto, cable, cables, cada, cadaver, campo, camufla, camuflarse, capa,
        capaces, capacidad, capaz, caracterizamos, carece, celulas, centenas,
        centrandones, centrandonos, cientos, cierre, cinta, circuito, colocamos,
        combinan, como, compactos, complementario, completamente, completando,
        completo, complicados, componentes, comprension, compuesto, con,
        concepto, conciencia, concreta, conducir, conecta, conformidad,
        congelacion, considerables, construimos, contienen, contrario,
        contraste, contrayendo, corresponde, correspondiente, creados, creamos,
        crear, criaturas, cuando, cuanto, cuerpo, curado, curvan, curven, dada,
        dado, dan, dando, datos, de, debido, decenas, deja, del, demostramos,
        denomina, denominamos, densidad, dentro, derivados, desde,
        deshidratacion, desplazo, despresurizacion, despues, destinado,
        deteccion, dias, diez, diferencia, diferentes, directamente, disenar,
        diseñar, diseño, diseños, disminucion, disponibles, dispositivo,
        dispositivos, domesticas, dos, duracion, durante, duros, e, efectiva,
        efectivamente, efector, eficazmente, ejemplo, el, electronica, elegimos,
        elevada, eludir, embargo, emplean, emplearse, en, energia, enfrentan,
        ensayo, ensayos, entorno, entornos, entrañar, entre, es, escala,
        escalas, especies, esta, establecido, estado, estan, este, esternon,
        estudiar, estudio, etapa, etapas, eutanasiada, eutanasiando, eutanasio,
        evitar, evolucion, exoesqueleto, exoesqueletos, experimento,
        exploracion, explorada, explorado, explosivos, explotan, exposicion,
        extender, extenderlas, extenderse, extendiendose, exteriores, externa,
        extiende, extremo, fabricacion, facilidad, fallecidas, falta,
        fascinacion, fases, fijaron, fina, final, flexibilidad, flexibles,
        flexionadas, flexores, forma, fractura, fragiles, fraguado, frio, fue,
        fuera, fuerza, fuerzas, funcional, fundamento, futuro, futuros, genera,
        generar, geometrias, geometrica, gota, gracias, gran, guepardos, ha,
        habitualmente, hace, hacia, hallazgos, han, hasta, hemolinfa,
        hidraulica, hidraulicos, hidrostatica, hipodermica, hipotesis, hizo,
        imagenes, imitan, impermeable, implementacion, implican, imposibles,
        inanimada, inanimados, inaugurando, incluir, incluso, incorporacion,
        incorporar, incorporarse, individual, ingenieria, inicio, injustificada,
        innata, insercion, insertada, inspiracion, inspirado, inteligencia,
        interfaz, interna, interruptor, intrincados, introduce, investigacion,
        irregulares, jeringa, jeringuilla, la, lado, las, led, levantar,
        limitaciones, listo, listos, lo, lobo, lock, locomocion, longevidad,
        longitud, los, luer, lugar, manera, manipulacion, mano, manual,
        maquina, margen, mas, masa, masas, material, materiales, maximo, mayor,
        mecanica, mecanismo, mecanismos, mediante, medir, medusas, mejorar,
        membrana, menos, menudo, mera, metodos, micronewtonios, micronewtons,
        microscopia, minimizacion, minutos, mitigar, modular, montaje,
        mostramos, motivos, movimiento, movimientos, muchas, mudados, muere,
        muerta, muertas, muerte, muestran, muestras, musculares, musculos,
        natural, naturales, naturaleza, navegacion, necrobotica, necrobotico,
        neumaticamente, neutro, ninguna, niveles, no, nos, nuestra, nuestro,
        nuestros, numerosas, o, objetos, observa, observamos, obstante,
        obtencion, obtener, obtuvo, operativa, operativo, oponerse, orden,
        otras, papel, para, pares, particular, paso, pasos, pata, patas,
        patelofemoral, patrones, peciolo, pedicelo, pegada, pegamento, pequeña,
        pequeñas, pequeño, perdida, perfeccionados, periodo, permanecen,
        permite, personalizado, peso, pinza, planteamos, plenamente, podemos,
        podran, podria, podriamos, podrian, por, poseen, posible, potencia,
        precisa, presento, presion, presuriza, presurizacion, previos,
        procedimiento, proceso, procesos, producen, producir, prolongar, propia,
        propio, proponemos, proporcionar, propuesto, prosoma, provoca, provoco,
        puedan, puede, pueden, puente, punto, que, quebradizas, rango, razones,
        realizar, realizarse, recogieron, recubierta, recubrimiento, recubrir,
        reducido, refinada, refuerzo, relacion, relacionadas, replicar,
        reproducir, requiere, requieren, respaldan, respectivamente,
        restrictivas, restrictivos, resulta, resultados, reutiliza,
        reutilizamos, rigido, rigidos, roboticas, roboticos, robots, sacrifica,
        sacrificando, sacrifico, se, seda, segundo, sencilla, sencillo, ser,
        servir, señalamos, sido, siguiendo, similares, simultanea, simultaneos,
        sin, sirve, sistema, sistemas, sitio, situacional, sobre, sola, solo,
        su, suelen, suplementario, susceptibles, tal, tamaño, tamaños, tambien,
        tediosas, tediosos, tejidos, temperatura, textura, tiempo, tienen,
        todas, todavia, todo, trabajo, trabajos, tras, traves, tres, trozo, un,
        una, unica, unicamente, unico, unicos, universal, usar, usarse, uso,
        util, utilizado, utilizando, utilizarse, van, vapor, variables,
        variados, variando, variedad, veces, ventral, vez, vida, vivos,
        volumenes, volvieran, y
    ]).

forma_erronea(centrandones, centrandonos).

% =========================================================
% PUENTE CON EL LEXICO SINTACTICO ACTUAL
% =========================================================

categoria_lexica(P, unidad_word) :- unidad_word(P).
categoria_lexica(P, det_word) :- det_word(P).
categoria_lexica(P, nombre_word) :- nombre_word(P).
categoria_lexica(P, verbo_word) :- verbo_word(P).
categoria_lexica(P, vc_word) :- vc_word(P).
categoria_lexica(P, vi_word) :- vi_word(P).
categoria_lexica(P, aux_word) :- aux_word(P).
categoria_lexica(P, aux_ser_word) :- aux_ser_word(P).
categoria_lexica(P, part_word) :- part_word(P).
categoria_lexica(P, modal_word) :- modal_word(P).
categoria_lexica(P, inf_word) :- inf_word(P).
categoria_lexica(P, adj_word) :- adj_word(P).
categoria_lexica(P, adv_word) :- adv_word(P).
categoria_lexica(P, prep_word) :- prep_word(P).
categoria_lexica(P, conj_word) :- conj_word(P).
categoria_lexica(P, conj_coord_word) :- conj_coord_word(P).
categoria_lexica(P, rel_word) :- rel_word(P).
categoria_lexica(P, ger_word) :- ger_word(P).
categoria_lexica(P, subord_word) :- subord_word(P).
categoria_lexica(P, se_word) :- se_word(P).
categoria_lexica(P, pron_personal_word) :- pron_personal_word(P).

categoria_lexica(centrandones, ger_word).
categoria_lexica(veces, nombre_word).
categoria_lexica(utilizarse, inf_word).

categoria_pronominal(P) :-
    ( categoria_lexica(P, pron_personal_word)
    ; categoria_lexica(P, se_word)
    ; categoria_lexica(P, rel_word)
    ),
    !.

categoria_verbal(P) :-
    P \= se,
    ( verbo_finito(P)
    ; categoria_lexica(P, vc_word)
    ; categoria_lexica(P, vi_word)
    ; (categoria_lexica(P, aux_word), P \= se)
    ; categoria_lexica(P, aux_ser_word)
    ; categoria_lexica(P, modal_word)
    ; categoria_lexica(P, inf_word)
    ; categoria_lexica(P, ger_word)
    ; participio_morfologico(P)
    ),
    !.

categoria_conjuntiva(P) :-
    ( categoria_lexica(P, conj_word)
    ; categoria_lexica(P, conj_coord_word)
    ; categoria_lexica(P, subord_word)
    ),
    !.

% =========================================================
% RASGOS DE SUSTANTIVOS
% =========================================================

rasgos_sustantivo(P, [
    referente(Referente),
    significado(Significado),
    contabilidad(Contabilidad),
    genero(Genero)
]) :-
    referente_sustantivo(P, Referente),
    significado_sustantivo(P, Significado),
    contabilidad_sustantivo(P, Contabilidad),
    genero_sustantivo(P, Genero).

referente_sustantivo(P, propio) :-
    memberchk(P, [luer, lock, led]),
    !.
referente_sustantivo(_, comun).

significado_sustantivo(P, abstracto) :-
    memberchk(P, [
        actuacion, aplicacion, aplicaciones, apertura, ausencia, capacidad,
        comprension, concepto, conciencia, conformidad, congelacion, cierre,
        densidad, deshidratacion, despresurizacion, deteccion, diferencia,
        disminucion, duracion, energia, evolucion, exploracion, exposicion,
        fabricacion, facilidad, fascinacion, flexibilidad, fuerza, fuerzas,
        hipotesis, implementacion, incorporacion, ingenieria, inteligencia,
        insercion, inspiracion, investigacion, locomocion, longevidad, longitud,
        manipulacion, masa, masas, mecanica, metodos, minimizacion, montaje,
        muerte, navegacion, obtencion, orden, potencia, presion, presurizacion,
        proceso, procesos, relacion, resultados, tiempo, uso, vida
    ]),
    !.
significado_sustantivo(P, colectivo) :-
    memberchk(P, [sistema, sistemas, conjunto, datos]),
    !.
significado_sustantivo(_, concreto).

contabilidad_sustantivo(P, no_contable) :-
    memberchk(P, [
        agua, aire, hemolinfa, pegamento, seda, vapor, frio, masa, presion,
        energia, temperatura, inteligencia, material, biomaterial
    ]),
    !.
contabilidad_sustantivo(_, contable).

genero_sustantivo(P, femenino) :-
    femenino_lexico(P),
    !.
genero_sustantivo(P, masculino) :-
    masculino_lexico(P),
    !.
genero_sustantivo(_, comun).

femenino_lexico(P) :-
    atom_concat(_, cion, P), !.
femenino_lexico(P) :-
    atom_concat(_, dad, P), !.
femenino_lexico(P) :-
    atom_concat(_, tud, P), !.
femenino_lexico(P) :-
    memberchk(P, [
        accionada, acrilica, adhesiva, agua, aguja, alta, analitica, araña,
        arañas, area, articulacion, articulaciones, apariencia, apertura,
        aplicada, autonoma, baja, balanza, basada, capa, celulas, cinta,
        conciencia, concreta, criaturas, dada, densidad, diferencia, efectiva,
        electronica, energia, escala, especies, etapa, etapas, evolucion,
        externa, facilidad, falta, fases, fina, flexibilidad, forma, fractura,
        fuerza, fuerzas, geometrica, gota, hidraulica, hidrostatica,
        hipodermica, hipotesis, imagenes, inanimada, ingenieria, innata,
        inteligencia, interfaz, interna, jeringa, jeringuilla, la, las, manera,
        mano, maquina, masa, masas, mecanica, medusas, membrana, muestras,
        naturaleza, necrobotica, ninguna, numerosas, otras, pata, patas, pegada,
        pequeña, pequeñas, perdida, pinza, potencia, precisa, presion, propia,
        quebradizas, razones, recubierta, refinada, relacion, restrictivas,
        roboticas, seda, sencilla, simultanea, sola, temperatura, textura,
        todas, una, unica, variedad, variables, vida
    ]).

masculino_lexico(P) :-
    atom_concat(_, o, P),
    \+ femenino_lexico(P),
    !.
masculino_lexico(P) :-
    atom_concat(_, aje, P), !.
masculino_lexico(P) :-
    memberchk(P, [
        abdomen, adhesivo, agarre, al, anclaje, ambito, angulo, animal,
        articulo, actuador, actuadores, biomaterial, cable, cables, cadaver,
        campo, circuito, componentes, contraste, cuerpo, datos, dias, diseño,
        diseños, dispositivo, dispositivos, duros, efector, ejemplo, el,
        ensayo, ensayos, entorno, entornos, estado, esternon, estudio,
        exoesqueleto, exoesqueletos, flexores, fundamento, futuro, guepardos,
        hallazgos, interruptor, lado, led, lobo, lock, luer, lugar, margen,
        materiales, mecanismo, mecanismos, metodos, micronewtonios,
        micronewtons, minutos, motivos, movimiento, movimientos, musculos,
        neutro, niveles, objetos, operativo, papel, pares, paso, pasos,
        patrones, peciolo, pedicelo, periodo, peso, procedimiento, proceso,
        procesos, prosoma, puente, punto, rango, refuerzo, resultados, rigido,
        rigidos, robots, segundo, sistema, sistemas, sitio, tamaño, tamaños,
        trabajo, trabajos, traves, tres, trozo, unico, unicos, vapor,
        volumenes
    ]).

% =========================================================
% RASGOS DE ADJETIVOS
% =========================================================

rasgos_adjetivo(P, [
    tipo_propiedad(Tipo),
    posicion(contextual),
    grado(Grado)
]) :-
    tipo_propiedad_adjetivo(P, Tipo),
    grado_adjetivo(P, Grado).

tipo_propiedad_adjetivo(P, relacional) :-
    memberchk(P, [
        acrilica, acrilico, analitica, animal, artificiales, autonoma,
        biocompatibles, biohibridos, bioinspirado, biologicos, biomimetico,
        biomimeticos, biotico, bioticos, domesticas, electronica, geometrica,
        hidraulica, hidraulicos, hidrostatica, hipodermica, manual, materiales,
        mecanica, muscular, musculares, natural, naturales, necrobotica,
        necrobotico, neumatica, roboticas, roboticos, situacional, universal,
        ventral
    ]),
    !.
tipo_propiedad_adjetivo(P, adverbial) :-
    memberchk(P, [actual, anterior, futura, futuro, futuros, mera, solo]),
    !.
tipo_propiedad_adjetivo(_, calificativo).

grado_adjetivo(P, comparativo) :-
    memberchk(P, [mayor, menor, mejor]),
    !.
grado_adjetivo(P, superlativo_absoluto) :-
    memberchk(P, [maximo, maxima, minimo, minima, optimo, unica, unico, unicos]),
    !.
grado_adjetivo(_, positivo).

% =========================================================
% RASGOS DE DETERMINANTES Y PRONOMBRES
% =========================================================

rasgos_determinante(P, Rasgos) :-
    determinante_especifico(P, Rasgos),
    !.
rasgos_determinante(_, [tipo(indefinido), genero(contextual), numero(contextual)]).

determinante_especifico(el, [tipo(articulo(determinado)), genero(masculino), numero(singular)]).
determinante_especifico(la, [tipo(articulo(determinado)), genero(femenino), numero(singular)]).
determinante_especifico(los, [tipo(articulo(determinado)), genero(masculino), numero(plural)]).
determinante_especifico(las, [tipo(articulo(determinado)), genero(femenino), numero(plural)]).
determinante_especifico(un, [tipo(articulo(indeterminado)), genero(masculino), numero(singular)]).
determinante_especifico(una, [tipo(articulo(indeterminado)), genero(femenino), numero(singular)]).
determinante_especifico(este, [tipo(demostrativo(proximidad)), genero(masculino), numero(singular)]).
determinante_especifico(esta, [tipo(demostrativo(proximidad)), genero(femenino), numero(singular)]).
determinante_especifico(su, [tipo(posesivo(atono_antepuesto)), persona(tercera), numero_poseedor(contextual)]).
determinante_especifico(nuestra, [tipo(posesivo(atono_antepuesto)), persona(primera), genero(femenino), numero(singular)]).
determinante_especifico(nuestro, [tipo(posesivo(atono_antepuesto)), persona(primera), genero(masculino), numero(singular)]).
determinante_especifico(nuestros, [tipo(posesivo(atono_antepuesto)), persona(primera), genero(masculino), numero(plural)]).
determinante_especifico(dos, [tipo(numeral(cardinal)), valor(2)]).
determinante_especifico(tres, [tipo(numeral(cardinal)), valor(3)]).
determinante_especifico(diez, [tipo(numeral(cardinal)), valor(10)]).
determinante_especifico(cientos, [tipo(numeral(cardinal)), valor(indeterminado_plural)]).
determinante_especifico(ambos, [tipo(indefinido), genero(masculino), numero(plural)]).
determinante_especifico(cada, [tipo(indefinido), numero(singular)]).
determinante_especifico(muchas, [tipo(indefinido), genero(femenino), numero(plural)]).
determinante_especifico(otras, [tipo(indefinido), genero(femenino), numero(plural)]).
determinante_especifico(todas, [tipo(indefinido), genero(femenino), numero(plural)]).
determinante_especifico(todo, [tipo(indefinido), genero(masculino), numero(singular)]).

rasgos_pronombre(P, [tipo(Tipo), persona(Persona), tonicidad(Tonicidad)]) :-
    pronombre_personal(P, Tipo, Persona, Tonicidad),
    !.
rasgos_pronombre(P, [tipo(relativo), funcion(contextual)]) :-
    categoria_lexica(P, rel_word),
    !.
rasgos_pronombre(_, [tipo(indefinido), funcion(contextual)]).

pronombre_personal(me, personal(objeto_atono_clitico), primera, atono).
pronombre_personal(te, personal(objeto_atono_clitico), segunda, atono).
pronombre_personal(se, personal(reflexivo), tercera, atono).
pronombre_personal(nos, personal(objeto_atono_clitico), primera, atono).
pronombre_personal(os, personal(objeto_atono_clitico), segunda, atono).
pronombre_personal(lo, personal(objeto_atono_clitico), tercera, atono).
pronombre_personal(la, personal(objeto_atono_clitico), tercera, atono).
pronombre_personal(los, personal(objeto_atono_clitico), tercera, atono).
pronombre_personal(las, personal(objeto_atono_clitico), tercera, atono).

% =========================================================
% RASGOS DE VERBOS
% =========================================================

rasgos_verbo(P, Rasgos) :-
    findall(F, forma_verbal(P, F), Formas0),
    ordenar_unicos(Formas0, Formas),
    funcion_verbal(P, Funcion),
    transitividad_verbal(P, Transitividad),
    voz_verbal(P, Voz),
    tipo_especial_verbal(P, Especial),
    regularidad_verbal(P, Regularidad),
    Rasgos = [
        formas(Formas),
        funcion_predicativa(Funcion),
        transitividad(Transitividad),
        voz(Voz),
        tipo_especial(Especial),
        regularidad(Regularidad)
    ].

forma_verbal(P, infinitivo) :- categoria_lexica(P, inf_word).
forma_verbal(P, gerundio) :- categoria_lexica(P, ger_word).
forma_verbal(P, participio) :- participio_morfologico(P).
forma_verbal(ser, infinitivo).
forma_verbal(P, conjugada) :- verbo_finito(P).

participio_morfologico(P) :-
    P = estado,
    !.
participio_morfologico(P) :-
    ( atom_concat(_, ado, P)
    ; atom_concat(_, ada, P)
    ; atom_concat(_, ados, P)
    ; atom_concat(_, adas, P)
    ; atom_concat(_, ido, P)
    ; atom_concat(_, ida, P)
    ; atom_concat(_, idos, P)
    ; atom_concat(_, idas, P)
    ; memberchk(P, [compuesto, muerta, muertas, visto, sido])
    ),
    categoria_lexica(P, part_word).

verbo_finito(P) :-
    memberchk(P, [
        abre, accionan, acopla, actua, actuan, actue, alcanza, aplica,
        aprovecha, biodegrada, camufla, caracterizamos, carece, colocamos,
        combinan, conecta, construimos, contienen, corresponde, creamos,
        curvan, curven, dan, deja, demostramos, denomina, denominamos,
        desplazo, elegimos, emplean, enfrentan, es, esta, estan, eutanasio,
        extiende, explotan, fijaron, forma, fue, genera, ha, hace, han, hizo,
        imitan, implican, introduce, mostramos, muere, muestran, observa, observamos,
        obtuvo, permanecen, permite, planteamos, podemos, podran, podria, podriamos,
        podrian, poseen, presento, presuriza, producen, proponemos, provoca,
        provoco, puedan, puede, pueden, recogieron, respaldan, resulta,
        requiere, requieren, reutiliza, reutilizamos, sacrifica, sacrifico, señalamos, sirve,
        suelen, tienen, van, volvieran
    ]).

funcion_verbal(P, copulativo) :-
    categoria_lexica(P, vc_word),
    !.
funcion_verbal(P, semicopulativo) :-
    memberchk(P, [permanecen, resulta, volvieran]),
    !.
funcion_verbal(_, predicativo).

transitividad_verbal(P, intransitivo) :-
    memberchk(P, [muere, permanecen, carece, enfrentan, actua, actuan, van]),
    !.
transitividad_verbal(P, ditransitivo) :-
    memberchk(P, [da, dan, dar]),
    !.
transitividad_verbal(P, transitivo) :-
    memberchk(P, [
        agarrar, alimentar, aplicar, aportar, aprovechar, caracterizar,
        caracterizamos, combinan, construir, construimos, contienen, crear,
        creamos, deja, demostramos, denomina, denominamos, disenar, diseñar,
        emplean, estudiar, evitar, extender, extiende, generar, genera, imitan,
        incorporar, levantar, medir, modular, mostramos, observar, observamos,
        obtener, permite, planteamos, poseen, presuriza, producir, proponemos,
        proporcionar, provoca, provoco, realizar, recogieron, reutiliza,
        reutilizamos, sacrifica, sacrifico, usar, utilizarse
    ]),
    !.
transitividad_verbal(_, contextual).

voz_verbal(P, pasivo_reflejo) :-
    atom_concat(_, se, P),
    !.
voz_verbal(_, contextual).

tipo_especial_verbal(P, auxiliar) :-
    ( categoria_lexica(P, aux_word)
    ; categoria_lexica(P, aux_ser_word)
    ),
    !.
tipo_especial_verbal(P, modal) :-
    categoria_lexica(P, modal_word),
    !.
tipo_especial_verbal(P, pronominal) :-
    atom_concat(_, se, P),
    !.
tipo_especial_verbal(_, ninguno).

regularidad_verbal(P, irregular) :-
    memberchk(P, [
        es, esta, estan, fue, ha, han, ser, sido, hace, hizo, tienen, puede,
        pueden, podemos, podran, podria, podriamos, podrian, puedan, da, dan,
        dando, van, volvieran
    ]),
    !.
regularidad_verbal(_, regular).

% =========================================================
% RASGOS DE ADVERBIOS
% =========================================================

rasgos_adverbio(P, [
    significado(Significado),
    funcion_discursiva(Funcion),
    forma(Forma)
]) :-
    significado_adverbio(P, Significado),
    funcion_adverbio(P, Funcion),
    forma_adverbio(P, Forma).

significado_adverbio(P, lugar) :-
    memberchk(P, [adentro, afuera, alla, dentro, fuera, hacia]),
    !.
significado_adverbio(P, tiempo) :-
    memberchk(P, [aun, despues, habitualmente, todavia, ya]),
    !.
significado_adverbio(P, cantidad_grado) :-
    memberchk(P, [aproximadamente, casi, gran, mas, maximo, menos, muy]),
    !.
significado_adverbio(P, negacion) :-
    memberchk(P, [no]),
    !.
significado_adverbio(P, afirmacion) :-
    memberchk(P, [si]),
    !.
significado_adverbio(P, orden) :-
    memberchk(P, [primero, segundo, dos, tres, diez]),
    !.
significado_adverbio(_, modo).

funcion_adverbio(P, conector_discursivo) :-
    memberchk(P, [ademas, embargo, obstante, contrario, contraste, asi]),
    !.
funcion_adverbio(P, focal) :-
    memberchk(P, [incluso, solo, unicamente, solamente]),
    !.
funcion_adverbio(P, aspectual) :-
    memberchk(P, [aun, todavia, ya, habitualmente]),
    !.
funcion_adverbio(_, modificador).

forma_adverbio(P, derivado_mente) :-
    atom_concat(_, mente, P),
    !.
forma_adverbio(_, simple).

% =========================================================
% RASGOS DE PREPOSICIONES Y CONJUNCIONES
% =========================================================

rasgos_preposicion(al, [tipo(contraccion), base([a, el])]) :- !.
rasgos_preposicion(del, [tipo(contraccion), base([de, el])]) :- !.
rasgos_preposicion(P, [tipo(propia(P))]) :-
    memberchk(P, [
        a, ante, bajo, cabe, con, contra, de, desde, durante, en, entre, hacia,
        hasta, mediante, para, por, segun, sin, sobre, tras, versus, via
    ]),
    !.
rasgos_preposicion(_, [tipo(impropia_o_contextual)]).

rasgos_conjuncion(P, [tipo(coordinante(copulativa))]) :-
    memberchk(P, [y, e, ni]),
    !.
rasgos_conjuncion(P, [tipo(coordinante(disyuntiva))]) :-
    memberchk(P, [o, u]),
    !.
rasgos_conjuncion(P, [tipo(coordinante(adversativa))]) :-
    memberchk(P, [pero, sino]),
    !.
rasgos_conjuncion(que, [tipo(subordinante(completiva))]) :- !.
rasgos_conjuncion(cuando, [tipo(subordinante(temporal))]) :- !.
rasgos_conjuncion(como, [tipo(subordinante(modal)), tipo(subordinante(comparativa))]) :- !.
rasgos_conjuncion(si, [tipo(subordinante(condicional))]) :- !.
rasgos_conjuncion(P, [tipo(subordinante(contextual))]) :-
    categoria_lexica(P, subord_word),
    !.
rasgos_conjuncion(_, [tipo(contextual)]).

% =========================================================
% LOCUCIONES RELEVANTES EN EL CORPUS
% =========================================================

locucion_lexico_semantica([sin, embargo], adverbio,
    [funcion_discursiva(conector_discursivo), forma(locucion_adverbial)]).
locucion_lexico_semantica([no, obstante], adverbio,
    [funcion_discursiva(conector_discursivo), forma(locucion_adverbial)]).
locucion_lexico_semantica([por, el, contrario], adverbio,
    [funcion_discursiva(conector_discursivo), forma(locucion_adverbial)]).
locucion_lexico_semantica([en, contraste, con], preposicion,
    [tipo(locucion_preposicional)]).
locucion_lexico_semantica([dado, que], conjuncion,
    [tipo(locucion_conjuntiva), subtipo(subordinante(causal))]).
locucion_lexico_semantica([tal, y, como], conjuncion,
    [tipo(locucion_conjuntiva), subtipo(subordinante(comparativa))]).

% =========================================================
% UTILIDADES
% =========================================================

ordenar_unicos(Entrada, Salida) :-
    sort(Entrada, Salida).
