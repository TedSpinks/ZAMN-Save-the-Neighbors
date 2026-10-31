# Pause map

`map.asm` is the whole pause map: it runs inside the pause loop (bank `BE`, from `inputs/third_party/zamn_pause_2mb.ips`), draws the level at one pixel per tile with fog of war, victims, the exit door and a legend, pans with the D-pad, and shows lives in the pause HUD. `tint/tint.asm` holds the per-level color table.

Design notes and findings: [patches/pause-map/TECHNICAL.md](../../patches/pause-map/TECHNICAL.md) and [docs/DEMO_NOTES.md](../../docs/DEMO_NOTES.md) (fog, exit door, scrolling, radar dimming).
