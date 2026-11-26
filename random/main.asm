;Compilation flags
ressedAfter = 256 ;pulled random values
reseedSidEnable = 0
reseedJoystickEnable = 1

* = $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)
; --- BAS1IC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

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
    inc .addr
    bne .done
    inc .addr+1
.done:
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

;Conecptual constants
wordLength = 2  ; 2 bytes = 16 bits
dwordLength = 4 ; 4 bytes = 32 bits
qwordLength = 8 ; 8 bytes = 64 bits

;Vic Registers
vicMemoryPointersRegister = $d018  ; screen, charset and sprite expansion blocks
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021

;Vic Colors
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorCyan = 3
vicColorViolet = 4
vicColorGreen = 5
vicColorBlue = 6
vicColorYellow = 7
vicColorOrange = 8
vicColorBrown = 9
vicColorLightRed = 10
vicColorDarkGray = 11
vicColorMiddleGray = 12
vicColorLightGreen = 13
vicColorLightBlue = 14
vicColorLightGray = 15

;C64 Memory
screen = $0400  ; 4*256 = 1024
colorRam = $d800  ; d800-dbe7 = 1000 * 4 bit (lower byte only)

;Sid Registers
sidVoice3FrequencyRegisterLow = $d40e
sidVoice3FrequencyRegisterHigh = $d40f
sidVoice3DutyCycleRegisterLow = $d410
sidVoice3DutyCycleRegisterHigh = $d411
sidVoice3ControlRegister = $d412
sidVoice3ValueRegister = $d41b

;Sid Constants
sidVoiceMaxValue = $0fff
sidVoiceControlWaveformTriangleMask = 16
sidVoiceControlWaveformSawtoothMask = 32
sidVoiceControlWaveformPulseMask = 64
sidVoiceControlWaveformNoiseMask = 128

;CIA registers
ciaJoystick2register = $dc00

;Kernel Registers
kernelTextColorRegister = $0286

;Program constants
sidVoice3Frequency = 4096 ; = maxRngN | max seed
sidVoice3DutyCycle = $800 ; = 50%
vicCharsetBlock = 7

;Function parameter storage
rExtra = $02
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe
midSqState = $cfff
lfsrState = $cffe

*=$080d
;Setup sid voice 3 for random number generation (seeding)
+ldi16 sidVoice3FrequencyRegisterLow, sidVoice3Frequency ;Set frequency
+ldi16 sidVoice3DutyCycleRegisterLow, sidVoice3DutyCycle ;Set duty cycle
+poke sidVoice3ControlRegister, sidVoiceControlWaveformNoiseMask ;Set wave shape to noise

;Setup custom character set
lda vicMemoryPointersRegister
ora #2*vicCharsetBlock
sta vicMemoryPointersRegister

;Set colors
+poke vicBackgroundColorRegister, vicColorBlack
+poke vicBorderColorRegister, vicColorDarkGray
+poke kernelTextColorRegister, vicColorWhite

;Setup custom character set
lda vicMemoryPointersRegister
ora #14
sta vicMemoryPointersRegister

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

reseedSid:
  +mov midSqState, sidVoice3ValueRegister
  +mov lfsrState, midSqState
  jmp apploop
}

!if reseedJoystickEnable == 1 {
reseedJoystick:
  +mov midSqState, ciaJoystick2register
  +mov lfsrState, ciaJoystick2register
  jmp apploop
}

apploop:
;Init app logic
ldx #0; currentIteration
ldy #0

interrationLoop:
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
bne interrationLoop
!if reseedSidEnable == 1 {
  jmp reseedSid
} else if reseedJoystickEnable == 1 {
  jmp reseedJoystick
} else {
  jmp interrationLoop
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

*=vicCharsetBlock*2048
hexcharset:
!bin "hexcharset1.prg", 256*9,2