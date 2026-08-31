*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Assembly options
useKernelPrintRotines = 1

;CIA Registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d
cia1portA = $dc00 ;Bit 6 = Control port 1 paddles selected, Bit 7 = Control port 2 paddels selected.
cia1portB = $dc01
cia1ddrA = $dc02
cia1ddrB = $dc03
cia1interruptControlRegister = $dc0d

;VIC Registers
screen = $400 ;4*256 = 1024 = $400
vicInterruptControlRegister = $d011
vicRasterInterruptScanlineSelectRegister = $d012
vicAcknowlageInterruptRegister = $d019
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicScreenAndChargenMemoryPointersRegister = $d018
colorRam = $d800 ;d800-dbe7 = 1000 * 4 bit (lower byte only)

;Hardware constants
vicColorBlack = 0
vicColorWhite = 1
vicColorRed = 2
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
screenColumns = 40
screenRows = 25

;Kernel registers
kernelSaveDataStartPointer = $fb ;$fb:$fc
kernelIrqVector = $0314 ;$0314-0315

;Kernel rotines
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81
kernelGetChar = $ffcf
kernelCharOut = $ffd2
kernelSetLfs = $ffba
kernelSetName = $ffbd
kernelLoad = $ffd5
kernelSave = $ffd8

;Basic rotines
basicPlot = $fff0

;General purpose registers
rExtra = $02
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe

;Program memory
userInputBuffer = $c000
bitmapStart = $2000

;Program constants
commandPromptColumn = 0
commandPromptRow = 20
charsetSize = 4096
diskFilenameMaxLength = 16
diskFileNameExtensionLength = 3
filenameSize = diskFilenameMaxLength + diskFileNameExtensionLength +1 ;+1 traditionally for null terminator byte

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro mov .dest, .src {
    lda .src
    sta .dest
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

!macro ldi16 .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro ldi16xy .value {
    ldx #<.value
    ldy #>.value
}

!macro mov16 .dest, .src {
    +mov .dest, .src
    +mov .dest+1, .src+1
}

!macro lsl16 .result, .times {
    !for .i, 0, .times {
        asl .result
        rol .result+1
    }
}

!macro add16i .addr, .value {
    clc
    lda #<.value
    sta .addr
    lda #>.value
    sta .addr+1
}

!macro mul10 .addr {
    lda .addr
    asl ;A=.addr*2
    sta rExtra
    lda .addr
    asl ;A=.addr*2
    asl ;A=.addr*4
    asl ;A=.addr*8
    adc rExtra ;A=(.addr*8)+(.addr*2)=.addr*10
}

!macro fillMemoryBlock .start, .length, .value {
    ldx #0
    lda #.value
.loop
    sta .start, x
    inx
    cpx #.length
    bne .loop
}

!macro copyMemoryChunks .sourcePointer, .destinationPointer, .chunkCountPointer, .chunkSize {
    ldx #0 ;current chunk
    ldy #0 ;byte in current chunk
.copyByte
    cpy #.chunkSize
    beq .nextChunk
    lda (.sourcePointer), y
    sta (.destinationPointer), y
    iny
    jmp .copyByte
.nextChunk
    +add16i .sourcePointer, .chunkSize
    ldy #0
    inx
    cpx .chunkCountPointer
    bne .copyByte
}

;output: X = length of .str
!macro strlen .str {
    ldx #0
    lda .str, x
    beq .done
    inx
.done
}

!macro copyMemoryPages .source, .destination, .pageCount {
    ldx #0 ;currentByte
.loop
    !for .currentPage, 0, .pageCount {
        lda .source+256*.currentPage, x
        sta .source+256*.currentPage, x
    }
    inx
    bne .loop
}

;output: X = index of first differing character, carry set if strings match. carry clear if strings differ
!macro strcmp .str1, .str2 {
    ldx #0
.loop
    lda .str1, x
    cmp #0
    beq .loopend
    lda .str2, x
    cmp #0
    beq .loopend
    cmp .str2, x
    bne .neq
    jmp loop
.loopend
    lda .str1, x
    cmp .str2, x
    bne .neq
.eq
    sec
    ldx #0
    jmp .done
.neq
    clc
    .done
}

!macro strtoi .str, .output {
    +poke .output, 0
    ldx #0
.loop
    lda .str, x
    beq .done
    sec
    sbc #'0'
    clc
    adc #.output
    sta .output
    inx
    beq .done
    +mul10 .output
    sta .output
    jmp .loop
.done
}

!macro kprint .str {
    ldx #0
.printchar
    lda .str, x
    jsr kernelCharOut
    inx
    cmp #$00 ;Null terminator / string end
    bne .printchar
}

!macro kcrlf {
    sec ;calling basicPlot while carry bit is set means read cursor position into X and Y
    jsr basicPlot
    inx ;move to the next row
    ldy #0 ;move to the beginning of that row
    clc; calling basicPlot while carry bit is clear means move cursor to x:y position
    jsr basicPlot
}

!macro kprintln .str {
    +kprint .str
    +kcrlf
}

;output: X = length of .input
!macro input .output {
    ldx #0
.getNextChar:
    jsr kernelGetChar
    cmp #$0d ;Carriage return
    beq .done
    sta .output, x
    inx
    jmp .getNextChar
.done:
}

!macro kprompt .str, .output {
    +kprint .str
    +input .output
}

!macro gprint .str, .column, .row {
    ldx #0
.printchar
    lda .str, x
    beq .done
    sta screen+.row*screenColumns+.column, x
    inx
    jmp .printchar
.done
}

!macro gprompt .str, .column, .row, .output {
    +gprint .str, .column, .row
    +input .output
}

!macro loadFileFromDisk .logicalFileNumber, .deviceNumber, .filenamePointer, .filenameLengthRegister, .xyOrPrgAddr {
    !if .xyOrPrgAddr == 0 {
        +phx
        +phy
    }
    lda #.logicalFileNumber
    !if .deviceNumber == 0 {
        ldx $ba ;last used drive id
    } else {
        ldx #.deviceNumber
    }
    ldy #.xyOrPrgAddr
    jsr kernelSetLfs
    lda .filenameLengthRegister
    +ldi16xy .filenamePointer
    jsr kernelSetName
    !if .xyOrPrgAddr == 0 {
        +ply
        +plx
    }
    lda #0
    jsr kernelLoad
}

!macro saveFileToDisk .logicalFileNumber, .deviceNumber, .filenamePointer, .filenameLengthRegister, .dataStart, .dataEnd {
    lda #.logicalFileNumber
    !if .deviceNumber == 0 {
        ldx $ba ;last used drive id
    } 
    !else {
        ldx #.deviceNumber
    }
    ldy #1
    jsr kernelSetLfs
    lda .filenameLengthRegister
    +ldi16xy .filenamePointer
    jsr kernelSetName
    +mov16 .kernelSaveDataStartPointer, .dataStart
    lda #.kernelSaveDataStartPointer
    +ldi16xy .dataEnd
    jsr kernelSave
}

!macro setCursorPosition .column, .row {
    ldx #.column
    ldy #.row
    jsr basicPlot
}

!macro setTextDisplayMode {
    +poke $dd00, $97
    +poke $d011, $1b
    +poke $d016, $c8
    +poke $d018, $15
    +poke $d021, $f6
}

!macro setBitmapDisplayMode {
;Set VIC bank to $C000-$FFFF (bank 3)
    lda $dd00
    and #$fc
    ora #$03
    sta $dd00
    +poke $d011, (1<<5) ;Bitmap mode on
    +poke $d016, (1<<4) ;Multicolor mode off
    +poke $d018, (1<<3) ;Set screen position to 0x2000
    +poke $d021, 0
}

;Set colors
;+poke vicBorderColorRegister, vicColorLightGreen
;+poke vicBackgroundColorRegister, vicColorBlack

;Setup raster interrupt
;sei ;Disable interrupts globally
;disable CIA's
;lda #$7f ;everything except highest bit
;sta cia1ControlRegister
;sta cia2ControlRegister

;Set rasterline for interrupt to fire on
;lda #$7f
;and vicInterruptControlRegister
;sta vicInterruptControlRegister
;+poke vicRasterInterruptScanlineSelectRegister, 50

;Set IRQ handler pointer to ISR
;+ldi16 kernelIrqVector, ISR200

;Renable interrupt
;cli

;Clear input buffers
+fillMemoryBlock userInputBuffer, filenameSize*2, $00

;Prompt for charsets
!if useKernelPrintRotines == 1 {
    +setCursorPosition commandPromptColumn, commandPromptRow
    +kprintln inputCharset1promptText
    +kprompt filenamePromptText, userInputBuffer
} else {
    +gprint inputCharset1promptText, commandPromptColumn, commandPromptRow
    +gprompt filenamePromptText, commandPromptColumn, commandPromptRow+1, userInputBuffer
}

;Load charset 1
+strlen userInputBuffer
stx r0
+ldi16xy inputCharset1start
+loadFileFromDisk 1, 0, userInputBuffer, r0, 0

mainloop:
;Clear user input buffers
+fillMemoryBlock userInputBuffer, filenameSize*2, $00

;Let user input ranges to take from each charset
!if useKernelPrintRotines == 1 {
    +kprompt takeFromCharset1promptText, userInputBuffer
} else {
    +gprompt takeFromCharset1promptText, commandPromptColumn, commandPromptRow+2, userInputBuffer
}
+strtoi userInputBuffer, r0
!if useKernelPrintRotines == 1 {
    +kprompt untilPromptText, userInputBuffer+filenameSize
} else {
    +gprompt untilPromptText, commandPromptColumn, commandPromptRow+3, userInputBuffer+filenameSize
}
+strtoi userInputBuffer+filenameSize, r2

;Transfer range specified by user into destination charset
lda r2
sec
sbc r0
sta rExtra ;Calculate the range length in characters from range start and range end specified by user
+poke r1, 0 ;Clear out upper byte of input charset address buffer
+lsl16 r0, 3 ;Multiply start offset in characters by 8=(2^3) bytes per character to get starting byte
+add16i r0, inputCharset1start ;Add start address to offset. Forming the full address of the selected region in charset 1
+poke r3, 0 ;Clear out upper byte of output charset address buffer
+lsl16 r2, 3 ;Multiply end offset in characters by 8=(2^3) bytes per character to starting byte of last character
+add16i r2, outputCharsetStart ;Add start address to offset. Forming the full address of the selected region in charset 2
+copyMemoryChunks r0, r2, rExtra, 8 ;Copy the selected ranges from charset 1 and 2 into charset 3

;Update charset display (optional)
+copyMemoryPages inputCharset1start, bitmapStart, 8
+copyMemoryPages inputCharset2start, bitmapStart+screenColumns*8*7, 8
+copyMemoryPages outputCharsetStart, bitmapStart+screenColumns+8*7*2, 8

;Reset cursor
clc
+setCursorPosition commandPromptColumn, commandPromptRow
jmp mainloop

;Write result charset back to disk on user entering "done"
rts

ISR50:
sei
inc vicAcknowlageInterruptRegister
dec vicBorderColorRegister
+setBitmapDisplayMode
inc vicBackgroundColorRegister
+ldi16 kernelIrqVector, ISR200
+poke vicRasterInterruptScanlineSelectRegister, 200
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine

ISR200:
sei
inc vicAcknowlageInterruptRegister
inc vicBorderColorRegister
+setTextDisplayMode
dec vicBackgroundColorRegister
+ldi16 kernelIrqVector, ISR50
+poke vicRasterInterruptScanlineSelectRegister, 50
cli
jmp kernelRestoreRegistersAndReturnFromInterruptRoutine

inputCharset1promptText:
!pet "load input charset 1: ", 0

inputCharset2promptText:
!pet "load input charset 2: ", 0

takeFromCharset1promptText:
!pet "take from charset 1: ", 0

takeFromCharset2promptText:
!pet "take from charset 2: ", 0
 
untilPromptText:
!pet "until: ", 0

drivePromptText:
!pet "drive: ", 0

filenamePromptText:
!pet "filename: ", 0

doneText:
!pet "done", 0

inputCharset1start:
*=*+charsetSize

inputCharset2start:
*=*+charsetSize

outputCharsetStart:
*=*+charsetSize