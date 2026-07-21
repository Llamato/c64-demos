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

!macro add16a .addr {
  adc addr
  sta addr
  adc #0
  sta addr+1
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
cia1PortA = $dc00 ;Bit 6 = Control port 1 paddles selected, Bit 7 = Control port 2 paddels selected.
sidADC0 = $d419 ;Analog value padel x is set to can be read here
sidADC1 = $d41a ;Analog value padel y is set to can be read here

;Kernel registers
kernelTextColorRegister = $286

;Programm constants
chargenAddress = $3800 ;7 * 2048 = 14336 = $3800

*=$080d
;Set colors
+poke vicBackgroundColorRegister, vicColorBlack
+poke kernelTextColorRegister, vicColorWhite

;Setup custom character set
+poke vicScreenAndChargenMemoryPointersRegister, (7<<1) ;7 * 2048 = 14336 = $3800. Shift by 1 to hit bits 1-3

;Set colors
+poke vicBorderColorRegister, vicColorGreen

;Clear screen 
ldy #0
tya

screenclearloop:
sta screen+0*256, y ;Screen page 0
sta screen+1*256, y ;Screen page 1
sta screen+2*256, y ;Screen page 2
sta screen+3*256, y ;Screen page 3
iny
bne screenclearloop

!zone divideScreenIntoColoredRegions {
  colorRamEnd = colorRam + screenSize
  colorRamPointerLowByte = 253
  colorRamPointerHighByte = 254
  +poke colorRamPointerLowByte, <colorRam
  +poke colorRamPointerHighByte, >colorRam
  ldy #0 ;Current column
  ldx #0 ;Current Row

.loop
    cpy #screenColumns/2
    bcc .inFirstHalf
    jmp .inSecondHalf
.inFirstHalf
      lda #vicColorRed
      jmp .nextColumn
.inSecondHalf
      lda #vicColorBlue
.nextColumn
      sta (colorRamPointerLowByte), y
      iny
      cpy #screenColumns
      bne .loop
.nextRow
      inx
      cpx #screenRows
      beq .done
      lda #screenColumns
      clc
      +add16a colorRamPointerLowByte
.done
}

apploop:
;Process padel 1
lda sidADC0
ldx #1
pha
jsr drawGraph ;Draw raw value 
pla
pha
jsr simpleMovingAverage
ldx #5
jsr drawGraph
pla
pha
jsr weightedMovingAverage
ldx #10
jsr drawGraph
pla
pha
jsr exponentialMovingAverage
ldx #19
jsr drawGraph
pla

;Process padel 2
lda sidADC1
ldx #21
pha
jsr exponentialMovingAverage
ldx #25
jsr drawGraph
pla
pha
jsr weightedMovingAverage
ldx #30
jsr drawGraph
pla
pha 
jsr simpleMovingAverage
ldx #35
jsr drawGraph
pla
ldx #39
jsr drawGraph

;Repeat
jmp apploop

drawGraph:
!zone drawGraph {
  ;Check if A is geater then 8
  ;If yes substract 8 and add block to bar
  ;Repeart until A is less then or equal to 8. Then selected coresponding top block by offset lookup

  ;Point pointer to start of lowest screen row
  rowStartPointerLowByte = 253
  rowStartPointerHighByte = 254
  +poke rowStartPointerLowByte, <screenRows*screenColumns-screenColumns
  +poke rowStartPointerHighByte, >screenRows*screenColumns-screenColumns
  
  ;Then add the column index to get the start of the bar
  pha 
  txa
  +add16a rowStartPointerLowByte
  pla

  .loop
  sec
  sbc #8
  cmp #8
  bcc .selectTop
  pha
  
  jmp loop
  rts
}

simpleMovingAverage:
;Not yet implemented
lda #0 
rts

weightedMovingAverage:
;Not yet implemented
lda #0
rts

exponentialMovingAverage:
;Not yet implemented
lda #0
rts

*=$3000
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