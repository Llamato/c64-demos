*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Vic Registers
vicBorderColorRegister = $d020
vicControlRegister = $d01a
vicRasterInterruptScanlineSelectRegister = $d012
vicInterruptControlRegister = $d011

;CIA
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d

;Kernel
kernelrqVector = $0314 ;$0314-0315
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81

;Sid file
sidFileLoadinAddress = $1200
sidFilePlaybackAddress = sidFileLoadinAddress+3

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
jsr sidstart ; run sid initializer
rts ; main  programm is finished here

rasterISR100:
lda #$01
sta $d019 ; Acknowledge interrupt
inc vicBorderColorRegister
jsr $1203
dec vicBorderColorRegister
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine


*=sidFileLoadinAddress
sidstart:
!bin "drdoom.sid",, $7c+2