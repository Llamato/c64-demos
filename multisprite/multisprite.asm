;Memory Mappings
vicBorderColor = $d020
vicBackgroundColor = $d021
spritesXhigh = $d010
spritesEnable = $d015
spritesEnableMulticolor = $d01c
spriteMultiColor1 = $d025
spriteMultiColor2 = $d026
sprite1PositionX = $d000
sprite1PositionY = $d001
sprite2PositionX = sprite1PositionX+2
sprite2PositionY = sprite1PositionY+2
sprite1BlockPointer = $07f8
sprite2BlockPointer = sprite1BlockPointer+1

;Constants
sprite1Block = 250 ;(*64=16000)
sprite2Block = 251 ;(*64=16064)
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorTihle = 3
vicColorPink = 4
vicColorGreen = 5
vicColorBlue = 6
vicColorYellow = 7
vicColorBrown = 8
vicColorDarkBrown = 9
vicColorOrange = 10
vicColorDarkGray = 11
vicColorGray = 12
vicColorLightGreen = 13
vicColorLightPurple = 14
vicColorLightGray = 15

;Setting shared colors
*= $1000
prgStart:
lda #vicColorBrown
sta spriteMultiColor1
lda #vicColorBlue
sta spriteMultiColor2

;Set background and border color
lda #vicColorBlack
sta vicBackgroundColor
sta vicBorderColor

;Setting sprite pointers
lda #sprite1Block
sta sprite1BlockPointer
lda #sprite2Block
sta sprite2BlockPointer

;Enable sprites (1+2)
lda #3 ;(1<<1) || (1<<2)
sta spritesEnable

;Position sprites (x from 0 to 320... 320 > 256 2 bytes) (y from 0 to 255 1 byte)
lda #100
sta sprite1PositionX
sta sprite1PositionY
sta sprite2PositionX
clc
adc #10
sta sprite2PositionY
lda #0
sta spritesXhigh

;Enable multicolor mode for sprite 1 and 2
lda #3
sta spritesEnableMulticolor

;We are done here. Hold the system
HoldAndCatchFire:
jsr moveleft
inc vicBorderColor
jmp HoldAndCatchFire

moveleft:
;Decrease x for both sprites in the pair
lda sprite1PositionX
sec
sbc #1
sta sprite1PositionX
bcs movesprite2
lda #$fe
and spritesXhigh
sta spritesXhigh
movesprite2:
lda sprite2PositionX
sec
sbc #1
sta sprite2PositionX
bcs moveleftdone
lda #$fd
and spritesXhigh
sta spritesXhigh
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

