#!/usr/bin/env python3
"""Saca los 1566 bytes que nadie ha conseguido identificar, y los mide.

Son los unicos bytes de la cinta que este trabajo no sabe explicar. Estan
localizados y demostrado que el juego no los ensena nunca, pero que SON sigue
sin saberse. Esta herramienta existe para que cualquiera pueda intentarlo sin
tener que repetir el desmontaje entero: extrae los tres trozos de tu propia
copia de la cinta y escupe las medidas que ya se han hecho, para que se puedan
comprobar antes de proponer nada.

Los tres trozos:

    0xA400-0xA7FF   1024 B   lo que sobra del decorado del nivel 1
    0xAE00-0xAFFF    512 B   lo que sobra del decorado del nivel 2
                             (identico byte a byte a 0xA600-0xA7FF)
    0xE323-0xE340     30 B   la cola que va detras del ultimo RET

Los dos primeros caen justo donde el tope de scroll deja de mirar: eso esta
demostrado con la propia linea 610 del programa, y por eso se sabe que el juego
no los muestra jamas. La cola de 30 bytes es otra cosa y va aparte.

Uso:  python3 tools/extrae_misterio.py work [directorio_salida]

Escribe misterio.bin (los 1566 seguidos), misterio_mapas.bin (solo los 1536 de
los decorados) y misterio_cola.bin (los 30), y saca por pantalla la firma.
"""
import os
import sys
from collections import Counter

ORG_CM2 = 0x9B91

TROZOS = [
    ("mapa1", 0xA400, 0xA800, "sobrante del decorado del nivel 1"),
    ("mapa2", 0xAE00, 0xB000, "sobrante del decorado del nivel 2"),
    ("cola",  0xE323, 0xE341, "la cola detras del ultimo RET"),
]


def firma(b, etq):
    """Las medidas que ya estan hechas, para que se puedan repetir."""
    print("  %s  (%d bytes)" % (etq, len(b)))
    par, imp = b[0::2], b[1::2]
    print("     valores distintos: %d en total, %d en posicion par, %d en impar"
          % (len(set(b)), len(set(par)), len(set(imp))))
    comunes = set(par) & set(imp)
    print("     valores que comparten pares e impares: %d %s"
          % (len(comunes), sorted("0x%02X" % c for c in comunes)))
    for etq2, mitad in (("pares  ", par), ("impares", imp)):
        fijos = []
        for bit in range(7, -1, -1):
            unos = sum((c >> bit) & 1 for c in mitad)
            if unos == len(mitad):
                fijos.append("bit %d siempre a UNO" % bit)
            elif unos == 0:
                fijos.append("bit %d siempre a CERO" % bit)
        print("     %s: %s" % (etq2, ", ".join(fijos) if fijos else "ningun bit fijo"))
    print("     bytes iguales a distancia k:", end=" ")
    for k in (1, 2, 3, 4, 8, 256):
        if k < len(b):
            ig = sum(1 for i in range(len(b) - k) if b[i] == b[i + k])
            print("k=%d:%.0f%%" % (k, 100 * ig / (len(b) - k)), end="  ")
    print()
    mas = Counter(b).most_common(4)
    print("     mas frecuentes: %s" % ", ".join("0x%02X x%d" % (v, n) for v, n in mas))
    if len(b) >= 512:
        bloques = [b[i:i + 256] for i in range(0, len(b) - 255, 256)]
        d = [hamming(x, y) for i, x in enumerate(bloques) for y in bloques[i + 1:]]
        print("     %d bloques de 256 B: se diferencian en %.0f bits de 2048 (%.1f%%)"
              % (len(bloques), sum(d) / len(d), 100 * sum(d) / len(d) / 2048))


POP = [bin(i).count("1") for i in range(256)]


def hamming(x, y):
    return sum(POP[p ^ q] for p, q in zip(x, y))


def esperado_ram(a):
    """La regla de RAM recien encendida que SI cumplen las otras zonas de basura."""
    return 0xFF if ((a >> 0) & 1) == ((a >> 7) & 1) else 0x00


def depende_de_la_direccion(datos, base):
    """La mejor pista que hay: el contenido parece dictarlo la direccion.

    Se mide de tres formas, y las tres dicen lo mismo. Ojo con la ultima: es la
    que impide dar el caso por cerrado.
    """
    print("  La pista: el contenido lo dicta la direccion")
    print("     polaridad de cada bit contra 'direccion par -> 1, impar -> 0':")
    for bit in range(7, -1, -1):
        ok = sum(1 for i, c in enumerate(datos)
                 if ((c >> bit) & 1) == (1 if (base + i) % 2 == 0 else 0))
        pct = 100.0 * ok / len(datos)
        nota = "  <- lo cumple" if pct > 85 else ("  <- cumple el INVERSO" if pct < 25 else "")
        print("        bit %d: %5.1f%%%s" % (bit, pct, nota))
    ff = [base + i for i, c in enumerate(datos) if c == 0xFF and (base + i) % 2 == 1]
    print("     0xFF en direccion impar: %d, y %d de ellos en direccion == 0x7F (mod 128)"
          % (len(ff), sum(1 for a in ff if (a & 0x7F) == 0x7F)))
    bits = sum(8 - POP[c ^ esperado_ram(base + i)] for i, c in enumerate(datos))
    print("     encaje con la regla de RAM de encendido de esta cinta: %.1f%%"
          % (100.0 * bits / (len(datos) * 8)))


def control(cm2):
    """La misma medida sobre el decorado que SI se ve, para tener con que comparar."""
    v = cm2[0xA000 - ORG_CM2:0xA400 - ORG_CM2]
    bloques = [v[i:i + 256] for i in range(0, 1024, 256)]
    d = [hamming(x, y) for i, x in enumerate(bloques) for y in bloques[i + 1:]]
    print("  Control, la misma medida sobre el decorado que SI se ve:")
    print("     %d bloques de 256 B: %.0f bits de 2048 (%.1f%%).  El azar da 1024 (50,0%%)."
          % (len(bloques), sum(d) / len(d), 100 * sum(d) / len(d) / 2048))
    print()
    print("  Control, el encaje con la regla de RAM de las zonas YA identificadas:")
    var = cm2  # el area de variables esta en CM1; aqui va el decorado como contraste
    bits = sum(8 - POP[c ^ esperado_ram(0xA000 + i)] for i, c in enumerate(v_slice(var)))
    print("     el mapa del nivel 1, que es un dato de verdad: %.1f%% (o sea, nada)"
          % (100.0 * bits / (len(v_slice(var)) * 8)))
    print("     las otras zonas de basura de la cinta dan 99,3% y 100,0%: ver")
    print("     la seccion 'Y sin embargo' de docs/es/BYTES-MUERTOS.md")


def v_slice(cm2):
    return cm2[0xA000 - ORG_CM2:0xA400 - ORG_CM2]


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    work = argv[1]
    salida = argv[2] if len(argv) > 2 else work
    cm2 = open(os.path.join(work, "CM2.raw"), "rb").read()

    trozos = {}
    for nombre, ini, fin, _ in TROZOS:
        trozos[nombre] = cm2[ini - ORG_CM2:fin - ORG_CM2]

    mapas = trozos["mapa1"] + trozos["mapa2"]
    cola = trozos["cola"]
    for fichero, datos in (("misterio.bin", mapas + cola),
                           ("misterio_mapas.bin", mapas),
                           ("misterio_cola.bin", cola)):
        with open(os.path.join(salida, fichero), "wb") as f:
            f.write(datos)

    total = len(mapas) + len(cola)
    print()
    print("  Los %d bytes sin identificar de Colt 36" % total)
    print("  " + "-" * 58)
    for nombre, ini, fin, desc in TROZOS:
        print("  0x%04X-0x%04X  %5d B   %s" % (ini, fin - 1, fin - ini, desc))
    print()
    print("  La segunda mitad del primer trozo es identica al segundo: %s"
          % (trozos["mapa1"][512:] == trozos["mapa2"]))
    print()
    firma(mapas, "los 1536 de los decorados")
    print()
    depende_de_la_direccion(trozos["mapa1"], 0xA400)
    print()
    control(cm2)
    print()
    firma(cola, "la cola de 30")
    print()
    print("  Escritos en %s: misterio.bin (%d B), misterio_mapas.bin (%d B), "
          "misterio_cola.bin (%d B)" % (salida, total, len(mapas), len(cola)))
    print()
    print("  Lo ya descartado, con su medida, esta en docs/es/BYTES-MUERTOS.md")
    print("  (o docs/DEAD-BYTES.md). Si encuentras lo que son, se agradece un")
    print("  aviso: lo que hace falta no es la idea sino la medida que la sostiene.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
