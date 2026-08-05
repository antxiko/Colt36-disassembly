#!/usr/bin/env python3
"""Detokeniza un programa MSX-BASIC y vuelve a tokenizarlo, byte a byte.

Colt 36 no esta escrito en ensamblador: el juego es un programa MSX-BASIC de 63
lineas que llama a rutinas en codigo maquina. Para leerlo hay que deshacer la
tokenizacion del interprete, que guarda cada palabra clave como un byte y cada
numero en un formato propio segun su magnitud.

Formato de un programa en memoria:

    0x00                        byte de guarda, justo antes de TXTTAB
    [linea] [linea] ... 0x0000  las lineas, encadenadas

y cada linea:

    ptr(2)   direccion de la SIGUIENTE linea; 0x0000 marca el fin del programa
    num(2)   numero de linea
    ...      los tokens
    0x00     fin de linea

Los punteros son absolutos, o sea que dependen de donde este cargado el
programa: por eso hay que decirle a esta herramienta el `org`.

La vuelta (`tok`) existe para poder comprobar que la lectura es exacta: si el
texto detokenizado se vuelve a tokenizar y sale el binario original byte a byte,
entonces el listado publicado no se ha inventado nada. Es la misma garantia que
da el reensamblado en un desensamblado normal.

Uso:
    basic_detok.py detok <binario> <org> [salida.bas]
    basic_detok.py tok   <fuente.bas> <org> [salida.bin]
    basic_detok.py check <binario> <org>      detokeniza, retokeniza y compara
"""
import sys

# ------------------------------------------------------------------ tokens
# Palabras clave de un byte, 0x81..0xFC.
TOKENS = {
    0x81: "END", 0x82: "FOR", 0x83: "NEXT", 0x84: "DATA", 0x85: "INPUT",
    0x86: "DIM", 0x87: "READ", 0x88: "LET", 0x89: "GOTO", 0x8A: "RUN",
    0x8B: "IF", 0x8C: "RESTORE", 0x8D: "GOSUB", 0x8E: "RETURN", 0x8F: "REM",
    0x90: "STOP", 0x91: "PRINT", 0x92: "CLEAR", 0x93: "LIST", 0x94: "NEW",
    0x95: "ON", 0x96: "WAIT", 0x97: "DEF", 0x98: "POKE", 0x99: "CONT",
    0x9A: "CSAVE", 0x9B: "CLOAD", 0x9C: "OUT", 0x9D: "LPRINT", 0x9E: "LLIST",
    0x9F: "CLS", 0xA0: "WIDTH", 0xA1: "ELSE", 0xA2: "TRON", 0xA3: "TROFF",
    0xA4: "SWAP", 0xA5: "ERASE", 0xA6: "ERROR", 0xA7: "RESUME",
    0xA8: "DELETE", 0xA9: "AUTO", 0xAA: "RENUM", 0xAB: "DEFSTR",
    0xAC: "DEFINT", 0xAD: "DEFSNG", 0xAE: "DEFDBL", 0xAF: "LINE",
    0xB0: "OPEN", 0xB1: "FIELD", 0xB2: "GET", 0xB3: "PUT", 0xB4: "CLOSE",
    0xB5: "LOAD", 0xB6: "MERGE", 0xB7: "FILES", 0xB8: "LSET", 0xB9: "RSET",
    0xBA: "SAVE", 0xBB: "LFILES", 0xBC: "CIRCLE", 0xBD: "COLOR",
    0xBE: "DRAW", 0xBF: "PAINT", 0xC0: "BEEP", 0xC1: "PLAY", 0xC2: "PSET",
    0xC3: "PRESET", 0xC4: "SOUND", 0xC5: "SCREEN", 0xC6: "VPOKE",
    0xC7: "SPRITE", 0xC8: "VDP", 0xC9: "BASE", 0xCA: "CALL", 0xCB: "TIME",
    0xCC: "KEY", 0xCD: "MAX", 0xCE: "MOTOR", 0xCF: "BLOAD", 0xD0: "BSAVE",
    0xD1: "DSKO$", 0xD2: "SET", 0xD3: "NAME", 0xD4: "KILL", 0xD5: "IPL",
    0xD6: "COPY", 0xD7: "CMD", 0xD8: "LOCATE", 0xD9: "TO", 0xDA: "THEN",
    0xDB: "TAB(", 0xDC: "STEP", 0xDD: "USR", 0xDE: "FN", 0xDF: "SPC(",
    0xE0: "NOT", 0xE1: "ERL", 0xE2: "ERR", 0xE3: "STRING$", 0xE4: "USING",
    0xE5: "INSTR", 0xE6: "'", 0xE7: "VARPTR", 0xE8: "CSRLIN", 0xE9: "ATTR$",
    0xEA: "DSKI$", 0xEB: "OFF", 0xEC: "INKEY$", 0xED: "POINT",
    0xEE: ">", 0xEF: "=", 0xF0: "<", 0xF1: "+", 0xF2: "-", 0xF3: "*",
    0xF4: "/", 0xF5: "^", 0xF6: "AND", 0xF7: "OR", 0xF8: "XOR",
    0xF9: "EQV", 0xFA: "IMP", 0xFB: "MOD", 0xFC: "\\",
}

# Funciones, que van con el prefijo 0xFF.
TOKENS_FF = {
    0x81: "LEFT$", 0x82: "RIGHT$", 0x83: "MID$", 0x84: "SGN", 0x85: "INT",
    0x86: "ABS", 0x87: "SQR", 0x88: "RND", 0x89: "SIN", 0x8A: "LOG",
    0x8B: "EXP", 0x8C: "COS", 0x8D: "TAN", 0x8E: "ATN", 0x8F: "FRE",
    0x90: "INP", 0x91: "POS", 0x92: "LEN", 0x93: "STR$", 0x94: "VAL",
    0x95: "ASC", 0x96: "CHR$", 0x97: "PEEK", 0x98: "VPEEK", 0x99: "SPACE$",
    0x9A: "OCT$", 0x9B: "HEX$", 0x9C: "LPOS", 0x9D: "BIN$", 0x9E: "CINT",
    0x9F: "CSNG", 0xA0: "CDBL", 0xA1: "FIX", 0xA2: "STICK", 0xA3: "STRIG",
    0xA4: "PDL", 0xA5: "PAD", 0xA6: "DSKF", 0xA7: "FPOS", 0xA8: "CVI",
    0xA9: "CVS", 0xAA: "CVD", 0xAB: "EOF", 0xAC: "LOC", 0xAD: "LOF",
    0xAE: "MKI$", 0xAF: "MKS$", 0xB0: "MKD$",
}

# Para retokenizar hace falta el diccionario al reves, y probar SIEMPRE la
# palabra mas larga primero: si no, "TO" se comeria la "T" de "TROFF".
PALABRAS = sorted(
    [(v, bytes([k])) for k, v in TOKENS.items()]
    + [(v, bytes([0xFF, k])) for k, v in TOKENS_FF.items()],
    key=lambda p: -len(p[0]),
)


class ErrorBasic(Exception):
    pass


# ----------------------------------------------------------- numeros: leer
def _float_msx(b, ancho):
    """Convierte un real de MSX (BCD con exponente en exceso 64) a texto.

    El byte 0 es el exponente: bit 7 el signo, y los 7 restantes la potencia de
    10 desplazada 64. Los demas bytes traen dos digitos decimales cada uno.
    """
    exp = b[0]
    if exp == 0:
        return "0"
    signo = "-" if exp & 0x80 else ""
    exp = (exp & 0x7F) - 64
    digitos = "".join(f"{x >> 4}{x & 0x0F}" for x in b[1:ancho])
    digitos = digitos.rstrip("0") or "0"
    # Se escribe en notacion normal mientras quepa; si no, en exponencial.
    if 0 < exp <= len(digitos):
        ent, frac = digitos[:exp], digitos[exp:]
        txt = ent + ("." + frac if frac else "")
    elif -2 < exp <= 0:
        txt = "." + "0" * (-exp) + digitos
    else:
        m = digitos[0] + ("." + digitos[1:] if len(digitos) > 1 else "")
        txt = f"{m}E{'+' if exp - 1 >= 0 else '-'}{abs(exp - 1)}"
    return signo + txt


def _num(d, i):
    """Lee la constante numerica que empieza en d[i]. Devuelve (texto, i_nuevo).

    Devuelve (None, i) si d[i] no abre una constante.
    """
    c = d[i]
    if c == 0x0B:
        return "&O" + format(d[i + 1] | (d[i + 2] << 8), "o"), i + 3
    if c == 0x0C:
        return "&H" + format(d[i + 1] | (d[i + 2] << 8), "X"), i + 3
    if c in (0x0D, 0x0E):
        # 0x0D es un puntero ya resuelto a la linea y 0x0E el numero sin
        # resolver; los dos se escriben como el numero de linea. Un programa
        # recien cargado de cinta solo trae 0x0E, pero uno volcado de la RAM
        # despues de correr puede traer 0x0D, y hay que saber leerlo.
        return str(d[i + 1] | (d[i + 2] << 8)), i + 3
    if c == 0x0F:
        return str(d[i + 1]), i + 2
    if 0x11 <= c <= 0x1A:
        return str(c - 0x11), i + 1
    if c == 0x1B:
        raise ErrorBasic(f"token 0x1B (no usado) en el offset {i}")
    if c == 0x1C:
        return str(d[i + 1] | (d[i + 2] << 8)), i + 3
    if c == 0x1D:
        return _float_msx(d[i + 1:i + 5], 4) + "!", i + 5
    if c == 0x1F:
        return _float_msx(d[i + 1:i + 9], 8) + "#", i + 9
    return None, i


# ---------------------------------------------------------------- detokenizar
def detok_linea(d, i, fin):
    """Detokeniza el cuerpo de una linea. d[i:fin] son los tokens, sin el 0x00."""
    out = []
    literal = False   # dentro de comillas no se traduce nada
    resto = False     # tras REM / ' / DATA tampoco
    while i < fin:
        c = d[i]
        if literal or resto:
            out.append(chr(c))
            if c == 0x22 and literal:
                literal = False
            i += 1
            continue
        if c == 0x22:
            literal = True
            out.append('"')
            i += 1
            continue
        txt, j = _num(d, i)
        if txt is not None:
            out.append(txt)
            i = j
            continue
        if c == 0xFF:
            nom = TOKENS_FF.get(d[i + 1])
            if nom is None:
                raise ErrorBasic(f"funcion 0xFF 0x{d[i+1]:02X} desconocida en {i}")
            out.append(nom)
            i += 2
            continue
        if c in TOKENS:
            out.append(TOKENS[c])
            # REM, la comilla simple y DATA se llevan crudo lo que venga detras.
            if c in (0x8F, 0xE6, 0x84):
                resto = True
            i += 1
            continue
        if c < 0x20 or c > 0x7E:
            raise ErrorBasic(f"byte 0x{c:02X} inesperado en el offset {i}")
        out.append(chr(c))
        i += 1
    return "".join(out)


def detok(data, org):
    """Detokeniza el programa entero. Devuelve (lineas, bytes_consumidos).

    `lineas` es una lista de (numero, texto). El programa empieza en org+1: el
    byte de org es la guarda que el interprete deja delante de TXTTAB.
    """
    lineas = []
    p = 1
    while True:
        # Ojo: el 0x0000 de fin de programa son solo dos bytes, no cuatro. Pedir
        # los cuatro de una cabecera de linea aqui hace fallar un programa que
        # este bien pero que acabe justo en el borde del binario.
        if p + 2 > len(data):
            raise ErrorBasic("el programa se acaba sin el 0x0000 final")
        nxt = data[p] | (data[p + 1] << 8)
        if nxt == 0:
            p += 2
            break
        if p + 4 > len(data):
            raise ErrorBasic(f"cabecera de linea incompleta en 0x{org+p:04X}")
        off = nxt - org
        if off <= p or off > len(data):
            raise ErrorBasic(
                f"el puntero de 0x{org+p:04X} apunta a 0x{nxt:04X}, fuera del programa"
            )
        if data[off - 1] != 0:
            raise ErrorBasic(f"la linea de 0x{org+p:04X} no acaba en 0x00")
        num = data[p + 2] | (data[p + 3] << 8)
        lineas.append((num, detok_linea(data, p + 4, off - 1)))
        p = off
    return lineas, p


# ------------------------------------------------------------------ tokenizar
# Tokens tras los cuales un numero es un NUMERO DE LINEA, no un valor. El
# interprete los codifica distinto (0x0E + 2 bytes en vez de la constante mas
# corta que quepa), asi que sin esta lista el binario no vuelve a salir igual.
TRAS_ESTOS_VA_UNA_LINEA = {
    0x89,  # GOTO
    0x8D,  # GOSUB
    0xDA,  # THEN
    0xA1,  # ELSE
    0x8C,  # RESTORE
    0x8A,  # RUN
    0x93,  # LIST
    0xA8,  # DELETE
    0xA7,  # RESUME
    0x9E,  # LLIST
}


def tok_linea(txt):
    out = bytearray()
    i = 0
    # Se enciende tras GOTO y compania, y sigue encendido a traves de espacios y
    # comas para que 'ON X GOTO 10,20,30' codifique las tres como lineas.
    modo_linea = False
    while i < len(txt):
        c = txt[i]
        if c == '"':
            out.append(0x22)
            i += 1
            while i < len(txt):
                out.append(ord(txt[i]))
                i += 1
                if out[-1] == 0x22:
                    break
            continue
        if c == "&" and i + 1 < len(txt) and txt[i + 1] in "hH":
            j = i + 2
            while j < len(txt) and txt[j] in "0123456789ABCDEFabcdef":
                j += 1
            out += bytes([0x0C]) + int(txt[i + 2:j], 16).to_bytes(2, "little")
            i = j
            continue
        if c == "&" and i + 1 < len(txt) and txt[i + 1] in "oO":
            j = i + 2
            while j < len(txt) and txt[j] in "01234567":
                j += 1
            out += bytes([0x0B]) + int(txt[i + 2:j], 8).to_bytes(2, "little")
            i = j
            continue
        if c.isdigit() or (c == "." and i + 1 < len(txt) and txt[i + 1].isdigit()):
            j = i
            while j < len(txt) and (txt[j].isdigit() or txt[j] == "."):
                j += 1
            # Notacion exponencial: la E solo cuenta si trae exponente detras.
            if j < len(txt) and txt[j] in "eE" and j + 1 < len(txt) and (
                txt[j + 1].isdigit() or txt[j + 1] in "+-"
            ):
                j += 2
                while j < len(txt) and txt[j].isdigit():
                    j += 1
            sufijo = txt[j] if j < len(txt) and txt[j] in "!#%" else ""
            if modo_linea and not sufijo and "." not in txt[i:j]:
                out += bytes([0x0E]) + int(txt[i:j]).to_bytes(2, "little")
            else:
                out += _tok_num(txt[i:j], sufijo)
            i = j + (1 if sufijo else 0)
            continue
        for pal, code in PALABRAS:
            if txt.startswith(pal, i):
                out += code
                if code in (b"\x8f", b"\xe6", b"\x84"):   # REM, ', DATA
                    out += txt[i + len(pal):].encode("latin-1")
                    return bytes(out)
                modo_linea = code[0] in TRAS_ESTOS_VA_UNA_LINEA
                i += len(pal)
                break
        else:
            # El espacio y la coma no cortan la lista de numeros de linea;
            # cualquier otro caracter si.
            if c not in " ,":
                modo_linea = False
            out.append(ord(c))
            i += 1
    return bytes(out)


def _tok_num(txt, sufijo):
    """Vuelve a codificar una constante numerica en el formato del interprete.

    El interprete elige la codificacion mas corta que sirva, y hay que elegir la
    misma o el binario no sale identico.
    """
    if sufijo == "!":
        return bytes([0x1D]) + _bcd(txt, 4)
    if sufijo == "#":
        return bytes([0x1F]) + _bcd(txt, 8)
    if "." not in txt and "e" not in txt.lower():
        n = int(txt)
        if 0 <= n <= 9:
            return bytes([0x11 + n])
        if 10 <= n <= 255:
            return bytes([0x0F, n])
        if 0 <= n <= 32767:
            return bytes([0x1C]) + n.to_bytes(2, "little")
    return bytes([0x1D]) + _bcd(txt, 4)


def _bcd(txt, ancho):
    """Codifica un decimal en el real BCD del MSX, del ancho pedido."""
    neg = txt.startswith("-")
    txt = txt.lstrip("+-")
    mant, _, expo = txt.lower().partition("e")
    ent, _, frac = mant.partition(".")
    digitos = (ent + frac).lstrip("0")
    ceros = len(ent + frac) - len((ent + frac).lstrip("0"))
    exp = len(ent) - ceros + (int(expo) if expo else 0)
    if not digitos:
        return bytes(ancho)
    digitos = (digitos + "0" * 2 * ancho)[: 2 * (ancho - 1)]
    b = bytearray([(exp + 64) | (0x80 if neg else 0)])
    for k in range(0, len(digitos), 2):
        b.append(int(digitos[k]) << 4 | int(digitos[k + 1]))
    return bytes(b[:ancho])


def tok(lineas, org):
    """Rearma el programa en memoria. `lineas` es una lista de (numero, texto)."""
    cuerpos = [(n, tok_linea(t)) for n, t in lineas]
    out = bytearray([0])
    p = org + 1
    for n, cuerpo in cuerpos:
        nxt = p + 4 + len(cuerpo) + 1
        out += nxt.to_bytes(2, "little") + n.to_bytes(2, "little") + cuerpo + b"\x00"
        p = nxt
    out += b"\x00\x00"
    return bytes(out)


# ----------------------------------------------------------------------- cli
def _leer_fuente(path):
    """Lee un .bas del proyecto: lineas BASIC mas comentarios nuestros.

    Un programa BASIC no deja meter explicaciones sin cambiar los bytes (REM
    ocupa sitio), asi que el listado comentado y el que reproduce el binario
    serian dos ficheros distintos, y el segundo se quedaria desactualizado.
    Se evita reservando el '#' al principio de linea para los comentarios del
    proyecto: no es sintaxis BASIC, se ignora al tokenizar, y asi el fichero
    publicado es a la vez el comentado y el que se comprueba.
    """
    lineas = []
    for n, ln in enumerate(open(path, encoding="latin-1"), 1):
        ln = ln.rstrip("\n").rstrip("\r")
        if not ln or ln.lstrip().startswith("#"):
            continue
        num, _, resto = ln.partition(" ")
        if not num.isdigit():
            raise ErrorBasic(f"{path}:{n}: la linea no empieza por un numero")
        lineas.append((int(num), resto))
    return lineas


def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    modo, path, org = sys.argv[1], sys.argv[2], int(sys.argv[3], 0)

    if modo == "detok":
        data = open(path, "rb").read()
        lineas, usados = detok(data, org)
        txt = "".join(f"{n} {t}\n" for n, t in lineas)
        if len(sys.argv) > 4:
            open(sys.argv[4], "w", encoding="latin-1").write(txt)
            print(f"{len(lineas)} lineas -> {sys.argv[4]}  ({usados} bytes del binario)")
        else:
            sys.stdout.write(txt)

    elif modo == "tok":
        out = tok(_leer_fuente(path), org)
        if len(sys.argv) > 4:
            open(sys.argv[4], "wb").write(out)
            print(f"-> {sys.argv[4]}  ({len(out)} bytes)")
        else:
            sys.stdout.buffer.write(out)

    elif modo in ("check", "verify"):
        data = open(path, "rb").read()
        if modo == "check":
            # Ida y vuelta sobre el propio binario: comprueba la herramienta.
            lineas, usados = detok(data, org)
            que = "ida y vuelta exacta"
        else:
            # El listado COMENTADO de src/ contra el binario: comprueba que lo
            # que se publica es de verdad el programa que hay en la cinta.
            if len(sys.argv) < 5:
                sys.exit("uso: basic_detok.py verify <binario> <org> <fuente.bas>")
            lineas, usados = _leer_fuente(sys.argv[4]), len(data)
            que = f"{sys.argv[4]} reproduce el binario"
        rehecho = tok(lineas, org)
        original = data[:usados]
        if rehecho == original:
            print(f"OK: {len(lineas)} lineas, {usados} bytes, {que}")
            return
        for k, (a, b) in enumerate(zip(original, rehecho)):
            if a != b:
                sys.exit(
                    f"DIFIEREN en el offset {k} (0x{org+k:04X}): "
                    f"original 0x{a:02X}, retokenizado 0x{b:02X}"
                )
        sys.exit(f"DIFIEREN en longitud: {len(original)} vs {len(rehecho)}")

    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
