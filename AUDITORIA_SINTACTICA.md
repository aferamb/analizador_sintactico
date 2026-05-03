# Auditoria sintactica de los corpus GPT/Claude

Verificacion ejecutada con `swipl -q -s main.pl`. Para cada frase aceptada se probo tambien `draw(Arbol)` con la salida silenciada: no hubo errores ni timeouts de `draw.pl`. Cuando la frase no se analiza, no hay arbol que dibujar. En frases largas, `draw.pl` funciona pero el diagrama ASCII es muy ancho y poco legible.

Leyenda: C = correcto; P = parcialmente correcto; I = incorrecto; R = rechazo correcto.

## Revision frase por frase

| Par | GPT | Claude | Evaluacion manual |
| --- | --- | --- | --- |
| 1 | Acepta `o`; sujeto `la pinza`, copula `es`, GAdj `capaz de agarrar...`. | Igual con `el efector...`. | P/P. La estructura principal es correcta, pero `su propia masa` aparece como GN final de `es`, no claramente dentro de `de hasta el 130 % de su propia masa`. |
| 2 | Acepta `oc`: `puede servir...` + `se camufla...`. | Equivalente. | C/C. Coordinacion y sujeto eliptico de la segunda coordinada razonables. |
| 3 | Acepta `o`. | Equivalente. | P/P. El nucleo sujeto y predicado son correctos, pero la negacion `no` queda como modificador nominal/adverbial dentro del GN de `aranas`; manualmente debe modificar al verbo `tienen/poseen`. |
| 4 | GPT acepta `o`. | Claude acepta `o`. | GPT P: pierde la negacion de `no es injustificada`. Claude I: analiza `Esta` como verbo copulativo y no reconoce bien `carece de fundamento`; manualmente `Esta fascinacion...` es sujeto. |
| 5 | Acepta `ocm`. | Acepta `ocm`. | GPT P, Claude C/P. La lectura general sujeto + `han inspirado` + objeto es buena. En GPT la relativa final queda menos visible/menos bien integrada que en Claude. |
| 6 | Acepta `o`. | Acepta `o`. | P/P. Reconoce sujeto y verbo `van`, pero `un paso mas alla al incorporar...` se analiza como GN con modificadores, no como locucion/adverbial comparativo-complemental. |
| 7 | Acepta `ocm`. | Acepta `ocm`. | GPT C/P: analiza bien complemento inicial, sujeto, pasiva refleja, relativa, gerundio y relativa preposicional. Claude P: la estructura principal es correcta, pero parte de `que requiere unicamente un sencillo paso...` se separa como complemento nominal/verbal y no queda tan bien ligada a `actuador listo para usar`. |
| 8 | Acepta `o`. | Equivalente. | C/C. Modal + infinitivo y complemento final `para incorporar...` razonables. |
| 9 | Acepta `o`. | Equivalente. | C/C. Pasiva refleja `se denomina` con atributo/denominacion coordinada correcta. |
| 10 | Acepta `ocm`. | Acepta `ocm`. | P/P. La estructura principal `sistemas combinan... para generar...` se recupera, pero las coordinaciones internas `celulas y tejidos naturales o... con componentes...` quedan mezcladas como complementos paralelos. |
| 11 | Rechaza. | Acepta `ocm`. | GPT R: rechazo correcto por `centrandones`. Claude P: estructura principal correcta (`proponemos aprovechar...`), pero los incisos participial/gerundial (`dada...`, `centrandonos...`) no quedan representados con toda la claridad manual. |
| 12 | Acepta `ocm`. | Equivalente. | P/P. Buena subordinada inicial `Cuando...`, sujeto `la presion` y verbo `deja de oponerse`; la relativa `lo que...` queda demasiado metida como complemento del infinitivo `oponerse`, cuando manualmente modifica a toda la proposicion principal. |
| 13 | Acepta `ocm`. | Equivalente. | P/P. La coordinacion verbal `permite... y sirve...` esta bien, pero `alta/elevada densidad` se analiza como `alta/elevada` nombre y `densidad` modificador; manualmente es determinante + adjetivo + nombre. |
| 14 | Acepta `ocm`. | Acepta `ocm`. | GPT C/P: buen doble complemento inicial y pasiva refleja negada. Claude P: recupera sujeto y pasiva `ha sido explorada`, pero `aun no` no queda claramente representado como negacion verbal. |
| 15 | Acepta `oc`. | Equivalente. | C/C. Coordinacion `demostramos... y mostramos...`; la completiva `que es posible...` se analiza de forma razonable. |
| 16 | Acepta `o`. | Equivalente. | C/P. Sujeto `Todo el proceso`, inciso `desde...`, modal `puede realizarse` y complemento temporal estan capturados. Detalles internos del inciso son aproximados. |
| 17 | Acepta `ocm`. | Acepta `ocm`. | GPT P: estructura condicional y principal correctas, pero `hacia dentro` aparece como dos adverbios y la relativa `lo que...` como complemento verbal. Claude C/P: aposicion `estado que...` bien; la coordinacion `que denominamos... y que corresponde...` queda comprimida dentro del GV. |
| 18 | Acepta `oc`. | Acepta `oc`. | GPT C/P: coordinacion principal correcta. Claude P: sintacticamente se analiza, pero la frase `las patas se actuan` es linguisticamente anomala; el arbol la trata como reflexiva ordinaria. |
| 19 | Acepta `o`. | Equivalente. | P/P. Sujeto y predicado correctos, pero el gerundio `contrayendo...` queda como modificador de `pata`; manualmente modifica al evento verbal `extiende`. |
| 20 | Acepta `ocm`. | Acepta `o`. | GPT I: `dan lugar` se deforma, con `lugar` tratado como infinitivo y coordinaciones mal repartidas. Claude C/P: estructura global correcta; incisos y gerundio final razonables. |
| 21 | Acepta `o`. | Acepta `o`. | GPT I: `personalizado, destinado...` se analiza mal como cadena participial y se pierde la relacion de `sobre la balanza... para medir...`. Claude C/P: mejor estructura, aunque la coordinacion `y medir asi...` dentro del proposito es aproximada. |
| 22 | Acepta `o`. | Equivalente. | C/C. Verbo transitivo con GN objeto y complementos nominales razonables. |
| 23 | Acepta `o`. | Equivalente. | P/P. Reconoce `demostramos la capacidad...`, pero `para agarrar una variedad de objetos` queda parcialmente repartido, con `de objetos` demasiado suelto. |
| 24 | Acepta `ocm`. | Identica salvo tilde. | P/P. La relativa `que actua como interruptor` se detecta, pero `como interruptor` tiende a quedar como complemento verbal externo. |
| 25 | Acepta `ocm`. | Equivalente. | C/C. Completiva con subordinada temporal interna y predicado principal correctamente representados. |
| 26 | Acepta `ocm`. | Equivalente. | P/P. Coordinacion verbal correcta, pero el complemento `de la arana/aranas` aparece separado del GN `mecanismo de movimiento`, no integrado como deberia. |
| 27 | Acepta `ocm`. | Equivalente. | C/C. Complemento inicial (`Una vez...`/`Tras...`), pasiva refleja y gerundio final bien capturados. |
| 28 | Acepta `ocm`. | Equivalente. | P/P. Subordinada causal inicial y marco temporal bien; el causal `por falta/ausencia...` se adjunta demasiado al GN `cuerpo` y no al predicado `se curvan`. |
| 29 | Acepta `ocm`. | Acepta `ocm`. | GPT C. Claude P: estructura explicativa `por dos razones, ... y ...` correcta, pero `como punto de insercion` se analiza con una lectura adjectival rara dentro del GN. |
| 30 | Acepta `o`. | Acepta `o`. | GPT P: captura sujeto y desplazamiento, pero `sin manipulacion externa debido a...` queda pobremente integrado. Claude C/P: `debido a...` aparece como participio incidental por la coma, aceptable para cobertura pero no ideal manualmente. |
| 31 | Acepta `ocm`. | Equivalente. | P/P. Sujeto y relativa `que ha inspirado...` se detectan; el complemento `de muchas/numerosas articulaciones...` queda parcialmente fuera del objeto `diseno de...`. |
| 32 | Acepta `o`. | Equivalente. | C/P. Pasiva refleja con gerundio instrumental correcta; detalles de `mediante... durante...` quedan resumidos como complementos encadenados. |
| 33 | Acepta `o`. | Equivalente. | C/C. Coordinacion verbal con inciso `ademas` bien resuelta. |
| 34 | Acepta `ocm`. | Acepta `ocm`. | I/I. Aunque acepta, el arbol pierde gran parte de `para crear... que... lo que...`; termina representando complementos finales como `de fabricacion`. Manualmente deberia ser verbo principal + infinitivo final + relativa + relativa causal `lo que...`. |
| 35 | Acepta `ocm`. | Equivalente. | P/P. Mejora el nucleo `concepto... aprovecha`, pero `propuesto en este trabajo` y `de reproducir/replicar artificialmente` no quedan perfectamente ligados a sus nucleos manuales. |
| 36 | Acepta `ocm`. | Equivalente. | C/P. Complemento inicial comparativo, sujeto y predicado con infinitivos coordinados se recuperan. En Claude `basado en material biotico` queda como participio nominal, aceptable aunque algo forzado. |
| 37 | Acepta `ocm`. | Acepta `o`. | C/C. GPT usa marcador inicial `No obstante`; Claude lo trata como inciso. Ambas lecturas son razonables. |
| 38 | Acepta `ocm`. | Equivalente. | P/P. La completiva `que la duracion... fue...` se reconoce mediante la maquinaria de relativas/complementos; la estructura global es legible, pero no es una completiva manual limpia. |
| 39 | Acepta `o`. | Equivalente. | P/P. Hipotesis + completiva `de que...` bien; `de agua` aparece como complemento final del verbo principal, cuando manualmente depende de `perdida`. |
| 40 | Acepta `ocm`. | Equivalente. | C/C. Sujeto `resultados`, verbo `muestran` y completiva/relativa `que la arana... presento/experimento...` razonables. |
| 41 | Acepta `oc`. | Equivalente. | I/I. La coordinacion `tamanos o especies` se interpreta como coordinacion de oraciones: `Estudiar...` o `especies podria...`; manualmente `o especies` esta dentro del GN/GP. |
| 42 | Acepta `ocm`. | Equivalente. | P/P. Estructura principal correcta, pero la coordinacion final `y aprovechar...` queda demasiado escondida o no claramente dependiente de `incluir/exploracion`. |
| 43 | Acepta `ocm`. | Equivalente. | C/P. Modal pasivo `podrian/podran incorporarse...` y lista de objetos bien; en Claude el orden `al sistema niveles...` genera adjuncion algo rara pero recupera la estructura. |
| 44 | Acepta `o`. | Acepta `o`. | GPT C. Claude I/P: la frase manual es `suelen entrañar`; el arbol muestra `entrañar` como verbo principal y no representa bien el modal `suelen`. |
| 45 | Acepta `ocm`. | Equivalente. | P/P. Verbo modal + infinitivo correcto; el gerundio instrumental `variando...` y la relativa `que requieren...` no quedan tan claramente estructurados como en un analisis manual. |
| 46 | Acepta `o`. | Acepta `o`. | P/P. Pasiva refleja y sujeto compuesto se capturan, pero la coordinacion interna del sujeto y los complementos instrumentales/finales quedan aproximados. |
| 47 | Acepta `oc`. | Acepta `oc`. | GPT C/P: coordinacion de dos pasivas reflejas y gerundio final razonables. Claude P: sin comas, `entre... siguiendo...` queda mas absorbido por el GN de muestras. |
| 48 | Acepta `ocm`. | Equivalente. | P/P. Relativa `que respaldan...` correcta; predicado `estan disponibles en el material suplementario/complementario...` se parte en GAdj + GN adicional. |
| 49 | Acepta `o`. | Equivalente. | I/P. El gerundio instrumental `utilizando un montaje/sistema...` no aparece como tal; el arbol termina con `de ensayos y balanza` como GP, perdiendo el nucleo `montaje/sistema compuesto...`. |
| 50 | Acepta `o`. | Acepta `o`. | C/C. Pasiva refleja en GPT y pasiva/copulativa participial en Claude correctamente aceptadas. |

## Problemas recurrentes

1. La negacion verbal (`no`, `aun no`) a veces se adjunta a GN o desaparece: pares 3, 4, 14.
2. Las completivas con `que` se analizan con nodos de relativa (`rel`) en muchos casos. Sirve para aceptar, pero no coincide con el analisis manual: pares 12, 25, 38, 40.
3. Las coordinaciones internas de GN/GP se confunden con coordinaciones oracionales: caso grave en par 41.
4. Gerundios y participios incidentales se aceptan, pero a veces se adjuntan al nombre equivocado: pares 19, 21, 45, 49.
5. Algunas frases aceptadas tienen arbol claramente malo aunque no haya timeout: pares 20 GPT, 21 GPT, 34 ambos, 41 ambos, 49 ambos.
