#!/usr/bin/env python3
"""Compatibility checks between the release patches and the third-party patches they were tested with.

    python3 tools/compat.py /path/to/clean.sfc [outdir]      (run build.py first: it writes the patches to out/)

1. Byte overlap: for every pair of IPS files, the bytes both change. No differing overlap means the pair gives the same ROM
   in either order; a differing overlap means the order matters, or the pair cannot be combined. The header checksum is
   left out (every patch carries its own; the console and emulators do not check it).
2. Writes the combined ROMs listed in COMBOS (applied in the order given) to outdir/compat/, so they can be boot-tested.
"""
import sys, os, itertools
HERE = os.path.dirname(os.path.abspath(__file__)); ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from mkfinal import apply

OUT = os.path.join(ROOT, 'out')
PATCHES = {'fire': 'zamn-reverse-fire.ips', 'strafe': 'zamn-strafe.ips', 'map': 'zamn-pause-map.ips', 'dropin': 'zamn-drop-in.ips',
           'aio': 'zamn-save-the-neighbors.ips'}
EXTERNAL = {'RI': 'inputs/third_party/reverse_inventory_cycling_v1.1.ips', 'Blood': 'inputs/third_party/bloody_disgusting_edition.ips'}
CHECKSUM = range(0x7FDC, 0x7FE0)
COMBOS = [('RI', 'fire'), ('RI', 'strafe'), ('RI', 'fire', 'map', 'dropin'), ('RI', 'strafe', 'map', 'dropin', 'Blood'), ('RI', 'map'), ('RI', 'dropin'), ('RI', 'map', 'dropin'),
          ('fire', 'Blood'), ('strafe', 'Blood'), ('map', 'Blood'), ('dropin', 'Blood'), ('fire', 'map'), ('fire', 'dropin'), ('strafe', 'map'), ('strafe', 'dropin'),
          ('map', 'dropin'), ('fire', 'map', 'dropin'), ('strafe', 'map', 'dropin'), ('RI', 'fire', 'map', 'dropin', 'Blood')]
ANY_ORDER = [('fire', 'map', 'dropin'), ('strafe', 'map', 'dropin'), ('fire', 'Blood'), ('map', 'Blood'), ('dropin', 'Blood'), ('map', 'dropin'), ('RI', 'map', 'dropin'), ('RI', 'Blood')]

def path(k): return os.path.join(OUT, PATCHES[k]) if k in PATCHES else os.path.join(ROOT, EXTERNAL[k])

def changes(f):
    d = open(f, 'rb').read(); p = 5; m = {}
    while d[p:p + 3] != b'EOF':
        o = int.from_bytes(d[p:p + 3], 'big'); n = int.from_bytes(d[p + 3:p + 5], 'big'); p += 5
        if n == 0: n = int.from_bytes(d[p:p + 2], 'big'); b = bytes([d[p + 2]]) * n; p += 3
        else: b = d[p:p + n]; p += n
        for i, x in enumerate(b): m[o + i] = x
    return m

def build(clean, order):
    r = bytearray(clean)
    for k in order: r = apply(r, path(k))
    return bytes(r)

def no_checksum(r):
    r = bytearray(r)
    for i in CHECKSUM: r[i] = 0
    return bytes(r)

if __name__ == '__main__':
    if len(sys.argv) < 2: raise SystemExit(__doc__)
    clean = open(sys.argv[1], 'rb').read()
    out = OUT = sys.argv[2] if len(sys.argv) > 2 else OUT
    names = list(PATCHES) + list(EXTERNAL); ch = {k: changes(path(k)) for k in names}
    print('pair   shared bytes   differing')
    for a, b in itertools.combinations(names, 2):
        shared = [x for x in ch[a] if x in ch[b] and x not in CHECKSUM]
        print('%-5s %-5s %6d %6d' % (a, b, len(shared), sum(ch[a][x] != ch[b][x] for x in shared)))
    for c in ANY_ORDER:
        same = len({no_checksum(build(clean, p)) for p in itertools.permutations(c)}) == 1
        print('any order' if same else 'ORDER MATTERS', ' + '.join(c))
    for p in ('fire', 'strafe'):
        print('Reverse Inventory first matters for', p, no_checksum(build(clean, ('RI', p))) != no_checksum(build(clean, (p, 'RI'))))
    os.makedirs(os.path.join(out, 'compat'), exist_ok=True)
    for c in COMBOS: open(os.path.join(out, 'compat', '+'.join(c) + '.sfc'), 'wb').write(build(clean, c))
