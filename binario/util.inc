;;;;;;;;;;;;
; util.inc ;
;;;;;;;;;;;;

; Description
; -----------
; utility constants and macros
;
; Constants
; ---------
; TRUE
; FALSE
; MAX_16BIT
; Z_POSITION: position of z flag in sreg
;
; Macros
; ------
; cb(byte, bitNumber): clears byte[bitNumber]
; sb(byte, bitNumber): sets byte[bitNumber]
; withinBounds(num, lower, upper): checks lower <= num <= upper
; tstWithT(register): tst register, but sets t flag instead of z flag
; checkBoolean(boolean): sets z flag according to boolean in data memory
;
; Revision History
; ----------------
; 4/30/2022     Matt Muldowney      true/false
; 5/27/2022     Matt Muldowney      max 16-bit value
; 6/02/2022     Matt Muldowney      cb, sb macros
; 6/02/2022     Matt Muldowney      withinBounds macro
; 6/03/2022     Matt Muldowney      tstWithT, copyTtoZ macros
; 6/03/2022     Matt Muldowney      checkBoolean macro

; ##########
; # consts #
; ##########

; booleans
; ========
.equ    TRUE    = 1
.equ    FALSE   = 0

; extrema
; =======
; largest value that can fit in 16 bits
; -------------------------------------
.equ    MAX_16BIT = 0xFFFF

; sreg locations
; ==============
; z flag position
.equ    Z_POSITION = 1



; ##########
; # macros #
; ##########

; cb(byte, bitNumber)
; =======================
;
; Description
; -----------
; cbi but for register-register input
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


; withinBounds(num, lower, upper)
; =====================================
;
; Description
; -----------
; This macro checks if lower <= num <= upper. The t flag is set iff
; this condition is met.
; Syntax:
;   withinbounds    Rd, Rr1, Rr2
; 0 <= d, r1, r2 <= 31
; Note that other flags (h, s, v, n, z, c) maybe set as a result of this macro.
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
    ;;; arguments
    ; @0 --> value
    ; @1 --> lower bound
    ; @2 --> upper bound

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


; tstWithT(register)
; ==================
; 
; Description
; -----------
; This macro performs a tst on register, but then moves the z flag to the
; t flag; i.e. it indicates the result of the tst with the t flag instead
; of the z flag.
; Syntax:
;   tstWithT    Rd
; 0 <= d <= 31
; Note that other flags (s, n, z) maybe set as a result of this macro.
; 
; Operational Description
; -----------------------
; Performs a tst on Rd, reads in sreg, then sets t according to z.
; 
; Arguments
; ---------
; register (Rd): the register to tst
; 
; Return Values
; -------------
; t: set iff z is set as a result of the tst
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; none
; 
; Local Variables
; ---------------
; sregResult (r23): reads in sreg after tst
; 
; Inputs
; ------
; none
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
; none
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
.macro  tstWithT
    push    r0

    .def    sregResult = r0

    ;;; perform tst on register
    tst     @0

    ;;; get z flag reading
    in      sregResult, sreg
    bst     sregResult, Z_POSITION

    pop     r0
.endm

; notTstWithT(register)
; ==================
; 
; Description
; -----------
; This macro performs a tst on register, but then moves  !z to the
; t flag; i.e. it indicates the opposite result of the tst with the t flag 
; instead of the z flag.
; Syntax:
;   notTstWithT    Rd
; 0 <= d <= 31, d != 23
; Note that other flags (s, n, z) maybe set as a result of this macro.
; 
; Operational Description
; -----------------------
; Performs a tst on Rd, reads in sreg, then sets t according to !z.
; Can't use r23 because we use that for a local variable.
; 
; Arguments
; ---------
; register (Rd): the register to tst
; 
; Return Values
; -------------
; t: set iff z is clear as a result of the tst
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; none
; 
; Local Variables
; ---------------
; sregResult: reads in sreg after tst
; invertZ: when eor'd with sreg, z inverted
; 
; Inputs
; ------
; none
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
; none
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
.macro  notTstWithT
    push    r0
    push    r23

    .def    sregResult = r0

    .def    invertZ = r23
    ldi     invertZ, (1<<Z_POSITION)

    ;;; perform tst on register
    tst     @0

    ;;; get !z flag reading
    in      sregResult, sreg
    eor     sregResult, invertZ
    bst     sregResult, Z_POSITION

    pop     r23
    pop     r0
.endm

; checkBool(boolean)
; ==================
; 
; Description
; -----------
; indicates if a boolean in data memory is True/False.
; If byte at data memory location "boolean" is TRUE, set z flag to 1;
; otherwise set z flag to 0.
; Resets boolean to FALSE everytime.
; Note that other flags (h, s, v, n, c) maybe set as a result of this macro.
; 
; Operational Description
; -----------------------
; Freezes sreg and stops interrupts (due to critical code), reads in
; boolean from data memory, and then resets boolean in data memory to FALSE,
; after unfreezes sreg.
; Then, if read in boolean is TRUE, set z flag, otherwise clear it.
; 
; Arguments
; ---------
; boolean (data memory location): the thing we are checking
; 
; Return Values
; -------------
; z: 1 iff boolean is TRUE
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; none
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
; 3 bytes
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
.macro  checkBool
    push    r0
    push    r16
    push    r17

    ; for freezing sreg
    .def    sregReading = r0
    ; for reading in boolean
    .def    booleanReg = r16
    ; for re-initing boolean
    .def    falseReg = r17
    ldi     falseReg, FALSE


    ;;; freeze status flags and stop interrupts
    in      sregReading, sreg
    cli
    
    ;;; critical code
    ; save boolean to register and reset it
    lds     booleanReg, @0
    sts     @0, falseReg
    ; end critical code
    
    ; unfreeze status flags
    out     sreg, sregReading
    
    ;;; check if boolean is TRUE/FAlSE
    ; booleanReg == TRUE --> booleanReg-- == 0
    ; booleanReg == FALSE --> booleanReg-- != 0
    dec     booleanReg
    tst     booleanReg

    ;;; done
    pop     r17
    pop     r16
    pop     r0
.endm