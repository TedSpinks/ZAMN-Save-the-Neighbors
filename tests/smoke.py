"""Quick check of a ROM: smoke.py rom.sfc features
features: d = drop-in join with pad 2, m = pause map opens and Start closes it; always checks R facing (walk left with and without R).
Panning is checked by pan.py: level 1 fits the map window, so it cannot scroll there."""
import sys, os
from harness import *
import hashlib
rom,feat=sys.argv[1],sys.argv[2]
c=boot(rom); out=[]
def fb(): return hashlib.md5(c.fb[3]).hexdigest()
c.tap(A,3,200); c.run(60); c.tap(ST,3,200); c.run(700)
out.append(('slots',rd(c,0x1E88),rd(c,0x1E8A)))
if 'd' in feat:
    c.pad[1]=ST; c.run(8); c.pad[1]=0; c.run(400); out.append(('after join',rd(c,0x1E88),rd(c,0x1E8A)))
if 'm' in feat:
    c.tap(ST,3,60); c.run(40); h0=fb(); c.tap(SEL,3,60); c.run(60); h1=fb()
    out.append(('map opened',h0!=h1))
    c.tap(ST,10,80); c.run(60)      # Start closes the map and unpauses
    h3=fb(); c.pad[0]=1<<7; c.run(60); c.pad[0]=0; h4=fb()
    out.append(('back in game and moving',h3!=h4))
# R button direction check: face vs walk
c.pad[0]=1<<6; c.run(30); d1=(rd(c,0x124),rd(c,0x126)); 
c.pad[0]=(1<<6)|(1<<11); c.run(30); d2=(rd(c,0x124),rd(c,0x126)); c.pad[0]=0
out.append(('walk-left facing / with R',d1,d2))
c.shot(TMP+'/sm_%s.png'%feat)
print(feat,out)
