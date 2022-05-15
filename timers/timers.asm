;;;;;;;;;;;;;;
; timers.asm ;
;;;;;;;;;;;;;;

; Description
; -----------
; Initializes timers by setting appropriate control, output compare, etc.
; registers
;
; Inputs
; ------
; None
;
; Outputs
; -------
; None
;
; User Interface
; --------------
; None
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
; 04/28/2022    Matt Muldowney      timer0 initialization
; 05/10/2022    Matt Muldowney      moved timer 0event handler here 
;                                       (previously in switches.asm)
; 05/10/2022    Matt Muldowney      added multiplexdisplay to timer0 event 
;                                       handler

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






; Timer0EventHandler Specification
; ================================
;
; Description
; -----------
; timer0 interrupt event handler. gets run once every 1 ms.
;
; Operational Description
; -----------------------
; runs switch debouncing and display multiplexing logic
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
Timer0EventHandler:
    ; save sreg
    in r0, sreg
    push r0

    rcall SwitchEventHandler
    rcall MultiplexDisplay

    ; recover sreg
    pop r0
    out sreg, r0

    reti
