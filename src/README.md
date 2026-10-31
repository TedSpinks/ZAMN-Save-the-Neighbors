# Source

65816 assembly (asar) for the patches that are built from code. `build.py` assembles these on top of the input patches in `inputs/`; each patch's `TECHNICAL.md` in `patches/` says which files go into it.

| Folder | What it holds |
|---|---|
| `map/` | The pause map |
| `options/` | OPTIONS menu, saved games and high scores, drop-in co-op, join prompt, character-select back-out |
| `intro/` | Press Start to skip the boot logos |
| `demo/` | Changes that keep the attract-mode demos identical to the original (hitbox) and the character-select confirm sound |

Assemble with [asar](https://github.com/RPGHacker/asar). `asar patch.asm rom.sfc` patches the ROM file in place, so always run it on a copy; `build.py` does.
