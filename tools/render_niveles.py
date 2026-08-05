#!/usr/bin/env python3
"""Dibuja lo que el juego ensena, reconstruyendolo desde los datos de la cinta.

No son capturas de pantalla: aqui se monta la memoria de video paso a paso,
siguiendo AL PIE DE LA LETRA lo que hace el programa (las lineas 510 a 575 para
la portada, y la 595 y la 600 para cada nivel), y luego se dibuja.

Por eso vale como comprobacion y no solo como ilustracion: si el reparto del
bloque estuviese mal -si lo que llamamos "dibujos" fuesen en realidad los
colores, por ejemplo- de aqui saldria ruido en vez de una pantalla legible. Que
salga el titulo con sus letras y los cuatro decorados reconocibles es la prueba
mas fuerte de que las tablas son las que decimos.

Ademas dibuja los mapas enteros de los cuatro niveles, que son mas altos que la
pantalla, para que se vea de una pieza por donde se mueve el decorado.

Uso: render_niveles.py <work/CM2.raw> <directorio_salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render_maps import PALETA, png            # noqa: E402
from render_vram import render_vram            # noqa: E402

ORG = 0x9B91

# Donde esta cada cosa dentro del bloque, segun lo que el propio programa lee.
DIBUJOS = 0xC000        # 2048 B, a la memoria de video 0, 2048 y 4096
COLORES = 0xC800        # 2048 B, a 8192, 10240 y 12288
SPRITES = 0xD800        # 256 B, a 14336
TITULO = 0xD000         # 768 B, a 6144
MARCADOR = 0xD300       # 256 B, a 6656 (las ocho filas de abajo)
NIVELES = 0xA000        # 2048 B por nivel

# Cuantas filas de su mapa usa cada nivel: lo fija el tope de scroll de la
# linea 610 del programa.
FILAS_UTILES = {1: 32, 2: 48, 3: 64, 4: 64}

NOMBRES = {1: "EL ALMACEN", 2: "EL CANON", 3: "LA MINA", 4: "EL SALOON"}


def sl(d, a, b):
    return d[a - ORG:b - ORG]


def base_vram(d):
    """Lo que hacen las lineas 510 a 570: dibujos, colores y sprites.

    Los mismos 2048 bytes van a los tres tercios de la pantalla, porque la
    rutina de copia no actualiza el puntero de origen y el programa solo le
    cambia el destino. De ahi que el juego trabaje con un unico juego de 256
    dibujos valido en toda la pantalla.
    """
    v = bytearray(16384)
    pat = sl(d, DIBUJOS, DIBUJOS + 0x800)
    col = sl(d, COLORES, COLORES + 0x800)
    for dst in (0, 2048, 4096):
        v[dst:dst + 2048] = pat
    for dst in (8192, 10240, 12288):
        v[dst:dst + 2048] = col
    v[14336:14336 + 256] = sl(d, SPRITES, SPRITES + 0x100)
    return v


def escribe(v, hl, texto):
    """La subrutina 15: el dibujo de cada letra es su codigo ASCII mas 60."""
    for g, ch in enumerate(texto, start=1):
        v[hl + g + 6143] = (ord(ch) + 60) & 0xFF


def portada(d):
    """Lineas 572 y 575."""
    v = base_vram(d)
    v[6144:6144 + 768] = sl(d, TITULO, TITULO + 0x300)
    escribe(v, 132, "TOPO0SOFTWARE")
    escribe(v, 718, "00MUSICA^GOMINOLAS")
    return v


def nivel(d, n):
    """Lineas 595 y 600: el marcador abajo y la ventana del decorado arriba."""
    v = base_vram(d)
    v[6656:6656 + 256] = sl(d, MARCADOR, MARCADOR + 0x100)
    mapa = sl(d, NIVELES + 2048 * (n - 1), NIVELES + 2048 * n)
    # La linea 600 arranca la ventana en 0xDA00 + 256*N, o sea 8 filas por nivel.
    off = (256 * n // 32) * 32
    v[6144:6144 + 512] = mapa[off:off + 512]
    return v


def mapa_entero(d, n, escala=2):
    """El decorado completo de un nivel, que es mas alto que la pantalla.

    Solo se dibujan las filas que el juego llega a mostrar: el resto se copia a
    memoria, pero el tope del scroll impide verlo nunca.
    """
    filas = FILAS_UTILES[n]
    mapa = sl(d, NIVELES + 2048 * (n - 1), NIVELES + 2048 * n)[:filas * 32]
    pat = sl(d, DIBUJOS, DIBUJOS + 0x800)
    col = sl(d, COLORES, COLORES + 0x800)
    w, h = 32 * 8 * escala, filas * 8 * escala
    img = [[PALETA[1]] * w for _ in range(h)]
    for i, t in enumerate(mapa):
        cx, cy = (i % 32) * 8, (i // 32) * 8
        for y in range(8):
            forma, color = pat[t * 8 + y], col[t * 8 + y]
            tinta, fondo = PALETA[color >> 4], PALETA[color & 15]
            for x in range(8):
                p = tinta if (forma >> (7 - x)) & 1 else fondo
                for dy in range(escala):
                    for dx in range(escala):
                        img[(cy + y) * escala + dy][(cx + x) * escala + dx] = p
    return w, h, img


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1], "rb") as f:
        d = f.read()
    salida = sys.argv[2]
    os.makedirs(salida, exist_ok=True)

    w, h, img = render_vram(portada(d), backdrop=1)
    png(os.path.join(salida, "portada.png"), w, h, img)
    print(f"  portada.png                       {w}x{h}")

    for n in (1, 2, 3, 4):
        w, h, img = render_vram(nivel(d, n), backdrop=1)
        png(os.path.join(salida, f"nivel{n}.png"), w, h, img)
        print(f"  nivel{n}.png     {NOMBRES[n]:12s}     {w}x{h}")

        w, h, img = mapa_entero(d, n)
        png(os.path.join(salida, f"mapa{n}.png"), w, h, img)
        print(f"  mapa{n}.png      {NOMBRES[n]:12s}     {w}x{h}"
              f"  ({FILAS_UTILES[n]} filas)")


if __name__ == "__main__":
    main()
