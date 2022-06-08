;;;;;;;;;;;;;;;
; binario.inc ;
;;;;;;;;;;;;;;;

; constants for switch logic
;
; Revision History
; ----------------
; 05/31/2022    Matt Muldowney      directions
; 06/01/2022    Matt Muldowney      beeping

; stack
; =====
; stack depth
; -----------
.equ    STACK_DEPTH = 127

; directions
; ==========
.equ    UP      = 0
.equ    LEFT    = 1
.equ    DOWN    = 2
.equ    RIGHT   = 3

; beeping
; =======
; beep length (in hundredths of a second)
; ---------------------------------------
.equ    BEEP_LENGTH = 10
; beep frequency (in Hz)
; ----------------------
.equ    BEEP_FREQ = 440

; game play
; =========
; initial game number
; -------------------
.equ    GAME_NUMBER_INIT = 0
; number of games
; ---------------
.equ    NUM_GAMES = 8
; number of bytes of eerom game takes up
; --------------------------------------
.equ    GAME_SPACE = 16
; game states
; -----------
.equ    STATE_INTRO     = 0
.equ    STATE_SELECT    = 1
.equ    STATE_PLAY      = 2
.equ    STATE_WIN       = 3
; initial game state
; ------------------
.equ    STATE_INIT      = STATE_INTRO
; game state arguments
; --------------------
.equ    NO_ACTION   = 0 ; nothing happened
.equ    LR_SWITCH   = 1 ; lr switch pressed
.equ    UD_SWITCH   = 2 ; ud switch pressed
.equ    LEFT_ROT    = 3 ; left rotation
.equ    RIGHT_ROT   = 4 ; right rotation
.equ    UP_ROT      = 5 ; up rotation
.equ    DOWN_ROT    = 6 ; down rotation


; buffElementToT(buffer, row, column)
; ===================================
;
; Description
; -----------
; Sets t flag equal to buffer[row, column].
; Syntax:
;   buffElementToT  buffer, Rr1, Rr2
; Where buffer is a data memory pointer, 0 <= Rr1, Rr2 <= 31.
;
; Operational Description
; -----------------------
; Adjusts buffer to column using y pointer and column argument as offset,
; then does buffer[column] >> row and sets t equal to the 0th bit of this
; result.
;
; Arguments
; ---------
; buffer (data memory pointer): the NUM_ROWS x NUM_COLS buffer
; row (int, Rr1): row in buffer
; column (int, Rr2): column in buffer
;
; Return Values
; -------------
; t flag: set to buffer[row, column]
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
.macro  buffElementToT
    push    r16
    push    r17
    push    yl
    push    yh
    ; push and column arguments since we overwrite it in this macro
    push    @2

    ; first get buffer[column]
    ldi     yl, low(@0)
    ldi     yh, high(@0)
    add     yl, @2
    ; use @2 to hold 0
    clr     @2
    adc     yh, @2

    ; then get buffer[column][row]
    mov     r17, @1
    ld      r16, y
    ; buffer[column] << row (puts buffer[column][row] in highest bit of byte)
    rcall   lslk
    ; put buffer[row, column] in t
    bst     r16, 7

    pop     @2
    pop     yh
    pop     yl
    pop     r17
    pop     r16
.endm



.macro  loadGameNumber
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
.endm