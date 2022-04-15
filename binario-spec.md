# Binario Specification

## Description

Binario is a game played on an 8 x 8 grid where each space can take on the
color red, green, or unfilled (indicated by an LED).
The game starts with each space on the grid initialized to red, green,
or unfilled.
The unfilled spaces are those that the user is allowed to change to red
or green (spaces that are initially filled with red or green are not allowed
to be changed by the user).
The user wins when they satisfy each of the following:

* each space in the grid is filled with either red or green
* no more than two adjacent spaces in the horizontal/vertical directions
have the same color
* every row and column has 4 red spaces and 4 green spaces
* no two rows are the same
* no two columns are the same.

## Global variables

### `initial_tableaus`

Array of tableau layouts which the game can be initialized with, along with
their associated solutions.

## Inputs

### up/down rotary encoder

Moves the user's position one space up when rotated clockwise and one space
down when rotated counter-clockwise.
When pushed, resets the game to the initial tableau.

### left/right rotary encoder

Moves the user's position one space right when rotated clockwise and one 
space left when rotated counter-clockwise.
When pushed, changes the color of the current space, cycling through
unfilled, red, and green in that order.

## Outputs

### 8 x 8 red/green LED matrix

The game board itself, layed out in a square grid of LEDs.
Each LED represents a space on the board and can be either red, green, or
unlit (unfilled).

### speaker

The speaker is responsible for giving audio feedback to the user.
The speaker beeps when the user attempts to overwrite one of the initialized
spaces, which is illegal.
The speaker plays a little tune when the user wins.

## User Interface

As described in the inputs section, there are two rotary encoders for moving
the user up/down and left/right.
When the user gets to one of the edges of the grid and tries to move into
the "wall", the cursor wraps around to the other edge.
For example, if the cursor is on the top row and the user tries to move up,
the cursor will be placed on the bottom row in the same column.

To reset the game to its initial state, the user pushes the up/down encoder.
This will change all spaces that the user set to unfilled, keeping the
spaces that were initially set by the game as their color.

To change the space of a color, the user pushes the left/right encoder,
which cycles between unfilled, red, and green in tha order.
If the user attempts to change a space that was set by the initial tableau,
the speaker will beep to indicate that this is illegal.

The LED in which the cursor is currently placed on will blink in order to
indicate to the user where they are on the grid.
The blinking patterns are depend on the type of space in the following
manner:

* unfilled space: oscillates between red and green
* filled space set by user: oscillates between the current color and
unfilled
* filled space set by initial tableau: oscillates between the color and 
unfilled at half speed

When the user has filled all the spaces with red or green and the
configuration satisfies all of the winning conditions, the speaker will
play a cutesy song to indicate that the user has won, along with having
all of the LEDs synchronously flash.
Once the song has completed, the board will re-initialize with a new
tableau, so that the user can play again.

## Error Handling

### overwriting a space set by the initial tableau

The speaker will beep and no change will take place on the grid itself.

### Moving into a "wall"

The 4 scenarios in which this can occur are

1. cursor on top row and user attempts to move up
2. cursor on bottom row and user attempts to move down
3. cursor on right-most column and user attempts to move right
4. cursor on left-most column and user attempts to move left

In any of these scenarios, the cursor will wrap around to the opposite wall.

## Algorithms

None

## Data Structures

Matrix (array of arrays) to represent 8 x 8 grid.

## Limitations

The LEDs can only take on red, green, or unlit, which limits the amount
of visual feedback that the system can give to the user.

## Known Bugs

None

## Special Notes

None
