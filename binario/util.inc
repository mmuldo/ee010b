;;;;;;;;;;;;
; util.inc ;
;;;;;;;;;;;;

; utility constants
;
; Revision History
; ----------------
; 4/30/2022     Matt Muldowney      true/false
; 5/27/2022     Matt Muldowney      max 16-bit value

; booleans
; ========
.equ    TRUE    = 1
.equ    FALSE   = 0

; extrema
; =======
; largest value that can fit in 16 bits
; -------------------------------------
.equ    MAX_16BIT = 0xFFFF


; cb(byte, bitNumber)
; =======================
;
; Description
; -----------
; cbi but for register, register input
; Clears byte[bitNumber].
; bitNumber is 1-hot (i.e. 0b00000100 --> 3)
; Syntax:
;   cb  Rd, Rr
; 0 <= r,d <= 31
;
; Operational Description
; -----------------------
; compliments bitNumber and ands it with byte
;
; Arguments
; ---------
; byte (8-bit string, r0-31): the byte which has a bit we want to clear
; bitNumber(int, r0-31): the position of the bit in the byte we want to clear;
;   must be between 0 and 7 (1-hot)
;
; Return Values
; -------------
; 8-bit string, Rd: byte with byte[bitNumber] clear 
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
; none
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
; none
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
; 1 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; none
.macro cb
    ;;; arguments
    ; @0 --> byte
    ; @1 --> bitNumber

    ; save bitNumber out of convenience to caller
    push    @1

    ; clear bit by and-ing that position with 0
    com     @1
    and     @0, @1

    pop     @1
.endm


; sb(byte, bitNumber)
; =======================
;
; Description
; -----------
; sbi but for register, register input
; sets byte[bitNumber].
; bitNumber is 1-hot (i.e. 0b00000100 --> 3)
; Syntax:
;   sb  Rd, Rr
; 0 <= r,d <= 31
;
; Operational Description
; -----------------------
; ors bitnumber with byte
;
; Arguments
; ---------
; byte (8-bit string, r0-31): the byte which has a bit we want to set
; bitNumber(int, r0-31): the position of the bit in the byte we want to set;
;   must be between 0 and 7 (1-hot)
;
; Return Values
; -------------
; 8-bit string, Rd: byte with byte[bitNumber] set 
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
; none
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
; none
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
; 1 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; this macro is pretty useless, but just wanted to put it here for completeness
.macro sb
    ;;; arguments
    ; @0 --> byte
    ; @1 --> bitNumber

    ; save bitNumber out of convenience to caller
    push    @1

    ; set bit by or-ing that position with 0
    or      @0, @1

    pop     @1
.endm



; withinbounds(num, lower, upper)
; =====================================
;
; Description
; -----------
; This macro checks if lower <= num <= upper. The t flag is set iff
; this condition is met.
; Syntax:
;   withinbounds    Rd, Rr1, Rr2
; 0 <= d, r1, r2 <= 31
;
; Operational Description
; -----------------------
; performs subtractions and checks sign bits in order to determine the
; relationship between the arguments
;
; Arguments
; ---------
; num (int, Rd): value that must be within bounds
; lower (int, Rr1): lower bound
; upper (int, Rr2): upper bound
;
; Return Values
; -------------
; t flag: set iff lower <= num <= upper
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
; 2 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
.macro  withinbounds
    ; save these b/c we're gonna overwrite
    push    @0
    push    @2

    ; @2's sign bit clear iff @0 <= @2
    sub     @2, @0
    ; @0's sign bit clear iff @0 >= @1
    sub     @0, @1

    ; @0[7] (sign bit) clear iff @0 within bounds
    or      @0, @2
    ; compliment so that @0[7] set iff @0 within bounds
    com     @0
    ; t <- @0[7]
    bst     @0, 7

    pop     @2
    pop     @0
.endm



; rotk(rotInstr, byte, k)
; =====================================
;
; Description
; -----------
; This macro performs the rotation insruction rotInstr on byte
; k times, kind of like:
;   while k > 0:
;       rotInstr byte
;       k--
; Syntax:
;   rotk    instr, Rd, Rr
; instr is any shift/rotation instruction
; 0 <= d, r <= 31
;
; Operational Description
; -----------------------
; loops k times and performs rotInstr on byte each time (uses relative jumps)
;
; Arguments
; ---------
; rotInstr: any shift/rotation instruction
; byte (8-bit string, Rd): register to rotate
; k (int, Rr): number of times to perform instr
;
; Return Values
; -------------
; byte (8-bit string, Rd): original byte shifted/rotated k times
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
; 2 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
.macro  rotk
    ; save k out of convenience to caller
    push    @2

    ; perform shift/rot on byte
    @0      @1

    dec     @2
    brne    -2
.endm