# Options screen (title menu: OPTIONS)

`src/options/options.asm`, assembled by `build.py` after the other hacks. Code is in the free space at the end of bank 82 (`82:F974..`, 0xFF in the clean ROM) and `83:FC40`.

## Screen
Same font and background as the password screen, so it matches the title and password screens. Items (rows 7/10/13/16, text column 5): PASSWORD, TOP SCORES, `R REVERSE` / `R STRAFE` / `R ORIGINAL`, EXIT. The selected item is palette 2 (green) and a left arrow (`:` glyph) sits at column 27, so the cursor does not rely on color alone.

| Input | Effect |
|---|---|
| Up / Down / Select | move the cursor (Select = down, like the title) |
| A B X Y | activate the item; on the R row they cycle reverse, strafe, original |
| Left / Right on the R row | change the setting |
| Start (on release) | back to the title; not when Start was pressed together with a face button |
| hold A+B+X+Y+Start for about 2 s on TOP SCORES | erase the scores (`JSL $82BB0D`, the boot-time default table); hint line counts 3, 2, 1, then `SCORES ERASED` |

TOP SCORES shows the attract-mode screen (`82:BA4F` set-up) and waits for any of A B X Y Start, then returns to Options. PASSWORD calls `JSL $82AFF3` (the title's own call); a bad or empty code returns to Options, a good one returns `$1E7C >= 2` and the title starts the game. EXIT and Start set `$1E7C = 1`, which makes the title redisplay itself.

## Hooks
- `80:9792` `JSL $82AFF3` -> `JSL OptionsEntry` (X, the password argument, is passed through).
- `9F:FFC0` (called from the five Reverse Fire / Strafe sites) -> `JML RMode`. One routine now implements all three modes; `$1EB4 <> 0` (attract demo) always uses original controls.
- `80:D28E` / `80:D295` radar checks -> `RadarCur` / `RadarPrev` (`83:FC40`): Select normally, L/R when `$1EB4 <> 0` or R mode = original. This replaces the old `demo_controls.asm`.

## WRAM (bank 7F, not used by the game or the map)
`7F:FE00` mode word `$5A00 + mode` (anything else reads as 0 = reverse, so power-on garbage is safe), `FE02` cursor, `FE04` previous pad, `FE06` erase hold frames, `FE08` combo flag, `FE0A` hint state, `FE0C` pad, `FE0E` new presses.

## Saving (`sram.asm`, included by `options.asm`)
- Header: `$7FD6 = 2` (ROM + battery RAM), `$7FD8 = 3` (8 KB). SRAM is `$70:0000`.
- `$0000` and `$0100`: two copies of one `$C8`-byte record (`'ZAMN'`, version 1, checksum, R mode word, the two score tables). Copy 1 is written, then copy 2, so a power cut mid-save leaves a good copy. Load takes the first valid one; if neither is valid the game keeps its default table. `$0200` onward is reserved for saved progress (a second record type).
- `SaveIfChanged` builds the record in WRAM (`7F:EE40`), compares its checksum with the last loaded / saved one and writes only when it differs. It is called when the score screen is about to be shown (`82:BA16`, attract mode and game over), every time the title is (re)drawn (`80:915A`), and from Options after erasing scores or changing the R mode.
- Load: the boot-time `JSL $82BB0D` at `80:85FC` became `ScoresInit`, which runs it (defaults) and then overwrites the table and R mode from SRAM.
- The original game stores 0 at `$70:0000` every time an attract demo starts (`80:9B78`, left over from a demo-recording buffer that nothing reads). That would wipe the first word of copy 1, so the store is NOPed.
- Bank `BF` (previously empty) holds the save code.

## Findings
- Leaving a screen that overwrote the title's sprite VRAM: the password screen takes a sprite handle at set-up (`JSL $80BDF2`, `$80C05A`, `$80C049`, `STX $68`) and releases it on exit (`LDA $68 / JSL $8083D5`). Without that pair the title's START / OPTIONS sprites come back pointing at tile slots that were never reloaded and are invisible. The Options screen does both (`Setup` / `OptOut`); the Top Scores wrapper does not, since the attract screen does not take a handle.
- Front-end text objects: `dw col|row<<8, palette; ASCII; 0` (`$FF` = another object follows). `/` = space. Palette 1 = orange text, 2 = green. Drawn by `JSL $82B8FB` (A = bank, X = object, Y = position offset) into the tilemap buffer at `7E:6502`; `JSL $82AD44` clears it.
- Font glyph map: A-Z, 0-9, `?` = `!`, `:` = left arrow, `;` = END, `<` = MR., `=` = Ms., `@` = small dot, `[ ] _ \ ^` and lowercase a-c, d, e = frame/diagonal pieces. There is no `+ - : . ,` glyph (to draw later).
- Glyphs are about 16 px per character, so about 15 characters fit on a line.
- The live high-score table is in WRAM at `7E:2064..20F8` (10 entries) and `7E:20FA..2121`, initialized once at boot by `82:BB0D` from ROM `82:BB2E` / `82:BBC4`. This is what the SRAM save will store.
- Password-screen set-up is `82:B4B7`; its background task is created in `82:B1A7` and killed by `82:B229`, so every screen that calls `B1A7` must call `B229` when it leaves.
- Password result: `$1E7C` = 1 bad code, >= 5 good code.

## Tests
The scenario scripts are in `tests/` (see `tests/README.md`): `saves.py`, `joinprompt.py`, `backout.py` and `smoke.py` cover the screens and features described here.


## Update: six rows, one-call drawing, resume (see SAVE_NOTES.md)
- Rows (3 tiles apart from row 5): RESUME GAME, PASSWORD, TOP SCORES, ERASE DATA, R mode, EXIT. Hints on rows 23 and 25. RESUME GAME opens the RESUME screen described in SAVE_NOTES.md (reuses `Draw*`/`Add`/`AddNum`, FadeIn/OptOut). ERASE DATA takes the hold-A+B+X+Y+Start combo and also wipes the saved game.
- The text engine uploads the tilemap after every object it draws, so drawing the objects one by one made the screen fill up (a flash on every cursor move). `Draw` now collects all objects into one list in WRAM (`7F:FF10`, objects chain with `$FF`) and makes a single `$82:B8FB` call with bank `$7F`.
- Cursor moves, selecting and R-mode changes are silent; only the erase confirmation plays a sound.
- Most of the code moved to bank BF (`$BF9000`); bank 82 keeps `J_B229`, `J_B1A7`, `J_BA4F` (RTS-terminated routines called through JSL stubs) and `ScoreHook`.
- `MVN` in asar is `mvn dest,src` (first operand is the destination bank).
- WRAM `7F:FD00-FEFF` is wiped by the map's fog code on every level change; persistent variables are at `7F:FF08-FF0F`.

## Character select: back out to the title (A+B+X+Y)
Hold A, B, X and Y together (either pad) on the character select screen, before anyone has pressed Start, and the game fades out and returns to the title. Release the buttons first (the hook waits for it, or the title would read a held A as START). The routine is `charback.asm` (hook at 80:99BA, the select loop's per-frame yield): it leaves like a game start does (fade, stop the select tasks), resets state like a finished attract demo (80:866F, 88A9, 895A, 8992, 85CF), clears $7C so the title's one-time set-up (logo fly-in) runs again, and returns to 80:9126. The 900-frame select timeout still starts the attract demo. Tested: pad 1, pad 2, repeated back-outs, normal START afterwards.
