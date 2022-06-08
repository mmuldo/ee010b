;;;;;;;;;;;;;;;
; display.asm ;
;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for the LED grid display including.
;
; Data Memory
; -----------
; redBuffer: NUM_ROWS x NUM_COLS boolean matrix; the current on states of 
;   the red LED grid
; greenBuffer: NUM_ROWS x NUM_COLS boolean matrix; the current on states of
;   the green LED grid
; ledBufferOffset: for display multiplexor: offset from 
;   ledBuffer that determines which column in 
;   the ledBuffer matrix to use for writing the 
;   rows of the display
; columnMaskG: for display multiplexor: 1-hot byte (in 
;   conjunction with columnMaskR) that 
;   determines which column of LEDs to write.
; columnMaskR: for display multiplexor: 1-hot byte (in 
;   conjunction with columnMaskG) that 
;   determines which column of LEDs to write
; useCursorColor2: when False, use color1 for cursor
;   when True use color2 for cursor
; cursorChangeCounter: when this hits 0, change the cursor color
; cursorRow: Row of display in which cursor resides
; cursorColumn: Row of display in which column resides
; cursorColor1: color for first blink of cursor
; cursorColor2: color for second blink of cursor
; 
;
; Tables
; ------
; ColorToRGTab: maps OFF, RED, GREEN, YELLOW to (red, green) on states
;
; Routines
; --------
; InitDisplayVars: inits display shared vars
; ClearDisplay: turns all LEDs off
; SetCursor: blinks a pixel in the grid between 2 specified colors
;   (indicating the cursor is at that position)
; PlotPixel: sets a pixel in the grid to a specified color
; MultiplexDisplay: cycles through which column to display
; PlotImage: plots image from specified location in program memory
;
; Revision History
; ----------------
; 05/07/2022    Matt Muldowney      dseg and multiplexing logic
; 05/08/2022    Matt Muldowney      revised functional specs
; 05/09/2022    Matt Muldowney      implemented ClearDisplay, PlotPixel,
;                                       SetCursor
; 05/11/2022    Matt Muldowney      minor bug fixes (mostly related to
;                                       unbalanced push/pop in functions)
; 05/14/2022    Matt Muldowney      docs
; 05/31/2022    Matt Muldowney      PlotImage
; 06/03/2022    Matt Muldowney      refactored each routine (functionally the same)

.dseg
    redBuffer:            .byte NUM_COLS
    greenBuffer:          .byte NUM_COLS

    ledBufferOffset:      .byte 1
    columnMaskG:          .byte 1
    columnMaskR:          .byte 1

    useCursorColor2:      .byte 1
    cursorChangeCounter:  .byte 1

    cursorRow:            .byte 1
    cursorColumn:         .byte 1

    cursorColor1:         .byte 1
    cursorColor2:         .byte 1



.cseg


; ColorToRGTab(color)
; ===================
;
; Description
; -----------
; Maps a color to a tuple of booleans indicating (greenOn, redOn).
; The mapping is:
;   OFF     -> FALSE, FALSE
;   RED     -> FALSE, TRUE
;   GREEN   -> TRUE,  FALSE
;   YELLOW  -> TRUE,  TRUE
ColorToRGTab:
    .db   FALSE,  FALSE   ; OFF
    .db   FALSE,  TRUE    ; RED
    .db   TRUE,   FALSE   ; GREEN
    .db   TRUE,   TRUE    ; YELLOW



; InitDisplayVars()
; =================
;
; Description
; -----------
; Initializes shared variables used for the LED display
;
; Operational Description
; -----------------------
; Sets shared variables to their initial values.
;
; Arguments
; ---------
; None
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer (NUM_ROWS x NUM_COLS boolean matrix): W
; greenBuffer (NUM_ROWS x NUM_COLS boolean matrix): W
; ledBufferOffset (int): W
; columnMaskG (NUM_ROWS bit string): W
; columnMaskR (NUM_ROWS bit string): W
; cursorRow (int): W
; cursorColumn (int): W
; cursorColor1 (bool): W
; cusorColor2 (bool): W
;
; Local Variables
; ---------------
; r16: temp register for loading to memory/outting to i/o
; r17-r19: for SetCursor arguments
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; Error Handling
; --------------
; None
;
; Algorithms
; ----------
; None
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; None
;
; Stack Depth
; --------------
; 10 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
InitDisplayVars:
    push    r16
    push    r17
    push    r18
    push    r19

    ; turn off all LEDs so that we start with a blank display
    rcall   ClearDisplay

    ; init buffer offset (for display mux)
    ldi     r16, BUFF_OFFSET_INIT
    sts     ledBufferOffset, r16
    
    ; init column masks (for display mux)
    ldi     r16, COL_MASK_G_INIT
    sts     columnMaskG, r16
    ldi     r16, COL_MASK_R_INIT
    sts     columnMaskR, r16
    
    ; init cursor change counter
    ldi     r16, CURSOR_COUNTER_INIT
    sts     cursorChangeCounter, r16

    ; init which color cursor starts on
    ldi     r16, USE_CURSOR_COLOR2_INIT
    sts     useCursorColor2, r16

    ; init cursor position (should be off grid so that we don't
    ;   initially see the cursor) and colors
    ldi     r16, CURSOR_ROW_INIT
    ldi     r17, CURSOR_COL_INIT
    ldi     r18, CURSOR_COLOR1_INIT
    ldi     r19, CURSOR_COLOR2_INIT
    rcall   SetCursor

    pop     r19
    pop     r18
    pop     r17
    pop     r16
    ret




; ClearDisplay()
; ==============
;
; Description
; -----------
; clears the LED display such that all LEDS are off.
; doesn't affect cursor.
;
; Operational Description
; -----------------------
; Sets all columns in the buffer to OFF
;
; Arguments
; ---------
; None
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer (NUM_ROWS x NUM_COLS boolean matrix): W
; greenBuffer (NUM_ROWS x NUM_COLS boolean matrix): W
;
; Local Variables
; ---------------
; offReg: holds OFF
; idx: loop counter
; y: redBuffer poiner
; z: greenBuffer poiner
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; Error Handling
; --------------
; None
;
; Algorithms
; ----------
; None
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; none
;
; Stack Depth
; -----------
; 6 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
ClearDisplay:
    push    r16
    push    r17
    push    yl
    push    yh
    push    zl
    push    zh

    ; just holds OFF
    .def    offReg = r16
    ldi     offReg, OFF

    ; loop index
    .def    idx = r17

    ; y: redBuffer
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)
    ; z: greenBuffer
    ldi     zl, low(greenBuffer)
    ldi     zh, high(greenBuffer)


    ; initialize loop var to NUM_COLS
    ldi     idx, NUM_COLS
  ClearBuffersLoop:
    ;;; turn off every column in red and green buffers
    st      y+, offReg
    st      z+, offReg
    dec     idx
    ; keep looping until idx hits 0
    brne    ClearBuffersLoop

    ;;; return
    pop zh
    pop zl
    pop yh
    pop yl
    pop r17
    pop r16
    ret




; SetCursor(row, column, color1, color2)
; ======================================
;
; Description
; -----------
; Sets the pixel at row, column of the display grid to blink between
; color1 and color2, switching every CURSOR_COUNTER_INIT number of Timer0
; interrupts. This indicates to the user
; that the cursor is located at row, column. The possible colors are
; OFF, RED, GREEN, and YELLOW.
;
; Operational Description
; -----------------------
; Sets cursorRow to row, cursorColumn to column, cursorColor1 to color1, and
; cursorColor2 to color2.
;
; Arguments
; ---------
; row (int, r16): row of the display (between 0 and NUM_ROWS-1)
; column (int, r17): column of the display (between 0 and NUM_COLS-1)
; color1 (int, r18): first color for the cursor to blink; can be
;   OFF, RED, GREEN, YELLOW
; color2 (int, r18): second color for the cursor to blink; can be
;   OFF, RED, GREEN, YELLOW
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; cursorRow (int): W
; cursorColumn (int): W
; cursorColor1 (int): W
; cursorColor2 (int): W
;
; Local Variables
; ---------------
; none
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; Error Handling
; --------------
; if row or column is outside of 0 and 7:
;   this is fine: in fact, we use this to "unset" the cursor (such that
;   no pixel on the display is blinking)
; if c1 or c2 is outside of OFF and YELLOW:
;   then we return without doing anything
;
; Algorithms
; ----------
; None
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; none
;
; Stack Depth
; -----------
; 3 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
SetCursor:
    ;;; arguments
    ; row for cursor
    .def    row = r16
    ; column for cursor
    .def    column = r17
    ; first color for cursor to blink
    .def    color1 = r18
    ; second color for cursor to blink
    .def    color2 = r19
    
    ;;; argument validity checks
    ; OFF <= color1 <= YELLOW
    withinBounds  color1, OFF, YELLOW
    brtc    SetCursorReturn

    ; OFF <= color2 <= YELLOW
    withinBounds  color2, OFF, YELLOW
    brtc    SetCursorReturn


    ;;; set the (row, column) position of the cursor
    sts     cursorRow, row
    sts     cursorColumn, column

    ;;; set cursorColor1, cursorColor2
    sts     cursorColor1, color1
    sts     cursorColor2, color2
    
  SetCursorReturn:
    ret




; PlotPixel(row, column, color)
; =============================
;
; Description
; -----------
; Sets the pixel at row, column of the display grid to the specied color
; (OFF, RED, GREEN, YELLOW).
;
; Operational Description
; -----------------------
; Converts color to (red, green) on states, then sets redBuffer[row, column]
; and greenBuffer[row, column] according to these on states.
;
; Arguments
; ---------
; row (int, r16): row of the display (between 0 and NUM_ROWS-1)
; column (int, r17): column of the display (between 0 and NUM_COLS-1)
; color (int, r18): color for pixel at row, column (OFF, RED, GREEN, YELLOW)
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer (NUM_ROWS x NUM_COLS bool matrix): W
; greenBuffer (NUM_ROWS x NUM_COLS bool matrix): W
;
; Local Variables
; ---------------
; zero: holds 0
; redOn: red on state corresponding to color
; greenOn: green on state corresponding to color
; ledOn: red/green on state we're currently checking
; bufferRowVector: holds row vector for current (red/green) buffer
; loopCounter: for looping twice
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; Error Handling
; --------------
; row < 0 or row >= NUM_ROWS:
;   return without doing anything
; column < 0 or column >= NUM_COLS:
;   return without doing anything
; color < OFF or color > YELLOW:
;   return without doing anything
;
; Algorithms
; ----------
; None
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; none
;
; Stack Depth
; -----------
; 8 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
PlotPixel:
    push    r19
    push    r20
    push    r21
    push    r22
    push    r23
    push    yl
    push    yh

    ;;; arguments
    ; row on display
    .def    row = r16
    ; column on display
    .def    column = r17
    ; color to set at buffer[r, c]
    .def    color = r18
    
    ;;; other registers needed
    ; for storing red, green LED on states of color
    .def    redOn = r19
    .def    greenOn = r20
    ; for current LED (red/green) we are checking (for loop)
    .def    ledOn = r21

    ; for updating buffer
    .def    bufferRowVector = r22

    ; for loop
    .def    loopCounter = r23

    ; for holding zero for adc
    ; reuse r19 because don't need this at the same time as redOn
    .def    zero = r19
    

    ;;; check validity of (row,column), return if invalid
    ; must have 0 <= row <= NUM_ROWS
    withinBounds    row, 0, NUM_ROWS
    brtc    PlotPixelReturnDetour
    ; must have 0 <= column <= NUM_COLS
    withinBounds    column, 0, NUM_COLS
    brtc    PlotPixelReturnDetour

    ;;; check validity of color, return if invalid
    withinBounds    color, OFF, YELLOW
    brtc    PlotPixelReturnDetour
    jmp     PlotPixelGetOnStates

  PlotPixelReturnDetour:
    ;;; need this because the brtc's are out of range of PlotPixelReturn
    jmp     PlotPixelReturn


  PlotPixelGetOnStates:
    ;;; the on states of red, green LEDS
    colorToRG   color, greenOn, redOn


    ;;; loop the following for red and green, since setting 
    ;;;   redBuffer[row, column] = redOn
    ;;;   and greenBuffer[row, column] = greenOn use the same logic
    ; initialize loop counter to 2 (since we're just running twice)
    ldi     loopCounter, 2
    ; start with redBuffer[row, column]
    mov     ledOn, redOn
    ; put y at redBuffer
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)
  PlotPixelLoop:
    ; adjust pointer by column
    clr     zero
    add     yl, column
    adc     yh, zero

    ; get the row vector at buffer[column]
    ld      bufferRowVector, y

    ; check if LED should be on
    cpi     ledOn, TRUE
    ; set buffer[row, column] according to z flag
    setBitToZ   bufferRowVector, row

    ; store updated rowVector back in buffer[column]
    st      y, bufferRowVector

    ; dec loop counter and check if we should exit
    dec     loopCounter
    breq    PlotPixelReturn
    ; if not done, next iteration is for greenBuffer[row, column]
    mov     ledOn, greenOn
    ; put y at greenBuffer
    ldi     yl, low(greenBuffer)
    ldi     yh, high(greenBuffer)
    ; and loop
    jmp     PlotPixelLoop

  PlotPixelReturn:
    pop     yh
    pop     yl
    pop     r23
    pop     r22
    pop     r21
    pop     r20
    pop     r19
    ret




; MultiplexDisplay()
; ==================
;
; Description
; -----------
; This is an event handler responsible for multiplxing the LED display (i.e.
; turning on the columns one at a time and writing the corresponding column
; in the buffer to the rows). It is called once very Timer0 interrupt.
;
; Operational Description
; -----------------------
; The LED mux first turns off all columns of the display. Then, using the
; current offset, it writes the row ports of the display and increments,
; the offset. Then, using a 1-hot column mask, it writes the corresponding
; column port (taking into account if a pixel should be blinked based on
; SetCursor) and rotates the column mask right. (Obviously, the offset and
; the column mask should line up such that we write the correct column to the
; correct place).
;
; Arguments
; ---------
; None
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer (NUM_ROWS x NUM_COLS bool matrix): R
; greenBuffer (NUM_ROWS x NUM_COLS bool matrix): R
; cursorChangeCounter (int): RW
; useCursorColor2 (bool): RW
; cursorRow (int): R
; cursorColumn (int): R
; cursorColor1 (int): R
; cursorColor2 (int): R
;
; Local Variables
; ---------------
; cursorColor: holds cursor color 1/2
; cursorRed: current red on state of cursor
; cursorGreen: current green on state of cursor
; cursorBit: red/green on state of cursor we're checking
; colMaskGReg: holds columnMaskG
; colMaskRReg: holds columnMaskR
; cursorColumnReg: holds cursorColumn
; cursorRowReg: holds cursorRow
; rowVector: row vector for current buffer[column]
;
; Inputs
; ------
; None
;
; Outputs
; -------
; PortA: green columns of LED grid
; PortC: rows of LED grid
; PortD: red columns of LED grid
;
; Error Handling
; --------------
; None
;
; Algorithms
; ----------
; Loops through the 16 columns of display
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; none
;
; Stack Depth
; -----------
; 11 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
MultiplexDisplay:
    push        r16
    push        r17
    push        r18
    push        r19
    push        r20
    push        r21
    push        yl
    push        yh

    ;;; before we start, turn all columns off
    ldi         r16, OFF
    out         porta, r16
    out         portd, r16

    ;;; registers needed
    ; for loading current cursor color
    .def        cursorColor = r16
    ; indicates if current cursor's green LED is on
    .def        cursorRed = r17
    ; indicates if current cursor's red LED is on
    .def        cursorGreen = r18
    ; holds the cursor LED on state (cursorRed or cursorGreen) 
    ;   we are using (reuse r16 since by the time we need this 
    ;   we won't need cursorColor)
    .def        cursorBit = r16

    ; holds the column masks columnMaskG and columnMaskR
    .def        colMaskGReg = r19
    .def        colMaskRReg = r21

    ; for loading ledBufferOffset (reuse r17 since by the time we
    ;   need this we won't need cursorRed)
    .def        bufferOffsetReg = r17

    ; for holding 0 (for 16-bit + 8-bit) (reuse r18 since by the time we
    ;   need this we won't need cursorRed)
    .def        zero = r18

    ; for comparing buffer offset to cursor's column (reuse r18 since we
    ;   don't need zero at the same time we need this)
    .def        cursorColumnReg = r18
    ; for setting/clearing rowVector[cursorRow] according to cursor when
    ;   we're on the cursor's column (reuse r18 since we don't need
    ;   cursorColumnReg at the same time we need this)
    .def        cursorRowReg = r18

    ; for holding the current column's corresponding row vector
    .def        rowVector = r20

    ;;; get current cursor color
    ; check if we are using color1 or color2 for cursor
    toggleOn0   useCursorColor2, cursorChangeCounter, CURSOR_COUNTER_INIT

    ; z = !useCursorColor2
    brne        MultiplexDisplayUseCursorColor2
    lds         cursorColor, cursorColor1
    jmp         MultiplexDisplayGetCursorRG
  MultiplexDisplayUseCursorColor2:
    lds         cursorColor, cursorColor2

  MultiplexDisplayGetCursorRG:
    ; convert cursor color to its red/green on states
    colorToRG   cursorColor, cursorGreen, cursorRed

    ;;; determine if we're on a red or green column
    ; use columnMaskG to determine where we are
    lds         colMaskGReg, columnMaskG
    lds         colMaskRReg, columnMaskR
    tst         colMaskGReg
    ; if the 1 is not in columnMaskG, load red
    breq        MultiplexDisplayLoadRed
    ; otherwise, load green
    ldi         yl, low(greenBuffer)
    ldi         yh, high(greenBuffer)
    mov         cursorBit, cursorGreen
    jmp         MultiplexDisplayGetColumn
  MultiplexDisplayLoadRed:
    ldi         yl, low(redBuffer)
    ldi         yh, high(redBuffer)
    mov         cursorBit, cursorRed

  MultiplexDisplayGetColumn:
    ;;; get row vector for the column we're on to display
    ; adjust y by offset (so that we're at the right column)
    lds         bufferOffsetReg, ledBufferOffset
    clr         zero
    add         yl, bufferOffsetReg
    adc         yh, zero
    ; load in column's row vector
    ld          rowVector, y

    ;;; see if we need to adjust rowVector based on cursor
    ; check if current column is cursor's column
    lds         cursorColumnReg, cursorColumn
    cp          cursorColumnReg, bufferOffsetReg
    ; if it isn't skip the cursor setting logic
    brne        MultiplexDisplayOutColumn
    ; otherwise, if it is, set rowVector[cursorRow] = cursorBit
    lds         cursorRowReg, cursorRow
    ; check if cursorBit is TRUE to see if we want to set
    ;   or clear rowVector[cursorRowReg]
    cpi         cursorBit, TRUE
    ; set/clear rowVector[cursorRowReg] according to z flag
    setBitToZ   rowVector, cursorRowReg

  MultiplexDisplayOutColumn:
    ; output the row vector
    out         portc, rowVector


    ;;; inc led buffer offset (the indexer) and reinit if necessary
    inc         bufferOffsetReg
    ; check if bufferOffset exceeds the max column index
    cpi         bufferOffsetReg, NUM_COLS
    ; if it doesn't, leave buffer offset incremented
    brne        MultiplexDisplayStoreBufferOffset
    ; otherwise, reinit the buffer offset
    ldi         bufferOffsetReg, BUFF_OFFSET_INIT
  MultiplexDisplayStoreBufferOffset:
    sts         ledBufferOffset, bufferOffsetReg


    ;;; output column masks to their respective ports
    ; green -> port a
    out         porta, colMaskGReg
    ; red -> port d
    out         portd, colMaskRReg

    ;;; rotate column masks
    ; if green column mask is in its final state...
    cpi         colMaskGReg, COL_MASK_G_FINAL
    brne        MultiplexDisplayRotateColumnMasks
    ; and if red column mask is in its final state...
    cpi         colMaskRReg, COL_MASK_R_FINAL
    brne        MultiplexDisplayRotateColumnMasks
    ; then reinit the column masks
    ldi         colMaskGReg, COL_MASK_G_INIT
    ldi         colMaskRReg, COL_MASK_R_INIT
    jmp         MultiplexDisplayStoreColumnMasks

  MultiplexDisplayRotateColumnMasks:
    lsr         colMaskGReg
    rol         colMaskRReg

  MultiplexDisplayStoreColumnMasks:
    sts         columnMaskG, colMaskGReg
    sts         columnMaskR, colMaskRReg


    pop        yh
    pop        yl
    pop        r21
    pop        r20
    pop        r19
    pop        r18
    pop        r17
    pop        r16

    ret



; PlotImage(ptr)
; =======================
;
; Description
; -----------
; Plots the specified image at ptr (passed in through Z register; 16 bytes 
; in program memory). These bytes are the column data for the image, with
; 8 red columns (starting with the left most) interleaved with eight
; green columns (starting with the left most); i.e. the first byte
; is the left-most red column, the second byte is the left-most green
; column, etc.
;
; Operational Description
; -----------------------
; Loops 16 times starting at ptr, using loop var n (initialized to 0).
; When n is even, redBuffer[n/2] = ptr[n]; when n is odd,
; greenBuffer[(n-1)/2] = ptr[n].
;
; Arguments
; ---------
; ptr (16 x 8-bit array, z): program memory location of image to plot
;
; Return Values
; -------------
; None
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer: W
; greenBuffer: W
;
; Local Variables
; ---------------
; n: loop var
; numLoops: number of times to loop
; currentCol: current column we're loading
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; Error Handling
; --------------
; None
;
; Algorithms
; ----------
; None
;
; Data Structures
; ---------------
; None
;
; Registers Used
; --------------
; z
;
; Stack Depth
; -----------
; 10 bytes
;
; Limitations
; -----------
; None
;
; Known Bugs
; ----------
; None
;
; Special Notes
; -------------
; None
PlotImage:
    push    r16
    push    r17
    push    r18
    push    xl
    push    xh
    push    yl
    push    yh

    ;;; arguments
    ; arguments pushed out of convenience to caller
    ; ptr = z
    push    zl
    push    zh


    ;;; other registers needed
    ; loop var
    .def    n = r16
    clr     n

    ; number of times to loop register
    .def    numLoops = r17
    ldi     numLoops, NUM_COLS
    ; NUM_COLS * 2
    lsl     numLoops

    ; current column
    .def    currentCol = r18

    ; redBuffer pointer
    ; commented out since we're gonna actually use "x"
    ; .def    redBufferPointer = x
    ldi     xl, low(redBuffer)
    ldi     xh, high(redBuffer)

    ; greenBuffer pointer
    ; commented out since we're gonna actually use "y"
    ; .def    greenBufferPointer = y
    ldi     yl, low(greenBuffer)
    ldi     yh, high(greenBuffer)

  PlotImageWhile:
    ;;; check if we should keep looping
    cp      n, numLoops
    ; if n == NUM_COLS * 2, then we're done
    breq    PlotImageReturn

    ;;; get the column we want
    lpm     currentCol, z+

    ;;; check parity of n
    bst     n, 0
    ; if it's odd, we want to set the green col
    brts    PlotImageGreenColumn
    ; if it's even, we want to set the red col

    ;;; set red col
    st      x+, currentCol
    jmp     PlotImageIncLoopVar

  PlotImageGreenColumn:
    ;;; set green col
    st      y+, currentCol

  PlotImageIncLoopVar:
    inc     n
    jmp     PlotImageWhile

  PlotImageReturn:
    pop     yh
    pop     yl
    pop     xh
    pop     xl
    pop     r18
    pop     r17
    pop     r16
    pop     zh
    pop     zl
    ret
