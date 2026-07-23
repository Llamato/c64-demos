*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

*=$080d

;Macros
!macro poke .addr, .value {
  lda #.value
  sta .addr
}

!macro mov .destination, .source {
  lda .source
  sta .destination
}

!macro add16a .addr {
  adc .addr
  sta .addr
  lda .addr+1
  adc #0
  sta .addr+1
}

!macro sub168i .addr, .value {
  sec
  lda .addr
  sbc #.value
  sta .addr
  lda .addr+1
  sbc #0
  sta .addr+1
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

!macro div1688 .dividendLow, .dividendHigh, .divisor, .quotient, .remainder {
  lda #0
  sta .remainder
  ldx #16
.loop:
  asl .dividendLow
  rol .dividendHigh
  rol .remainder
  lda .remainder
  bcs .subtract
  cmp .divisor
  bcc .noSubtract
.subtract:
  sec
  sbc .divisor
  sta .remainder
  inc .dividendLow
.noSubtract:
  dex
  bne .loop
  lda .dividendLow
  sta .quotient
}

;Hardware constants
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorViolet = 4
vicColorGreen = 5
vicColorBlue = 6
screenColumns = 40
screenRows = 25
screenSize = screenColumns * screenRows

;Hardware registers
screen = $400 ;4*256 = 1024 = $400
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicScreenAndChargenMemoryPointersRegister = $d018
colorRam = $d800 ;d800-dbe7 = 1000 * 4 bit (lower byte only)
cia1portA = $dc00 ;Bit 6 = Control port 1 paddles selected, Bit 7 = Control port 2 paddels selected.
cia1portB = $dc01
cia1ddrA = $dc02
cia1ddrB = $dc03
cia1interruptControlRegister = $dc0d
sidADC0 = $d419 ;Analog value padel x is set to can be read here
sidADC1 = $d41a ;Analog value padel y is set to can be read here

;Kernel registers
kernelTextColorRegister = $286

;Program constants
chargenAddress = $3800 ;7 * 2048 = 14336 = $3800

*=$080d
;Set colors
+poke vicBackgroundColorRegister, vicColorBlack
+poke kernelTextColorRegister, vicColorWhite

;Setup custom character set
;+poke vicScreenAndChargenMemoryPointersRegister, (7<<1) ;7 * 2048 = 14336 = $3800. Shift by 1 to hit bits 1-3
lda vicScreenAndChargenMemoryPointersRegister
ora #14
sta vicScreenAndChargenMemoryPointersRegister

;Setup paddel input
lda cia1portA
and #$3f ;Clear bit 7 and 6
ora #$80 ;Set bit 7 and thereby select control port 1
sta cia1portA

;Set colors
+poke vicBorderColorRegister, vicColorGreen

;Clear screen
!zone clearscreen {
  lda #0
  ldx #0
.loop:
  sta screen, x
  sta screen+256, x
  sta screen+512, x
  sta screen+768, x
  inx
  bne .loop
}

apploop:
!zone main {
.tempA = $c020
.tempX = $c021
.tempY = $c022
;Process padel 1
  jsr readPaddel
  sta .tempA
  ldy #1
  jsr drawGraph ;Draw a graph for the raw value
  lda .tempA
  ldx #255
  ldy #200
  jsr scale ;Scale the raw value to fit the screen
  sta .tempA ;Update the masurement preserving register to contain the scaled value
  ldy #5
  jsr drawGraph ;Draw a graph for the scaled value
  lda .tempA ;Restore the scaled value to the accumulator
  jsr simpleMovingAverage ;Apply simple moving average smoothing
  ldx #255
  ldy #200
  jsr scale
  ldy #10
  jsr drawGraph ;Draw a graph for the simple average smoothed value 
  lda .tempA
  jsr weightedMovingAverage
  ldy #15
  jsr drawGraph
  lda .tempA
  jsr exponentialMovingAverage
  ldy #20
  jsr drawGraph
  jmp apploop
}

readPaddel:
!zone readPadel {
;Disable keyboard scan
  sei
  sta cia1portB
;Short delay
  ldy #$80
delayloop:
  dey
  bne delayloop
;Read adc masurement
  lda sidADC0
  cli
  rts
}

;long map(long x, long in_min, long in_max, long out_min, long out_max) {
;  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
;}
;with in_min=0 and out_min=0 simplifies to x * out_max / in_max
;with A=x, X=in_max and Y=out_max
scale:
!zone scale {
  .xValue = $c010
  .inMax = $c011
  .outMax = $c012
  .resultLow = $c013
  .resultHigh = $c014
  .remainder = $c015
  sta .xValue
  stx .inMax
  sty .outMax
;Multiply: result = x * out_max
  +mul8816 .xValue, .outMax, .resultLow, .resultHigh
;Divide: result = result / in_max
  +div1688 .resultLow, .resultHigh, .inMax, .xValue, .remainder
;Result in .xValue
  lda .xValue
  rts
}

drawGraph:
!zone drawGraph {
;Input: A = value (0-255), Y = column to draw at
  .rowStartPointerLowByte = 253
  .rowStartPointerHighByte = 254
  .tempA = $cff0
  .tempX = $cff1
  .tempY = $cff2
  sta .tempA
  stx .tempX
  sty .tempY
;Set pointer to start of screen + offset to bottom row
  lda #<screen
  clc
  adc #<(screenRows*screenColumns - screenColumns)
  sta .rowStartPointerLowByte
  lda #>screen
  adc #>(screenRows*screenColumns - screenColumns)
  sta .rowStartPointerHighByte
  ldx #0
  lda .tempA
.loop:
  cmp #8
  bcc .partial
  lda #8
  ldy .tempY
  sta (.rowStartPointerLowByte), y
  +sub168i .rowStartPointerLowByte, screenColumns
  inx
  lda .tempA
  sec
  sbc #8
  sta .tempA
  cpx #screenRows
  beq .done
  jmp .loop
.partial:
  cmp #0
  beq .clearRest
  ldy .tempY
  sta (.rowStartPointerLowByte), y
.clearRest:
  +sub168i .rowStartPointerLowByte, screenColumns
  inx
.clearLoop:
  cpx #screenRows
  beq .done
  +sub168i .rowStartPointerLowByte, screenColumns
  inx
  lda #0
  ldy .tempY
  sta (.rowStartPointerLowByte), y
  jmp .clearLoop
.done:
  lda .tempA
  ldx .tempX
  ldy .tempY
  rts
}

measurementCount = 64
sumAccumulator = $c030 ;($c030-$c031)
simpleMovingAverage:
!zone simpleMovingAverage {
;Clear the sum accumulator. Note the accumulator needs to be larger then the value being read in but 2 bytes (16 bits) are already enough for up to 256 8 bit massurements since (2^16)/(2^8)=256
  +poke sumAccumulator, 0
  +poke sumAccumulator+1, 0
;Keep track of how many measurements have yet to be taken
  ldx #measurementCount
  clc
.readingLoop
  jsr readPaddel
  +add16a sumAccumulator ;Sum up the messurements into the sumAccumulator
  dex
  bne .readingLoop
;Divide by the number of messurements
  lsr sumAccumulator+1
  ror sumAccumulator
  lsr sumAccumulator+1
  ror sumAccumulator
  lsr sumAccumulator+1
  ror sumAccumulator
  lsr sumAccumulator+1
  ror sumAccumulator
  lsr sumAccumulator+1
  ror sumAccumulator
  lsr sumAccumulator+1
  ror sumAccumulator
  lda sumAccumulator
  rts
}


weightedMovingAverage:
;Not yet implemented
lda #0
rts

exponentialMovingAverage:
;Not yet implemented
lda #0
rts

*=7*2048
customchars:
;0 filled 8 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000

;1 filled 7 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %11111111

;2 filled 6 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %11111111
!byte %11111111

;3 filled 5 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %11111111
!byte %11111111
!byte %11111111

;4 filled 4 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %00000000
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

;5 filled 3 empty
!byte %00000000
!byte %00000000
!byte %00000000
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

;6 filled 2 empty
!byte %00000000
!byte %00000000
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

;7 filled 1 empty
!byte %00000000
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111

;7 filled 0 empty
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111
!byte %11111111