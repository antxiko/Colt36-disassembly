#!/usr/bin/env python3
"""Dibuja la pantalla de carga a partir de los datos del bloque 'scr'.

Reproduce lo que hace el propio modulo: los 6144 bytes de dibujos van tal cual,
y los 768 de color se expanden repitiendo cada uno ocho veces, que es el atajo
con el que el bloque ahorra 5376 bytes de cinta.

Como la tabla de casillas la deja puesta el sistema al entrar en el modo de
pantalla -numeradas 0 a 255 tres veces, una por tercio-, aqui se monta igual.

Uso: render_carga.py <work/scr.raw> <salida.png>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from render_maps import png                     # noqa: E402
from render_vram import render_vram             # noqa: E402

ORG = 0x9C40
DIBUJOS = 0x9C40      # 0x1800 bytes, a la memoria de video 0x0000
COLOR = 0xB440        # 0x300 bytes, expandidos a 0x1800 en 0x2000


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1], "rb") as f:
        d = f.read()

    v = bytearray(16384)
    v[0x0000:0x1800] = d[DIBUJOS - ORG:DIBUJOS - ORG + 0x1800]

    # La tabla de casillas: 0..255 tres veces, tal y como la deja el sistema.
    for i in range(768):
        v[0x1800 + i] = i % 256

    # El color, expandido ocho veces por celda.
    comprimido = d[COLOR - ORG:COLOR - ORG + 0x300]
    for i, c in enumerate(comprimido):
        v[0x2000 + i * 8:0x2000 + i * 8 + 8] = bytes([c]) * 8

    w, h, img = render_vram(v, backdrop=1)
    png(sys.argv[2], w, h, img)
    print(f"  {sys.argv[2]}  {w}x{h}")


if __name__ == "__main__":
    main()
