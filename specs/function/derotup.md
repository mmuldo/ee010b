# DeRotUp Specification

## Description

`DeRotUp()` is responsible for distinguishing between a up turn from
one detent to the adjacent detent on the U/D rotary encoder and random
jiggling in between detents.

## Operational Description

Input rotations on the U/D rotary encoder are represented by the following
four ordered graycodes:

* `11`: detent 1
* `01`: just up of detent 1
* `00`: middle between detent 1 and detent 2
* `10`: just up of detent 2
* next `11`: detent 2

A up rotation should be registered if and only if the following sequence
of graycode inputs is seen on the U/D rotary encoder:
```
11 -> [sequence of inputs] -> 11 -> 01 -> [sequence of inputs] -> 01 -> 00 -> [sequence of inputs] ->  00 -> 10 -> [sequence of inputs] -> 10 -> 11
```
In other words, we need to see a complete rotation of graycode inputs in
order `11 -> 01 -> 00 -> 10 -> 11`,
but it is possible that other inputs could interject this rotation based on
oscillations of the U/D rotary encoder as it moves from one detent to
another.
After observing a complete up rotation, the `UDRotUp` flag is set.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

### `UDRotUp` (bool)

This flag is passed to `UpRot()`.
U/D rotary encoder up rotation (complete upward cycle through the
graycode inputs) --> `UDRotUp` set,
otherwise, --> `UDRotUp` reset.

### `UDRotGrayCode` (8-bit string)

Bits 3 and 4 are masked into the lower two bits of `UDRotGrayCode`.
The upper 6 bits of `UDRotGrayCode` are `0`.

## Local Variables

### `UpGrayCodeStack` (8-bit string)

Initialized to `00 00 00 11`.
This keeps track of the most recently seen `UDRotGrayCode`s.
An example sequence of runs looks like:

| UDRotGrayCode | UpGrayCodeStack |
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

### PE[4,3] (CHECK IF THIS IS up)

The U/D rotary encoder is connected to the 4th and 3rd bit of port E.
The values these bits can take on are the graycode values:

| 4 | 3 |
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

If the value of `UpGrayCodeStack` is `11 01 00 10` and the lower 2 bits
of `UDRotGrayCode` are `11`, `UDRotUp` is set, `UpGrayCodeStack` is
reinitialized to `00 00 00 11`, and the function exits.
If the value of `UpGrayCodeStack` is `11 10 00 01` and the lower 2 bits
of `UDRotGrayCode` are `11` (i.e. a complete up turn),
`UpGrayCodeStack` is
reinitialized to `00 00 00 11`, and the function exits.
Each time the function is run, the bits 2 and 3 of `UpGrayCodeStack`
are compared to the lower 2 bits of `UDRotGrayCode`; if they are equal,
`UpGrayCodeStack` is logically shifted up and the function exits.
Otherwise, the lower 2 bits of `UpGrayCodeStack` are compared to the lower
2 bits of `UDRotGrayCode`; if they are not equal, `UpGrayCodeStack` is
logically shifted up and added to `UDRotGrayCode`. Otherwise, the
function exits.

## Data Structures

Stack in the form of a bit string, where things get "stacked" by logically
shifting up and "popped" by logically shifting up, 2 bits at a time.

## Limitations

Turning the U/D rotary encoder too fast could cause jumping between
non-adjacent graycodes, which isn't handled by the function.
However, all that will happen is that the up rotation doesn't get
registered, i.e. this won't cause the algorithm to break.

## Known Bugs

None

## Special Notes

One may be inclined to think that up rotations will break this function.
The following example displays how this situation is okay:

| UDRotGrayCode | UpGrayCodeStack | |
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
|11             | 00 00 00 00 | up rotation |
