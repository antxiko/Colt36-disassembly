# Findings

Colt 36 isn't written in machine code: the whole game is a 63-line MSX-BASIC program, tokenised and recorded on tape as if it were a binary. Of the 18,352 bytes in the data block, only 309 are processor instructions. That has one advantage for anyone taking it apart: you can point at the bugs, line by line. What follows is what turned up when we did, each item with the evidence behind it.

## The score is displayed multiplied by a hundred

The bottom eight rows of the screen — the status bar — come pre-drawn on the tape and don't move during play. On row 22, columns 1 to 6, they carry **six** zeros. The subroutine that refreshes the score, line 10, writes only **four** digits:

    10 Q=PT%/1000:VPOKE6849,Q+156: ... :VPOKE6852,Q+156:RETURN

`VPOKE` writes a byte straight into video memory, and each byte in that area is the pattern number of one cell. Address 6849 is row 22, column 1, and the four writes reach as far as column 4. Columns 5 and 6 keep their factory zero forever. Shooting a bandit is worth twenty points (`PT%=PT%+20`, line 350) and the screen reads 2000.

![The level 1 status bar, with the six zeros of the score](imagenes/nivel1.png)

## Ammunition isn't restocked when you lose a life

Line 599 is `M%=40:TI%=0`: forty bullets and the bandit counter at zero. The game loop starts at 600. When you lose a life, line 749 does `VPOKE 6727,V%+156:GOSUB30:GOTO600`. It goes back to 600, not to 599. The forty shots are per level, not per life.

And this isn't cosmetic, it changes how the game actually plays. The firing routine, line 300, opens with `IF M%=0THENRETURN`: with no bullets, pressing the button does absolutely nothing, not even a sound. Meanwhile the bandit keeps counting, and at step 232 of his phase counter he fires and takes a life off you. If you run out of ammunition with lives to spare, you watch them go one by one and there's nothing you can do.

## Line 730 is unreachable

    730 PLAY"ACA":GOTO 610

Three checks. The only dispatch that could call it, line 640, doesn't list it: `ON (PS%-200)\8 GOTO 690,700,700,740,700,720,760`. There is no `GOTO`, `GOSUB` or `THEN` anywhere in the 63 lines that points at 730. And the preceding line ends in a `GOTO`, so you can't fall into it in sequence either. It's the leftover of an earlier version that stayed in.

## Five smaller oddities

- **A typo on line 630**: `TR%=T`, for `TR%=T%`. It does no harm, because 635 reassigns `TR%` immediately afterwards and because MSX-BASIC returns zero when reading a variable that has not been used before. But that wasn't the intention.
- **When the game ends, the character set is copied over the board as if it were scenery.** Line 2000 sets `N%=15` and calls the level-setup routine; there, line 33 does `N%=N%+10*(N%>10)` and, since a true comparison is −1 in MSX-BASIC, `N%` ends up as 5. The address comes out of `&HA000+2048*(N%-1)`, i.e. 0xC000, which isn't the fifth level but the pattern table: 2048 bytes of typeface dumped onto the board. Nobody notices because it returns to the title screen and the board is reloaded before play.
- Line 310 uses sprite pattern number 8, and only eight patterns are loaded, 0 to 7. You can't see it because the sprite goes to y=200, off the screen.
- The left-hand limit on the crosshair is `X%>0` and the step is 8 pixels starting from 132, so the run goes 132, 124… 12, 4, and from 4 the condition still holds: `X%` ends up at −4: the crosshair goes half a cell past the edge.
- **The fourth level tile on the status bar is never cleared.** Line 2010, which does `D%=6835+2*N%:VPOKED%,0`, only ever runs with `N%` at 2, 3 and 4; at 5 the previous line has already jumped to the title screen.

## A line numbered 65535

On tape, the first line of the program carries the number **65535**, above the maximum MSX-BASIC allows. The 45 bytes of machine code that come with the program write the number **4** over it just before starting the interpreter. Without that patch the program won't run: verified in the emulator by jumping straight to 0x9093, where the `GOSUB 20` on line 520 aborts with *Undefined line number in 520*.

And what that line contains finishes the thought: `POKE &HFBB1,1`. Address 0xFBB1 is BASROM, the location the system uses to decide whether CTRL+STOP can interrupt. Set to 1, the game can't be stopped, and therefore can't be listed either.

## A variable that isn't the game's

Between the end of the program and the startup code there are 297 bytes the interpreter overwrites within the first few milliseconds: not one line of the program references a single address in that range. Even so, they tell you how the tape was made.

At 0x8F60 there are eleven bytes in the exact format of an entry in the interpreter's variable table: `08` (double precision), the letter `I` with its padding, and eight BCD bytes worth **37025**. Reproduced byte for byte in the emulator. And they are not merely *shaped* like a variable table entry: the startup code does `ld hl,08f60h / ld (0f6c2h),hl`, which sets VARTAB — the interpreter's own pointer to the start of the variable table — to precisely that address. Colt 36 can't have created it: it uses `I%`, integer, and never a double `I`. It's what happened to be in the memory of whoever recorded the tape.

After it come 285 bytes of uninitialised RAM that follow the rule "0xFF if bit 0 of the address matches bit 7, and 0x00 if not" — the power-on contents openMSX documents for several machines — in 282 of the 285. Since the rule depends on the **absolute** address, it works as a fingerprint: it fits 282 of the 285 (98.9%) if the block sat at 0x8000, and only 226 (79.3%) if it had been at 0x83E8, which is where the tape loads it. On the programmer's machine the game already lived at 0x8000; 0x83E8 is a detour to avoid trampling the loader while it loads, and the first thing the startup code does is copy it to its proper place.

## The BSAVE was made with the game sitting on the title screen

Both copy routines read their parameters from a fixed six-byte block at 0xD9E1: how much, where to and where from. On the tape they are recorded as `00 03 / 00 18 / 00 D0`, i.e. 768 bytes, destination 6144, source 0xD000. Those are exactly the values on line 572, `BC=768:DE=6144:HL=&HD000`, the one that paints the title-screen board.

There's a second fingerprint pointing the same way: the 2048 bytes of the work area (0xDA00–0xE1FF) carry an identical, byte-for-byte copy of the level 1 map — verified by comparing the two ranges — and that area is filled in by the program at the start of every level, so there's no need to record it. The block wasn't assembled cold: it was dumped from an MSX with the game loaded and stopped on the title screen.

![The game's title screen](imagenes/portada.png)

## Forty-eight seconds saved

![The loading screen](imagenes/carga.png)

The screen you see while the game loads is just an illustration: it doesn't touch the sound chip, it doesn't wait and it doesn't check anything. What's interesting is how it stores the colour. In this screen mode the MSX allows a different pair of colours on **each of the eight lines** of an 8×8 cell, which comes to 6144 bytes of attributes. Here only one is stored per cell: 768 bytes, which the routine replicates eight times on the fly. The cost is that gradients have to be handled with checkerboard dithering, and it saves 5376 bytes of tape, which at that speed is about 48 seconds less waiting. The painting takes 0.27 s measured in the emulator, with the screen off: the image appears all at once.

## The credits, read off the binary

- The title screen says **LUIGILOPEZ 87** and **MUSICA:GOMINOLAS** (music: Gominolas).
- The loading screen is signed **CANO**, bottom right.
- The block holding the publisher's logo is byte for byte the same one that appears on other Topo Soft tapes: it wasn't made for this game.

There is a fourth name in there that never reaches the screen. The board is recorded with the text drawn into it as tile numbers, and decoding it (`tile − 60 = ASCII`, which is what the print routine on line 15 does in reverse) row 22 reads:

```
LUIGILOPEZ.hg.PARA..............     h and g are tiles 164 and 163: the large digits 8 and 7
```

**LUIGILOPEZ 87 PARA** — and then the sentence stops. Line 575 writes `  MUSICA:GOMINOLAS` starting at column 14 of that same row, which lands exactly on top of the `PARA`. What you actually see is `LUIGILOPEZ 87   MUSICA:GOMINOLAS`. The credit was rewritten at some point and the leftover of the older one is still sitting there in the board, painted over every single time the title screen comes up.
