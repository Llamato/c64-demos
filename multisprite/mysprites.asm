*= $1000 
spriteXhigh = $d010
;Set background and border color
lda #0
sta 53280
sta 53281

;Setting shared colors
LDA #$08 ; sprite multicolor 1
STA $D025
LDA #$06 ; sprite multicolor 2
STA $D026

;Setting sprite pointers
lda #250
sta $07f8
lda #251
sta $07f9

;Enable sprites (1+2)
lda #3
sta $d015

;Postion sprites (x from 0 to 320... 320 > 256 2 bytes) (y from 0 to 255 1 byte)
lda #100
sta $d000
sta $d001
sta $d002
clc
adc #10
sta $d003
lda #0
sta $d010

;Enable multicolor mode for sprite 1 and 2
lda #3
sta $d01c
HoldAndCatchFire:
jsr moveleft
inc 53280
jmp HoldAndCatchFire

moveleft:
;Decrease x for both sprites in the pair
lda $d000
sec
sbc #1
sta $d000
bcs movesprite2
lda #$fe
and $d010
sta $d010
movesprite2:
lda $d002
sec
sbc #1
sta $d002
bcs moveleftdone
lda #$fd
and $d010
sta $d010
moveleftdone:
rts

*=$3e80
; sprite 1 / multicolor / color: $03
sprite1
!byte $00,$00,$00,$00,$00,$00,$08,$00
!byte $0a,$08,$00,$28,$02,$00,$20,$02
!byte $15,$50,$00,$5f,$d4,$01,$7f,$d4
!byte $01,$ff,$d0,$01,$ff,$d0,$01,$7f
!byte $d0,$00,$7f,$d0,$00,$7f,$40,$00
!byte $5d,$40,$00,$15,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$83

; sprite 2 / multicolor / color: $0P
sprite2
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $00,$00,$00,$00,$00,$00,$00,$00
!byte $10,$00,$00,$10,$00,$00,$10,$00
!byte $00,$54,$00,$01,$a5,$00,$01,$a9
!byte $00,$01,$a9,$00,$01,$a9,$00,$01
!byte $a5,$00,$01,$54,$00,$00,$44,$00
!byte $01,$44,$00,$01,$04,$00,$01,$04
!byte $00,$01,$04,$00,$01,$04,$00,$87

