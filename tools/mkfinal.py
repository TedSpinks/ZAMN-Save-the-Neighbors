"""IPS helpers shared by the build: apply(), cs_fix() (SNES header checksum), diff_ips().
Command line: mkfinal.py patched.sfc out.ips clean.sfc  (writes the IPS and checks that it reproduces the ROM)"""
import sys
def cs_fix(r):
    r=bytearray(r); r[0x7FDC:0x7FE0]=b'\0\0\0\0'; cs=sum(r)&0xFFFF; ic=cs^0xFFFF
    r[0x7FDC:0x7FE0]=ic.to_bytes(2,'little')+cs.to_bytes(2,'little'); return r
FORCE=set(range(0x6C8,0x6CC))|set(range(0x3EF8,0x3F0A))   # sites older builds patched (fog hook, hitbox constants): always write them
def diff_ips(base,t,path):
    base=bytes(base)+b'\0'*(len(t)-len(base)); n=len(t); recs=[]; i=0
    while i<n:
        if base[i]!=t[i] or i in FORCE:
            j=i
            gap=64 if i>=0x100000 else 8   # expansion area: write complete spans (zeros included) so stale bytes from an older patch can't survive
            while j<n and j-i<0xFFF0 and (base[j]!=t[j] or j in FORCE or any(base[k]!=t[k] or k in FORCE for k in range(j+1,min(j+1+gap,n)))): j+=1
            recs.append([i,t[i:j]]); i=j
        else: i+=1
    if recs[-1][0]+len(recs[-1][1])<n: recs.append([n-1,t[n-1:n]])
    d=b'PATCH'
    for o,x in recs:
        if o==0x454f46: o-=1; x=base[o:o+1]+x
        d+=o.to_bytes(3,'big')+len(x).to_bytes(2,'big')+x
    open(path,'wb').write(d+b'EOF'); return len(recs),len(d)+3
def apply(rom,f):
    d=open(f,'rb').read(); rom=bytearray(rom); p=5
    while d[p:p+3]!=b'EOF':
        o=int.from_bytes(d[p:p+3],'big'); n=int.from_bytes(d[p+3:p+5],'big'); p+=5
        if n==0: n=int.from_bytes(d[p:p+2],'big'); v=bytes([d[p+2]])*n; p+=3
        else: v=d[p:p+n]; p+=n
        if o+n>len(rom): rom+=b'\0'*(o+n-len(rom))
        rom[o:o+n]=v
    return rom
if __name__=='__main__':
    clean=open(sys.argv[3],'rb').read()
    t=cs_fix(open(sys.argv[1],'rb').read())
    print(diff_ips(clean,t,sys.argv[2]))
    assert apply(clean,sys.argv[2])==t; print('verified')
