;set the device
.device ATMEGA64




;get the definitions for the device
.include  "m64def.inc"
.include "timers.inc"
.include "ports.inc"
.include "switches.inc"
.include "util.inc"
.include "display.inc"


;include all the .inc files since all .asm files are needed here (no linker)

.dseg
					.byte 127
	TopOfStack:		.byte 1


.cseg




;setup the vector area

.org    $0000

        JMP     Start                   ;reset vector
        JMP     PC                      ;external interrupt 0
        JMP     PC                      ;external interrupt 1
        JMP     PC                      ;external interrupt 2
        JMP     PC                      ;external interrupt 3
        JMP     PC                      ;external interrupt 4
        JMP     PC                      ;external interrupt 5
        JMP     PC                      ;external interrupt 6
        JMP     PC                      ;external interrupt 7
        JMP     PC                      ;timer 2 compare match
        JMP     PC                      ;timer 2 overflow
        JMP     PC                      ;timer 1 capture
        JMP     PC                      ;timer 1 compare match A
        JMP     PC                      ;timer 1 compare match B
        JMP     PC                      ;timer 1 overflow
        JMP     Timer0EventHandler      ;timer 0 compare match
        JMP     PC                      ;timer 0 overflow
        JMP     PC                      ;SPI transfer complete
        JMP     PC                      ;UART 0 Rx complete
        JMP     PC                      ;UART 0 Tx empty
        JMP     PC                      ;UART 0 Tx complete
        JMP     PC                      ;ADC conversion complete
        JMP     PC                      ;EEPROM ready
        JMP     PC                      ;analog comparator
        JMP     PC                      ;timer 1 compare match C
        JMP     PC                      ;timer 3 capture
        JMP     PC                      ;timer 3 compare match A
        JMP     PC                      ;timer 3 compare match B
        JMP     PC                      ;timer 3 compare match C
        JMP     PC                      ;timer 3 overflow
        JMP     PC                      ;UART 1 Rx complete
        JMP     PC                      ;UART 1 Tx empty
        JMP     PC                      ;UART 1 Tx complete
        JMP     PC                      ;Two-wire serial interface
        JMP     PC                      ;store program memory ready




; start of the actual program

Start:                                  ;start the CPU after a reset
        ldi     r16, low(TopOfStack)    ;initialize the stack pointer
        out     spl, r16
        ldi     r16, high(TopOfStack)
        out     sph, r16

		rcall	InitDisplayPorts
        rcall   InitDisplayVars
        rcall   InitTimer0
        sei

		ldi r16, 1
		ldi r17, 1
		ldi r18, 2
		rcall PlotPixel

        ldi r16, 0
		ldi r17, 0
		ldi r18, 0
		rcall PlotPixel

        ldi r16, 5
		ldi r17, 5
		ldi r18, 1
		rcall PlotPixel

        ldi r16, 3
		ldi r17, 4
		ldi r18, 3
		rcall PlotPixel

        ldi r16, 2
		ldi r17, 4
		ldi r18, -1
		rcall PlotPixel

        ldi r16, 5
		ldi r17, 6
		ldi r18, 4
		rcall PlotPixel

		ldi r16, 5
		ldi r17, 4
		ldi r18, -1
		ldi r19, 4
		rcall SetCursor

    InfLoop: jmp InfLoop

.include "timers.asm"
.include "ports.asm"
.include "switches.asm"
.include "util.asm"
.include "display.asm"
