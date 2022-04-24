# DeRotRight Specification

## Description

`DeRotRight()` is responsible for distinguishing between a right turn from
one detent to the adjacent detent on the L/R rotary encoder and random
jiggling in between detents.

## Operational Description

Input rotations on the L/R rotary encoder are represented by the following
four ordered graycodes:

* `11`: detent 1
* `01`: just right of detent 1
* `00`: middle between detent 1 and detent 2
* `10`: just right of detent 2
* next `11`: detent 2

A right rotation should be registered if and only if the following sequence
of graycode inputs is seen on the L/R rotary encoder:
```
11 -> [sequence of inputs] -> 11 -> 01 -> [sequence of inputs] -> 01 -> 00 -> [sequence of inputs] ->  00 -> 10 -> [sequence of inputs] -> 10 -> 11
```
In other words, we need to see a complete rotation of graycode inputs in
order `11 -> 01 -> 00 -> 10 -> 11`,
but it is possible that other inputs could interject this rotation based on
oscillations of the L/R rotary encoder as it moves from one detent to
another.
After observing a complete right rotation, the `LRRotRight` flag is set.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

### `LRRotRight` (bool)

This flag is passed to `RightRot()`.
L/R rotary encoder right rotation (complete rightward cycle through the
graycode inputs) --> `LRRotRight` set,
otherwise, --> `LRRotRight` reset.

### `LRRotGrayCode` (8-bit string)

Bits 6 and 7 are masked into the lower two bits of `LRRotGrayCode`.
The upper 6 bits of `LRRotGrayCode` are `0`.

## Local Variables

### `RightGrayCodeStack` (8-bit string)

Initialized to `00 00 00 11`.
This keeps track of the most recently seen `LRRotGrayCode`s.
An example sequence of runs looks like:

| LRRotGrayCode | RightGrayCodeStack |
| ------------- | ----------------- |
|               | 00 00 00 11 |
|11             | 00 00 00 11 |
|01             | 00 00 11 01 |
|11             | 00 00 00 11 |
|01             | 00 00 11 01 |
|00             | 00 11 01 00 |
|00             | 00 11 01 00 |
|00             | 00 11 01 00 |
|10             | 11 01 00 10 |
|00             | 00 11 01 00 |
|10             | 11 01 00 10 |
|11             | 00 00 00 00 |

## Inputs

### PE[7,6] (CHECK IF THIS IS RIGHT)

The L/R rotary encoder is connected to the 7th and 6th bit of port E.
The values these bits can take on are the graycode values:

| 7 | 6 |
| --- | --- |
| 1 | 1 |
| 1 | 0 |
| 0 | 0 |
| 0 | 1 |

where `11` corresponds to being on a detent and the others are between
detents.

## Outputs

None

## Error Handling

None

## Algorithms

If the value of `RightGrayCodeStack` is `11 01 00 10` and the lower 2 bits
of `LRRotGrayCode` are `11`, `LRRotRight` is set, `RightGrayCodeStack` is
reinitialized to `00 00 00 11`, and the function exits.
If the value of `RightGrayCodeStack` is `11 10 00 01` and the lower 2 bits
of `LRRotGrayCode` are `11` (i.e. a complete right turn),
`RightGrayCodeStack` is
reinitialized to `00 00 00 11`, and the function exits.
Each time the function is run, the bits 2 and 3 of `RightGrayCodeStack`
are compared to the lower 2 bits of `LRRotGrayCode`; if they are equal,
`RightGrayCodeStack` is logically shifted right and the function exits.
Otherwise, the lower 2 bits of `RightGrayCodeStack` are compared to the lower
2 bits of `LRRotGrayCode`; if they are not equal, `RightGrayCodeStack` is
logically shifted right and added to `LRRotGrayCode`. Otherwise, the
function exits.

## Data Structures

Stack in the form of a bit string, where things get "stacked" by logically
shifting right and "popped" by logically shifting right, 2 bits at a time.

## Limitations

Turning the L/R rotary encoder too fast could cause jumping between
non-adjacent graycodes, which isn't handled by the function.
However, all that will happen is that the right rotation doesn't get
registered, i.e. this won't cause the algorithm to break.

## Known Bugs

None

## Special Notes

One may be inclined to think that right rotations will break this function.
The following example displays how this situation is okay:

| LRRotGrayCode | RightGrayCodeStack | |
| ------------- | ----------------- |----|
|               | 00 00 00 11 |
|11             | 00 00 00 11 |
|10             | 00 00 11 10 |
|00             | 00 11 10 00 |
|01             | 11 10 00 01 |
|11             | 00 00 00 11 | nothing happens |
|01             | 00 01 11 01 |
|00             | 01 11 01 00 |
|10             | 11 01 00 10 |
|11             | 00 00 00 00 | right rotation |
