# LRSwitch Specification

## Description

`LRSwitch()` is a function that indicates if the L/R switch
has been pressed.
It is called by the main subroutine to determine whether or not to perform
the L/R switch press action.

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the L/R switch has been pressed
since the last time `LRSwitch` was called,
as indicated by the `LRSwitchFlagPressed` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `LRSwitchFlagPressed` before returning,
in order to handle future presses.

## Arguments

None

## Return Values

If `LRSwitchPressed` is high, return `TRUE`;
if `LRSwitchPressed` is low, return `FALSE`.

## Global Variables

None

## Shared Variables

### `LRSwitchPressed`

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
