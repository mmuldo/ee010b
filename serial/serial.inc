;;;;;;;;;;;;;;
; serial.inc ;
;;;;;;;;;;;;;;

; port constants
;
; Revision History
; ----------------
; 5/27/2022     Matt Muldowney      eerom consts
; 5/27/2022     Matt Muldowney      spi consts


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
.equ    EEROM_CAPACITY  = 128


; SPI consts
; ==========
; spi interrupt flag mask
; -----------------------
.equ    SPIF_MASK       = 0b10000000

; READ command
; ------------
; first 7 bits are dummy 0's
; 110 -> read
; last 6 bits are for address (or READL with address)
.equ    READH           = 0b00000001
.equ    READL           = 0b10000000
