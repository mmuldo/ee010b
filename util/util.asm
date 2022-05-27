;;;;;;;;;;;;
; util.asm ;
;;;;;;;;;;;;

; Description
; -----------
; Contains utility functions for other files
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
; 05/07/2022    Matt Muldowney      shifting multiple times
; 05/08/2022    Matt Muldowney      clearbit and setbit
; 05/27/2022    Matt Muldowney      div24by16




.cseg

; ClearBit(byte, bitNumber)
; =======================
;
; Description
; -----------
; clears byte[7 - bitNumber] (reversed because that's how the board is)
;
; Operational Description
; -----------------------
; RORs 0b1111 1110 such that the 0 is in the bitNumber position, and then 
;   ANDs it with byte to ensure byte[bitNumber] is cleared
;
; Arguments
; ---------
; byte (8-bit string, r16): the byte which has a bit we want to clear
; bitNumber(int, r17): the position of the bit in the byte we want to clear;
;   must be between 0 and 7
;
; Return Values
; -------------
; 8-bit string, r16: byte with byte[7 - bitNumber] clear 
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
; if bitNumber is out of range [0, 7], do nothing and return
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
; r16: byte
; r17: bitNumber
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
ClearBit:
    ;;; arguments
    .def byte = r16
    .def bitNumber = r17

    ;;; check validity of bitNumber
    ; bitNumber must be >= 0
    push r18
    ldi r18, TRUE
    
    ; save r16, r17 bc we need to overwrite them for function call
    push r16
    push r17
    
    mov r16, bitNumber
    ldi r17, 0
    rcall CheckValid
    ; recover r17 for next stuff and save it again
    pop r17
    push r17

    ; bitNumber must be <= 7 (byte length)
    ldi r16, 7
    ; bitNumber already in r17
    mov r17, bitNumber
    rcall CheckValid
    ; recover r16, r17
    pop r17
    pop r16

    cpi r18, TRUE
    ; put stack pointer back at caller's address
    pop r18
    ; if bitNumber not valid, just return
    brne Return_ClearBit

    
    ;;; other needed registers
    ; r18: bit mask (this gets shifted appropriately)
    .def mask = r18
    push mask
    ldi mask, 0b01111111

    ;;; shift the bit mask left bitNumber times
    ; save r16, r17 bc we need to overwrite for function call
    push r16
    push r17
    
    mov r16, mask
    ; rork(mask, bitNumber)
    rcall rork 
    mov mask, r16
    ; recover r16, r17
    pop r17
    pop r16

    ;;; clear the bit in byte
    and byte, mask
    pop mask
  Return_ClearBit:
    ret


; SetBit(byte, bitNumber)
; =======================
;
; Description
; -----------
; sets byte[7 - bitNumber] (reversed because that's how the board is)
;
; Operational Description
; -----------------------
; RSLs 0b10000000 such that the 1 is in the bitNumber position, and then ORs it 
; with byte to ensure byte[bitNumber] is set
;
; Arguments
; ---------
; byte (8-bit string, r16): the byte which has a bit we want to set
; bitNumber(int, r17): the position of the bit in the byte we want to set;
;   must be between 0 and 7
;
; Return Values
; -------------
; 8-bit string, r16: byte with byte[7 - bitNumber] set 
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
; if bitNumber is out of range [0, 7], do nothing and return
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
; r16: byte
; r17: bitNumber
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
SetBit:
    ;;; arguments
    .def byte = r16
    .def bitNumber = r17

    ;;; check validity of bitNumber
    ; bitNumber must be >= 0
    push r18
    ldi r18, TRUE

	; save r16, r17 bc we need to overwrite them for function call
    push r16
    push r17

    mov r16, bitNumber
    ldi r17, 0
    rcall CheckValid
	; recover r17 for next stuff and save it again
	pop r17
	push r17

    ; bitNumber must be <= 7 (byte length)
    ldi r16, 7
    ; bitNumber already in r17
    rcall CheckValid
	; recover r16, r17
    pop r17
    pop r16

    cpi r18, TRUE
	; put stack pointer back at caller's address
	pop r18
    ; if bitNumber not valid, just return
    brne Return_SetBit

    ;;; other needed registers
    ; r18: bit mask (this gets shifted appropriately)
    .def mask = r18
    push mask
    ldi mask, 0b10000000

    ;;; shift the bit mask left bitNumber times
	; save r16, r17 bc we need to overwrite for function call
    push r16
    push r17
    mov r16, mask
	; r17 already contains bitNumber
    ; mask >> bitNumber (lslk(mask, bitNumber))
    rcall lsrk 
    mov mask, r16
	; recover r16, r17
    pop r17
    pop r16

    ;;; set the bit in byte
    or byte, mask
    pop mask

  Return_SetBit:
    ret


; CheckValid(value1, value2, validFlag)
; =====================================
;
; Description
; -----------
; sets validFlag to FALSE iff value1 < value2; otherwise, does nothing
;
; Operational Description
; -----------------------
; compares value1 and value2; if value1 >= value2, do nothing (just return);
; if value1 < value2, this is consdered invalid, so set validFlag = FALSE
;
; Arguments
; ---------
; value1 (int, r16): value that must be greater than or equal to
; value2 (int, r17): value that must be less than or equal to
; validFlag (bool, r18): flag to set to false if invalid
;
; Return Values
; -------------
; bool, r18: flag indicating validity
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
; r16: value1
; r17: value2
; r18: validFlag
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
CheckValid:
    ;;; arguments
    .def value1 = r16
    .def value2 = r17
    .def validFlag = r18

    ;;; check that value1 >= value2
    cp value1, value2
    brge Return_CheckValid
    ldi validFlag, FALSE

  Return_CheckValid:
    ret


; Saturate(value, lowerBound, upperBound)
; =======================================
;
; Description
; -----------
; if value < lowerBound, sets value = lowerBound; if value > upperBound,
; value = upperBound; otherwise, value is untouched
;
; Operational Description
; -----------------------
; See description
;
; Arguments
; ---------
; value (int, r16): value that will possibly be saturated
; lowerBound (int, r17): value that must be less than or equal to
; upperBound (bool, r18): value that must be greater than or equal to
;
; Return Values
; -------------
; int, r16: the saturated value
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
; r16: value
; r17: lowerBound
; r18: upperbound
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
Saturate:
    ;;; arguments
    .def value = r16
    .def lowerBound = r17
    .def upperBound = r18

    ;;; check if value < lowerBound
    cp value, lowerBound
    brge CheckTooLarge_Saturate
    ; saturate if it is
    mov value, lowerBound
    jmp Return_Saturate

    ;;; check if value > upperBound
  CheckTooLarge_Saturate:
    cp upperBound, value
    brge Return_Saturate
    ; saturate if it is
    mov value, upperBound

  Return_Saturate:
    ret


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
; r16: byte
; r17: k
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
lslk:
    .def byte = r16 ; r16: the thing we are lsl-ing
    .def k = r17    ; r17: the amount to lsl

  lslLoop:
    cpi     k, 0
    breq    lslDone
    lsl     byte
    dec     k
    jmp     lslLoop
  lslDone:
    ret


; rolk(byte, k)
; ==================
;
; Description
; -----------
; rotates byte left (not through carry)! k times
;
; Operational Description
; -----------------------
; performs k (lsl -> adc 0)s on byte
;
; Arguments
; ---------
; byte (8-bit string, r16): byte to rol
; k (int, r17): amount to rol
;
; Return Values
; -------------
; 8-bit string, r16: byte rol'd k times
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
; r16: byte
; r17: k
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
rolk:
    ;;; arguments
    .def byte = r16
    .def k = r17
    
    ;;; other registers
    .def zero = r18
    push zero
    ldi zero, 0

  rolLoop:
    cpi     k, 0
    breq    rolDone
    lsl     byte
    adc     byte, zero
    dec     k
    jmp     rolLoop
  rolDone:
    pop zero
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
; r16: byte
; r17: k
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
lsrk:
    .def byte = r16 ; r16: the thing we are lsr-ing
    .def k = r17    ; r17: the amount to lsr

  lsrLoop:
    cpi     k, 0
    breq    lsrDone
    lsr     byte
    dec     k
    jmp     lsrLoop
  lsrDone:
    ret


; rork(byte, k)
; ==================
;
; Description
; -----------
; rotates byte right (not through carry)! k times
;
; Operational Description
; -----------------------
; performs k (lsr -> adc 0)s on byte
;
; Arguments
; ---------
; byte (8-bit string, r16): byte to ror
; k (int, r17): amount to ror
;
; Return Values
; -------------
; 8-bit string, r16: byte ror'd k times
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
; r16: byte
; r17: k
;
; Stack Depth
; -----------
; None
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
rork:
    ;;; arguments
    .def byte = r16
    .def k = r17

  rorLoop:
    cpi     k, 0
    breq    rorDone
    dec     k
    lsr     byte
    ; if carry is clear, we want to keep 0 in the msb
    brcc    rorLoop
    ; otherwise, if carry is set, want to put 1 in the msb
    ori     byte, 0b10000000
    jmp     rorLoop
  rorDone:
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
; [unknown]
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
; bitcnt = 24
; remainder = 0
;
; WHILE bitcnt > 0:
;   rol dividend
;   rol remainder
;
;   IF can perform (remainder - divisor) without carry:
;       remainder = remainder - divisor
;   ENDIF
;
;   bitcnt--
; ENDWHILE
;
; rol dividend
; quotient = invert dividend
;
; return (quotient, remainder)
Div24by16:
    ;;; arguments
    ; dividend
    .def    dividendH = r18
    .def    dividendM = r17
    .def    dividendL = r16

    ; divisor
    .def    divisorH = r21
    .def    divisorL = r22


    ;;; return values
    ; quotient
    .def    quotientH = r18
    .def    quotientM = r17
    .def    quotientL = r16

    ; remainder
    .def    remainderH = r3
    .def    remainderL = r2
    clr     remainderH
    clr     remainderL

    
    ;;; other registers we need
    ; number of bits to divide into
    .def    bitcnt = r22
    push    r22
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
  Div16SkipSub:
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


    pop bitcnt
    ret
