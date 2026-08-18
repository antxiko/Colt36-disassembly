#!/usr/bin/env python3
"""Genera la portada de la web, en ingles y en castellano.

El diseno vive en tools/estilo_web.py: aqui solo va el contenido de este juego.

Todo el material visual sale del propio binario -incluido el rotulo de la
cabecera, recortado de la pantalla de titulo- y las imagenes van embebidas como
data URI, de modo que cada pagina es un fichero autocontenido que se puede abrir
sin servidor.

  python3 tools/make_web.py <work/CM2.raw> <dir imagenes> <salida.html> [en|es]

La inglesa se escribe en docs/index.html y la castellana en docs/es/index.html.
"""
import tempfile
import base64
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from estilo_web import ESTILO          # noqa: E402
from render_maps import PALETA, png    # noqa: E402
from render_niveles import portada     # noqa: E402

# El temporal del sistema: en Windows no hay /tmp.
TMP = tempfile.gettempdir()

REPO = "https://github.com/antxiko/Colt36-disassembly"

# Donde cae el rotulo del juego dentro de la pantalla de titulo, en casillas.
ROTULO = (9, 8, 14, 2)      # columna, fila, ancho, alto

# Los textos de los dos idiomas van juntos a proposito: si se toca uno, se ve
# enseguida que el otro se ha quedado descolgado.
T = {
    "en": dict(
        titulo="Colt 36 (1987) — a commented disassembly",
        claim="A 1987 cassette tape, taken apart line by line. <b>All 34,239 bytes "
              "on it are accounted for</b> — and the game turned out to be written "
              "in BASIC.",
        ficha=["Topo Soft · <b>1987</b>", "Graphics <b>LuigiLopez</b>",
               "Music <b>Gominolas</b>", "MSX1 · <b>64K</b>"],
        nav=[("#numbers", "The numbers"), ("#findings", "Findings"),
             ("#screens", "The levels"), ("#method", "How it was done")],
        docnav=[("GETTING-STARTED.html", "Getting started"),
                ("THE-GAME.html", "The game"), ("THE-TAPE.html", "The tape"),
                ("THE-CODE.html", "The code"), ("FINDINGS.html", "Findings"),
                ("DEAD-BYTES.html", "Dead bytes")],
        otro=("es/", "En castellano"),
        h_num="The game in numbers", h_find="What turned up when we took it apart",
        h_scr="The four levels", h_met="How it was done",
        cifras=[("100%", "of the binary accounted for"), ("65", "routines identified"),
                ("4", "level maps"), ("4,932", "bytes of code"),
                ("29,307", "bytes of data"), ("1,566", "bytes unidentified")],
        nota_num="Those bytes of code are not what you would expect. Only "
                 "<b style='color:var(--tinta);font-weight:400'>997 of them are "
                 "machine code</b>; the other 3,935 are a tokenised MSX-BASIC "
                 "program — the game itself. And the 1,566 unidentified bytes are "
                 "not a gap in the map: every byte on the tape has been assigned a "
                 "role. Those are the ones whose <i>contents</i> we could not name, "
                 "and it is proven that the game never displays them. They are "
                 "<a href='DEAD-BYTES.html#wanted'>wanted, dead or alive</a>: what "
                 "has been ruled out, with what measurement, and how to have a go.",
        nota_scr="These aren't screen captures. They are drawn from the game's own "
                 "data, following step by step what the program does to build the "
                 "screen. Each level is a 32-column map, taller than the screen; "
                 "the game shows a 16-row window of it and moves that window.",
        nivel="Level", tira="Full map", pantalla="On screen",
        pie_leg="Documentation and preservation work on a 1987 game. The code and "
                "artwork belong to their authors and to Topo Soft. The tape image "
                "is not distributed.",
    ),
    "es": dict(
        titulo="Colt 36 (1987) — desensamblado comentado",
        claim="Una cinta de cassette de 1987, desmontada línea a línea. <b>Los "
              "34.239 bytes que trae están explicados</b>, y el juego resultó estar "
              "escrito en BASIC.",
        ficha=["Topo Soft · <b>1987</b>", "Gráficos <b>LuigiLopez</b>",
               "Música <b>Gominolas</b>", "MSX1 · <b>64K</b>"],
        nav=[("#numbers", "Las cifras"), ("#findings", "Hallazgos"),
             ("#screens", "Los niveles"), ("#method", "Cómo se hizo")],
        docnav=[("EMPEZAR.html", "Empezar"), ("EL-JUEGO.html", "El juego"),
                ("LA-CINTA.html", "La cinta"), ("EL-CODIGO.html", "El código"),
                ("HALLAZGOS.html", "Hallazgos"),
                ("BYTES-MUERTOS.html", "Bytes muertos")],
        otro=("../", "In English"),
        h_num="El juego en cifras", h_find="Lo que apareció al desmontarlo",
        h_scr="Los cuatro niveles", h_met="Cómo se hizo",
        cifras=[("100%", "del binario explicado"), ("65", "rutinas identificadas"),
                ("4", "mapas de nivel"), ("4.932", "bytes de código"),
                ("29.307", "bytes de datos"), ("1.566", "bytes sin identificar")],
        nota_num="Esos bytes de código no son lo que uno espera. Solo "
                 "<b style='color:var(--tinta);font-weight:400'>997 son código "
                 "máquina</b>; los otros 3.935 son un programa MSX-BASIC "
                 "tokenizado, que es el juego. Y los 1.566 sin identificar no son "
                 "un hueco en el mapa: todos los bytes de la cinta tienen asignado "
                 "su papel. Son aquellos cuyo <i>contenido</i> no hemos sabido "
                 "nombrar, y está demostrado que el juego no los enseña nunca. "
                 "<a href='BYTES-MUERTOS.html#se-busca'>Se buscan, vivos o "
                 "muertos</a>: lo descartado, con qué medida, y cómo intentarlo.",
        nota_scr="No son capturas de pantalla. Están dibujadas a partir de los "
                 "datos del propio juego, siguiendo paso a paso lo que hace el "
                 "programa para montar la pantalla. Cada nivel es un mapa de 32 "
                 "columnas más alto que la pantalla: el juego enseña una ventana "
                 "de 16 filas y lo que mueve es esa ventana.",
        nivel="Nivel", tira="Mapa completo", pantalla="En pantalla",
        pie_leg="Trabajo de documentación y preservación sobre un juego de 1987. "
                "El código y los gráficos son de sus autores y de Topo Soft. La "
                "imagen de cinta no se distribuye.",
    ),
}

# Cuantas filas de su mapa usa cada nivel, y como se llama.
NIVELES = [(1, "EL ALMACEN", 32), (2, "EL CANON", 48),
           (3, "LA MINA", 64), (4, "EL SALOON", 64)]

# (titulo, cuerpo html) por idioma
HALLAZGOS = {
    "en": [
        ("The game is written in BASIC",
         "<p>The block that carries the game is not machine code: it is a "
         "<b>tokenised MSX-BASIC program, 63 lines long</b>, with just 45 bytes of "
         "Z80 at the end to start the interpreter. Everything that had to be fast "
         "is done by four routines called with <code>USR</code> — and the most "
         "important of them is seventeen bytes long.</p>"
         "<p>So the usual guarantee does not apply here. Instead of reassembling, "
         "the commented listing is <b>re-tokenised</b> and must produce the tape's "
         "bytes exactly. It does.</p>"),
        ("The score is shown multiplied by a hundred",
         "<p>The panel is drawn with six zeroes, and the routine that prints the "
         "score only writes four digits: columns 5 and 6 keep the zeroes they came "
         "with. Shooting a bandit adds 20 to the counter and the screen reads "
         "<b>2000</b>.</p>"),
        ("A line number nobody can reach",
         "<p>Line 730 plays a sound and jumps back into the loop, and nothing in "
         "the program ever goes there: no <code>GOTO</code>, no <code>GOSUB</code>, "
         "no <code>THEN</code>, and it is not in the dispatch list of line 640 "
         "either. The line before it ends in a jump, so it cannot be fallen into. "
         "It is a leftover from an earlier version, still on the tape.</p>"),
        ("You do not get your bullets back",
         "<p>Losing a life returns to line 600, not 599 — and 599 is the one that "
         "reloads the forty bullets. They are per <i>level</i>, not per life. Run "
         "out and line 300 just returns without even making a sound: you cannot "
         "shoot anything any more, and the lives you have left go one after "
         "another while you watch.</p>"),
        ("The program is protected against being listed",
         "<p>On the tape the first line is numbered <b>65535</b>, above the highest "
         "line number MSX-BASIC accepts, and the Z80 startup writes a 4 over it. "
         "Without that patch the program breaks: verified in the emulator, the "
         "first <code>GOSUB</code> aborts with <i>Undefined line number in 520</i>. "
         "And what that line does is <code>POKE &amp;HFBB1,1</code>, which disables "
         "CTRL+STOP — so the running game cannot be halted, and therefore cannot "
         "be listed.</p>"),
        ("The tape still holds a scrap of the author's machine",
         "<p>In the interpreter's variable area the tape carries eleven bytes with "
         "the exact shape of an MSX-BASIC variable entry: a double-precision "
         "<code>I</code> holding 37025. This program never uses one — it uses "
         "<code>I%</code>, an integer. Behind it are 285 bytes of uninitialised "
         "RAM which follow the power-on pattern of the machine.</p>"
         "<p>That pattern gives away something else. It depends on the "
         "<i>absolute</i> address, and it fits 282 of the 285 (98.9%) at 0x8000 but only 226 (79.3%) at "
         "0x83E8 — so on the programmer's machine the game already lived at "
         "0x8000, and the tape's load address is only a detour to avoid "
         "overwriting the loader while it loads.</p>"),
    ],
    "es": [
        ("El juego está escrito en BASIC",
         "<p>El bloque que trae el juego no es código máquina: es un <b>programa "
         "MSX-BASIC tokenizado de 63 líneas</b>, con solo 45 bytes de Z80 al final "
         "para arrancar el intérprete. Todo lo que tenía que ir rápido lo hacen "
         "cuatro rutinas que se llaman con <code>USR</code>, y la más importante de "
         "ellas mide diecisiete bytes.</p>"
         "<p>Así que aquí la garantía de siempre no vale. En vez de reensamblar, el "
         "listado comentado se vuelve a <b>tokenizar</b> y tiene que dar los bytes "
         "de la cinta exactos. Los da.</p>"),
        ("La puntuación se enseña multiplicada por cien",
         "<p>El marcador viene dibujado con seis ceros, y la subrutina que escribe "
         "la puntuación solo pone cuatro cifras: las columnas 5 y 6 se quedan con "
         "el cero que traen de fábrica. Abatir a un bandido suma 20 al contador y "
         "en pantalla se lee <b>2000</b>.</p>"),
        ("Una línea a la que no llega nadie",
         "<p>La línea 730 hace sonar algo y vuelve al bucle, y en todo el programa "
         "no hay nada que salte ahí: ni un <code>GOTO</code>, ni un "
         "<code>GOSUB</code>, ni un <code>THEN</code>, y tampoco está en el reparto "
         "de la línea 640. La línea de antes acaba en un salto, así que tampoco se "
         "cae dentro. Es un resto de una versión anterior que se quedó grabado.</p>"),
        ("Las balas no se reponen",
         "<p>Al perder una vida se vuelve a la línea 600, no a la 599 — y la 599 es "
         "la que recarga las cuarenta balas. Son por <i>nivel</i>, no por vida. Si "
         "te quedas sin ellas, la línea 300 se limita a hacer <code>RETURN</code> "
         "sin sonar siquiera: ya no puedes abatir a nadie, y las vidas que te "
         "queden se van una detrás de otra mientras miras.</p>"),
        ("El programa está protegido para que no se pueda listar",
         "<p>En la cinta, la primera línea viene numerada <b>65535</b>, por encima "
         "del mayor número de línea que MSX-BASIC admite, y el arranque en Z80 le "
         "escribe un 4 encima. Sin ese parche el programa se rompe: comprobado en "
         "el emulador, el primer <code>GOSUB</code> aborta con <i>Undefined line "
         "number in 520</i>. Y lo que hace esa línea es <code>POKE &amp;HFBB1,1</code>, "
         "que desactiva CTRL+STOP: el juego en marcha no se puede parar y, por "
         "tanto, tampoco listar.</p>"),
        ("La cinta guarda todavía un resto de la máquina del autor",
         "<p>En el área de variables del intérprete, la cinta trae once bytes con "
         "la forma exacta de una entrada de variable de MSX-BASIC: una "
         "<code>I</code> de doble precisión que vale 37025. Este programa no usa "
         "ninguna: usa <code>I%</code>, entera. Detrás hay 285 bytes de RAM sin "
         "inicializar que siguen el patrón de encendido de la máquina.</p>"
         "<p>Y ese patrón delata otra cosa. Depende de la dirección "
         "<i>absoluta</i>, y encaja en 282 de los 285 (98,9 %) en 0x8000 pero solo en 226 (79,3 %) en 0x83E8: en "
         "la máquina del programador el juego ya vivía en 0x8000, y la dirección de "
         "carga de la cinta es solo un desvío para no pisar al cargador mientras "
         "carga.</p>"),
    ],
}

METODO = {
    "en": "<p>There is no turbo loading here: the tape is made of standard blocks, "
          "so the bytes come straight out of the tape file and no emulator is "
          "needed to decode them. What the emulator <i>is</i> used for is proof. "
          "The game's memory image is rebuilt by hand — one block relocates itself "
          "on startup — and then openMSX loads the real tape and its RAM is dumped "
          "at the exact instant the game starts. The two match, byte for byte.</p>"
          "<p>From there, code is traced by following control flow from the known "
          "entry points, never by disassembling linearly: 18 KB of graphics decoded "
          "as instructions would throw everything out of alignment. Regions known "
          "to be data are declared off-limits, because one bad seed sends the "
          "tracer into the artwork and inflates coverage with nonsense.</p>"
          "<p>Two separate checks guard the result. <b>Reproducibility</b>: every "
          "listing must give back the original binary — reassembled for the machine "
          "code, re-tokenised for the BASIC. And a <b>budget</b>: every byte must "
          "be either traced code or a data range named in the notes. The second "
          "exists because the first cannot see misinterpretation — if graphics get "
          "marked as code, the bytes still come out identical and only the listing "
          "lies.</p>",
    "es": "<p>Aquí no hay carga turbo: la cinta son bloques estándar, así que los "
          "bytes salen directamente del fichero y no hace falta ningún emulador "
          "para decodificarlos. Para lo que <i>sí</i> se usa el emulador es para "
          "demostrar. La imagen de memoria del juego se reconstruye a mano —uno de "
          "los bloques se recoloca solo al arrancar— y después openMSX carga la "
          "cinta de verdad y se vuelca su RAM en el instante exacto en que el juego "
          "arranca. Las dos coinciden byte a byte.</p>"
          "<p>A partir de ahí, el código se traza siguiendo el flujo desde los "
          "puntos de entrada conocidos, nunca desensamblando en línea recta: 18 KB "
          "de gráficos leídos como instrucciones desalinearían todo lo demás. Las "
          "zonas que se sabe que son datos se declaran prohibidas, porque una sola "
          "semilla mala mete al trazador en los dibujos e infla la cobertura con "
          "basura.</p>"
          "<p>Dos comprobaciones distintas guardan el resultado. "
          "<b>Reproducibilidad</b>: cada listado tiene que devolver el binario "
          "original —reensamblando, en el código máquina; volviendo a tokenizar, en "
          "el BASIC—. Y un <b>presupuesto</b>: cada byte tiene que ser o código "
          "trazado, o un rango de datos con nombre en las notas. La segunda existe "
          "porque la primera no ve los errores de interpretación: si unos gráficos "
          "se marcan como código, los bytes siguen saliendo idénticos y el único "
          "que miente es el listado.</p>",
}


def b64(p):
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode()


def img(p, alt):
    return f'<img src="data:image/png;base64,{b64(p)}" alt="{alt}" loading="lazy">'


def recorta_rotulo(d, escala=4):
    """Recorta el rotulo del juego de la pantalla de titulo, ya montada."""
    v = portada(d)
    col0, fila0, ncols, nfilas = ROTULO
    w, h = ncols * 8 * escala, nfilas * 8 * escala
    out = [[PALETA[1]] * w for _ in range(h)]
    for fy in range(nfilas):
        tercio = (fila0 + fy) // 8
        pat = tercio * 0x800
        col = 0x2000 + tercio * 0x800
        for fx in range(ncols):
            t = v[0x1800 + (fila0 + fy) * 32 + col0 + fx]
            for l in range(8):
                forma, color = v[pat + t * 8 + l], v[col + t * 8 + l]
                tinta, fondo = PALETA[color >> 4], PALETA[color & 15]
                for b in range(8):
                    rgb = tinta if (forma >> (7 - b)) & 1 else fondo
                    for sy in range(escala):
                        for sx in range(escala):
                            out[(fy * 8 + l) * escala + sy][(fx * 8 + b) * escala + sx] = rgb
    return w, h, out


def main(binpath, imgdir, out, idioma="en"):
    with open(binpath, "rb") as f:
        d = f.read()
    t = T[idioma]

    w, h, im = recorta_rotulo(d)
    png(f"{TMP}/_c36_logo.png", w, h, im)

    hallazgos = "".join(f'<div class="hall"><h3>{tit}</h3>{cuerpo}</div>'
                        for tit, cuerpo in HALLAZGOS[idioma])

    galeria = ""
    for n, nombre, filas in NIVELES:
        mapa = os.path.join(imgdir, f"mapa{n}.png")
        pant = os.path.join(imgdir, f"nivel{n}.png")
        alt = f'{t["nivel"]} {n}'
        galeria += (
            f'<div class="nivel"><h3>{t["nivel"]} {n}<span class="sep">·</span>'
            f'<em>{nombre}</em></h3>'
            f'<div class="rejilla" style="grid-template-columns:1fr;max-width:540px">'
            f'<figure>{img(pant, alt)}'
            f'<figcaption><span>{t["pantalla"]}</span>'
            f'<span class="dir">32 x 24</span></figcaption></figure></div>'
            f'<div class="rejilla" style="margin-top:.9rem;max-width:540px">'
            f'<figure>{img(mapa, alt)}'
            f'<figcaption><span>{t["tira"]}</span>'
            f'<span class="dir">32 x {filas}</span></figcaption></figure></div></div>')

    nav = "".join(f'<a href="{h_}">{x}</a>' for h_, x in t["nav"])
    docnav = "".join(f'<a href="{h_}">{x}</a>' for h_, x in t["docnav"])
    docnav += f'<a href="{REPO}">GitHub</a>'
    docnav += (f'<a href="{t["otro"][0]}" style="margin-left:auto;color:var(--oro)">'
               f'{t["otro"][1]}</a>')

    doc = f"""<title>{t["titulo"]}</title>
<style>{ESTILO}</style>
<div class="w">
<header class="top">
  {img(f"{TMP}/_c36_logo.png", "Colt 36")}
  <p class="claim">{t["claim"]}</p>
  <div class="ficha">{"".join(f"<span>{x}</span>" for x in t["ficha"])}</div>
</header>
<nav>{nav}</nav>
<nav class="docs">{docnav}</nav>

<section id="numbers">
  <h2>{t["h_num"]}</h2>
  <div class="cifras">{"".join(f'<div class="cifra"><b>{a}</b><span>{b}</span></div>'
                                for a, b in t["cifras"])}</div>
  <p class="n" style="margin-top:1.5rem;color:var(--suave)">{t["nota_num"]}</p>
</section>

<section id="findings"><h2>{t["h_find"]}</h2>{hallazgos}</section>

<section id="screens">
  <h2>{t["h_scr"]}</h2>
  <p class="n" style="color:var(--suave)">{t["nota_scr"]}</p>
  {galeria}
</section>

<section id="method"><h2>{t["h_met"]}</h2>
  <div class="n">{METODO[idioma]}</div>
</section>

<footer>{t["pie_leg"]}</footer>
</div>
"""
    with open(out, "w", encoding="utf-8") as f:
        f.write(doc)
    print(f"  {out}: {len(doc) // 1024} KB ({idioma})")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3],
         sys.argv[4] if len(sys.argv) > 4 else "en")
