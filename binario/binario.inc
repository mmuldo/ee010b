;;;;;;;;;;;;;;;
; binario.inc ;
;;;;;;;;;;;;;;;

; constants for switch logic
;
; Revision History
; ----------------
; 05/31/2022    Matt Muldowney      directions
; 06/01/2022    Matt Muldowney      beeping

; directions
; ==========
.equ    UP      = 0
.equ    LEFT    = 1
.equ    DOWN    = 2
.equ    RIGHT   = 3

; beeping
; ============
; beep length (in hundredths of a second)
; ---------------------------------------
.equ    BEEP_LENGTH = 10
; beep frequency (in Hz)
.equ    BEEP_FREQ = 440