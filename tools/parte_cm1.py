#!/usr/bin/env python3
"""Parte el bloque CM1 en los tres trozos de distinta naturaleza que contiene.

CM1 es el bloque que trae el juego, y no es homogeneo: la mayor parte es un
programa MSX-BASIC tokenizado, y solo el final es codigo Z80. Un unico listado
no puede representarlo, porque las dos cosas se leen y se comprueban de forma
distinta: el BASIC se detokeniza y se vuelve a tokenizar, y el codigo se
desensambla y se vuelve a ensamblar.

El reparto, con las direcciones donde el bloque se EJECUTA (CM1 se carga en
0x83E8 pero lo primero que hace es copiarse a 0x8000):

    basic     0x8000..0x8F5E   3935 B  el programa: 63 lineas tokenizadas.
                                       Acaba en el 0x0000 que marca fin de
                                       programa, justo antes del VARTAB=0x8F60
                                       que pone el arranque.
    vars      0x8F5F..0x9087    297 B  lo que el interprete vera como area de
                                       variables al arrancar.
    arranque  0x9088..0x90B4     45 B  codigo Z80: el trozo que pone en marcha
                                       el interprete, y el recolocador.

Concatenados en ese orden dan CM1 entero, byte a byte: es lo que comprueba
`make verify`.

Uso: parte_cm1.py <work/CM1.raw> <dir_salida>
"""
import os
import sys

# nombre, primera direccion, ultima direccion (INCLUSIVE), para que sirve
TROZOS = [
    ("basic",    0x8000, 0x8F5E, "programa MSX-BASIC tokenizado, 63 lineas"),
    ("vars",     0x8F5F, 0x9087, "area de variables del interprete"),
    ("arranque", 0x9088, 0x90B4, "codigo Z80: arranque del interprete y recolocador"),
]

# Donde acaba CM1 despues de copiarse a si mismo.
ORG = 0x8000


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    d = open(sys.argv[1], "rb").read()
    salida = sys.argv[2]
    os.makedirs(salida, exist_ok=True)

    fin_esperado = ORG + len(d) - 1
    if TROZOS[-1][2] != fin_esperado:
        sys.exit(
            f"el reparto acaba en 0x{TROZOS[-1][2]:04X} pero CM1 acaba en "
            f"0x{fin_esperado:04X}: hay {len(d)} bytes y el reparto no los cubre"
        )

    anterior = ORG
    total = 0
    for nombre, ini, fin, para_que in TROZOS:
        if ini != anterior:
            sys.exit(f"hueco o solape en el reparto: 0x{anterior:04X} -> 0x{ini:04X}")
        trozo = d[ini - ORG:fin - ORG + 1]
        open(os.path.join(salida, f"cm1_{nombre}.bin"), "wb").write(trozo)
        print(f"  {nombre:9s} 0x{ini:04X}..0x{fin:04X}  {len(trozo):5d} bytes  {para_que}")
        anterior = fin + 1
        total += len(trozo)

    if total != len(d):
        sys.exit(f"el reparto suma {total} bytes y CM1 tiene {len(d)}")
    print(f"  los tres trozos suman los {total} bytes de CM1, sin huecos")


if __name__ == "__main__":
    main()
