# Menu art helpers: green PASSWORD cells in bank 8E (ROM), screen coords from the title state.
ROMBASE=0xE*0x8000-0x8000
CELLS=[(180,199,0x8B80),(196,194,0x8C00),(212,191,0x8C80),(228,186,0x8D00),(244,183,0x8D80)]  # (x,y,rom addr)
def decode(rom,addr):
    im=[[0]*16 for _ in range(16)]
    for q,(dx,dy) in enumerate(((0,0),(8,0),(0,8),(8,8))):
        b=rom[ROMBASE+addr+q*32:ROMBASE+addr+q*32+32]
        for y in range(8):
            for x in range(8):
                s=7-x; im[dy+y][dx+x]=(b[2*y]>>s&1)|(b[2*y+1]>>s&1)<<1|(b[16+2*y]>>s&1)<<2|(b[17+2*y]>>s&1)<<3
    return im
def encode(im):
    out=bytearray()
    for dx,dy in ((0,0),(8,0),(0,8),(8,8)):
        p=[bytearray(8) for _ in range(4)]
        for y in range(8):
            for x in range(8):
                v=im[dy+y][dx+x]
                for pl in range(4):
                    if v>>pl&1: p[pl][y]|=0x80>>x
        for y in range(8): out+=bytes([p[0][y],p[1][y]])
        for y in range(8): out+=bytes([p[2][y],p[3][y]])
    return bytes(out)
def layer(rom,cells=CELLS,W=100,H=60,ox=170,oy=165):
    L=[[0]*W for _ in range(H)]
    for x,y,a in cells:
        im=decode(rom,a)
        for j in range(16):
            for i in range(16):
                if im[j][i]: L[y-oy+j][x-ox+i]=im[j][i]
    return L
def slice_back(L,cells=CELLS,ox=170,oy=165):
    out=[]
    for x,y,a in cells:
        out.append(encode([[L[y-oy+j][x-ox+i] for i in range(16)] for j in range(16)]))
    return out
