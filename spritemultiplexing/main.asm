*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Hardware constants
pageSize = 256
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorCyan = 3
vicColorPurple = 4
vicColorGreen = 5
vicColorBlue = 6
vicColorYellow = 7
vicColorBrown = 8
vicColorDarkBrown = 9
vicColorLightBrown = 10
vicColorDarkGray = 11
vicColorGray = 12
vicColorLightGreen = 13
vicColorLightBlue = 14
vicColorLightGray = 15
vicHardwareSpriteCount = 8
highresSpriteWidth = 24
highresSpriteHeight = 21
screenWidth = 320
screenHeight = 200
spriteStartOffsetX = 25
spriteStartOffsetY = 0
spriteScreenCoordinateOffsetX = 25
spriteScreenCoordinateOffsetY = 21
spriteSize = 64
sidVoiceControlWaveformTriangleMask = 16
sidVoiceControlWaveformSawtoothMask = 32
sidVoiceControlWaveformPulseMask = 64
sidVoiceControlWaveformNoiseMask = 128
sidVoiceMaxValue = $0fff
sidVoiceControlWaveformTriangleMask = 16
sidVoiceControlWaveformSawtoothMask = 32
sidVoiceControlWaveformPulseMask = 64
sidVoiceControlWaveformNoiseMask = 128
sidVoice3Frequency = 4096 ; = maxRngN | max seed
sidVoice3DutyCycle = $800 ; = 50%
registersPerSpritePosition = 2
petsciiBlank = 32

;sid Registers
sidVoice3FrequencyRegisterLow = $d40e
sidVoice3FrequencyRegisterHigh = $d40f
sidVoice3DutyCycleRegisterLow = $d410
sidVoice3DutyCycleRegisterHigh = $d411
sidVoice3ControlRegister = $d412
sidVoice3ValueRegister = $d41b

;Vic Registers
screen = $0400
vicSprite0bitmapBlockPointerRegister = $07f8
vicSprite1bitmapBlockPointerRegister = $07f9
vicSprite2bitmapBlockPointerRegister = $07fa
vicSprite3bitmapBlockPointerRegister = $07fb
vicSprite4bitmapBlockPointerRegister = $07fc
vicSprite5bitmapBlockPointerRegister = $07fd
vicSprite6bitmapBlockPointerRegister = $07fe
vicSprite7bitmapBlockPointerRegister = $07ff
vicMultiColorModeRegister = $d016
vicMemoryPointersRegister = $d018
vicAcknowlageInterruptRegister = $d019
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicBackgroundMulticolorPrimeryColorRegister = $d022
vicBackgroundMulticolorSecondaryColorRegister = $d023
vicSpriteMulticolorPrimeryColorRegister = $d025
vicSpriteMulticolorSecondaryColorRegister = $d026
vicControlRegister = $d01a
vicSpriteMultiColorRegister = $d01c
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite1positionXregister = $d002
vicSprite1positionYregister = $d003
vicSprite2positionXregister = $d004
vicSprite2positionYregister = $d005
vicSprite3positionXregister = $d006
vicSprite3positionYregister = $d007
vicSprite4positionXregister = $d008
vicSprite4positionYregister = $d009
vicSprite5positionXregister = $d00a
vicSprite5positionYregister = $d00b
vicSprite6positionXregister = $d00c
vicSprite6positionYregister = $d00d
vicSprite7positionXregister = $d00e
vicSprite7positionYregister = $d00f
vicSpriteEnableRegister = $d015
vicSprite0colorRegister = $d027
vicSprite1colorRegister = $d028
vicSprite2colorRegister = $d029
vicSprite3colorRegister = $d02a
vicSprite4colorRegister = $d02b
vicSprite5colorRegister = $d02c
vicSprite6colorRegister = $d02d
vicSprite7colorRegister = $d02e
vicSpritePositionsXhighbitRegister = $d010
vicRasterInterruptScanlineSelectRegister = $d012
vicInterruptControlRegister = $d011
vicSprite0colorRegister = $d027

;Color Ram
colorRam = $d800

;CIA registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d

;Kernel
kernelrqVector = $0314 ;$0314-0315
kernelTextColor = $0286
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81

;Program constants
backgroundCharsetStart=$3800
backgroundColorStart=backgroundCharsetStart+pageSize*8
backgroundScreenStart=backgroundColorStart+pageSize*8
fishCount = vicHardwareSpriteCount*2
lowerSpriteBitmapsStartingBlock = 128
higherSpriteBitmapsStartingBlock = lowerSpriteBitmapsStartingBlock + vicHardwareSpriteCount
lowerMirroredSpriteBitmapsStartingBlock = higherSpriteBitmapsStartingBlock + vicHardwareSpriteCount
higherMirroredSpriteBitmapsStartingBlock = lowerMirroredSpriteBitmapsStartingBlock + vicHardwareSpriteCount
lowToHighRasterline = 125
highToLowRasterline = 250
bitmapFlipDelta = lowerMirroredSpriteBitmapsStartingBlock - lowerSpriteBitmapsStartingBlock
lowerSpriteBitmapsStart = lowerSpriteBitmapsStartingBlock * spriteSize
higherSpriteBitmapsStart = higherSpriteBitmapsStartingBlock * spriteSize
lowerMirroredSpriteBitmapsStart = lowerMirroredSpriteBitmapsStartingBlock * spriteSize
higherMirroredSpriteBitmapsStart = higherMirroredSpriteBitmapsStartingBlock * spriteSize

;Program memory
rExtra = 2
rExtra2 = 250
r0 = 251
r1 = 252
r2 = 253
r3 = 254

!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
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

!macro phy {
    tya
    pha
}

!macro plx {
    pla
    tax
}

!macro ply {
    pla
    tay
}

!macro rev .src, .dest {
    lda #0
    sta .dest
    lda .src
    ldy #8
.bitloop
    asl
    ror .dest
    dey
    bne .bitloop
}

!macro revpairwise .src, .dest {
;pair 0-1 -> 6-7 : left shift 6
    lda .src
    and #$03
    asl
    asl
    asl
    asl
    asl
    asl
    sta .dest

;pair 2-3 -> 4-5 : left shift 2
    lda .src
    and #$0C
    asl
    asl
    ora .dest
    sta .dest

;pair 4-5 -> 2-3 : right shift 2
    lda .src
    and #$30
    lsr
    lsr
    ora .dest
    sta .dest

;pair 6-7 -> 0-1 : right shift 6
    lda .src
    and #$C0
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    ora .dest
    sta .dest
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro mov16 .dest, .src {
    +mov .dest, .src
    +mov .dest+1, .src+1
}

!macro and16 .acc, .op {
    lda .acc
    and .op
    sta .acc
    lda .acc+1
    and .op+1
    sta .acc+1
}

!macro eor16 .acc, .op {
    lda .acc
    eor .op
    sta .acc
    lda .acc+1
    eor .op+1
    sta .acc+1
}

!macro inc16 .addr {
    inc .addr
    bne .done
    inc .addr+1
.done
}

!macro msk16x .addr {
    +phx
    +ldi16 .addr, 1
    cpx #0
    beq .done
.loop
    asl .addr
    rol .addr+1
    dex
    bne .loop
.done
    +plx
}

!macro setSpriteStatus .spriteNr, .status {
    lda .status
    and #$10
    beq +
    lda vicSpriteMultiColorRegister
    ora #(1 << .spriteNr)
    sta vicSpriteMultiColorRegister
    jmp ++
+
    lda vicSpriteMultiColorRegister
    and #(1 << .spriteNr) XOR $ff
    sta vicSpriteMultiColorRegister
++
}

!macro mirrorHighresSprite .src, .dest {
    !for .currentRow, 0, highresSpriteHeight -1 {
        +rev .src+3*.currentRow, .dest+2+3*.currentRow
        +rev .src+1+3*.currentRow, .dest+1+3*.currentRow
        +rev .src+2+3*.currentRow, .dest+3*.currentRow
    }
}

!macro mirrorMultiColorSprite .src, .dest {
    +revpairwise .src, .dest+2
    +revpairwise .src+1, .dest+1
    +revpairwise .src+2, .dest
}

!macro changeDirection .direction {
    +phx
    +msk16x r0
    +eor16 .direction, r0
    +plx
}

*=$080d
;Setup sid voice 3 for random number generation (seeding)
    +ldi16 sidVoice3FrequencyRegisterLow, sidVoice3Frequency ;Set frequency
    +ldi16 sidVoice3DutyCycleRegisterLow, sidVoice3DutyCycle ;Set duty cycle
    +poke sidVoice3ControlRegister, sidVoiceControlWaveformNoiseMask ;Set wave shape to noise

;clear screen and setup color ram
    ldx #0

screenmemoryloop:
!for .currentPage, 0, 3 {
    lda backgroundColorStart+.currentPage*pageSize, x
    sta colorRam+.currentPage*pageSize, x
    lda backgroundScreenStart+.currentPage*pageSize, x
    sta screen+.currentPage*pageSize, x
}
    inx
    bne screenmemoryloop

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
    +poke vicRasterInterruptScanlineSelectRegister, highToLowRasterline

;set IRQ handler pointer to ISR
    +ldi16 kernelrqVector, rasterISRhigh

;enable raster interrupt
    lda vicControlRegister
    ora #$01 ;set raster interrupt enable bit to 1
    sta vicControlRegister
    cli ;reenable interrupts

;set sprite modes
    +poke vicSpriteMultiColorRegister, 0 ;disable multicolor mode for all sprites
    +poke vicSpriteEnableRegister, 255 ;enable sprites 1 and 2 though bits 0 and 1

;set sprite block pointers
!for .currentSprite, 0, vicHardwareSpriteCount-1 {
    +poke vicSprite0bitmapBlockPointerRegister+.currentSprite, lowerSpriteBitmapsStartingBlock+.currentSprite   
}

;setup individual fish
!for .currentFish, 0, fishCount -1 {
    +mov fishSpeeds+.currentFish, sidVoice3ValueRegister
    +ldi16 r0, lowerSpriteBitmapsStart+spriteSize*.currentFish
    +ldi16 r2, lowerMirroredSpriteBitmapsStart+spriteSize*.currentFish
    +mov lowerFishStatusBits+.currentFish, lowerSpriteBitmapsStart+spriteSize-1+spriteSize*.currentFish
    and #$10                             
    bne +
    jsr mirrorHighresSprite
    jmp ++
+
    jsr mirrorMultiColorSprite
++
}

;set sprite colors
    +poke vicSpriteMulticolorPrimeryColorRegister, vicColorCyan
    +poke vicSpriteMulticolorSecondaryColorRegister, vicColorWhite

;set background colors
    sta vicBackgroundMulticolorPrimeryColorRegister
    +poke vicBackgroundMulticolorSecondaryColorRegister, vicColorRed
    +poke vicBackgroundColorRegister, vicColorBlue
    +poke vicMultiColorModeRegister, $d8 ;Enable multicolor character mode
    +poke vicMemoryPointersRegister, %00011110

demoloop:
    ldx #0

fishMoveLoopHeader:
    cpx #fishCount
    bne checkFishSpeed
    jmp demoloop

checkFishSpeed:
    dec fishMovementCounters, x
    beq fishShouldMove
    jmp moveNextFish

fishShouldMove:
    lda fishSpeeds, x
    sta fishMovementCounters, x

!zone upDownMovement {
moveFishUpOrDown:
    txa
    and #1
    beq .sinejumppad
    jmp triangleUpDownMovement
.sinejumppad:
    jmp triangleUpDownMovement
}

!zone leftRightMovement {
shouldFishMoveLeftOrRight:
    +msk16x r0
    +and16 r0, fishDirectionsX
    lda r0
    ora r1
    beq moveFishLeft

moveFishRight:
    lda lowerFishPositionsX, x
    cmp #255
    beq bounceRight
    inc lowerFishPositionsX, x
    jmp moveNextFish

bounceRight:
    jsr changeHeading
    +changeDirection fishDirectionsX
    jmp moveNextFish

moveFishLeft:
    lda lowerFishPositionsX, x
    cmp #spriteScreenCoordinateOffsetX
    beq bounceLeft
    dec lowerFishPositionsX, x
    jmp moveNextFish

bounceLeft:
    jsr changeHeading
    +changeDirection fishDirectionsX
}

moveNextFish:
    inx
    jmp fishMoveLoopHeader

triangleUpDownMovement:
!zone triangleUpDownMovement {
    +msk16x r0
    +and16 r0, fishDirectionsY
    lda r0
    ora r1
    beq .moveFishDown
    jmp .moveFishUp
    
.moveFishDown:
    lda lowerFishPositionsY, x
    cmp fishBobDownLimits, x
    bcs .bounceUp
    inc lowerFishPositionsY, x
    jmp shouldFishMoveLeftOrRight

.bounceUp:
    +changeDirection fishDirectionsY
    jmp shouldFishMoveLeftOrRight

.moveFishUp:
    lda lowerFishPositionsY, x
    cmp fishBobUpLimits, x
    bcc .bounceDown
    dec lowerFishPositionsY, x
    jmp shouldFishMoveLeftOrRight

.bounceDown:
    +changeDirection fishDirectionsY
    jmp shouldFishMoveLeftOrRight
}

changeHeading:
!zone changeHeading {
    lda lowerFishBitmapBlockPointer, x
    cmp #lowerSpriteBitmapsStartingBlock + fishCount
    bcc .toMirrored

    ; currently mirrored -> go back to original
    sec
    sbc #bitmapFlipDelta
    jmp .store

.toMirrored:
    ; currently original -> go to mirrored
    clc
    adc #bitmapFlipDelta

.store:
    sta lowerFishBitmapBlockPointer, x
    rts
}

rasterISRhigh:
    sei
    inc vicAcknowlageInterruptRegister ;acknowlage interrupt
    +poke vicBorderColorRegister, vicColorYellow ;visualize screen division
    +push r2
    +push r3
!for .currentSprite, 0, vicHardwareSpriteCount-1 {
    +mov vicSprite0positionXregister+registersPerSpritePosition*.currentSprite, higherFishPositionsX+.currentSprite
    +mov vicSprite0positionYregister+registersPerSpritePosition*.currentSprite, higherFishPositionsY+.currentSprite
    +mov vicSprite0colorRegister+.currentSprite, higherFishStatusBits+.currentSprite
    +mov vicSprite0bitmapBlockPointerRegister+.currentSprite, higherFishBitmapBlockPointer+.currentSprite
    +setSpriteStatus .currentSprite, higherFishStatusBits+.currentSprite
    ;+poke vicSprite6colorRegister, vicColorYellow
}
    lda #$fe ;everything except the lowest bit high
    and vicSpritePositionsXhighbitRegister
    sta r3
    pha ;push r3 to the stack
    lda #1
    and higherSpritesPositionXhighBits
    ora r3
    sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 higher position x high bit
    pla
    sta r3 ;pull r3 from the stack
    lda #$7f ;everything except the highest bit high
    and vicInterruptControlRegister
    sta vicInterruptControlRegister
    +poke vicRasterInterruptScanlineSelectRegister, highToLowRasterline
    +ldi16 kernelrqVector, rasterISRlow
    +pull r3
    +pull r2
    cli
    jmp kernelRestoreRegistersAndReturnFromInterruptRoutine ;return from interrupt, restoring regs using kernel rotinue

rasterISRlow:
    sei
    inc vicAcknowlageInterruptRegister ;acknowlage interrupt
    +poke vicBorderColorRegister, vicColorLightBlue ;visualize screen division
    +push r2
    +push r3
!for .currentSprite, 0, vicHardwareSpriteCount-1 {
    +mov vicSprite0positionXregister+registersPerSpritePosition*.currentSprite, lowerFishPositionsX+.currentSprite
    +mov vicSprite0positionYregister+registersPerSpritePosition*.currentSprite, lowerFishPositionsY+.currentSprite
    +mov vicSprite0colorRegister+.currentSprite, lowerFishStatusBits+.currentSprite
    +mov vicSprite0bitmapBlockPointerRegister+.currentSprite, lowerFishBitmapBlockPointer+.currentSprite
    +setSpriteStatus .currentSprite, lowerFishStatusBits+.currentSprite
    ;+poke vicSprite6colorRegister, vicColorYellow
}
    lda r3
    and vicSpritePositionsXhighbitRegister
    sta r3
    pha ;push r3 to the stack
    lda #1
    and lowerSpritesPositionXhighBits
    ora r3
    sta vicSpritePositionsXhighbitRegister ;sprite 0 position x high bit = sprite 0 lower position x high bit
    pla
    sta r3 ;pull r3 from the stack
    lda #$7f ;everything except the highest bit high
    and vicInterruptControlRegister
    sta vicInterruptControlRegister
    +poke vicRasterInterruptScanlineSelectRegister, lowToHighRasterline
    +ldi16 kernelrqVector, rasterISRhigh
    +pull r3
    +pull r2
    cli
    jmp kernelRestoreRegistersAndReturnFromInterruptRoutine ;return from interrupt, restoring regs using kernel rotinue


; ------------------------------------------------------------
; revByte: reverse the 8 bits of one byte.
;   in : A = byte
;   out: A = reversed byte
;   clobbers: Y, rExtra
; ------------------------------------------------------------
revByte:
!zone revByte {
    ldy #8
    sta rExtra
    lda #0
.loop:
    asl rExtra
    ror
    dey
    bne .loop
    rts
}

; ------------------------------------------------------------
; revHighresRow: reverse one 3-byte high-res row.
;   in : r0/r1 = source address (3 bytes)
;        r2/r3 = destination address (3 bytes)
;   out: 3 reversed-and-swapped bytes at (r2),y
;        r0/r1 and r2/r3 advanced by 3
;   clobbers: A, Y
; ------------------------------------------------------------
revHighresRow:
    ldy #0
    lda (r0),y          ; src byte 0 -> dest byte 2
    jsr revByte
    ldy #2
    sta (r2),y

    ldy #1
    lda (r0),y          ; src byte 1 -> dest byte 1
    jsr revByte
    ldy #1
    sta (r2),y

    ldy #2
    lda (r0),y          ; src byte 2 -> dest byte 0
    jsr revByte
    ldy #0
    sta (r2),y

    ; advance both pointers by 3
    clc
    lda r0
    adc #3
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #3
    sta r2
    bcc +
    inc r3
+
    rts

; ------------------------------------------------------------
; revPairwiseByte: reverse the bit-pairs of one byte (multicolor).
;   in : A = byte
;   out: A = pairwise-reversed byte
;   clobbers: Y, r0, r1
; ------------------------------------------------------------

revPairwiseByte:
!zone revPairwiseByte {
    sta rExtra
    and #$03
    asl
    asl
    asl
    asl
    asl
    asl
    sta rExtra2

    lda rExtra
    and #$0c
    asl
    asl
    ora rExtra2
    sta rExtra2

    lda rExtra
    and #$30
    lsr
    lsr
    ora rExtra2
    sta rExtra2

    lda rExtra
    and #$c0
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    ora rExtra2      ; result stays in A
    rts
}

; ------------------------------------------------------------
; revMulticolorRow: reverse one 3-byte multicolor row.
;   in : r0/r1 = source address (3 bytes)
;        r2/r3 = destination address (3 bytes)
;   out: 3 pairwise-reversed-and-swapped bytes at (r2),y
;        r0/r1 and r2/r3 advanced by 3
;   clobbers: A, Y
; ------------------------------------------------------------
revMulticolorRow:
    ldy #0
    lda (r0),y
    jsr revPairwiseByte
    ldy #2
    sta (r2),y

    ldy #1
    lda (r0),y
    jsr revPairwiseByte
    ldy #1
    sta (r2),y

    ldy #2
    lda (r0),y
    jsr revPairwiseByte
    ldy #0
    sta (r2),y

    clc
    lda r0
    adc #3
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #3
    sta r2
    bcc +
    inc r3
+
    rts

mirrorHighresSprite:
!zone mirrorHighresSprite {
    ldx #highresSpriteHeight
.rowLoop
    ldy #0
    lda (r0),y
    jsr revByte
    ldy #2
    sta (r2),y

    ldy #1
    lda (r0),y
    jsr revByte
    ldy #1
    sta (r2),y

    ldy #2
    lda (r0),y 
    jsr revByte
    ldy #0
    sta (r2),y

    clc
    lda r0
    adc #3
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #3
    sta r2
    bcc +
    inc r3
+
    dex
    bne .rowLoop

    ldy #0
    lda (r0),y
    sta (r2),y

    clc
    lda r0
    adc #1
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #1
    sta r2
    bcc +
    inc r3
+
    rts
}

mirrorMultiColorSprite:
!zone mirrorMultiColorSprite {
    ldx #highresSpriteHeight
.rowLoop
    ldy #0
    lda (r0),y
    jsr revPairwiseByte
    ldy #2
    sta (r2),y

    ldy #1
    lda (r0),y
    jsr revPairwiseByte
    ldy #1
    sta (r2),y

    ldy #2
    lda (r0),y 
    jsr revPairwiseByte
    ldy #0
    sta (r2),y

    clc
    lda r0
    adc #3
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #3
    sta r2
    bcc +
    inc r3
+
    dex
    bne .rowLoop

    ldy #0
    lda (r0),y
    sta (r2),y

    clc
    lda r0
    adc #1
    sta r0
    bcc +
    inc r1
+
    clc
    lda r2
    adc #1
    sta r2
    bcc +
    inc r3
+
    rts
}

fishDirectionsX:
!fill fishCount, 0

fishDirectionsY:
!fill fishCount, 0

lowerFishPositionsX:
!for .currentSprite, 1, vicHardwareSpriteCount {
    !byte .currentSprite * 25
}

higherFishPositionsX:
!for .currentSprite, 1, vicHardwareSpriteCount {
    !byte .currentSprite * 25
}

lowerFishPositionsY:
!fill vicHardwareSpriteCount, 75

higherFishPositionsY:
!fill vicHardwareSpriteCount, 150

;128 = double height
;64 = double width
;32 = multicolor
;8-1 = color
lowerFishStatusBits:
!for .currentSprite, 1, vicHardwareSpriteCount {
    !byte .currentSprite
}

higherFishStatusBits:
!for .currentSprite, 1, vicHardwareSpriteCount {
    !byte .currentSprite
}

lowerFishBitmapBlockPointer:
!for .currentSprite, 0, vicHardwareSpriteCount -1 {
    !byte lowerSpriteBitmapsStartingBlock+.currentSprite
}

higherFishBitmapBlockPointer:
!for .currentSprite, 0, vicHardwareSpriteCount -1 {
    !byte higherSpriteBitmapsStartingBlock+.currentSprite
}

fishBobUpLimits:
!fill vicHardwareSpriteCount, 50
!fill vicHardwareSpriteCount, 140

fishBobDownLimits:
!fill vicHardwareSpriteCount, 90
!fill vicHardwareSpriteCount, 160

lowerSpritesPositionXhighBits:
!byte 0

higherSpritesPositionXhighBits:
!byte 0

fishSpeeds:
!fill fishCount, 128

fishMovementCounters:
!fill fishCount, 0

sinTable:
!word 0, 6, 12, 18, 25, 31, 37, 43, 49, 56, 62, 68, 74, 80, 86, 92
!word 97, 103, 109, 115, 120, 126, 131, 136, 142, 147, 152, 157, 162, 167, 171, 176
!word 181, 185, 189, 193, 197, 201, 205, 209, 212, 216, 219, 222, 225, 228, 231, 234
!word 236, 239, 241, 243, 245, 247, 248, 250, 251, 252, 253, 254, 255, 255, 255, 255
!word 255, 255, 255, 255, 254, 253, 252, 251, 250, 248, 247, 245, 243, 241, 239, 236
!word 234, 231, 228, 225, 222, 219, 216, 212, 209, 205, 201, 197, 193, 189, 185, 181
!word 176, 171, 167, 162, 157, 152, 147, 142, 136, 131, 126, 120, 115, 109, 103, 97
!word 92, 86, 80, 74, 68, 62, 56, 49, 43, 37, 31, 25, 18, 12, 6, 0
!word -6, -12, -18, -25, -31, -37, -43, -49, -56, -62, -68, -74, -80, -86, -92, -97
!word -103, -109, -115, -120, -126, -131, -136, -142, -147, -152, -157, -162, -167, -171, -176, -181
!word -185, -189, -193, -197, -201, -205, -209, -212, -216, -219, -222, -225, -228, -231, -234, -236
!word -239, -241, -243, -245, -247, -248, -250, -251, -252, -253, -254, -255, -255, -255, -255, -255
!word -255, -255, -255, -254, -253, -252, -251, -250, -248, -247, -245, -243, -241, -239, -236, -234
!word -231, -228, -225, -222, -219, -216, -212, -209, -205, -201, -197, -193, -189, -185, -181, -176
!word -171, -167, -162, -157, -152, -147, -142, -136, -131, -126, -120, -115, -109, -103, -97, -92
!word -86, -80, -74, -68, -62, -56, -49, -43, -37, -31, -25, -18, -12, -6, 0

*=lowerSpriteBitmapsStart
lowerSpriteBitmaps:
!src "dragonbirdssprites.asm"

*=higherSpriteBitmapsStart
higherSpriteBitmaps:
!src "aisprites.asm"

*=lowerMirroredSpriteBitmapsStart
lowerMirroredSpriteBitmaps:

*=higherMirroredSpriteBitmapsStart
higherMirroredSpriteBitmaps:

*=backgroundCharsetStart
!src "backgroundcharset.asm"

*=backgroundColorStart
!src "backgroundcolors.asm"

*=backgroundScreenStart
!src "backgroundscreen.asm"6