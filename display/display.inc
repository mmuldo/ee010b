;;;;;;;;;;;;;;;
; display.inc ;
;;;;;;;;;;;;;;;

; constants for switch logic
;
; Revision History
; ----------------
; 05/07/2022    Matt Muldowney      display matrix stuff

; LED display matrix
; ==================
; 8 red and green rows
.equ    NUM_ROWS    = 8

; 8 red and green columns
.equ    NUM_COLS    = 8

; initial column value
.equ    COL_INIT    = 0x00

; initial ledBufferOffset (for display mux)
.equ    BUFF_OFFSET_INIT    = 0

; initial column masks (for display mux)
.equ    COL_MASK_G_INIT     = 0x80
.equ    COL_MASK_R_INIT     = 0x00

; cursor
; ======
; cursor change counter (uses 1 ms timer0)
.equ    CURSOR_COUNTER_INIT = 500

; cursor blinking (determines which color to use for cursor)
.equ    USE_CURSOR_COLOR2_INIT = FALSE

; cursor position
.equ    CURSOR_ROW_INIT = FALSE
.equ    CURSOR_COL_INIT = FALSE

; alternate cursor color
.equ    CURSOR_RED2_INIT    = 0
.equ    CURSOR_GREEN2_INIT  = 0
