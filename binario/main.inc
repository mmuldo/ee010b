;;;;;;;;;;;;
; main.inc ;
;;;;;;;;;;;;

; Description
; -----------
; constants for main loop
;
; Constants
; ---------
; STACK_DEPTH
; STATE_INTRO: game introduction state
; STATE_SELECT: game selection state
; STATE_PLAY: game play state
; STATE_LOSS: incorrect solution state
; STATE_WIN: correct solution state
; STATE_INIT: first state for the game to be in
; NO_ACTION: no user input
; LR_SWITCH: lr switch pressed
; UD_SWITCH: ud switch pressed
; LEFT_ROT: left turn
; RIGHT_ROT: right turn
; UP_ROT: up turn
; DOWN_ROT: down turn
;
; Macros
; ------
; loadGameNumber: loads the game at the index stored in gameNumber from eerom
; getState(stateReg): loads current game state into stateReg register
; setState(stateImm): sets current game state to stateImm immediate value
;
; Revision History
; ----------------
; 06/05/2022    Matt Muldowney      stack depth
; 06/06/2022    Matt Muldowney      state enumeration
; 06/07/2022    Matt Muldowney      action enumeration
; 06/07/2022    Matt Muldowney      loadGameNumber macro
; 06/08/2022    Matt Muldowney      set/getState macros
; 06/09/2022    Matt Muldowney      victory consts


; ##########
; # consts #
; ##########

; stack
; =====
; stack depth
; -----------
.equ    STACK_DEPTH = 127

; game play
; =========
; game states
; -----------
.equ    STATE_INTRO     = 0
.equ    STATE_SELECT    = 1
.equ    STATE_PLAY      = 2
.equ    STATE_LOSS      = 3
.equ    STATE_WIN       = 4
; initial game state
; ------------------
.equ    STATE_INIT      = STATE_INTRO
; actions
; -------
.equ    NO_ACTION   = 0 ; nothing happened
.equ    LR_SWITCH   = 1 ; lr switch pressed
.equ    UD_SWITCH   = 2 ; ud switch pressed
.equ    LEFT_ROT    = 3 ; left rotation
.equ    RIGHT_ROT   = 4 ; right rotation
.equ    UP_ROT      = 5 ; up rotation
.equ    DOWN_ROT    = 6 ; down rotation

; victory
; =======
; victory note length (in 10ms)
; -----------------------------
.equ    VICTORY_NOTE_LENGTH = 50


; ##########
; # macros #
; ##########


; loadGameNumber
; ==============
;
; Description
; -----------
; Loads the game at index stored in gameNumber from eerom and plots it to the
; LED display.
; Syntax:
;   loadGameNumber
;
; Operational Description
; -----------------------
; Computes eerom address from gameNumber index and then calls LoadGameFromEEROM
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
; 29 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; none
.macro  loadGameNumber
    push    r0
    push    r1
    push    r16
    push    r17

    ; index of the game to load in EEROM
    .def    gameNumberReg = r16
    lds     gameNumberReg, gameNumber
    ; number of bytes a game takes up in eerom
    .def    gameSpaceReg = r17
    ldi     gameSpaceReg, GAME_SPACE

    ; address in eerom = {index of game} * {# of bytes game takes up}
    mul     gameNumberReg, gameSpaceReg

    ; move result into r17 to prep for LoadGameFromEEROM call
    mov     r17, r0
    ; LoadGameFromEEROM(GAME_SPACE*gameNumber)
    rcall   LoadGameFromEEROM

    pop    r17
    pop    r16
    pop    r1
    pop    r0
.endm



; getState(stateReg)
; ==================
;
; Description
; -----------
; Loads current game state into stateReg register.
; Syntax:
;   getState    Rd
; where 16 <= d <= 31.
;
; Operational Description
; -----------------------
; just ldi's state into stateReg
;
; Arguments
; ---------
; none
;
; Return Values
; -------------
; stateReg (Rd): register to load state into
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
; 0 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; none
.macro  getState
    lds     @0, state
.endm


; setState(stateImm)
; ==================
;
; Description
; -----------
; Sets the game state to stateImm immediate value.
; See state consts above.
; Syntax:
;   setState    stateImm
; where stateImm is one of STATE_INTRO, STATE_SELECT, STATE_PLAY, STATE_LOSS,
; and STATE_WIN.
;
; Operational Description
; -----------------------
; sts's stateImm into state
;
; Arguments
; ---------
; stateImm: one of STATE_INTRO, STATE_SELECT, STATE_PLAY, STATE_LOSS,
; and STATE_WIN.

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
; 1 byte
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; none
.macro  setState
    push    r16

    ; for storing immediate value
    .def    stateReg = r16

    ldi     stateReg, @0
    sts     state, stateReg

    pop     r16
.endm