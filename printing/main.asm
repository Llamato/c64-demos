;Config flags
printToScreen = 1
convertToPetsciiOnTheFly = 1

*= $0801           ; Standard BASIC start memory for C64 ($0801 is 2049)

; --- BASIC Upstart Stub (10 SYS 2061) ---
    !16 next_line   ; Pointer to next line
    !16 10          ; Line number 10
    !byte $9e         ; BASIC token for SYS
    !text "2061"      ; Address of our code (Decimal: 2061 = Hex $080D)
    !byte $00         ; End of BASIC line
next_line:
    !16 $0000       ; End of BASIC program

;Hardware registers
screenRam = $400
vicBorderColorRegister = $d020

;Hardware constants
screenColumns = 40
screenRows = 25
screenSize = 1000
filenameLength = 16
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

;Kernel registers
kernelLastUsedIoId = $ba
kernelSaveDataStartPointer = $fb ;$fb:$fc
kernelIrqVector = $0314 ;$0314-0315

;Kernel rotines
kernelIrqHandler = $ea31
kernelRestoreRegistersAndReturnFromInterruptRoutine = $ea81
kernelKeyboardScanRoutine = $ea87
kernelSetLfs = $ffba
kernelSetName = $ffbd
kernelOpen = $ffc0
kernelClose = $ffc3
kernelSetInputChannel = $ffc6
kernelSetOutputChannel = $ffc9
readKernelIOstatus = $ffb7
kernelClearChannel = $ffcc
kernelGetChar = $ffcf
kernelCharOut = $ffd2
kernelCharIn = $ffcf
kernelLoad = $ffd5
kernelSave = $ffd8

;Basic rotines
basicPlot = $fff0
basicCls = $e544

;Software registers
rExtra = $02
r0 = 251
r1 = 252
r2 = 253
r3 = 254
dataBuffer = $c000
dataBufferSize = $1000

;Macros
!macro poke .addr, .value {
    lda #.value
    sta .addr
}

!macro ldi16i .addr, .value {
    +poke .addr, <.value
    +poke .addr+1, >.value
}

!macro ldi16xy .value {
    ldx #<.value
    ldy #>.value
}

!macro mov .dest, .src {
    lda .src
    sta .dest
}

!macro chrtoi .chr, .output {
    lda .chr
    sec
    sbc #'0'
    sta .output
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
!macro kinput .output {
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
    +kinput .output
}

!macro closeFileStream .logicalFileNumber {
    jsr kernelClearChannel
    lda #.logicalFileNumber
    jsr kernelClose
}

!macro openDiskFileStream .logicalFileNumber, .deviceNumber, .channel, .filenamePointer, .filenameLengthRegister {
    lda #.logicalFileNumber
    !if .deviceNumber == 0 {
        ldx kernelLastUsedIoId
    } else {
        ldx #.deviceNumber
    }
    ldy #.channel
    jsr kernelSetLfs
    lda .filenameLengthRegister
    +ldi16xy .filenamePointer
    jsr kernelSetName
    jsr kernelOpen
    bcs .error
    ldx #.logicalFileNumber
    jsr kernelSetInputChannel
    bcs .closeThenError
    jmp .done
.closeThenError:
    sta rExtra
    +closeFileStream .logicalFileNumber
    +poke vicBorderColorRegister, vicColorBlack
    jmp holdAndCatchFire
.error:
    jsr readKernelIOstatus
    sta rExtra
    +poke vicBorderColorRegister, vicColorViolet
    jmp holdAndCatchFire
.done:
}

!macro openPrinterStream .logicalFileNumber, .deviceNumber, .channel {
    lda #.logicalFileNumber
    ldx #.deviceNumber
    ldy #.channel
    jsr kernelSetLfs
    lda #0
    jsr kernelSetName
    jsr kernelOpen
    bcs .error
    ldx #.logicalFileNumber
    jsr kernelSetOutputChannel
    bcs .closeThenError
    jmp .done
.closeThenError:
    sta rExtra
    +closeFileStream .logicalFileNumber
    +poke vicBorderColorRegister, vicColorWhite
    jmp holdAndCatchFire
.error:
    jsr readKernelIOstatus
    sta rExtra
    +poke vicBorderColorRegister, vicColorYellow
    jmp holdAndCatchFire
.done
}

init:
;Switch to lowercase charset using kernel
lda #14
jsr kernelCharOut

;Prompt user for required information
+kprintln readFromText
+kprompt diskDrivePrompt, diskDriveIdContainer
+kprompt filenamePrompt, filenameContainer
stx filenameContainer+filenameLength

;Clear screen and prepare disk drive for stream read
jsr basicCls
+chrtoi diskDriveIdContainer, r0

mainloop:
jsr readFromDiskIntoBuffer
jsr writeFromBufferToPrinter
+poke vicBorderColorRegister, vicColorGreen
jmp holdAndCatchFire

!zone readFromDiskIntoBuffer {
readFromDiskIntoBuffer:
    +openDiskFileStream 8, 8, 0, filenameContainer, filenameContainer+filenameLength
    ldx #0

readLoop:
;Read char from disk
    jsr kernelGetChar
    sta dataBuffer, x
;Check disk drive status
    jsr readKernelIOstatus
    sta r0
    and #$40 ;End of file
    bne atEof
    lda r0
    bne onReadError
    inx
    bne readLoop
;Block of 256 bytes is full.
    stx rExtra
    +closeFileStream 8
    rts

;End of file has been reached
atEof:
    inx
    stx rExtra
    +closeFileStream 8
    +poke vicBorderColorRegister, vicColorLightGreen
    rts

;We have some problem reading the disk. Let's hold and catch fire.
onReadError:
    sta rExtra
    +poke vicBorderColorRegister, vicColorRed
    +closeFileStream 8
    jmp holdAndCatchFire
}

!zone writeFromBufferToPrinter {
writeFromBufferToPrinter:
    +openPrinterStream 4, 4, 7
    ldx #0

writeLoopHeader:
    cpx rExtra
    beq .done

writeLoopBody:
!if printToScreen == 1 {
    stx r0
    ldx #3 ;3 = screen
    jsr kernelSetOutputChannel
    ldx r0
    lda dataBuffer, x
    jsr kernelCharOut
    stx r0
    ldx #4 ;4 = logical file number of printer
    jsr kernelSetOutputChannel
    ldx r0
}
    lda dataBuffer, x
    jsr kernelCharOut
    inx
    jmp writeLoopHeader

.done:
    +closeFileStream 4
    rts
}

holdAndCatchFire:
jmp holdAndCatchFire ;Wait! forvever.....

readFromText:
!pet "read from: ", 0

diskDrivePrompt:
!pet "disk drive: ", 0

filenamePrompt:
!pet "filename: ", 0

printerTestString:
!pet "this is a printer test...", 0

diskDriveIdContainer:
!word 8

filenameContainer:
!fill filenameLength+1, 0