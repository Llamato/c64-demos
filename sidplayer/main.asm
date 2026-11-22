* = $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Vic Registers
vicScreenControl1Register = $d011  ; bits 0-2 = y scroll, bit 5 = 40/80 columns, bit 7 = 9th bit of the raster compare line
vicRasterInterruptScanlineSelectRegister = $d012  ; low 8 bits of the raster compare line, the 9th bit lives in $d011 bit 7
vicInterruptControlRegister = $d01a  ; interrupt enable bits, bit 0 = raster
vicBorderColorRegister = $d020

;Cia Registers
cia1ControlRegister = $dc0d  ; interrupt control register, bit 7 = all interrupts off
cia2ControlRegister = $dd0d  ; interrupt control register, bit 7 = all interrupts off

;Sid Registers
sidVoice3ValueRegister = $d41b

;Kernel Registers
kernelIrqVector = $0314  ; $0314-0315

;Kernel Routines
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81



;Sid file constants
sidFileStartAddress = $1200
sidFilePlaybackAddress = sidFileStartAddress+3

;setup raster interrupt
sei ;disable interrupts globally
;disable CIA's
lda #$7f ;everything except highest bit
sta cia1ControlRegister
sta cia2ControlRegister

;set rasterline for interrupt to fire on
lda #$7f
and vicScreenControl1Register
sta vicScreenControl1Register
lda #100 ;line 100
sta vicRasterInterruptScanlineSelectRegister

;set IRQ handler pointer to ISR
lda #<rasterISR100
sta kernelIrqVector ;low byte set
lda #>rasterISR100
sta kernelIrqVector+1 ;high byte set

;enable raster interrupt
lda vicInterruptControlRegister
ora #$01 ;set raster interrupt enable bit to 1
sta vicInterruptControlRegister
cli ;reenable interrupts

;initialize sid
lda #0
tax
tay
jsr sidFileStartAddress ;run sid initializer

holdAndCatchFire:
jmp holdAndCatchFire

rasterISR100:
lda #$01
sta $d019 ;acknowledge interrupt
inc vicBorderColorRegister
jsr sidFilePlaybackAddress ;jump to sid play address. Playing next note.
dec vicBorderColorRegister
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine

* = $1200
;Sid file
!bin "drdoom.sid",, $7c+2 ; Skip sid header