# Colt 36 (Topo Soft, 1987, MSX) — desensamblado comentado

Una cinta de cassette de 1987, desmontada línea a línea. Los **34 239 bytes** que
trae están explicados, y el juego resultó estar escrito en **BASIC**.

📖 **[Documentación completa](https://antxiko.github.io/Colt36-disassembly/)**
· [En castellano](https://antxiko.github.io/Colt36-disassembly/es/)

---

## Qué es esto

*Colt 36* es una galería de tiro del oeste que Topo Soft publicó para MSX en
1987. Este repositorio contiene su código completo, comentado, más las
herramientas para reconstruirlo y comprobarlo.

Lo que hace este juego distinto de lo que uno espera: **no está escrito en
ensamblador**. El bloque que trae el juego es un programa **MSX-BASIC tokenizado
de 63 líneas**, con solo 45 bytes de Z80 al final para poner el intérprete en
marcha. En toda la cinta hay **997 bytes de código máquina**, y la rutina que
hace el scroll —el motor gráfico entero— mide diecisiete.

## Cómo se comprueba que esto es verdad

`make` regenera los listados desde el binario de la cinta y exige que salga
exactamente el original:

```
topo  4254 B   OK: reproducible byte a byte
scr   7100 B   OK: reproducible byte a byte
CM2  18352 B   OK: reproducible byte a byte
CM1   4277 B   OK: el bloque del juego se rehace byte a byte

TOTAL 34239 bytes, 34239 explicados (100.00%), 0 sin explicar
```

Como el juego está en BASIC, aquí la prueba no es reensamblar sino **volver a
tokenizar**: el listado comentado (`src/colt36.bas`) se convierte otra vez a los
bytes del intérprete y tienen que coincidir con los de la cinta. Ese listado
admite comentarios propios (las líneas que empiezan por `#`), así que el fichero
que se publica es exactamente el que se comprueba, y no pueden divergir.

Hay además un **presupuesto**, que es una comprobación distinta: cada byte tiene
que ser o código que el trazador alcanza de verdad, o un rango de datos con
nombre y explicación. Existe porque la reproducibilidad no ve los errores de
interpretación: si unos gráficos se marcaran como código, los bytes seguirían
saliendo idénticos y el único que mentiría sería el listado.

Y **58 tests**, buena parte de ellos dedicados a comprobar que lo que dice la
documentación es lo que hace el juego.

## SE BUSCAN 1566 bytes, vivos o muertos

Queda una cosa sin cerrar, y se publica como lo que es. De los 34 239 bytes de
la cinta hay **1566 que nadie ha conseguido identificar**: 1536 en el sobrante
de dos decorados y 30 en una cola detrás del último `RET`. Está demostrado que
el juego no los enseña jamás, y descartado que sean código Z80, mapa, dibujos,
color, música, sonido digitalizado, tabla de notas o copia de ninguna otra parte
de la cinta —cada descarte con su medida—. Y no son un dibujo en ningún ancho:
la racha media de píxeles iguales es 1,63, *por debajo* del 2,00 del azar,
cuando los dibujos del propio juego dan 3,91.

Pero **no son basura**. La mejor pista es que su contenido parece dictarlo la
**dirección de memoria**, no un dato: cada bit tiene su propia polaridad atada a
la paridad de la dirección (el bit 1 la cumple en el 99,2 % de los bytes; el bit
6 cumple la contraria en el 81,2 %), y los ocho únicos 0xFF en dirección impar
caen los ocho donde los siete bits bajos están todos a uno. Eso ningún formato
de datos lo hace. La conclusión fácil sería «es RAM sin inicializar», pero esta
cinta trae dos zonas identificadas como tal y los sospechosos **no se les
parecen**: encajan con esa regla al 47,7 %, cuando las otras dan 99,3 % y
100,0 % y un dato cualquiera da 50 %.

Y para mirarlos no hace falta tener la cinta: **están publicados**, en volcado
hexadecimal en la propia página y como fichero en
[`datos/misterio.bin`](datos/misterio.bin). Con tu propia copia, además, los
regeneras y repites todas las medidas con dos órdenes:

```sh
make extract
make misterio     # los saca, los mide, y actualiza datos/misterio.bin
```

El cartel completo, con lo descartado y cómo se descartó, está en
[la página de bytes muertos](https://antxiko.github.io/Colt36-disassembly/es/BYTES-MUERTOS.html).
Las hipótesis van por [issues](https://github.com/antxiko/Colt36-disassembly/issues/new/choose):
lo que hace falta no es la idea sino la medida que la sostiene.

## Empezar

```sh
make          # extrae, genera los listados y lo comprueba todo
make test     # solo los tests
make web      # regenera la web de docs/
make misterio # saca los 1566 bytes sin identificar y los mide
make ram      # carga la cinta en openMSX y contrasta la memoria (tarda)
```

Hace falta `pasmo`, `z80dasm` y Python 3. Para `make ram` y las capturas,
`openmsx`.

**La cinta no se distribuye** con este repositorio, solo el trabajo de
documentación (ver [AVISO-LEGAL.md](AVISO-LEGAL.md)). Para reconstruirlo todo
hace falta tu propia copia, con el nombre `colt36.tsx` en la raíz y este sha256:

```
4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13
```

Sin la cinta puedes igualmente leer los listados de `src/` y pasar los tests que
no dependen del binario.

## Qué hay en cada sitio

| | |
|---|---|
| `src/colt36.bas` | **el juego**: las 63 líneas de BASIC, comentadas |
| `src/colt36_arranque.asm` | los 45 bytes de Z80 que arrancan el intérprete |
| `src/colt36_cm2.asm` | dibujos, decorados, música y las rutinas de apoyo |
| `src/colt36_scr.asm` | la pantalla que se ve mientras carga |
| `src/colt36_topo.asm` | el logo animado de la casa |
| `src/*.notes` | las anotaciones de las que salen los listados |
| `tools/basic_detok.py` | detokeniza y retokeniza MSX-BASIC, byte a byte |
| `tools/render_niveles.py` | dibuja las pantallas desde los datos del binario |
| `tools/omsx_juega.tcl` | carga la cinta en openMSX y saca capturas |
| `datos/misterio.bin` | los 1566 bytes sin identificar, para quien quiera probar |
| `docs/` | la documentación y la web |

## Créditos

Los del propio juego, leídos de su binario: gráficos de **LuigiLopez**, música de
**Gominolas**, y la pantalla de carga firmada por **Cano**. *Colt 36* es de Topo
Soft y de sus autores; esto es trabajo de preservación y estudio. Ver
[AVISO-LEGAL.md](AVISO-LEGAL.md).
