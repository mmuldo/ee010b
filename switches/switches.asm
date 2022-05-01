.DSEG
    LRSwitchPressed:    .BYTE 1 ; bool indicating LR switch has been pressed
    LRSwitchCounter:    .BYTE 1 ; counter for debouncing LR switch
    UDSwitchPressed:    .BYTE 1 ; bool indicating UD switch has been pressed 
    UDSwitchCounter:    .BYTE 1 ; counter for debouncing UD switch

    LRRotLeft:          .BYTE 1 ; bool indicating LR has been rotated left
    LRRotRight:         .BYTE 1 ; bool indicating LR has been rotated right

    ;   This keeps track of the most recently seen gray codes
    ;   An example sequence of runs looks like:
    ;   
    ;   | graycode      | LRGrayCodeStack   |
    ;   | ------------- | ----------------- |
    ;   |               | 00 00 00 11       |
    ;   |11             | 00 00 00 11       |
    ;   |10             | 00 00 11 10       |
    ;   |11             | 00 00 00 11       |
    ;   |10             | 00 00 11 10       |
    ;   |00             | 00 11 10 00       |
    ;   |00             | 00 11 10 00       |
    ;   |00             | 00 11 10 00       |
    ;   |01             | 11 10 00 01       |
    ;   |00             | 00 11 10 00       |
    ;   |01             | 11 10 00 01       |
    ;   |11             | 00 00 00 00       |
    LRGrayCodeStack:    .BYTE 1

    UDRotUp:            .BYTE 1 ; bool indicating UD has been rotated up
    UDRotDown:          .BYTE 1 ; bool indicating UD has been rotated down

    ;   This keeps track of the most recently seen UD rotary encoder gray codes
    ;   An example sequence of runs looks like:
    ;   
    ;   | graycode      | UDGrayCodeStack   |
    ;   | ------------- | ----------------- |
    ;   |               | 00 00 00 11       |
    ;   |11             | 00 00 00 11       |
    ;   |10             | 00 00 11 10       |
    ;   |11             | 00 00 00 11       |
    ;   |10             | 00 00 11 10       |
    ;   |00             | 00 11 10 00       |
    ;   |00             | 00 11 10 00       |
    ;   |00             | 00 11 10 00       |
    ;   |01             | 11 10 00 01       |
    ;   |00             | 00 11 10 00       |
    ;   |01             | 11 10 00 01       |
    ;   |11             | 00 00 00 00       |
    UDGrayCodeStack:    .BYTE 1

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
InitSwitchVars:
    PUSH    R16
    PUSH    R17
    PUSH    R18

    LDI     R16, FALSE  ; initial value for shared booleans
    LDI     R17, SWITCH_COUNTER_INIT    ; switch press counter value to count 
                                            ; down from (in ms)
    LDI     R18, GRAYCODE_STACK_INIT    ; initial graycode stack

    STS     LRSwitchPressed, R16
    STS     LRSwitchCounter, R17

    STS     UDSwitchPressed, R16
    STS     UDSwitchCounter, R17

    STS     LRRotLeft, R16
    STS     LRRotRight, R16
    STS     LRGrayCodeStack, R18

    STS     UDRotUp, R16
    STS     UDRotDown, R16
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
;
; Pseudocode
; ----------
; DebounceLR()
; DebounceUD()
; DeRotLR()
; DeRotUD()
SwitchEventHandler:
    RCALL   DebounceLR
    RCALL   DebounceUD
    RCALL   DeRotLR
    RCALL   DeRotUD
    RETI

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

    IN      R16, PinE
    ANDI    R16, PORTE_LRSWITCH_MSK

    CPI     R16, PORTE_LRSWITCH_MSK ; check if LR is not pressed (== 1)
    BREQ    LR_NOT_PRESSED

    LDS     R16, LRSwitchCounter
    CPI     R16, 0                  ; check if LR switch counter is still at 0
    BREQ    DebounceLR_RET          ; if so, then nothing to do

    CPI     R16, 1                  ; check if LR switch counter is at 1
    BRNE    LR_COUNT_NOT_0_OR_1     ; if not, need to keep decrementing
    LDI     R17, TRUE               ; if it is, register a switch press since
                                        ; the next decrement will put it at 0
    STS     LRSwitchPressed, R17

LR_COUNT_NOT_0_OR_1:
    DEC     R16                     ; NOTE: this gets run as long as LR switch
                                        ; counter is not already at 0
    STS     LRSwitchCounter, R16
    JMP     DebounceLR_RET

LR_NOT_PRESSED:
    LDI     R16, SWITCH_COUNTER_INIT ; re-init LR switch counter
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
;
; Pseudocode
; ----------
; IF PortE[5] == 1:
;   IF UDSwitchCounter == 0:
;       UDSwitchCounter = 0
;   ELSE IF UDSwitchCounter == 1:
;       UDSwitchPressed = 1
;       UDSwitchCounter--
;   ELSE:
;       UDSwitchCounter--
;   ENDIF
; ELSE:
;   UDSwitchCounter = 20
; ENDIF
DebounceUD:
    PUSH    R16 ; used for PinE reading and UDSwitchCounter RW
    PUSH    R17 ; used for UDSwitchPressed writing

    IN      R16, PinE
    ANDI    R16, PORTE_UDSWITCH_MSK

    CPI     R16, PORTE_UDSWITCH_MSK ; check if UD is not pressed (== 1)
    BREQ    UD_NOT_PRESSED

    LDS     R16, UDSwitchCounter
    CPI     R16, 0                  ; check if UD switch counter is still at 0
    BREQ    DebounceUD_RET          ; if so, then nothing to do

    CPI     R16, 1                  ; check if UD switch counter is at 1
    BRNE    UD_COUNT_NOT_0_OR_1     ; if not, need to keep decrementing
    LDI     R17, TRUE               ; if it is, register a switch press since
                                        ; the next decrement will put it at 0
    STS     UDSwitchPressed, R17

UD_COUNT_NOT_0_OR_1:
    DEC     R16                     ; NOTE: this gets run as long as UD switch
                                        ; counter is not already at 0
    STS     UDSwitchCounter, R16
    JMP     DebounceUD_RET

UD_NOT_PRESSED:
    LDI     R16, SWITCH_COUNTER_INIT ; re-init UD switch counter
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

    ; if macro ever gets working, uncomment this
    ;LSRK    R17, PORTE_LRROT_SHIFT
    LDI     R16, PORTE_LRROT_SHIFT
    LRROT_LSR:
        CPI     R16, 0      ; check if K is 0
        BREQ    LRROT_LSR_DONE  ; if so, we're done
    
        LSR     R17
        Dec     R16
        JMP     LRROT_LSR
    LRROT_LSR_DONE:

    CPI     R17, 0b00000011     ; check if on detent
    BRNE    LR_STACK_UPDATE

    LDS     R19, LRGrayCodeStack    
                                    

    CPI     R19, GRAYCODE_CCW_FULL ; if on detent, check if 
                                                    ; graycode stack 
                                                    ; is ccw full
    BRNE    LR_CHECK_CW_FULL                       
    LDI     R18, TRUE               ; if ccw full, register left rot
    STS     LRRotLeft, R18
    LDI     R19, GRAYCODE_STACK_INIT ; reinit graycode stack
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_CHECK_CW_FULL:
    CPI     R19, GRAYCODE_CW_FULL ; if on detent, and 
                                                    ; not ccw full, check if 
                                                    ; graycode stack 
                                                    ; is cw full
    BRNE    LR_STACK_UPDATE
    LDI     R18, TRUE               ; if cw full, register right rot
    STS     LRRotRight, R18
    LDI     R19, GRAYCODE_STACK_INIT ; reinit graycode stack
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_STACK_UPDATE:
    MOV     R20, R19         ; get LRGrayCodeStack[3, 2] (2nd to last gray
                                ; code)
    ANDI    R20, 0b00001100

    ; uncomment if this macro ever gets working
    ;LSRK    R20, 2
    LSR     R20
    LSR     R20

    CP      R20, R17            ; check if current gray code is equal to the
                                    ; 2nd to last gray code
    BRNE    LR_CHECK_STACK_PREV

    ; uncomment if macro gets working
    ;LSRK    R19, 2
    LSR     R19                 ; if it is the 2nd to last gray code,
    LSR     R19                    ; pop previous gray code off stack
    STS     LRGrayCodeStack, R19
    JMP     DeRotLR_RET

LR_CHECK_STACK_PREV:
    MOV     R20, R19         ; get LRGrayCodeStack[1, 0] (previous gray code)
    ANDI    R20, 0b00000011

    CP      R20, R17            ; check if current gray code is equal to the
                                    ; previous graycode
    BREQ    DeRotLR_RET
    ; uncomment if this macro ever gets working
    ; LSLK    R19, 2                  ; if it isn't the previous gray code,
                                        ; push current graycode onto stack
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
    ; uncomment if this macro ever gets working
    ;LSRK    R17, PORTE_UDROT_SHIFT
    LDI     R16, PORTE_UDROT_SHIFT
    UDROT_LSR:
        CPI     R16, 0      ; check if K is 0
        BREQ    UDROT_LSR_DONE  ; if so, we're done
    
        LSR     R17
        Dec     R16
        JMP     UDROT_LSR
    UDROT_LSR_DONE:

    CPI     R17, 0b00000011     ; check if on detent
    BRNE    UD_STACK_UPDATE

    LDS     R19, UDGrayCodeStack    
                                    

    CPI     R19, GRAYCODE_CCW_FULL ; if on detent, check if 
                                                    ; graycode stack 
                                                    ; is ccw full
    BRNE    UD_CHECK_CW_FULL                       
    LDI     R18, TRUE               ; if ccw full, register up rot
    STS     UDRotUp, R18
    LDI     R19, GRAYCODE_STACK_INIT ; reinit graycode stack
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_CHECK_CW_FULL:
    CPI     R19, GRAYCODE_CW_FULL ; if on detent, and 
                                                    ; not ccw full, check if 
                                                    ; graycode stack 
                                                    ; is cw full
    BRNE    UD_STACK_UPDATE
    LDI     R18, TRUE               ; if cw full, register down rot
    STS     UDRotDown, R18
    LDI     R19, GRAYCODE_STACK_INIT ; reinit graycode stack
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_STACK_UPDATE:
    MOV     R20, R19         ; get UDGrayCodeStack[3, 2] (2nd to last gray
                                ; code)
    ANDI    R20, 0b00001100
    ; uncomment if this ever gets working
    ;LSRK    R20, 2
    LSR     R20
    LSR     R20

    CP      R20, R17            ; check if current gray code is equal to the
                                    ; 2nd to last gray code
    BRNE    UD_CHECK_STACK_PREV
    ; uncomment if this ever gets working
    ;LSRK    R19, 2                  ; if it is the 2nd to last gray code,
    LSR     R19
    LSR     R19
                                        ; pop previous gray code off stack
    STS     UDGrayCodeStack, R19
    JMP     DeRotUD_RET

UD_CHECK_STACK_PREV:
    MOV     R20, R19         ; get UDGrayCodeStack[1, 0] (previous gray code)
    ANDI    R20, 0b00000011

    CP      R20, R17            ; check if current gray code is equal to the
                                    ; previous graycode
    BREQ    DeRotUD_RET
    ; uncomment if ever gets working
    ;LSLK    R19, 2                  ; if it isn't the previous gray code,
                                        ; push current graycode onto stack
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

; CheckSwitchAction macro
; =====================
; 
; Description
; -----------
; indicates if a boolean shared var (@0) is set or reset
; 
; Operational Description
; -----------------------
; Returns `TRUE` (i.e. sets the zero flag) if the has been set since the last
; time this was called;
; otherwise,
; returns `FALSE` (i.e. resets the zero flag).
; Resets @0.
; 
; Arguments
; ---------
; @0 (boolean shared var): RW
; 
; Return Values
; -------------
; If @0 is high, return `TRUE` (zero flag set);
; if @0 is low, return `FALSE` (zero flag reset).
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; None (although functions using this macro RW @0, which is a shared var)
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
; This doesn't work because of label issues, so commented out for now
; 
; Special Notes
; -------------
; None
;.MACRO CheckSwitchAction
;PUSH    R16 ; save status flags
;PUSH    R17 ; R @0
;PUSH    R18 ; W @0
;
;IN      R16, SREG   ; freeze status flags
;CLI
;
;; critical code
;LDS     R17, @0     ; save @0 to register
;LDI     R18, FALSE  ; reinit @0
;STS     @0, R18
;; end critical code
;
;OUT     SREG, R16   ; unfreeze status flags
;
;CPI     R17, TRUE   ; check if @0 is set
;BRNE    1f
;SEZ                 ; if set, return true
;JMP     2f
;
;1:
;    CLZ             ; if reset, return false
;2:
;    POP     R18
;    POP     R17
;    POP     R16
;.ENDMACRO

LRSwitch:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRSwitchPressed
    PUSH    R22 ; W LRSwitchPressed
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, LRSwitchPressed     ; save LRSwitchPressed to register
    LDI     R22, FALSE  ; reinit LRSwitchPressed
    STS     LRSwitchPressed, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if LRSwitchPressed is set
    BRNE    LRSWITCHPRESSED_NOT_SET
    SEZ                 ; if set, return true
    JMP     LRSwitch_RET
    
LRSWITCHPRESSED_NOT_SET:
    CLZ             ; if reset, return false
LRSwitch_RET:
    POP     R22
    POP     R21
    POP     R0
    RET

UDSwitch:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDSwitchPressed
    PUSH    R22 ; W UDSwitchPressed
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, UDSwitchPressed     ; save UDSwitchPressed to register
    LDI     R22, FALSE  ; reinit UDSwitchPressed
    STS     UDSwitchPressed, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if UDSwitchPressed is set
    BRNE    UDSWITCHPRESSED_NOT_SET
    SEZ                 ; if set, return true
    JMP     UDSwitch_RET
UDSWITCHPRESSED_NOT_SET:
    CLZ             ; if reset, return false
UDSwitch_RET:
    POP     R22
    POP     R21
    POP     R0
    RET

LeftRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRRotLeft
    PUSH    R22 ; W LRRotLeft
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, LRRotLeft     ; save LRRotLeft to register
    LDI     R22, FALSE  ; reinit LRRotLeft
    STS     LRRotLeft, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if LRRotLeft is set
    BRNE    LRROTLEFT_NOT_SET
    SEZ                 ; if set, return true
    JMP     LeftRot_RET
LRROTLEFT_NOT_SET:
    CLZ             ; if reset, return false
LeftRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET

RightRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R LRRotRight
    PUSH    R22 ; W LRRotRight
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, LRRotRight     ; save LRRotRight to register
    LDI     R22, FALSE  ; reinit LRRotRight
    STS     LRRotRight, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if LRRotRight is set
    BRNE    LRROTRIGHT_NOT_SET
    SEZ                 ; if set, return true
    JMP     RightRot_RET
LRROTRIGHT_NOT_SET:
    CLZ             ; if reset, return false
RightRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET

UpRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDRotUp
    PUSH    R22 ; W UDRotUp
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, UDRotUp     ; save UDRotUp to register
    LDI     R22, FALSE  ; reinit UDRotUp
    STS     UDRotUp, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if UDRotUp is set
    BRNE    UDROTUP_NOT_SET
    SEZ                 ; if set, return true
    JMP     UpRot_RET
UDROTUP_NOT_SET:
    CLZ             ; if reset, return false
UpRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET

DownRot:
    PUSH    R0 ; save status flags
    PUSH    R21 ; R UDRotDown
    PUSH    R22 ; W UDRotDown
    
    IN      R0, SREG   ; freeze status flags
    CLI
    
    ; critical code
    LDS     R21, UDRotDown     ; save UDRotDown to register
    LDI     R22, FALSE  ; reinit UDRotDown
    STS     UDRotDown, R22
    ; end critical code
    
    OUT     SREG, R0   ; unfreeze status flags
    
    CPI     R21, TRUE   ; check if UDRotDown is set
    BRNE    UDROTDOWN_NOT_SET
    SEZ                 ; if set, return true
    JMP     DownRot_RET
UDROTDOWN_NOT_SET:
    CLZ             ; if reset, return false
DownRot_RET:
    POP     R22
    POP     R21
    POP     R0
    RET
