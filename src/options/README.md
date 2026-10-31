# Options, saves, drop-in

Built together into the main patch by `options.asm`, which includes the other files. `dropin_only.asm` builds just the drop-in (no save prompt) for patch 3.

| File | What it does |
|---|---|
| `options.asm` | OPTIONS screen, R-button mode (reverse, strafe, original), radar button, hooks |
| `sram.asm` | Battery RAM: high scores and the R mode |
| `save.asm` | Saved games (written at level end), RESUME GAME, ownership and wipe rules |
| `dropin.asm` | Start on the idle pad joins a second player |
| `joinprompt.asm` | RESUME / NEW GAME / CANCEL prompt when the joiner has a saved game |
| `charback.asm` | A+B+X+Y on the character select returns to the title |
| `dropin_only.asm` | Drop-in without the prompt or saves |

Notes: [OPTIONS.md](OPTIONS.md) (screen, hooks, WRAM, SRAM), [SAVE_NOTES.md](SAVE_NOTES.md) (save format, research, rules for later versions), [DROPIN.md](DROPIN.md) (drop-in and the prompt).
