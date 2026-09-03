# Piano Puzzle Lib
This library implements all the piano puzzles from Chapter 4!


### ***EVERYTHING IS SUBJECT TO CHANGE.***



## Moving Bookshelves
To make a moving bookshelf puzzle you'll need 2 things.

A piano and a bookshelf.

To make a piano, on an object layer, create a point and call it "RemotePiano"

Properties:

| Property | Type | Default | Values | Description |
|-|-|-|-|-|
| `target` | `object` | `nil` | `any` | `The movable bookshelf` |
| `type` | `string` | `blue` | `blue, green, pink, red, ` | `The Color / Shape` |