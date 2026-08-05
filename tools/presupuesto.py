#!/usr/bin/env python3
"""Presupuesto de la cinta: ni un byte sin explicar.

Por que este control y no el porcentaje de codigo trazado: el 97% de Colt 36 son
datos, asi que un "3% de codigo" suena a trabajo a medias cuando puede estar
entero. Lo que mide el avance de verdad es que cada byte sea una de estas cosas:

  - codigo que el trazador alcanza de verdad siguiendo el flujo
  - un byte dentro de un rango de datos IDENTIFICADO en el fichero de notas
  - parte del programa BASIC, que se comprueba de otra forma (detokenizando y
    volviendo a tokenizar; si eso sale byte a byte, esta explicado por completo)

Y es un control DISTINTO del de reproducibilidad. Un byte puede reensamblar
perfecto y estar sin explicar; o peor, estar mal explicado: si unos graficos se
marcan como codigo, el binario reensamblado sigue saliendo identico -los bytes
no cambian, solo su lectura- y el listado miente igual.

Uso: presupuesto.py <directorio_work> <directorio_src>
"""
import json
import os
import sys

# nombre del modulo, org, fichero .raw, prefijo de sus ficheros de trazado/notas
MODULOS = [
    ("topo", 0x9470, "topo.raw", "topo"),
    ("scr",  0x9C40, "scr.raw",  "scr"),
    ("CM2",  0x9B91, "CM2.raw",  "cm2"),
]

# El bloque del juego va aparte: la mayor parte es un programa BASIC, que no se
# mide con el trazador sino con la ida y vuelta de tools/basic_detok.py.
CM1 = [
    ("programa BASIC", 0x8000, 3935, "63 lineas, verificadas retokenizando"),
    ("area de variables", 0x8F5F, 297, "identificado: 1 byte muerto, 11 de una variable sobrante y 285 de RAM sin inicializar"),
    ("arranque Z80", 0x9088, 45, "desensamblado y comentado"),
]

# El cargador de cinta, que es un fichero de texto y no lleva codigo.
CARGADOR = ("cargador BASIC", 256, "117 bytes de texto, 1 de fin de fichero y 138 de relleno")


def rangos_de_notas(path):
    """Saca los rangos de datos declarados con la directiva D del fichero .notes."""
    out = []
    if not os.path.exists(path):
        return out
    for ln in open(path, encoding="utf-8"):
        ln = ln.strip()
        if not ln.startswith("D "):
            continue
        p = ln.split(None, 3)
        out.append((int(p[1], 0), int(p[2], 0)))
    return out


def revisa(work, src, nombre, org, raw, pref):
    size = len(open(os.path.join(work, raw), "rb").read())
    estado = bytearray(size)          # 0 sin explicar, 1 codigo, 2 datos con nombre

    tr = json.load(open(os.path.join(work, f"{pref}.trace.json")))
    for kind, a, b in tr["blocks"]:
        if kind == "c":
            for i in range(max(0, a - org), min(size, b - org)):
                estado[i] = 1

    for a, b in rangos_de_notas(os.path.join(src, f"{pref}.notes")):
        for i in range(max(0, a - org), min(size, b - org)):
            if estado[i] == 0:
                estado[i] = 2

    codigo = estado.count(1)
    datos = estado.count(2)
    huerfanos = estado.count(0)
    return size, codigo, datos, huerfanos, estado


def huecos(estado, org):
    """Agrupa los bytes sin explicar en rangos, para poder ir a mirarlos."""
    out, ini = [], None
    for i, v in enumerate(estado):
        if v == 0 and ini is None:
            ini = i
        elif v != 0 and ini is not None:
            out.append((org + ini, org + i))
            ini = None
    if ini is not None:
        out.append((org + ini, org + len(estado)))
    return out


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    work, src = sys.argv[1], sys.argv[2]

    total = explicado = 0
    pendientes = []

    print(f"  {'modulo':16s} {'bytes':>7s} {'codigo':>7s} {'datos':>7s} {'sin explicar':>13s}")
    print("  " + "-" * 56)

    for nombre, org, raw, pref in MODULOS:
        size, cod, dat, huerf, estado = revisa(work, src, nombre, org, raw, pref)
        total += size
        explicado += cod + dat
        print(f"  {nombre:16s} {size:7d} {cod:7d} {dat:7d} {huerf:13d}")
        for a, b in huecos(estado, org):
            pendientes.append((nombre, a, b))

    # El bloque del juego, con su criterio propio.
    print("  " + "-" * 56)
    for etiqueta, org, size, como in CM1:
        total += size
        explicado += size
        print(f"  {etiqueta:16s} {size:7d}   {como}")

    print("  " + "-" * 56)
    etiqueta, size, como = CARGADOR
    total += size
    explicado += size
    print(f"  {etiqueta:16s} {size:7d}   {como}")

    print("  " + "=" * 56)
    sin = total - explicado
    pct = 100.0 * explicado / total if total else 0
    print(f"  {'TOTAL':16s} {total:7d} bytes, {explicado} explicados ({pct:.2f}%), {sin} sin explicar")

    if pendientes:
        print()
        print("  Sin explicar:")
        for nombre, a, b in pendientes:
            print(f"    {nombre:6s} 0x{a:04X}..0x{b - 1:04X}  ({b - a} bytes)")
        print()
        print("  Cada uno de estos rangos tiene que acabar dentro de una directiva D")
        print("  del fichero de notas, con una explicacion de que es y de como se sabe.")
        sys.exit(1)

    print()
    print("  OK: ni un byte de la cinta sin asignar")


if __name__ == "__main__":
    main()
