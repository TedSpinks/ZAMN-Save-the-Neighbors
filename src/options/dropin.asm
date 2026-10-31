; ZAMN 2P drop-in: Start on the idle pad joins that player to the running game (see DROPIN.md).  Assembled as part of options.asm,
; after save.asm (same bank).
;
; Start on the pad of an empty slot arms a join; the slot is spawned as soon as the other player has been in a normal, grounded
; state for a few checks in a row (about 3 s are allowed). That Start never pauses: an empty pad only joins. A Start that is
; already down when a level starts (or the game is unpaused), or pressed in the first moments after, is ignored, and has to be
; released before it can arm: skipping a between-level screen with the idle pad does not join anybody. A player who ran out of lives cannot come back on that level.
; A joiner is a fresh player: default health, lives, weapon, ammo, items; no score, no victims.
; Define NOPROMPT to leave out the saved-game prompt and JoinSave (the stand-alone drop-in patch has no saves).

!dlvl   = $7FFF10               ; level each slot ran out of lives on (word per slot, 0 = none): no rejoin on that level
!jpend  = $7FFF14               ; a join is armed: checks left before it is dropped (0 = none)
!jhold  = $7FFF16               ; bit 0 / 1: the Start that armed (or joined) this pad is still down: it must not pause
!jok    = $7FFF18               ; consecutive checks the other player was in a safe state
!jslot  = $7FFF1A               ; slot index * 2 of the player being joined
!jact   = $7FFF1C               ; slot index * 2 of the player already in the game
!jp0    = $7FFF1E               ; the pads for this check, Start removed where it was used up (pad 2 = !jp0 + 2)
!jp1    = $7FFF20
!jlast  = $7FFF22               ; frame counter at the previous check
!jgrace = $7FFF24               ; checks left in the grace period after a level start / unpause: no join is armed
!jcur   = $7FFF26               ; Start is down on the empty slot's pad
!jmode  = $7FFF28               ; what the joiner chose in the prompt (joinprompt.asm): 0 no save, 1 resume it, 2 start fresh over it

JOINCHECKS = 90                 ; the pause check runs every other frame
JOINGRACE  = 45                 ; about 1.5 s
JOINSAFE   = 3                  ; safe checks in a row before the join

pushpc
org $8089B0                     ; pause check, was LDA $6E / ORA $70
        jsl PauseGate
        nop
        nop
org $80CEDA                     ; a player ran out of lives, was STZ $1E88,X / STZ $1F9C,X
        jsl SlotOut
        nop
        nop
pullpc

; X = slot * 2
SlotOut:
        stz.w $1E88,x
        stz.w $1F9C,x
        lda.l $7E1E7C
        sta.l !dlvl,x
        rtl

; -> A = the pad bits the pause check looks at
PauseGate:
        rep #$30
        lda.l $00006E
        sta.l !jp0
        lda.l $000070
        sta.l !jp1
        lda.l $7E1EB4                   ; attract demo: untouched
        bne .out
        lda.l $000020                   ; the frame counter: the check normally runs every other frame, so a longer gap means
        pha                             ; the level has just started or the game was paused
        sec
        sbc.l !jlast
        cmp.w #5
        bcc +
        lda.w #JOINGRACE
        sta.l !jgrace
+       pla
        sta.l !jlast
        jsr Hold
        jsr Arm
.out:   lda.l !jp0
        ora.l !jp1
        rtl

; a Start that armed or joined is hidden until it is released
Hold:   ldx.w #0
.pad:   lda.l !jhold
        and.l PadBit,x
        beq .next
        lda.l !jp0,x
        and.w #$1000
        beq .free
        lda.l !jp0,x
        and.w #$EFFF
        sta.l !jp0,x
        bra .next
.free:  lda.l !jhold
        eor.l PadBit,x
        sta.l !jhold
.next:  inx
        inx
        cpx.w #4
        bne .pad
        rts

PadBit: dw 1,2

Arm:    lda.l $7E1E88
        beq .e0
        lda.l $7E1E8A
        beq .e1
.none:  lda.w #0                        ; both are in: nothing to join
        sta.l !jpend
        rts
.e0:    lda.l $7E1E8A
        beq .none                       ; nobody is in
        ldx.w #0
        lda.w #2
        bra .go
.e1:    ldx.w #2
        lda.w #0
.go:    sta.l !jact
        txa
        sta.l !jslot
        lda.l !jp0,x                    ; the empty slot's pad never pauses: Start is only for joining
        and.w #$1000
        sta.l !jcur
        lda.l !jp0,x
        and.w #$EFFF
        sta.l !jp0,x
        lda.l !jgrace
        beq .live
        dec a
        sta.l !jgrace
        lda.l !jcur                     ; grace period: whatever is pressed now has to be released first
        beq .rts
        lda.l !jhold
        ora.l PadBit,x
        sta.l !jhold
        rts
.live:  lda.l !jpend
        bne .pending
        lda.l !jcur                     ; Start arms a join
        beq .rts
        lda.l !jhold
        and.l PadBit,x
        bne .rts
        lda.l $7E1E7C                   ; not on the level this slot ran out of lives on
        cmp.l !dlvl,x
        beq .rts
if defined("NOPROMPT") == 0
        jsr NeedPrompt                  ; a saved game for this character: ask what the joiner wants
        bcc .nosave
        jsr JoinPrompt
        sta.l !jmode
        bne .arm
        lda.l !jslot                    ; canceled: no join, and the Start still down has to be released first
        tax
        lda.l !jhold
        ora.l PadBit,x
        sta.l !jhold
        rts
endif
.nosave: lda.w #0
        sta.l !jmode
.arm:   lda.l !jslot
        tax
        lda.w #JOINCHECKS
        sta.l !jpend
        lda.w #0
        sta.l !jok
        lda.l !jhold
        ora.l PadBit,x
        sta.l !jhold
.rts:   rts
.pending:
        dec a
        sta.l !jpend
        lda.l !jact
        tax
        jsr Safe
        bcc .unsafe
        lda.l !jok
        inc a
        sta.l !jok
        cmp.w #JOINSAFE
        bcc .rts
        jsr Join
        lda.w #0
        sta.l !jpend
        rts
.unsafe:
        lda.w #0
        sta.l !jok
        rts

; X = slot * 2 of the player in the game: carry set when he is alive, on the ground and in a normal (idle / walking / firing)
; state: the movement states of the player task are the handlers at $D53D-$D704
Safe:   lda.l $7E1CB8,x
        beq .no
        bmi .no
        lda.l $0000D2,x                 ; his object
        beq .no
        tay
        lda.w $0004,y                   ; height above the ground
        bne .no
        lda.w $000C,y                   ; the task that owns the object -> its direct page
        tax
        lda.l $8082DE,x
        tax
        lda.l $000028,x                 ; its state
        cmp.w #$D53D
        bcc .no
        cmp.w #$D705
        bcs .no
        sec
        rts
.no:    clc
        rts

; the slot in !jslot joins at the other player's position as a fresh player
Join:   lda.l !jslot
        tax
        lda.w #1
        sta.l $7E1E88,x
        lda.w #0
        sta.l $7E1F9C,x                 ; victims saved
        sta.l $7E1F98,x
        sta.l $7E1FB8,x                 ; has not reached an exit
        lda.w #4
        sta.l $7E6054,x                 ; bonus threshold, as at the start of a game
        txa
        asl a
        clc
        adc.w #$1E72                    ; score: 4 bytes per slot
        ldy.w #2
        jsr ClrW
        lda.l !jslot
        asl a
        asl a
        asl a
        asl a                           ; 16 * slot * 2 = $20 per slot
        pha
        clc
        adc.w #$1CCC                    ; ammo table
        ldy.w #$000E
        jsr ClrW
        pla
        clc
        adc.w #$1D0C                    ; item table
        ldy.w #$000C
        jsr ClrW
        lda.l !jslot                    ; default health, lives, weapon, item and starting ammo; setting up slot 0 also
        bne .init                       ; rewrites slot 1's first ammo / item entries, so those are put back
        lda.l $7E1CEC
        pha
        lda.l $7E1D3A
        pha
        ldx.w #0
        jsl $808874
        pla
        sta.l $7E1D3A
        pla
        sta.l $7E1CEC
        bra .spawn
.init:  tax
        jsl $808874
.spawn:
if defined("NOPROMPT") == 0
        jsr JoinSave
endif
        lda.l !jact
        tax
        lda.l $0000D2,x
        tay
        lda.w $0002,y                   ; the task's start position and slot: the same parameters 80:8803 gives at level start
        sta.b $00
        lda.w $0006,y
        sta.b $02
        lda.l !jslot
        lsr a
        sta.b $04
        sta.b $06
        lda.w #$CDF4
        ldy.w #$0080
        jsl $808248
        rts

; A = WRAM address, Y = words: zero them
ClrW:   tax
        lda.w #0
-       sta.l $7E0000,x
        inx
        inx
        dey
        bne -
        rts
