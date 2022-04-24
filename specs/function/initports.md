# InitPorts Specification

## Description

`InitPorts()` initializes the ports used by the binario game; specifically,
it specifies that Port E is an input port, and clears all bits of the port.

## Operational Description

This function sets the `DDR` for port E to `OxOO` and sets the port E
register to `0x00`.

## Arguments

None

## Return Values

None

## Global Variables

None

## Shared Variables

None

## Local Variables

None

## Inputs

### Port E

8-bit input port for binario game:

| Input | Port E Bit |
| ----- | ---------- |
| L/R rotary encoder| 7, 6 |
| L/R switch | 5 |
| U/D rotary encoder | 4, 3 |
| U/D switch | 2 |

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
