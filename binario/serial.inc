;;;;;;;;;;;;;;
; serial.inc ;
;;;;;;;;;;;;;;

; port constants
;
; Revision History
; ----------------
; 5/27/2022     Matt Muldowney      eerom consts
; 5/27/2022     Matt Muldowney      spi consts
; 6/02/2022     Matt Muldowney      eerom read macro


; EEROM consts
; ============
; bit on EEROM port at which chip-select is controlled
; ----------------------------------------------------
.equ    EEROM_CS_BIT    = 0
; bit on EEROM port at which SCK is controlled
; ----------------------------------------------------
.equ    EEROM_SCK_BIT  = 1
; bit on EEROM port at which MOSI is controlled
; ----------------------------------------------------
.equ    EEROM_MOSI_BIT  = 2
; bit on EEROM port at which MISO is controlled
; ----------------------------------------------------
.equ    EEROM_MISO_BIT  = 3

; spi control register (for our purposes)
; ---------------------------------------
; 0.......  disable spi interrupts
; .1......  enable spi
; ..0.....  msb first
; ...1....  master mode
; ....0...  leading edge rising, trailing edge falling
; .....1..  leading edge sample, trailing edge setup
; ......01  prescalar of 8 for SCK
.equ    EEROM_CTR       = 0b01010001

; amount of storable bytes in EEROM
; ---------------------------------
.equ    EEROM_CAPACITY  = 129


; SPI consts
; ==========
; spi interrupt flag mask
; -----------------------
.equ    SPIF_MASK       = 0b10000000

; READ command
; ==============
; first 7 bits are dummy 0's
; 110 -> read
; last 6 bits are for address (or READL with address)
.equ    READH           = 0b00000011
.equ    READL           = 0b00000000


; read(addr, data1, data2)
; ========================
;
; Description
; -----------
; Macro that Reads addr from eerom and stores it in 
; two 8 bit registers. The syntax is:
;   read    Rr, Rd1, Rd2
; where 0 <= r, d1, d2 <= 31, but r != 23;
; i.e. DON'T USE R23 for Rr.
; addr is passed in on Rr.
; First byte read from eerom is output to Rd1.
; Second byte read from eerom is output to Rd2.
;
; Operational Description
; -----------------------
; Sets chip select high, outputs READH and READL to spdr, and then
; receives data one byte at a time.
; R23 can't be used for Rr because we need it for outputting spi
; commands.
;
; Arguments
; ---------
; addr (8-bit address, r0-22,24-31): word address of eerom to read 
;
; Return Values
; -------------
; byte1 (8-bit data, r0-31): first data byte at addr
; byte2 (8-bit data, r0-31): second data byte at addr
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
; spicmd (8-bit string, r23): utility register for outputting to spdr
;
; Inputs
; ------
; None
;
; Outputs
; -------
; EEROM chip select port
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
; --------------
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
; Although r23 is preserved in this macro, it can't be used for Rr.
.macro read
    ;;; util register (r23 b/c most likely not to collide)
    .def    spicmd = r23
    push    spicmd

    ;;; set chip select high
    sbi     portb, EEROM_CS_BIT
    
    ;;; output read command
    ; high byte of read command
    ldi     spicmd, READH
    out     spdr, spicmd
    ; wait until ready
    rcall   SerialReady
    ; low byte of read command (includes address)
    ldi     spicmd, READL
    or      spicmd, @0
    ; shift left for acknowledgement
    lsl     spicmd
    out     spdr, spicmd
    ; wait until ready
    rcall   SerialReady
    
    ; pop spicmd in case user wants to use r23 for rd1 or rd2
    pop     spicmd

    ;;; reuse spicmd register for zero;
    ;;;   needed to out garbage to spdr
    .def    zero = r23
    clr     zero

    ;;; read in data (2 bytes total)
    ; give garbage to shift in thing we want
    out     spdr, zero
    ; wait until ready
    rcall   SerialReady
    ; read in first byte
    in      @1, spdr
    
    ; give garbage to shift in thing we want
    out     spdr, zero
    ; wait until ready
    rcall   SerialReady
    ; read in second byte
    in      @2, spdr

    ;;; set chip select low
    cbi     portb, EEROM_CS_BIT
.endm