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

;Vic Registers
screen = $400; 4*256 = 1024
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
cia1ControlReigster = $dc0d
cia2ControlRegister = $dd0d

;Kernel
kernelrqVector = $0314 ;$0314-0315
kernelTextColor = $286
kernelRestoreRegistersAndReturnFromInterruptRotine = $ea81

;Programm
sprite0block = 128

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
lda #$7f ;everything execpt highest bit
sta cia1ControlReigster
sta cia2ControlRegister

;set rasterline for interrupt to fire on
lda #$7f
and vicInterruptControlRegister
sta vicInterruptControlRegister
lda #100 ; line 100
sta vicRasterInterruptScanlineSelectRegister

;set IRQ handler pointer to ISR
lda #<rasterISR100
sta kernelrqVector ;low byte set
lda #>rasterISR100
sta kernelrqVector+1 ;high byte set


;enable raster interrupt
lda vicControlRegister
ora #$01 ; set raster interrupt enable bit to 1
sta vicControlRegister
cli ;Reenable interrupts

;setup sprite
lda #sprite0block
sta vicSprite0bitmapBlockPointerRegister ;sprite one bitmap block set to 100*64
lda #0
sta vicSpriteMultiColorRegister ;disable multicolor for all sprites
lda #1 ;(1 << 0) = 1
sta vicSpriteEnableRegister ;enable sprite 1
lda #vicColorWhite
sta vicSprite0colorRegister


;animation code starts here

;set sprite positions
lda #0
sta $cffe ;lower sprites x position high bits
sta $cfff ;higher sprites x position high bits
lda #50
sta $c000 ;sprite 0 lower position x = 50
sta $c001 ;sprite 0 lower position y = 50
lda #150
sta $c002 ;sprite 0 higher position x = 150
sta $c003 ;sprite 0 higher position y = 150

;set upper sprite positions
gameloop:
jmp gameloop

rasterISR100:
sei
inc $d019 ;acknowlage interrupt
inc vicBorderColorRegister ;visualize screen division
lda $c003
sta vicSprite0positionYregister ;sprite 0 position y = sprite 0 higher position y
lda $c002
sta vicSprite0positionXregister ;sprite 0 position x = sprite 0 higher position x
lda #$fe
and vicSpritePositionsXhighbitRegister
sta 254
lda 254 ;tmp reg 1
pha ;save temp reg 1 to stack
lda #1
and $cfff
ora 254
sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 higher position x high bit
pla
sta 254 ;restore temp reg 1 from stack
lda #$7f
and vicInterruptControlRegister
sta vicInterruptControlRegister
lda #250 ; line 250
sta vicRasterInterruptScanlineSelectRegister
lda #<rasterISR250
sta kernelrqVector
lda #>rasterISR250
sta kernelrqVector+1 ;setup next raster interrupt
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRotine ;return from interrupt, restoring regs using kernel rotinue


rasterISR250:
sei
inc $d019 ;acknowlage interrupt
dec vicBorderColorRegister ;visualize screen division
lda $c001
sta vicSprite0positionYregister ;sprite 0 position y = sprite 0 lower position y
lda $c000
sta vicSprite0positionXregister ;sprite 0 position x = sprite 0 lower position x
lda $fe
and vicSpritePositionsXhighbitRegister
sta 254
lda 254 ;tmp reg 1
pha ;save temp reg 1 to stack
lda #1
and $cfff
ora 254
sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 lower position x high bit
pla
sta 254 ;restore temp reg 1 from stack
lda #$7f
and vicInterruptControlRegister
sta vicInterruptControlRegister
lda #100 ; line 100
sta vicRasterInterruptScanlineSelectRegister
lda #<rasterISR100
sta kernelrqVector
lda #>rasterISR100
sta kernelrqVector+1 ;setup next raster interrupt
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRotine ;return from interrupt, restoring regs using kernel rotinue

*=sprite0block*64
fish: 
;The AI I had this draw told me this is a fish. I will let you be the judge...
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