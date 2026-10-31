; ZAMN pause-screen level map  (Split+QoL pause patch, bank BE)
; Select while paused -> full-level map on BG3 (Start there closes the map and unpauses), 1 px per tile, 192x120 tile window, D-pad pans.
lorom

!ox    = $7FFC00
!oy    = $7FFC02
!W     = $7FFC04
!H     = $7FFC06
!blink = $7FFC08
!prev  = $7FFC0A
!dummy = $7FFC0C
!cgsv  = $7FFC10
!cgsv6 = $7FFC50
!fogon = $7FFC0E
!egg   = $7FFCC4
!rsF   = $7FFCC8
!rsT   = $7FFCCA
!rsR   = $7FFCCC
!stx   = $7FFCCE
!sela  = $7FFCD0
!exx   = $7FFCD2                ; level exit door position per player slot (x, then y; 0 = none yet)
!exy   = $7FFCD6
!need  = $7FFCC0
!lvl   = $7FFCC2
!wb8   = $7FFC1C
!t0    = $7FFC70
!t1    = $7FFC72
!t2    = $7FFC74
!t3    = $7FFC76
!t4    = $7FFC78
!t5    = $7FFC7A
!t7    = $7FFC7C
!lastp = $7FFC80
!wc    = $7FFC8C
!hc    = $7FFC8E
!c0    = $7FFCA8
!r0    = $7FFCAA
!tbase = $7FFCAC
!hdma  = $7FFCB0
!mkn   = $7FFC86
!ra    = $7FFCE0                ; cell range of the last RenderRange
!rb    = $7FFCE2
!ca    = $7FFCE4
!cb    = $7FFCE6
!oxm   = $7FFCE8                ; (ox/8) mod wc and (oy/8) mod hc: where the window sits in the character slots
!oym   = $7FFCEA
!sdir  = $7FFCEC                ; scroll direction: 0 right / down, 1 left / up
!told  = $7FFCEE
!cnt   = $7FFCF0
!padv  = $7FFCF2
!arR   = $7FFCF4                ; arrow enabled flags, worked out before the vblank work
!arL   = $7FFCF6
!arD   = $7FFCF8
!arU   = $7FFCFA
!rep   = $7FFCFC                ; frames to wait before the next scroll step while a direction is held
!pdir  = $7FFCFE                ; directions held on the previous pass
!rbuf  = $7FFA10
!tbuf  = $7FFB80
!lsv   = $7FF180                ; the 7 score tiles of each player (14 bytes at +0 / +16) that REST nn replaces while paused
!hsv   = $7FF1C0                ; 16 bytes: the tile character 260 held before the heart
!mA    = $7FF1B4                ; MapCheck / LivesSwap / RadarSwap keep their registers here, not on the stack: the pause loop's task stack has very little room
!mX    = $7FF1B6
!mY    = $7FF1B8
!sF0   = $7FF1BA
!sF2   = $7FF1BC
!sF4   = $7FF1BE
!lvh   = $7FF1B2                ; 1 = the heart tile is in character 260 (the tile it replaced is kept at !hsv)
!lvf   = $7FF1A4                ; per player: 1 = REST nn is on screen
!lvm   = $7FF1A8                ; LivesSwap work variables
!lva   = $7FF1AC
!lvu   = $7FF1AE
!lvt   = $7FF1B0
!lvb   = $7FF1D0                ; the 7 words REST nn is made of (also copied into the HUD tilemap shadow in WRAM)
!blk   = $7FFBC0
!mk    = $7FF000                ; 120 markers x 3 bytes (worst case needs 113: 2 players x 9 + 15 victims x 4 + 35 items); 7FF000-7FF167 is free
!cgsv3 = $7FFC40
!cgsv2 = $7FFC48
!hudn  = $7FFC84
!hud   = $7FF700
!hud2  = $7FF210
!fog   = $7FFD00
!floorc = $7FFC1A
!wallc = $7FFC1E
!pbuf  = $7FFC90
!dpsv  = $7FFC20

; ---- hook: replaces the two frame-wait JSLs in the pause loop (BE:8061) ----
org $BE8061
        jsl MapCheck
        nop : nop : nop : nop

; ---- fog-of-war hook (no hook in the level loader: it must stay cycle-exact or the attract demos desync) ----
org $80C07F                             ; per-frame wait: LDA $24 / EOR #1 / STA $24
        jsl MarkFog
        nop : nop : nop

; ---- the exit door is created (when the last victim is saved) in the routine at 82:F8D9; remember where ----
org $82F8DD                             ; was STA $08 / LDA $00
        jsl ExitHook

; ---- pause screen: the radar is shown dimmed (it is not controllable from pause), the inventory stays bright ----
; The pause palette code leaves CGRAM 16-31 (all the HUD palettes) and color 178 (the radar frame) undimmed.
; color 178 is now dimmed like everything else.  The radar cells (HUD tilemap, rows 6-13) move from palette 7,
; which the inventory numbers share, to the unused palette 4, whose colors become a dimmed copy of palette 7.
org $BE80EF
        db $EA,$EA,$EA,$EA,$EA          ; was CPX #$0164 / BEQ: no more exemption for color 178
org $BE810D
        jsr PalFix                      ; runs just before the dimmed palette is handed to the NMI callback
        nop : nop : nop
org $BE8077
        jsr PalOut                      ; pause exit: radar back to palette 7
org $BE8174
        db $80,$08                      ; BRA $817E: L/R no longer toggle the radar in pause (the radar is only shown, dimmed)

org $BE8230
MapCheck:
        jsl $80C07F
        jsl $80C07F
        php
        rep #$30
        sta.l !mA
        lda.w $006E
        ora.w $0070
        bit.w #$2000
        beq .done
        txa
        sta.l !mX
        tya
        sta.l !mY
        jsr MapRun
        lda.l !stx
        beq .rel
        lda.w $006E                     ; map closed with Start: let the pause loop see Start so it unpauses too
        ora.w #$1000
        sta.w $006E
        bra .out
.rel:   jsl $80C07F                     ; wait for Select to be released
        lda.w $006E
        ora.w $0070
        bit.w #$3000
        bne .rel
.out:   lda.l !mY
        tay
        lda.l !mX
        tax
.done:  lda.l !mA
        plp
        rtl

PalFix: php
        rep #$30
        ldx.w #$0000
.c:     lda.l $7E5428+$38,x             ; palette 7 (colors 28-31) ...
        lsr a
        and.w #$3DEF
        sta.l $7FF800+$20,x             ; ... halved, into palette 4 (colors 16-19) of the pause palette
        inx
        inx
        cpx.w #$0008
        bne .c
        lda.w #$1C00
        ldy.w #$1000
        jsr RadarSwap
        lda.w #0
        jsr LivesSwap
        plp
        lda.w #$8118
        ldy.w #$00BE
        rts

PalOut: php
        rep #$30
        lda.w #$1000
        ldy.w #$1C00
        jsr RadarSwap
        lda.w #1
        jsr LivesSwap
        plp
        lda.w #$A084
        rts


; LivesSwap: A = 0: the score of every player in the game becomes "REST nn" (lives, at most 99) - 7 tiles, the width of the
; score, so it ends at the right edge of the health bar; A = 1: the score tiles come back.
; HUD tilemap (VRAM word $6400) row 4: columns 0-6 for player 1, 16-22 for player 2.
LivesSwap:
        rep #$30
        sta.l !lvm
        lda $F0
        sta.l !sF0
        lda $F2
        sta.l !sF2                      ; DetectVram uses these
        lda $F4
        sta.l !sF4
        sep #$20
        lda.b #$01
        sta.l $004200                   ; NMI off
        lda.b #$80
        sta.l $002100                   ; forced blank
        sta.w $2115
        jsr DetectVram
        rep #$30
        jsr LvTile
        lda.l !lvm
        bne +
        sta.l !lvf                      ; (the flags are not trusted after a power-on)
        sta.l !lvf+2
+       ldx.w #0
.slot:  stx $F4
        txa
        asl a : asl a : asl a
        sta.l !lva
        clc
        adc.w #$6480
        sta.l !lva
        lda.l !lvm
        beq +
        jsr LvPut
        bra .next
+       jsr LvDraw
.next:  ldx $F4
        inx
        inx
        cpx.w #4
        bcs +
        jmp .slot
+       lda.l !sF4
        sta $F4
        lda.l !sF2
        sta $F2
        lda.l !sF0
        sta $F0
        sep #$20
        lda.b #$81
        sta.l $004200
        rep #$20
        rts

LvDraw:
        lda.l $7E1E88,x                 ; a player in the game: keep the score tiles, write REST
        bne +
        rts
+
        lda.l !lva
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq +
        lda.w $2139
        lda.w $213A
+       rep #$20
        txa
        asl a : asl a : asl a
        tax
        ldy.w #7
        sep #$20
.sv:    lda.w $2139
        sta.l !lsv,x
        inx
        lda.w $213A
        sta.l !lsv,x
        inx
        dey
        bne .sv
        rep #$20
        ldx $F4
        lda.l $7E1D4C,x                 ; lives -> tens and units
        cmp.w #100
        bcc +
        lda.w #99
+       sta.l !lvu
        lda.w #0
        sta.l !lvt
-       lda.l !lvu
        cmp.w #10
        bcc +
        sbc.w #10
        sta.l !lvu
        lda.l !lvt
        inc a
        sta.l !lvt
        bra -
+       lda.l !lva
        sta.w $2116
        ldx.w #0
-       lda.l LivesTxt,x
        jsr Emit
        cpx.w #8
        bne -
        lda.l !lvt                      ; the heart sits right before the number: one digit, or two for 10 and up
        bne +
        lda.w #$3C00
        jsr Emit
        lda.w #$3904
        jsr Emit
        bra ++
+       lda.w #$3904
        jsr Emit
        lda.l !lvt
        clc
        adc.w #$3C07                    ; digit 0 = char 7, HUD palette
        jsr Emit
++      lda.l !lvu
        clc
        adc.w #$3C07
        jsr Emit
        ; The game redraws the whole HUD from a tilemap copy in WRAM whenever a player cycles an item or weapon.  Put the
        ; same 7 words there, so that redraw keeps REST nn (it used to bring the score back for a moment).
        ldx $F4
        jsr ShadowPut
        ldx $F4
        lda.w #1
        sta.l !lvf,x
        rts

Emit:   sta.w $2118                     ; X = byte offset in !lvb, advanced by one word
        sta.l !lvb,x
        inx
        inx
        rts

HudShadow: dw $5FB6,$5FD6                ; WRAM copy of the HUD tilemap cells of the two score fields (VRAM $6480 / $6490)

; ShadowPut: X = player index (0/2); the 7 words in !lvb go into that player's score cells of the HUD's WRAM tilemap copy
ShadowPut:
        lda.l HudShadow,x
        tay
        ldx.w #!lvb&$FFFF
        lda.w #13
        phb
        mvn $7E,$7F
        plb
        rts

LvPut:  lda.l !lvf,x
        beq .no2
        lda.w #0
        sta.l !lvf,x
        lda.l !lva
        sta.w $2116
        txa
        asl a : asl a : asl a
        tax
        ldy.w #7
-       lda.l !lsv,x
        sta.w $2118
        inx
        inx
        dey
        bne -
        ldx $F4                         ; the score goes back into the HUD's WRAM copy as well
        lda.l HudShadow,x
        tay
        lda $F4
        asl a : asl a : asl a
        clc
        adc.w #!lsv&$FFFF
        tax
        lda.w #13
        phb
        mvn $7E,$7F
        plb
.no2:   rts

; The HUD font has no heart: character 260 (VRAM byte $9040, free on every level; the map backs it up; $9000-$9005 is the probe area of DetectVram) holds one while paused.
LvTile: lda.l !lvm
        bne .out
        lda.w #$4820                    ; VRAM word address of character 260
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq +
        lda.w $2139
        lda.w $213A
+       ldx.w #0
.keep:  lda.w $2139
        sta.l !hsv,x
        inx
        lda.w $213A
        sta.l !hsv,x
        inx
        cpx.w #16
        bne .keep
        rep #$20
        lda.w #$4820
        sta.w $2116
        ldx.w #0
.heart: lda.l HeartTile,x
        sta.w $2118
        inx
        inx
        cpx.w #16
        bne .heart
        lda.w #1
        sta.l !lvh
        rts
.out:   lda.l !lvh
        beq .no
        lda.w #0
        sta.l !lvh
        lda.w #$4820
        sta.w $2116
        ldx.w #0
.back:  lda.l !hsv,x
        sta.w $2118
        inx
        inx
        cpx.w #16
        bne .back
.no:    rts

HeartTile: dw $6C6C,$BED2,$BEC2,$FE82,$FE82,$7C44,$3828,$1010
LivesTxt: dw $3C00,$3C00,$3C00,$3C00           ; the heart is char 260 in HUD palette 6 (red): $3904

; RadarSwap: A = palette bits to find, Y = palette bits to set, on HUD tilemap rows 6-13 (VRAM word $6400)
RadarSwap:
        rep #$30
        sta.l !rsF
        tya
        sta.l !rsT
        lda $F0
        sta.l !sF0
        lda $F2
        sta.l !sF2                      ; DetectVram uses these
        sep #$20
        lda.b #$01
        sta.l $004200                   ; NMI off
        lda.b #$80
        sta.l $002100                   ; forced blank
        jsr DetectVram
        rep #$20
        lda.w #6
        sta.l !rsR
.row:   sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.l !rsR
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.w #$6400
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq +
        lda.w $2139
        lda.w $213A
+       ldx.w #$0000
.rd:    lda.w $2139
        sta.l $7FFB80,x
        inx
        lda.w $213A
        sta.l $7FFB80,x
        inx
        cpx.w #64
        bne .rd
        rep #$20
        ldx.w #$0000
.sw:    lda.l $7FFB80,x
        and.w #$1C00
        cmp.l !rsF
        bne +
        lda.l $7FFB80,x
        and.w #$E3FF
        ora.l !rsT
        sta.l $7FFB80,x
+       inx
        inx
        cpx.w #64
        bne .sw
        lda.l !rsR
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.w #$6400
        sta.w $2116
        ldx.w #$0000
.wr:    lda.l $7FFB80,x
        sta.w $2118
        inx
        inx
        cpx.w #64
        bne .wr
        lda.l !rsR
        inc a
        sta.l !rsR
        cmp.w #14
        bcs +
        jmp .row
+       lda.l !sF2
        sta $F2
        lda.l !sF0
        sta $F0
        sep #$20
        lda.b #$81
        sta.l $004200
        rep #$20
        rts

; ---------------------------------------------------------------------------
macro px()
        lda.l $7F0000,x
        and.w #$03FF
        asl a
        tay
        asl $F0
        asl $F2
        lda [$BA],y
        bit.w #$0100
        bne ?w
        lsr a
        bcc ?d
        inc $F0
        bra ?d
?w:     inc $F2
?d:     inx
        inx
endmacro

MapRun:
        phd
        phb
        pea.w $8080
        plb
        plb
        pea.w $0000
        pld
        sep #$20
        lda.b #$01
        sta.w $4200                     ; NMI off, auto-joypad on
        lda.b #$80
        sta.w $2100                     ; force blank
        stz.w $420C                     ; HDMA off (split-screen uses it)
        rep #$20
        ; save DP scratch $E0-$FF
        ldx.w #$0000
.sv:    lda.w $00E0,x
        sta.l !dpsv,x
        inx
        inx
        cpx.w #$0020
        bne .sv
        ; save CGRAM 28-31
        sep #$20
        lda.b #28
        sta.w $2121
        ldx.w #$0000
.cg:    lda.w $213B
        sta.l !cgsv,x
        inx
        cpx.w #$0008
        bne .cg
        lda.b #12
        sta.w $2121
        ldx.w #$0000
.c3:    lda.w $213B
        sta.l !cgsv3,x
        inx
        cpx.w #$0008
        bne .c3
        lda.b #8
        sta.w $2121
        ldx.w #$0000
.c2:    lda.w $213B
        sta.l !cgsv2,x
        inx
        cpx.w #$0008
        bne .c2
        stz.w $2121
        lda.w $213B
        sta.l !cgsv+8
        lda.w $213B
        sta.l !cgsv+9
        lda.b #16
        sta.w $2121
        ldx.w #$0000
.c6:    lda.w $213B
        sta.l !cgsv6,x
        inx
        cpx.w #$0020
        bne .c6
        ; back up VRAM $9000-$9FFF (map chars + tilemap live there; split-screen uses it)
        jsr DetectVram
        sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #$4800
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq .nd1
        lda.w $2139
        lda.w $213A
.nd1:   ldx.w #$0000
.bt:    lda.w $2139
        sta.l $7FE400,x
        inx
        lda.w $213A
        sta.l $7FE400,x
        inx
        cpx.w #$0C00
        bne .bt
        ldx.w #$0000
.bt2:   lda.w $2139
        sta.l $7FF300,x
        inx
        lda.w $213A
        sta.l $7FF300,x
        inx
        cpx.w #$0400
        bne .bt2
        ldx.w #$0000                    ; VRAM $5000-$5037: the legend tiles (chars 512-518) overwrite it
.bt3:   lda.w $2139
        sta.l $7FE000,x
        inx
        lda.w $213A
        sta.l $7FE000,x
        inx
        cpx.w #$0070
        bne .bt3
        ; sparse backup of the HUD tilemap (VRAM word $6400, the map's tilemap goes there)
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #$6400
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq .nd3
        lda.w $2139
        lda.w $213A
.nd3:   ldx.w #$0000
        ldy.w #$0000
.hl:    lda.w $2139
        sta $F0
        lda.w $213A
        sta $F1
        rep #$20
        lda $F0
        beq .hz
        cpx.w #$00FC
        bcs .hb
        sta.l !hud+2,x
        tya
        sta.l !hud,x
        inx : inx : inx : inx
        bra .hz
.hb:    cpx.w #$01EC
        bcs .hz
        sta.l !hud2-252+2,x
        tya
        sta.l !hud2-252,x
        inx : inx : inx : inx
.hz:    sep #$20
        iny
        cpy.w #1024
        bne .hl
        rep #$20
        txa
        lsr a : lsr a
        sta.l !hudn
        ; level size
        lda.w $00B2
        lsr a
        sta.l !W
        lda.w $00B4
        sta.l !H
        lda.l !W
        lsr a : lsr a : lsr a
        sta.l !wb8
        ; panel size in cells (fits the level when it is smaller than the window), centered
        lda.l !W
        clc
        adc.w #7
        lsr a : lsr a : lsr a
        cmp.w #22
        bcc +
        lda.w #22
+       sta.l !wc
        lda.l !H
        clc
        adc.w #7
        lsr a : lsr a : lsr a
        cmp.w #14
        bcc +
        lda.w #14
+       sta.l !hc
        lda.w #32
        sec
        sbc.l !wc
        lsr a
        sta.l !c0
        lda.w #14
        sec
        sbc.l !hc
        lsr a
        clc
        adc.w #8                        ; panel rows start one lower than before: room for a blank row under the legend
        sta.l !r0
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.l !c0
        clc
        adc.w #$6400
        sta.l !tbase
        sep #$20
        lda.l !r0
        asl a : asl a : asl a
        sta.l !hdma
        lda.b #$FF
        sta.l !hdma+1
        lda.b #$00
        sta.l !hdma+2
        lda.l !hc
        asl a : asl a : asl a
        sta.l !hdma+3
        lda.l !c0
        asl a : asl a : asl a
        sta.l !hdma+4
        lda.l !c0
        clc
        adc.l !wc
        asl a : asl a : asl a
        dec a
        sta.l !hdma+5
        lda.b #$01
        sta.l !hdma+6
        lda.b #$FF
        sta.l !hdma+7
        lda.b #$00
        sta.l !hdma+8
        sta.l !hdma+9
        rep #$20
        lda.w $1E7C
        cmp.w #64
        bcc +
        lda.w #0
+       asl a : asl a
        tax
        lda.l TintTab,x
        sta.l !floorc
        lda.l TintTab+2,x
        sta.l !wallc
        ; ---- initial origin from player 1 (or 2) ----
        ldy.w $00D2
        bne +
        ldy.w $00D4
+       ldx.w #$0000                    ; default (no player)
        sty $EE
        tya
        beq .org0
        lda.w $0002,y
        lsr a : lsr a : lsr a
        sec
        sbc.w #88
        bpl +
        lda.w #0
+       and.w #$FFF8
        sta.l !ox
        ldy $EE
        lda.w $0006,y
        lsr a : lsr a : lsr a
        sec
        sbc.w #56
        bpl +
        lda.w #0
+       and.w #$FFF8
        sta.l !oy
        bra .clamp
.org0:  lda.w #0
        sta.l !ox
        sta.l !oy
.clamp: jsr Clamp
        lda.w #$FFFF
        sta.l !prev
        lda.w #0
        sta.l !blink
        sta.l !egg
        sta.l !stx
        sta.l !sela
        sta.l !rep
        sta.l !pdir
        inc a
        sta.l !fogon                    ; every visit starts normal: fog on, no items
        jsr InitMap
        jsr BuildMk
        jsr Redraw
        jsr Arrows
        jsr Show

.loop:  sep #$20
.w1:    lda.w $4210
        bpl .w1
        ; the automatic joypad read starts about 33 dots into vblank, later than this poll can run: let busy come up first
        ; (12 reads of $4212 are a few hundred master clocks), or a stale / half shifted pad value is read
        rep 12 : lda.w $4212
.w2:    lda.w $4212
        and.b #$01
        bne .w2
        rep #$20
        ; blink marker color
        lda.l !blink
        inc a
        sta.l !blink
        and.w #$0010
        beq .red
        lda.w #$7FFF
        bra .setc
.red:   lda.w #$001F
.setc:  sep #$20
        sep #$20
        pha
        lda.b #27
        sta.w $2121
        pla
        sta.w $2122
        xba
        sta.w $2122
        rep #$20
        lda.l !blink
        and.w #$0010
        beq .cy
        lda.w #$7FFF
        bra .setc2
.cy:    lda.w #$7D00
.setc2: sep #$20
        pha
        lda.b #19
        sta.w $2121
        pla
        sta.w $2122
        xba
        sta.w $2122
        rep #$20
        lda.w $4218
        ora.w $421A
        sta $EC
        lda.l !prev
        eor.w #$FFFF
        and $EC
        sta $E0                         ; buttons newly pressed this frame
        lda $EC
        and.w #$A0B0                    ; A+B+L+R+Select all down, the last one pressed this frame
        cmp.w #$A0B0
        bne .nocombo
        lda $E0
        and.w #$A0B0
        beq .nocombo
.combo: lda.l !egg                      ; easter egg: normal -> whole map -> whole map + items -> normal
        inc a
        cmp.w #3
        bcc +
        lda.w #0
+       sta.l !egg
        lda.l !egg
        beq +
        lda.w #0
        bra ++
+       lda.w #1
++      sta.l !fogon                    ; fog is on only in the normal state
        lda.w #0
        sta.l !sela                     ; the chord used this Select press: releasing it must not close the map
        lda $EC
        sta.l !prev
        jmp .redo
.nocombo:
        lda $E0
        bit.w #$1000
        beq +
        lda.w #1
        sta.l !stx                      ; Start: close the map and unpause
        jmp .exit
+       lda $E0
        bit.w #$2000
        beq +
        lda.w #1
        sta.l !sela                     ; Select pressed: the map closes when it is released, unless the chord completes first
+       lda.l !sela
        beq .nofg
        lda $EC
        bit.w #$2000
        bne .nofg                       ; still held
        jmp .exit
.nofg:  lda $EC
        sta.l !prev
        ; panning: one cell per step; a new direction steps at once, then repeats after a short delay
        lda $EC
        and.w #$0F00
        sta.l !padv
        bne +
        sta.l !pdir                     ; nothing held
        sta.l !rep
        jmp .loop
+       cmp.l !pdir
        bne .newp
        lda.l !rep
        beq .rpt
        dec a
        sta.l !rep
        jmp .loop
.newp:  lda.w #12                       ; first step now, the next one after 12 frames (a tap moves one cell)
        bra .st
.rpt:   lda.w #2
.st:    sta.l !rep
        lda.l !padv
        sta.l !pdir
        bit.w #$0100
        beq +
        lda.w #0
        jsr ScrollH
+       lda.l !padv
        bit.w #$0200
        beq +
        lda.w #1
        jsr ScrollH
+       lda.l !padv
        bit.w #$0400
        beq +
        lda.w #0
        jsr ScrollV
+       lda.l !padv
        bit.w #$0800
        beq +
        lda.w #1
        jsr ScrollV
+       jmp .loop
.redo:  jsr BuildMk
        jsr Redraw
        jsr Arrows
        jmp .loop

.exit:  sep #$20
        lda.b #$80
        sta.w $2100
        lda.b #28
        sta.w $2121
        ldx.w #$0000
.rc:    lda.l !cgsv,x
        sta.w $2122
        inx
        cpx.w #$0008
        bne .rc
        lda.b #16
        sta.w $2121
        ldx.w #$0000
.r6:    lda.l !cgsv6,x
        sta.w $2122
        inx
        cpx.w #$0020
        bne .r6
        lda.b #8
        sta.w $2121
        ldx.w #$0000
.r2:    lda.l !cgsv2,x
        sta.w $2122
        inx
        cpx.w #$0008
        bne .r2
        lda.b #12
        sta.w $2121
        ldx.w #$0000
.r3:    lda.l !cgsv3,x
        sta.w $2122
        inx
        cpx.w #$0008
        bne .r3
        stz.w $2121
        lda.l !cgsv+8
        sta.w $2122
        lda.l !cgsv+9
        sta.w $2122
        ; restore VRAM $9000-$9FFF from the backup
        lda.b #$80
        sta.w $2115
        rep #$20
        lda.w #$4800
        sta.w $2116
        sep #$20
        ldx.w #$0000
.rt:    lda.l $7FE400,x
        sta.w $2118
        inx
        lda.l $7FE400,x
        sta.w $2119
        inx
        cpx.w #$0C00
        bne .rt
        ldx.w #$0000
.rt2:   lda.l $7FF300,x
        sta.w $2118
        inx
        lda.l $7FF300,x
        sta.w $2119
        inx
        cpx.w #$0400
        bne .rt2
        ldx.w #$0000
.rt3:   lda.l $7FE000,x
        sta.w $2118
        inx
        lda.l $7FE000,x
        sta.w $2119
        inx
        cpx.w #$0070
        bne .rt3
        rep #$20
        lda.w #$6400
        sta.w $2116
        ldx.w #1024
        lda.w #0
.hz2:   sta.w $2118
        dex
        bne .hz2
        ldx.w #$0000
.hr:    txa
        lsr a : lsr a
        cmp.l !hudn
        bcs .hrd
        cpx.w #$00FC
        bcs .hr2
        lda.l !hud,x
        clc
        adc.w #$6400
        sta.w $2116
        lda.l !hud+2,x
        sta.w $2118
        inx : inx : inx : inx
        bra .hr
.hr2:   lda.l !hud2-252,x
        clc
        adc.w #$6400
        sta.w $2116
        lda.l !hud2-252+2,x
        sta.w $2118
        inx : inx : inx : inx
        bra .hr
.hrd:   sep #$20
        stz.w $420C
        lda.b #$A0
        sta.w $2125
        stz.w $2126
        stz.w $2127
        lda.b #$10
        sta.w $2130
        lda.b #$A2
        sta.w $2131
        lda.b #$E5
        sta.w $2132
        lda.b #$64
        sta.w $2109
        lda.b #$17
        sta.w $212C
        rep #$20
        ldx.w #$0000
.rd:    lda.l !dpsv,x
        sta.w $00E0,x
        inx
        inx
        cpx.w #$0020
        bne .rd
        sep #$20
        lda.b #$81
        sta.w $4200
        rep #$20
        plb
        pld
        rts

; some emulators return a stale latch on the first VRAM read after setting VMADD
; (hardware does not); detect it with a sentinel so the readback works on both.
DetectVram:
        sep #$20
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
        ; try A: no dummy read
        lda.w #$4800
        sta.w $2116
        sep #$20
        lda.w $2139
        sta $F0
        lda.w $213A
        sta $F1
        lda.w $2139
        sta $F2
        lda.w $213A
        sta $F3
        rep #$20
        lda.w #0
        ldx $F0
        cpx.w #$A5C3
        bne .needd
        ldx $F2
        cpx.w #$3C5A
        beq .set
.needd: lda.w #1                        ; hardware/emulator needs a dummy read
.set:   sta.l !dummy
        rts

; clamp origin to [0, max] (multiples of 8)
Clamp:
        lda.l !W
        sec
        sbc.w #176
        bcs +
        lda.w #0
+       sta $EE
        lda.l !ox
        bmi .x0
        cmp $EE
        bcc .xok
        lda $EE
        bra .xok
.x0:    lda.w #0
.xok:   sta.l !ox
        lda.l !H
        sec
        sbc.w #112
        bcs +
        lda.w #0
+       sta $EE
        lda.l !oy
        bmi .y0
        cmp $EE
        bcc .yok
        lda $EE
        bra .yok
.y0:    lda.w #0
.yok:   sta.l !oy
        rts

; palette / registers to display the map
Show:
        rep #$20
        ldx.w #$0000
.pb:    lda.l PalData,x
        sta.l !pbuf,x
        inx
        inx
        cpx.w #$0018
        bne .pb
        lda.l !wallc
        sta.l !pbuf+2
        sta.l !pbuf+10
        sta.l !pbuf+18
        sep #$20
        stz.w $2121
        stz.w $2122
        stz.w $2122
        lda.b #12
        sta.w $2121
        stz.w $2122
        stz.w $2122
        stz.w $2122
        stz.w $2122
        stz.w $2122
        stz.w $2122
        lda.b #$63
        sta.w $2122
        lda.b #$10
        sta.w $2122
        lda.b #16
        sta.w $2121
        ldx.w #$0000
.p:     lda.l !pbuf,x
        sta.w $2122
        inx
        cpx.w #$0018
        bne .p
        lda.b #8                        ; pal 2 = pal 6 with a white color 3: the easter-egg item dots
        sta.w $2121
        ldx.w #$0010
.p2:    lda.l !pbuf,x
        sta.w $2122
        inx
        cpx.w #$0016
        bne .p2
        lda.b #$FF
        sta.w $2122
        lda.b #$7F
        sta.w $2122
        lda.b #$04
        sta.w $212C
        stz.w $212D
        lda.b #$FF
        sta.w $2112
        sta.w $2112
        ; color math: backdrop + fixed floor color, only inside the map panel
        ; (color window 1, bounds from HDMA channel 0)
        lda.b #$10
        sta.w $2130
        lda.b #$20
        sta.w $2131
        sta.w $2125
        rep #$20
        lda.l !floorc
        and.w #$001F
        ora.w #$0020
        sep #$20
        sta.w $2132
        rep #$20
        lda.l !floorc
        lsr a : lsr a : lsr a : lsr a : lsr a
        and.w #$001F
        ora.w #$0040
        sep #$20
        sta.w $2132
        rep #$20
        lda.l !floorc
        xba
        lsr a : lsr a
        and.w #$001F
        ora.w #$0080
        sep #$20
        sta.w $2132
        lda.b #$01
        sta.w $4300
        lda.b #$26
        sta.w $4301
        lda.b #$B0
        sta.w $4302
        lda.b #$FC
        sta.w $4303
        lda.b #$7F
        sta.w $4304
        lda.b #$01
        sta.w $420C
        lda.b #$0F
        sta.w $2100
        rep #$20
        rts
; CGRAM 16-27: pal4 (P2), pal5 (victims), pal6 (P1/base); wall color patched in; pal7 stays the game's HUD palette (font + arrows)
PalData: dw $0000,$7FFF,$6503,$7D00, $0000,$7FFF,$6503,$03FF, $0000,$7FFF,$6503,$001F

; ---------------------------------------------------------------------------
InitMap:
        sep #$20
        lda.b #$80
        sta.w $2115
        rep #$20
        ; tilemap at VRAM word 0: all blank
        lda.w #$6400
        sta.w $2116
        ldx.w #1024
        lda.w #$18BC
-       sta.w $2118
        dex
        bne -
        stz $F6
        ; glyphs: arrows, blocks and legend pieces (chars 497-518), stored in the unused
        ; tilemap rows 28-31 (VRAM $9F00..) which are never displayed
        lda.w #$4F88
        sta.w $2116
        ldx.w #$0000
.gl:    lda.l GlyphTab,x
        sta.w $2118
        inx
        inx
        cpx.w #$0150
        bne .gl
        jsr Legend
        ; border ring around the panel
        lda.l !wc
        sta $E4
        lda.l !hc
        sta $E6
        lda.l !c0
        sta $E0
        lda.l !r0
        sta $E2
        dec a
        sta $E8
        lda $E2
        clc
        adc $E6
        sta $EA
        lda $E0
        dec a
        sta $EC
        lda $E0
        clc
        adc $E4
        sta $EE
        ldx $E0
.rt:    phx
        lda.w #$1DFB
        ldy $E8
        jsr PutT
        plx
        phx
        lda.w #$9DFB
        ldy $EA
        jsr PutT
        plx
        inx
        cpx $EE
        bne .rt
        ldy $E2
.rl:    phy
        lda.w #$1DFC
        ldx $EC
        jsr PutT
        ply
        phy
        lda.w #$5DFC
        ldx $EE
        jsr PutT
        ply
        iny
        cpy $EA
        bne .rl
        lda.w #$1DFD
        ldx $EC
        ldy $E8
        jsr PutT
        lda.w #$5DFD
        ldx $EE
        ldy $E8
        jsr PutT
        lda.w #$9DFD
        ldx $EC
        ldy $EA
        jsr PutT
        lda.w #$DDFD
        ldx $EE
        ldy $EA
        jsr PutT
        ; blank char (188) then window chars
        lda.w #$4800
        sta.w $2116
        ldx.w #8
        lda.w #0
-       sta.w $2118
        dex
        bne -
        rts

BuildMk:
        rep #$20
        lda.w #0
        sta.l !mkn
; markers are drawn newest-first (see Redraw), so the order added here is the priority:
; players, then victims, then (easter egg) items; the 84-marker cap trims items first
        ldx.w #$0000
.pl:    phx
        lda.w $1E88,x
        beq .nopl
        ldy.w $00D2,x
        beq .nopl
        lda.w $1E84,x
        bne .julie
        lda.w #$18BD
        bra .pcol
.julie: lda.w #$10BD
.pcol:  sta $EE
        lda.w $0002,y
        lsr a : lsr a : lsr a
        sec
        sbc.l !ox
        sta $E6
        lda.w $0006,y
        lsr a : lsr a : lsr a
        sec
        sbc.l !oy
        sta $E8
        ; 3x3 block
        lda.w #$FFFF
        sta $EA                         ; dy
.dy:    lda.w #$FFFF
        sta $EC                         ; dx
.dx:    lda $E6
        clc
        adc $EC
        tax
        lda $E8
        clc
        adc $EA
        tay
        jsr AddMk
        inc $EC
        lda $EC
        cmp.w #2
        bne .dx
        inc $EA
        lda $EA
        cmp.w #2
        bne .dy
.nopl:  plx
        inx
        inx
        cpx.w #$0004
        bne .pl

; ---- exit door(s) (2x2, yellow like the victims): the door is created next to the player who saves the last victim ----
        lda.w #$14BD
        sta $EE
        ldx.w #$0000
.xl:    lda.l !exx,x
        ora.l !exy,x
        beq .xn
        phx
        lda.l !exy,x
        tay
        lda.l !exx,x
        tax
        jsr Mk2x2
        plx
.xn:    inx
        inx
        cpx.w #$0004
        bne .xl

; ---- victims (2x2) ----
        lda.w #$14BD
        sta $EE
        lda.l $7E6E30
        cmp.w #16
        bcc +
        lda.w #15
+       sta $E0
        stz $E2
.vl:    lda $E2
        cmp $E0
        bcs .vdone
        tax
        lda.l $7E605A,x
        and.w #$0080
        bne .vnext
        lda $E2
        asl a : asl a
        tax
        lda.l $7E6DF4,x
        ora.l $7E6DF6,x
        beq .vnext
        lda.l $7E6DF6,x
        tay
        lda.l $7E6DF4,x
        tax
        jsr Mk2x2
.vnext: inc $E2
        bra .vl
.vdone:
; ---- easter egg: items still lying around (white, 1 px) ----
        lda.l !egg
        cmp.w #2
        bne .idone
        lda.w #$08BD
        sta $EE
        stz $E2
.il:    ldx $E2
        lda.l $7E1EC4,x
        cmp.w #$C000
        beq .idone
        and.w #$C000
        bne .inext
        lda.l $7E6D02,x
        ora.l $7E6D48,x
        beq .inext
        lda.l $7E6D48,x
        tay
        lda.l $7E6D02,x
        tax
        jsr Mk1x1
.inext: lda $E2
        inc a : inc a
        sta $E2
        cmp.w #$0046
        bcc .il
.idone: rts

; Mk1x1 / Mk2x2: X,Y = world pixel position, $EE = tilemap palette bits.  When fog is on, nothing is
; added for a spot that is still hidden in the fog.
Mk2x2:  jsr FogMk
        bcs +
        rts
+       ldx $E6
        ldy $E8
        jsr AddMk
        ldx $E6
        inx
        ldy $E8
        jsr AddMk
        ldx $E6
        ldy $E8
        iny
        jsr AddMk
        ldx $E6
        inx
        ldy $E8
        iny
        jmp AddMk
Mk1x1:  jsr FogMk
        bcs +
        rts
+       ldx $E6
        ldy $E8
        jmp AddMk

; FogMk: world X,Y -> window pixel in $E6/$E8; carry set = visible (not fogged)
FogMk:  stx $EA
        sty $E8
        lda.l !fogon
        beq .show
        lda $E8
        lsr a : lsr a : lsr a : lsr a : lsr a : lsr a
        tay
        lda.w #0
.m:     cpy.w #0
        beq .md
        clc
        adc.l !wb8
        dey
        bra .m
.md:    sta $E4
        lda $EA
        lsr a : lsr a : lsr a : lsr a : lsr a : lsr a
        clc
        adc $E4
        cmp.w #$0200
        bcs .show
        tax
        sep #$20
        lda.l !fog,x
        rep #$20
        and.w #$00FF
        bne .show
        clc
        rts
.show:  lda $EA
        lsr a : lsr a : lsr a
        sec
        sbc.l !ox
        sta $E6
        lda $E8
        lsr a : lsr a : lsr a
        sec
        sbc.l !oy
        sta $E8
        sec
        rts


Arrows:
        sep #$20
.aw:    lda.w $4210
        bpl .aw
        rep #$20
ArrowsNow:
        stz $EE
        lda.l !W
        sec
        sbc.w #176
        bcc .r0
        cmp.l !ox
        beq .r0
        bcc .r0
        inc $EE
.r0:    ldx.w #ArrR-ArrR
        jsr PutArrow
        stz $EE
        lda.l !ox
        beq .l0
        inc $EE
.l0:    ldx.w #ArrL-ArrR
        jsr PutArrow
        stz $EE
        lda.l !H
        sec
        sbc.w #112
        bcc .d0
        cmp.l !oy
        beq .d0
        bcc .d0
        inc $EE
.d0:    ldx.w #ArrD-ArrR
        jsr PutArrow
        stz $EE
        lda.l !oy
        beq .u0
        inc $EE
.u0:    ldx.w #ArrU-ArrR
        jsr PutArrow
        rts

; AddMk: X,Y = marker pixel (window coords), $EE high byte = tilemap palette bits
AddMk:
        cpx.w #176
        bcc +
        rts
+       cpy.w #112
        bcc +
        rts
+       stx $F0
        sty $F2
        lda.l !mkn
        cmp.w #120
        bcc +
        rts
+       sta $F4
        asl a
        clc
        adc $F4
        tax
        sep #$20
        lda $F0
        sta.l !mk,x
        lda $F2
        sta.l !mk+1,x
        lda $EF
        sta.l !mk+2,x
        rep #$20
        lda.l !mkn
        inc a
        sta.l !mkn
        rts

; ---------------------------------------------------------------------------
; Window cells.  A cell of the level keeps the same character slot while the window scrolls over it:
;     slot = ((oy/8 + row) mod hc) * wc + ((ox/8 + col) mod wc)         (character number = $BD + slot)
; so a scroll step only has to draw the row or column that comes into view and shift the tilemap.
SetRing:                                ; !oxm = (ox/8) mod wc, !oym = (oy/8) mod hc
        rep #$20
        lda.l !ox
        lsr a : lsr a : lsr a
-       cmp.l !wc
        bcc +
        sec
        sbc.l !wc
        bra -
+       sta.l !oxm
        lda.l !oy
        lsr a : lsr a : lsr a
-       cmp.l !hc
        bcc +
        sec
        sbc.l !hc
        bra -
+       sta.l !oym
        rts

RowBase:                                ; A = window cell row -> A = slot row * wc
        clc
        adc.l !oym
        cmp.l !hc
        bcc +
        sec
        sbc.l !hc
+       tax
        lda.w #0
-       cpx.w #0
        beq +
        clc
        adc.l !wc
        dex
        bra -
+       rts

ColSlot:                                ; A = window cell column -> A = slot column
        clc
        adc.l !oxm
        cmp.l !wc
        bcc +
        sec
        sbc.l !wc
+       rts

; RenderRange: draw the window cells rows !ra..!rb-1, columns !ca..!cb-1 (one of the two ranges is a single
; line) into rbuf (16 bytes per cell) and tbuf (tilemap word per cell), in row-major order, markers included.
RenderRange:
        rep #$20
        lda.w #0
        sta $EC                         ; byte offset in rbuf
        sta $EA                         ; byte offset in tbuf
        lda.l !ra
        sta $F6                         ; window cell row
.cy:    lda $F6
        asl a : asl a : asl a
        clc
        adc.l !oy
        sta $E2                         ; level tile row of the cell row
        cmp.l !H
        bcc +
        lda.w #0
        bra ++
+       lda.w #1
++      sta $E0                         ; 1 = inside the level
        lda $E2
        asl a
        sta $FA
        lda $E2
        lsr a : lsr a : lsr a
        tay
        lda.w #0
.mu:    cpy.w #0
        beq .md
        clc
        adc.l !wb8
        dey
        bra .mu
.md:    sta $FE
        lda $F6
        jsr RowBase
        sta $E6                         ; slot row * wc
        lda.l !ca
        sta $F4                         ; window cell column
.cx:    lda $F4
        asl a : asl a : asl a
        clc
        adc.l !ox
        sta $E4
        asl a
        sta $FC
        lda $E0
        bne +
        jmp .blank
+       lda $E4
        cmp.l !W
        bcc +
        jmp .blank
+       lda.l !fogon
        beq .nofog
        lda $E4
        lsr a : lsr a : lsr a
        clc
        adc $FE
        cmp.w #$0200
        bcs .nofog
        tax
        sep #$20
        lda.l !fog,x
        rep #$20
        and.w #$00FF
        bne .nofog
        jmp .fogb
.nofog: lda $F4
        jsr ColSlot
        clc
        adc $E6
        clc
        adc.w #$18BD
        ldx $EA
        sta.l !tbuf,x
        stz $F8
.r:     lda $F8
        asl a
        clc
        adc $FA
        tax
        lda.l $7E4328,x
        clc
        adc $FC
        tax
        stz $F0
        stz $F2
        %px()
        %px()
        %px()
        %px()
        %px()
        %px()
        %px()
        %px()
        lda $F2
        xba
        ora $F0
        ldx $EC
        sta.l !rbuf,x
        inx
        inx
        stx $EC
        inc $F8
        lda $F8
        cmp.w #8
        beq +
        jmp .r
+       bra .next
.blank: lda.w #$1DFA
        bra .bset
.fogb:  lda.w #$0DFA
.bset:  ldx $EA
        sta.l !tbuf,x
        ldx $EC
        ldy.w #8
        lda.w #0
-       sta.l !rbuf,x
        inx
        inx
        dey
        bne -
        stx $EC
.next:  inc $EA
        inc $EA
        inc $F4
        lda $F4
        cmp.l !cb
        beq +
        jmp .cx
+       inc $F6
        lda $F6
        cmp.l !rb
        beq +
        jmp .cy
+       ; ---- markers that fall inside the range: newest first, so the oldest (highest priority) is drawn last ----
        lda.l !mkn
        sta $E0
        dec a
        sta $E8
        asl a
        clc
        adc $E8
        sta $E8
.mk:    lda $E0
        bne +
        rts
+       ldx $E8
        lda.l !mk+1,x
        and.w #$00FF
        sta $F2                         ; pixel y
        lsr a : lsr a : lsr a
        cmp.l !ra
        bcs +
        jmp .mkx
+
        cmp.l !rb
        bcc +
        jmp .mkx
+
        sta $F6                         ; cell row
        lda.l !mk,x
        and.w #$00FF
        sta $F0                         ; pixel x
        lsr a : lsr a : lsr a
        cmp.l !ca
        bcs +
        jmp .mkx
+
        cmp.l !cb
        bcc +
        jmp .mkx
+
        sta $FC                         ; cell column
        lda $F6
        sec
        sbc.l !ra
        sta $FA
        lda $FC
        sec
        sbc.l !ca
        clc
        adc $FA
        sta $F4                         ; cell number within the range (one of the two spans is 1)
        asl a : asl a : asl a : asl a
        sta $FA
        lda $F2
        and.w #$0007
        asl a
        clc
        adc $FA
        sta $FA                         ; rbuf byte offset of the pixel row
        lda $F0
        and.w #$0007
        tax
        lda.l BitTab,x
        and.w #$00FF
        sta $F0
        xba
        ora $F0
        sta $F0                         ; bit in both planes
        ldx $FA
        lda.l !rbuf,x
        ora $F0
        sta.l !rbuf,x
        lda $F6                         ; the cell's tilemap word: its slot, with the marker's palette
        jsr RowBase
        sta $F0
        lda $FC
        jsr ColSlot
        clc
        adc $F0
        clc
        adc.w #$00BD
        sta $F0
        ldx $E8
        lda.l !mk+2,x
        and.w #$00FF
        xba
        ora $F0
        sta $F0
        lda $F4
        asl a
        tax
        lda $F0
        sta.l !tbuf,x
.mkx:   lda $E8
        sec
        sbc.w #3
        sta $E8
        dec $E0
        jmp .mk

; WaitVb: wait for the start of a vblank (the full vblank is then available) and set up DMA channel 7 for VRAM writes
WaitVb: sep #$20
.w0:    lda.w $4212
        bmi .w0
.w1:    lda.w $4212
        bpl .w1
        lda.b #$80
        sta.w $2115
        lda.b #$01
        sta.w $4370
        lda.b #$18
        sta.w $4371
        lda.b #$7F
        sta.w $4374
        rep #$20
        rts

; FlushChars: send the cells of the last RenderRange from rbuf to their character slots (vblank).
; A full row is two DMAs (its slots are one run that wraps once), a column goes cell by cell.
FlushChars:
        rep #$20
        lda.l !ra
        jsr RowBase
        sta $FA                         ; slot row * wc of the first cell
        lda.l !ca
        jsr ColSlot
        sta $FC                         ; slot column of the first cell
        lda.l !cb
        sec
        sbc.l !ca
        cmp.w #1
        beq .col
        lda.l !wc                       ; ---- a full row: slot columns $FC..wc-1, then 0..$FC-1
        sec
        sbc $FC
        sta $F6                         ; cells in the first run
        lda $FA
        clc
        adc $FC
        asl a : asl a : asl a
        clc
        adc.w #$45E8
        sta.w $2116
        lda.w #!rbuf&$FFFF
        sta.w $4372
        lda $F6
        asl a : asl a : asl a : asl a
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
        lda $FC
        beq .rd
        lda $FA
        asl a : asl a : asl a
        clc
        adc.w #$45E8
        sta.w $2116
        lda $F6
        asl a : asl a : asl a : asl a
        clc
        adc.w #!rbuf&$FFFF
        sta.w $4372
        lda $FC
        asl a : asl a : asl a : asl a
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
.rd:    rts
.col:   lda.l !rb                       ; ---- one column: the cells are slot rows apart
        sec
        sbc.l !ra
        sta $F8                         ; cells
        lda.l !hc                       ; slots in all = hc * wc
        tax
        lda.w #0
-       clc
        adc.l !wc
        dex
        bne -
        sta $EE
        lda.w #!rbuf&$FFFF
        sta $F0
.fc:    lda $FA
        clc
        adc $FC
        asl a : asl a : asl a
        clc
        adc.w #$45E8
        sta.w $2116
        lda $F0
        sta.w $4372
        lda.w #16
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
        lda $F0
        clc
        adc.w #16
        sta $F0
        lda $FA
        clc
        adc.l !wc
        cmp $EE
        bcc +
        lda.w #0
+       sta $FA
        dec $F8
        bne .fc
        rts

; ReadVram: read $F4 bytes of VRAM from word address $F0 into rbuf (channel 7)
ReadVram:
        rep #$20
        lda $F0
        sta.w $2116
        sep #$20
        lda.l !dummy
        beq +
        lda.w $2139
        lda.w $213A
+       lda.b #$81
        sta.w $4370
        lda.b #$39
        sta.w $4371
        rep #$20
        lda.w #!rbuf&$FFFF
        sta.w $4372
        lda $F4
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        lda.b #$01
        sta.w $4370
        lda.b #$18
        sta.w $4371
        rep #$20
        rts

; WriteBuf: copy $F4 bytes from WRAM bank 7F address $F2 to the VRAM word address $F0
WriteBuf:
        rep #$20
        lda $F0
        sta.w $2116
        lda $F2
        sta.w $4372
        lda $F4
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
        rts

; MoveWords: copy $E4 words inside VRAM from word address $E0 to $E2, a piece at a time through the first 256 bytes of rbuf;
; $E6 = 0 copies from the start, 1 from the end (needed when the destination lies after the source)
MoveWords:
        rep #$20
.mw:    lda $E4
        beq .md
        cmp.w #128
        bcc +
        lda.w #128
+       sta $F6                         ; words in this piece
        asl a
        sta $F4                         ; bytes
        lda $E6
        bne .desc
        lda $E0
        sta $F0
        jsr ReadVram
        lda $E2
        sta $F0
        lda.w #!rbuf&$FFFF
        sta $F2
        jsr WriteBuf
        lda $E0
        clc
        adc $F6
        sta $E0
        lda $E2
        clc
        adc $F6
        sta $E2
        lda $E4
        sec
        sbc $F6
        sta $E4
        bra .mw
.desc:  lda $E4
        sec
        sbc $F6
        sta $F8                         ; where the last piece starts
        clc
        adc $E0
        sta $F0
        jsr ReadVram
        lda $F8
        clc
        adc $E2
        sta $F0
        lda.w #!rbuf&$FFFF
        sta $F2
        jsr WriteBuf
        lda $F8
        sta $E4
        bra .mw
.md:    rts

; RowAddr: A = panel row -> A = tilemap word address of its first cell
RowAddr:
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.l !tbase
        rts

; the tilemap block that holds the panel: whole rows, $E8 = first word, $EA = words
PanelBlock:
        lda.l !r0
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.w #$6400
        sta $E8
        lda.l !hc
        asl a : asl a : asl a : asl a : asl a
        sta $EA
        rts

; ColWrite: $F0 = first VRAM word, $F2 = WRAM source: hc words down one tilemap column
ColWrite:
        rep #$20
        lda $F0
        sta.w $2116
        lda $F2
        sta.w $4372
        lda.l !hc
        asl a
        sta.w $4375
        sep #$20
        lda.b #$81                      ; VRAM address steps one tilemap row per word
        sta.w $2115
        lda.b #$80
        sta.w $420B
        lda.b #$80
        sta.w $2115
        rep #$20
        rts

; FillBar: hc words of A at rbuf + X (a frame bar column, made before the vblank)
FillBar:
        sta $F0
        stx $F2
        lda.l !hc
        asl a
        clc
        adc $F2
        tax
        lda $F0
-       sta.l !rbuf-2,x
        dex
        dex
        cpx $F2
        bne -
        rts

; BlankCol: A = tilemap column: blank the hc words of that column of the panel block ($E8 = block start)
BlankCol:
        clc
        adc $E8
        sta $F0
        lda.w #!blk&$FFFF
        sta $F2
        jmp ColWrite

; ShiftH: the window moved one cell sideways (!sdir 0 = right): move the whole tilemap block by one word, then
; repair the columns that it damaged (frame bars, the new cell column) and the arrows
ShiftH:
        rep #$20
        jsr PanelBlock
        lda $EA
        dec a
        sta $E4                         ; words to move
        lda.l !sdir
        bne .left
        lda $E8                         ; right: every word takes its right neighbour
        inc a
        sta $E0
        lda $E8
        sta $E2
        stz $E6
        bra .go
.left:  lda $E8
        sta $E0
        inc a
        sta $E2
        lda.w #1
        sta $E6
.go:    jsr MoveWords
        jsr PanelBlock
        lda.l !sdir                     ; the move left copies of the frame bars and arrows one word aside: blank them
        bne .bl
        lda.w #1
        jsr BlankCol
        lda.l !c0
        sec
        sbc.w #2
        jsr BlankCol
        bra .bd
.bl:    lda.w #4
        jsr BlankCol
        lda.w #30
        jsr BlankCol
        lda.l !c0
        clc
        adc.l !wc
        inc a
        jsr BlankCol
.bd:    lda $E8                         ; frame bars (made at rbuf+256 and +288 before the vblank)
        clc
        adc.l !c0
        dec a
        sta $F0
        lda.w #(!rbuf&$FFFF)+256
        sta $F2
        jsr ColWrite
        lda $E8
        clc
        adc.l !c0
        clc
        adc.l !wc
        sta $F0
        lda.w #(!rbuf&$FFFF)+288
        sta $F2
        jsr ColWrite
        lda $E8                         ; the new cell column
        clc
        adc.l !c0
        sta $F0
        lda.l !sdir
        bne +
        lda $F0
        clc
        adc.l !wc
        dec a
        sta $F0
+       lda.w #!tbuf&$FFFF
        sta $F2
        jsr ColWrite
        jmp ArrowsLR

; ShiftV: the window moved one cell down (!sdir 0) or up: move the tilemap block by one row, write the new row
ShiftV:
        rep #$20
        jsr PanelBlock
        lda $EA
        sec
        sbc.w #32
        sta $E4
        lda.l !sdir
        bne .up
        lda $E8                         ; down: every row takes the row below
        clc
        adc.w #32
        sta $E0
        lda $E8
        sta $E2
        stz $E6
        bra .go
.up:    lda $E8
        sta $E0
        clc
        adc.w #32
        sta $E2
        lda.w #1
        sta $E6
.go:    jsr MoveWords
        jsr PanelBlock
        lda $E8                         ; the new row: last row going down, first row going up
        clc
        adc.l !c0
        sta $F0
        lda.l !sdir
        bne +
        lda $EA
        sec
        sbc.w #32
        clc
        adc $F0
        sta $F0
+       lda.w #!tbuf&$FFFF
        sta $F2
        lda.l !wc
        asl a
        sta $F4
        jsr WriteBuf
        jsr ArrowsAll
        ; The left and right arrows sit in the rows that were moved, so their cells moved one row too: ArrowsAll drew them in
        ; their place again, and the row they left (above when going down, below when going up) is blanked, or the arrows
        ; would smear a little further with every step.
        ldx.w #0
.cl:    lda.l ArrClr,x
        sta.w $2116
        lda.w #$18BC
        sta.w $2118
        sta.w $2118
        inx
        inx
        cpx.w #8
        bne .cl
        rts

ArrClr: dw $65BC,$65A2,$661C,$6602              ; right / left arrow cells, the row above and the row below the arrow

; ArrowFlags: which of the four arrows are lit for the current origin (same rules as Arrows)
ArrowFlags:
        rep #$20
        lda.w #0
        sta.l !arR
        sta.l !arL
        sta.l !arD
        sta.l !arU
        lda.l !W
        sec
        sbc.w #176
        bcc .r0
        cmp.l !ox
        beq .r0
        bcc .r0
        lda.w #1
        sta.l !arR
.r0:    lda.l !ox
        beq .l0
        lda.w #1
        sta.l !arL
.l0:    lda.l !H
        sec
        sbc.w #112
        bcc .d0
        cmp.l !oy
        beq .d0
        bcc .d0
        lda.w #1
        sta.l !arD
.d0:    lda.l !oy
        beq .u0
        lda.w #1
        sta.l !arU
.u0:    rts

macro arrw(o)
        lda $F0
        beq ?b
        lda.l ArrR+<o>,x
        bra ?s
?b:     lda.w #$18BC
?s:     sta.w $2118
endmacro

; ArrGroup: X = offset of the arrow's 4 cells in the arrow tables, $F0 = lit flag, $F2 / $F4 = tilemap address of its two cell rows
ArrGroup:
        lda $F2
        sta.w $2116
        %arrw(0)
        %arrw(6)
        lda $F4
        sta.w $2116
        %arrw(12)
        %arrw(18)
        rts

; ArrowsLR / ArrowsAll: rewrite the arrows during the vblank work of a scroll step
; (the left and right ones sit inside the tilemap block that was moved; the up and down ones change when an end is reached)
ArrowsLR:
        rep #$20
        lda.l !arR
        sta $F0
        ldx.w #ArrR-ArrR
        lda.w #$65DC
        sta $F2
        lda.w #$65FC
        sta $F4
        jsr ArrGroup
        lda.l !arL
        sta $F0
        ldx.w #ArrL-ArrR
        lda.w #$65C2
        sta $F2
        lda.w #$65E2
        sta $F4
        jmp ArrGroup

ArrowsAll:
        jsr ArrowsLR
        lda.l !arD
        sta $F0
        ldx.w #ArrD-ArrR
        lda.w #$66EF
        sta $F2
        lda.w #$670F
        sta $F4
        jsr ArrGroup
        lda.l !arU
        sta $F0
        ldx.w #ArrU-ArrR
        lda.w #$64AF
        sta $F2
        lda.w #$64CF
        sta $F4
        jmp ArrGroup

; ScrollH / ScrollV: A = 0 right / down, 1 left / up.  Moves the window by one cell (8 tiles); only the cells
; that come into view are drawn, the rest of the picture is shifted.
ScrollH:
        rep #$20
        sta.l !sdir
        lda.l !ox
        sta.l !told
        lda.l !sdir
        bne .l
        lda.l !ox
        clc
        adc.w #8
        bra .s
.l:     lda.l !ox
        sec
        sbc.w #8
.s:     sta.l !ox
        jsr Clamp
        lda.l !ox
        cmp.l !told
        bne +
        rts
+       jsr SetRing
        jsr BuildMk
        lda.w #0
        sta.l !ra
        lda.l !hc
        sta.l !rb
        lda.l !sdir
        bne .c0
        lda.l !wc
        dec a
        bra .c1
.c0:    lda.w #0
.c1:    sta.l !ca
        inc a
        sta.l !cb
        jsr RenderRange
        lda.w #$1DFC
        ldx.w #256
        jsr FillBar
        lda.w #$5DFC
        ldx.w #288
        jsr FillBar
        lda.w #$0DFA
        ldx.w #320
        jsr FillBar
        lda.l !hc
        asl a
        tax
        lda.w #$18BC
-       sta.l !blk-2,x
        dex
        dex
        bne -
        jsr ArrowFlags
        jsr WaitVb                      ; vblank 1: blank the column that is about to scroll out, then draw the new
        jsr PanelBlock                  ; cells into its character slots (nothing shows them yet)
        lda $E8
        clc
        adc.l !c0
        sta $F0
        lda.l !sdir
        beq +
        lda $F0
        clc
        adc.l !wc
        dec a
        sta $F0
+       lda.w #(!rbuf&$FFFF)+320
        sta $F2
        jsr ColWrite
        jsr FlushChars
        jsr WaitVb                      ; vblank 2: slide the tilemap and add the new column
        jmp ShiftH

ScrollV:
        rep #$20
        sta.l !sdir
        lda.l !oy
        sta.l !told
        lda.l !sdir
        bne .u
        lda.l !oy
        clc
        adc.w #8
        bra .s
.u:     lda.l !oy
        sec
        sbc.w #8
.s:     sta.l !oy
        jsr Clamp
        lda.l !oy
        cmp.l !told
        bne +
        rts
+       jsr SetRing
        jsr BuildMk
        lda.w #0
        sta.l !ca
        lda.l !wc
        sta.l !cb
        lda.l !sdir
        bne .r0
        lda.l !hc
        dec a
        bra .r1
.r0:    lda.w #0
.r1:    sta.l !ra
        inc a
        sta.l !rb
        jsr RenderRange
        jsr ArrowFlags
        jsr WaitVb
        jsr FlushChars
        jmp ShiftV

; Redraw: the whole window, one cell row at a time (draw the row with the display on, send it in vblank)
Redraw:
        rep #$20
        jsr SetRing
        lda.w #0
        sta.l !cnt
        sta.l !ca
        lda.l !wc
        sta.l !cb
.row:   lda.l !cnt
        sta.l !ra
        inc a
        sta.l !rb
        jsr RenderRange
        jsr WaitVb
        jsr FlushChars
        lda.l !cnt
        jsr RowAddr
        sta.w $2116
        lda.w #!tbuf&$FFFF
        sta.w $4372
        lda.l !wc
        asl a
        sta.w $4375
        sep #$20
        lda.b #$80
        sta.w $420B
        rep #$20
        lda.l !cnt
        inc a
        sta.l !cnt
        cmp.l !hc
        bne .row
        rts


BitTab: db $80,$40,$20,$10,$08,$04,$02,$01

; ---------------------------------------------------------------------------
; explored-area tracking (1 byte per 8x8-tile block at 7F:EC00)
; Wipe the explored-area array. Called from MarkFog (never from the level loader) when a
; player becomes active after the title/demo, or when the level number changes.
ClearFogBody:
        lda.w #0
        sta.l !exx
        sta.l !exx+2
        sta.l !exy
        sta.l !exy+2
        ldx.w #$01FE
        lda.w #0
.c:     sta.l !fog,x
        dex
        dex
        bpl .c
        lda.w #1
        sta.l !fogon
        lda.w #$FFFF
        sta.l !lastp
        sta.l !lastp+2
        lda.w #0
        sta.l !need
        lda.w $1E7C
        sta.l !lvl
        rts

; ExitHook: runs inside the exit-door spawner (bank 82, task DP: $00/$02 = door x/y, $06 = player slot)
ExitHook:
        sta $08                         ; the two instructions this replaced
        phx
        lda $06
        and.w #$0002
        tax
        lda $00
        sta.l !exx,x
        lda $02
        sta.l !exy,x
        plx
        lda $00
        rtl

MarkFog:
        lda.w $1EB4                     ; attract demo playing? keep this path tiny and constant so the
        beq .play                       ; demos (recorded against the original timing) stay in step
.tog:   lda.b $24                       ; the instructions this hook replaced
        eor.w #$0001
        sta.b $24
        rtl
.play:  lda.l $7FFA00                   ; paused: nobody moves, so nothing to mark.  The pause loop runs on a task stack with little room
        bne .tog                        ; (the stack of another task starts right below it, and the NMI pushes 13 bytes on top of the stack in use)
        php
        rep #$30
        pha
        phx
        phy
        phb
        pea.w $0000
        plb
        plb
        lda.w $1E88
        ora.w $1E8A
        bne .act
        lda.w #1                        ; nobody playing (title, demo end, game over): re-arm
        sta.l !need
        bra .go
.act:   lda.l !need
        bne .clr
        lda.w $1E7C
        cmp.l !lvl
        beq .go
.clr:   jsr ClearFogBody                ; new game / new level
.go:    ldx.w #$0000
.pl:    lda.w $00D2,x
        beq .nx
        cmp.w #$2000
        bcs .nx
        tay
        lda.w $1E88,x
        beq .nx
        lda.w $0002,y
        lsr a : lsr a : lsr a : lsr a : lsr a : lsr a
        sta.l !t0
        lda.w $0006,y
        lsr a : lsr a : lsr a : lsr a : lsr a : lsr a
        sta.l !t1
        xba
        ora.l !t0
        cmp.l !lastp,x
        beq .nx
        sta.l !lastp,x
        phx
        jsr MarkBlocks
        plx
.nx:    inx
        inx
        cpx.w #$0004
        beq .done
        jmp .pl
.done:  plb
        ply
        plx
        pla
        plp
        lda.b $24
        eor.w #$0001
        sta.b $24
        rtl

MarkBlocks:
        lda.w $00B2
        lsr a : lsr a : lsr a : lsr a
        sta.l !t2
        lda.w $00B4
        lsr a : lsr a : lsr a
        sta.l !t3
        lda.l !t1
        sec
        sbc.w #2
        sta.l !t4
        ldx.w #5
.row:   phx
        lda.l !t4
        bmi .rs
        cmp.l !t3
        bcs .rs
        tay
        lda.w #0
.mu:    cpy.w #0
        beq .md
        clc
        adc.l !t2
        dey
        bra .mu
.md:    sta.l !t5
        lda.l !t0
        sec
        sbc.w #2
        sta.l !t7
        ldx.w #5
.col:   lda.l !t7
        bmi .cs
        cmp.l !t2
        bcs .cs
        clc
        adc.l !t5
        cmp.w #$0200
        bcs .cs
        tay
        sep #$20
        lda.b #1
        phx
        tyx
        sta.l !fog,x
        plx
        rep #$20
.cs:    lda.l !t7
        inc a
        sta.l !t7
        dex
        bne .col
.rs:    lda.l !t4
        inc a
        sta.l !t4
        plx
        dex
        bne .row
        rts

; Dig: A = number (0-99) -> A = its digit count
Dig:    cmp.w #10
        bcc +
        lda.w #2
        rts
+       lda.w #1
        rts

; CenterCol: A = text width in cells -> $E6 = first column that centers it on the 32-cell screen
CenterCol:
        sta $EA
        lda.w #32
        sec
        sbc $EA
        lsr a
        sta $E6
        rts

; A = tilemap word, X = column, Y = row (BG3 map at VRAM $4C00)
PutT:
        pha
        tya
        asl a : asl a : asl a : asl a : asl a
        clc
        adc.w #$6400
        sta $F0
        txa
        clc
        adc $F0
        sta.w $2116
        pla
        sta.w $2118
        rts


; Legend: row 1 = [ZEKE] [JULIE] (only active players), row 3 = victims left, row 26 = LEVEL n, all centered;
; a blank row separates each pair of text rows (the up arrow sits at rows 5-6, the down arrow at rows 23-24)
Legend:
        stz $F4
        stz $F6
        ldx.w #$0000
.pc:    lda.w $1E88,x
        beq .pn
        lda.w $1E84,x
        beq .pz
        inc $F6
        bra .pn
.pz:    inc $F4
.pn:    inx
        inx
        cpx.w #4
        bne .pc
        ; ---- players, centered on row 1 ----
        lda.w #1
        sta $F8
        stz $EA
        lda $F4
        beq +
        lda.w #6
        sta $EA
+       lda $F6
        beq +
        lda $EA
        clc
        adc.w #7
        sta $EA
+       lda $EA
        beq .bot
        dec a
        sta $EA
        lda.w #32
        sec
        sbc $EA
        lsr a
        sta $E6
        lda $F4
        beq +
        lda.w #5
        sta $EE
        ldx.w #LT_Zeke-LegendTab
        jsr PutRun
        inc $E6
+       lda $F6
        beq .bot
        lda.w #6
        sta $EE
        ldx.w #LT_Julie-LegendTab
        jsr PutRun
        ; ---- LEVEL n, centered on row 26 (the down arrow is at rows 23-24) ----
.bot:   lda.w #26
        sta $F8
        lda.w $1E7C
        jsr Dig
        clc
        adc.w #6
        jsr CenterCol
        lda.w #5
        sta $EE
        ldx.w #LT_Level-LegendTab
        jsr PutRun
        inc $E6
        lda.w $1E7C
        jsr PutNum
        lda.w #3                        ; victims line: centered on row 3, one blank row under the players
        sta $F8
        lda.l $7E6E30                   ; total victims (0 = none on this level: nothing more to show)
        bne +
        jmp .done
+       cmp.w #16
        bcc +
        lda.w #15
+       sta $E0
        lda.l $7E1D52                   ; victims left (BCD) -> binary in $E4
        and.w #$00FF
        sta $E4
        lsr a : lsr a : lsr a : lsr a
        asl a
        sta $EC
        asl a : asl a
        clc
        adc $EC
        sta $EC
        lda $E4
        and.w #$000F
        clc
        adc $EC
        sta $E4
        lda $E0
        jsr Dig
        sta $EC                         ; digits in the total
        lda $E4
        beq .allw
        jsr Dig
        clc
        adc $EC
        clc
        adc.w #15                       ; swatch, n, slash, total, gap, LEFT TO SAVE
        bra .cw
.allw:  lda.l !exx
        ora.l !exx+2
        beq .nodw
        lda.w #6                        ; swatch, EXIT (one pixel right, so the gap matches the player rows)
        bra .cw
.nodw:  lda $EC
        clc
        adc.w #10                       ; ALL, gap, total, gap, SAVED
.cw:    jsr CenterCol
        lda $E4
        beq .all
        lda $E4                         ; the digit after the swatch decides where the icon sits, so that the gap is always 3 pixels:
        cmp.w #1                        ; 1 (n = 1, 10-15) leaves 2 extra blank columns -> icon one pixel to the right,
        beq .sw1                        ; 2-9 start in column 0 -> icon one pixel to the left
        cmp.w #10
        bcs .sw1
        dec $E6
        lda.w #$1600
        ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
        lda.w #$1601
        bra .sw2
.sw1:   lda.w #$15FF
.sw2:   ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
        lda $E4
        jsr PutNum
        lda.w #$1DFE                    ; slash
        ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
        lda $E0
        jsr PutNum
        inc $E6
        lda.w #12
        sta $EE
        ldx.w #LT_Left-LegendTab
        jsr PutRun
        rts
.all:   lda.l !exx
        ora.l !exx+2
        beq .nodoor
        lda.w #1                        ; the exit door is open: swatch + EXIT
        sta $EE
        ldx.w #LT_Sw-LegendTab
        jsr PutRun
        lda.w #5
        sta $EE
        ldx.w #LT_Exit-LegendTab
        jsr PutRun
        rts
.nodoor: lda.w #3                       ; ALL n SAVED
        sta $EE
        ldx.w #LT_All-LegendTab
        jsr PutRun
        inc $E6
        lda $E0
        jsr PutNum
        inc $E6
        lda.w #5
        sta $EE
        ldx.w #LT_Saved-LegendTab
        jsr PutRun
.done:  rts

PutRun:
.l:     phx
        lda.l LegendTab,x
        ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
        plx
        inx
        inx
        dec $EE
        bne .l
        rts

PutNum:
        ldx.w #$0000
.dv:    cmp.w #10
        bcc .dd
        sbc.w #10
        inx
        bra .dv
.dd:    sta $EE
        cpx.w #0
        beq .one
        txa
        clc
        adc.w #$1C07
        ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
.one:   lda $EE
        clc
        adc.w #$1C07
        ldx $E6
        ldy $F8
        jsr PutT
        inc $E6
        rts

GlyphTab:
        dw $0000,$0000,$0000,$0000,$0000,$FF00,$807F,$807F
        dw $8000,$C000,$A040,$9060,$8870,$04F8,$02FC,$01FE
        dw $807F,$807F,$FF00,$0000,$0000,$0000,$0000,$0000
        dw $01FE,$02FC,$04F8,$8870,$9060,$A040,$C000,$8000
        dw $0700,$0403,$0403,$0403,$0403,$0403,$0403,$0403
        dw $E000,$20C0,$20C0,$20C0,$20C0,$20C0,$20C0,$20C0
        dw $F807,$403F,$201F,$100F,$0807,$0403,$0201,$0100
        dw $1FE0,$02FC,$04F8,$08F0,$10E0,$20C0,$4080,$8000
        dw $FCFC,$FCFC,$FCFC,$FCFC,$FCFC,$FCFC,$FCFC,$FCFC
        dw $FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF,$FFFF
        dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$00FF
        dw $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
        dw $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0001
        ; slash: 7 rows like the digits, one pixel step per row (x = 6,5,4,3,3,2,1), banded like the font (orange, orange, light, light, orange x3)
        dw $0200,$0400,$0008,$0010,$1000,$2000,$4000,$0000
        dw $7E7E,$7E7E,$7E7E,$7E7E,$7E7E,$7E7E,$7E7E,$7E7E   ; char 511: swatch, icon shifted right one pixel (columns 1-6)
        dw $0101,$0101,$0101,$0101,$0101,$0101,$0101,$0101   ; char 512: right edge of the swatch, icon starts one pixel left of its tile
        dw $F8F8,$F8F8,$F8F8,$F8F8,$F8F8,$F8F8,$F8F8,$F8F8   ; char 513: the rest of that swatch (columns 0-4)
        dw $7F00,$7F1F,$1070,$007F,$7F1F,$7010,$7F00,$3F3F   ; char 514: EXIT, shifted one pixel right (E)
        dw $6300,$F780,$013F,$021E,$BE80,$7F08,$7310,$B1B1   ; char 515: EXIT, shifted one pixel right (X)
        dw $1E00,$8F83,$020E,$020E,$0E02,$0E02,$9E80,$8787   ; char 516: EXIT, shifted one pixel right (I)
        dw $3F00,$0F03,$020E,$020E,$0E02,$0E02,$0E02,$0606   ; char 517: EXIT, shifted one pixel right (T)
        dw $0000,$8080,$0000,$0000,$0000,$0000,$0000,$0000   ; char 518: EXIT, shifted one pixel right (spill of the T)

; PutArrow: X = offset into ArrR table (4 cells of word,col,row)
PutArrow:
        ldy.w #4
.pa:    phy
        phx
        lda $EE
        beq .pb0
        lda.l ArrR,x
        bra .pb1
.pb0:   lda.w #$18BC
.pb1:   sta $F2
        lda.l ArrR+2,x
        sta $F4
        lda.l ArrR+4,x
        tay
        ldx $F4
        lda $F2
        jsr PutT
        plx
        txa
        clc
        adc.w #6
        tax
        ply
        dey
        bne .pa
        rts
ArrR:
        dw $1DF1,28,14
        dw $1DF2,29,14
        dw $1DF3,28,15
        dw $1DF4,29,15
ArrL:
        dw $5DF2,2,14
        dw $5DF1,3,14
        dw $5DF4,2,15
        dw $5DF3,3,15
ArrD:
        dw $1DF5,15,23
        dw $1DF6,16,23
        dw $1DF7,15,24
        dw $1DF8,16,24
ArrU:
        dw $9DF7,15,5
        dw $9DF8,16,5
        dw $9DF5,15,6
        dw $9DF6,16,6

; (tilemap word, column) pairs for the legend row
LegendTab:
LT_Zeke:  dw $19F9,$1CA9,$1C94,$1C9A,$1C94
LT_Julie: dw $11F9,$1C99,$1CA4,$1C9B,$1C98,$1C94
LT_Sw:    dw $15F9
LT_Level: dw $1C9B,$1C94,$1CA5,$1C94,$1C9B
LT_Left:  dw $1C9B,$1C94,$1C95,$1CA3,$18BC,$1CA3,$1C9E,$18BC,$1CA2,$1C90,$1CA5,$1C94
LT_All:   dw $1C90,$1C9B,$1C9B
LT_Exit:  dw $1E02,$1E03,$1E04,$1E05,$1E06     ; E X I T and the spill of the T, shifted one pixel right (chars 514-518)
LT_Saved: dw $1CA2,$1C90,$1CA5,$1C94,$1C93
LegendEnd:

HdmaTab:
        db 56,$FF,$00
        db 112,40,215
        db 1,$FF,$00
        db 0

incsrc "tint/tint.asm"
