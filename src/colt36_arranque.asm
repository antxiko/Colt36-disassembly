;; COLT 36 - Topo Soft, 1987 - MSX
;; El final del bloque del juego: area de variables y arranque del interprete
;;
;; Colt 36 esta escrito en MSX-BASIC (ver src/colt36.bas). Este listado cubre lo
;; que va DETRAS del programa dentro del mismo bloque de cinta: 297 bytes que el
;; interprete usara como area de variables, y los 45 bytes de codigo Z80 que son
;; lo unico que hay que ejecutar para poner el juego en marcha.
;;
;; DONDE SE EJECUTA. El bloque se carga en 0x83E8 pero lo primero que hace es
;; copiarse a 0x8000, asi que las direcciones buenas -las que aparecen en los
;; saltos- son las de aqui. La rutina que hace la copia esta al final de este
;; mismo listado, y es la unica que se ejecuta en la direccion de carga.
;;
;; COMO ARRANCA UN PROGRAMA BASIC DESDE CODIGO MAQUINA. Hacen falta tres cosas,
;; y las tres estan en los 20 bytes de 0x9088:
;;   1. que el programa este en su sitio, a partir de TXTTAB (0x8001)
;;   2. que VARTAB (0xF6C2) apunte justo detras, que es donde el interprete
;;      construira la tabla de variables
;;   3. saltar a la rutina del interprete que empieza a ejecutar
;;
;; Y una cuarta, que es lo interesante: PARCHEAR LA PRIMERA LINEA. En la cinta,
;; la primera linea del programa viene numerada 65535, que esta por encima del
;; maximo que MSX-BASIC admite. Con ese numero el programa no se puede ejecutar:
;; el primer GOSUB que busque una linea hacia atras se topa con el 65535, lo ve
;; mayor que lo que busca y aborta con "Undefined line number in 520". El
;; arranque le escribe encima el numero 4 y con eso el programa cobra vida. O
;; sea que quien se lleve el bloque y lo cargue por su cuenta no obtiene un
;; programa que funcione, sino uno que se rompe en cuanto empieza.

	org 08f5fh

;; ---------------------------------------------------------------- variables
;; Desde aqui hasta 0x9087 es el area de variables del interprete: VARTAB
;; apuntara a 0x8F60 y ahi ira construyendo su tabla en cuanto el juego arranque
;; (con el juego en marcha ocupa unos 166 bytes, 27 variables). O sea que NADA
;; de lo que hay grabado aqui se lee jamas: son 297 bytes que la cinta trae
;; llenos y que el interprete pisa en los primeros milisegundos.
;;
;; Aun asi vale la pena mirar lo que hay, porque cuenta como se hizo el juego.

;; Un byte muerto. Lo canonico seria que VARTAB apuntase aqui, a 0x8F5F, que es
;; donde acaba el programa (los dos ceros de 0x8F5D-0x8F5E lo cierran); el
;; arranque pone 0x8F60, uno mas arriba, y este byte se queda sin usar.
	defb 000h		; 8f5f

;; Una variable de MSX-BASIC que sobra, con el formato exacto de la tabla del
;; interprete: 0x08 = doble precision, 'I' y un cero como nombre, y ocho bytes
;; de valor en BCD que dan 37025. COLT 36 no la puede haber creado, porque usa
;; I% -entera- y nunca una I doble. Es lo que habia en la memoria de quien grabo
;; la cinta.
	defb 008h,049h,000h,045h,037h,002h,050h,000h,000h,000h,000h		; 8f60

;; Y desde aqui, 285 bytes de RAM SIN INICIALIZAR. No son relleno de ensamblador
;; ni datos: siguen la regla "0xFF si el bit 0 de la direccion coincide con el
;; bit 7, y 0x00 si no", que es el aspecto que tiene la memoria de un MSX recien
;; encendido, con bloques de 128 bytes que van alternando. Se cumple en 282 de
;; los 285 bytes.
;;
;; Dos cosas se deducen de esto. La primera es que el bloque se grabo con un
;; BSAVE de un rango mas ancho que el programa, y se colo lo que hubiera detras.
;; La segunda es mas fina: como la regla depende de la direccion ABSOLUTA, sirve
;; para saber desde donde se grabo. Encaja al 96% si el bloque estaba en 0x8000
;; y solo al 77% si hubiera estado en 0x83E8, o sea que en la maquina del
;; programador el juego ya vivia en 0x8000, y el 0x83E8 de la cinta es solo un
;; desvio para no pisar al cargador mientras carga.
	defb 0ffh,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 8f6b
	defb 000h,0ffh,000h,0ffh,000h,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8f7b
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8f8b
	defb 0ffh,000h,0ffh,000h,0ffh,000h,040h,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8f9b
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8fab
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8fbb
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8fcb
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8fdb
	defb 0ffh,000h,0bfh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h		; 8feb
	defb 0ffh,000h,0ffh,000h,0ffh,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 8ffb
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 900b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 901b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 902b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 903b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 904b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 905b
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 906b
	defb 000h,0ffh,000h,0ffh,000h,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh		; 907b

;; ------------------------------------------------------------------ arranque
;; Estos 20 bytes son el punto al que salta el recolocador, y lo unico que hay
;; que ejecutar para que el juego empiece.
arranque:
	ld hl,0909ch		; los cinco bytes de la cabecera de linea buena
	ld de,08000h		; encima del principio del programa
	ld bc,00005h
	ldir			; el parche: la linea 65535 pasa a ser la 4
	ld hl,08f60h		; donde empieza el area de variables
	ld (0f6c2h),hl		; VARTAB
	jp 073ach		; y al interprete, a ejecutar el programa

;; La cabecera de linea que el LDIR de arriba copia sobre 0x8000: el byte de
;; guarda, el enlace a la linea siguiente (0x800D, que no cambia) y el numero de
;; linea 4 en lugar del 65535 que trae la cinta.
	defb 000h,00dh,080h,004h,000h		; 909c

;; Seis bytes de relleno que siguen el mismo patron de RAM sin inicializar que
;; el area de variables de arriba (lo cumplen cinco de los seis).
	defb 0d8h,000h,0ffh,000h,0ffh,000h	; 90a1

;; ---------------------------------------------------------------- recolocador
;; La unica rutina de todo el bloque que se ejecuta en la direccion de CARGA y
;; no en la de ejecucion: es el `exec` que declara la cabecera BIN de la cinta,
;; 0x948F, o sea esta misma direccion mas 0x3E8. El BLOAD"cas:",R la llama en
;; cuanto termina de cargar; ella copia el bloque entero 0x3E8 bytes mas abajo
;; -incluyendose a si misma- y salta al arranque, que ya esta en su sitio.
;;
;; Por que cargar en 0x83E8 y no directamente en 0x8000: porque mientras el
;; juego se carga, quien manda es el cargador de la cinta, que es un programa
;; BASIC y vive precisamente a partir de 0x8001. Cargar encima seria cargar
;; sobre el programa que esta ejecutando el propio BLOAD.
;; (a esta etiqueta no salta nadie desde dentro del listado: se entra desde
;; fuera, porque es la direccion de arranque que declara la cinta)
recolocador:
	ld hl,083e8h		; de donde se ha cargado
	ld de,08000h		; a donde se ejecuta
	ld bc,010b5h		; los 4277 bytes del bloque entero
	ldir
	jp arranque
