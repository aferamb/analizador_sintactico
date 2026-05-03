# Correcciones propuestas y aplicadas tras la auditoria

Este documento usa `AUDITORIA_SINTACTICA.md` como punto de partida. No repite la auditoria: enumera que fallaba, donde estaba el problema probable en Prolog, que deberia reconocer el analizador y que cambio se aplico o queda como mejora posterior.

## Cambios aplicados

| Pares afectados | Estructura que fallaba | Zona implicada | Por que el arbol era malo | Que debe reconocer | Cambio aplicado |
| --- | --- | --- | --- | --- | --- |
| 3, 4, 14 | Negacion verbal `no`, `aun no`, `todavia no`. | `modificador_nominal(gadv/1)` y reglas `g_verbal_simple/1`. | `no` podia entrar como modificador nominal y dejaba de modificar al verbo. | La negacion debe formar parte del GV: `gv(gadv(adv(no)), V, ...)` o `gv(gadv(adv(aun),adv(no)), Aux, ...)`. | Se bloqueo `no/aun/todavia/tambien` como modificadores nominales. |
| 4 Claude | `Esta fascinacion... no carece de fundamento`. | `g_verbal_simple(gv(VC, GN))` y lexico. | `esta` se leia como copula eliptica y `carece` no estaba como verbo. | Sujeto `Esta fascinacion por las aranas` + GV `no carece de fundamento`. | Se impidio `vc(esta)+GN` y se anadio `verbo_word(carece)`. |
| 13 | Adjetivo antepuesto: `alta/elevada densidad`. | `g_nominal_simple/1`. | `alta/elevada` se tomaban como nucleo nominal y `densidad` como modificador. | `gn(det(esta), adj(alta), n(densidad), ...)`. | Se anadio `adjetivo_antepuesto/1` para adjetivos prenominales frecuentes y controlados. |
| 20 GPT | Locucion verbal `dan lugar a...`. | `g_verbal_simple/1`, `complementos_verbales/1`, lexico de `lugar`. | `lugar` se leia como infinitivo/nombre independiente y la coordinacion `a la apertura y al cierre` se rompia. | GV locucional `gv(v(dan), n(lugar), comps(...))`. | Se anadio regla `verbo_dar_lugar + lugar` y continuacion de complementos con `y + complemento`. |
| 20 Claude, 49 | Coordinacion continuativa de complementos: `X y Y` tras un complemento ya abierto. | `complementos_verbales/1`. | Despues de analizar el primer complemento, `y ...` no podia continuar como segundo complemento paralelo. | `comps_coord_cont(conj(y), Comp, Resto)`. | Se anadio `comps_coord_cont/3`, restringido a `y` para no reabrir el fallo de `o especies`. |
| 21 GPT | Objeto con inciso participial: `un peso personalizado, destinado..., sobre...`. | `g_verbal_simple/1`, `inciso_oracional/1`, participios nominales. | `personalizado, destinado...` se convertia en una cadena participial dentro del GN y se perdia `sobre la balanza...`. | `colocamos` + GN objeto + inciso participial + GP locativo/final. | Se anadio regla verbal guardada por coma-inciso y se bloqueo `personalizado` como cabeza de participio nominal. |
| 34 | Complemento final `para crear...` tras objeto directo. | `g_nominal/1`, `g_preposicional/1`, `g_verbal_simple/1`. | El GN `el cadaver de una arana` se tragaba el `para crear...` como modificador nominal, y el arbol acababa en `de fabricacion`. | Verbo `reutilizamos` + objeto `el cadaver...` + GP final `para crear...` con relativa y `lo que...`. | Se anadio `g_nominal_antes_de_para/3` y una regla `verbo + GN + GP(para...) + complementos`, evitando que el GN absorba el final. |
| 35, 36, 40 | Formas ambiguas nombre/participio/verbo. | `participio_frase_nominal/1`, `modificador_nominal/1`. | Formas finitas o adjetivas podian actuar como modificadores nominales y robar el verbo principal. | El nucleo verbal debe mantenerse como verbo; participios nominales solo cuando sean plausibles. | Se introdujo `participio_nominal_valido/1` con bloqueos selectivos (`aprovecha`, `experimento`, `presento`, `personalizado`). |
| 41 | Sujeto infinitivo y coordinacion nominal con `o`. | `oracion_simple/1`, `conjuncion_oracional/1`. | `tamanos o especies` se analizaba como coordinacion de oraciones. | Sujeto infinitivo `Estudiar ... tamanos o especies` + GV `podria conducir...`. | Se anadio `oracion_simple(o(Inf,GV))` para sujetos infinitivos y se excluyo `o/u` de la coordinacion oracional. |
| 44 Claude | Perifrasis/modal `suelen entranar`. | Lexico y `modificador_nominal/1`. | `suelen` se consumia como modificador nominal y no como modal. | GV `gv(mod(suelen), inf(entranar), ...)`. | Se anadio `modal_word(suelen)` y se impidio que modales funcionen como modificador nominal desnudo. |
| 49 | Gerundio instrumental `utilizando un montaje/sistema...`. | `complementos_verbales/1`, `gerundio_frase/1`, `modificador_nominal/1`. | El gerundio podia adjuntarse mal o perderse en complementos nominales. | Complemento verbal instrumental con el montaje/sistema y coordinacion interna `maquina... y balanza...`. | Se quito el gerundio como modificador nominal y se reforzo la continuacion coordinada de complementos. |

## Mejoras que quedan recomendadas

| Pares | Fallo pendiente | Zona probable | Cambio recomendado |
| --- | --- | --- | --- |
| 1 | `de hasta el 130 % de su propia masa` aun podria integrarse mejor como un solo GP cuantitativo. | `cantidad/1`, `g_preposicional/1`. | Crear una regla de GP cuantitativo: `de hasta + cantidad + de + GN`. |
| 6 | `un paso mas alla al incorporar...` se reconoce, pero no como locucion adverbial/comparativa. | `g_adverbial/1` o `g_verbal_simple/1`. | Anadir locucion verbal/adverbial `ir un paso mas alla al + infinitivo`. |
| 10, 31, 46 | Coordinaciones nominales complejas se aceptan, pero el alcance semantico de los modificadores no siempre es exacto. | `g_nominal/1`, `modificadores_nominales/1`. | Introducir listas de GN/GP como listas reales en vez de arbol binario de complementos para repartir modificadores por constituyente. |
| 12, 17, 38, 40 | Muchas completivas y consecutivas con `que/lo que` se representan todavia con nodos `rel`. | `relativo_base/1`, `subordinada_completiva/1`, `complemento_verbal/1`. | Separar definitivamente `relativo` de `completiva`: usar `subc(comp_que(...))` tras verbos de decir/mostrar/observar y reservar `rel(...)` para modificadores nominales. |
| 19, 45, 47 | Gerundios instrumentales/eventivos aceptados, pero a veces no queda claro si modifican al verbo principal o a un GN. | `gerundio_frase/1`, `complemento_verbal/1`. | Crear nodos especificos `ger_eventivo/1` y priorizarlos como complemento verbal tras el predicado antes que dentro de GN. |
| 23, 26, 39 | Complementos `de...` pueden quedar demasiado sueltos. | `g_nominal/1`, `g_preposicional/1`. | Reglas especificas para nucleos nominales que seleccionan complemento: `capacidad para`, `mecanismo de`, `perdida de`, `diseno de`. |
| 30 | `debido a...` tras coma se trata como participio incidental. | `complemento_verbal_poscoma/1`. | Preferir `gp(p(debido_a), GN)` antes que `partf(part(debido), ...)`. |
| 42, 43 | Coordinaciones de infinitivos finales se aceptan, pero no siempre quedan bajo el mismo nucleo. | `infinitivo_frase/1`, `complementos_verbales/1`. | Regla `infinitivo_coord/1` para `para mejorar... y aprovechar...`. |
| 48 | `estan disponibles en el material suplementario/complementario...` se parte en GAdj + GN adicional. | `g_verbal_simple/1`, `g_adjetival/1`. | Priorizar `vc + gadj(disponibles, GP)` y evitar que `suplementario/complementario` salga como GN independiente. |

## Pruebas ejecutadas

- Barrido completo de todos los pares con `call_with_time_limit(8, once(analizar_texto(...)))`.
- Resultado esperado tras los cambios: solo `PAR 11 GPT=no CLAUDE=ok`.
- Prueba de `draw/1` sobre todos los arboles aceptados con salida silenciada: sin errores.
- Reinspeccion de arboles de los pares 3, 4, 13, 20, 21, 34, 41, 44 y 49.
