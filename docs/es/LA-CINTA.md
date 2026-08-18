# La cinta

`colt36.tsx` ocupa 34 722 bytes y su sha256 es `4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13`. Dentro hay cinco bloques grabados con la codificación de cinta estándar del MSX: ningún cargador turbo, ninguna rutina propia de lectura de cinta, nada más rápido que lo que trae la máquina de fábrica. Es lenta de verdad: desde que empieza a sonar la cinta hasta que arranca la animación del logo de la casa pasan 69,7 segundos medidos en el emulador.

| bloque | tipo | carga | fin | arranque | tamaño |
|---|---|---|---|---|---|
| `COLT36` | ASCII | — | — | — | 256 B |
| `topo` | BIN | 0x9470 | 0xA50D | 0x9470 | 4254 B |
| `scr` | BIN | 0x9C40 | 0xB7FB | 0xB798 | 7100 B |
| `CM2` | BIN | 0x9B91 | 0xE340 | 0x9BBA | 18 352 B |
| `CM1` | BIN | 0x83E8 | 0x949C | 0x948F | 4277 B |

Son 34 239 bytes de contenido. El bloque de `CM1` arrastra además un byte de relleno `0xFF` detrás de los datos, y con él se acaba la cinta.

## Qué es un BIN en cinta

Cada bloque va precedido de una cabecera de dieciséis bytes: diez bytes iguales que dicen de qué tipo es y seis con el nombre. En `COLT36` esos diez bytes son `0xEA`, que significa «texto»; en los otros cuatro son `0xD0`, que significa «binario».

Un BIN de cinta no lleva nada parecido a una tabla de reubicación ni a una lista de símbolos. Lo único que trae de más son tres direcciones de dos bytes al principio del bloque de datos: **carga**, **fin** y **arranque**. `BLOAD"cas:"` vuelca los bytes entre la de carga y la de fin, tal cual, sin tocarlos; si se le añade `,R`, al terminar salta a la de arranque. Eso es todo. El bloque tiene que saber caer donde cae, y si la máquina tiene ocupada esa memoria, peor para la máquina.

El bloque ASCII funciona distinto: es un programa BASIC guardado como texto plano, y se carga con `RUN"cas:"`, que lo lee y lo ejecuta. Ocupa 256 bytes clavados porque los ficheros de texto en cinta se escriben en registros de ese tamaño, rellenos con `0x1A` hasta completarlo.

## El cargador

Los 256 bytes del primer bloque son 117 de texto, un `0x1A` de fin de fichero y 138 más de relleno. El texto es este:

    10 COLOR 1,1,1:SCREEN 2
    20 BLOAD"cas:",R
    30 BLOAD"cas:",R
    40 CLEAR200,39824!
    50 BLOAD"cas:",R
    60 BLOAD"cas:",R

La línea 10 pone tinta, fondo y borde del mismo color —el 1 es el negro— y pasa al modo gráfico de 256×192. La pantalla queda a oscuras. La 20 trae `topo`, el logo de la casa, que se ejecuta en su propia dirección de carga, hace su animación y devuelve el control al BASIC. La 30 trae `scr`, la pantalla de carga, cuyo arranque en 0xB798 la pinta en 0,27 segundos: aparece de golpe, no se ve dibujar.

![La pantalla de carga de Colt 36, firmada CANO](../imagenes/carga.png)

La 50 trae `CM2`, los 18 352 bytes de dibujos, decorados y música, y la 60 el juego propiamente dicho.

Falta la 40, que es la interesante. `CLEAR200,39824` reserva 200 bytes para cadenas y baja el techo de memoria del intérprete a 39824, o sea 0x9B90, justo un byte por debajo de donde va a caer `CM2`. Y no puede ir en cualquier sitio. Tiene que ir **después** de la línea 20, porque una vez hecho el `CLEAR` la pila y el buffer de fichero del intérprete pasan a vivir en 0x98A0..0x9B90, que está dentro del rango de `topo` (0x9470..0xA50D): el `BLOAD` de la línea 20 estaría escribiendo encima de su propia pila y del buffer con el que lee la cinta. Y tiene que ir **antes** de la 60, para que cuando el juego arranque el techo ya esté puesto y ni la pila ni las cadenas lleguen jamás a tocar los datos.

### La prueba de que se grabó con `SAVE",A"`

En `39824!` hay un signo de admiración que nadie tecleó. En MSX-BASIC un entero llega hasta 32767; 39824 no cabe, así que el intérprete lo guarda como número de precisión simple, y cuando un `LIST` lo vuelve a escribir le añade el sufijo `!` que marca ese tipo. Es decir: el texto que hay en la cinta es literalmente la salida de un `LIST`, y el cargador se grabó con `SAVE"cas:",A` desde el propio intérprete, no se escribió a mano en un editor.

## Qué se pisa a qué

Los cuatro bloques binarios ocupan rangos que se solapan, porque van llegando y desalojándose por turnos:

- `scr` pisa 2254 bytes de `topo`.
- `CM2` pisa `scr` entero y otros 2429 bytes de `topo`.
- `CM1`, al caer en 0x83E8..0x949C, se lleva por delante 45 bytes más de `topo`.

De los 4254 bytes del logo quedan sin pisar 1780, los de 0x949D a 0x9B90. Y 0x9B90 es exactamente el techo que fijó el `CLEAR`: lo que sobrevive del logo cae justo en la zona que el intérprete usa como pila y espacio de cadenas. El cadáver aguanta más de lo que uno diría, porque el juego gasta poca pila: medido a los 80 segundos de partida seguían intactos 1629 de esos bytes, y 893 de ellos seguidos, de 0x949D a 0x9819.

## Un `,R` que no arranca nada

Los cuatro `BLOAD` llevan `,R`, pero el de `CM2` no pone en marcha nada. Su dirección de arranque, 0x9BBA, contiene un único byte `0xC9`, que es la instrucción `RET` del Z80: el salto entra ahí y vuelve inmediatamente. Ese byte es el final de la rutina que empieza en 0x9B91, la que inicializa el reproductor de música.

Y tenía que ser así a propósito. `BSAVE` permite omitir la dirección de arranque, pero en ese caso toma la de carga, que aquí es 0x9B91: el `,R` habría arrancado el reproductor de música con el juego todavía sin cargar. Apuntar el arranque a un `RET` es la forma de que un bloque de datos puros conviva con un cargador que siempre usa `,R`.

## El recolocador de `CM1`

El último bloque se carga en 0x83E8 y su dirección de arranque es 0x948F. Ahí hay cinco instrucciones:

    LD HL,0x83E8
    LD DE,0x8000
    LD BC,0x10B5
    LDIR
    JP 0x9088

`LDIR` copia BC bytes de HL a DE: aquí, los 4277 del bloque entero, mil bytes más abajo. Como el destino queda por debajo del origen, la copia hacia adelante no se muerde la cola. La rutina se copia también a sí misma, y cuando termina salta a 0x9088, que ya está en su sitio.

La razón de todo el rodeo es que el juego es un programa MSX-BASIC, y en el MSX los programas BASIC viven a partir de 0x8001, que es exactamente donde tiene que acabar `CM1`. Pero mientras la cinta carga, el programa que manda es el cargador, que también es BASIC y también está en 0x8001, ejecutando el `BLOAD` de la línea 60. Cargar el juego directamente en su sitio sería escribir encima del programa que está leyendo la cinta. Así que el bloque aterriza mil bytes más arriba, en terreno libre, y solo baja a su casa cuando el cargador ya no hace falta.

De ahí en adelante ya no queda cinta: los 20 bytes de 0x9088 ponen VARTAB —el puntero donde el intérprete construye su tabla de variables— en 0x8F60 y saltan a la rutina que ejecuta programas. Antes de eso escriben cinco bytes sobre 0x8000 que renumeran la primera línea del juego, que en la cinta es la 65535: ver [Una línea numerada 65535](HALLAZGOS.html#una-linea-numerada-65535).

![La pantalla de título de Colt 36](../imagenes/portada.png)
