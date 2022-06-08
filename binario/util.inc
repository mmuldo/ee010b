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
; BIT{n}_MASK: for masking off nth bit in byte
;
; Macros
; ------
; cb(byte, bitNumber): clears byte[bitNumber]
; sb(byte, bitNumber): sets byte[bitNumber]
; withinBounds(num, lower, upper): checks lower <= num <= upper
; tstWithT(register): tst register, but sets t flag instead of z flag
; checkBoolean(boolean): sets z flag according to boolean in data memory
; toggleOn0(boolean, counter, counterInit): toggles boolean when counter hits 0
;   and reinits counter when it hits 0
; flipBits(byte, biti, bitj, bitjMask): swaps byte[i] and byte[j]
; flipByte(byte): swaps byte[k] = byte[7-k] (i.e. flips byte around)
; setBitToZ(register, n): set register[n] = z flag
;
; Revision History
; ----------------
; 4/30/2022     Matt Muldowney      true/false
; 5/27/2022     Matt Muldowney      max 16-bit value
; 6/02/2022     Matt Muldowney      cb, sb macros
; 6/02/2022     Matt Muldowney      withinBounds macro
; 6/03/2022     Matt Muldowney      tstWithT, copyTtoZ macros
; 6/03/2022     Matt Muldowney      checkBoolean macro
; 6/04/2022     Matt Muldowney      toggleOn0, setBitToZ, flipBits, flipByte

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
; ---------------
.equ    Z_POSITION = 1

; bit index masks
; ===============
.equ    BIT7_MASK = 0b10000000
.equ    BIT6_MASK = 0b01000000
.equ    BIT5_MASK = 0b00100000
.equ    BIT4_MASK = 0b00010000
.equ    BIT3_MASK = 0b00001000
.equ    BIT2_MASK = 0b00000100
.equ    BIT1_MASK = 0b00000010
.equ    BIT0_MASK = 0b00000001



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


; withinBoundsHelper(num, lower, upper)
; =====================================
;
; Description
; -----------
; This macro is a helper for withinBounds. The difference between the two is
; that, for this macro, lower and upper arguments are registers, while for
; withinBounds, they are immediate values.
; Checks if lower <= num <= upper. The t flag is set iff
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
; @0, @2
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
.macro  withinBoundsHelper
    ;;; arguments
    ; @0 --> value
    ; @1 --> lower bound
    ; @2 --> upper bound

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
.endm


; withinBounds(num, lower, upper)
; =====================================
;
; Description
; -----------
; This macro is a wrapper for withinBoundsHelper. The difference between 
; the two is that, for this withinBoundsHelper, lower and upper arguments are 
; registers, while for this macro, they are immediate values.
; Checks if lower <= num <= upper. The t flag is set iff
; this condition is met.
; Syntax:
;   withinbounds    Rd, lower, upper
; 0 <= d <= r25, and lower and upper are immediate values.
; Note that other flags (h, s, v, n, z, c) maybe set as a result of this macro.
;
; Operational Description
; -----------------------
; Loads lower and upper into registers and calls withinBoundsHelper.
; The reason we can't use r11, r12, and r13 is because we need those to load
; arguments to withinBoundsHelper.
;
; Arguments
; ---------
; num (int, Rd): value that must be within bounds
; lower (int, immediate): lower bound
; upper (int, immediate): upper bound
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
; 3 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
.macro  withinBounds
    push    xl
    push    yl
    push    yh

    ;;; arguments
    ; @0 --> value
    ; @1 --> lower bound
    ; @2 --> upper bound

    ;;; load arguments into other registers to try and avoid
    ;;;     conflicts
    ; xl: value
    ; yl: lower bound
    ; yh: upper bound
    mov     xl, @0
    ldi     yl, @1
    ldi     yh, @2

    ;;; run helper (this sets t for us)
    withinBoundsHelper  xl, yl, yh
    
    ;;; recover stuff
    pop     yh
    pop     yl
    pop     xl
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



; toggleOn0(boolean, counter, counterInit)
; ========================================
; 
; Description
; -----------
; Inverts boolean in data memory when counter in data memory
; hits 0. If counter != 0, it's decremented. When counter = 0,
; counter is reinitialized to counterInit.
; Syntax:
;   toggleOn0   boolean, counter, counterInit
; where boolean and counter are data memory addresses and
; counterInit is a constant.
; Returns z flag: z flag is set to the inverse of boolean
; 
; Operational Description
; -----------------------
; Loads in boolean and counter from memory and decrements counter.
; If it hits 0, it's reinitialized, and boolean is inverted by
; tst-ing and setting according to z flag.
; 
; Arguments
; ---------
; boolean (data memory location): the thing we are toggling
; counter (data memory location): counter (must be >= 1)
; counterInit (const): initial value of counter
; 
; Return Values
; -------------
; boolean: if counter hits 0, inverted; otherwise, unchanged
; z flag: set to !boolean
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
; boolean: for holding data memory boolean
; counter: for holding data memory counter
; zFlagRead: for reading z flag
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
.macro  toggleOn0
    push    r16
    push    r17
    push    r18

    ;;; registers needed
    ; boolean we are toggling
    .def    boolean = r16
    ; counter to check boolean toggle
    .def    counter = r17
    ; for reading z flag
    .def    zFlagRead = r18

    ;;; load stuff from data memory
    lds     boolean, @0
    lds     counter, @1

    dec     counter
    ;;; get z flag
    in      zFlagRead, sreg
    ; put z flag in bottom bit
    lsr     zFlagRead
    ; mask off bottom bit
    andi    zFlagRead, 0x01

    ;;; invert boolean if z flag set (i.e. if we hit 0)
    eor     boolean, zFlagRead

    ;;; reinit counter if z flag set (i.e. if we hit 0)
    ; if z flag = 0, skip the next line
    sbrc    zFlagRead, 0
    ldi     counter, @2

    ;;; store stuff back in data memory
    sts     @0, boolean
    sts     @1, counter

    ;;; return current value of boolean
    tst     boolean

    pop     r18
    pop     r17
    pop     r16
.endm




; flipBits(byte, biti, bitj, bitjMask)
; ====================================
; 
; Description
; -----------
; Exchanges byte[biti] with byte[bitj].
; Syntax:
;   flipBits    Rd, biti, bitj, bitjMask
; 0 <= d <= 31 and biti, bitj, and bitjMasks are constants.
; 
; Operational Description
; -----------------------
; Stores biti in t, sets/clears biti according to bitj, and loads
; t into bitj.
; 
; Arguments
; ---------
; byte (Rd): register containing bits to flip
; biti (const): index of the ith bit in byte
; bitj (const): index of the jth bit in byte
; bitjMask (const): const for masking off bitj from byte
; 
; Return Values
; -------------
; Rd (byte): byte with biti and bitj flipped.
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
; 0 byte
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
.macro  flipBits
    ; store byte[biti] in t flag
    bst     @0, @1

    ; if byte[bitj] is clear, skip the next instr
    sbrc    @0, @2
    ; if byte[bitj] is set, set byte[biti]
    sbr     @0, @3

    ; if byte[bitj] is set, skip the next instr
    sbrs    @0, @2
    ; if byte[bitj] is clear, clear byte[biti]
    cbr     @0, @3

    ; load t flag into byte[bitj]
    bld     @0, @2
.endm




; flipByte(byte)
; ==============
; 
; Description
; -----------
; Flips the byte such that byte[k] = byte[7-k]. For example,
; suppose byte contains 0b01100001; flipByte(byte) would result
; in byte containing 0b10000110.
; Syntax:
;   flipByte    Rd
; 0 <= d <= 31
; 
; Operational Description
; -----------------------
; Calls flipBit(byte, k, 7-k, kMask) for (7,0), (6,1), (5,2), and (4,3).
; 
; Arguments
; ---------
; byte (Rd): register containing byte to flip
; 
; Return Values
; -------------
; Rd (byte): byte flipped
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
; 0 bytes
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
.macro  flipByte
    flipBits    @0, 7, 0, BIT7_MASK
    flipBits    @0, 6, 1, BIT6_MASK
    flipBits    @0, 5, 2, BIT5_MASK
    flipBits    @0, 4, 3, BIT4_MASK
.endm



; setBitToZ(register, n)
; ======================
;
; Description
; -----------
; Sets register[7-n] to z flag.
; The reason why it's backwards is because this macro is primarily used for
; setting the LED display rowVectors, which are indexed backwards
; Syntax:
;   setBitToZ   Rd, Rr
; 0 <= d, r <= 31; d,r != 11.
;
; Operational Description
; -----------------------
; push sreg, lslk({one hot mask}, n), pop sreg, set/clear bit 
; using hone hot mask based on z flag.
; The reason we can't use r11 is because that's what we use to shift the
; masking register into place.
;
; Arguments
; ---------
; register (byte, Rd): register to set/clear bit in
; n (int, Rr): position in register to set/clear
; z flag: register[n] = z
;
; Return Values
; -------------
; byte, Rd: register with nth position set to z
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
; sregSaved: for reading sreg
; oneHotBit: mask for setting/clearing a bit in a byte
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
; 5 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
.macro  setBitToZ
    push    r0
    push    r11

    ; for saving sreg
    .def    sregSaved = r0

    ; for setting/clearing bit
    .def    oneHotBit = r11

    ; save sreg in r0
    in      sregSaved, sreg

    ; shift oneHotBit into place with lslk(oneHotBit, n)
    push    r16
    push    r17
    ; lslk(oneHotBit, n)
    mov     r17, @1
    ;ldi     r16, BIT0_MASK
    ;rcall   lslk
    ldi     r16, BIT7_MASK
    rcall   lsrk
    mov     oneHotBit, r16
    pop     r17
    pop     r16

    ; if z clear, skip the next instr
    sbrc    sregSaved, Z_POSITION
    ; if z set, set register[n]
    or      @0, oneHotBit
    ; fine if this instr performed, regardless of whether
    ;   z flag is set or cleared: if set, we don't need
    ;   oneHotBit anymore; if cleared, have to do this
    com     oneHotBit
    ; if z set, skip the next instr
    sbrs    sregSaved, Z_POSITION
    ; if z clear, clear register[n]
    and     @0, oneHotBit

    pop     r11
    pop     r0
.endm




; rotateOutOfBounds(num, lower, upper)
; =====================================
;
; Description
; -----------
; This macro checks if lower <= num <= upper. If not, it performs the following:
;   num < lower --> sets num to upper
;   num > upper --> sets num to lower
; Syntax:
;   rotateOutOfBounds    Rd, lower, upper
; 16 <= d <= 25, and lower and upper are immediate values.
;
; Operational Description
; -----------------------
; Checks if lower <= num <= upper with withinBounds macro.
; Then it moves Rd to xl, lower to yl,
; upper to yh and calls RotateOutOfBoundsHelper.
;
; Arguments
; ---------
; num (int, Rd): value that is checked to be within bounds
; lower (int, immediate): lower bound
; upper (int, immediate): upper bound
;
; Return Values
; -------------
; int, Rd (num): the number unchanged if within bounds, or changed in the
;   manner specified if out of bounds.
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
; 3 bytes
;
; Limitations
; -----------
; None
;
; Special Notes
; -------------
; None
.macro  rotateOutOfBounds
    push    xl
    push    yl
    push    yh

    ;;; set t flag with withinBounds(num, lower, upper)
    withinBounds    @0, @1, @2

    ;;; RotateOutOfBoundsHelper(num, lower, upper)
    mov     xl, @0
    ldi     yl, @1
    ldi     yh, @2
    rcall   RotateOutOfBoundsHelper

    ; xl contains adjusted num
    mov     @0, xl

    pop    yh
    pop    yl
    pop    xl
.endm