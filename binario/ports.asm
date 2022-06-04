;;;;;;;;;;;;;
; ports.asm ;
;;;;;;;;;;;;;

; Description
; -----------
; Initializes ports by specifying which ports are input/output.
;
; Routines
; --------
; InitSwitchPort: initializes port for switches and rotary encoders to input
; InitDisplayPorts: initializes ports for LED display to output
; InitSoundPort: initializes port for speaker to output
;
; Revision History
; ----------------
; 04/28/2022    Matt Muldowney      switch port init (port e)
; 05/10/2022    Matt Muldowney      display ports init (ports a, c, d)

.cseg

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
    push    r16

    ; set PortE as an input port
    ldi     r16, input
    out     ddre, r16

    pop     r16
    ret

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
    push r16

    ldi r16, OUTPUT

    ; set display ports to output
    out ddra, r16
    out ddrc, r16
    out ddrd, r16

    pop r16
    ret


; InitSoundPort Specification
; ============================
;
; Description
; -----------
; Initializes speaker port (port b bit 5) to output
;
; Operational Description
; -----------------------
; Sets DDRB[5] to 1
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
; DDRB (8-bit register)
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
InitSoundPort:
    sbi     ddrb, SPKR_PORT_BIT
    ret
