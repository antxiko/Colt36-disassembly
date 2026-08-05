# Aviso legal y de atribución

## De quién es cada cosa

**El juego no es nuestro.** *Colt 36* (1987) lo publicó **Topo Soft**. El propio
programa acredita la música a **Gominolas**. Todos los derechos sobre el juego
siguen siendo de sus titulares.

**Lo que sí es nuestro** son las herramientas de este repositorio, los
comentarios del listado, el análisis y la documentación. Eso se publica bajo la
licencia que consta en `LICENSE`.

## Qué contiene este repositorio

El fichero `src/colt36.bas` es el **listado comentado** del juego: el programa
MSX-BASIC original, con explicaciones intercaladas. Los ficheros `src/*.asm` son
el desensamblado comentado de las rutinas en código máquina que lo acompañan, y
de la pantalla de carga. Se publican con ánimo de **preservación, estudio y
documentación** de un título que forma parte de la historia del software
español, y que hoy no está a la venta por ningún canal.

La imagen de cinta (`.tsx`) **no** se distribuye aquí.

Hay una excepción, y conviene explicarla porque es deliberada: `datos/misterio.bin`
son 1566 bytes tomados de la cinta, y sí están. Son los únicos que este trabajo
no ha conseguido identificar, y la razón de publicarlos es que sin ellos no se
puede discutir sobre ellos: la página de bytes muertos va justamente de eso. Son
el 4,6 % de la cinta, está medido que **no son código** —usan 60 valores de byte
distintos y no contienen un solo `CALL` ni un solo `RET`— y está demostrado a
partir del propio programa que **el juego no los enseña nunca**. No ejecutan
nada, no reconstruyen nada y no sustituyen a la cinta para ningún fin.

Las imágenes de `docs/` no son capturas de pantalla tomadas del juego: se
generan a partir de los datos del binario con las herramientas del repositorio,
como parte de la demostración de que el formato está bien entendido.

## Si eres uno de los autores

Si trabajaste en *Colt 36* o eres titular de derechos sobre el juego, y
prefieres que este material no esté publicado, **dilo y se retira sin
discusión**. La intención de este trabajo es exactamente la contraria a
perjudicaros: es dejar constancia de cómo estaba hecho.

## Sobre los créditos

Los nombres de arriba se han leído del binario del juego, no de fuentes
externas. Si la atribución real es otra —era habitual que los créditos de la
época se quedaran cortos o usaran seudónimos— se corrige encantados con
cualquier dato mejor.
