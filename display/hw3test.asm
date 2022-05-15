;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW3TEST                                  ;
;                            Homework #3 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #3.  The function makes a
; number of calls to the display functions to test them.  The functions
; included are:
;    DisplayTest - test the homework display functions
;
; Revision History:
;    5/15/18  Glen George               initial revision
;    4/21/22  Glen George               added constants for test table sizes
;    5/14/22  Matt Muldowney            downloaded
;    5/14/22  Matt Muldowney            added Start function for running tests



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


.dseg
					.byte 127
	TopOfStack:		.byte 1


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

		rcall	InitDisplayPorts
        rcall   InitDisplayVars
        rcall   InitTimer0
        sei

        rcall DisplayTest

; DisplayTest
;
; Description:       This procedure tests the display functions.  It first
;                    loops calling the PlotPixel function.  Following this it
;                    makes a number of calls to SetCursor.  Finally it
;                    interleaves calls to SetCursor and PlotPixel.  To test
;                    the code the display must be checked for the appropriate
;                    patterns being displayed.  The function never returns.
;
; Operation:         The arguments to call each function with are stored in
;                    tables.  The function loops through the tables making the
;                    appropriate display code calls.  Delays are done after
;                    most calls so the display can be examined.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R20         - test counter.
;                    Z (ZH | ZL) - test table pointer.
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
; Registers Changed: flags, R16, R17, R18, R19, R20, R21, Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       unknown (at least 7 bytes)
;
; Author:            Glen George
; Last Modified:     May 15, 2018

DisplayTest:


        RCALL   ClearDisplay            ;first clear the display

FillRed:                                ;now fill the display with red
        LDI     R16, 7                  ;initialize row counter

FillRedRowLoop:
        LDI     R17, 7                  ;initialize column counter each row

FillRedColLoop:
        PUSH    R16                     ;save row and column counters
        PUSH    R17
        LDI     R18, PIXEL_RED          ;want a red pixel
        RCALL   PlotPixel               ;and plot the pixel
        POP     R17                     ;restore row and column counters
        POP     R16

        DEC     R17                     ;update column
        BRPL    FillRedColLoop          ;and loop until all columns done

        DEC     R16                     ;update row
        BRPL    FillRedRowLoop          ;and loop until all rows done

        LDI     R16, 100                ;now delay a bit
        RCALL   Delay16


FillGreen:                              ;now fill the display with green
        LDI     R17, 7                  ;initialize column counter

FillGreenColLoop:
        LDI     R16, 7                  ;initialize row counter each column

FillGreenRowLoop:
        PUSH    R16                     ;save row and column counters
        PUSH    R17
        LDI     R18, PIXEL_GREEN        ;want a green pixel
        RCALL   PlotPixel               ;and plot the pixel
        POP     R17                     ;restore row and column counters
        POP     R16

        DEC     R16                     ;update row
        BRPL    FillGreenRowLoop        ;and loop until all rows done

        DEC     R17                     ;update column
        BRPL    FillGreenColLoop        ;and loop until all columns done

        LDI     R16, 100                ;now delay a bit
        RCALL   Delay16


        RCALL   ClearDisplay            ;clear the display
        LDI     R16, 100                ;delay a bit
        RCALL   Delay16


PlotPixelTests:                         ;do the PlotPixel tests
        LDI     ZL, LOW(2 * TestPPTab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestPPTab) ;   PlotPixel test table
        LDI     R20, TestPPTab_ENTRIES  ;get the number of tests

PlotPixelTestLoop:

        LPM     R16, Z+                 ;get the PlotPixel arguments from the
        LPM     R17, Z+                 ;   table
        LPM     R18, Z+

        PUSH    ZL                      ;save registers around PlotPixel call
        PUSH    ZH
        PUSH    R20
        RCALL   PlotPixel               ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LPM     R16, Z+                 ;get the time delay from the table
        RCALL   Delay16                 ;and do the delay

        DEC     R20                     ;update loop counter
        BRNE    PlotPixelTestLoop       ;and keep looping if not done
        ;BREQ   SetCursorTests          ;otherwise test SetCursor function


SetCursorTests:                         ;do the SetCursor tests
        LDI     ZL, LOW(2 * TestSCTab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestSCTab) ;   SetCursor test table
        LDI     R20, TestSCTab_ENTRIES  ;get the number of tests

SetCursorTestLoop:

        LPM     R16, Z+                 ;get the SetCursor arguments from the
        LPM     R17, Z+                 ;   table
        LPM     R18, Z+
        LPM     R19, Z+

        PUSH    ZL                      ;save registers around SetCursor call
        PUSH    ZH
        PUSH    R20
        RCALL   SetCursor               ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LPM     R16, Z                  ;get the time delay from the table
        RCALL   Delay16                 ;and do the delay
        LPM     R16, Z+                 ;do twice the delay
        RCALL   Delay16

        ADIW    Z, 1                    ;skip the padding byte

        DEC     R20                     ;update loop counter
        BRNE    SetCursorTestLoop       ;and keep looping if not done
        ;BREQ   TestSetCursor2          ;otherwise test SetCursor function


TestSetCursor2:                         ;do special SetCursor tests
        LDI     ZL, LOW(2 * TestSSCTab) ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestSSCTab);   special SetCursor test table
        LDI     R20, TestSSCTab_ENTRIES ;get the number of tests

SetCursorTestLoop2:

        LPM     R16, Z+                 ;get the SetCursor arguments from the
        LPM     R17, Z+                 ;   table
        LPM     R18, Z+
        LPM     R19, Z+

        PUSH    R16                     ;save location for PlotPixel call
        PUSH    R17

        PUSH    ZL                      ;save registers around SetCursor call
        PUSH    ZH
        PUSH    R20
        RCALL   SetCursor               ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LPM     R16, Z+                 ;get the time delay from the table
        MOV     R21, R16                ;save time delay for later
        RCALL   Delay16                 ;and do the delay

        LPM     R18, Z+                 ;get PlotPixel color from table

        POP     R17                     ;restore coordinates for PlotPixel
        POP     R16

        PUSH    ZL                      ;save registers around PlotPixel call
        PUSH    ZH
        PUSH    R20
        PUSH    R21
        RCALL   PlotPixel               ;call the function
        POP     R21                     ;restore the registers
        POP     R20
        POP     ZH
        POP     ZL


        MOV     R16, R21                ;get the delay back and do it again
        RCALL   Delay16

        DEC     R20                     ;update loop counter
        BRNE    SetCursorTestLoop2      ;and keep looping if not done
        ;BREQ   DoneDisplayTests        ;otherwise done with display tests


DoneDisplayTests:                       ;have done all the tests
        LDI     R16, 8                  ;turn off the cursor
        LDI     R17, 8                  ;   (don't care about color)
        RCALL   SetCursor
        RJMP    DisplayTest             ;start over and loop forever


        RET                             ;should never get here




; Delay16
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

Delay16:

Delay16Loop:                            ;outer loop runs R16 times
        LDI     YL, LOW(20000)          ;inner loop is 4 clocks
        LDI     YH, HIGH(20000)         ;so loop 20000 times to get 80000 clocks
Delay16InnerLoop:                       ;do the delay
        SBIW    Y, 1
        BRNE    Delay16InnerLoop

        DEC     R16                     ;count outer loop iterations
        BRNE    Delay16Loop


DoneDelay16:                            ;done with the delay loop - return
        RET




; Test Tables


; TestPPTab
;
; Description:      This table contains the values of arguments for testing
;                   the PlotPixel function.  Each entry consists of the row
;                   number (0 to 7), the column number (0 to 7), the pixel
;                   color, and the time delay to leave the pixel displayed.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

TestPPTab:
               ;Row    Column    Color         Delay
        .DB      0,      0,      PIXEL_RED,       1     ;fill display diagonally

        ;size of each entry
        .EQU    TestPPTab_ENTRY_SIZE = PC - TestPPTab

        .DB      7,      7,      PIXEL_GREEN,     5
        .DB      1,      0,      PIXEL_RED,       1
        .DB      6,      7,      PIXEL_GREEN,     5
        .DB      0,      1,      PIXEL_RED,       1
        .DB      7,      6,      PIXEL_GREEN,     5
        .DB      0,      2,      PIXEL_RED,       1
        .DB      7,      5,      PIXEL_GREEN,     5
        .DB      1,      1,      PIXEL_RED,       1
        .DB      6,      6,      PIXEL_GREEN,     5
        .DB      2,      0,      PIXEL_RED,       1
        .DB      5,      7,      PIXEL_GREEN,     5
        .DB      3,      0,      PIXEL_RED,       1
        .DB      4,      7,      PIXEL_GREEN,     5
        .DB      2,      1,      PIXEL_RED,       1
        .DB      5,      6,      PIXEL_GREEN,     5
        .DB      1,      2,      PIXEL_RED,       1
        .DB      6,      5,      PIXEL_GREEN,     5
        .DB      0,      3,      PIXEL_RED,       1
        .DB      7,      4,      PIXEL_GREEN,     5
        .DB      0,      4,      PIXEL_RED,       1
        .DB      7,      3,      PIXEL_GREEN,     5
        .DB      1,      3,      PIXEL_RED,       1
        .DB      6,      4,      PIXEL_GREEN,     5
        .DB      2,      2,      PIXEL_RED,       1
        .DB      5,      5,      PIXEL_GREEN,     5
        .DB      3,      1,      PIXEL_RED,       1
        .DB      4,      6,      PIXEL_GREEN,     5
        .DB      4,      0,      PIXEL_RED,       1
        .DB      3,      7,      PIXEL_GREEN,     5
        .DB      5,      0,      PIXEL_RED,       1
        .DB      2,      7,      PIXEL_GREEN,     5
        .DB      4,      1,      PIXEL_RED,       1
        .DB      3,      6,      PIXEL_GREEN,     5
        .DB      3,      2,      PIXEL_RED,       1
        .DB      4,      5,      PIXEL_GREEN,     5
        .DB      2,      3,      PIXEL_RED,       1
        .DB      5,      4,      PIXEL_GREEN,     5
        .DB      1,      4,      PIXEL_RED,       1
        .DB      6,      3,      PIXEL_GREEN,     5
        .DB      0,      5,      PIXEL_RED,       1
        .DB      7,      2,      PIXEL_GREEN,     5
        .DB      0,      6,      PIXEL_RED,       1
        .DB      7,      1,      PIXEL_GREEN,     5
        .DB      1,      5,      PIXEL_RED,       1
        .DB      6,      2,      PIXEL_GREEN,     5
        .DB      2,      4,      PIXEL_RED,       1
        .DB      5,      3,      PIXEL_GREEN,     5
        .DB      3,      3,      PIXEL_RED,       1
        .DB      4,      4,      PIXEL_GREEN,     5
        .DB      4,      2,      PIXEL_RED,       1
        .DB      3,      5,      PIXEL_GREEN,     5
        .DB      5,      1,      PIXEL_RED,       1
        .DB      2,      6,      PIXEL_GREEN,     5
        .DB      6,      0,      PIXEL_RED,       1
        .DB      1,      7,      PIXEL_GREEN,     5
        .DB      7,      0,      PIXEL_RED,       1
        .DB      0,      7,      PIXEL_GREEN,     5
        .DB      6,      1,      PIXEL_RED,       1
        .DB      1,      6,      PIXEL_GREEN,     5
        .DB      5,      2,      PIXEL_RED,       1
        .DB      2,      5,      PIXEL_GREEN,     5
        .DB      4,      3,      PIXEL_RED,       1
        .DB      3,      4,      PIXEL_GREEN,   100

        .DB      0,      7,      PIXEL_OFF,      10     ;clear display diagonally
        .DB      0,      6,      PIXEL_OFF,       1
        .DB      1,      7,      PIXEL_OFF,      10
        .DB      0,      5,      PIXEL_OFF,       1
        .DB      1,      6,      PIXEL_OFF,       1
        .DB      2,      7,      PIXEL_OFF,      10
        .DB      0,      4,      PIXEL_OFF,       1
        .DB      1,      5,      PIXEL_OFF,       1
        .DB      2,      6,      PIXEL_OFF,       1
        .DB      3,      7,      PIXEL_OFF,      10
        .DB      0,      3,      PIXEL_OFF,       1
        .DB      1,      4,      PIXEL_OFF,       1
        .DB      2,      5,      PIXEL_OFF,       1
        .DB      3,      6,      PIXEL_OFF,       1
        .DB      4,      7,      PIXEL_OFF,      10
        .DB      0,      2,      PIXEL_OFF,       1
        .DB      1,      3,      PIXEL_OFF,       1
        .DB      2,      4,      PIXEL_OFF,       1
        .DB      3,      5,      PIXEL_OFF,       1
        .DB      4,      6,      PIXEL_OFF,       1
        .DB      5,      7,      PIXEL_OFF,      10
        .DB      0,      1,      PIXEL_OFF,       1
        .DB      1,      2,      PIXEL_OFF,       1
        .DB      2,      3,      PIXEL_OFF,       1
        .DB      3,      4,      PIXEL_OFF,       1
        .DB      4,      5,      PIXEL_OFF,       1
        .DB      5,      6,      PIXEL_OFF,       1
        .DB      6,      7,      PIXEL_OFF,      10
        .DB      0,      0,      PIXEL_OFF,       1
        .DB      1,      1,      PIXEL_OFF,       1
        .DB      2,      2,      PIXEL_OFF,       1
        .DB      3,      3,      PIXEL_OFF,       1
        .DB      4,      4,      PIXEL_OFF,       1
        .DB      5,      5,      PIXEL_OFF,       1
        .DB      6,      6,      PIXEL_OFF,       1
        .DB      7,      7,      PIXEL_OFF,      10
        .DB      1,      0,      PIXEL_OFF,       1
        .DB      2,      1,      PIXEL_OFF,       1
        .DB      3,      2,      PIXEL_OFF,       1
        .DB      4,      3,      PIXEL_OFF,       1
        .DB      5,      4,      PIXEL_OFF,       1
        .DB      6,      5,      PIXEL_OFF,       1
        .DB      7,      6,      PIXEL_OFF,      10
        .DB      2,      0,      PIXEL_OFF,       1
        .DB      3,      1,      PIXEL_OFF,       1
        .DB      4,      2,      PIXEL_OFF,       1
        .DB      5,      3,      PIXEL_OFF,       1
        .DB      6,      4,      PIXEL_OFF,       1
        .DB      7,      5,      PIXEL_OFF,      10
        .DB      3,      0,      PIXEL_OFF,       1
        .DB      4,      1,      PIXEL_OFF,       1
        .DB      5,      2,      PIXEL_OFF,       1
        .DB      6,      3,      PIXEL_OFF,       1
        .DB      7,      4,      PIXEL_OFF,      10
        .DB      4,      0,      PIXEL_OFF,       1
        .DB      5,      1,      PIXEL_OFF,       1
        .DB      6,      2,      PIXEL_OFF,       1
        .DB      7,      3,      PIXEL_OFF,      10
        .DB      5,      0,      PIXEL_OFF,       1
        .DB      6,      1,      PIXEL_OFF,       1
        .DB      7,      2,      PIXEL_OFF,      10
        .DB      6,      0,      PIXEL_OFF,       1
        .DB      7,      1,      PIXEL_OFF,      10
        .DB      7,      0,      PIXEL_OFF,      50

        .DB      0,      0,      PIXEL_RED,       1     ;checkboard test pattern
        .DB      1,      0,      PIXEL_RED,       1
        .DB      2,      0,      PIXEL_RED,       1
        .DB      3,      0,      PIXEL_OFF,       1
        .DB      4,      0,      PIXEL_OFF,       1
        .DB      5,      0,      PIXEL_GREEN,     1
        .DB      6,      0,      PIXEL_GREEN,     1
        .DB      7,      0,      PIXEL_GREEN,    10
        .DB      0,      1,      PIXEL_RED,       1
        .DB      1,      1,      PIXEL_RED,       1
        .DB      2,      1,      PIXEL_RED,       1
        .DB      3,      1,      PIXEL_OFF,       1
        .DB      4,      1,      PIXEL_OFF,       1
        .DB      5,      1,      PIXEL_GREEN,     1
        .DB      6,      1,      PIXEL_GREEN,     1
        .DB      7,      1,      PIXEL_GREEN,    10
        .DB      0,      2,      PIXEL_RED,       1
        .DB      1,      2,      PIXEL_RED,       1
        .DB      2,      2,      PIXEL_RED,       1
        .DB      3,      2,      PIXEL_OFF,       1
        .DB      4,      2,      PIXEL_OFF,       1
        .DB      5,      2,      PIXEL_GREEN,     1
        .DB      6,      2,      PIXEL_GREEN,     1
        .DB      7,      2,      PIXEL_GREEN,    10
        .DB      0,      3,      PIXEL_OFF,       1
        .DB      1,      3,      PIXEL_OFF,       1
        .DB      2,      3,      PIXEL_OFF,       1
        .DB      3,      3,      PIXEL_RED,       1
        .DB      4,      3,      PIXEL_RED,       1
        .DB      5,      3,      PIXEL_OFF,       1
        .DB      6,      3,      PIXEL_OFF,       1
        .DB      7,      3,      PIXEL_OFF,      10
        .DB      0,      4,      PIXEL_OFF,       1
        .DB      1,      4,      PIXEL_OFF,       1
        .DB      2,      4,      PIXEL_OFF,       1
        .DB      3,      4,      PIXEL_RED,       1
        .DB      4,      4,      PIXEL_RED,       1
        .DB      5,      4,      PIXEL_OFF,       1
        .DB      6,      4,      PIXEL_OFF,       1
        .DB      7,      4,      PIXEL_OFF,      10
        .DB      0,      5,      PIXEL_GREEN,     1
        .DB      1,      5,      PIXEL_GREEN,     1
        .DB      2,      5,      PIXEL_GREEN,     1
        .DB      3,      5,      PIXEL_OFF,       1
        .DB      4,      5,      PIXEL_OFF,       1
        .DB      5,      5,      PIXEL_RED,       1
        .DB      6,      5,      PIXEL_RED,       1
        .DB      7,      5,      PIXEL_RED,      10
        .DB      0,      6,      PIXEL_GREEN,     1
        .DB      1,      6,      PIXEL_GREEN,     1
        .DB      2,      6,      PIXEL_GREEN,     1
        .DB      3,      6,      PIXEL_OFF,       1
        .DB      4,      6,      PIXEL_OFF,       1
        .DB      5,      6,      PIXEL_RED,       1
        .DB      6,      6,      PIXEL_RED,       1
        .DB      7,      6,      PIXEL_RED,      10
        .DB      0,      7,      PIXEL_GREEN,     1
        .DB      1,      7,      PIXEL_GREEN,     1
        .DB      2,      7,      PIXEL_GREEN,     1
        .DB      3,      7,      PIXEL_OFF,       1
        .DB      4,      7,      PIXEL_OFF,       1
        .DB      5,      7,      PIXEL_RED,       1
        .DB      6,      7,      PIXEL_RED,       1
        .DB      7,      7,      PIXEL_RED,     100

        ; number of entries in the table
        .EQU    TestPPTab_ENTRIES = (PC - TestPPTab) / TestPPTab_ENTRY_SIZE




; TestSCTab
;
; Description:      This table contains the values of arguments for testing
;                   the SetCursor function.  Each entry consists of the row
;                   number (0 to 7), the column number (0 to 7), the first
;                   cursor color, the second cursor color, the time delay to
;                   leave the cursor displayed, and a padding byte of 0 (so
;                   each entry is an even number of bytes - word aligned).
;
; Author:           Glen George
; Last Modified:    April 6, 2018

TestSCTab:
               ;Row    Column    Color 1       Color 2       Delay   Padding
        .DB      0,      0,      PIXEL_GREEN,  PIXEL_OFF,     250,      0

        ;size of each test table entry
        .EQU    TestSCTab_ENTRY_SIZE = PC - TestSCTab

        .DB      7,      7,      PIXEL_RED,    PIXEL_OFF,     250,      0
        .DB      0,      7,      PIXEL_RED,    PIXEL_OFF,     250,      0
        .DB      7,      0,      PIXEL_GREEN,  PIXEL_OFF,     250,      0
        .DB      4,      4,      PIXEL_GREEN,  PIXEL_RED,     250,      0
        .DB      1,      4,      PIXEL_GREEN,  PIXEL_RED,     250,      0
        .DB      5,      3,      PIXEL_OFF,    PIXEL_RED,     250,      0
        .DB      5,      5,      PIXEL_OFF,    PIXEL_GREEN,   250,      0
        .DB      4,      6,      PIXEL_RED,    PIXEL_GREEN,   250,      0
        .DB      2,      5,      PIXEL_RED,    PIXEL_RED,     250,      0
        .DB      3,      4,      PIXEL_GREEN,  PIXEL_GREEN,   250,      0
        .DB      0,      0,      PIXEL_OFF,    PIXEL_OFF,     250,      0
        .DB      8,      4,      PIXEL_GREEN,  PIXEL_RED,     250,      0
        .DB      0,      8,      PIXEL_GREEN,  PIXEL_RED,     250,      0

        ; number of entries in the table
        .EQU    TestSCTab_ENTRIES = (PC - TestSCTab) / TestSCTab_ENTRY_SIZE




; TestSSCTab
;
; Description:      This table contains the values of arguments for testing
;                   the SetCursor function.  Each entry consists of the row
;                   number (0 to 7), the column number (0 to 7), the first
;                   cursor color, the second cursor color, the time delay to
;                   leave the cursor displayed.  Following this is the color
;                   for a PlotPixel call at the same location.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

TestSSCTab:
               ;Row    Column    Color 1       Color 2      Delay  Color
        .DB      0,      0,      PIXEL_GREEN,  PIXEL_OFF,    250,  PIXEL_GREEN

        ;size of each test table entry
        .EQU    TestSSCTab_ENTRY_SIZE = PC - TestSSCTab

        .DB      0,      7,      PIXEL_OFF,    PIXEL_GREEN,  250,  PIXEL_RED
        .DB      5,      3,      PIXEL_OFF,    PIXEL_RED,    250,  PIXEL_GREEN
        .DB      3,      5,      PIXEL_GREEN,  PIXEL_OFF,    250,  PIXEL_RED
        .DB      7,      7,      PIXEL_OFF,    PIXEL_OFF,    250,  PIXEL_GREEN
        .DB      7,      0,      PIXEL_OFF,    PIXEL_OFF,    250,  PIXEL_RED
        .DB      0,      0,      PIXEL_GREEN,  PIXEL_OFF,    250,  PIXEL_RED

        ; number of entries in the table
        .EQU    TestSSCTab_ENTRIES = (PC - TestSSCTab) / TestSSCTab_ENTRY_SIZE
