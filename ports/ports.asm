.include "ports.inc"

;;;;;;;;;;;;;
; ports.asm ;
;;;;;;;;;;;;;

; Description
; -----------
; Initializes ports by specifying which ports are input/output.
;
; Inputs
; ------
; None
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
; 04/28/2022    Matt Muldowney      PortE initialization

.CSEG

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
InitSwitchPort:
    PUSH    R16

    ; set PortE as an input port
    LDI     R16, INPUT
    OUT     DDRE, R16

    POP     R16
    RET

; InitDisplayPorts Specification
; ============================
;
; Description
; -----------
; Initializes PortA (green LED columns), C (LED rows), and D (red LED columns),
; specifying them as output ports.
;
; Operational Description
; -----------------------
; Sets DDRA, C, and D to 0xFF (setting PortA, C, and D to input).
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
; Outputs
; -------
; DDRA (8-bit register)
; DDRC (8-bit register)
; DDRD (8-bit register)
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
InitDisplayPorts:
    ;;; registers needed
    ; r16: holds OUTPUT port const
    .def output = r16
    push output
    ldi output, OUTPUT

    out ddra, output
    out ddrc, output
    out ddrd, output

    pop output
    ret
