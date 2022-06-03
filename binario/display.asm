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

    cursorRedColor1:    .byte 1 ; whether or not red LED should be turned on 
                                ; for first blink of cursor
    cursorGreenColor1:  .byte 1 ; whether or not green LED should be turned on 
                                ; for first blink of cursor
    cursorRedColor2:    .byte 1 ; whether or not red LED should be turned on 
                                ; for second blink of cursor
    cursorGreenColor2:  .byte 1 ; whether or not green LED should be turned on 
                                ; for second blink of cursor

.cseg

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
    ;;; arguments
    .def r = r16    ; row
    .def c = r17    ; column
    .def c1 = r18   ; cursor color 1
    .def c2 = r19   ; cursor color 2
    
    ;;; other registers we need
    .def red1 = r21
    push red1        ; cursor red color 1

    .def green1 = r22
    push green1        ; cursor green color 1

    .def red2 = r23
    push red2        ; cursor red color 2

    .def green2 = r24
    push green2        ; cursor green color 2


    ;;; set the (row, column) position of the cursor
    sts cursorRow, r
    sts cursorColumn, c


    ;;; saturate c1, c2 args if invalid (less than OFF, greater than YELLOW)
    ; OFF <= c1 <= YELLOW
    mov r16, c1
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    ; recover r16 -> c1
    mov c1, r16

    ; push c1 since we need to overwrite for function call (no longer need
    ;   to save r, c)
    push c1
    ; OFF <= c2 <= YELLOW
    mov r16, c2
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    ; recover c1 for later stuff
    pop c1
    ; copy r16 to c2
    mov c2, r16


    ;;; set the color information of the cursor
    ; red1 is bit0 of c1
    mov red1, c1
    andi red1, TRUE
    sts cursorRedColor1, red1

    ; green1 is bit 1 of c1
    mov green1, c1
    lsr green1
    sts cursorGreenColor1, green1

    ; red2 is bit0 of c2
    mov red2, c2
    andi red2, TRUE
    sts cursorRedColor2, red2

    ; green2 is bit 2 of c2
    mov green2, c2
    lsr green2
    sts cursorGreenColor2, green2
    
    
    ;;; return
    pop green2
    pop red2
    pop green1
    pop red1
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
    ;;; push needed registers
    .def blank = r16 ; r16: OFF
    push blank        ; r16: OFF
    ldi blank, OFF

    .def idx = r17
    push idx        ; r17: loop index


    ; y: redBuffer, z: greenBuffer
    push yl
    push yh
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    push zl
    push zh
    ldi zl, low(greenBuffer)
    ldi zh, high(greenBuffer)


    ;;; turn off every column in red and green buffers
    ldi idx, 0
  ClearBuffersLoop:
    st y+, blank
    st z+, blank
    inc idx
    cpi idx, NUM_COLS
    brlt ClearBuffersLoop
    

    ;;; return
    pop zh
    pop zl
    pop yh
    pop yl
    pop idx
    pop blank
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
    ;;; arguments
    .def r = r16        ; r16: display row
    .def c = r17        ; r17: display column
    .def color = r18    ; r18: color to set
    

    ;;; check validity of (r,c) , return if invalid
    ; save color since overwritten by function call
    push color
    ldi r18, TRUE ; we can use this for each call since CheckValid only
                    ; changes its value if invalid

    ; save r, c since overwritten by function call
    push r
    push c
    ; r must be >= 0
    mov r16, r
    ldi r17, 0
    rcall CheckValid

    ; r must be <= NUM_ROWS-1
    mov r17, r
    ldi r16, NUM_ROWS
    dec r16
    rcall CheckValid

    ; recover c -> r16
    pop r16
    ; c must be >= 0
    ldi r17, 0
    rcall CheckValid

    ; copy c (in r16 at the moment) to r17)
    mov r17, r16
    ; c must be <= NUM_COLS-1
    ldi r16, NUM_COLS
    dec r16
    rcall CheckValid
    
    ; recover r and c
    mov c, r17
    pop r

    ; return if any of the above args are invalid
    cpi r18, TRUE
    ; recover color
    pop color
    brne Return_PlotPixel

    
    ;;; other registers we need
    .def redOn = r19
    push redOn            ; r19: red color
    .def greenOn = r20
    push greenOn            ; r20: green color
    .def zero = r21       ; immediate 0
    push zero
    ldi zero, 0
    

    ;;; check validity of color, set to nearest bound (OFF or YELLOW) if out
    ;;;     of bounds
    ; save r, c since overwritten by function call
    push r
    push c
    ; color must be >= OFF
    mov r16, color
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    pop c
    mov color, r16
    pop r


    ;;; set red/greenBuffer[r, c] according to red/greenOn
    ; red is bit0 of color
    mov redOn, color
    andi redOn, TRUE

    ; green is bit 1 of color
    mov greenOn, color
    lsr greenOn

    ; put y at redBuffer[c]
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    add yl, c
    adc yh, zero
    
    ; put z at greenBuffer[c]
    ldi zl, low(greenBuffer)
    ldi zh, high(greenBuffer)
    add zl, c
    adc zh, zero

    
    ; prepare for Set/ClearBit function calls
    mov r17, r
    ld r16, y
    ; if redOn is TRUE...
    cpi redOn, TRUE
    brne ClearRedBufferCR_PlotPixel
    ; then set redBuffer[c][r]
    rcall SetBit
    jmp StoreRedBufferBack_PlotPixel
  ClearRedBufferCR_PlotPixel:
    rcall ClearBit
    ;jmp StoreRedBufferBack_PlotPixel
  StoreRedBufferBack_PlotPixel:
    st y, r16

    ; prepare for Set/ClearBit function calls
    ld r16, z
    ; note r is already in r17
    ; if greenOn is TRUE...
    cpi greenOn, TRUE
    brne ClearGreenBufferCR_PlotPixel
    ; then set greenBuffer[c][r]
    rcall SetBit
    jmp StoreGreenBufferBack_PlotPixel
  ClearGreenBufferCR_PlotPixel:
    rcall ClearBit
    ;jmp StoreGreenBufferBack_PlotPixel
  StoreGreenBufferBack_PlotPixel:
    st z, r16
    
    pop zero
    pop greenOn
    pop redOn

  Return_PlotPixel:
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
    ;;; registers needed
    .def temp = r16
    push temp        ; r16: multipurpose


    rcall ClearDisplay

    ; init buffer offset (for display mux)
    ldi temp, BUFF_OFFSET_INIT
    sts ledBufferOffset, temp
    
    ; init column masks (for display mux)
    ldi temp, COL_MASK_G_INIT
    sts columnMaskG, temp
    ldi temp, COL_MASK_R_INIT
    sts columnMaskR, temp
    
    ; init cursor change counter
    ldi temp, CURSOR_COUNTER_INIT
    sts cursorChangeCounter, temp

    ; init cursor blinking
    ldi temp, USE_CURSOR_COLOR2_INIT
    sts useCursorColor2, temp

    ; init cursor position
    ldi temp, CURSOR_ROW_INIT
    sts cursorRow, temp
    ldi temp, CURSOR_COL_INIT
    sts cursorColumn, temp

    ; init cursor colors
    ldi temp, CURSOR_RED_COLOR1_INIT
    sts cursorRedColor1, temp
    ldi temp, CURSOR_GREEN_COLOR1_INIT
    sts cursorGreenColor1, temp
    ldi temp, CURSOR_RED_COLOR2_INIT
    sts cursorRedColor2, temp
    ldi temp, CURSOR_GREEN_COLOR2_INIT
    sts cursorGreenColor2, temp

    pop temp
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
; cursorRedColor1 (int): R
; cursorGreenColor1 (int): R
; cursorRedColor2 (int): R
; cursorGreenColor2 (int): R
;
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
; y
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
MultiplexDisplay:
    ;;; registers needed
    ; r16: temporary stuff
    .def temp = r16
    push temp

    ; r17, r18: column masks
    .def colMaskG = r17
    push colMaskG
    lds colMaskG, columnMaskG
    .def colMaskR = r18
    push colMaskR
    lds colMaskR, columnMaskR

    ; r19: buffer offset
    .def bufferOffset = r19
    push bufferOffset
    lds bufferOffset, ledBufferOffset

    ; r20, r21: cursor stuff
    .def useColor2 = r20
    push useColor2
    lds useColor2, useCursorColor2
    .def changeCounter = r21
    push changeCounter
    lds changeCounter, cursorChangeCounter

    ; r22: the cursor color we are setting (could be for red/green 1/2 
    ;   depending)
    .def cursorColor = r22
    push cursorColor
    
    ; r23: immediate 0
    .def zero = r23
    push zero
    ldi zero, 0

    ; y: buffer
    push yl
    push yh


    ;;; turn off all columns
    ldi temp, OFF
    out porta, temp
    out portd, temp


    ;;; figure out if we want to load green or red into Y
    ; if the 1 is not in columnMaskG...
    cpi colMaskG, 0
    ; load red buffer
    breq LoadRedBuffer
    ; otherwise , load green buffer
    ldi yl, low(greenBuffer)
    ldi yh, high(greenBuffer)

    ; if currently using cursor color 2...
    cpi useColor2, TRUE
    ; load green cursor color 2
    breq UseCursorGreenColor2
    ; otherwise, load green cursor color 1
    lds cursorColor, cursorGreenColor1
    jmp ResolveCursorInBuffer
  UseCursorGreenColor2:
    ; load green cursor color 2 if useColor2 is true
    lds cursorColor, cursorGreenColor2
    jmp ResolveCursorInBuffer

  LoadRedBuffer:
    ; load red buffer
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)

    ; if currently using cursor color 2...
    cpi useColor2, TRUE
    ; load red cursor color 2
    breq UseCursorRedColor2
    ; otherwise, load red cursor color 1
    lds cursorColor, cursorRedColor1
    jmp ResolveCursorInBuffer
  UseCursorRedColor2:
    ; load red cursor color 2
    lds cursorColor, cursorRedColor2
    ;jmp ResolveCursorInBuffer

    ;;; figure out if we're at the cursor's column (and thus should load
    ;;;     the cursor colors)
  ResolveCursorInBuffer:
    ; adjust y by offset (so that we're at the right column)
    add yl, bufferOffset
    adc yh, zero

    ; if the current column is the cursor's column ...
    lds temp, cursorColumn
    cp bufferOffset, temp
    ld temp, y ; put the column vector in temp
    brne OutY2C
    
    ; prepare for Set/ClearBit function calls
    ; then set the current column's cursor row bit
    ; note that r16 (temp) already contains the column vector
    ; save colMaskG because we need to overwrite for function call
    push colMaskG
    lds r17, cursorRow
    
    ; and if cursorColor is set ...
    cpi cursorColor, TRUE
    brne ClearCursorInBuffer
    rcall SetBit
    ; temp[cursorRow] (which contains column vector to output to port c) is 
    ;   now set
    ; recover colMaskG
    pop colMaskG
    jmp OutY2C
  ClearCursorInBuffer:
    rcall ClearBit
    ; temp[cursorRow] (which contains column vector to output to port c) is 
    ;   now clear
    ; recover colMaskG
    pop colMaskG
    ;jmp OutY2C


  OutY2C:
    ;;; output y (the rows of the current column) to port c
    out portc, temp
    

    ;;; adjust cursor vars and re-init if necessary
    dec changeCounter
	  sts cursorChangeCounter, changeCounter
    ; if cursorChangeCounter is at 0 ...
    cpi changeCounter, 0
    brne ReInitOffset
    ; invert useCursorColor2
    ldi temp, TRUE
    eor useColor2, temp
    sts useCursorColor2, useColor2
    ; reinit cursorChangeCounter
    ldi changeCounter, CURSOR_COUNTER_INIT
    sts cursorChangeCounter, changeCounter


    ;;; inc led buffer offset (the indexer) and reinit if necessary
  ReInitOffset:
    inc bufferOffset
    ; if bufferOffset doesn't exceed the max column index...
    cpi bufferOffset, NUM_COLS
    ; leave the buffer offset incremented
    brne StoreBufferOffset
    ; otherwise, reinit the buffer offset
    ldi bufferOffset, BUFF_OFFSET_INIT
  StoreBufferOffset:
    sts ledBufferOffset, bufferOffset


    ;;; output column masks to their respective ports
    ; green -> port a
    out porta, colMaskG
    ; red -> port d
    out portd, colMaskR

    ;;; rotate column masks
    ; if green column mask is in its final state...
    cpi colMaskG, COL_MASK_G_FINAL
    brne RotateColumnMasks
    ; and if red column mask is in its final state...
    cpi colMaskR, COL_MASK_R_FINAL
    brne RotateColumnMasks
    ; then reinit the column masks
    ldi colMaskG, COL_MASK_G_INIT
    ldi colMaskR, COL_MASK_R_INIT
    jmp StoreColumnMasks

  RotateColumnMasks:
    lsr colMaskG
    rol colMaskR

  StoreColumnMasks:
    sts columnMaskG, colMaskG
    sts columnMaskR, colMaskR


    pop yh
    pop yl
    pop zero
    pop cursorColor
    pop changeCounter
    pop useColor2
    pop bufferOffset
    pop colMaskR
    pop colMaskG
    pop temp

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
;
; Pseudocode
; ----------
;
; n = 0
; x = redBuffer
; y = greenBuffer
; z = ptr
; WHILE n < NUM_COLS * 2:
;   IF n is even:
;     x++ = z++
;   ELSE:
;     y++ = z++
;   n++
; END_WHILE
PlotImage:
    ;;; arguments
    ; commented out since we're gonna actually use "z"
    ; .def    ptr = z

    ;;; other registers needed
    ; loop var
    .def    n = r16
    push    n
    clr     n

    ; number of times to loop register
    .def    numLoops = r17
    push    numLoops
    ldi     numLoops, NUM_COLS
    ; NUM_COLS * 2
    lsl     numLoops

    ; current column
    .def    currentCol = r18
    push    currentCol

    ; redBuffer pointer
    ; commented out since we're gonna actually use "x"
    ; .def    redBufferPointer = x
    push    xl
    push    xh
    ldi     xl, low(redBuffer)
    ldi     xh, high(redBuffer)

    ; greenBuffer pointer
    ; commented out since we're gonna actually use "y"
    ; .def    greenBufferPointer = y
    push    yl
    push    yh
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
    pop     currentCol
    pop     numLoops
    pop     n
    ret