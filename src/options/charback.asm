; Character select: A + B + X + Y held together (either pad) takes you back to the title, as long as nobody has pressed Start yet.
; (assembled as part of options.asm, after joinprompt.asm, same bank)
;
; The select routine (80:98EA, called by JSR from the title function at 80:9173) yields once per frame at 80:99BA
; (LDA #$0001 / JSL $808353).  The hook yields as before and, on the four buttons (after they are let go, or the title would take a
; held A as START again), removes the two character pictures like the routine's own exit for "nobody started" (80:99F6) and
; then leaves the way an attract demo does when it ends (80:9BAD: reset the game state), but returning to 80:9126, the title
; set-up that a finished demo returns to.  The timeout of the select screen still starts a demo, as before.

pushpc
org $8099BA
        jsl CharBack
        nop : nop : nop
pullpc

CharBack:
        lda.w #$0001
        jsl $808353                     ; what the hook replaced
        lda.w $1E88
        ora.w $1E8A
        bne .out                        ; somebody already pressed Start: the game is starting
        lda.w $006E
        ora.w $0070
        and.w #!FACE
        cmp.w #!FACE
        beq .back
.out:   rtl
.back:
.up:    lda.w #$0001
        jsl $808353
        lda.w $006E
        ora.w $0070
        and.w #!FACE
        bne .up
        lda.w #$9C7D                    ; leave like a game start does (80:99D5): fade out, stop the select screen's tasks
        ldy.w #$0080
        jsl $8083AE
        lda.w #$0010
        jsl $808353
        lda.b $6C
        jsl $8083D5
        lda.b $60
        jsl $8083D5
        wai
        lda.b $50
        jsl $80BE41
        lda.b $52
        jsl $80BE41
        jsl $80866F                     ; then reset the game state the way a finished attract demo does (80:9B9C..9BCE)
        jsl $8088A9
        jsl $80895A
        jsl $808992
        jsl $8085CF
        lda.w #$0001
        sta.w $1E7C
        stz.w $1E84
        stz.w $007C                     ; the title's one-time set-up runs again (80:9136)
        lda.w #$0005
        jsl $808353
        pla                             ; drop the 3-byte JSL return
        sep #$20
        pla
        rep #$20
        lda.w #$9125                    ; the select routine returns to the title's set-up (80:9126)
        sta $01,s
        jml $809A1A                     ; an RTS in bank 80
