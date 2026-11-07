# Reverse Fire and Strafe: technical notes

## What the patches change
Both are small IPS files for the 1 MB ROM (193 and 177 bytes). They share the same hook sites and differ only in the routine they call.

- **Direction hooks:** five sites in the player control code (`80:D255`, `D302`, `D32B`, `D353`, `D4CD`) call a routine at `9F:FFC0` (free space at the end of the ROM). The routine reads the pad (`$1A`, R is `$0010`) and the direction, and returns the facing the game should use: the opposite direction for reverse fire, or the previous facing for strafe. With no direction pressed it changes nothing.
- **Radar:** the radar checks at `80:D28E` and `80:D295` call `RadarCur` / `RadarPrev` at `83:FC40`. They test Select (`$2000`) while a game is running and the original L/R mask (`$0030`) while an attract-mode demo plays (`$1EB4` is nonzero). That is what keeps the demos identical to the original: they contain recorded L presses.
- **Legacy sites:** the IPS also writes the original bytes back at `80:86C8` and `80:BEF8-BF09`, which earlier builds of this project patched. The result is the same whether the patch goes on a clean ROM or on an older build.
- The header checksum is fixed (`80:FFDC`).

## Why Reverse Inventory Cycling must go first
Reverse Inventory Cycling also moves the radar check (`80:D28E`, `D295`). If it is applied after Reverse Fire or Strafe, it puts the radar back on R. Applied before, the patch here overwrites it. The two patches share nine bytes, seven of which differ (`tools/compat.py` lists them).

## Why not twin-stick
I considered twin-stick controls like *Smash T.V.* I could have freed up enough buttons by only letting you change weapons and items from the pause screen, but I didn't feel like twin-stick fit the game. I think it suits a frantic game where enemies overwhelm you from every side, and ZAMN doesn't play like that. What I really needed was a little room: a way to shoot enemies while running away from them. I felt like reverse fire and strafe were better ways to do that.

## Testing
- Attract-mode demos: the rendered frame, hashed every 100 frames for 40,000 frames, equals the original for both patches (Snes9x). The four demos use the original controls.
- Facing: walk left with and without R. Reverse fire flips the facing; strafe keeps it; both leave it alone without R.
- Combinations: see the table in the readme; each combined ROM was started and played on Snes9x, bsnes and Mesen-S (`tools/compat.py`).
- Not tested: real hardware.
