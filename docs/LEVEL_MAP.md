# ZAMN Pause-Screen Level Map: data spike (level 1, US ROM)

## Where the level is in RAM
- **Tile map:** 16-bit SNES tilemap words in bank `7F`, starting at `7F:0000`. Tile number = `word & $03FF` (the game also uses `& $01FF` and `$DC` for a priority check). One word = one 8x8 tile. World pixel position / 8 = tile coordinate.
- **Row addressing:** `JSL $80AD1C` (X = tile column, Y = tile row, returns A = offset in bank 7F): `A = word at 7E:4328 + 2*Y`, plus `2*X`. The row table at `7E:4328` holds the byte offset of each row (level 1: 0, $160, $2C0, ... stride 352). `$B2` = row stride in bytes (352 for level 1, so width = 176 tiles). Rows in the table: at least 104.
- **Level 1 size:** 176 x 104 tiles (1408 x 832 px). `$AE = 44` and `$B0 = 13` look like size values in larger units (176/4, 104/8); to verify on other levels.
- **Tile attribute table:** word per tile number (`& $03FF`, so 1024 words), long pointer in `$BA/$BC` (level 1: `7E:611A`, so copied to RAM at level load). The game reads it as `LDA [$BA],Y` in 77 places.
  - Bit 0 (`$0001`): solid for the player and objects (the 6-point probe at `80:AE43`-`AE92` tests it with `LSR A / BCS`). Verified by overlay on level 1: hedges, brick walls and the fence line up.
  - Bit 1 (`$0002`): second blocking class (water and monster-only blocks; `BIT #$0002` at `80:AEC6`-`AF1F`, `LSR LSR` tests in banks 82 and 83). The pool at the top of level 1 shows up here.
  - Other bits seen: `$0004` (`80:AF59`), `$0008` (`80:B052`), `$0080`, `$0100`, `$1000`, `$2000`, `$4000`, `$8000`. Most common ground attribute on level 1 is `$1080` (walkable).
- **Players:** object pointers `$D2` (P1) and `$D4` (P2); X pixel at `+2`, Y pixel at `+6` (P1 on level 1 start = 350, 585, i.e. tile 43, 73).
- **Scrolling:** a tilemap column buffer at `7E:4B28` (`$40` bytes) is built by the routine at `80:A5E5` (reads `[$50]` in bank 7F, writes `[$54]`), then DMA'd to VRAM by `80:9EB5`. Level tile graphics are streamed from bank `8C` as you scroll, so the level can't be drawn from VRAM; draw the map from tile classes instead.

## Level sizes (all levels)
- Level header pointer table: `9F:8002 + 2*n` (word per level; index 0 and 51 are the title/intro level, 1 = Level 1, up to 55). Each header is in bank 9F. Fields: `+0` / `+2` long pointers (tile map source `9B:8000` for level 1), `+4` long pointer (attribute data `9D:F930`), `+$22` width and `+$24` height in 64-px units (tiles = units x 8), `+$26` priority threshold (`$DC`), `+$2A/+$2C` player start X/Y in pixels.
- `80:ACA2` (called from `80:86C8` at level load) takes X = width units, Y = height units and sets `$AE = 2X`, `$B0 = Y`, `$B2 = 16X` (row stride in bytes), `$B4 = 8Y` (rows), and builds the row table at `7E:4328`.
- So at run time: width in tiles = `$B2 / 2`, rows = `$B4`.
- Range across all levels: smallest 48x192 (level 50), 80x144, 96x144; widest 280x104 (level 35) and 272x104 (47); tallest 72x376 (level 21) and 104x280 (level 18). Max cells 72x376 = 27,072 words, fits the 64 KB tile bank.
- Scale rule for the map: 1 pixel per tile when width <= 256 and rows <= 224, otherwise 1 pixel per 2x2 tiles (a pixel is a wall if any of its tiles is). Worst case 280x376 at half scale = 140x188. Fits every level.

## Pause screen
- The Split+QoL pause patch does not use a menu screen: it dims the frozen play screen and handles weapon/item changes with the buttons. A map would be an overlay drawn over (or instead of) the dimmed screen. Code is in bank `BE` (`BE:8000`).

## Pause loop (Split+QoL pause patch, bank BE)
- `BE:8000` is a self-contained loop entered from the vanilla pause: sets `7F:FA00 = 1` (paused flag), then each iteration handles both players (`JSR $8127` = weapon/item cycling per player), calls `JSL $80C07F` twice (frame wait), reads `$006E | $0070` (pad words) and exits when Start (`$1000`) is pressed again, then clears `7F:FA00` and restores the screen via `JSL $8083AE` (`A=$A084, Y=$0080`).
- Hook point for the map: inside this loop, test Select (`$2000`) on the pad words and call the map routine (draw on first press, redraw/clear on the next, and force-blank around the VRAM writes). New code can go in bank BE free space or the end of bank 9F.

## Map renderer plan
1. On pause + a button (Select suggested), force blank, build a bitmap from the tile map: floor (attr bit0 and bit1 clear) / wall (bit 0) / water (bit 1 only).
2. 1 pixel per tile: level 1 = 176 x 104 px, fits the 256 x 224 screen; the biggest possible map in a 64 KB bank (256 x 128 tiles) also fits at 1 px per tile.
3. Markers for P1, P2 and victims (the radar code already finds victims), blinking.
4. Optional fog of war: set a bit per 8x8 tile as players walk through it.
5. Cost: about 18,000 pixels per build in 65816 code; done once per pause, so a fraction of a second.

## Still to check
- Level dimension variables for other levels (maze levels especially), and whether `$B2` / row table are always valid.
- Free VRAM / which BG to use during pause; how the pause patch freezes the game and what it leaves in VRAM.
- Whether bit 0 / bit 1 are enough to show doors and one-way tiles on the maze levels.

## Debug core additions (see SPIKES.md)
`ZDMA=<file>` logs every DMA (PC, source, dest, size). `ZWATCH=<hex WRAM offset>` logs writes to one byte.

## STATUS: v1 pause-screen map WORKS (emulator-tested)  — see map/map.asm
Press **Select while paused** -> full-level map; D-pad pans (hold); Select or Start closes it (back to the normal pause screen).
Tested on levels 1, 2, 5, 10 (maze), 18 (tall), 21 (tallest), 35 (widest), 40, and in the full stack (Rebalanced+Split/QoL+reverse fire+hitbox+blood) on level 10.

### Design (as built)
- 1 px per tile, 176x112-tile window (22x14 BG3 chars), recentered on P1 at open; pans in 48/32-tile steps (whole-level render ~20 frames).
- Classes from the attribute table ([$BA]): bit 0x100 = water (blue), else bit 0 = wall (white), else floor (black). Players = 3x3 blinking red/yellow block (CGRAM 31 toggled every 16 frames).
- NMI is switched off ($4200=$01, auto-joypad on) and the screen force-blanked while drawing; the map loop polls $4210/$4212/$4218 itself. TM=$04 (BG3 only).
- VRAM: map chars use BG3 chars 188..496 (VRAM $8BC0..$9FFF), which are empty on all levels tested (BG3 font/HUD chars are 1..187). Tilemap reuses the BG3 HUD tilemap ($C800); its 2 KB is backed up to **7F:E400-EBFF** and restored on exit. (Level 18's tile map ends at 7F:E380, the largest of any level; 7F:F200 is a live game variable and 7F:F800-FA00 is the pause palette copy, so avoid those.) Scratch vars at 7F:FC00-FC4F; DP $E0-$FF saved/restored at 7F:FC20.
- CGRAM entries 0 and 28-31 saved/restored. $2109/$210C are not changed.
- Hook: BE:8061 (the two `JSL $80C07F` frame waits in the pause loop) -> `JSL MapCheck` which does the two waits then tests Select. New code BE:8230-BE:886A.

### Lessons
- **VRAM is not free where it looks free**: BG1's tilemap is 64x64 ($D000-$EFFF) and zero blocks there are real map area; sprite chars (0-$3FFF) are loaded dynamically per level. Only BG3 chars 188+ were safe.
- **VRAM read quirk**: after setting VMADD the Snes9x core returns the first word twice (read sequence w0,w0,w1,...). `DetectVram` writes sentinel words and checks the read sequence so the code works whether or not an extra dummy read is needed.
- Attribute meaning: 0x1080/0x80/0x1000 walkable; 0x3/0x7/0x2007 wall; 0x103 water (pool/lake, 10k tiles on level 18); 0x0 tree canopies/overhead; 0x2/0x2002 thin wall-face tiles (not drawn).
- Don't mix `lda.b #` immediates after a routine that ends in 16-bit mode (asar assumed 8-bit, code mis-decoded).

### Files
`map/map.asm` (source, asar, applied on top of splitqol.sfc), `ZAMN_PauseMap.ips` (2 KB, apply after any Split+QoL stack), `ZAMN_Rebalanced_SplitQoL_PauseMap_ALL_IN_ONE.ips` (Rebalanced + Split/QoL + reverse fire + hitbox 150 + blood + map, from the clean US ROM).

### Next ideas
Civilian/victim markers (reuse radar's victim scan), fog of war (explored-bit per 8x8), P2 marker is coded but untested, smoother panning.

## v2: civilian markers + fog of war (emulator-tested, also in the full stack on level 21)
- **Victims:** table of (x,y) pixel pairs at **7E:6DF4** (4 bytes each), count at **7E:6E30**; entry i is gone when `7E:605A+i` has bit 7 set (this is what the radar at 82:D93A tests). Source list is header +0x1E (12-byte records: x, y, 0, id, handler ptr), copied by 82:DB46 at level load. Drawn as 2x2 green dots; each affected 8x8 char switches to BG3 palette 6 (CGRAM 24-27, saved/restored at 7F:FC50) so green can coexist with the 4-color BG3 limit. Players are redrawn last and force their chars back to palette 7. Victims are always shown, fogged or not.
- **Fog of war:** one byte per 8x8-tile block at **7F:EC00-EDFF** (max 423 blocks). Hook 1 at 80:C07F (per-frame wait: `LDA $24/EOR #1/STA $24` replaced by `JSL MarkFog` + NOPs) marks the 5x5 blocks around each active player whenever the player's block changes. Hook 2 at 80:86C8 (`JSL $80ACA2` in the level loader) -> `ClearFog` wipes the array and turns fog on at every level load. Render skips unexplored chars (blank), so fogged renders are also faster.
- **A button** (map open) toggles fog on/off. Fog state in 7F:FC0E.
- Per-frame cost is tiny (only recomputed when a player crosses a block edge).
- Both hooks avoid every other known patch (checked against all IPS in the stacks); only the existing pause patch at BE:8061 is modified.

## v3 (current): window 128x96 tiles, split-screen safe, P2, fogged victims hidden
- **Why smaller:** in 2-player split-screen the game uses VRAM $9000-$9FFF (P2's BG tilemaps), WRAM 7F:F000-F20A (split state/HDMA data) and HDMA ($420C=$FE). v3 backs up VRAM $9000-$9FFF (4 KB) to WRAM (7F:E400-EFFF + 7F:F300-F6FF), draws the map into it (chars 188..380 from $8BC0, tilemap at $9800 via $2109=$4C), restores it on exit, and sets $420C=0 while the map is up (HDMA returns by itself when NMI resumes). Window is 16x12 chars = 128x96 tiles; pan steps 32 (x) / 24 (y).
- The old BG3 HUD tilemap is no longer touched.
- Fog array moved to **7F:FD00-FEFF**. Free WRAM summary: 7F:E400-EFFF, F300-F6FF (map backup), FC00-FC8F (scratch), FD00-FEFF (fog); avoid F000-F2FF (split mode), F800-FA00 (pause palette copy/flag).
- Civilians in unexplored (fogged) blocks are hidden while fog is on (A toggles).
- Player 2: marker + fog reveal verified in a real 2P game (join with controller 2 Start on the title screen), including the split-screen state.
- color schemes compared: (A fixed / B per-level tint / C match game). Match-game gives poor contrast on levels where hedge and lawn are both dark green.

## v4 (current): per-level tint, legend, scroll arrows, distinct P2
- **Tint (scheme B):** `tint/tint.asm` (`TintTab`, 64 x {floor, wall} BGR555, indexed by `$1E7C`). Generated by `tint/sample.py` (boots each level, samples median screen color of floor/wall tiles using attribute classes + camera `$1B6A/$1B6C`) then floor = 0.32 x sample, wall = 0.6 x sample + 120. Levels 19/42/47 had too few wall samples (wall derived from floor hue); non-levels use gray defaults. Floor color is written to CGRAM 0 (backdrop); wall color into palettes 5/6/7 entry 1.
- **Palettes (CGRAM 16-31 saved/restored at 7F:FC50-FC6F):** pal4 = text/arrows (white), pal5 = P2 (cyan, blinks cyan/white via entry 23), pal6 = victims (green), pal7 = P1 (red, blinks red/yellow via entry 31). Water is a fixed blue in all palettes.
- **Legend (row 3):** `[P1] [P2] [VICTIMS]` using the game's own BG3 font (A=char 144.., digits 7+d); the game's term for the civilians is "victims".
- **Scroll arrows** drawn when the window can move further: chars 381 (right arrow, H-flip for left), 382 (down arrow, V-flip for up), 383 (solid block for legend squares), written into the free chars at the end of the window range.
- All verified: 1P levels, real 2P (shared screen and split-screen), full stack; VRAM/CGRAM identical after exit.

## Status v5 — bigger arrows, game-font colors
- Scroll arrows are now 16x16 (2x2 chars) orange arrows with outline, drawn with the game's HUD palette 7; left/up use H/V flip. Chars 496-504 are stored in the unseen tilemap rows 28-31 (VRAM word $4F80).
- Legend text uses the font's native palette 7 (entries 28-31 no longer overwritten). Markers moved to pal4 (P2 cyan), pal5 (victims green), pal6 (P1/base). Blink writes CGRAM 27 (P1) and 19 (P2).
- Verified L1/L21 and real 2P; IPS rebuilt (ZAMN_PauseMap.ips 3,279 bytes; ALL_IN_ONE rebuilt).
- v5b: 1px background-color gap between legend color squares and labels (square glyph 7px wide).

## Status v6 — bigger window, black surround, border, smooth scrolling
- Window is now 22x14 chars (176x112 tiles) at 1 px/tile. Map tilemap moved to VRAM $C800 (the HUD tilemap, which is sparse-backed-up to 7F:F700 and restored on exit), freeing chars 188-511 ($8BC0-$9FFF; the P2 area is still backed up).
- Floor color is now PPU color math: backdrop stays black, color window 1 (bounds from HDMA channel 0, table HdmaTab) adds the fixed floor color only inside the panel. Legend, arrows and surround are plain transparent over black. Game values restored on exit: $2125=$A0 $2126/7=0 $2130=$10 $2131=$A2 $2132=$E5, $420C=0.
- color window enable is bit 5 (W1 enable), bit 4 is invert (WOBJSEL high nibble) - the game itself uses W2.
- Fog cells = solid char in pal3 (CGRAM 12-15, saved/restored) dim slate; cells outside the level = black (pal7 idx3). 1 px peach border ring (3 chars + flips) around the panel. BG3 VOFS=-1 so row 28 line 0 no longer shows as junk at the bottom.
- Legend square is 6 px wide (2 px gap to the label).
- Smooth redraw: no force blank while scrolling. Redraw() computes one cell-row into WRAM (rbuf 7F:FA10, tbuf FB80), applies markers from a pixel list (BuildMk/AddMk, 7F:FF00), then copies the row in vblank (1 row/frame, 14 frames). Arrows are refreshed in vblank afterwards.
- WRAM headroom is nearly zero (7F:E380-EFFF, F20F-F7FF, FA02-FFFF were the only never-written ranges); this is what limits the window size. Level 21+ use VRAM $A000-$C7FF so it can not be used without a backup.
- v6b: panel/border/color-window now fit the level when it is smaller than 22x14 cells and are centered (HDMA table built in WRAM at 7F:FCB0).
- v6c: marker colors fixed and color-blind friendly (P1 yellow, P2 cyan, victims magenta, no blink); arrow head is an exact 45-90-45 triangle.
- v6d: P1 red / P2 blue (HUD colors) flashing to white, victims steady yellow; legend shows victims left (counted at open from 7E:605A flags).
- v6e: legend labelled ZEKE (red) / JULIE (blue) instead of P1/P2. Slot 0 is always Zeke, slot 1 Julie (P2-only start puts Julie in slot 1).
- v6g: legend shows only active players (flags 1E88/1E8A), centered; victims shown as rescued/total (slash glyph = char 510).
- v6h: character per slot is the word at 7E:1E84 (slot0) / 1E86 (slot1): 0=Zeke, 2=Julie; marker colors and legend follow the character. Victims-left is the BCD byte 7E:1D52 (live, same as the mini map); legend shows left/total. Map reads both pads ($4218|$421A) so either controller can pan/exit.
- v6i: FIX radar (in-game mini map, toggled with L) corruption after the map: radar on makes ~87 nonzero words in the HUD tilemap, the sparse backup overflowed at 63. Backup now has 123 entries (7F:F700 + 7F:F210).

### v6j — scroll corruption fix (from user's RetroArch save state)
Cause: the per-row VRAM copy waited with `lda $4210 / bpl` (RDNMI latch). If computing a row took longer than a frame, the latch was already set from an earlier vblank, so the copy started mid-frame in active display and VRAM writes were dropped, leaving stale/duplicated rows (reproduced: same scroll position rendered differently on repeat visits, ~100 bytes differing).
Fix: wait for the real start of vblank ($4212 bit7: wait for clear, then set) and copy chars + tilemap row by DMA (ch7, mode 1 -> $2118) instead of a CPU loop, so it always fits in vblank. Verified on the user's state: 150 random pans, identical render at each position (old build: inconsistent at every position). Exit-restore regression unchanged.
Note: RetroArch states are RZIP (#RZIPv) -> chunked zlib -> RASTATE -> 'MEM ' chunk = raw core state; loads in the harness.

### Standalone build (no split screen)
`ZAMN_PauseMap_Standalone.ips` = Split+QoL's own `optional/zamn_pause_2mb.ips` (pause loop at BE:8000, 2 MB expansion) + the map records, applied to a clean US ROM. The pause code is byte-identical to the one inside the Split+QoL stack, so the map hooks (BE:8061, fog hooks 80:86C8 / 80:C07F) are unchanged. Tested from a fresh boot in 1P and 2P (no split screen): map opens, pans, exit restores VRAM/CGRAM/PPU regs exactly, game resumes. Add on top of any other hack that does not touch those hooks.

### v6k: demo-safe fog hooks
The level-loader hook (ClearFog at 80:86C8) is gone: it desyncs the attract demos. MarkFog now clears the fog lazily (see DEMO_NOTES.md) and returns almost at once while a demo plays. Fixed: scroll corruption (v6j) still in place.
