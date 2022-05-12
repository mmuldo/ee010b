;;;;;;;;;;;;;;;
; display.asm ;
;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for the LED grid display including:
;   * InitDisplayVars: inits display shared vars
;   * MultiplexDisplay: cycles through which column to display
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
; None
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

    cursorRed2:         .byte 1 ; whether or not red LED should be turned on 
                                ; for second blink of cursor
    cursorGreen2:       .byte 1 ; whether or not green LED should be turned on 
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
; r (int, r16): row of the display (between 0 and 7)
; c (int, r17): column of the display (between 0 and 7)
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
    push r21        ; cursor red color 1
    .def red1 = r21
    push r22        ; cursor green color 1
    .def green1 = r22
    push r23        ; cursor red color 2
    .def red2 = r23
    push r24        ; cursor green color 2
    .def green2 = r24

    push r20        ; constant YELLOW
    .def yellow = r20
    ldi yellow, YELLOW


    ;;; set the (row, column) position of the cursor
    sts cursorRow, r
    sts cursorColumn, c


    ;;; saturate c1, c2 args if invalid (less than OFF, greater than YELLOW)
    push r16
    push r17
    push r18
    mov r16, c1
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    pop r18
    pop r17
    mov c1, r16
    pop r16

    push r16
    push r17
    push r18
    mov r16, c2
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    pop r18
    pop r17
    mov c2, r16
    pop r16


    ;;; set the color information of the cursor
  SetCursorColors:
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
    pop r20
    pop r24
    pop r23
    pop r22
    pop r21
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
; None
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
    push r16        ; r16: OFF
    .def off = r16
    ldi off, OFF

    push r17        ; r17: loop index
    .def idx = r17

    ; y: redBuffer, z: greenBuffer
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    ldi zl, low(greenBuffer)
    ldi zh, high(greenBuffer)

    ;;; turn off every column in red and green buffers
    ldi idx, 0
  ClearBuffersLoop:
    st y+, off
    st z+, off
    cpi idx, NUM_COLS
    brlt ClearBuffersLoop
    

    ;;; return
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
; None
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
; red = TRUE & color
; red << r
; redBuffer[c] |= red
; 
; green = color >> 1
; green << r
; greenBuffer[c] |= green
PlotPixel:
    ;;; arguments
    .def r = r16        ; r16: display row
    .def c = r17        ; r17: display column
    .def color = r18    ; r18: color to set


    ;;; other registers we need
    push r19            ; r19: red color
    .def red = r19

    push r20            ; r20: green color
    .def green = r20

    push r22            ; r22: YELLOW
    .def yellow = r22
    ldi yellow, YELLOW

    push r23            ; r23: redBuffer[c]
    .def redBuffer_c = r23

    push r24            ; r24: greenBuffer[c]
    .def greenBuffer_c = r24

    ;;; check validity of (r,c) , return if invalid
    push r18
    ldi r18, TRUE ; we can use this for each call since CheckValid only
                    ; changes its value if invalid

    ; r must be >= 0
    push r16
    push r17
    mov r16, r
    ldi r17, 0
    rcall CheckValid
    pop r17
    pop r16

    ; r must be < NUM_ROWS
    push r16
    push r17
    ldi r16, NUM_ROWS
    dec r16
    mov r17, r
    rcall CheckValid
    pop r17
    pop r16

    ; c must be >= 0
    push r16
    push r17
    mov r16, c
    ldi r17, 0
    rcall CheckValid
    pop r17
    pop r16

    ; c must be < NUM_COLS
    push r16
    push r17
    ldi r16, NUM_ROWS
    dec r16
    mov r17, r
    rcall CheckValid
    pop r17
    pop r16

    ; return if any of the above args are invalid
    cpi r18, TRUE
    pop r18
    breq CheckColorValidity_PlotPixel
    ret

    ;;; check validity of color, set to nearest bound (OFF or YELLOW) if out
    ;;; of bounds
    ; color must be >= OFF
    push r16
    push r17
    push r18
    mov r16, color
    ldi r17, OFF
    ldi r18, YELLOW
    rcall Saturate
    pop r18
    pop r17
    mov color, r16
    pop r16


    ;;; set redBuffer[r, c]
    mov red, color

    ; get red bit from color
    andi red, TRUE

    ; red << r
    push r16
    push r17
    ld r16, red
    ld r17, r
    rcall lslk
    mov red, r16
    pop r17
    pop r16

    ; put y at redBuffer[c]
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    add yl, c
    adc yh, 0
    ; get contents at redBuffer[c]
    lds redBuffer_c, y

    ; redBuffer[c] |= red
    or redBuffer_c, red
    sts y, redBuffer_c


    ;;; set greenBuffer[r, c]
    mov green, color

    ; get green bit from color
    andi green, TRUE

    ; green << r
    push r16
    push r17
    ld r16, green
    ld r17, r
    rcall lslk
    mov green, r16
    pop r17
    pop r16

    ; put y at greenBuffer[c]
    ldi yl, low(greenBuffer)
    ldi yh, high(greenBuffer)
    add yl, c
    adc yh, 0
    ; get contents at greenBuffer[c]
    lds greenBuffer_c, y

    ; greenBuffer[c] |= green
    or greenBuffer_c, green
    sts y, greenBuffer_c

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
; [unknown]
;
; Stack Depth
; --------------
; [unknown]
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
    push r16        ; r16: multipurpose
    .def temp = r16

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

    ; init cursor color
    ldi temp, CURSOR_RED_COLOR_1_INIT
    sts cursorRedColor1, temp
    ldi temp, CURSOR_GREEN_COLOR_1_INIT
    sts cursorGreenColor1, temp
    ldi temp, CURSOR_RED_COLOR_2_INIT
    sts cursorRedColor2, temp
    ldi temp, CURSOR_GREEN_COLOR_2_INIT
    sts cursorGreenColor2, temp

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
; cursorRed2 (int): R
; cursorGreen2 (int): R
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
; Y
; [others]
;
; Stack Depth
; -----------
; [unknown]
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
; save sreg
; turn off columns
;
; IF columnMaskG != 0:
;   load greenBuffer into Y
; ELSE:
;   load redBuffer into Y
; add ledBufferOffset to Y
; 
; ouput Y to port c
; IF ledBufferOffset == cursorColumn and useCursorColor2:
;   IF columnMaskG != 0:
;       PortC[cursorRow] = cursorGreen2
;   ELSE:
;       PortC[cursorRow] = cursorRed2
;
; cursorChangeCounter--
; IF cursorChangeCounter == 0:
;   useCursorColor2 = !useCursorColor2
;   reinit cursorChangeCounter to 500
;
; IF ledBufferOffset == 7:
;   reinit ledBufferOffset to 0
; ELSE:
;   increment ledBufferOffset
; 
; output columnMaskG to port a
; output columnMaskR to port d
; IF columnMaskG == 0x00 and columnMaskR == 0x01:
;   reinit columnMaskR to 0x80
;   reinit columnMaskG to 0x00
; ELSE:
;   lsr columnMaskG
;   ror columnMaskR
;
; write back sreg
MultiplexDisplay:
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

    ;;; turn off all columns
    ldi temp, OFF
    out porta, temp
    out portd, temp

    ;;; figure out if we want to load green or red into Y
    ; if the 1 is in columnMaskG, load greenBuffer into Y
    cpi colMaskG, 0
    breq LoadRedBuffer
    ldi yl, low(greenBuffer)
    ldi yh, high(greenBuffer)

    ; figure out which green color (1 or 2) we want for the cursor
    cpi useColor2, FALSE
    brne UseCursorGreenColor2
    lds cursorColor, cursorGreenColor1
    jmp ResolveCursorInBuffer
  UseCursorGreenColor2:
    lds cursorColor, cursorGreenColor2
    ;jmp ResolveCursorInBuffer

    ; otherwise the 1 is in columnMaskR, so load redBuffer into Y
  LoadRedBuffer:
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)

    ; figure out which red color (1 or 2) we want for the cursor
    cpi useColor2, FALSE
    brne UseCursorRedColor2
    lds cursorColor, cursorRedColor1
    jmp ResolveCursorInBuffer
  UseCursorRedColor2:
    lds cursorColor, cursorRedColor2
    ;jmp ResolveCursorInBuffer

    ;;; figure out if we're at the cursor's column
  ResolveCursorInBuffer:
    ; adjust y by offset (so that we're at the right column)
    add yl, bufferOffset
    adc yh, 0

    ; if the current column is the cursor's column ...
    lds temp, cursorColumn
    cpi bufferOffset, temp
    lds temp, y ; put the column vector in temp
    brne OutY2C
    ; and if cursorColor is set ...
    cpi cursorColor, TRUE
    brne ClearCursorInBuffer
    ; then set the current column's cursor row bit
    ; note that r16 (temp) already contains the column vector
    push r17
    lds r17, cursorRow
    rcall SetBit
    pop r17
    ; temp[r] (r16) is now set
    jmp OutY2C
  ClearCursorInBuffer:
    ; otherwise clear the current column's cursor row bit
    ; note that r16 (temp) already contains the column vector
    push r17
    lds r17, cursorRow
    rcall SetBit
    pop r17
    ; temp[r] (r16) is now cleared
    ;jmp OutY2C

    ;;; output y (the rows of the current column) to port c
  OutY2C:
    out portc, temp

    
    ;;; adjust cursor vars and re-init if necessary
    dec changeCounter
    cpi changeCounter, 0
    brne ReInitOffset
    ; if cursorChangeCounter is at 0 ...
    ; invert useCursorColor2
    eor useColor2, TRUE
    ; reinit cursorChangeCounter
    ldi changeCounter, CURSOR_COUNTER_INIT
    sts cursorChangeCounter, changeCounter


    ;;; inc led buffer offset (the indexer) and reinit if necessary
    inc bufferOffset
    cpi bufferOffset, NUM_COLS
    brne StoreBufferOffset
    ldi bufferOffset, BUFF_OFFSET_INIT
  StoreBufferOffset:
    sts ledBufferOffset, bufferOffset


    ;;; output column masks to their respective ports
    ; green -> port a
    out porta, colMaskG
    ; red -> port d
    out portd, colMaskR

    ;;; rotate column masks
    cpi colMaskG, 0x00
    brne RotateColumnMasks
    cpi colMaskR, 0x01
    brne RotateColumnMasks
    ldi colMaskG, COL_MASK_G_INIT
    ldi colMaskR, COL_MASK_R_INIT
    jmp StoreColumnMasks

  RotateColumnMasks:
    lsr colMaskG
    ror colMaskR

  StoreColumnMasks:
    sts columnMaskG, colMaskG
    sts columnMaskR, colMaskR

    ret
