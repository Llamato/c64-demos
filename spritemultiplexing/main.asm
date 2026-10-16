*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Petscii text
petsciiBlank = 32

;Vic Colors
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorCyan = 3
vicColorPurple = 4
vicColorGreen = 5
vicColorBlue = 6
vicColorYellow = 7
vicColorBrown = 8
vicColorDarkBrown = 9
vicColorLightBrown = 10
vicColorDarkGray = 11
vicColorGray = 12
vicColorLightGreen = 13
vicColorLightBlue = 14
vicColorLightGray = 15

;Vic Registers
screen = $0400 ;4*256 = 1024
vicSprite0bitmapBlockPointerRegister = $07f8
vicSprite1bitmapBlockPointerRegister = $07f9
vicSprite2bitmapBlockPointerRegister = $07fa
vicSprite3bitmapBlockPointerRegister = $07fb
vicSprite4bitmapBlockPointerRegister = $07fc
vicSprite5bitmapBlockPointerRegister = $07fd
vicSprite6bitmapBlockPointerRegister = $07fe
vicSprite7bitmapBlockPointerRegister = $07ff
vicAcknowlageInterruptRegister = $d019
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicControlRegister = $d01a
vicSpriteMultiColorRegister = $d01c
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite1positionXregister = $d002
vicSprite1positionYregister = $d003
vicSprite2positionXregister = $d004
vicSprite2positionYregister = $d005
vicSprite3positionXregister = $d006
vicSprite3positionYregister = $d007
vicSprite4positionXregister = $d008
vicSprite4positionYregister = $d009
vicSprite5positionXregister = $d00a
vicSprite5positionYregister = $d00b
vicSprite6positionXregister = $d00c
vicSprite6positionYregister = $d00d
vicSprite7positionXregister = $d00e
vicSprite7positionYregister = $d00f
vicSpriteEnableRegister = $d015
vicSprite0colorRegister = $d027
vicSprite1colorRegister = $d028
vicSprite2colorRegister = $d029
vicSprite3colorRegister = $d02a
vicSprite4colorRegister = $d02b
vicSprite5colorRegister = $d02c
vicSprite6colorRegister = $d02d
vicSprite7colorRegister = $d02e
vicSpritePositionsXhighbitRegister = $d010
vicRasterInterruptScanlineSelectRegister = $d012
vicInterruptControlRegister = $d011
vicSprite0colorRegister = $d027


;CIA
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d

;Kernel
kernelrqVector = $0314 ;$0314-0315
kernelTextColor = $0286
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81

;Program constants
sprite0block = 128
sprite1block = 129
sprite2block = 130
sprite3block = 131
sprite4block = 132
sprite5block = 133
sprite6block = 134
sprite7block = 13

;Program memory
rExtra = 2
r0 = 251
r1 = 252
r2 = 253
r3 = 254

sprite0lowerPositionX = $c000
sprite0lowerPositionY = $c001
sprite0higherPositionX = $c002
sprite0higherPositionY = $c003
sprite1lowerPositionX = $c004
sprite1lowerPositionY = $c005
sprite1higherPositionX = $c006
sprite1higherPositionY = $c007
sprite2lowerPositionX = $c008
sprite2lowerPositionY = $c009
sprite2higherPositionX = $c00a
sprite2higherPositionY = $c00b
sprite3lowerPositionX = $c00c
sprite3lowerPositionY = $c00d
sprite3higherPositionX = $c00e
sprite3higherPositionY = $c00f
sprite4lowerPositionX = $c010
sprite4lowerPositionY = $c011
sprite4higherPositionX = $c012
sprite4higherPositionY = $c013
sprite5lowerPositionX = $c014
sprite5lowerPositionY = $c015
sprite5higherPositionX = $c016
sprite5higherPositionY = $c017
sprite6lowerPositionX = $c018
sprite6lowerPositionY = $c019
sprite6higherPositionX = $c020
sprite6higherPositionY = $c021
sprite7lowerPositionX = $c022
sprite7lowerPositionY = $c023
sprite7higherPositionX = $c024
sprite7higherPositionY = $c025

lowerSpritesPositionXhighBits = $cffe
higherSpritesPositionXhighBites = $cfff

!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

*=$080d
;set colors
lda #13
sta vicBorderColorRegister
lda #vicColorBlack
sta vicBackgroundColorRegister
sta kernelTextColor

;clear screen
ldy #0
lda #petsciiBlank

screenclearloop:
sta screen+0*256, y ;Screen page 0
sta screen+1*256, y ;Screen page 1
sta screen+2*256, y ;Screen page 2
sta screen+3*256, y ;Screen page 3
iny
bne screenclearloop

;setup raster interrupt
sei ;disable interrupts globally
;disable CIA's
lda #$7f ;everything except highest bit
sta cia1ControlRegister
sta cia2ControlRegister

;set rasterline for interrupt to fire on
lda #$7f
and vicInterruptControlRegister
sta vicInterruptControlRegister
+poke vicRasterInterruptScanlineSelectRegister, 100

;set IRQ handler pointer to ISR
+ldi16 kernelrqVector, rasterISRhigh

;enable raster interrupt
lda vicControlRegister
ora #$01 ;set raster interrupt enable bit to 1
sta vicControlRegister
cli ;Reenable interrupts

;set sprite modes
+poke vicSpriteMultiColorRegister, 0 ;disable multicolor mode for all sprites
+poke vicSpriteEnableRegister, 255 ;enable sprites 1 and 2 though bits 0 and 1

;set sprite block pointers
+poke vicSprite0bitmapBlockPointerRegister, sprite0block
+poke vicSprite1bitmapBlockPointerRegister, sprite1block
+poke vicSprite2bitmapBlockPointerRegister, sprite2block
+poke vicSprite3bitmapBlockPointerRegister, sprite3block
+poke vicSprite4bitmapBlockPointerRegister, sprite4block
+poke vicSprite5bitmapBlockPointerRegister, sprite5block
+poke vicSprite6bitmapBlockPointerRegister, sprite6block
+poke vicSprite7bitmapBlockPointerRegister, sprite7block

;set sprite colors
+poke vicSprite0colorRegister, vicColorWhite
+poke vicSprite1colorRegister, vicColorRed
+poke vicSprite2colorRegister, vicColorCyan
+poke vicSprite3colorRegister, vicColorPurple
+poke vicSprite4colorRegister, vicColorGreen
+poke vicSprite5colorRegister, vicColorBlue
+poke vicSprite6colorRegister, vicColorYellow
+poke vicSprite7colorRegister, vicColorBrown

;animation code starts here

;set sprite position high bites
lda #0
sta lowerSpritesPositionXhighBits
sta higherSpritesPositionXhighBites

;set sprite y positions
lda #50
sta sprite0lowerPositionY
sta sprite1lowerPositionY
sta sprite2lowerPositionY
sta sprite3lowerPositionY
sta sprite4lowerPositionY
sta sprite5lowerPositionY
sta sprite6lowerPositionY
sta sprite7lowerPositionY
lda #150
sta sprite0higherPositionY
sta sprite1higherPositionY
sta sprite2higherPositionY
sta sprite3higherPositionY
sta sprite4higherPositionY
sta sprite5higherPositionY
sta sprite6higherPositionY
sta sprite7higherPositionY

;set sprite x positions
lda #50
sta sprite0lowerPositionX
sta sprite0higherPositionX
lda #100
sta sprite1lowerPositionX
sta sprite1higherPositionX
lda #150
sta sprite2lowerPositionX
sta sprite2higherPositionX
lda #200
sta sprite3lowerPositionX
sta sprite3higherPositionX
lda #200
sta sprite4lowerPositionX
sta sprite4higherPositionX
lda #250
sta sprite5lowerPositionX
sta sprite5higherPositionX

gameloop:
jmp gameloop

rasterISRhigh:
sei
inc vicAcknowlageInterruptRegister ;acknowlage interrupt
inc vicBorderColorRegister ;visualize screen division
+mov vicSprite0positionXregister, sprite0higherPositionX
+mov vicSprite0positionYregister, sprite0higherPositionY
+mov vicSprite1positionXregister, sprite1higherPositionX
+mov vicSprite1positionYregister, sprite1higherPositionY
+mov vicSprite2positionXregister, sprite2higherPositionX
+mov vicSprite2positionYregister, sprite2higherPositionY
+mov vicSprite3positionXregister, sprite3higherPositionX
+mov vicSprite3positionYregister, sprite3higherPositionY
+mov vicSprite4positionXregister, sprite4higherPositionX
+mov vicSprite4positionYregister, sprite4higherPositionY
+mov vicSprite5positionXregister, sprite5higherPositionX
+mov vicSprite5positionYregister, sprite5higherPositionY
+mov vicSprite6positionXregister, sprite6higherPositionX
+mov vicSprite6positionYregister, sprite6higherPositionY
+mov vicSprite7positionXregister, sprite7higherPositionX
+mov vicSprite7positionYregister, sprite7higherPositionY
lda #$fe ;Everything except the lowest bit high
and vicSpritePositionsXhighbitRegister
sta r3
pha ;push r3 to the stack
lda #1
and higherSpritesPositionXhighBites
ora r3
sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 higher position x high bit
pla
sta r3 ;pull r3 from the stack
lda #$7f ;everything except the highest bit high
and vicInterruptControlRegister
sta vicInterruptControlRegister
+poke vicRasterInterruptScanlineSelectRegister, 250
+ldi16 kernelrqVector, rasterISRlow
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine ;return from interrupt, restoring regs using kernel rotinue

rasterISRlow:
sei
inc vicAcknowlageInterruptRegister ;acknowlage interrupt
dec vicBorderColorRegister ;visualize screen division
+mov vicSprite0positionXregister, sprite0lowerPositionX
+mov vicSprite0positionYregister, sprite0lowerPositionY
+mov vicSprite1positionXregister, sprite1lowerPositionX
+mov vicSprite1positionYregister, sprite1lowerPositionY
+mov vicSprite2positionXregister, sprite2lowerPositionX
+mov vicSprite2positionYregister, sprite2lowerPositionY
+mov vicSprite3positionXregister, sprite3lowerPositionX
+mov vicSprite3positionYregister, sprite3lowerPositionY
+mov vicSprite4positionXregister, sprite4lowerPositionX
+mov vicSprite4positionYregister, sprite4lowerPositionY
+mov vicSprite5positionXregister, sprite5lowerPositionX
+mov vicSprite5positionYregister, sprite5lowerPositionY
+mov vicSprite6positionXregister, sprite6lowerPositionX
+mov vicSprite6positionYregister, sprite6lowerPositionY
+mov vicSprite7positionXregister, sprite7lowerPositionX
+mov vicSprite7positionYregister, sprite7lowerPositionY
lda r3
and vicSpritePositionsXhighbitRegister
sta r3
pha ;push r3 to the stack
lda #1
and higherSpritesPositionXhighBites
ora r3
sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 lower position x high bit
pla
sta r3 ;pull r3 from the stack
lda #$7f ;everything except the highest bit high
and vicInterruptControlRegister
sta vicInterruptControlRegister
+poke vicRasterInterruptScanlineSelectRegister, 100
+ldi16 kernelrqVector, rasterISRhigh
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine ;return from interrupt, restoring regs using kernel rotinue

*=sprite0block*64 
;Deepseek told me this is a fish. I will let you be the judge...
!byte $00,$3C,$00
!byte $01,$42,$80
!byte $02,$99,$40
!byte $06,$24,$60
!byte $08,$18,$10
!byte $18,$3C,$18
!byte $30,$7E,$3C
!byte $60,$FF,$7E
!byte $C0,$FF,$FF
!byte $C0,$FD,$FF
!byte $BF,$FC,$FF
!byte $9F,$7F,$FF
!byte $3F,$FE,$7C
!byte $1F,$F8,$78
!byte $0F,$F0,$30
!byte $07,$E0,$00
!byte $03,$C0,$00
!byte $01,$80,$00
!byte $00,$00,$00
!byte $00,$00,$00
!byte $00,$00,$00

*=sprite1block*64
;Claude told me this is a fish. I will let you be the judge...
!byte $00,$00,$00  ; ........................
!byte $00,$70,$00  ; .........XXX............
!byte $00,$f8,$00  ; ........XXXXX...........
!byte $00,$00,$00  ; ........................
!byte $00,$20,$00  ; ..........X.............
!byte $03,$ff,$00  ; ......XXXXXXXXXX........
!byte $07,$ff,$c0  ; .....XXXXXXXXXXXXX......
!byte $0f,$ff,$f0  ; ....XXXXXXXXXXXXXXXX....
!byte $1b,$ff,$fc  ; ...XX.XXXXXXXXXXXXXXXX..   <- eye
!byte $1f,$ff,$fe  ; ...XXXXXXXXXXXXXXXXXXXX.
!byte $1f,$ff,$ff  ; ...XXXXXXXXXXXXXXXXXXXXX
!byte $1f,$ff,$fe  ; ...XXXXXXXXXXXXXXXXXXXX.
!byte $1f,$ff,$fc  ; ...XXXXXXXXXXXXXXXXXXX..
!byte $0f,$ff,$f0  ; ....XXXXXXXXXXXXXXXX....
!byte $07,$ff,$c0  ; .....XXXXXXXXXXXXX......
!byte $03,$ff,$00  ; ......XXXXXXXXXX........
!byte $00,$20,$00  ; ..........X.............
!byte $00,$f8,$00  ; ........XXXXX...........
!byte $00,$70,$00  ; .........XXX............
!byte $00,$00,$00  ; ........................
!byte $00,$00,$00  ; ........................

*=sprite2block*64
;Github copilot told me this is a fish. I will let you be the judge...
!byte %00000000, %00000000, %00000000
!byte %00000000, %00000000, %00000000
!byte %00000000, %00011100, %00000000
!byte %00000000, %00111110, %00000000
!byte %00000000, %01111111, %00000000
!byte %00000000, %11111111, %10000000
!byte %00000001, %11111111, %11000000
!byte %00000011, %11111111, %11100000
!byte %00000111, %11111111, %11110000
!byte %00001111, %11011111, %11111000   ; eye gap hint
!byte %00011111, %10111111, %11111100   ; eye pixel region
!byte %00001111, %11011111, %11111000
!byte %00000111, %11111111, %11110000
!byte %00000011, %11111111, %11100000
!byte %00000001, %11111111, %11000000
!byte %00000000, %11111111, %10000000
!byte %00000000, %01111111, %00000000
!byte %00000000, %00111110, %00000000
!byte %00000000, %00011100, %00000000
!byte %00000000, %00001000, %00000000
!byte %00000000, %00000000, %00000000

*=sprite3block*64
;Chatgpt told me this is a fish. I will let you be the judge...
!byte %00000000,%00000000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00111100,%00000000
!byte %00000000,%01111110,%00000000
!byte %00000111,%11111111,%00000000
!byte %00011111,%11111111,%10000000
!byte %00111111,%11111111,%11100000
!byte %01111111,%11111111,%11110000
!byte %11111111,%10111111,%11111000
!byte %11111111,%11111111,%11111100
!byte %11111111,%11111111,%11111000
!byte %01111111,%11111111,%11110000
!byte %00111111,%11111111,%11100000
!byte %00011111,%11111111,%10000000
!byte %00000111,%11111111,%00000000
!byte %00000000,%01111110,%00000000
!byte %00000000,%00111100,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00011000,%00000000
!byte %00000000,%00100100,%00000000
!byte %00000000,%01000010,%00000000

*=sprite4block*64
;Gamini told me this is a fish. I will let you be the judge...
!byte %00000000, %00001100, %00000000
!byte %00000000, %00011110, %00000000
!byte %00000000, %00111111, %00000000
!byte %00000001, %11111111, %10000000
!byte %00000111, %11111111, %11000000
!byte %00001111, %11111111, %11100000
!byte %00011111, %11011111, %11110000   ; Contains eye space
!byte %00111111, %10011111, %01111000
!byte %01111111, %11111111, %00111100   ; Tail narrows
!byte %01111111, %11111110, %00011110   ; Tail tip 1
!byte %01111111, %11111100, %00001111   ; Tail split
!byte %01111111, %11111110, %00011110   ; Tail tip 2
!byte %00111111, %11111111, %00111100
!byte %00011111, %11111111, %01111000
!byte %00001111, %11111111, %11100000
!byte %00000111, %11111111, %11000000
!byte %00000001, %11111111, %10000000
!byte %00000000, %00111111, %00000000
!byte %00000000, %00011110, %00000000
!byte %00000000, %00001100, %00000000
!byte %00000000, %00000000, %00000000

*=sprite5block*64
;Grok told me this is a fish. I will let you be the judge...
!byte %00000000, %00000000, %00000000   ; row 0
!byte %00000000, %00000000, %00000000   ; row 1
!byte %00001110, %00000000, %00000000   ; row 2  .. dorsal fin
!byte %00011111, %00000000, %00000000   ; row 3
!byte %00111111, %10000000, %00000000   ; row 4
!byte %01111111, %11000000, %00000000   ; row 5
!byte %01111111, %11100000, %00000000   ; row 6
!byte %11111111, %11110000, %00000000   ; row 7  .. body
!byte %11111111, %11111000, %00000000   ; row 8
!byte %11111111, %11111100, %00000000   ; row 9  .. eye area (you can set a pixel for eye)
!byte %11111111, %11111110, %00000000   ; row 10
!byte %11111111, %11111111, %00000000   ; row 11
!byte %11111111, %11111111, %10000000   ; row 12
!byte %01111111, %11111111, %11000000   ; row 13
!byte %01111111, %11111111, %10000000   ; row 14
!byte %00111111, %11111111, %00000000   ; row 15
!byte %00011111, %11111100, %00000000   ; row 16
!byte %00001111, %11100000, %00000000   ; row 17  .. tail
!byte %00000111, %10000000, %00000000   ; row 18
!byte %00000000, %00000000, %00000000   ; row 19
!byte %00000000, %00000000, %00000000   ; row 20

*=sprite6block*64
;Mistral told me this is a fish. I will let you be the judge...
!byte $00, $00, $00, $00, $00, $00, $00, $00 ; Top border (empty)
!byte $00, $00, $00, $00, $00, $00, $00, $00
!byte $00, $00, $00, $18, $18, $00, $00, $00 ; Fish body starts
!byte $00, $00, $3C, $7E, $7E, $3C, $00, $00 ; Fish body (widest part)
!byte $00, $00, $7E, $FF, $FF, $7E, $00, $00 ; Fish body (middle)
!byte $00, $00, $3C, $7E, $7E, $3C, $00, $00 ; Fish body (end)
!byte $00, $00, $00, $18, $18, $00, $00, $00 ; Fish tail
!byte $00, $00, $00, $00, $00, $00, $00, $00 ; Bottom border (empty)
!byte $00, $00, $00, $00, $00, $00, $00, $00