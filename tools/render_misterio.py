#!/usr/bin/env python3
"""Dibuja los 1536 bytes sin identificar con la lectura que mejor les encaja.

De todas las formas de leerlos, la unica que no se cae a la primera es como
PAREJAS: un byte de dibujo -ocho pixeles, un bit cada uno- y detras un byte de
color -tinta en el nibble alto, fondo en el bajo-, que es el formato de la
pantalla del MSX. Encaja porque los bytes impares se comportan como color mejor
que la propia tabla de color del juego: 681 de 768 llevan el mismo fondo.

Lo que sale no es una figura, y por eso el caso sigue abierto: es una trama de
azules sobre azules, con los bits cayendose poco a poco de izquierda a derecha.
Se dibuja igualmente porque es la mejor lectura que hay y porque asi cualquiera
la ve sin tener que fiarse de la descripcion.

Se dibujan las dos anchuras que tienen sentido en un MSX -32 caracteres, que es
la pantalla entera, y 16- y al lado el decorado del nivel 1, que son bytes de la
misma zona de la cinta y de los que si se sabe lo que son.

Uso: render_misterio.py <work/CM2.raw> <directorio_salida>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from render_maps import PALETA, png                # noqa: E402

ORG_CM2 = 0x9B91
SOSPECHOSOS = (0xA400, 0xA800, 0xAE00, 0xB000)


def parejas(datos):
    """(dibujo, color) tal como las guardaria un editor de graficos del MSX."""
    return list(zip(datos[0::2], datos[1::2]))


def dibuja(pares, ancho, escala=3, backdrop=1):
    """Cada pareja es una fila de 8 pixeles; `ancho` de ellas por linea."""
    alto = len(pares) // ancho
    w, h = ancho * 8 * escala, alto * escala
    img = [[PALETA[backdrop]] * w for _ in range(h)]
    for i, (patron, color) in enumerate(pares):
        y, cx = divmod(i, ancho)
        tinta = PALETA[color >> 4] if (color >> 4) else PALETA[backdrop]
        fondo = PALETA[color & 15] if (color & 15) else PALETA[backdrop]
        for px in range(8):
            c = tinta if (patron >> (7 - px)) & 1 else fondo
            x0 = (cx * 8 + px) * escala
            for ey in range(escala):
                fila = img[y * escala + ey]
                for ex in range(escala):
                    fila[x0 + ex] = c
    return w, h, img


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    with open(sys.argv[1], "rb") as f:
        d = f.read()
    salida = sys.argv[2]
    os.makedirs(salida, exist_ok=True)

    a, b, c, e = SOSPECHOSOS
    sosp = d[a - ORG_CM2:b - ORG_CM2] + d[c - ORG_CM2:e - ORG_CM2]
    pares = parejas(sosp)

    for ancho in (32, 16):
        w, h, img = dibuja(pares, ancho)
        nombre = "misterio-parejas-%d.png" % ancho
        png(os.path.join(salida, nombre), w, h, img)
        print("  %-28s %dx%d   los 1536, a %d caracteres" % (nombre, w, h, ancho))

    # el vecino del que si se sabe lo que es, leido igual, para comparar
    vecino = d[0xA000 - ORG_CM2:0xA400 - ORG_CM2]
    w, h, img = dibuja(parejas(vecino), 32)
    png(os.path.join(salida, "misterio-control.png"), w, h, img)
    print("  %-28s %dx%d   el decorado de al lado, leido igual" %
          ("misterio-control.png", w, h))


if __name__ == "__main__":
    main()
