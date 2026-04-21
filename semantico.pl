% semantico.pl
% Módulo de enriquecimiento semántico (Apartado 2.2).
%
% Asocia palabras del corpus a categorías semánticas y define
% reglas de compatibilidad entre sujeto y predicado para
% apoyar la detección de incoherencias y usos no literales.
%
% Predicados exportados:
%   tipo/2 — categoría semántica de una palabra
%   tipo_verbo/2 — tipo de acción que expresa un verbo
%   compatible/2 — par (tipo_sujeto, tipo_verbo) semánticamente coherente
%   categoria/2 — consulta cómoda (incluye ambigüedad)
%   es_ambiguo/1 — true si la palabra tiene más de un tipo
%   tipos_de/2 — lista de todos los tipos de una palabra


% =========================================================
% CATEGORÍAS SEMÁNTICAS DE SUSTANTIVOS
%
% tipo(+Palabra, +Categoria)
%
% Categorías usadas:
%   persona            
%   rol_profesional — persona con un rol definido
%   entidad_tecnologica — sistemas, software, hardware, redes
%   fenomeno_economico  — fenómenos del mercado y finanzas
%   institucion — organizaciones o entidades colectivas
%   objeto_fisico — cosa tangible / mueble
%   lugar — espacio físico o geográfico
%   concepto_abstracto  — idea, resultado, proceso sin materialidad
%   entidad_biologica — organismo, célula, partícula con base física
%   accion_nominal — sustantivo deverbativo, es decir, derivado directamente de un verbo 
%                    mediante sufijos (diagnóstico, análisis)
% =========================================================

% Personas y roles
tipo(juan, persona).
tipo(maria, persona).
tipo(hombre, persona).
tipo(mujer, persona).
tipo(estudiante, persona).
tipo(estudiante, rol_profesional).
tipo(profesor, persona).
tipo(profesor, rol_profesional).
tipo(usuario, persona).
tipo(cliente, persona).
tipo(enfermero, persona).
tipo(enfermero, rol_profesional).
tipo(paciente, persona).

% Entidades tecnológicas
tipo(sistema, entidad_tecnologica).
tipo(modelo, entidad_tecnologica).
tipo(algoritmo, entidad_tecnologica).
tipo(software, entidad_tecnologica).
tipo(hardware, entidad_tecnologica).
tipo(red, entidad_tecnologica).
tipo(sensor, entidad_tecnologica).
tipo(sensor, objeto_fisico).
tipo(robot, entidad_tecnologica).
tipo(robot, objeto_fisico).
tipo(servidor, entidad_tecnologica).
tipo(dispositivo, entidad_tecnologica).
tipo(dispositivo, objeto_fisico).
tipo(plataforma, entidad_tecnologica).

% Fenómenos y entidades económicas
tipo(inflacion, fenomeno_economico).
tipo(precio, fenomeno_economico).
tipo(inversion, fenomeno_economico).
tipo(mercado, fenomeno_economico).
tipo(mercado, institucion).     % banco / mercado como lugar de intercambio
tipo(banco, institucion).
tipo(banco, objeto_fisico).  % banco como mueble -> ambigüedad léxica
tipo(empresa, institucion).

% Entidades científicas y clínicas
tipo(particula, entidad_biologica).
tipo(electron, entidad_biologica).
tipo(foton, entidad_biologica).
tipo(muestra, objeto_fisico).
tipo(laboratorio, lugar).
tipo(hospital, lugar).
tipo(hospital, institucion).
tipo(tratamiento, accion_nominal).
tipo(diagnostico, accion_nominal).
tipo(ensayo, accion_nominal).

% Conceptos abstractos y resultados
tipo(proceso, concepto_abstracto).
tipo(resultado, concepto_abstracto).
tipo(problema, concepto_abstracto).
tipo(analisis, accion_nominal).
tipo(analisis, concepto_abstracto).
tipo(prueba, accion_nominal).
tipo(dato, concepto_abstracto).
tipo(datos, concepto_abstracto).
tipo(clase, concepto_abstracto).
tipo(clase, lugar).
tipo(filosofia, concepto_abstracto).
tipo(derecho, concepto_abstracto).

% Lugares
tipo(madrid, lugar).

% Partes del cuerpo / objetos físicos
tipo(pelo, objeto_fisico).


% =========================================================
% CATEGORÍAS SEMÁNTICAS DE VERBOS
%
% tipo_verbo(+Verbo, +TipoAccion)
%
% Tipos de acción:
%   accion_fisica — requiere agente físico con capacidad motriz
%   accion_cognitiva — requiere agente con capacidad mental
%   accion_tecnica — propia de sistemas o técnicos
%   proceso_economico — transformación de valor o intercambio
%   proceso_natural — ocurre sin agente (impersonal o natural)
%   accion_comunicativa — transmitir información
% =========================================================

tipo_verbo(analiza, accion_cognitiva).
tipo_verbo(analiza, accion_tecnica).
tipo_verbo(evalua, accion_cognitiva).
tipo_verbo(evalua, accion_tecnica).
tipo_verbo(estudia, accion_cognitiva).
tipo_verbo(lee, accion_cognitiva).
tipo_verbo(presenta, accion_comunicativa).
tipo_verbo(depende, accion_cognitiva).

tipo_verbo(procesa, accion_tecnica).
tipo_verbo(detecta, accion_tecnica).
tipo_verbo(genera, accion_tecnica).
tipo_verbo(mejora, accion_tecnica).
tipo_verbo(controla, accion_tecnica).
tipo_verbo(utiliza, accion_tecnica).
tipo_verbo(mide, accion_tecnica).

tipo_verbo(compra, proceso_economico).
tipo_verbo(vende, proceso_economico).
tipo_verbo(aumenta, proceso_economico).
tipo_verbo(reduce, proceso_economico).

tipo_verbo(come, accion_fisica).
tipo_verbo(bebe, accion_fisica).
tipo_verbo(tiene, accion_fisica).
tipo_verbo(tiene, accion_cognitiva).

tipo_verbo(llueve, proceso_natural).
tipo_verbo(nieva, proceso_natural).


% =========================================================
% COMPATIBILIDAD SEMÁNTICA SUJETO–VERBO
%
% compatible(+TipoSujeto, +TipoVerbo)
%
% Define qué tipos de sujeto pueden ejecutar qué tipos de acción
% de forma literal (sin metáfora ni incoherencia).
%
% Esta tabla es el núcleo del análisis de coherencia:
% si un par (sujeto, verbo) no tiene tipo_sujeto y tipo_verbo
% compatibles según estas reglas, puede ser problemático.
% =========================================================

compatible(persona, accion_fisica).
compatible(persona, accion_cognitiva).
compatible(persona, accion_tecnica).
compatible(persona, proceso_economico).
compatible(persona, accion_comunicativa).

compatible(rol_profesional, accion_cognitiva).
compatible(rol_profesional, accion_tecnica).
compatible(rol_profesional, accion_comunicativa).

compatible(entidad_tecnologica, accion_tecnica).
compatible(entidad_tecnologica, proceso_economico).  % el algoritmo reduce costes

compatible(institucion, proceso_economico).
compatible(institucion, accion_comunicativa).

compatible(fenomeno_economico, proceso_economico).  % la inflación aumenta

% Los procesos naturales no tienen sujeto agentivo
% (son impersonales en la gramática, pero lo marco igualmente)
compatible(proceso_natural, proceso_natural).


% =========================================================
% PREDICADOS DE CONSULTA
% =========================================================

% categoria(+Palabra, -Categoria)
% Devuelve todas las categorías de una palabra (incluye ambigüedad).
% Ejemplo:
%   ?- categoria(banco, C).
%   C = institucion ;
%   C = objeto_fisico.
categoria(Palabra, Categoria) :-
    tipo(Palabra, Categoria).

% es_ambiguo(+Palabra)
% True si la palabra tiene más de una categoría semántica.
% Ejemplo: ?- es_ambiguo(banco).   % true
es_ambiguo(Palabra) :-
    tipo(Palabra, C1),
    tipo(Palabra, C2),
    C1 \= C2.

% tipos_de(+Palabra, -Lista)
% Recoge todos los tipos de una palabra en una lista.
% Ejemplo: ?- tipos_de(banco, L).   % L = [institucion, objeto_fisico]
tipos_de(Palabra, Lista) :-
    findall(C, tipo(Palabra, C), Lista).

% compatibles_sujeto_verbo(+Sujeto, +Verbo)
% True si existe al menos un par de tipos compatible entre sujeto y verbo.
% Ejemplo:
%   ?- compatibles_sujeto_verbo(juan, analiza).    % true
%   ?- compatibles_sujeto_verbo(inflacion, come).  % false
compatibles_sujeto_verbo(Sujeto, Verbo) :-
    tipo(Sujeto, TS),
    tipo_verbo(Verbo, TV),
    compatible(TS, TV),
    !.

% categoria_semantica(+Palabra)
% Imprime las categorías de una palabra de forma legible.
categoria_semantica(Palabra) :-
    tipos_de(Palabra, Lista),
    (   Lista = []
    ->  format("'~w' no tiene categoria semantica registrada.~n", [Palabra])
    ;   format("Categorias de '~w': ~w~n", [Palabra, Lista])
    ).
