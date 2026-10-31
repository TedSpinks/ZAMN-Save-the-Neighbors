# Demo safety and small changes

Attract-mode demos replay recorded input, so any change in timing, collision or button meaning makes them drift. See [docs/DEMO_NOTES.md](../../docs/DEMO_NOTES.md).

| File | What it does |
|---|---|
| `hitbox_demo.asm` | Keeps the original 16-pixel collision box while a demo plays, and uses the 24-pixel box (+50%) in normal play |
| `charselect.asm` | Character select confirm plays the password-confirm sound instead of the evil laugh |

Both are part of the main patch only.
