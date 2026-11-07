#!/usr/bin/env python3
"""Builds every ZAMN release patch from a clean ROM.

    python3 build.py /path/to/Zombies_Ate_My_Neighbors_USA.sfc [outdir]

Builds the Save the Neighbors Edition plus the individual patches (reverse fire, strafe, pause map, drop-in) and packs them into one release zip.
Each IPS is the difference between the clean ROM and that build, so the patches that need the 2 MB ROM carry identical
expansion / header bytes and can be applied in any order where they do not touch the same code.
Needs: asar (tools/asar or on PATH), Python 3, Pillow (title art only).
"""
import sys, os, re, subprocess, shutil, zlib, hashlib, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, 'tools'))
from mkfinal import apply, cs_fix, diff_ips

CLEAN_CRC32 = 0x7CFC0C7C                      # Zombies Ate My Neighbors (USA), 1 MB, no header
CLEAN_SHA1 = '1be79496d7a38b293d6a5d9fba0e16f3cb37d5ff'
ASAR = os.path.join(HERE, 'tools', 'asar')
if not os.path.exists(ASAR): ASAR = shutil.which('asar')
TP = os.path.join(HERE, 'inputs', 'third_party'); CT = os.path.join(HERE, 'inputs', 'controls')

def asar(rom, src):
    p = subprocess.run([ASAR, src, rom], capture_output=True, text=True)
    if p.returncode: raise SystemExit('asar failed on %s:\n%s%s' % (src, p.stdout, p.stderr))

def expand(r):
    """2 MB LoROM: size byte, zero fill, and the final byte the other expansion patch writes ($FF), so every patch agrees."""
    r = bytearray(r); r[0x7FD7] = 0x0B
    if len(r) < 0x200000: r += b'\0' * (0x200000 - len(r))
    r[0x1FFFFF] = 0xFF
    return r

def plain_links(text):
    """Links between the repository's files don't work inside a zip: keep the link text, drop the target."""
    return re.sub(r'\[([^\]]+)\]\((?!https?://)[^)]*\)', r'\1', text)

def build_all(cleanpath, outdir):
    clean = open(cleanpath, 'rb').read()
    if zlib.crc32(clean) != CLEAN_CRC32 or hashlib.sha1(clean).hexdigest() != CLEAN_SHA1:
        raise SystemExit('this is not the clean Zombies Ate My Neighbors (USA) 1 MB ROM (CRC32 %08X expected)' % CLEAN_CRC32)
    os.makedirs(outdir, exist_ok=True)
    tmp = tempfile.mkdtemp(prefix='zamn_build_')
    results = {}

    def finish(name, rom):
        rom = cs_fix(rom)
        path = os.path.join(outdir, name + '.ips')
        n, size = diff_ips(clean, rom, path)
        assert apply(clean, path) == rom, 'IPS does not reproduce the build: ' + name
        results[name] = (size, '%08X' % zlib.crc32(bytes(rom)))
        open(os.path.join(tmp, name + '.sfc'), 'wb').write(rom)
        return rom

    def asm(rom, *srcs):
        f = os.path.join(tmp, 'work.sfc'); open(f, 'wb').write(rom)
        for s in srcs: asar(f, os.path.join(HERE, s))
        return bytearray(open(f, 'rb').read())

    # reverse fire and strafe: the controls patches (hooks in the 1 MB ROM, no menu, demo-safe)
    finish('zamn-reverse-fire', apply(clean, os.path.join(CT, 'ZAMN_ReverseFire.ips')))
    finish('zamn-strafe', apply(clean, os.path.join(CT, 'ZAMN_Strafe.ips')))

    # pause map = the Split+QoL pause loop (2 MB, bank BE) + the map
    r = apply(clean, os.path.join(TP, 'zamn_pause_2mb.ips'))
    r = asm(r, 'src/map/map.asm')
    finish('zamn-pause-map', r)

    # drop-in without saves or prompt
    r = asm(expand(clean), 'src/options/dropin_only.asm')
    finish('zamn-drop-in', r)

    # Save the Neighbors Edition, everything: Reverse Fire + Hitbox 150 + Reverse Inventory + Blood, pause loop, map, skip intro, hitbox demo guard,
    #    options / saves / drop-in / join prompt / back-out (options.asm), character select sound, title art
    r = apply(clean, os.path.join(CT, 'combo_rf_hitbox_ri_blood.ips'))
    r = apply(r, os.path.join(TP, 'zamn_pause_2mb.ips'))
    r = asm(r, 'src/map/map.asm', 'src/intro/skipintro.asm', 'src/demo/hitbox_demo.asm', 'src/options/options.asm', 'src/demo/charselect.asm')
    f = os.path.join(tmp, 'work.sfc'); open(f, 'wb').write(r)
    art = os.path.join(tmp, 'title_art.ips')
    subprocess.run([sys.executable, 'build_title_art.py', os.path.abspath(cleanpath), art, f], cwd=os.path.join(HERE, 'tools'), check=True, capture_output=True)
    r = apply(open(f, 'rb').read(), art)
    finish('zamn-save-the-neighbors', r)

    # one release zip: the main patch at the top, the individual patches in individual/, the README, the cheat file and the CRCs of the results
    import zipfile
    individual = ['zamn-reverse-fire', 'zamn-strafe', 'zamn-pause-map', 'zamn-drop-in']
    main = 'zamn-save-the-neighbors'
    with zipfile.ZipFile(os.path.join(outdir, main + '-v1.0.0.zip'), 'w', zipfile.ZIP_DEFLATED) as z:
        z.write(os.path.join(outdir, main + '.ips'), main + '.ips')
        for n in individual: z.write(os.path.join(outdir, n + '.ips'), 'individual/' + n + '.ips')
        z.writestr('README.md', plain_links(open(os.path.join(HERE, 'README.md')).read()))
        z.write(os.path.join(HERE, 'CHEAT.txt'), 'CHEAT.txt')
        z.writestr('CHECKSUMS.txt', 'Apply to Zombies Ate My Neighbors (USA), 1 MB, no header (CRC32 %08X, SHA-1 %s).\n' % (CLEAN_CRC32, CLEAN_SHA1) +
                   ''.join('%s%s.ips -> patched ROM CRC32 %s\n' % ('' if n == main else 'individual/', n, results[n][1]) for n in [main] + individual))
    for k, (size, crc) in results.items(): print('%-24s %6d bytes   result CRC32 %s' % (k + '.ips', size, crc))
    return tmp

if __name__ == '__main__':
    if len(sys.argv) < 2: raise SystemExit(__doc__)
    t = build_all(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, 'out'))
    print('patched ROMs for testing:', t)
