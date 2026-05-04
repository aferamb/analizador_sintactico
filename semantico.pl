% semantico.pl
% Módulo de enriquecimiento semántico (Apartado 2.2).
%
% Dominio del corpus: Necrobótica (uso de arañas muertas como actuadores robóticos).
% Fuente: "Necrobotics: Biotic Materials as Ready-to-Use Actuators" (Yuk et al., Science Advances, 2022).
%
% Predicados exportados:
%   tipo/2 — categoría semántica de un sustantivo o entidad
%   tipo_verbo/2 — tipo de acción que expresa un verbo
%   compatible/2 — par (tipo_sujeto, tipo_verbo) semánticamente coherente
%   categoria/2 — consulta cómoda (incluye ambigüedad)
%   es_ambiguo/1 — true si la palabra tiene más de un tipo semántico
%   tipos_de/2 — lista de todos los tipos de una palabra
%   compatibles_sujeto_verbo/2 — true si sujeto y verbo son semánticamente compatibles
%   categoria_semantica/1 — imprime las categorías de una palabra

:- encoding(utf8).

% =========================================================
% CATEGORÍAS SEMÁNTICAS DE SUSTANTIVOS
%
% tipo(+Palabra, +Categoria)
%
% Categorías empleadas en este dominio (necrobótica):
%   ser_vivo — organismo animal vivo o muerto 
%   organismo_biologico — célula, tejido o componente micro de un ser vivo
%   entidad_robotica — robot, actuador o sistema artificial
%   componente_biologico — parte del cuerpo de un organismo (pata, músculo, articulación)
%   componente_mecanico — pieza de un sistema artificial (aguja, cable, circuito)
%   material_biotico — material extraído de un ser vivo (seda, hemolinfa, tejido)
%   material_sintetico — material artificial (pegamento, polímero, silicio)
%   sustancia — líquido, adhesivo o fluido (hemolinfa, agua, pegamento)
%   instrumento — herramienta experimental (balanza, jeringuilla, microscopio)
%   objeto_fisico — objeto tangible sin función biológica o robótica específica
%   proceso_nominal — sustantivo deverbativo que designa un proceso (muerte, fabricación)
%   concepto_abstracto — idea sin materialidad (fuerza, densidad, capacidad)
%   lugar — espacio físico o geográfico
%   persona — ser humano (investigador, ingeniero...)


% --- Seres vivos y organismos completos ---
tipo(araña, ser_vivo).
tipo(araña, objeto_fisico).      % "araña de luces" (lámpara) 
tipo(arañas, ser_vivo).
tipo(arañas, objeto_fisico).
tipo(cadaver, ser_vivo).           % cuerpo muerto tratado aún como origen biológico
tipo(cadaver, objeto_fisico).      % como objeto inerte 
tipo(abeja, ser_vivo).
tipo(rata, ser_vivo).
tipo(guepardos, ser_vivo).
tipo(medusas, ser_vivo).
tipo(insecto, ser_vivo).
tipo(insectos, ser_vivo).
tipo(cucarachas, ser_vivo).
tipo(escarabajos, ser_vivo).

% --- Microorganismos y células ---
tipo(bacterias, ser_vivo).
tipo(bacterias, organismo_biologico).
tipo(cardiomiocitos, organismo_biologico).
tipo(celula, organismo_biologico).
tipo(celulas, organismo_biologico).

% --- Personas y roles profesionales ---
tipo(investigador, persona).
tipo(investigadores, persona).
tipo(ingenieros, persona).
tipo(autores, persona).

% --- Componentes biológicos (partes de organismos) ---
tipo(pata, componente_biologico).
tipo(pata, objeto_fisico).         % pata de mueble 
tipo(patas, componente_biologico).
tipo(patas, objeto_fisico).
tipo(musculo, componente_biologico).
tipo(musculos, componente_biologico).
tipo(articulacion, componente_biologico).
tipo(articulacion, componente_mecanico).   % unión mecánica flexible 
tipo(articulaciones, componente_biologico).
tipo(articulaciones, componente_mecanico).
tipo(exoesqueleto, componente_biologico).
tipo(exoesqueleto, componente_mecanico).   % actúa como estructura rígida 
tipo(exoesqueletos, componente_biologico).
tipo(exoesqueletos, componente_mecanico).
tipo(prosoma, componente_biologico).
tipo(abdomen, componente_biologico).
tipo(membrana, componente_biologico).
tipo(cuerpo, componente_biologico).
tipo(cuerpo, objeto_fisico).         % cuerpo como masa inerte 
tipo(cuerpos, componente_biologico).
tipo(cuerpos, objeto_fisico).

% --- Materiales bióticos ---
tipo(seda, material_biotico).
tipo(biomaterial, material_biotico).
tipo(biomateriales, material_biotico).
tipo(tejido, material_biotico).
tipo(tejido, organismo_biologico).    % tejido vivo 
tipo(tejidos, material_biotico).
tipo(tejidos, organismo_biologico).
tipo(hemolinfa, material_biotico).
tipo(hemolinfa, sustancia).

% --- Materiales sintéticos y sustancias ---
tipo(pegamento, material_sintetico).
tipo(pegamento, sustancia).
tipo(cianoacrilato, material_sintetico).
tipo(cianoacrilato, sustancia).
tipo(goma, material_sintetico).
tipo(silicio, material_sintetico).
tipo(poliuretano, material_sintetico).
tipo(cera, material_sintetico).
tipo(recubrimiento, material_sintetico).
tipo(capa, material_sintetico).
tipo(capa, componente_mecanico).   % capa como elemento estructural 
tipo(agua, sustancia).
tipo(aceite, sustancia).
tipo(vapor, sustancia).
tipo(plasma, sustancia).

% --- Entidades robóticas y tecnológicas ---
tipo(robot, entidad_robotica).
tipo(robots, entidad_robotica).
tipo(actuador, entidad_robotica).
tipo(actuadores, entidad_robotica).
tipo(efector, entidad_robotica).
tipo(efectores, entidad_robotica).
tipo(pinza, entidad_robotica).
tipo(pinza, instrumento).             % pinza manual de laboratorio 
tipo(pinzas, entidad_robotica).
tipo(sistema, entidad_robotica).
tipo(sistema, concepto_abstracto).      % sistema como concepto 
tipo(sistemas, entidad_robotica).
tipo(sistemas, concepto_abstracto).
tipo(sensor, entidad_robotica).
tipo(sensor, componente_mecanico).
tipo(sensores, entidad_robotica).
tipo(dispositivo, entidad_robotica).
tipo(dispositivo, componente_mecanico).
tipo(dispositivos, entidad_robotica).
tipo(circuito, componente_mecanico).
tipo(led, componente_mecanico).

% --- Componentes mecánicos e instrumentos ---
tipo(aguja, instrumento).
tipo(aguja, componente_mecanico).    % aguja de coser
tipo(agujas, instrumento).
tipo(agujas, componente_mecanico).
tipo(jeringuilla, instrumento).
tipo(jeringa, instrumento).
tipo(cable, componente_mecanico).
tipo(cables, componente_mecanico).
tipo(muelle, componente_mecanico).
tipo(muelles, componente_mecanico).
tipo(balanza, instrumento).
tipo(balanza, objeto_fisico).
tipo(maquina, instrumento).
tipo(maquina, objeto_fisico).
tipo(microscopio, instrumento).
tipo(manometro, instrumento).

% --- Procesos en forma nominal ---
tipo(muerte, proceso_nominal).
tipo(deshidratacion, proceso_nominal).
tipo(locomocion, proceso_nominal).
tipo(fabricacion, proceso_nominal).
tipo(actuacion, proceso_nominal).
tipo(actuaciones, proceso_nominal).
tipo(presurizacion, proceso_nominal).
tipo(despresurizacion, proceso_nominal).
tipo(apertura, proceso_nominal).
tipo(cierre, proceso_nominal).
tipo(eutanasia, proceso_nominal).
tipo(diseno, proceso_nominal).
tipo(analisis, proceso_nominal).
tipo(analisis, concepto_abstracto). % análisis como resultado 

% --- Conceptos abstractos ---
tipo(fuerza, concepto_abstracto).
tipo(fuerzas, concepto_abstracto).
tipo(presion, concepto_abstracto).
tipo(presiones, concepto_abstracto).
tipo(densidad, concepto_abstracto).
tipo(potencia, concepto_abstracto).
tipo(resistencia, concepto_abstracto).
tipo(flexibilidad, concepto_abstracto).
tipo(duracion, concepto_abstracto).
tipo(longevidad, concepto_abstracto).
tipo(capacidad, concepto_abstracto).
tipo(capacidad, entidad_robotica).       % "capacidad de la pinza" 
tipo(datos, concepto_abstracto).
tipo(resultado, concepto_abstracto).
tipo(resultados, concepto_abstracto).
tipo(hipotesis, concepto_abstracto).
tipo(concepto, concepto_abstracto).
tipo(energia, concepto_abstracto).
tipo(masa, concepto_abstracto).
tipo(angulo, concepto_abstracto).
tipo(vida, concepto_abstracto).
tipo(vida, proceso_nominal).        % vida como proceso biológico

% --- Lugares ---
tipo(laboratorio, lugar).
tipo(entorno, lugar).
tipo(entornos, lugar).


% =========================================================
% CATEGORÍAS SEMÁNTICAS DE VERBOS
%
% tipo_verbo(+FormaVerbal, +TipoAccion)
%
% Se incluyen infinitivos y formas conjugadas que aparecen en el corpus.
%
% Tipos de acción:
%   accion_fisica — requiere agente con capacidad motriz (agarrar, extender, levantar)
%   proceso_biologico  — proceso inherente a organismos vivos (morir, biodegradarse)
%   accion_tecnica — propia de sistemas o técnicos (medir, presurizar, insertar)
%   proceso_mecanico — proceso de un mecanismo (abrir, cerrar, actuar, producir)
%   accion_cognitiva — requiere capacidad mental (estudiar, plantear, diseñar)
%   accion_comunicativa — transmitir o mostrar información (demostrar, mostrar, indicar)

% --- Acciones físicas ---
tipo_verbo(agarra, accion_fisica).
tipo_verbo(agarran, accion_fisica).
tipo_verbo(agarrar, accion_fisica).
tipo_verbo(extiende, accion_fisica).
tipo_verbo(extienden, accion_fisica).
tipo_verbo(extender, accion_fisica).
tipo_verbo(levanta, accion_fisica).
tipo_verbo(levantan, accion_fisica).
tipo_verbo(levantar, accion_fisica).
tipo_verbo(contrae, accion_fisica).
tipo_verbo(contraen, accion_fisica).
tipo_verbo(contraer, accion_fisica).
tipo_verbo(curvan, accion_fisica).
tipo_verbo(curvarse, accion_fisica).
tipo_verbo(come, accion_fisica).   % relevante para detectar uso no literal
tipo_verbo(bebe, accion_fisica).
tipo_verbo(camufla, accion_fisica).   % camuflarse es acción propia de seres vivos
tipo_verbo(camuflarse, accion_fisica).   % en robots es uso no literal

% --- Procesos biológicos (inherentes a organismos vivos) ---
tipo_verbo(muere, proceso_biologico).
tipo_verbo(morir, proceso_biologico).
tipo_verbo(biodegrada, proceso_biologico).
tipo_verbo(biodegradarse, proceso_biologico).
tipo_verbo(deshidrata, proceso_biologico).
tipo_verbo(sacrifica, proceso_biologico).
tipo_verbo(sacrificar, proceso_biologico).
tipo_verbo(eutanasiar, proceso_biologico).

% --- Acciones técnicas (propias de sistemas o investigadores) ---
tipo_verbo(mide, accion_tecnica).
tipo_verbo(medimos, accion_tecnica).
tipo_verbo(medir, accion_tecnica).
tipo_verbo(presuriza, accion_tecnica).
tipo_verbo(presurizar, accion_tecnica).
tipo_verbo(caracteriza, accion_tecnica).
tipo_verbo(caracterizamos, accion_tecnica).
tipo_verbo(caracterizar, accion_tecnica).
tipo_verbo(detecta, accion_tecnica).
tipo_verbo(detectar, accion_tecnica).
tipo_verbo(genera, accion_tecnica).
tipo_verbo(generar, accion_tecnica).
tipo_verbo(controla, accion_tecnica).
tipo_verbo(controlar, accion_tecnica).
tipo_verbo(inserta, accion_tecnica).
tipo_verbo(insertar, accion_tecnica).
tipo_verbo(insertan, accion_tecnica).
tipo_verbo(utiliza, accion_tecnica).
tipo_verbo(utilizar, accion_tecnica).
tipo_verbo(reutiliza, accion_tecnica).
tipo_verbo(reutilizamos, accion_tecnica).
tipo_verbo(reutilizar, accion_tecnica).
tipo_verbo(construimos, accion_tecnica).
tipo_verbo(construir, accion_tecnica).
tipo_verbo(aplica, accion_tecnica).
tipo_verbo(aplicar, accion_tecnica).
tipo_verbo(recoge, accion_tecnica).
tipo_verbo(recogemos, accion_tecnica).

% --- Procesos mecánicos (propios de mecanismos o actuadores) ---
tipo_verbo(actua, proceso_mecanico).
tipo_verbo(actuan, proceso_mecanico).
tipo_verbo(actuar, proceso_mecanico).
tipo_verbo(abre, proceso_mecanico).
tipo_verbo(abrir, proceso_mecanico).
tipo_verbo(cierra, proceso_mecanico).
tipo_verbo(cerrar, proceso_mecanico).
tipo_verbo(produce, proceso_mecanico).
tipo_verbo(producen, proceso_mecanico).
tipo_verbo(producir, proceso_mecanico).
tipo_verbo(aumenta, proceso_mecanico).
tipo_verbo(aumentar, proceso_mecanico).
tipo_verbo(reduce, proceso_mecanico).
tipo_verbo(reducir, proceso_mecanico).
tipo_verbo(desplaza, proceso_mecanico).
tipo_verbo(desplazar, proceso_mecanico).
tipo_verbo(funciona, proceso_mecanico).
tipo_verbo(funcionar, proceso_mecanico).

% --- Acciones cognitivas (requieren capacidad mental) ---
tipo_verbo(estudia, accion_cognitiva).
tipo_verbo(estudiamos, accion_cognitiva).
tipo_verbo(estudiar, accion_cognitiva).
tipo_verbo(analiza, accion_cognitiva).
tipo_verbo(analizar, accion_cognitiva).
tipo_verbo(plantea, accion_cognitiva).
tipo_verbo(planteamos, accion_cognitiva).
tipo_verbo(plantear, accion_cognitiva).
tipo_verbo(disenar, accion_cognitiva).
tipo_verbo(disenamos, accion_cognitiva).
tipo_verbo(proponer, accion_cognitiva).
tipo_verbo(proponemos, accion_cognitiva).
tipo_verbo(evalua, accion_cognitiva).
tipo_verbo(evaluar, accion_cognitiva).
tipo_verbo(depende, accion_cognitiva).
tipo_verbo(inspira, accion_cognitiva).   % inspirar en sentido intelectual
tipo_verbo(inspiran, accion_cognitiva).
tipo_verbo(inspirar, accion_cognitiva).

% --- Acciones comunicativas (transmitir o mostrar información) ---
tipo_verbo(demuestra, accion_comunicativa).
tipo_verbo(demostramos, accion_comunicativa).
tipo_verbo(demostrar, accion_comunicativa).
tipo_verbo(muestra, accion_comunicativa).
tipo_verbo(mostramos, accion_comunicativa).
tipo_verbo(mostrar, accion_comunicativa).
tipo_verbo(presenta, accion_comunicativa).
tipo_verbo(presentar, accion_comunicativa).
tipo_verbo(senalamos, accion_comunicativa).
tipo_verbo(indica, accion_comunicativa).
tipo_verbo(indican, accion_comunicativa).
tipo_verbo(indicar, accion_comunicativa).
tipo_verbo(observamos, accion_comunicativa).
tipo_verbo(observar, accion_comunicativa).


% =========================================================
% COMPATIBILIDAD SEMÁNTICA SUJETO–VERBO
%
% compatible(+TipoSujeto, +TipoVerbo)
%
% Define qué tipos de sujeto pueden realizar qué tipos de acción
% de forma LITERAL (sin metáfora ni incoherencia).
%
% Si un par (sujeto, verbo) no tiene tipos compatibles según estas
% reglas, la combinación puede ser problemática (incoherente o metafórica).
% =========================================================

% Personas: pueden hacer de todo de forma literal
compatible(persona, accion_fisica).
compatible(persona, proceso_biologico).
compatible(persona, accion_tecnica).
compatible(persona, proceso_mecanico).
compatible(persona, accion_cognitiva).
compatible(persona, accion_comunicativa).

% Seres vivos: acciones físicas y procesos biológicos
compatible(ser_vivo, accion_fisica).       % la araña extiende sus patas
compatible(ser_vivo, proceso_biologico).   % la araña muere, se deshidrata

% Componentes biológicos (patas, músculos, articulaciones...)
compatible(componente_biologico, accion_fisica).     % la pata se extiende, el músculo se contrae
compatible(componente_biologico, proceso_biologico). % la articulación se deteriora

% Entidades robóticas (robots, actuadores, efectores...)
compatible(entidad_robotica, proceso_mecanico).    % el actuador se abre, el robot se desplaza
compatible(entidad_robotica, accion_tecnica).      % el sistema detecta, mide, controla

% Instrumentos (balanza, máquina de ensayo...)
compatible(instrumento, accion_tecnica).           % la balanza mide, la máquina ensaya
compatible(instrumento, proceso_mecanico).

% Componentes mecánicos (circuito, aguja, cable...)
compatible(componente_mecanico, proceso_mecanico). % el circuito funciona, la aguja inserta

% Los materiales, sustancias, conceptos abstractos y procesos nominales
% NO se definen como sujetos compatibles con ninguna acción, de modo que
% cualquier oración que los use como sujeto activo resulta semánticamente
% problemática (incoherente o no literal).


% =========================================================
% PREDICADOS DE CONSULTA

% categoria(+Palabra, -Categoria)
% Devuelve todas las categorías semánticas de una palabra (incluyendo ambigüedad).
% Ejemplo:
%   ?- categoria(araña, C).
%   C = ser_vivo ;
%   C = objeto_fisico.
categoria(Palabra, Categoria) :-
    tipo(Palabra, Categoria).

% es_ambiguo(+Palabra)
% True si la palabra tiene más de una categoría semántica.
% Ejemplo:
%   ?- es_ambiguo(araña).    % true  (ser_vivo / objeto_fisico)
%   ?- es_ambiguo(musculo).  % false
es_ambiguo(Palabra) :-
    tipo(Palabra, C1),
    tipo(Palabra, C2),
    C1 \= C2.

% tipos_de(+Palabra, -Lista)
% Recoge todos los tipos de una palabra en una lista.
% Ejemplo:
%   ?- tipos_de(pata, L).
%   L = [componente_biologico, objeto_fisico].
tipos_de(Palabra, Lista) :-
    findall(C, tipo(Palabra, C), Lista).

% compatibles_sujeto_verbo(+Sujeto, +Verbo)
% True si existe al menos un par de tipos semánticos compatible.
% Ejemplo:
%   ?- compatibles_sujeto_verbo(araña, extiende).    % true
%   ?- compatibles_sujeto_verbo(pegamento, estudia). % false
compatibles_sujeto_verbo(Sujeto, Verbo) :-
    tipo(Sujeto, TS),
    tipo_verbo(Verbo, TV),
    compatible(TS, TV),
    !.

% categoria_semantica(+Palabra)
% Imprime las categorías de una palabra de forma legible.
% Ejemplo:
%   ?- categoria_semantica(articulacion).
%   Categorias de 'articulacion': [componente_biologico, componente_mecanico]
categoria_semantica(Palabra) :-
    tipos_de(Palabra, Lista),
    (   Lista = []
    ->  format("'~w' no tiene categoria semantica registrada.~n", [Palabra])
    ;   format("Categorias de '~w': ~w~n", [Palabra, Lista])
    ).
