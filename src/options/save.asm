; ZAMN saved game (RESUME GAME).  Assembled as part of options.asm, right after sram.asm (same bank, continues the code).
;
; SRAM $0200 / $0300: two copies of one $E0-byte record, written one after the other (same scheme as the score record).
;   +0 'ZSAV'   +4 version (1)   +6 checksum of +8..+$DF   +8 record 0 (Zeke)   +$74 record 1 (Julie)
; One record per character ($6C bytes), each a complete picture of that player at the start of a level, plus the game-wide
; values at that moment, so a record stands alone:
;   +0 valid (1)   +2 level ($1E7C)   +4 victim block $1F9C..$1FBB (32)   +$24 $1D50   +$26 $1D52   +$28 health   +$2A lives
;   +$2C weapon   +$2E item   +$30 ammo table (28)   +$4C item table (24)   +$64 score (4)   +$68 bonus threshold (7E:6054+)
; Written when a level is completed (after the next level has been set up) for every player still in the game; the record of a
; player who ran out of lives while the other carried on is wiped then; everything of this game is wiped on game over.

!SAV     = $700200
!SAV2    = $700300
!SLEN    = $00E0
!RLEN    = $006C
!rA      = $7FFE22             ; scratch for the transfer loop
!rB      = $7FFE24
!rC      = $7FFE26
!rD      = $7FFE28
!actmask = $7FFF0C             ; bit 0 / 1 = slot 0 / 1 was playing when the game started; bit 2 / 3 = this game owns that slot's save
                               ; (it wrote it, or resumed from it): only an owned save is wiped
!tb      = $7FFE38             ; SRAM offset of the record being handled
!ts      = $7FFE3A             ; live slot index (0 / 1) being handled
!t2      = $7FFE3C             ; scratch
!t3      = $7FFE3E             ; scratch

; ---- hooks into the main game loop (80:84B1) ----
pushpc
org $8084BD                    ; was JSL $808618 (player set-up)
        jsl InitHook
org $8084F6                    ; was JSL $808909 (next level)
        jsl SaveHook
org $8084FC                    ; was JSL $808A00 (game over)
        jsl OverHook
org $809169                    ; was JSL $80AC7E, first call after the title menu accepted a start
        jsl ResumeStart
org $809944                    ; was LDA #1 / STA $1E88 (player 1 pressed Start on the player select screen)
        jsl StartP1
        nop
        nop
org $80997B                    ; was LDA #1 / STA $1E8A (player 2 pressed Start)
        jsl StartP2
        nop
        nop
pullpc

; what a record holds: record offset, WRAM address, extra address per slot (slot 1 = slot 0 + this), length
SlotTab:
        dw $0002,$1E7C,$0000,$0002
        dw $0004,$1F9C,$0000,$0020
        dw $0024,$1D50,$0000,$0002
        dw $0026,$1D52,$0000,$0002
        dw $0028,$1CB8,$0002,$0002
        dw $002A,$1D4C,$0002,$0002
        dw $002C,$1CBC,$0002,$0002
        dw $002E,$1CC0,$0002,$0002
        dw $0030,$1CCC,$0020,$001C
        dw $004C,$1D0C,$0020,$0018
        dw $0064,$1E72,$0004,$0004
        dw $0068,$6054,$0002,$0002
SlotTabEnd:

InitHook:
        jsl $808618
        jsl GameStart
        rtl

SaveHook:
        jsl $808909
        jsl SaveGame
        rtl

OverHook:
        jsl WipeActive
        jml $808A00

; the title accepted a start: when RESUME GAME chose one character, put him or her in slot 0 and leave the title; for both,
; the player select screen runs as for a new game, and whoever presses Start plays with the save of the character shown
ResumeStart:
        jsl $80AC7E
        rep #$30
        lda.l !resume
        beq .no
        cmp.w #3
        beq .no                        ; both: the player select screen follows and lets each player pick a character
        lda.w #0
        sta.l $7E1E88
        sta.l $7E1E8A
        lda.w #0                       ; Zeke is character 0, Julie 2; they are in slots 0 and 1 unless one plays alone
        sta.l $7E1E84
        lda.w #2
        sta.l $7E1E86
        lda.l !resume
        cmp.w #2
        bne +
        lda.w #1                       ; Julie alone: she plays on pad 1 (slot 0), as the player select does with SELECT
        sta.l $7E1E88
        lda.w #2
        sta.l $7E1E84
        lda.w #0
        sta.l $7E1E86
        bra .go
+       lda.w #1                       ; Zeke alone: slot 0
        sta.l $7E1E88
.go:    pla                    ; skip the player select: return from the title function as 80:9178 does
        sep #$20
        pla
        rep #$20
.no:    rtl

; player select, resuming both saves (!resume = 3): whoever presses Start puts both players in the game, as they stand on the
; screen; without a Start press the screen times out to the title as always (the call replaces LDA #1 / STA $1E88|$1E8A)
StartP1:
        lda.w #1
        sta.w $1E88
        lda.l !resume
        cmp.w #3
        bne .rts
        lda.w #1
        sta.w $1E8A
        ldy.b $52                      ; player 2's picture appears too
        lda.w $0000,y
        and.w #$7FFF
        sta.w $0000,y
.rts:   rtl

StartP2:
        lda.w #1
        sta.w $1E8A
        lda.l !resume
        cmp.w #3
        bne .rts
        lda.w #1
        sta.w $1E88
        ldy.b $50
        lda.w $0000,y
        and.w #$7FFF
        sta.w $0000,y
.rts:   rtl

; after the game set up its players: remember who is playing and, when resuming, load their saved state over the defaults
GameStart:
        rep #$30
        lda.w #0
        sta.l !t2
        lda.l $7E1E88
        beq +
        lda.w #1
        sta.l !t2
+       lda.l $7E1E8A
        beq +
        lda.l !t2
        ora.w #2
        sta.l !t2
+       lda.l !t2
        sta.l !actmask
        lda.w #0                       ; drop-in (dropin.asm): nobody has run out of lives yet, nothing armed
        sta.l !dlvl
        sta.l !dlvl+2
        sta.l !jpend
        sta.l !jhold
        sta.l !jgrace
        lda.l !resume
        beq .done
        lda.l !actmask
        asl a
        asl a
        ora.l !actmask
        sta.l !actmask                 ; a resumed player's save belongs to this game
        phb
        jsr Prep
        lda.l !actmask
        and.w #3
        cmp.w #3
        beq .both
        lda.l !actmask
        and.w #1
        beq +
        lda.w #0
        jsr LoadSlot
+       lda.l !actmask
        and.w #2
        beq .fin
        lda.w #1
        jsr LoadSlot
        bra .fin
.both:  jsr Winner                     ; both resume together: the better save sets the level and the victims, so it loads last
        sta.l !t2
        lda.l $7E1E84                  ; the slot Zeke plays in
        beq +
        lda.w #1
+       sta.l !rD
        lda.l !t2
        beq +
        lda.l !rD                      ; Julie's save wins: her slot is the other one
        eor.w #1
        sta.l !rD
+       lda.l !rD
        eor.w #1
        jsr LoadSlot
        lda.l !rD
        jsr LoadSlot
.fin:   plb
        lda.w #0
        sta.l !resume
.done:  rtl

; level complete (the next level has just been set up): save every player that is still in the game
SaveGame:
        rep #$30
        lda.l $7E1E7C
        cmp.w #2
        bcc .none                      ; wrapped past the last level
        phb
        jsr Prep
        lda.w #0
        jsr SaveSlot
        lda.w #1
        jsr SaveSlot
        jsr Finish
        plb
.none:  rtl

; game over: everything the players of this game had saved goes
WipeActive:
        rep #$30
        phb
        jsr Prep
        lda.l !actmask
        and.w #4
        beq +
        lda.l $7E1E84                  ; slot 0's character -> its record
        beq ++
        lda.w #1
++      jsr WipeRec
+       lda.l !actmask
        and.w #8
        beq +
        lda.l $7E1E86
        beq ++
        lda.w #1
++      jsr WipeRec
+       jsr Finish
        lda.w #0
        sta.l !actmask
        plb
        rtl

; Options: ERASE DATA also removes the saved game
WipeAll:
        rep #$30
        phb
        jsr Prep
        lda.w #0
        jsr WipeRec
        lda.w #1
        jsr WipeRec
        jsr Finish
        plb
        rtl

; Options: A = what is saved (bit 0 Zeke, bit 1 Julie, bit 2 both)
SaveStatus:
        rep #$30
        phb
        ldy.w #$0200
        jsr Check
        bcc .ok
        ldy.w #$0300
        jsr Check
        bcc .ok2
        plb
        lda.w #0
        rtl
.ok2:   ldx.w #$0308
        bra .rd
.ok:    ldx.w #$0208
.rd:    lda.w #0
        sta.l !t3
        lda.l $700000,x
        cmp.w #1
        bne +
        lda.l !t3
        ora.w #1
        sta.l !t3
+       txa
        clc
        adc.w #!RLEN
        tax
        lda.l $700000,x
        cmp.w #1
        bne +
        lda.l !t3
        ora.w #2
        sta.l !t3
+       lda.l !t3
        cmp.w #3
        bne .out
        lda.w #7
.out:   plb
        rtl

; Options, RESUME screen: !rinfo = level and victim count (binary) of the Zeke save, the Julie save, and the one both would continue from
ResInfo:
        rep #$30
        phb
        jsr Prep
        plb
        lda.l !SAV+8+2
        sta.l !rinfo
        lda.l !SAV+8+$24
        jsr Bcd
        sta.l !rinfo+2
        lda.l !SAV+8+!RLEN+2
        sta.l !rinfo+4
        lda.l !SAV+8+!RLEN+$24
        jsr Bcd
        sta.l !rinfo+6
        jsr Winner
        beq +
        lda.l !rinfo+4
        sta.l !rinfo+8
        lda.l !rinfo+6
        sta.l !rinfo+10
        rtl
+       lda.l !rinfo
        sta.l !rinfo+8
        lda.l !rinfo+2
        sta.l !rinfo+10
        rtl

; the save that wins when both resume together: the higher level, at the same level the higher victim count -> A = 0 Zeke, 1 Julie
Winner: lda.l !SAV+8+2
        cmp.l !SAV+8+!RLEN+2
        bcc .julie
        bne .zeke
        lda.l !SAV+8+$24               ; BCD
        cmp.l !SAV+8+!RLEN+$24
        bcc .julie
.zeke:  lda.w #0
        rts
.julie: lda.w #1
        rts

Bcd:    and.w #$00FF                   ; A = BCD byte -> binary
        pha
        lsr a
        lsr a
        lsr a
        lsr a
        sta.l !t2
        asl a
        asl a
        asl a
        clc
        adc.l !t2
        adc.l !t2
        sta.l !t2
        pla
        and.w #$000F
        clc
        adc.l !t2
        rts

; ---- internals (all called with 16-bit registers) ----

; A = live slot index (0 / 1): save that player if he is still in the game
SaveSlot:
        sta.l !ts
        asl a
        tax
        lda.l $7E1E88,x
        bne .play
        lda.l !ts                      ; not in the game now: if this game owns his save, he ran out of lives
        beq +
        lda.l !actmask
        and.w #8
        bra ++
+       lda.l !actmask
        and.w #4
++      beq .rts
        lda.l !ts
        asl a
        tax
        lda.l $7E1E84,x
        beq +
        lda.w #1
+       jmp WipeRec
.play:  lda.l !ts
        asl a
        tax
        lda.l $7E1E84,x                ; character 0 / 2 -> record 0 / 1
        beq +
        lda.w #1
+       jsr RecBase
        tax
        lda.w #1
        sta.l !SAV,x
        lda.w #0
        jsr Xfer
        lda.l !ts                      ; this game now owns that slot's save
        beq +
        lda.l !actmask
        ora.w #8
        bra ++
+       lda.l !actmask
        ora.w #4
++      sta.l !actmask
.rts:   rts

; A = live slot index: copy the record of the character in that slot from SRAM into the game
LoadSlot:
        sta.l !ts
        asl a
        tax
        lda.l $7E1E84,x
        beq +
        lda.w #1
+       jsr RecBase
        tax
        lda.l !SAV,x
        cmp.w #1
        bne .rts
        lda.w #1
        jsr Xfer
.rts:   rts

; A = record number (0 / 1) -> A = SRAM offset of the record, also kept in !tb
RecBase:
        cmp.w #0
        beq +
        lda.w #$0008+!RLEN
        bra ++
+       lda.w #$0008
++      sta.l !tb
        rts

; A = record number: its valid word goes to 0
WipeRec:
        jsr RecBase
        tax
        lda.w #0
        sta.l !SAV,x
        rts

; a joiner resuming mid-level: the same, but only what belongs to the player (not the level and the victims)
XferOwn: sta.l !t3
        ldx.w #4*8
        jmp XferRow

; !tb = record offset, !ts = live slot index, A = 0 slot -> record, 1 record -> slot
Xfer:   sta.l !t3
        ldx.w #0
XferRow:
.row:   phx
        lda.l SlotTab,x                ; record offset
        clc
        adc.l !tb
        clc
        adc.w #!SAV&$FFFF
        sta.l !rB                      ; SRAM address (low 16 bits of $70:xxxx)
        lda.l SlotTab+2,x              ; WRAM address
        pha
        lda.l !ts
        beq +
        lda.l SlotTab+4,x
        clc
        adc $01,s
        sta $01,s
+       pla
        sta.l !rA
        lda.l SlotTab+6,x
        dec a
        sta.l !rC
        lda.l !t3
        bne .ld
        lda.l !rA
        tax
        lda.l !rB
        tay
        lda.l !rC
        mvn $70,$7E
        bra .nx
.ld:    lda.l !rB
        tax
        lda.l !rA
        tay
        lda.l !rC
        mvn $7E,$70
.nx:    plx
        txa
        clc
        adc.w #8
        tax
        cpx.w #SlotTabEnd-SlotTab
        bne .row
        rts

; copy 1 usable: valid as it is, else restored from copy 2, else a fresh empty record
Prep:   ldy.w #$0200
        jsr Check
        bcc .ok
        ldy.w #$0300
        jsr Check
        bcs .fresh
        ldx.w #$0300
        ldy.w #$0200
        lda.w #!SLEN-1
        mvn $70,$70
.ok:    rts
.fresh: ldx.w #0
        lda.w #0
-       sta.l !SAV,x
        inx
        inx
        cpx.w #!SLEN
        bne -
        lda.w #$535A
        sta.l !SAV
        lda.w #$5641
        sta.l !SAV+2
        lda.w #1
        sta.l !SAV+4
        rts

; checksum into copy 1, then the same record into copy 2
Finish: ldy.w #$0200
        jsr Sum
        sta.l !SAV+6
        ldx.w #$0200
        ldy.w #$0300
        lda.w #!SLEN-1
        mvn $70,$70
        rts

; Y = copy offset: carry clear when the copy is a valid record
Check:  tya
        tax
        lda.l $700000,x
        cmp.w #$535A
        bne .bad
        lda.l $700002,x
        cmp.w #$5641
        bne .bad
        lda.l $700004,x
        cmp.w #1
        bne .bad
        jsr Sum
        pha
        tya
        tax
        pla
        cmp.l $700006,x
        bne .bad
        clc
        rts
.bad:   sec
        rts

; Y = copy offset -> A = checksum of its words +8..+$DF (Y is kept)
Sum:    phy
        tya
        clc
        adc.w #8
        tax
        ldy.w #(!SLEN-8)/2
        lda.w #$5AA5
-       clc
        adc.l $700000,x
        asl a
        adc.w #0
        inx
        inx
        dey
        bne -
        ply
        rts
