;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   HW2TEST                                  ;
;                            Homework #2 Test Code                           ;
;                                  EE/CS 10b                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Description:      This program tests the switch and encoder functions for
;                   Homework #2.  It sets up the stack and calls the homework
;                   test function.
;
; Input:            User presses of the switches and rotations of the rotary
;                   encoders are stored in memory.
; Output:           None.
;
; User Interface:   No real user interface.  The user inputs switch presses
;                   and rotations and appropriate data is written to memory.
; Error Handling:   None.
;
; Algorithms:       None.
; Data Structures:  None.
;
; Known Bugs:       None.
; Limitations:      Only the last 128 switch inputs are stored.
;
; Revision History:
;    5/02/18  Glen George               initial revision
;    4/06/22  Glen George               changed output format to only store an
;                                          extra byte when there is an error
;    4/27/22  Matt Muldowney            downloaded
;    4/28/22  Matt Muldowney            included constituent files
;    4/28/22  Matt Muldowney            call init functions




;set the device
.device ATMEGA64




;get the definitions for the device
.include  "m64def.inc"

;include all the .inc files since all .asm files are needed here (no linker)
.include "timers.inc"
.include "ports.inc"
.include "switches.inc"
.include "sound.inc"
.include "util.inc"



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
        LDI     R16, LOW(TopOfStack)    ;initialize the stack pointer
        OUT     SPL, R16
        LDI     R16, HIGH(TopOfStack)
        OUT     SPH, R16

        rcall   ClearBuff
        
        rcall   InitSwitchPort
        RCALL   InitTimer0
        RCALL   InitSwitchVars
        SEI


        RCALL   SwitchTest              ;do the switch tests
        RJMP    Start                   ;shouldn't return, but if it does, restart




; SwitchTest
;
; Description:       This procedure tests the switch functions.  It loops
;                    calling each status function and when it finds a switch
;                    press or rotation the appropriate character is written to
;                    the key buffer (KeyBuf).  It also verifies that there is
;                    no longer a switch or rotation and if there is, it writes
;                    an 0xEE to the buffer to indicate an error.  Thus for
;                    properly working functions the buffer will contain only
;                    the switch press and rotation characters.  The function
;                    never returns.
;
; Operation:         For each switch its status functions are called.  If
;                    there is a press or rotation an appropriate letter is
;                    written to the buffer (KeyBuf).  Then the status function
;                    is called again and if there is again a press or rotation
;                    (should not be the case) 0xEE is written to the buffer to
;                    indicate an error.  The function then loops and starts
;                    over, performing these tests in an infinite loop.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   R4 - pointer into buffer.
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
; Registers Changed: flags, R4, R5, R16, Y (YH | YL)
; Stack Depth:       unknown (at least 2 bytes)
;
; Author:            Glen George
; Last Modified:     April 6, 2022

SwitchTest:


        CLR     R4              ;start at beginning of buffer

SwitchTestLoop:

CheckLRSwitch:                  ;check LRSwitch function

        PUSH    R4              ;save buffer index around call to LRSwitch
        RCALL   LRSwitch        ;check for left/right switch
        POP     R4
        BRNE    CheckUDSwitch   ;if none, check up/down switch

        LDI     R16, '2'        ;otherwise have a switch press
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling LRSwitch
        RCALL   LRSwitch        ;check for left/right switch again
        POP     R4              ;   (shouldn't be one)
        BRNE    CheckUDSwitch   ;if none, don't write EE, just check next

        LDI     R16, 0xEE       ;otherwise have an erroneous press so write EE
        RCALL   StoreBuff
        ;RJMP   CheckUDSwitch


CheckUDSwitch:                  ;check UDSwitch function

        PUSH    R4              ;save buffer index around call to UDSwitch
        RCALL   UDSwitch        ;check for up/down switch
        POP     R4
        BRNE    CheckRotLeft    ;if none, check left rotation

        LDI     R16, '1'        ;otherwise have a switch press
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling UDSwitch
        RCALL   UDSwitch        ;check for up/down switch again
        POP     R4              ;   (shouldn't be one)
        BRNE    CheckRotLeft    ;if none, don't write EE, just check next

        LDI     R16, 0xEE       ;otherwise spurious switch press so write EE
        RCALL   StoreBuff
        ;RJMP   CheckRotLeft


CheckRotLeft:                   ;check LeftRot function

        PUSH    R4              ;save buffer index around call to LeftRot
        RCALL   LeftRot         ;check for left rotation
        POP     R4
        BRNE    CheckRotRight   ;if none, check right rotation

        LDI     R16, 'L'        ;otherwise have a left rotation
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling LeftRot
        RCALL   LeftRot         ;check for left rotation again
        POP     R4              ;   (shouldn't be one)
        BRNE    CheckRotRight   ;if none, no error, just check next

        LDI     R16, 0xEE       ;otherwise erroneous rotation so write EE
        RCALL   StoreBuff
        ;RJMP   CheckRotRight


CheckRotRight:                  ;check RightRot function

        PUSH    R4              ;save buffer index around call to RightRot
        RCALL   RightRot        ;check for right rotation
        POP     R4
        BRNE    CheckRotUp      ;if none, check up rotation

        LDI     R16, 'R'        ;otherwise have a right rotation
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling RightRot
        RCALL   RightRot        ;check for right rotation again
        POP     R4              ;   (shouldn't be one)
        BRNE    CheckRotUp      ;if none, no error so just check next

        LDI     R16, 0xEE       ;otherwise have spurious rotation so write EE
        RCALL   StoreBuff
        ;RJMP   CheckRotUp


CheckRotUp:                     ;check UpRot function

        PUSH    R4              ;save buffer index around call to UpRot
        RCALL   UpRot           ;check for up rotation
        POP     R4
        BRNE    CheckRotDown    ;if none, check down rotation

        LDI     R16, 'U'        ;otherwise have an up rotation
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling UpRot
        RCALL   UpRot           ;check for up rotation again
        POP     R4              ;   (shouldn't be one)
        BRNE    CheckRotDown    ;if don't have one, no error so check next

        LDI     R16, 0xEE       ;otherwise error in function so write EE
        RCALL   StoreBuff
        ;RJMP   CheckRotDown


CheckRotDown:                   ;check DownRot function

        PUSH    R4              ;save buffer index around call to DownRot
        RCALL   DownRot         ;check for down rotation
        POP     R4
        BRNE    DoneCheckSw     ;if none, done checking switches

        LDI     R16, 'D'        ;otherwise have a down rotation
        RCALL   StoreBuff       ;store it in the buffer

        PUSH    R4              ;save index while calling DownRot
        RCALL   DownRot         ;check for down rotation again
        POP     R4              ;   (shouldn't be one)
        BRNE    DoneCheckSw     ;if none, don't write EE, and done

        LDI     R16, 0xEE       ;otherwise function error so write EE
        RCALL   StoreBuff
        ;RJMP   DoneCheckSw


DoneCheckSw:                    ;done checking switch functions
        JMP     SwitchTestLoop  ;keep looping forever


        RET                     ;should never get here




; StoreBuff
;
; Description:       This procedure stores the byte passed in R16 at the
;                    offset in the KeyBuf buffer passed in R4.  The offset is
;                    updated and the new offset is returned in R4.
;
; Operation:         The Y register is loaded with the buffer address.  The
;                    passed offset is then added to this address and the
;                    passed byte is stored at this location.  The passed
;                    offset is then incremented and returned.
;
; Arguments:         R4  - offset in KeyBuf at which to write the passed byte.
;                    R16 - byte to write to the buffer at the passed offset.
; Return Value:      R4  - offset of the next location in the buffer.
;
; Local Variables:   Y - pointer into buffer.
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
; Registers Changed: flags, R4, R16, R17, Y (YH | YL)
; Stack Depth:       0 bytes
;
; Author:            Glen George
; Last Modified:     May 1, 2018

StoreBuff:

        LDI     YL, LOW(KeyBuf) ;get buffer location to store switch at
        LDI     YH, HIGH(KeyBuf)

        LDI     R17, 0          ;for carry propagation
        ADD     YL, R4          ;add the passed offset
        ADC     YH, R17

        STD     Y + 0, R16      ;store the passed byte in the buffer

        INC     R4              ;update the buffer offset, wrapping at 256


        RET                     ;all done, return


ClearBuff:
    push r16
    push r17
    push yl
    push yh

    ldi     yl, low(KeyBuf)
    ldi     yh, high(KeyBuf)
    ldi     r16, 255
    ldi     r17, 0

ClearBuffLoop:
    st  y+, r17
    dec r16
    brne ClearBuffLoop

    pop yh
    pop yl
    pop r17
    pop r16
    ret

;the data segment


.dseg


; buffer in which to store keys (length must be 256)
KeyBuf:         .BYTE   256


; the stack - 128 bytes
                .BYTE   127
TopOfStack:     .BYTE   1               ;top of the stack




; since don't have a linker, include all the .asm files

.include "switches.asm"
.include "timers.asm"
.include "ports.asm"

