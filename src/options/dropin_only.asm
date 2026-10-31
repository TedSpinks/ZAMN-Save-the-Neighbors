; ZAMN 2P drop-in as a stand-alone patch: no saved games, no join prompt (dropin.asm built with NOPROMPT).
; Needs the 2 MB expansion (same header / size bytes as every other ZAMN patch); the code goes in bank BF.
lorom
!NOPROMPT = 1


pushpc
org $8084BD                     ; was JSL $808618 (player set-up)
        jsl DropInInit
pullpc

org $BF8000
incsrc "dropin.asm"

DropInInit:
        jsl $808618
        rep #$30
        lda.w #0                ; nobody has run out of lives yet, nothing armed
        sta.l !dlvl
        sta.l !dlvl+2
        sta.l !jpend
        sta.l !jhold
        sta.l !jgrace
        rtl

