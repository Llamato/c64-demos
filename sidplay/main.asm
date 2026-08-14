*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;CIA
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d

;Kernel
kernelrqVector = $0314 ;$0314-0315
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81

;Sid file constants
sidFileStartAddress = $1200
sidFilePlaybackAddress = sidFileStartAddress+3

;Vic Registers
vicBorderColorRegister = $d020
vicControlRegister = $d01a
vicSpritesPositionXhighRegister = $d010
vicInterruptControlRegister = $d011
vicRasterInterruptScanlineSelectRegister = $d012
vicSpriteEnableRegister = $d015
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite0bitmapBlockPointerRegister = $07f8
vicSprite0colorRegister = $d027
vicSprite1colorRegister = $d028
vicSprite2colorRegister = $d029
vicSprite3colorRegister = $d02a
vicSprite1positionXregister = $d002
vicSprite1positionYregister = $d003
vicSprite1bitmapBlockPointerRegister = $07f9
vicSprite1colorRegister = $d028
vicSprite2positionXregister = $d004
vicSprite2positionYregister = $d005
vicSprite2bitmapBlockPointerRegister = $07fa
vicSprite3colorRegister = $d02a
vicSprite3positionXregister = $d006
vicSprite3positionYregister = $d007
vicSprite3bitmapBlockPointerRegister = $07fb

;Program registers
r0 = $c000
r1 = $c001
r2 = $f7
r3 = $f8
r4 = $c002
r5 = $c003
r6 = $c004
r7 = $c005
rExtra = $c006

;Visualisation constants
sprite0block = 128
sprite1block = 129
sprite2block = 130
sprite3block = 131
spriteBytesPerRow = 3
bitsPerByte = 8
spriteColumns = 24
spriteRows = 21
spriteStride = 64
spriteLength = 63

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro fmb .addr, .length, .value {
    lda #.value
    ldx #0
.loop
    cpx #.length
    beq .done
    sta .addr, x
    inx
    jmp .loop
.done
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro mov16 .dest, .src {
    +mov .dest, .src
    +mov .dest+1, .src+1
}

!macro push .addr {
    lda .addr
    pha
}

!macro pull .addr {
    pla
    sta .addr
}

!macro setBit .byteAddr, .bitNr {
    lda #(1<<.bitNr)
    ora .byteAddr
    sta .byteAddr
}

!macro clearBit .byteAddr, .bitNr {
    lda #(1<<.bitNr)^255
    and .byteAddr
    sta .byteAddr
}

!macro setSpritePositionX .spriteNr, .xPosition {
    !if .xPosition > 255 {
        +setBit vicSpritesPositionXhighRegister, .spriteNr
    } else {
        +clearBit vicSpritesPositionXhighRegister, .spriteNr
    }
    +poke vicSprite0positionXregister+2*.spriteNr, <(.xPosition & 255)
}

!macro setSpritePositionY .spriteNr, .yPosition {
    +poke vicSprite0positionYregister+2*.spriteNr, .yPosition
}

!macro add168 .accumulator, .accumulative {
    lda .accumulator
    clc
    adc .accumulative
    sta .accumulator
    lda .accumulator+1
    adc #0
    sta .accumulator+1
}

!macro add16 .accumulator, .accumulative {
  lda .accumulator
  clc
  adc .accumulative
  sta .accumulator
  lda .accumulator+1
  adc .accumulative+1
  sta .accumulator+1
}

!macro mul8816 .factor1addr, .factor2addr, .resultLow, .resultHigh {
  lda #0
  sta .resultLow
  sta .resultHigh
  ldx #8
.loop:
  lsr .factor1addr
  bcc .noAdd
  lda .resultHigh
  clc
  adc .factor2addr
  sta .resultHigh
.noAdd:
  ror .resultHigh
  ror .resultLow
  dex
  bne .loop
}

!macro div168 .dividend, .divisor, .remainder {
.divide:
    lda #0
    sta .remainder
    ldx #16
.divloop
    asl .dividend
    rol .dividend+1
    rol .remainder
    lda .remainder
    sec
    sbc .divisor
    bcc .skip
    sta .remainder
    inc .dividend
.skip
    dex
    bne .divloop
    rts
}

!macro div16 .dividend, .divisor, .remainder {
.divide:
    lda #0
    sta .remainder
    sta .remainder+1
    ldx #16
.divloop
    asl .dividend
    rol .dividend+1
    rol .remainder
    rol .remainder+1
    lda .remainder
    sec
    sbc .divisor
    tay
    lda .remainder+1
    sbc .divisor+1
    bcc .skip
    sta .remainder+1
    sty .remainder
    inc .dividend
.skip
    dex
    bne .divloop
    rts
}

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
lda #100 ;line 100
sta vicRasterInterruptScanlineSelectRegister

;set IRQ handler pointer to ISR
lda #<rasterISR100
sta kernelrqVector ;low byte set
lda #>rasterISR100
sta kernelrqVector+1 ;high byte set

;enable raster interrupt
lda vicControlRegister
ora #$01 ;set raster interrupt enable bit to 1
sta vicControlRegister
cli ;reenable interrupts

;visualisation starts here
;enable sprites
+poke vicSpriteEnableRegister, $0f

;set sprite pointers
+poke vicSprite0bitmapBlockPointerRegister, sprite0block
+poke vicSprite1bitmapBlockPointerRegister, sprite1block
+poke vicSprite2bitmapBlockPointerRegister, sprite2block
+poke vicSprite3bitmapBlockPointerRegister, sprite3block

;position sprites
+setSpritePositionX 0, 40
+setSpritePositionY 0, 100
+setSpritePositionX 1, 80
+setSpritePositionY 1, 100
+setSpritePositionX 2, 120
+setSpritePositionY 2, 100
+setSpritePositionX 3, 220
+setSpritePositionY 3, 100

;color sprites
+poke vicSprite0colorRegister, 1
+poke vicSprite1colorRegister, 2
+poke vicSprite2colorRegister, 3
+poke vicSprite3colorRegister, 4

;clear sprites
+fmb sprite0block * spriteStride, spriteLength, 0
+fmb sprite1block * spriteStride, spriteLength, 0
+fmb sprite2block * spriteStride, spriteLength, 0
+fmb sprite3block * spriteStride, spriteLength, 0

;initialize sid
lda #0
tax
tay
jsr sidFileStartAddress ;run sid initializer

;draw Circles
;0
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke rExtra, spriteRows / 2
+ldi16 r2, sprite0block * spriteStride
jsr makeCircleSpriteBresenham
;1
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke rExtra, spriteRows / 2
+ldi16 r2, sprite1block * spriteStride
jsr makeCircleSpriteBresenham
;2
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke rExtra, spriteRows / 2
+ldi16 r2, sprite2block * spriteStride
jsr makeCircleSpriteBresenham
;3
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke rExtra, spriteRows / 2
+ldi16 r2, sprite3block * spriteStride
jsr makeCircleSpriteBresenham

visloop:

jmp visloop

;r0 = position.x
;r1 = position.y
spritePixelPositionToBitmapPosition:
+poke rExtra, spriteBytesPerRow*bitsPerByte
+mul8816 rExtra, r1, r2, r3 ;r2:r3 = position.y * SPRITE_BYTES_PER_ROW * BITS_PER_BYTE
+add168 r2, r0 ;r2:r3 = bitPosition = position.y * SPRITE_BYTES_PER_ROW * BITS_PER_BYTE + position.x
+poke rExtra, bitsPerByte ;rExtra = bitsPerByte = 8
+mov16 r0, r2
+div168 r0, rExtra, r2 ;r0:r1 = bitPosition / bitsPerByte = byte, r2 = bitPosition % bitsPerByte = bit
rts

;r0 = position.x
;r1 = position.y
;r2:r3 = spriteBaseAddress
setSpritePixel:
!zone setSpritePixel {
    +push r2
    +push r3
    jsr spritePixelPositionToBitmapPosition 
    lda #(bitsPerByte - 1)
    sec
    sbc r2 ;A=((bitsPerByte - 1) - bitmapPosition.bit)
    tay ;Y=(bitsPerByte - 1) - bitmapPosition.bit)
    lda #1
.shift
    cpy #0
    beq .nomoreshift
    asl ;A=A<<1
    dey ;Y=Y-1
    jmp .shift
.nomoreshift
    sta rExtra ;rExtra=A=(1<<((bitsPerByte - 1) - bitmapPosition.bit)), Y=0
    +pull r3
    +pull r2
    ldy r0 ;Y=bitmapPosition.byte
    lda rExtra ;A=(1<<((bitsPerByte - 1) - bitmapPosition.bit)), Y=bitmapPosition.byte
    ora (r2), y ;A=spriteBaseAddress[Y] | (1<<((bitsPerByte - 1) - bitmapPosition.bit))
    sta (r2), y ;spriteBaseAddress[Y] = spriteBaseAddress[Y] | (1<<((bitsPerByte - 1) - bitmapPosition.bit))
    rts
}

;r0 = center.x
;r1 = center.y
;r2:r3 = spriteBaseAddress
;r4 = circumfrancePoint.x
;r5 = circumfrancePoint.y
mirrorCircleSegment:
+mov r6, r0
+mov r7, r1
+mov r0, r6
clc
adc r4
sta r0
+mov r1, r7
clc
adc r5
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x + circumfrancePoint.x, center.y + circumfrancePoint.y});
+mov r0, r6
sec
sbc r4
sta r0
+mov r1, r7
clc
adc r5
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x - circumfrancePoint.x, center.y + circumfrancePoint.y});
+mov r0, r6
clc
adc r4
sta r0
+mov r1, r7
sec
sbc r5
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x + circumfrancePoint.x, center.y - circumfrancePoint.y});
+mov r0, r6
sec
sbc r4
sta r0
+mov r1, r7
sec
sbc r5
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x - circumfrancePoint.x, center.y - circumfrancePoint.y});
+mov r0, r6
clc
adc r5
sta r0
+mov r1, r7
clc
adc r4
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x + circumfrancePoint.y, center.y + circumfrancePoint.x});
+mov r0, r6
sec
sbc r5
sta r0
+mov r1, r7
clc
adc r4
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x - circumfrancePoint.y, center.y + circumfrancePoint.x});
+mov r0, r6
clc
adc r5
sta r0
+mov r1, r7
sec
sbc r4
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x + circumfrancePoint.y, center.y - circumfrancePoint.x});
+mov r0, r6
sec
sbc r5
sta r0
+mov r1, r7
sec
sbc r4
sta r1
jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {center.x - circumfrancePoint.y, center.y - circumfrancePoint.x});
rts

;r0 = center.x
;r1 = center.y
;r2:r3 = spriteBaseAddress
;rExtra = radius
makeCircleSpriteBresenham:
!zone makeCircleSpriteBresenham {
    +poke r4, 0
    +mov r5, rExtra ;r4:r5 = circumfrancePoint = {0, r}
    asl rExtra
    lda #3
    sec
    sbc rExtra
    sta rExtra ;rExtra = d = 3 - (2 * r)
    +push rExtra
    +push r0
    +push r1
    jsr mirrorCircleSegment ;mirrorCircleSegment(bitmapPointer, center, circumfrancePoint);
    +pull r1
    +pull r0
    +pull rExtra
.loopHead ;while(circumfrancePoint.x < circumfrancePoint.y)
    lda r4
    cmp r5
    bcs .loopEnd
    lda rExtra
    bmi .dNegative
.dPositive
    dec r5 ;circumfrancePoint.y--;
    lda r4 ;A=circumfrancePoint.x
    sec
    sbc r5 ;A=circumfrancePoint.x - circumfrancePoint.y
    asl ;A=2 * (circumfrancePoint.x - circumfrancePoint.y)
    asl ;A=4 * (circumfrancePoint.x - circumfrancePoint.y)
    clc
    adc #10 ;A=4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
    adc rExtra ;A=d + 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
    sta rExtra ;rExtra = A = d + 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
    jmp .loopFooter
.dNegative
    lda r4 ;A=circumfrancePoint.x
    asl ;A=2 * circumfrancePoint.x
    asl ;A=4 * circumfrancePoint.x
    clc
    adc #6 ;A=4 * circumfrancePoint.x + 6
    adc rExtra ;A=d + 4 * circumfrancePoint.x + 6
    sta rExtra ;rExtra = A = d + 4 * circumfrancePoint.x + 6
.loopFooter
    inc r4 ;circumfrancePoint.x++;
    +push rExtra
    +push r0
    +push r1
    jsr mirrorCircleSegment ;mirrorCircleSegment(bitmapPointer, center, circumfrancePoint);
    +pull r1
    +pull r0
    +pull rExtra
    jmp .loopHead
.loopEnd
    rts
}

rasterISR100:
lda #$01
sta $d019 ;acknowledge interrupt
inc vicBorderColorRegister
jsr sidFilePlaybackAddress ;jump to sid play address. Playing next note.
dec vicBorderColorRegister
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine


*=sidFileStartAddress
!bin "drdoom.sid",, $7c+2