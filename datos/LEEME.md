# Los 1566 bytes sin identificar

`misterio.bin` son los únicos bytes de la cinta de *Colt 36* que este trabajo no
sabe explicar, puestos aquí para que cualquiera pueda intentarlo sin tener que
repetir el desmontaje entero ni conseguir una copia de la cinta.

    sha256  4819fc2ad2d2e6ccf7a49cf92e91b3e0af03fc9df84a96cac35c7bf66a39d5c9
    1566 bytes, en este orden:

    offset 0     1024 B   0xA400-0xA7FF   sobrante del decorado del nivel 1
    offset 1024   512 B   0xAE00-0xAFFF   sobrante del decorado del nivel 2
                                          (idéntico a 0xA600-0xA7FF)
    offset 1536    30 B   0xE323-0xE340   la cola detrás del último RET

Las direcciones son las de la memoria del MSX con el juego ya cargado, que es
donde significan algo.

## Por qué estos sí y la cinta no

La imagen de cinta no se distribuye con este repositorio (ver
[AVISO-LEGAL.md](../AVISO-LEGAL.md)): quien quiera reconstruirlo todo pone la
suya. Estos 1566 bytes son otra cosa, y por eso están:

- **No son código.** Está medido: usan 60 valores de byte distintos en 1566, y
  no contienen un solo `CALL` ni un solo `RET`. No ejecutan nada.
- **El juego no los usa.** Está demostrado a partir del tope de scroll del propio
  programa: nunca llegan a la pantalla, en ninguna partida.
- **No reconstruyen nada.** Son el 4,6 % de la cinta, sin las tablas, sin el
  programa y sin el cargador.
- **Son el objeto de estudio.** La página de bytes muertos va justamente sobre
  ellos, y sin poder mirarlos no hay nada que discutir.

## Qué se sabe y qué no

Lo medido, con sus cifras y sus controles, está en
[docs/es/BYTES-MUERTOS.md](../docs/es/BYTES-MUERTOS.md) (o
[docs/DEAD-BYTES.md](../docs/DEAD-BYTES.md) en inglés). En corto: se ha
descartado que sean código de ninguna CPU, dibujo de ningún ancho, mapa, color,
música, sonido digitalizado, tabla de notas o copia de otra parte de la cinta.
La mejor pista es que su contenido parece dictarlo la **dirección de memoria** y
no un dato, aunque tampoco son el patrón de RAM sin inicializar que sí trae esta
misma cinta en otras dos zonas.

Para repetir todas las medidas sobre tu propia copia:

    make extract
    make misterio

Si encuentras lo que son —o descartas algo más, con su medida—, hay una
[plantilla de issue](../.github/ISSUE_TEMPLATE/1566-bytes.yml) esperando.
