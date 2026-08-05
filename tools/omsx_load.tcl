# Carga la cinta original de Colt 36 en openMSX y vuelca la RAM al arrancar.
#
# Para que sirve: tools/monta_ram.py reconstruye la memoria del juego a mano,
# copiando CM1 de 0x83E8 a 0x8000 igual que hace el recolocador. Eso es
# determinista, pero es una reconstruccion NUESTRA. Este script deja que cargue
# la cinta de verdad y vuelca la RAM en el instante exacto en que el juego va a
# arrancar, de modo que las dos se pueden comparar byte a byte. Si coinciden, la
# imagen sobre la que se ha hecho todo el analisis deja de ser una suposicion.
#
# Cadena de carga de Colt 36, leida del cargador BASIC de la propia cinta:
#   10 COLOR 1,1,1:SCREEN 2
#   20 BLOAD"cas:",R   -> topo  en 0x9470, se ejecuta ahi mismo (logo de Topo Soft)
#   30 BLOAD"cas:",R   -> scr   en 0x9C40, se ejecuta en 0xB798 (pantalla de carga)
#   40 CLEAR200,39824  -> HIMEM = 0x9B90, justo debajo de donde va CM2
#   50 BLOAD"cas:",R   -> CM2   en 0x9B91, "se ejecuta" en 0x9BBA, que es un RET
#   60 BLOAD"cas:",R   -> CM1   en 0x83E8, se ejecuta en 0x948F: se copia a 0x8000
#                                y salta a 0x9088, que arranca el interprete BASIC
#
# No hay carga turbo: son bloques KCS estandar, asi que esto tarda lo que tarda
# una cinta de verdad (varios minutos de tiempo emulado, pocos segundos de reloj
# con el acelerador quitado).

# openMSX no pasa argv a los scripts de -script, asi que van por entorno.
set TSX $::env(COLT36_TSX)
set OUT $::env(COLT36_OUT)

set LOG [open "$OUT/omsx_load.log" w]
proc say {msg} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $msg"; flush $LOG }

proc dump {name addr size} {
    global OUT
    set f [open "$OUT/$name" w]
    fconfigure $f -translation binary
    puts -nonewline $f [debug read_block memory $addr $size]
    close $f
    say "volcado $name  <- CPU\[[format 0x%04X $addr] .. [format 0x%04X [expr {$addr+$size-1}]]\] ($size bytes)"
}

set throttle off
catch {set renderer none}

cassetteplayer insert $TSX
say "cinta insertada: $TSX"

debug set_bp 0x9470 {} { say "topo en marcha: logo de Topo Soft" }
debug set_bp 0xB798 {} { say "scr en marcha: pantalla de carga" }

# Justo antes del LDIR que recoloca CM1: aqui los dos bloques del juego estan ya
# en RAM, CM1 todavia en su direccion de carga.
debug set_bp 0x948F {} {
    say "CM1 cargado en 0x83E8; va a copiarse a 0x8000"
    dump "ram_antes_de_recolocar.bin" 0x0000 0x10000
}

# Despues del LDIR y antes de arrancar el interprete: este es el momento que
# reproduce monta_ram.py.
debug set_bp 0x9088 {} {
    say "CM1 ya recolocado en 0x8000; va a arrancar el interprete BASIC"
    dump "ram_al_arrancar.bin" 0x0000 0x10000
    say "OK: la cinta original carga y el juego llega a su punto de arranque"
    exit 0
}

# El BASIC tarda un poco en estar listo para aceptar teclas.
after time 4 {
    say "tecleando RUN\"CAS:\""
    type "RUN\"CAS:\"\r"
}

after time 1200 { say "TIMEOUT: no se llego a 0x9088"; exit 1 }
