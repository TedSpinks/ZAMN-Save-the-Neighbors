; ZAMN battery save: the high-score table and the R-button mode.  (assembled as part of options.asm)
;
; SRAM layout (8 KB, header $7FD8 = 3, $7FD6 = 2):
;   $0000  record, copy 1       $00C8 bytes, see below
;   $0100  record, copy 2       written right after copy 1, so a power cut during a save leaves one good copy
;   $0200  reserved for saved progress (a second record type with its own magic / checksum)
; Record: +0 'ZAMN', +4 version (1), +6 checksum of +8..+$C7, +8 R mode word, +$0A score table 1 (7E:2064, $95 bytes),
;         +$9F score table 2 (7E:20FA, $28 bytes), +$C7 pad.
;
; A copy is built in WRAM (7F:FE40) and only written when its checksum differs from the one last loaded / saved, so calling
; SaveIfChanged is cheap and safe at any time.

!stg    = $7FFE40               ; staging copy of the record ($C8 bytes)
!sramck = $7FFF0A               ; checksum of the record SRAM holds (or its complement when SRAM has no valid record)
!RECLEN = $00C8

; header: battery-backed RAM, 8 KB
org $80FFD6
        db $02
org $80FFD8
        db $03

; the original game stores 0 at $70:0000 every time an attract demo starts (80:9B78, the leftover of a demo-recording buffer
; that nothing reads): with real SRAM that wipes the first word of our record, so remove the store
org $809B78
        db $EA,$EA,$EA,$EA

; boot: the game fills the score table with its defaults at 80:85FC; load the saved one over it
org $8085FC
        jsl ScoresInit

; every boot, reset included: the game only fills the score table when its "table is set" flag ($7E:2124) is clear, and that flag
; survives a reset while the 7F:FFxx variables do not.  So the R-button mode is loaded here, before the flag is tested (was LDA $7E2124)
org $8085F6
        jsl BootHook

; every time the title menu is (re)drawn: another chance to save a score the game just entered (80:915A was JSL $80AC7E)
org $80915A
        jsl TitleHook

; the score screen of the attract mode / game over: save before it is shown
org $82BA16
        jsr ScoreHook

org $BF8000

TitleHook:
        lda.w #0                        ; the title is on screen again: a pending RESUME GAME choice is void
        sta.l !resume
        jsl SaveIfChanged
        jml $80AC7E

BootHook:
        php
        rep #$30
        phx
        phy
        ldy.w #$0000
        jsr TrySlot
        bcc .ok
        ldy.w #$0100
        jsr TrySlot
        bcs .no
.ok:    lda.l !stg+8
        sta.l !rmode
        lda.l !stg+6
        sta.l !sramck                   ; (so the first SaveIfChanged does not rewrite what SRAM already holds)
.no:    ply
        plx
        plp
        lda.l $7E2124                   ; the instruction this hook replaced
        rtl

ScoresInit:
        jsl $82BB0D                     ; the original call: default table
        rep #$30
        ldy.w #$0000
        jsr TrySlot
        bcc .ok
        ldy.w #$0100
        jsr TrySlot
        bcc .ok
        jsr BuildStage                  ; no valid record: keep the defaults and make the next SaveIfChanged write them
        eor.w #$FFFF
        sta.l !sramck
        rtl
.ok:    phb
        lda.l !stg+8
        sta.l !rmode
        ldx.w #(!stg+$0A)&$FFFF
        ldy.w #$2064
        lda.w #$0095-1
        mvn $7E,$7F
        ldx.w #(!stg+$9F)&$FFFF
        ldy.w #$20FA
        lda.w #$0028-1
        mvn $7E,$7F
        plb
        lda.l !stg+6
        sta.l !sramck
        rtl

SaveIfChanged:
        rep #$30
        jsr BuildStage
        cmp.l !sramck
        beq .done
        sta.l !sramck
        phb
        ldx.w #!stg&$FFFF
        ldy.w #$0000
        lda.w #!RECLEN-1
        mvn $70,$7F
        ldx.w #!stg&$FFFF
        ldy.w #$0100
        lda.w #!RECLEN-1
        mvn $70,$7F
        plb
.done:  rtl

; Y = SRAM offset of a copy.  Carry clear = valid; the copy is left in the staging area.
TrySlot:
        phb
        tyx
        ldy.w #!stg&$FFFF
        lda.w #!RECLEN-1
        mvn $7F,$70
        plb
        lda.l !stg
        cmp.w #$415A
        bne .bad
        lda.l !stg+2
        cmp.w #$4E4D
        bne .bad
        lda.l !stg+4
        cmp.w #1
        bne .bad
        jsr Checksum
        cmp.l !stg+6
        bne .bad
        clc
        rts
.bad:   sec
        rts

; fills the staging area from the live data; A = its checksum (also stored in the record)
BuildStage:
        phb
        lda.w #$415A
        sta.l !stg
        lda.w #$4E4D
        sta.l !stg+2
        lda.w #1
        sta.l !stg+4
        lda.l !rmode
        sta.l !stg+8
        ldx.w #$2064
        ldy.w #(!stg+$0A)&$FFFF
        lda.w #$0095-1
        mvn $7F,$7E
        ldx.w #$20FA
        ldy.w #(!stg+$9F)&$FFFF
        lda.w #$0028-1
        mvn $7F,$7E
        plb
        sep #$20
        lda.b #0
        sta.l !stg+$C7
        rep #$20
        jsr Checksum
        sta.l !stg+6
        rts

Checksum:                               ; over the words at +8..+$C7 of the staging area
        lda.w #$5AA5
        ldx.w #8
-       clc
        adc.l !stg,x
        asl a
        adc.w #0
        inx
        inx
        cpx.w #!RECLEN
        bne -
        rts
