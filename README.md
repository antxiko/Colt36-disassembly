# Colt 36 (Topo Soft, 1987, MSX) — a commented disassembly

A 1987 cassette tape, taken apart line by line. All **34,239 bytes** on it are
accounted for — and the game turned out to be written in **BASIC**.

📖 **[Full documentation](https://antxiko.github.io/Colt36-disassembly/)**
· [En castellano](https://antxiko.github.io/Colt36-disassembly/es/)
· [README en castellano](README.es.md)

---

## What this is

*Colt 36* is a western shooting gallery that Topo Soft published for the MSX in
1987. This repository holds its complete code, commented, along with the tools
to rebuild and verify it.

What makes this game different from what you would expect: it is **not written
in assembly**. The block carrying the game is a **tokenised MSX-BASIC program,
63 lines long**, with just 45 bytes of Z80 at the end to start the interpreter.
There are **997 bytes of machine code** on the whole tape, and the routine that
does the scrolling — the entire graphics engine — is seventeen bytes long.

## How you know this is true

`make` regenerates the listings from the tape binary and requires that the
original comes back out, exactly:

```
topo  4254 B   OK: reproducible byte a byte
scr   7100 B   OK: reproducible byte a byte
CM2  18352 B   OK: reproducible byte a byte
CM1   4277 B   OK: el bloque del juego se rehace byte a byte

TOTAL 34239 bytes, 34239 explicados (100.00%), 0 sin explicar
```

Because the game is in BASIC, the test here is not reassembly but
**re-tokenisation**: the commented listing (`src/colt36.bas`) is turned back into
interpreter bytes, and they must match the tape. That listing accepts comments
of our own (lines starting with `#`), so the file that gets published is exactly
the file that gets checked, and the two cannot drift apart.

There is also a **budget**, which is a different check: every byte must be either
code the tracer genuinely reaches, or a data range with a name and an
explanation. It exists because reproducibility cannot see misinterpretation — if
graphics were marked as code, the bytes would still come out identical and only
the listing would lie.

And **57 tests**, many of them dedicated to checking that what the documentation
says is what the game does.

## WANTED: 1566 bytes, dead or alive

One thing is still open, and it gets published as what it is. Of the 34,239
bytes on the tape there are **1566 nobody has managed to identify**: 1536 in the
leftovers of two pieces of scenery and 30 in a tail after the last `RET`. It is
proven that the game never shows them, and they have been ruled out as Z80 code,
map, patterns, colour, music, digitised sound, note table, or a copy of any
other part of the tape — each with its measurement. Nor are they a picture at
any width: the mean run of identical pixels is 1.63, *below* chance at 2.00,
where the game's own patterns give 3.91.

But they are **not rubbish**. The best lead is that their contents appear to be
dictated by the **memory address**, not by a datum: each bit has its own
polarity tied to the parity of the address (bit 1 obeys it in 99.2 % of the
bytes; bit 6 obeys the opposite in 81.2 %), and the only eight 0xFF at odd
addresses all land where the seven low address bits are ones. No data format
does that. The easy conclusion would be "uninitialised RAM", but this tape
carries two regions identified as exactly that and the suspects **look nothing
like them**: they fit that rule at 47.7 %, where the others give 99.3 % and
100.0 % and any old datum gives 50 %.

And you don't need the tape to look at them: they are **published**, as a hex
dump on the page itself and as a file in [`datos/misterio.bin`](datos/misterio.bin).
With your own copy you can also regenerate them and repeat every measurement in
two commands:

```sh
make extract
make misterio     # extracts them, measures them, refreshes datos/misterio.bin
```

The full poster, with what has been ruled out and how, is on
[the dead-bytes page](https://antxiko.github.io/Colt36-disassembly/DEAD-BYTES.html).
Hypotheses go through [issues](https://github.com/antxiko/Colt36-disassembly/issues/new/choose):
what's needed isn't the idea but the measurement behind it.

## Getting started

```sh
make          # extract, generate the listings and verify everything
make test     # tests only
make web      # rebuild the site in docs/
make misterio # extract the 1566 unidentified bytes and measure them
make ram      # load the tape in openMSX and compare memory (slow)
```

You need `pasmo`, `z80dasm` and Python 3. For `make ram` and the screenshots,
`openmsx`.

**The tape is not distributed** with this repository, only the documentation work
(see [AVISO-LEGAL.md](AVISO-LEGAL.md)). To rebuild everything you need your own
copy, named `colt36.tsx` in the root, with this sha256:

```
4f3090407ff22826a0ce1281908c497396cda972fe10dd0af694330cd62ebe13
```

Without the tape you can still read the listings in `src/` and run the tests that
do not depend on the binary.

## What lives where

| | |
|---|---|
| `src/colt36.bas` | **the game**: 63 lines of BASIC, commented |
| `src/colt36_arranque.asm` | the 45 bytes of Z80 that start the interpreter |
| `src/colt36_cm2.asm` | tiles, level maps, music and the support routines |
| `src/colt36_scr.asm` | the loading screen |
| `src/colt36_topo.asm` | the publisher's animated logo |
| `src/*.notes` | the annotations the listings are generated from |
| `tools/basic_detok.py` | de-tokenises and re-tokenises MSX-BASIC, byte for byte |
| `tools/render_niveles.py` | draws the screens from the binary's own data |
| `tools/omsx_juega.tcl` | loads the tape in openMSX and takes screenshots |
| `datos/misterio.bin` | the 1566 unidentified bytes, for anyone who wants a go |
| `docs/` | the documentation and the website |

Note that the source listings and their comments are written in Spanish, as is
the game itself; the documentation site is available in both languages.

## Credits

The game's own, read from its binary: graphics by **LuigiLopez**, music by
**Gominolas**, and the loading screen signed by **Cano**. *Colt 36* belongs to
Topo Soft and to its authors; this is preservation and study work. See
[AVISO-LEGAL.md](AVISO-LEGAL.md).
