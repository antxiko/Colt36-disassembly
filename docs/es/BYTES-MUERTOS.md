# Bytes muertos

Un desensamblado no termina cuando el código se entiende: termina cuando cada byte de la cinta tiene dueño. En Colt 36 el reparto cierra al 100% —34 239 bytes de contenido, 34 239 explicados—, pero una parte de ese contenido no la lee nadie. Sumando solo los trozos que se cuentan aquí salen **3263 bytes muertos**; si se añaden los 2048 del área de trabajo y los pellizcos de relleno, son **5456 bytes de 34 239, casi el 16% de la cinta**.

## Los 297 bytes del área de variables

El juego es un programa MSX-BASIC tokenizado (guardado ya troceado en códigos internos, no como texto), y el bloque que lo trae reserva detrás del listado 297 bytes en 0x8F5F–0x9087: el **área de variables**, la tabla donde el intérprete va anotando las variables que el programa crea al ejecutarse. Grabarla en cinta no sirve de nada, y aquí se puede demostrar de tres formas independientes.

La primera: el programa no menciona ni una dirección de ese rango. La segunda: lo grabado se destruye en cuanto el juego crea su primera variable. La tercera es la que más dice. El contenido es 1 byte muerto, **11 bytes de una variable sobrante** —una `I` de doble precisión con valor 37025, con el formato exacto de la tabla del intérprete, reproducido byte a byte en el emulador— y **285 bytes de RAM sin inicializar**. Esos 285 siguen la regla «0xFF si el bit 0 de la dirección coincide con su bit 7, y 0x00 si no», que es el contenido de encendido documentado para varias máquinas: la cumplen **282 de 285**.

Y como la regla depende de la dirección *absoluta*, el patrón funciona de huella. Encaja en 282 de los 285 (98,9 %) si el bloque estaba en 0x8000, y solo en 226 (79,3 %) si hubiera estado en 0x83E8, que es donde la cinta lo carga. O sea: en la máquina del programador el juego ya vivía en 0x8000, y el 0x83E8 es un desvío para no pisar al cargador. Basura que dice dónde se hizo el juego.

## Los 88 de la pantalla de carga

![La pantalla que se ve mientras el juego carga](../imagenes/carga.png)

El bloque de la ilustración de carga reparte 6144 bytes de dibujo + 768 de color + **88 bytes que no lee nadie** + 95 de código + 5 ceros. Los 88 cumplen la misma regla de RAM recién encendida, los 88 de 88: el `BSAVE` con que se grabó el bloque cogió un rango un poco más ancho que los datos. Comprobado además en el emulador con un punto de observación sobre esas direcciones: cero lecturas durante el pintado.

## El decorado de 0xD400 al que no apunta nadie

En 0xD400–0xD5FF hay 512 bytes con formato de tablero: números de casilla, 32 por fila. Las doce primeras filas dibujan una escena coherente —dos plataformas con botellas y una empalizada larga—, con solo ocho dibujos distintos y **ocho casillas de las que se rompen al dispararles** (los dibujos 72 y 73). Las cuatro últimas filas, 128 bytes, son ceros.

Nadie lo lee. En todo el listado no aparece ni una constante entre 0xD400 y 0xD5FF, y las copias vecinas se quedan justo fuera: la portada son 768 bytes desde 0xD000 (acaban en 0xD300), el marcador 256 desde 0xD300 (acaban **exactamente** en 0xD400), y lo siguiente que toca alguien está ya en 0xD600. Un decorado descartado que se quedó dentro del fichero.

![El decorado descartado de 0xD400, dibujado con los propios gráficos del juego. Nunca llegó a verse en pantalla](../imagenes/decorado-inedito.png)

Esta imagen no ha existido nunca en una pantalla. Está dibujada a partir de esos
512 bytes con la tabla de dibujos del propio juego, que es lo que la convierte en
algo más que una curiosidad: si el reparto del bloque estuviera mal, de ahí
saldría ruido. Sale una escena montada, con sus botellas colocadas sobre los
estantes y su empalizada alineada. Alguien la dibujó y luego decidió no usarla.


## El recorte olvidado de 0xD9A0

Los escondites de los bandidos viven en 0xD900: diez por nivel, cuatro bytes cada uno, cuarenta bytes por nivel, 160 en total. El programa los indexa con `K%=INT(RND(-TIME)*10)*4+&HD900+40*(N%-1)`, así que la dirección más alta que llega a leer es 0xD99F.

Los 64 bytes siguientes, 0xD9A0–0xD9DF, son una **copia literal de las formas y los colores de las casillas 170 a 173**: comprobado byte a byte contra las tablas de dibujos de 0xC000 y de color de 0xC800. Es el bloque de 2×2 justo anterior al primer modelo de bandido, que empieza en la casilla 174. Un recorte de las tablas grandes, pegado ahí y olvidado.

## La fila de relleno de 0xD620

En 0xD600 hay 512 bytes, todos con el dibujo 255, la casilla vacía. La línea 30 los usa para borrar la zona de juego antes de anunciar el nivel: `HL=&HD600 : BC=32 : FOR DE=6144 TO 6656 STEP 32`. Copia **32 bytes**, siempre los mismos, a diecisiete filas seguidas de la pantalla; el origen no cambia nunca. Los **480 bytes de 0xD620 a 0xD7FF** son más de lo mismo y no los lee nadie.

## Los 256 ceros de 0xE200

El área de trabajo del nivel ocupa 0xDA00–0xE1FF y detrás vienen 256 bytes a cero, hasta que en 0xE300 empieza la primera rutina en código máquina. Son relleno para que esa rutina caiga en dirección redonda. Que no se vean se sigue del tope de scroll de la línea 610: para los niveles 3 y 4 el tope es 0xE000 y la ventana de 512 bytes acaba en 0xE1FF, el último byte del área de trabajo. Ni uno más.

## Lo que no se ha conseguido identificar

Aquí toca decir exactamente qué se sabe y qué no.

**El sobrante de los mapas 1 y 2 (1536 bytes).** Cada decorado es un tablero de 32×64, 2048 bytes, y se copia entero al área de trabajo. Pero esa misma línea 610 pone el tope en 0xDC00 para el nivel 1 y en 0xDE00 para el 2, con lo que la última ventana visible acaba en 0xDDFF y en 0xDFFF: **32 filas y 48 filas**. Lo que queda fuera es, al byte, **0xA400–0xA7FF (1024 B)** y **0xAE00–0xAFFF (512 B)**. Eso está demostrado: el juego no muestra esos bytes jamás.

![El decorado completo del nivel 1, EL ALMACÉN](../imagenes/mapa1.png)

Qué son, no. Se ha descartado que sean mapa, color, música o copia de cualquier otra parte de la cinta. Se ha descartado que sean **PCM** (sonido digitalizado, una muestra por byte): la correlación entre bytes vecinos sale **−0,27**, y una señal muestreada de verdad da **+0,99**. Se ha descartado que sean una **tabla de periodos de notas**: leídos como palabras de 16 bits, la desviación respecto a la escala templada es de **0,244 semitonos**, que es lo que da el azar, mientras que la tabla de periodos real del juego da **0,090**.

Y hay dos descartes que merecen su propia medida, porque cierran de golpe familias enteras de hipótesis.

**No son código, de ninguna máquina.** No hace falta ir CPU por CPU: basta con contar cuántos valores de byte distintos usan. Los 1566 usan **60**. Trescientos bytes de código Z80 de esta misma cinta usan **67**, y un programa necesita muchos más conforme crece, porque tiene que nombrar registros, saltos y constantes. La consecuencia es que faltan instrucciones que ningún programa puede no tener: en los 1566 bytes hay **cero `CALL` (0xCD), cero `RET` (0xC9), cero prefijos 0xED, cero `JR`, cero `DJNZ` y cero `LD BC,nn`**. Ninguna. Y como es una cuenta sobre el conjunto de bytes, vale para cualquier alineamiento y para cualquier procesador de ocho bits: si el opcode no está en el bloque, no está en ninguna lectura del bloque.

**No son un dibujo, en ningún ancho.** Aquí la medida es la longitud media de racha: cuántos píxeles seguidos del mismo color hay, leyendo los bits en fila. Un dibujo, por dentado que sea, tiene rachas **más largas** que el azar, porque las cosas dibujadas son continuas. Los bytes de la cinta lo confirman: los dibujos del juego dan **3,91** y el mapa del nivel 1 da **3,82**, contra los **2,00** exactos del azar. Los sospechosos dan **1,63**: alternan *más* que unos bytes aleatorios. Y como la racha horizontal no depende del ancho de la línea, esto descarta a la vez todos los anchos posibles.

**La cola de 30 bytes (0xE323–0xE340).** Van detrás del último `RET`, hasta el final que declara la cabecera:

    16 E9 16 69 16 E9 16 E9 16 49 16 49 04 40 00 40
    00 41 00 41 04 41 00 41 00 41 00 69 00 41

Quince parejas. El primer byte es siempre 0x16, 0x04 o 0x00; el segundo toma solo cinco valores. No son código alcanzable, ni dibujos, ni color, ni mapa, ni música, y la secuencia no aparece en ningún otro sitio de la cinta, ni siquiera buscando solo los seis primeros bytes.

### Lo que sí se sabe: no son basura

Descartar cosas no es el único resultado. Estos bytes tienen una estructura que se mide, y una bastante llamativa. Sobre los 1536 de los decorados:

- **Las posiciones pares y las impares no comparten valores.** Hay 55 valores distintos: 34 aparecen solo en posición par, 22 solo en impar, y el único que aparece en las dos es 0xFF. La consecuencia es medible: dos bytes cualesquiera a distancia impar coinciden el **0,0 %** de las veces —ni una sola— mientras que a distancia 2 coinciden el 49 %.
- **El bit 1 está puesto en los 768 bytes de posición par.** En los 768. Sin una excepción.
- **Los bytes pares llevan encendidos los bits de índice impar (7, 3, 1) y los impares los de índice par (6, 4, 2).** Visto como imagen eso da un damero, y por ahí se fue la primera hipótesis; la explicación resultó ser otra, y está más abajo.
- **Son seis bloques de 256 bytes que son variaciones de un mismo bloque.** Esta es la medida más fuerte de todas. Comparando bit a bit, dos bloques cualesquiera se diferencian en **191 bits de 2048, un 9,3 %**. La misma medida sobre el decorado de al lado —el que sí se ve— da **1098 bits, un 53,6 %**, que es lo que da el azar. Buscando el periodo que menos diferencias deja, entre 1 y 256, gana **256** con un 9,2 % de bits distintos; todos los periodos impares se van al 74 %, por encima del azar. Y 256 bytes es exactamente una fila de 32 caracteres de pantalla.

Y la cola de 30 bytes, que se había tratado como un asunto aparte, resulta tener **la misma firma**: alternancia estricta, alfabetos de posición par e impar sin un solo valor en común, bits fijos complementarios en cada paridad. Con 30 bytes eso podría ser casualidad y hay que decirlo; con 1536, no.

### La mejor pista: el contenido lo dicta la dirección

Esto es lo más lejos que se ha llegado, y es la pista que hay que seguir. Lo que decide qué byte hay en cada sitio no parece ser un contenido, sino **la dirección de memoria en la que está**. Tres medidas independientes apuntan a lo mismo:

- **Cada bit tiene su propia polaridad, y va atada a la paridad de la dirección.** Tomando la regla «dirección par → el bit vale 1, dirección impar → vale 0», la cumplen el bit 1 en el **99,2 %** de los bytes, el bit 3 en el 96,3 %, el bit 7 en el 92,0 % y el bit 0 en el 88,0 %. Y los bits 2 y 6 cumplen **la contraria**, al 20,1 % y al 18,8 %. Es un efecto por *posición del bit*, no por valor del byte, y eso es lo que hace que no encaje en ningún formato: un mapa, un dibujo, un texto o una muestra de sonido tratan el byte como una unidad. Ocho chips de memoria de un bit, uno por cada línea de datos, no.
- **Los ocho 0xFF en dirección impar caen los ocho en el mismo sitio del ciclo.** En los 1024 bytes hay exactamente ocho bytes 0xFF en dirección impar, y son 0xA47F, 0xA4FF, 0xA57F, 0xA5FF, 0xA67F, 0xA6FF, 0xA77F y 0xA7FF: las ocho direcciones cuyos siete bits bajos están todos a uno. Las ocho, sin fallar una.
- **El bloque entero es una constante de dos bytes con bits caídos.** La palabra de 16 bits que mejor se le ajusta es **9B 54**, y las 512 palabras del bloque están a una media de **2,46 bits de ella**, de dieciséis. El azar daría 8.

Y de ahí sale, por fin, la explicación de por qué 0xA600–0xA7FF y 0xAE00–0xAFFF son idénticos byte a byte: están separados por 0x800, que es múltiplo de 128, así que **tienen los mismos bits bajos de dirección**. No hacía falta que nadie copiara nada.

### Y sin embargo, no es la basura conocida de esta cinta

Aquí es donde hay que frenar. La conclusión natural sería «es RAM sin inicializar, como los otros restos», y esta cinta permite comprobarlo, porque ya tiene dos zonas identificadas como tal: los 88 bytes de la pantalla de carga y los 285 del área de variables. Las dos cumplen la regla «0xFF si el bit 0 de la dirección coincide con el bit 7, y 0x00 si no». Contando bits, el encaje es este:

    los 88 bytes de la pantalla de carga    100,0 %
    los 285 del area de variables            99,3 %
    ---------------------------------------------
    LOS SOSPECHOSOS de 0xA400                47,7 %
    los de 0xAE00                            46,4 %
    ---------------------------------------------
    el mapa del nivel 1, un dato de verdad   50,3 %
    la tabla de dibujos                      50,4 %

Los sospechosos encajan **igual que un dato cualquiera**, o sea nada. Si fueran la misma memoria sin inicializar de la misma máquina, tendrían que parecerse a las otras dos, y no se parecen. Así que lo que hay es esto y no más: unos bytes cuyo contenido depende de la dirección —lo cual ningún formato de datos hace— pero que no son el patrón de encendido que sí se ha identificado en el resto de la cinta. Puede que sean memoria sin inicializar de otra clase, de otro chip o de otro momento. Puede que sean otra cosa. Medido está lo que está.

### SE BUSCA

Esta es la única parte del trabajo que sigue abierta, así que se publica como lo que es: un cartel.

```
    *-------------------------------------------------------------*
    |                                                             |
    |                   S E   B U S C A N                         |
    |                  VIVOS  O  MUERTOS                          |
    |                                                             |
    |                    1 5 6 6   B Y T E S                      |
    |                                                             |
    |   Vistos por ultima vez en una cinta de Topo Soft, 1987,    |
    |   en las direcciones 0xA400, 0xAE00 y 0xE323. Llevan        |
    |   cuarenta anos ahi sin que nadie sepa a que se dedican.    |
    |                                                             |
    |   SENAS PARTICULARES                                        |
    |     - solo 60 valores de byte distintos en 1566             |
    |     - el bit 1 encendido en los 768 bytes de posicion par   |
    |     - cada bit con su polaridad atada a la paridad de la    |
    |       direccion: el bit 1 la cumple al 99,2%, el 6 al 18,8% |
    |     - los 8 unicos 0xFF en direccion impar caen los ocho    |
    |       donde los 7 bits bajos estan todos a uno              |
    |     - seis bloques de 256 bytes que solo se diferencian     |
    |       en el 9% de sus bits (el decorado de al lado: 54%)    |
    |                                                             |
    |   NO SON  codigo de ninguna CPU (60 valores de byte, cero   |
    |           CALL y cero RET en 1566) - dibujo de ningun       |
    |           ancho (racha 1,63, por debajo del azar 2,00) -    |
    |           mapa - color - musica - sonido digitalizado -     |
    |           tabla de notas - copia de otra parte de la cinta  |
    |           - la RAM de encendido que si trae esta cinta      |
    |             (encajan al 47,7%; las otras zonas al 99-100%)  |
    |                                                             |
    |   SE LES BUSCA VIVOS: que alguien diga que son.             |
    |   SE LES ACEPTA MUERTOS: un "no es X, y esta es la          |
    |   medida que lo descarta" tambien vale, y se publica.       |
    |                                                             |
    |   RECOMPENSA  tu nombre en este repositorio, al lado de     |
    |               los bytes que hayas identificado              |
    |                                                             |
    *-------------------------------------------------------------*
```

Para trastear con ellos no hace falta repetir el desmontaje. Con tu propia copia de la cinta:

```sh
make extract
python3 tools/extrae_misterio.py work work
```

Eso deja `work/misterio.bin` (los 1566 seguidos), `work/misterio_mapas.bin` (los 1536 de los decorados) y `work/misterio_cola.bin` (los 30), y saca por pantalla todas las medidas de arriba para que se puedan comprobar antes de dar nada por bueno.

Si crees que sabes lo que son, [abre un issue](https://github.com/antxiko/Colt36-disassembly/issues/new/choose). Lo que hace falta no es la idea —ideas hay muchas y varias eran buenas— sino la medida que la sostiene: qué habría que ver si la hipótesis fuese cierta, y qué sale al mirarlo.

## Por qué esto se cuenta

Porque el presupuesto de bytes solo cierra si cada uno tiene dueño, y «no lo sé» es un dueño con nombre y apellidos. El hueco que se calla se llena solo, y lo que lo llena suele ser una explicación verosímil que nadie ha medido. Escribir «basura» y seguir es cómodo; escribir *qué* medida se hizo, con qué cifra salió y contra qué se comparó permite que otro repita la prueba y desmienta la conclusión.

Y porque los bytes muertos son la mejor prueba material que deja una cinta. El patrón de la RAM sin inicializar dice que el juego se escribió en 0x8000. Los seis bytes de parámetros de 0xD9E1 vienen grabados con 768, 6144 y 0xD000, que son exactamente los valores de la línea 572, la que pinta la portada. El área de trabajo trae una copia exacta del mapa del nivel 1. Nadie grabó eso a propósito: la cinta se cortó de una sesión viva, parada en la pantalla de título, con el poso de la última partida todavía en memoria. Eso no se sabe leyendo el código. Se sabe leyendo lo que sobra.
