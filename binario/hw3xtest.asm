;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3XTEST                                 ;
;                      Homework #3 Extra Credit Test Code                    ;
;                                   EE/CS 10b                                ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #3 extra credit.  The function
; makes a number of calls to the display functions to test them.  The
; functions included are:
;    DisplayTestEx - test the homework extra credit display functions
;
; The local functions included are:
;    Delay16Ex - delay the passed amount of time
;
; Revision History:
;    5/15/18  Glen George               initial revision
;    4/21/22  Glen George               added constants for test table sizes



;set the device
.device ATMEGA64

; chip definitions
.include  "m64def.inc"

; local include files
.include "timers.inc"
.include "ports.inc"
.include "switches.inc"
.include "util.inc"
.include "display.inc"
.include "serial.inc"
.include "sound.inc"


;the data segment


.dseg

		        .byte 127
        TopOfStack:	.byte 1


.cseg


;setup the vector area

.org    $0000

        JMP     Start                   ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        JMP     Timer0EventHandler      ;timer 0 compare match
        JMP     PC                      ;timer 0 overflow
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compare match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready




; start of the actual program

Start:                                  ;start the CPU after a reset
        ldi     r16, low(TopOfStack)    ;initialize the stack pointer
        out     spl, r16
        ldi     r16, high(TopOfStack)
        out     sph, r16

        rcall   InitSwitchPort
        rcall   InitSwitchVars
        rcall	InitDisplayPorts
        rcall   InitDisplayVars
        rcall   InitSoundPort
        rcall   InitSerialIO
        rcall   InitTimer0
        rcall   InitTimer1
        sei

        ldi     zl, low(2*TestDisplay)
        ldi     zh, high(2*TestDisplay)
        rcall   PlotImage
        ForeverLoop:
        jmp     ForeverLoop

TestDisplay:
        .DB     0b00000000, 0b00000000          ;screen 4
        .DB     0b00001000, 0b00001000
        .DB     0b00101010, 0b00100010
        .DB     0b00010100, 0b00001000
        .DB     0b01100011, 0b01011101
        .DB     0b00010100, 0b00001000
        .DB     0b00101010, 0b00100010
        .DB     0b00001000, 0b00001000

; DisplayTestEx
;
; Description:       This procedure tests the display functions.  It tests the
;                    PlotImage function by calling it with a number of arrays
;                    in memory.
;
; Operation:         The PlotImage function is called with a number of test
;                    arrays with delays between each call.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20         - test counter.
;                    Z (ZH | ZL) - pointer to test image.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R20, Y (YH | YL), Z (ZH | ZL)
; Stack Depth:       unknown (at least 5 bytes)
;
; Author:            Glen George
; Last Modified:     May 13, 2018

DisplayTestEx:


        RCALL   ClearDisplay            ;first clear the display


PlotImageTests:                         ;do the PlotImage tests
        LDI     ZL, LOW(2 * TestPITab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestPITab) ;   PlotImage test table
        LDI     R20, TestPITab_COL_CNT  ;get the number of columns to output

PlotImageTestLoop:

        PUSH    ZL                      ;save registers around PlotImage call
        PUSH    ZH
        PUSH    R20
        RCALL   PlotImage               ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 10                 ;100 ms delay between scrolls
        RCALL   Delay16Ex               ;and do the delay

        ADIW    Z, 2 * TestPITab_COL_SIZE ;scroll the display (Z in bytes)
        DEC     R20                     ;update loop counter
        BRNE    PlotImageTestLoop       ;and keep looping if not done
        ;BREQ   PlotImageTest2          ;otherwise do some more tests


PlotImageTest2:                         ;do more PlotImage tests
        LDI     ZL, LOW(2 * TestPITab2) ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestPITab2);   second PlotImage test table
        LDI     R20, TestPITab2_IMAGE_CNT ;get the number of images to output

PlotImageTestLoop2:

        PUSH    ZL                      ;save registers around PlotImage call
        PUSH    ZH
        PUSH    R20
        RCALL   PlotImage               ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 25                 ;250 ms delay between images
        RCALL   Delay16Ex               ;and do the delay

        ADIW    Z, 2 * TestPITab2_IMAGE_SIZE ;move to next image (Z in bytes)
        DEC     R20                     ;update loop counter
        BRNE    PlotImageTestLoop2      ;and keep looping if not done
        ;BREQ   DoneDisplayTestEx       ;otherwise done with tests


DoneDisplayTestEx:                      ;have done all the tests
        RJMP    DisplayTestEx           ;start over and loop forever


        RET                             ;should never get here




; Delay16Ex
;
; Description:       This procedure delays the number of clocks passed in R16
;                    times 80000.  Thus with a 8 MHz clock the passed delay is
;                    in 10 millisecond units.
;
; Operation:         The function just loops decrementing Y until it is 0.
;
; Arguments:         R16 - 1/80000 the number of CPU clocks to delay.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 6, 2018

Delay16Ex:

Delay16ExLoop:                          ;outer loop runs R16 times
        LDI     YL, LOW(20000)          ;inner loop is 4 clocks
        LDI     YH, HIGH(20000)         ;so loop 20000 times to get 80000 clocks
Delay16ExInnerLoop:                     ;do the delay
        SBIW    Y, 1
        BRNE    Delay16ExInnerLoop

        DEC     R16                     ;count outer loop iterations
        BRNE    Delay16ExLoop


DoneDelay16Ex:                          ;done with the delay loop - return
        RET




; Test Tables


; TestPITab
;
; Description:      This table contains screens to send to the PlotImage
;                   function to test it.  Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte.  The table is designed to be scrolled one
;                   column at a time.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

TestPITab:
        .DB     0b00000000, 0b00000000

        .EQU    TestPITab_COL_SIZE = PC - TestPITab     ;size of each column

        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00011000, 0b00011000
        .DB     0b00111100, 0b00111100
        .DB     0b01111110, 0b01111110
        .DB     0b11111111, 0b11111111
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b10000001, 0b00000000
        .DB     0b11111111, 0b00000000
        .DB     0b10010001, 0b00000000
        .DB     0b10010001, 0b00000000
        .DB     0b01101110, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000001
        .DB     0b00000000, 0b00100111
        .DB     0b00000000, 0b00000001
        .DB     0b00000000, 0b00000000
        .DB     0b00010000, 0b00010000
        .DB     0b00011111, 0b00011111
        .DB     0b00001000, 0b00001000
        .DB     0b00010000, 0b00010000
        .DB     0b00010000, 0b00010000
        .DB     0b00001111, 0b00001111
        .DB     0b00000000, 0b00000000
        .DB     0b00100110, 0b00000000
        .DB     0b00101001, 0b00000000
        .DB     0b00101001, 0b00000000
        .DB     0b00011111, 0b00000000
        .DB     0b00000001, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000001 
        .DB     0b00000000, 0b00001111 
        .DB     0b00000000, 0b00010001 
        .DB     0b00000000, 0b00010000 
        .DB     0b00000000, 0b00001000 
        .DB     0b00000000, 0b00000000
        .DB     0b00000001, 0b00000001
        .DB     0b00100111, 0b00100111
        .DB     0b00000001, 0b00000001
        .DB     0b00000000, 0b00000000
        .DB     0b00001110, 0b00000000
        .DB     0b00010001, 0b00000000
        .DB     0b00010001, 0b00000000
        .DB     0b00001110, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b11111111, 0b11111111
        .DB     0b01111110, 0b01111110
        .DB     0b00111100, 0b00111100
        .DB     0b00011000, 0b00011000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000

        ; number of columns in the table
        .EQU    TestPITab_COL_CNT = (PC - TestPITab) / TestPITab_COL_SIZE




; TestPITab2
;
; Description:      This table contains screens to send to the PlotImage
;                   function to test it.  Each word is a column of the display
;                   with the red column in the low byte and green column in
;                   the high byte.  The table contains a number of screens
;                   which are meant to be displayed one at a time.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

TestPITab2:
        .DB     0b00000000, 0b00000000          ;screen 1
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00001000, 0b00001000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000

        .EQU    TestPITab2_IMAGE_SIZE = PC - TestPITab2 ;size of each screen

        .DB     0b00000000, 0b00000000          ;screen 2
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000
        .DB     0b00001000, 0b00001000
        .DB     0b00011100, 0b00010100
        .DB     0b00001000, 0b00001000
        .DB     0b00000000, 0b00000000
        .DB     0b00000000, 0b00000000

        .DB     0b00000000, 0b00000000          ;screen 3
        .DB     0b00000000, 0b00000000
        .DB     0b00001000, 0b00001000
        .DB     0b00011100, 0b00010100
        .DB     0b00110110, 0b00101010
        .DB     0b00011100, 0b00010100
        .DB     0b00001000, 0b00001000
        .DB     0b00000000, 0b00000000

        .DB     0b00000000, 0b00000000          ;screen 4
        .DB     0b00001000, 0b00001000
        .DB     0b00101010, 0b00100010
        .DB     0b00010100, 0b00001000
        .DB     0b01100011, 0b01011101
        .DB     0b00010100, 0b00001000
        .DB     0b00101010, 0b00100010
        .DB     0b00001000, 0b00001000

        .DB     0b00000000, 0b00000000          ;screen 5
        .DB     0b01001001, 0b01000001
        .DB     0b00100010, 0b00001000
        .DB     0b00000000, 0b00011100
        .DB     0b01000001, 0b00111110
        .DB     0b00000000, 0b00011100
        .DB     0b00100010, 0b00001000
        .DB     0b01001001, 0b01000001

        .DB     0b00000000, 0b00000000          ;screen 6
        .DB     0b01000001, 0b00001000
        .DB     0b00000000, 0b00101010
        .DB     0b00000000, 0b00011100
        .DB     0b00000000, 0b01111111
        .DB     0b00000000, 0b00011100
        .DB     0b00000000, 0b00101010
        .DB     0b01000001, 0b00001000

        .DB     0b00000000, 0b00000000          ;screen 7
        .DB     0b00000000, 0b01001001
        .DB     0b00000000, 0b00101010
        .DB     0b00000000, 0b00011100
        .DB     0b00000000, 0b01111111
        .DB     0b00000000, 0b00011100
        .DB     0b00000000, 0b00101010
        .DB     0b00000000, 0b01001001

        ; number of screens in the table
        .EQU    TestPITab2_IMAGE_CNT = (PC - TestPITab2) / TestPITab2_IMAGE_SIZE

; include asm files here (since no linker)
.include "timers.asm"
.include "ports.asm"
.include "switches.asm"
.include "util.asm"
.include "display.asm"
.include "sound.asm"
.include "serial.asm"
