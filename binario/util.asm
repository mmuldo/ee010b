;;;;;;;;;;;;
; util.asm ;
;;;;;;;;;;;;

; Description
; -----------
; Contains utility functions for other files
;
; Routines
; --------
; lslk(byte, k): performs byte << k
; lsrk(byte, k): performs byte >> k
; Div24by16(dividend, divisor): performs dividend/divisor
; Delay10ms(n): perform 10ms delay n times
; RotateOutOfBoundsHelper(num, lower, upper): helper function for
;   rotateOutOfBounds macro; if t flag set, does nothing; if t flag clear
;   and num < lower, num = upper; otherwise num = lower
;
; Revision History
; ----------------
; 05/07/2022    Matt Muldowney      shifting multiple times
; 05/08/2022    Matt Muldowney      clearbit and setbit
; 05/27/2022    Matt Muldowney      div24by16
; 06/03/2022    Matt Muldowney      Delay10ms
; 06/06/2022    Matt Muldowney      RotateOutOfBoundsHelper




.cseg


; lslk(byte, k)
; ==================
;
; Description
; -----------
; logically shifts byte left k times
;
; Operational Description
; -----------------------
; performs k lsl's on byte
;
; Arguments
; ---------
; byte (8-bit string, r16): byte to lsl
; k (int, r17): amount to lsl
;
; Return Values
; -------------
; 8-bit string, r16: byte << k
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
; Registers Used
; --------------
; r16
;
; Stack Depth
; -----------
; 1 byte
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
lslk:
    push    r17

    ;;; arguments
    ; the thing we're lsl-ing
    .def    byte = r16
    ; the amount to lsl
    .def    k = r17

  lslLoop:
    dec     k
    brlt    lslDone
    lsl     byte
    jmp     lslLoop

  lslDone:
    pop     r17
    ret


    
; lsrk(byte, k)
; ==================
;
; Description
; -----------
; logically shifts byte right k times
;
; Operational Description
; -----------------------
; performs k lsr's on byte
;
; Arguments
; ---------
; byte (8-bit string, r16): byte to lsr
; k (int, r17): amount to lsr
;
; Return Values
; -------------
; 8-bit string, r16: byte >> k
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
; Registers Used
; --------------
; r16
;
; Stack Depth
; -----------
; 1 byte
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
lsrk:
    ; save k argument
    push    r17

    ;;; arguments
    .def byte = r16 ; r16: the thing we are lsr-ing
    .def k = r17    ; r17: the amount to lsr

  lsrLoop:
    dec     k
    brlt    lsrDone
    lsr     byte
    jmp     lsrLoop
  lsrDone:
    pop     r17
    ret





; Div24by16(dividend, divisor)
; ============================
;
; Description
; -----------
; Divides the 24-bit unsigned value passed in r18|r17|r16 by the 16-bit
; unsigned value passed in r21|r20. The quotient is returned in r18|r17|r16
; and the remainder is returned in r3|r2.
;
; Operational Description
; -----------------------
; Divides r18|r17|r16 by r21|r20 using a restoring division algorithm with
; a 16-bit temporary register r3|r2 and shifting the quotient into r18|r17|r16
; as the dividend is shifted out. Note that the carry flag is the inverted
; quotient bit (and this is what is shifted into the quotient, so at the end
; the enitre quotient is inverted.
;
; Arguments
; ---------
; dividend (unsigned int, r18|r17|r16)
; divisor (unsigned int, r21|r20)
;
; Return Values
; -------------
; unsigned int, r18|r17|r16: the quotient
; unsigned int, r3|r2: the remainder
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
; bitcnt (unsigned int): number of bits left in division
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
; restoring division
;
; Data Structures
; ---------------
; none
;
; Registers Used
; --------------
; r18, r17, r16, r3, r2
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
Div24by16:
    push    r22

    ;;; arguments
    ; dividend
    .def    dividendH = r18
    .def    dividendM = r17
    .def    dividendL = r16

    ; divisor
    .def    divisorH = r21
    .def    divisorL = r20

    ; remainder
    .def    remainderH = r3
    .def    remainderL = r2
    clr     remainderH
    clr     remainderL

    
    ;;; other registers we need
    ; number of bits to divide into
    .def    bitcnt = r22
    ldi     r22, 24


    ;;; division loop
  Div24by16Loop:
    ; rotate bit into remainder (and carry into dividend registers)
    rol     dividendL
    rol     dividendM
    rol     dividendH
    rol     remainderL
    rol     remainderH

    ; check if can subtract divisor from remainder
    cp      remainderL, divisorL
    cpc     remainderH, divisorH
    brcs    Div24by16SkipSub
    ; if can subtract divisor from remainder, do it
    sub     remainderL, divisorL
    sbc     remainderH, divisorH
  Div24by16SkipSub:
    ; if can't subtract divisor from remainder, skip it
    ; note that C = 0 if subtracted, C = 1 if not

    ; dec loop counter
    dec     bitcnt
    ; continue looping if bitcnt > 0, otherwise exit loop
    brne    Div24by16Loop

    ;;; final steps
    ; shift last quotient bit in
    rol     dividendL
    rol     dividendM
    rol     dividendH

    ; invert dividend to get quotient (carry flag is inverse of quotient bit)
    com     dividendL
    com     dividendM
    com     dividendH


    pop     r22
    ret



; Delay10ms(n)
; ============
;
; Description
; -----------
; This procedure delays the number of clocks passed in r16
; times 80000. Thus with a 8 MHz clock the passed delay is
; in 10 millisecond units.                    
;
; Operational Description
; -----------------------
; The function just loops decrementing y until it is 0
;
; Arguments
; ---------
; n (int, r16): number of 10 ms delays
; 
; Return Value
; ------------
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
; y: used for looping
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
; restoring division
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
; 3 bytes
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
Delay10ms:
    push    r16
    push    yl
    push    yh

    ;;; arguments
    .def    n = r16

  Delay10msLoop:
    ; inner loop is 4 clocks
    ; so loop 20,000 times to get 80,000 clocks
    ldi     yl, low(20000)
    ldi     yh, high(20000)
  Delay10msInnerLoop:
    ;;; delay 10 ms
    sbiw    y, 1
    brne    Delay10msInnerLoop

    ;;; dec n and continue outer loop
    dec     n
    ; if n != 0, need to keep loopin
    brne    Delay10msLoop

    ; otherwise, done
    pop     yh
    pop     yl
    pop     r16
    ret


; RotateOutOfBoundsHelper(num, lower, upper)
; ==========================================
;
; Description
; -----------
; Helper function for rotateOutOfBounds macro. If t flag is set, doesn't do
; anything (just returns). If t flag is clear and num (xl) < lower (yl), num
; is set to upper (yh). If t flag is set and num >= lower (in this case, it
; would be guaranteed that num > upper), then num is set to lower.
;
; Operational Description
; -----------------------
; If t flag clear, returns without doing anything. If t flag set,
; performs cpi num, lower. If the result is negative, sets num to upper;
; otherwise, sets num to lower.
;
; Arguments
; ---------
; num (int, xl): value that is checked to be within bounds
; lower (int, yl): lower bound
; upper (int, yh): upper bound
;
; Return Values
; -------------
; int, xl (num): the number unchanged if t is set, or changed in the
;   manner specified if t is clear.
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
; Registers Used
; --------------
; none
;
; Stack Depth
; -----------
; 0 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
RotateOutOfBoundsHelper:
    ;;; arguments
    ; xl: num
    ; yl: lower bound
    ; yh: upper bound

    ;;; if t set, we're all good, so just return
    brts    RotateOutOfBoundsHelperReturn
    
    ;;; otherwise, compare num to lower
    cp      xl, yl
    ; if num < lower (i.e. if n is set), set num to upper
    brmi    RotateOutOfBoundsHelperSetToUpper
    ; otherwise, set num to lower
    mov     xl, yl
    ; and done
    jmp     RotateOutOfBoundsHelperReturn

  RotateOutOfBoundsHelperSetToUpper:
    ; set num to upper
    mov     xl, yh
    
  RotateOutOfBoundsHelperReturn:
    ret