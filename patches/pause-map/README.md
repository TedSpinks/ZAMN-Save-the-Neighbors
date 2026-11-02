# Pause map

Pausing is much more useful now. The pause patch from [ZAMN: Splitscreen + Quality of Life](https://www.romhacking.net/hacks/10134/) by AuroraBorealis lets you change your weapon and item while the game is paused (B or A for the next one, Y or X for the previous one). This patch is built on it, and adds your remaining lives to the pause screen, shown as a heart and a number (♥ n) where your score normally is. See [Credits](../../README.md#credits).

Then press **Select** for the auto-map:

- It starts empty and fills in as you explore, so you can see where you've been. Colors follow each level.
- Both players appear as blinking markers (red for player 1, cyan for player 2).
- Neighbors you've found show up in green, and a counter tells you how many are still left to save.
- The exit door appears once the last neighbor is rescued.
- On big levels the D-pad scrolls the map (hold to repeat), with arrows showing which way there is more.
- **Select** goes back to the pause screen; **Start** closes the map and unpauses.

## How to patch

Apply `zamn-pause-map.ips` to a clean *Zombies Ate My Neighbors (USA)* ROM, 1 MB, no header (CRC32 `7CFC0C7C`). The patch expands the ROM to 2 MB.

## Tested combinations

| Combination | Result | How to apply |
|---|---|---|
| [Reverse Fire or Strafe](../reverse-fire-strafe/README.md) | Works | Any order |
| [Drop-in](../drop-in/README.md) | Works | Any order |
| Reverse Fire or Strafe + Drop-in | Works | Any order |
| [Reverse Inventory Cycling v1.1](https://www.romhacking.net/hacks/4318/) | Works | Any order |
| [Bloody Disgusting Edition](https://www.romhacking.net/hacks/4306/) | Works | Any order |
| [Save the Neighbors Edition](../save-the-neighbors/README.md) | Already included | Use the all-in-one patch alone |

## Known limits

- Emulator testing only (Snes9x, bsnes, Mesen-S).
- A one-frame tap of Select can be missed; press it normally.

More: [TECHNICAL.md](TECHNICAL.md), [Credits](../../README.md#credits).
