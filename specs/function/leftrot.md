# LeftRot Specification

## Description

`LeftRot()` is a function that indicates if the L/R rotary encoder
has been rotated left.
It is called by the main subroutine to determine whether or not to perform
the L/R rotary encoder left rotation action.

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the L/R rotary encoder has been
rotated left since the last time `LeftRot` was called,
as indicated by the `LRRotLeft` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `LRRotLeft` before returning,
in order to handle future left rotations.

## Arguments

None

## Return Values

If `LRRotLeft` is high, return `TRUE` (zero flag set);
if `LRRotLeft` is low, return `FALSE` (zero flag reset).

## Global Variables

None

## Shared Variables

### `LRRotLeft`

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
