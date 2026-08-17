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

Cada medida va con su CONTROL: la misma cuenta hecha sobre bytes de esta cinta
de los que si se sabe lo que son. Una cifra sola no dice nada; lo que dice algo
es la distancia entre la cifra de los sospechosos y la del control.
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


def bits_de(bloque):
    """Los bits de un bloque como lista de 0/1, bit 7 primero."""
    out = []
    for b in bloque:
        for k in range(7, -1, -1):
            out.append((b >> k) & 1)
    return out


def plantilla_validada(bloques):
    """El motivo de 256 bytes, medido SIN hacerse trampas.

    Los bloques de 256 se parecen entre si; la forma honrada de medir cuanto es
    dejar uno fuera, votar la plantilla bit a bit con los demas, y contar
    cuantos bits del bloque apartado -que no ha votado- reproduce. Devuelve los
    aciertos (de 2048) por cada bloque dejado fuera.
    """
    bb = [bits_de(b) for b in bloques]
    n = len(bb[0])
    res = []
    for fuera in range(len(bb)):
        dentro = [bb[i] for i in range(len(bb)) if i != fuera]
        aciertos = 0
        for pos in range(n):
            voto = 1 if sum(d[pos] for d in dentro) * 2 > len(dentro) else 0
            aciertos += (voto == bb[fuera][pos])
        res.append(aciertos)
    return res, n


def mejor_xor(datos, base, nbits=12):
    """Para cada bit de dato, el mejor 'XOR de bits de la direccion' posible.

    Es la idea de 'el contenido lo dicta la direccion' llevada al limite: se
    prueban por fuerza bruta las 8192 combinaciones por bit (todas las mascaras
    de los 12 bits bajos, con y sin inversion) y se queda la que mas acierta.
    El truco para que sea instantaneo: los predictores se recorren en codigo
    Gray, cada paso es UN xor de enteros grandes, y los aciertos los da
    bit_count. Devuelve [(aciertos, mascara, inversion)] por bit de dato.
    """
    n = len(datos)
    bases = []
    for j in range(nbits):
        v = 0
        for i in range(n):
            if ((base + i) >> j) & 1:
                v |= 1 << i
        bases.append(v)
    resultado = []
    for bit in range(8):
        d = 0
        for i in range(n):
            if (datos[i] >> bit) & 1:
                d |= 1 << i
        mejor = (-1, 0, 0)
        pred, g_ant = 0, 0
        for k in range(1 << nbits):
            g = k ^ (k >> 1)
            if k:
                pred ^= bases[(g ^ g_ant).bit_length() - 1]
            g_ant = g
            coinc = n - (pred ^ d).bit_count()
            if coinc > mejor[0]:
                mejor = (coinc, g, 0)
            if n - coinc > mejor[0]:
                mejor = (n - coinc, g, 1)
        resultado.append(mejor)
    return resultado


def suma_xor(datos, base):
    r = mejor_xor(datos, base)
    return sum(a for a, _, _ in r), 8 * len(datos)


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


VISIBLE = [0x400, 0x600, 0x800, 0x800]   # lo que el tope del scroll deja ver de cada tablero


def tableros(cm2):
    return [cm2[0xA000 + 0x800 * i - ORG_CM2:0xA800 + 0x800 * i - ORG_CM2] for i in range(4)]


def filas_visibles(cm2):
    """Todas las filas de 32 tiles que el juego llega a ensenar."""
    out = []
    for m, v in zip(tableros(cm2), VISIBLE):
        out += [m[f:f + 32] for f in range(0, v, 32)]
    return out


def la_plantilla(cm2, sosp):
    """La medida mas fuerte: una plantilla de 256 bytes repetida seis veces."""
    print("  Una plantilla de 256 bytes, repetida con variaciones")
    print("     (se deja un bloque fuera, se vota la plantilla con los otros tres")
    print("      y se cuenta cuanto acierta sobre el que no ha votado)")
    for etq, datos in (("los sospechosos      ", sosp),
                       ("CONTROL decorado visible", v_slice(cm2)),
                       ("CONTROL tabla de dibujos", cm2[0xC000 - ORG_CM2:0xC400 - ORG_CM2])):
        res, n = plantilla_validada([datos[i * 256:(i + 1) * 256] for i in range(4)])
        print("     %s: %s  -> %.1f%% de sus bits"
              % (etq, " ".join("%d" % r for r in res), 100.0 * sum(res) / (len(res) * n)))
    print("     El azar da 50%. Lo de al lado, que es un dato de verdad, se queda ahi.")


def xor_de_la_direccion(cm2, work):
    """Hasta donde llega 'el contenido lo dicta la direccion' si se ajusta del todo."""
    print("  Cuanto explica la direccion, ajustando el mejor XOR de sus bits")
    filas = [("los sospechosos de 0xA400", cm2[0xA400 - ORG_CM2:0xA800 - ORG_CM2], 0xA400),
             ("los sospechosos de 0xAE00", cm2[0xAE00 - ORG_CM2:0xB000 - ORG_CM2], 0xAE00),
             ("CONTROL decorado visible ", v_slice(cm2), 0xA000),
             ("CONTROL tabla de dibujos ", cm2[0xC000 - ORG_CM2:0xC400 - ORG_CM2], 0xC000)]
    # los dos controles positivos viven en otros bloques de la cinta
    try:
        scr = open(os.path.join(work, "scr.raw"), "rb").read()
        filas.append(("RAM de encendido: los 88 ", scr[6912:7000], 0xB740))
    except OSError:
        pass
    try:
        cm1 = open(os.path.join(work, "CM1.raw"), "rb").read()
        filas.append(("RAM de encendido: los 285", cm1[0x8F6B - 0x8000:0x9088 - 0x8000], 0x8F6B))
    except OSError:
        pass
    for etq, datos, base in filas:
        ok, tot = suma_xor(datos, base)
        print("     %s: %5d de %5d bits (%.1f%%)" % (etq, ok, tot, 100.0 * ok / tot))
    print("     La RAM de encendido de verdad se explica ENTERA con la direccion.")
    print("     Los sospechosos no llegan, y un dato normal se queda mas abajo:")
    print("     tienen estructura de direccion, pero no son ese tipo de basura.")


def lente_de_tablero(cm2, sosp):
    """Leidos como lo que tienen al lado: filas de 32 tiles de un decorado."""
    print("  Leidos como decorado, que es lo que tienen al lado")
    vis = set()
    for m, v in zip(tableros(cm2), VISIBLE):
        vis |= set(m[:v])
    ts = set(sosp)
    print("     valores que usan: %d ; tiles que usan los decorados de verdad: %d ; en comun: %d"
          % (len(ts), len(vis), len(ts & vis)))
    t3 = set(tableros(cm2)[2][:0x400])
    t4 = set(tableros(cm2)[3][:0x400])
    print("     CONTROL, dos decorados de verdad entre si: %d valores, %d en comun"
          % (len(t3), len(t3 & t4)))
    pares = Counter()
    for i in range(0, len(sosp), 2):
        pares[(sosp[i], sosp[i + 1])] += 1
    top = pares.most_common(6)
    print("     sus parejas mas repetidas: %s"
          % ", ".join("%02X %02X x%d" % (x, y, n) for (x, y), n in top))
    fv = filas_visibles(cm2)
    en_vis = sum(1 for (x, y), _ in top for f in fv for c in range(0, 32, 2)
                 if f[c] == x and f[c + 1] == y)
    print("     esas seis parejas, en los decorados que si se ven: %d veces" % en_vis)
    mejor = max(sum(1 for k in range(32) if sosp[i + k] == f[k])
                for i in range(0, len(sosp), 32) for f in fv)
    print("     y la fila suya que mas se parece a una de verdad: %d casillas de 32" % mejor)


def lente_de_color(cm2, sosp):
    """La medida que mas les favorece: los impares, leidos como bytes de color."""
    print("  Leidos como parejas (dibujo, color), que es donde mejor encajan")
    imp = sosp[1::2]
    bajo = Counter(b & 15 for b in imp).most_common(1)[0]
    print("     de sus 768 bytes impares, %d llevan el fondo %X: el %.1f%%"
          % (bajo[1], bajo[0], 100.0 * bajo[1] / len(imp)))
    pareja = Counter((b >> 4, b & 15) for b in imp).most_common(1)[0]
    print("     y la pareja tinta/fondo %X sobre %X sale %d veces, el %.1f%%"
          % (pareja[0][0], pareja[0][1], pareja[1], 100.0 * pareja[1] / len(imp)))
    col = cm2[0xC800 - ORG_CM2:0xD000 - ORG_CM2]
    c = Counter(b & 15 for b in col).most_common(1)[0]
    print("     CONTROL, la tabla de color de verdad: su fondo %X sale el %.1f%%"
          % (c[0], 100.0 * c[1] / len(col)))
    m = Counter(b & 15 for b in v_slice(cm2)).most_common(1)[0]
    print("     CONTROL, el decorado (que no es color): su nibble bajo sale el %.1f%%"
          % (100.0 * m[1] / len(v_slice(cm2))))
    print("     O sea que como color se comportan MEJOR que la tabla de color del juego.")


def lente_de_musica(cm2, sosp):
    """El reproductor de la cinta lee un byte por paso: o nota, o 0xFE, o 0xFF."""
    def validos(b):
        return sum(1 for x in b if x <= 0x59 or x in (0xFE, 0xFF))
    mel = cm2[0x9D7D - ORG_CM2:0xA000 - ORG_CM2]
    print("  Leidos como musica, con el formato del reproductor de esta misma cinta")
    print("     las melodias de verdad: %d de %d bytes son eventos validos (todos)"
          % (validos(mel), len(mel)))
    print("     los sospechosos:        %d de %d (%.1f%%), o sea que no lo son"
          % (validos(sosp), len(sosp), 100.0 * validos(sosp) / len(sosp)))


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
    la_plantilla(cm2, trozos["mapa1"])
    print()
    xor_de_la_direccion(cm2, work)
    print()
    lente_de_tablero(cm2, mapas)
    print()
    lente_de_color(cm2, mapas)
    print()
    lente_de_musica(cm2, mapas)
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
