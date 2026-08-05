# Dead bytes

A disassembly isn't finished when the code makes sense: it's finished when every byte on the tape has an owner. In Colt 36 the accounting closes at 100% —34,239 bytes of content, 34,239 explained— but part of that content is never read by anything. Counting only the pieces listed here gives **3263 dead bytes**; add the 2048 of the work area and the odd scrap of padding and it comes to **5456 bytes out of 34,239, almost 16% of the tape**.

## The 297 bytes of the variable area

The game is a tokenised MSX-BASIC program (saved already chopped into internal codes, not as text), and the block that carries it reserves 297 bytes behind the listing, at 0x8F5F–0x9087: the **variable area**, the table where the interpreter notes down the variables the program creates as it runs. Saving it to tape achieves nothing, and that can be shown here three independent ways.

The first: the program never mentions a single address in that range. The second: what was saved is destroyed the moment the game creates its first variable. The third says the most. The content is 1 dead byte, **11 bytes of a leftover variable** —a double-precision `I` holding 37025, in the exact format of the interpreter's table, reproduced byte for byte in the emulator— and **285 bytes of uninitialised RAM**. Those 285 follow the rule "0xFF if bit 0 of the address matches its bit 7, 0x00 if it doesn't", which is the documented power-on content for several machines: **282 of the 285** obey it.

And since the rule depends on the *absolute* address, the pattern works as a fingerprint. It fits 282 of the 285 (98.9%) if the block sat at 0x8000, and only 226 (79.3%) had it sat at 0x83E8, which is where the tape loads it. In other words: on the programmer's machine the game already lived at 0x8000, and 0x83E8 is a detour to keep clear of the loader. Rubbish that tells you where the game was made.

## The 88 in the loading screen

![The screen you look at while the game loads](imagenes/carga.png)

The block holding the loading illustration divides into 6144 bytes of pattern + 768 of colour + **88 bytes nobody reads** + 95 of code + 5 zeros. The 88 obey the same freshly-powered-RAM rule, 88 out of 88: the `BSAVE` that recorded the block took a range slightly wider than the data. Confirmed in the emulator too, with a watchpoint on those addresses: zero reads while the picture is drawn.

## The scenery at 0xD400 that nothing points to

At 0xD400–0xD5FF there are 512 bytes in board format: tile numbers, 32 per row. The first twelve rows draw a coherent scene —two platforms with bottles and a long stockade— out of only eight distinct patterns and **eight tiles of the sort that break when shot** (patterns 72 and 73). The last four rows, 128 bytes, are zeros.

Nobody reads it. Nowhere in the listing is there a single constant between 0xD400 and 0xD5FF, and the neighbouring copies stop just short: the title screen is 768 bytes from 0xD000 (ending at 0xD300), the scoreboard 256 from 0xD300 (ending **exactly** at 0xD400), and the next thing anything touches is already at 0xD600. A discarded piece of scenery left inside the file.

![The discarded scenery at 0xD400, drawn with the game's own graphics. It was never once on screen](imagenes/decorado-inedito.png)

This picture has never existed on a screen. It is drawn from those 512 bytes
using the game's own tile table, which is what makes it more than a curiosity:
if the block's layout were wrong, what came out would be noise. Instead you get
an assembled scene, bottles standing on their shelves and the stockade lined up.
Somebody drew it and then decided not to use it.


## The forgotten offcut at 0xD9A0

The bandits' hiding places live at 0xD900: ten per level, four bytes each, forty bytes per level, 160 in all. The program indexes them with `K%=INT(RND(-TIME)*10)*4+&HD900+40*(N%-1)`, so the highest address it ever reads is 0xD99F.

The next 64 bytes, 0xD9A0–0xD9DF, are a **literal copy of the shapes and colours of tiles 170 to 173**: checked byte for byte against the pattern table at 0xC000 and the colour table at 0xC800. It's the 2×2 block immediately before the first bandit model, which starts at tile 174. An offcut of the big tables, pasted there and forgotten.

## The padding row at 0xD620

At 0xD600 there are 512 bytes, every one of them pattern 255, the empty tile. Line 30 uses them to clear the play area before announcing the level: `HL=&HD600 : BC=32 : FOR DE=6144 TO 6656 STEP 32`. It copies **32 bytes**, always the same ones, to seventeen consecutive rows of the screen; the source never moves. The **480 bytes from 0xD620 to 0xD7FF** are more of the same, and nobody reads them.

## The 256 zeros at 0xE200

The level's work area occupies 0xDA00–0xE1FF, and behind it come 256 zero bytes, until the first machine-code routine starts at 0xE300. They're padding, so that the routine lands on a round address. That they're never seen follows from the scroll limit in line 610: for levels 3 and 4 the limit is 0xE000 and the 512-byte window ends at 0xE1FF, the last byte of the work area. Not one byte further.

## What hasn't been identified

Here it's a matter of saying exactly what is known and what isn't.

**The leftovers of maps 1 and 2 (1536 bytes).** Each piece of scenery is a 32×64 board, 2048 bytes, and the whole thing is copied to the work area. But that same line 610 puts the limit at 0xDC00 for level 1 and at 0xDE00 for level 2, so the last visible window ends at 0xDDFF and at 0xDFFF: **32 rows and 48 rows**. What falls outside is, to the byte, **0xA400–0xA7FF (1024 B)** and **0xAE00–0xAFFF (512 B)**. That much is proven: the game never shows those bytes.

![The complete scenery of level 1, EL ALMACÉN (the warehouse)](imagenes/mapa1.png)

What they are, no. They've been ruled out as map, as colour, as music and as a copy of any other part of the tape. Ruled out as **PCM** (digitised sound, one sample per byte): the correlation between neighbouring bytes comes out at **−0.27**, and a genuinely sampled signal gives **+0.99**. Ruled out as a **table of note periods**: read as 16-bit words, the deviation from equal temperament is **0.244 semitones**, which is what chance gives, while the game's real period table gives **0.090**.

Two of the exclusions deserve a measurement of their own, because they close off whole families of hypotheses at once.

**They are not code, from any machine.** There is no need to go CPU by CPU: it is enough to count how many distinct byte values they use. The 1566 use **60**. Three hundred bytes of Z80 code from this same tape use **67**, and a program needs far more as it grows, because it has to name registers, jumps and constants. The consequence is that instructions no program can do without are missing: in the 1566 bytes there are **zero `CALL` (0xCD), zero `RET` (0xC9), zero 0xED prefixes, zero `JR`, zero `DJNZ` and zero `LD BC,nn`**. Not one. And since this is a count over the set of bytes, it holds for any alignment and any eight-bit processor: if the opcode isn't in the block, it isn't in any reading of the block.

**They are not a picture, at any width.** Here the measurement is mean run length: how many consecutive pixels of the same colour there are, reading the bits in a row. A picture, however jagged, has runs **longer** than chance, because drawn things are continuous. The tape's own bytes confirm it: the game's patterns give **3.91** and the level 1 map gives **3.82**, against the exact **2.00** of chance. The suspects give **1.63**: they alternate *more* than random bytes do. And since a horizontal run doesn't depend on the line width, this rules out every possible width at once.

**The 30-byte tail (0xE323–0xE340).** They sit after the last `RET`, up to the end declared by the header:

    16 E9 16 69 16 E9 16 E9 16 49 16 49 04 40 00 40
    00 41 00 41 04 41 00 41 00 41 00 69 00 41

Fifteen pairs. The first byte is always 0x16, 0x04 or 0x00; the second takes only five values. They're not reachable code, nor patterns, nor colour, nor map, nor music, and the sequence appears nowhere else on the tape, not even searching for just the first six bytes.

### What is known: they are not rubbish

Ruling things out isn't the only result. These bytes have a structure that can be measured, and a fairly striking one. On the 1536 from the scenery:

- **Even and odd positions share no values.** There are 55 distinct values: 34 appear only at an even position, 22 only at an odd one, and the only one appearing in both is 0xFF. The consequence is measurable: any two bytes an odd distance apart match **0.0 %** of the time — not once — while at distance 2 they match 49 %.
- **Bit 1 is set in all 768 bytes at even positions.** All 768. Without one exception.
- **Even bytes carry the odd-numbered bits (7, 3, 1) and odd bytes the even-numbered ones (6, 4, 2).** Seen as an image that gives a checkerboard, and that is where the first hypothesis went; the explanation turned out to be another one, and it is below.
- **They are six blocks of 256 bytes that are variations on one block.** This is the strongest measurement of the lot. Compared bit by bit, any two blocks differ by **191 bits out of 2048, 9.3 %**. The same measurement on the scenery next door — the part that does get shown — gives **1098 bits, 53.6 %**, which is what chance gives. Searching for the period that leaves the fewest differences, from 1 to 256, the winner is **256** at 9.2 % differing bits; every odd period goes to 74 %, worse than chance. And 256 bytes is exactly one row of 32 screen characters.

And the 30-byte tail, which had been treated as a separate matter, turns out to carry **the same signature**: strict alternation, even- and odd-position alphabets without a single value in common, complementary fixed bits in each parity. At 30 bytes that could be coincidence and it should be said; at 1536, it couldn't.

### The best lead: the address dictates the contents

This is as far as it has got, and it is the lead to follow. What decides which byte sits where does not appear to be a content at all, but **the memory address it sits at**. Three independent measurements point the same way:

- **Each bit has its own polarity, and it is tied to the parity of the address.** Taking the rule "even address → the bit is 1, odd address → it is 0", bit 1 obeys it in **99.2 %** of the bytes, bit 3 in 96.3 %, bit 7 in 92.0 % and bit 0 in 88.0 %. And bits 2 and 6 obey **the opposite**, at 20.1 % and 18.8 %. It is an effect of *bit position*, not of byte value, and that is what stops it fitting any format: a map, a picture, a text or a sound sample all treat the byte as one unit. Eight one-bit memory chips, one per data line, do not.
- **The eight 0xFF at odd addresses all land at the same point in the cycle.** In the 1024 bytes there are exactly eight 0xFF bytes at an odd address, and they are 0xA47F, 0xA4FF, 0xA57F, 0xA5FF, 0xA67F, 0xA6FF, 0xA77F and 0xA7FF: the eight addresses whose seven low bits are all ones. All eight, without a miss.
- **The whole block is a two-byte constant with bits knocked out.** The 16-bit word that best fits it is **9B 54**, and the block's 512 words sit an average of **2.46 bits away** from it, out of sixteen. Chance would give 8.

And from that comes, at last, the explanation of why 0xA600–0xA7FF and 0xAE00–0xAFFF are identical byte for byte: they are 0x800 apart, which is a multiple of 128, so **they have the same low address bits**. Nobody needed to copy anything.

### And yet it is not this tape's known rubbish

This is where to put the brakes on. The natural conclusion would be "it's uninitialised RAM, like the other leftovers", and this tape lets you check that, because it already has two regions identified as exactly this: the 88 bytes in the loading screen and the 285 in the variable area. Both obey the rule "0xFF if bit 0 of the address matches bit 7, 0x00 if it doesn't". Counting bits, the fit is this:

    the 88 bytes in the loading screen      100.0 %
    the 285 in the variable area             99.3 %
    ---------------------------------------------
    THE SUSPECTS at 0xA400                   47.7 %
    the ones at 0xAE00                       46.4 %
    ---------------------------------------------
    the level 1 map, a genuine piece of data 50.3 %
    the pattern table                        50.4 %

The suspects fit **exactly as well as any old data**, which is to say not at all. If they were the same uninitialised memory from the same machine, they would have to resemble the other two, and they don't. So what there is, is this and no more: bytes whose contents depend on the address — which no data format does — but which are not the power-on pattern that has been identified elsewhere on this tape. They may be uninitialised memory of another kind, from another chip or another moment. They may be something else. What is measured is what is measured.

### WANTED

This is the one part of the work still open, so it gets published as what it is: a poster.

```
    *-------------------------------------------------------------*
    |                                                             |
    |                     W A N T E D                             |
    |                  DEAD  OR  ALIVE                            |
    |                                                             |
    |                  1 5 6 6   B Y T E S                        |
    |                                                             |
    |   Last seen on a Topo Soft cassette, 1987, at addresses     |
    |   0xA400, 0xAE00 and 0xE323. Forty years sitting there      |
    |   without anyone knowing what they do for a living.         |
    |                                                             |
    |   DISTINGUISHING MARKS                                      |
    |     - only 60 distinct byte values in 1566                  |
    |     - bit 1 set in all 768 bytes at even positions          |
    |     - each bit's polarity tied to the address parity:       |
    |       bit 1 obeys at 99.2%, bit 6 at 18.8%                  |
    |     - the only 8 0xFF at odd addresses all land where       |
    |       the 7 low address bits are all ones                   |
    |     - six blocks of 256 bytes differing in only 9% of       |
    |       their bits (the scenery next door: 54%)               |
    |                                                             |
    |   NOT  code of any CPU (60 byte values, zero CALL and       |
    |        zero RET in 1566) - a picture at any width (run      |
    |        1.63, below chance at 2.00) - map - colour -         |
    |        music - digitised sound - note table - a copy of     |
    |        another part of the tape - the power-on RAM this     |
    |        tape does carry (47.7% fit; the other regions        |
    |        99-100%)                                             |
    |                                                             |
    |   WANTED ALIVE: someone to say what they are.               |
    |   ACCEPTED DEAD: a "not X, and here is the measurement      |
    |   that rules it out" counts too, and gets published.        |
    |                                                             |
    |   REWARD  your name in this repository, next to the         |
    |           bytes you identified                              |
    |                                                             |
    *-------------------------------------------------------------*
```

Playing with them doesn't mean repeating the teardown. With your own copy of the tape:

```sh
make extract
python3 tools/extrae_misterio.py work work
```

That leaves `work/misterio.bin` (all 1566), `work/misterio_mapas.bin` (the 1536 from the scenery) and `work/misterio_cola.bin` (the 30), and prints every measurement above so they can be checked before anything is taken as read.

If you think you know what they are, [open an issue](https://github.com/antxiko/Colt36-disassembly/issues/new/choose). What's needed isn't the idea — there have been plenty, and several were good — but the measurement behind it: what you would have to see if the hypothesis were true, and what comes out when you look.

## Why this gets written down

Because the byte budget only closes if every byte has an owner, and "I don't know" is an owner with a name to it. A gap you keep quiet about fills itself, and what fills it is usually a plausible explanation nobody has measured. Writing "rubbish" and moving on is comfortable; writing down *what* was measured, what figure it gave and what it was compared against lets someone else repeat the test and prove the conclusion wrong.

And because dead bytes are the best physical evidence a tape leaves behind. The uninitialised-RAM pattern says the game was written at 0x8000. The six parameter bytes at 0xD9E1 come recorded with 768, 6144 and 0xD000, which are exactly the values in line 572, the one that draws the title screen. The work area carries an exact copy of the level 1 map. Nobody saved that on purpose: the tape was cut from a live session, sitting on the title screen, with the residue of the last game still in memory. You don't learn that by reading the code. You learn it by reading what's left over.
