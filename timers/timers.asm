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
; 05/27/2022    Matt Muldowney      timsk init in inittimer0 now only sets
;                                       timer0's respective interrupt bit
; 05/27/2022    Matt Muldowney      timer1 initialization

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
    push    r16

    ldi     r16, TIMER0_CTR
    out     tccr0, r16

    ldi     r16, TIMER0_COMP
    out     ocr0, r16

    sbi     timsk, OCIE0_BIT

    pop     r16
    ret






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
    rcall MultiplexDisplay


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
; Inits Timer1 in toggle mode and phase and frequency correct mode with a
; prescalar of 8. Also, initially disables timer1a output compare match
; interrupts.
;
; Operational Description
; -----------------------
; Outputs approprate values to control registers TCCR1A and TCCR1B and clears
; appropriate bit in TIMSK.
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
; 2 bytes
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
;
; Pseudocode
; ----------
;
; out TCCR1A, TIMER1A_CTR
; out TCCR1B, TIMER1B_CTR
; cbi TIMSK, OCIE1A_BIT
InitTimer1:
    ; temporary register
    .def    tmp = r16
    push    tmp

    ldi     tmp, TIMER1A_CTR
    out     tccr1a, tmp

    ldi     tmp, TIMER1B_CTR
    out     tccr1b, tmp

    cbi     timsk, OCIE1A_BIT

    pop     tmp
    ret
