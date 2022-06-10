;;;;;;;;;;;;;
; sound.inc ;
;;;;;;;;;;;;;

; Description
; -----------
; constants for sound logic
;
; Constants
; ---------
; SPKR_PORT_BIT: the bit at which the speaker resides on its port
;
; Revision History
; ----------------
; 05/29/2022    Matt Muldowney      

; ports
; =====
; bit at which speaker resides on its respective port
; ---------------------------------------------------
.equ    SPKR_PORT_BIT = 5

; notes
; =====
.equ    C3 = 131
.equ    E3 = 165
.equ    G3 = 196
.equ    B3 = 247
.equ    C4 = 262
.equ    E4 = 330
.equ    G4 = 392
.equ    B4 = 494
.equ    C5 = 523