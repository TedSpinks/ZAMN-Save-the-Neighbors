# Saved-game research notes (WRAM map and hook points)

Status: implemented in `save.asm` (see the end of this file for the design and tests). The tables below are the research it is based on. All addresses are WRAM (7E:xxxx) unless noted; "P" = player slot offset X (0 = slot 0, 2 = slot 1).

## Per-player state (found in the player init routine 80:8874, called for X=0 and X=2 from 80:8618)
| Address | Meaning |
|---|---|
| `$1E88` / `$1E8A` | slot 0 / slot 1 is in the game (HUD and level loop test these) |
| `$1E84` / `$1E86` | character in slot 0 / slot 1 (0 = Zeke, 2 = Julie) |
| `$1CB8,P` | health (starts at 10) |
| `$1D4C,P` | lives left (starts at 2, level-end bonus raises it to at most 5; `DEC` at 80:CEC5 and `BMI` = out of lives) |
| `$1CBC,P` | current weapon index (0..13) |
| `$1CC0,P` | current item index (0..11; starts at 7) |
| `$1CCC` / `$1CEC` | weapon ammo tables, 14 words each (BCD), slot 0 / slot 1. Index 0 = squirt gun, starts at `$0150`. This is the "150" on the HUD, not the score |
| `$1D0C` / `$1D2C` | item count tables, 12 words each, slot 0 / slot 1. Item 7 starts at 1 (`$1D1A` / `$1D3A`) |
| `$1E72` (+`$1E74`) / `$1E76` (+`$1E78`) | score, 32 bit, slot 0 / slot 1 |
| `7E:6054` / `7E:6056` | next bonus score threshold per slot (BCD, `+4` each time; set to 4 at 80:8626) |

## Game-wide state
| Address | Meaning |
|---|---|
| `$1E7C` | level number (also the password result and title result) |
| `$1D52` | victims left on this level (BCD, live) |
| `$1D50` | victims for the level (BCD, set with `$1D52` at level start, 80:866F) |
| `$1F9C` / `$1F9E` | victim counts per slot, with id lists at `$1FA0..` and `$1FAB..` (stores at 80:C83F / C84F). Their sum is the victim count the password encodes (82:B102) and what 80:866F copies into `$1D50` / `$1D52` |
| `$1F98,X` | pause flag per player |
| `$1EB4` | attract-mode demo flag (nonzero while a demo plays) |

Open question: exactly how `$1F9C/$1F9E` relate to "victims saved vs killed". The bonus code at 82:D479 adds an extra victim (`INC $1F9C,X`, `$1D50`/`$1D52` +1) while the sum is below 10, otherwise an extra life. To be confirmed in play.

## Game flow (main loop 80:84B1)
`8085CF` setup, `809126` title menu, `808618` player init, `808632` level load, `808516` play the level (carry set = game over), `80866F` level-end victim setup, `82BD6A` password / level-complete screen, `808909` next level, then back to `808849`.
- Level complete: after `JSL $82BD6A` at **80:84F6** (`JSL $808909`): candidate hook, runs only for real play (not demos, which use 80:9B3D / 9B9C).
- Game over: **80:84FC** `JSL $808A00`: candidate hook to wipe the save.
- Both candidate hooks are outside the cycle-sensitive level loader (80:86C8), so demos should not drift. Re-run the 40,000-frame demo comparison after hooking.

## Size estimate
Per player: health 2 + lives 2 + weapon 2 + item 2 + ammo 28 + items 24 + score 4 + threshold 2 + victims 2 + character 2 = about 70 bytes. Game-wide about 20. Two characters plus game-wide, doubled for the two-copy checksum scheme, is under 400 bytes of the 7.5 KB free.


## Implementation (save.asm)
- **SRAM `$0200` / `$0300`**: two copies of one `$E0`-byte record, checksummed, written one after the other. One record per character ($6C bytes): valid flag, level, victim block (`$1F9C..$1FBB`, `$1D50`, `$1D52`), health, lives, weapon, item, ammo table, item table, score, bonus threshold. Each record stands alone, so a Zeke save and a Julie save can come from different games; BOTH is offered whenever both exist; the better save wins (see Merge rule). The table `SlotTab` drives the copy in both directions.
- **Save**: `80:84F6` (`JSL $808909`, next level) is `SaveHook`: it runs the original, then saves every player still in the game. A player who was in the game at the start (`actmask`) but whose slot flag is now 0 ran out of lives and has his record wiped. Characters are looked up through `$1E84/$1E86`, so a swapped Zeke/Julie still lands in the right record.
- **Game over**: `80:84FC` (`JSL $808A00`) is `OverHook`: wipes only the saves this game *owns*: bits 2 and 3 of `actmask` are set when the game writes a slot's save at a level end or resumes from it. A new game that ends before its first level-end therefore leaves an older save alone, and a character who was not in the game keeps his save. The same ownership test decides the out-of-lives wipe at a level end.
- **Game start**: `80:84BD` (`JSL $808618`) is `InitHook`: runs the player set-up, remembers who is playing, and when RESUME GAME chose a save, loads it over the defaults.
- **Leaving the title**: `80:9169` (first call after the title accepted a start) is `ResumeStart`: when a save was chosen it sets the slot flags and returns from the title function the way `80:9178` does, skipping the player select. A single resumed player is always slot 0 (pad 1): Julie alone swaps the character words (`$1E84 = 2`, `$1E86 = 0`) like SELECT on the player select. Resuming BOTH does not skip the title's player select: `ResumeStart` returns normally and the select screen runs in a mandatory two-player mode (`!resume = 3`): the two start-press sites (`80:9944` P1, `80:997B` P2) call `StartP1`/`StartP2`, which set both slot flags and unhide both pictures, so either Start begins a co-op game with the characters as displayed (SELECT still swaps before a Start; no Start = the usual 900-frame timeout to the title). `GameStart` loads the save of the character in each slot. `TitleHook` clears the pending choice when the title is redisplayed (select timed out, demo, etc.). Records are found through the character in each slot, so either arrangement saves and loads correctly.
- **Options**: row 0 RESUME GAME opens the RESUME screen (`ResumeScreen`): one entry per save (ZEKE, JULIE, BOTH, compacted, each with `LEVEL n` and `VICTIMS n`), Up/Down/Select move, A/B/X/Y pick, EXIT or Start goes back; with no save the row's hint says NO SAVE and nothing opens. `ResInfo` fills `7F:FE10..1B` (level, victims in binary: Zeke, Julie, both) from SRAM; victims are the record's `$1D50` (BCD).
- **Merge rule (BOTH)**: `Winner` = higher level; at equal levels the higher `$1D50`; ties go to Zeke. `GameStart` loads the losing slot first and the winner's last, so the game-wide rows (level, victim block, `$1D50/$1D52`) are the winner's while each player keeps own score, gear, lives and bonus threshold. The saves of both players are then owned by the game as before; the one-run wipe rules are unchanged. ERASE DATA wipes the saved game together with the scores.
- **WRAM**: `7F:FD00-FEFF` is the map's explored-area array and is wiped every time the level number changes. Anything that must survive a level lives at `7F:FF08-FF0F` (`rmode`, `sramck`, `actmask`, `resume`). The R-button mode used to sit at `7F:FE00`, so it was reset to REVERSE after the first level; fixed.
- **2P drop-in** is done: see DROPIN.md (`dropin.asm`).

## Tests (clean ROM + IPS, emulator)
Level 1 completed through the real exit door with poked ammo, items and score: the record holds exactly those values; Julie-only, Zeke-only and both resume with the same values and level; a player at 0 lives is wiped at the next level end; game over wipes both copies; ERASE DATA wipes them; copy 1 corrupt falls back to copy 2; both corrupt gives NO SAVE; the R mode survives into the resumed game; the four attract demos plus the title loop still match the clean ROM over 40,000 frames.

Ownership tests: resume Zeke then game over wipes Zeke only; resume both then game over wipes both; a new game as Zeke ending in game over wipes nothing; a new game that finishes a level replaces Zeke's save and leaves Julie's alone.

## Compatibility rule for later releases (0.9 beta)
Both records carry a version word at +4 (currently 1) and are located by magic ('ZAMN' at $0000/$0100, 'ZSAV' at $0200/$0300) and checksum. Version 1 is frozen: a later release must read it as it is, may only append data after the last version-1 byte (score record +$C7, saved-game record +$DF) or use a higher version with an upgrade step, and must never reuse the magic with a different layout. Today's code does not compare the version word; a release that changes the layout has to add that check first.
