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
; Data Memory
; -----------
; topOfStack: initial location of stack pointer; defines the stack depth, so
;   must be the first item in dseg
; gameBoard: NUM_ROWS x NUM_COLS boolean matrix where each element indicates
;   if that pixel in the LED grid belongs to the game board
; solution: NUM_ROWS x NUM_COLS boolean matrix that holds the solution of the
;   current game; a bit value of 1 indicates the pixel should be red while
;   a bit value of 0 indicates the pixel should be green
; gameNumber: the # game currently shown; starts at 0
; state: the current state of the main loop; one of STATE_INTRO, STATE_SELECT,
;   STATE_PLAY, STATE_WIN
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


;set the device
.device ATMEGA64

; chip definitions
.include  "m64def.inc"

; local include files
.include "timers.inc"
.include "ports.inc"
.include "switches.inc"
.include "util.inc"
.include "display.inc"
.include "serial.inc"
.include "sound.inc"
.include "binario.inc"


.dseg
                .byte STACK_DEPTH
    TopOfStack:	.byte 1

    gameBoard:  .byte NUM_COLS
    solution:   .byte NUM_COLS
    gameNumber: .byte 1
    state:      .byte 1



.cseg

;setup the vector area

.org    $0000

        JMP     Main                    ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        JMP     Timer0EventHandler      ;timer 0 compare match
        JMP     PC                      ;timer 0 overflow
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compare match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready


; maps a state index (STATE_INTRO, STATE_SELECT, STATE_PLAY, STATE_WIN) to a
; state function handler
MainLoopTab:
    .dw     StateIntro
    .dw     StateSelect
    .dw     StatePlay
    .dw     StateWin


; converts an action ()
ActionToDir:
    .db 0, 0, 0, LEFT, RIGHT, UP, DOWN


; TODO: document
Main:
    ; initialize stack pointer
    ldi     r16, low(topOfStack)
    out     spl, r16
    ldi     r16, high(topOfStack)
    out     sph, r16

    ; initialize the game components
    rcall   InitEverything


MainLoop:
    ; argument to state function (initialize to NO_ACTION)
    .def    stateArg = r16
    ldi     stateArg, NO_ACTION

    ; current state main loop is in
    .def    stateReg = r17
    lds     stateReg, state

    ; just holds 0 (for 16-bit, 8-bit addition)
    .def    zero = r18
    clr     zero

    ;;; check listeners for switch presses/rotations
    ;;; if a listener returns true, set the stateArg accordingly
    rcall   LRSwitch
    brne    MainLoopCheckUDSwitch
    ldi     stateArg, LR_SWITCH
  MainLoopCheckUDSwitch:
    rcall   UDSwitch
    brne    MainLoopCheckLeftRot
    ldi     stateArg, UD_SWITCH
  MainLoopCheckLeftRot:
    rcall   LeftRot
    brne    MainLoopCheckRightRot
    ldi     stateArg, LEFT_ROT
  MainLoopCheckRightRot:
    rcall   RightRot
    brne    MainLoopCheckUpRot
    ldi     stateArg, RIGHT_ROT
  MainLoopCheckUpRot:
    rcall   UpRot
    brne    MainLoopCheckDownRot
    ldi     stateArg, UP_ROT
  MainLoopCheckDownRot:
    rcall   DownRot
    brne    MainLoopCallStateFunction
    ldi     stateArg, DOWN_ROT


  MainLoopCallStateFunction:
    ; point z at MainLoopTab
    ldi     zl, low(2*MainLoopTab)
    ldi     zh, high(2*MainLoopTab)

    ; just in case state is out of range, put it back in range
    rotateOutOfBounds   stateReg, STATE_INTRO, STATE_WIN
    sts     state, stateReg

    ; offset MainLoopTab pointer by state
    ; since word addressed, have to multiply state by 2 (i.e. lsl)
    lsl     stateReg
    add     zl, stateReg
    adc     zh, zero

    ; call state function (note that argument already loaded into r16)
    lpm     r0, z+
    lpm     r1, z
    movw    z, r1:r0
    icall
    
    ; reloop
    rjmp    MainLoop



StateIntro:
    ;;; go to game select state
    ldi     r16, STATE_SELECT
    sts     state, r16

    ;;; initial game board load from eerom
    loadGameNumber
    ret



; StateSelect(stateArg)
; =====================
;
; Description
; -----------
; Handler for when main loop is in STATE_SELECT state, i.e. the state
; in which the user is selecting a game board to play. The user can
; rotate the Up/Down rotary encoder to flip between games and then
; select a game by pressing the Up/Down switch.
; StateSelect deduces what to do based on the passed in stateArg (r16),
; which can be NO_ACTION, UP_ROT, DOWN_ROT, or UD_SWITCH.
;
; Operational Description
; -----------------------
; Here is the mapping from stateArg (r16) to action:
;   NO_ACTION --> return without doing anything
;   UP_ROT    --> increment gameNumber mod NUM_GAMES
;   DOWN_ROT  --> decrement gameNumber mod NUM_GAMES
;   UD_SWITCH --> set state = STATE_PLAY
;
; Arguments
; ---------
; stateArg (int, r16): indicates the action that took place during the
;   previous loop of main
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
; r0, r1, r16, r17, r18
;
; Stack Depth
; -----------
; 19 bytes
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
StateSelect:
    ;;; arguments
    ; indicates action that just took place (e.g. up rotation, lr switch press,
    ;   etc.)
    .def    stateArg = r16

    ; for loading current game #
    .def    gameNumberReg = r17
    lds     gameNumberReg, gameNumber

    ; for multiplying gameNumber to compute eerom address
    .def    gameSpaceReg = r18
    ldi     gameSpaceReg, GAME_SPACE

    ; check for no action
    cpi     stateArg, NO_ACTION
    ; if no action, return without doing anything
    breq    StateSelectReturn

    ; check for up rotation
    cpi     stateArg, UP_ROT
    ; if no up rotation, check down rotation
    brne    StateSelectCheckDownRot
    ; if up rotation, gameNumberReg++
    inc     gameNumberReg
    ; goto game load
    rjmp    StateSelectLoadGame

  StateSelectCheckDownRot:
    ; check for down rotation
    cpi     stateArg, DOWN_ROT
    ; if no down rotation, check ud switch press
    brne    StateSelectCheckUDSwitch
    ; if down rotation, gameNumberReg--
    dec     gameNumberReg
    ; goto game load
    ;rjmp    StateSelectLoadGame

  StateSelectLoadGame:
    ; gameNumber % NUM_GAMES
    rotateOutOfBounds   gameNumberReg, 0, NUM_GAMES-1
    ; store new game number value back in data memory
    sts     gameNumber, gameNumberReg

    ; load the game stored at the index gameNumber in eerom
    loadGameNumber

    ; and done
    rjmp    StateSelectReturn


  StateSelectCheckUDSwitch:
    ; check for ud switch press
    cpi     stateArg, UD_SWITCH
    ; if no switch press, nothing to do
    brne    StateSelectReturn
    ; if switch press, user has selected this game, so goto play game state
    ldi     r16, STATE_PLAY
    sts     state, r16
    ; and done

  StateSelectReturn:
    ret



    

StatePlay:
    ;;; arguments
    ; action on previous loop of main
    .def    stateArg = r16

    ;;; other registers needed
    ; holds 0 (for 16-bit, 8-bit addition)
    .def    zero = r17

    ;;; check if nothing happened
    cpi     stateArg, NO_ACTION
    ; if nothing happened, just return
    breq    StatePlayReturn


    ;;; check if lr switch pressed
    cpi     stateArg, LR_SWITCH
    ; if lr switch not pressed, check ud switch
    brne    StatePlayCheckUDSwitch
    ; if lr switch pressed, rotate color at the current cursor position
    lds     r16, cursorRow
    lds     r17, cursorColumn
    rcall   RotatePixelColor
    ; and done
    rjmp    StatePlayReturn


  StatePlayCheckUDSwitch:
    ;;; check if ud switch pressed
    cpi     stateArg, UD_SWITCH
    ; if ud switch not pressed, then the action must have been to move
    ;   the cursor
    brne    StatePlayMoveCursor
    ; if ud switch pressed, reset game by loading the current game
    ;   at index gameNumber in eerom
    rcall   ClearDisplay
    loadGameNumber
    ; and done
    rjmp    StatePlayReturn


  StatePlayMoveCursor:
    ;;; if we've reached this point, the action must have been a turn of
    ;;;   the rotary encoders, so move cursor according to the turn
    ; load ActionToDir table
    ldi     zl, low(2 * ActionToDir)
    ldi     zh, high(2 * ActionToDir)
    ; stateArg (which indicates action) is the offset
    clr     zero
    add     zl, stateArg
    adc     zh, zero
    ; load the direction to move cursor
    lpm     r16, z
    ; MoveCursor(ActionToDir[stateArg])
    rcall   MoveCursor
    ; and done


  StatePlayReturn:
    ret


StateWin:
    ret



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


; InitEverything
; ==============
;
; Description
; -----------
; Initializes everything for the binario game, including:
;   * binario game vars, etc.
;   * switches and rotary encoders
;   * LED display
;   * speaker
;   * serial i/o
;   * i/o ports
;   * timers
; Also turns on interrupts.
;
; Operational Description
; -----------------------
; Calls various init functions.
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
; r16, r17
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
InitEverything:
    ; initialize binario vars
    rcall   InitBinarioVars

    ; initialize switches/rotary encoders
    rcall   InitSwitchPort
    rcall   InitSwitchVars

    ; initialize display
    rcall   InitDisplayPorts
    rcall   InitDisplayVars

    ; initialize sound
    rcall   InitSoundPort
    ; initialize speaker by playing 0 Hz frequency
    clr     r17
    clr     r16
    rcall   PlayNote

    ; initialize serio io
    rcall   InitSerialIO


    ; initialize timers
    rcall   InitTimer0
    rcall   InitTimer1

    ; turn on interrupts
    sei

    ; all ready to go!
    ret


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
    ; for holding GAME_NUMBER_INIT
    ; reuse r16 b/c don't need at same time as falseReg
    .def    gameNumberInitReg = r16
    ; for holding STATE_INIT
    ; reuse r16 b/c don't need at same time as gameNumberInitReg
    .def    stateInitReg = r16

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


    ;;; initialize first game stored in eerom to display
    ldi     gameNumberInitReg, GAME_NUMBER_INIT
    sts     gameNumber, gameNumberInitReg


    ;;; initialize initial game state
    ldi     stateInitReg, STATE_INIT
    sts     state, stateInitReg

    pop     yh
    pop     yl
    pop     r17
    pop     r16
    ret



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
;   * redBuffer[col] = solution[col] && gameBoard[col]
;   * greenBuffer[col] = !solution[addr] && gameBoard[col]
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
; redBuffer: W
; greenBuffer: W
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

    ; the current redBuffer column
    .def    redColumn = r19
    ; the current greenBuffer column
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


    ;;; load up redBuffer and greenBuffer
    ; in this first loop, we load red/greenBuffer according to solution

    ; x will point to solution
    ldi     xl, low(solution)
    ldi     xh, high(solution)

    ; y will point to redBuffer 
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)

    ; z will point to green buffer
    ldi     zl, low(greenBuffer)
    ldi     zh, high(greenBuffer)

  LoadGameFromEEROMSolutionLoop:
    ; get current solution column
    ld      solutionColumn, x+

    ; redBuffer[col] = solution[col]
    st      y+, solutionColumn

    ; greenBuffer[col] = !solution[col]
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

    ; y will point to redBuffer 
    ldi     yl, low(redBuffer)
    ldi     yh, high(redBuffer)

    ; z will point to green buffer
    ldi     zl, low(greenBuffer)
    ldi     zh, high(greenBuffer)

    ; reinitialize numColsReg (our indexer)
    ldi     numColsReg, NUM_COLS
  LoadGameFromEEROMGameBoardLoop:
    ; get current col of game board
    ld      gameBoardColumn, x+

    ; get current col of redBuffer
    ld      redColumn, y

    ; mask off game board bits
    and     redColumn, gameBoardColumn
  
    ; store back in redBuffer
    st      y+, redColumn

    ; get current col of greenBuffer
    ld      greenColumn, z

    ; mask off game board bits
    and     greenColumn, gameBoardColumn
  
    ; store back in redBuffer
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
; So, we simply set color[0] = redBuffer[row, column], and
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
; redBuffer: R
; greenBuffer: R
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
    ;;; arguments
    .def    row = r16
    .def    column = r17

    ;;; return values
    .def    color = r18
    clr     color


    ;;; get the current pixel color at (row, column)
    ; put redBuffer[row, column] in t flag
    buffElementToT  redBuffer, row, column
    ; load it into color[0]
    bld     color, 0

    ; put greenBuffer[row, column] in t flag
    buffElementToT  greenBuffer, row, column
    ; load it into color[1]
    bld     color, 1
    ; color now contains current color at (row, column)

    ; return
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
    ;;; arguments
    .def    row = r16
    .def    column = r17

    ; put gameBoard[row, column] in t flag
    buffElementToT  gameBoard, row, column

    ; t set --> reserved
    brts    PixelReservedReturnTrue
    ; t clear --> not reserved
    clz
    jmp     PixelReservedReturn
  PixelReservedReturnTrue:
    sez

  PixelReservedReturn:
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

    ; row diff is the first item
    lds     row, cursorRow
    lpm     tmp, z+
    add     row, tmp
    ; column diff is the second item
    lds     column, cursorColumn
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


; include asm files here (since no linker)
.include "timers.asm"
.include "ports.asm"
.include "switches.asm"
.include "util.asm"
.include "display.asm"
.include "sound.asm"
.include "serial.asm"
