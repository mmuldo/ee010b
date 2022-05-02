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
