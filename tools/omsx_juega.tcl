# Carga Colt 36 en openMSX, lo deja jugando y va sacando capturas.
#
# Cargar la cinta entera tarda (no hay turbo: son bloques KCS a velocidad
# normal), asi que lo primero que hace este script es guardar un savestate en
# cuanto el juego arranca. A partir de ahi se puede volver a ese punto en un
# segundo, con `openmsx -savestate colt36_arranque`, en vez de tragarse los seis
# minutos de cinta cada vez.
#
# Las capturas van a $COLT36_OUT/png. Los momentos elegidos son los que hacen
# falta para dar por bueno el analisis: la portada con la mira, y el primer
# nivel ya en marcha con su marcador.

set TSX $::env(COLT36_TSX)
set OUT $::env(COLT36_OUT)

file mkdir "$OUT/png"
set LOG [open "$OUT/omsx_juega.log" w]
proc say {msg} { global LOG; puts $LOG "\[[format %8.2f [machine_info time]]\] $msg"; flush $LOG }
# OJO con el acelerador. Con `throttle off` el emulador corre a la velocidad que
# da la maquina y openMSX se salta el dibujado de casi todos los fotogramas, asi
# que `screenshot` devuelve el ULTIMO que llego a dibujarse: se capturan tres
# momentos distintos del juego y salen tres ficheros identicos, sin que nada
# avise. Que la CPU esta corriendo se comprueba mirando el PC, que va cambiando.
#
# Por eso se carga la cinta con el acelerador quitado (que es lo que ahorra los
# seis minutos y medio de cassette) y se vuelve a poner ANTES de capturar.
proc foto {name} {
    global OUT
    screenshot -raw -prefix "$OUT/png/$name"
    say "captura $name"
}

set throttle off

cassetteplayer insert $TSX
say "cinta insertada"

debug set_bp 0x9088 {} {
    say "el juego arranca: se guarda el savestate para no repetir la carga"
    savestate colt36_arranque
    cassetteplayer eject

    # La portada la pintan las lineas 500-575 del BASIC y a partir de la 582 se
    # queda en bucle moviendo la mira hasta que se dispara.
    # A velocidad real a partir de aqui, para que el VDP dibuje de verdad los
    # fotogramas que vamos a capturar (ver la nota de arriba sobre el acelerador).
    set throttle on
    after time 12 {
        foto "01_portada"

        # STRIG(0) es la barra espaciadora: es lo que saca del bucle de portada.
        say "disparo para empezar la partida"
        keymatrixdown 8 1
        after time 0.3 {
            keymatrixup 8 1
            after time 8 {
                foto "02_nivel1"
                after time 5 { foto "03_nivel1_bis"; say "hecho"; exit 0 }
            }
        }
    }
}

after time 4 {
    say "tecleando RUN\"CAS:\""
    type "RUN\"CAS:\"\r"
}

after time 1400 { say "TIMEOUT"; exit 1 }
