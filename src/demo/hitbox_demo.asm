; ZAMN: bigger hitboxes (150%) in normal play; attract-mode demos keep the original 16px box
; (their recorded inputs only make sense against the original collision).
lorom

; the box constants in the original routine go back to 8 / 16 (used by the demos)
org $80BEF8 : db $08
org $80BEFB : db $10
org $80BF06 : db $08
org $80BF09 : db $10

; the single caller (80:BDCC) now goes through a demo check
org $80BDCC
        jsl HbEntry

; 150% copy of the routine 80:BEC9-BF1A in the free space at 80:FF68
org $80FF68
HbBig:
        db $A4,$9C,$F0,$4D,$88,$88,$F0,$49
        db $BE,$7E,$13,$88,$88,$84,$3C,$B5
        db $0E,$F0,$3A,$85,$4A,$B5,$02,$85
        db $38,$B5,$06,$85,$3A,$BE,$7E,$13
        db $B5,$0E,$F0,$25,$C5,$4A,$F0,$21
        db $B5,$02,$38,$E5,$38,$18,$69,$0C
        db $00,$C9,$18,$00,$B0,$13,$B5,$06
        db $38,$E5,$3A,$18,$69,$0C,$00,$C9
        db $18,$00,$B0,$05,$5A,$20,$8F,$BE
        db $7A,$88,$88,$10,$D0,$A4,$3C,$D0
        db $B7,$6B

org $83FC00
HbEntry:
        lda.w $1EB4                     ; nonzero while an attract demo is playing
        beq .play
        jml $80BEC9                     ; original routine (16px box)
.play:  jml HbBig                       ; 24px box
