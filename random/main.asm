;Compilation flags
reseedEnable = 1
mtEnable = 0

*=$0801           ; Standard BASIC start memory for C64 ($0801 is 2049)
; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Conecptual constants
wordLength = 2 ; 2 bytes = 16 bits
dwordLength = 4 ; 4 bytes = 32 bits
qwordLength = 8 ; 8 bytes = 64 bits

;Macros
!macro poke .addr, .value {
  lda #.value
  sta .addr
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro mov .destination, .source {
  lda .source
  sta .destination
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

!macro swp {
  asl 
  adc #$80
  rol 
  asl 
  adc #$80
  rol 
}

!macro mov16 .destination, .source {
  +mov .destination, .source
  +mov .destination+1, .source+1
}

!macro mov32 .destination, .source {
  +mov .destination, .source
  +mov .destination+1, .source+1
  +mov .destination+2, .source+2
  +mov .destination+3, .source+3
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

!macro add16i .accumulator, .immediate {
  clc
  lda .accumulator
  adc #<.immediate
  sta .accumulator
  lda .accumulator+1
  adc #>.immediate
  sta .accumulator+1
}

!macro sub16i .accumulator, .immediate {
  sec
  lda .accumulator
  sbc #<.immediate
  sta .accumulator
  lda .accumulator+1
  sbc #>.immediate
  sta .accumulator
}

!macro add32 .accumulator, .accumulative {
  clc
  !for .currentByte, 0, dwordLength {
    lda .accumulator+.currentByte
    adc .accumulative+.currentByte
    sta .accumulator+.currentByte
  }
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

!macro mul161632 .factor1addr, .factor2addr, .result {
  lda #0
  !for .currentByte, 0, dwordLength {
    sta .result+.currentByte
  }
  ldx #16
.loop:
  lsr .factor1addr+1
  ror .factor1addr
  bcc .noAdd
  +add16 .result+2, .factor2addr
.noAdd:
  clc
  ror .result+3
  ror .result+2
  ror .result+1
  ror .result
  dex
  bne .loop
}

!macro mul323264 .factor1addr, .factor2addr, .result {
  lda #0
  !for .currentByte, 0, qwordLength {
    sta .result+.currentByte
  }
  ldx #32
.loop:
  lsr .factor1addr+3
  ror .factor1addr+2
  ror .factor1addr+1
  ror .factor1addr
  bcc .noAdd
  +add32 .result+4, .factor2addr
.noAdd
  clc
  ror .result+7
  ror .result+6
  ror .result+5
  ror .result+4
  ror .result+3
  ror .result+2
  ror .result+1
  ror .result
  dex
  bne .loop
}

;Is bit in accumulator set? If yes then store 1 into the accumulator else keep zero left from the and operation.
;Apply this macro to two values to align two misaligned bits in the accumulator, so they can be used in further logic operations with each other. 
!macro tst .bit { 
  and #1<<.bit
  beq .zero
  lda #1
.zero
}

!macro inc16 .addr {
  clc
  lda .addr
  adc #1
  sta .addr
  lda .addr+1
  adc #0
  sta .addr+1
}

!macro dec16 .addr {
  sec
  lda .addr
  sbc #1
  sta .addr
  lda .addr+1
  sbc #0
  sta .addr+1
}

!macro nextdword16 .addr { ;Increment a 16 bit counter by a dword (+4)
  +add16i .addr, dwordLength
}

!macro previousdword16 .addr { ;Decrement a 16 bit counter by a dword (-4)
  +sub16i .addr, dwordLength
}

!macro lsr32 .addr, .count {
  !for .currentShift, 0, .count {
    lsr .addr+3
    ror .addr+2
    ror .addr+1
    ror .addr+0
  }
}

!macro lsl32 .addr, .count {
  !for .currentShift, 0, .count {
    asl .addr+0
    rol .addr+1
    rol .addr+2
    rol .addr+3
  }
}

!macro and32 .accumulator, .operant {
  !for .currentByte, 0, dwordLength {
    lda .accumulator+.currentByte
    and .operant+.currentByte
    sta .accumulator+.currentByte
  }
}

!macro xor32 .accumulator, .operant {
  !for .currentByte, 0, dwordLength {
    lda .accumulator+.currentByte
    eor .operant+.currentByte
    sta .accumulator+.currentByte
  }
}

!macro discardHighDword .addr {
  !for .currentByte, 0, dwordLength {
    lda .addr+.currentByte
    and #$ff
    sta .addr+.currentByte
  }
  !for .currentByte, dwordLength, qwordLength {
    lda .addr+.currentByte
    and #0
    sta .addr+currentByte
  }
}

;Hardware registers
sidVoice3FrequencyRegisterLow = $d40e
sidVoice3FrequencyRegisterHigh = $d40f
sidVoice3DutyCycleRegisterLow = $d410
sidVoice3DutyCycleRegisterHigh = $d411
sidVoice3ControlRegister = $d412
sidVoice3ValueRegister = $d41b
screenAndChargenMemoryPointersRegister = $d018
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
screen = $0400
colorRam = $d800

;Hardware constants
sidVoiceMaxValue = $0fff
sidVoiceControlWaveformTriangleMask = 16
sidVoiceControlWaveformSawtoothMask = 32
sidVoiceControlWaveformPulseMask = 64
sidVoiceControlWaveformNoiseMask = 128
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorTihle = 3
vicColorPink = 4
vicColorGreen = 5
vicColorBlue = 6
vicColorYellow = 7
vicColorBrown = 8
vicColorDarkBrown = 9
vicColorOrange = 10
vicColorDarkGray = 11
vicColorGray = 12
vicColorLightGreen = 13
vicColorLightPurple = 14
vicColorLightGray = 15

;Kernel registers
kernelTextColorRegister = $286

;Program constants
sidVoice3Frequency = 4096 ; = maxRngN | max seed
sidVoice3DutyCycle = $800 ; = 50%
vicCharsetBlock = 7

;Function constants
MtStateVectorElementCount = 624
MtStateVectorM = 397

;Function parameter storage
rExtra = $02
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe
r4 = $c0f0
r5 = $c0f1
r6 = $c0f2
r7 = $c0f3
r8 = $c0f4
r9 = $c0f5
r10 = $c0f6
r11 = $c0f7
r12 = $c0f8
r13 = $c0f9
r14 = $c0e0
r15 = $c0e1
r16 = $c0e2
r17 = $c0e3
r18 = $c0e4
r19 = $c0e5
r20 = $c0e6
r21 = $c0e7
midSqState = $cfff
lfsrState = $cffe
mTwisterState= $c0fa ;($c0fa-$c0fd)

;Mt19937 is meant to be implemented with all values being at least 32 bits long and all counters being at least 16 bit long.
;Because of this 
tagMtRandStateMt = $c000 ;(32bit / 4 byte) * MtStateVectorElementCount long
tagMtRandStateIndex = tagMtRandStateMt+MtStateVectorElementCount * dwordLength ;(16bit / 2 bytes) long index to iterate over (32 bit / 4 byte) values

*=$080d
;Setup sid voice 3 for random number generation (seeding)
+ldi16 sidVoice3FrequencyRegisterLow, sidVoice3Frequency ;Set frequency
+ldi16 sidVoice3DutyCycleRegisterLow, sidVoice3DutyCycle ;Set duty cycle
+poke sidVoice3ControlRegister, sidVoiceControlWaveformNoiseMask ;Set wave shape to noise

;Setup custom character set
lda screenAndChargenMemoryPointersRegister
ora #2*vicCharsetBlock
sta screenAndChargenMemoryPointersRegister

;Set colors
+poke vicBackgroundColorRegister, vicColorBlack
+poke vicBorderColorRegister, vicColorDarkGray
+poke kernelTextColorRegister, vicColorWhite

;Setup custom character set
lda screenAndChargenMemoryPointersRegister
ora #14
sta screenAndChargenMemoryPointersRegister

;Clear screen
!zone clearscreen {
  lda vicBackgroundColorRegister
  ldx #0
.loop:
  sta colorRam,x
  sta colorRam+256, x
  sta colorRam+512, x
  sta colorRam+768, x
  inx
  bne .loop
}

reseed:
;Init random middle square algorithm
+mov midSqState, sidVoice3ValueRegister

;Init linear feedback shift register
+mov lfsrState, midSqState

!if mtEnable = 1 {
;Init mt19937
  lda midSqState
  !for .currentByte, 0, dwordLength {
    sta tagMtRandStateMt+.currentByte
  }
  ;+discardHighDword tagMtRandStateMt ;Optional?
  +ldi16 tagMtRandStateIndex, 1*dwordLength
mtInitForLoopHead: ;for(rand->index=1; rand->index<STATE_VECTOR_LENGTH; rand->index++)
  lda tagMtRandStateIndex+1
  cmp #>(MtStateVectorElementCount * dwordLength)
  bne mtInitForLoopBody
  lda tagMtRandStateIndex
  cmp #<(MtStateVectorElementCount * dwordLength)
  bne mtInitForLoopBody
  jmp mtInitForLoopEnd
  mtInitForLoopBody:
  +ldi16 r0, tagMtRandStateMt ;r0 = &rand->mt
  +previousdword16 tagMtRandStateIndex ;index = index-1
  +add16 r0, tagMtRandStateIndex ;r0 =  &rand->mt[rand->index-1]
  ldy #0
  lda (r0), y
  sta r4
  iny 
  lda (r0), y 
  sta r5
  iny
  lda (r0), y
  sta r6
  iny
  lda (r0), y
  sta r7
  +mov16 r2, tagMtRandStateMt
  +add16 r2, tagMtRandStateIndex
  +mul323264 r4, magicRandomInitialFactorWord, r14 ;r14:21 = (6069 * rand->mt[rand->index-1])
  iny
  lda r14 
  sta (r0), y
  iny
  lda r15
  sta (r0), y
  iny
  lda r16
  sta (r0), y
  iny
  lda r17
  sta (r0), y
  iny
  lda r18
  sta (r0), y
  iny
  lda r19
  sta (r0), y
  iny
  lda r20
  sta (r0), y
  iny
  lda r21
  sta (r0), y ;rand->mt[rand->index] = (6069 * rand->mt[rand->index-1])
mtInitForLoopFooter:
  +add16i tagMtRandStateIndex, 2 ; (index = index-1+2)=(index = index +1)=index++
  jmp mtInitForLoopHead
mtInitForLoopEnd:
}

;Init app logic
ldx #0; currentIteration
ldy #0

apploop:
;Display sid voice
lda sidVoice3ValueRegister
sta screen, x
lda kernelTextColorRegister
sta colorRam, x

;Call and display random middle square
jsr randomMidSquare
lda midSqState
sta screen+256, x
lda kernelTextColorRegister
clc
adc #16/4
sta colorRam+256, x

;Call and display random linear feedback shift register
jsr randomLfsr
lda lfsrState
sta screen+512, x
lda kernelTextColorRegister
clc
adc #2*16/4
sta colorRam+512, x

;Next Round
inx
bne apploop
!if reseedEnable == 0 {
  jmp apploop
} else {
  jmp reseed
}

randomMidSquare: ;Compute a number of n bits length by taking n bits from the middle of the bit sequence created by (f(n)-1)^2
php
+phx
+mov r2, midSqState
+mov rExtra, midSqState
+mul8816 rExtra, r2, r0, r1 ;Multiply the result of the previous iteration with itself
lda r0
and #$f0 ;Take the high nibble of the low byte of the multiplication result
+swp ;Swap the results in the high nibble with the zeros in the low nibble
sta midSqState ;Let the high nibble of the low byte of the multiplication result be the low nibble of the iteration result
lda r1
and #$0f ;Take the low nibble of the high byte of the multiplication result
+swp ;Swap the results in the low nibble with the zeros in the high nibble
ora midSqState ;Let the low nibble of the high byte of the multiplication result be the high nibble of the iteration result
sta midSqState ;Store the result of this iteration for the next iteration
+plx
plp
rts

randomLfsr: ;Simulates a shift register with bit 6 and 7 connected to the inputs of a xor gate and the output of the gate connected to the input of the shift register
php
lda lfsrState ;Take the value of the previous stage
+tst 7 ;If bit 7 of the previous stage is 1 then load 1 into the accumulator. The equivalent of wiring bit 7 of the lsfr to the first input of the xor gate
sta r0
lda lfsrState
+tst 6 ;Perform the same test as above, The equivalent of wiring bit 6 of the lsfr to the second input of the xor gate
eor r0 ;Perform the xor operation
asl lfsrState ;Logically shift the shift register left. Logical shift leaves a zero in the rightmost bit. 
ora lfsrState ;Replace that zero with the result of the xor operation. The equivalent of wiring the output of the xor gate to the input of the lsfr
sta lfsrState ;Store the result of this interration for the next iteration.
plp
rts

randomMT19937
!if mtEnable = 1 {
  php
  lda tagMtRandStateIndex+1
  cmp #>MtStateVectorElementCount
  bne jumppad
  lda tagMtRandStateIndex
  cmp #<MtStateVectorElementCount
  bne jumppad
  jmp twist
jumppad:
  jmp temper

twist:
  +ldi16 r0, tagMtRandStateMt ;r0:r1 is now a 16 bit version of [kk]
  +ldi16 r2, MtStateVectorM*dwordLength+tagMtRandStateMt ;r2:r3 is now a 16 bit version of [kk+STATE_VECTOR_M]
mtTwistFirstForLoopHead: ; if kk<STATE_VECTOR_LENGTH-STATE_VECTOR_M then goto mtTwistFirstForLoopBody else goto mtTwistFirstForLoopEnd
  lda r1
  cmp #>tagMtRandStateMt + (MtStateVectorElementCount - MtStateVectorM) * dwordLength
  bne mtTwistFirstForLoopBody
  lda r0
  cmp #<tagMtRandStateMt + (MtStateVectorElementCount - MtStateVectorM) * dwordLength
  bne mtTwistFirstForLoopBody
  jmp mtTwistFirstForLoopEnd
mtTwistFirstForLoopBody:
  jsr twistElement
mtTwistFirstForLoopFooter:
  ;kk++
  +nextdword16 r0
  +nextdword16 r2
  jmp mtTwistFirstForLoopHead
  mtTwistFirstForLoopEnd:
  +ldi16 r2, tagMtRandStateMt ;r2:r3 is now a 16 bit version of [kk+(STATE_VECTOR_M-STATE_VECTOR_LENGTH)]
  mtTwistSecondForLoopHead: ;if [kk<STATE_VECTOR_LENGTH-1] then goto mtTwistSecondForLoopBody else goto mtTwistSecondForLoopEnd
  lda r1
  cmp #>tagMtRandStateMt + (MtStateVectorElementCount-1) * dwordLength
  bne mtTwistSecondForLoopBody
  lda r0
  cmp #<tagMtRandStateMt + (MtStateVectorElementCount-1) * dwordLength
  bne mtTwistSecondForLoopBody
  jmp mtTwistSecondForLoopFooter
  mtTwistSecondForLoopBody:
  jsr twistElement
mtTwistSecondForLoopFooter:
  ;kk++
  +nextdword16 r0
  +nextdword16 r2
  jmp mtTwistSecondForLoopHead
mtTwistSecondForLoopEnd:
  +ldi16 r2, tagMtRandStateMt + (MtStateVectorM -1) * dwordLength ;r0:r1 is now [STATE_VECTOR_LENGTH-1]
  ldy #0
  lda (r0), y
  and upperMask
  sta mTwisterState
  iny
  lda (r0), y
  and upperMask+1
  sta mTwisterState+1
  iny
  lda (r0), y
  and upperMask+2
  sta mTwisterState+2
  iny
  lda (r0), y
  and upperMask+3
  sta mTwisterState+3 ;y = (rand->mt[STATE_VECTOR_LENGTH-1] & UPPER_MASK)
  +ldi16 r0, tagMtRandStateMt
  ldy #0
  lda (r0), y 
  and lowerMask
  ora mTwisterState
  sta mTwisterState
  iny
  lda (r0), y
  and lowerMask+1
  ora mTwisterState+1
  sta mTwisterState+1
  iny
  lda (r0), y
  and lowerMask+2
  ora mTwisterState+2
  sta mTwisterState+2
  iny
  lda (r0), y
  and lowerMask+3
  ora mTwisterState+3
  sta mTwisterState+3 ;y = (rand->mt[STATE_VECTOR_LENGTH-1] & UPPER_MASK) | (rand->mt[0] & LOWER_MASK);
  +mov32 r10, mTwisterState ;r10 = y
  +lsr32 r10, 1 ; r10 = (y >> 1)
  lda mTwisterState
  and #1
  beq mtTwistLastSkipMag ;if mag[y & 0x01]=0 then r10 xor 0 = r10 
  +xor32 r10, magicRandomIterationFactorWord ;else r10=(y >> 1) xor mag[y & 0x1]
mtTwistLastSkipMag: ;Here r10 is (y >> 1) ^ mag[y & 0x1
  ldy #0
  lda (r2), y
  eor r10
  sta (r0), y
  iny
  lda (r2), y
  eor r11
  sta (r0), y
  iny
  lda (r2), y
  eor r12
  sta (r0), y
  iny
  lda (r2), y
  eor r13
  sta (r0), y ;rand->mt[STATE_VECTOR_LENGTH-1] = rand->mt[STATE_VECTOR_M-1] ^ (y >> 1) ^ mag[y & 0x1];
  +ldi16 tagMtRandStateIndex, 0

temper:
  +ldi16 r0, tagMtRandStateMt
  +add16 r0, tagMtRandStateIndex
  +nextdword16 tagMtRandStateIndex
  ldy #0
  lda (r0), y
  sta mTwisterState
  iny
  lda (r0), y
  sta mTwisterState+1
  iny
  lda (r0), y
  sta mTwisterState+2
  iny
  lda (r0), y
  sta mTwisterState+3 ;y = rand->mt[rand->index++];
  +mov32 r6, mTwisterState
  +lsr32 r6, 11
  +xor32 r6, mTwisterState
  +mov32 mTwisterState, r6
  +lsl32  r6, 7
  +and32 r6, temperingMaskB
  +xor32 r6, mTwisterState
  +mov32 mTwisterState, r6
  +lsl32 r6, 15
  +and32 r6, temperingMaskC
  +xor32 r6, mTwisterState
  +mov32 mTwisterState, r6
  +lsr32 mTwisterState, 18
  plp
  rts

twistElement:
  ldy #0
  lda (r0), y
  and upperMask
  sta mTwisterState
  iny
  lda (r0), y
  and upperMask+1
  sta mTwisterState+1
  iny
  lda (r0), y 
  and upperMask+2
  sta mTwisterState+2
  iny
  lda (r0), y
  and upperMask+3
  sta mTwisterState+3
  iny
  lda (r0), y
  and lowerMask
  ora mTwisterState
  sta mTwisterState
  iny
  lda (r0), y
  and lowerMask+1
  ora mTwisterState+1
  sta mTwisterState+1
  iny
  lda (r0), y
  and lowerMask+2
  ora mTwisterState+2
  sta mTwisterState+2
  iny
  lda (r0), y
  and lowerMask+3
  ora mTwisterState+3
  sta mTwisterState+3 ; y = (rand->mt[kk] & UPPER_MASK) | (rand->mt[kk+1] & LOWER_MASK);
  +mov32 r10, mTwisterState; r10 = y
  +lsr32 r10, 1 ; r10 = (y >> 1)
  lda mTwisterState
  and #1
  beq mtTwistForLoopSkipMag ; if mag[y & 0x01]=0 then r10 xor 0 = r10 
  +xor32 r10, magicRandomIterationFactorWord ; else r10=(y >> 1) xor mag[y & 0x1]
mtTwistForLoopSkipMag:
  ldy #0
  lda (r2), y
  eor r10
  sta (r0), y
  iny
  lda (r2), y
  eor r11
  sta (r0), y
  iny
  lda (r2), y
  eor r12
  sta (r0), y
  iny
  lda (r2), y
  eor r13
  sta (r0), y; rand->mt[kk] = rand->mt[r2:r3] ^ (y >> 1) ^ mag[y & 0x1];
  rts
}
upperMask: !32 $80000000
lowerMask: !32 $7fffffff
temperingMaskB: !32 $329d2c5680
temperingMaskC: !32 $efc60000
fullMask !32 $ffffffff
stateVectorLengthWord: !16 MtStateVectorElementCount
stateVectorMword: !16 MtStateVectorM
magicRandomInitialFactorWord: !32 6069
magicRandomIterationFactorWord: !32 $9908b0df

*=vicCharsetBlock*2048
hexcharset:
!bin "hexcharset1.prg", 256*9,2