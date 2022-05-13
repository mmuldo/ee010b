;;;;;;;;;;;;;;;;
; switches.asm ;
;;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for switches and rotary encoders including:
;   * SwitchEventHandler: Timer0 interrupt event handler
;   * InitSwitchVars: intialization for shared vars in this file
;   * DebounceLR: debounces L/R switch
;   * DebounceUD: debounces U/D switch
;   * DeRotLR: checks for a detent-to-detent movement on L/R rotary encoder
;   * DeRotUD: checks for a detent-to-detent movement on U/D rotary encoder
;   * LRSwitch: indicates when the L/R switch has been pressed
;   * UDSwitch: indicates when the L/R switch has been pressed
;   * LeftRot: indicates when the L/R rotary encoder has turned left (ccw)
;   * RightRot: indicates when the L/R rotary encoder has turned right (cw)
;   * UpRot: indicates when the U/D rotary encoder has turned up (ccw)
;   * DownRot: indicates when the U/D rotary encoder has turned down (cw)
;
; Inputs
; ------
; L/R switch: PortE[5]
; U/D switch: PortE[2]
; L/R rotary encoder: PortE[7,6]
; U/D rotary encoder: PortE[4,3]
;
; Outputs
; -------
; None
;
; User Interface
; --------------
; None
;
; Error Handling
; --------------
; None
;
; Known Bugs
; ----------
; None
;
; Limitations
; -----------
; None
;
; Revision History
; ----------------
; 04/28/2022    Matt Muldowney      initial revision
; 04/28/2022    Matt Muldowney      fixed syntax errors
; 04/28/2022    Matt Muldowney      got rid of macros bc they don't work :(
; 04/28/2022    Matt Muldowney      changed registers in certain functions to
;                                       avoid register collisions
; 04/28/2022    Matt Muldowney      push and pop SREG in SwitchEventHandler
; 04/28/2022    Matt Muldowney      docs

.DSEG
    LRSwitchPressed:    .BYTE 1 ; bool indicating LR switch has been pressed
    LRSwitchCounter:    .BYTE 1 ; counter for debouncing LR switch
    UDSwitchPressed:    .BYTE 1 ; bool indicating UD switch has been pressed 
    UDSwitchCounter:    .BYTE 1 ; counter for debouncing UD switch

    LRRotLeft:          .BYTE 1 ; bool indicating LR has been rotated left
    LRRotRight:         .BYTE 1 ; bool indicating LR has been rotated right

    LRGrayCodeStack:    .BYTE 1 ; keeps tack of 4 most recently seen gray 
                                ;   codes for L\R rotary encoder. 
                                ;   e.g. a value of 0b11100001 means 
                                ;   that the most recently seen codes were
                                ;   01, 00, 10, and 11 in that order

    UDRotUp:            .BYTE 1 ; bool indicating UD has been rotated up
    UDRotDown:          .BYTE 1 ; bool indicating UD has been rotated down

    UDGrayCodeStack:    .BYTE 1 ; keeps tack of 4 most recently seen gray 
                                ;   codes for L\R rotary encoder. 
                                ;   e.g. a value of 0b11100001 means 
                                ;   that the most recently seen codes were
                                ;   01, 00, 10, and 11 in that order

.CSEG

; InitSwitchVars Specification
; ========================
; 
; Description
; -----------
; `InitSwitchVars()` initializes the shared variables used by the event
; handler.
; 
; Operational Description
; -----------------------
; All event handling flags are reset to 0 and the interrupt flag is set to 1
; (to enable interrupts).
; 
; Arguments
; ---------
; None
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
; LRSwitchPressed (bool): W
; UDSwitchPressed (bool): W
; LRRotLeft (bool): W
; LRRotRight (bool): W
; LRGrayCodeStack (8-bit string): W
; UDRotUp (bool): W
; UDRotDown (bool): W
; UDGrayCodeStack (8-bit string): W
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
InitSwitchVars:
    PUSH    R16
    PUSH    R17
    PUSH    R18

    LDI     R16, FALSE                  ; initial value for shared booleans
    STS     LRSwitchPressed, R16
    STS     UDSwitchPressed, R16
    STS     LRRotLeft, R16
    STS     LRRotRight, R16
    STS     UDRotUp, R16
    STS     UDRotDown, R16


    LDI     R17, SWITCH_COUNTER_INIT    ; switch press counter value to count 
                                            ; down from (in ms)
    STS     LRSwitchCounter, R17
    STS     UDSwitchCounter, R17


    LDI     R18, GRAYCODE_STACK_INIT    ; initial graycode stack
    STS     LRGrayCodeStack, R18
    STS     UDGrayCodeStack, R18

    POP     R18
    POP     R17
    POP     R16
    RET


; SwitchEventHandler Specification
; ================================
; 
; Description
; -----------
; Handles the following events:
; 
; * switch presses (specifically, debouncing switch presses)
; * rotary encoder rotations (specifically, debouncing rotations)
; 
; Operational Description
; -----------------------
; This function simply loops calls the following debouncing functions once
; ever 1 ms (every time Timer0 generates an interrupt):
;   DebounceLR()
;   DebounceUD()
;   DeRotLR()
;   DeRotUD()
;
; Arguments
; ---------
; None
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
SwitchEventHandler:
    RCALL   DebounceLR
    RCALL   DebounceUD
    RCALL   DeRotLR
    RCALL   DeRotUD

    ret



; DebounceLR Specificaiton
; ========================
; 
; Description
; -----------
; `DebounceLR()` is responsible for distinguishing a press from random
; fluctuations on the L/R switch.
; 
; Operational Description
; -----------------------
; Holding down the L/R switch for 20 ms (20 timer cycles consecutively)
; registers as a press. In more detail, the L/R switch pin being high for
; 20 ms will result in the `LRSwitchPressed` flag being set.
; 
; Arguments
; ---------
; None
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
; LRSwitchPressed (bool): RW
; LRSwitchCounter (int): RW
; 
; Local Variables
; ---------------
; None
; 
; Inputs
; ------
; PortE[5]
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
; 2 bytes
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
DebounceLR:
    PUSH    R16 ; used for PinE reading and LRSwitchCounter RW
    PUSH    R17 ; used for LRSwitchPressed writing

    ; get L/R switch press status from PortE
    IN      R16, PinE
    ANDI    R16, PORTE_LRSWITCH_MSK

    ; check if LR is not pressed (1 --> not pressed; 0 --> pressed)
    CPI     R16, PORTE_LRSWITCH_MSK
    BREQ    LR_NOT_PRESSED

    ; if presesd, check if LR counter is still at 0
    ; if it is, nothing more to do, so just return
    LDS     R16, LRSwitchCounter
    CPI     R16, 0
    BREQ    DebounceLR_RET

    ; check if LR counter is at 1
    ; if it is, register a switch press, since next decrement will put
    ;   counter at 0.
    ; if not, need to keep decrementing
    CPI     R16, 1
    BRNE    LR_COUNT_NOT_0_OR_1
    LDI     R17, TRUE
    STS     LRSwitchPressed, R17

LR_COUNT_NOT_0_OR_1:
    ; if LR is pressed but >= 1, decrement and return
    DEC     R16
    STS     LRSwitchCounter, R16
    JMP     DebounceLR_RET

LR_NOT_PRESSED:
    ; if LR not pressed, re-init LR switch counter
    LDI     R16, SWITCH_COUNTER_INIT
    STS     LRSwitchCounter, R16
        
DebounceLR_RET:
    POP     R17
    POP     R16
    RET





; DebounceUD Specificaiton
; ========================
; 
; Description
; -----------
; `DebounceUD()` is responsible for distinguishing a press from random
; fluctuations on the U/D switch.
; 
; Operational Description
; -----------------------
; Holding down the U/D switch for 20 ms (20 timer cycles consecutively)
; registers as a press. In more detail, the U/D switch pin being high for
; 20 ms will result in the `UDSwitchPressed` flag being set.
; 
; Arguments
; ---------
; None
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
; UDSwitchPressed (bool): RW
; UDSwitchCounter (int): RW
; 
; Local Variables
; ---------------
; None
; 
; Inputs
; ------
; PortE[2]
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
DebounceUD:
    PUSH    R16 ; used for PinE reading and UDSwitchCounter RW
    PUSH    R17 ; used for UDSwitchPressed writing

    ; get U/D switch press status from PortE
    IN      R16, PinE
    ANDI    R16, PORTE_UDSWITCH_MSK

    ; check if LR is not pressed (1 --> not pressed; 0 --> pressed)
    CPI     R16, PORTE_UDSWITCH_MSK
    BREQ    UD_NOT_PRESSED

    ; if presesd, check if LR counter is still at 0
    ; if it is, nothing more to do, so just return
    LDS     R16, UDSwitchCounter
    CPI     R16, 0
    BREQ    DebounceUD_RET

    ; check if UD counter is at 1
    ; if it is, register a switch press, since next decrement will put
    ;   counter at 0.
    ; if not, need to keep decrementing
    CPI     R16, 1
    BRNE    UD_COUNT_NOT_0_OR_1
    LDI     R17, TRUE
    STS     UDSwitchPressed, R17

UD_COUNT_NOT_0_OR_1:
    ; if UD is pressed but >= 1, decrement and return
    DEC     R16
    STS     UDSwitchCounter, R16
    JMP     DebounceUD_RET

UD_NOT_PRESSED:
    ; if UD not pressed, re-init LR switch counter
    LDI     R16, SWITCH_COUNTER_INIT
    STS     UDSwitchCounter, R16
        
DebounceUD_RET:
    POP     R17
    POP     R16
    RET






; DeRotLR Specification
; =======================
; 
; Description
; -----------
; `DeRotLR()` is responsible for distinguishing between a turn from
; one detent to the adjacent detent on the L/R rotary encoder and random
; jiggling in between detents.
; 
; Operational Description
; -----------------------
; Input rotations on the L/R rotary encoder are represented by the following
; four ordered graycodes:
; 
; * `11`: detent 1
; * `01`: just left of detent 1
; * `00`: middle between detent 1 and detent 2
; * `10`: just right of detent 2
; * next `11`: detent 2
; 
; A left rotation should be registered if and only if the following sequence
; of graycode inputs is seen on the L/R rotary encoder:

; 11 -> [sequence of inputs] 
;   -> 11 -> 10 -> [sequence of inputs] 
;   -> 10 -> 00 -> [sequence of inputs] 
;   -> 00 -> 01 -> [sequence of inputs] 
;   -> 01 -> 11
;
; In other words, we need to see a complete rotation of graycode inputs in
; order `11 -> 10 -> 00 -> 01 -> 11`,
; but it is possible that other inputs could interject this rotation based on
; oscillations of the L/R rotary encoder as it moves from one detent to
; another.
; After observing a complete left rotation, the `LRRotLeft` flag is set.
;
; A right rotation should be registered if and only if the following sequence
; of graycode inputs is seen on the L/R rotary encoder:
;
; 11 -> [sequence of inputs] 
;   -> 11 -> 01 -> [sequence of inputs] 
;   -> 01 -> 00 -> [sequence of inputs] 
;   -> 00 -> 10 -> [sequence of inputs] 
;   -> 10 -> 11
;
; In other words, we need to see a complete rotation of graycode inputs in
; order `11 -> 01 -> 00 -> 10 -> 11`,
; but it is possible that other inputs could interject this rotation based on
; oscillations of the L/R rotary encoder as it moves from one detent to
; another.
; After observing a complete right rotation, the `LRRotRight` flag is set.
; 
; Arguments
; ---------
; None
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
; LRRotLeft (bool): W
; LRRotRight (bool): W
; LRGrayCodeStack (8-bit string): RW
; 
; Local Variables
; ---------------
; LRRotGrayCode (8-bit string): RW
;   current LR rotary encoder gray code
; 
; Inputs
; ------
; PortE[7,6]
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
; Stack in the form of a bit string, where things get "stacked" by logically
; shifting left and "popped" by logically shifting right, 2 bits at a time.
; 
; Limitations
; -----------
; Turning the L/R rotary encoder too fast could cause jumping between
; non-adjacent graycodes, which isn't handled by the function.
; However, all that will happen is that the left rotation doesn't get
; registered, i.e. this won't cause the algorithm to break.
; 
; Known Bugs
; ----------
; None
; 
; Special Notes
; -------------
; None
DeRotLR:
    PUSH    R17     ; LRRotGrayCode (current graycode)
    PUSH    R18     ; for writing to LRRotLeft/Right
    PUSH    R19     ; LR rotary encoder gray code stack
    PUSH    R20     ; isolated bits of LR rotary encoder gray code stack

    ; read in LR rotary encoder graycode
    IN      R17, PinE
    ANDI    R17, PORTE_LRROT_MSK

    ; shift the graycode reading down so that it's sitting in the bottom
    ;   2 bits
    LDI     R16, PORTE_LRROT_SHIFT
    LRROT_LSR:
        CPI     R16, 0
        BREQ    LRROT_LSR_DONE
        LSR     R17
        Dec     R16
        JMP     LRROT_LSR
    LRROT_LSR_DONE:

    ; get graycode stack
    LDS     R19, LRGrayCodeStack    

    ; check if on detent
    ; if we're not, can't have done a full turn yet, so go to stack update
    ;   section.
    CPI     R17, 0b00000011
    BRNE    LR_STACK_UPDATE

    ; if on detent, check if graycode stack is ccw full
    CPI     R19, GRAYCODE_CCW_FULL
    BRNE    LR_CHECK_CW_FULL                       

    ; if ccw full, register left rotation and re-init graycode stack
    ; then return
    LDI     R18, TRUE
    STS     LRRotLeft, R18
    LDI     R19, GRAYCODE_STACK_INIT
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_CHECK_CW_FULL:
    ; if on detent and not ccw full, check if graycode stack is cw full
    CPI     R19, GRAYCODE_CW_FULL
    BRNE    LR_STACK_UPDATE

    ; if cw full, register right rotation and reinit graycode stack
    ; then return
    LDI     R18, TRUE
    STS     LRRotRight, R18
    LDI     R19, GRAYCODE_STACK_INIT
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_STACK_UPDATE:
    ; get 2nd most recent seen gray code
    MOV     R20, R19
    ANDI    R20, 0b00001100
    ; shift down so that it's sitting in the bottom 2 bits
    LSR     R20
    LSR     R20

    ; check if current gray code is equal to the 2nd to last gray code
    CP      R20, R17
    BRNE    LR_CHECK_STACK_PREV

    ; if it is, pop the previous gray code off stack
    LSR     R19
    LSR     R19
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_CHECK_STACK_PREV:
    ; get previously seen gray code
    MOV     R20, R19
    ANDI    R20, 0b00000011

    ; check if current gray code is equal to previous graycode
    CP      R20, R17
    BREQ    DeRotLR_RET

    ; if the current gray code isn't the previous graycode, push the current
    ;   gray code onto the stack
    LSL     R19
    LSL     R19
    ADD     R19, R17
    STS     LRGrayCodeStack, R19
    
DeRotLR_RET:
    POP     R20
    POP     R19
    POP     R18
    POP     R17
    RET






; DeRotUD Specification
; =======================
; 
; Description
; -----------
; `DeRotUD()` is responsible for distinguishing between a turn from
; one detent to the adjacent detent on the U/D rotary encoder and random
; jiggling in between detents.
; 
; Operational Description
; -----------------------
; Input rotations on the U/D rotary encoder are represented by the following
; four ordered graycodes:
; 
; * `11`: detent 1
; * `01`: just up of detent 1
; * `00`: middle between detent 1 and detent 2
; * `10`: just down of detent 2
; * next `11`: detent 2
; 
; A up rotation should be registered if and only if the following sequence
; of graycode inputs is seen on the U/D rotary encoder:

; 11 -> [sequence of inputs] 
;   -> 11 -> 10 -> [sequence of inputs] 
;   -> 10 -> 00 -> [sequence of inputs] 
;   -> 00 -> 01 -> [sequence of inputs] 
;   -> 01 -> 11
;
; In other words, we need to see a complete rotation of graycode inputs in
; order `11 -> 10 -> 00 -> 01 -> 11`,
; but it is possible that other inputs could interject this rotation based on
; oscillations of the U/D rotary encoder as it moves from one detent to
; another.
; After observing a complete up rotation, the `UDRotup` flag is set.
;
; A down rotation should be registered if and only if the following sequence
; of graycode inputs is seen on the U/D rotary encoder:
;
; 11 -> [sequence of inputs] 
;   -> 11 -> 01 -> [sequence of inputs] 
;   -> 01 -> 00 -> [sequence of inputs] 
;   -> 00 -> 10 -> [sequence of inputs] 
;   -> 10 -> 11
;
; In other words, we need to see a complete rotation of graycode inputs in
; order `11 -> 01 -> 00 -> 10 -> 11`,
; but it is possible that other inputs could interject this rotation based on
; oscillations of the U/D rotary encoder as it moves from one detent to
; another.
; After observing a complete down rotation, the `UDRotdown` flag is set.
; 
; Arguments
; ---------
; None
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
; UDRotup (bool): W
; UDRotdown (bool): W
; UDGrayCodeStack (8-bit string): RW
; 
; Local Variables
; ---------------
; UDRotGrayCode (8-bit string): RW
;   current UD rotary encoder gray code
; 
; Inputs
; ------
; PortE[7,6]
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
; Stack in the form of a bit string, where things get "stacked" by logically
; shifting up and "popped" by logically shifting down, 2 bits at a time.
; 
; Registers Used
; --------------
; None
;
; Stack Depth
; -----------
; 4 bytes
;
; Limitations
; -----------
; Turning the U/D rotary encoder too fast could cause jumping between
; non-adjacent graycodes, which isn't handled by the function.
; However, all that will happen is that the up rotation doesn't get
; registered, i.e. this won't cause the algorithm to break.
; 
; Known Bugs
; ----------
; None
; 
; Special Notes
; -------------
; None
DeRotUD:
    PUSH    R17     ; UDRotGrayCode (current graycode)
    PUSH    R18     ; for writing to UDRotUp/Down
    PUSH    R19     ; UD rotary encoder gray code stack
    PUSH    R20     ; isolated bits of UD rotary encoder gray code stack

    ; read in UD rotary encoder graycode
    IN      R17, PinE
    ANDI    R17, PORTE_UDROT_MSK

    ; shift the graycode reading down so that it's sitting in the bottom
    ;   2 bits
    LDI     R16, PORTE_UDROT_SHIFT
    UDROT_LSR:
        CPI     R16, 0
        BREQ    UDROT_LSR_DONE
        LSR     R17
        Dec     R16
        JMP     UDROT_LSR
    UDROT_LSR_DONE:

    ; get graycode stack
    LDS     R19, UDGrayCodeStack    

    ; check if on detent
    ; if we're not, can't have done a full turn yet, so go to stack update
    ;   section.
    CPI     R17, 0b00000011
    BRNE    UD_STACK_UPDATE

    ; if on detent, check if graycode stack is ccw full
    CPI     R19, GRAYCODE_CCW_FULL
    BRNE    UD_CHECK_CW_FULL                       

    ; if ccw full, register left rotation and re-init graycode stack
    ; then return
    LDI     R18, TRUE
    STS     UDRotUp, R18
    LDI     R19, GRAYCODE_STACK_INIT
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_CHECK_CW_FULL:
    ; if on detent and not ccw full, check if graycode stack is cw full
    CPI     R19, GRAYCODE_CW_FULL
    BRNE    UD_STACK_UPDATE

    ; if cw full, register right rotation and reinit graycode stack
    ; then return
    LDI     R18, TRUE
    STS     UDRotDown, R18
    LDI     R19, GRAYCODE_STACK_INIT
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_STACK_UPDATE:
    ; get 2nd most recent seen gray code
    MOV     R20, R19
    ANDI    R20, 0b00001100
    ; shift down so that it's sitting in the bottom 2 bits
    LSR     R20
    LSR     R20

    ; check if current gray code is equal to the 2nd to last gray code
    CP      R20, R17
    BRNE    UD_CHECK_STACK_PREV

    ; if it is, pop the previous gray code off stack
    ; then return
    LSR     R19
    LSR     R19
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_CHECK_STACK_PREV:
    ; get previously seen gray code
    MOV     R20, R19
    ANDI    R20, 0b00000011

    ; check if current gray code is equal to previous graycode
    CP      R20, R17
    BREQ    DeRotUD_RET

    ; if the current gray code isn't the previous graycode, push the current
    ;   gray code onto the stack
    LSL     R19
    LSL     R19
    ADD     R19, R17
    STS     UDGrayCodeStack, R19
    
DeRotUD_RET:
    POP     R20
    POP     R19
    POP     R18
    POP     R17
    RET

; LRSwitch specification
; =====================
; 
; Description
; -----------
; indicates if a LR switch has been pressed
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the has been pressed since 
; the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets LRSwitchPressed.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If LRSwitchPressed is high, return `TRUE` (zero flag set);
; if LRSwitchPressed is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; LRSwitchPressed (bool): RW
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
LRSwitch:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRSwitchPressed
    PUSH    R22 ; W LRSwitchPressed
    
    ; freeze status flags and stop interrupts
    IN      R0, SREG
    CLI
    
    ; critical code
    ; save LRSwitchPressed to register and reset it
    LDS     R21, LRSwitchPressed
    LDI     R22, FALSE
    STS     LRSwitchPressed, R22
    ; end critical code
    
    ; unfreeze status flags
    OUT     SREG, R0
    
    ; check if LRSwitchPressed is set
    CPI     R21, TRUE
    BRNE    LRSWITCHPRESSED_NOT_SET

    ; if set, return true
    SEZ
    JMP     LRSwitch_RET
    
LRSWITCHPRESSED_NOT_SET:
    ; if reset, return false
    CLZ

LRSwitch_RET:
    POP     R22
    POP     R21
    POP     R0
    RET






; UDSwitch specification
; =====================
; 
; Description
; -----------
; indicates if a UD switch has been pressed
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the has been pressed since 
; the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets UDSwitchPressed.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If UDSwitchPressed is high, return `TRUE` (zero flag set);
; if UDSwitchPressed is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; UDSwitchPressed (bool): RW
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
UDSwitch:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDSwitchPressed
    PUSH    R22 ; W UDSwitchPressed
    
    ; freeze status flags and stop interrupts
    IN      R0, SREG
    CLI
    
    ; critical code
    ; save UDSwitchPressed to register and reset it
    LDS     R21, UDSwitchPressed
    LDI     R22, FALSE
    STS     UDSwitchPressed, R22
    ; end critical code
    
    ; unfreeze status flags
    OUT     SREG, R0

    ; check if UDSwitchPressed is set
    CPI     R21, TRUE
    BRNE    UDSWITCHPRESSED_NOT_SET

    ; if set, return true
    SEZ
    JMP     UDSwitch_RET
UDSWITCHPRESSED_NOT_SET:
    ; if reset, return false
    CLZ

UDSwitch_RET:
    POP     R22
    POP     R21
    POP     R0
    RET





; LeftRot specification
; =====================
; 
; Description
; -----------
; indicates if the LR rotary encoder has been turned left
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the LR rotary encoder has 
; been turned since the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets LRRotLeft.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If LRRotLeft is high, return `TRUE` (zero flag set);
; if LRRotLeft is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; LRRotLeft (bool): RW
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
LeftRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRRotLeft
    PUSH    R22 ; W LRRotLeft
    
    ; freeze status flags and stop interrupts
    IN      R0, SREG
    CLI
    
    ; critical code
    ; save LRRotLeft to register and reset it
    LDS     R21, LRRotLeft
    LDI     R22, FALSE
    STS     LRRotLeft, R22
    ; end critical code

    ; unfreeze status flags
    OUT     SREG, R0
    
    ; check if LRRotLeft is set
    CPI     R21, TRUE
    BRNE    LRROTLEFT_NOT_SET

    ; if set, return true
    SEZ
    JMP     LeftRot_RET
LRROTLEFT_NOT_SET:
    ; if reset, return false
    CLZ
LeftRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET




; RightRot specification
; =====================
; 
; Description
; -----------
; indicates if the LR rotary encoder has been turned right
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the LR rotary encoder has 
; been turned since the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets LRRotRight.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If LRRotRight is high, return `TRUE` (zero flag set);
; if LRRotRight is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; LRRotRight (bool): RW
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
RightRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRRotRight
    PUSH    R22 ; W LRRotRight
    
    ; freeze status flags and stop interrupts
    IN      R0, SREG
    CLI
    
    ; critical code
    ; save LRRightRot to register and reset it
    LDS     R21, LRRotRight
    LDI     R22, FALSE
    STS     LRRotRight, R22
    ; end critical code
    
    ; unfreeze status flags
    OUT     SREG, R0
    
    ; check if LRRotRight is set
    CPI     R21, TRUE
    BRNE    LRROTRIGHT_NOT_SET

    ; if set, return true
    SEZ
    JMP     RightRot_RET
LRROTRIGHT_NOT_SET:
    ; if reset, return false
    CLZ

RightRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET




; UpRot specification
; =====================
; 
; Description
; -----------
; indicates if the UD rotary encoder has been turned up
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the UD rotary encoder has 
; been turned since the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets UDRotUp.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If UDRotUp is high, return `TRUE` (zero flag set);
; if UDRotUp is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; UDRotUp (bool): RW
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
UpRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDRotUp
    PUSH    R22 ; W UDRotUp

    IN      R0, SREG
    CLI
    
    ; critical code
    ; save UDRotUp to register and reset it
    LDS     R21, UDRotUp
    LDI     R22, FALSE
    STS     UDRotUp, R22
    ; end critical code
    
    ; unfreeze status flags
    OUT     SREG, R0
    
    ; check if UDRotUp is set
    CPI     R21, TRUE
    BRNE    UDROTUP_NOT_SET

    ; if set, return true
    SEZ
    JMP     UpRot_RET
UDROTUP_NOT_SET:
    ; if reset, return false
    CLZ

UpRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET




; DownRot specification
; =====================
; 
; Description
; -----------
; indicates if the UD rotary encoder has been turned down
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the UD rotary encoder has 
; been turned since the last time this was called;
; otherwise, returns `FALSE` (i.e. resets the zero flag).
; Resets UDRotDown.
; 
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; If UDRotDown is high, return `TRUE` (zero flag set);
; if UDRotDown is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; UDRotDown (bool): RW
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
DownRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDRotDown
    PUSH    R22 ; W UDRotDown
    
    ; freeze status flags and stop interrupts
    IN      R0, SREG
    CLI
    
    ; critical code
    ; save UDRotDown to register and reset it
    LDS     R21, UDRotDown
    LDI     R22, FALSE
    STS     UDRotDown, R22
    ; end critical code
    
    ; unfreeze status flags
    OUT     SREG, R0
    
    ; check if UDRotDown is set
    CPI     R21, TRUE
    BRNE    UDROTDOWN_NOT_SET

    ; if set, return true
    SEZ
    JMP     DownRot_RET
UDROTDOWN_NOT_SET:
    ; if reset, return false
    CLZ

DownRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET
