;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW4TEST                                  ;
;                            Homework #4 Test Code                           ;
;                                   EE  10b                                  ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the test code for Homework #4.  The function makes a
; number of calls to the PlayNote and ReadEEROM functions to test them.  The
; functions included are:
;    EEROMSoundTest - test the homework sound and EEROM functions
;
; Revision History:
;    5/31/18  Glen George               initial revision
;    4/21/22  Glen George               added constants for number of tests
;    4/21/22  Glen George               changed test data to match final EEROM
;                                          values


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
;.include "binario.inc"


;the data segment


.dseg

		        .byte 127
        TopOfStack:	.byte 1

        ; buffer for data read from the EEROM
        ReadBuffer:     .BYTE   128             ;EEROM is 1024 bits
    
        ; buffer containing the expected data from the EEROM
        CompareBuffer:  .BYTE   128             ;EEROM is 1024 bits



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
        ;; initialize speaker by playing 0 Hz frequency
        ldi     r17, 0
        ldi     r16, 0
        rcall   PlayNote
        sei

        rcall ReadEEROMTests






; EEROMSoundTest
;
; Description:       This procedure tests the sound and EEROM functions.  It
;                    first loops calling the PlayNote function.  Following
;                    this it makes a number of calls to ReadEEROM.  A tone is
;                    output while testing ReadEEROM.  The tone increases in
;                    pitch as the tests are done.  If a test fails a low tone
;                    is output and the LEDs are red.  If all tests pass, the
;                    Twilight Zone theme is played and the LEDs are green.
;                    The function never returns.
;
; Operation:         The arguments to call each function with are stored in
;                    tables.  The function loops through the tables making the
;                    appropriate function calls.  Delays are done after calls
;                    to PlayNote so the sound can be heard.
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
; Output:            The LED display is set to all red or all green.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, R16, R17, R18, R19, R20, X (XH | XL), Y (YH | YL),
;                    Z (ZH | ZL)
; Stack Depth:       unknown (at least 7 bytes)
;
; Author:            Glen George
; Last Modified:     May 31, 2018

EEROMSoundTest:

TestSetup:
        LDI     R16, 0xFF               ;will be using LEDs, set up direction
        OUT     DDRA, R16
        OUT     DDRC, R16
        OUT     DDRD, R16
                                        ;copy EEROM data from code to data
        LDI     ZL, LOW(2 * EEROMDataTab)       ;start at the beginning of the
        LDI     ZH, HIGH(2 * EEROMDataTab)      ;   EEROM data table
        LDI     XL, LOW(CompareBuffer)          ;buffer with expected data
        LDI     XH, HIGH(CompareBuffer)
        LDI     R16, 128                ;128 bytes to transfer

CopyLoop:
        LPM     R0, Z+                  ;get EEROM data
        ST      X+, R0                  ;store in compare buffer
        DEC     R16                     ;update loop counter
        BRNE    CopyLoop                ;and loop while still have bytes to copy
        ;BREQ   PlayNoteTests           ;otherwise start the tests


PlayNoteTests:                          ;do some tests of PlayNote only
        LDI     ZL, LOW(2 * TestPNTab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestPNTab) ;   PlayNote test table
        LDI     R20, TestPNTab_TEST_CNT ;get the number of tests

PlayNoteTestLoop:
        LPM     R16, Z+                 ;get the PlayNote argument from the
        LPM     R17, Z+                 ;   table

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 200                ;delay for 2 seconds
        RCALL   Delay16                 ;and do the delay

        DEC     R20                     ;update loop counter
        BRNE    PlayNoteTestLoop        ;and keep looping if not done
        ;BREQ   ReadEEROMTests          ;otherwise test ReadEEROM function


ReadEEROMTests:                         ;do the SetCursor tests
        LDI     ZL, LOW(2 * TestRdTab)  ;start at the beginning of the
        LDI     ZH, HIGH(2 * TestRdTab) ;   ReadEEROM test table
        LDI     R20, TestRdTab_TEST_CNT ;get the number of tests

ReadEEROMTestLoop:

        LPM     R16, Z+                 ;get sound to play while testing EEROM
        LPM     R17, Z+                 ;   reads

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LPM     R16, Z+                 ;now get the ReadEEROM arguments from
        LPM     R17, Z+                 ;   the table
        LDI     YL, LOW(ReadBuffer)     ;buffer to read data into
        LDI     YH, HIGH(ReadBuffer)

        PUSH    ZL                      ;save registers around ReadEEROM call
        PUSH    ZH
        PUSH    R20
        PUSH    R17
        PUSH    R16
        RCALL   ReadEEROM               ;call the function
        POP     R16                     ;restore the registers
        POP     R17
        POP     R20
        POP     ZH
        POP     ZL

CheckData:                              ;check the data read
        LDI     YL, LOW(ReadBuffer)     ;buffer with data read
        LDI     YH, HIGH(ReadBuffer)
        LDI     XL, LOW(CompareBuffer)  ;buffer with expected data
        LDI     XH, HIGH(CompareBuffer)

        ADD     XL, R17                 ;get the pointer to data actually read
        LDI     R17, 0
        ADC     XH, R17

CheckDataLoop:                          ;now loop checking the bytes
        LD      R18, Y+                 ;get read data
        LD      R19, X+                 ;get compare data
        CP      R18, R19                ;check if the same
        BRNE    PlayFailure             ;if not, failure
        DEC     R16                     ;otherwise decrement byte count
        BRNE    CheckDataLoop           ;and check all the data

        LDI     R16, 35                 ;read worked - let the note play for
        RCALL   Delay16                 ;   350 milliseconds

        DEC     R20                     ;update loop counter
        BRNE    ReadEEROMTestLoop       ;and keep looping if not done
        ;BREQ   PlaySuccess             ;if done - everything worked, play success tune


PlaySuccess:                            ;play the tune indicating success

        LDI     R16, 0xFF               ;turn LEDs all green
        OUT     PORTA, R16
        LDI     R16, 0
        OUT     PORTD, R16
        LDI     R16, 0xFF
        OUT     PORTC, R16

        LDI     ZL, LOW(2 * SuccessTab) ;start at the beginning of the
        LDI     ZH, HIGH(2 * SuccessTab);   special success tune table
        LDI     R20, SuccessTab_LEN     ;get the number of notes

PlaySuccessLoop:
        LPM     R16, Z+                 ;get the PlayNote argument from the
        LPM     R17, Z+                 ;   table

        PUSH    ZL                      ;save registers around PlayNote call
        PUSH    ZH
        PUSH    R20
        RCALL   PlayNote                ;call the function
        POP     R20                     ;restore the registers
        POP     ZH
        POP     ZL

        LDI     R16, 35                 ;each note is 350ms
        RCALL   Delay16                 ;and do the delay

        DEC     R20                     ;update loop counter
        BRNE    PlaySuccessLoop         ;and keep looping if not done
        BREQ    DoneEEROMSoundTests     ;otherwise done with tests


PlayFailure:                            ;play the tune indicating failure
        LDI     R16, LOW(261)           ;play middle C
        LDI     R17, HIGH(261)
        RCALL   PlayNote

        LDI     R16, 0xFF               ;turn LEDs all red
        OUT     PORTD, R16
        LDI     R16, 0
        OUT     PORTA, R16
        LDI     R16, 0xFF
        OUT     PORTC, R16

        LDI     R16, 50                 ;1/2 second note
        RCALL   Delay16

        LDI     R16, LOW(82)            ;play E2
        LDI     R17, HIGH(82)
        RCALL   PlayNote

        LDI     R16, 100                ;1 second note
        RCALL   Delay16

        ;BREQ   DoneEEROMSoundTests     ;and done with tests


DoneEEROMSoundTests:                    ;have done all the tests
        LDI     R16, 0                  ;turn off the sound
        LDI     R17, 0
        RCALL   PlayNote

        RJMP    PC                      ;and tests are done


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


; TestPNTab
;
; Description:      This table contains the values of arguments for testing
;                   the PlayNote function.  Each entry is just a 16-bit
;                   frequency for the note to play.
;
; Author:           Glen George
; Last Modified:    April 8, 2022

TestPNTab:

        .DW     261                     ;middle C
        .DW     440                     ;middle A
        .DW     1000
        .DW     0                       ;turn off output for a bit
        .DW     2000
        .DW     50
        .DW     4000
        .DW     100

        ;size of the table (number of tests)
        .EQU    TestPNTab_TEST_CNT = PC - TestPNTab




; TestRdTab
;
; Description:      This table contains the values of arguments for testing
;                   the ReadEEROM function.  Each entry consists of the note
;                   frequency to play during the test, the number of bytes to
;                   read, and the address from which to read the bytes.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

TestRdTab:
        .DW     146
        .DB     2, 0

        ;size of each entry in test table
        .EQU    TestRdTab_ENTRY_SIZE = PC - TestRdTab

        .DW     220
        .DB     10, 6
        .DW     294
        .DB     1, 100
        .DW     370
        .DB     1, 121
        .DW     440
        .DB     2, 93
        .DW     523
        .DB     21, 68
        .DW     622
        .DB     17, 33
        .DW     784
        .DB     64, 63
        .DW     1000
        .DB     128, 0


        ;size of the table (number of tests)
        .EQU    TestRdTab_TEST_CNT = (PC - TestRdTab) / TestRdTab_ENTRY_SIZE




; SuccessTab
;
; Description:      This table contains the tune to play upon successful
;                   completion of the tests.  Each entry is the frequency of a
;                   note to play.
;
; Author:           Glen George
; Last Modified:    April 6, 2022

SuccessTab:

        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784
        .DW     860, 830, 660, 784

        ;size of the table (number of notes)
        .EQU    SuccessTab_LEN = PC - SuccessTab




; EEROMDataTab
;
; Description:      Table of data to that should be read from the EEROM.
;                   There are 1024 bits (64 16-bit words).
;
; Author:           Glen George
; Last Modified:    April 21, 2022

EEROMDataTab:

        .DW     0xD4D2, 0xB42B, 0xCA4D, 0x2D33
        .DW     0x7749, 0x4382, 0x2532, 0x70C8
        .DW     0xB4D2, 0x964B, 0xAC69, 0x2D53
        .DW     0x952E, 0x80BD, 0xD486, 0x2131
        .DW     0x6A6C, 0x9695, 0xA569, 0x539A
        .DW     0x774C, 0x1598, 0x4282, 0x9CD8
        .DW     0x939A, 0x6A65, 0xCA95, 0x6C35
        .DW     0x31B0, 0x6B8A, 0x6059, 0x838A
        .DW     0x336A, 0x4BD4, 0x2DB4, 0x95CA
        .DW     0x1313, 0x0A09, 0x3345, 0x43D8
        .DW     0x9A4D, 0x6CA5, 0x9953, 0xB266
        .DW     0x7AF0, 0x284D, 0x480C, 0x2160
        .DW     0x2D2B, 0x9AD4, 0x3665, 0xD2C9
        .DW     0xFA12, 0x73C0, 0x608E, 0xCC10
        .DW     0x9A2D, 0x9365, 0xA55A, 0xD46A
        .DW     0x60C2, 0x6302, 0x5B0C, 0x043A








; include asm files here (since no linker)
.include "timers.asm"
.include "ports.asm"
.include "switches.asm"
.include "util.asm"
.include "display.asm"
.include "sound.asm"
.include "serial.asm"
;.include "binario.asm"
