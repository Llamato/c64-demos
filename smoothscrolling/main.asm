* = $0801
; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for sys
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Vic Registers
vicScreenControl1Register = $d011
vicRasterInterruptScanlineSelectRegister = $d012
vicScreenControl2Register = $d016
vicAcknowledgeInterruptRegister = $d019
vicInterruptControlRegister = $d01a

;C64 Memory
screen = $0400
screenColumns = 40

;Cia Registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d

;Kernel Registers
kernelIrqVector = $0314

;Kernel Routines
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81


;petscii characters
petsciiSpace = $20

;Hardware constants
pageSize = 256

;application constants
refillColumn = 39
scrollTextRow = 12 
scrollRow = screen+scrollTextRow*screenColumns
rasterline = 255

;zeropage registers
scrollPixel = $f8 ;0-7, the hardware x scroll shown this frame
textIndex = $f9 ;which message character enters at the right edge next

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro shiftScrollRow {
    
}

init:
;clear screens
    lda #petsciiSpace
    ldx #0
.screenclearloop
!for .currentPage, 0, 2 {
    sta screen+.currentPage*pageSize, x
}
    inx
    bne .screenclearloop
    ldx #231
.screenclearloop2
    sta screen+3*pageSize, x
    dex
    bpl .screenclearloop2

;prime the marquee row and start the fine scroll at 0
    +poke scrollPixel, 0

;setup raster interrupt
    sei ;disable interrupts globally
;disable CIA's
    lda #$7f ;everything except highest bit
    sta cia1ControlRegister
    sta cia2ControlRegister

;set rasterline for interrupt to fire on
    lda #$7f ;clear $d011 bit 7 (raster compare bit 8), else $d012=$ff means line 511 and the irq never fires
    and vicScreenControl1Register
    sta vicScreenControl1Register
    +poke vicRasterInterruptScanlineSelectRegister, rasterline

;set IRQ handler pointer to ISR
    +ldi16 kernelIrqVector, rasterISR

;enable raster interrupt
    lda vicInterruptControlRegister
    ora #$01 ;set raster interrupt enable bit to 1
    sta vicInterruptControlRegister
    cli ;reenable interrupts
    jmp * ;jump to self for infinite loop

rasterISR:
!zone rasterISR {
    lda #$01
    sta vicAcknowledgeInterruptRegister
    sei
    lda scrollPixel
    sec
    sbc #1
    sta scrollPixel
    bcs .applyFineScroll
    +poke scrollPixel, 7
    ldx #0
.shiftScrollLoop:
    lda scrollRow+1, x
    sta scrollRow, x
    inx
    cpx #refillColumn
    bne .shiftScrollLoop
    ldy textIndex
    lda scrollText, y
    sta scrollRow+refillColumn
    iny
    cpy #scrollTextLength
    bne .nowrap
    ldy #0
.nowrap:
    sty textIndex
.applyFineScroll:
    lda vicScreenControl2Register
    and #%11111000 ;keep everything but the three fine scroll bits
    ora scrollPixel
    sta vicScreenControl2Register
.returnFromInterrupt:
    +ldi16 kernelIrqVector, rasterISR
    cli
    jmp kernelRestoreRegistersAndReturnFromInterruptRoutine
}

scrollText:
!scr "the horse does not eat mashed portatos.          heat from fire, fire from heat.          "
scrollTextLength = *-scrollText
