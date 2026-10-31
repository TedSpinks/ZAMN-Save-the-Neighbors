"""Character-select back-out (A+B+X+Y) on Save the Neighbors: backout.py rom.sfc loop|race|three|opts
loop = repeated back-outs on either pad then a normal start; race = back-out at different moments around the 900-frame timeout; three = three-button combinations must be ignored; opts = back-out after visiting OPTIONS."""
import sys, os
from harness import *
def regs(c):
    st=bytes(c.save()); i=st.find(b'REG:'); b=i+11
    blk=st[b:b+16]; return int.from_bytes(blk[14:16],'big')
def hung(c):
    import os
    if os.environ.get('CORE'):
        sn=[]
        for i in range(4):
            c.run(15); c.shot(TMP+'/h.png'); sn.append(open(TMP+'/h.png','rb').read())
        return len(set(sn))==1
    n=0
    for i in range(30):
        c.run(1); pc=regs(c)
        if 0xCCC8<=pc<=0xCCDD: n+=1
    return n>=25
def title_ok(c):
    c.shot(TMP+'/st_t.png'); from PIL import Image
    im=Image.open(TMP+'/st_t.png').convert('RGB'); w,h=im.size
    px=im.resize((64,56)).getdata()
    red=sum(1 for p in px if p[0]>150 and p[1]<60 and p[2]<60)
    return red>300      # the red spiral fills the title
def to_title(c): c.run(1500)
def backout(c,pad=0,btn=A|B|X|Y):
    c.pad[pad]=btn; c.run(20); c.pad[pad]=0
sc=sys.argv[2]; c=boot(sys.argv[1]); res=[]
if sc=='loop':
    for i in range(int(os.environ.get("N","25"))):
        c.tap(A,3,200); c.run(60+(i*37)%200); backout(c,i&1); to_title(c)
        res.append(title_ok(c))
    c.tap(A,3,200); c.run(60); c.tap(ST,3,200); c.run(900)

    res.append(not hung(c))
elif sc=='race':
    for d in (2,5,10,200,850,880,895,899,905,930):
        c.tap(A,3,200); c.run(d); backout(c); to_title(c)
        r=title_ok(c)
        if not r:   # may have gone to demo via timeout instead: wait for it to come back
            c.run(6000); r=title_ok(c)
        res.append((d,r,not hung(c)))
elif sc=='three':
    c.tap(A,3,200); c.run(60)
    for m in (A|B|X,A|B|Y,B|X|Y,A|X|Y): c.pad[0]=m; c.run(30); c.pad[0]=0; c.run(30)
    c.shot(TMP+'/st_s.png'); res.append('select still up: see st_s.png')
elif sc=='opts':
    c.run(2,pad=DN); c.run(20); c.tap(A,3,200); c.run(120); c.tap(ST,3,200); c.run(300)
    c.tap(A,3,200); c.run(60); backout(c); to_title(c); res.append(title_ok(c)); res.append(not hung(c))
    c.tap(A,3,200); c.run(60); c.tap(ST,3,200); c.run(600); res.append(not hung(c))
print(sc,res)
