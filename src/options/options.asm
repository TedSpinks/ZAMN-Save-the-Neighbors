; ZAMN Options screen (title menu: choosing OPTIONS) + runtime R-button mode.
; Code lives in free space at the end of bank 82; the screen reuses the password screen's font and background.
lorom

; Variables that must survive a level change live at 7F:FF08-FF0F: the explored-area array of the map (7F:FD00-FEFF) is wiped
; whenever the level number changes, so nothing else may touch it.  Bank 7F below 7F:EE00 holds the level's tile map.
; Scratch for the screens and the save code lives at 7F:EE02-EF07, shared with the pause map's decal list and the join
; prompt's palette backup (neither is up while this code runs).
!rmode  = $7FFF08               ; $5A00 + mode (0 reverse fire, 1 strafe, 2 original); anything else reads as 0
!ocur   = $7FEE02               ; cursor row 0..5 (RESUME GAME, PASSWORD, TOP SCORES, ERASE DATA, R mode, EXIT)
!oprev  = $7FEE04               ; pad on the previous frame
!ohold  = $7FEE06               ; frames the erase combo has been held
!ocombo = $7FEE08               ; Start was pressed together with a face button: it must not exit on release
!ostate = $7FEE0A               ; hint line: 0 normal, 1-3 erase countdown, 4 scores erased
!cpad   = $7FEE0C               ; pad this frame (P1 | P2)
!oedge  = $7FEE0E               ; buttons newly pressed this frame
!ravail = $7FEE20               ; saved games present (save.asm): bit 0 Zeke, bit 1 Julie, bit 2 both
!resume = $7FFF0E               ; saved game chosen to resume: 1 Zeke, 2 Julie, 3 both, 0 none
; the RESUME screen (the Options variables above are not touched while it runs, except the ones .show resets again)
!rinfo  = $7FEE10               ; level and victim count to show, 2 words each: Zeke, Julie, both (save.asm: ResInfo)
!rcur   = $7FEE1C               ; cursor: the choice (1 Zeke, 2 Julie, 3 both) it is on
!rtmp   = $7FEE1E               ; choice being drawn
!rrow   = $7FEE06               ; position offset of the entry being drawn (rows of 6 text rows)
!bptr   = $7FEE30               ; end of the object list being built
!list   = $7FFF10               ; the object list (bank 7F, up to 240 bytes)

!NP = 1                                 ; text palette
!SP = 2                                 ; highlighted item palette

!UP = $0800
!DOWN = $0400
!LEFT = $0200
!RIGHT = $0100
!SEL = $2000
!START = $1000
!FACE = $C0C0                     ; B Y A X
!ALL5 = $D0C0

; ---- title menu: OPTIONS now opens this screen (X = the argument the password screen takes) ----
org $809792
        jsl OptionsEntry

; ---- every Reverse Fire / Strafe hook site calls $9F:FFC0; it now reads the chosen mode ----
org $9FFFC0
        jml RMode
        padbyte $FF : pad $9FFFDE

; ---- radar button ----
; Reverse Fire / Reverse Inventory moved the radar to Select. While an attract demo plays ($1EB4 <> 0), or with
; R BUTTON = ORIGINAL, the radar check uses the original L / R mask ($0030) again.
org $80D28E                             ; was LDA $1A / AND #$2000 (Reverse Inventory)
        jsl RadarCur
        nop
org $80D295                             ; was LDA $1C / AND #$2000
        jsl RadarPrev
        nop

org $83FC40
RadarCur:
        lda.w $1EB4
        bne .orig
        jsl RModeGet
        cmp.w #2
        beq .orig
        lda.b $1A
        and.w #$2000                    ; Select
        rtl
.orig:  lda.b $1A
        and.w #$0030                    ; original L / R
        rtl

RadarPrev:
        lda.w $1EB4
        bne .orig
        jsl RModeGet
        cmp.w #2
        beq .orig
        lda.b $1C
        and.w #$2000
        rtl
.orig:  lda.b $1C
        and.w #$0030
        rtl

; Bank 82 only keeps what must run in bank 82 (the routines below are RTS-terminated and the score screen's call site is a JSR);
; the rest of the Options code lives in bank BF.
org $82F974
J_B229: jsr $B229
        rtl
J_B1A7: jsr $B1A7
        rtl
J_BA4F: jsr $BA4F
        rtl

; the score screen's set-up call ($82:BA16 was JSR $BA4F): save any new score first
ScoreHook:
        jsl SaveIfChanged
        jmp $BA4F

org $BF9000

; ---------------------------------------------------------------------------------------------
GetMode:                                ; A = 0 reverse, 1 strafe, 2 original (bad/unset value = reverse); Z set for reverse
        lda.l !rmode
        sec
        sbc.w #$5A00
        cmp.w #3
        bcc .ok
        lda.w #0
.ok:    cmp.w #0                        ; the flags must describe A (RMode branches on them; the CMP above left Z clear for 0)
        rts

RModeGet:                               ; long entry for the radar check in bank 83
        jsr GetMode
        rtl

; Z = no direction pressed (the caller's LDA); $24 = direction, $26 = facing, $1A = pad, R = $0010
RMode:  beq .ret
        lda.w $1EB4                     ; attract demo: original controls
        bne .plain
        jsr GetMode
        beq .rev
        dec a
        beq .str
.plain: lda.b $24
        sta.b $26
        rtl
.str:   lda.b $1A
        and.w #$0010
        bne .ret                        ; R held: keep facing
        bra .plain
.rev:   lda.b $1A
        and.w #$0010
        beq .plain
        lda.b $24                       ; R held: face the opposite way
        dec a
        dec a
        clc
        adc.w #8
        and.w #$000F
        inc a
        inc a
        sta.b $26
.ret:   rtl

; ---------------------------------------------------------------------------------------------
OptionsEntry:
        rep #$30
        phb
        phk
        plb
        phx
        stz.w $1E7C
        lda.w #0
        sta.l !ocur
        sta.l !ostate
        sta.l !resume
        jsl SaveStatus
        sta.l !ravail
.show:  jsr Setup
        lda.w #0
        sta.l !ohold
        sta.l !ocombo
        sta.l !oprev
        jsr Draw
        jsr FadeIn
.loop:  wai
        lda.w $006E
        ora.w $0070
        sta.l !cpad
        lda.l !oprev
        eor.w #$FFFF
        and.l !cpad
        sta.l !oedge

        ; Start together with a face button = erase combo, not exit
        lda.l !cpad
        and.w #!START
        beq +
        lda.l !cpad
        and.w #!FACE
        beq +
        lda.w #1
        sta.l !ocombo
+
        ; cursor
        lda.l !ocur
        pha
        lda.l !oedge
        and.w #!UP
        beq +
        lda.l !ocur
        dec a
        bpl +++
        lda.w #5
+++     sta.l !ocur
+       lda.l !oedge
        and.w #(!DOWN|!SEL)
        beq +
        lda.l !ocur
        inc a
        cmp.w #6
        bcc +++
        lda.w #0
+++     sta.l !ocur
+       pla
        cmp.l !ocur
        beq .same
        lda.w #0
        sta.l !ostate
        sta.l !ohold
        jsr Draw
.same:
        ; R button: left / right change it
        lda.l !ocur
        cmp.w #4
        bne +
        lda.l !oedge
        and.w #!LEFT
        beq ++
        jsr ModePrev
        bra +
++      lda.l !oedge
        and.w #!RIGHT
        beq +
        jsr ModeNext
+
        ; erase combo on ERASE DATA
        lda.l !ocur
        cmp.w #3
        bne .nohold
        lda.l !cpad
        and.w #!ALL5
        cmp.w #!ALL5
        bne .nohold
        lda.l !ohold
        inc a
        sta.l !ohold
        cmp.w #120
        bcs .erase
        jsr Div40                       ; hint state 1..3 = 40 frames each
        inc a
        cmp.l !ostate
        beq .acts
        sta.l !ostate
        jsr Draw
        bra .acts
.erase: lda.l !ostate
        cmp.w #4
        beq .acts
        jsl $82BB0D                     ; default score table
        jsl SaveIfChanged
        jsl WipeAll
        lda.w #0
        sta.l !ravail
        lda.w #$0013
        jsl $80CC3B
        lda.w #4
        sta.l !ostate
        jsr Draw
        bra .acts
.nohold:
        lda.l !ohold
        beq .acts
        lda.w #0
        sta.l !ohold
        lda.l !ostate
        cmp.w #4
        beq .acts
        lda.w #0
        sta.l !ostate
        jsr Draw

.acts:  ; face buttons
        lda.l !oedge
        and.w #!FACE
        beq .nof
        lda.l !cpad
        and.w #!START
        bne .nof
        lda.l !ocur                     ; selecting is silent (the title's laugh stays on the title)
        bne +
        jmp .rs
+       cmp.w #1
        beq .pw
        cmp.w #2
        beq .ts
        cmp.w #3
        beq .nof                        ; ERASE DATA: hold the combo
        cmp.w #4
        beq .md
        bra .quit
.md:    jsr ModeNext
        bra .nof
.ts:    jsr OptOut
        jsr TopScores
        jmp .show
.pw:    jsr OptOut
        lda $01,s                       ; the title's argument
        tax
        jsl $82AFF3
        lda.w $1E7C
        cmp.w #2
        bcs .done                       ; a good password: the title starts the game
        cmp.w #1
        beq .back                       ; a bad password: back to OPTIONS
        bra .done                       ; 0 = the secret-level code (82:B018): back to the title, which keeps it, as the
                                        ; original does; START then plays the bonus level
.back:  jmp .show
.nof:
        ; Start (released, not part of a combo) leaves
        lda.l !oprev
        and.w #!START
        beq .nst
        lda.l !cpad
        and.w #!START
        bne .nst
        lda.l !ocombo
        bne .nst
.quit:  jsr OptOut
        lda.w #1
        sta.w $1E7C
.done:  plx
        plb
        rtl
.nst:   lda.l !cpad                     ; every button up: the next Start press starts fresh
        and.w #!ALL5
        bne +
        sta.l !ocombo
+       lda.l !cpad
        sta.l !oprev
        jmp .loop
.rs:    lda.l !ravail                   ; RESUME GAME opens the RESUME screen; with nothing saved it does nothing
        bne +
        jmp .nof
+       jsr OptOut
        jsr ResumeScreen                ; -> 1 Zeke, 2 Julie, 3 both, 0 back (leaves the screen faded out)
        bne +
        jmp .show
+       sta.l !resume
        dec a
        asl a
        asl a
        tax
        lda.l !rinfo,x                  ; the level it was saved at (both: the one the game continues from)
        sta.w $1E7C
        jmp .done

ModeNext:
        jsr GetMode
        inc a
        cmp.w #3
        bcc +
        lda.w #0
+       bra SetMode
ModePrev:
        jsr GetMode
        dec a
        bpl SetMode
        lda.w #2
SetMode:
        clc
        adc.w #$5A00
        sta.l !rmode
        jsl SaveIfChanged
        jmp Draw

Div40:  ldx.w #0                        ; A / 40 -> A
-       cmp.w #40
        bcc +
        sbc.w #40
        inx
        bra -
+       txa
        rts

; ---------------------------------------------------------------------------------------------
FadeIn:
        stz.w $136C
        wai
        lda.w $136C
        and.w #$007F
        sta.w $136C
-       wai
        lda.w $136C
        cmp.w #$000F
        beq +
        inc a
        sta.w $136C
        bra -
+       stz.w $006E
        stz.w $0072
        stz.w $0070
        stz.w $0074
        stz.w $1EB2
-       wai                             ; wait until the button that got us here is up
        lda.w $006E
        ora.w $0070
        and.w #$FFF0
        bne -
        rts

FadeOut:
        wai
        lda.w $136C
        beq +
        dec a
        sta.w $136C
        bra FadeOut
+       lda.w #$0080
        sta.w $136C
        wai
        jsl J_B229                      ; stop the background task
        rts

OptOut: jsr FadeOut                     ; leaving the Options screen: also release the sprite handle ($82:B304)
        lda.w $0068
        jsl $8083D5
        wai
        rts

; ---------------------------------------------------------------------------------------------
; The RESUME screen: one entry per saved game (ZEKE, JULIE, BOTH), each with its level and victim count. Up / Down / Select
; move, A B X Y pick (EXIT goes back), Start goes back too. -> A = 1 Zeke, 2 Julie, 3 both, 0 back; the screen is faded out when it returns.
ResumeScreen:
        jsl ResInfo
        lda.l !ravail
        and.w #1
        bne +
        lda.w #2                        ; no Zeke save: the cursor starts on Julie
        bra ++
+       lda.w #1
++      sta.l !rcur
        jsr Setup
        lda.w #0
        sta.l !oprev
        jsr RDraw
        jsr FadeIn
.loop:  wai
        lda.w $006E
        ora.w $0070
        sta.l !cpad
        lda.l !oprev
        eor.w #$FFFF
        and.l !cpad
        sta.l !oedge
        lda.l !cpad
        sta.l !oprev
        lda.l !oedge
        and.w #!START
        bne .back
        lda.l !oedge
        and.w #!FACE
        bne .pick
        lda.l !oedge
        and.w #!UP
        beq +
        jsr RPrev
        jsr RDraw
        bra .loop
+       lda.l !oedge
        and.w #(!DOWN|!SEL)
        beq .loop
        jsr RNext
        jsr RDraw
        bra .loop
.back:  lda.w #0
        bra .out
.pick:  lda.l !rcur
        cmp.w #4
        bne .out
        lda.w #0                        ; EXIT
.out:   pha
        jsr OptOut
        pla
        rts

RNext:  lda.l !rcur                     ; the next saved game, wrapping around
-       inc a
        cmp.w #5
        bcc +
        lda.w #1
+       jsr Avail
        beq -
        sta.l !rcur
        rts

RPrev:  lda.l !rcur
-       dec a
        bne +
        lda.w #4
+       jsr Avail
        beq -
        sta.l !rcur
        rts

Avail:  pha                             ; A = choice 1..4 (Zeke, Julie, both, EXIT): Z clear when it exists (A is kept)
        cmp.w #3
        beq .both
        cmp.w #4
        beq .exit
        and.l !ravail
        bra +
.both:  lda.w #4
        and.l !ravail
        bra +
.exit:  lda.w #1
+       tax
        pla
        cpx.w #0
        rts

RDraw:  jsr DrawBegin
        jsr RBuild
        jmp DrawEnd

RBuild: ldx.w #TRTitle
        ldy.w #0
        jsr Add
        lda.w #0
        sta.l !rrow
        lda.w #1
        jsr Entry
        lda.w #2
        jsr Entry
        lda.w #3
        jsr Entry
        lda.l !rcur
        cmp.w #4
        beq +
        ldx.w #TRExit
        ldy.w #0
        jmp Add
+       ldx.w #TRExitS
        ldy.w #0
        jsr Add
        ldx.w #TRArrowX
        ldy.w #0
        jmp Add

Entry:  sta.l !rtmp                     ; A = choice: draws its name, level and victim count at the next free position
        jsr Avail
        bne +
        rts
+       lda.l !rtmp
        dec a
        asl a
        tax
        lda.l !rcur
        cmp.l !rtmp
        beq .sel
        lda.w RNames,x
        bra .nm
.sel:   lda.w RNamesS,x
.nm:    tax
        lda.l !rrow
        tay
        jsr Add
        lda.l !rcur
        cmp.l !rtmp
        bne +
        ldx.w #TRArrow
        lda.l !rrow
        tay
        jsr Add
+       ldx.w #TRLevel
        lda.l !rrow
        tay
        jsr Add
        ldx.w #TRVict
        lda.l !rrow
        tay
        jsr Add
        lda.l !rtmp
        dec a
        asl a
        asl a
        tax
        lda.l !rinfo,x                  ; level
        pha
        lda.l !rinfo+2,x                ; victims
        pha
        lda.l !rrow
        clc
        adc.w #$051A                    ; last digit of the level: column 26, row 5
        tax
        ldy.w #!NP
        lda.b $03,s
        jsr AddNum
        lda.l !rrow
        clc
        adc.w #$0712                    ; last digit of the victims: column 18, row 7
        tax
        ldy.w #!NP
        pla
        jsr AddNum
        pla
        lda.l !rrow
        clc
        adc.w #$0600
        sta.l !rrow
        rts

RNames: dw TRZeke,TRJulie,TRBoth
RNamesS: dw TRZekeS,TRJulieS,TRBothS

TopScores:                              ; the attract-mode screen, but it stays until a button is pressed
        phb
        pea.w $8282                     ; the screen code reads its tables with the data bank at $82, as its caller sets it
        plb
        plb
        jsl J_BA4F
        plb
-       wai
        lda.w $006E
        ora.w $0070
        and.w #!ALL5
        bne -
-       wai
        lda.w $006E
        ora.w $0070
        and.w #!ALL5
        beq -
        jmp FadeOut

; same set-up as the password screen ($82:B4B7..B51F), without its text
Setup:
        lda.w $136C
        ora.w #$0080
        sta.w $136C
        jsl $809F9D
        stz.w $1B6A
        stz.w $1B6C
        stz.w $210D
        stz.w $210D
        sep #$20
        lda.b #$80
        sta.w $2100
        lda.b #$68
        sta.w $2107
        lda.b #$02
        sta.w $210B
        lda.b #$15
        sta.w $212C
        rep #$30
        lda.w #$0083
        ldx.w #$F18C
        ldy.w #$0100
        jsl $80C872
        lda.w #$0080
        pha
        lda.w #$009E
        ldx.w #$8F76
        ldy.w #$0100
        jsl $80C892
        pla
        lda.w #$0096
        pha
        lda.w #$9683
        ldx.w #$4000
        ldy.w #$1620
        jsl $80C8B8
        pla
        lda.w #$0008
        jsl J_B1A7
        jsl $82AD44
        jsl $80BDF2                     ; sprite VRAM bookkeeping, as the password screen does ($82:B584)
        lda.w #$8000
        ldy.w #$0084
        jsl $80C05A
        jsl $80C049
        stx.w $0068
        lda.w #1
        jsl $808353
        rts

; ---------------------------------------------------------------------------------------------
Obj:                                    ; X = text object, Y = position offset
        lda.w #$0082
        jsl $82B8FB
        rts

; The text engine uploads the tilemap after every object it draws, so drawing the objects one by one shows the
; screen filling up (a flash on every cursor move). Draw collects every object into one list in WRAM
; (objects chain with $FF) and draws that list with a single call.
Draw:   jsr DrawBegin
        jsr DrawBuild
        jmp DrawEnd

DrawBegin:
        jsl $82AD44                     ; empty tilemap buffer (no upload)
        lda.w #!list
        sta.l !bptr
        rts

DrawEnd:
        lda.w #$007F
        ldx.w #!list
        ldy.w #0
        jsl $82B8FB
        rts

; appends a text object of this bank to the list in 7F:!list
Open:   rep #$30                        ; -> X = where the next object goes
        lda.l !bptr
        tax
        cmp.w #!list
        beq +
        dex                             ; the end marker of the previous object becomes "another object follows"
        sep #$20
        lda.b #$FF
        sta.l $7F0000,x
        inx
        rep #$20
+       rts

Add:    rep #$30                        ; X = text object, Y = position offset (added to the object's position)
        phy
        txy                             ; Y = source
        jsr Open
        lda.w $0000,y                   ; position (column | row << 8) plus the offset
        clc
        adc.b $01,s
        sta.l $7F0000,x
        pla
        sep #$20
        lda.w $0002,y                   ; palette (2 bytes, may contain zeros)
        sta.l $7F0002,x
        lda.w $0003,y
        sta.l $7F0003,x
        inx : inx : inx : inx
        iny : iny : iny : iny
-       lda.w $0000,y                   ; text, including its 0 end marker
        sta.l $7F0000,x
        iny
        inx
        cmp.b #$00
        bne -
        rep #$20
        txa
        sta.l !bptr
        rts

; appends a number object: A = value 0..99, X = position of its last digit, Y = palette (a second digit goes to the left)
AddNum: rep #$30
        pha
        phx
        phy
        jsr Open                        ; $01 palette, $03 position, $05 value
        lda.b $05,s
        cmp.w #10
        lda.b $03,s
        bcc +
        sec
        sbc.w #2
+       sta.l $7F0000,x
        lda.b $01,s
        sta.l $7F0002,x
        inx : inx : inx : inx
        lda.b $05,s
        jsr Div10                       ; Y = tens, A = ones
        sta.b $05,s
        sep #$20
        cpy.w #0
        beq +
        tya
        clc
        adc.b #'0'
        sta.l $7F0000,x
        inx
+       lda.b $05,s
        clc
        adc.b #'0'
        sta.l $7F0000,x
        inx
        lda.b #0
        sta.l $7F0000,x
        inx
        rep #$20
        txa
        sta.l !bptr
        pla : pla : pla
        rts

Div10:  ldy.w #0                        ; A / 10 -> Y quotient, A remainder
-       cmp.w #10
        bcc +
        sbc.w #10
        iny
        bra -
+       rts

DrawBuild:
        ldx.w #TTitle
        ldy.w #0
        jsr Add
        lda.l !ocur                     ; row 0
        beq +
        ldx.w #TRes
        bra ++
+       ldx.w #TResS
++      ldy.w #0
        jsr Add
        lda.l !ocur                     ; row 1
        cmp.w #1
        beq +
        ldx.w #TPass
        bra ++
+       ldx.w #TPassS
++      ldy.w #0
        jsr Add
        lda.l !ocur                     ; row 2
        cmp.w #2
        beq +
        ldx.w #TTop
        bra ++
+       ldx.w #TTopS
++      ldy.w #0
        jsr Add
        lda.l !ocur                     ; row 3
        cmp.w #3
        beq +
        ldx.w #TErase
        bra ++
+       ldx.w #TEraseS
++      ldy.w #0
        jsr Add
        jsr GetMode                     ; row 4
        asl a
        tax
        lda.l !ocur
        cmp.w #4
        beq +
        lda.w RNorm,x
        bra ++
+       lda.w RSel,x
++      tax
        ldy.w #0
        jsr Add
        lda.l !ocur                     ; row 5
        cmp.w #5
        beq +
        ldx.w #TExit
        bra ++
+       ldx.w #TExitS
++      ldy.w #0
        jsr Add
        lda.l !ocur                     ; pointer
        asl a
        tax
        lda.w ArrowY,x
        tay
        ldx.w #TArrow
        jsr Add
        lda.l !ocur                     ; hints
        beq .h0
        cmp.w #3
        beq .h3
        cmp.w #4
        bne .hx
        ldx.w #THchg1
        ldy.w #0
        jsr Add
        ldx.w #THchg2
        ldy.w #0
        jmp Add
.h0:    lda.l !ravail
        bne .hx
        ldx.w #THnone                   ; no saved game
        ldy.w #0
        jmp Add
.h3:    lda.l !ostate
        cmp.w #4
        beq .done
        ldx.w #THerase1
        ldy.w #0
        jsr Add
        lda.l !ostate
        asl a
        tax
        lda.w EraseLine,x
        tax
        ldy.w #0
        jmp Add
.done:  ldx.w #THdone
        ldy.w #0
        jmp Add
.hx:    rts

ArrowY: dw $0000,$0300,$0600,$0900,$0C00,$0F00
RNorm:  dw TRRev,TRStr,TROrg
RSel:   dw TRRevS,TRStrS,TROrgS
EraseLine: dw THerase2,THerase3,THerase4,THerase5

macro obj(col,row,pal,text)
        dw (<row><<8)|<col>,<pal>
        db "<text>",0
endmacro

TTitle: %obj(9,2,!NP,"OPTIONS")
TRes:   %obj(5,5,!NP,"RESUME/GAME")
TResS:  %obj(5,5,!SP,"RESUME/GAME")
TPass:  %obj(5,8,!NP,"PASSWORD")
TPassS: %obj(5,8,!SP,"PASSWORD")
TTop:   %obj(5,11,!NP,"TOP/SCORES")
TTopS:  %obj(5,11,!SP,"TOP/SCORES")
TErase: %obj(5,14,!NP,"ERASE/DATA")
TEraseS: %obj(5,14,!SP,"ERASE/DATA")
TRRev:  %obj(5,17,!NP,"R/REVERSE")
TRRevS: %obj(5,17,!SP,"R/REVERSE")
TRStr:  %obj(5,17,!NP,"R/STRAFE")
TRStrS: %obj(5,17,!SP,"R/STRAFE")
TROrg:  %obj(5,17,!NP,"R/ORIGINAL")
TROrgS: %obj(5,17,!SP,"R/ORIGINAL")
TExit:  %obj(5,20,!NP,"EXIT")
TExitS: %obj(5,20,!SP,"EXIT")
TArrow: %obj(27,5,!SP,":")
THchg1: %obj(3,23,!NP,"LEFT/OR/RIGHT")
THchg2: %obj(7,25,!NP,"TO/CHANGE")
THnone: %obj(9,23,!NP,"NO/SAVE")
TRTitle: %obj(10,2,!NP,"RESUME")
TRZeke:  %obj(1,5,!NP,"ZEKE")
TRZekeS: %obj(1,5,!SP,"ZEKE")
TRJulie: %obj(1,5,!NP,"JULIE")
TRJulieS: %obj(1,5,!SP,"JULIE")
TRBoth:  %obj(1,5,!NP,"BOTH")
TRBothS: %obj(1,5,!SP,"BOTH")
TRLevel: %obj(12,5,!NP,"LEVEL")
TRVict:  %obj(1,7,!NP,"VICTIMS")
TRArrow: %obj(29,5,!SP,":")
TRExit:  %obj(1,23,!NP,"EXIT")
TRExitS: %obj(1,23,!SP,"EXIT")
TRArrowX: %obj(29,23,!SP,":")
THerase1: %obj(4,23,!NP,"HOLD/A/B/X/Y")
THerase2: %obj(2,25,!NP,"START/TO/ERASE")
THerase3: %obj(4,25,!NP,"ERASING/IN/3")
THerase4: %obj(4,25,!NP,"ERASING/IN/2")
THerase5: %obj(4,25,!NP,"ERASING/IN/1")
THdone: %obj(5,23,!NP,"DATA/ERASED")

incsrc "sram.asm"
incsrc "dropin.asm"
incsrc "save.asm"
incsrc "joinprompt.asm"
incsrc "charback.asm"
