"""Comprueba que lo que dice la documentacion es lo que hace el juego.

Estos tests existen porque los datos publicados se desactualizan solos. Un
comentario que era cierto cuando se escribio sigue ahi cuando deja de serlo, y
la comprobacion de reproducibilidad no se entera de nada: los bytes no cambian,
solo lo que decimos de ellos.

Asi que aqui se cogen las afirmaciones CONCRETAS del listado comentado y se
contrastan contra el binario. Si alguna deja de ser cierta, esto se pone rojo.

Se saltan solos si no esta la cinta extraida, porque no se distribuye.
"""
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(RAIZ, "work")
SRC = os.path.join(RAIZ, "src")

CM2_ORG = 0x9B91


def hay(*p):
    return os.path.exists(os.path.join(*p))


sin_cm2 = unittest.skipUnless(hay(WORK, "CM2.raw"), "hace falta 'make extract' para esto")
sin_cm1 = unittest.skipUnless(hay(WORK, "CM1.raw"), "hace falta 'make extract' para esto")
sin_bas = unittest.skipUnless(hay(SRC, "colt36.bas"), "falta el listado del juego")


def cm2():
    with open(os.path.join(WORK, "CM2.raw"), "rb") as f:
        return f.read()


def sl(d, a, b):
    return d[a - CM2_ORG:b - CM2_ORG]


def listado():
    with open(os.path.join(SRC, "colt36.bas"), encoding="latin-1") as f:
        return f.read()


def lineas_basic():
    """Las lineas del juego, sin nuestros comentarios: {numero: texto}."""
    out = {}
    for ln in listado().splitlines():
        if not ln or ln.lstrip().startswith("#"):
            continue
        num, _, resto = ln.partition(" ")
        out[int(num)] = resto
    return out


class TestElMarcador(unittest.TestCase):
    """Publicamos que la puntuacion se ve multiplicada por cien. A ver."""

    @sin_cm2
    def test_el_marcador_trae_seis_ceros_y_el_juego_escribe_cuatro(self):
        d = cm2()
        marcador = sl(d, 0xD300, 0xD400)          # 8 filas, van a las filas 16..23
        fila22 = marcador[(22 - 16) * 32:(22 - 16) * 32 + 32]
        ceros = [c for c, t in enumerate(fila22) if t == 156]   # 156 es el dibujo del '0'
        self.assertEqual(ceros, [1, 2, 3, 4, 5, 6], "el marcador deberia traer seis ceros")

        # Y el programa solo escribe cuatro, en 6849..6852 = fila 22, columnas 1..4.
        escritas = sorted(
            (a - 6144) % 32
            for a in (6849, 6850, 6851, 6852)
        )
        self.assertEqual(escritas, [1, 2, 3, 4])
        for a in (6849, 6850, 6851, 6852):
            self.assertEqual((a - 6144) // 32, 22)
        # O sea que las columnas 5 y 6 no las toca nadie: de ahi el x100.
        self.assertEqual(set(ceros) - set(escritas), {5, 6})

    @sin_bas
    def test_el_listado_escribe_esas_cuatro_direcciones(self):
        self.assertIn("VPOKE6849", lineas_basic()[10])
        self.assertIn("VPOKE6852", lineas_basic()[10])


class TestLosNiveles(unittest.TestCase):
    """Publicamos cuatro niveles, con sus nombres y su altura util."""

    NOMBRES = ["000EL0ALMACEN", "0000EL0CA[ON", "0000LA0MINA", "0000EL0SALOON"]

    @sin_bas
    def test_los_nombres_salen_del_data_del_juego(self):
        data = lineas_basic()[3000]
        for n in self.NOMBRES:
            self.assertIn(f'"{n}"', data)

    @sin_bas
    def test_el_data_tiene_quince_elementos(self):
        """Cuatro niveles, seis huecos de relleno y cinco calificaciones."""
        elementos = re.findall(r'"[^"]*"', lineas_basic()[3000])
        self.assertEqual(len(elementos), 15)
        self.assertEqual(elementos[4:10], ['""'] * 6)

    def test_los_topes_de_scroll_dan_la_altura_que_publicamos(self):
        """La formula de la linea 610, evaluada como lo haria MSX-BASIC.

        Publicamos 32 filas para el nivel 1, 48 para el 2 y 64 para el 3 y el 4.
        """
        alturas = {}
        for n in (1, 2, 3, 4):
            # En BASIC lo cierto vale -1, y de ahi el ultimo termino.
            tope = 0xE200 - 512 * (4 - n) + 512 * (-1 if n == 4 else 0)
            visible_hasta = tope + 512          # el tope, mas la ventana de 512
            alturas[n] = (visible_hasta - 0xDA00) // 32
        self.assertEqual(alturas, {1: 32, 2: 48, 3: 64, 4: 64})

    @sin_bas
    def test_la_formula_del_tope_es_la_que_esta_en_el_listado(self):
        self.assertIn("&HE200-512*(4-N%)+512*(N%=4)", lineas_basic()[610])


class TestLosBandidos(unittest.TestCase):
    """Publicamos: diez escondites por nivel, cuatro modelos, cinco fotogramas."""

    @sin_cm2
    def test_diez_escondites_por_nivel_de_cuatro_bytes(self):
        d = cm2()
        tabla = sl(d, 0xD900, 0xD9A0)
        self.assertEqual(len(tabla), 4 * 10 * 4)
        for nivel in range(4):
            for i in range(10):
                fila, col, modelo, ps = tabla[nivel * 40 + i * 4:nivel * 40 + i * 4 + 4]
                with self.subTest(nivel=nivel + 1, escondite=i):
                    self.assertIn(modelo, (1, 2, 3, 4), "el modelo va de 1 a 4")
                    self.assertLess(col, 32, "la columna cabe en el tablero")
                    self.assertTrue(188 <= ps <= 207, "el retardo de salida va de 188 a 207")

    @sin_cm2
    def test_ningun_escondite_cae_fuera_de_la_parte_visible_de_su_nivel(self):
        """Si uno cayera mas abajo del tope de scroll, seria un bandido invisible."""
        d = cm2()
        tabla = sl(d, 0xD900, 0xD9A0)
        limite = {1: 32, 2: 48, 3: 64, 4: 64}
        for nivel in range(1, 5):
            filas = [tabla[(nivel - 1) * 40 + i * 4] for i in range(10)]
            with self.subTest(nivel=nivel):
                self.assertLess(max(filas), limite[nivel])

    def test_los_numeros_de_dibujo_de_cada_modelo(self):
        """C%=150+20*MD%+desplazamiento, con desplazamientos 4, 8, 12, 16 y 20.

        Publicamos que el modelo 1 ocupa del 174 al 193, y asi los cuatro. Y que
        el umbral de "esto es un bandido" de la linea 340 es 174, que es
        justamente el primero.
        """
        rangos = {}
        for md in (1, 2, 3, 4):
            base = 150 + 20 * md
            # Cada fotograma son cuatro casillas: C%, C%+1, C%+2 y C%+3.
            tiles = [base + desp + k for desp in (4, 8, 12, 16, 20) for k in range(4)]
            rangos[md] = (min(tiles), max(tiles))
        self.assertEqual(rangos, {1: (174, 193), 2: (194, 213),
                                  3: (214, 233), 4: (234, 253)})
        self.assertEqual(rangos[1][0], 174)

    @sin_bas
    def test_el_umbral_174_esta_en_el_listado(self):
        self.assertIn("PI%<174", lineas_basic()[340])


class TestLosObjetosRompibles(unittest.TestCase):
    """Publicamos: los dibujos 71 a 78 se rompen y valen de 1 a 8 puntos."""

    @sin_bas
    def test_el_listado_hace_lo_que_decimos(self):
        l = lineas_basic()
        self.assertIn("PI%>70", l[305])      # por debajo de 71 no vale nada
        self.assertIn("PI%>78", l[320])      # por encima de 78 ya no es rompible
        self.assertIn("PI%+8", l[325])       # la version rota esta 8 mas alla
        self.assertIn("PT%+PI%-70", l[325])  # y vale de 1 a 8 puntos

    @sin_cm2
    def test_los_cuatro_decorados_llevan_objetos_rompibles(self):
        d = cm2()
        utiles = {1: (0xA000, 0xA400), 2: (0xA800, 0xAE00),
                  3: (0xB000, 0xB800), 4: (0xB800, 0xC000)}
        for nivel, (a, b) in utiles.items():
            with self.subTest(nivel=nivel):
                mapa = sl(d, a, b)
                rompibles = [t for t in mapa if 71 <= t <= 78]
                self.assertTrue(rompibles, "un nivel sin nada que romper seria raro")


class TestElCodigoMuerto(unittest.TestCase):
    """Publicamos que la linea 730 no la alcanza nadie."""

    @sin_bas
    def test_a_la_730_no_salta_nadie(self):
        l = lineas_basic()
        self.assertIn(730, l, "la linea 730 tiene que seguir existiendo")
        for num, texto in l.items():
            if num == 730:
                continue
            for destino in re.findall(r"(?:GOTO|GOSUB|THEN|ELSE)\s*(\d+)", texto):
                self.assertNotEqual(int(destino), 730,
                                    f"la linea {num} salta a la 730")
        # Y el reparto de la 640 tampoco la lista.
        self.assertNotIn("730", l[640])

    @sin_bas
    def test_la_linea_anterior_acaba_en_goto_asi_que_tampoco_se_cae_dentro(self):
        self.assertTrue(lineas_basic()[720].rstrip().endswith("GOTO 650"))


class TestLasRutinasDeCodigoMaquina(unittest.TestCase):
    """Publicamos donde estan y que hacen las cuatro rutinas USR."""

    @sin_bas
    def test_las_direcciones_publicadas_son_las_que_declara_el_juego(self):
        l500 = lineas_basic()[500]
        for defusr in ("DEFUSR1=&HE300", "DEFUSR2=&HE313", "DEFUSR3=&H41",
                       "DEFUSR4=&H44", "DEFUSR5=&H9B91", "DEFUSR6=&H9BBB"):
            self.assertIn(defusr, l500)

    @sin_cm2
    def test_usr1_es_una_llamada_a_la_rutina_de_video_del_sistema(self):
        d = cm2()
        usr1 = sl(d, 0xE300, 0xE311)
        self.assertEqual(usr1, bytes.fromhex(
            "2a e1 d9"     # LD HL,(0xD9E1)  el cuanto
            "44 4d"        # LD B,H / LD C,L
            "2a e3 d9"     # LD HL,(0xD9E3)  el adonde
            "54 5d"        # LD D,H / LD E,L
            "2a e5 d9"     # LD HL,(0xD9E5)  el desde donde
            "cd 5c 00"     # CALL 0x005C     LDIRVM, la copia a video del sistema
            "c9"           # RET
        ))

    @sin_cm2
    def test_usr2_es_la_misma_pero_acabando_en_ldir(self):
        d = cm2()
        usr2 = sl(d, 0xE313, 0xE323)
        self.assertEqual(usr2[:13], sl(d, 0xE300, 0xE311)[:13],
                         "hasta el final son la misma rutina")
        self.assertEqual(usr2[13:], bytes.fromhex("ed b0 c9"))   # LDIR / RET

    @sin_cm2
    def test_el_arranque_declarado_de_cm2_es_un_ret(self):
        """Publicamos que cargar CM2 no hace nada. El arranque es 0x9BBA."""
        self.assertEqual(cm2()[0x9BBA - CM2_ORG], 0xC9)


class TestElJuegoDeCaracteres(unittest.TestCase):
    """Publicamos que el dibujo de una letra es su codigo ASCII mas 60."""

    @sin_bas
    def test_la_subrutina_15_suma_60(self):
        self.assertIn("+60", lineas_basic()[15])

    @sin_bas
    def test_el_cero_hace_de_espacio_en_los_textos(self):
        """Si '0' no fuera el hueco en blanco, los rotulos saldrian con ceros."""
        self.assertEqual(ord("0") + 60, 108)
        # Y por eso los textos del juego llevan '0' donde va un espacio.
        self.assertIn('"NIVEL00^"', lineas_basic()[31])

    @sin_bas
    def test_los_digitos_van_por_su_cuenta_con_el_156(self):
        for n in (10, 31, 597, 749):
            self.assertIn("156", lineas_basic()[n])


DOCS = os.path.join(RAIZ, "docs")
POP = [bin(i).count("1") for i in range(256)]


def doc(*p):
    with open(os.path.join(DOCS, *p), encoding="utf-8") as f:
        return f.read()


def hamming(x, y):
    return sum(POP[a ^ b] for a, b in zip(x, y))


def misterio():
    """Los 1536 bytes sin identificar, los del cartel."""
    d = cm2()
    return sl(d, 0xA400, 0xA800) + sl(d, 0xAE00, 0xB000)


class TestElCartelDelosBytesSinIdentificar(unittest.TestCase):
    """Las cifras del cartel SE BUSCA se publican; que sigan siendo verdad.

    Es la parte de la documentacion con mas riesgo de pudrirse, porque son
    medidas finas sobre unos bytes que nadie ha identificado. Si alguien afina
    una y no toca el texto, o al reves, esto se pone rojo.
    """

    @sin_cm2
    def test_son_1566_bytes(self):
        d = cm2()
        total = len(misterio()) + len(sl(d, 0xE323, 0xE341))
        self.assertEqual(total, 1566)
        self.assertIn("1566", doc("DEAD-BYTES.md"))
        self.assertIn("1566", doc("es", "BYTES-MUERTOS.md"))

    @sin_cm2
    def test_el_alfabeto_par_y_el_impar_solo_comparten_el_ff(self):
        b = misterio()
        par, imp = set(b[0::2]), set(b[1::2])
        self.assertEqual(len(par | imp), 55)
        self.assertEqual(len(par), 34)
        self.assertEqual(len(imp), 22)
        self.assertEqual(par & imp, {0xFF})

    @sin_cm2
    def test_el_bit_1_esta_puesto_en_todos_los_bytes_pares(self):
        pares = misterio()[0::2]
        self.assertEqual(len(pares), 768)
        self.assertTrue(all(c & 0x02 for c in pares))

    @sin_cm2
    def test_a_distancia_impar_no_coincide_ni_un_byte(self):
        b = misterio()
        for k in (1, 3):
            iguales = sum(1 for i in range(len(b) - k) if b[i] == b[i + k])
            self.assertEqual(iguales, 0, "a distancia %d si coinciden" % k)

    @sin_cm2
    def test_seis_bloques_de_256_casi_iguales_frente_al_decorado_que_si_se_ve(self):
        """La medida mas fuerte del cartel: 9,3 % contra 53,6 %."""
        def dispersion(datos, n):
            bl = [datos[i * 256:(i + 1) * 256] for i in range(n)]
            d = [hamming(x, y) for i, x in enumerate(bl) for y in bl[i + 1:]]
            return 100.0 * sum(d) / len(d) / 2048

        sospechosos = dispersion(misterio(), 6)
        visible = dispersion(sl(cm2(), 0xA000, 0xA400), 4)
        self.assertAlmostEqual(sospechosos, 9.3, places=1)
        self.assertAlmostEqual(visible, 53.6, places=1)
        # Y que sean las cifras que estan publicadas, con su coma o su punto.
        for ruta, cifras in ((("DEAD-BYTES.md",), ("9.3 %", "53.6 %")),
                             (("es", "BYTES-MUERTOS.md"), ("9,3 %", "53,6 %"))):
            t = doc(*ruta)
            for cifra in cifras:
                self.assertTrue(cifra in t, "falta %r en %s" % (cifra, "/".join(ruta)))


class TestElVolcadoPublicado(unittest.TestCase):
    """Los 1566 bytes se publican en la web y como fichero. Que sean los de verdad.

    Un volcado hexadecimal escrito en un documento es justo el tipo de cosa que
    se queda desfasada sin que nadie se entere, y aqui es el objeto entero de la
    pagina: si el volcado no fuera el de la cinta, lo que se discutiria seria una
    ficcion.
    """

    RANGOS = [(0xA400, 0xA800), (0xAE00, 0xB000), (0xE323, 0xE341)]

    def esperado(self):
        d = cm2()
        return b"".join(sl(d, a, b) for a, b in self.RANGOS)

    def del_documento(self, *ruta):
        """Saca los bytes de las lineas 'XXXX  AA BB CC ...' del documento."""
        out = bytearray()
        for ln in doc(*ruta).splitlines():
            m = re.match(r"^([0-9A-F]{4})  ((?:[0-9A-F]{2} ?)+)$", ln.strip())
            if m:
                out += bytes.fromhex(m.group(2).replace(" ", ""))
        return bytes(out)

    @sin_cm2
    def test_el_volcado_de_la_pagina_es_el_binario(self):
        for ruta in (("es", "BYTES-MUERTOS.md"), ("DEAD-BYTES.md",)):
            with self.subTest(doc="/".join(ruta)):
                publicado = self.del_documento(*ruta)
                self.assertEqual(len(publicado), 1566)
                self.assertEqual(publicado, self.esperado())

    @sin_cm2
    def test_el_fichero_del_repositorio_es_el_binario(self):
        ruta = os.path.join(RAIZ, "datos", "misterio.bin")
        self.assertTrue(os.path.exists(ruta), "falta datos/misterio.bin")
        with open(ruta, "rb") as f:
            self.assertEqual(f.read(), self.esperado())

    def test_el_sha_publicado_es_el_del_fichero(self):
        import hashlib
        ruta = os.path.join(RAIZ, "datos", "misterio.bin")
        if not os.path.exists(ruta):
            self.skipTest("falta datos/misterio.bin")
        with open(ruta, "rb") as f:
            sha = hashlib.sha256(f.read()).hexdigest()
        with open(os.path.join(RAIZ, "datos", "LEEME.md"), encoding="utf-8") as f:
            self.assertIn(sha, f.read())


class TestSeLeenPeroNoSeVen(unittest.TestCase):
    """Los 1536 bytes SI se leen y se copian; lo que no pasa es que se vean.

    Este test existe por una correccion que llego de fuera: alguien leyo que en
    esta pagina habia bytes 'que no lee nadie' y respondio, con razon, que USR2
    accede a 0xA400. Y es cierto: la linea 33 se lleva el mapa entero de 2048
    bytes al area de trabajo con un LDIR, y estos van dentro. Lo que no ocurre
    jamas es que lleguen a la pantalla. Confundir las dos cosas es facil, asi
    que aqui se fija la diferencia con numeros.
    """

    @sin_bas
    def test_la_linea_33_copia_el_mapa_entero_de_2048(self):
        l33 = lineas_basic()[33]
        self.assertIn("HL=&HA000+2048*(N%-1)", l33)
        self.assertIn("DE=&HDA00", l33)
        self.assertIn("BC=2048", l33)
        self.assertIn("USR2", l33)

    @sin_cm2
    def test_usr2_es_un_ldir_pelado(self):
        """0xE313: coge los tres parametros de 0xD9E1 y hace LDIR."""
        r = sl(cm2(), 0xE313, 0xE323)
        self.assertEqual(r[0], 0x2A)                 # ld hl,(nn)
        self.assertEqual(r[1] | (r[2] << 8), 0xD9E1)  # el contador
        self.assertEqual(r[13], 0xED)                # ldir
        self.assertEqual(r[14], 0xB0)
        self.assertEqual(r[15], 0xC9)                # ret

    def test_los_misteriosos_acaban_en_0xde00_y_la_ventana_para_en_0xddff(self):
        """La cuenta que lo explica todo: se copian, y se quedan un byte fuera."""
        destino = 0xDA00 + (0xA400 - 0xA000)
        self.assertEqual(destino, 0xDE00)
        # El tope de scroll del nivel 1 es 0xDC00 y la ventana son 512 bytes.
        ultimo_visible = 0xDC00 + 512 - 1
        self.assertEqual(ultimo_visible, 0xDDFF)
        self.assertEqual(destino - ultimo_visible, 1)

    def test_la_documentacion_hace_la_distincion(self):
        for ruta, frases in ((("es", "BYTES-MUERTOS.md"), ("se leen, y se copian", "no se ven")),
                             (("DEAD-BYTES.md",), ("are read, and they are copied", "never seen"))):
            t = doc(*ruta)
            for f in frases:
                self.assertIn(f, t, "falta %r en %s" % (f, "/".join(ruta)))


class TestLaPistaDeLaDireccion(unittest.TestCase):
    """La mejor pista publicada: el contenido de esos bytes lo dicta la direccion.

    Y, sobre todo, el contraste que impide darla por cerrada: NO cumplen la regla
    de RAM de encendido que si cumplen las otras zonas de basura de esta cinta.
    """

    @sin_cm2
    def test_la_polaridad_de_cada_bit_va_atada_a_la_paridad_de_la_direccion(self):
        b = sl(cm2(), 0xA400, 0xA800)

        def polaridad(bit):
            ok = sum(1 for i, c in enumerate(b)
                     if ((c >> bit) & 1) == (1 if (0xA400 + i) % 2 == 0 else 0))
            return 100.0 * ok / len(b)

        self.assertAlmostEqual(polaridad(1), 99.2, places=1)
        self.assertAlmostEqual(polaridad(3), 96.3, places=1)
        self.assertAlmostEqual(polaridad(7), 92.0, places=1)
        self.assertAlmostEqual(polaridad(0), 88.0, places=1)
        # Y estos dos cumplen la contraria, que es lo raro del asunto.
        self.assertAlmostEqual(polaridad(2), 20.1, places=1)
        self.assertAlmostEqual(polaridad(6), 18.8, places=1)

    @sin_cm2
    def test_los_ocho_ff_impares_caen_todos_en_el_mismo_punto_del_ciclo(self):
        b = sl(cm2(), 0xA400, 0xA800)
        ff = [0xA400 + i for i, c in enumerate(b) if c == 0xFF and (0xA400 + i) % 2]
        self.assertEqual(len(ff), 8)
        self.assertTrue(all((a & 0x7F) == 0x7F for a in ff))
        self.assertEqual(ff, [0xA47F, 0xA4FF, 0xA57F, 0xA5FF,
                              0xA67F, 0xA6FF, 0xA77F, 0xA7FF])

    @sin_cm2
    def test_no_son_la_ram_de_encendido_que_si_trae_esta_cinta(self):
        """El contraste que sostiene el 'y sin embargo' del documento."""
        def encaje(datos, base):
            bits = sum(8 - POP[c ^ (0xFF if (base + i) & 1 == ((base + i) >> 7) & 1 else 0)]
                       for i, c in enumerate(datos))
            return 100.0 * bits / (len(datos) * 8)

        d = cm2()
        self.assertAlmostEqual(encaje(sl(d, 0xA400, 0xA800), 0xA400), 47.7, places=1)
        self.assertAlmostEqual(encaje(sl(d, 0xAE00, 0xB000), 0xAE00), 46.4, places=1)
        # Un dato de verdad da lo mismo: o sea que el 47,7 % no significa nada.
        self.assertAlmostEqual(encaje(sl(d, 0xA000, 0xA400), 0xA000), 50.3, places=1)

    @sin_cm2
    def test_no_son_codigo_de_ninguna_cpu(self):
        d = cm2()
        mist = sl(d, 0xA400, 0xA800) + sl(d, 0xAE00, 0xB000) + sl(d, 0xE323, 0xE341)
        self.assertEqual(len(mist), 1566)
        self.assertEqual(len(set(mist)), 60)
        for opcode in (0xCD, 0xC9, 0xED, 0x18, 0x10, 0x01):
            self.assertEqual(mist.count(opcode), 0,
                             "el opcode 0x%02X no deberia aparecer" % opcode)
        # Control: 300 bytes de codigo Z80 de verdad de esta misma cinta.
        real = sl(d, 0x9B91, 0x9B91 + 300)
        self.assertGreater(len(set(real)), 60)
        self.assertGreater(real.count(0xCD), 0)

    @sin_cm2
    def test_no_son_un_dibujo_de_ningun_ancho(self):
        """Racha media de bits iguales: un dibujo la tiene MAS larga que el azar."""
        def racha(b):
            bits = "".join(format(c, "08b") for c in b)
            tot, n = [], 1
            for i in range(1, len(bits)):
                if bits[i] == bits[i - 1]:
                    n += 1
                else:
                    tot.append(n); n = 1
            tot.append(n)
            return sum(tot) / len(tot)

        d = cm2()
        mist = sl(d, 0xA400, 0xA800) + sl(d, 0xAE00, 0xB000) + sl(d, 0xE323, 0xE341)
        self.assertAlmostEqual(racha(mist), 1.63, places=2)
        self.assertGreater(racha(sl(d, 0xC000, 0xC600)), 3.5)   # los dibujos del juego
        self.assertGreater(racha(sl(d, 0xA000, 0xA400)), 3.5)   # el mapa del nivel 1
        # El azar da 2,00 exacto, asi que los sospechosos estan por DEBAJO.
        self.assertLess(racha(mist), 2.0)


class TestLaHuellaDeLaRamSinInicializar(unittest.TestCase):
    """Publicamos que el area de variables delata donde vivia el juego."""

    @sin_cm1
    def test_la_regla_encaja_en_0x8000_y_no_en_0x83e8(self):
        with open(os.path.join(WORK, "CM1.raw"), "rb") as f:
            cm1 = f.read()
        # CM1 se carga en 0x83E8 pero se ejecuta recolocado en 0x8000.
        ram = cm1[0x8F6B - 0x8000:0x9088 - 0x8000]
        self.assertEqual(len(ram), 285)

        def encaje(base):
            return sum(1 for i, b in enumerate(ram)
                       if b == (0xFF if ((base + i) & 1) == ((base + i) >> 7 & 1) else 0x00))

        self.assertEqual(encaje(0x8F6B), 282)
        self.assertEqual(encaje(0x8F6B + 0x3E8), 226)

    def test_las_cifras_publicadas_son_esas(self):
        for fichero in ("FINDINGS.md", os.path.join("es", "HALLAZGOS.md")):
            t = doc(fichero)
            self.assertIn("282", t)
            self.assertIn("226", t)


class TestLaFichaDeNivelQueNoSeBorra(unittest.TestCase):
    """Publicamos que la cuarta ficha del marcador no la borra nadie."""

    @sin_cm2
    def test_hay_cuatro_fichas_y_la_2010_solo_llega_a_tres(self):
        # El marcador se pinta con los 256 bytes de 0xD300 (linea 595).
        marcador = sl(cm2(), 0xD300, 0xD400)
        fichas = [c for c in range(32) if marcador[5 * 32 + c] == 182]
        self.assertEqual(fichas, [23, 25, 27, 29], "las cuatro fichas del marcador")
        # 2010 borra 6835+2*N%, y solo se ejecuta con N% = 2, 3 y 4.
        borradas = [(6835 + 2 * n) - 6656 - 5 * 32 for n in (2, 3, 4)]
        self.assertEqual(borradas, [23, 25, 27])
        self.assertNotIn(29, borradas)

    @sin_bas
    def test_la_formula_es_la_que_esta_en_el_listado(self):
        self.assertIn("D%=6835+2*N%", lineas_basic()[2010])

    @sin_cm2
    def test_el_marcador_trae_cinco_vidas_y_el_juego_pone_tres(self):
        marcador = sl(cm2(), 0xD300, 0xD400)
        # Fila 18 (la 2 del marcador, que empieza en la 16), columna 7.
        self.assertEqual(marcador[2 * 32 + 7], 161)      # 156 + 5
        self.assertEqual((6727 - 6144) // 32, 18)
        self.assertEqual((6727 - 6144) % 32, 7)          # la misma casilla

    @sin_bas
    def test_la_597_escribe_tres_encima(self):
        self.assertIn("V%=3:VPOKE6727,156+V%", lineas_basic()[597])


class TestElCreditoTapado(unittest.TestCase):
    """Publicamos que el tablero dice LUIGILOPEZ 87 PARA y que la 575 lo tapa."""

    @sin_cm2
    def test_el_tablero_lleva_el_credito_escrito_dentro(self):
        fila22 = sl(cm2(), 0xD000, 0xD300)[22 * 32:23 * 32]
        texto = "".join(chr(c - 60) if 60 <= c - 60 < 127 else "." for c in fila22)
        self.assertTrue(texto.startswith("LUIGILOPEZ"))
        self.assertIn("PARA", texto)
        # 'h' y 'g' son los dibujos 164 y 163: los digitos grandes 8 y 7.
        self.assertEqual((fila22[11], fila22[12]), (164, 163))

    @sin_bas
    def test_la_575_escribe_encima_a_partir_de_la_columna_14(self):
        l575 = lineas_basic()[575]
        self.assertIn("HL=718", l575)
        self.assertIn('"00MUSICA^GOMINOLAS"', l575)
        self.assertEqual(718 // 32, 22)          # misma fila
        self.assertEqual(718 % 32, 14)           # justo encima del PARA


if __name__ == "__main__":
    unittest.main()
