"""Comprueba que lo que decimos de la cinta es lo que la cinta trae.

Estos tests no miran el analisis ni la documentacion: miran el binario. Sirven
para que, si algun dia se cambia una herramienta y deja de extraer lo mismo, se
entere alguien antes de publicarlo.

Los que necesitan la cinta se saltan solos si no esta, porque no se distribuye.
"""
import hashlib
import json
import os
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(RAIZ, "work")
TSX = os.path.join(RAIZ, "colt36.tsx")
TSX_SHA = "4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13"

# El bloque del logo de Topo Soft, que no es exclusivo de este juego. Es el sha
# del CUERPO, sin los seis bytes de cabecera BIN: el bloque completo tal y como
# viene en la cinta da otro (2921e0f2...), y confundir los dos es facil.
TOPO_SHA = "695cd61a49eb87570f1404c47821d69c2997c5d845f7c48371a46a472b89932d"


def hay(*partes):
    return os.path.exists(os.path.join(WORK, *partes))


def leer(nombre):
    with open(os.path.join(WORK, nombre), "rb") as f:
        return f.read()


sin_extraer = unittest.skipUnless(
    hay("bloques.json"), "hace falta 'make extract' (y la cinta) para esto"
)
# La cinta no se distribuye con el repositorio (ver AVISO-LEGAL.md), asi que los
# tests que la necesitan se saltan solos en una copia recien descargada. No son
# tests desactivados: en cuanto pones tu TSX en la raiz, se ejecutan todos.
sin_cinta = unittest.skipUnless(
    os.path.exists(TSX), "la cinta no se distribuye con el repositorio"
)
sin_montar = unittest.skipUnless(
    hay("cm1_basic.bin"), "hace falta 'make' para esto"
)


class TestCinta(unittest.TestCase):
    @sin_cinta
    def test_la_cinta_es_la_que_documentamos(self):
        with open(TSX, "rb") as f:
            self.assertEqual(hashlib.sha256(f.read()).hexdigest(), TSX_SHA)

    @sin_extraer
    def test_las_cabeceras_bin_son_las_documentadas(self):
        """Las direcciones de carga y arranque que publicamos salen de aqui."""
        with open(os.path.join(WORK, "bloques.json")) as f:
            b = json.load(f)
        esperado = {
            "topo": (0x9470, 0xA50D, 0x9470, 4254),
            "scr": (0x9C40, 0xB7FB, 0xB798, 7100),
            "CM2": (0x9B91, 0xE340, 0x9BBA, 18352),
            "CM1": (0x83E8, 0x949C, 0x948F, 4277),
        }
        for nombre, (carga, final, arranque, tam) in esperado.items():
            with self.subTest(bloque=nombre):
                self.assertEqual(b[nombre]["carga"], carga)
                self.assertEqual(b[nombre]["final"], final)
                self.assertEqual(b[nombre]["arranque"], arranque)
                self.assertEqual(b[nombre]["tam"], tam)

    @sin_extraer
    def test_el_logo_de_topo_no_es_de_este_juego(self):
        """El bloque del logo es una pieza que Topo Soft reutilizaba tal cual.

        Se comprueba para poder decirlo en la documentacion sin que sea una
        impresion: es el mismo binario, byte a byte.
        """
        self.assertEqual(hashlib.sha256(leer("topo.raw")).hexdigest(), TOPO_SHA)

    @sin_extraer
    def test_el_unico_relleno_de_la_cinta_es_un_byte(self):
        """Ni un byte de la cinta sin justificar, tampoco los que sobran."""
        with open(os.path.join(WORK, "bloques.json")) as f:
            b = json.load(f)
        rellenos = {n: v["relleno"] for n, v in b.items() if v["relleno"]}
        self.assertEqual(rellenos, {"CM1": 1})
        self.assertEqual(leer("CM1.relleno"), b"\xff")


class TestArranque(unittest.TestCase):
    """El bloque del juego se copia a si mismo antes de arrancar."""

    @sin_extraer
    def test_el_recolocador_dice_lo_que_decimos_que_dice(self):
        cm1 = leer("CM1.raw")
        # El arranque declarado en la cabecera BIN, 0x948F, con CM1 cargado en
        # 0x83E8, cae en este offset del cuerpo.
        off = 0x948F - 0x83E8
        recolocador = bytes.fromhex(
            "21 e8 83"     # LD HL,0x83E8   de donde se ha cargado
            "11 00 80"     # LD DE,0x8000   a donde se va a ejecutar
            "01 b5 10"     # LD BC,0x10B5   el bloque entero
            "ed b0"        # LDIR
            "c3 88 90"     # JP 0x9088      el arranque, ya en su sitio
        )
        self.assertEqual(cm1[off:off + len(recolocador)], recolocador)

    @sin_extraer
    def test_el_ldir_mueve_el_bloque_entero(self):
        """El LDIR copia 0x10B5 bytes, que son exactamente los que mide CM1."""
        self.assertEqual(0x10B5, len(leer("CM1.raw")))


class TestImagenDeRam(unittest.TestCase):
    """La imagen sobre la que se analiza el juego es la RAM de verdad.

    tools/monta_ram.py reconstruye la memoria a mano reproduciendo el LDIR del
    recolocador. Es determinista, pero es una reconstruccion nuestra: si el
    razonamiento estuviese mal, todo el analisis colgaria de un error. Este test
    la contrasta contra la RAM que deja openMSX cargando la cinta original
    (make ram). Se salta si ese volcado no esta hecho.
    """

    RAM = os.path.join(RAIZ, "dump", "ram_al_arrancar.bin")
    IMG = os.path.join(RAIZ, "dump", "juego64.bin")

    # Los dos trozos que ocupa el juego al arrancar, ya recolocado.
    ZONAS = [("CM1", 0x8000, 0x90B4), ("CM2", 0x9B91, 0xE340)]

    sin_ram = unittest.skipUnless(
        os.path.exists(RAM) and os.path.exists(IMG),
        "hace falta 'make ram' (openMSX y la cinta) para esto",
    )

    @sin_ram
    def test_la_imagen_montada_es_la_ram_real(self):
        with open(self.RAM, "rb") as f:
            real = f.read()
        with open(self.IMG, "rb") as f:
            img = f.read()
        for nombre, a, b in self.ZONAS:
            with self.subTest(zona=nombre):
                self.assertEqual(real[a:b + 1], img[a:b + 1])


class TestRepartoCM1(unittest.TestCase):
    """CM1 se parte en programa BASIC + variables + arranque, sin huecos."""

    @sin_montar
    def test_los_tres_trozos_dan_cm1(self):
        trozos = b"".join(
            leer(f"cm1_{n}.bin") for n in ("basic", "vars", "arranque")
        )
        self.assertEqual(trozos, leer("CM1.raw"))

    @sin_montar
    def test_los_tamanos_son_los_publicados(self):
        self.assertEqual(len(leer("cm1_basic.bin")), 3935)
        self.assertEqual(len(leer("cm1_vars.bin")), 297)
        self.assertEqual(len(leer("cm1_arranque.bin")), 45)


if __name__ == "__main__":
    unittest.main()
