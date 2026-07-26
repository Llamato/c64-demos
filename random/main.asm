*=$0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
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

!macro pushregs {
  php
  pha
  +phx
  +phy
}

!macro pullregs {
  +ply
  +plx
  pla
  plp
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
    +mov .destination, source
    +mov .destination+1, source+1
}

!macro add16 .accumulator, .accumulative {
    lda accumulator
    clc
    adc accumulative
    sta accumulator
    lda accumulator+1
    adc accumulative+1
    sta accumulator+1
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
  +ldi16 result, 0
  +ldi16 result+2, 0
  ldx #16
.loop:
  lsr .factor1addr+1
  ror .factor1addr
  bcc .noAdd
  +add16 result+2, factor2addr
.noAdd:
  clc
  ror result+3
  ror result+2
  ror result+1
  ror result
  dex
  bne .loop
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

;Function parameter storage
r0 = $00fb
r1 = $00fc
r2 = $00fd
r3 = $00fe
r4 = $0002

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

;Init random middle square algorithm
+mov previousMidSqrtNumber, sidVoice3ValueRegister
;Init app logic
ldx #0; currentIteration

apploop:
;Display sid voice
lda sidVoice3ValueRegister
sta screen, x
lda kernelTextColorRegister
sta colorRam, x
jsr randomMidSquare
lda previousMidSqrtNumber
sta screen+256, x
lda kernelTextColorRegister
clc
adc #16/4
sta colorRam+256, x
inx
jmp apploop

randomMidSquare: ;Compute a number of n bits length by taking n bits from the middle of the bit sequence created by (f(n)-1)^2
php
+phx
+mov r2, midSqrtNumber
+mov r4, midSqrtNumber
+mul8816 r4, r2, r0, r1 ;Multiply the result of the previous iteration with itself
lda r0
and #$f0 ;take the high nibble of the low byte of the multiplication result
+swp ;swap the results in the high nibble with the zeros in the low nibble
sta midSqrtNumber ;let the high nibble of the low byte of the multiplication result be the low nibble of the iteration result
lda r1
and #$0f ;take the low nibble of the high byte of the multiplication result
+swp ;swap the results in the low nibble with the zeros in the high nibble
ora midSqrtNumber ;let the low nibble of the high byte of the multiplication result be the high nibble of the iteration result
sta midSqrtNumber ;Store the result of this iteration as previousMidSqrtNumber for the next iteration
+plx
plp
rts

midSqrtNumber:
!byte 0 ;Note the seed must not be 0 as the algorithm collapses would collapse due to 0 being the destructive element of multiplication.

*=vicCharsetBlock*2048
hexcharset:
!bin "hexcharset1.prg",256*9,2