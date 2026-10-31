# ZAMN: Save the Neighbors Edition: technical notes

## How it is built
`build.py` applies, in order, to the clean ROM:
1. `inputs/controls/combo_rf_hitbox_ri_blood.ips`: Reverse Fire hooks, Hitbox 150, Reverse Inventory Cycling v1.1 and Bloody Disgusting Edition.
2. `inputs/third_party/zamn_pause_2mb.ips`: the pause loop and the 2 MB expansion.
3. asar: `src/map/map.asm`, `src/intro/skipintro.asm`, `src/demo/hitbox_demo.asm`, `src/options/options.asm` (which includes `sram.asm`, `dropin.asm`, `save.asm`, `joinprompt.asm`, `charback.asm`), `src/demo/charselect.asm`.
4. `tools/build_title_art.py`: the OPTIONS title art.
Then the checksum is fixed, the IPS is diffed against the clean ROM and checked to reproduce the build byte for byte. Code lives in banks `BE` (pause loop, map) and `BF` (options, saves, drop-in, join prompt, back-out), plus small stubs in `82` and `83`.

## Design choices
- **One R routine, three modes.** The five Reverse Fire / Strafe hook sites call `9F:FFC0`, which now jumps to `RMode`. The mode (`$5A00` + 0 reverse, 1 strafe, 2 original) is in `7F:FF08`; any other value reads as reverse, so power-on garbage is safe. `$1EB4` (demo) always means original controls.
- **Radar:** `RadarCur` / `RadarPrev` (`83:FC40`) use Select, or the original L/R mask in a demo or with R = ORIGINAL.
- **Hitbox:** the original routine at `80:BEC9` keeps its 8/16 constants for the demos; the 12/24 copy is at `80:FF68`; `HbEntry` picks one by `$1EB4`. The +50% idea and routine come from JamesIV4 (see CREDITS).
- **Demo safety:** demos replay recorded input against the real game, so any change in timing, collision or button meaning makes them drift. No hook sits in the level loader, and each change above checks `$1EB4`.

## Saving (`sram.asm`, `save.asm`)
- Header: `$7FD6 = 2` (ROM + battery RAM), `$7FD8 = 3` (8 KB). SRAM is `$70:0000`.
- `$0000` and `$0100`: two copies of one `$C8`-byte score record (`'ZAMN'`, version 1, checksum, R mode, score tables). Copy 1 is written, then copy 2, so a power cut mid-save leaves a good copy. `$0200` and `$0300`: two copies of the saved-game record (`'ZSAV'`), one `$6C`-byte block per character. Each block stands alone, so a Zeke save and a Julie save can come from different games.
- Saves are written at level end (`SaveHook`, `80:84F6`) and only when the checksum changed. Game over (`OverHook`, `80:84FC`) wipes only the saves this game owns (written or resumed this run). BOTH uses the better record for the shared state (higher level, then more victims, ties to Zeke).
- The original game writes 0 to `$70:0000` whenever an attract demo starts; that store is NOPed.
- **Compatibility rule for later releases:** version 1 is frozen. A later release must read it as it is, may only append data after the last version-1 byte or use a higher version with an upgrade step, and must never reuse a magic with a different layout. Today's code does not compare the version word; a release that changes the layout has to add that check first.
- WRAM `7F:FD00-FEFF` is wiped by the map on every level change, so persistent variables sit at `7F:FF08-FF0F`.

## Join prompt (`joinprompt.asm`)
Shown when the joiner's character has a saved game. The game is frozen (NMI off, own frame loop and joypad reads, like the map); the picture is dimmed like the pause screen and only palette 4 is overridden. CGRAM, tilemap rows and two tiles are saved and restored. Only the joiner's pad counts; 30 s without an answer cancels.

## Character select back-out (`charback.asm`)
Hook at `80:99BA` (the select loop's per-frame yield). A+B+X+Y on either pad, before anyone presses Start and after the buttons are released, leaves like a game start does (fade, stop the select tasks), resets state like a finished attract demo, clears `$7C` so the title's one-time set-up runs again, and returns to `80:9126`. Returning without that teardown gave garbage graphics or hung the sound handshake (`$CCC8`), so it is complete by design.

## Issues found and fixed
- **Joypad read race (bsnes):** see the pause-map notes. The join prompt waited for the auto-read to finish too early and could read stale buttons (Down never registered, A arrived late). It now waits for busy to rise, then fall. The same fix is in the map loop.
- **R mode reset after the first level:** the mode sat in the range the map wipes; moved to `7F:FF08`.

## Testing
Snes9x, bsnes (accuracy) and Mesen-S, through libretro cores, on a clean ROM plus the IPS:
- Level completed through the real exit door with known ammo, items and score: the record holds those values; Zeke, Julie and both resume correctly; a player at 0 lives is wiped at the next level end; game over and ERASE DATA wipe; a corrupt copy 1 falls back to copy 2; both corrupt gives NO SAVE; ownership rules (resume then game over wipes that save only; a new game that ends before its first level end wipes nothing).
- Join prompt: RESUME joins with the saved score, CANCEL does not join, NEW GAME joins fresh and keeps the old save until the next level end; identical on all three emulators.
- Character select back-out: pad 1 and pad 2, 25 repeats, early/late/near the 900-frame timeout, three-button combinations ignored.
- Smoke test (join, map open/pan/close, R facing) on all three.
- Stack depth: lowest stack pointer `$112A` (plain pause patch `$1137`), within the spare room.
- Save the Neighbors cannot be compared frame for frame with the original: skip-intro shifts timing and the blood edition changes graphics. Its demo-safety rests on the 40,000-frame comparisons of the patches it is made from.
- Not tested: real hardware.
