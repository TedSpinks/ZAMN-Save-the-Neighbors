# Tools

| File | What it does |
|---|---|
| `mkfinal.py` | IPS helpers used by `build.py`: apply an IPS, fix the SNES header checksum, write an IPS as the difference between two ROMs |
| `compat.py` | Which patches can be combined: byte overlap between patches, order checks, and the combined ROMs for testing |
| `build_title_art.py`, `art.py`, `options_title_art.txt` | The OPTIONS title label art (needs Pillow) |
| `lr.py` | Headless libretro driver (ctypes) used by `tests/` |
| `asm65.py`, `dis.py` | A small 65816 assembler and disassembler used for analysis |

`build.py` needs [asar](https://github.com/RPGHacker/asar) on PATH or in this folder (`tools/asar`; the binary is not committed). See [docs/TOOLCHAIN_NOTES.md](../docs/TOOLCHAIN_NOTES.md) for how the toolchain was set up.
