;Decrease x for both sprites in the pair
lda sprite1PositionX
sec
sbc #1
sta sprite1PositionX
bcs movesprite2
lda #$fe
and $d010
sta $d010
movesprite2:
lda $d002
sec
sbc #1
sta $d002
bcs moveleftdone
lda #$fd
and $d010
sta $d010
moveleftdone:

moveup:
lda sprite1PositionY
sec
sbc #1
sta sprite1PositionY