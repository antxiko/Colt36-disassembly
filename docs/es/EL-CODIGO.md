# Cómo está hecho Colt 36

Colt 36 está escrito en MSX-BASIC. No es un cargador en BASIC que arranca un juego en ensamblador: el juego entero —el bucle principal, la detección de impactos, el marcador, la lógica de los bandidos— son **63 líneas de MSX-BASIC**, 3935 bytes en forma tokenizada (la representación interna comprimida con la que el intérprete guarda un programa). Es un juego comercial de acción de 1987 y se juega perfectamente. Lo que sigue explica cómo es eso posible.

![La pantalla de título](../imagenes/portada.png)

## El reparto del trabajo

El bloque grande de la cinta, `CM2`, ocupa 18 352 bytes y es casi todo datos: los dibujos, los cuatro decorados, las melodías, los sprites. De código máquina hay **309 bytes**, el 1,7 % del bloque, en tres piezas:

- **USR1** (0xE300, 17 bytes) copia un bloque de RAM a la memoria de vídeo llamando a LDIRVM, la rutina de la BIOS —el sistema en ROM de la máquina— que está en 0x005C. Este es el motor gráfico entero del juego. La llaman trece líneas del BASIC.
- **USR2** (0xE313, 16 bytes) es la misma rutina hasta el último momento, donde en lugar de llamar a la BIOS hace un `LDIR`, la instrucción del Z80 que copia un bloque de memoria a memoria. Se la llama desde **un solo sitio** del programa: llevar el decorado del nivel al área de trabajo, al empezar cada nivel y otra vez al repetirlo tras perder una vida.
- **El reproductor de música** (0x9B91–0x9CA4, 276 bytes), del que se habla más abajo.

`USR3` y `USR4` no son rutinas del juego. La línea 500 las declara como `DEFUSR3=&H41` y `DEFUSR4=&H44`: son DISSCR y ENASCR, dos entradas de la BIOS para apagar y encender la pantalla mientras se dibuja.

A esos 309 bytes hay que sumar 45 más, que viven en el otro bloque y solo se ejecutan una vez, al arrancar.

## El truco: el juego no dibuja, escribe números de casilla

En este modo de pantalla el MSX divide la imagen en 32 × 24 casillas de 8 × 8 píxeles, y lo que hay en la memoria de vídeo no son píxeles sino una tabla de 768 números, uno por casilla, que dice qué dibujo va en cada sitio. Colt 36 mantiene **una copia de ese tablero en la RAM normal**, a partir de 0xDA00, y trabaja siempre sobre la copia.

Así, todo el juego se reduce a leer y escribir números:

- **Disparar es un solo `PEEK`.** La línea 305 hace `PI%=PEEK(HL+225+X%\8)`, que es la casilla bajo el centro de la mira: siete filas más abajo del origen de la ventana y una columna a la derecha. No hay geometría, ni cajas de colisión, ni recorrer una lista de enemigos.
- **Acertar es cambiar ese número.** Los dibujos 71 a 78 son objetos rompibles que valen de 1 a 8 puntos, y romperlos es escribir el número ocho posiciones más allá, que es su versión rota.
- **Los bandidos no son sprites.** Son bloques de 2 × 2 casillas que el BASIC va escribiendo con cuatro `POKE` sobre el tablero de memoria, según un contador de fase. Los únicos sprites de verdad —imágenes que el chip de vídeo mueve por su cuenta— son la mira, el fogonazo, la mosca de la portada y los ojos.

Cuando toca enseñar el resultado, USR1 vuelca de golpe los 512 bytes de la ventana visible (16 filas) a la memoria de vídeo. Escribir 512 bytes uno a uno desde BASIC sería inviable; en código máquina es instantáneo.

![Nivel 1, EL ALMACÉN, con su marcador](../imagenes/nivel1.png)

## Los parámetros en un sitio fijo, y el scroll que sale gratis

USR1 y USR2 no reciben argumentos. Leen sus tres parámetros de seis posiciones fijas de memoria, 0xD9E1–0xD9E6: cuántos bytes copiar, adónde y desde dónde, cada uno en dos bytes. Quien los deja ahí es la subrutina 20 del BASIC, que parte cada número de 16 bits en parte baja y parte alta a base de dividir entre 256, porque el intérprete no tiene operadores para hacerlo.

Lo interesante es que **ninguna de las dos rutinas actualiza esos parámetros al terminar**, y el programa lo aprovecha en los dos sitios donde importa.

El primero es el scroll vertical. No hay desplazamiento de ningún tipo: en cada vuelta del bucle se vuelca otra vez la ventana entera desde una dirección distinta. Mover el decorado una fila es sumarle 32 a la dirección de origen. Por eso la línea 620 solo reescribe dos bytes —los del origen— y llama a USR1: el cuánto y el adónde siguen puestos de la vuelta anterior. (La mira, por cierto, no sube ni baja: está clavada en la fila 7, y arriba y abajo mueven el decorado.)

El segundo es la panorámica de la línea 746: cuando el bandido que te dispara queda fuera de la ventana, el programa recorre el decorado hasta él reescribiendo también solo esos dos bytes del origen. Y hay un tercer sitio donde se reaprovecha el mismo origen, aunque ahí el BASIC sí vuelve a pasar por la subrutina 20: la carga de los dibujos. La pantalla se divide en tres bandas de 2048 bytes que pueden tener juegos de dibujos distintos, hasta 768 en total. Las líneas 520, 530 y 535 cambian **solo el destino** y llaman tres veces a USR1, así que suben el mismo juego de 256 dibujos a las tres bandas. Se renuncia a los 768 posibles y a cambio cualquier casilla vale en cualquier parte de la pantalla, que es justo lo que permite mover el decorado libremente.

![El decorado completo del nivel 3, LA MINA: 32 columnas por 64 filas](../imagenes/mapa3.png)

## El arranque, y por qué el programa no se puede listar

El bloque `CM1` de la cinta son 4277 bytes que se cargan en 0x83E8. Su dirección de arranque, 0x948F, cae en un recolocador de cinco instrucciones que se copia a sí mismo y a todo lo demás 1000 bytes más abajo:

    LD HL,0x83E8 / LD DE,0x8000 / LD BC,0x10B5 / LDIR / JP 0x9088

Carga en 0x83E8 y no directamente en 0x8000 porque mientras el juego se está cargando quien manda es el cargador de la cinta, que es a su vez un programa BASIC y vive precisamente a partir de 0x8001: cargar encima sería pisar el programa que está ejecutando el `BLOAD`.

Ya en su sitio, el arranque de 0x9088 hace tres cosas: copia cinco bytes sobre el principio del programa, apunta VARTAB (0xF6C2, el puntero donde el intérprete construye su tabla de variables) a 0x8F60, y salta a 0x73AC, la rutina del intérprete que empieza a ejecutar.

Esos cinco bytes son una protección. En la cinta, **la primera línea del programa viene numerada 65535**, por encima del máximo que MSX-BASIC admite, y el arranque le escribe encima el número 4. Sin ese parche el juego no funciona: comprobado en el emulador saltando por detrás de la copia, el `GOSUB 20` de la línea 520 aborta con *Undefined line number in 520*. Quien se lleve el bloque y lo cargue por su cuenta no obtiene un programa listable, sino uno roto.

Y lo primero que hace esa línea recién numerada remata la idea: `POKE &HFBB1,1`. Esa posición es BASROM, con la que el sistema decide si CTRL+STOP puede interrumpir. Puesta a 1, el juego ya no se puede parar; y si no se puede parar, no se puede listar.

## La música, y por qué solo suena en la portada

El reproductor es mínimo: un byte por canal y por paso, sin duraciones ni envolventes. `0xFE` significa volver al principio, `0xFF` silencio, y cualquier otro valor es un número de nota que se dobla y sirve de índice en una tabla de 96 periodos de 16 bits. USR5 inicializa; **USR6 toca un solo paso** y vuelve. Escribe en el chip de sonido por sus puertos, 0xA0 y 0xA1, en seis bytes, sin pasar por la rutina del sistema.

Como no hay ningún enganche a la interrupción del vídeo, la música solo avanza si alguien llama a USR6 continuamente, y el único sitio del programa que lo hace es la línea 582, dentro del bucle de la portada. Todo el control de tempo de la canción es el `FOR H%=1TO35` que va justo detrás. En cuanto empieza la partida nadie vuelve a llamar, y a partir de ahí el sonido sale de los `PLAY` y `SOUND` del propio BASIC.

Un detalle de la tabla de periodos: la primera entrada es un DO1 clavado (32,71 Hz), pero el reproductor no arranca por ahí. Su base está en la séptima entrada, así que la nota 0 de las melodías es un FA#1 y las seis primeras no se alcanzan nunca.

## Los textos raros del listado

Leyendo el programa uno se encuentra cosas como `DATA "0000EL0CA[ON"` o `A$="00MUSICA^GOMINOLAS"`. No son erratas. El juego usa su propio juego de caracteres, y el dibujo de una letra es **su código ASCII más 60**. De ahí que el `'0'` (48 + 60 = 108) sea el hueco en blanco y haga de espacio, el `'['` sea la eñe, el `'^'` los dos puntos y el `'_'` la admiración. Las letras `j`, `k` y `l` de la línea 2010 tampoco son letras: son los dibujos de la bala y las dos mitades del icono de bandido con que se repone el marcador. Los dígitos van por su cuenta, con el dibujo 156 más la cifra.
