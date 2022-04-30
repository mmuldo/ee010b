.dseg
    LRSwitch: .Byte 1

; InitSwitchPort Specification
; ============================
;
; Description
; -----------
; Initializes PortE (input port for switches), specifying it as an input port.
;
; Operational Description
; -----------------------
; Sets DDRE to 0x00 (setting PortE to input).
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
; PortE (8-bit register)
;
; Outputs
; -------
; DDRE (8-bit register)
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
;
; Pseudocode
; ----------
; DDRE = 0x00
InitSwitchPort:
    PUSH    R16
    LDI     R16, 0
    OUT     DDRE, R16
    POP     R16

; InitSharedVars Specification
; ========================
; 
; Description
; -----------
; `InitSharedVars()` initializes the shared variables used by the event handler.
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
; LRRotGrayCode (8-bit string): W
; UDRotUp (bool): W
; UDRotDown (bool): W
; UDRotGrayCode (8-bit string): W
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

    LDI     R16, 0
    LDI     R17, 20

    STS     LRSwitchPressed, R16
    STS     LRSwitchCounter, R17

    STS     UDSwitchPressed, R16
    STS     UDSwitchCounter, R17

    STS     LRRotLeft, R16
    STS     LRRotRight, R16
    STS     LRRotGrayCode, R16

    STS     UDRotLeft, R16
    STS     UDRotRight, R16
    STS     UDRotGrayCode, R16

    POP     R17
    POP     R16

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
;   IF LRSwitchCounter == 0:
;       LRSwitchCounter = 0
;   ELSE IF LRSwitchCounter == 1:
;       LRSwitchPressed = 1
;       LRSwitchCounter--
;   ELSE:
;       LRSwitchCounter--
;   ENDIF
; ELSE:
;   LRSwitchCounter = 20
; ENDIF
DebounceLR:
    IN      R16, PinE
    AND     R16, PORTE_LRPRESS

    CPI     R16, 0
