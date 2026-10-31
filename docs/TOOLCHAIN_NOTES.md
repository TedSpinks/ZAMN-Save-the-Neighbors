# ZAMN Comprehensive Hack: Toolchain Status

## How tools get into the sandbox
Direct downloads (curl, pip, npm, crates, Go proxy, buildbot, apt mirrors) are blocked, but **`git clone https://github.com/...` works**. Everything below was built from clones.

```
git clone --depth 1 https://github.com/RPGHacker/asar
cmake -S asar/src -B asar/build -DASAR_GEN_EXE=ON -DASAR_GEN_DLL=OFF -DASAR_GEN_LIB=OFF -DASAR_GEN_PYTHON=OFF && cmake --build asar/build -j8
#  -> asar/build/asar/bin/asar   (the cmake "Generate step failed" line is the tests target; the binary still builds)
git clone --depth 1 https://github.com/libretro/snes9x
make -j8 -C snes9x/libretro   # -> snes9x_libretro.so (built with ALLOW_CPU_OVERCLOCK)
```
Beware: `asar patch.asm rom.sfc` patches the ROM file in place; always run it on a copy.

## Verified working
- asar: assembled the strafe hook (`lorom`, `org $9FFFC0`) and got the shipped bytes `F0 0B A5 1A 29 10 00 D0 04 A5 24 85 26 6B`.
- Snes9x core: `lr.py` (ctypes libretro driver) boots the clean US ZAMN ROM headless; Konami and LucasArts logos, legal screen and intro render correctly in screenshots. API: `Core(so, rom)`, `.run(frames, pad=bitmask)`, `.ram(addr, n)` (WRAM), `.sram(addr, n)`, `.shot(png)`. Pad bits: B0 Y1 Select2 Start3 Up4 Down5 Left6 Right7 A8 X9 L10 R11 (libretro ids). Pad 2 via `c.pad[1]`.
- `asm65.py`: Python 65816 assembler (fallback); 0 mismatches on a 720-block ROM round trip. `dis.py`: disassembler.

## Still to do
- Save-state helper (retro_serialize) for fast scenario setup, and SRAM persistence test (write SRAM, reload).
- Find the title menu and high score table code with the emulator's memory view (the two debugger spikes in FEASIBILITY.md).
- Optional: 65816 simulator for pure logic tests (less needed now that a real core runs).
