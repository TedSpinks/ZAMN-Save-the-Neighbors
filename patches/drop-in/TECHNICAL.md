# Drop-in co-op: technical notes

Source: `src/options/dropin.asm`; this patch is `src/options/dropin_only.asm`, which builds it without the save prompt (`!NOPROMPT = 1`).

## How the game does it
- A player is a task started with `JSL $808248` (A = `$CDF4`, Y = `$0080`). Its parameters come from the caller's direct page: `$00`/`$02` = x/y, `$04`/`$06` = slot. The main thread's direct page is `$0C00`; the spawn must not switch to DP 0, because `INC $0006` inside `8248` would then corrupt `$06` and create a second slot-0 task.
- Everything per player keys on the slot flags `$1E88`/`$1E8A`: HUD, two-player camera, level-complete count (`$1FB8+$1FBA = $1E88+$1E8A`), the exit door task.
- The pause check is `80:89B0` (any pad's Start), called every other frame. `PauseGate` replaces its first two instructions, so an idle pad's Start never reaches the pause code.

## Design
- **Arming:** Start on the idle pad arms a join. After a join, the Start that armed it stays hidden until released, so the new player's first Start does not pause.
- **Grace period:** a gap of five or more frames between runs of the check means a level just started or the game was unpaused. For the next 45 checks (about 1.5 s) no join is armed, and a Start that is down has to be released first.
- **Waiting:** the player already in the game must be alive, on the ground (object height 0) and in a normal movement state (`$D53D-$D704`: idle, walking, firing) for 3 checks in a row. After 90 checks (about 3 s) the join is dropped.
- **Spawn:** at the other player's position, so it is never inside a wall or on water. Default health, lives, weapon, item and starting ammo (`80:8874`); score 0; bonus threshold 4. Slot 0's set-up also rewrites slot 1's first ammo and item entries, so `Join` saves and restores those two words.
- **No rejoin on the level a player ran out of lives on:** `SlotOut` (`80:CEDA`) records the level in `!dlvl`.
- Variables live at `7F:FF10-FF20`; `GameStart` clears them. Attract demos are untouched (`$1EB4`).

## Testing
- Start held across the level start is ignored until released, then a fresh tap joins; unpause then a tap inside the grace period is ignored and one after it joins.
- Join with a 10-frame Start: running, fresh player 2, player 1's inventory untouched; the join waits while airborne; timeout cancels without pausing; a later Start re-arms.
- Slot 0 out of lives cannot rejoin on that level and joins on the next; slot 1's inventory untouched; level completion with a joiner.
- Attract demos equal the original over 40,000 frames.
- Join with each pad, on Snes9x, bsnes and Mesen-S.
- Combinations: see the table in the readme.

## Known limits
See the readme. The pause loop itself (`BE:806C`) still accepts Start from either pad to unpause.
