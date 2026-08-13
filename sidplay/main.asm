setup raster interrupt
sei ;disable interrupts globally
;disable CIA's
lda #$7f ;everything except highest bit
sta cia1ControlRegister
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

;initalize sid
lda #0
tax
tay
jsr $c000 ; run sid initializer

holdandcatchfire:
jmp holdandcatchfire

rasterISR100:
sei
inc $d019 ;acknowlage interrupt
inc $d020
jsr $c006 ;play next node
dec $d020
cli
jmp $ea81 ;return from interrupt


*=$c000
!bin "drdoom.sid",, $7c+2