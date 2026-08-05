# The tape

`colt36.tsx` is 34,722 bytes and its sha256 is `4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13`. Inside are five blocks recorded with the standard MSX tape encoding: no turbo loader, no home-made tape-reading routine, nothing faster than what the machine came with from the factory. It really is slow: from the moment the tape starts playing to the moment the logo animation starts running, 69.7 seconds go by, measured in the emulator.

| block | type | load | end | start | size |
|---|---|---|---|---|---|
| `COLT36` | ASCII | — | — | — | 256 B |
| `topo` | BIN | 0x9470 | 0xA50D | 0x9470 | 4254 B |
| `scr` | BIN | 0x9C40 | 0xB7FB | 0xB798 | 7100 B |
| `CM2` | BIN | 0x9B91 | 0xE340 | 0x9BBA | 18,352 B |
| `CM1` | BIN | 0x83E8 | 0x949C | 0x948F | 4277 B |

That is 34,239 bytes of content. The `CM1` block also drags a padding byte of `0xFF` along behind the data, and with it the tape ends.

## What a BIN on tape is

Each block is preceded by a sixteen-byte header: ten identical bytes saying what type it is, and six with the name. In `COLT36` those ten bytes are `0xEA`, which means "text"; in the other four they are `0xD0`, which means "binary".

A BIN on tape carries nothing resembling a relocation table or a symbol list. The only extra it brings is three two-byte addresses at the start of the data block: **load**, **end** and **start**. `BLOAD"cas:"` dumps the bytes between the load address and the end address, exactly as they are, untouched; add `,R` and it jumps to the start address when it finishes. That is all. The block has to know where it is going to land, and if the machine has that memory occupied, so much the worse for the machine.

The ASCII block works differently: it is a BASIC program saved as plain text, and it is loaded with `RUN"cas:"`, which reads it and runs it. It takes up exactly 256 bytes because text files on tape are written in records of that size, padded with `0x1A` until they are full.

## The loader

The 256 bytes of the first block are 117 of text, one `0x1A` end-of-file byte and 138 more of padding. The text is this:

    10 COLOR 1,1,1:SCREEN 2
    20 BLOAD"cas:",R
    30 BLOAD"cas:",R
    40 CLEAR200,39824!
    50 BLOAD"cas:",R
    60 BLOAD"cas:",R

Line 10 sets ink, background and border to the same colour — 1 is black — and switches to the 256×192 graphics mode. The screen goes dark. Line 20 brings in `topo`, the company logo, which runs at its own load address, does its animation and hands control back to BASIC. Line 30 brings in `scr`, the loading screen, whose start address at 0xB798 paints it in 0.27 seconds: it appears all at once, you never see it being drawn.

![The Colt 36 loading screen, signed CANO](imagenes/carga.png)

Line 50 brings in `CM2`, the 18,352 bytes of artwork, scenery and music, and line 60 the game itself.

That leaves line 40, which is the interesting one. `CLEAR200,39824` reserves 200 bytes for strings and lowers the interpreter's memory ceiling to 39824, that is 0x9B90, exactly one byte below where `CM2` is going to land. And it cannot go just anywhere. It has to come **after** line 20, because once the `CLEAR` has been done the interpreter's stack and file buffer move to 0x98A0..0x9B90, which is inside the range of `topo` (0x9470..0xA50D): the `BLOAD` on line 20 would be writing over its own stack and over the buffer it reads the tape with. And it has to come **before** line 60, so that when the game starts the ceiling is already in place and neither the stack nor the strings ever reach the data.

### The proof that it was saved with `SAVE",A"`

In `39824!` there is an exclamation mark nobody typed. In MSX-BASIC an integer only goes up to 32767; 39824 does not fit, so the interpreter stores it as a single-precision number, and when a `LIST` writes it back out it adds the `!` suffix that marks that type. In other words: the text on the tape is literally the output of a `LIST`, and the loader was saved with `SAVE"cas:",A` from the interpreter itself — it was not typed by hand in an editor.

## What overwrites what

The four binary blocks occupy overlapping ranges, because they arrive and evict each other in turn:

- `scr` overwrites 2254 bytes of `topo`.
- `CM2` overwrites the whole of `scr` and another 2429 bytes of `topo`.
- `CM1`, landing at 0x83E8..0x949C, takes out another 45 bytes of `topo`.

Of the logo's 4254 bytes, 1780 are left untouched, those from 0x949D to 0x9B90. And 0x9B90 is exactly the ceiling the `CLEAR` set: what survives of the logo falls precisely in the area the interpreter uses as its stack and string space. The corpse lasts longer than you would think, because the game spends little stack: measured 80 seconds into a game, 1629 of those bytes were still intact, and 893 of them consecutive, from 0x949D to 0x9819.

## An `,R` that starts nothing

All four `BLOAD`s carry `,R`, but the one for `CM2` sets nothing running. Its start address, 0x9BBA, holds a single byte `0xC9`, which is the Z80's `RET` instruction: the jump goes in and comes straight back out. That byte is the end of the routine beginning at 0x9B91, the one that initialises the music player.

And it had to be that way on purpose. `BSAVE` lets you leave out the start address, but in that case it takes the load address, which here is 0x9B91: the `,R` would have fired up the music player with the game not yet loaded. Pointing the start address at a `RET` is how a block of pure data gets along with a loader that always uses `,R`.

## The `CM1` relocator

The last block loads at 0x83E8 and its start address is 0x948F. There sit five instructions:

    LD HL,0x83E8
    LD DE,0x8000
    LD BC,0x10B5
    LDIR
    JP 0x9088

`LDIR` copies BC bytes from HL to DE: here, all 4277 of the whole block, a thousand bytes further down. Since the destination is below the source, copying forwards never bites its own tail. The routine copies itself too, and when it is done it jumps to 0x9088, which is by then already in place.

The reason for the whole detour is that the game is an MSX-BASIC program, and on the MSX, BASIC programs live from 0x8001 onwards, which is exactly where `CM1` has to end up. But while the tape is loading, the program in charge is the loader, which is also BASIC and is also at 0x8001, running the `BLOAD` on line 60. Loading the game straight into its place would mean writing over the program that is reading the tape. So the block lands a thousand bytes higher up, on free ground, and only comes down to its home once the loader is no longer needed.

From there on there is no tape left: the 20 bytes at 0x9088 set VARTAB — the pointer where the interpreter builds its variable table — to 0x8F60 and jump to the routine that runs programs. Before that they write five bytes over 0x8000, and that is no small detail: on tape the game's first line is numbered 65535, above the maximum MSX-BASIC accepts, and those five bytes renumber it as line 4. Anyone who extracts the `CM1` block and loads it on their own does not get the game: they get a program that breaks the moment it looks for a line backwards.

![The Colt 36 title screen](imagenes/portada.png)
