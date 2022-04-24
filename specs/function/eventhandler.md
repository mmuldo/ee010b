# EventHandler Specification

## Description

`EventHandler()` is a function that handles the following events:

* switch presses (specifically, debouncing switch presses)
* rotary encoder rotations (specifically, debouncing rotations)

In response to the above events, `EventHandler` sets certain flags that are
shared with the switch and rotary encoder functions.

## Operational Description

This function simply loops the following once every 1 ms:

```
DebounceLR()
DebounceUD()
DeRotLeft()
DeRotRight()
DeRotUp()
DeRotDown()
```

See the following:

* [DebounceLR()](./debouncelr.md)
* [DebounceUD()](./debounceud.md)
* [DeRotLeft()](./derotleft.md)
* [DeRotRight()](./derotright.md)
* [DeRotUp()](./derotup.md)
* [DeRotDown()](./derotdown.md)

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

## Local Variables

None

## Inputs

### PE2 (CHECK IF THIS IS RIGHT)

The U/D switch is connected to the 2nd bit of port E.
When low, the switch is not held down.
When high, the switch is held down.
Being held down for 20 ms will register as an U/D switch press.

### PE[4,3] (CHECK IF THIS IS RIGHT)

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

### PE5 (CHECK IF THIS IS RIGHT)

The L/R switch is connected to the 5th bit of port E.
When low, the switch is not held down.
When high, the switch is held down.
Being held down for 20 ms will register as an L/R switch press.

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

See:

* [DebounceLR()](./debouncelr.md)
* [DebounceUD()](./debounceud.md)
* [DeRotLeft()](./derotleft.md)
* [DeRotRight()](./derotright.md)
* [DeRotUp()](./derotup.md)
* [DeRotDown()](./derotdown.md)
