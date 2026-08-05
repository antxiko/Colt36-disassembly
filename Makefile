# Colt 36 (Topo Soft, 1987, MSX1) - desensamblado
#
# `make` regenera los listados comentados desde el binario de la cinta y
# comprueba que al rehacerlos sale EXACTAMENTE el original, byte a byte.
#
# Esa comprobacion es lo que hace utilizable el trabajo: mientras este en verde,
# cualquier cosa que diga la documentacion se puede contrastar con el binario, y
# cualquier cambio en el juego se puede atribuir a lo que hemos tocado y no a un
# error de interpretacion.
#
# Particularidad de este juego: Colt 36 no esta escrito en ensamblador. El bloque
# que trae el juego es un programa MSX-BASIC de 63 lineas tokenizado, con solo 45
# bytes de codigo Z80 al final para poner el interprete en marcha. Las rutinas
# rapidas (volcados a VRAM, sonido) viven en el otro bloque y el BASIC las llama
# con DEFUSR. Por eso aqui la comprobacion de reproducibilidad son DOS: el
# programa se detokeniza y se vuelve a tokenizar, y el codigo se desensambla y se
# vuelve a ensamblar. Ver tools/basic_detok.py y tools/parte_cm1.py.

TSX  := colt36.tsx
# sha256 de la cinta con la que se hizo este trabajo.
TSX_SHA := 4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13
SYMS := work/msx.sym
MSXGL ?= /Users/fx-media/Documents/BARCOEMESEKS/MSXgl/engine/src

.PHONY: all verify clean extract syms listados sanity test cinta imagenes web misterio

all: verify

# ---------------------------------------------------------------- extraccion
# La cinta no se distribuye con el repositorio (ver AVISO-LEGAL.md), asi que lo
# primero es decirlo claro. Un "No rule to make target" no le explica nada a
# quien acaba de descargar esto.
cinta:
	@if [ ! -f "$(TSX)" ]; then \
	  echo ""; \
	  echo "  Falta la imagen de cinta: $(TSX)"; \
	  echo ""; \
	  echo "  No se distribuye con este repositorio, solo el listado comentado"; \
	  echo "  del juego (ver AVISO-LEGAL.md). Para reconstruirlo todo hace falta"; \
	  echo "  tu propia copia del TSX de Colt 36, con ese nombre y en la raiz"; \
	  echo "  del proyecto:"; \
	  echo ""; \
	  echo "      cp \"/donde/lo/tengas/Colt 36 ... .tsx\"  $(TSX)"; \
	  echo ""; \
	  echo "  Debe dar este sha256:"; \
	  echo "      $(TSX_SHA)"; \
	  echo ""; \
	  echo "  Sin la cinta si puedes: leer los listados de src/, y ejecutar los"; \
	  echo "  tests que no dependen del binario, con 'make test'."; \
	  echo ""; \
	  exit 1; \
	fi
	@echo "$(TSX_SHA)  $(TSX)" | shasum -a 256 -c - >/dev/null 2>&1 \
	  || { echo "  AVISO: $(TSX) no da el sha256 esperado; los listados pueden no cuadrar."; }

extract: extracted/.stamp
extracted/.stamp: tools/tsx_parse.py tools/cuerpos_bin.py | cinta
	@mkdir -p work dump
	python3 tools/tsx_parse.py "$(TSX)" extracted
	python3 tools/cuerpos_bin.py extracted work
	@touch $@

syms:
	@mkdir -p work
	@if [ -d "$(MSXGL)" ]; then \
	  python3 tools/gen_msx_syms.py "$(MSXGL)" $(SYMS); \
	else \
	  echo "MSXgl no esta en $(MSXGL); se conserva el $(SYMS) que ya hay."; \
	fi

# ------------------------------------------------------- imagen de ejecucion
# Los dos bloques del juego no se leen bien por separado: el BASIC llama a
# rutinas que estan en el otro bloque, y ademas no se ejecuta donde se carga.
# Esta es la RAM tal y como queda al arrancar, que es donde las direcciones
# significan lo que dicen.
dump/juego64.bin: tools/monta_ram.py extracted/.stamp
	@mkdir -p dump
	python3 tools/monta_ram.py work dump/juego64.bin

# La imagen de arriba se monta a mano, reproduciendo el LDIR del recolocador. Es
# determinista, pero es una reconstruccion NUESTRA. Esto deja que openMSX cargue
# la cinta de verdad y vuelca su RAM en el mismo instante, para poder comparar.
# No entra en `make` porque tarda (la cinta va a velocidad normal, sin turbo),
# pero conviene pasarlo cada vez que se toque monta_ram.py.
ram: dump/ram_al_arrancar.bin
dump/ram_al_arrancar.bin: tools/omsx_load.tcl | cinta
	@mkdir -p dump
	COLT36_TSX="$(PWD)/$(TSX)" COLT36_OUT="$(PWD)/dump" \
	  openmsx -machine Philips_VG_8020-20 -script tools/omsx_load.tcl

.PHONY: ram

# El bloque del juego, partido en programa BASIC / variables / arranque Z80.
work/cm1_basic.bin: tools/parte_cm1.py extracted/.stamp
	python3 tools/parte_cm1.py work/CM1.raw work
	@python3 -c "import sys;\
	d=open('work/CM1.raw','rb').read();\
	open('work/cm1_cola.bin','wb').write(d[0x8F5F-0x8000:])"

# ------------------------------------------------------------------ trazado
work/topo.trace.json: tools/z80trace.py src/topo.entries extracted/.stamp
	python3 tools/z80trace.py work/topo.raw 0x9470 src/topo.entries work/topo

work/cm2.trace.json: tools/z80trace.py src/cm2.entries src/cm2.nocode extracted/.stamp
	python3 tools/z80trace.py work/CM2.raw 0x9B91 src/cm2.entries work/cm2 src/cm2.nocode

# El trazado de la pantalla de carga no genera listado -ese esta comentado a
# mano- pero si hace falta para el presupuesto, que necesita saber que bytes son
# codigo alcanzable en los tres modulos.
work/scr.trace.json: tools/z80trace.py src/scr.entries extracted/.stamp
	python3 tools/z80trace.py work/scr.raw 0x9C40 src/scr.entries work/scr

# ----------------------------------------------------------------- listados
# Dos de los cuatro listados NO se regeneran, porque estan comentados a mano y
# `verify` es quien comprueba que siguen reproduciendo el binario: el del juego
# (src/colt36.bas, que es BASIC) y el de su arranque (src/colt36_arranque.asm).
# Los otros dos si salen de las herramientas, a partir de sus ficheros de notas.
listados: src/colt36_topo.asm src/colt36_cm2.asm

src/colt36_topo.asm: work/topo.trace.json src/topo.notes tools/mkasm.py
	python3 tools/mkasm.py work/topo.raw 0x9470 work/topo.trace.json \
	  src/topo.notes $(SYMS) $@ "COLT 36 - MSX - TOPO: el logo animado de Topo Soft"

src/colt36_cm2.asm: work/cm2.trace.json src/cm2.notes tools/mkasm.py
	python3 tools/mkasm.py work/CM2.raw 0x9B91 work/cm2.trace.json \
	  src/cm2.notes $(SYMS) $@ \
	  "COLT 36 - MSX - CM2: dibujos, decorados, musica y las rutinas de apoyo"

# -------------------------------------------------------------- verificacion
verify: listados sanity test
	@echo "=================================================================="
	@echo " Reproducibilidad 1/3: el listado del juego contra el binario"
	@echo "=================================================================="
	@echo " El juego esta en BASIC, asi que aqui la prueba no es reensamblar"
	@echo " sino volver a tokenizar: el listado comentado tiene que producir"
	@echo " exactamente los bytes que trae la cinta."
	@python3 tools/basic_detok.py verify work/cm1_basic.bin 0x8000 src/colt36.bas
	@echo ""
	@echo "=================================================================="
	@echo " Reproducibilidad 2/3: ensamblar debe dar el binario exacto"
	@echo "=================================================================="
	@./tools/verify_build.sh src/colt36_arranque.asm work/cm1_cola.bin 0x8F5F
	@./tools/verify_build.sh src/colt36_topo.asm     work/topo.raw     0x9470
	@./tools/verify_build.sh src/colt36_scr.asm      work/scr.raw      0x9C40
	@./tools/verify_build.sh src/colt36_cm2.asm      work/CM2.raw      0x9B91
	@echo ""
	@echo "=================================================================="
	@echo " Reproducibilidad 3/3: y las dos mitades juntas, el bloque entero"
	@echo "=================================================================="
	@python3 tools/basic_detok.py tok src/colt36.bas 0x8000 work/_basic.bin
	@pasmo --bin src/colt36_arranque.asm work/_cola.bin
	@cat work/_basic.bin work/_cola.bin > work/cm1_rehecho.bin
	@cmp work/cm1_rehecho.bin work/CM1.raw \
	  && echo "OK: el bloque del juego se rehace byte a byte (4277 bytes)"
	@rm -f work/_basic.bin work/_cola.bin

# El control de sanidad va aparte de la reproducibilidad porque detecta un fallo
# que esta NO ve: si el trazador marca graficos como codigo, el binario sigue
# saliendo identico -los bytes son los mismos- pero el listado miente.
sanity: work/cm1_basic.bin work/topo.trace.json work/scr.trace.json work/cm2.trace.json
	@echo "=================================================================="
	@echo " Sanidad del trazado: las zonas de datos no pueden salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py work/cm2.trace.json src/cm2.nocode
	@echo ""
	@echo "=================================================================="
	@echo " Presupuesto del binario: no deben quedar bytes sin explicar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py work src

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# Las imagenes de la web. No son capturas: se dibujan a partir de los datos del
# binario, siguiendo lo que hace el propio programa para montar la pantalla. Por
# eso valen tambien de comprobacion: si el reparto del bloque estuviese mal,
# saldria ruido en vez de un decorado reconocible.
imagenes: extracted/.stamp
	@mkdir -p docs/imagenes
	python3 tools/render_niveles.py work/CM2.raw docs/imagenes
	python3 tools/render_carga.py work/scr.raw docs/imagenes/carga.png

# La web de GitHub Pages: ingles en docs/ y castellano en docs/es/. El diseno es
# el compartido por la serie (tools/estilo_web.py) y las paginas salen
# autocontenidas, con las imagenes embebidas.
web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py work/CM2.raw docs/imagenes docs/index.html en
	python3 tools/make_web.py work/CM2.raw docs/imagenes docs/es/index.html es
	@touch docs/.nojekyll
	@python3 tools/check_enlaces.py docs

# Los unicos bytes de la cinta que este trabajo NO sabe explicar. Saca los tres
# trozos a work/ y mide lo que se ha medido sobre ellos, para que cualquiera
# pueda intentarlo sin repetir el desmontaje. Ver la seccion "SE BUSCA" de
# docs/es/BYTES-MUERTOS.md.
misterio: extracted/.stamp
	@python3 tools/extrae_misterio.py work work

clean:
	rm -rf extracted dump build work/*.raw work/*.bin work/*.json work/*.relleno
	rm -f extracted/.stamp
