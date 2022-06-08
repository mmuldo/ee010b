;;;;;;;;;;;;;;;
; display.inc ;
;;;;;;;;;;;;;;;

; Description
; -----------
; constants and macros for display logic
;
; Constants
; ---------
; OFF: integer enumerator for off
; RED: integer enumerator for red color
; GREEN: integer enumerator for green color
; YELLOW: integer enumarotr for yellow color
; PIXEL_OFF (same as OFF)
; PIXEL_RED (same as RED)
; PIXEL_GREEN (same as GREEN)
; PIXEL_YELLOW (same as YELLOW)
; NUM_ROWS: number of rows on display
; NUM_COLS: number of columns on display
; BUFF_OFFSET_INIT: intial offset from column 0 in buffer
; COL_MASK_G_INIT: starting state of green column mask
; COL_MASK_R_INIT: starting state of red column mask
; COL_MASK_G_FINAL: ending state of green column mask (before repeating cycle)
; COL_MASK_R_FINAL: ending state of red column mask (before repeating cycle)
; CURSOR_COUNTER_INIT: initial value to count down from before switching
;   cursor colors
; USE_CURSOR_COLOR2_INIT: whether or not we initially want to use cursor color 2
; CURSOR_ROW_INIT
; CURSOR_COL_INIT
; CURSOR_COLOR1_INIT
; CURSOR_COLOR2_INIT
;
; Macros
; ------
; colorToRG(colorReg, greenReg, redReg): wrapper for accessing ColorToRGTab
; pltimg(ptr): wrapper for PlotImage(pointer)
;
; Revision History
; ----------------
; 05/07/2022    Matt Muldowney      display matrix consts
; 05/09/2022    Matt Muldowney      cursor consts and color consts
; 05/10/2022    Matt Muldowney      changed cursor counter init to 250 ms
;                                       (from 500 ms)
; 05/31/2022    Matt Muldowney      pltimg macro
; 06/03/2022    Matt Muldowney      colorToRG macro

; colors
; ======
.equ    OFF     = 0
.equ    RED     = 1
.equ    GREEN   = 2
.equ    YELLOW  = 3


; colors
; ======
.equ    PIXEL_OFF     = 0
.equ    PIXEL_RED     = 1
.equ    PIXEL_GREEN   = 2
.equ    PIXEL_YELLOW  = 3

; LED display matrix
; ==================
; 8 red and green rows
.equ    NUM_ROWS    = 8

; 8 red and green columns
.equ    NUM_COLS    = 8

; initial ledBufferOffset (for display mux)
.equ    BUFF_OFFSET_INIT    = 0

; initial column masks (for display mux)
.equ    COL_MASK_G_INIT     = 0x80
.equ    COL_MASK_R_INIT     = 0x00
; final column masks (for display mux)
.equ    COL_MASK_G_FINAL    = 0x00
.equ    COL_MASK_R_FINAL    = 0x80

; cursor
; ======
; cursor change counter (uses 1 ms timer0)
.equ    CURSOR_COUNTER_INIT = 250

; cursor blinking (determines which color to use for cursor)
.equ    USE_CURSOR_COLOR2_INIT = FALSE

; cursor position (anything that puts the cursor out of bounds will do)
.equ    CURSOR_ROW_INIT = NUM_ROWS
.equ    CURSOR_COL_INIT = NUM_COLS

; initial cursor colors
.equ    CURSOR_COLOR1_INIT  = OFF
.equ    CURSOR_COLOR2_INIT  = OFF




; colorToRG(colorReg, greenReg, redReg)
; =====================================
;
; Description
; -----------
; Wrapper for accessing ColorToRGTab table.
; Syntax:
;   colorToRG   Rr, Rd1, Rd2
; Where 16 <= r, d1, d2 <= 31.
;
; Operational Description
; -----------------------
; loads ColorToRGTab label into z register, offsets based on colorReg,
; then lpms into greenReg and redReg.
;
; Arguments
; ---------
; colorReg (int, Rr): the color, stored in a register
;
; Return Values
; -------------
; greenReg (bool, Rd1): indicates if green LED should be on
; redReg (bool, Rd1): indicates if red LED should be on
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
; z: pointer to ColorToRGTab
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
; None: doesn't handle bad inputs (i.e. when colorReg != OFF, RED, GREEN, YELLOW)
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
; none
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
.macro  colorToRG
    ; push colorReg arg out of convenience to caller
    push    @0
    push    zl
    push    zh

    ; load pm label into z
    ldi     zl, low(2*ColorToRGTab)
    ldi     zh, high(2*ColorToRGTab)

    ; multiply offset (colorReg) by 2 to correct addressing
    lsl     @0
    ; adjust z by offset
    add     zl, @0
    ; reuse colorReg for zero
    clr     @0
    adc     zh, @0

    ; first byte is green bool
    lpm     @1, z+
    ; second byte is red bool
    lpm     @2, z

    pop     zh
    pop     zl
    pop     @0
.endm



; pltimg(ptr)
; ===========
;
; Description
; -----------
; Wrapper for PlotImage that allows passing of a program label;
; avoids the zl, zh loading business.
; Syntax:
;   pltimage    label
;
; Operational Description
; -----------------------
; loads label into z register and then calls PlotImage(z)
;
; Arguments
; ---------
; label: program label (0 <= label < 4M)
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
; none
;
; Local Variables
; ---------------
; z: for loading ptr from program memory
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
; none
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
.macro  pltimg
    push    zl
    push    zh

    ;;; load pm label into z
    ldi     zl, low(2*@0)
    ldi     zh, high(2*@0)
    ;;; call PlotImage
    rcall   PlotImage

    pop     zh
    pop     zl
.endm