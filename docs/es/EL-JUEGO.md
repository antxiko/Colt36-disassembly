# El juego

COLT 36 es una galería de tiro ambientada en el oeste. Cuatro escenarios —**EL ALMACÉN**, **EL CAÑÓN**, **LA MINA** y **EL SALOON**—, tres vidas, cuarenta balas por nivel y dieciséis bandidos que abatir en cada uno antes de pasar al siguiente. Al final, según hasta dónde hayas llegado, el juego te califica: CHAPUCERO, REGULARCILLO, BUENO, MUY BUENO o SHERIFF!!

![La pantalla de título](../imagenes/portada.png)

La portada no es una pantalla de espera cualquiera. Lo que se mueve con el mando es una mosca que revolotea sobre el vaquero del dibujo, y los ojos del vaquero la siguen con un seguimiento amortiguado: la mosca recorre 44 píxeles a lo ancho y los ojos solo cinco, así que la miran sin desorbitarse. Se dispara y empieza la partida. El programa lee a la vez el teclado y el mando (`STICK(0) OR STICK(1)`, `STRIG(0) OR STRIG(1)`), de modo que sirve cualquiera de los dos.

## La mecánica no es la que parece

Aquí conviene entender tres cosas antes de mirar nada más, porque ninguna de las tres es lo que uno supone al jugar.

**La mira no sube ni baja.** Está clavada en la fila 7 de la pantalla: su sprite —un patrón de 16×16 píxeles que el chip de vídeo dibuja encima del fondo, aquí dos capas superpuestas para darle perfil— va siempre a y=52. Arriba y abajo mueven el **decorado**. Izquierda y derecha sí mueven la mira, de ocho en ocho píxeles.

**El scroll no es un desplazamiento.** El juego trata la pantalla como un tablero de 32 columnas por 24 filas y trabaja sobre una copia de ese tablero en memoria, a partir de 0xDA00. Las dieciséis filas de arriba son la zona de juego y las ocho de abajo el marcador, que no se mueve. Mover el decorado una fila es sumar o restar 32 a un puntero; y entonces, en cada vuelta del bucle, se vuelca **otra vez la ventana entera de 512 bytes** a la pantalla desde esa dirección nueva. No hay desplazamiento de píxeles en ninguna parte: hay un volcado completo por fotograma.

**Los bandidos no son sprites.** Son bloques de 2×2 casillas que el programa escribe con POKE sobre el tablero de memoria. Los únicos sprites del juego son la mira, el fogonazo del disparo, la mosca de la portada y los ojos.

## Disparar

Toda la detección de impactos del juego es **un solo PEEK**:

    PI%=PEEK(HL+225+X%\8)

`HL` es la casilla por la que empieza lo que se está viendo; el 225 son siete filas hacia abajo (7×32) más una columna a la derecha, que es donde cae el centro de la mira. Se lee el número de dibujo que hay ahí y se decide con él. Como la mira arranca en X%=132 y se mueve de ocho en ocho, siempre vale 4 módulo 8, así que se pueden apuntar las columnas 1 a 31: a la columna 0 no se llega nunca.

Si el número es 70 o menos, no hay nada que valga. Los dibujos **71 a 78** son objetos rompibles: valen de 1 a 8 puntos y se sustituyen por el dibujo ocho números más allá, que es su versión rota —y como esa versión ya pasa de 78, no se puede cobrar dos veces el mismo objeto. El destrozo vive en la copia de memoria, o sea que dura hasta que se recarga el nivel: al perder una vida, todo vuelve a estar entero. Un aviso para quien mire los mapas: los dibujos 79 a 86 no salen ni una sola vez en la parte jugable de los cuatro decorados. Las 386 casillas donde aparecen —siempre el 80 o el 84— estan todas en las filas de los mapas 1 y 2 que el tope del scroll no deja ver nunca.

Del 174 en adelante están los bandidos. El filtro tiene tres condiciones y cada una tapa un agujero distinto: hace falta que el número llegue a 174, que no sea 255 —la casilla vacía, la más frecuente del decorado, sin cuya excepción se cobrarían veinte puntos disparando al aire— y que el bandido no esté ya cayendo.

## El ciclo del bandido

Cada bandido tiene un contador de fase, PS%, que sube de uno en uno por fotograma. Solo pasa algo en los múltiplos de ocho a partir de 200:

| PS% | qué ocurre |
|---|---|
| 208 | suena el aviso **y** asoma, en el mismo fotograma |
| 216, 224 | se anima |
| 232 | **dispara y te quita una vida** |
| 240 | cae abatido (aquí solo llega si le has dado) |
| 248 | se borra |
| 256 | se acabó su turno: se elige otro |

Tienes desde PS%=209 hasta PS%=232 para acertarle: **veinticuatro vueltas**. El 232 entra porque el disparo se procesa antes que el reparto dentro de la misma vuelta, así que acertar justo en el fotograma en que le toca disparar todavía te salva.

Cada modelo de bandido tiene cinco fotogramas de 2×2, es decir veinte casillas: el modelo 1 ocupa los dibujos 174 a 193, el 2 los 194 a 213, el 3 los 214 a 233 y el 4 los 234 a 253. Tres fotogramas son de asomar, uno el de disparar y el último el de caer.

De dónde salen es una tabla en 0xD900: **diez escondites por nivel, cuatro bytes cada uno** —fila, columna, modelo y retardo de salida, este último entre 188 y 207, o sea entre 1 y 20 vueltas de espera antes de asomar—. Se elige uno al azar resembrando con el reloj del sistema, así que los dieciséis bandidos de un nivel salen de esos diez sitios y alguno se repite, a veces dos veces seguidas.

Cuando te disparan hay un detalle que se agradece: si el bandido estaba fuera de la ventana visible, el juego hace una panorámica fila a fila hasta él para enseñarte de dónde vino el tiro. Y mientras juegas, los ojos de la cara que preside el marcador miran hacia arriba, al frente o hacia abajo según el bandido esté por encima, dentro o por debajo de lo que estás viendo: son la pista para saber en qué dirección buscarlo.

## Los cuatro decorados

Los cuatro mapas están grabados como tableros de 32 columnas por 64 filas, 2048 bytes cada uno, pero **no se usan enteros**. El tope del scroll deja al nivel 1 en 32 filas y al 2 en 48; solo el 3 y el 4 gastan las 64. Los niveles crecen a lo alto conforme avanzas, y los dos últimos ya miden lo mismo.

| | nivel | filas útiles | el mapa, hasta donde llega el scroll |
|---|---|---|---|
| ![EL ALMACÉN](../imagenes/nivel1.png) | 1 EL ALMACÉN | 32 | ![](../imagenes/mapa1.png) |
| ![EL CAÑÓN](../imagenes/nivel2.png) | 2 EL CAÑÓN | 48 | ![](../imagenes/mapa2.png) |
| ![LA MINA](../imagenes/nivel3.png) | 3 LA MINA | 64 | ![](../imagenes/mapa3.png) |
| ![EL SALOON](../imagenes/nivel4.png) | 4 EL SALOON | 64 | ![](../imagenes/mapa4.png) |

## El marcador

Las vidas se escriben como una cifra. Las cuarenta balas se muestran con diez casillas, cuatro balas por casilla, y los dieciséis bandidos con ocho columnas en dos filas, a dos por columna. En las capturas se lee VIDAS:5 y seis ceros de puntuación porque así viene grabado el marcador en la cinta; en cuanto empieza la partida el programa escribe encima el 3 de las tres vidas.

Los ceros de la puntuación son seis, pero la rutina que la escribe solo pone cuatro cifras: las dos últimas columnas se quedan de adorno. Es decir que **la puntuación se enseña multiplicada por cien**. Abatir un bandido suma 20 y en pantalla se lee 2000.

El otro fallo se nota jugando: **las balas no se reponen al perder una vida**. Los cuarenta tiros son por nivel. Si te quedas sin ellos, disparar no hace nada —ni suena—, ya no puedes abatir a nadie, y las vidas que te queden se van una detrás de otra sin que puedas evitarlo.

La calificación final sale de dónde te quedaste: caer en el nivel 1 es CHAPUCERO; en el 2, REGULARCILLO; en el 3, BUENO; en el 4, MUY BUENO. Terminar los cuatro es SHERIFF!!
