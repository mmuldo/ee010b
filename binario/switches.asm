;;;;;;;;;;;;;;;;
; switches.asm ;
;;;;;;;;;;;;;;;;

; Description
; -----------
; Contains all logic for switches and rotary encoders including
;
; Data Memory
; -----------
; lrSwitchPressed (1 byte):   bool indicating LR switch has been pressed
; lrSwitchCounter (1 byte):   counter for debouncing LR switch
;
; udSwitchPressed (1 byte):   bool indicating UD switch has been pressed 
; udSwitchCounter (1 byte):   counter for debouncing UD switch
;                           
; lrRotLeft (1 byte):         bool indicating LR has been rotated left
; lrRotRight (1 byte):        bool indicating LR has been rotated right
;                           
; leftGrayCodeStack (1 byte): keeps tack of 4 most recently seen gray 
;                                codes for L\R rotary encoder. 
;                             e.g. a value of 0b11100001 means 
;                             that the most recently seen codes were
;                             01, 00, 10, and 11 in that order.
;                             used for checking for left turn
; rightGrayCodeStack (1 byte): keeps tack of 4 most recently seen gray 
;                             codes for L\R rotary encoder. 
;                             e.g. a value of 0b11100001 means 
;                             that the most recently seen codes were
;                             01, 00, 10, and 11 in that order
;                             used for checking for right turn
;                           
; udRotUp (1 byte):           bool indicating UD has been rotated up
; udRotDown (1 byte):         bool indicating UD has been rotated down
;                           
; upGrayCodeStack (1 byte):   keeps tack of 4 most recently seen gray 
;                             codes for L\R rotary encoder. 
;                             e.g. a value of 0b11100001 means 
;                             that the most recently seen codes were
;                             01, 00, 10, and 11 in that order
;                             used for checking for up turn
; downGrayCodeStack (1 byte): keeps tack of 4 most recently seen gray 
;                             codes for L\R rotary encoder. 
;                             e.g. a value of 0b11100001 means 
;                             that the most recently seen codes were
;                             01, 00, 10, and 11 in that order
;                             used for checking for down turn
;
; Routines
; --------
; SwitchEventHandler: Timer0 interrupt event handler
; InitSwitchVars: intialization for shared vars in this file
; DebounceHelper(counter, switchReading): helper routine for debounce macro
;   (in switches.inc)
; DerotHelper(grayCodeStack, encoderReading, fullTurn): helper routine for
;   derot macro (in switches.inc)
; LRSwitch: indicates when the L/R switch has been pressed
; UDSwitch: indicates when the L/R switch has been pressed
; LeftRot: indicates when the L/R rotary encoder has turned left (ccw)
; RightRot: indicates when the L/R rotary encoder has turned right (cw)
; UpRot: indicates when the U/D rotary encoder has turned up (ccw)
; DownRot: indicates when the U/D rotary encoder has turned down (cw)
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
; 06/05/2022    Matt Muldowney      refactoring: consolidated debouncing,
;                                     deroting, and event handling functions

.dseg
    lrSwitchPressed:    .byte 1
    lrSwitchCounter:    .byte 1
    udSwitchPressed:    .byte 1
    udSwitchCounter:    .byte 1
    lrRotLeft:          .byte 1
    lrRotRight:         .byte 1
    leftGrayCodeStack:  .byte 1
    rightGrayCodeStack: .byte 1
    udRotUp:            .byte 1
    udRotDown:          .byte 1
    upGrayCodeStack:    .byte 1
    downGrayCodeStack:  .byte 1
                               

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
; leftGrayCodeStack (8-bit string): W
; rightGrayCodeStack (8-bit string): W
; udRotUp (bool): W
; udRotDown (bool): W
; udGrayCodeStack (8-bit string): W
; upGrayCodeStack (8-bit string): W
; downGrayCodeStack (8-bit string): W
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
    sts     leftGrayCodeStack, grayCodeStackInit
    sts     rightGrayCodeStack, grayCodeStackInit
    sts     upGrayCodeStack, grayCodeStackInit
    sts     downGrayCodeStack, grayCodeStackInit

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
; lrSwitchPressed (bool): RW
; udSwitchPressed (bool): RW
; lrRotLeft (bool): RW
; lrRotRight (bool): RW
; leftGrayCodeStack (8-bit string): RW
; rightGrayCodeStack (8-bit string): RW
; udRotUp (bool): RW
; udRotDown (bool): RW
; udGrayCodeStack (8-bit string): RW
; upGrayCodeStack (8-bit string): RW
; downGrayCodeStack (8-bit string): RW
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
; 4 bytes
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
    nop
    ;;; debounce lr switch
    debounce    lrSwitchCounter, pine, LRSWITCH_MASK, lrSwitchPressed
    nop

    ;;; debounce ud switch
    debounce    udSwitchCounter, pine, UDSWITCH_MASK, udSwitchPressed

    ;;; derot lr rotary encoder in the left direction
    derot       leftGrayCodeStack, GRAYCODE_CCW_FULL, pine, LRROT_BIT1, LRROT_BIT2, lrRotLeft

    ;;; derot lr rotary encoder in the right direction
    derot       rightGrayCodeStack, GRAYCODE_CW_FULL, pine, LRROT_BIT1, LRROT_BIT2, lrRotRight

    ;;; derot ud rotary encoder in the up direction
    derot       upGrayCodeStack, GRAYCODE_CCW_FULL, pine, UDROT_BIT1, UDROT_BIT2, udRotUp

    ;;; derot ud rotary encoder in the down direction
    derot       downGrayCodeStack, GRAYCODE_CW_FULL, pine, UDROT_BIT1, UDROT_BIT2, udRotDown

    reti




; DebounceHelper(counter, switchReading)
; ======================================
; 
; Description
; -----------
; Helper function for debounce macro.  Distinguishes a switch 
; press from random switch fluctuations.
; The counter argument (r16) presumably starts at some positive value and then
; counts down while the switch is held down.
; A switch press should be registered iff the counter is 1 and the switch
; is still held down (switchReading (r17) is nonzero). Note that if the 
; counter is 0 and the switch is still
; held down, the counter will not decrement further, but will also not
; register a switch press, since it was already done when the counter was 1.
; Whenever the switch is not held down, the counter is reinit-ed to its
; starting value. If a switch press is to be registered, the z flag will
; be set; otherwise, the z flag is cleared.
; Arguments are counter (r16 by value), and switchReading (r17 by value).
; Return values are the new counter (r16) (either reinitialized, decremented,
; or 0) and the z flag (set if switch press registered, cleared otherwise).
; 
; Operational Description
; -----------------------
; Tst's the switchReading. If z=1, re-initializes counter and clears
; z flag. If z=0 and counter > 1, clears z flag and decrements counter.
; If z = 0 and counter = 1, sets z flag and decrements counter.
; If z = 0 and counter = 0, clears z flag and leaves counter untouched.
; 
; Arguments
; ---------
; counter (int, r16): switch debounce counter
; switchReading (byte, r17): the pin reading;
;   if switchReading = 0, switch up,
;   if switchReading != 0, switch down
; 
; Return Values
; -------------
; z flag: set iff switch press should be registered
; int, r16: the updated counter
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
; none
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
; 0 bytes
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
DebounceHelper:
    ;;; arguments
    .def    counter = r16
    .def    switchReading = r17

    ;;; check pin reading
    ; switchReading = 0 iff pin is up
    tst     switchReading
    ; now, z = 1 iff switch is up

    ; if z = 0 (switch down), check counter
    brne    DebounceHelperCheckCounter
    ; otherwise, switch is up, so reinit counter and return
    ldi     counter, DEBOUNCE_TIME
    jmp     DebounceHelperNotPressed

  DebounceHelperCheckCounter:
    ;;; check if counter = 0
    tst     counter
    ; if counter = 0, press already registered, so don't do anything
    breq    DebounceHelperNotPressed

    ;;; otherwise, check if counter = 1
    dec     counter
    ; at this point, z = 1 iff counter was 1 prior to decrement
    ; so all done
    jmp     DebounceHelperReturn

  DebounceHelperNotPressed:
    ;;; not pressed, so clear z
    clz
    ; and done

  DebounceHelperReturn:
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
; r18. If a full turn is registered, the z flag will be set; otherwise, the
; z flag will be cleared. Moreover, the grayCodeStack (r16) is updated in the following
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
; z flag is set, grayCodeStack is reinitialized, and the function returns. 
; Otherwise, z flag is cleared. Then we check if the encoderReading == 2 
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
; z flag: set if full turn registered, cleared otherwise
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
    push    r19

    ;;; arguments
    .def    grayCodeStack = r16
    .def    fullTurn = r18

    ;;; other registers needed
    ; previous encoder readings
    .def    prevReading = r19


    ;;; check if on detent
    cpi     encoderReading, ON_DETENT
    ; if not, we haven't done a full turn yet, so just go
    ;   to stack update
    brne    DerotHelperStackUpdate
    ; otherwise, set z flag by comparing gray code stack to full state
    cp      grayCodeStack, fullTurn
    ; reinit
    ldi     grayCodeStack, GRAYCODE_STACK_INIT
    ; and return
    jmp     DerotHelperReturn

  DerotHelperStackUpdate:
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
    jmp     DerotHelperClearZ

  DerotHelperCheckPrevious:
    ;;; check if we saw this encoder reading last time
    ; get previously seen gray code
    mov     prevReading, grayCodeStack
    andi    prevReading, PREVIOUS_MASK

    ; check if current gray code is equal to the 2nd to last gray code
    cp      encoderReading, prevReading
    ; if it is, don't do anything and just return
    breq    DerotHelperClearZ
    ; if it isn't, push the current graycode onto the stack
    lsl     grayCodeStack
    lsl     grayCodeStack
    add     grayCodeStack, encoderReading
    ; and retun since nothing more to do
    
  DerotHelperClearZ:
    ;;; for any of the stack update cases, clear z
    clz

  DerotHelperReturn:
    pop     r19
    ret


; Registering events
; ==================
;
; Description
; -----------
; The following routines just call checkBool with the appropriate argument.
; Please see the checkBool macro in util.inc for more information.
; In short, they indicate if their respective flags are True/False.
; If true, they set the z flag, and if false they clear it.
; The respective flags are cleared everytime.
;
; Operational Description
; -----------------------
; just calls checkBool macro
;
; Arguments
; ---------
; None
; 
; Return Values
; -------------
; z flag: set iff shared variable is True
; 
; Global Variables
; ----------------
; None
; 
; Shared Variables
; ----------------
; LRSwitch: lrSwitchPressed (RW)
; UDSwitch: udSwitchPressed (RW)
; LeftRot: lrRotLeft (RW)
; RightRot: lrRotRight (RW)
; UpRot: udRotUp (RW)
; DownRot: udRotDown (RW)
; 
; Local Variables
; ---------------
; none
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
; none
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
; none
; 
; Known Bugs
; ----------
; None
; 
; Special Notes
; -------------
; None
LRSwitch:
    checkBool   lrSwitchPressed
    ret

UDSwitch:
    checkBool   udSwitchPressed
    ret

LeftRot:
    checkBool   lrRotLeft
    ret

RightRot:
    checkBool   lrRotRight
    ret

UpRot:
    checkBool   udRotUp
    ret

DownRot:
    checkBool   udRotDown
    ret
