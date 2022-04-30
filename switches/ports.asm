; utility macros
.include "util.asm"

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
    OUTI    DDRE, 0     ; set PortE as an input port
    POP     R16
    RET

