;;;;;;;;;;;;;;
; timers.inc ;
;;;;;;;;;;;;;;

; constants for initializing timers
;
; Revision History
; ----------------
; 04/30/2022    Matt Muldowney      set constants for Timer0
; 04/30/2022    Matt Muldowney      incorrect settings for TCCR0 register

; Timer0 registers
; ================
; Timer0 control register value (for TCCR0)
; -----------------------------------------
; 0.......  don't force output compare
; .0..1...  clear timer on compare mode
; ..00....  normal compare output mode
; .....011  prescalar of 32
.EQU    TIMER0_CTR  =   0b00001011

; Timer0 output compare value (for OCR0)
; --------------------------------------
; Clock runs at 8 MHz, want frequency of 1 KHz
; --> 8x10^6 / 32x10^3  = 250
.EQU    TIMER0_COMP =   250

; Timer0 mask register value (for TIMSK)
; --------------------------------------
; ......10  enable Timer0 compare match interrupts
.EQU    TIMER0_MSK  =   0b00000010
