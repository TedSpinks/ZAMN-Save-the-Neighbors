# Reverse Fire and Strafe

Two small control hacks for the US version of *Zombies Ate My Neighbors*. Both use the **R button**, so pick one.

| Patch | R button |
|---|---|
| `zamn-reverse-fire.ips` | Hold R while you walk and your character turns to face (and shoot) the opposite way. Let go and you face the way you walk again. |
| `zamn-strafe.ips` | Hold R while you walk and your character keeps facing (and shooting) the same direction. Let go and facing follows the D-pad again. |

Both let you back away from a horde while you keep shooting at it. Reverse fire is simpler on the run; strafe is more flexible, since you can lock any direction and circle around enemies. R only does something while you are pressing a direction.

## Changed controls

In the original game, L and R both open the victim radar. Both patches move the radar to **Select** so R is free.

| Button | Action |
|---|---|
| R (hold) | Reverse fire, or strafe (lock facing) |
| Select | Victim radar |

The attract-mode demos keep the original controls (L and R for the radar, no reverse or strafe), so they play exactly like the original game.

## How to patch

Apply **one** of the two IPS files to a clean *Zombies Ate My Neighbors (USA)* ROM, 1 MB, no header (CRC32 `7CFC0C7C`). Don't apply both: they change the same code, so whichever goes on last wins.

## Tested combinations

| Combination | Result | How to apply |
|---|---|---|
| Reverse Fire + Strafe | Not compatible: both use R and change the same code | Pick one |
| Either + [Pause map](../pause-map/README.md) | Works | Any order |
| Either + [Drop-in](../drop-in/README.md) | Works | Any order |
| Either + Pause map + Drop-in | Works | Any order |
| Either + [Reverse Inventory Cycling v1.1](https://www.romhacking.net/hacks/4318/) | Works | Reverse Inventory first, then Reverse Fire or Strafe (in the other order Reverse Inventory puts the radar back on R, so R opens the radar too) |
| Either + [Bloody Disgusting Edition](https://www.romhacking.net/hacks/4306/) | Works | Any order |
| [Save the Neighbors Edition](../save-the-neighbors/README.md) | Already included: R is set to reverse, strafe or original in the OPTIONS menu | Use the all-in-one patch alone |

With Reverse Inventory Cycling, hold L while cycling weapons or items to cycle backward.

## Known limits

- Emulator testing only (Snes9x, bsnes, Mesen-S). Reports from real hardware are welcome, especially for two-player games and special states such as swimming or after drinking a potion.
- Holding R while standing still does nothing.

More: [TECHNICAL.md](TECHNICAL.md), [Credits](../../README.md#credits).
