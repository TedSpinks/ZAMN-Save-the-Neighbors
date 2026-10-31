"""Pan the pause map on a level larger than the map window: pan.py rom.sfc battery.sram
Uses a saved-game fixture (joinprompt.py make) that resumes at level 2, opens the map and reports, per direction, whether the map's scroll position changed."""
import sys, os
from harness import *
rom=sys.argv[1]; fx=open(sys.argv[2],'rb').read()
c=boot(rom,fx)
to_options(c); c.run(40); c.tap(B,3,100); c.tap(B,3,100); c.run(120); c.tap(ST,3,200); c.run(700)
g=lambda a: rd(c,0x10000+(a&0xFFFF))
pos=lambda: (g(0xFCE8),g(0xFCEA))
print('level',rd(c,0x1E7C),'slots',rd(c,0x1E88),rd(c,0x1E8A))
c.tap(ST,3,60); c.run(40); c.tap(SEL,3,60); c.run(60)
print('wc,hc',g(0xFC8C),g(0xFC8E),'start',pos())
out=[]
for name,b in [('R',R),('DN',DN),('UP',UP),('L',L),('R',R),('R',R),('DN',DN),('UP',UP),('L',L),('L',L)]:
    p0=pos(); c.pad[0]=b; c.run(40); c.pad[0]=0; c.run(30); out.append((name,p0!=pos()))
print(out)
