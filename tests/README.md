# Tests

Scenario scripts that drive a ROM headless in a libretro SNES core and check what the game does. They are how the claims in the patch `TECHNICAL.md` files were checked. They need:

- Python 3 with Pillow (screenshots);
- a libretro core `.so` for Snes9x, bsnes or Mesen-S, selected with the `CORE` environment variable (`ZAMN_TMP` sets where screenshots and fixtures go). Cores are not in this repository;
- a patched ROM from `python3 build.py` (and, for comparisons, the clean ROM).

| Script | What it checks |
|---|---|
| `smoke.py` | Boots, starts a game, optionally joins player 2 and opens/closes the pause map, and checks R facing |
| `pan.py` | Pan the pause map on a level that is larger than the map window |
| `saves.py` | Level-end save and RESUME GAME (Save the Neighbors) |
| `joinprompt.py` | The RESUME / NEW GAME / CANCEL prompt when the joiner has a saved game |
| `backout.py` | A+B+X+Y back-out from the character select |
| `demos.py` | Frame hashes of the attract-mode demos, to compare a patched ROM with the clean one |
| `harness.py` | The shared helpers (boot, memory reads, pad masks) |

Example, on each core in turn:

```
CORE=/path/to/snes9x_libretro.so python3 tests/smoke.py out/rom.sfc dm
```

`tools/compat.py` checks which patches can be combined (see the root `TECHNICAL.md`). The stack-depth measurement was made with a bsnes core patched to count stack use, which is not part of this repository.
