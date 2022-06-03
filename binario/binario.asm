;;;;;;;;;;;;;;;
; binario.asm ;
;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for playing the binario game, including:
;   helper stuff:
;       * GetColor(row, column): gets the current color at (row, column)
;       * PixelReserved(row, column): determines if (row, column) is a
;           reserved pixel
;       * RowColumnValid(row, column): determines if (row, column) is on grid
;       * GetCursorColors(row, column): gets what the colors of the cursor
;           should be based on the current pixel color and reservation
;           at (row, column)
;       * Beep(n): beeps at user n times
;   actual stuff:
;       * MoveCursor: moves cursor Up, Down, Left, or Right from its current
;           position
;       * RotatePixelColor(row, column): rotates the current pixel color
;           based on ColorRotation
;
; Inputs
; ------
; TODO: ask
;
; Outputs
; -------
; TODO: ask
;
; User Interface
; --------------
; TODO: ask
; 8 x 8 LED grid, where each pixel contains a red LED and a green LED
; up/down and left/right rotary encoders
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
; 05/31/2022    Matt Muldowney      initial revision
; 06/01/2022    Matt Muldowney      helper functions
; 06/01/2022    Matt Muldowney      cursor movement functions
; 06/01/2022    Matt Muldowney      cursor color functions

.dseg
    ; 8 x 8-bit boolean matrix where each element indicates if 
    ;   that pixel on the LED grid belongs to the game board
    gameBoard:  .byte 8



.cseg

; converts a direction (UP, LEFT, DOWN, RIGHT) to a 
; coordinate vector to add to (cursorRow, cursorColumn)
DirToCoords:
    .db -1, 0   ; up
    .db 0, -1   ; left
    .db 1, 0    ; down
    .db 0, 1    ; right

; performs the following mapping:
;   OFF -> RED
;   RED -> GREEN
;   GREEN -> OFF
;   YELLOW -> YELLOW
ColorRotation:
    .db RED, GREEN, OFF, YELLOW


; GetColor(row, column)
;
; Description
; -----------
; Gets the current pixel color at (row, column).
; row argument is passed in on r16, column on r17.
; color returned on r18.
; The integer-to-color mapping is determined by OFF, RED, GREEN,
; and YELLOW constants defined in display.inc.
;
; Operational Description
; -----------------------
; Reads redBuffer to determine if the red LED at (row, column)
; is on, and likewise for greenBuffer. The color at (row, column)
; is equal to {red is on} + {green is on}.
;
; Arguments
; ---------
; row (int, r16): row on grid
; column (int, r17): column on grid
;
; Return Values
; -------------
; int, r18: color1
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer: R
; greenBuffer: R
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
; None (assumes caller will handle (row, column) beint out of bounds)
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
; r18 (r16 and r17 preserved)
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
GetColor:
    ;;; arguments
    ; arguments pushed for convenience to caller
    .def    row = r16
    push    row
    .def    column = r17
    push    column

    ;;; return values
    .def    color = r18

    ;;; other registers needed
    ; general purpose register
    .def    tmp = r20
    push    r20

    ; need to overwrite column, so save it in here
    .def    columnTmp = r21
    push    columnTmp
    mov     columnTmp, column

    ; needed for buffer access
    push    yl
    push    yh


    ;;; get the current pixel color at (row, column)
    ; number of times to shift for lsrk
    .def    k = r17
    mov     k, row

    ; byte input for lsrk
    .def    byte = r16

    ; first get redBuffer[column]
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)
    add     yl, columnTmp
    adc     yh, zero

    ; then get color = redBuffer[column][row]
    ld      byte, y
    push    k ; save k
    ; byte >> k (puts redBuffer[column][row] in lowest bit of byte)
    rcall   lsrk
    pop     k ; recover k
    ; put {red is on} in color
    bst     byte, 0
    bld     color, 0

    ; second get greenBuffer[column]
    ldi     yl, low(greenBuffer)
    ldi     yh, high(greenBuffer)
    add     yl, columnTmp
    adc     yh, zero

    ; then get color += greenBuffer[column][row]
    ld      byte, y
    push    k ; save k
    ; byte >> k (puts greenBuffer[column][row] in lowest bit of byte)
    rcall   lsrk
    pop     k ; recover k
    ; put {green is on} in tmp an add to color
    bst     byte, 0
    bld     tmp, 0
    add     color, tmp
    ; color now contains current color at (row, column)

    ; return
    pop     yh
    pop     yl
    pop     columnTmp
    pop     tmp
    pop     column
    pop     row
    ret



; PixelReserved(row, column)
;
; Description
; -----------
; Determines whether or not (row, column) is a reserved pixel.
; This is determined by:
;   pixel on game board --> reserved
;   pixel on not on game board --> not reserved
; row argument is passed in on r16, column on r17.
; If reserved, Z flag set
; If not reserved, Z flag cleared
;
; Operational Description
; -----------------------
; Sets Z flag if gameBoard[column][row] is TRUE,
; clears Z flag otherwise
;
; Arguments
; ---------
; row (int, r16): row on grid
; column (int, r17): column on grid
;
; Return Values
; -------------
; Z flag: set if reserved, cleared otherwise
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; gameBoard: R
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
; None (assumes caller will handle (row, column) being out of bounds)
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
; none (r16 and r17 preserved)
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
PixelReserved:
    ;;; arguments
    ; arguments pushed out of convenience to caller
    .def    row = r16
    push    row
    .def    column = r17
    push    column

    ; need to overwrite column, so save it in here
    .def    columnTmp = r18
    push    columnTmp
    mov     columnTmp, column

    ; needed for buffer access
    push    yl
    push    yh

    ;;; stuff for lsrk
    ; number of times to shift for lsrk
    .def    k = r17
    mov     k, row
    ; byte input for lsrk
    .def    byte = r16

    ;;; check if current pixel belongs to game board
    ldi     yl, low(gameBoard)
    ldi     yh, low(gameBoard)
    add     yl, columnTmp
    adc     yh, zero

    ; finally, get gameBoard[column]
    ld      byte, y
    ; byte >> k (puts gameBoard[column][row] in lowest bit of byte)
    rcall   lsrk
    bst     byte, 0

    ; t set --> reserved
    brts    PixelReservedReturnTrue
    ; t clear --> not reserved
    clz
    jmp     PixelReservedReturn
  PixelReservedReturnTrue:
    sez

  PixelReservedReturn:
    ;;; return
    pop     yh
    pop     yl
    pop     columnTmp
    pop     column
    pop     row
    ret


; RowColumnValid(row, column)
;
; Description
; -----------
; Determines if the (row, column) are valid in the following way:
;   0 <= row < NUM_ROWS and 0 <= column < NUM_COLS --> valid
;   otherwise --> not valid
; If valid, sets zero flag, and clears zero flag otherwise.
;
; Operational Description
; -----------------------
; Performs CheckValid on each boundary case.
;
; Arguments
; ---------
; row (int, r16): row
; column (int, r17): column
;
; Return Values
; -------------
; Z flag: set if valid, cleared otherwise
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; None
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
; none (r16, r17 preserved)
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
RowColumnValid:
    ;;; arguments
    ; push args out of convenience to caller
    .def    row = r16
    .def    column = r17

    ;;; check validity of (row, column)
    ; need these registers
    .def    value1 = r16
    .def    value2 = r17
    .def    validFlag = r18
    push    validFlag

    ; initialize valid flag to true
    ldi     validFlag, TRUE

    ; check row >= 0
    ; save stuff
    push    value1
    push    value2
    ;mov     value1, row
    clr     value2
    rcall   CheckValid
    ; recover stuff
    pop     value2
    pop     value1

    ; check NUM_ROWS-1 >= row
    ; save stuff
    push    value1
    push    value2
    mov     value2, row
    ldi     value1, NUM_ROWS-1
    rcall   CheckValid
    ; recover stuff
    pop     value2
    pop     value1

    ; check column >= 0
    ; save stuff
    push    value1
    push    value2
    mov     value1, column
    clr     value2
    rcall   CheckValid
    ; recover stuff
    pop     value2
    pop     value1

    ; check NUM_COLS-1 >= column
    ; save stuff
    push    value1
    push    value2
    ;mov     value2, column
    ldi     value1, NUM_COLS-1
    rcall   CheckValid
    ; recover stuff
    pop     value2
    pop     value1

    ;;; check valid flag
    cpi     validFlag, True
    ; if valid, set z flag
    breq    RowColumnValidSetZ
    ; if not valid, clear z flag
    clz
    jmp     RowColumnValidReturn
  RowColumnValidSetZ:
    sez

  RowColumnValidReturn:
    pop     validFlag
    ret




; GetCursorColors(row, column)
;
; Description
; -----------
; Gets what the cursor colors at the specfied (row, column) should
; be. Here's the mapping:
;   pixel belongs to game board
;       color1 = current pixel color
;       color2 = yellow
;   pixel doesn't belong to game board
;       pixel off --> color1 = red, color2 = green
;       pixel one --> color1 = current pixel color,
;                       color2 = off
; row argument is passed in on r16, column on r17.
; color1 returned on r18, color2 on r19.
; The integer-to-color mapping is determined by OFF, RED, GREEN,
; and YELLOW constants defined in display.inc.
;
; Operational Description
; -----------------------
; Gets the pixel color at (row, color) and whether or not
; (row, color) belongs to the game board, and based on that
; information, returns the cursor colors in the manner
; described in the Description.
;
; Arguments
; ---------
; row (int, r16): row on grid
; column (int, r17): column on grid
;
; Return Values
; -------------
; int, r18: color1
; int, r19: color2
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; redBuffer: R
; greenBuffer: R
; gameBoard: R
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
; row/column out of grid bounds:
;   returns (OFF, OFF)
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
; r18, r19 (r16 and r17 preserved)
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
GetCursorColors:
    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; return values
    .def    color1 = r18
    .def    color2 = r19

    ;;; other registers needed
    ; general purpose register
    .def    tmp = r20
    push    r20

    ; need to overwrite column, so save it in here
    .def    columnTmp = r21
    push    columnTmp
    mov     columnTmp, column


    ;;; check validity of (row, column)
    rcall   RowColumnValid
    ; if valid, goto function body
    breq    GetCursorColorsBody
    ; otherwise, load OFF into color1 and color2 and return
    ldi     color1, OFF
    ldi     color2, OFF
    jmp     GetCursorColorsReturn

    
  GetCursorColorsBody:
    ;;; get the current pixel color at (row, column)
    ; already have r16 = row, r17 = column for args
    rcall   GetColor
    ; color1 now contains current color at (row, column)


    ;;; check if current pixel belongs to game board
    ; already have r16 = row, r17 = column for args
    rcall   PixelReserved
    ; z clear --> pixel not reserved by game board
    breq    GetCursorColorsNotReserved
    ; z set --> belongs to game board, so set color2 to yellow
    ldi     color2, YELLOW
    ; and done
    jmp     GetCursorColorsReturn


  GetCursorColorsNotReserved:
    ;;; figure out colors based on current pixel color
    cpi     color1, OFF
    ; if off, set color1 to red, color2 to green
    breq    GetCursorCurrentColorOff
    ; if not off, set color2 to off and keep color1
    ldi     color2, OFF
    ; and done
    jmp     GetCursorColorsReturn

  GetCursorCurrentColorOff:
    ; current color OFF, so set color1 red, color2 green
    ldi     color1, RED
    ldi     color2, GREEN
    ; and done
    ;jmp     GetCursorColorsReturn

  GetCursorColorsReturn:
    pop     columnTmp
    pop     tmp
    ret



; MoveCursor(dir)
; ===============
;
; Description
; -----------
; Moves the cursor in the specified dir (passed on r16); dir can be
;   0 -> up
;   1 -> left
;   2 -> down
;   3 -> right
; If cursor is against one of the edges on the display, wraps cursor
; around to the other side; e.g. if the cursor is at (3, 7) and
; we want to move the cursor right, the curosr will now be at (3, 0)
;
; Operational Description
; -----------------------
; Gets the current (row, column) and calls
; SetCursor with the following arguments:
;   up      --> r = row-1, c = column
;   left    --> r = row, c = column-1
;   down    --> r = row+1, c = column
;   right   --> r = row, c = column+1
; Arguments c1 and c2 determined by GetCursorColors(r, c)
;
; Arguments
; ---------
; dir (int, r16): direction in which to move cursor
;   0 --> up
;   1 --> left
;   2 --> down
;   3 --> right
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
; cursorRow: R
; cursorColumn: R
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
; dir not one of UP, LEFT, DOWN, RIGHT:
;   don't do anything, just return
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
; none (r16 preserved)
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
MoveCursor:
    ;;; arguments
    ; direction to move cursor
    .def    dir = r16
    push    dir

    ;;; other registers needed
    ; row to move cursor
    ; already pushed when we pushed dir
    .def    row = r16

    ; column to move cursor
    .def    column = r17
    push    column

    ; color1 of new cursor
    .def    color1 = r18
    push    color1

    ; color2 of new cursor
    .def    color2 = r19
    push    color2

    ; zero (for adc)
    .def    zero = r20
    push    zero
    clr     zero

    ; general purpose
    .def    tmp = r21
    push    tmp

    ; for loading from program memory
    push    zl
    push    zh

    ;;; check validity of dir
    .def    value1 = r16
    .def    value2 = r17
    .def    validFlag = r18
    push    validFlag

    ; initialize validFlag to TRUE
    ldi     validFlag, TRUE

    ; check dir >= UP
    push    value1
    push    value2
    ;mov     value1, dir
    ldi     value2, UP
    rcall   CheckValid
    pop     value2
    pop     value1

    ; check RIGHT >= dir
    push    value1
    push    value2
    mov     value2, dir
    ldi     value1, RIGHT
    rcall   CheckValid
    pop     value2
    pop     value1

    ; if valid, continue with function body
    cpi     validFlag, TRUE
    pop     validFlag
    breq    MoveCursorBody
    ; if not valid, just return
    jmp     MoveCursorReturn


  MoveCursorBody:
    ;;; get coords based on dir
    ; load DirToCoords table ito z
    ldi     zl, low(2 * DirToCoords)
    ldi     zh, high(2 * DirToCoords)
    ; offset = dir
    lsl     dir ; multiply dir by 2 to correct addressing
    add     zl, dir
    adc     zh, zero

    ; row diff is the first item
    lds     row, cursorRow
    lpm     tmp, z+
    add     row, tmp
    ; column diff is the second item
    lds     column, cursorColumn
    lpm     tmp, z
    add     column, tmp

    ;;; readjust (row, column) if needed
  ;MoveCursorCheckRowTooLarge:
    ; check if row exceeds NUM_ROWS
    cpi     row, NUM_ROWS
    ; if it's not too large, check if it's too small
    brlt    MoveCursorCheckRowTooSmall
    ; if it's too large, set to 0 and check column
    ldi     row, 0
    jmp     MoveCursorCheckColumnTooLarge

  MoveCursorCheckRowTooSmall:
    ; check if row under 0
    cpi     row, 0
    ; if it's not too small, check column
    brge    MoveCursorCheckColumnTooLarge
    ; if it's too small, set to NUM_ROWS and check column
    ldi     row, NUM_ROWS
    ;jmp     MoveCursorCheckColumnTooLarge

  MoveCursorCheckColumnTooLarge:
    ; check if column exceeds NUM_COLS
    cpi     column, NUM_COLS
    ; if it's not too large, check if it's too small
    brlt    MoveCursorCheckColumnTooSmall
    ; if it's too large, set to 0 and get colors we want for cursor
    ldi     column, 0
    jmp     MoveCursorGetColors

  MoveCursorCheckColumnTooSmall:
    ; check if column under 0
    cpi     column, 0
    ; if it's not too small, check column
    brge    MoveCursorGetColors
    ; if it's too small, set to NUM_COLS and get colors we want for cursor
    ldi     column, NUM_COLS
    ;jmp     MoveCursorGetColors


  MoveCursorGetColors:
    ;;; get the colors for the cursor to blink between
    ; already have r16 = row, r17 = column
    rcall   GetCursorColors
    ; returns (color1, color2) into our color1, color2

    ;;; set cursor
    ; already have r16 = row, r17 = column, r18 = color1, r19 = color2
    rcall   SetCursor


  MoveCursorReturn:
    ;;; return
    pop     zh
    pop     zl
    pop     tmp
    pop     zero
    pop     color2
    pop     color1
    pop     column
    pop     dir
    ret




; Beep(n)
; =======
;
; Description
; -----------
; Beeps frequency BEEP_FREQ for BEEP_LENGTH at user n times.
; n is passed on r16
;
; Operational Description
; -----------------------
; calls PlayNote(BEEP_FREQ), waits BEEP_LENGTH * 10ms, then
; calls PlayNote(0) to turn off speaker.
;
; Arguments
; ---------
; n (int, r16): number of times to beep
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
; None
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
; none (r16 preserved)
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
Beep:
    ;;; arguments
    .def    n = r16
    push    n

    ;;; other registers
    ; need this b/c we overwrite n's register
    .def    nCopy = r18
    push    nCopy
    mov     nCopy, n

    ; for PlayNote(BEEP_FREQ)
    .def    freql = r16
    .def    freqh = r17

    ; for Delay10ms(BEEP_LENGTH)
    .def    delayTimes = r16

  BeepLoop:
    ;;; play beep freq
    ldi     freql, low(BEEP_FREQ)
    ldi     freqh, high(BEEP_FREQ)
    rcall   PlayNote

    ;;; wait
    ldi     delayTimes, BEEP_LENGTH
    rcall   Delay10ms

    ;;; loop
    dec     nCopy
    brne    BeepLoop

    ; if n == 0, we're done
    pop     nCopy
    pop     n
    ret


; RotatePixelColor(row, column)
; =============================
; 
; Description
; -----------
; If the current pixel position is on the game board (i.e. reserved), beeps
; at user (doesn't change color).
; If the current pixel position is not on the game board (i.e. not reserved),
; changes the pixel color to the next color in the cycle. The cycle is:
;   off -> red -> green -> off -> red -> green -> etc.
; row passed in on r16, column on r17
;
; Operational Description
; -----------------------
; Calls PixelReserved(row, column) to determine whether or not to beep.
; If didn't beep, calls GetColor(row, column) to determine
; colors for PlotPixel(row, column, color) and
; SetCursor(row, column, color1, color2).
;
; Arguments
; ---------
; row (int, r16): row of pixel
; column (int, r16): column of pixel
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
; None
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
; row/column out of grid bounds:
;   doesn't do anything, just returns
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
; none (r16 and r17 preserved)
;
; Stack Depth
; -----------
; 4 bytes
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
RotatePixelColor:
    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; other registers needed
    ; color of pixel at (row, column)
    .def    color = r18
    push    color

    ; zero
    .def    zero = r19
    push    zero
    clr     zero

    ; for color rotation
    push    zl
    push    zh

    ;;; check validity of arguments
    ; arguments already r16 = row, r17 = column
    rcall   RowColumnValid
    ; if valid, continue with function body
    breq    RotatePixelColorBody
    ; if not valid, just return
    jmp     RotatePixelColorReturn

  RotatePixelColorBody:
    ;;; check if pixel is reserved
    ; arguments already r16 = row, r17 = column
    rcall   PixelReserved
    ; if not reserved, continue with pixel color rotation
    brne    RotatePixelColorRotate
    ; if reserved, beep once
    .def    n = r16
    push    n
    ldi     n, 1
    rcall   Beep
    pop     n
    ; and return
    jmp     RotatePixelColorReturn

  RotatePixelColorRotate:
    ;;; rotate the pixel color
    ; get the current pixel color
    ; arguments already r16 = row, r17 = column
    rcall   GetColor
    ; r18 = color

    ; load ColorRotation table ito z
    ldi     zl, low(2 * DirToCoords)
    ldi     zh, high(2 * DirToCoords)
    ; offset = color
    add     zl, color
    adc     zh, zero
    ; new color is ColorRotation[color]
    lpm     color, z

    ;;; plot pixel and set cursor
    ; arguments already r16 = row, r17 = column, r18 = color
    rcall   PlotPixel
    ; arguments already r16 = row, r17 = column
    rcall   GetCursorColors
    ; r18 = color1, r19 = color2
    ; arguments already r16 = row, r17 = column, r18 = color1, r19 = color2
    rcall   SetCursor


  RotatePixelColorReturn:
    ;;; and return
    pop     zh
    pop     zl
    pop     zero
    pop     color
    ret
