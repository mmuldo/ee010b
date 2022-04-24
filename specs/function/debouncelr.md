# DebounceLR Specificaiton

## Description

`DebounceLR()` is responsible for distinguishing a press from random
fluctuations on the L/R switch.

## Operational Description

Holding down the L/R switch for 20 ms (20 timer cycles consecutively)
registers as a press. In more detail, the L/R switch pin being high for
20 ms will result in the `LRSwitchPressed` flag being set.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

### `LRSwitchPressed` (bool)

This flag is passed to the `LRSwitch()`.
L/R switch pressed (held down for 20 ms) --> `LRSwitchPressed` set,
otherwise, --> `LRSwitchPressed` reset.

## Local Variables

### `LRSwitchCounter` (int)

Initialized to 20.
If switch is held down (L/R switch pin is high), then `LRSwitchCounter` is
decremented;
otherwise, reset to 20.
When `LRSwitchCounter` reaches 0, `LRSwitchPressed` is set and
`LRSwitchCounter` is reinitialized to 20.

## Inputs

### PE5 (CHECK IF THIS IS RIGHT)

The L/R switch is connected to the 5th bit of port E.
When low, the switch is not held down.
When high, the switch is held down.
Being held down for 20 ms will register as an L/R switch press.

## Outputs

None

## Error Handling

None

## Algorithms

Decrementer

## Data Structures

None

## Limitations

None

## Known Bugs

None

## Special Notes

None
