;;;;;;;;;;;;;
; ports.inc ;
;;;;;;;;;;;;;

; Description
; -----------
; port constants
;
; Constants
; ---------
; INPUT: ddr contents to define port as input
; OUTPUT: ddr contents to define port as output
;
; Revision History
; ----------------
; 5/11/2022     Matt Muldowney      input and output port consts
; 6/03/2022     Matt Muldowney      docs

; i/o
; ===
; contents of ddr to set entire port to input
; -------------------------------------------
.equ    INPUT   = 0x00

; contents of ddr to set entire port to output
; --------------------------------------------
.equ    OUTPUT  = 0xFF
