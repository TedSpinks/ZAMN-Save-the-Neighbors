# ZAMN: Save the Neighbors Edition!

A ROM hack for *Zombies Ate My Neighbors* (SNES) with a saved run for each player, drop-in co-op, a full auto-map, and reverse fire.

- **Save the game!** Zeke and Julie each keep their own run, saved after every level. Resume either one or both, play solo or together, and mix it up whenever you like. High scores are saved too, and passwords still work!
- **Drop-in co-op!** The second player joins any time by pressing Start, and can bring their own run along!
- **A full auto-map!** Pause, press Select, and the level fills in as you explore, like the maps in Metroidvanias and Dead Cells. Find every victim without getting lost!
- **Reverse fire or strafe on R!** Hold R to shoot backward while you run away, or to lock your aim in place. Pairs perfectly with [Reverse Inventory Cycling](https://www.romhacking.net/hacks/4318/) on L (included).

Includes both an all-in-one patch and separate patches: take everything, pick just the features you want, or mix them with other mods.

## Save and OPTIONS

A new **OPTIONS** entry on the title menu holds everything Save the Neighbors adds.

| Row | Action |
|---|---|
| RESUME GAME | Pick a saved game (ZEKE, JULIE or BOTH) |
| PASSWORD | The game's password screen |
| TOP SCORES | The high score table |
| ERASE DATA | Hold A+B+X+Y+Start for about 2 seconds to erase scores and saved games |
| R REVERSE / STRAFE / ORIGINAL | Left/Right changes the R setting |
| EXIT | Back to the title |

Each save is one run, written whenever you finish a level. When a run is over, so is its save: it's erased on game over, or when a player runs out of lives in co-op. It uses 8 KB of battery RAM, so flash carts need SRAM enabled.

## Pause map

Pausing is much more useful now. The pause patch from [ZAMN: Splitscreen + Quality of Life](https://www.romhacking.net/hacks/10134/) by AuroraBorealis (included) lets you change your weapon and item while the game is paused (B or A for the next one, Y or X for the previous one), which is super helpful.

Save the Neighbors also shows your remaining lives on the pause screen, as `REST n` where your score normally is.

Then press **Select** for the auto-map. It starts empty and fills in as you explore, so you can always see where you've been. Both players appear as blinking markers (red for player 1, cyan for player 2). Victims you've found show up in green, a counter tells you how many are still left to save, and the exit door appears once the last one is rescued. On big levels the D-pad scrolls the map. **Select** goes back to the pause screen, and **Start** closes the map and unpauses.

Stuck? The map has a cheat that reveals the unexplored parts of the level. The button combo is in [CHEAT.txt](https://github.com/TedSpinks/ZAMN-Save-the-Neighbors/blob/main/CHEAT.txt).

## Drop-in co-op

Press Start on the second pad during a one-player game and the second character joins right where you are. If that character has a saved run, a prompt lets them bring it along (RESUME), start fresh (NEW GAME, which replaces the save only when the next level ends) or CANCEL.

A drop-in player who resumes keeps everything from their saved run: health, lives, weapons, ammo, items and score. They join the level you're on, and their save updates to that level when you finish it. If their saved level is higher than yours, you may prefer to start over from OPTIONS → RESUME GAME → BOTH, which starts you both on the higher level.

## Reverse fire and strafe

Hold **R** while you walk to shoot backward (reverse fire) or to lock your aim in place (strafe). Choose reverse fire, strafe or the original controls on the OPTIONS screen. The victim radar moves to **Select**. The new controls are switched off during the attract-mode demos; otherwise they break the recordings.

## Everything in the all-in-one patch

The all-in-one patch has all of the above, plus:

- **[Reverse Inventory Cycling](https://www.romhacking.net/hacks/4318/):** hold L while cycling weapons or items to go backward.
- **[Bloody Disgusting Edition](https://www.romhacking.net/hacks/4306/):** restores the blood on the Game Over screen.
- **Bigger hitbox:** items, neighbors and shots are 50% easier to hit, an idea from [Zombies Ate My Neighbors DX](https://github.com/JamesIV4/zombies-ate-my-neighbors-dx).

## Patching

You need a clean *Zombies Ate My Neighbors (USA)* ROM: 1 MB, no header, CRC32 `7CFC0C7C` (SHA-1 `1be79496d7a38b293d6a5d9fba0e16f3cb37d5ff`). Use any IPS patcher, such as [Floating IPS](https://www.romhacking.net/utilities/1040/) or [MultiPatch](https://www.romhacking.net/utilities/746/).

**Pick one:**

- `zamn-save-the-neighbors.ips`: the all-in-one patch, with everything included. Apply it alone; it already contains every individual patch below.
- Or any of the individual patches from `individual/`:

| File | Adds |
|---|---|
| `zamn-reverse-fire.ips` | Hold R to shoot backward while you run away |
| `zamn-strafe.ips` | Hold R to lock your aim in place (don't combine with reverse fire) |
| `zamn-pause-map.ips` | Pause map and weapon/item cycling while paused |
| `zamn-drop-in.ips` | Drop-in co-op, without the join prompt or saves |

Saved runs, the OPTIONS screen and the join prompt are only in the all-in-one patch. The individual patches work without them.

Reverse fire or strafe, the pause map and drop-in work together in any order. Details, including how to combine them with Reverse Inventory Cycling and the Bloody Disgusting Edition, are in the [patch readmes](patches/README.md).

## More details

[TECHNICAL.md](TECHNICAL.md) has the patched ROM checksums, how everything was tested, design notes and the version history.

## Credits

- **Zombies Ate My Neighbors** by LucasArts and Konami. This repository contains no game data, only patches.
- **Pause patch:** changing weapons and items while paused comes from [ZAMN: Splitscreen + Quality of Life](https://www.romhacking.net/hacks/10134/) by AuroraBorealis, and the pause map is built on it.
- **[Reverse Inventory Cycling v1.1](https://www.romhacking.net/hacks/4318/)** by Stanley_Decker and Sloat, included.
- **[Zombies Ate My Neighbors: Bloody Disgusting Edition](https://www.romhacking.net/hacks/4306/)** by Board_Avenger, included.
- **Bigger hitbox:** the +50% hitbox idea and collision routine come from JamesIV4's [Zombies Ate My Neighbors DX](https://github.com/JamesIV4/zombies-ate-my-neighbors-dx).
- **Tools:** [asar](https://github.com/RPGHacker/asar) by RPGHacker builds the code. Testing was done on Snes9x, bsnes (byuu / Near and contributors) and Mesen-S (Sour).

This is an unofficial fan project. It is not affiliated with or endorsed by the original developers or publishers.
