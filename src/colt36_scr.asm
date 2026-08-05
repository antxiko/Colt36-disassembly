;; COLT 36 - Topo Soft, 1987 - MSX
;; Modulo 'scr': la pantalla que se ve mientras carga el juego
;;
;; En la cinta es un bloque BIN con carga en 0x9C40, final en 0xB7FB y arranque
;; en 0xB798. Lo trae el BLOAD"cas:",R de la linea 30 del cargador, con la
;; pantalla ya puesta en SCREEN 2 y en negro por la linea 10.
;;
;; Es la ilustracion de la caratula: una mano con un revolver disparando, y tras
;; unas puertas de saloon la silueta de un tipo con sombrero del que solo se ven
;; los ojos. Abajo a la derecha esta la firma del grafista, CANO.
;;
;; REPARTO DEL BLOQUE
;;   0x9C40..0xB43F  6144 B  los dibujos, tal cual van a la memoria de video
;;   0xB440..0xB73F   768 B  el color, comprimido: un byte por celda de 8x8
;;   0xB740..0xB797    88 B  basura: RAM sin inicializar que se colo al grabar
;;   0xB798..0xB7F6    95 B  el codigo
;;   0xB7F7..0xB7FB     5 B  ceros de cola
;;                    ------
;;                    7100 B
;;
;; EL DETALLE QUE MERECE LA PENA. En SCREEN 2 el MSX admite un par de colores
;; distinto en CADA UNA de las ocho lineas de una celda, o sea 6144 bytes de
;; color. Aqui el dibujo se limita a un solo par por celda y guarda 768, que la
;; rutina de abajo replica ocho veces al vuelo. Cuesta que los degradados haya
;; que resolverlos a base de tramado en damero, y a cambio ahorra 5376 bytes de
;; cinta, que a la velocidad a la que carga esto son unos 48 segundos menos de
;; espera. En 1987, con la cinta girando delante del comprador, eso era el
;; argumento ganador.
;;
;; El modulo no hace nada mas: no toca el chip de sonido, no espera, no comprueba
;; nada. Pinta y vuelve al BASIC, que sigue por la linea 40. Tampoco escribe
;; ningun registro del VDP ni la tabla de nombres: se apoya en lo que ya dejo
;; puesto el SCREEN 2 de la linea 10.

DISSCR	equ 00041h		; BIOS: apaga la imagen
ENASCR	equ 00044h		; BIOS: enciende la imagen

	org 09c40h

;; ------------------------------------------------------------------ dibujos
;; Los 6144 bytes de la tabla de patrones, en el orden exacto en que van a la
;; memoria de video: tres tercios de 2048, y dentro de cada uno, ocho lineas por
;; celda. No hay compresion de ningun tipo.
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c40
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c50
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c60
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c70
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c80
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9c90
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h,01ch,031h	; 9ca0
	defb 000h,000h,000h,000h,000h,0ffh,000h,0ffh,000h,000h,000h,000h,000h,0f0h,01ch,0c6h	; 9cb0
	defb 000h,000h,000h,000h,000h,000h,001h,003h,000h,000h,000h,000h,000h,07fh,0c0h,01fh	; 9cc0
	defb 000h,000h,000h,000h,000h,0ffh,000h,0feh,000h,000h,000h,000h,000h,080h,0e0h,030h	; 9cd0
	defb 000h,000h,000h,000h,000h,07fh,040h,05fh,000h,000h,000h,000h,000h,0ffh,001h,0fdh	; 9ce0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0ffh,080h,0bfh	; 9cf0
	defb 000h,000h,000h,000h,000h,0ffh,000h,0ffh,000h,000h,000h,000h,000h,0ffh,000h,0ffh	; 9d00
	defb 000h,000h,000h,000h,000h,0feh,002h,0fah,000h,000h,000h,000h,000h,000h,000h,000h	; 9d10
	defb 03fh,03fh,03fh,03fh,03fh,01fh,01fh,03fh,010h,000h,050h,030h,050h,070h,070h,070h	; 9d20
	defb 07eh,07eh,07eh,07eh,07eh,03eh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; 9d30
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d40
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d50
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,007h	; 9d60
	defb 000h,000h,000h,000h,000h,000h,0f0h,02ch,000h,000h,000h,000h,000h,000h,000h,000h	; 9d70
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d80
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d90
	defb 000h,000h,000h,000h,000h,000h,000h,000h,067h,04fh,0dfh,09fh,0bfh,0bfh,0bfh,0bfh	; 9da0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f3h,0f9h,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh	; 9db0
	defb 006h,004h,08dh,089h,08bh,08bh,08bh,08bh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9dc0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,098h,0c8h,0ech,0e4h,0f4h,0f4h,0f4h,0f4h	; 9dd0
	defb 05fh,05fh,05fh,05fh,05fh,05fh,05fh,05fh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh	; 9de0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; 9df0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9e00
	defb 0fah,0fah,0fah,0fah,0fah,0fah,0fah,0fah,000h,000h,000h,000h,000h,000h,000h,000h	; 9e10
	defb 03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,070h,070h,070h,070h,070h,070h,070h,070h	; 9e20
	defb 07eh,07eh,07eh,07eh,07eh,03eh,03eh,03eh,0e0h,0e0h,0a0h,0a0h,0a0h,0e0h,0e0h,0e0h	; 9e30
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9e40
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9e50
	defb 000h,000h,000h,000h,000h,000h,000h,000h,018h,061h,082h,079h,005h,002h,002h,001h	; 9e60
	defb 016h,02dh,0dbh,0d6h,07dh,07dh,01fh,01fh,000h,000h,000h,080h,0c0h,0e0h,0e0h,0f2h	; 9e70
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h	; 9e80
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9e90
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; 9ea0
	defb 0ffh,0ffh,0c0h,09fh,0b1h,0a0h,0a0h,0a0h,0fdh,0fdh,07dh,03dh,0bdh,0bdh,0bdh,0bdh	; 9eb0
	defb 08bh,08bh,08bh,08bh,08bh,08bh,08bh,08bh,0ffh,0ffh,0f8h,0f3h,0f6h,0f4h,0f4h,0f4h	; 9ec0
	defb 0ffh,0ffh,007h,0f3h,01bh,00bh,00bh,00bh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; 9ed0
	defb 05fh,05fh,05fh,047h,077h,017h,017h,017h,0fdh,0fdh,0fdh,0f1h,0f7h,0f4h,0f4h,0f4h	; 9ee0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bfh,0bfh,0bfh,0b8h,0bbh,0bah,0bah,0bah	; 9ef0
	defb 0ffh,0ffh,0ffh,00fh,0efh,02fh,02fh,02fh,0ffh,0ffh,0ffh,0e0h,0efh,0e8h,0e8h,0e8h	; 9f00
	defb 0fah,0fah,0fah,03ah,0bah,0bah,0bah,0bah,000h,000h,000h,000h,000h,000h,000h,000h	; 9f10
	defb 03fh,03fh,01fh,01fh,01fh,03fh,01fh,03fh,072h,072h,070h,070h,06fh,047h,00fh,000h	; 9f20
	defb 07eh,07eh,03eh,07eh,07eh,07eh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0e0h,0c0h,0e0h,0e0h	; 9f30
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9f40
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9f50
	defb 000h,000h,000h,000h,000h,000h,000h,000h,001h,001h,000h,000h,000h,000h,000h,000h	; 9f60
	defb 00fh,00fh,08fh,087h,087h,04fh,043h,047h,0fbh,0fch,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9f70
	defb 0a0h,070h,0f8h,0f9h,0f1h,0e0h,0c3h,087h,000h,000h,0e0h,038h,02ch,0d7h,0b5h,0edh	; 9f80
	defb 000h,000h,000h,000h,000h,000h,080h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; 9f90
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; 9fa0
	defb 0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0bdh,081h,0ffh,000h,000h,000h,000h,000h	; 9fb0
	defb 08bh,08bh,08bh,00bh,00bh,00bh,00bh,00bh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; 9fc0
	defb 00bh,00bh,00bh,00bh,00bh,00bh,00bh,00bh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; 9fd0
	defb 017h,017h,017h,017h,017h,017h,017h,017h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; 9fe0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bah,082h,0feh,000h,000h,000h,000h,000h	; 9ff0
	defb 02fh,02fh,02fh,02fh,02fh,02fh,02fh,02fh,0e8h,0e8h,0e8h,0e8h,0e8h,0e8h,0e8h,0e8h	; a000
	defb 0bah,082h,0feh,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a010
	defb 03eh,03fh,03bh,037h,02fh,01ch,000h,000h,0ffh,0ffh,0f3h,0ffh,0ffh,0fdh,000h,000h	; a020
	defb 07eh,0feh,07eh,07eh,07eh,0feh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0c0h	; a030
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a040
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a050
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,001h,003h,003h,000h,01eh,079h	; a060
	defb 067h,0efh,0efh,0ffh,0fdh,030h,088h,043h,0ffh,0fch,0f0h,0c0h,003h,00fh,03fh,0ffh	; a070
	defb 00fh,01fh,03fh,0ffh,0ffh,0f0h,0c0h,001h,0edh,0feh,0feh,0ffh,0ffh,00fh,041h,0a8h	; a080
	defb 030h,0fch,0feh,0ffh,0ffh,0ffh,0cfh,007h,000h,000h,000h,000h,080h,0c0h,0f0h,0f8h	; a090
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; a0a0
	defb 0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0ffh,081h,0bdh,0bdh,0bdh,0bdh,0bdh,0bdh	; a0b0
	defb 08bh,08bh,08bh,08bh,08bh,08bh,08bh,08bh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; a0c0
	defb 00bh,00bh,00bh,00bh,00bh,00bh,00bh,00bh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; a0d0
	defb 017h,017h,017h,017h,017h,017h,017h,077h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f7h	; a0e0
	defb 000h,03fh,020h,02fh,02fh,02fh,02fh,0efh,000h,0e0h,020h,0a0h,0a0h,0a0h,0a0h,0a1h	; a0f0
	defb 02fh,02fh,02fh,02fh,02fh,02fh,02fh,0efh,0e8h,0e8h,0e8h,0e8h,0e8h,0e8h,0e8h,0efh	; a100
	defb 05bh,002h,005h,000h,0ffh,00eh,00fh,00fh,0ffh,0aah,055h,000h,0ffh,0bfh,0dfh,0ffh	; a110
	defb 0ffh,0aah,055h,000h,0ffh,0ffh,0ffh,09fh,0f8h,088h,018h,028h,058h,028h,058h,028h	; a120
	defb 07eh,076h,07eh,07eh,07eh,076h,076h,07eh,0c0h,0e0h,0e0h,0e0h,0a0h,0c0h,0e0h,0e0h	; a130
	defb 000h,000h,000h,000h,000h,000h,000h,001h,000h,000h,001h,003h,01fh,07fh,07fh,0ffh	; a140
	defb 007h,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f8h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a150
	defb 000h,080h,0c0h,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,0f8h,0ffh,0ffh,0ffh	; a160
	defb 000h,000h,000h,000h,000h,0c0h,0fch,0ffh,0feh,0fch,07ch,0f8h,0f8h,0b0h,030h,0f2h	; a170
	defb 005h,012h,002h,00dh,02bh,056h,00bh,0d7h,06fh,0feh,0feh,0feh,0fdh,0fdh,0fdh,0fdh	; a180
	defb 003h,0e1h,0e0h,0e8h,0ech,0dfh,0dfh,0dfh,0fch,0feh,07fh,03fh,01fh,00fh,087h,0c3h	; a190
	defb 000h,000h,000h,080h,0c0h,0f0h,0f8h,0fch,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh,0bfh	; a1a0
	defb 0b1h,09fh,0c0h,0ffh,0ffh,0ffh,0ffh,0ffh,0bdh,03dh,07dh,0fdh,0fdh,0fdh,0fdh,0fdh	; a1b0
	defb 08bh,08bh,08bh,08bh,08bh,08bh,08bh,08bh,0f6h,0f3h,0f8h,0ffh,0ffh,0ffh,0ffh,0ffh	; a1c0
	defb 01bh,0f3h,007h,0ffh,0ffh,0ffh,0ffh,0ffh,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h,0f4h	; a1d0
	defb 047h,05fh,05fh,05fh,05fh,05fh,05fh,05fh,0f0h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a1e0
	defb 00fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h	; a1f0
	defb 00fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0e1h,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh,0fdh	; a200
	defb 00fh,00fh,00fh,00fh,00fh,00fh,00fh,00fh,0e1h,0dch,0d8h,0b8h,0b8h,0b8h,0b8h,0b8h	; a210
	defb 07fh,0ffh,0ffh,07fh,07fh,07fh,07fh,07fh,058h,028h,058h,028h,058h,028h,058h,028h	; a220
	defb 07eh,07eh,07eh,03eh,03eh,07eh,07eh,03eh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; a230
	defb 001h,007h,00fh,01fh,01fh,01fh,01fh,01bh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a240
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0f7h,0f7h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0bfh,0d3h	; a250
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a260
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0c0h,0e0h,0f8h,0fch,0feh,0feh,0ffh,0ffh	; a270
	defb 0afh,057h,02fh,07fh,0b7h,0dfh,047h,00bh,0fbh,0fbh,0fbh,0f7h,0f7h,0efh,0deh,0ddh	; a280
	defb 0deh,0bch,0bch,0beh,07fh,07fh,0f8h,0e0h,061h,030h,018h,08ch,067h,0b1h,0dbh,063h	; a290
	defb 0feh,07eh,03eh,01fh,00fh,00fh,04fh,06fh,09fh,0dfh,04fh,067h,031h,01ch,007h,000h	; a2a0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,000h,0fdh,0f9h,0fbh,0f2h,0c6h,01ch,0f0h,000h	; a2b0
	defb 089h,08dh,004h,006h,003h,001h,000h,000h,0ffh,0ffh,0ffh,07fh,01fh,0c0h,07fh,000h	; a2c0
	defb 0ffh,0ffh,0ffh,0ffh,0feh,000h,0ffh,000h,0e4h,0ech,0c8h,098h,030h,0e0h,080h,000h	; a2d0
	defb 05fh,05fh,05fh,05fh,05fh,040h,07fh,000h,0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,000h	; a2e0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,000h,0ffh,000h,0a1h,0a1h,0a1h,0a1h,0a1h,021h,0e1h,000h	; a2f0
	defb 07fh,07fh,07fh,07fh,07fh,000h,0ffh,000h,0fdh,0fdh,0fdh,0fdh,0fdh,001h,0ffh,000h	; a300
	defb 00fh,00fh,00fh,00fh,07fh,07fh,07fh,07fh,0bch,0dch,0deh,0e1h,0bfh,0feh,0ffh,0ffh	; a310
	defb 03fh,0b7h,0dfh,0ebh,0f7h,0f7h,0eeh,0ceh,058h,028h,058h,028h,050h,020h,040h,080h	; a320
	defb 03eh,03eh,07eh,07eh,07eh,07eh,07eh,07eh,0e0h,0c0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; a330
	defb 00eh,000h,000h,000h,000h,000h,000h,000h,07fh,0efh,0a3h,03bh,01fh,017h,006h,003h	; a340
	defb 0fbh,0ffh,0ffh,0ffh,07fh,0ffh,0ffh,0fah,043h,0a1h,080h,080h,041h,080h,080h,0c0h	; a350
	defb 0ffh,0dbh,0dfh,03fh,037h,057h,0cbh,03fh,0ffh,0ffh,07fh,0ffh,0ffh,0ffh,06bh,0e5h	; a360
	defb 0ffh,0f7h,0ffh,0ffh,0afh,09fh,002h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,06fh	; a370
	defb 080h,080h,0e0h,0e1h,0e0h,0f0h,0f0h,0f0h,0bdh,07bh,0d7h,02fh,025h,003h,002h,001h	; a380
	defb 0e0h,0e0h,0e4h,0f7h,0fbh,03dh,00eh,017h,03bh,01fh,00fh,007h,082h,0c2h,0e6h,01dh	; a390
	defb 06fh,06fh,06fh,06fh,0efh,0deh,0deh,0deh,06ch,016h,01dh,02fh,05fh,05fh,0afh,03fh	; a3a0
	defb 000h,000h,000h,080h,0c0h,0f0h,0f8h,0fch,000h,000h,000h,000h,000h,000h,000h,000h	; a3b0
	defb 000h,000h,000h,000h,000h,000h,003h,007h,000h,000h,000h,000h,000h,000h,0e8h,0a4h	; a3c0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,05bh,009h,007h,006h,008h,008h	; a3d0
	defb 010h,010h,010h,010h,0d0h,0a0h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a3e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a3f0
	defb 001h,001h,001h,001h,001h,001h,000h,000h,0ffh,0feh,0ffh,0fdh,0fdh,0f2h,0ebh,0e5h	; a400
	defb 0e0h,04ah,055h,0cbh,0d5h,0aah,0e4h,0e8h,00fh,007h,007h,00fh,01fh,03fh,03fh,07fh	; a410
	defb 0aeh,09eh,0dch,0fch,0f8h,0f0h,0e0h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h	; a420
	defb 07eh,07eh,07eh,03eh,07eh,078h,070h,060h,0e0h,0e0h,0e0h,0c0h,080h,000h,000h,000h	; a430
	defb 002h,007h,00fh,01fh,02fh,037h,03bh,03dh,006h,003h,081h,0c1h,0e1h,0f3h,0e3h,0d1h	; a440
	defb 0fbh,0efh,0f7h,0ffh,0ebh,0ffh,0ffh,07fh,040h,040h,080h,0c0h,0c0h,0c0h,0c0h,080h	; a450
	defb 00fh,003h,000h,000h,000h,000h,000h,09ch,0f7h,0feh,07ah,000h,000h,000h,000h,000h	; a460
	defb 000h,000h,003h,001h,000h,000h,000h,000h,03fh,0fdh,0dah,068h,0a5h,0b4h,003h,00bh	; a470
	defb 0f0h,0f0h,070h,078h,078h,0f8h,0b8h,0bch,000h,000h,000h,000h,000h,000h,000h,000h	; a480
	defb 003h,000h,000h,000h,000h,000h,000h,000h,0ddh,0ebh,07bh,037h,0aeh,01ch,058h,050h	; a490
	defb 09eh,08eh,004h,004h,00ch,018h,018h,030h,05fh,01fh,01fh,00fh,01fh,00fh,007h,007h	; a4a0
	defb 0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,0c0h,0e0h,0f0h,0f8h,0feh,0ffh	; a4b0
	defb 00ch,000h,000h,000h,000h,000h,000h,000h,080h,00eh,03eh,00ch,004h,000h,008h,000h	; a4c0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,004h,000h,000h,001h,004h,010h,000h,009h	; a4d0
	defb 0c0h,0a0h,020h,000h,0c0h,0a0h,020h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a4e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a4f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0f7h,0fbh,03fh,000h,000h,000h,000h,000h	; a500
	defb 0c0h,0c1h,081h,003h,007h,00fh,00fh,01fh,0ffh,0ffh,0fbh,0feh,0beh,09ch,0f8h,0f0h	; a510
	defb 0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a520
	defb 06ch,05ch,05ch,05eh,05eh,05fh,06fh,06fh,000h,000h,000h,000h,000h,000h,0c0h,0a0h	; a530
	defb 03dh,03fh,03fh,03dh,03dh,03fh,03fh,03fh,033h,011h,031h,033h,070h,031h,031h,071h	; a540
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0feh,0fch,081h,083h,007h,007h,00fh,00fh,01eh,01dh	; a550
	defb 0e2h,0ech,0d8h,0f0h,0a0h,000h,080h,011h,000h,000h,000h,000h,01fh,038h,0e0h,0c0h	; a560
	defb 000h,000h,000h,000h,080h,070h,008h,004h,005h,027h,00bh,00bh,00fh,007h,003h,007h	; a570
	defb 0fch,0fch,07eh,0beh,0feh,0ffh,0ffh,0bfh,000h,000h,002h,005h,005h,00bh,01fh,00fh	; a580
	defb 000h,000h,000h,080h,0a0h,0fch,0feh,0ffh,000h,000h,000h,001h,007h,00ch,050h,0c0h	; a590
	defb 070h,060h,0c0h,087h,003h,003h,001h,001h,003h,002h,000h,000h,0c0h,0f0h,0f8h,0fch	; a5a0
	defb 0ffh,0ffh,0dfh,03fh,037h,00bh,003h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,0bfh	; a5b0
	defb 08ch,0ceh,0f7h,0f9h,0feh,0ffh,0ffh,0ffh,004h,002h,089h,0c0h,0e0h,072h,091h,0e0h	; a5c0
	defb 000h,000h,040h,089h,084h,010h,04ah,088h,024h,082h,00bh,001h,0b4h,092h,04bh,06fh	; a5d0
	defb 0c0h,0c0h,020h,010h,0e0h,0e0h,030h,070h,000h,000h,000h,000h,000h,000h,000h,000h	; a5e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a5f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a600
	defb 03fh,03fh,07fh,07fh,07fh,07fh,07fh,07fh,0f7h,0e5h,0cah,0c0h,0ffh,0ffh,0ffh,0ffh	; a610
	defb 0f0h,05ch,0abh,055h,00ah,0e5h,0f2h,0f9h,000h,000h,000h,080h,0c0h,060h,0a0h,050h	; a620
	defb 077h,078h,07eh,07eh,076h,06eh,066h,066h,060h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; a630
	defb 03fh,03fh,03fh,03bh,03fh,03fh,03fh,01fh,071h,071h,071h,070h,070h,071h,071h,070h	; a640
	defb 0fch,0fah,0f8h,0f8h,0f4h,0f0h,0f0h,0e0h,03eh,03dh,079h,07dh,07eh,0f6h,0edh,0edh	; a650
	defb 0a3h,06eh,014h,078h,0f0h,0d0h,060h,0c0h,000h,000h,007h,003h,009h,00ch,006h,001h	; a660
	defb 002h,002h,080h,0c1h,0c1h,080h,040h,001h,001h,001h,001h,001h,000h,000h,000h,000h	; a670
	defb 0ffh,0ffh,0ffh,0bfh,0ffh,07fh,07fh,03fh,00fh,083h,080h,080h,080h,0cah,0cah,0c5h	; a680
	defb 0ffh,0ffh,0ffh,07fh,03fh,01ch,0c0h,080h,0c0h,080h,080h,000h,000h,000h,000h,000h	; a690
	defb 000h,000h,000h,000h,000h,000h,000h,000h,07fh,01fh,007h,001h,000h,000h,000h,000h	; a6a0
	defb 000h,0c0h,0d8h,0dch,0beh,07eh,01eh,000h,0bfh,00fh,00bh,007h,000h,000h,000h,000h	; a6b0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,03fh,03fh,00bh,0f0h,0f8h,0fdh,0feh,0feh,0feh,0fdh,0f9h	; a6c0
	defb 024h,012h,04bh,029h,084h,016h,04bh,009h,0b7h,097h,05bh,07fh,0bfh,0ffh,07fh,07fh	; a6d0
	defb 0f0h,0f0h,0f0h,0f0h,0f0h,0f0h,0e0h,0e0h,000h,000h,000h,000h,000h,000h,000h,000h	; a6e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a6f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a700
	defb 07fh,07fh,07fh,07fh,000h,000h,000h,000h,0f7h,0f7h,0fdh,0f5h,01dh,00eh,007h,007h	; a710
	defb 0fch,0feh,0feh,0feh,0ffh,087h,073h,063h,0b0h,058h,0a8h,058h,028h,058h,028h,058h	; a720
	defb 066h,066h,06eh,07eh,06eh,07eh,07eh,03eh,0e0h,0e0h,0e0h,0e0h,0c0h,0e0h,0e0h,0e0h	; a730
	defb 01fh,01fh,03fh,03fh,03fh,03fh,03fh,03fh,070h,070h,070h,070h,070h,070h,070h,070h	; a740
	defb 001h,001h,001h,001h,003h,002h,003h,007h,0dbh,0ffh,06fh,06eh,0deh,0d4h,0ech,0e8h	; a750
	defb 080h,000h,001h,003h,007h,00fh,00fh,00fh,000h,07ch,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a760
	defb 000h,000h,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,004h,002h,0d8h,0fch,0fch,0fch	; a770
	defb 03fh,007h,000h,000h,000h,001h,003h,003h,0edh,04ah,002h,000h,000h,0dah,0feh,0ffh	; a780
	defb 000h,000h,000h,000h,000h,000h,000h,0c0h,000h,000h,000h,000h,000h,000h,000h,000h	; a790
	defb 000h,000h,000h,000h,000h,000h,004h,0a0h,000h,000h,000h,015h,002h,055h,0aah,055h	; a7a0
	defb 000h,000h,0a2h,014h,0aah,055h,0aah,055h,000h,000h,000h,042h,0a8h,055h,0aah,055h	; a7b0
	defb 00bh,000h,000h,000h,000h,000h,000h,000h,0fah,0b6h,034h,000h,000h,002h,001h,000h	; a7c0
	defb 025h,017h,04bh,02fh,027h,017h,04bh,08fh,0ffh,0ffh,0ffh,0ffh,0ffh,0fch,0f0h,0c0h	; a7d0
	defb 0c0h,0c0h,0c0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a7f0
	defb 000h,000h,000h,000h,000h,000h,000h,001h,000h,00fh,015h,02ah,040h,03fh,0efh,0ffh	; a800
	defb 000h,0feh,055h,0aah,005h,0f2h,0d9h,0dah,006h,006h,006h,086h,086h,0c7h,047h,0a7h	; a810
	defb 0e1h,0e1h,0e1h,0e1h,0f1h,073h,07bh,087h,028h,058h,028h,058h,028h,058h,028h,058h	; a820
	defb 03eh,07eh,07eh,07eh,07eh,07eh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0c0h,0c0h,0e0h,0e0h	; a830
	defb 03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,070h,070h,070h,070h,070h,070h,070h,070h	; a840
	defb 007h,00fh,00fh,00fh,00eh,01eh,017h,017h,0d8h,0d8h,0f0h,050h,0e0h,0e0h,060h,0e0h	; a850
	defb 00fh,007h,015h,001h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,03fh,00fh	; a860
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0d9h	; a870
	defb 08fh,0cfh,0efh,0efh,0e7h,0f7h,0f7h,073h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a880
	defb 0c0h,0e0h,0e0h,0f0h,0e0h,0e0h,0c0h,0c0h,004h,004h,000h,042h,004h,025h,04ah,040h	; a890
	defb 002h,015h,00ah,055h,0aah,055h,0aah,057h,0aah,055h,0abh,055h,0aah,07fh,0bbh,0ffh	; a8a0
	defb 0aah,0d5h,0aah,0d5h,0feh,0fdh,0ffh,0f7h,0aah,055h,0aah,055h,0ffh,05fh,0ffh,0fdh	; a8b0
	defb 0a0h,051h,0aah,055h,0aah,055h,0bah,0fdh,000h,048h,0a0h,054h,0a8h,055h,0aah,055h	; a8c0
	defb 004h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8d0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a8f0
	defb 001h,001h,001h,001h,001h,001h,001h,001h,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a900
	defb 08dh,074h,0fdh,0f8h,0f9h,0fah,0f1h,0dah,067h,0a7h,047h,0c7h,047h,0c7h,04eh,0ddh	; a910
	defb 0ffh,0f3h,06bh,0a7h,087h,097h,04bh,02bh,028h,058h,028h,058h,028h,058h,028h,058h	; a920
	defb 03eh,07eh,07eh,07eh,03eh,01eh,00eh,004h,0e0h,0e0h,0e0h,0e0h,0c0h,080h,000h,000h	; a930
	defb 03fh,03eh,03ah,03fh,03fh,03fh,03fh,03fh,070h,070h,070h,070h,070h,070h,070h,070h	; a940
	defb 016h,01fh,01fh,01fh,02fh,01fh,02fh,017h,0c0h,0c0h,080h,080h,080h,000h,000h,000h	; a950
	defb 000h,000h,000h,000h,000h,001h,00fh,01fh,003h,000h,001h,000h,000h,000h,0e0h,0f8h	; a960
	defb 0ffh,0ffh,07fh,00dh,001h,000h,000h,000h,0ffh,0fch,0fdh,0c0h,080h,000h,000h,000h	; a970
	defb 0fbh,0fbh,0f0h,071h,0a1h,040h,080h,000h,0ffh,0ffh,0d3h,0bdh,0bch,000h,000h,000h	; a980
	defb 0a0h,0a1h,088h,042h,000h,009h,048h,013h,00ah,015h,02ah,015h,0aah,055h,0afh,05fh	; a990
	defb 0abh,057h,0afh,05fh,0abh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a9a0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; a9b0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0eah,0d5h,0fah,07dh,0ffh,0ffh,0ffh,0ffh	; a9c0
	defb 0a8h,055h,0aah,055h,0aah,0f5h,0eah,0fdh,000h,000h,0a0h,015h,0aah,054h,0aah,055h	; a9d0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; a9f0
	defb 001h,001h,001h,001h,001h,001h,001h,001h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aa00
	defb 09ch,0dfh,0e9h,0f2h,0f6h,0fah,0f9h,0fch,036h,0f2h,04bh,069h,0a4h,092h,02dh,02dh	; aa10
	defb 05bh,0d7h,04bh,06fh,0b7h,0dfh,0ffh,07fh,028h,058h,028h,058h,030h,050h,026h,061h	; aa20
	defb 000h,000h,000h,000h,000h,000h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h	; aa30
	defb 03fh,03eh,03fh,03bh,039h,033h,033h,037h,070h,070h,070h,070h,070h,070h,010h,070h	; aa40
	defb 02bh,01eh,03eh,05eh,03ch,07ch,07ch,098h,000h,000h,000h,001h,001h,000h,000h,000h	; aa50
	defb 03fh,0ffh,0ffh,0ffh,0ffh,07fh,01fh,01fh,0fch,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aa60
	defb 000h,028h,0e8h,0feh,0ffh,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,000h,080h,0c0h	; aa70
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,009h,042h,011h,02ah,045h,00ah,055h	; aa80
	defb 0aah,015h,0abh,055h,0abh,055h,0abh,05fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aa90
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aaa0
	defb 000h,000h,010h,001h,00ah,055h,0abh,055h,000h,000h,004h,010h,0aah,055h,0aah,055h	; aab0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; aac0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0aah,0d5h,0aah,0f5h,0aah,0f5h,0fah,0f5h	; aad0
	defb 0a0h,055h,0aah,054h,0aah,055h,0aah,055h,000h,000h,080h,040h,080h,050h,0a8h,050h	; aae0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aaf0
	defb 001h,000h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,07fh,07fh,037h,031h	; ab00
	defb 0feh,0ffh,0ffh,0ffh,0ebh,0d9h,0f5h,0edh,0b7h,0cbh,0cfh,0efh,0b7h,05fh,07fh,07fh	; ab10
	defb 0ffh,0feh,0feh,0feh,0fch,0fch,0fch,0f8h,040h,000h,0e0h,038h,00dh,006h,002h,003h	; ab20
	defb 040h,020h,050h,0b0h,058h,0a8h,058h,02ch,000h,000h,000h,000h,000h,000h,000h,000h	; ab30
	defb 033h,03fh,03fh,03fh,03fh,03eh,03fh,01fh,030h,010h,050h,070h,070h,070h,070h,060h	; ab40
	defb 018h,038h,0f0h,070h,0b0h,060h,0a0h,060h,000h,000h,000h,000h,000h,000h,000h,000h	; ab50
	defb 00fh,00fh,00fh,007h,001h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,05fh,007h	; ab60
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0c7h,0e0h,0e0h,0e0h,0f0h,0f8h,0f0h,0f0h,0f0h	; ab70
	defb 000h,005h,000h,005h,00ah,005h,0aah,015h,0aah,055h,0aah,055h,0aah,055h,0aah,057h	; ab80
	defb 0bfh,05fh,0ffh,07fh,0efh,07fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ab90
	defb 010h,001h,00ah,055h,02ah,055h,0abh,055h,02ah,015h,0aah,057h,0aah,057h,0bbh,05fh	; aba0
	defb 0afh,03dh,0feh,07fh,0ffh,0f3h,0f3h,0f1h,0deh,0fbh,0ffh,0feh,0ffh,0e7h,0c3h,013h	; abb0
	defb 084h,051h,0aah,0d5h,0aah,0fdh,06eh,0f5h,000h,008h,0a0h,054h,0aah,055h,0aah,055h	; abc0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0feh,0fdh,0feh,0fdh,0ffh,0fdh,0ffh,0ffh	; abd0
	defb 0aah,055h,0aah,055h,0aah,055h,0aah,055h,0a0h,055h,0aah,051h,0aah,055h,0aah,054h	; abe0
	defb 000h,000h,040h,000h,080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; abf0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,018h,00ch,007h,001h,000h,000h,000h,000h	; ac00
	defb 042h,013h,021h,0e5h,07ah,00fh,060h,040h,0bfh,0ffh,07fh,0ffh,0ffh,0f8h,000h,001h	; ac10
	defb 0f8h,0f0h,0e0h,0c0h,00eh,033h,0c1h,023h,007h,017h,00fh,00fh,03fh,03fh,0ffh,0ffh	; ac20
	defb 054h,02ch,094h,0ach,094h,0ach,094h,0a8h,000h,000h,000h,000h,000h,000h,000h,000h	; ac30
	defb 01fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,020h,070h,070h,060h,060h,050h,070h,070h	; ac40
	defb 0e0h,060h,080h,040h,0c0h,040h,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ac50
	defb 000h,000h,070h,038h,09ch,0cch,064h,010h,007h,001h,000h,000h,000h,000h,07eh,0ffh	; ac60
	defb 0c0h,000h,000h,000h,000h,000h,000h,000h,0b0h,020h,000h,000h,000h,000h,000h,000h	; ac70
	defb 02ah,015h,02ah,055h,02ah,015h,0aah,015h,0afh,05fh,0afh,07fh,0aeh,07fh,0ffh,07fh	; ac80
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,00ah,015h,002h,015h,02ah,045h,02ah,055h	; ac90
	defb 0aah,057h,0bfh,057h,0bfh,06fh,0beh,0fch,0ffh,0ffh,0ffh,0ffh,0ffh,00fh,00fh,01fh	; aca0
	defb 0e0h,0e0h,0e0h,0c0h,0c0h,0c0h,0c0h,0c0h,003h,033h,0b3h,0b3h,069h,075h,039h,051h	; acb0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0f0h,0fbh,0f0h,0eah,0f5h,0feh,0edh,0feh,07fh,03eh,0bfh	; acc0
	defb 0a0h,050h,0a0h,054h,0a9h,0d5h,0aah,054h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; acd0
	defb 0bah,0d5h,0fah,0fdh,0fah,0ddh,0fah,0fdh,0aah,055h,0aah,055h,0aah,055h,0aah,055h	; ace0
	defb 0a0h,040h,0a8h,040h,0a8h,040h,0a0h,050h,000h,000h,000h,000h,000h,000h,000h,000h	; acf0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad00
	defb 040h,040h,040h,070h,07fh,07fh,07fh,07fh,002h,002h,005h,00ch,0fdh,0fch,0fdh,0fch	; ad10
	defb 067h,0a7h,063h,0a1h,060h,0a7h,07dh,0aah,0ffh,0ffh,0ffh,0c3h,07ch,080h,078h,0aeh	; ad20
	defb 090h,0a0h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ad30
	defb 03fh,03fh,03fh,03fh,01fh,03fh,03fh,03fh,060h,070h,070h,070h,070h,070h,070h,070h	; ad40
	defb 080h,080h,080h,080h,080h,040h,040h,020h,000h,000h,000h,000h,000h,000h,000h,000h	; ad50
	defb 003h,007h,00fh,00fh,01fh,01fh,003h,003h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ad60
	defb 0c0h,0e0h,0f8h,0f8h,0feh,0feh,0feh,0ffh,000h,000h,000h,000h,000h,000h,000h,000h	; ad70
	defb 02ah,015h,02ah,055h,0afh,055h,02fh,055h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ad80
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0aah,057h,02ah,055h,0aah,055h,02ah,095h	; ad90
	defb 0fch,07ch,0f8h,078h,0b8h,0f8h,078h,0f8h,01fh,01fh,01fh,00eh,000h,000h,000h,000h	; ada0
	defb 000h,000h,000h,000h,00fh,009h,01dh,011h,000h,000h,000h,000h,01eh,013h,0bbh,0a3h	; adb0
	defb 0e0h,040h,000h,002h,004h,00dh,00eh,016h,09fh,09fh,01fh,01eh,01fh,01fh,01fh,01fh	; adc0
	defb 0a8h,055h,0aah,0d5h,0eah,055h,0aah,054h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; add0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0aah,055h,0aah,055h,0eah,0d5h,0aah,0d5h	; ade0
	defb 0a0h,048h,0a0h,050h,0a8h,050h,088h,050h,000h,000h,000h,000h,000h,000h,000h,000h	; adf0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; ae00
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0fdh,0fch,0fdh,0ffh,0ffh,0ffh,0ffh,0ffh	; ae10
	defb 040h,03fh,0ffh,0ffh,0f7h,0efh,0ffh,0ffh,055h,00ah,0e5h,0f2h,0f9h,0fch,0fdh,0feh	; ae20
	defb 080h,0c0h,060h,0b0h,050h,0a8h,058h,0a8h,000h,000h,000h,000h,000h,000h,000h,000h	; ae30
	defb 03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,060h,050h,070h,060h,06fh,047h,00fh,000h	; ae40
	defb 010h,000h,000h,000h,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,0c0h,0a0h,020h,020h	; ae50
	defb 001h,001h,000h,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,07fh,01fh,00fh,003h,001h	; ae60
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0fbh,080h,080h,0e0h,0e0h,0e0h,0e0h,0e0h,0c0h	; ae70
	defb 00bh,055h,02bh,047h,02bh,017h,04bh,097h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; ae80
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,02bh,055h,02ah,015h,02ah,015h,002h,000h	; ae90
	defb 0f8h,07ch,0fch,05eh,0bfh,057h,01fh,002h,000h,000h,000h,000h,000h,080h,0f0h,0bch	; aea0
	defb 013h,01fh,01fh,00fh,00fh,000h,000h,000h,0e7h,0ffh,0beh,0beh,01ch,000h,000h,000h	; aeb0
	defb 014h,008h,000h,000h,001h,007h,00fh,038h,01eh,03fh,07fh,07dh,0f7h,0fdh,0aah,014h	; aec0
	defb 0aah,055h,0aah,054h,0a9h,054h,088h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,01fh	; aed0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0aah,0d5h,0eah,0d5h,0eah,0d5h,0eah,0d5h	; aee0
	defb 0a0h,044h,0a0h,050h,0a0h,050h,0a0h,050h,000h,000h,000h,000h,000h,000h,000h,000h	; aef0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af00
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0ffh,0feh,0feh,0fdh,0fch,0fdh,0fch,0fdh	; af10
	defb 007h,063h,0a3h,061h,0a1h,061h,0a1h,061h,0ffh,0ffh,0ffh,0ffh,0ffh,0bfh,0ffh,0d7h	; af20
	defb 054h,02ch,014h,0ach,094h,0ach,094h,0ach,000h,000h,000h,000h,000h,000h,000h,000h	; af30
	defb 03fh,03fh,03fh,03fh,03fh,01fh,01fh,03fh,07fh,0e7h,07fh,07fh,07fh,0feh,000h,000h	; af40
	defb 0feh,0fah,0feh,0eeh,0deh,0beh,07eh,07eh,060h,0a0h,0a0h,0e0h,060h,0e0h,0e0h,0e0h	; af50
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af60
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; af70
	defb 02bh,017h,02bh,055h,029h,005h,012h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; af80
	defb 0feh,0fch,0fch,0f8h,0f8h,0f8h,0f8h,0f8h,07ch,004h,0d4h,0d4h,0f4h,0f4h,0f3h,0f4h	; af90
	defb 000h,000h,000h,000h,000h,000h,00fh,0e0h,000h,000h,000h,000h,000h,000h,003h,09ch	; afa0
	defb 01fh,001h,03dh,03dh,03dh,0bdh,039h,0bdh,00fh,000h,01ah,01ah,01eh,01eh,01eh,01eh	; afb0
	defb 080h,080h,080h,080h,080h,080h,060h,09ch,000h,000h,000h,000h,000h,000h,078h,085h	; afc0
	defb 003h,000h,007h,007h,007h,017h,067h,097h,0e0h,020h,0a0h,0a0h,0a0h,0a0h,020h,0a0h	; afd0
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0eah,0d5h,0aah,0d5h,0aah,055h,0eah,054h	; afe0
	defb 080h,048h,020h,040h,080h,000h,080h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; aff0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b000
	defb 07fh,07fh,077h,07fh,06fh,07fh,07fh,07fh,0fch,0fdh,0fch,0fdh,0fch,0fdh,0fch,0fdh	; b010
	defb 0a1h,061h,0a1h,061h,0a1h,061h,0a1h,061h,0efh,0a5h,0cbh,089h,0e9h,0a5h,0cbh,0d3h	; b020
	defb 094h,0ach,094h,0ach,094h,0ach,094h,0ach,000h,000h,000h,000h,000h,000h,000h,000h	; b030
	defb 01fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,010h,000h,050h,030h,050h,070h,070h,070h	; b040
	defb 07eh,07eh,07eh,07eh,07eh,03eh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; b050
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b060
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b070
	defb 002h,005h,000h,002h,000h,000h,000h,000h,0ffh,077h,0beh,055h,0aah,015h,02ah,050h	; b080
	defb 0f8h,050h,0e8h,050h,0a0h,054h,080h,000h,0f7h,0ffh,0f7h,0ffh,0d7h,0f7h,0d7h,0d7h	; b090
	defb 000h,0e0h,0e0h,0e0h,0f8h,0ffh,0bfh,0efh,063h,01fh,05fh,05fh,05fh,0dfh,0dfh,0dfh	; b0a0
	defb 0bdh,0bdh,0f9h,0b9h,0bdh,0ddh,0bdh,0bdh,01eh,01fh,01eh,01fh,01ah,01eh,01ah,01ah	; b0b0
	defb 0e2h,0fdh,0fdh,0fdh,0ffh,0fdh,0f7h,0fdh,000h,003h,003h,003h,00fh,0fbh,0fbh,0fbh	; b0c0
	defb 077h,0f7h,0ffh,0f7h,0f7h,0fbh,0f7h,0f7h,0a0h,0a0h,020h,020h,0a0h,0a0h,0a0h,0a0h	; b0d0
	defb 0beh,075h,0aeh,055h,0aah,015h,0aah,044h,0aah,055h,0a8h,054h,0a0h,054h,082h,000h	; b0e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b0f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b100
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0fch,0fdh,0fch,0fdh,0fch,0fdh,0fch,0fdh	; b110
	defb 0a1h,061h,0a1h,061h,0a1h,061h,0b1h,051h,089h,0a5h,093h,083h,0c9h,0a5h,091h,0d3h	; b120
	defb 094h,0ach,094h,0ach,094h,0ach,094h,0ach,000h,000h,000h,000h,000h,000h,000h,000h	; b130
	defb 03fh,03fh,03fh,03fh,03fh,03fh,03fh,03fh,070h,070h,070h,070h,070h,070h,070h,070h	; b140
	defb 07eh,07eh,03eh,03eh,03eh,07eh,07eh,07eh,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h,0e0h	; b150
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b160
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b170
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b180
	defb 000h,000h,000h,000h,000h,000h,000h,000h,0d7h,0f7h,0f7h,0efh,0e3h,0f7h,0e5h,023h	; b190
	defb 0afh,0efh,0efh,0a7h,0afh,0ffh,0efh,0efh,0dfh,0ffh,0dfh,07fh,05eh,0d6h,0deh,0dfh	; b1a0
	defb 0adh,0bdh,0bdh,0bdh,0adh,0fdh,0b5h,0b5h,01ah,01eh,01eh,01dh,01ch,01eh,01eh,00eh	; b1b0
	defb 0f5h,0fdh,0fdh,0f4h,075h,0ffh,0bdh,07dh,0fbh,0ffh,0fbh,0efh,0ebh,0fah,0fbh,0fbh	; b1c0
	defb 0f5h,0f7h,0f7h,0f7h,0d5h,0dfh,0d6h,0f6h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h	; b1d0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b1e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b1f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b200
	defb 07fh,07fh,07fh,07fh,07fh,07fh,07fh,07fh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b210
	defb 0abh,053h,007h,0ffh,0ffh,0ffh,0ffh,0feh,0f9h,0fdh,0ddh,0efh,087h,073h,063h,0e1h	; b220
	defb 094h,0ach,094h,0ach,094h,0ach,094h,0ach,000h,000h,000h,000h,000h,000h,000h,000h	; b230
	defb 03fh,03fh,03fh,03fh,03fh,03fh,03fh,01fh,072h,072h,070h,070h,06fh,047h,00fh,000h	; b240
	defb 07eh,07eh,07eh,07eh,07eh,07eh,07eh,026h,0e0h,0e0h,0e0h,0e0h,0dfh,08fh,01fh,000h	; b250
	defb 000h,000h,000h,000h,0ffh,0ffh,0ffh,000h,000h,000h,000h,000h,0d8h,0ffh,0ffh,000h	; b260
	defb 000h,000h,000h,000h,0ffh,0ffh,0fbh,000h,000h,000h,000h,000h,0ffh,0ffh,0ffh,000h	; b270
	defb 000h,000h,000h,000h,0ffh,0ffh,0fdh,000h,000h,000h,000h,000h,0f7h,0ffh,0ffh,000h	; b280
	defb 000h,000h,000h,000h,0ffh,0ffh,0fdh,000h,01eh,000h,000h,000h,0f7h,0efh,0bfh,000h	; b290
	defb 01fh,02fh,003h,000h,0f0h,0ech,0c6h,00fh,0efh,09fh,0cfh,05bh,01fh,01fh,003h,000h	; b2a0
	defb 0d4h,0fdh,0bdh,0bdh,0b5h,0bdh,0bdh,02ch,01ah,01eh,01eh,01ch,01eh,01eh,01eh,00ch	; b2b0
	defb 0fdh,0d9h,0eah,0fdh,0fdh,0f4h,020h,000h,0fbh,0ebh,0fbh,0fbh,0fbh,01bh,003h,003h	; b2c0
	defb 0f5h,0f7h,0f7h,0f7h,077h,0f7h,0f7h,0c7h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0a0h,0c0h	; b2d0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b2e0
	defb 07fh,080h,09bh,0a2h,0a3h,09eh,080h,07fh,0f1h,001h,019h,095h,0d5h,053h,010h,0f1h	; b2f0
	defb 0feh,001h,039h,045h,045h,039h,001h,0feh,000h,000h,000h,000h,000h,000h,000h,000h	; b300
	defb 07fh,07fh,07fh,03fh,03fh,03fh,01fh,01fh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b310
	defb 0feh,0feh,0feh,0f2h,0edh,0ffh,0efh,0efh,0e1h,0e1h,0e1h,0f1h,073h,07bh,087h,0efh	; b320
	defb 094h,0a8h,098h,0a8h,090h,0a0h,040h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b330
	defb 03eh,03fh,03bh,037h,02fh,01fh,000h,000h,0ffh,0ffh,0ffh,0ffh,0e7h,0ffh,000h,000h	; b340
	defb 0ffh,0e4h,0dfh,0fbh,0fdh,03fh,000h,000h,0ffh,0ffh,0ffh,0ffh,0bfh,0ffh,000h,000h	; b350
	defb 0ffh,0ffh,0ffh,0ffh,0deh,0ffh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h	; b360
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0bfh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,0f1h,000h,000h	; b370
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,0ffh,0ffh,0f4h,0f8h,0fbh,0ffh,000h,000h	; b380
	defb 0ffh,0ffh,03fh,03fh,07fh,0ffh,000h,000h,0ffh,0ffh,0ffh,0ffh,0ffh,07fh,000h,000h	; b390
	defb 087h,0dfh,0efh,0f7h,0fah,0fch,000h,000h,080h,0c0h,080h,000h,000h,000h,000h,000h	; b3a0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3b0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3c0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3d0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3e0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b3f0
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b400
	defb 00fh,007h,003h,001h,000h,000h,000h,000h,0ffh,0ffh,0ffh,0ffh,07fh,00fh,000h,000h	; b410
	defb 0f7h,0ffh,0ffh,0ffh,0ffh,0ffh,000h,000h,0efh,0f6h,0fch,0f8h,0f0h,0c0h,000h,000h	; b420
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; b430

;; ------------------------------------------------------------------- colores
;; Un byte por celda de 8x8, en el formato del MSX: el nibble alto es la tinta y
;; el bajo el fondo. Son 32x24 = 768. La rutina RELLENA escribe cada uno ocho
;; veces seguidas para completar la tabla de color de la VRAM.
	defb 0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0a1h,0a1h,0a1h,0a1h	; b440
	defb 0a1h,0b1h,0b1h,0b1h,0a1h,0a1h,0a1h,0b1h,0b1h,0b1h,0b1h,0b1h,021h,0c1h,021h,0c1h	; b450
	defb 0f1h,0f1h,0f1h,0f1h,0f1h,071h,071h,0f1h,0f1h,0f1h,0f1h,0f1h,0b1h,0b1h,0b1h,0b1h	; b460
	defb 0a1h,0a1h,0a1h,0a1h,0b1h,0b1h,0b1h,0a1h,0a1h,0a1h,0a1h,0a1h,021h,0c1h,021h,0c1h	; b470
	defb 0f1h,0f1h,0f1h,0f1h,071h,071h,071h,071h,071h,0b1h,0f1h,0f1h,0a1h,0a1h,0a1h,0a1h	; b480
	defb 0b1h,0b1h,0b1h,0b1h,0a1h,0a1h,0a1h,0b1h,0b1h,0b1h,0b1h,0b1h,021h,0c1h,021h,0c1h	; b490
	defb 0f1h,0f1h,0f1h,0f1h,0f1h,071h,071h,071h,071h,071h,071h,0f1h,0b1h,0b1h,0b1h,0b1h	; b4a0
	defb 0a1h,0a1h,0a1h,0a1h,0b1h,0b1h,0a1h,0a1h,0a1h,0a1h,0a1h,0a1h,021h,021h,021h,0c1h	; b4b0
	defb 0f1h,0f1h,0f1h,0d1h,0d1h,071h,071h,071h,071h,071h,071h,071h,0a1h,0a1h,0a1h,0a1h	; b4c0
	defb 0b1h,0b1h,0b1h,0b1h,0a1h,0a1h,0a1h,0a1h,0b1h,0b1h,081h,081h,081h,081h,021h,0c1h	; b4d0
	defb 0b1h,0b1h,0b1h,0b1h,0b1h,0b5h,0b5h,071h,051h,051h,051h,071h,071h,0b1h,0b1h,0b1h	; b4e0
	defb 0a1h,0a1h,0a1h,0a1h,0b1h,0b1h,0b1h,0b1h,0a1h,0a1h,081h,081h,081h,081h,021h,0c1h	; b4f0
	defb 0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,051h,051h,051h,051h,071h,0a1h,0a1h,0a1h	; b500
	defb 0b1h,0b1h,0b1h,0b1h,0a1h,0a1h,0a1h,0a1h,0b1h,0b1h,081h,081h,081h,081h,021h,0c1h	; b510
	defb 0d1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,051h,051h,051h,071h,071h,071h,0a1h	; b520
	defb 0e1h,0e1h,0e1h,0e1h,0e1h,0e1h,0f1h,0f1h,081h,081h,081h,081h,081h,081h,021h,0c1h	; b530
	defb 021h,0c1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,051h,051h,051h,071h,071h,071h	; b540
	defb 0e1h,0e1h,0e1h,0e1h,0e1h,0e1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0c1h,0c1h	; b550
	defb 021h,0c1h,0b1h,051h,051h,071h,071h,0b1h,0b1h,051h,051h,051h,051h,051h,071h,071h	; b560
	defb 071h,071h,0e1h,0e1h,0e1h,0f1h,0f1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,021h,0c1h	; b570
	defb 021h,0c1h,0b1h,051h,071h,071h,071h,0b1h,0b1h,051h,051h,051h,0b1h,051h,051h,071h	; b580
	defb 071h,071h,0e1h,0e1h,0e1h,0f1h,0f1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,021h,0c1h	; b590
	defb 021h,0c1h,051h,071h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,041h	; b5a0
	defb 071h,071h,0e1h,0e1h,0e1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,081h,021h,0c1h	; b5b0
	defb 021h,0c1h,071h,071h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,041h,041h	; b5c0
	defb 041h,041h,041h,041h,0f1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,081h,021h,0c1h	; b5d0
	defb 021h,0c1h,071h,071h,0b1h,0b1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,041h,041h,041h	; b5e0
	defb 041h,041h,041h,041h,041h,041h,0f1h,0f1h,081h,081h,081h,081h,081h,081h,081h,0f1h	; b5f0
	defb 021h,0c1h,071h,0b1h,0b1h,0b1h,0b1h,0b1h,0f1h,041h,041h,041h,041h,041h,074h,074h	; b600
	defb 041h,041h,041h,041h,041h,041h,041h,0f1h,081h,081h,081h,081h,081h,081h,081h,0f1h	; b610
	defb 021h,0c1h,071h,0f1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,041h,074h,074h,071h,071h	; b620
	defb 074h,074h,041h,041h,041h,041h,041h,0f1h,081h,081h,081h,081h,081h,081h,081h,0f1h	; b630
	defb 021h,0c1h,071h,0a1h,071h,0b1h,0b1h,0b1h,041h,041h,041h,074h,071h,071h,071h,071h	; b640
	defb 071h,071h,074h,041h,041h,041h,041h,041h,0f1h,081h,081h,081h,081h,081h,081h,0f1h	; b650
	defb 021h,0c1h,071h,0c1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,074h,071h,071h,0f1h,0f1h	; b660
	defb 051h,071h,074h,041h,041h,041h,041h,041h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b670
	defb 021h,0c1h,0c1h,0c1h,0b1h,0b1h,0b1h,0b1h,041h,041h,041h,074h,071h,071h,0f1h,0f1h	; b680
	defb 071h,071h,074h,041h,041h,041h,041h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b690
	defb 021h,021h,021h,0c1h,0f1h,0f1h,0b1h,0b1h,041h,041h,041h,021h,0c1h,0c1h,0c1h,021h	; b6a0
	defb 0c1h,021h,0c1h,021h,041h,041h,041h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b6b0
	defb 021h,0c1h,021h,0c1h,0f1h,0f1h,0f1h,0f1h,041h,041h,041h,021h,0c1h,021h,0c1h,021h	; b6c0
	defb 0c1h,021h,0c1h,021h,041h,041h,041h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b6d0
	defb 021h,0c1h,021h,0c1h,0f1h,0f1h,0f1h,0f1h,041h,041h,041h,021h,0c1h,021h,0c1h,021h	; b6e0
	defb 0c1h,021h,0c1h,021h,041h,041h,041h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b6f0
	defb 021h,0c1h,021h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,0c1h,021h,0c1h,021h	; b700
	defb 021h,021h,0c1h,021h,041h,0f1h,0f1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b710
	defb 021h,021h,021h,021h,021h,021h,021h,021h,021h,021h,021h,021h,021h,0c1h,0f1h,0f1h	; b720
	defb 0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,0f1h,081h,081h,081h,081h,081h,0f1h	; b730

;; -------------------------------------------------------------------- basura
;; 88 bytes que no lee nadie. Se ve que no son relleno de ensamblador porque
;; siguen la regla "0xFF si el bit 0 de la direccion coincide con el bit 7, y
;; 0x00 si no", que es el aspecto que tiene la RAM de un MSX recien encendido:
;; el BSAVE con el que se grabo el bloque cogio un rango un poco mas ancho que
;; los datos y arrastro lo que habia detras. Comprobado en el emulador con un
;; punto de observacion sobre este rango: cero lecturas durante el pintado.
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; b740
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; b750
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; b760
	defb 0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h	; b770
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh	; b780
	defb 000h,0ffh,000h,0ffh,000h,0ffh,000h,0ffh	; b790

;; -------------------------------------------------------------------- codigo
;; Punto de entrada: el `exec` que declara la cabecera BIN del bloque.
pinta:
	call DISSCR		; apaga la pantalla: ni se ve el proceso, ni hay
	di			; que pelearse con el VDP por el acceso a la VRAM
	ld hl,09c40h		; origen  = los dibujos, aqui mismo
	ld de,00000h		; destino = VRAM 0x0000, la tabla de patrones
	ld bc,01800h		; los 6144 bytes de una tacada
	call ram2vram

	ld hl,02000h		; destino = VRAM 0x2000, la tabla de color
	ld de,0b440h		; origen  = los 768 bytes comprimidos
	ld bc,00300h		; una celda por byte
celda:
	push bc			; el contador de celdas
	ld a,(de)		; el color de esta celda
	ld bc,00008h		; que hay que repetir en sus ocho lineas
	push de
	push hl
	call rellena
	pop hl
	pop de
	inc de			; siguiente byte de color
	ld bc,00008h
	add hl,bc		; siguientes ocho bytes de la tabla de color
	pop bc
	dec bc
	ld a,b
	or c
	jr nz,celda

	ei
	call ENASCR		; y la pantalla aparece entera, de golpe
	ret			; de vuelta al BASIC, que sigue en la linea 40

;; Copia BC bytes de la RAM (HL) a la VRAM (DE).
ram2vram:
	ex de,hl		; el VDP quiere la direccion de VRAM en HL
	call setwrt
bucle1:
	ld a,(de)
	out (098h),a
	inc de
	dec bc
	ld a,c
	or b
	jr nz,bucle1
	ret

;; Deja el VDP apuntando a HL en modo escritura. Los dos bytes de la direccion
;; salen por el puerto 0x99, primero el bajo. El bit 6 a uno es lo que pide
;; escritura; como el bit 7 sale a cero, esto NUNCA escribe un registro del VDP.
;; Los dos NOP sueltos son el respiro que el chip necesita entre accesos.
setwrt:
	ld a,l
	nop
	out (099h),a
	ld a,h
	and 03fh		; la VRAM se direcciona con 14 bits
	or 040h			; bit 6 = escritura
	out (099h),a
	nop
	ret

;; Escribe BC veces el byte A en la VRAM a partir de HL. El PUSH AF / POP AF de
;; dentro del bucle no es un descuido: es la forma de conservar A, que es
;; justamente el valor que se esta escribiendo una y otra vez.
rellena:
	push af
	call setwrt
bucle2:
	pop af
	out (098h),a
	push af
	dec bc
	ld a,c
	or b
	jr nz,bucle2
	pop af
	ret

;; ---------------------------------------------------------------- cola
;; Cinco ceros hasta el final que declara la cabecera BIN. Nadie los usa.
	defb 000h,000h,000h,000h,000h	; b7f7
