;;;;;;;;;;;;;;;
; binario.asm ;
;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for playing the binario game.
;
; Data Memory
; -----------
; gameBoard: NUM_ROWS x NUM_COLS boolean matrix where each element indicates
;   if that pixel in the LED grid belongs to the game board
; solution: NUM_ROWS x NUM_COLS boolean matrix that holds the solution of the
;   current game; a bit value of 1 indicates the pixel should be red while
;   a bit value of 0 indicates the pixel should be green
; lossIndicated: if true loss already has been indicated to user, so no need to
;   do it again; if false, need to indicate loss to user
;
; Tables
; ------
; DirToCoords: converts a direction to a coordinate vector
; ColorRotation: maps color to the next color in the rotation
;
; Routines
; --------
; InitBinarioVars: initializes binario shared variables
; LoadGameFromEEROM(addr): loads GAME_SPACE number of bytes from eerom[addr]
;   and plots onto display
; GetColor(row, column): gets the current color at (row, column)
; PixelReserved(row, column): determines if (row, column) is a
;   reserved pixel
; RowColumnValid(row, column): determines if (row, column) is on grid
; GetCursorColors(row, column): gets what the colors of the cursor
;   should be based on the current pixel color and reservation
;   at (row, column)
; MoveCursor: moves cursor Up, Down, Left, or Right from its current
;   position
; Beep(n): beeps at user n times
; RotatePixelColor(row, column): rotates the current pixel color
;   based on ColorRotation
; CheckWin: checks if the current display matches the current game board
;
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
; 06/04/2022    Matt Muldowney      load game function
; 06/04/2022    Matt Muldowney      init function
; 06/05/2022    Matt Muldowney      check win function
; 06/05/2022    Matt Muldowney      loss indicated flag for avoiding



.dseg
    gameBoard:      .byte NUM_COLS
    solution:       .byte NUM_COLS
    lossIndicated:  .byte 1



.cseg


; ##########
; # tables #
; ##########

; converts a direction (UP, LEFT, DOWN, RIGHT) to a 
; coordinate vector to add to (cursorRow, cursorColumn)
DirToCoords:
    .db -1, 0   ; UP
    .db 0, -1   ; LEFT
    .db 1, 0    ; DOWN
    .db 0, 1    ; RIGHT

; performs the following mapping:
;   OFF -> RED
;   RED -> GREEN
;   GREEN -> OFF
;   YELLOW -> YELLOW
ColorRotation:
    .db RED, GREEN, OFF, YELLOW


; Contains welcome screens to send to PlotImage.
; The message to scroll is "<Binario> Select a Game"
; Each word is a column in the display, with the red column in the high byte
; and the green column in the low byte.
; The table is designed to be scrolled one column at a time.
WelcomeScreen:
    ; this first column also helps us define the column size
    .db     0b00000000, 0b00000000

    ; define the size of each column
    .equ    WelcomeScreen_COL_SIZE = pc - WelcomeScreen

    ; blank
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; arrow
    .db     0b00011000, 0b00011000
    .db     0b00111100, 0b00111100
    .db     0b01111110, 0b01111110
    .db     0b11111111, 0b11111111
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; B
    .db     0b10000001, 0b00000000
    .db     0b11111111, 0b00000000
    .db     0b10010001, 0b00000000
    .db     0b10010001, 0b00000000
    .db     0b01101110, 0b00000000
    .db     0b00000000, 0b00000000

    ; i
    .db     0b00000000, 0b00000001
    .db     0b00000000, 0b00100111
    .db     0b00000000, 0b00000001
    .db     0b00000000, 0b00000000

    ; n
    .db     0b00010000, 0b00010000
    .db     0b00011111, 0b00011111
    .db     0b00001000, 0b00001000
    .db     0b00010000, 0b00010000
    .db     0b00010000, 0b00010000
    .db     0b00001111, 0b00001111
    .db     0b00000000, 0b00000000

    ; a
    .db     0b00100110, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00011111, 0b00000000
    .db     0b00000001, 0b00000000
    .db     0b00000000, 0b00000000

    ; r
    .db     0b00000000, 0b00000001 
    .db     0b00000000, 0b00001111 
    .db     0b00000000, 0b00010001 
    .db     0b00000000, 0b00010000 
    .db     0b00000000, 0b00001000 
    .db     0b00000000, 0b00000000

    ; i
    .db     0b00000001, 0b00000001
    .db     0b00100111, 0b00100111
    .db     0b00000001, 0b00000001
    .db     0b00000000, 0b00000000

    ; o
    .db     0b00001110, 0b00000000
    .db     0b00010001, 0b00000000
    .db     0b00010001, 0b00000000
    .db     0b00001110, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; arrow
    .db     0b11111111, 0b11111111
    .db     0b01111110, 0b01111110
    .db     0b00111100, 0b00111100
    .db     0b00011000, 0b00011000
    .db     0b00000000, 0b00000000

    ; blank
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; S
    .db     0b01100010, 0b00000000
    .db     0b10010001, 0b00000000
    .db     0b10010001, 0b00000000
    .db     0b10010001, 0b00000000
    .db     0b01001110, 0b00000000
    .db     0b00000000, 0b00000000

    ; e
    .db     0b00011110, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00011010, 0b00000000
    .db     0b00000000, 0b00000000

    ; l
    .db     0b10000001, 0b00000000
    .db     0b11111111, 0b00000000
    .db     0b00000001, 0b00000000
    .db     0b00000000, 0b00000000

    ; e
    .db     0b00011110, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00101001, 0b00000000
    .db     0b00011010, 0b00000000
    .db     0b00000000, 0b00000000

    ; c
    .db     0b00011110, 0b00000000
    .db     0b00100001, 0b00000000
    .db     0b00100001, 0b00000000
    .db     0b00100001, 0b00000000
    .db     0b00010010, 0b00000000
    .db     0b00000000, 0b00000000

    ; t
    .db     0b01000000, 0b00000000
    .db     0b11111110, 0b00000000
    .db     0b01000001, 0b00000000
    .db     0b01000010, 0b00000000
    .db     0b00000000, 0b00000000

    ; space
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; a
    .db     0b00000000, 0b00100110
    .db     0b00000000, 0b00101001
    .db     0b00000000, 0b00101001
    .db     0b00000000, 0b00011111
    .db     0b00000000, 0b00000001
    .db     0b00000000, 0b00000000

    ; space
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; G
    .db     0b01111110, 0b01111110
    .db     0b10000001, 0b10000001
    .db     0b10010001, 0b10010001
    .db     0b10010001, 0b10010001
    .db     0b01011110, 0b01011110
    .db     0b00000000, 0b00000000

    ; a
    .db     0b00100110, 0b00100110
    .db     0b00101001, 0b00101001
    .db     0b00101001, 0b00101001
    .db     0b00011111, 0b00011111
    .db     0b00000001, 0b00000001
    .db     0b00000000, 0b00000000

    ; m
    .db     0b00010000, 0b00010000
    .db     0b00011111, 0b00011111
    .db     0b00001000, 0b00001000
    .db     0b00010000, 0b00010000
    .db     0b00001111, 0b00001111
    .db     0b00010000, 0b00010000
    .db     0b00001111, 0b00001111
    .db     0b00000000, 0b00000000

    ; e
    .db     0b00011110, 0b00011110
    .db     0b00101001, 0b00101001
    .db     0b00101001, 0b00101001
    .db     0b00101001, 0b00101001
    .db     0b00011010, 0b00011010
    .db     0b00000000, 0b00000000

    ; blank
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000

    ; number of columns in the table
    .equ    WelcomeScreen_COL_CNT = (pc - WelcomeScreen) / WelcomeScreen_COL_SIZE

    ; blank
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000
    .db     0b00000000, 0b00000000



; InitBinarioVars
; ===============
;
; Description
; -----------
; Initializes shared vars for the binario game.
;
; Operational Description
; -----------------------
; Sets shared vars for the binario game to their initial value.
; For gameBoard, sets each column to FALSE.
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
; None
;
; Local Variables
; ---------------
; falseReg: holds false
; idx: loop index for clearing game board
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
InitBinarioVars:
    push  r16
    push  r17
    push  yl
    push  yh

    ; for holding FALSE
    .def    falseReg = r16

    ; loop index
    .def    idx = r17


    ;;; intialize game board to all FALSE, such that the game board
    ;;;   doesn't initially reserve any pixels
    ldi     falseReg, FALSE
    ldi     idx, NUM_COLS
  InitBinarioVarsClearGameBoardLoop:
    st      y+, falseReg
    dec     idx
    brne    InitBinarioVarsClearGameBoardLoop


    ;;; initialize lossIndicated to false
    ldi     falseReg, FALSE
    sts     lossIndicated, falseReg

    pop     yh
    pop     yl
    pop     r17
    pop     r16
    ret


; DisplayWelcome
; ==============
;
; Description
; -----------
; Scrolls the WelcomeScreen table across the display.
; The message is "<Binario> Select a Game"
;
; Operational Description
; -----------------------
; Loops through program memory WelcomeScreen_COL_CNT times starting at WelcomeScreen.
;
; Arguments
; ---------
; none
;
; Return Values
; -------------
; none
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; none
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
; none
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
; 14 bytes
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
DisplayWelcome:
    push    r16
    push    r20
    push    zl
    push    zh

    ; number of 10ms delays between each scroll
    .def    numDelays = r16

    ; loop counter
    .def    numColsLeft = r20

    ; load starting point of table
    ldi     zl, low(2 * WelcomeScreen)
    ldi     zh, high(2 * WelcomeScreen)
    ; get number of columns to scroll
    ldi     numColsLeft, WelcomeScreen_COL_CNT

  DisplayWelcomeLoop:
    ; plot the current screen
    rcall   PlotImage

    ; delay 100 ms between scrolls
    ldi     numDelays, 10
    rcall   Delay10ms

    ; scroll display
    adiw    z, 2 * WelcomeScreen_COL_SIZE
    ; update loop counter and keep looping until it hits 0
    dec     numColsLeft
    brne    DisplayWelcomeLoop

    ;;; all done
    pop     zh
    pop     zl
    pop     r20
    pop     r16



; LoadGameFromEEROM(addr)
; ==============================
;
; Description
; -----------
; Plots pixels on the LED display according to data stored at EEROM addr (r17).
; It is assumed that, at addr, the first 8 bytes correspond to the game's
; solution and the next 8 bytes correspond to the fixed positions.
; For the solution bytes, a bit value of 1 indicates that pixel is red, while a
; bit value of 0 indicates that pixel is green.
; For the fixed positions, a bit value of 1 indicates that pixel is reserved by
; the game board, while a bit value of 0 indicates that pixel can be changed by
; the user (thus, the fixed position bytes are loaded directly into gameBoard).
;
; Operational Description
; -----------------------
; Reads eerom[addr] into solution and eerom[addr+NUM_COLS] into gameBoard.
; Then, loops the following NUM_COLS times:
;   * red buffer[col] = solution[col] && gameBoard[col]
;   * green buffer[col] = !solution[addr] && gameBoard[col]
;
; Arguments
; ---------
; addr: byte address in EEROM
;
; Return Values
; -------------
; none
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; gameBoard: W
; solution: W
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
; None (ReadEEROM handles bad addr argument)
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
LoadGameFromEEROM:
    push    r16
    push    r18
    push    r19
    push    xl
    push    xh
    push    yl
    push    yh
    push    zl
    push    zh

    ;;; arguments
    .def    addr = r17

    ;;; other registers needed
    ; holds NUM_COLS
    .def    numColsReg = r16

    ; current solution column
    .def    solutionColumn = r18
    ; current gameBoard column
    ; reuse r18 since we don't need at same time as solution
    .def    gameBoardColumn = r18

    ; the current red buffer column
    .def    redColumn = r19
    ; the current green buffer column
    ; reuse r19 since we don't need at same time as redColumn
    .def    greenColumn = r19

    ;;; read NUM_COLS bytes from eerom[addr] into solution
    ldi     r16, NUM_COLS
    ; r17 already contains eerom addr
    ldi     yl, low(solution)
    ldi     yh, high(solution)
    ; ReadEEROM(NUM_COLS, addr, solution)
    rcall   ReadEEROM

    ;;; read NUM_COLS bytes from eerom[addr+NUM_COLS] into gameBoard
    subi    addr, -NUM_COLS
    ldi     yl, low(gameBoard)
    ldi     yh, high(gameBoard)
    ; ReadEEROM(NUM_COLS, addr + NUM_COLS, gameBoard)
    rcall   ReadEEROM


    ;;; load up red buffer and green buffer
    ; in this first loop, we load red/greenBuffer according to solution

    ; x will point to solution
    ldi     xl, low(solution)
    ldi     xh, high(solution)

    ; y will point to red buffer 
    getRedBuffer    yh, yl

    ; z will point to green buffer
    getGreenBuffer  zh, zl

  LoadGameFromEEROMSolutionLoop:
    ; get current solution column
    ld      solutionColumn, x+

    ; red buffer[col] = solution[col]
    st      y+, solutionColumn

    ; green buffer[col] = !solution[col]
    com     solutionColumn
    st      z+, solutionColumn

    ; numColsReg is our indexer (initialized to NUM_COLS)
    dec     numColsReg
    ; when it hits 0, we're done
    brne    LoadGameFromEEROMSolutionLoop


    ; in this second loop, we and red/greenBuffer with gameBoard to
    ;   just get the pixels that are reserved by the gameBoard

    ; x will point to gameBoard
    ldi     xl, low(gameBoard)
    ldi     xh, high(gameBoard)

    ; y will point to red buffer 
    getRedBuffer    yh, yl

    ; z will point to green buffer
    getGreenBuffer    zh, zl

    ; reinitialize numColsReg (our indexer)
    ldi     numColsReg, NUM_COLS
  LoadGameFromEEROMGameBoardLoop:
    ; get current col of game board
    ld      gameBoardColumn, x+

    ; get current col of red buffer
    ld      redColumn, y

    ; mask off game board bits
    and     redColumn, gameBoardColumn
  
    ; store back in red buffer
    st      y+, redColumn

    ; get current col of green buffer
    ld      greenColumn, z

    ; mask off game board bits
    and     greenColumn, gameBoardColumn
  
    ; store back in green buffer
    st      z+, greenColumn

    ; numColsReg is our indexer (initialized to NUM_COLS)
    dec     numColsReg
    ; when it hits 0, we're done
    brne    LoadGameFromEEROMGameBoardLoop
    

    ;;; all done, so return
  LoadGameFromEEROMReturn:
    pop     zh
    pop     zl
    pop     yh
    pop     yl
    pop     xh
    pop     xl
    pop     r19
    pop     r18
    pop     r16
    ret


; GetColor(row, column)
; =====================
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
; The color mapping has been setup in a way such that the bit 0
; of the color indicates if the red LED should be on, and bit 1
; of the color indicates if the green LED should be on.
; So, we simply set color[0] = red buffer[row, column], and
; color[1] = greenBuffer[row, column].
;
; Arguments
; ---------
; row (int, r16): row on grid
; column (int, r17): column on grid
;
; Return Values
; -------------
; int, r18: color
;
; Global Variables
; ----------------
; None
;
; Shared Variables
; ----------------
; none
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
; r18
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
GetColor:
    push    yl
    push    yh

    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; return values
    .def    color = r18
    clr     color


    ;;; get the current pixel color at (row, column)
    ; put red buffer[row, column] in t flag
    getRedBuffer    yh, yl
    buffElementToT  y, row, column
    ; load it into color[0]
    bld     color, 0

    ; put greenBuffer[row, column] in t flag
    getGreenBuffer  yh, yl
    buffElementToT  y, row, column
    ; load it into color[1]
    bld     color, 1
    ; color now contains current color at (row, column)

    ; return
    pop     yh
    pop     yl
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
; none
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
    push    yl
    push    yh

    ;;; arguments
    .def    row = r16
    .def    column = r17

    ; put gameBoard[row, column] in t flag
    ldi     yl, low(gameBoard)
    ldi     yh, high(gameBoard)
    buffElementToT  y, row, column

    ; t set --> reserved
    brts    PixelReservedReturnTrue
    ; t clear --> not reserved
    clz
    jmp     PixelReservedReturn
  PixelReservedReturnTrue:
    sez

  PixelReservedReturn:
    pop     yh
    pop     yl
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
GetCursorColors:
    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; return values
    .def    color1 = r18
    .def    color2 = r19

    ;;; check validity of (row, column)
    ; 0 <= row <= NUM_ROWS - 1
    withinBounds    row, 0, NUM_ROWS
    ; if not within bounds, return without doing anything
    ; 0 <= column <= NUM_COLS - 1
    brtc    GetCursorColorsReturn
    ; 0 <= col <= NUM_COLS - 1
    withinBounds    column, 0, NUM_COLS
    ; if not within bounds, return without doing anything
    brtc    GetCursorColorsReturn

    
  GetCursorColorsBody:
    ;;; get the current pixel color at (row, column)
    ; already have r16 = row, r17 = column for args
    rcall   GetColor
    ; color1 now contains current color at (row, column)

    ;;; check if current pixel belongs to game board
    ; already have r16 = row, r17 = column for args
    rcall   PixelReserved
    ; z clear --> pixel not reserved by game board
    brne    GetCursorColorsNotReserved
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

  GetCursorColorsReturn:
    ret



; MoveCursor(dir)
; ===============
;
; Description
; -----------
; Moves the cursor in the specified dir (passed on r16); dir can be
;   UP -> up
;   LEFT -> left
;   DOWN -> down
;   RIGHT -> right
; See binario.inc for values of consts.
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
;   UP --> up
;   LEFT --> left
;   DOWN --> down
;   RIGHT --> right
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
; none
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
    push    r16
    push    r17
    push    r18
    push    r19
    push    r20
    push    r21
    push    r22
    push    r23
    push    zl
    push    zh

    ;;; arguments
    ; direction to move cursor
    .def    dir = r16

    ;;; other registers needed
    ; row to move cursor
    .def    row = r16
    ; column to move cursor
    .def    column = r17
    ; color1 of new cursor
    .def    color1 = r18
    ; color2 of new cursor
    .def    color2 = r19

    ; zero (for adc)
    .def    zero = r20
    clr     zero

    ; general purpose
    .def    tmp = r21

    ; loop var for performing same logic on row, column adjustment
    .def    loopVar = r22

    ; for adjusting row and column
    .def    adjustParam = r23

    ;;; check validity of dir
    ; must have UP <= dir <= RIGHT
    withinBounds  dir, UP, RIGHT
    ; if condition not satisfied, just return
    brts    MoveCursorDirToCoords
    ; the reason why we don't just do a brtc to MoveCursorReturn is because
    ;   it is out of range
    jmp     MoveCursorReturn


  MoveCursorDirToCoords:
    ;;; get coords based on dir
    ; load DirToCoords table ito z
    ldi     zl, low(2 * DirToCoords)
    ldi     zh, high(2 * DirToCoords)
    ; offset = dir
    lsl     dir ; multiply dir by 2 to correct addressing
    add     zl, dir
    adc     zh, zero

    ; get the current cursor (row, column)
    getCursorPosition   row, column

    ; row diff is the first item
    lpm     tmp, z+
    add     row, tmp
    ; column diff is the second item
    lpm     tmp, z
    add     column, tmp


    ;;; readjust (row, column) if needed
    ; row/col > upper bound --> set to lower bound
    ; row/col < lower bound --> set to upper bound
    rotateOutOfBounds   row, 0, NUM_ROWS-1
    rotateOutOfBounds   column, 0, NUM_COLS-1


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
    pop     r23
    pop     r22
    pop     r21
    pop     r20
    pop     r19
    pop     r18
    pop     r17
    pop     r16
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
    push    r16
    push    r17
    push    r18

    ;;; arguments
    .def    n = r16

    ;;; other registers
    ; need this b/c we overwrite n's register
    .def    nCopy = r18
    mov     nCopy, n

    ; for PlayNote(BEEP_FREQ)
    .def    freql = r16
    .def    freqh = r17

    ; for Delay10ms(BEEP_LENGTH)
    .def    numDelays = r16

  BeepLoop:
    ;;; play beep freq
    ldi     freql, low(BEEP_FREQ)
    ldi     freqh, high(BEEP_FREQ)
    rcall   PlayNote

    ;;; wait
    ldi     numDelays, BEEP_LENGTH
    rcall   Delay10ms

    ;;; play 0 Hz freq
    clr     freql
    clr     freqh
    rcall   PlayNote

    ;;; wait
    ldi     numDelays, BEEP_LENGTH
    rcall   Delay10ms

    ;;; loop
    dec     nCopy
    brne    BeepLoop

    ; if n == 0, we're done
    pop     r18
    pop     r17
    pop     r16
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
    push    r16
    push    r18
    push    r19
    push    zl
    push    zh

    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; other registers needed
    ; color of pixel at (row, column)
    .def    color = r18

    ; zero
    .def    zero = r19
    clr     zero

    ; number of times to beep at user if they attempt to write a reserved space
    ; reuse r16 b/c we don't need at the same time as row
    .def    n = r16

    ;;; check validity of (row, column)
    ; 0 <= row <= NUM_ROWS - 1
    withinBounds    row, 0, NUM_ROWS
    ; if not within bounds, return without doing anything
    ; 0 <= column <= NUM_COLS - 1
    brtc    RotatePixelColorReturn
    ; 0 <= col <= NUM_COLS - 1
    withinBounds    column, 0, NUM_COLS
    ; if not within bounds, return without doing anything
    brtc    RotatePixelColorReturn
    ; otherwise, continue with function body


    ;;; check if pixel is reserved
    ; arguments already r16 = row, r17 = column
    rcall   PixelReserved
    ; if not reserved, continue with pixel color rotation
    brne    RotatePixelColorRotate
    ; if reserved, beep once
    ldi     n, 1
    rcall   Beep
    ; and return
    jmp     RotatePixelColorReturn

  RotatePixelColorRotate:
    ;;; rotate the pixel color
    ; get the current pixel color
    ; arguments already r16 = row, r17 = column
    rcall   GetColor
    ; r18 = color

    ; load ColorRotation table ito z
    ldi     zl, low(2 * ColorRotation)
    ldi     zh, high(2 * ColorRotation)
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
    pop     r19
    pop     r18
    pop     r16
    ret




; CheckWin
; ========
; 
; Description
; -----------
; Checks if the current display matches the current game solution.
; If it does match, sets state to STATE_WIN. Otherwise, sets state
; to STATE_LOSS
;
; Operational Description
; -----------------------
; Calls DisplayFilled to check that display is filled. If it isn't, returns
; without doing anything. If it is, loops the following NUM_COLS times:
;   * if red buffer[col] != solution[col], sets state to STATE_LOSS
;   * if green buffer[col] != !solution[col], sets state to STATE_LOSS
; If we successfully exit the loop, sets state to STATE_WIN.
;
; Arguments
; ---------
; none
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
; solution: R
; lossIndicated: RW
;
; Local Variables
; ---------------
; columnNumber (int): loop var for looping through columns in buffers
; redBufferCol: holds current redBuffer[col]
; greenBufferCol: holds current greenBuffer[col]
; solutionCol: holds current solution[col]
; stateReg (int): for updating state if necessary
; lossIndicatedReg (int): read/write of lossIndicated flag
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
; none
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
; 16 bytes
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
CheckWin:
    push    r16
    push    r17
    push    r18
    push    xl
    push    xh
    push    yl
    push    yh
    push    zl
    push    zh

    ;;; registers needed
    ; loop var
    .def    columnNumber = r16
    ; for holding red buffer[col]
    .def    redBufferCol = r17
    ; for holding green buffer[col]
    ; reuse r17 because don't need at same time as redBufferCol
    .def    greenBufferCol = r17
    ; for holding solution[col]
    .def    solutionCol = r18
    ; for updating state
    ; reuse r16 since don't need at same time as columnNumber
    .def    stateReg = r16
    ; for RW of lossIndicated
    ; reuse r16 since don't need at same time as stateReg
    .def    lossIndicatedReg = r16

    ;;; check if display is completely filled
    rcall   DisplayFilled
    ; if not, don't do anything, just return
    brne    CheckWinReturn
    ; otherwise, continue on with checking win


    ;;; load up buffers
    ; x points at solution
    ldi     xl, low(solution)
    ldi     xh, high(solution)
    ; y points at red buffer
    getRedBuffer    yh, yl
    ; z points at green buffer
    getGreenBuffer  zh, zl


    ;;; loop columns
    ; initialize loop counter
    ldi     columnNumber, NUM_COLS
  CheckWinLoop:
    ; get solution[col]
    ld      solutionCol, x+
    ; get red buffer[col]
    ld      redBufferCol, y+
    ; check solution[col] == red buffer[col]
    cp      redBufferCol, solutionCol
    ; if not equal, beep at user to tell them it's incorrect
    brne    CheckWinIndicateLoss
    ; if they are equal, continue on

    ; get greenBuffer[col]
    ld      greenBufferCol, z+
    ; check !solution[col] == greenBuffer[col]
    com     solutionCol
    cp      greenBufferCol, solutionCol
    ; if not equal, goto loss state
    brne    CheckWinIndicateLoss
    ; if they are equal, continue on by relooping
    
    ; reloop by decrementing columnNumber, until it's 0
    dec     columnNumber
    brne    CheckWinLoop
    

    ;;; if we've reached this point, the user has won, so goto win state
    setState    STATE_WIN
    ; and done
    jmp     CheckWinReturn


  CheckWinIndicateLoss:
    ;;; display is filled, but user hasn't won
    ; check if loss already indicated
    lds     lossIndicatedReg, lossIndicated
    cpi     lossIndicatedReg, TRUE
    ; if it has, no need to goto loss state
    breq    CheckWinReturn

    ; otherwise, indicate loss
    ldi     lossIndicatedReg, TRUE
    sts     lossIndicated, lossIndicatedReg
    ; and goto loss state
    setState    STATE_LOSS
    ; and done


  CheckWinReturn:
    pop     zh
    pop     zl
    pop     yh
    pop     yl
    pop     xh
    pop     xl
    pop     r18
    pop     r17
    pop     r16
    ret


