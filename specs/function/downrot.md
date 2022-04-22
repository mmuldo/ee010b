# DownRot Specification

## Description

`DownRot()` is a function that indicates if the U/D rotary encoder
has been rotated down.
It is called by the main subroutine to determine whether or not to perform
the U/D rotary encoder down rotation action.

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the U/D rotary encoder has been
rotated down since the last time `DownRot` was called,
as indicated by the `UDRotDown` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `UDRotDown` before returning,
in order to handle future down rotations.

## Arguments

None

## Return Values

If `UDRotDown` is high, return `TRUE`;
if `UDRotDown` is low, return `FALSE`.

## Global Variables

None

## Shared Variables

### `UDRotDown`

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
