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
visualize = 1

;CIA Registers
cia1ControlRegister = $dc0d
cia2ControlRegister = $dd0d
cia1portA = $dc00 ;Bit 6 = Control port 1 paddles selected, Bit 7 = Control port 2 paddels selected.
cia1portB = $dc01
cia1ddrA = $dc02
cia1ddrB = $dc03
cia1interruptControlRegister = $dc0d

;VIC Registers
vicScreenControl1Register = $d011
vicRasterInterruptScanlineSelectRegister = $d012
vicScreenControl2Register = $d016
vicMemoryPointersRegister = $d018
vicAcknowlageInterruptRegister = $d019
vicInterruptControlRegister = $d01a
vicBorderColorRegister = $d020
vicBackgroundColorRegister = $d021
vicScreenAndChargenMemoryPointersRegister = $d018
colorRam = $d800 ;d800-dbe7 = 1000 * 4 bit (lower byte only)

;Hardware constants
pageSize = 256
bitmapPages = 32 ;32=8192/256
vicBitmapSize = 8000
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
kernelLastUsedIoId = $ba
kernelSaveDataStartPointer = $fb ;$fb:$fc
kernelIrqVector = $0314 ;$0314-0315


;Kernel rotines
kernelIrqHandler = $ea31
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81
kernelKeyboardScanRoutine = $ea87
kernelGetChar = $ffcf
kernelCharOut = $ffd2
kernelSetLfs = $ffba
kernelSetName = $ffbd
kernelLoad = $ffd5
kernelSave = $ffd8

;Basic rotines
basicPlot = $fff0
basicCls = $e544

;Basic constants
basicBytesFree = 38911

;General purpose registers
rExtra = $02
r0 = $fb
r1 = $fc
r2 = $fd
r3 = $fe

;Program constants
bitmapRasterline = 50
textRasterline = 210
commandPromptColumn = 0
commandPromptRow = 20
charSize = 8
charsetSize = 2048
charromSize = 4096
bitmapSize = 8192
charsetPages = 8 ;8=256/8
charsPerCharset = 256
diskFilenameMaxLength = 16
diskFileNameExtensionLength = 3
filenameSize = diskFilenameMaxLength + diskFileNameExtensionLength +1 ;+1 traditionally for null terminator byte

;Program memory
userInputBuffer = $c000
bitmapStart = $2000
textScreen = $400 ;4*256 = 1024 = $400
inputCharset1start = bitmapStart
inputCharset2start = bitmapStart+charsetSize
outputCharsetStart = bitmapStart+charsetSize*2
outputCharsetEnd = outputCharsetStart+charsetSize
inputCharrom1loadinAddress = bitmapStart+bitmapSize
inputCharrom2loadinAddress = bitmapStart+bitmapSize*2

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
    !for .i, 1, .times {
        asl .result
        rol .result+1
    }
}

!macro add16 .accumulator, .additive {
    clc
    lda .accumulator
    adc .additive
    sta .accumulator
    lda .accumulator+1
    adc .additive+1
    sta .accumulator+1
}

!macro add16i .addr, .value {
    clc
    lda #<.value
    adc .addr
    sta .addr
    lda #>.value
    adc .addr+1
    sta .addr+1
}

!macro sub16 .minuend, .subtrahend {
    sec
    lda .minuend
    sbc .subtrahend
    sta .minuend
    lda .minuend+1
    sbc .subtrahend+1
    sta .minuend+1
}

!macro sub16i .addr, .value {
    sec
    lda .addr
    sbc #<.value
    sta .addr
    lda .addr+1
    sbc #>.value
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
    clc
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
    +add16i .destinationPointer, .chunkSize
    ldy #0
    inx
    cpx .chunkCountPointer
    bne .copyByte
}

!macro fillMemoryPages .start, .pageCount, .value {
    ldx #0 ;currentByte
    lda #.value
.loop
    !for .currentPage, 0, .pageCount {
        sta .start+pageSize*.currentPage, x
    }
    inx
    bne .loop
}

!macro copyMemoryPages .source, .destination, .pageCount {
    ldx #0 ;currentByte
.loop
    !for .currentPage, 0, .pageCount {
        lda .source+pageSize*.currentPage, x
        sta .destination+pageSize*.currentPage, x
    }
    inx
    beq .done
    jmp .loop
.done
}

;output: X = length of .str
!macro strlen .str {
    ldx #0
.loop:
    lda .str, x
    beq .done
    inx
    jmp .loop
.done
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
    lda .str1, x
    cmp .str2, x
    bne .neq
    inx
    jmp .loop
.loopend
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
    sbc #'0'          ; A = digit value (0-9)
    tay               ; stash digit
    +mul10 .output    ; A = .output * 10  (using OLD output)
    sta .output
    tya
    clc
    adc .output        ; add the digit to output*10
    sta .output
    inx
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
    cpx #screenRows-1
    beq .scrollScreen
    inx ;move to the next row
    ldy #0 ;move to the beginning of that row
    clc; calling basicPlot while carry bit is clear means move cursor to x:y position
    jsr basicPlot
    jmp .done
.scrollScreen
    ldy #0
    clc
    jsr basicPlot
.done
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

!macro loadFileFromDisk .logicalFileNumber, .deviceNumber, .filenamePointer, .filenameLengthRegister, .xyOrPrgAddr {
    !if .xyOrPrgAddr == 0 { ; 0= Take address to load into from x and y registers, 1 = take address from prg file.
        +phx
        +phy
    }
    lda #.logicalFileNumber
    !if .deviceNumber == 0 {
        ldx kernelLastUsedIoId
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
        ldx kernelLastUsedIoId
    } else {
        ldx #.deviceNumber
    }
    ldy #1
    jsr kernelSetLfs
    lda .filenameLengthRegister
    +ldi16xy .filenamePointer
    jsr kernelSetName
    +ldi16 kernelSaveDataStartPointer, .dataStart
    +ldi16xy .dataEnd
    lda #kernelSaveDataStartPointer
    jsr kernelSave
}

!macro setCursorPosition .column, .row {
    clc
    ldx #.row
    ldy #.column
    jsr basicPlot
}

!macro setTextDisplayMode {
    +poke vicScreenControl1Register, $1b
    +poke vicScreenControl2Register, $c8
    +poke vicMemoryPointersRegister, $15
}

!macro setBitmapDisplayMode {
    +poke vicScreenControl1Register, $1b | (1<<5) ;Bitmap mode on
    +poke vicScreenControl2Register, $c8 & ((1<<4) xor $ff) 
    +poke vicMemoryPointersRegister, (1<<3) | (1<<4) ;Set bitmap position to 0x2000 and keep screen at $0400
}

;Clear input buffers
+fillMemoryBlock userInputBuffer, filenameSize*4, $00

;Clear text screen
jsr basicCls ;cls = clear last screen

;Clear bitmap memory
+fillMemoryPages bitmapStart, bitmapPages, $00

;Reset cursor
+setCursorPosition commandPromptColumn, commandPromptRow

;Prompt for first charset
+setCursorPosition commandPromptColumn, commandPromptRow
+kprintln inputCharset1promptText
+kprompt filenamePromptText, userInputBuffer
+kcrlf
+kprompt charsetSelectionPromptText, userInputBuffer+filenameSize
+kcrlf

;Prompt for second charset
jsr basicCls
+setCursorPosition commandPromptColumn, commandPromptRow
+kprintln inputCharset2promptText
+kprompt filenamePromptText, userInputBuffer+filenameSize*2
+kcrlf
+kprompt charsetSelectionPromptText, userInputBuffer+filenameSize*3
+kcrlf

;Load first charrom
+strlen userInputBuffer
stx r0
+ldi16xy inputCharrom1loadinAddress+2
+loadFileFromDisk 1, 0, userInputBuffer, r0, 0

;Load second charrom
+strlen userInputBuffer+filenameSize*2
stx r0
+ldi16xy inputCharrom2loadinAddress+2
+loadFileFromDisk 1, 0, userInputBuffer+filenameSize*2, r0, 0

;Load first or second charset from first charrom?
;If we are to load the second charset then we have already done so, since the kernel routine can only load whole files.
;Therefor we can load the second charset into the correct memory location by copying it over the first charset.
lda userInputBuffer+filenameSize
cmp #'1'
bne replaceFirstCharst
jmp skipFirstCharsetReplace
replaceFirstCharst:
+copyMemoryPages inputCharrom1loadinAddress+charsetSize, bitmapStart, charsetPages
jmp selectSecondCharset
skipFirstCharsetReplace:
+copyMemoryPages inputCharrom1loadinAddress, bitmapStart, charsetPages

selectSecondCharset:
lda userInputBuffer+filenameSize*3
cmp #'1'
bne replaceSecondCharset
jmp skipSecondCharsetReplace
replaceSecondCharset:
+copyMemoryPages inputCharrom2loadinAddress+charsetSize, bitmapStart+charsetSize, charsetPages
jmp clearOutputCharsetBitmap
skipSecondCharsetReplace:
+copyMemoryPages inputCharrom2loadinAddress, bitmapStart+charsetSize, charsetPages

clearOutputCharsetBitmap:
+fillMemoryPages outputCharsetStart, charsetPages, $00

!if visualize == 1 {
    sei ;Disable interrupts globally

    ;Disable CIA's
    lda #$7f ;everything except highest bit
    sta cia1ControlRegister
    ;sta cia2ControlRegister

    ;Set rasterline for interrupt to fire on
    lda vicInterruptControlRegister
    ora #$01
    ora vicInterruptControlRegister
    sta vicInterruptControlRegister
    +poke vicRasterInterruptScanlineSelectRegister, bitmapRasterline

    ;Set IRQ handler pointer to ISR
    +mov16 kernelIrqInitialState, kernelIrqVector
    +ldi16 kernelIrqVector, ISRtext

    cli ;Renable interrupt
}

mainloop:
!if visualize == 1 {
    ;Set colors
    +fillMemoryBlock textScreen, 0, vicColorWhite
    +fillMemoryBlock textScreen+pageSize, 0, vicColorGreen
    +fillMemoryBlock textScreen+pageSize*2, 0, vicColorViolet
}
;Clear user input buffers
+fillMemoryBlock userInputBuffer, filenameSize*2, $00

;Let user input ranges to take from first charset
+kprompt takeFromCharset1promptText, userInputBuffer
+strcmp userInputBuffer, saveText
bcs saveOutputCharsetToDisk
+strtoi userInputBuffer, r0
+kprompt untilPromptText, userInputBuffer+filenameSize
+strcmp userInputBuffer+filenameSize, saveText
bcs saveOutputCharsetToDisk
+kcrlf
+strtoi userInputBuffer+filenameSize, r2

;Transfer selected range into destination charset
ldx #'0'
jsr copyFromCharset

;Clear user input buffers
+fillMemoryBlock userInputBuffer, filenameSize*2, $00

;Let user input ranges to take from second charset
+kprompt takeFromCharset2promptText, userInputBuffer
+strcmp userInputBuffer, saveText
bcs saveOutputCharsetToDisk
+strtoi userInputBuffer, r0
+kprompt untilPromptText, userInputBuffer+filenameSize
+strcmp userInputBuffer+filenameSize, saveText
bcs saveOutputCharsetToDisk
+kcrlf
+strtoi userInputBuffer+filenameSize, r2

;Transfer selected range into destination charset
ldx #'1'
jsr copyFromCharset

;Clear screen
jsr basicCls ;cls = clear last screen

;Reset cursor
+setCursorPosition commandPromptColumn, commandPromptRow

;16 bit compare between currentOutputCharacterOffset and charsetSize. If  charsetSize < currentOutputCharacterOffset then goto continue else goto saveOutputCharsetToDisk
lda currentOutputCharacterOffset+1
cmp #>charsetSize
bcc continue                 ; high byte less -> definitely not full, continue
bne saveOutputCharsetToDisk  ; high byte greater (not equal, not less) -> definitely full
lda currentOutputCharacterOffset
cmp #<charsetSize
bcc continue                  ; high bytes equal, low byte less -> not full
jmp saveOutputCharsetToDisk   ; or just fall through / jsr, depending on layout

continue:
jmp mainloop

saveOutputCharsetToDisk:
;Clear user input buffers
+fillMemoryBlock userInputBuffer, filenameSize, $00

;Prompt user for save file
+kprompt saveToPromptText, userInputBuffer
+strlen userInputBuffer
stx rExtra

;Reset graphics modes and interrupt states for disk timing
!if visualize = 1 {
    sei ;Disable interrupts globally

    ;Renable cia
    +mov cia1ControlRegister, cia1InitialSate

    ;Disable Vic interrupt
    lda vicInterruptControlRegister
    and #$fe
    sta vicInterruptControlRegister

    ;Set IRQ handler pointer to kernel ISR
    +mov16 kernelIrqVector, kernelIrqInitialState

    ;Reject graphics go back to text
    +setTextDisplayMode

    cli ;Renable interrupt
}

+saveFileToDisk 2, 0, userInputBuffer, rExtra, outputCharsetStart, outputCharsetEnd

;End of program
+kcrlf
+kprintln programCompletedText
+kprintln restartComputerText
holdAndCatchFire:
jmp holdAndCatchFire

ISRbitmap:
sei
lda #$01
ora vicAcknowlageInterruptRegister
sta vicAcknowlageInterruptRegister
+setBitmapDisplayMode
+ldi16 kernelIrqVector, ISRtext
+poke vicRasterInterruptScanlineSelectRegister, textRasterline
cli
jmp kernelIrqHandler

ISRtext:
sei
lda #$01
ora vicAcknowlageInterruptRegister
sta vicAcknowlageInterruptRegister
+setTextDisplayMode
+ldi16 kernelIrqVector, ISRbitmap
+poke vicRasterInterruptScanlineSelectRegister, bitmapRasterline
cli
jmp kernelIrqHandler

;r0 = From character
;r2 = Until character
;X = first or second charset as input ('1' or '0')
copyNothing:
rts

copyFromCharset:
lda r2
sec
sbc r0
clc
;adc #1
cmp #0
beq copyNothing
sta rExtra ;rExtra = r2-r0 = until-from = length of range
+poke r1, 0 ; free r0:r1 high byte for input charset address + from Character offset
+lsl16 r0, 3 ;r0:r1 = r0*2^3 = r0*8
cpx #'1'
beq inputIsSecondCharset
inputIsFirstCharset:
+add16i r0, inputCharset1start ;r0:r1 = inputCharset1start+r0*8
jmp copyChars
inputIsSecondCharset:
+add16i r0, inputCharset2start ;r0:r1 = inputCharset2start+r0*8
copyChars:
+ldi16 r2, outputCharsetStart
+add16 r2, currentOutputCharacterOffset ;r2:r3 = outputCharsetStart + currentOutputCharacterOffset
+copyMemoryChunks r0, r2, rExtra, charSize ;perform copy with r2:r3 becoming = outputCharsetStart + currentOutputCharacterOffset + bytesCopied
+sub16i r2, outputCharsetStart ;r2:r3 = currentOutputCharacterOffset + bytesCopied
+mov16 currentOutputCharacterOffset, r2 ;currentOutputCharacterOffset = currentOutputCharacterOffset + bytesCopied
rts

currentOutputCharacterOffset:
!word 0

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

charsetSelectionPromptText:
!pet "charset in rom (1 or 2): ", 0

saveText:
!pet "save", 0

saveToPromptText:
!pet "save to: ", 0

programCompletedText:
!pet "the program is completed", 0

restartComputerText:
!pet "please restart your computer", 0

cia1InitialSate:
!byte %10000001 

kernelIrqInitialState:
!word 0