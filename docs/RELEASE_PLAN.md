# ZAMN release plan (romhacking.net, initial beta)

> Planning notes kept for history. Patch names here are the working names (1a, 1b, 2, 3, 4); they are now `zamn-reverse-fire`, `zamn-strafe`, `zamn-pause-map`, `zamn-drop-in` and `zamn-save-the-neighbors`. Folder names in the older sections refer to the working tree before the repository was set up; the layout now is described in the root `TECHNICAL.md`.

Status: planning. Testing continues for a few days before any build is frozen.

## Posts

| # | Post | Contents | Depends on |
|---|------|----------|------------|
| 1 | Reverse fire + Strafe | one zip, two IPS (1a reverse fire, 1b strafe; pick one); controls only, no menu; fixed behavior | nothing |
| 2 | Map screen | pause + Select map, fog of war, exit door, `♥n` lives in the pause HUD | nothing |
| 3 | Drop-in co-op | Start on the idle pad joins; **no join prompt** | nothing |
| 4 | Save the Neighbors Edition | everything above + OPTIONS menu, saved games, high scores, title art, join prompt (RESUME / NEW GAME / CANCEL) | the other posts link here for the UI |

Post 4 is the full build. Posts 1-3 are cut-down variants of the same source; each readme points to post 4 for the menu and save features.

## Required changes before release

1. **Controls (1a, 1b):** build without the options code. The firing hooks currently call `JSL $BF9011` to read the setting; replace with a fixed default.
   Keep the attract-demo guard (`LDA $1EB4` -> original input path): the demos were recorded against the original timing, and the early versions of these patches desynced them. Verify demo playback hash for each patch.
2. **Drop-in (3):** build variant with `NeedPrompt` fixed to "no save" (no `JoinPrompt`, `JoinSave`, `!jmode`), so none of the save code is pulled in.
3. **Map (2):** `LivesSwap` (pause `♥n`) stays in. Rebuild the stale `map/ZAMN_PauseMap_Standalone.ips` with the stack fixes (see below).
4. **Pause-loop stack budget:** the pause runs on a task stack with about 15 bytes to spare before the next task's stack, plus 13 bytes the NMI pushes. Rule: no code in the pause loop or the per-frame hook (`80:C07F`, `BE:8061`, `80:89B0`) may use more than a few bytes of stack. Registers are kept in WRAM. Add a stack-depth check to the test harness.
5. **Shared RAM:** map buffers `$7FF000-$7FF7FF` vs skip-intro/exit flags `$7FF7FC/$7FF7FE`. Prove it harmless (flags only used on the title) or move one.
6. **Header / expansion:** every IPS that needs the 2 MB ROM must carry identical expansion and header bytes (LoROM, 2 MB; SRAM size and battery for post 4). Applying posts in any order must give the same result.
7. **Save format:** version field in the SRAM record and a rule that later releases read old saves.

## Test matrix

Build script produces: 1a, 1b, 2, 3, 4 (and any combination worth supporting, e.g. 1a+2+3). Harness per build, on a clean ROM + IPS:

- applies cleanly, CRC of the result matches the build;
- applying other posts on top, in every order, gives the same bytes as Save the Neighbors where they overlap and runs;
- attract demo hash over 40,000 frames equals the original game for the controls patches;
- pause -> map -> close -> unpause stress (the harness that found the stack overflow): 0 crashes in 1,000+ cycles from varied gameplay states, level 7 included;
- drop-in: join with each pad, join during pause, both pads, no prompt;
- post 4: saves, resume, new game over save, high scores, join prompt, SRAM header.

Emulators: Snes9x (current), then bsnes/higan and Mesen2 for the timing-sensitive parts (forced-blank VRAM DMA, NMI off/on in the map and prompts, `$4212` polling). No hardware testing; label "tested on emulators" and ask players for reports on GitHub.

## Release checklist

- Version label: 0.9 / beta in each readme and post title.
- Original ROM: Zombies Ate My Neighbors (USA), with the required CRC32/MD5/SHA-1 on each post; say plainly the European version is not supported.
- Readme per post: controls, what it combines with, known issues, credits (asar etc.), screenshots.
- GitHub: source, build script, issue template asking for emulator/core, ROM CRC, which patches were applied, and steps.
- Post order: publish 4 first (or at the same time) so the others can link to it.

## GitHub repository

One repo for everything, so players and other hackers have a single place for issues. Working name: `zamn-hacks`.

```
zamn-hacks/
  README.md                 what each patch does, which to pick, links to the romhacking.net posts, supported ROM + CRCs
  CHANGELOG.md
  LICENSE                   code license; no ROM data in the repo
  .gitignore                *.sfc *.smc *.srm save states, build/, __pycache__
  .github/
    ISSUE_TEMPLATE/bug_report.yml     asks: emulator + core + version, ROM CRC32, which patches/in what order, steps, save state if possible
    ISSUE_TEMPLATE/feature_request.yml
    PULL_REQUEST_TEMPLATE.md
  TECHNICAL.md              building, testing, design choices, known limits
  CREDITS.md
  patches/
    reverse-fire-strafe/  pause-map/  drop-in/  save-the-neighbors/     each: README.md (what it does, how to patch, tested combinations table) + TECHNICAL.md (design, testing, issues)
  src/
    common/           header/expansion, shared defines, RAM map
    reverse-fire/  strafe/  map/  dropin/  saves/  options/  title-art/
    main.asm          assembles a build from feature flags (asar defines: FEATURE_MAP, FEATURE_DROPIN, ...)
  tools/              asar (or fetch script), IPS maker/verifier, disassembler, libretro runner
  tests/              stress/fuzz scripts, demo-hash check, scenario scripts, fixtures (SRAM files)
  build.py              builds every release patch from a clean ROM given on the command line; prints CRCs
  releases/             (git tag + GitHub release assets only, not committed): the IPS files, named zamn-<feature>-v0.9.ips, with CRCs
```

Rules for the repo:
- No ROMs, save states or generated SFC files are committed; `build.py` and the tests take the path to the user's clean ROM (the USA CRC is checked first).
- One source tree with feature flags replaces the current copies (`map_v6a.asm` ... `map_v10_wip.asm`, `*_DIAGNOSTIC*.ips`, `final_*.sfc`): the history stays in git, not in file names.
- The snes9x libretro core used by the harness: link to where to get it rather than shipping a binary (check its license first); the build/test instructions say which core version was used.
- Releases: each romhacking.net post links to the matching GitHub release tag; each release lists the IPS files with CRC32 of the patched result.
- The other projects in the Project (Wild Guns, MERCS, Xeno Crisis, ...) are separate repos, not part of this one.

Migration steps (after testing settles):
1. Pick the live source of truth (current `map.asm`, `options/*.asm`, `demo/*.asm`, `tools/`), delete experiments.
2. Introduce feature flags and confirm the Save the Neighbors build is byte-identical to today's `final.sfc`.
3. Cut the standalone variants from the flags and verify each (test matrix above).
4. Move docs into `patches/<name>/`, write the README and issue templates.
5. Tag `v0.9.0-beta`, attach the IPS files, then publish the romhacking.net posts pointing at it.

## Post-release backlog (not for 0.9 beta)

- **Pixel-smooth map panning.** Panning is currently cell-stepped (8 tiles per step, repeat after 12 frames then every 3; see DEMO_NOTES.md "Smoother map scrolling (v10)"). Idea: slide the map background layer 1-2 px per frame between cell steps and do the cell redraw/tilemap shift when a full cell is crossed. Must keep working with split-screen safety, the arrows and frame bars, fog, and the pause-loop stack budget. Optional cheaper step first: shorten the repeat delay (`!rep`). Revisit after one or two releases are out.
- Plus/colon/slash glyphs; twin-stick, split toggle, nearest-victim edge pointers; update DROPIN.md for the new join-prompt layout; optional score-screen screenshot regression; optionally gate the pause loop's `BE:806C` Start-from-either-pad unpause.

- Pause `♥n` and inventory cycling (fixed): the game redraws the whole HUD from a tilemap copy in WRAM (`7E:5FB6` P1 / `7E:5FD6` P2, 7 words each, DMA'd to VRAM `$6480`/`$6490`) whenever a player cycles an item or weapon, which brought the score back. `LivesSwap` now writes `REST nn` into that WRAM copy as well as VRAM (`Emit`, `ShadowPut`), and `LvPut` puts the score back into both on unpause. Test: frame-by-frame screenshots after Y/A on either pad show no HUD change except the item icon; score cells (VRAM + WRAM copy) identical after unpause; demo hash unchanged; crash harness 0/200. Note for the stress script: a 3-frame Start tap can be missed while the map is panning (same without this change).
- R-button mode lost on emulator reset (fixed): the saved mode was only loaded by `ScoresInit`, which the game calls only while its "score table is set" flag (`7E:2124`) is clear. That flag survives a reset, the 7F:FFxx variables (`!rmode`) do not, so a reset fell back to Reverse while SRAM still held the mode. `BootHook` (`80:85F6`, was `LDA $7E2124`) now loads the mode (and the SRAM checksum) from the valid record on every boot. Test: modes 0/1/2 survive a reset, SRAM unchanged by reset+title, corrupt copy 1 -> copy 2 used, both corrupt/blank -> Reverse, no crash. Demo regression note: the demo-hash script (WRAM 0-1FFF every 100 frames) changed, because boot is a few cycles longer; only transient bytes differ (`$04` NMI saved S, `$18`, `$1C`, `$1E`, and stack residue `$112D-$113F`), no gameplay state. Use a masked hash for boot-code changes.
- Join prompt corrupted the picture on level 23 (fixed): `PPal` recolored CGRAM 12-15 (2-bit palette 3) for a Zeke-red / Julie-blue title, but colors 0-15 belong to the playfield's 16-color palette 0 and level 23 draws its ground with colors 12-15 (noise while the prompt was up). Palette 6 (24-27) is not free either: it colors the HUD weapon/item icons. Only palette 4 (16-19) is free, so the prompt now recolors only that one and the title uses the highlight palette. Rule: a screen drawn over the live playfield may only change CGRAM 16-19 (and may dim the rest). Test: `u18`/`u19`-style sweep, prompt on levels 2-48, screenshot vs a dim-only build, 0 differing pixels outside the text rows.
- Join prompt NEW GAME erased the joiner's save at once (fixed): it now keeps the old record until the next level end (`SaveHook` replaces it); game over before that leaves it (not owned). A loaded emulator save state also replaces the battery save with its own copy (the state carries SRAM): mention in the readme.
- Reverse fire did nothing after choosing REVERSE in OPTIONS (fixed): `GetMode` returned 0 through a path where the last instruction was `CMP #3`, leaving Z clear, and `RMode` branches on Z (`BEQ .rev`), so an explicit REVERSE (`$5A00`) fell through to the original controls. Only an unset/invalid value (which goes through `LDA #0`) worked. `GetMode` now ends with `CMP #0`. Test: player DP `$100` facing (`$126`) vs direction (`$124`) for left/up/right/down + R in modes REVERSE (explicit), default, STRAFE; old build: explicit REVERSE faced the walking direction, new build faces the opposite way. Add this check to the harness (all three modes, all four directions).

## Decisions (2026-10-30)

- **Third-party code is bundled, with credit.** The map needs the Split-screen+QoL pause loop (bank BE), and the controls need Reverse Inventory Cycling (romhacking.net 4318) to stay demo-safe, so the IPS files that use them include those bytes. Every readme and post credits the original authors with links. Blood edition (BLOODY DISGUSTING EDITION) is in the current Save the Neighbors build; its author is credited too (confirm it stays in).
- **Post 4 is the convenience bundle:** one IPS with everything tested together: pause map, Reverse Fire / Strafe / Original (OPTIONS menu), Reverse Inventory, Hitbox 150, Blood, skip intro, character-select confirm sound, A+B+X+Y back-out from character select, OPTIONS menu, saved games / RESUME, high scores, drop-in with join prompt, title art. Posts 1-3 stay the small separate downloads.
- **Reverse Inventory in attract demos:** verified harmless. Rendered demo frames every 100 frames over 40,000 frames are identical to the original game for Reverse Inventory alone, Reverse Fire, Strafe, and Reverse Fire + Hitbox 150 + Reverse Inventory (Snes9x). Save the Neighbors cannot be compared frame for frame (skip intro shifts timing, Blood changes graphics), so its demo check is "plays, no desync/crash".
- **Emulators:** Snes9x, bsnes (accuracy, libretro core built locally with memory accessors added) and Mesen-S (libretro) run the harness (`CORE=...` env var selects the core; `lr.py` handles Mesen-S's late callback setup and bsnes's 0RGB1555 default). Character-select back-out passes on all three.

## Status (2026-10-30)

Done: `build.py` builds 1a, 1b, 2, 3 and 4 from a clean ROM (CRC32 check, each IPS verified to reproduce its build; Save the Neighbors is byte-identical to the build tested all along, result CRC32 AB420B3E). Sources: `options/dropin_only.asm` (drop-in with `NOPROMPT`), third-party inputs in `third_party/`, controls IPS in `controls/`.
- Required change 1 (controls): 1a/1b are the demo-safe release2 patches; frames of the attract demos equal the original over 40,000 frames (Snes9x).
- 2 (drop-in, no prompt): `dropin.asm` `NOPROMPT` define; demo frames equal the original; join with pad 2 tested on Snes9x, bsnes, Mesen-S.
- 3 (map): rebuilt from `map.asm` on the pause base; demo frames equal the original; open / pan / close / resume on all three emulators (a 2-frame Start tap closes the map; a 1-frame tap can miss).
- 4 (stack): bsnes build with a lowest-stack counter for bank BE: plain pause patch lowest S $1137, map $112A, Save the Neighbors $112A (also with a joiner): +13 bytes for the map, none for the rest.
- 5 (shared RAM): the skip-intro flags (7F:F7FC/F7FE) lie inside the map's HUD buffer range; harmless: they are written and read only while the boot logos run, re-initialized at every boot (`KonamiWrap`) and the latch unregisters itself (`!arm` cleared) before any level.
- 6 (header/expansion): `expand()` and the pause patch write the same size byte (`$7FD7 = $0B`), zero fill and final byte `$FF`; the only conflicting byte between a 2 MB patch and Save the Neighbors is the SRAM size (`$7FD8`), which Save the Neighbors owns. Pairs checked: no conflicts among 1a/1b (except each other), 2, 3.
- 7 (save format): version word exists in both records; compatibility rule written in SAVE_NOTES.md.
- Cross-emulator: Snes9x, bsnes (accuracy, libretro core built here with memory accessors) and Mesen-S: smoke (join, map, R facing), character-select back-out, taps. Not done: the full save / resume / high score matrix on bsnes and Mesen-S (Snes9x only), hardware.
- Docs: README, CREDITS (author names still to fill in), CHANGELOG, per-post docs, issue templates, `.gitignore`.

Still to do: fill in credits; run the save/resume matrix on the other two emulators; repo migration (single source tree with feature flags instead of the current folders, git history); tag and publish; decide on `map/ZAMN_PauseMap_Standalone.ips` (now replaced by `zamn-2-pause-map.ips`).

## Cross-emulator results and the joypad-read fix (2026-10-30)

- Save / resume / high scores on Snes9x, bsnes, Mesen-S: identical. Level-end save (record holds the poked score and ammo, both copies equal), RESUME GAME (level, score, ammo restored), R-mode and score table persistence, corrupt-copy fallback, erase.
- Join prompt (Julie saved, Zeke starts, pad 2 presses Start): RESUME joins with the saved score, CANCEL does not join, NEW GAME joins fresh and keeps the old record. Identical on all three after the fix below.
- **Bug found by bsnes (real-hardware race):** `PWait` in `joinprompt.asm` (and the map's own loop) tested "auto-joypad busy is clear" right after the vblank flag. The automatic read starts about 33 dots later, so the test could pass before the read began and the pad registers were read stale or half shifted. On bsnes Down never registered at the prompt and A arrived late. Fix: wait for busy to go up (bounded poll in the prompt, 12 reads of `$4212` in the map), then for it to go down. Snes9x and Mesen-S were unaffected. Rule: every own frame loop that reads `$4218` must do this.
- Start tap while the map is open: 2+ frames always closes it on all three; a 1-frame tap can miss (one phase on Snes9x and bsnes).
- Stack (bsnes counter): Save the Neighbors lowest S $112A, unchanged by the fix.


## Decisions (2026-10-30, docs)
- Hitbox 150 and Blood are bundled only in Save the Neighbors; the other posts don't include them. Save the Neighbors still includes Reverse Inventory Cycling.
- Reverse fire and strafe share one post, one folder and one readme (two IPS files).
- Every post has README.md (summary, how to patch, table of tested combinations with how to apply them) and TECHNICAL.md (testing, issues, design). The top-level README.md / TECHNICAL.md do the same for the whole repository.
- American English spelling everywhere.
- The combination tables come from `tools/compat.py` (byte overlap, any-order check) plus a boot/play test of each combined ROM.
