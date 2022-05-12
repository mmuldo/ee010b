.cseg

; ClearBit(byte, bitNumber)
; =======================
;
; Description
; -----------
; clears byte[bitNumber]
;
; Operational Description
; -----------------------
; ROLs 0b1111 1110 such that the 0 is in the bitNumber position, and then 
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
; 8-bit string, r16: byte with byte[bitNumber] set 
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
    push r16
    push r17
    mov r16, bitNumber
    ldi r17, 0
    rcall CheckValid
    pop r17
    pop r16

    ; bitNumber must be <= 7 (byte length)
    push r16
    push r17
    ldi r16, 7
    mov r17, bitNumber
    rcall CheckValid
    pop r17
    pop r16

    cpi r18, TRUE
    breq ClearBitBody
    ret


  ClearBitBody:
    ;;; other needed registers
    ; r18: bit mask (this gets shifted appropriately)
    .def mask = r18
    push mask
    ldi mask, 0b11111110

    ;;; shift the bit mask left bitNumber times
    push r16
    push r17
    mov r16, mask
    ; set carry flag so that we rotate 1s back
    sec
    ; rolk(mask, bitNumber)
    rcall rolk 
    mov mask, r16
    pop r17
    pop r16

    ;;; set the bit in byte
    and byte, mask
    pop mask
    ret


; SetBit(byte, bitNumber)
; =======================
;
; Description
; -----------
; sets byte[bitNumber]
;
; Operational Description
; -----------------------
; LSLs 0x01 such that the 1 is in the bitNumber position, and then ORs it with
; byte to ensure byte[bitNumber] is set
;
; Arguments
; ---------
; byte (8-bit string, r16): the byte which has a bit we want to set
; bitNumber(int, r17): the position of the bit in the byte we want to set;
;   must be between 0 and 7
;
; Return Values
; -------------
; 8-bit string, r16: byte with byte[bitNumber] set 
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
    push r16
    push r17
    mov r16, bitNumber
    ldi r17, 0
    rcall CheckValid
    pop r17
    pop r16

    ; bitNumber must be <= 7 (byte length)
    push r16
    push r17
    ldi r16, 7
    mov r17, bitNumber
    rcall CheckValid
    pop r17
    pop r16

    cpi r18, TRUE
    breq SetBitBody
    ret

    ;;; other needed registers
    ; r18: bit mask (this gets shifted appropriately)
    .def mask = r18
    push mask
    ldi mask, 0x01

    ;;; shift the bit mask left bitNumber times
    push r16
    push r17
    mov r16, mask
    ; mask << bitNumber (lslk(mask, bitNumber))
    lslk 
    mov mask, r16
    pop r17
    pop r16

    ;;; set the bit in byte
    or byte, mask
    pop mask
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
    ldi value, lowerBound
    jmp Return_Saturate

    ;;; check if value > upperBound
  CheckTooLarge:
    cp upperBound, value
    brge Return_Saturate
    ; saturate if it is
    ldi value, upperBound

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
; rotates byte left through carry k times
;
; Operational Description
; -----------------------
; performs k rol's on byte
;
; Arguments
; ---------
; byte (8-bit string, r16): byte to rol
; k (int, r17): amount to rol
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
rolk:
    ;;; arguments
    .def byte = r16
    .def k = r17

  rolLoop:
    cpi     k, 0
    breq    rolDone
    rol     byte
    dec     k
    jmp     rolLoop
  rolDone:
    ret
