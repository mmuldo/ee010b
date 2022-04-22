# EventHandler Specification

## Description

`EventHandler()` is a function that handles the following events:

* switch presses (specifically, debouncing switch presses)
* rotary encoder rotations (specifically, debouncing rotations)

In response to the above events, `EventHandler` sets certain flags that are
shared with the switch and rotary encoder functions.

## Operational Description

Inputs (the switches and rotary encoders) for the event handler come in on
Port E.
A switch held down (pin high) for 20 ms (20 timer cycles) should register as
a switch press (the corresponding switch flag should be set).
A rotary that's rotated through the four adjacent values
(e.g. 00 -> 01 -> 11 -> 10) should register as a rotation in the appropriate
direction (the corresponding rotary encoder flag should be set).
The rotary encoder patterns are the following):

* 
The function checks the value of `switchCounter`.
If `switchCounter > 0`, `switchCounter` is decremented;
otherwise the `[switch]SwitchPressed` flag is set and `switchCounter` is
reinitialized to [`PRESS_COUNT_INIT`](#press-count-init).

## Arguments

### `switchCounter`

The switch counter to operate on.
In this case, there are two choices: the switch counter for the U/D switch
(`UDSwitchCounter`) and the switch counter for the L/R switch
(`LRSwitchCounter`).
This argument is either decremented or reinitialized when the function is
called.

## Return Values

This function doesn't return anything, but sets
