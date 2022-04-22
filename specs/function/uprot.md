# UpRot Specification

None

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the U/D rotary encoder has been
rotated up since the last time `UpRot` was called,
as indicated by the `UDRotUp` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `UDRotUp` before returning,
in order to handle future up rotations.

## Arguments

### `UDRotUp`

Flag (boolean) set by debouncing logic.
Note: this flag is reset by the function.

## Return Values

If `UDRotUp` is high, return `TRUE`;
if `UDRotUp` is low, return `FALSE`.

## Global Variables

None

## Shared Variables

## Description

`UpRot()` is a function that indicates if the U/D rotary encoder
has been rotated up.
It is called by the main subroutine to determine whether or not to perform
the U/D rotary encoder up rotation action.

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
