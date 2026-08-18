#!/usr/bin/env python3
"""Lo que la portada dice del listado tiene que ser verdad.

La cifra de etiquetas bautizadas estaba escrita a mano en tools/make_web.py y
no la vigilaba nadie: se podia quedar desfasada sin que saltara nada.
"""
import glob
import os
import re
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


class TestLaCifraDeLaPortada(unittest.TestCase):
    """La portada publica cuantas etiquetas con nombre tiene el listado.

    Estaba escrita a mano en tools/make_web.py y no la vigilaba nadie, asi que
    podia quedarse desfasada sin que saltara nada. Las DATA_ de los bloques de
    datos NO cuentan: se publican aparte, como rangos de datos.
    """

    def test_las_etiquetas_bautizadas_son_las_que_publica_la_web(self):
        et = set()
        for fichero in glob.glob(os.path.join(RAIZ, "src", "*.asm")):
            with open(fichero, encoding="utf-8") as f:
                for nombre in re.findall(r"(?m)^([A-Za-z_]\w*):", f.read()):
                    if not nombre.startswith("DATA_"):
                        et.add(nombre)
        with open(os.path.join(RAIZ, "tools", "make_web.py"), encoding="utf-8") as f:
            web = f.read()
        publicadas = re.findall(r'\("(\d+)", "(?:routines and tables named|'
                                r'rutinas y tablas bautizadas)"\)', web)
        self.assertEqual(len(set(publicadas)), 1,
                         "la cifra no se publica igual en los dos idiomas")
        self.assertEqual(int(publicadas[0]), len(et),
                         "la portada publica %s etiquetas y el listado tiene %d"
                         % (publicadas[0], len(et)))


if __name__ == "__main__":
    unittest.main()
