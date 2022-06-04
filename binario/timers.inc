;;;;;;;;;;;;;;
; timers.inc ;
;;;;;;;;;;;;;;

; Description
; -----------
; constants for initializing timers
;
; Constants
; ---------
; TIMER0_CTR: control register for timer0
; TIMER0_COMP: output compare register for timer0
; OCIE0_BIT: output compare interrupt enable in timsk
; TIMER1A_CTR: control register a for timer1
; TIMER1B_CTR_PRESCALE8: control register b for timer1, with prescalar 8
; TIMER1B_CTR_PRESCALE0: control register b for timer1, with prescalar 0
; F_TIMER1A_H: high byte of base timer1a frequency
; F_TIMER1A_M: medium byte of base timer1a frequency
; F_TIMER1A_L: low byte of base timer1a frequency
;
; Revision History
; ----------------
; 04/30/2022    Matt Muldowney      set constants for Timer0
; 04/30/2022    Matt Muldowney      incorrect settings for TCCR0 register
; 05/27/2022    Matt Muldowney      set bits in timsk directly with sbi, so
;                                       update consts to reflect that
; 05/27/2022    Matt Muldowney      constants for Timer1
;
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

; bit to set in TIMSK to enable Timer0 interrupts on compare match
; ----------------------------------------------------------------
.equ    OCIE0_Bit   =   0b00000010


; Timer1 registers
; ================
; Timer1A control register value (for TCCR1A)
; -------------------------------------------
; 01......  toggle mode for OC1A
; ..00....  normal mode for OC1B
; ....00..  normal mode for OC1C
; ......01  phase and frequency correct mode for WGM1
.equ    TIMER1A_CTR =   0b01000001

; Timer1B control register value (for TCCR1B)
; -------------------------------------------
; 00......  TODO: figure out what this should actually be
; ..-.....  reserved
; ...10...  phase and frequency correct mode for WGM1
; .....010  prescale clock by 8
.equ    TIMER1B_CTR_PRESCALE8 =   0b00010010
; .....000  prescale clock by 8
.equ    TIMER1B_CTR_PRESCALE0 =   0b00010000

; Timer1A base frequency
; ----------------------
; the magic number is 
;   f_clk / (2 * prescalar) = 8 MHz / (2 * 8) = 500000 = 0x07A120
; This values was chosen because, when devided by 16-bit numbers,
; it falls in the range of audible frequencies.
.equ    F_TIMER1A_H =   0x07
.equ    F_TIMER1A_M =   0xA1
.equ    F_TIMER1A_L =   0x20