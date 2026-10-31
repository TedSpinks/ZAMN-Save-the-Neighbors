"""Headless libretro driver: Core(so, rom).run(frames, pad=0) ; .ram(addr,n) reads WRAM; .shot(path)"""
import ctypes as C, sys
from ctypes import *
class Info(Structure): _fields_=[("path",c_char_p),("data",c_void_p),("size",c_size_t),("meta",c_char_p)]
class AV(Structure): _fields_=[("w",c_uint),("h",c_uint),("mw",c_uint),("mh",c_uint),("ar",c_float)]
class Tim(Structure): _fields_=[("fps",c_double),("sr",c_double)]
class Geo(Structure): _fields_=[]
class SAV(Structure): _fields_=[("geo",c_byte*20),("tim",Tim)]
ENV=C.CFUNCTYPE(c_bool,c_uint,c_void_p); VID=C.CFUNCTYPE(None,c_void_p,c_uint,c_uint,c_size_t)
AUD=C.CFUNCTYPE(None,c_int16,c_int16); AUDB=C.CFUNCTYPE(c_size_t,c_void_p,c_size_t)
POLL=C.CFUNCTYPE(None); INP=C.CFUNCTYPE(c_int16,c_uint,c_uint,c_uint,c_uint)
class Core:
    def __init__(s,so,rom):
        s.l=CDLL(so); s.pad=[0,0]; s.fb=None; s.fmt=2; s.vars={}
        s._env=ENV(s.env); s._vid=VID(s.vid); s._aud=AUD(lambda a,b:None); s._audb=AUDB(lambda d,n:n)
        s._poll=POLL(lambda:None); s._inp=INP(s.inp)
        late='mesen' in so.lower()      # Mesen-S creates its renderer in retro_load_game: the callbacks go in after it
        def cbs():
            s.l.retro_set_video_refresh(s._vid); s.l.retro_set_audio_sample(s._aud); s.l.retro_set_audio_sample_batch(s._audb)
            s.l.retro_set_input_poll(s._poll); s.l.retro_set_input_state(s._inp)
        s.l.retro_set_environment(s._env)
        if not late: cbs()
        s.l.retro_init()
        s.data=open(rom,'rb').read(); s.buf=C.create_string_buffer(s.data,len(s.data))
        i=Info(rom.encode(),cast(s.buf,c_void_p),len(s.data),None); assert s.l.retro_load_game(byref(i))
        if late: cbs()
        s.l.retro_get_memory_data.restype=c_void_p; s.l.retro_get_memory_size.restype=c_size_t
    def env(s,cmd,p):
        if cmd==10: s.fmt=cast(p,POINTER(c_uint))[0]; return True      # SET_PIXEL_FORMAT
        if cmd==3: cast(p,POINTER(c_bool))[0]=True; return True
        if cmd in(9,31): cast(p,POINTER(c_char_p))[0]=b'/tmp'; return True
        if cmd==15:
            import os
            k=cast(p,POINTER(c_char_p))[0]
            for kv in os.environ.get('SETV','').split(','):
                if '=' in kv and kv.split('=')[0].encode()==k:
                    s.vars[k]=kv.split('=')[1].encode(); cast(p,POINTER(c_char_p))[1]=s.vars[k]; return True
            return False
        return False
    def vid(s,d,w,h,pitch):
        if d: s.fb=(w,h,pitch,string_at(d,h*pitch))
    def inp(s,port,dev,idx,id_):
        if dev!=1 or port>1: return 0
        return 1 if (s.pad[port]>>id_)&1 else 0
    def run(s,n,pad=None):
        if pad is not None: s.pad[0]=pad
        for _ in range(n): s.l.retro_run()
    def mem(s,kind,addr,n):
        p=s.l.retro_get_memory_data(kind); return string_at(p+addr,n)
    def ram(s,a,n=1): return s.mem(2,a,n)       # RETRO_MEMORY_SYSTEM_RAM
    def sram(s,a,n=1): return s.mem(0,a,n)
    def shot(s,path):
        from PIL import Image
        w,h,p,d=s.fb; im=Image.new('RGB',(w,h))
        px=im.load()
        for y in range(h):
            row=d[y*p:(y+1)*p]
            for x in range(w):
                if s.fmt==2: v=row[2*x]|row[2*x+1]<<8; px[x,y]=((v>>11&31)*255//31,(v>>5&63)*255//63,(v&31)*255//31)
                elif s.fmt==0: v=row[2*x]|row[2*x+1]<<8; px[x,y]=((v>>10&31)*255//31,(v>>5&31)*255//31,(v&31)*255//31)
                else: px[x,y]=(row[4*x+2],row[4*x+1],row[4*x])
        im.save(path)
# joypad ids: B0 Y1 SEL2 START3 UP4 DOWN5 LEFT6 RIGHT7 A8 X9 L10 R11

def _save(s):
    n=s.l.retro_serialize_size(); b=C.create_string_buffer(n); assert s.l.retro_serialize(b,n); return b.raw
def _load(s,data):
    b=C.create_string_buffer(data,len(data)); assert s.l.retro_unserialize(b,len(data))
Core.save=_save; Core.load=_load
def _tap(s,mask,hold=3,wait=20):
    s.run(hold,pad=mask); s.run(wait,pad=0)
Core.tap=_tap
