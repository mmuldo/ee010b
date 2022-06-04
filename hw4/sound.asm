;;;;;;;;;;;;;
; sound.asm ;
;;;;;;;;;;;;;

; Description
; -----------
; Contains functions for controlling speaker.
;
; Routines
; --------
; PlayNote(f): plays frequency f over speaker
;
; Revision History
; ----------------
; 05/27/2022    Matt Muldowney      initial revision
; 05/31/2022    Matt Muldowney      remove timsk RW (b/c we don't need it)


.cseg


; PlayNote(f)
; ===========
;
; Description
; -----------
; Plays frequency f in Hz (passed in on r17|r16) over speaker, until this
; function is called again with a different frequency. If f = 0, speaker output
; is turned off.
;
; Operational Description
; -----------------------
; The frequency of the wave generated by timer1 is given by:
;   f = f_clk/(2*prescalar*OCR1A)
; In our case, the timer1 prescalar is 8 and our clk frequency is 8 MHz, thus,
;   OCR1A = 500,000/f
; Thus, this function divides 500,000 (a 24-bit values) by f (a 16-bit value)
; and then stores the result in OCR1A, along with enabling the timer1
; interrupts. If f=0, timer1 interrupts are disabled.
;
; Arguments
; ---------
; f (unsigned int, r17|r16): the frequency to play
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
; speaker
;
; Error Handling
; --------------
; If frequency f is too small (and thus the result of the division can't fit
; into 16 bits for OCR1A), 0xFFFF is stored in OCR1A, resulting in a frequency
; of 7.63 Hz.
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
; none (r16, r17 preserved)
;
; Stack Depth
; --------------
; 5 bytes
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
PlayNote:
    ; not that we save arguments out of convenience to caller
    push    r16
    push    r17
    push    r18
    push    r20
    push    r21

    ;;; arguments
    ; f (frequency in Hz)
    .def    fL = r16
    .def    fH = r17

    ;;; check if f is 0 Hz
    tst     fH
    brne    PlayNoteNonZero
    tst     fL
    brne    PlayNoteNonZero
    ; if f = 0 Hz, turn speaker off by setting presecaler to 0
    ldi     tmp, TIMER1B_CTR_PRESCALE0
    out     tccr1b, tmp
    ; and we're done
    jmp     PlayNoteRet

  PlayNoteNonZero:
    ; if f != 0, do some actual logic

    ;;; other registers needed
    ; divisor for div24by16
    .def    divisorH = r21
    .def    divisorL = r20

    ; the diviser is the frequency we want
    mov     divisorH, fH
    mov     divisorL, fL

    ; dividend for div24by16
    .def    dividendH = r18
    .def    dividendM = r17
    .def    dividendL = r16

    ; the dividend is the base timer1a frequency
    ldi     dividendH, F_TIMER1A_H
    ldi     dividendM, F_TIMER1A_M
    ldi     dividendL, F_TIMER1A_L

    rcall   Div24by16

    ; quotient returned by div24by16
    .def    quotientH = r18
    .def    quotientM = r17
    .def    quotientL = r16
    ; the quotient is the thing to put in the output compare register

    ;;; check if quotient is too large
    tst     quotientH
    breq    PlayNoteOutToSpkr
    ; if quotient too large, set to max 16-bit value
    ldi     quotientM, high(MAX_16BIT)
    ldi     quotientL, low(MAX_16BIT)

    ;;; output necessary stuff
  PlayNoteOutToSpkr:
    out     ocr1ah, quotientM
    out     ocr1al, quotientL
    ; turn speaker on by setting prescalar to 8
    ldi     tmp, TIMER1B_CTR_PRESCALE8
    out     tccr1b, tmp

    ;;; now we're done
  PlayNoteRet:
    pop     r21
    pop     r20
    pop     r18
    pop     r17
    pop     r16
    ret