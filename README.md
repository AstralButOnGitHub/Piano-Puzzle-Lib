# Piano Puzzle Lib
This library implements all the piano puzzles from Chapter 4.
This includes:

Moving Bookshelves, Password Pianos, and Moving Pianos. (yet to be added)

### ***EVERYTHING IS SUBJECT TO CHANGE.***
This library is VERY Work-In-Progress.

I do not reccomend using this for any big projects until it's fully ready.

## Moving Bookshelves
To make a moving bookshelf puzzle you'll need 2 things.

A piano and a bookshelf.

To make a piano, on an object layer, create a point and call it "RemotePiano"

Properties:

| Property | Type | Default | Values | Description |
|-|-|-|-|-|
| `target` | `object` | `nil` | `any` | `The movable bookshelf` |
| `type` | `string` | `blue` | `blue, green, pink, red, ` | `The Color / Shape` |

TODO:
- make sure bookshelf movement speed is acurrate
- **NEEDS WORK**. octave switch player move