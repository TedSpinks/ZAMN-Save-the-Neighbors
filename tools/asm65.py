"""asm65.py - small two-pass 65816 assembler for SNES LoROM hacks.
Syntax: labels `name:`, `.local` labels, `name = expr`, `org $9FFFC0` (24-bit SNES addr),
db/dw/dl/ds, `.a8 .a16 .i8 .i16` (REP/SEP also tracked), `;` comments, `#<x #>x #^x`,
operand forms of the standard 65816 syntax. Force size with suffix: lda.b / lda.w / lda.l.
Size rule: literal <$100 -> direct page, <$10000 -> absolute, else long; labels -> absolute
(long for JSL/JML). Output: {file_offset: bytes} for LoROM, plus symbol table."""
import re, sys
from dis import ops as OPS, M as LEN
T = {}
for op, (n, m) in OPS.items(): T.setdefault(n, {})[m] = op
def snes2off(a): return ((a >> 16) & 0x7F) * 0x8000 + ((a & 0xFFFF) - 0x8000)
class AsmError(Exception): pass
def ev(expr, sym, loc, pc):
    e = expr.strip(); pre = None
    if e[:1] in '<>^' : pre, e = e[0], e[1:]
    e = re.sub(r'\$([0-9A-Fa-f]+)', lambda m: str(int(m.group(1), 16)), e)
    e = re.sub(r'%([01]+)', lambda m: str(int(m.group(1), 2)), e)
    unresolved = []
    def name(m):
        n = m.group(0)
        if n == '*': return str(pc)
        k = loc + n if n.startswith('.') else n
        if k in sym: return str(sym[k])
        unresolved.append(k); return '0'
    e = re.sub(r"\.?[A-Za-z_][A-Za-z_0-9]*|\*(?![\d(])", name, e)
    v = int(eval(e, {"__builtins__": {}}, {}))
    if pre == '<': v &= 0xFF
    elif pre == '>': v = (v >> 8) & 0xFF
    elif pre == '^': v = (v >> 16) & 0xFF
    return v, bool(unresolved), bool(re.search(r"[A-Za-z_]", expr.replace('$', '').replace('0x', '')) and not re.fullmatch(r"[<>^]?\s*\$?[0-9A-Fa-f]+", expr.strip()))
def parse_operand(s):
    s = s.strip()
    if s == '': return 'imp', None
    if s.upper() == 'A': return 'acc', None
    if s[0] == '#': return 'imm', s[1:]
    m = re.fullmatch(r"\(\s*(.+?)\s*,\s*[sS]\s*\)\s*,\s*[yY]", s)
    if m: return 'sry', m.group(1)
    m = re.fullmatch(r"\[\s*(.+?)\s*\]\s*,\s*[yY]", s)
    if m: return 'indly', m.group(1)
    m = re.fullmatch(r"\[\s*(.+?)\s*\]", s)
    if m: return 'indl', m.group(1)
    m = re.fullmatch(r"\(\s*(.+?)\s*,\s*[xX]\s*\)", s)
    if m: return 'indx', m.group(1)
    m = re.fullmatch(r"\(\s*(.+?)\s*\)\s*,\s*[yY]", s)
    if m: return 'indy', m.group(1)
    m = re.fullmatch(r"\(\s*(.+?)\s*\)", s)
    if m: return 'ind', m.group(1)
    m = re.fullmatch(r"(.+?)\s*,\s*[sS]", s)
    if m: return 'sr', m.group(1)
    m = re.fullmatch(r"(.+?)\s*,\s*[xX]", s)
    if m: return 'x', m.group(1)
    m = re.fullmatch(r"(.+?)\s*,\s*[yY]", s)
    if m: return 'y', m.group(1)
    if re.fullmatch(r"(.+?)\s*,\s*(.+)", s) and re.search(r"\w\s*,\s*[$\w]", s): return 'bm', s
    return 'plain', s
class Asm:
    def __init__(self): self.sym = {}; self.out = {}
    def run(self, src):
        for pas in (1, 2):
            self.pc = 0; self.loc = ''; self.m16 = False; self.x16 = False; self.out = {}; self.pas = pas
            for n, line in enumerate(src.split('\n'), 1):
                try: self.line(line)
                except AsmError as ex: raise AsmError(f"line {n}: {ex}: {line.strip()}")
                except Exception as ex: raise AsmError(f"line {n}: {type(ex).__name__} {ex}: {line.strip()}")
        return self.out
    def emit(self, bs):
        if self.pas == 2:
            o = snes2off(self.pc)
            for i, b in enumerate(bs): self.out[o + i] = b & 0xFF
        self.pc += len(bs)
    def val(self, e): 
        v, unres, isname = ev(e, self.sym, self.loc, self.pc)
        if unres and self.pas == 2: raise AsmError("undefined symbol in " + e)
        return v, isname
    def line(self, line):
        line = line.split(';')[0].strip()
        if not line: return
        m = re.match(r"^(\.?[A-Za-z_][A-Za-z_0-9]*)\s*:\s*(.*)$", line)
        if m:
            name = m.group(1)
            if name.startswith('.'): name = self.loc + name
            else: self.loc = name
            if self.pas == 1 and name in self.sym: raise AsmError("duplicate label " + name)
            self.sym[name] = self.pc; line = m.group(2).strip()
            if not line: return
        m = re.match(r"^([A-Za-z_][A-Za-z_0-9]*)\s*=\s*(.+)$", line)
        if m: self.sym[m.group(1)] = self.val(m.group(2))[0]; return
        p = line.split(None, 1); mn = p[0].lower(); rest = p[1] if len(p) > 1 else ''
        if mn == 'org': self.pc = self.val(rest)[0]; return
        if mn in ('.a8', '.a16', '.i8', '.i16'):
            if mn[1] == 'a': self.m16 = mn == '.a16'
            else: self.x16 = mn == '.i16'
            return
        if mn in ('db', 'dw', 'dl'):
            w = {'db': 1, 'dw': 2, 'dl': 3}[mn]
            for part in re.split(r",(?![^()]*\))", rest):
                part = part.strip()
                if part.startswith('"'):
                    for ch in part.strip('"'): self.emit([ord(ch)])
                else:
                    v = self.val(part)[0]; self.emit([(v >> (8 * i)) & 0xFF for i in range(w)])
            return
        if mn == 'ds': self.emit([0] * self.val(rest)[0]); return
        force = None
        if '.' in mn and mn.split('.')[1] in 'bwl': mn, force = mn.split('.'); 
        N = mn.upper()
        if N not in T: raise AsmError("unknown mnemonic " + mn)
        modes = T[N]; kind, e = parse_operand(rest)
        if kind == 'imp':
            md = 'imp' if 'imp' in modes else 'acc' if 'acc' in modes else None
            if md is None: raise AsmError("needs operand")
            self.emit([modes[md]]); return
        if kind == 'acc':
            if 'acc' not in modes: raise AsmError("no accumulator mode"); 
            self.emit([modes['acc']]); return
        if kind == 'imm':
            v = self.val(e)[0]
            if 'imm8' in modes: L = 1
            elif 'immm' in modes: L = 2 if self.m16 else 1
            elif 'immx' in modes: L = 2 if self.x16 else 1
            else: raise AsmError("no immediate mode")
            md = 'imm8' if 'imm8' in modes else 'immm' if 'immm' in modes else 'immx'
            if N == 'REP': self.m16 |= bool(v & 0x20); self.x16 |= bool(v & 0x10)
            if N == 'SEP':
                if v & 0x20: self.m16 = False
                if v & 0x10: self.x16 = False
            if N == 'PEA': pass
            self.emit([modes[md]] + [(v >> (8 * i)) & 0xFF for i in range(L)]); return
        if kind == 'bm':
            a, b = [x.strip() for x in e.split(',')]
            self.emit([modes['bm'], self.val(b)[0] & 0xFF, self.val(a)[0] & 0xFF]); return   # MVN src,dst -> dst,src bytes
        v, isname = self.val(e)
        if kind in ('sr', 'sry', 'indx', 'indy', 'ind', 'indl', 'indly') :
            cand = {'sr': ['sr'], 'sry': ['sry'], 'indl': ['indl', 'absil'], 'indly': ['indly'],
                    'indx': ['indx', 'absix'], 'indy': ['indy'], 'ind': ['ind', 'absi']}[kind]
            if kind in ('indx', 'ind', 'indl') and (isname or v > 0xFF) : cand = cand[::-1]
            md = next((c for c in cand if c in modes), None)
            if md is None: raise AsmError("bad addressing mode for " + N)
            L = LEN[md]; self.emit([modes[md]] + [(v >> (8 * i)) & 0xFF for i in range(L)]); return
        if kind == 'plain' and ('rel' in modes or 'rell' in modes):
            md = 'rel' if 'rel' in modes else 'rell'
            L = LEN[md]; base = self.pc + 1 + L; d = (v - (base & 0xFFFF)) if v <= 0xFFFF else (v - base)
            if L == 2: d = ((d + 0x8000) & 0xFFFF) - 0x8000
            if self.pas == 2 and not (-128 <= d <= 127 if L == 1 else -32768 <= d <= 32767): raise AsmError(f"branch out of range ({d})")
            self.emit([modes[md]] + [(d >> (8 * i)) & 0xFF for i in range(L)]); return
        sfx = {'plain': '', 'x': 'x', 'y': 'y'}[kind]
        order = {'b': ['dp'], 'w': ['abs'], 'l': ['absl']}.get(force)
        if order is None:
            if N in ('JSL', 'JML') or (isname and N in ('JSR','JMP')): order = ['absl', 'abs']
            elif isname: order = ['abs', 'absl', 'dp']
            else: order = ['dp', 'abs', 'absl'] if v < 0x100 else ['abs', 'absl'] if v < 0x10000 else ['absl']
            if N in ('JSL','JML'): order = ['absl']
            if N in ('JSR','JMP'): order = ['abs'] if not (v > 0xFFFF and not isname) else ['absl']
        for o in order:
            md = o + sfx
            if md in modes:
                L = LEN[md]; self.emit([modes[md]] + [(v >> (8 * i)) & 0xFF for i in range(L)]); return
        raise AsmError(f"no mode {order}{sfx} for {N}")
def ips_from(patches, rom=None):
    offs = sorted(patches); recs = []; i = 0
    while i < len(offs):
        j = i
        while j + 1 < len(offs) and offs[j + 1] == offs[j] + 1: j += 1
        start = offs[i]; data = bytes(patches[o] for o in range(start, offs[j] + 1))
        for k in range(0, len(data), 0xFFFF):
            ch = data[k:k+0xFFFF]; s = start + k
            if s == 0x454F46: raise AsmError("EOF offset")
            recs.append(s.to_bytes(3, 'big') + len(ch).to_bytes(2, 'big') + ch)
        i = j + 1
    return b'PATCH' + b''.join(recs) + b'EOF'
