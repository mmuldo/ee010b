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
; Data Memory
; -----------
; lrSwitchPressed (1 byte): ; bool indicating LR switch has been pressed
; lrSwitchCounter (1 byte): ; counter for debouncing LR switch
;
; udSwitchPressed (1 byte): ; bool indicating UD switch has been pressed 
; udSwitchCounter (1 byte): ; counter for debouncing UD switch
;                           
; lrRotLeft (1 byte):       ; bool indicating LR has been rotated left
; lrRotRight (1 byte):      ; bool indicating LR has been rotated right
;                           
; lrGrayCodeStack (1 byte): ; keeps tack of 4 most recently seen gray 
;                           ;   codes for L\R rotary encoder. 
;                           ;   e.g. a value of 0b11100001 means 
;                           ;   that the most recently seen codes were
;                           ;   01, 00, 10, and 11 in that order
;                           
; udRotUp (1 byte):         ; bool indicating UD has been rotated up
; udRotDown (1 byte):       ; bool indicating UD has been rotated down
;                           
; udGrayCodeStack (1 byte): ; keeps tack of 4 most recently seen gray 
;                           ;   codes for L\R rotary encoder. 
;                           ;   e.g. a value of 0b11100001 means 
;                           ;   that the most recently seen codes were
;                           ;   01, 00, 10, and 11 in that order
;
; Routines
; --------
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

.dseg
    lrSwitchPressed:    .byte 1
    lrSwitchCounter:    .byte 1
    udSwitchPressed:    .byte 1
    udSwitchCounter:    .byte 1
    lrRotLeft:          .byte 1
    lrRotRight:         .byte 1
    lrGrayCodeStack:    .byte 1
    udRotUp:            .byte 1
    udRotDown:          .byte 1
    udGrayCodeStack:    .byte 1
                               

.cseg

; InitSwitchVars()
; ================
; 
; Description
; -----------
; InitSwitchVars initializes the shared variables used by the event
; handler.
; 
; Operational Description
; -----------------------
; All event handling flags are reset to 0 and the interrupt flag is set to 1
; (to enable interrupts).
; Moreover, switch vars are initialized to their respective values.
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
; lrSwitchPressed (bool): W
; udSwitchPressed (bool): W
; lrRotLeft (bool): W
; lrRotRight (bool): W
; lrGrayCodeStack (8-bit string): W
; udRotUp (bool): W
; udRotDown (bool): W
; udGrayCodeStack (8-bit string): W
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
    push    r16
    push    r17
    push    r18

    ; contains FALSE
    .def    falseReg = r16
    ldi     falseReg, FALSE

    ; contains DEBOUNCE_TIME
    .def    debounceTime = r17
    ldi     debounceTime, DEBOUNCE_TIME

    ; contains GRAYCODE_STACK_INIT
    .def    grayCodeStackInit = r18
    ldi     grayCodeStackInit, GRAYCODE_STACK_INIT

    ; shared booleans should be initialized to false (since we haven't registered
    ;   presses/rotations)
    sts     lrSwitchPressed, falseReg
    sts     udSwitchPressed, falseReg
    sts     lrRotLeft, falseReg
    sts     lrRotRight, falseReg
    sts     udRotUp, falseReg
    sts     udRotDown, falseReg

    ; shared switch counters should be initialized to DEBOUNCE_TIME and
    ;   count down from there
    sts     lrSwitchCounter, debounceTime
    sts     udSwitchCounter, debounceTime

    ; shared graycode stacks should be initialized to the starting
    ;   positions of the rotary encoders
    sts     lrGrayCodeStack, grayCodeStackInit
    sts     udGrayCodeStack, grayCodeStackInit

    pop     r18
    pop     r17
    pop     r16
    ret


; SwitchEventHandler
; ==================
; 
; Description
; -----------
; Handles the following events:
; * switch presses (specifically, debouncing switch presses)
; * rotary encoder rotations (specifically, debouncing rotations)
; Called once every Timer0 interrupt.
; 
; Operational Description
; -----------------------
; This function simply calls the debouncing logic.
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
; actionRegistered (bool): for reading if action registered during debounce/rot
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
; Registers Used
; --------------
; None
;
; Stack Depth
; -----------
; 1 bytes
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
    push    r16

    ; for manipulation with t flag
    .def    actionRegistered = r16
    clr     actionRegistered

    ;;; debounce lr switch
    debounce    lrSwitchCounter, pine, LRSWITCH_MASK
    ; if switch pressed register, t flag will be set
    bld         actionRegistered, 0
    sts         lrSwitchPressed, actionRegistered

    ;;; debounce ud switch
    debounce    udSwitchCounter, pine, UDSWITCH_MASK
    ; if switch pressed register, t flag will be set
    bld         actionRegistered, 0
    sts         udSwitchPressed, actionRegistered

    ;;; derot lr rotary encoder in the left direction
    derot       lrGrayCodeStack, GRAYCODE_CCW_FULL, pine, LRROT_BIT1, LRROT_BIT2
    ; if rotary encoder turned left, t flag will be set
    bld         actionRegistered, 0
    sts         lrRotLeft, actionRegistered

    ;;; derot lr rotary encoder in the right direction
    derot       lrGrayCodeStack, GRAYCODE_CW_FULL, pine, LRROT_BIT1, LRROT_BIT2
    ; if rotary encoder turned right, t flag will be set
    bld         actionRegistered, 0
    sts         lrRotRight, actionRegistered

    ;;; derot ud rotary encoder in the up direction
    derot       udGrayCodeStack, GRAYCODE_CCW_FULL, pine, UDROT_BIT1, UDROT_BIT2
    ; if rotary encoder turned up, t flag will be set
    bld         actionRegistered, 0
    sts         udRotUp, actionRegistered

    ;;; derot ud rotary encoder in the down direction
    derot       udGrayCodeStack, GRAYCODE_CW_FULL, pine, UDROT_BIT1, UDROT_BIT2
    ; if rotary encoder turned down, t flag will be set
    bld         actionRegistered, 0
    sts         udRotDown, actionRegistered

    pop     r16
    ret



; ResolveSwitchCounter(counter)
; =============================
; 
; Description
; -----------
; Determines what to do with a switch counter based on the t flag.
; counter is passed by reference via y.
; Here are the possible outcomes:
;   t clear and counter > 0 --> decrement counter
;   t clear and counter == 0 --> counter = 0
;   t set --> reinit counter
; 
; Operational Description
; -----------------------
; First checks if t is set. If it is, reinits counter.
; Then checks if counter > 0. If so, decrements counter.
; 
; Arguments
; ---------
; counter (16-address, y): data memory address of counter
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
; counterReg (int): local copy of counter
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
; 1 byte
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
ResolveSwitchCounter:
    push    r16

    ;;; counter value
    .def    counterReg = r16

    ;;; t = 1 --> reinit
    brts    ResolveSwitchCounterReinit

    ;;; t = 0 and counter == 0 --> return
    ld      counterReg, y
    tst     counterReg
    breq    ResolveSwitchCounterReturn

    ;;; otherwise, dec counter
    dec     counterReg
    jmp     ResolveSwitchCounterStore

  ResolveSwitchCounterReinit:
    ldi     counterReg, DEBOUNCE_TIME
    ;jmp     ResolveSwitchCounterStore

  ResolveSwitchCounterStore:
    ;;; store changed counter
    st      y, counterReg
    ;jmp     ResolveSwitchCounterReturn

  ResolveSwitchCounterReturn:
    pop     r16
    ret



; DerotHelper(grayCodeStack, encoderReading, fullTurn)
; ====================================================
; 
; Description
; -----------
; Helper function for derot macro. Responsible for distinguishing between a turn 
; between one detent to the adjacent detent on a rotary encoder and random
; jiggling in between detents. A full turn is registered iff the encoder
; reading == ON_DETENT and the grayCodeStack == fullTurn.
; encoderReading is passed in on r17, grayCodeStack on r16, and fullTurn on
; r18. If a full turn is registered, the t flag will be set; otherwise, the
; t flag will be cleared. Moreover, the grayCodeStack (r16) is updated in the following
; manner:
;   full turn --> reinitialized
;   otherwise --> if encoderReading == 2 readings previous, popped off 
;                       grayCodeStack
;                   if encoderReading == previous reading, do nothing
;                   otherwise, encoderReading pushed onto grayCodeStack
; 
; Operational Description
; -----------------------
; The encoderReading is checked to see if it matches ON_DETENT. If it does,
; grayCodeStack is checked to see if it matches fullTurn. If it does, the
; t flag is set, grayCodeStack is reinitialized, and the function returns. 
; Otherwise, t flag is cleared. Then we check if the encoderReading == 2 
; readings previous, pop off grayCodeStack; if encoderReading != previous, 
; push onto grayCodeStack. Then return.
; 
; Arguments
; ---------
; grayCodeStack (8-bit string, r16): stack of previous encoder readings
; encoderReading (2-bit string, r17): current encoderReading
; fullTurn (8-bit string, r18): what the grayCodeStack will be after a
;   full turn
; 
; Return Values
; -------------
; t: set if full turn registered, cleared otherwise
; r16, 8-bit string: updated grayCodeStack
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
; prevReading: for checking previous graycode readings
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
; Stack in the form of a bit string, where things get "stacked" by logically
; shifting left and "popped" by logically shifting right, 2 bits at a time.
; 
; Registers Changed
; -----------------
; None
;
; Stack Depth
; -----------
; 1 byte
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
DerotHelper:
    push    r17
    push    r19

    ;;; arguments
    .def    grayCodeStack = r16
    .def    encoderReading = r17
    .def    fullTurn = r18

    ;;; other registers needed
    ; previous encoder readings
    .def    prevReading = r19

    ;;; check if on detent
    cpi     encoderReading, ON_DETENT
    ; if not, we haven't done a full turn yet, so just go
    ;   to stack update
    brne    DerotHelperStackUpdate
    ; otherwise, check if grayCodeStack is full
    cp      grayCodeStack, fullTurn
    ; if full, set t to register full turn, reinit grayCodeStack, and return
    set
    ldi     grayCodeStack, GRAYCODE_STACK_INIT
    jmp     DerotHelperReturn

  DerotHelperStackUpdate:
    ; clear t since we didn't register a full turn
    clt

    ;;; check if we saw this encoder reading 2 times ago
    ; get 2nd most recent seen gray code
    mov     prevReading, grayCodeStack
    andi    prevReading, PENULTIMATE_MASK

    ; shift down so that it's sitting in the bottom 2 bits
    lsr     prevReading
    lsr     prevReading

    ; check if current gray code is equal to the 2nd to last gray code
    cp      encoderReading, prevReading
    brne    DerotHelperCheckPrevious
    ; if it is, pop the previous gray code off stack
    lsr     grayCodeStack
    lsr     grayCodeStack

    ; and return since nothing more to do
    jmp     DerotHelperReturn

  DerotHelperCheckPrevious:
    ;;; check if we saw this encoder reading last time
    ; get previously seen gray code
    mov     prevReading, grayCodeStack
    andi    prevReading, PREVIOUS_MASK

    ; check if current gray code is equal to the 2nd to last gray code
    cp      encoderReading, prevReading
    ; if it is, don't do anything and just return
    breq    DerotHelperReturn
    ; if it isn't, push the current graycode onto the stack
    lsl     encoderReading
    lsl     encoderReading
    add     grayCodeStack, encoderReading
    
  DerotHelperReturn:
    pop     r19
    pop     r17
    ret