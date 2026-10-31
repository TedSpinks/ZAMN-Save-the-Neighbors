# minimal 65816 disassembler for LoROM; usage: dis.py rom bank:addr count [m] [x]
import sys
M=dict(imp=0,acc=0,immm=-1,immx=-2,imm8=1,dp=1,dpx=1,dpy=1,ind=1,indx=1,indy=1,indl=1,indly=1,sr=1,sry=1,abs=2,absx=2,absy=2,absl=3,abslx=3,rel=1,rell=2,absi=2,absix=2,absil=2,bm=2)
ops={}
def A(s):
    for line in s.strip().split('\n'):
        for t in line.split(','):
            t=t.strip()
            if not t: continue
            c,n,m=t.split(); ops[int(c,16)]=(n,m)
A("""00 BRK imm8,01 ORA indx,02 COP imm8,03 ORA sr,04 TSB dp,05 ORA dp,06 ASL dp,07 ORA indl,08 PHP imp,09 ORA immm,0A ASL acc,0B PHD imp,0C TSB abs,0D ORA abs,0E ASL abs,0F ORA absl
10 BPL rel,11 ORA indy,12 ORA ind,13 ORA sry,14 TRB dp,15 ORA dpx,16 ASL dpx,17 ORA indly,18 CLC imp,19 ORA absy,1A INC acc,1B TCS imp,1C TRB abs,1D ORA absx,1E ASL absx,1F ORA abslx
20 JSR abs,21 AND indx,22 JSL absl,23 AND sr,24 BIT dp,25 AND dp,26 ROL dp,27 AND indl,28 PLP imp,29 AND immm,2A ROL acc,2B PLD imp,2C BIT abs,2D AND abs,2E ROL abs,2F AND absl
30 BMI rel,31 AND indy,32 AND ind,33 AND sry,34 BIT dpx,35 AND dpx,36 ROL dpx,37 AND indly,38 SEC imp,39 AND absy,3A DEC acc,3B TSC imp,3C BIT absx,3D AND absx,3E ROL absx,3F AND abslx
40 RTI imp,41 EOR indx,42 WDM imm8,43 EOR sr,44 MVP bm,45 EOR dp,46 LSR dp,47 EOR indl,48 PHA imp,49 EOR immm,4A LSR acc,4B PHK imp,4C JMP abs,4D EOR abs,4E LSR abs,4F EOR absl
50 BVC rel,51 EOR indy,52 EOR ind,53 EOR sry,54 MVN bm,55 EOR dpx,56 LSR dpx,57 EOR indly,58 CLI imp,59 EOR absy,5A PHY imp,5B TCD imp,5C JML absl,5D EOR absx,5E LSR absx,5F EOR abslx
60 RTS imp,61 ADC indx,62 PER rell,63 ADC sr,64 STZ dp,65 ADC dp,66 ROR dp,67 ADC indl,68 PLA imp,69 ADC immm,6A ROR acc,6B RTL imp,6C JMP absi,6D ADC abs,6E ROR abs,6F ADC absl
70 BVS rel,71 ADC indy,72 ADC ind,73 ADC sry,74 STZ dpx,75 ADC dpx,76 ROR dpx,77 ADC indly,78 SEI imp,79 ADC absy,7A PLY imp,7B TDC imp,7C JMP absix,7D ADC absx,7E ROR absx,7F ADC abslx
80 BRA rel,81 STA indx,82 BRL rell,83 STA sr,84 STY dp,85 STA dp,86 STX dp,87 STA indl,88 DEY imp,89 BIT immm,8A TXA imp,8B PHB imp,8C STY abs,8D STA abs,8E STX abs,8F STA absl
90 BCC rel,91 STA indy,92 STA ind,93 STA sry,94 STY dpx,95 STA dpx,96 STX dpy,97 STA indly,98 TYA imp,99 STA absy,9A TXS imp,9B TXY imp,9C STZ abs,9D STA absx,9E STZ absx,9F STA abslx
A0 LDY immx,A1 LDA indx,A2 LDX immx,A3 LDA sr,A4 LDY dp,A5 LDA dp,A6 LDX dp,A7 LDA indl,A8 TAY imp,A9 LDA immm,AA TAX imp,AB PLB imp,AC LDY abs,AD LDA abs,AE LDX abs,AF LDA absl
B0 BCS rel,B1 LDA indy,B2 LDA ind,B3 LDA sry,B4 LDY dpx,B5 LDA dpx,B6 LDX dpy,B7 LDA indly,B8 CLV imp,B9 LDA absy,BA TSX imp,BB TYX imp,BC LDY absx,BD LDA absx,BE LDX absy,BF LDA abslx
C0 CPY immx,C1 CMP indx,C2 REP imm8,C3 CMP sr,C4 CPY dp,C5 CMP dp,C6 DEC dp,C7 CMP indl,C8 INY imp,C9 CMP immm,CA DEX imp,CB WAI imp,CC CPY abs,CD CMP abs,CE DEC abs,CF CMP absl
D0 BNE rel,D1 CMP indy,D2 CMP ind,D3 CMP sry,D4 PEI dp,D5 CMP dpx,D6 DEC dpx,D7 CMP indly,D8 CLD imp,D9 CMP absy,DA PHX imp,DB STP imp,DC JML absil,DD CMP absx,DE DEC absx,DF CMP abslx
E0 CPX immx,E1 SBC indx,E2 SEP imm8,E3 SBC sr,E4 CPX dp,E5 SBC dp,E6 INC dp,E7 SBC indl,E8 INX imp,E9 SBC immm,EA NOP imp,EB XBA imp,EC CPX abs,ED SBC abs,EE INC abs,EF SBC absl
F0 BEQ rel,F1 SBC indy,F2 SBC ind,F3 SBC sry,F4 PEA abs,F5 SBC dpx,F6 INC dpx,F7 SBC indly,F8 SED imp,F9 SBC absy,FA PLX imp,FB XCE imp,FC JSR absix,FD SBC absx,FE INC absx,FF SBC abslx""")
fmt=dict(imp='',acc='A',immm='#${v}',immx='#${v}',imm8='#${v}',dp='${v}',dpx='${v},X',dpy='${v},Y',ind='(${v})',indx='(${v},X)',indy='(${v}),Y',indl='[${v}]',indly='[${v}],Y',sr='${v},S',sry='(${v},S),Y',abs='${v}',absx='${v},X',absy='${v},Y',absl='${v}',abslx='${v},X',absi='(${v})',absix='(${v},X)',absil='[${v}]',bm='${v}')
def off(b,a): return (b&0x7F)*0x8000+(a-0x8000)
def dis(rom,bank,addr,count,m16=True,x16=True,out=print):
    for _ in range(count):
        o=off(bank,addr); op=rom[o]; n,md=ops[op]; L=M[md]
        if L==-1: L=2 if m16 else 1
        if L==-2: L=2 if x16 else 1
        b=rom[o+1:o+1+L]; v=int.from_bytes(b,'little') if L else 0
        if md=='rel': s=f"${(addr+2+(v-256 if v>127 else v))&0xFFFF:04X}"
        elif md=='rell': s=f"${(addr+3+(v-65536 if v>32767 else v))&0xFFFF:04X}"
        elif md=='bm': s=f"${b[1]:02X},${b[0]:02X}"
        else: s=fmt[md].replace('{v}',f"{v:0{L*2}X}") if L else fmt[md]
        if n=='REP': m16=m16 or bool(v&0x20); x16=x16 or bool(v&0x10)
        if n=='SEP':
            if v&0x20: m16=False
            if v&0x10: x16=False
        out(f"{bank:02X}:{addr:04X}  {rom[o:o+1+L].hex(' '):<12} {n} {s}")
        addr+=1+L
if __name__=='__main__':
    rom=open(sys.argv[1],'rb').read(); b,a=sys.argv[2].split(':')
    dis(rom,int(b,16),int(a,16),int(sys.argv[3]),sys.argv[4]!='8' if len(sys.argv)>4 else True,sys.argv[5]!='8' if len(sys.argv)>5 else True)
