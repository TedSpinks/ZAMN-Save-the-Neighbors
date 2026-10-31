"""Saved games on Save the Neighbors: saves.py rom.sfc [battery.sram|-] [resume]
No 'resume': plays level 1, completes it through the exit conditions and prints the SRAM record. With a battery file and 'resume': picks RESUME GAME in OPTIONS and prints the loaded state."""
import sys, os
from harness import *
rom=sys.argv[1]; fx=sys.argv[2] if len(sys.argv)>2 else None
c=boot(rom, open(fx,'rb').read() if fx and fx!='-' else None)
sr=lambda a,n: bytes(c.mem(0,a,n))
res={}
if len(sys.argv)>3 and sys.argv[3]=='resume':
    # RESUME GAME from OPTIONS: B opens the resume list, B picks the top entry, Start leaves
    to_options(c); c.run(40); c.tap(B,3,100); c.tap(B,3,100); c.run(120); c.tap(ST,3,200); c.run(700)
    rec=sr(0x200,0xE0)
    res['magic']=rec[:4]; res['active']=(rd(c,0x1E88),rd(c,0x1E8A)); res['level']=rd(c,0x1E7C); res['lives']=(rd(c,0x1F9C),rd(c,0x1F9E)); res['score']=bytes(c.ram(0x1E72,4)).hex()
    res['ammo']=bytes(c.ram(0x1CCC,8)).hex()
else:
    c.tap(A,3,200); c.run(60); c.tap(ST,3,200); c.run(600)
    poke(c,0x1E72,bytes.fromhex('12345600')); poke(c,0x1CCC,bytes.fromhex('2a00110022003300'))
    lvl0=rd(c,0x1E7C); poke(c,0x1D52,(0).to_bytes(2,'little')); poke(c,0x1F9C,(1).to_bytes(2,'little')); poke(c,0x1FB8,(1).to_bytes(2,'little')); c.run(1500)
    rec=sr(0x200,0xE0)
    res['level before/after']=(lvl0,rd(c,0x1E7C)); res['magic']=rec[:4]; res['version']=rec[4]
    z=rec[8:8+0x6C]; res['valid']=z[0]; res['rec level']=int.from_bytes(z[2:4],'little'); res['rec score']=z[0x64:0x68].hex(); res['rec ammo']=z[0x30:0x38].hex()
    res['copy2 same']=sr(0x200,0xE0)==sr(0x300,0xE0)
print(os.path.basename(os.environ.get('CORE','snes9x')),res)
open(TMP+'/sv_dump_%s.sram'%os.path.basename(os.environ.get('CORE','snes9x')),'wb').write(bytes(c.mem(0,0,0x2000))) if not (len(sys.argv)>3) else None
