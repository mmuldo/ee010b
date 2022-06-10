;;;;;;;;;;;;;;;;
; switches.inc ;
;;;;;;;;;;;;;;;;

; Description
; -----------
; constants and macros for switch logic
;
; Constants
; ---------
; LRROT_BIT1: lr rotary encoder bit position in port
; LRROT_BIT2: lr rotary encoder bit position in port
; UDROT_BIT1: ud rotary encoder bit position in port
; UDROT_BIT2: ud rotary encoder bit position in port
; GRAYCODE_STACK_INIT
; GRAYCODE_CCW_FULL: value of graycode stack when it's been fully
;   turned counter clockwise
; GRAYCODE_CW_FULL: value of graycode stack when it's been fully
;   turned clockwise
; ON_DETENT: graycode value when rotary encoder is on detent
; PENULTIMATE_MASK: graycode stack mask for the 2nd to last seen
;   rotary encoder graycode value
; PREVIOUS_MASK: graycode stack mask for the last seen
;   rotary encoder graycode value
; LRSWITCH_MASK: lr switch mask in port
; UDSWITCH_MASK: ud switch mask in port
; DEBOUNCE_TIME: amount of time (ms) switch needs to be held down before
;   considered a "press"
;
; Macros
; ------
; debounce(counter, switchPin, switchMask): distinguishes a "press" on pin
;   from random fluctuations
; derot(grayCodeStack, fullTurn, rotPin, rotBit1, rotBit2): distinguishes
;   "rotation" on pin from random fluctuations
;
; Revision History
; ----------------
; 04/30/2022    Matt Muldowney      switch consts
; 06/02/2022    Matt Muldowney      debounce and derot macros


; ##########
; # consts #
; ##########

; Rotary encoders
; ===============
; bit locations
; -------------
.equ    LRROT_BIT1  = 7
.equ    LRROT_BIT2  = 6
.equ    UDROT_BIT1  = 4
.equ    UDROT_BIT2  = 3

; initial graycode stack: assume that we start on a detent
; --------------------------------------------------------
.EQU    GRAYCODE_STACK_INIT = 0b00000011

; what stack looks like after a full counter-clockwise rotation
; -------------------------------------------------------------
.EQU    GRAYCODE_CCW_FULL   = 0b11100001

; what stack looks like after a full clockwise rotation
; -------------------------------------------------------------
.EQU    GRAYCODE_CW_FULL    = 0b11010010

; detent graycode
; ---------------
.equ    ON_DETENT = 0b11

; 2nd to last encoder reading mask
; --------------------------------
.equ    PENULTIMATE_MASK = 0b00001100

; last encoder reading mask
; --------------------------------
.equ    PREVIOUS_MASK = 0b00000011

; Switches
; ========
; masks
; -----
.equ    LRSWITCH_MASK   = 0b00100000
.equ    UDSWITCH_MASK   = 0b00000100

; switch timer starting value in ms
; -----------------------------------------------------
.EQU    DEBOUNCE_TIME = 20




; debounce(counter, switchPin, switchMask, pressedFlag)
; =====================================================
; 
; Description
; -----------
; This macro distinguishes a switch press from random switch fluctuations.
; The counter argument presumably starts at some positive value and then
; counts down while the switch is held down.
; A switch press should be registered iff the counter is 1 and the switch
; is still held down. Note that if the counter is 0 and the switch is still
; held down, the counter will not decrement further, but will also not
; register a switch press, since it was already done when the counter was 1.
; Whenever the switch is not held down, the counter is reinit-ed to its
; starting value. If a switch press is to be registered, pressedFlag will
; be set; otherwise, pressedFlag is cleared.
; Syntax:
;   debounce    counter, switchPin, switchMask, pressedFlag
; where counter is a shared variable in data memory, switchPin is the input
; pin that the switch resides on, switchMask is the specific bit for the
; switch's input pin, and pressedFlag is a shared variable in data memory.
; 
; Operational Description
; -----------------------
; Reads in switchPin and masks off what we want with switchMask. Then,
; Calls DebounceHelper and sets pressedFlag = z flag.
; 
; Arguments
; ---------
; counter (16-bit address): location of counter variable in data memory
; switchPin: I/O pin that the switch is on
; switchMask: const for masking switch off pin
; pressedFlag (16-bit address): location of the boolean in data memory that
;   indicates the switch was pressed
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
; none
; 
; Local Variables
; ---------------
; switchPinReading: for reading in i/o switch pin
; localCounter: local copy of counter (since we might reset it)
; isPressed: local copy to store in pressedFlag
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
; Decrementer
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
; 4 bytes
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
.macro  debounce
    push    r16
    push    r17

    ; for reading in switch pin
    .def    switchPinReading = r17

    ; for storing counter locally
    .def    localCounter = r16
    lds     localCounter, @0

    ;;; read switch pin and mask off the thing we want
    in      switchPinReading, @1
    ; compliment because switch pin is active low
    com     switchPinReading
    ; mask off switch's pin bit
    andi    switchPinReading, @2

    ;;; call debounce helper
    ; counter in r16
    ; switchReading in r17
    rcall   DebounceHelper
    ; updated counter in r16
    ; z flag set iff switch pressed

    ;;; move z flag to pressedFlag
    ; reuse r17
    ; for reading z flag into pressedFlag
    .def    isPressed = r17

    ; read in sreg
    in      isPressed, sreg
    ; z flag in sreg[1], so lsr
    lsr     isPressed
    ; and mask off
    andi    isPressed, TRUE
    ; finally, store in data memory flag
    sts     @3, isPressed

    ; also store counter back in data memory
    sts     @0, localCounter

    pop     r17
    pop     r16
.endm



; derot(grayCodeStack, fullTurn, rotPin, rotBit1, rotBit2, rotFlag)
; =================================================================
; 
; Description
; -----------
; Macro responsible for distinguishing between a turn 
; between one detent to the adjacent detent on a rotary encoder and random
; jiggling in between detents. A full turn is registered iff the encoder
; reading (from rotPin[rotBit1,2]) == ON_DETENT and the 
; grayCodeStack == fullTurn.
; If a full turn is registered, the rotFlag will be set to TRUE; otherwise, the
; rotFlag flag will be cleared. Moreover, the grayCodeStack is updated in the
; following manner:
;   full turn --> reinitialized
;   otherwise --> if encoderReading == 2 readings previous, popped off 
;                       grayCodeStack
;                   if encoderReading == previous reading, do nothing
;                   otherwise, encoderReading pushed onto grayCodeStack
; Syntax:
;   derot   grayCodeStack, fullTurn, rotPin, rotBit1, rotBit2, rotFlag
; where grayCodeStack is a data memory variable, fullTurn is an immediate,
; rotPin is an I/O pin, rotMask is an immediate, and rotFlag is a
; data memory variable.
; 
; Operational Description
; -----------------------
; Reads in from rotPin and masks off with rotMask, then calls DerotHelper.
; Then sets rotFlag according to z flag.
; 
; Arguments
; ---------
; grayCodeStack (16-bit address): stack of previous encoder readings
; fullTurn (8-bit immediate): what the grayCodeStack will be after a
;   full turn
; rotPin (I/O pin): pin in which rotary encoder resides on
; rotBit1 (immediate): first bit of rotary encoder on pin
; rotBit2 (immediate): second bit of rotary encoder on pin
; rotFlag (16-bit address): location of the boolean in data memory that
;   indicates the rotary encoder was turned
; 
; Return Values
; -------------
; none
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
; grayCodeStackReg: local copy of gray code stack
; encoderReadin: for reading in rotary encoder from pin
; fullTurnReg: for storing fullTurn const in register
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
; None
; 
; Data Structures
; ---------------
; none
; 
; Registers Changed
; -----------------
; None
;
; Stack Depth
; -----------
; 6 bytes
;
; Limitations
; -----------
; none
; 
; Known Bugs
; ----------
; None
; 
; Special Notes
; -------------
; None
.macro  derot
    ; save registers we use
    push    r16
    push    r17
    push    r18

    ;;; arguments for DerotHelper
    .def    grayCodeStackReg = r16
    .def    encoderReading = r17
    .def    fullTurnReg = r18

    ;;; load in gray code stack from data memory
    lds     grayCodeStackReg, @0

    ;;; read in encoder from pin
    in      encoderReading, @2
    ; "mask off" procedure: use t flag to get the bits we want
    ;   and put them in the bottom 2 bits of reading
    bst     encoderReading, @3
    bld     encoderReading, 1
    bst     encoderReading, @4
    bld     encoderReading, 0
    ; mask off bottom 2 bits
    andi    encoderReading, 0b00000011

    ;;; load fullTurn immediate into register
    ldi     fullTurnReg, @1

    ;;; call helper
    rcall   DerotHelper
    ; updated graycodestack in r16
    ; z flag set iff encoder turned

    ;;; move z flag to rotFlag
    ; reuse r17
    ; for reading z flag into rotFlag
    .def    isRot = r17

    ; read in sreg
    in      isRot, sreg
    ; z flag in sreg[1], so lsr
    lsr     isRot
    ; and mask off
    andi    isRot, TRUE
    ; finally, store in data memory flag
    sts     @5, isRot

    ;;; load new grayCodeStack into data memory
    sts     @0, grayCodeStackReg

    pop     r18
    pop     r17
    pop     r16
.endm