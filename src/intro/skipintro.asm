; ZAMN: press Start to skip the boot logos (Konami, LucasArts, legal notice)
; A per-frame callback (registered with the game's own callback list, and removed again when the
; logos are over, so it costs nothing during play or the demos) latches Start into a flag, so a press
; is never missed between screens; each logo then checks the flag and finishes early.
lorom

!skip = $7FF7FE                         ; 16-bit flag: Start was pressed during the logos
!arm  = $7FF7FC                         ; $A55A while the logos are running

; --- front end (80:9140): arm the latch, then run the Konami logo ---
org $809140
        jsl KonamiWrap                  ; was JSL $838000

; --- legal notice (80:914E): skip entirely when the flag is set ---
org $80914E
        jsl LegalWrap                   ; was JSL $8091F7

; --- legal notice's 128-frame wait (80:9242): Start ends it early ---
org $809242
        jsl LegalWait                   ; was LDA #$0080 / JSL $808353
        nop : nop : nop

; --- LucasArts logo per-frame helper (80:9344): honor the flag ---
org $809344
        jsl LucasChk                    ; was LDA $006E / CMP #$0010
        nop : nop

; --- Konami logo: its per-frame no-op (JSR $8254) now checks the flag ---
org $838102 : jsr KonamiChk
org $838135 : jsr KonamiChk
org $83815A : jsr KonamiChk
org $838184 : jsr KonamiChk
org $8381CC : jsr KonamiChk
org $8381F2 : jsr KonamiChk
org $838217 : jsr KonamiChk

org $83FB3C
LatchCb:                                ; runs every frame from the NMI callback list
        lda.l !arm
        cmp.w #$A55A
        bne .end
        lda.w $006E
        ora.w $0070
        bit.w #$1000
        beq .keep
        lda.w #$0001
        sta.l !skip
.keep:  sec                             ; stay registered
        rtl
.end:   clc                             ; logos are over: unregister
        rtl

KonamiWrap:
        rep #$20
        lda.w #$0000
        sta.l !skip
        lda.w #$A55A
        sta.l !arm
        lda.w #LatchCb
        ldy.w #$0083
        jsl $8083AE                     ; register the callback
        jsl $838000
        rtl

KonamiChk:
        lda.l !skip
        beq .no
        pla                             ; drop the JSR return address
        jmp $821D                       ; straight to the logo's fade-out
.no:    rts

LucasChk:
        lda.l !skip
        bne .skip
        lda.w $006E                     ; the instructions this replaced
        cmp.w #$0010
        rtl
.skip:  pla                             ; drop our JSL return (3 bytes)
        sep #$20
        pla
        rep #$20
        jml $809385                     ; the original Start-pressed path

LegalWrap:
        lda.l !skip
        beq .run
        lda.w #$0080
        sta.w $136C
        sep #$20
        stz.w $212C
        rep #$20
        bra .end
.run:   jsl $8091F7
.end:   lda.w #$0000
        sta.l !arm                      ; logos are over: stop latching Start
        rtl

LegalWait:
        lda.w #$0080
        pha
.l:     lda.w #$0001
        jsl $808353
        lda.l !skip
        bne .out
        lda $01,s
        dec a
        sta $01,s
        bne .l
.out:   pla
        rtl
