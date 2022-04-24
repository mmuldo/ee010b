# InitTimers Specification

## Description

`InitTimers()` initializes the timers for the the binario game.
Note that the clock is run at 8 MHz.
The event handler uses timer0 with a period of 1 ms (frequency of 1 kHz),
and thus uses a prescaler of 8000.

## Operational Description

Resets timer0 to 0 with a prescaler of 8000.
Puts timer in continuous mode.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

None

## Local Variables

None

## Inputs

None

## Outputs

None

## Error Handling

None

## Algorithms

None

## Data Structures

None

## Limitations

None

## Known Bugs

None

## Special Notes

None
