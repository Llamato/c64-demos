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
vicControlRegister1 = $d011
vicControlRegister2 = $d016
vicMemoryPointersRegister = $d018
vicRasterInterruptScanlineSelectRegister = $d012
vicAcknowlageInterruptRegister = $d019
vicInterruptControlRegister = $d01a
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicSpriteEnableRegister = $d015
vicSpritePositionsXhighbitRegister = $d010
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite0colorRegister = $d027
vicSprite0bitmapBlockPointerRegister = $07f8

;Screen and Color Ram
screen = $0400
colorRam = $d800

;CIA registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d
cia1TimerControlRegister = $dc05
cia2TimerControlRegister = $dd05

;Joysticks
joystickPort1 = $dc01
joystickPort2 = $dd01

;Kernel
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81
kernelrqVector = $0314 ;$0314-0315
chargenRom = $e000 ;character rom, visible to the cpu here while romsel=0
cpuBankRegister = $01
cpuBankRegister = $01

;petscii characters
petsciiSpace = $20
petsciiDollar = $24
petsciiSolidBlock = $a0 ;chargen full block, used for the dirt
petsciiSurfaceBlock = $78 ;chargen top-half block: the surface line

;application constants
screenColumns = 40
screenRows = 25
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
    lda #$7f
    and vicInterruptControlRegister
    sta vicInterruptControlRegister
    +poke vicRasterInterruptScanlineSelectRegister, rasterline

;set IRQ handler pointer to ISR
    +ldi16 kernelrqVector, rasterISR

;enable raster interrupt
    lda vicInterruptControlRegister
    ora #$01 ;set raster interrupt enable bit to 1
    sta vicInterruptControlRegister
    cli ;reenable interrupts

demoloop:

    jmp demoloop

rasterISR:
    lda #$01
    sta vicAcknowlageInterruptRegister
    sei
    inc screen/
    inc vicBackgroundColorRegister
    +ldi16 kernelrqVector, rasterISR
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
