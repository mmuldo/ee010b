.EQU    PORTE_LRSWITCH_MSK  = 0b00100000    ; PortE[5]
.EQU    PORTE_UDSWITCH_MSK  = 0b00000100    ; PortE[2]
.EQU    PORTE_LRROT_MSK     = 0b11000000    ; PortE[7, 6]
.EQU    PORTE_LRROT_SHIFT   = 6             ; amount to LSR
.EQU    PORTE_UDROT_MSK     = 0b00011000    ; PortE[7, 6]
.EQU    PORTE_UDROT_SHIFT   = 3             ; amount to LSR

.EQU    GRAYCODE_CCW_FULL   = 0b11100001
.EQU    GRAYCODE_CW_FULL    = 0b11010010

.EQU    SWITCH_COUNTER_INIT = 20            ; 20 ms timer
.EQU    GRAYCODE_STACK_INIT = 0b00000011    ; 20 ms timer
