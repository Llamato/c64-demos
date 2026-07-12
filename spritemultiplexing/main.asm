*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

*=$080d
;set colors
lda #13
sta 53280
lda #0
sta 53281
sta 646

;clear screen
ldy #0
lda #32
screenclearloop:
sta 1024, y
sta 1024+256, y
sta 1024+512, y
sta 1024+768, y
iny
bne screenclearloop

;setup raster interrupt
sei ;disable interrupts globally
;disable CIA's
lda #$7f
sta $dc0d
sta $dd0d

;set rasterline for interrupt to fire on
lda #$7f
and $d011
sta $d011
lda #100 ; line 100
sta $d012

;set IRQ handler pointer to ISR
lda #<rasterISR100
sta $0314 ;low byte set
lda #>rasterISR100
sta $0315 ;high byte set


;enable raster interrupt
lda $d01a
ora #$01
sta $d01a
cli ;Reenable interrupts

;setup sprite
lda #251
sta $07f8 ;sprite one bitmap block set to 251*64
lda #0
sta $d01c ;disable multicolor for all sprites
lda #1
sta $d015 ;enable sprite 1


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
inc 53280 ;visualize screen division
lda $c003
sta $d001 ;sprite 0 position y = sprite 0 higher position y
lda $c002
sta $d000 ;sprite 0 position x = sprite 0 higher position x
lda #$fe
and $d010
sta 254
lda 254 ;tmp reg 1
pha ;save temp reg 1 to stack
lda #1
and $cfff
ora 254
sta $d010 ;sprite 0 position x high bit = sprite 0 higher position x high bit
pla
sta 254 ;restore temp reg 1 from stack
lda #$7f
and $d011
sta $d011
lda #250 ; line 250
sta $d012
lda #<rasterISR250
sta $0314
lda #>rasterISR250
sta $0315 ;setup next raster interrupt
cli
jmp $ea81 ;return from interrupt, restoring regs using kernel rotinue


rasterISR250:
sei
inc $d019 ;acknowlage interrupt
dec 53280 ;visualize screen division
lda $c001
sta $d001 ;sprite 0 position y = sprite 0 lower position y
lda $c000
sta $d000 ;sprite 0 position x = sprite 0 lower position x
lda $fe
and $d010
sta 254
lda 254 ;tmp reg 1
pha ;save temp reg 1 to stack
lda #1
and $cfff
ora 254
sta $d010 ;sprite 0 position x high bit = sprite 0 lower position x high bit
pla
sta 254 ;restore temp reg 1 from stack
lda #$7f
and $d011
sta $d011
lda #100 ; line 100
sta $d012
lda #<rasterISR100
sta $0314
lda #>rasterISR100
sta $0315 ;setup next raster interrupt
cli
jmp $ea81 ;return from interrupt, restoring regs using kernel rotinue

*=251*64
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