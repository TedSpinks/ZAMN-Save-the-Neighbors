# 2P drop-in (implemented in `dropin.asm`)

Start on the pad of an empty slot joins that player to the running game, at any moment of a level.

## Behavior
- **Arming:** Start on the idle pad arms a join (attract demos are untouched). The idle pad's Start never reaches the pause check at all: an empty pad only joins, it no longer pauses (a banned or pending Start is swallowed too). After a join, the Start that armed it stays hidden until released, so the new player's first Start does not pause.
- **Grace period:** the check normally runs every other frame, so a gap of five or more frames since the last run means the level has just started or the game was unpaused. For the next 45 checks (about 1.5 s) no join is armed, and a Start that is down in that time has to be released before it can arm (`!jhold`). Skipping a between-level screen with the idle pad, or unpausing with it, therefore does not join anyone.
- **Waiting:** the join happens once the player already in the game has been alive, on the ground (object height 0) and in a normal movement state (the player task's state is one of the handlers `$D53D-$D704`: idle, walking, firing) for 3 checks in a row (the check runs every other frame). If that does not happen within 90 checks (about 3 s) the join is dropped.
- **Spawn:** at the other player's position, so it is never inside a wall or on water, and the two players start together.
- **Fresh player:** default health, lives, weapon, item and starting ammo (`80:8874`), empty ammo and item tables, score 0, bonus threshold 4, no victims, exit flag clear. Slot 0's set-up also rewrites slot 1's first ammo and item entries, so `Join` saves and restores those two words.
- **No rejoin on the level a player ran out of lives on:** `SlotOut` (`80:CEDA`, where the game clears the slot) records the level in `!dlvl`; a Start on that pad then does what it always did (pauses). The next level allows the join.
- **Saves:** a joiner is an ordinary active player at the next level clear (saved, owned, wiped on game over). When the joiner's character has a saved game, a prompt comes first (below).

## Joiner with a saved game (`joinprompt.asm`)
Start on the empty pad, when that character (Zeke or Julie) has a valid saved game, opens a prompt before the join is armed (no save: nothing changes).

```
      JULIE JOINS            title in the highlight color
RESUME    LEVEL 6 ♥3   ◄     the cursor blinks, with the words of its row
NEW GAME  REPLACES SAVE
CANCEL
    SURE? A YES B NO         only after NEW GAME is picked: A confirms, B goes back (nothing is erased yet)
```
- **Controls:** only the joiner's pad (either controller): Up / Down / Select move, A B X Y or Start pick; in SURE? only A (yes) and B (no) count. Buttons down when the prompt opens have to be released first. After 30 s without an answer the prompt cancels. Player 1 cannot cancel.
- **While it is up:** the game is frozen (the pause check does not return: NMI off, own frame loop, own joypad reads, as the pause map does). The picture is dimmed like the pause screen (CGRAM 0-15 and 32-255 halved, the HUD palettes stay bright); only palette 4 (CGRAM 16-19, the highlight, also used by the title) is overridden: colors 0-15 are the playfield's (level 23 uses 12-15) and palette 6 colors the HUD icons. Text goes on BG3, tilemap rows 11-15. Heart and arrow are tiles 261/262 (VRAM word `$4828`). CGRAM, the tilemap rows and the two tiles are saved (7F:E400-E89F) and restored on exit. Needs only the pause base, not the pause map.
- **Results:** CANCEL (or the timeout) - no join, a Start still down has to be released first; RESUME - `!jmode` = 1; NEW GAME + yes - `!jmode` = 2. The join then waits for a safe moment as before.
- **Join with RESUME:** after the default player is set up, `XferOwn` loads the record's health, lives, weapon, item, ammo, items, score and bonus threshold into the slot (not the level or the victims: the level is shared). The save is then owned by this game (wiped on game over like a resumed one). **Join with NEW GAME:** the join is fresh as before and the character's old record is kept until the next level end, where `SaveHook` writes the joiner and replaces it (the game does not own the old save, so a game over before that wipes nothing of it).
- **Tests:** both pads as joiner, prompt for each character, cursor wrap, SURE? yes / no, CANCEL row, Start pick, timeout, held Start released first, joiner state equals the record, the other slot untouched, SRAM record still there after NEW GAME and replaced at the next level end, the other character's save kept, pause / map / unpause for the resumed joiner, no prompt when only the other character has a save, builds with and without the pause map, drop-in regressions, demos identical over 40,000 frames.

## How the game does it (findings)
- A player is a task started with `JSL $808248` (A = `$CDF4`, Y = `$0080`). Its parameters come from the *caller's direct page*: `$00`/`$02` = x/y, `$04` = `$06` = slot. The main thread's direct page is `$0C00` (the spawn must not switch to DP 0: `INC $0006` inside 8248 would then corrupt `$06` and a second slot-0 task is created).
- Everything per player keys on the slot flags `$1E88/$1E8A`: HUD, two-player camera (`80:A8B3` uses `$D2/$D4`), level-complete count (`$1FB8+$1FBA = $1E88+$1E8A`), the exit-door task.
- The pause check is `80:89B0` (any pad's Start), called from the level loop every other frame before the HUD hook. `PauseGate` replaces its first two instructions.
- An object's `+$0C` is the id of the task that owns it, and `$80:82DE + id` is that task's direct page; `dp+$28` is its state.

## Variables (7F:FF10-FF20; only used during a game, the Options list that shares the area is rebuilt on entry)
`!dlvl` (word per slot), `!jpend`, `!jhold`, `!jok`, `!jslot`, `!jact`, `!jp0/!jp1` (this check's pads), `!jlast`, `!jgrace`, `!jcur`, `!jmode` (FF28). `GameStart` clears `!dlvl`, `!jpend`, `!jhold`, `!jgrace`.

## Tests (emulator, clean ROM + IPS)
Start held across the level start is ignored until released, then a fresh tap joins; unpause by the first player then a tap inside the grace period is ignored and one after it joins; Start taps from a dead player's pad do not pause. Join with a 10-frame Start: running, fresh P2, P1 inventory untouched; join waits while the player is airborne and happens when grounded; timeout cancels, Start does not pause, a later Start re-arms; P2 Start while paused unpauses without arming; slot 0 out of lives cannot rejoin on that level and joins on the next, slot 1's inventory untouched; level completion with a joiner; save written with the joiner's score; game over wipes everything this game owns; demos identical over 40,000 frames.

## Known limits
- Mashing the idle pad's Start for longer than the grace period into the level can still arm a join.
- The pause loop itself (`BE:806C`) still accepts Start from either pad to unpause; only the pause check is gated.
- A state outside `$D53D-$D704` (hurt, dying, carried, item animations) just delays the join.
