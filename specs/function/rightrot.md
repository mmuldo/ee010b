# RightRot Specification

## Description

`RightRot()` is a function that indicates if the L/R rotary encoder
has been rotated right.
It is called by the main subroutine to determine whether or not to perform
the L/R rotary encoder right rotation action.

## Operational Description

Returns `TRUE` (i.e. sets the zero flag) if the L/R rotary encoder has been
rotated right since the last time `RightRot` was called,
as indicated by the `LRRotRight` flag set by the debouncing logic;
otherwise,
returns `FALSE` (i.e. resets the zero flag).
When returning `TRUE`, resets `LRRotRight` before returning,
in order to handle future right rotations.

## Arguments

None

## Return Values

If `LRRotRight` is high, return `TRUE` (zero flag set);
if `LRRotRight` is low, return `FALSE` (zero flag reset).

## Global Variables

None

## Shared Variables

### `LRRotRight`

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
