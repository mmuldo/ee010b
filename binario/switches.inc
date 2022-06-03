;;;;;;;;;;;;;;;;
; switches.inc ;
;;;;;;;;;;;;;;;;

; constants for switch logic
;
; Revision History
; ----------------
; 04/30/2022    Matt Muldowney      

; PortE Masks
; ===========
; PortE[5]: L/R switch
; --------------------
.EQU    PORTE_LRSWITCH_MSK  = 0b00100000

; PortE[2]: U/D switch
; --------------------
.EQU    PORTE_UDSWITCH_MSK  = 0b00000100

; PortE[7,6]: L/R rotary encoder
; ------------------------------
.EQU    PORTE_LRROT_MSK     = 0b11000000
.EQU    PORTE_LRROT_SHIFT   = 6             ; amount to LSR

; PortE[4,3]: U/D rotary encoder
; ------------------------------
.EQU    PORTE_UDROT_MSK     = 0b00011000
.EQU    PORTE_UDROT_SHIFT   = 3             ; amount to LSR



; Rotary encoders
; ===============
; initial graycode stack: assume that we start on a detent
; --------------------------------------------------------
.EQU    GRAYCODE_STACK_INIT = 0b00000011

; what stack looks like after a full counter-clockwise rotation
; -------------------------------------------------------------
.EQU    GRAYCODE_CCW_FULL   = 0b11100001

; what stack looks like after a full clockwise rotation
; -------------------------------------------------------------
.EQU    GRAYCODE_CW_FULL    = 0b11010010



; Switches
; ========
; switch timer starting value: counts down from 20ms in
.EQU    SWITCH_COUNTER_INIT = 20



; debounce(counter, switchPin, switchMask)
; ========================================
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
; starting value. If a switch press is to be registered, the t flag will
; be set; otherwise, the t flag is cleared.
; Syntax:
;   debounce    counter, switchPin, switchMask
; where counter is a shared variable in data memory, switchPin is the input
; pin that the switch resides on, and switchMask is the specific bit for the
; switch's input pin.
; 
; Operational Description
; -----------------------
; Reads in switchPin and masks off what we want with switchMask. Then,
; it tst's the masked off reading and puts the result in t. It then
; resolves the counter (back in data memory) based on the result. Then, it
; ands this result with (local) counter (since we want to check if counter is 1)
; and puts the result in t.
; 
; Arguments
; ---------
; counter (16-bit address): location of counter variable in data memory
; switchPin: I/O pin that the switch is on
; switchMask: const for masking switch off pin
; 
; Return Values
; -------------
; t: set iff switch press should be registered
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
; [unknown]
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
    ; for reading in switch pin
    .def    switchPinReading = r23
    push    switchPinReading

    ; for storing counter locally
    .def    localCounter = r22
    push    localCounter
    sts     localCounter, @0

    ; for performing operations with t
    .def    tReading = r21
    push    tReading
    ; set to all 1's initially
    ldi     tReading, 0xFF

    ;;; read switch pin and mask off the thing we want
    in      switchPinReading, @1
    andi    switchPinReading, @2

    ;;; put reading into t flag
    tstWithT    switchPinReading

    ;;; based on result, resolve the counter (dec/reinit/don't do anything)
    push    yl
    push    yh
    ldi     yl, low(@0)
    ldi     yh, high(@0)
    rcall   ResolveSwitchCounter

    ;;; set t according to pin reading and current count value
    bld     tReading, 0
    and     tReading, counter
    subi    tReading, 1
    ; if counter was 1, tReading should now be 0
    tstWithT    tReading
.endm