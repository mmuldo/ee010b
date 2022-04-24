# UDSwitch Specification

## Description

`UDSwitch()` is a function that indicates if the U/D switch
has been pressed.
It is called by the main subroutine to determine whether or not to perform
the U/D switch press action.

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the U/D switch has been pressed
since the last time `UDSwitch` was called,
as indicated by the `UDSwitchPressed` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `UDSwitchPressed` before returning,
in order to handle future presses.

## Arguments

None

## Return Values

If `UDSwitchPressed` is high, return `TRUE` (zero flag set);
if `UDSwitchPressed` is low, return `FALSE` (zero flag reset).

## Global Variables

None

## Shared Variables

### `UDSwitchPressed`

Flag (boolean) set by debouncing logic.
Note: this flag is reset by the function.

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
