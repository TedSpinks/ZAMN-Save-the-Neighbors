; ZAMN 2P drop-in, a joiner who has a saved game: a prompt (RESUME / NEW GAME / CANCEL) before the join is armed.  Assembled as
; part of options.asm, after dropin.asm (same bank).
;
; The game is frozen while the prompt is up: the pause check does not return (NMI off, own frame loop, own joypad reads - the
; way the pause map works).  The picture is dimmed like the pause screen (palettes 0-15 and 32-255 halved, the HUD palettes stay
; bright) and the text goes on the HUD layer (BG3), tilemap rows 11-15.  Everything touched (CGRAM, those tilemap rows, two
; tiles) is saved first and put back afterwards.  Only the joiner's pad is read.
;
; Result: 0 cancel, 1 resume the save, 2 start fresh (the save is replaced when the level ends, not before).

!pcg    = $7FE400               ; CGRAM backup (512)
!ptm    = $7FE600               ; HUD tilemap rows 9-17 backup (576)
!pimg   = $7FE840               ; the 9 rows being shown (576)
!ptile  = $7FEA80               ; backup of the two tiles drawn here (32)
!pdum   = $7FEB40               ; VRAM reads need a dummy read first (see DetectVram in map.asm)
!pcur   = $7FEB42               ; cursor row 0-2
!pmode  = $7FEB44               ; 0 menu, 1 "SURE?"
!pph    = $7FEB46               ; frame counter (blink)
!pbl    = $7FEB48               ; blink phase
!pprev  = $7FEB4A               ; pad of the previous frame
!pres   = $7FEB4C               ; result, $FFFF = still choosing
!plvl   = $7FEB4E               ; saved level
!plif   = $7FEB50               ; saved lives
!pchr   = $7FEB52               ; 0 Zeke, 1 Julie
!pat    = $7FEB54               ; attribute for PutS
!pnew   = $7FEB56               ; buttons newly pressed
!ptmo   = $7FEB58               ; frames left before the prompt gives up
!pdirty = $7FEB5A               ; the text has to be drawn again
!pbat   = $7FEB5C               ; attribute of a blinking word
!pt     = $7FEB5E
!pq     = $7FEB60

PROW    = 9                     ; first HUD tilemap row used
NROWS   = 9                     ; title, blank, RESUME, blank, NEW GAME, blank, CANCEL, blank, SURE?
LCOL    = 4                     ; left column of the text; the cursor sits 2 columns after the end of NEW GAME  REPLACES SAVE
PTMO    = 1800                  ; frames (30 s) before the prompt gives up and cancels
HEARTCH = 261                   ; the two tiles: VRAM word $4800 + (char - 256) * 8, free on every level
ARROWCH = 262
HEARTV  = $4828
ORANGE  = $3C00                 ; tilemap attributes: HUD palette 7 (orange) ...
BRIGHT  = $3000                 ; ... palette 4 (bright yellow while the prompt is up) ...
REDP    = $3800                 ; ... palette 6 (the heart) ...
; Only colors 16-31 (the 2-bit layer's palettes 4-7) may be changed: colors 0-15 are shared with the playfield's own 16-color
; palette 0 (level 23 draws its ground with colors 12-15, so recoloring them turned the picture to noise), palettes 5-7 are the
; HUD's (palette 6 also colors the weapon and item icons), palette 4 is the only free one.

; carry set when the character of the slot in !jslot has a saved game
NeedPrompt:
        jsl SaveStatus                  ; 1 Zeke, 2 Julie, 7 both
        pha
        lda.l !jslot
        tax
        lda.l $7E1E84,x
        bne +
        lda.w #1
        bra ++
+       lda.w #2
++      sta.l !pt
        pla
        and.l !pt
        beq +
        sec
        rts
+       clc
        rts

; -> A = 0 cancel, 1 resume, 2 start fresh
JoinPrompt:
        rep #$30
        phb
        phd
        jsr PInfo
        pea.w $8080
        plb
        plb
        pea.w $0000
        pld
        lda.b $E0                       ; scratch of the text writer
        pha
        lda.b $E2
        pha
        sep #$20
        lda.b #$01
        sta.w $4200                     ; NMI off, auto-joypad on
        lda.b #$80
        sta.w $2100                     ; forced blank
        stz.w $420C                     ; HDMA off
        rep #$30
        jsr PDetect
        jsr PSave
        jsr PPal
        jsr PTiles
        lda.w #0
        sta.l !pcur
        sta.l !pmode
        sta.l !pph
        sta.l !pbl
        sta.l !pdirty
        lda.w #$FFFF
        sta.l !pres
        lda.w #PTMO
        sta.l !ptmo
        jsr PRead
        sta.l !pprev                    ; whatever is held now has to be released first
        jsr PBuild
        jsr PUpload
        sep #$20
        lda.b #$0F
        sta.w $2100
        rep #$20
.frame: jsr PWait
        jsr PRead
        jsr PInput
        lda.l !pres
        cmp.w #$FFFF
        bne .done
        lda.l !ptmo
        dec a
        sta.l !ptmo
        bne +
        lda.w #0                        ; nobody answered: cancel
        sta.l !pres
        bra .done
+       lda.l !pph
        inc a
        sta.l !pph
        and.w #7
        bne +
        lda.l !pbl
        eor.w #1
        sta.l !pbl
        lda.w #1
        sta.l !pdirty
+       lda.l !pdirty
        beq .frame
        lda.w #0
        sta.l !pdirty
        jsr PBuild                      ; (too slow for the vblank: built first, sent at the start of the next one)
        jsr PWait
        jsr PUpload
        bra .frame
.done:  sep #$20
        lda.b #$80
        sta.w $2100
        rep #$20
        jsr PRestore
        sep #$20
        lda.b #$81
        sta.w $4200                     ; NMI on: the game puts the screen back on
        rep #$20
        pla
        sta.b $E2
        pla
        sta.b $E0
        pld
        plb
        lda.l !pres
        rts

; the saved level and lives of the joiner's character
PInfo:  phb
        jsr Prep
        plb
        lda.l !jslot
        tax
        lda.l $7E1E84,x
        beq +
        lda.w #1
+       sta.l !pchr
        jsr RecBase
        tax
        lda.l !SAV+2,x
        cmp.w #100
        bcc +
        lda.w #99
+       sta.l !plvl
        lda.l !SAV+$2A,x
        cmp.w #100
        bcc +
        lda.w #99
+       sta.l !plif
        rts

; wait for the start of vblank and the end of the automatic joypad read
; The automatic read does not start at the first dot of vblank (about dot 33 of the next scanline on hardware, and an accurate emulator
; models that), so a "busy is clear" test made straight after the vblank flag can pass before the read has begun and the pad
; registers are read stale or half shifted. Wait (a bounded few dozen polls) for busy to go up first, then for it to go down.
PWait:  sep #$20
.a:     lda.w $4212
        bmi .a
.b:     lda.w $4212
        bpl .b
        phx
        ldx.w #$0030
.c:     lda.w $4212
        and.b #$01
        bne .d
        dex
        bne .c
.d:     lda.w $4212
        and.b #$01
        bne .d
        plx
        rep #$20
        rts

PRead:  lda.l !jslot
        tax
        lda.w $4218,x
        rts

; A = pad -> cursor, answer
PInput: sta.l !pnew
        lda.l !pprev
        eor.w #$FFFF
        and.l !pnew
        pha
        lda.l !pnew
        sta.l !pprev
        pla
        sta.l !pnew                     ; newly pressed buttons
        lda.l !pmode
        bne .ask
        lda.l !pnew
        and.w #$2400                    ; Down / Select: next row
        beq .up
        lda.l !pcur
        inc a
        cmp.w #3
        bcc +
        lda.w #0
+       sta.l !pcur
        bra .dirty
.up:    lda.l !pnew
        and.w #$0800
        beq .pick
        lda.l !pcur
        dec a
        bpl +
        lda.w #2
+       sta.l !pcur
        bra .dirty
.pick:  lda.l !pnew
        and.w #$D0C0                    ; B Y A X or Start
        beq .rts
        lda.l !pcur
        beq .resume
        cmp.w #1
        beq .sure
        lda.w #0                        ; CANCEL
        sta.l !pres
        rts
.resume: lda.w #1
        sta.l !pres
        rts
.sure:  lda.w #1
        sta.l !pmode
        bra .dirty
.ask:   lda.l !pnew                     ; SURE?  A yes, B no
        and.w #$0080
        beq +
        lda.w #2
        sta.l !pres
        rts
+       lda.l !pnew
        and.w #$8000
        beq .rts
        lda.w #0
        sta.l !pmode
.dirty: lda.w #1
        sta.l !pdirty
.rts:   rts

; A = ascii -> A = tile
Tile:   cmp.w #$20
        bne +
        lda.w #0
        rts
+       cmp.w #$3F
        bne +
        lda.w #171
        rts
+       cmp.w #$41
        bcs .letter
        clc
        adc.w #7-$30                    ; digits: 0 = char 7
        rts
.letter: clc
        adc.w #144-$41                  ; A = char 144
        rts

; X = byte offset in !pimg, the string at [$E0], attribute in !pat -> X after the last character
PutS:   ldy.w #0
.l:     sep #$20
        lda [$E0],y
        rep #$20
        and.w #$00FF
        beq .end
        phy
        jsr Tile
        ora.l !pat
        sta.l !pimg,x
        inx
        inx
        ply
        iny
        bra .l
.end:   rts

; A = 0-99, X = byte offset in !pimg, attribute in !pat: the number without a leading zero
PutNum: cmp.w #100
        bcc +
        lda.w #99
+       ldy.w #0
-       cmp.w #10
        bcc +
        sbc.w #10
        iny
        bra -
+       pha
        tya
        beq .units
        clc
        adc.w #7
        ora.l !pat
        sta.l !pimg,x
        inx
        inx
.units: pla
        clc
        adc.w #7
        ora.l !pat
        sta.l !pimg,x
        inx
        inx
        rts

; A = row 0-2 -> A = the attribute of its words: the cursor's row blinks, in SURE? mode NEW GAME stays bright
SelAttr: sta.l !pt
        lda.l !pmode
        beq .menu
        lda.l !pt
        cmp.w #1
        bne .orange
        lda.w #BRIGHT
        rts
.menu:  lda.l !pcur
        cmp.l !pt
        bne .orange
        lda.l !pbat
        rts
.orange: lda.w #ORANGE
        rts

macro ps(str, offs)
        ldx.w #<str>
        stx.b $E0
        ldx.w #<offs>
        jsr PutS
endmacro

PBuild: ldx.w #0
        lda.w #0
-       sta.l !pimg,x
        inx
        inx
        cpx.w #NROWS*64
        bne -
        lda.w #$00BF                    ; the strings are in this bank
        sta.b $E2
        lda.l !pbl
        beq +
        lda.w #BRIGHT
        bra ++
+       lda.w #ORANGE
++      sta.l !pbat
        lda.w #BRIGHT                   ; the title names the joiner, in the highlight palette
        sta.l !pat
        lda.l !pchr
        bne .julie
        %ps(StZeke, (0*32+LCOL+7)*2)
        bra .rows
.julie: %ps(StJulie, (0*32+LCOL+7)*2)
.rows:  lda.w #0
        jsr SelAttr
        sta.l !pat
        %ps(StResume, (2*32+LCOL)*2)
        lda.w #ORANGE
        sta.l !pat
        %ps(StLevel, (2*32+LCOL+10)*2)
        lda.l !plvl
        jsr PutNum
        inx
        inx
        lda.w #HEARTCH|REDP
        sta.l !pimg,x
        inx
        inx
        lda.l !plif
        jsr PutNum
        lda.w #1
        jsr SelAttr
        sta.l !pat
        %ps(StNew, (4*32+LCOL)*2)
        lda.w #ORANGE
        sta.l !pat
        %ps(StReplaces, (4*32+LCOL+10)*2)
        lda.w #2
        jsr SelAttr
        sta.l !pat
        %ps(StCancel, (6*32+LCOL)*2)
        lda.l !pmode
        beq .arrow
        lda.l !pbat                     ; SURE?
        sta.l !pat
        %ps(StSure, (8*32+LCOL+4)*2)
        lda.w #ORANGE
        sta.l !pat
        %ps(StYesNo, (8*32+LCOL+9)*2)
.arrow: lda.l !pcur                     ; the cursor, at the right edge like OPTIONS
        inc a
        asl a                           ; text rows are 2 tilemap rows apart
        asl a
        asl a
        asl a
        asl a
        asl a
        asl a
        clc
        adc.w #(LCOL+24)*2
        tax
        lda.l !pbat
        ora.w #ARROWCH
        sta.l !pimg,x
        rts

; the text rows to VRAM
PUpload: sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #$6400+(PROW*32)
        sta.w $2116
        sep #$20
        lda.b #$01
        sta.w $4370
        lda.b #$18
        sta.w $4371
        rep #$20
        lda.w #!pimg&$FFFF
        sta.w $4372
        sep #$20
        lda.b #$7F
        sta.w $4374
        rep #$20
        lda.w #NROWS*64
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
        rts

; VRAM reads need a dummy read first on some hardware and emulators: find out as the pause map does (VRAM word $4800 is free)
PDetect: sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #$4800
        sta.w $2116
        lda.w #$A5C3
        sta.w $2118
        lda.w #$3C5A
        sta.w $2118
        lda.w #$1234
        sta.w $2118
        lda.w #$4800
        sta.w $2116
        sep #$20
        lda.w $2139
        sta.l !pq
        lda.w $213A
        sta.l !pq+1
        lda.w $2139
        sta.l !pq+2
        lda.w $213A
        sta.l !pq+3
        rep #$20
        lda.l !pq
        cmp.w #$A5C3
        bne .need
        lda.l !pq+2
        cmp.w #$3C5A
        bne .need
        lda.w #0
        bra .st
.need:  lda.w #1
.st:    sta.l !pdum
        rts

; A = VRAM word address, X = 7F offset, Y = words: VRAM -> WRAM
RdVram: sta.w $2116
        sep #$20
        lda.l !pdum
        beq .l
        lda.w $2139
        lda.w $213A
.l:     lda.w $2139
        sta.l $7F0000,x
        inx
        lda.w $213A
        sta.l $7F0000,x
        inx
        dey
        bne .l
        rep #$20
        rts

; A = VRAM word address, X = 7F offset, Y = words: WRAM -> VRAM
WrVram: sta.w $2116
.l:     lda.l $7F0000,x
        sta.w $2118
        inx
        inx
        dey
        bne .l
        rts

PSave:  sep #$20
        lda.b #$80
        sta.w $2115
        stz.w $2121
        rep #$30
        ldx.w #0
.c:     sep #$20
        lda.w $213B
        sta.l !pcg,x
        inx
        lda.w $213B
        sta.l !pcg,x
        inx
        rep #$20
        cpx.w #512
        bne .c
        lda.w #$6400+(PROW*32)
        ldx.w #!ptm&$FFFF
        ldy.w #NROWS*32
        jsr RdVram
        lda.w #HEARTV
        ldx.w #!ptile&$FFFF
        ldy.w #16
        jmp RdVram

; the picture dimmed like the pause screen; palette 4 (colors 16-19) becomes the bright highlight (also used by the title)
PPal:   sep #$20
        stz.w $2121
        rep #$30
        ldx.w #0
        ldy.w #0
.c:     lda.l !pcg,x
        cpy.w #16
        bcc .dim
        cpy.w #20
        bcc .hi
        cpy.w #32
        bcc .w
.dim:   lsr a
        and.w #$3DEF
        bra .w
.hi:    phx
        tya
        sec
        sbc.w #16
        asl a
        tax
        lda.l PalHi,x
        plx
.w:     sep #$20
        sta.w $2122
        xba
        sta.w $2122
        rep #$20
        inx
        inx
        iny
        cpy.w #256
        bne .c
        rts

PalHi:  dw $0000,$7BFF,$1B9F,$0000

PTiles: sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #HEARTV
        sta.w $2116
        ldx.w #0
-       lda.l PTileTab,x
        sta.w $2118
        inx
        inx
        cpx.w #32
        bne -
        rts

PTileTab: dw $6C6C,$BED2,$BEC2,$FE82,$FE82,$7C44,$3828,$1010
          dw $0606,$1F19,$7F61,$FF81,$FF81,$7F61,$1F19,$0606

PRestore: sep #$20
        lda.b #$80
        sta.w $2115
        stz.w $2121
        rep #$30
        ldx.w #0
.c:     sep #$20
        lda.l !pcg,x
        sta.w $2122
        inx
        lda.l !pcg,x
        sta.w $2122
        inx
        rep #$20
        cpx.w #512
        bne .c
        lda.w #$6400+(PROW*32)
        ldx.w #!ptm&$FFFF
        ldy.w #NROWS*32
        jsr WrVram
        lda.w #HEARTV
        ldx.w #!ptile&$FFFF
        ldy.w #16
        jmp WrVram

StZeke:    db "ZEKE JOINS",0
StJulie:   db "JULIE JOINS",0
StResume:  db "RESUME",0
StLevel:   db "LEVEL ",0
StNew:     db "NEW GAME",0
StReplaces: db "REPLACES SAVE",0
StCancel:  db "CANCEL",0
StSure:    db "SURE?",0
StYesNo:   db " A YES B NO",0

; the join itself, called by Join after the default player is set up: a resume loads the saved health, lives, weapon, item,
; ammo, items, score and bonus threshold (not the level or the victims: the level is shared); a fresh start keeps the old save until the
; next level end, where it is replaced
JoinSave:
        lda.l !jmode
        cmp.w #1
        beq .resume
        cmp.w #2
        beq .fresh
        rts
.resume: phb
        jsr Prep
        lda.l !jslot
        lsr a
        sta.l !ts
        lda.l !jslot
        tax
        lda.l $7E1E84,x
        beq +
        lda.w #1
+       jsr RecBase
        tax
        lda.l !SAV,x
        cmp.w #1
        bne .no
        lda.w #1
        jsr XferOwn
        lda.l !ts                       ; this game now owns that slot's save
        bne +
        lda.l !actmask
        ora.w #4
        bra ++
+       lda.l !actmask
        ora.w #8
++      sta.l !actmask
.no:    plb
        rts
.fresh: phb                            ; the old save stays until this game saves the joiner at a level end (SaveHook replaces it);
        jsr Prep                        ; a game over before that leaves it alone, because this game does not own it
        jsr Finish
        plb
        rts
