;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   BINARIO                                  ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description
; -----------
; Binario is a game played on an 8 x 8 grid where each space can take on the
; color red, green, or unfilled (indicated by an LED).
; The game starts with each space on the grid initialized to red, green,
; or unfilled.
; The unfilled spaces are those that the user is allowed to change to red
; or green (spaces that are initially filled with red or green are not allowed
; to be changed by the user).
; The user wins when they satisfy each of the following:
;   * each space in the grid is filled with either red or green
;   * no more than two adjacent spaces in the horizontal/vertical directions
;       have the same color
;   * every row and column has 4 red spaces and 4 green spaces
;   * no two rows are the same
;   * no two columns are the same.
;
; Global variables
; ----------------
; none (ASK)
;
; Inputs
; ------
; up/down switch
;   When selecting a game, rotate to flip through game options and push to
;   select a game to play.
;   When playing a game, rotate clockwise to move the cursor down (wraps to
;   the top row when can't go further down) and counterclockwise to move the
;   cursor up (wraps to the bottom row when can't go further up); push to
;   reset the game to the initial tableau.
; left/right switch 
;   When selecting a game, does nothing.
;   When playing a game, rotate clockwise to move the cursor right (wraps to
;   the leftmost column when can't go further right) and counterclockwise to 
;   move the cursor left (wraps to the rightmost column when can't go further
;   left); push to change the the color of the pixel at which the cursor is
;   currently placed in the following manner:
;       * pixel part of the initial tableau --> pixel unchanged
;       * pixel unfilled --> red
;       * pixel red --> green
;       * pixel green --> unfilled
;
; Outputs
; -------
; 8 x 8 red/green LED matrix
;   Square grid of LED pixels on which the game is played. Each pixel can
;   either be unfilled, red, green, or yellow. There are 8 rows of pixels and
;   8 columns of pixels.
; speaker:
;   Gives audio feedback to user. Plays songs during the intro screen, the
;   game selection screen, and the win screen. During game play, if the use
;   attempts to write a pixel that is part of the initial tableau, the speaker
;   will beep once at the use at the frequency specified by BEEP_FREQ (see
;   binario.inc).
;
; User Interface
; --------------
; Game introduction
;   When initially loading the game, "Binario" will scroll across the LED
;   matrix followed by "Select a game". Moreover, the speaker will play the
;   song "Juicy" by Doja Cat. During this time, the inputs to the
;   system have no effect. Once the scrolling is complete, the next phase is
;   game selection.
; Game selection
;   The speaker will continue to play "Juicy" by Doja Cat.
;   The LED matrix will display a game that the user can choose to play by
;   pressing the up/down switch. Each time the user turns the up/down switch
;   up or down, a different game is presented for the user to choose. There
;   are 8 possible games to choose from, and turning the up/down switch up will
;   move forward through the list of choices (wrapping back to the first 
;   choice when at the 8th choice) while turning it down will move backwards
;   through the list (wrapping back to the 8th choice when at the first
;   choice). Once a game is selected, the next phase is to actually play the
;   game.
; Game play
;   The speaker song changes to "Kolors" by Monte Booker.
;   The cursor location is conveyed to the user via blinking between two colors
;   at the location. The possible blinking patterns given the pixel are as 
;   follows:
;       | part of initial tableau | current color | first cursor color | second cursor color |
;       --------------------------------------------------------------------------------------
;       | yes                     | red           | red                | yellow              |
;       | yes                     | green         | green              | yellow              |
;       | no                      | unfilled      | red                | green               |
;       | no                      | red           | red                | unfilled            |
;       | no                      | green         | green              | unfilled            |
;       --------------------------------------------------------------------------------------
;   The user can move the cursor up by turning the up/down switch
;   counterclockwise, down by moving the up/down switch clockwise, left by
;   moving the left/right switch counterclockwise, and right by moving the
;   left/right switch clockwise.
;   If the pixel is not part of the initial tableau, the user can change the
;   color by pressing the left/right switch. If the pixel is currently unfilled,
;   pressing will change the pixel color to red; red, to green; and green,
;   to unfilled. If the user presses the left/right switch while the cursor is
;   over a pixel part of the initial tableau (i.e. they attempt to write a
;   pixel part of the initial tableau), the speaker will beep at them (see
;   BEEP_FREQ in binario.inc for the beep frequency).
;   At any point, the user can push the up/down switch to reset the game to
;   the initial tableau (i.e. change any pixel they have written to unfilled).
;   Once each pixel in the LED grid is filled with either red or green, the
;   game checks if the user has satisfied each of the win conditions specified
;   in the description. If they have, the user has won and the next phase
;   is user win. If not, the next phase is user loss.
; User loss
;   The speaker just beeps at the user twice to indicate they have an incorrect
;   solution and then goes back to the game play phase.
; User win
;   Once the user has won the game, the speaker will start playing "Champion"
;   by Kanye West. After 4 seconds, the display will start blinking "W".
;   When the user presses the up/down switch, the game will return to the
;   game introduction phase.
;
; Error Handling
; --------------
; Attempt to overwrite pixel reserved by initial tableau
;   The speaker will beep once at the user.
; Moving into a "wall" during game play
;   The 4 scenarios in which this can occur are:
;     1. cursor on top row and user attempts to move up
;     2. cursor on bottom row and user attempts to move down
;     3. cursor on right-most column and user attempts to move right
;     4. cursor on left-most column and user attempts to move left
;   In any of these scenarios, the cursor will wrap around to the opposite wall.
;
; Limitations
; -----------
; The only inputs are:
;   * up/down switch push
;   * up rotation
;   * down rotation
;   * left/right switch push
;   * left rotation
;   * right rotation
; This limits the amount of input the user can give to the system.
; Furthermore, the only outputs are:
;   * speaker that can only play a single frequency at a time
;   * LED grid in which each pixel is either unfilled, red, or green
; This limits the amount of feedback that can be given to the user by the
; system.
;
; Known bugs
; ----------
; none
;
; Special Notes
; -------------
; none




;;;;;;;;;;;;
; main.asm ;
;;;;;;;;;;;;

; Data Memory
; -----------
; topOfStack: initial location of stack pointer; defines the stack depth, so
;   must be the first item in dseg
; state: the current state of the main loop; one of STATE_INTRO, STATE_SELECT,
;   STATE_PLAY, STATE_WIN
; gameNumber: the # game currently shown; starts at 0
;
; Tables
; ------
; MainLoopTab: converts a state to a state handler
; ActionToDir: converts an action to a direction
;
; Routines
; --------
; Main: driver for binario game; contains main loop
; StateIntro: state handler for STATE_INTRO (introduces binario game)
; StateSelect: state handler for STATE_SELECT (game selection)
; StatePlay: state handler for STATE_PLAY (actual game play)
; StateLoss: state handler for STATE_LOSS (incorrect solution on display)
; StateWin: state handler for STATE_WIN (correct solution on display)
; InitEverything: calls all init functions
; InitMain: initializes vars for main loop
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
.include "main.inc"


.dseg
                    .byte STACK_DEPTH
    TopOfStack:	    .byte 1

    state:          .byte 1
    gameNumber:     .byte 1



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


; ##########
; # tables #
; ##########

; maps a state index (STATE_INTRO, STATE_SELECT, STATE_PLAY, STATE_LOSS,
; STATE_WIN) to a state function handler
MainLoopTab:
    .dw     StateIntro      ; STATE_INTRO
    .dw     StateSelect     ; STATE_SELECT
    .dw     StatePlay       ; STATE_PLAY
    .dw     StateLoss       ; STATE_LOSS
    .dw     StateWin        ; STATE_WIN


; converts an action to a direction to move the cursor in the following manner:
;   | action      | direction |
;   ---------------------------
;   | NO_ACTION   | N/A       |
;   | LR_SWITCH   | N/A       |
;   | UD_SWITCH   | N/A       |
;   | LEFT_ROT    | LEFT      |
;   | RIGHT_ROT   | RIGHT     |
;   | UP_ROT      | UP        |
;   | DOWN_ROT    | DOWN      |
ActionToDir:
    .db 0, 0, 0, LEFT, RIGHT, UP, DOWN



; ######################
; # main loop routines #
; ######################
; Main
; ====
;
; Description
; -----------
; Reset vector routine which contains the main loop for the binario game.
; First initializes everything for the binario game, then goes to main loop.
; The main loop listens for user inputs then, given the current game state
; passes the read input to the current state's handler. Loops this
; behavior forever.
;
; Operational Description
; -----------------------
; Initializes the stack pointer and calls InitEverything to initialize
; all ports, timers, variables, etc. Then, loops the following forever:
;   * call the input even listeners sequentially and each time set
;       the local variable action accordingly.
;   * read in the current game state and lookup the corresponding
;       state handler routing in MainLoopTab
;   * call that handler, passing action as the argument
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
; topOfStack: W
; state: RW
;
; Local Variables
; ---------------
; action (int): enumerator for the action that occurred on this loop (see
;   actions in binario.inc)
; zero (int): holds 0 (for 16-bit, 8-bit addition)
; stateReg (int): local copy of the current game state (see game states in
;   binario.inc for the enumeration of ints to states)
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
; state somehow is not one of STATE_INTRO, STATE_SELECT, STATE_PLAY, 
;   STATE_LOSS, STATE_WIN:
;   call rotateOutOfBounds(stateReg, STATE_INTRO, STATE_WIN) to ensure state
;   is valid
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
    .def    action = r16
    ldi     action, NO_ACTION

    ; current state main loop is in
    .def    stateReg = r17
    lds     stateReg, state

    ; just holds 0 (for 16-bit, 8-bit addition)
    .def    zero = r18
    clr     zero

    ;;; check listeners for switch presses/rotations
    ;;; if a listener returns true, set the action accordingly
    rcall   LRSwitch
    brne    MainLoopCheckUDSwitch
    ldi     action, LR_SWITCH
  MainLoopCheckUDSwitch:
    rcall   UDSwitch
    brne    MainLoopCheckLeftRot
    ldi     action, UD_SWITCH
  MainLoopCheckLeftRot:
    rcall   LeftRot
    brne    MainLoopCheckRightRot
    ldi     action, LEFT_ROT
  MainLoopCheckRightRot:
    rcall   RightRot
    brne    MainLoopCheckUpRot
    ldi     action, RIGHT_ROT
  MainLoopCheckUpRot:
    rcall   UpRot
    brne    MainLoopCheckDownRot
    ldi     action, UP_ROT
  MainLoopCheckDownRot:
    rcall   DownRot
    brne    MainLoopCallStateFunction
    ldi     action, DOWN_ROT

  MainLoopCallStateFunction:
    ; point z at MainLoopTab
    ldi     zl, low(2*MainLoopTab)
    ldi     zh, high(2*MainLoopTab)

    ; just in case state is out of range, put it back in range
    rotateOutOfBounds   stateReg, STATE_INTRO, STATE_WIN
    sts     state, stateReg

    ; offset MainLoopTab pointer by state.
    lsl     stateReg
    add     zl, stateReg
    adc     zh, zero

    ; call state function (note that the action argument already loaded into r16)
    lpm     r0, z+
    lpm     r1, z
    movw    z, r1:r0
    icall
    
    ; reloop
    rjmp    MainLoop




; StateIntro
; ==========
;
; Description
; -----------
; Handler for when main loop is in STATE_INTRO state, i.e. the state
; in which we welcome the user to the game.
; Initializes everything and displays a welcome message.
;
; Operational Description
; -----------------------
; calls InitEverything, calls DisplayWelcome, then sends game to
; STATE_SELECT state.
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
; None
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
StateIntro:
    ; reinit everything
    rcall   InitEverything

    ;;; scroll welcom screen
    rcall   DisplayWelcome

    ;;; go to game select state
    setState    STATE_SELECT

    ;;; load an initial game board from eerom
    loadGameNumber
    ret



; StateSelect(action)
; ===================
;
; Description
; -----------
; Handler for when main loop is in STATE_SELECT state, i.e. the state
; in which the user is selecting a game board to play. The user can
; rotate the Up/Down rotary encoder to flip between games and then
; select a game by pressing the Up/Down switch.
; StateSelect deduces what to do based on the passed in action (r16),
; which can be NO_ACTION, UP_ROT, DOWN_ROT, or UD_SWITCH.
;
; Operational Description
; -----------------------
; Here is the mapping from input action (r16) to how to handle it:
;   NO_ACTION --> return without doing anything
;   UP_ROT    --> increment gameNumber mod NUM_GAMES
;   DOWN_ROT  --> decrement gameNumber mod NUM_GAMES
;   UD_SWITCH --> set state = STATE_PLAY
;
; Arguments
; ---------
; action (int, r16): indicates the action that took place during the
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
; gameNumberReg (int): local copy of gameNumber to load from eerom
; stateReg (int): for changing game state to STATE_PLAY if ud switch is pressed
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
; action is not NO_ACTION, UP_ROT, DOWN_ROT, or UD_SWITCH
;   the routine vacuously handles this by just not doing anything
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
    .def    action = r16

    ;;; other registers
    ; for loading current game #
    .def    gameNumberReg = r17
    lds     gameNumberReg, gameNumber

    ; for changing the game state if necessary
    ; reuse r16 since don't need this at same time as action
    .def    stateReg = r16

    ; check for no action
    cpi     action, NO_ACTION
    ; if no action, return without doing anything
    breq    StateSelectReturn

    ; check for up rotation
    cpi     action, UP_ROT
    ; if no up rotation, check down rotation
    brne    StateSelectCheckDownRot
    ; if up rotation, gameNumberReg++
    inc     gameNumberReg
    ; goto game load
    rjmp    StateSelectLoadGame

  StateSelectCheckDownRot:
    ; check for down rotation
    cpi     action, DOWN_ROT
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
    cpi     action, UD_SWITCH
    ; if no switch press, nothing to do
    brne    StateSelectReturn
    ; if switch press, user has selected this game, so goto play game state
    ldi     stateReg, STATE_PLAY
    sts     state, stateReg
    ; also initialize cursor by moving it onto board
    ldi     r16, RIGHT
    rcall   MoveCursor
    ; and done

  StateSelectReturn:
    ret



    
; StatePlay(action)
; =================
;
; Description
; -----------
; Handler for when main loop is in STATE_PLAY state, i.e. the state
; in which the user is playing the game they selected to play.
; The user can move the cursor using the up/down and left/right
; rotary encoders, plot a pixel (if not reserved by the game board)
; by pressing the left/right switch, and reset to the initial tableau
; by pressing the up/down switch.
; StatePlay deduces what to do based on the passed in action (r16),
; which can be NO_ACTION, UP_ROT, DOWN_ROT, UD_SWITCH,
; LEFT_ROT, RIGHT_ROT, or LR_SWITCH.
; If every pixel on the game board is filled and the user has satisfied
; the win conditions described in the description at the top of this file,
; sets state to STATE_WIN.
;
; Operational Description
; -----------------------
; Here is the mapping from input action (r16) to how to handle it:
;   NO_ACTION --> return without doing anything
;   LR_SWITCH --> call RotatePixelColor(cursorRow, cursorColumn)
;   UD_SWITCH --> clear display and call loadGameNumber
;   otherwise --> call MoveDir(ActionToDirection[action])
;
; Arguments
; ---------
; action (int, r16): indicates the action that took place during the
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
; cursorRow: R
; cursorColumn: R
;
; Local Variables
; ---------------
; zero (int): holds 0 (for 16-bit, 8-bit addition)
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
; action is not NO_ACTION, UP_ROT, DOWN_ROT, or UD_SWITCH
;   the routine vacuously handles this by just not doing anything
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
StatePlay:
    ;;; arguments
    ; action on previous loop of main
    .def    action = r16

    ;;; other registers needed
    ; holds 0 (for 16-bit, 8-bit addition)
    .def    zero = r17

    ;;; check if nothing happened
    cpi     action, NO_ACTION
    ; if nothing happened, just return
    breq    StatePlayReturn


    ;;; check if lr switch pressed
    cpi     action, LR_SWITCH
    ; if lr switch not pressed, check ud switch
    brne    StatePlayCheckUDSwitch
    ; if lr switch pressed, rotate color at the current cursor position
    getCursorPosition   r16, r17
    rcall   RotatePixelColor
    ; and done
    rjmp    StatePlayReturn


  StatePlayCheckUDSwitch:
    ;;; check if ud switch pressed
    cpi     action, UD_SWITCH
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
    ; action (which indicates action) is the offset
    clr     zero
    add     zl, action
    adc     zh, zero
    ; load the direction to move cursor
    lpm     r16, z
    ; MoveCursor(ActionToDir[action])
    rcall   MoveCursor
    ; and done

  StatePlayReturn:
    ; check for a win
    rcall   CheckWin
    ret


    
; StateLoss
; =========
;
; Description
; -----------
; Handler for when main loop is in STATE_LOSS state, i.e. the state
; in which the user has completely filled the display but their
; solution is incorrect.
; Beeps twice at user to indicate they have an incorrect solution,
; and then allows them to keep playing.
;
; Operational Description
; -----------------------
; Calls Beep(2) and then sends state back to STATE_PLAY.
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
; r16
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
StateLoss:
    ;;; beep twice at user
    ldi       r16, 2
    rcall     Beep

    ;;; go to play state
    setState  STATE_PLAY
    ret



; StateWin
; ========
;
; Description
; -----------
; Handler for when main loop is in STATE_WIN state, i.e. the state
; in which the user has completely filled the display and their
; solution is correct.
; Plays five "victory" notes to indicate victory, then sends back to intro.
;
; Operational Description
; -----------------------
; Calls a sequence of PlayNotes followed by delays, then sets state to STATE_INTRO.
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
; r16, r17
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
StateWin:
    ; for passing frequencies to PlayNote
    .def    freql = r16
    .def    freqh = r17

    ; note length in units of 10ms
    ; reuse r16 because don't need at same time as freql
    .def    noteLength = r16

    ;;; play the notes
    ; C4
    ldi     freql, low(C4)
    ldi     freqh, high(C4)
    rcall   PlayNote
    ; delay
    ldi     noteLength, VICTORY_NOTE_LENGTH
    rcall   Delay10ms

    ; E4
    ldi     freql, low(E4)
    ldi     freqh, high(E4)
    rcall   PlayNote
    ; delay
    ldi     noteLength, VICTORY_NOTE_LENGTH
    rcall   Delay10ms

    ; G4
    ldi     freql, low(G4)
    ldi     freqh, high(G4)
    rcall   PlayNote
    ; delay
    ldi     noteLength, VICTORY_NOTE_LENGTH
    rcall   Delay10ms

    ; B4
    ldi     freql, low(B4)
    ldi     freqh, high(B4)
    rcall   PlayNote
    ; delay
    ldi     noteLength, VICTORY_NOTE_LENGTH
    rcall   Delay10ms

    ; C5
    ldi     freql, low(C5)
    ldi     freqh, high(C5)
    rcall   PlayNote
    ; delay
    ldi     noteLength, VICTORY_NOTE_LENGTH
    rcall   Delay10ms

    ; turn off speaker
    clr     freql
    clr     freqh
    rcall   PlayNote

    ;;; go back intro state
    setState  STATE_INTRO
    ret




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
    ; initialize main vars
    rcall   InitMainVars

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


; InitMainVars
; ===============
;
; Description
; -----------
; Initializes shared vars for the main loop
;
; Operational Description
; -----------------------
; Sets shared vars for main to their initial value.
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
; gameNumberInitReg: for holding GAME_NUMBER_INIT
; stateInitReg: for holding STATE_INIT
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
InitMainVars:
    push  r16

    ; for holding GAME_NUMBER_INIT
    ; reuse r16 b/c don't need at same time as falseReg
    .def    gameNumberInitReg = r16
    ; for holding STATE_INIT
    ; reuse r16 b/c don't need at same time as gameNumberInitReg
    .def    stateInitReg = r16

    ;;; initialize first game stored in eerom to display
    ldi     gameNumberInitReg, GAME_NUMBER_INIT
    sts     gameNumber, gameNumberInitReg

    ;;; initialize initial game state
    ldi     stateInitReg, STATE_INIT
    sts     state, stateInitReg

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
.include "binario.asm"


