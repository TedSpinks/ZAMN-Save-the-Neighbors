"""Join prompt on Save the Neighbors: joinprompt.py rom.sfc make|resume|cancel|new
'make' plays Julie through level 1 and writes the fixture TMP/fx_julie.sram; the other modes boot with it, join player 2 and answer the prompt (RESUME, CANCEL, NEW GAME + yes)."""
import sys, os
from harness import *
rom=sys.argv[1]; mode=sys.argv[2]
if mode=='make':      # Julie plays level 1 alone (SELECT swaps on the character select), completes it: her record is saved
    c=boot(rom); c.tap(A,3,200); c.run(60); c.tap(SEL,3,60); c.run(20); c.tap(ST,3,200); c.run(600)
    poke(c,0x1E72,bytes.fromhex('00770000')); poke(c,0x1D52,(0).to_bytes(2,'little')); poke(c,0x1F9C,(1).to_bytes(2,'little')); poke(c,0x1FB8,(1).to_bytes(2,'little')); c.run(1500)
    s=bytes(c.mem(0,0,0x2000)); open(TMP+'/fx_julie.sram','wb').write(s); print('who',rd(c,0x1E84),rd(c,0x1E86),'rec0 valid',s[0x208],'rec1 valid',s[0x200+0x74],'level',rd(c,0x1E7C)); sys.exit()
def tp(c,m,h=3,w=60):
    c.pad[1]=m; c.run(h); c.pad[1]=0; c.run(w)
c=boot(rom,open(TMP+'/fx_julie.sram','rb').read())
c.tap(A,3,200); c.run(60); c.tap(ST,3,200); c.run(700)
out={'p1 char':(rd(c,0x1E84),rd(c,0x1E86))}
f=rd(c,0x20); c.pad[1]=ST; c.run(6); c.pad[1]=0; c.run(120)
out['prompt frozen']=rd(c,0x20)==f or abs(rd(c,0x20)-f)<8
c.shot(TMP+'/jpx_%s_prompt.png'%os.environ.get('CORE','s9x').split('/')[-1][:5])
if mode=='resume':
    tp(c,A,3,60); c.run(30); print('after pick',rd(c,0x1E88),rd(c,0x1E8A)); c.run(300)
elif mode=='cancel':
    tp(c,DN,3,30); tp(c,DN,3,30); tp(c,A,3,60); c.run(300)
elif mode=='new':
    tp(c,DN,3,30); tp(c,A,3,60); c.run(30); tp(c,A,3,60); c.run(300)       # NEW GAME, SURE? yes
out['slots']=(rd(c,0x1E88),rd(c,0x1E8A)); out['p2 score']=bytes(c.ram(0x1E76,4)).hex()
out['running']=rd(c,0x20)!=f
out['sram rec1 valid']=bytes(c.mem(0,0x200+0x74,1))[0]
print(os.environ.get('CORE','snes9x').split('/')[-1],mode,out)
