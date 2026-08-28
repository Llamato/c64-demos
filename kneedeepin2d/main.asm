;Vic Registers
vicBorderColorRegister = $d020
vicControlRegister = $d01a
vicSpritesPositionXhighRegister = $d010
vicInterruptControlRegister = $d011
vicRasterInterruptScanlineSelectRegister = $d012
vicSpriteEnableRegister = $d015
vicSpriteDoubleHeightRegister = $d017
vicSpriteDoubleWidthRegister = $d01d
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
r8 = $c006
r9 = $c007
r10 = $c008
r11 = $c009
r12 = $c00a
r13 = $c00b
backBufferPointer = $cffe ;cffe:cfff

;Visualisation constants
sprite0block = 128
sprite1block = 129
sprite2block = 130
sprite3block = 131
backbufferBlock = 132
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

!macro phx {
    txa
    pha
}

!macro plx {
    pla
    tax
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

!macro add16i .accumulator, .accumulative {
    lda .accumulator
    clc
    adc #<.accumulative
    sta .accumulator
    lda .accumulator+1
    adc #>.accumulative
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

!macro eor16i .addr, .mask {
    lda .addr
    eor #<.mask
    sta .addr
    lda .addr+1
    eor #>.mask
    sta .addr+1
}

!macro flipSign {
    eor #$ff
    clc
    adc #1
}

!macro abs {
    bpl .done
    +flipSign
.done
}

!macro abs16 .x {
    lda .x+1
    bpl .done
    +eor16i .x, $ff
    +add16i .x, 1
.done
}

;visualisation starts here
;enable sprites
+poke vicSpriteEnableRegister, $0f

;set sprite pointers
+poke vicSprite0bitmapBlockPointerRegister, sprite0block
+poke vicSprite1bitmapBlockPointerRegister, sprite1block
+poke vicSprite2bitmapBlockPointerRegister, sprite2block
+poke vicSprite3bitmapBlockPointerRegister, sprite3block

;set sprite dimensions
+poke vicSpriteDoubleHeightRegister, $0f
+poke vicSpriteDoubleWidthRegister, $0f

;position sprites
+setSpritePositionX 0, 50
+setSpritePositionY 0, 100
+setSpritePositionX 1, 100
+setSpritePositionY 1, 100
+setSpritePositionX 2, 150
+setSpritePositionY 2, 100
+setSpritePositionX 3, 200
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

;draw Circles
;0
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke r13, spriteRows / 2
+ldi16 r2, sprite0block * spriteStride
jsr makeCircleSpriteBresenham
;1
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke r13, spriteRows / 2
+ldi16 r2, sprite1block * spriteStride
jsr makeCircleSpriteBresenham
;2
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke r13, spriteRows / 2
+ldi16 r2, sprite2block * spriteStride
jsr makeCircleSpriteBresenham
;3
+poke r0, spriteColumns / 2
+poke r1, spriteRows / 2
+poke r13, spriteRows / 2
+ldi16 r2, sprite3block * spriteStride
jsr makeCircleSpriteBresenham

+poke r12, 0 ;r12 = line destination.x
+ldi16 backBufferPointer, backbufferBlock * spriteStride

visloop:
!zone visloop {
;draw circle to backbuffer
    +poke r0, spriteColumns / 2
    +poke r1, spriteRows / 2
    +poke r13, spriteRows / 2
    +mov16 r2, backBufferPointer
    jsr makeCircleSpriteBresenham
;draw line backbuffer
    +poke r0, spriteColumns / 2
    +poke r1, spriteRows -1
    +mov16 r2, backBufferPointer
    ldx r12
    lda circleOffsetX, x
    clc
    adc #(spriteColumns / 2)
    sta r4 ;destination.x = (spriteColumns / 2) + circleOffsetX
    lda circleOffsetY, x
    clc
    adc #(spriteRows / 2)
    sta r5 ;destination.y = (spriteRows / 2) + circleOffsetY
    inc r12
    lda r12
    cmp #spriteColumns
    bne .skipWarpAround
    +poke r12, 0
.skipWarpAround
    jsr makeLineSpriteBresenham
;Swap back and front Buffers
    lda #sprite0block
    cmp vicSprite0bitmapBlockPointerRegister
    bne .backbufferToFront
.frontBufferToBack
    +fmb sprite0block * spriteStride, spriteLength, $00
    +ldi16 backBufferPointer, sprite0block * spriteStride
    +poke vicSprite0bitmapBlockPointerRegister, backbufferBlock
    jmp visloop
.backbufferToFront
    +fmb backbufferBlock * spriteStride, spriteLength, $00
    +ldi16 backBufferPointer, backbufferBlock * spriteStride
    +poke vicSprite0bitmapBlockPointerRegister, sprite0block
    jmp visloop
}

;r0 = position.x
;r1 = position.y
spritePixelPositionToBitmapPosition:
+poke r13, spriteBytesPerRow*bitsPerByte
+mul8816 r13, r1, r2, r3 ;r2:r3 = position.y * SPRITE_BYTES_PER_ROW * BITS_PER_BYTE
+add168 r2, r0 ;r2:r3 = bitPosition = position.y * SPRITE_BYTES_PER_ROW * BITS_PER_BYTE + position.x
+poke r13, bitsPerByte ;r13 = bitsPerByte = 8
+mov16 r0, r2
+div168 r0, r13, r2 ;r0:r1 = bitPosition / bitsPerByte = byte, r2 = bitPosition % bitsPerByte = bit
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
    sta r13 ;r13=A=(1<<((bitsPerByte - 1) - bitmapPosition.bit)), Y=0
    +pull r3
    +pull r2
    ldy r0 ;Y=bitmapPosition.byte
    lda r13 ;A=(1<<((bitsPerByte - 1) - bitmapPosition.bit)), Y=bitmapPosition.byte
    ora (r2), y ;A=spriteBaseAddress[Y] | (1<<((bitsPerByte - 1) - bitmapPosition.bit))
    sta (r2), y ;spriteBaseAddress[Y] = spriteBaseAddress[Y] | (1<<((bitsPerByte - 1) - bitmapPosition.bit))
    rts
}

;r0 = origin.x
;r1 = origin.y
;r2:r3 = spriteBaseAddress
;r4 = destination.x
;r5 = destination.y
makeLineSpriteBresenham:
!zone makeLineSpriteBresenham {
    lda r4
    sec
    sbc r0
    +abs
    sta r6 ;r6 = dx = abs(destination.x - origin.x)
    lda r5
    sec
    sbc r1
    +abs
    sta r7 ;r7 = dy = abs(destination.y - origin.y)
    +poke r8, 1 ;r8 = sx = 1
    lda r0
    cmp r4
    bcc .skipInvSx
    lda r8
    sec
    sbc #2
    sta r8 ;r8 = sx = -1
.skipInvSx
    +poke r9, 1 ;r9 = sy = 1
    lda r1
    cmp r5
    bcc .skipInvSy
    lda r9
    sec
    sbc #2
    sta r9 ;r9 = sy = -1
.skipInvSy
    lda r6
    sec
    sbc r7
    sta r10 ; r10 = err = dx - dy
.drawLoop
    lda r0
    bmi .skipSetPixel
    cmp #spriteColumns
    bcs .skipSetPixel
    lda r1
    bmi .skipSetPixel
    cmp #spriteRows
    bcs .skipSetPixel
    +push r0
    +push r1
    jsr setSpritePixel ;setSpritePixel(bitmapPointer, (struct Vector2uis) {x, y});
    +pull r1
    +pull r0
.skipSetPixel
    lda r0
    cmp r4
    bne .dontBreak ;if(x != destination.x) then goto dontBreak
    lda r1
    cmp r5
    bne .dontBreak ;if(y != destination.y) then goto dontBreak
    rts ;if (x == destination.x && y == destination.y) break;
.dontBreak
    lda r10
    asl
.checkForXerror
    sta r11 ;r11 = e2
    lda r7
    +flipSign ;A = -dy
    cmp r11
    bpl .checkForYerror ;if(-dy >= e2) then goto noXerror with (-dy >= e2) equivalent to (!(e2 > -dy))
    lda r10
    sec
    sbc r7
    sta r10 ;err = err - dy
    lda r0
    clc
    adc r8
    sta r0 ;x = x + sx
.checkForYerror
    lda r11
    cmp r6
    bpl .noYerror
    lda r10
    clc
    adc r6
    sta r10 ;err = err + dx
    lda r1
    clc
    adc r9
    sta r1 ;y = y + sy
.noYerror
    jmp .drawLoop
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
;r13 = radius
makeCircleSpriteBresenham:
!zone makeCircleSpriteBresenham {
    +poke r4, 0
    +mov r5, r13 ;r4:r5 = circumfrancePoint = {0, r}
    asl r13
    lda #3
    sec
    sbc r13
    sta r13 ;r13 = d = 3 - (2 * r)
    +push r13
    +push r0
    +push r1
    jsr mirrorCircleSegment ;mirrorCircleSegment(bitmapPointer, center, circumfrancePoint);
    +pull r1
    +pull r0
    +pull r13
.loopHead ;while(circumfrancePoint.x < circumfrancePoint.y)
    lda r4
    cmp r5
    bcs .loopEnd
    lda r13
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
    adc r13 ;A=d + 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
    sta r13 ;r13 = A = d + 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
    jmp .loopFooter
.dNegative
    lda r4 ;A=circumfrancePoint.x
    asl ;A=2 * circumfrancePoint.x
    asl ;A=4 * circumfrancePoint.x
    clc
    adc #6 ;A=4 * circumfrancePoint.x + 6
    adc r13 ;A=d + 4 * circumfrancePoint.x + 6
    sta r13 ;r13 = A = d + 4 * circumfrancePoint.x + 6
.loopFooter
    inc r4 ;circumfrancePoint.x++;
    +push r13
    +push r0
    +push r1
    jsr mirrorCircleSegment ;mirrorCircleSegment(bitmapPointer, center, circumfrancePoint);
    +pull r1
    +pull r0
    +pull r13
    jmp .loopHead
.loopEnd
    rts
}

;lookup tables are derived from
;circleX = r * cos(a)
;circleY = r * sin(a)
;as follows:
;We have 24 possible x values from the width of the sprite.
;We want to cover an arch from 330° to 210° for a analog meter look.
;Therefor each step in the circle function needs to be (330° - 210°) / (24 -1) = 120° / (24-1) = 5.217° in arc size.
;With that it holds that for k in range 0 to 23: alpha(k) = 210° + 5.217° * k
circleOffsetX: ;r * cos(alpha(k))
!byte -9,-8,-8,-7,-6,-6,-5,-4,-3,-2,-1,0,0,1,2,3,4,5,6,6,7,8,8,9
circleOffsetY: ;r * sin(alpha(k))
!byte -5,-6,-6,-7,-8,-8,-9,-9,-9,-10,-10,-10,-10,-10,-10,-9,-9,-9,-8,-8,-7,-6,-6,-5

*=sidFileStartAddress: