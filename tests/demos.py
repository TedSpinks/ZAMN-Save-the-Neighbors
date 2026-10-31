"""Frame-hash check of the attract-mode demos: demos.py rom.sfc out.txt [checkpoints]
Hashes the frame every 100 frames (default 400 checkpoints = 40,000 frames). Run it on the clean ROM and on a patched ROM and
diff the two files: they must be identical for every patch that promises demo-safe behavior."""
import sys, hashlib
from harness import *
c = boot(sys.argv[1], None, frames=0); hs = []; n = int(sys.argv[3]) if len(sys.argv) > 3 else 400
for i in range(n):
    c.run(100); hs.append(hashlib.md5(c.fb[3]).hexdigest()[:8])
open(sys.argv[2], 'w').write('\n'.join(hs)); print('done', len(hs))
