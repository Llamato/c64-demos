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

;Memory mapped registers
;nc = X
sc = $02
c = $fb ;$fb:fc
cellPtr = $fd ;$fd:fe

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
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

gameloop:
    +ldi16 c, 0
l20: ;for c=0 to 1000
    lda c+1
    cmp #>1000
    bne cellloop
    lda c
    cmp #<1000
    bne cellloop
    inc sc ;150 sc=sc+1
    jmp gameloop ;160 goto 20

cellloop:
    ldx #0 ;10 nc=0
l40: ;if c<1000 then goto checkRight
    lda c
    cmp #<1000
    lda c+1
    sbc #>1000
    bcs l50
    jmp checkRight
l50: ;if c>0 then goto checkLeft
    lda c
    ora c+1
    beq l60
    jmp checkLeft
l60: ;if c<960 then goto checkBottom
    lda c
    cmp #<960
    lda c+1
    sbc #>960
    bcs l90
    jmp checkBottom
l90: ;if c>39 then goto checkTop
    lda c
    cmp #40
    lda c+1
    sbc #0
    bcc l120
    jmp checkTop
l120: ;if nc<2 or nc>3 then goto clearCell
    cpx #2
    bcc clearCell ;X < 2
    cpx #4
    bcs clearCell ;X >= 4 <=> X > 3
l130: ;if nc=3 then  goto fillCell
    cpx #3
    beq fillCell
next:
    +inc16 c
    jmp l20

fillCell:
    +ldi16 cellPtr, 1024 ;cellPtr = 1024
    +add16 cellPtr, c ;cellPtr = 1024+c
    lda #83 ;a = 83 = heart
    ldy #0 ;y = 0
    sta (cellPtr), y ;poke 1024+c, 83
    +ldi16 cellPtr, 55296 ;cellPtr = 55296
    +add16 cellPtr, c ;cellPtr 55296+c
    lda sc ;a = sc
    sta (cellPtr), y ;poke 55296+c, sc
    jmp next

clearCell:
    +ldi16 cellPtr, 1024 ;cellPtr = 1024
    +add16 cellPtr, c ;cellPtr = 1024+c
    lda #32 ;32 = blank
    ldy #0
    sta (cellPtr), y ;poke 1024+c, 32
    jmp next

checkRight:
    +ldi16 cellPtr, 1024 ;cellPtr = 1024
    +add16 cellPtr, c ;cellPtr = 1024+c
    +inc16 cellPtr ;cellPtr=cellPtr+1
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c+1)
    cmp #32
    beq l50jp ;peek(1024+c+1)==32 then goto l50
    inx ;otherwise x=x+1 nc=nc+1
l50jp: ;Needed because compare instructions can not jump further then 128 bytes
    jmp l50

checkLeft:
    +ldi16 cellPtr, 1024 ;cellPtr = 1024
    +add16 cellPtr, c ;cellPtr = 1024+c
    +dec16 cellPtr ;cellPtr = cellPtr+1 = 1024+c+1
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c-1)
    cmp #32
    beq l60jp ;if cell is empty then goto l60
    inx ;otherwise nc=nc+1
l60jp:;Needed because compare instructions can not jump further then 128 bytes
    jmp l60

checkBottom:
    +ldi16 cellPtr, 1024+40 ;cellPtr = 1024+40
    +add16 cellPtr, c ;cellPtr = 1024+c+40
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c+40)
    cmp #32
    beq checkBottomLeft ;if cell is empty then goto checkBottomLeft
    inx ;otherwise nc=nc+1

checkBottomLeft:
    +dec16 cellPtr
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c+40-1)
    cmp #32
    beq checkBottomRight ;if cell is empty then goto checkBottomRight
    inx ;otherwise nc=nc+1

checkBottomRight:
    +inc16 cellPtr
    +inc16 cellPtr
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c+40+1)
    cmp #32
    beq l90jp ;if cell is empty then goto l90
    inx ;otherwise nc=nc+1
l90jp:;Needed because compare instructions can not jump further then 128 bytes
    jmp l90

checkTop:
    +ldi16 cellPtr, 1024-40 ;cellPtr = 1024-40
    +add16 cellPtr, c ;cellPtr = 1024+c-40
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c-40)
    cmp #32
    beq checkTopLeft ;if cell is empty then goto checkTopLeft
    inx ;otherwise nc=nc+1

checkTopLeft:
    +dec16 cellPtr
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c-40-1)
    cmp #32
    beq checkTopRight ;if cell is empty then goto checkTopRight
    inx ;otherwise nc=nc+1

checkTopRight:
    +inc16 cellPtr
    +inc16 cellPtr
    ldy #0
    lda (cellPtr), y ;peek(cellPtr+y) = peek(1024+c-40+1)
    cmp #32
    beq l120jp ;if cell is empty then goto l120
    inx ;otherwise nc=nc+1
l120jp:;Needed because compare instructions can not jump further then 128 bytes
    jmp l120