; test
; OUTI macro
; ==========
;
; Description
; -----------
; stores immediate in I/O register
;
; Arguments
; ---------
; @0: I/O register
; @1: immediate value
;
; Registers Changed
; -----------------
; R16
;
; Stack Depth
; -----------
; None
.MACRO OUTI
LDI     R16, @1
OUT     @0, R16
.ENDMACRO

; LSRK macro
; ==========
;
; Description
; -----------
; performs an LSR K times
;
; Arguments
; ---------
; @0: Rd
; @1: K (positive integer number of times to shift LSR)
;
; Registers Changed
; -----------------
; R16
;
; Stack Depth
; -----------
; None
.MACRO LSRK
1:
    LDI     R16, @1
    CPI     R16, 0      ; check if K is 0
    BREQ    2f          ; if so, we're done

    LSR     @0
    Dec     R16
    JMP     1b
2:
.ENDMACRO

; LSLK macro
; ==========
;
; Description
; -----------
; performs an LSL K times
;
; Arguments
; ---------
; @0: Rd
; @1: K (positive integer number of times to shift LSL)
;
; Registers Changed
; -----------------
; R16
;
; Stack Depth
; -----------
; None
.MACRO LSLK
1:
    LDI     R16, @1
    CPI     R16, 0      ; check if K is 0
    BREQ    2f          ; if so, we're done

    LSL     @0
    Dec     R16
    JMP     1b
2:
.ENDMACRO
