# =============================================================================
# COLT 36 - Topo Soft, 1987 - MSX
# El juego, linea a linea
# =============================================================================
#
# Esto es el programa completo de Colt 36, tal y como esta grabado en la cinta,
# con explicaciones intercaladas. Las lineas que empiezan por '#' son nuestras;
# todo lo demas es del juego, byte a byte. Que sea byte a byte no es una forma
# de hablar: 'make' vuelve a tokenizar este fichero y comprueba que sale
# exactamente el binario de la cinta, asi que si un comentario dijera algo que
# el programa no hace, el programa seguiria estando aqui entero para desmentirlo.
#
# COLT 36 ESTA ESCRITO EN BASIC. No es lo que uno espera de un juego comercial
# de 1987, pero es asi: son 63 lineas de MSX-BASIC. Lo que hace que funcione es
# el reparto del trabajo. El BASIC lleva la logica -donde esta la mira, cuantas
# balas quedan, que diana toca ahora- y todo lo que tiene que ir rapido lo hacen
# cuatro rutinas en codigo maquina que el programa llama con USR. La mas
# importante vuelca un trozo de memoria a la pantalla de golpe: es la que hace
# el scroll, y en BASIC puro no habria sido posible.
#
# El programa se apoya en un truco que conviene entender antes de leerlo. En vez
# de dibujar con instrucciones graficas, el juego trata la pantalla como un
# tablero de 32x24 casillas y trabaja sobre una COPIA de ese tablero en memoria
# (a partir de 0xDA00). Disparar es mirar que numero de casilla hay bajo la mira;
# acertar es cambiar ese numero por otro. Luego la rutina en codigo maquina copia
# el trozo que toca a la pantalla. Por eso casi todo el juego son PEEK y POKE
# sobre direcciones, y no hay una sola instruccion de dibujo.
#
# DOS COSAS QUE NO SON LO QUE PARECEN, Y SIN LAS CUALES EL LISTADO NO SE ENTIENDE
#
# La primera: la mira NO sube ni baja. Esta clavada en la fila 7 de la pantalla
# (el sprite va siempre a y=52). Cuando mueves el mando arriba y abajo lo que se
# mueve es el DECORADO, y ni siquiera se desplaza: en cada vuelta del bucle se
# vuelca otra vez la ventana entera de 512 bytes a la pantalla desde una
# direccion distinta. Izquierda y derecha si mueven la mira.
#
# La segunda: los bandidos no son sprites. Son bloques de dos por dos casillas
# que el propio BASIC va escribiendo con POKE en el tablero de memoria segun un
# contador de fase. Los unicos sprites que hay son la mira, el fogonazo del
# disparo, y la mosca y los ojos de las dos caras que salen en pantalla.
#
# COMO SE LEEN LAS DIRECCIONES DE PANTALLA
# La tabla de casillas de la pantalla empieza en la direccion 6144 de la memoria
# de video. Asi que un VPOKE 6727 cae en:
#     6727 - 6144 = 583   ->   fila 583\32 = 18, columna 583 MOD 32 = 7
# Las filas 0 a 15 son la zona de juego, por donde se mueve el decorado, y las
# 16 a 23 el marcador de abajo, que se queda fijo.
#
# LOS TEXTOS
# El juego usa su propio juego de caracteres, corrido 60 posiciones respecto al
# ASCII (ver la subrutina 15). Como consecuencia, dentro de los textos de este
# programa el ESPACIO se escribe con un '0', y algunos signos hacen de letra:
# el '[' es la enye de "CA[ON" y el '^' es un adorno. No son erratas.
#
# LAS VARIABLES
# Son 28, y esta lista esta sacada de la tabla del propio interprete con el
# juego corriendo, no leyendo el listado.
#
# Ojo con HL, DE y BC: aqui NO son registros del procesador, sino variables
# BASIC normales y corrientes que se llaman asi, y ademas de doble precision.
# Se usan para pasarle los tres parametros a la rutina de volcado (subrutina 20).
#
#     N%   nivel en curso, 1 a 4. De 11 a 15 significa "pantalla final", y el
#          valor concreto elige la calificacion
#     V%   vidas que quedan, 3 a 0
#     PT%  puntuacion. En pantalla se lee multiplicada por cien (ver la 10)
#     M%   balas que quedan, de 40 a 0. Se reponen por NIVEL, no por vida
#     TI%  bandidos abatidos en el nivel, de 0 a 16
#     X%   posicion horizontal de la mira, en pixeles. Va de 8 en 8 y siempre
#          vale 4 modulo 8; puede llegar a -4
#     HL   casilla del tablero por la que empieza lo que se esta viendo. Moverla
#          de 32 en 32 es todo el scroll vertical del juego
#     BA%  direccion de la casilla donde esta saliendo el bandido
#     MD%  modelo de bandido, de 1 a 4 (que dibujo sale)
#     PS%  fase del bandido: cuenta desde 188..207 hasta 256, y en los multiplos
#          de ocho a partir de 200 dispara una accion. Ver la linea 640
#     PI%  numero de casilla que hay bajo la mira al disparar
#     K%   puntero a la ficha del bandido elegido, dentro de la tabla de 0xD900
#     C%   numero de dibujo del bloque del bandido
#     E%, I%  posicion de la mosca de la portada
#     S%   lectura del mando; T% la del boton en este fotograma y TR% la del
#          anterior, que es el antirrebote del disparo
#     A$   texto a escribir
#     G%, G, D, D%, Q, H%, J%  auxiliares de un solo uso (contadores de los FOR
#          de espera, indices, y los valores que devuelven los USR y no se usan)
#
# Y una que NO existe: la T del "TR%=T" de la linea 630. Es una errata por T%.
# MSX-BASIC, al LEER una variable que no existe, devuelve cero sin crearla, asi
# que ahi lo que se asigna es un cero. Comprobado: en la tabla de variables del
# juego en marcha no hay ninguna entrada llamada T.
#
# =============================================================================

# -----------------------------------------------------------------------------
# ARRANQUE
# -----------------------------------------------------------------------------
# Esta linea viene grabada en la cinta con el numero 65535, y los 45 bytes de
# codigo maquina que arrancan el interprete le escriben encima el numero 4 (ver
# src/colt36_arranque.asm). El motivo es que 65535 esta por encima del mayor
# numero de linea que MSX-BASIC admite, asi que el programa tal y como se graba
# NO se puede ejecutar: hace falta pasar por el arranque.
#
# Y lo que hace la linea remata la idea: 0xFBB1 es BASROM, la posicion con la
# que el sistema decide si CTRL+STOP puede interrumpir. Poniendola a 1 el juego
# deja de poder pararse, y con ello de poder listarse.
#
# Aqui va con el 65535 porque es lo que hay en la cinta. En memoria, cuando el
# programa corre, esta linea es la 4.
65535 POKE &HFBB1,1
9 GOTO 500

# -----------------------------------------------------------------------------
# SUBRUTINAS
# -----------------------------------------------------------------------------
# 10 - Escribe la puntuacion en el marcador.
# Va sacando las cifras de PT% de mil en mil: divide, escribe la parte entera,
# se queda con el resto y multiplica por diez para la siguiente. Los cuatro
# digitos van a las casillas 6849 a 6852, o sea fila 22, columnas 1 a 4. El +156
# es lo que convierte un digito en su dibujo: el '0' del juego es el patron 156.
#
# LA PUNTUACION SE ENSENA MULTIPLICADA POR CIEN. El marcador viene dibujado con
# SEIS ceros (fila 22, columnas 1 a 6) y esta subrutina solo escribe los cuatro
# primeros: las columnas 5 y 6 se quedan con el cero que traen de fabrica. Asi
# que abatir un bandido suma 20 a PT% y en pantalla se lee 2000.
#
# Que la cuenta salga sin errores de redondeo no es casualidad: los decimales
# del MSX se guardan en BCD, y el argumento de VPOKE trunca, asi que con
# PT%=1900 sale 157.9, que trunca al patron 157 (el '1'), y el resto queda en
# 0.9 exacto para la cifra siguiente.
10 Q=PT%/1000:VPOKE6849,Q+156:Q=10*(Q-Q\1):VPOKE6850,Q+156:Q=10*(Q-Q\1):VPOKE6851,Q+156:Q=10*(Q-Q\1):VPOKE6852,Q+156:RETURN

# 15 - Escribe el texto A$ en la pantalla, empezando en la casilla HL.
# El 6143 es 6144-1, porque el bucle empieza en 1 y no en 0, de modo que HL es
# el numero de casilla de la primera letra. Los sitios donde escribe:
#     HL=132 -> fila  4, col  4    HL=200 -> fila  6, col  8
#     HL=237 -> fila  7, col 13    HL=261 -> fila  8, col  5
#     HL=329 -> fila 10, col  9    HL=599 -> fila 18, col 23
#     HL=609 -> fila 19, col  1    HL=631 -> fila 19, col 23
#     HL=718 -> fila 22, col 14
# El +60 es el desplazamiento del juego de caracteres propio del juego respecto
# al ASCII, y de ahi salen las rarezas de los textos: el '0' (48+60=108) es el
# hueco en blanco y hace de espacio, el '[' (91+60=151) es la enye de "CA[ON",
# el '^' (94+60=154) son los dos puntos y el '_' (95+60=155) la admiracion de
# "SHERIFF__". Y las letras 'j', 'k' y 'l' de la linea 2010 son los dibujos de
# la bala y las dos mitades del icono de bandido.
#
# Ojo: los digitos NO pasan por aqui. Van sueltos, con el 156+cifra que usan las
# lineas 10, 31, 597 y 749.
15 FORG%=1TOLEN(A$):VPOKE(HL+G%+6143),ASC(MID$(A$,G%,1))+60:NEXT:RETURN

# 20 - Deja los parametros donde la rutina de volcado los va a buscar.
# La rutina USR1 no recibe argumentos: lee de tres parejas de posiciones fijas.
#     0xD9E1/0xD9E2  BC, cuantos bytes copiar
#     0xD9E3/0xD9E4  DE, a que direccion de la pantalla
#     0xD9E5/0xD9E6  HL, desde que direccion de la memoria
# Cada pareja se guarda como parte baja y parte alta, y por eso hacen falta esas
# divisiones entre 256: es la forma de partir un numero de 16 bits en dos bytes
# sin tener operadores para hacerlo.
20 POKE &HD9E2,INT(BC/256):POKE &HD9E1,BC-(INT(BC/256))*256:POKE &HD9E4,INT(DE/256):POKE &HD9E3,DE-(INT(DE/256))*256:POKE &HD9E6,INT(HL/256):POKE &HD9E5,HL-(INT(HL/256))*256:RETURN

# -----------------------------------------------------------------------------
# PANTALLA DE NIVEL Y PANTALLA FINAL
# -----------------------------------------------------------------------------
# 30 - Esconde los cinco sprites (mandandolos a la fila 200, fuera de la vista) y
# recarga sus dibujos desde 0xD600. Luego cae en la 31.
30 FORD=0 TO4:PUTSPRITE D,(0,200),8,0:NEXT:HL=&HD600+65536!:BC=32:FOR DE=6144 TO 6656STEP 32:GOSUB 20:D=USR1(0):NEXT

# 31 - Si N% es 5 o menos estamos entre niveles: se anuncia "NIVEL n" y suena la
# musica corta. Si es mayor, el juego ha terminado y se va a la 32.
31 IFN%>5THEN32:ELSEHL=237:A$="NIVEL00^":GOSUB 15:VPOKE 6387,N%+156:PLAY"S1L8M5000O5CDEFF16F16CC16C16F3O4L4","S1L8M5000O3CDEFF16F16CC16C16F3O4L4":GOTO 33

# 32 - Fin de partida: musica larga y los dos rotulos de despedida.
32 PLAY"S1L8M5000O5CDR64EFR64FFR64FER64CER64F2O4F1","S1L8M5000O2CDR64EFR64FFR64FER64CER64F2O1F1":A$="JUEGO0TERMINADO":HL=200:GOSUB15:A$="CALIFICACION0GENERAL^":HL=261:GOSUB15:FORG=1TO1500:NEXT

# 33 - Saca de la lista de la linea 3000 el rotulo que toca -el nombre del nivel
# si estamos empezando uno, o la calificacion final si se acabo la partida- y lo
# escribe. El N%=N%+10*(N%>10) es la forma de restar 10 cuando N% viene marcado
# como "pantalla final": en BASIC una comparacion cierta vale -1, asi que eso es
# N% - 10 si N%>10, y N% tal cual si no. Despues carga el decorado del nivel:
# lleva 2048 bytes desde 0xA000 (mas 2048 por cada nivel ya pasado) al tablero
# de trabajo en 0xDA00.
#
# Y aqui hay un fallo, de los que no se ven porque no molestan. Cuando se
# completa el juego entero, la 2000 pone N%=15; al pasar por aqui, el ajuste lo
# deja en 5, y entonces esta misma linea pide el "nivel 5", que no existe:
# 0xA000 + 2048*4 = 0xC000, que no es un decorado sino la tabla de dibujos. O
# sea que copia 2048 bytes de la fuente de letras al tablero. No se nota porque
# lo siguiente es volver a la portada y el tablero se recarga antes de jugar.
33 RESTORE3000:FORG%=1TON%:READ A$:NEXT:HL=329:GOSUB15:N%=N%+10*(N%>10):FORG=1TO1500:NEXT:HL=&HA000+2048*(N%-1)+65536!:DE=&HDA00+65536!:BC=2048:GOSUB20:D=USR2(0):RETURN

# -----------------------------------------------------------------------------
# EL DISPARO
# -----------------------------------------------------------------------------
# 300 - Si no quedan balas no pasa nada. Si quedan, suena el disparo (ruido del
# canal C del chip de sonido) y se dibuja el fogonazo con dos sprites encima de
# la mira.
300 IF M%=0THENRETURN :ELSESOUND 6,210:SOUND 7,220:SOUND12,40:SOUND8,0:SOUND9,0:SOUND10,16:SOUND13,1:PUTSPRITE 3,(X%,52),11,5:PUTSPRITE 4,(X%,52),8,4:FORG=1 TO30:NEXT:PUTSPRITE 4,(X%,52),8,6

# 303 - Gasta una bala y apaga la marca que le corresponde en el marcador. Las 40
# balas se muestran con 10 casillas, o sea cuatro balas por casilla: por eso el
# (39-M%)\4.
303 M%=M%-1:VPOKE6753+(39-M%)\4,0

# 305 - Aqui esta toda la deteccion de impactos del juego, y es UN SOLO PEEK.
# HL es la casilla de arriba a la izquierda de lo que se esta viendo, y como la
# mira esta clavada en la fila 7 y su centro cae una casilla a la derecha de
# X%\8, la casilla apuntada es HL + 7*32 + X%\8 + 1, que es el HL+225+X%\8 de
# aqui. Si el numero es 70 o menos, ahi no hay nada que valga y se sale.
#
# Como X% arranca en 132 y se mueve de ocho en ocho, siempre vale 4 modulo 8, y
# X%\8+1 recorre las columnas 1 a 31: a la columna 0 no se puede apuntar nunca.
305 PI%=PEEK(HL+225+X%\8):IF PI%>70 THEN 320
310 PUTSPRITE 3,(0,200),0,8:PUTSPRITE 4,(0,200),0,8:RETURN

# 320 - Los numeros del 71 al 78 son decorado que se puede romper (botellas,
# cristales). Del 174 en adelante son las dianas.
320 IF PI%>78 THEN 340

# 325 - Decorado roto: se sustituye la casilla por la version rota, que esta 8
# numeros mas alla, y se suman tantos puntos como valga el objeto (de 1 a 8,
# segun cual sea). Como la version rota pasa de 78, no se puede volver a cobrar
# por el mismo objeto. El destrozo se queda en el tablero de memoria, o sea que
# dura hasta que se recarga el nivel: al perder una vida vuelve todo entero.
#
# Ojo al leer los mapas: los numeros 79 a 86 no salen ni una sola vez en la
# parte jugable de los cuatro decorados. Las 386 casillas donde aparecen estan
# todas en las filas que el tope del scroll no deja ver nunca.
325 POKE HL+225+X%\8,PI%+8:PT%=PT%+PI%-70:GOSUB10:IF PI%>73 THEN PLAY"S1M5000O3C16R30G16","S1M5000O3C16R30G16":GOTO 310
327 PLAY"S1O7B4O4","S1O6C4O4":GOTO310

# 340 - Filtro del bandido. Las tres condiciones estan bien puestas y cada una
# tapa un agujero: el 174 es el primer numero de bloque de bandido (sale de la
# cuenta de la linea 700 con el primer modelo); el 255 hay que descartarlo
# aparte porque es la casilla VACIA del decorado, la mas frecuente del mapa, y
# sin esa excepcion se cobrarian 20 puntos disparando al aire; y el PS%>239
# impide cobrar dos veces el mismo bandido mientras cae y se borra, porque en
# esas dos fases sus casillas siguen pasando de 174.
340 IF PI%<174 OR PI%=255 OR PS%>239THEN 310

# 350 - Bandido abatido: 20 puntos (2000 en el marcador), se le manda a su fase
# de retirada (PS%=240, con lo que se salta la 232, que es en la que dispara) y
# se apaga una marca del contador. Los 16 bandidos se cuentan con 8 casillas en
# dos filas, o sea a dos por casilla, y de ahi el dividir entre dos y el alternar
# segun TI% sea par o impar. Que la cuenta case depende de que el argumento de
# VPOKE trunque: con TI% par la direccion sale acabada en .5 y cae en la misma
# casilla que empezo el impar anterior, que es justo lo que se quiere.
350 PT%=PT%+20:GOSUB10:PS%=240:TI%=TI%+1:VPOKE 6743+(TI%-1)/2,0-167*(TI%\2<>TI%/2):VPOKE 6775+(TI%-1)/2,169+(TI%\2<>TI%/2):PLAY"S1M5000O5C16F16A16O6C10O5A","S1O3C16F16A16O4C10O3A":GOTO 310

# -----------------------------------------------------------------------------
# ARRANQUE DE VERDAD: PREPARAR LA PANTALLA Y LA PORTADA
# -----------------------------------------------------------------------------
# 500 - CLEAR200,39824 baja el techo de la memoria del BASIC a 0x9B90, que es
# justo debajo de donde esta cargado el bloque de graficos y rutinas: asi el
# interprete no se lo pisa. Luego declara las seis rutinas en codigo maquina.
# USR3 y USR4 no son del juego: 0x41 y 0x44 son dos llamadas del sistema para
# apagar y encender la pantalla, y se usan para que no se vea el dibujado.
500 CLEAR200,39824!:COLOR 15,4,1:SCREEN2,2,0:DEFUSR1=&HE300:DEFUSR2=&HE313:DEFUSR3=&H41:DEFUSR4=&H44:DEFUSR5=&H9B91:DEFUSR6=&H9BBB

# 510 a 570 - Con la pantalla apagada, se cargan los dibujos. La pantalla de este
# modo se divide en tres bandas de 2048 bytes, y hay que llenar las tres tanto de
# formas como de colores: de ahi los seis volcados de 2048. Los ultimos 256 bytes
# son los dibujos de los sprites.
510 D%=USR3(0):BC=2048:HL=&HC000+65536!:DE=0
520 GOSUB20:D%=USR1(0)
530 DE=2048:GOSUB20:D%=USR1(0)
535 DE=4096:GOSUB 20:D%=USR1(0)
540 HL=&HC800+65536!:DE=8192
550 GOSUB20:D%=USR1(0)
560 DE=10240:GOSUB20:D%=USR1(0)
565 DE=12288:GOSUB 20:D%=USR1(0)
570 DE=14336:HL=&HD800+65536!:BC=256:GOSUB20:D%=USR1(0)

# 572 - Pone el tablero de la portada: 768 bytes desde 0xD000, que son las 24
# filas de la pantalla de titulo.
572 D%=USR3(0):BC=768:DE=6144:HL=&HD000+65536!:GOSUB20:D=USR1(0)

# 575 - Anade los dos rotulos que no vienen en el dibujo y enciende la pantalla.
# El 132 es fila 4, columna 4; el 718 es fila 22, columna 14.
575 HL=132:A$="TOPO0SOFTWARE":GOSUB 15:HL=718:A$="00MUSICA^GOMINOLAS":GOSUB15:D=USR4(0)

# 580 a 592 - El bucle de la portada, del que no se sale hasta que se dispara.
# Lo que se mueve con el mando NO es una mira: es la mosca que revolotea sobre
# el vaquero del dibujo, dentro de los limites E% de 10 a 54 e I% de 119 a 165.
# USR5 arranca la musica y USR6 la va sirviendo un paso por vuelta: hay que
# llamarla continuamente, y por eso esta dentro del bucle. El FOR H%=1TO35 que
# la acompana es todo el control de tempo que tiene la cancion. Como USR6 solo
# se llama aqui, esta es la unica musica del juego que suena por esta via:
# durante la partida todo el sonido sale de los PLAY y SOUND del propio BASIC.
580 E%=40:I%=125:BEEP
581 D%=USR5(0)
582 J%=USR6(0):FORH%=1TO35:NEXT
585 S%=STICK(0)ORSTICK(1):E%=E%-2*((S%=2ORS%=3ORS%=4)ANDE%<53)+2*((S%=6ORS%=7ORS%=8)ANDE%>10):I%=I%-2*((S%=4ORS%=5ORS%=6)ANDI%<164)+2*((S%=8ORS%=1ORS%=2)ANDI%>119)

# 590 - Dibuja la mosca y, ademas, los OJOS del vaquero, que la siguen. La
# cuenta (31-(31-E%-8)/10, 143-(143-I%)/4) es un seguimiento amortiguado: la
# mosca recorre 44 pixeles a lo ancho y los ojos solo 5, asi que la miran sin
# salirse de la cara. El D%=3-4*(D%=3) alterna D% entre 3 y 7 en cada vuelta, y
# como esos son dos dibujos de la mosca con el ala en distinta posicion, lo que
# se consigue es que aletee.
590 D%=3-4*(D%=3):PUTSPRITE0,(31-(31-E%-8)/10,143-(143-I%)/4),5,2:PUTSPRITE1,(E%,I%),15,D%:IF (STRIG(0)ORSTRIG(1))=-1THEN595
592 GOTO 582

# -----------------------------------------------------------------------------
# COMIENZA LA PARTIDA
# -----------------------------------------------------------------------------
# 595 - Pone el marcador de abajo: 256 bytes desde 0xD300 a las ocho ultimas
# filas de la pantalla.
595 BEEP:DE=6656:BC=256:HL=&HD300+65536!:GOSUB20:D=USR1(0)

# 597 - Primer nivel, tres vidas, cero puntos, y a la pantalla de "NIVEL 1".
597 N%=1:V%=3:VPOKE6727,156+V%:PT%=0:GOSUB30

# 599 - Cada nivel empieza con 40 balas y ninguna diana acertada.
599 M%=40:TI%=0

# 600 - Deja puestos los tres parametros de la rutina de volcado para la ventana
# del nivel: 512 bytes, a la tabla de la pantalla, desde la fila 8*N% del mapa.
# Aqui todavia no se vuelca nada; el primer volcado es el de la linea 620.
600 HL=&HDA00+65536!+256*N%:BC=512:DE=6144:GOSUB20

# 605 - Mira en el centro, ninguna diana en juego todavia (PS%=256 es el valor
# que en la linea 640 hace que se elija una nueva).
605 X%=132:BA%=&HDA00+224:MD%=1:PS%=256

# -----------------------------------------------------------------------------
# EL BUCLE DE JUEGO. Da una vuelta por fotograma: mueve el decorado, mueve la
# mira, mira si se dispara, y avanza la fase de la diana.
# -----------------------------------------------------------------------------
# 610 - El "scroll". Subir o bajar el decorado es mover HL una fila (32 casillas)
# arriba o abajo, con topes para no salirse del tablero. No hay desplazamiento
# de verdad: la 620 vuelve a volcar la ventana entera de 512 bytes desde la nueva
# direccion, sesenta veces por segundo si hace falta, y eso es todo el efecto.
#
# El tope de abajo sale de &HE200-512*(4-N%)+512*(N%=4) y da 0xDC00 para el
# nivel 1, 0xDE00 para el 2 y 0xE000 para el 3 y el 4 (el ultimo termino
# aprovecha que lo cierto vale -1). Traducido: el nivel 1 solo usa 32 de las 64
# filas de su mapa, el 2 usa 48, y el 3 y el 4 las 64 enteras. Los niveles
# crecen a lo alto conforme avanzas, y el 3 y el 4 miden ya lo mismo.
610 S%=STICK(0)ORSTICK(1):HL=HL+32*((S%=1ORS%=2ORS%=8) AND HL>&HDA00+65536!)-32*((S%=5ORS%=4ORS%=6)AND HL<&HE200-512*(4-N%)+512*(N%=4)+65536!)

# 620 - Vuelca el trozo de tablero que toca. Aqui solo se cambia HL, porque el
# cuanto y el adonde siguen siendo los de la vuelta anterior.
620 POKE&HD9E6,INT(HL/256):POKE&HD9E5,HL-(INT(HL/256))*256:D=USR1(0)

# 625 - Mueve la mira a izquierda y derecha y la dibuja con dos sprites
# superpuestos, uno blanco y otro negro, para que tenga perfil. El tercero es un
# detalle bonito: son los OJOS de la cara que preside el marcador, colocados en
# (127, 151, 146 o 156) segun el bandido este por debajo, dentro o por encima de
# lo que se ve. O sea que la cara mira hacia donde esta el peligro, y sirve de
# pista para saber en que direccion hay que buscarlo.
#
# Detalle: el tope de la izquierda es X%>0 y el paso es 8 desde 4, asi que X%
# puede acabar en -4 y la mira se sale media casilla por el borde izquierdo.
625 X%=X%-8*((S%=2 ORS%=3ORS%=4)ANDX%<240)+8*((S%=6ORS%=7ORS%=8)ANDX%>0):PUTSPRITE0,(X%,52),15,1:PUTSPRITE1,(X%,52),1,0:PUTSPRITE2,(127,151-5*(BA%>HL+320-65536!)+5*(BA%<HL+124-65536!)),4,2

# 630 - Dispara solo en el flanco: hace falta que el boton este pulsado ahora y
# no lo estuviera en la vuelta anterior, para que mantenerlo apretado no vacie el
# cargador. Ojo al TR%=T: la variable que guarda el estado se llama TR% y la que
# se le asigna es T, sin el %, que no se usa en ninguna otra parte del programa y
# por tanto vale cero. Funciona igual porque la 635 vuelve a asignar TR%
# inmediatamente, pero la intencion era claramente escribir T%.
630 T%=STRIG(0)OR STRIG(1):IFT%=-1 ANDTR%=0 THEN TR%=T:GOSUB300
635 TR%=T%

# 637 y 640 - El reloj del bandido, que es la maquina de estados del juego. PS%
# sube de uno en uno en cada vuelta (linea 650) y aqui solo se actua cuando pasa
# de 200 y es multiplo de ocho; el PS%\8<>PS%/8 es la forma de preguntar "es
# multiplo de ocho", comparando la division entera con la de verdad.
#
# El reparto de la 640, con el valor de PS% que le corresponde a cada uno:
#     200 -> indice 0: ON no salta y se sigue por la 650. No pasa nada
#     208 -> 690  suena el aviso... y CAE en la 700, porque la 690 no lleva
#                 GOTO. Por eso el aviso y la aparicion son el mismo fotograma
#     216 -> 700  se anima
#     224 -> 700  se anima
#     232 -> 740  DISPARA: es la fase en la que te quita una vida
#     240 -> 700  pose de caida (aqui llega si le has dado, por la linea 350)
#     248 -> 720  se borra
#     256 -> 760  se acabo su turno: a elegir otro
# O sea que tienes desde PS%=209 hasta PS%=232 para dispararle: veinticuatro
# vueltas. Llega hasta el 232 inclusive porque el disparo (630) se procesa ANTES
# del reparto dentro de la misma vuelta, asi que acertar justo en el fotograma
# en que le toca disparar todavia te salva.
637 IF PS%<200 OR PS%\8<>PS%/8THEN 650
640 ON (PS%-200)\8 GOTO 690,700,700,740,700,720,760
650 PS%=PS%+1:GOTO 610

# 690 - El aviso: cuatro notas secas antes del disparo. No lleva GOTO, asi que
# sigue por la 700 y pinta el bandido en el mismo fotograma.
690 PLAY"V15O7C16R16C16R16C16R16C16O4"

# 700 - Dibuja el bandido: cuatro casillas en cuadro, con el numero de dibujo
# sacado del modelo (MD%, de 1 a 4) y del momento de la animacion. Cada modelo
# tiene CINCO fotogramas de 2x2, o sea veinte casillas: el modelo 1 ocupa los
# numeros 174 a 193, el 2 los 194 a 213, el 3 los 214 a 233 y el 4 los 234 a 253.
# Tres fotogramas son de asomar (los que calcula esta linea), uno es el de
# disparar (lo pone la 740) y el ultimo el de caer abatido (lo pone la 350).
700 C%=150+20*MD%+((((PS%-200)/2)\4)*4):POKEBA%,C%:POKEBA%+1,C%+1:POKEBA%+32,C%+2:POKEBA%+33,C%+3:GOTO 650

# 720 - Lo borra: las cuatro casillas a cero.
720 POKEBA%,0:POKEBA%+1,0:POKEBA%+32,0:POKEBA%+33,0:GOTO 650

# 730 - Esta linea no la alcanza nadie. El unico reparto que podria llamarla es
# el ON de la 640, y ahi no esta; en todo el listado no hay ningun GOTO, GOSUB
# ni THEN que apunte al 730, y la linea de antes acaba en GOTO, asi que tampoco
# se llega por orden. Es un resto de una version anterior que se quedo grabado.
730 PLAY"ACA":GOTO 610

# 740 a 749 - Te han disparado. Se dibuja el bandido en su pose de disparo,
# suena el tiro, y si donde esta no se ve en pantalla, la 746 hace una
# panoramica: recorre el decorado de fila en fila hasta el, para ensenarte de
# donde vino el tiro. El paso del FOR sale +32 o -32 segun este por debajo o por
# encima, que es lo que hace el 32+64*(...) aprovechando que lo cierto vale -1.
# Luego se descuenta una vida; si era la ultima, N% se marca con +10 para que la
# pantalla de nivel saque la calificacion final.
#
# OJO, y esto se nota jugando: la 749 vuelve a la 600, no a la 599. O sea que al
# perder una vida NO se reponen las balas. Los 40 tiros son por NIVEL, no por
# vida. Si te quedas sin ellos, la 300 se limita a hacer RETURN sin sonar
# siquiera, ya no puedes abatir a nadie, y las vidas que te queden se van una
# detras de otra sin que puedas hacer nada.
740 C%=150+20*MD%+16:POKEBA%,C%:POKEBA%+1,C%+1:POKEBA%+32,C%+2:POKEBA%+33,C%+3:GOSUB20:D%=USR1(0)
745 SOUND 6,210:SOUND 7,220:SOUND12,40:SOUND8,0:SOUND9,0:SOUND10,16:SOUND13,1:FORD%=0TO1000:NEXT:IF(BA%+65312!>HL-192)AND(BA%+65312!<HL+192)THEN747
746 FORHL=HLTOBA%+65344!STEP32+64*(BA%+65312!<HL):FORD%=0TO40:NEXT:POKE&HD9E6,INT(HL/256):POKE&HD9E5,HL-(INT(HL/256))*256:D=USR1(0):NEXT
747 FORG=1TO1000:NEXT:V%=V%-1:IF V%=0THENVPOKE6727,156:N%=N%+10:GOSUB30:GOTO 572
749 VPOKE 6727,V%+156:GOSUB30:GOTO600

# 760 - Toca bandido nuevo. Si ya van 16, el nivel se ha terminado. Si no, se
# elige uno al azar de entre los diez escondites que trae el nivel: son grupos de
# cuatro bytes a partir de 0xD900, cuarenta bytes por nivel, y cada grupo dice
# fila, columna, modelo y fase inicial. Esa fase inicial va de 188 a 207, o sea
# que tarda entre 1 y 20 vueltas en asomar, y por eso no salen todos al mismo
# ritmo. RND(-TIME) resiembra con el reloj del sistema en cada eleccion, asi que
# el mismo escondite puede repetirse dos veces seguidas.
760 IF TI%=16THEN 2000 :ELSEK%=INT(RND(-TIME)*10)*4+&HD900+40*(N%-1):BA%=&HDA00+PEEK(K%+0)*32+PEEK(K%+1):MD%=PEEK(K%+2):PS%=PEEK(K%+3):GOTO 650

# -----------------------------------------------------------------------------
# NIVEL SUPERADO
# -----------------------------------------------------------------------------
# 2000 - Siguiente nivel. Si ya no hay mas (eran cuatro), se marca N% para la
# pantalla final y se vuelve a la portada.
2000 N%=N%+1:IF N%=5THENN%=15:GOSUB30:GOTO 572
2005 PLAY"S1L8M5000O5CDR64EFR64FFR64FER64CER64F2O4F1","S1L8M5000O2CDR64EFR64FFR64FER64CER64F2O1F1":FORG=1TO2600:NEXT

# 2010 - Limpia el marcador para el nivel siguiente: apaga la casilla del nivel
# que se acaba de pasar y vuelve a pintar las 40 balas y las 16 dianas. Las
# letras 'j', 'k' y 'l' no son letras: con el desplazamiento de 60 del juego de
# caracteres son los dibujos de bala y de diana sin gastar.
2010 GOSUB30:D%=6835+2*N%:VPOKED%,0:VPOKED%+1,0:VPOKED%+32,0:VPOKED%+33,0:A$="jjjjjjjjjj":HL=609:GOSUB15:A$="kkkkkkkk":HL=599:GOSUB15:A$="llllllll":HL=631:GOSUB15:GOTO 599

# -----------------------------------------------------------------------------
# LOS ROTULOS
# -----------------------------------------------------------------------------
# Los cuatro primeros son los nombres de los niveles y los cinco ultimos las
# calificaciones finales, de peor a mejor. Los seis huecos del medio estan para
# que la cuenta cuadre: la linea 33 lee N% elementos de esta lista, y como la
# calificacion se pide con N% valiendo 11 o mas, los huecos son lo que hace que
# el undecimo elemento sea la primera calificacion. Recuerdese que el '0' es el
# espacio y el '[' la enye.
3000 DATA "000EL0ALMACEN","0000EL0CA[ON","0000LA0MINA","0000EL0SALOON","","","","","","","00CHAPUCERO","REGULARCILLO","000BUENO","00MUY0BUENO","00SHERIFF__"
