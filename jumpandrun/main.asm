; jump and run - smooth right to left scrolling demo
;
; the smooth scroll is pure vic-ii hardware: bits 0-2 of $d016 shift the whole
; text display one pixel per value. running right counts that value down from
; 7 to 0; when it would drop below zero we shift the screen memory one column
; left, generate fresh terrain in the freed column 39 and restart at 7.
; because the background colour equals the border colour, the 0-7 pixel gap
; the fine scroll opens at the screen edge is invisible.
;
; controls: joystick 1 or 2. left/right runs, fire jumps.

*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for sys
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Vic Registers
vicControlRegister1 = $d011
vicControlRegister2 = $d016
vicMemoryPointersRegister = $d018
vicRasterInterruptScanlineSelectRegister = $d012
vicAcknowlageInterruptRegister = $d019
vicInterruptControlRegister = $d01a
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicSpriteEnableRegister = $d015
vicSpritePositionsXhighbitRegister = $d010
vicSprite0positionXregister = $d000
vicSprite0positionYregister = $d001
vicSprite0colorRegister = $d027
vicSprite0bitmapBlockPointerRegister = $07f8

;Screen and Color Ram
screen = $0400
colorRam = $d800

;CIA registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d
cia1TimerControlRegister = $dc05
cia2TimerControlRegister = $dd05

;CIA input ports: the joysticks sit on cia PORT B (the keyboard rows):
;joystick 1 on $dc01, joystick 2 on $dd01. port A carries the matrix columns
;and must be driven high; cia2 port A is also the serial bus and reads junk
;($3f), which is why reading it made the runner jump constantly.
joystickPort1 = $dc01
joystickPort2 = $dd01

;Kernel
kernelrqVector = $0314 ;$0314-0315
chargenRom = $e000 ;character rom, visible to the cpu here while romsel=0
cpuBankRegister = $01

;vic colors
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
vicColorBlue = 6
vicColorYellow = 7
vicColorBrown = 8
vicColorDarkBrown = 9
vicColorLightBlue = 14

;petscii characters
petsciiSpace = $20
petsciiDollar = $24
petsciiSolidBlock = $a0 ;chargen full block, used for the dirt
petsciiSurfaceBlock = $78 ;chargen top-half block: the surface line

;memory layout, everything inside the default vic bank $0000-$3fff
;note: a prg loaded at $0801 is truncated at $3700 (the kernal cassette
;buffer), so all embedded data sits below that and is copied into place at
;init.
;$d018 layout (c64-wiki 53272): bits 7-4 = screen base in 1k units, bits
;3-1 = charset base in 2k units, bit 0 unused. the sprite base uses the
;same bits 7-4 but in 16k units. with $01=$37 the character rom is off,
;so the default $15 (charset bits = $1000, the rom shadow) makes the vic
;read ram at $1000 - our own heightmap bytes - as glyphs: that is the
;"special characters instead of letters" on the hud.
heightmapStart = $1000 ;ground row per world column, 256 entries
coinsStart = $1100 ;coin row per world column, $ff = no coin
;the vic bank is 0 ($dd00 bits 1-0 = 11): the vic only sees $0000-$3fff.
;sprite base bits 7-4 = 1 wraps to bank offset 0, so block 240 is fetched
;from 240*64 = $3c00 - the art must live there, not at $7c00.
runnerSpriteStart = $3c00 ;block 240 run a, 241 run b, 242 jump
runnerSpriteSource = $1a00 ;embedded sprite frames, copied to runnerSpriteStart
;we embed the chargen letters half and copy it to $3000 (a 2k aligned ram
;charset base the vic can see; $1000/$1800 are overshadowed by the rom).
charsetRam = $3000 ;2048 bytes the vic reads as the charset
charsetSource = $2400 ;embedded letters half, copied to charsetRam
;$1c = %0001_110_0: screen $0400, charset $3000, sprite base $4000.
vicMemoryValue = $1c
runnerSpriteBlockRunA = 240
runnerSpriteBlockRunB = 241
runnerSpriteBlockJump = 242

;application constants
screenColumns = 40
screenRows = 25
hudRows = 2 ;rows 0-1 are the hud and never shift
refillColumn = 39 ;new terrain enters here when scrolling left
maxScrollSpeed = 2 ;pixels per frame of the fine scroll
playerScreenX = 100 ;the runner stays at a fixed screen x
playerScreenColumn = 13 ;screen column under the middle of the runner
feetSpriteRow = 17 ;sprite art row that touches the ground
surfacePixelOffset = 4 ;the surface line sits 4 pixels into the ground row
;a sprite y of 0 appears at raster 18, a text row r starts at raster 51+8r.
;feet row 17 on the surface line: y + 18 + 17 = 51 + 8*groundRow + 4
groundYOffset = 32 ;y = 8*groundRow + 32. measured in vice: with 20 the
;feet sat ~12 rasters above the surface line (looked like a floating tile);
;32 puts the feet row right on top of the ground block.
jumpVelocityHigh = $fc ;-4.0 px/frame in 8.8 fixed point
jumpVelocityLow = 0
gravity = 64 ;+0.25 px/frame^2 in 8.8 fixed point. with the 4 px/frame
;launch this gives a 16 frame rise of 32 pixels (4 text rows) and the same
;fall back: about half a second of air. measured in vice with the old value
;of 32 the arc was 66 pixels high and hung for a full second, which looked
;floaty.
rasterline = 255 ;irq in the lower border, no bad lines

;program registers (zero page)
ptr = $c0
ptr2 = $c2
ptr3 = $c4
ptr4 = $c6

;program state
fineScroll = $20 ;mirror of $d016 bits 0-2
scrollX = $21 ;world column currently drawn in screen column 0
scrollSpeed = $22
playerYlow = $23 ;8.8 fixed point y of the sprite top
playerYhigh = $24
playerVelocityLow = $25
playerVelocityHigh = $26
groundLevelLow = $27 ;8.8 fixed point y of the ground under the player
groundLevelHigh = $28
groundRow = $29
onGround = $2a
frameCounter = $2b
fireWasPressed = $2c ;joystick fire edge latch
moveDirection = $2d ;-1, 0 or 1 from the joystick
keyboardWasPressed = $2e ;keyboard jump edge latch, kept separate from the
;joystick latch: readInput clears fireWasPressed every frame when no joystick
;is connected, which made holding space re-trigger tryJump every frame - the
;rapid auto-bounce.
spaceDown = $2f ;space key currently held (0/1)
colIdx = $30 ;column being drawn
rowCounter = $31
dirtColor = $32
score = $33
debugCol = $34
keyQ = $35 ;q key currently held (0/1)
keyP = $36 ;p key currently held (0/1)
joy2State = $3a ;joystick 2 port bits sampled this frame
joy1State = $3b ;joystick 1 port bits sampled this frame
fireDown = $3c ;fire held on either joystick this frame

!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

;advance a 16 bit pointer by a fixed amount
!macro advance .addr, .amount {
    clc
    lda .addr
    adc #(.amount) & $ff
    sta .addr
    lda .addr+1
    adc #((.amount) >> 8) & $ff
    sta .addr+1
}

;copy the embedded runner sprite frames to their block area at $3c00.
;three 64 byte frames: runA, runB, jump.
    ldx #0
.spriteloop
    lda runnerSpriteSource+0*64, x
    sta runnerSpriteStart+0*64, x
    lda runnerSpriteSource+1*64, x
    sta runnerSpriteStart+1*64, x
    lda runnerSpriteSource+2*64, x
    sta runnerSpriteStart+2*64, x
    inx
    cpx #64
    bne .spriteloop

;copy the embedded chargen letters half to charsetRam. with $01=$37 the
;chargen rom is switched off, so the vic must read its glyphs from ram:
;the default $d018 ($15) points the charset at $0c00 - inside our own
;machine code - which is what looked like special characters instead of
;letters on the hud.
    +ldi16 ptr, charsetSource
    +ldi16 ptr2, charsetRam
    ldx #8
.charsetCopyRow
    ldy #0
.charsetCopyLoop
    lda (ptr), y
    sta (ptr2), y
    iny
    bne .charsetCopyLoop
    +advance ptr, 256
    +advance ptr2, 256
    dex
    bne .charsetCopyRow

;screen $0400, charset $3000 (the copied letters half), sprite base $4000
;(blocks 240-242 then read $7c00, where the runner frames were copied).
    +poke vicMemoryPointersRegister, vicMemoryValue

;clear the screen with sky. the loops cover $0400-$07e7: the kernel leaves
;text in $0700-$07e7 (screen rows 19-24) and colours in $db00-$dbe7, which
;showed up as white inverse text bands at the bottom of the display.
    lda #petsciiSpace
    ldx #0
.screenclearloop
    sta screen+0*256, x
    sta screen+1*256, x
    sta screen+2*256, x
    inx
    bne .screenclearloop
    ldx #231
.screenclearloop2
    sta screen+3*256, x
    dex
    bpl .screenclearloop2

;sky colour everywhere
    lda #vicColorLightBlue
    ldx #0
.colorfillloop
    sta colorRam+0*256, x
    sta colorRam+1*256, x
    sta colorRam+2*256, x
    inx
    bne .colorfillloop
    ldx #231
.colorfillloop2
    sta colorRam+3*256, x
    dex
    bpl .colorfillloop2

;hud text in the two rows that never shift. it starts at screen column 1:
;the hardware fine scroll ($d016 bits 0-2) shifts the whole display up to
;seven pixels left, and at the larger phases the glyph in column 0 - the J
;of JUMP - scrolls off the left edge. one column of margin keeps it on
;screen at every scroll phase.
    ldx #0
.hudloop
    lda hudText, x
    beq .huddone
    sta screen+1, x
    lda #vicColorWhite
    sta colorRam+1, x
    inx
    bne .hudloop
.huddone

;border and background are the same colour, which hides the fine scroll gap
    +poke vicBorderColorRegister, vicColorBlue
    +poke vicBackgroundColorRegister, vicColorBlue

;40 column mode (bit 3 set) with fine scroll starting at 7
    +poke vicControlRegister2, %00001111
    +poke fineScroll, 7

;sprite 0 setup: the runner
    +poke vicSprite0bitmapBlockPointerRegister, runnerSpriteBlockRunA
    +poke vicSprite0colorRegister, vicColorYellow
    +poke vicSprite0positionXregister, playerScreenX
    lda vicSpritePositionsXhighbitRegister
    and #%11111110 ;playerScreenX < 256, clear bit 0 of sprite 0
    sta vicSpritePositionsXhighbitRegister
    +poke vicSpriteEnableRegister, %00000001

;seed the coins: one every sixteenth world column, three rows above the ground
    ldx #0
.coinseedloop
    txa
    and #%00001111
    cmp #8
    bne .coinnone
    lda heightmapStart, x
    sec
    sbc #3
    sta coinsStart, x
    jmp .coinnext
.coinnone
    lda #$ff
    sta coinsStart, x
.coinnext
    inx
    bne .coinseedloop

;the starting world is drawn further down, only after the raster sync is
;armed: drawing all 40 columns takes longer than one frame, and doing it
;before the vic has scanned the screen once let the vic render half-written
;columns - the gaps and stray "pillars" that showed on the first screen and
;then disappeared.

;setup raster interrupt in the lower border
    sei ;disable interrupts globally
;disable all cia interrupt sources: the kernel leaves timer a (jiffy clock)
    ;and timer b enabled. cia2 timer a drives the cpu NMI line, so a latched
    ;cia2 flag gives us an nmi storm; cia1 timers storm the irq line.
    +poke cia1ControlRegister, $00
    +poke cia2ControlRegister, $00


;drive all keyboard matrix columns high so the joysticks (which share the
;matrix rows on cia port b) read idle: a pressed joystick line pulls its row low
    +poke $dc02, $ff ;cia1 port a data direction = outputs (matrix columns)
    +poke $dc03, $00 ;cia1 port b data direction = inputs (rows / joystick 1)
    +poke $dc00, $ff ;all columns high
    +poke $dd02, $ff ;cia2 port a data direction = outputs (matrix columns)
    +poke $dd03, $00 ;cia2 port b data direction = inputs (rows / joystick 2)
    +poke $dd00, $ff ;all columns high

;frame sync by polling the vic raster flag instead of using an irq. the kernal
;irq chain (its handler jsrs through $0314 and re-arms the cia timers and
;$d01a on every interrupt) fought our own handler every way we tried: chained
;handlers crashed on the stack, self-contained ones raced the kernal's
;re-arming, and the raster flag re-latched on the same line, which overflowed
;the stack. here the cpu stays masked with sei forever: the vic still latches
;its raster flag in $d019 when the beam hits $d012, we just read that flag
;instead of being interrupted by it. no vectors, no acks, no rom banking, and
;a re-latched flag cannot storm because nothing ever takes the interrupt.
    +poke cia1TimerControlRegister, $00 ;stop the jiffy timers: no cia flags,
    +poke cia2TimerControlRegister, $00 ;so no nmi either (cia2 timer a drives nmi)
    lda vicAcknowlageInterruptRegister ;clear whatever the kernal latched
    lda cia1ControlRegister
    lda cia2ControlRegister
    +poke vicInterruptControlRegister, %00000010 ;vic raster flag latching on
    +poke vicRasterInterruptScanlineSelectRegister, rasterline
    ;bit 5 must stay set: it selects C64 mode, clearing it blanks the whole
    ;display (the screen goes solid background colour). keep it, clear only
    ;bit 1 (raster irq enable - we poll $d019 instead).
    +poke vicControlRegister1, %00011011 ;C64 mode, 40 columns, normal screen, raster irq off

;paint the starting world with the display switched off ($d011 bit 4 = 0):
;the vic keeps scanning the screen while we write, and painting 40 columns
;takes several frames, so doing it with the display on let the vic fetch
;half-written columns - the gaps and stray "pillars" that showed on the very
;first screen and vanished once the main loop started. with the display off
;the vic fetches nothing, and we switch it back on only after the whole
;world is in place and the beam has completed a frame.
    +poke vicControlRegister1, %00001011 ;display off

    +poke scrollX, 0
    ldx #0
.initialworldloop
    stx colIdx
    jsr drawWorldColumn
    ldx colIdx ;drawWorldColumn clobbers x, so reload the loop counter
    inx
    cpx #screenColumns
    bne .initialworldloop

;place the runner on the ground under it
    +poke onGround, 1
    lda scrollX
    clc
    adc #playerScreenColumn
    tax
    lda heightmapStart, x
    asl
    asl
    asl
    clc
    adc #groundYOffset
    sta playerYhigh
    sta vicSprite0positionYregister
    +poke playerYlow, 0

;wait for the raster flag: the frame that started while we were painting is
;over, the beam is in the lower border, safe to show the screen
.initialwait
    lda vicAcknowlageInterruptRegister
    and #%00010000 ;raster flag
    beq .initialwait
    +poke vicAcknowlageInterruptRegister, %00010000
    +poke vicControlRegister1, %00011011 ;display on

;main loop: one game step per frame
mainLoop:
    ;the beam is at $d012 when the raster flag lights up. wait for it at the
    ;bottom border, do the whole frame's writes there (no bad lines), then
    ;re-arm on a line the beam has already passed so the flag can only latch
    ;once per frame, and wait out that one too.
    lda vicAcknowlageInterruptRegister
    and #%00010000 ;raster flag
    beq mainLoop
    +poke vicAcknowlageInterruptRegister, %00010000
    +poke vicRasterInterruptScanlineSelectRegister, 100

    jsr readInput
    jsr readKeyboard
    jsr updateScroll
    jsr updatePlayer
    jsr updateAnimation
    jsr updateScore
    jsr drawScore

    lda vicAcknowlageInterruptRegister
    and #%00010000
    beq .rearm
    +poke vicAcknowlageInterruptRegister, %00010000
.rearm
    +poke vicRasterInterruptScanlineSelectRegister, rasterline
    jmp mainLoop

;--- input ---
;joystick 2 (cia2 port a) first, joystick 1 (cia1 port a) as fallback.
;a pressed joystick line pulls the port line low, so a zero after masking
;means the direction is pressed.
readInput:
!zone readInput {
    ;both joysticks are sampled first, then acted on: the old code branched
    ;straight out of the port 2 read into the port 1 read, and the "fire not
    ;pressed" branch of port 1 cleared the fire latch every frame even while
    ;port 2 fire was held - so holding fire bounced continuously.
    +poke moveDirection, 0
    ;joystick bits: 0=up 1=down 2=left 3=right 4=fire, pressed = low
    +poke joy2State, $ff
    lda joystickPort2
    and #%00011100 ;left, right and fire only
    sta joy2State
    +poke joy1State, $ff
    lda joystickPort1
    and #%00011100
    sta joy1State

    ;direction: joystick 2 wins over joystick 1
    lda joy2State
    and #%00000100 ;left
    beq .joy2Left
    lda joy2State
    and #%00001000 ;right
    beq .joy2Right
    jmp .joy1Direction
.joy2Left
    +poke moveDirection, -1
    jmp .joy1Direction
.joy2Right
    +poke moveDirection, 1

.joy1Direction
    lda moveDirection
    bne .readFire ;joystick 2 already set a direction
    lda joy1State
    and #%00000100 ;left on port 1
    beq .joy1Left
    lda joy1State
    and #%00001000 ;right on port 1
    beq .joy1Right
    jmp .readFire
.joy1Left
    +poke moveDirection, -1
    jmp .readFire
.joy1Right
    +poke moveDirection, 1

.readFire
    lda joy2State
    and #%00010000 ;fire on port 2
    beq .fireDown
    lda joy1State
    and #%00010000 ;fire on port 1
    beq .fireDown
    +poke fireDown, 0
    jmp .handleFire
.fireDown
    +poke fireDown, 1
.handleFire
    lda fireDown
    beq .fireReleased
    lda fireWasPressed
    bne .noRepeat ;fire still held from last frame: no auto-repeat
    +poke fireWasPressed, 1
    jsr tryJump
    rts
.noRepeat
    rts
.fireReleased
    +poke fireWasPressed, 0 ;released: arm the latch for the next press
    rts
}

;keyboard fallback so the demo is playable without a joystick:
;q = left, p = right, space = jump. the matrix is strobed one column at a
;time (port a output, active low) and the rows are read back on port b.
;matrix cells (verified against vice's gtk3_sym and gtk3_sym_be keymaps,
;which agree on these keys): q = col 7 row 6, p = col 5 row 1,
;space = col 7 row 4. the old code strobed col 6/bit 7, col 1/bit 5 and
;col 4/bit 7 - that is /, s and n - which is why space never jumped.
readKeyboard:
!zone readKeyboard {
    ;direction and jump are sampled independently: the old code returned as
    ;soon as a direction key was seen, so space was never noticed while q or
    ;p was held - that is why jumping only worked when standing still.
    ;matrix cells (c64-wiki keyboard matrix): q = col 7 row 6, space = col 7
    ;row 4, p = col 5 row 1. a pressed key pulls its row line low.
    +poke $dc00, %01111111 ;col 7 low
    lda $dc01
    and #%01000000 ;q
    beq .qDown
    +poke keyQ, 0
    jmp .readSpace
.qDown
    +poke keyQ, 1
.readSpace
    lda $dc01 ;col 7 is still strobed low
    and #%00010000 ;space
    beq .spaceHeld
    +poke spaceDown, 0
    jmp .readP
.spaceHeld
    +poke spaceDown, 1
.readP
    +poke $dc00, %11011111 ;col 5 low
    lda $dc01
    and #%00000010 ;p
    beq .pDown
    +poke keyP, 0
    jmp .columnsHigh
.pDown
    +poke keyP, 1
.columnsHigh
    +poke $dc00, $ff ;columns high again for the joystick read next frame

    lda keyQ
    beq .checkP
    +poke moveDirection, -1
    jmp .handleSpace
.checkP
    lda keyP
    beq .handleSpace
    +poke moveDirection, 1

.handleSpace
    lda spaceDown
    beq .spaceReleased
    lda keyboardWasPressed
    bne .noRepeat ;space still held from last frame: no auto-repeat
    +poke keyboardWasPressed, 1
    jsr tryJump
    rts
.noRepeat
    rts
.spaceReleased
    +poke keyboardWasPressed, 0 ;released: arm the latch for the next press
    rts
}

;--- scrolling ---
;bits 0-2 of $d016 shift the whole text display: one pixel per value,
;counting up moves the picture right. running right therefore counts the
;fine scroll down; when it would drop below zero we add eight, shift the
;screen memory one column left and generate fresh terrain in the freed
;column 39. running left mirrors this and refills column 0. the sprite layer
;is not affected by the fine scroll, so the runner stays put while the world
;slides smoothly under it.
updateScroll:
!zone updateScroll {
    lda moveDirection
    beq .noScroll
    bmi .leftward
    ;rightward: fine scroll down. the new value must be stored, not just left
    ;in a - the old code branched away with it in a only, so fineScroll never
    ;changed and the world never shifted.
    lda fineScroll
    sec
    sbc #maxScrollSpeed
    bpl .storeFine
    clc
    adc #8 ;wrapped below zero: add eight, shift the screen one column
    sta fineScroll
    jsr shiftScreenLeft
    inc scrollX
    +poke colIdx, refillColumn
    jsr drawWorldColumn
    jmp .writeFineScroll
.storeFine
    sta fineScroll
    jmp .writeFineScroll
.leftward
    ;leftward: fine scroll up
    lda fineScroll
    clc
    adc #maxScrollSpeed
    cmp #8
    bcs .wrapRight
    sta fineScroll
    jmp .writeFineScroll
.wrapRight
    sec
    sbc #8
    sta fineScroll
    jsr shiftScreenRight
    dec scrollX
    +poke colIdx, 0
    jsr drawWorldColumn
.writeFineScroll
    lda fineScroll ;drawWorldColumn clobbers a, so reload the fine scroll value
    ora #%00001000 ;keep 40 column mode
    sta vicControlRegister2
.noScroll
    rts
}

;shift rows 2..24 of screen and color ram one column left, then clear the
;freed column 39 so drawWorldColumn can refill it
shiftScreenLeft:
!zone shiftScreenLeft {
    +ldi16 ptr, screen+hudRows*40 ;destination column 0
    +ldi16 ptr2, screen+hudRows*40+1 ;source column 1
    +ldi16 ptr3, colorRam+hudRows*40
    +ldi16 ptr4, colorRam+hudRows*40+1
    ldx #screenRows-hudRows
.rowloop
    ldy #0
.colloop
    lda (ptr2), y
    sta (ptr), y
    lda (ptr4), y
    sta (ptr3), y
    iny
    cpy #screenColumns-1
    bne .colloop
    ldy #screenColumns-1
    lda #petsciiSpace
    sta (ptr), y
    lda #vicColorLightBlue
    sta (ptr3), y
    +advance ptr, 40
    +advance ptr2, 40
    +advance ptr3, 40
    +advance ptr4, 40
    dex
    bne .rowloop
    rts
}

;mirror of shiftScreenLeft for running left, frees column 0
shiftScreenRight:
!zone shiftScreenRight {
    +ldi16 ptr, screen+hudRows*40+1 ;destination column 1
    +ldi16 ptr2, screen+hudRows*40 ;source column 0
    +ldi16 ptr3, colorRam+hudRows*40+1
    +ldi16 ptr4, colorRam+hudRows*40
    ldx #screenRows-hudRows
.rowloop
    ldy #screenColumns-2
.colloop
    lda (ptr2), y
    sta (ptr), y
    lda (ptr4), y
    sta (ptr3), y
    dey
    bpl .colloop
    ldy #0
    lda #petsciiSpace
    sta (ptr2), y ;free column 0
    lda #vicColorLightBlue
    sta (ptr4), y
    +advance ptr, 40
    +advance ptr2, 40
    +advance ptr3, 40
    +advance ptr4, 40
    dex
    bne .rowloop
    rts
}

;draw one screen column (colIdx) from the world heightmap and coin table.
;the world column shown here is (scrollX + colIdx) mod 256.
drawWorldColumn:
!zone drawWorldColumn {
    lda scrollX
    clc
    adc colIdx
    tax
    lda heightmapStart, x
    sta groundRow
    ;ptr = screen + hudRows*40 + colIdx, ptr2 = colorRam + same
    lda #<(screen+hudRows*40)
    clc
    adc colIdx
    sta ptr
    lda #>(screen+hudRows*40)
    adc #0
    sta ptr+1
    lda #<(colorRam+hudRows*40)
    clc
    adc colIdx
    sta ptr2
    lda #>(colorRam+hudRows*40)
    adc #0
    sta ptr2+1
    ;walk down to the ground row, clearing the sky cells we pass so a
    ;refilled column never keeps terrain from its previous visit
    lda groundRow
    sec
    sbc #hudRows
    tax
    beq .drawTerrain
.advanceLoop
    ldy #0
    lda #petsciiSpace
    sta (ptr), y
    lda #vicColorLightBlue
    sta (ptr2), y
    +advance ptr, 40
    +advance ptr2, 40
    dex
    bne .advanceLoop
;draw the surface line, then the dirt below it
.drawTerrain
    ldy #0
    lda #petsciiSolidBlock
    sta (ptr), y
    lda #vicColorBrown
    sta (ptr2), y
    lda #25
    sec
    sbc groundRow
    tax
    beq .drawCoin
    +advance ptr, 40
    +advance ptr2, 40
    dex
    lda #vicColorDarkBrown
    sta dirtColor
.terrainloop
    ldy #0
    lda #petsciiSolidBlock
    sta (ptr), y
    lda dirtColor
    sta (ptr2), y
    +advance ptr, 40
    +advance ptr2, 40
    dex
    bne .terrainloop
;coin in this column?
.drawCoin
    lda scrollX
    clc
    adc colIdx
    tax
    lda coinsStart, x
    cmp #$ff
    bne .coinRowSetup
    ;a collected coin regrows when its column re-enters the world after a
    ;lap, so the score keeps climbing instead of stopping at 16
    txa
    and #%00001111
    cmp #8
    bne .done
    lda heightmapStart, x
    sec
    sbc #3
    sta coinsStart, x
    lda coinsStart, x
.coinRowSetup
    sta rowCounter
    lda #<(screen+hudRows*40)
    clc
    adc colIdx
    sta ptr3
    lda #>(screen+hudRows*40)
    adc #0
    sta ptr3+1
    lda rowCounter
    sec
    sbc #hudRows
    tax
    beq .coinPlace
.coinRowLoop
    +advance ptr3, 40
    dex
    bne .coinRowLoop
.coinPlace
    lda #<colorRam-screen
    clc
    adc ptr3
    sta ptr4
    lda #>colorRam-screen
    adc ptr3+1
    sta ptr4+1
    ldy #0
    lda #petsciiDollar
    sta (ptr3), y
    lda #vicColorYellow
    sta (ptr4), y
.done
    rts
}

;--- player physics ---
;the ground under the runner is read from the heightmap at the world column
;under the sprite. the sprite top y is 8.8 fixed point; the feet row of the
;sprite art sits on the surface line of the ground.
updatePlayer:
!zone updatePlayer {
    ;ground row under the player
    lda scrollX
    clc
    adc #playerScreenColumn
    tax
    lda heightmapStart, x
    sta groundRow
    asl ;*8
    asl
    asl
    clc
    adc #groundYOffset
    sta groundLevelHigh
    +poke groundLevelLow, 0
    lda onGround
    beq .airborne
    ;standing: stick to the ground, it may have moved under us
    +mov playerYhigh, groundLevelHigh
    +mov playerYlow, groundLevelLow
    jmp .writeSprite
.airborne
    lda playerVelocityHigh
    bpl .checkLanding
    jmp .integrate ;still rising
.checkLanding
    ;falling: land when the feet reach the surface
    lda playerYhigh
    cmp groundLevelHigh
    bcs .land
    jmp .integrate
.land
    +mov playerYhigh, groundLevelHigh
    +mov playerYlow, groundLevelLow
    +poke playerVelocityLow, 0
    +poke playerVelocityHigh, 0
    +poke onGround, 1
    jmp .writeSprite
.integrate
    ;velocity += gravity
    clc
    lda playerVelocityLow
    adc #gravity
    sta playerVelocityLow
    lda playerVelocityHigh
    adc #0
    sta playerVelocityHigh
    ;y += velocity
    clc
    lda playerYlow
    adc playerVelocityLow
    sta playerYlow
    lda playerYhigh
    adc playerVelocityHigh
    sta playerYhigh
.writeSprite
    lda playerYhigh
    sta vicSprite0positionYregister
    rts
}

tryJump:
!zone tryJump {
    lda onGround
    beq .done
    +poke onGround, 0
    +poke playerVelocityLow, 0
    +poke playerVelocityHigh, jumpVelocityHigh
    ;give the sprite an initial hop of one jump velocity step
    clc
    lda playerYlow
    adc #jumpVelocityLow
    sta playerYlow
    lda playerYhigh
    adc #jumpVelocityHigh
    sta playerYhigh
.done
    rts
}

;--- animation ---
;two run frames alternate every 8 frames while moving on the ground, the jump
;pose while in the air.
updateAnimation:
!zone updateAnimation {
    inc frameCounter
    lda onGround
    beq .jumpPose
    lda moveDirection
    beq .standPose
    lda frameCounter
    and #%00000111
    cmp #4
    bcc .frameA
    lda #runnerSpriteBlockRunB
    sta vicSprite0bitmapBlockPointerRegister
    rts
.frameA
    lda #runnerSpriteBlockRunA
    sta vicSprite0bitmapBlockPointerRegister
    rts
.jumpPose
    lda #runnerSpriteBlockJump
    sta vicSprite0bitmapBlockPointerRegister
    rts
.standPose
    lda #runnerSpriteBlockRunA
    sta vicSprite0bitmapBlockPointerRegister
    rts
}

;--- score ---
;a coin is collected when the runner is on the ground and the coin floats
;three rows above it, i.e. the runner is standing right under it.
updateScore:
!zone updateScore {
    lda onGround
    beq .done
    lda scrollX
    clc
    adc #playerScreenColumn
    tax
    lda coinsStart, x
    cmp #$ff
    beq .done
    lda groundRow
    sec
    sbc #3
    cmp coinsStart, x
    bne .done
    lda #$ff
    sta coinsStart, x
    inc score
    ;erase the coin from the screen: row groundRow-3, column playerScreenColumn
    lda groundRow
    sec
    sbc #3
    sta rowCounter
    lda #<(screen+hudRows*40)
    clc
    adc #playerScreenColumn
    sta ptr3
    lda #>(screen+hudRows*40)
    adc #0
    sta ptr3+1
    lda rowCounter
    sec
    sbc #hudRows
    tax
    beq .coinErase
.coinEraseRowLoop
    +advance ptr3, 40
    dex
    bne .coinEraseRowLoop
.coinErase
    ldy #0
    lda #petsciiSpace
    sta (ptr3), y
    lda #<(colorRam-screen)
    clc
    adc ptr3
    sta ptr4
    lda #>(colorRam-screen)
    adc ptr3+1
    sta ptr4+1
    lda #vicColorLightBlue
    sta (ptr4), y
.done
    rts
}

;--- score hud ---
;hud row 1: "SCORE nnn". the debug blocks this replaces used raw state
;values as colours, which read as random coloured squares.
drawScore:
!zone drawScore {
    ;"score" at row 1 column 1 - same one column margin as the title, so the
    ;fine scroll can never clip the first letter
    ldx #0
.scoreTextLoop
    lda scoreText, x
    beq .scoreDigits
    sta screen+40+1, x
    lda #vicColorWhite
    sta colorRam+40+1, x
    inx
    bne .scoreTextLoop
.scoreDigits
    ;score -> three decimal digits at columns 6..8
    lda score
    ldx #0 ;hundreds counter
.hundredsLoop
    cmp #100
    bcc .hundredsDone
    sbc #100
    inx
    jmp .hundredsLoop
.hundredsDone
    sta rowCounter ;remainder (<100)
    txa
    clc
    adc #48
    sta screen+40+6
    lda #vicColorYellow
    sta colorRam+40+6
    ;remainder (<100) -> tens and ones
    lda rowCounter
    ldx #0
.tensLoop
    cmp #10
    bcc .tensDone
    sbc #10
    inx
    jmp .tensLoop
.tensDone
    clc
    adc #48
    sta screen+40+8 ;ones
    lda #vicColorYellow
    sta colorRam+40+8
    txa
    clc
    adc #48
    sta screen+40+7 ;tens
    lda #vicColorYellow
    sta colorRam+40+7
    rts
}


;--- data ---
;all embedded data lives below $3700 (the cassette buffer truncation point)
hudText:
    !text "JUMP AND RUN"
    !byte $00
scoreText:
    !text "SCORE "
    !byte $00

*= heightmapStart
!src "heightmap.asm"

*= runnerSpriteSource
!src "runner.asm"

*= charsetSource
!src "charset_letters.asm"
