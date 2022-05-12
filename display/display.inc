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

; cursor position (anything that puts the cursor out of bounds will do)
.equ    CURSOR_ROW_INIT = NUM_ROWS
.equ    CURSOR_COL_INIT = NUM_COLS

; alternate cursor color
.equ    CURSOR_RED_COLOR1_INIT    = 0
.equ    CURSOR_GREEN_COLOR1_INIT  = 0
.equ    CURSOR_RED_COLOR2_INIT    = 0
.equ    CURSOR_GREEN_COLOR2_INIT  = 0

; colors
; ======
.equ    OFF     = 0
.equ    RED     = 1
.equ    GREEN   = 2
.equ    YELLOW  = 3
