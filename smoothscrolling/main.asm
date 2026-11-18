*= $0801
; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for sys
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Vic Registers
    vicSprite0positionXregister                          = $d000
    vicSprite0positionYregister                          = $d001
    vicSpritePositionsXhighbitRegister                   = $d010  ; bit n = x bit 8 of sprite n
    vicScreenControl1Register                            = $d011  ; bits 0-2 = y scroll, bit 5 = 40/80 columns, bit 7 = 9th bit of the raster compare line
    vicRasterInterruptScanlineSelectRegister             = $d012  ; low 8 bits of the raster compare line, the 9th bit lives in $d011 bit 7
    vicSpriteEnableRegister                              = $d015  ; bit n enables sprite n
    vicScreenControl2Register                            = $d016  ; bit 5 = multicolor mode, bits 0-2 = x scroll
    vicMemoryPointersRegister                            = $d018  ; screen, charset and sprite expansion blocks
    vicAcknowledgeInterruptRegister                      = $d019  ; read: interrupt flags, write: acknowledge them
    vicInterruptControlRegister                          = $d01a  ; interrupt enable bits, bit 0 = raster
    vicBorderColorRegister                               = $d020
    vicBackgroundColorRegister                           = $d021
    vicSprite0colorRegister                              = $d027
    vicSprite0bitmapBlockPointerRegister                 = $07f8

;C64 Memory
    screen                                               = $0400  ; 4*256 = 1024
    colorRam                                             = $d800  ; d800-dbe7 = 1000 * 4 bit (lower byte only)
    screenColumns                                        = 40
    screenRows                                           = 25
    chargenRom                                           = $e000  ; character rom, visible to the cpu here while romsel=0

;Cia Registers
    cia1TimerControlRegister                             = $dc05
    cia1ControlRegister                                  = $dc0d  ; interrupt control register, bit 7 = all interrupts off
    cia2TimerControlRegister                             = $dd05
    cia2ControlRegister                                  = $dd0d  ; interrupt control register, bit 7 = all interrupts off

;Kernel Registers
    kernelIrqVector                                      = $0314  ; $0314-0315

;Kernel Routines
    kernelRestoreRegistersAndReturnFromInterruptRoutine  = $ea81

;Cpu Registers
    cpuBankRegister                                      = $01    ; cpu ram/rom select, bit 3 = romsel

;Joysticks
joystickPort1 = $dc01
joystickPort2 = $dd01


;petscii characters
petsciiSpace = $20
petsciiDollar = $24
petsciiSolidBlock = $a0 ;chargen full block, used for the dirt
petsciiSurfaceBlock = $78 ;chargen top-half block: the surface line

;application constants
hudRows = 2 ;rows 0-1 are the hud and never shift
refillColumn = 39 ;new terrain enters here when scrolling left
maxScrollSpeed = 2 ;pixels per frame of the fine scroll
playerScreenX = 100 ;the runner stays at a fixed screen x
playerScreenColumn = 13 ;screen column under the middle of the runner
feetSpriteRow = 17 ;sprite art row that touches the ground
surfacePixelOffset = 4 ;the surface line sits 4 pixels into the ground row
;a sprite y of 0 appears at raster 18, a text row r starts at raster 51+8r.
;feet row 17 on the surface line: y + 18 + 17 = 51 + 8*groundRow + 4
groundYOffset = 32 ;y = 8*groundRow + 32. measured in vice: with 20 the
;feet sat ~12 rasters above the surface line (looked like a floating tile);
;32 puts the feet row right on top of the ground block.
jumpVelocityHigh = $fc ;-4.0 px/frame in 8.8 fixed point
jumpVelocityLow = 0
gravity = 64 ;+0.25 px/frame^2 in 8.8 fixed point. with the 4 px/frame
;launch this gives a 16 frame rise of 32 pixels (4 text rows) and the same
;fall back: about half a second of air. measured in vice with the old value
;of 32 the arc was 66 pixels high and hung for a full second, which looked
;floaty.
rasterline = 255 ;irq in the lower border, no bad lines

;zeropage registers
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro strcpy .dest, .src {
    ldx #0
.loop
    lda .src , x
    cmp #$00
    beq .done
    sta .dest, x
    inx
    jmp .loop
.done
}

init:
;clear screen
    lda #petsciiSpace
    ldx #0
.screenclearloop
    sta screen+0*256, x
    sta screen+1*256, x
    sta screen+2*256, x
    inx
    bne .screenclearloop
    ldx #231
.screenclearloop2
    sta screen+3*256, x
    dex
    bpl .screenclearloop2

;copy hello world string
    +strcpy screen, helloWorldString

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
    lda #$7f ;clear $d01a bit 7
    and vicInterruptControlRegister
    sta vicInterruptControlRegister
    +poke vicRasterInterruptScanlineSelectRegister, rasterline

;set IRQ handler pointer to ISR
    +ldi16 kernelIrqVector, rasterISR

;enable raster interrupt
    lda vicInterruptControlRegister
    ora #$01 ;set raster interrupt enable bit to 1
    sta vicInterruptControlRegister
    cli ;reenable interrupts

demoloop:

    jmp demoloop

rasterISR:
    lda #$01
    sta vicAcknowledgeInterruptRegister
    sei
    inc screen
    inc vicBackgroundColorRegister
    +ldi16 kernelIrqVector, rasterISR
    cli
    jmp kernelRestoreRegistersAndReturnFromInterruptRoutine

veryShortDelay:
!zone veryShortDelay {
    ldx #255
.loop
    dex
    bne .loop
}

helloWorldString:
!scr "hello world!"
!byte $00
