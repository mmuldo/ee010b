# InitShared Specification

## Description

`InitShared()` initializes the shared variables used by the event handler.

## Operational Description

All event handling flags are reset to 0 and the interrupt flag is set to 1
(to enable interrupts).

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

### `UDSwitchPressed` (bool)

This flag is passed to the `UDSwitch()`.
U/D switch pressed (held down for 20 ms) --> `UDSwitchPressed` set,
otherwise, --> `UDSwitchPressed` reset.

### `LRRotLeft` (bool)

This flag is passed to `LeftRot()`.
L/R rotary encoder left rotation (complete leftward cycle through the
graycode inputs) --> `LRRotLeft` set,
otherwise, --> `LRRotLeft` reset.

### `LRRotRight` (bool)

This flag is passed to `RightRot()`.
L/R rotary encoder right rotation (complete rightward cycle through the
graycode inputs) --> `LRRotRight` set,
otherwise, --> `LRRotRight` reset.

### `LRRotGrayCode` (8-bit string)

Bits 6 and 7 are masked into the lower two bits of `LRRotGrayCode`.
The upper 6 bits of `LRRotGrayCode` are `0`.

### `UDRotUp` (bool)

This flag is passed to `UpRot()`.
U/D rotary encoder up rotation (complete upward cycle through the
graycode inputs) --> `UDRotUp` set,
otherwise, --> `UDRotUp` reset.

### `UDRotDown` (bool)

This flag is passed to `DownRot()`.
U/D rotary encoder down rotation (complete downward cycle through the
graycode inputs) --> `UDRotDown` set,
otherwise, --> `UDRotDown` reset.

### `UDRotGrayCode` (8-bit string)

Bits 3 and 4 are masked into the lower two bits of `UDRotGrayCode`.
The upper 6 bits of `UDRotGrayCode` are `0`.

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
