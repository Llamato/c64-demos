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
vicColorLightBrown = 8
vicColorDarkBrown = 9
vicColorVeryLightBrown = 10
vicColorDarkGray = 11
vicColorGray = 12
vicColorLightGreen = 13
vicColorLightBlue = 14
vicColorLightGray = 15

;Vic Registers
screen = $400 ;4*256 = 1024
vicAcknowlageInterruptRegister = $d019
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicControlRegister = $d01a
vicSpriteMultiColorRegister = $d01c
vicSpriteEnableRegister = $d015
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite0bitmapBlockPointerRegister = $07f8
vicSprite0colorRegister = $d027
vicSpritePositionsXhighbitRegister = $d010
vicRasterInterruptScanlineSelectRegister = $d012
vicInterruptControlRegister = $d011

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
sprite7block = 135

;Programm memory
rExtra = 2
r0 = 251
r1 = 252
r2 = 253
r3 = 254
sprite0lowerPositionX = $c000
sprite0lowerPositionY = $c001
sprite0higherPositionX = $c002
sprite0higherPositionY = $c003

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
+ldi16 kernelrqVector. rasterISR100

;enable raster interrupt
lda vicControlRegister
ora #$01 ; set raster interrupt enable bit to 1
sta vicControlRegister
cli ;Reenable interrupts

;setup sprites
lda #0
sta vicSpriteMultiColorRegister ;disable multicolor for all sprites
+poke vicSprite0bitmapBlockPointerRegister, sprite0block ;sprite one bitmap block set to 100*64
+poke vicSpriteEnableRegister, 3 ;enable sprites 1 and 2 though bits 0 and 1

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

;set sprite positions
lda #0
sta lowerSpritesPositionXhighBits
sta higherSpritesPositionXhighBites
lda #50
sta sprite0lowerPositionX
sta sprite0lowerPositionY
lda #150
sta sprite0higherPositionX
sta sprite0higherPositionY

;set upper sprite positions
gameloop:
jmp gameloop

rasterISR100:
sei
inc vicAcknowlageInterruptRegister ;acknowlage interrupt
inc vicBorderColorRegister ;visualize screen division
lda sprite0higherPositionY
sta vicSprite0positionYregister
lda sprite0lowerPositionX
sta vicSprite0positionXregister
lda #$fe ;Everything execpt the lowest bit high
and vicSpritePositionsXhighbitRegister
sta r3
pha ;push r3 to the stack
lda #1
and higherSpritesPositionXhighBites
ora r3
sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 higher position x high bit
pla
sta r3 ;pull r3 from the stack
lda #$7f ;everything execpt the highest bit high
and vicInterruptControlRegister
sta vicInterruptControlRegister
lda #250 ;raster line 250
sta vicRasterInterruptScanlineSelectRegister
lda #<rasterISR250
sta kernelrqVector
lda #>rasterISR250
sta kernelrqVector+1 ;setup next raster interrupt
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine ;return from interrupt, restoring regs using kernel rotinue

rasterISR250:
sei
inc vicAcknowlageInterruptRegister ;acknowlage interrupt
dec vicBorderColorRegister ;visualize screen division
lda sprite0lowerPositionX
sta vicSprite0positionXregister
lda sprite0lowerPositionY
sta vicSprite0positionYregister
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
lda #$7f ;everything execpt the highest bit high
and vicInterruptControlRegister
sta vicInterruptControlRegister
lda #100 ;raster line 100
sta vicRasterInterruptScanlineSelectRegister
lda #<rasterISR100
sta kernelrqVector
lda #>rasterISR100
sta kernelrqVector+1 ;setup next raster interrupt
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