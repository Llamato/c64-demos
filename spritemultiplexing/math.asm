
!macro poke .addr, .v {
    lda #.v
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro lsl {
    clc
    rol
}
!macro add8 .op1, .op2 { ;a=op1+op2
    lda .op1
    clc
    adc op2
}

!macro sub8 .op1, op2 { ;a=op1-op2
    lda .op1
    sec
    sbc .op2
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

!macro push .addr {
    lda .addr 
    pha
}

!macro pull .addr {
    pla
    sta .addr
}

!macro add16a .i16addr {
    clc
    adc i16addr
    sta i16addr
    adc #0
    sta i16addr+1
}

!macro pow2x {
    lda #1

    .loop
        cpx #0
        beq .done
        lsr
        dex
        jmp loop
}

!macro mul8 .multiplier, .multiplicand, product
    lda #0             
    sta .product+1
    ldx #8

    .multloop:
        lsr .multiplier      
        bcc .no_add   
        clc                
        lda .product+1
        adc .multiplicand
        sta .product+1

    .no_add:
        ror .product+1
        ror .product
        dex
        bne .multloop
        rts

!macro mul168 .i16addr, .i8addr, .result {
    lda #0
    sta .result
    sta .result+1
    ldx #8

    .loop
        lsr i8addr
        bcc .no_add
        clc
        lda .result
        adc .i16addr
        sta .result
        lda .result+1
        adc .i16addr+1
        sta .result+1

    .no_add
        asl .i16addr
        rol .i16addr+1
        dex
        bne .loop
}

!macro div168 .i16addr, .i8addr { ;i16addr = Qutient, a = Reminder
    ldx #16
    lda #0

    .loop:
        asl i16addr
        rol i16addr
        rol
        cmp i8addr
        bcc no_sub
        sbc i8addr
        inc i16addr

    .no_sub:
        dex
        bne .loop 
}

setSpritePixel: ;r0 = x, r1=y
    +poke r2, 3 * 8
    +mul8 r1, r2, r3
    +add16a r0
    +poke r2, 8
    +div168 r3, r2
    tax
    +pow2x
    sta r2
    ora (r3), r2
    rts

mirrorCircleSpriteSegment: ;r0 = center.x, r1 = center.y, r2 = circumfrancePoint.x, r3 = circumfrancePoint.y
    +add8 r0, r2
    sta r4 ;r4 = center.x + circumfrancePoint.x
    +add8 r0, r3
    sta r5 ;r5 = center.x + circumfrancePoint.y
    +add8 r1, r2 
    sta r6 ;r6 = center.y + circumfrancePoint.x
    +add8 r1, r3
    sta r7 ;r7 = center.y + circumfrancePoint.y
    +sub8 r0, r2
    sta r8 ;r8 = center.x - circumfrancePoint.x
    +sub r0, r3
    sta r9 ;r9 = center.x - circumfrancePoint.y
    +sub8 r1, r2
    sta r10 ;r10 = center.y - circumfrancePoint.x
    +sub8 r1, r3
    sta r11 ;r11 = center.y - circumfrancePoint.y
    +mov r0, r4 ;x = center.x + circumfrancePoint.x
    +mov r1, r5 ;y = center.y + circumfrancePoint.y
    jsr setSpritePixel
    +mov r0, r8 ;x = center.x - circumfrancePoint.x
    +mov r1, r5 ;y = center.y + circumfrancePoint.y
    jsr setSpritePixel
    +mov r0, r4 ;x = center.x + circumfrancePoint.x
    +mov r1, r11 ;y = center.y - circumfrancePoint.y
    jsr setSpritePixel
    +mov r0, r8 ;x = center.x - circumfrancePoint.x
    +mov r1, r11 ;y = center.y - circumfrancePoint.y
    jsr setSpritePixel
    +mov r0, r9 ;x = center.x - circumfrancePoint.y
    +mov r1, r6 ;y = center.y + circumfrancePoint.x
    jsr setSpritePixel
    +mov r0, r5 ;x = center.x + circumfrancePoint.y
    +mov r1, r6 ;y = center.y + circumfrancePoint.x
    jsr setSpritePixel
    +mov r0, r5 ;x = center.x + circumfrancePoint.y
    +mov r1, r10 ;y = center.y - circumfrancePoint.x
    jsr setSpritePixel
    +mov r0, r9 ;x = center.x - circumfrancePoint.y
    +mov r1, r10 ;y = center.y - circumfrancePoint.x
    rts

drawCircleSpriteBresenham: ;a=radius, r0 = center.x, r1 = center.y
{
    sta r4 ;r4 = radius
    sta r3 ;r3 = circumfrancePoint.y = radius
    +poke r2, 0 ;r2 = circumfrancePoint.x = 0
    clc
    rol r4 ;r4 = 2 * radius
    lda #3
    sec
    sbc r4
    sta r4; r4 = diameter = 3 - (2 * radius)
    +push r0
    +push r1
    +push r2
    +push r3
    jsr mirrorCircleSpriteSegment
    +pull r3
    +pull r2
    +pull r1
    +pull r0
    .loop:
        lda r2
        cmp r3
        bcc .loopstart
        jmp .loopend
        .loopstart
            lda r4
            cmp #0
            bpl .positive ;if(diameter > 0)
            jmp .negative ;if(!(diameter > 0))
            .positive
                lda r3
                sec
                sbc #1
                sta r3 ;circumfrancePoint.y--;
                lda r2 ;a = r2 = circumfrancePoint.x
                sec
                sbc r3 ;a = circumfrancePoint.x - circumfrancePoint.y
                clc
                rol
                clc
                rol ;a = 4 * (circumfrancePoint.x - circumfrancePoint.y)
                clc
                adc #10; a = 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10
                adc r4 ;a = diameter + 4 * (circumfrancePoint.x - circumfrancePoint.y) + 10;
                sta r4 ;r4 = a
                jmp .common
            .negative
                lda r2 ;a = r2 = circumfrancePoint.x
                clc
                rol
                clc
                rol ;a = 4 * circumfrancePoint.x
                clc
                adc #6 ;a = 4 * circumfrancePoint.x + 6
                adc r4 ; a = diameter + 4 * circumfrancePoint.x + 6
        .common:
            inc r2
            +push r0
            +push r1
            +push r2
            +push r3
            jsr mirrorCircleSpriteSegment
            +pull r3
            +pull r2
            +pull r1
            +pull r0
            jmp loop
.loopend
    rts
}