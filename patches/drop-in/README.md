# Drop-in co-op

Press **Start on the idle pad** at any moment of a level and a second player joins the running game.

- The join happens once the player already in the game is alive, on the ground, and walking, standing or shooting (within about 3 seconds, otherwise it is dropped). The newcomer appears at the other player's position as a fresh player: default health, lives, weapon, item and ammo, score 0.
- Start on an empty pad only joins; it does not pause. A Start still held when a level starts, or pressed in the first 1.5 seconds after a level starts or the game is unpaused, is ignored until released, so skipping a between-level screen does not join anyone.
- A player who ran out of lives cannot come back on the same level; the next level allows it.
- Attract-mode demos are untouched.

This patch has no save prompt. The [Save the Neighbors Edition](../save-the-neighbors/README.md) asks RESUME, NEW GAME or CANCEL when the joining character has a saved game.

## How to patch

Apply `zamn-drop-in.ips` to a clean *Zombies Ate My Neighbors (USA)* ROM, 1 MB, no header (CRC32 `7CFC0C7C`). The patch expands the ROM to 2 MB.

## Tested combinations

| Combination | Result | How to apply |
|---|---|---|
| [Reverse Fire or Strafe](../reverse-fire-strafe/README.md) | Works | Any order |
| [Pause map](../pause-map/README.md) | Works | Any order |
| Reverse Fire or Strafe + Pause map | Works | Any order |
| [Reverse Inventory Cycling v1.1](https://www.romhacking.net/hacks/4318/) | Works | Any order |
| [Bloody Disgusting Edition](https://www.romhacking.net/hacks/4306/) | Works | Any order |
| [Save the Neighbors Edition](../save-the-neighbors/README.md) | Not compatible: Save the Neighbors has its own version with the join prompt | Use the all-in-one patch alone |

## Known limits

- Emulator testing only (Snes9x, bsnes, Mesen-S).
- Mashing Start on the idle pad for longer than the grace period into a level can still start a join.
- The pause screen still accepts Start from either pad to unpause; only the pause check is gated.
- Hurt, dying, carried or item-animation states delay the join.

More: [TECHNICAL.md](TECHNICAL.md), [Credits](../../README.md#credits).
