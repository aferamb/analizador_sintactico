# Documentacion del lexico semantico

Este documento explica como consultar `lexico_semantico.pl`, el inventario de
clasificacion lexico-semantica creado para comparar las frases traducidas por
ChatGPT y Claude.

El archivo trabaja con las formas normalizadas que usa el analizador. Por eso,
las palabras con tilde del texto original aparecen sin tilde en las consultas:
`ademas`, `presion`, `necrobotica`, `articulo`. La letra `ñ` se conserva, por
ejemplo en `araña`.

## Cargar el lexico

Desde la raiz del proyecto:

```bash
swipl -q -s lexico_semantico.pl
```

Tambien puedes ejecutar consultas directamente desde la terminal:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(araña,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Para consultar otra palabra, sustituye `araña` por el token normalizado que
quieras analizar.

## Predicados disponibles

```prolog
lexico_semantico(Palabra, Clase, Rasgos).
```

Devuelve la clase principal y los rasgos de una palabra.

```prolog
clase_lexico_semantica(Palabra, Clase).
```

Devuelve solo las clases posibles de una palabra.

```prolog
rasgos_lexico_semanticos(Palabra, Clase, Rasgos).
```

Devuelve los rasgos de una palabra para una clase concreta.

```prolog
palabra_lexico_semantica(Palabra).
```

Comprueba si una palabra pertenece al vocabulario del corpus.

```prolog
locucion_lexico_semantica(Tokens, Clase, Rasgos).
```

Consulta locuciones registradas, como `[sin,embargo]` o `[dado,que]`.

## Consultar la clasificacion completa de una palabra

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(araña,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
sustantivo-[referente(comun),significado(concreto),contabilidad(contable),genero(femenino)]
```

## Palabra ambigua: `la`

`la` puede funcionar como determinante o como pronombre.

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(la,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
determinante-[tipo(articulo(determinado)),genero(femenino),numero(singular)]
pronombre-[tipo(personal(objeto_atono_clitico)),persona(tercera),tonicidad(atono)]
```

## Palabra ambigua: `que`

`que` puede aparecer como pronombre relativo o como conjuncion subordinante.

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(que,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
pronombre-[tipo(relativo),funcion(contextual)]
conjuncion-[tipo(subordinante(completiva))]
```

## Verbo: `agarrar`

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(agarrar,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
verbo-[formas([infinitivo]),funcion_predicativa(predicativo),transitividad(transitivo),voz(contextual),tipo_especial(ninguno),regularidad(regular)]
```

## Adverbio: `ademas`

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(ademas,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
adverbio-[significado(modo),funcion_discursiva(conector_discursivo),forma(simple)]
```

## Conjuncion: `y`

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(y,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
conjuncion-[tipo(coordinante(copulativa))]
```

## Forma problematica del corpus: `centrandones`

`centrandones` aparece en el corpus GPT como forma erronea. El lexico la
registra como gerundio para que el analisis posterior pueda detectarla y
tratarla.

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "forall(lexico_semantico(centrandones,Clase,Rasgos),(writeq(Clase-Rasgos),nl)),halt."
```

Salida esperada:

```text
verbo-[formas([gerundio]),funcion_predicativa(predicativo),transitividad(contextual),voz(contextual),tipo_especial(ninguno),regularidad(regular)]
```

## Consultar solo las clases

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "findall(Clase,clase_lexico_semantica(la,Clase),Clases),writeq(Clases),nl,halt."
```

Salida esperada:

```text
[determinante,pronombre]
```

## Consultar los rasgos de una clase concreta

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "rasgos_lexico_semanticos(araña,sustantivo,Rasgos),writeq(Rasgos),nl,halt."
```

Salida esperada:

```text
[referente(comun),significado(concreto),contabilidad(contable),genero(femenino)]
```

## Consultar si una palabra esta en el corpus

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "(palabra_lexico_semantica(pinza)->write(si);write(no)),nl,halt."
```

Salida esperada:

```text
si
```

## Consultar una locucion

Comando:

```bash
swipl -q -s lexico_semantico.pl -g "locucion_lexico_semantica([sin,embargo],Clase,Rasgos),writeq(Clase-Rasgos),nl,halt."
```

Salida esperada:

```text
adverbio-[funcion_discursiva(conector_discursivo),forma(locucion_adverbial)]
```

## Comparacion lexico-semantica GPT/Claude

### Cargar el comparador

```bash
swipl -q -s comparativo_lexico_semantico.pl
```

### Comparar un par concreto

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "comparar_ls(1),halt."
```

### Obtener el resumen global

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "resumen_lexico_semantico,halt."
```

### Exportar el TSV lexico-semantico

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "exportar_tsv_ls('resultados_ls.tsv'),halt."
```

### Consultas utiles

Obtener una metrica concreta de un par:

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "comparacion_ls(1,C),valor_comparacion_ls(C,jaccard_global,J),write(J),nl,halt."
```

Ver top de palabras por corpus y categoria:

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "top_palabras_ls(gpt,sustantivo,5,Top),writeq(Top),nl,halt."
```

Ver vocabulario exclusivo y compartido:

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "vocabulario_global_exclusivo_ls(sustantivo,SoloGPT,SoloClaude,Compartido),writeq((SoloGPT,SoloClaude,Compartido)),nl,halt."
```

Listar sustituciones lexicas candidatas:

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "sustituciones_lexicas_ls(S),writeq(S),nl,halt."
```

Listar pares interesantes:

```bash
swipl -q -s comparativo_lexico_semantico.pl -g "pares_interesantes_ls(P),writeq(P),nl,halt."
```

## Comprobar que el lexico carga sin errores

```bash
swipl -q -s lexico_semantico.pl -g "halt."
```

Si no imprime nada y vuelve a la terminal, el archivo se ha cargado
correctamente.
