;;;;;;;;;;;;;;
; timers.asm ;
;;;;;;;;;;;;;;

; Description
; -----------
; Initializes timers by setting appropriate control, output compare, etc.
; registers
;
; Routines
; --------
; InitTimer0: initializes timer0 to 1ms interrupt period
; Timer0EventHandler: runs switch debouncing and display muxing
;   logic on timer0 interrupt
; InitTimer1: initializes timer1 for wave generation
;
; Revision History
; ----------------
; 04/28/2022    Matt Muldowney      timer0 initialization
; 05/10/2022    Matt Muldowney      moved timer 0event handler here 
;                                       (previously in switches.asm)
; 05/10/2022    Matt Muldowney      added multiplexdisplay to timer0 event 
;                                       handler
; 05/27/2022    Matt Muldowney      timsk init in inittimer0 now only sets
;                                       timer0's respective interrupt bit
; 05/27/2022    Matt Muldowney      timer1 initialization
; 06/03/2022    Matt Muldowney      comment out timer0 event handler logic 
;                                       for now

.cseg

; InitTimer0 Specification
; ============================
;
; Description
; -----------
; Initializes Timer0 which we will use to generate interrupts every 1 ms.
; This is handy for debouncing the switches and display multiplexing.
;
; Operational Description
; -----------------------
; The clock runs at 8 MHz, so we initialize timer0 with a prescalar of 32 and
; put it in output compare mode, setting the output compare register to 250.
; This puts the period of interrupts at 1 ms, which is good for things like
; debouncing and display multiplexing.
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
InitTimer0:
    push    r16
    push    r17

    ; tmp register
    .def    tmp = r16

    ; register to out to timsk
    .def    timskReg = r17
    ; timsk should intially be 0 so we can set the bits we want individually
    clr     timskReg

    ; timer0 control register
    ldi     tmp, TIMER0_CTR
    out     tccr0, tmp

    ; timer0 output compare register
    ldi     tmp, TIMER0_COMP
    out     ocr0, tmp

    ; set OCIE0_BIT in timsk
    ori     timskReg, OCIE0_BIT
    out     timsk, timskReg

    pop     r17
    pop     r16
    ret






; Timer0EventHandler Specification
; ================================
;
; Description
; -----------
; timer0 interrupt event handler. gets run once every timer0 interrupt
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
	; need r0 for sreg
	push r0
    ; save sreg into r0
    in r0, sreg
	; push r0 again in case functions below mess it up
    push r0
	
	; multiplexdisplay uses y and z registers, so we need
	;	to save those
	push yl
	push yh
	push zl
	push zh

    rcall SwitchEventHandler
    ;rcall MultiplexDisplay


	pop zh
	pop zl
	pop yh
	pop yl
    pop r0
    out sreg, r0
	pop r0

    reti




; InitTimer1
; ==========
;
; Description
; -----------
; Inits Timer1 in toggle mode and phase and frequency correct mode with an
; initial prescalar of 0 (to turn off speaker).
;
; Operational Description
; -----------------------
; Outputs approprate values to control registers TCCR1A and TCCR1B
; (TCCR1B initially set such that speaker is off).
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
; none
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
; none
;
; Outputs
; -------
; none
;
; Error Handling
; --------------
; none
;
; Algorithms
; ----------
; none
;
; Data Structures
; ---------------
; none
;
; Registers Used
; --------------
; none
;
; Stack Depth
; --------------
; 1 byte
;
; Limitations
; -----------
; none
;
; Known Bugs
; ----------
; none
;
; Special Notes
; -------------
; none
InitTimer1:
    push r16

    ; temporary register
    .def    tmp = r16

    ; timer1 control register a
    ldi     tmp, TIMER1A_CTR
    out     tccr1a, tmp

    ; timer1 control register b
    ; intially has prescalar 0 to turn
    ;   wave generation off
    ldi     tmp, TIMER1B_CTR_PRESCALE0
    out     tccr1b, tmp

    pop     r16
    ret
