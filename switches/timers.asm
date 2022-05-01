; utility macros
;.include "util.asm"

.CSEG

; InitTimer0 Specification
; ============================
;
; Description
; -----------
; Initializes Timer0 which we will use to generate interrupts every 1 ms.
; This is handy for debouncing the switches.
;
; Operational Description
; -----------------------
; The clock runs at 8 MHz, so we initialize timer0 with a prescalar of 32 and
; put it in output compare mode, setting the output compare register to 250.
; (Note: 8 MHz / 32 / 250 = 1 KHz --> period of 1 ms).
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
; Registers Changed
; -----------------
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
InitTimer0:
    PUSH    R16

    LDI     R16, TIMER0_CTR
    OUT     TCCR0, R16

    LDI     R16, TIMER0_COMP
    OUT     OCR0, R16

    LDI     R16, TIMER0_MSK
    OUT     TIMSK, R16

    POP     R16
    RET
