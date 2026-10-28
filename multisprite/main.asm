*= $0801           ; standard basic start memory for c64 ($0801 is 2049)

; --- basic upstart stub (10 sys 2061) ---
    !16 next_line   ; pointer to next line
    !16 10          ; line number 10
    !byte $9e         ; basic token for sys
    !text "2061"      ; address of our code (decimal: 2061 = hex $080d)
    !byte $00         ; end of basic line
next_line:
    !16 $0000       ; end of basic program

;vic registers
screen = $0400
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
spritesXhighRegister = $d010
spritesEnableRegister = $d015
spritesEnableMulticolorRegister = $d01c
spriteMultiColor1register = $d025
spriteMultiColor2register = $d026
sprite0positionX = $d000
sprite0positionY = $d001
sprite1positionX = $d002
sprite1positionY = $d003
sprite2positionX = $d004
sprite2positionY = $d005
sprite3positionX = $d006
sprite3positionY = $d007
sprite4positionX = $d008
sprite4positionY = $d009
sprite5positionX = $d00a
sprite5positionY = $d00b
vicSprite0colorRegister = $d027
vicSprite1colorRegister = $d028
vicSprite2colorRegister = $d029
vicSprite3colorRegister = $d02a
vicSprite4colorRegister = $d02b
vicSprite5colorRegister = $d02c
sprite0blockPointer = $07f8
sprite1blockPointer = $07f9
sprite2blockPointer = $07fa
sprite3blockPointer = $07fb
sprite4blockPointer = $07fc
sprite5blockPointer = $07fd

;program registers
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe

;system constants
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorThile = 3
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
spriteWidth = 24
spriteHeight = 21
spriteSize = 64

;application constants
spriteCount = 6
sprite0block = 250 ;(*64=16000)

!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro phx {
    txa
    pha
}

!macro plx {
    pla
    tax
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

;set background and border color
+poke vicBackgroundColorRegister, vicColorGreen
+poke vicBorderColorRegister, vicColorLightGreen

;screen clear loop
lda #32 ; 32 = clear / empty char
screenclearloop:
sta screen+0*256, y ;Screen page 0
sta screen+1*256, y ;Screen page 1
sta screen+2*256, y ;Screen page 2
sta screen+3*256, y ;Screen page 3
iny
bne screenclearloop

;setting shared colors
+poke spriteMultiColor1register, vicColorBrown
+poke spriteMultiColor2register, vicColorBlue
!for .currentSprite, 0, spriteCount-1 {
    +poke vicSprite0colorRegister+.currentSprite, .currentSprite
}

;setting sprite pointers
!for .currentSprite, 0, spriteCount-1 {
    +poke sprite0blockPointer+.currentSprite, sprite0block+.currentSprite
}

;enable sprites (1+2+3+4+5+6)
+poke spritesEnableRegister, (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3) | (1 << 4) | (1 << 5)

;disable multicolor mode for all sprites
+poke spritesEnableMulticolorRegister, 0

;set sprite colors
+poke vicSprite0colorRegister, vicColorBlack
+poke vicSprite1colorRegister, vicColorBlack
+poke vicSprite2colorRegister, vicColorThile
+poke vicSprite3colorRegister, vicColorThile
+poke vicSprite4colorRegister, vicColorRed
+poke vicSprite5colorRegister, vicColorRed

;position sprites (x from 0 to 320... 320 > 256 2 bytes) (y from 0 to 255 1 byte)
+ldi16 r0, 100 ;X position
+poke r2, 100  ;Y position
jsr setMultiSpritePosition

;movement loop
demoloop:
jmp demoloop

;Input: None
;Output: r0=XposLow, r1=XposHigh, r2=Ypos
getMuliSpritePosition:
!zone getMuliSpritePosition {
    +mov r0, sprite0positionX
    lda spritesXhighRegister
    and #1
    sta r1
    +mov r2, sprite0positionY
    rts
}

;Input:  r0=XposLow, r1=XposHigh (0 or 1), r2=Ypos
;Output: sprites 0..spriteCount-1 positioned,
;Clobbers: A, X, Y, r3
setMultiSpritePosition:
!zone setMultiSpritePosition {
    +poke r3, 0
    ldx #0 ;X = current sprite
.loop:
    txa
    and #1
    beq .left
    lda #spriteWidth ;right half: offset 24
    bne .add ;always taken (A<>0)
.left:
    lda #0 ;left half: offset 0
.add:
    clc
    adc r0 ;A = low byte, C = carry out
    pha ;save low byte
    lda r1
    adc #0 ;A = high byte + carry
    and #1 ;bit 8 of this sprite's X
    beq .noHigh
    lda .bitMask,x
    ora r3
    sta r3
.noHigh:
    txa
    asl ;A = sprite*2
    tay ;Y = register offset, X stays the sprite number
    pla
    sta sprite0positionX, y
    lda r2
    sta sprite0positionX+1, y
    inx
    cpx #spriteCount
    bne .loop
    +mov spritesXhighRegister, r3
    rts
.bitMask:
    !byte 1,2,4,8,16,32,64,128
}

moveRight:
!zone moveRight {
    jsr getMuliSpritePosition
    inc r0
    beq .done
    inc r1
.done
    jsr setMultiSpritePosition
    rts
}

moveLeft:
!zone moveLeft {
    jsr getMuliSpritePosition
    sec
    lda r0
    sbc #1
    sta r0
    lda r1
    sbc #0
    sta r1
    jsr setMultiSpritePosition
    rts
}

moveDown:
!zone moveDown {
    jsr getMuliSpritePosition
    inc r2
    jsr setMultiSpritePosition
    rts
}

moveUp:
!zone moveUp {
    jsr getMuliSpritePosition
    dec r2
    jsr setMultiSpritePosition
    rts
}

*=sprite0block*spriteSize

; --- sprite 0: wheels, left half (block 250) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%01111100,%00000000
!byte %00000000,%11111110,%00000000
!byte %00000001,%11111111,%00000000
!byte %00000001,%11111111,%00000000
!byte %00000001,%11101111,%00000000
!byte %00000001,%11111111,%00000000
!byte %00000001,%11111111,%00000000
!byte %00000000,%11111110,%00000000
!byte %00000000,%01111100,%00000000
!byte 0 ;padding

; --- sprite 1: wheels, right half (block 251) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00111110,%00000000
!byte %00000000,%01111111,%00000000
!byte %00000000,%11111111,%10000000
!byte %00000000,%11111111,%10000000
!byte %00000000,%11110111,%10000000
!byte %00000000,%11111111,%10000000
!byte %00000000,%11111111,%10000000
!byte %00000000,%01111111,%00000000
!byte %00000000,%00111110,%00000000
!byte 0 ;padding

; --- sprite 2: windows, left half (block 252) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%11111001
!byte %00000000,%00000001,%11111001
!byte %00000000,%00000001,%11111001
!byte %00000000,%00000011,%11111001
!byte %00000000,%00000111,%11111001
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00110000,%00000000,%00000000
!byte %00110000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte 0 ;padding

; --- sprite 3: windows, right half (block 253) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %11111100,%00000000,%00000000
!byte %11111110,%00000000,%00000000
!byte %11111111,%10000000,%00000000
!byte %11111111,%11000000,%00000000
!byte %11111111,%11100000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00001100
!byte %00000000,%00000000,%00001100
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte 0 ;padding

; --- sprite 4: body, left half (block 254) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000001,%11111111
!byte %00000000,%00000011,%11111111
!byte %00000000,%00000111,%11111111
!byte %00000000,%00000111,%11111111
!byte %00000000,%00001111,%11111111
!byte %00000000,%00011111,%11111111
!byte %00011111,%11111111,%11111111
!byte %00111111,%11111111,%11111111
!byte %01111111,%10000011,%11111111
!byte %01111110,%00000000,%11111111
!byte %01111110,%00000000,%11111111
!byte %01111100,%00000000,%01111111
!byte %01111100,%00000000,%01111111
!byte %01111100,%00000000,%01111111
!byte %00111100,%00000000,%01111111
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte 0   ; padding: sprite blocks are 64 bytes

; --- sprite 5: body, right half (block 255) ---
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %11111110,%00000000,%00000000
!byte %11111111,%00000000,%00000000
!byte %11111111,%10000000,%00000000
!byte %11111111,%11100000,%00000000
!byte %11111111,%11110000,%00000000
!byte %11111111,%11111000,%00000000
!byte %11111111,%11111111,%11111000
!byte %11111111,%11111111,%11111100
!byte %11111111,%11000001,%11111110
!byte %11111111,%00000000,%01111110
!byte %11111111,%00000000,%01111110
!byte %11111110,%00000000,%00111110
!byte %11111110,%00000000,%00111110
!byte %11111110,%00000000,%00111110
!byte %11111110,%00000000,%00111100
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte 0 ;padding