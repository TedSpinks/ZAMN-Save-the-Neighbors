"""Shared helpers for the emulator scenario scripts: boots a ROM in a libretro core and drives it headless.

Environment:
  CORE      path to a libretro SNES core (snes9x, bsnes or Mesen-S .so). Required.
  ZAMN_TMP  directory for screenshots and fixture files (default: the system temp directory).
"""
import os, sys, ctypes, tempfile
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))
from lr import Core

TMP = os.environ.get('ZAMN_TMP', tempfile.gettempdir())
B, Y, SEL, ST, UP, DN, L, R, A, X = [1 << i for i in range(10)]   # pad masks in libretro joypad id order (B0 Y1 Select2 Start3 Up4 Down5 Left6 Right7 A8 X9)

def boot(rom, sram=None, frames=2400):
    """Start rom, optionally with a battery file, and run past the logos to the title."""
    core = os.environ.get('CORE')
    if not core: raise SystemExit('set CORE to a libretro core (.so)')
    c = Core(core, rom)
    if 'bsnes' in core: c.fmt = 0          # this core never sets a pixel format: 0RGB1555
    if sram is not None: ctypes.memmove(c.l.retro_get_memory_data(0), sram, len(sram))
    c.run(frames); return c

def rd(c, a, k=2):
    """Little-endian WRAM read. WRAM is 128 KB: bank 7F addresses are at 0x10000 + offset (7F:FC0A is 0x1FC0A)."""
    return int.from_bytes(c.ram(a, k), 'little')

def poke(c, addr, data): ctypes.memmove(c.l.retro_get_memory_data(2) + addr, data, len(data))

def to_options(c):
    c.run(2, pad=DN); c.run(20); c.tap(A, 3, 200)
