#!/usr/bin/env python3
"""Arma la imagen de 64K con el juego tal y como queda en la RAM al arrancar.

Hace falta porque los dos bloques del juego no se leen bien por separado: el
BASIC de CM1 llama a rutinas que estan en CM2, y CM1 ademas no se ejecuta donde
se carga. Sobre la imagen montada las direcciones significan lo que dicen.

Que hace, y por que:

  CM2  se carga en 0x9B91 y se queda donde esta.
  CM1  se carga en 0x83E8, pero su ultima rutina (el `exec` de la cabecera BIN,
       0x948F) es LD HL,0x83E8 / LD DE,0x8000 / LD BC,0x10B5 / LDIR / JP 0x9088,
       o sea que lo primero que hace el bloque es copiarse 0x3E8 bytes mas abajo.
       Aqui se reproduce esa copia.

La copia es determinista -no depende de la maquina ni del momento- asi que la
imagen se puede montar sin emulador. Aun asi conviene contrastarla contra la RAM
de openMSX de vez en cuando: para eso esta tools/omsx_dump.tcl.

Uso: monta_ram.py <dir_work> <salida.bin>
"""
import sys

# nombre, direccion de CARGA, direccion donde acaba EJECUTANDOSE
BLOQUES = [
    ("CM2", 0x9B91, 0x9B91),
    ("CM1", 0x83E8, 0x8000),
]


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    work, salida = sys.argv[1], sys.argv[2]

    img = bytearray(0x10000)
    for nombre, carga, ejec in BLOQUES:
        d = open(f"{work}/{nombre}.raw", "rb").read()
        if ejec + len(d) > 0x10000:
            sys.exit(f"{nombre} no cabe en 64K en 0x{ejec:04X}")
        img[ejec:ejec + len(d)] = d
        movido = "" if carga == ejec else f"  (recolocado desde 0x{carga:04X})"
        print(f"  {nombre}: 0x{ejec:04X}..0x{ejec + len(d) - 1:04X}  {len(d)} bytes{movido}")

    open(salida, "wb").write(bytes(img))
    print(f"  -> {salida}")


if __name__ == "__main__":
    main()
