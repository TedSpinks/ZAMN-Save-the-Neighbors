# ZAMN: Save the Neighbors Edition

`zamn-save-the-neighbors.ips` is everything in this project in one patch: saved games and high scores, the OPTIONS menu and the other screens, and every other patch. Apply it alone to a clean USA ROM.

## What is in it

- **Reverse fire, strafe or the original radar button on R**, chosen on the new **OPTIONS** screen (title menu) and remembered in battery RAM. See [Reverse Fire and Strafe](../reverse-fire-strafe/README.md).
- **Pause map** and weapon/item cycling while paused: [Pause map](../pause-map/README.md).
- **Drop-in co-op** with a join prompt when the joiner's character has a saved game: RESUME, NEW GAME (replaces the save only when the next level ends) or CANCEL. [Drop-in](../drop-in/README.md).
- **Saved games:** written when a level is completed. RESUME GAME in OPTIONS offers ZEKE, JULIE or BOTH. Game over and running out of lives wipe only what this game owns; ERASE DATA wipes everything. Passwords still work.
- **High scores** saved in battery RAM.
- **Bigger hitboxes:** the shared sprite collision box grows from 16 to 24 pixels (+50%) on each axis. It covers picking up items, rescuing neighbors and shots hitting enemies; wall and terrain collision is unchanged.
- **Reverse Inventory Cycling** (hold L while cycling weapons or items to cycle backward) and **Bloody Disgusting Edition** (restores the blood on the Game Over screen).
- Press Start to skip the boot logos; a confirm sound on the character select; **A+B+X+Y** on the character select (before anyone presses Start) goes back to the title; new OPTIONS title art.
- Attract-mode demos keep the original controls and the original hitbox.

## OPTIONS menu

| Row | Action |
|---|---|
| RESUME GAME | Pick a saved game (ZEKE, JULIE or BOTH) |
| PASSWORD | The game's password screen |
| TOP SCORES | The high score table |
| ERASE DATA | Hold A+B+X+Y+Start for about 2 seconds to erase scores and saved games |
| R REVERSE / STRAFE / RADAR | A, B, X, Y or Left/Right cycles the setting. RADAR is the original: R opens the neighbor radar |
| EXIT | Back to the title (Start does the same) |

## How to patch

Apply `zamn-save-the-neighbors.ips` to a clean *Zombies Ate My Neighbors (USA)* ROM, 1 MB, no header (CRC32 `7CFC0C7C`). The patch expands the ROM to 2 MB and sets 8 KB of battery RAM; on a flash cart, enable SRAM. Do not apply any of the other patches on top of it.

## Tested combinations

Save the Neighbors already contains everything below, so there is nothing to combine with it. Applying the others on top overwrites parts of it.

| Other patch | Result | How to apply |
|---|---|---|
| Reverse Fire or Strafe | Included, as the R setting in OPTIONS | Use the all-in-one patch alone |
| Pause map | Included | Use the all-in-one patch alone |
| Drop-in | Included, with the join prompt | Use the all-in-one patch alone |
| Reverse Inventory Cycling v1.1 | Included | Use the all-in-one patch alone |
| Bloody Disgusting Edition | Included | Use the all-in-one patch alone |
| Any other hack | Not tested | |

## Known limits

- Emulator testing only (Snes9x, bsnes, Mesen-S).
- Loading an emulator save state replaces the game's battery save with the copy inside the state.
- The skip-intro change shifts the boot timing, so the attract demos start a little differently from the original; each demo itself plays as recorded.

More: [TECHNICAL.md](TECHNICAL.md), [Credits](../../README.md#credits).
