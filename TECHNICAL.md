# Technical notes

Details that don't belong in the readmes: building, testing, design choices, problems found. Per-patch notes are in `patches/<name>/TECHNICAL.md`.

## Patched ROM checksums
Each patch applied alone to the clean ROM (CRC32 `7CFC0C7C`):

| Patch | IPS size | Patched ROM size | Patched ROM CRC32 |
|---|---|---|---|
| `zamn-save-the-neighbors.ips` | 17,297 B | 2 MB | `77B323A8` |
| `zamn-reverse-fire.ips` | 193 B | 1 MB | `76BCB0CD` |
| `zamn-strafe.ips` | 177 B | 1 MB | `6B1E29EE` |
| `zamn-pause-map.ips` | 9,024 B | 2 MB | `7AA976BF` |
| `zamn-drop-in.ips` | 702 B | 2 MB | `B6F8306B` |

## Building
`python3 build.py /path/to/clean.sfc [outdir]` (output goes to `out/` by default, which is not committed) builds every patch from the clean ROM, checks the ROM's CRC32 and SHA-1 first, and for each patch writes the IPS, verifies that applying it to the clean ROM reproduces the build byte for byte, and then packs one release zip (the main patch IPS, the individual patches in `individual/`, README.md, CHEAT.txt, CHECKSUMS.txt). Needs [asar](https://github.com/RPGHacker/asar) (in `tools/` or on PATH) and Python 3 with Pillow (title art only).

| Output | Built from |
|---|---|
| `zamn-reverse-fire.ips`, `zamn-strafe.ips` | `inputs/controls/ZAMN_ReverseFire.ips`, `inputs/controls/ZAMN_Strafe.ips` |
| `zamn-pause-map.ips` | `inputs/third_party/zamn_pause_2mb.ips` + `src/map/map.asm` |
| `zamn-drop-in.ips` | the 2 MB expansion + `src/options/dropin_only.asm` |
| `zamn-save-the-neighbors.ips` | see [Save the Neighbors Edition](patches/save-the-neighbors/TECHNICAL.md) |

## Design choices
- **Every patch is a diff from the clean ROM.** The pause map, drop-in and Save the Neighbors patch carry identical expansion bytes (header `$7FD7 = $0B`, zero fill, last byte `$FF`), so patches that don't touch the same code give the same ROM in any order. Only the main patch sets the battery RAM header bytes (`$7FD6`, `$7FD8`).
- **Independent patches.** The pause map doesn't depend on the options, saves or drop-in code, and the reverse-fire and strafe patches need nothing else.
- **The header checksum** is correct in each patch alone. A combination carries the checksum of the last patch applied, so it is wrong; the console and emulators don't check it.
- **Demo safety.** Attract-mode demos replay recorded input and are cycle-sensitive: no hook sits in the level loader, and every change that alters timing, collision or button meaning checks the demo flag `$1EB4`. See `DEMO_NOTES.md`.
- **Patch a clean ROM.** An IPS only writes bytes that differ from the clean ROM. Over an older build, stale bytes could survive; the patches rewrite the known legacy sites to limit that, but a clean ROM is the supported base.

## Testing
Scenarios run on Snes9x, bsnes (accuracy core) and Mesen-S through libretro; `CORE=<core.so>` selects the emulator for the scripts in `tests/` (see `tests/README.md`).
- Boot, start a game, move, pause, map open/pan/close, unpause; drop-in join with each pad; R facing.
- Character select back-out; save, resume and high scores; join prompt (see the Save the Neighbors Edition notes).
- Attract demos: rendered frames hashed every 100 frames for 40,000 frames equal the original for reverse fire, strafe, pause map, drop-in, Reverse Inventory, reverse fire + pause map + drop-in, and Reverse Fire + Hitbox 150 + Reverse Inventory (Snes9x).
- Pause-loop stack depth (bsnes with a lowest-stack counter): plain pause patch, map and Save the Neighbors Edition compared.
- **Combinations:** `python3 tools/compat.py clean.sfc` lists, for each pair of patches, the bytes both change and how many of those differ (none: same result in either order), checks the "any order" claims by applying every permutation, and writes the combined ROMs to `out/compat/`. Each combined ROM in the readme tables was started on Snes9x, bsnes and Mesen-S, played into a level, and checked for the features it includes (R facing, map open and close, drop-in join). The third-party patches used (Reverse Inventory Cycling v1.1, Bloody Disgusting Edition) are in `inputs/third_party/`.
- Not tested: real hardware, and any patch not listed in the tables.

## Problems found while testing
- **Joypad read race (bsnes).** After the vblank flag, `$4212` bit 0 (auto-read busy) is still clear until about dot 33 of the next line. Own frame loops that poll "busy clear" can read `$4218` stale or half shifted. Fix: wait for busy to rise (bounded), then fall. Applied to the join prompt and the map loop; any new frame loop that reads the pad must do the same.
- **Character select back-out** without full teardown gave garbage graphics or a hang in the sound handshake; fixed by leaving the way a game start does.
- **Patching an already-patched ROM** left stale bytes; see above.

## Known limits (1.0)
- Emulator testing only.
- Loading an emulator save state replaces the game's battery save with the copy inside the state (Save the Neighbors).
- Save the Neighbors SRAM use is 8 KB; flash carts need SRAM enabled.
- Backlog: pixel-smooth map panning, more glyphs (plus, colon, slash), nearest-victim pointers, gating the pause loop's unpause (`BE:806C`).

## Repository layout
| Folder | Contents |
|---|---|
| `patches/` | One folder per release patch: `README.md` (what it does, how to patch, tested combinations) and `TECHNICAL.md` |
| `src/` | The 65816 source (asar): `map/`, `options/` (OPTIONS menu, saves, drop-in, join prompt, back-out), `intro/`, `demo/` |
| `inputs/` | Patches by other authors, and the controls patches, that `build.py` starts from |
| `tools/` | Build and analysis helpers (IPS writer, compatibility check, title art, libretro driver, assembler and disassembler) |
| `tests/` | Emulator scenario scripts |
| `docs/` | Research and planning notes: demo findings, level map, password list, release plan, toolchain notes |

## Version history
- **1.0.0:** fixes the pause map's memory use on big levels (it overwrote the bottom of the level map and some tile graphics), the secret-level password, and joining mid-level; reshapes the OPTIONS title lettering; renames the R setting ORIGINAL to RADAR. See `CHANGELOG.md`.
- **0.9.0-beta:** first public beta of the Save the Neighbors Edition and the individual patches (reverse fire, strafe, pause map, drop-in). See `CHANGELOG.md`.
