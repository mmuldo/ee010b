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
; Sets chip select to an output.
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
; [unknown]
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
;
; sbi eeromPort, EEROM_CS_BIT
; out SPCR, EEROM_CTR
InitSerialIO:
    ;;; registers needed
    .def    temp = r16
    push temp

    ; set chip-select high initially
    sbi     ddrb, EEROM_CS_BIT
    ; set sck to output
    sbi     ddrb, EEROM_SCK_BIT
    ; set master (avr) -> slave (eerom) as output 
    sbi     ddrb, EEROM_MOSI_BIT
    ; set master (avr) <- slave (eerom) as input 
    cbi     ddrb, EEROM_MISO_BIT

    ; set spi control register
    ldi     temp, EEROM_CTR
    out     spcr, temp

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
; numBytes (int): RW
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
; [unknown]
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
;
; Pseudocode
; ----------
;
; check a+n is within range
; check p+n is within range
;
; # edge case: starting addr is odd
; IF a is odd:
;   set CS high
;
;   eeromAddr = a / 2 - 1
;   output read command to SPI at eeromAddr
;   first byte is garbage
;   store second byte
;
;   set CS low
;
;   a++
;   p++
;   n--
; ENDIF
;
; WHILE (n > 0):
;   IF (a is even):
;       set CS high
;       eeromAddr = a / 2
;       output read command to SPI at eeromAddr
;   ENDIF
;
;   read and store byte
;
;   IF (a is odd) or (numBytes == 1):
;       set CS low
;   ENDIF
;
;   a++
;   p++
;   n--
; ENDWHILE
ReadEEROM:
    ;;; arguments
    ; number of bytes to read
    .def    n = r16
    ; EEROM start address
    .def    a = r17
    ; data memory start address
    ; this commented out line just indicates that p is stored in y
    ;.def    p = y


    ;;; other registers
    ; actual EEROM address (addresses the word, not the byte)
    .def    eeromAddr = r18
    push    eeromAddr

    ; register for spi commands
    .def    spiData = r19
    push    spiData

    ; registers for testing argument validity
    .def    testL = r20
    .def    testH = r21
    push    testL
    push    testH

    ; needed for add/adc commands
    .def    zero = r22
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


    ;;; edge case: starting addr a is odd
    ;;;     this is an issue because eerom addresses words, not bytes,
    ;;;     so an odd byte  addr a means we're trying to access eerom we don't 
    ;;;     have direct access to
    ; check if a is odd
    bst     a, 0
    brtc    ReadEEROMWhile
    ; if it is odd, we have to deal with the edge case
    ; get the actual word address
    mov     eeromAddr, a
    lsr     eeromAddr

    ; set chip select high
    sbi     ddrb, EEROM_CS_BIT

    ; output read command
    ldi     spiData, READH
    out     spdr, spiData
    ldi     spiData, READL
    or      spiData, eeromAddr
    rcall   SerialReady
    out     spdr, spiData
    
    ; first byte is garbage
    rcall   SerialReady

    ; store second byte
    rcall   SerialReady
    in      spiData, spdr
    st      y+, spiData
    
    ; set chip select low
    cbi     ddrb, EEROM_CS_BIT

    ; increment/decrement stuff
    inc     a
    dec     n


  ReadEEROMWhile:
    ;;; check if there are still bytes to read
    tst     n
    ; if no more bytes, we're done
    breq    ReadEEROMRet
    ; otherwise, do loop

    ;;; check if a is even
    bst     a, 0
    brts    ReadEEROMReadAndStore
    ; if a is even, then we can address eerom, so...
    ; ... get the actual word address
    mov     eeromAddr, a
    lsr     eeromAddr

    ; ...set chip select high
    sbi     ddrb, EEROM_CS_BIT

    ; ...and output read command
    ldi     spiData, READH
    out     spdr, spiData
    rcall   SerialReady
    ldi     spiData, READL
    or      spiData, eeromAddr
    out     spdr, spiData


  ReadEEROMReadAndStore:
    rcall   SerialReady
    ;;; read and store byte
    in      spiData, spdr
    st      y+, spiData

    ;;; inc/dec stuff
    inc     a
    dec     n

    ;;; check if a is even (after incrementing)
    bst     a, 0
    ; if it is, or ...
    brtc    ReadEEROMCSOff
    ; ... if this is the last byte then ...
    tst     n
    brne    ReadEEROMWhile

    ; ... turn chip select off, since we're done reading this word
  ReadEEROMCSOff:
    ; set chip select off
    cbi     ddrb, EEROM_CS_BIT
    ; and loop
    rjmp    ReadEEROMWhile

    
  ReadEEROMRet:
    pop     zero
    pop     testH
    pop     testL
    pop     spiData
    pop     eeromAddr

    ret
