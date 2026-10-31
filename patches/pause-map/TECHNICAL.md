# Pause map: technical notes

## Structure
- `zamn_pause_2mb.ips` (third-party, see Credits in the README) supplies the pause loop in bank `BE` (`BE:8000`, 560 bytes, plus a 39-byte hook) and the 2 MB expansion (header `$7FD7 = $0B`, zero fill, last byte `$FF`). `map/map.asm` adds the map on top. The expansion bytes are identical in every patch that needs 2 MB, so those patches can be applied in any order.
- The map runs inside the pause loop with NMI off: it has its own frame loop and its own joypad reads, saves and restores VRAM, CGRAM and the HUD, and returns to the pause screen.
- Level data is rendered at one pixel per tile into BG3 characters. Panning moves one cell (8 tiles) per step; each cell keeps a fixed character slot while the window moves over it, so only cells that come into view are redrawn. A full redraw takes about 0.3 s.
- Fog of war: `MarkFog` runs from a frame hook and records explored cells in `7F:FD00-FEFF`. There is deliberately no hook in the level loader (`80:86C8`): even a pass-through `JML` there shifts timing enough to desynchronize the attract demos. The array is cleared lazily when no player is active or the level number changes.
- Exit door: it is created only when the last victim is saved, so `82:F8DD` calls `ExitHook`, which records its position per player slot.
- Pause screen: the radar is dimmed with the rest of the screen (palette 4 gets a halved copy of palette 7 and the radar cells use it while paused), and L/R no longer toggle the radar there.
- A hidden chord on the map (A+B+L+R+Select) steps through whole map, whole map with item dots, and normal.

## Issues found and fixed
- **Joypad read race (found by bsnes).** Right after the vblank flag, `$4212` bit 0 (auto-read busy) is still clear until about dot 33 of the next line. A frame loop that waits for busy to clear could read `$4218` stale or half shifted. The map loop now waits for busy to rise (bounded) and then fall. Taps of two frames or more now close the map on all three emulators; a one-frame tap can still be missed.
- **Fog cleared on map reopen.** Two map variables sat inside the palette buffer and were overwritten when the map opened. They moved to `7F:FCC0-FCC2`.
- **Border garbage when patching an already-patched ROM.** An IPS only writes bytes that differ from the clean ROM, so zero bytes in the expansion were never written and stale bytes from an older build survived. The patch now writes whole spans (zeros included) in the expansion and always rewrites the legacy hook sites. Patching a clean ROM is still the recommended way.

## Testing
- Map opens, closes and the game resumes, with one and two players (Snes9x, bsnes, Mesen-S).
- Panning on a level larger than the map window: identical results on all three emulators on level 2 (vertical), and on both axes on level 19 (Snes9x). Level 1 fits the window, so it cannot pan.
- Attract demos: rendered frames every 100 frames for 40,000 frames equal the original (0 of 400 checkpoints differ).
- Stack depth (bsnes with a lowest-stack counter): lowest stack pointer `$112A` with the map, `$1137` with the plain pause patch: 13 bytes more, inside the spare room.
- State after unpause: tilemap and palette identical to before the map opened.
- Combinations: see the table in the readme.
