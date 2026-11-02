"""Builds ZAMN_OptionsTitleArt.ips: the PASSWORD title label art becomes OPTIONS (bank 8E, file 0x70B80..0x70E7F).
The art is the hand-finished picture in options_title_art.txt (the title's own sprite cells, see art.py).
usage: build_title_art.py clean.sfc out.ips [rom_to_patch.sfc]   (the optional ROM gets the same bytes written, for combined builds)"""
import sys; sys.path.insert(0,'.')
import art, asm65
clean=open(sys.argv[1],'rb').read(); rom=bytearray(clean)
V={'.':0,'#':4,'o':5,'x':6,'_':8}
rows=[l.rstrip('\n') for l in open('options_title_art.txt') if not l.startswith('#')]
L=[[0]*100 for _ in range(60)]
for j,r in enumerate(rows):
    for i,c in enumerate(r): L[18+j][i]=V[c]
lit={(x,y) for y in range(60) for x in range(100) if L[y][x]}
for dx,dy in ((-1,2),(0,2),(-1,1)):                      # drop shadow, same shape as the original letters'
    for x,y in lit:
        if 0<=x+dx<100 and 0<=y+dy<60 and (x+dx,y+dy) not in lit: L[y+dy][x+dx]=8
for (cx,cy,a),data in zip(art.CELLS,art.slice_back(L)): rom[art.ROMBASE+a:art.ROMBASE+a+0x80]=data
# The sixth chunk (8E:8E00) is drawn twice by the original label: sprite list 8F:E889 (count, then 8-byte entries x, y, ?,
# tile), entries 2 and 5, at (213,175) and (180,183), carrying the tops of PASSWORD's O and A. Entry 5 is moved onto entry 2,
# so the chunk shows once, at (213,175), and carries the art there (the top of the N's left stem, above cell 3).
EXTRA=(213,175,0x8E00)
rom[art.ROMBASE+0x8E00:art.ROMBASE+0x8E00+0x80]=art.slice_back(L,[EXTRA])[0]
e5=(0x8F&0x7F)*0x8000+(0xE889-0x8000)+1+4*8
assert clean[e5:e5+4]==bytes([0xDF,0xFF,0xEF,0xFF])            # entry 5: x -33, y -17
rom[e5:e5+4]=bytes([0x00,0x00,0xE7,0xFF])                      # same as entry 2: x 0, y -25
patch={i:rom[i] for i in range(len(rom)) if rom[i]!=clean[i]}
open(sys.argv[2],'wb').write(asm65.ips_from(patch)); print(len(patch),"bytes changed, ips written")
if len(sys.argv)>3:
    t=bytearray(open(sys.argv[3],'rb').read())
    for i,v in patch.items(): t[i]=v
    open(sys.argv[3],'wb').write(t)
