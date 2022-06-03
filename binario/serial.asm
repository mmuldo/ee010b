;;;;;;;;;;;;;;
; serial.asm ;
;;;;;;;;;;;;;;

; Description
; -----------
; handles all interactions between the serial peripheral interface (SPI) and
; the EEROM, including:
;   * InitSerialIO: initializes SPI
;   * SerialReady: awaits SPIF flag before executing an spi command
;   * ReadEEROM(a, p, n): read n bytes from EEROM address a and store at p
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
; 05/27/2022    Matt Muldowney      spi init
; 05/31/2022    Matt Muldowney      serialready and readeerom functions
; 06/02/2022    Matt Muldowney      docs




.cseg

; InitSerialIO
; ============
;
; Description
; -----------
; Initializes serial I/O by setting up the SPI in master mode 0 with
; interrupts disabled, SPI enabled, msb written/read first, and with a
; prescalar of 8.
;
; Operational Description
; -----------------------
; Sets chip select to an output, MISO to input, MOSI to output, and SCK
; to output.
; Sets the SPCR register such that interrupts are disabled, SPI enabled,
; MSB written first, master mode 0, and prescalar 8.
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
; eeromPort (8-bit string): R
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
; None
InitSerialIO:
    ;;; registers needed
    .def    temp = r16
    push temp

    ; set chip-select to output
    sbi     ddrb, EEROM_CS_BIT
    ; set chip-select high for initialization
    sbi     portb, EEROM_CS_BIT
    ; set sck to output
    sbi     ddrb, EEROM_SCK_BIT
    ; set master (avr) -> slave (eerom) as output 
    sbi     ddrb, EEROM_MOSI_BIT
    ; set master (avr) <- slave (eerom) as input 
    cbi     ddrb, EEROM_MISO_BIT

    ; set spi control register
    ldi     temp, EEROM_CTR
    out     spcr, temp

    ; set chip-select low now that we're done
    cbi     portb, EEROM_CS_BIT

    pop temp
    ret



; SerialReady
; ===========
;
; Description
; -----------
; checks serial status register to see if it's ready for R/W (waits until it
; is ready)
;
; Operational Description
; -----------------------
; loops until SPIF is high
;
; Arguments
; ---------
; none
;
; Return Values
; -------------
; none
;
; Global Variables
; ----------------
; none
;
; Shared Variables
; ----------------
; none
;
; Local Variables
; ---------------
; tempSPIF
;
; Inputs
; ------
; none
;
; Outputs
; -------
; none
;
; Error Handling
; --------------
; none
;
; Algorithms
; ----------
; none
;
; Data Structures
; ---------------
; none
;
; Registers Used
; --------------
; none
;
; Stack Depth
; --------------
; 1 byte
;
; Limitations
; -----------
; none
;
; Known Bugs
; ----------
; none
;
; Special Notes
; -------------
; none
SerialReady:
    .def    tempSPIF = r16
    push    tempSPIF

    ;;; do-while: read in spif until it's set
  SerialReadyDoWhile:
    in      tempSPIF, spsr
    andi    tempSPIF, SPIF_MASK
    ; check if spif set
    cpi     tempSPIF, SPIF_MASK
    brne    SerialReadyDoWhile

    ; if it is, then we're done
    pop     tempSPIF
    ret



; ReadEEROM(a, p, n)
; ==================
;
; Description
; -----------
; reads n (r16) bytes of data from serial EEROM address a (r17) and stores it 
; at data address p (y).
;
; Operational Description
; -----------------------
; starting from address floor(a/2), reads two bytes at a time (since EEROM 
; stores words) and then stores them at the corresponding data address
; p + offset. if a is odd, the very first byte read is ignored. if n is odd,
; the very last byte read is ignored.
;
; Arguments
; ---------
; n (int, r16): number of bytes to read and store
; a (8-bit address, r17): the EEROM byte address to start reading bytes from
; p (16-bit address, y): the data address to start storing bytes at
;
; Return Values
; -------------
; none
;
; Global Variables
; ----------------
; none
;
; Shared Variables
; ----------------
; none
;
; Local Variables
; ---------------
; testH:testL: for validating arguments
; zero: register that just holds 0
; eeromAddr: word address in eerom
; firstByte:secondByte: data at eeromAddr
;
; Inputs
; ------
; none
;
; Outputs
; -------
; none
;
; Error Handling
; --------------
; in either of the following cases, the function is aborted:
;   (a) + n exceeds the amount of EEROM memory
;   (p) + n exceeds the amount of data memory
;
; Algorithms
; ----------
; none
;
; Data Structures
; ---------------
; none
;
; Registers Used
; --------------
; none
;
; Stack Depth
; --------------
; 8 bytes
;
; Limitations
; -----------
; none
;
; Known Bugs
; ----------
; none
;
; Special Notes
; -------------
; none
ReadEEROM:
    ;;; arguments
    ; save args out of convenience to caller
    ; number of bytes to read
    .def    n = r16
    push    n
    ; EEROM start address
    .def    a = r17
    push    a
    ; p is stored in y
    push    yl
    push    yh


    ;;; other registers
    ; actual EEROM address (addresses the word, not the byte)
    .def    eeromAddr = r18
    push    eeromAddr

    ; registers for testing argument validity
    .def    testL = r24
    .def    testH = r25
    push    testL
    push    testH

    ; needed for add/adc commands
    .def    zero = r21
    push    zero
    clr     zero

    ;;; check if a + n is valid; if not, return
    mov     testL, a
    add     testL, n
    ; check for unsigned overflow
    brcs    ReadEEROMRet
    ; check if too large
    cpi     testL, EEROM_CAPACITY
    brsh    ReadEEROMRet

    ;;; check if p + n is valid; if not, return
    movw    testH:testL, y
    add     testL, n
    adc     testH, zero
    ; check for unsigned overflow (this also checks if too large since data
    ; memeory can store 2**16 bytes)
    brcs    ReadEEROMRet

    ; since we're sone with testH and testL, redefine them
    ;   for eerom read use
    .def    firstByte = r24
    .def    secondByte = r25

  ReadEEROMWhile:
    ;;; check if there are still bytes to read
    ; if n == 0, no more bytes to read, so done
    tst     n
    breq    ReadEEROMRet
    ; otherwise, do loop

    ;;; get word address
    mov     eeromAddr, a
    lsr     eeromAddr

    ;;; read in data from eeromAddr
    read    eeromAddr, firstByte, secondByte

    ;;; store data first byte
    ; if a is odd, we're on the first iteration edge case
    ;   of starting the read in the middle of a word,
    ;   so skip reading the first byte because it's
    ;   garbage
    bst     a, 0
    brts    ReadEEROMSkipFirstByte
    st      y+, firstByte
    inc     a
    dec     n
    ; if n == 0, we're done (this handles the edge case of reading an
    ;   odd number of bytes)
    breq    ReadEEROMRet
  ReadEEROMSkipFirstByte:
    ;;; store data second byte
    st      y+, secondByte
    inc     a
    dec     n

    ;;; loop
    rjmp    ReadEEROMWhile

    
  ReadEEROMRet:
    pop     zero
    pop     testH
    pop     testL
    pop     eeromAddr
    pop     yh
    pop     yl
    pop     a
    pop     n

    ret