;;;;;;;;;;;;;;;
; display.asm ;
;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for the LED grid display including:
;   * InitDisplayVars: inits display shared vars
;   * MultiplexDisplay: cycles through which column to display
;   * ClearDisplay: turns all LEDs off
;   * PlotPixel: sets a pixel in the grid to a specified color
;   * SetCursor: blinks a pixel in the grid between 2 specified colors
;       (indicating the cursor is at that position)
;   * PlotImage: plots image from specified location in program memory
;
; Inputs
; ------
; None
;
; Outputs
; -------
; PortA: green LED columns
; PortC: LED rows
; PortD: red LED columns
;
; User Interface
; --------------
; 8 x 8 LED grid, where each pixel contains a red LED and a green LED
;
; Error Handling
; --------------
; None
;
; Known Bugs
; ----------
; None
;
; Limitations
; -----------
; None
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

.dseg

    redBuffer:          .byte 8 ; the current contents of the red LED grid
    greenBuffer:        .byte 8 ; the current contents of the green LED grid

    ledBufferOffset:    .byte 1 ; for display multiplexor: offset from 
                                ; ledBuffer that determines which column in 
                                ; the ledBuffer matrix to use for writing the 
                                ; rows of the display
    columnMaskG:        .byte 1 ; for display multiplexor: 1-hot byte (in 
                                ; conjunction with columnMaskR) that 
                                ; determines which column of LEDs to write.
    columnMaskR:        .byte 1 ; for display multiplexor: 1-hot byte (in 
                                ; conjunction with columnMaskG) that 
                                ; determines which column of LEDs to write

    useCursorColor2:    .byte 1 ; when False, use color1 for cursor
                                ; when True use color2 for cursor
    cursorChangeCounter: .byte 1; when this hits 0, change the cursor color

    cursorRow:          .byte 1 ; Row of display in which cursor resides
    cursorColumn:       .byte 1 ; Row of display in which column resides

    cursorColor1:    .byte 1    ; color for first blink of cursor
    cursorColor2:    .byte 1    ; color for second blink of cursor

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


; SetCursor(r, c, c1, c2)
; =======================
;
; Description
; -----------
; Sets the pixel at row r, column c of the display grid to blink between
; color c1 and color c2, switching every 500 ms. This indicates to the user
; that the cursor is located at row r, column c. The possible colors are
; blank, red, green, and yellow.
;
; Operational Description
; -----------------------
; Sets display[r, c] according to c1, cursorRed2 and cursorGreen2 according to 
; c2, cursorRow to r, cursorColumn to c, such the the display multiplexor 
; knows how to set up the blinking of the cursor location.
;
; Arguments
; ---------
; r (int, r16): row of the display (between 0 and 7) (overwrites)
; c (int, r17): column of the display (between 0 and 7) (overwrites)
; c1 (int, r18): first color for the cursor to blink (0: blank, 
;   1: red, 2: green, 3: yellow)
; c2 (int, r19): second color for the cursor to blink (0: blank, 
;   1: red, 2: green, 3: yellow)
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
; cursorRedColor1 (int): W
; cursorGreenColor1 (int): W
; cursorRedColor2 (int): W
; cursorGreenColor2 (int): W
;
; Local Variables
; ---------------
; None
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
; if r or c is outside of 0 and 7:
;   this is fine: in fact, we use this to "unset" the cursor (such that
;   no pixel on the display is blinking)
; if c1 or c2 is outside of 0 and 3:
;   if they are above 3, they get reset to 3; if they are below 0, they get
;   reset to 0.
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
; r16: r
; r17: c
; r18: c1
; r19: c2
;
; Stack Depth
; -----------
; 5 bytes
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
    push    r20
    push    r21

    ;;; arguments
    .def    r = r16    ; row
    .def    c = r17    ; column
    .def    c1 = r18   ; cursor color 1
    .def    c2 = r19   ; cursor color 2
    
    ;;; other registers we need
    ; for withinBounds tests
    .def    offReg = r20
    ; for withinBounds tests
    .def    yellowReg = r21

    ;;; argument validity checks

    ; OFF <= c1 <= YELLOW
    ldi     offReg, OFF
    ldi     yellowReg, YELLOW
    withinBounds  c1, offReg, yellowReg
    brtc    SetCursorReturn

    ; OFF <= c2 <= YELLOW
    withinBounds  c2, offReg, yellowReg
    brtc    SetCursorReturn


    ;;; set the (row, column) position of the cursor
    sts     cursorRow, r
    sts     cursorColumn, c

    ;;; set cursorColor1, cursorColor2
    sts     cursorColor1, c1
    sts     cursorColor2, c2
    
  SetCursorReturn:
    pop     r21
    pop     r20

    ret





; ClearDisplay()
; ==============
;
; Description
; -----------
; clears the LED display such that all LEDS are off
; doesn't affect cursor
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
; redBuffer (8 x 8 boolean matrix): W
; greenBuffer (8 x 8 boolean matrix): W
;
; Local Variables
; ---------------
; None
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
; y, z
;
; Stack Depth
; -----------
; 2 bytes
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





; PlotPixel(r, c, color)
; ======================
;
; Description
; -----------
; Sets the pixel at row r, column c of the display grid to the specied color
; (blank, red, green, or yellow).
;
; Operational Description
; -----------------------
; Sets display[r, c] according to color.
;
; Arguments
; ---------
; r (int, r16): row of the display (between 0 and 7)
; c (int, r17): column of the display (between 0 and 7)
; color (int, r18): color for pixel at r, c (0: blank, 1: red, 2: green, 
;   3: yellow)
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
; redBuffer (8 x 8 bool matrix): W
; greenBuffer (8 x 8 bool matrix): W
;
; Local Variables
; ---------------
; None
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
; if r or c is outside of 0 and 7, don't do anything (return right away)
; if color is less than OFF set to OFF; if it is greater than YELLOW set
;   to YELLOW
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
; r16: r
; r17: c
; r18: color
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
PlotPixel:
    push    r19
    push    r20
    push    r21
    push    yl
    push    yh

    ;;; arguments
    ; row on display
    .def    r = r16
    ; column on display
    .def    c = r17
    ; color to set at buffer[r, c]
    .def    color = r18
    
    ;;; other registers needed
    ; for argument validity checks; zero also used for adding 16-bits to 8-bits
    .def    zero = r19
    .def    numRowsReg = r20
    ; reuse r20 since we don't need numColsRegand and numRowsReg simultaneously
    .def    numColsReg = r20
    ; reuse r19 since we don't need offReg and zero simultaneously
    .def    offReg = r19
    ; reuse r20 since we don't need yellowReg and numRowsReg simultaneously
    .def    yellowReg = r20

    ; for storing red, green LED on states of color
    ; reuse r20 since don't need yellowReg when using this
    .def    redOn = r20
    .def    greenOn = r21

    ; for updating buffer
    .def    bufferRowVector = r19

    ;;; check validity of (r,c), return if invalid
    ; must have 0 <= r <= NUM_ROWS
    clr     zero
    ldi     numRowsReg, NUM_ROWS
    withinBounds    r, zero, numRowsReg
    brtc    PlotPixelReturnDetour
    ; must have 0 <= c <= NUM_COLS
    ldi     numRowsReg, NUM_ROWS
    withinBounds    c, zero, numColsReg
    brtc    PlotPixelReturnDetour

    ;;; check validity of color, return if invalid
    ldi     offReg, OFF
    ldi     yellowReg, YELLOW
    withinBounds    color, offReg, yellowReg
    brtc    PlotPixelReturnDetour
    jmp     PlotPixelGetOnStates

  PlotPixelReturnDetour:
    ;;; need this because the brtc's are out of range of PlotPixelReturn
    jmp     PlotPixelReturn


  PlotPixelGetOnStates:
    ;;; the on states of red, green LEDS
    colorToRG   color, redOn, greenOn


    ;;; set redBuffer[r, c] = redOn
    ; put y at redBuffer[c]
    clr     zero
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)
    add     yl, c
    adc     yh, zero

    ; get the row vector at redBuffer[c]
    ld      bufferRowVector, y

    ; check if red LED should be on
    cpi     redOn, TRUE
    ; set redBuffer[r, c] according to z flag
    setBitToZ   bufferRowVector, r

    ; store updated rowVector back in redBuffer[c]
    st      y, bufferRowVector


    ;;; set greenBuffer[r, c] = greenOn
    ; put y at greenBuffer[c]
    clr     zero
    ldi     yl, low(greenBuffer)
    ldi     yh, high(greenBuffer)
    add     yl, c
    adc     yh, zero

    ; get the row vector at greenBuffer[c]
    ld      bufferRowVector, y

    ; check if green LED should be on
    cpi     greenOn, TRUE
    ; set greenBuffer[r, c] according to z flag
    setBitToZ   bufferRowVector, r

    ; store updated rowVector back in greenBuffer[c]
    st      y, bufferRowVector

  PlotPixelReturn:
    pop     yh
    pop     yl
    pop     r21
    pop     r20
    pop     r19
    ret




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
; redBuffer (8 x 8 boolean matrix): W
; greenBuffer (8 x 8 boolean matrix): W
; ledBufferOffset (int): W
; columnMaskG (8 bit string): W
; columnMaskR (8 bit string): W
; cursorRow (int): W
; cursorColumn (int): W
; cursorRed2 (bool): W
; cursorGreen2 (bool): W
;
; Local Variables
; ---------------
; None
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
; 1 byte
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
    ; initially see the cursor) and colors
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







; MultiplexDisplay()
; ==================
;
; Description
; -----------
; This is an event handler responsible for multiplxing the LED display (i.e.
; turning on the columns one at a time and writing the corresponding column
; in the buffer to the rows).
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
; redBuffer (8 x 8 bool matrix): R
; greenBuffer (8 x 8 bool matrix): R
; cursorChangeCounter (int): RW
; useCursorColor2 (bool): RW
; cursorRow (int): R
; cursorColumn (int): R
; cursorColor1 (int): R
; cursorColor2 (int): R
;
; Local Variables
; ---------------
; ledBufferOffset (int): RW
; columnMaskR (8 bit string): RW
; columnMaskG (8 bit string): RW
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

    ; for clearing/setting bit in register (reuse r18 since
    ;   don't need cursorRowRegby the time we need this)
    .def        oneHotBit = r18

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
    ; rows are indexed backwards on actual display, so compliment base NUM_ROWS
    ;neg         cursorRowReg
    ;subi        cursorRowReg, -NUM_ROWS
    ; shift cursor bit into row position
    ; r16 (byte): one-hot bit (0b00000001)
    ; r17 (k): cursorRowReg
    push        r16
    ldi         r16, BIT0_MASK
    push        r17
    mov         r17, cursorRowReg
    rcall       lslk
    ; store result in oneHotBit register (so we can recover r16)
    mov         oneHotBit, r16
    pop         r17
    pop         r16

    ; check if cursorBit is 0
    tst         cursorBit
    ; if it isn't, set bit
    brne        MultiplexDisplaySetCursorBit
    ; if it is, clear bit
    com         oneHotBit
    and         rowVector, oneHotBit
    jmp         MultiplexDisplayOutColumn
  MultiplexDisplaySetCursorBit:
    ; set cursor bit in rowVector
    or          rowVector, oneHotBit

  MultiplexDisplayOutColumn:
    ; rows on actual display are flipped from the actual
    ;   indexing, so flip rowVector before outputting
    flipByte    rowVector
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
; n (int): loop var
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
; 1 byte
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
    ;;; flip it (because row indices are flipped on display)
    flipByte  currentCol

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
