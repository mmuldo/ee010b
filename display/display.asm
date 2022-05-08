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
    ldi r16, COL_INIT

    ; init every column in redBuffer and greenBuffer
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    ldi zl, low(greenBuffer)
    ldi zh, high(greenBuffer)
    ldi r17, 0 ; index of loop
    InitBuffers:
        st y+, r16
        st z+, r16

        inc r17
        cpi r17, NUM_COLS
        brlt InitBuffers

    ; init buffer offset (for display mux) to 0
    ldi r16, BUFF_OFFSET_INIT
    sts ledBufferOffset, r16
    
    ; init column masks (for display mux)
    ldi r16, COL_MASK_G_INIT
    sts columnMaskG, r16
    ldi r16, COL_MASK_R_INIT
    sts columnMaskR, r16
    
    ; init cursor change counter
    ldi r16, CURSOR_COUNTER_INIT
    sts cursorChangeCounter, r16

    ; init cursor blinking
    ldi r16, USE_CURSOR_COLOR2_INIT
    sts useCursorColor2, r16

    ; init cursor position
    ldi r16, CURSOR_ROW_INIT
    sts cursorRow, r16
    ldi r16, CURSOR_COL_INIT
    sts cursorColumn, r16

    ; init alternate cursor color
    ldi r16, CURSOR_RED2_INIT
    sts cursorRed2, r16
    ldi r16, CURSOR_GREEN2_INIT
    sts cursorGreen2, r16



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
    ldi yl, low(redBuffer)
    ldi yh, high(redBuffer)
    ldi zl, low(greenBuffer)
    ldi zh, high(greenBuffer)

    
