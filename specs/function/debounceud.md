# DebounceUD Specificaiton

## Description

`DebounceUD()` is responsible for distinguishing a press from random
fluctuations on the U/D switch.

## Operational Description

Holding down the U/D switch for 20 ms (20 timer cycles consecutively)
registers as a press. In more detail, the U/D switch pin being high for
20 ms will result in the `UDSwitchPressed` flag being set.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

### `UDSwitchPressed` (bool)

This flag is passed to the `UDSwitch()`.
U/D switch pressed (held down for 20 ms) --> `UDSwitchPressed` set,
otherwise, --> `UDSwitchPressed` reset.

## Local Variables

### `UDSwitchCounter` (int)

Initialized to 20.
If switch is held down (U/D switch pin is high), then `UDSwitchCounter` is
decremented;
otherwise, reset to 20.
When `UDSwitchCounter` reaches 0, `UDSwitchPressed` is set and
`UDSwitchCounter` is reinitialized to 20.

## Inputs

### PE2 (CHECK IF THIS IS RIGHT)

The U/D switch is connected to the 2nd bit of port E.
When low, the switch is not held down.
When high, the switch is held down.
Being held down for 20 ms will register as an U/D switch press.

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
