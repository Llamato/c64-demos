*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program


;Hardware constants
bitmapScreenWidth = 320
bitmapScreenHeight = 200
spriteWidth = 24
spriteHeight = 21
spriteBlockSize = 64

sidADC0 = $d419 ;Mouse x axis position can be read here 
sidADC1 = $d41a ;Mouse y axis position can be read here
vicSpritesPositionXhighRegister = $d010
vicSpriteEnableRegister = $d015
vicSpriteDoubleHeightRegister = $d017
vicSpriteDoubleWidthRegister = $d01d
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite0bitmapBlockPointerRegister = $07f8

;Software constants
cursorSpriteBlock = 128

;Memory mapping
r0 = 251
r1 = 252
r2 = 253
r3 = 254
previousMousePositionX = $c000 ;$c000:c001
previousMousePositionY = $c002

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

*=$080d
init:
+poke vicSprite0bitmapBlockPointerRegister, cursorSpriteBlock ;Point sprite 0 at cursor bitmap
+poke vicSpritesPositionXhighRegister, 0
+poke vicSprite0positionXregister, bitmapScreenWidth / 2 - spriteWidth / 2 ;Position mouse cursor in the middle of the screen
+poke vicSpriteDoubleWidthRegister, 0 ;Turn double width off for all sprites
+poke vicSpriteDoubleHeightRegister, 0 ;Turn double height off for all sprites
+poke vicSpriteEnableRegister, 1 ;Enable mouse cursor

main:
;Read mouse axis
ldx sidADC0
ldy sidADC1
stx vicSprite0positionXregister
sty vicSprite0positionYregister

jmp main

*=cursorSpriteBlock * spriteBlockSize
cursorSprite:
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000001,%11111111,%10000000
!byte %00000001,%11111111,%10000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000000,%00000000,%00000000
!byte %00000001