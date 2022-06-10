;;;;;;;;;;;;;;;
; binario.inc ;
;;;;;;;;;;;;;;;

; Description
; -----------
; constants for binario game
;
; Constants
; ---------
; UP
; LEFT
; DOWN
; RIGHT
; BEEP_LENGTH: number of hundredths of a second beep is
; BEEP_FREQ: frequency (in Hz) at which to beep
; GAME_NUMBER_INIT: first game to present to user during game select phase
; NUM_GAMES: number of games in eerom
; GAME_SPACE: number of bytes of eerom 1 game takes up
;
; Revision History
; ----------------
; 05/31/2022    Matt Muldowney      directions
; 06/01/2022    Matt Muldowney      beeping
; 06/05/2022    Matt Muldowney      eerom game loading consts

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


; eerom games
; ===========
; initial game number
; -------------------
.equ    GAME_NUMBER_INIT = 0
; number of games
; ---------------
.equ    NUM_GAMES = 8
; number of bytes of eerom game takes up
; --------------------------------------
.equ    GAME_SPACE = 16