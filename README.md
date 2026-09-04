![alt text](logo.png)
# Piano Puzzle Lib
This library implements all the piano puzzles from Chapter 4!


***EVERYTHING IS SUBJECT TO CHANGE.***

---
## Moving Bookshelf Puzzles

To make a moving bookshelf puzzle you'll need 3(ish) things.

A ``RemotePiano`` event with an object property ``"target"`` being a ``MovingBookshelf`` event, and an object layer called ``pianocollision``

In your pianocollision layer, Insert rectangles.
These will act as the boundaries to where the MovingBookshelf can move.
![alt text](image-3.png)

This is cool but what how do we stand on the bookshelves?

(bare with me)
You'll want to make 4 new object layers.
``objects_floor_1``, ``objects_floor_2``, ``collision_floor_1``, ``collision_floor_2``

![alt text](image-5.png)
Any objects within these layers will change depending on your current layer.

You should make ``collision_floor_1`` match what you would normally have on the ``collision`` layer.
(``collision_floor_2`` is special, we'll talk about that in a bit.)

So putting an event like ``Chest`` on ``objects_floor_2`` will make it inaccessible unless you're on layer 2.
But, how do we get to layer 2?

On your ``objects_party`` layer, make a rectangle event called FloorTrigger.
This will be where the player can move up and down the floors.
![alt text](image-4.png)

## Object Properties
### RemotePiano
| Property | Type | Default | Values | Description |
|-|-|-|-|-|
| `target (target_1, target_2)` | `object` | `nil` | `MovingObject` | `The controllable object.` |
| `type` | `string` | `blue` | `blue, green, pink, red, twotone` | `Used for the sprites and icon. (Twotone enables controlling 2 objects at once.).` |
| `sprite` | `string` | `nil` | `any sprite` | `Overrides the current sprite.` |
| `camera_pos` | `marker` | `nil` | `Marker` | `Sets the camera pos instead of the currently controlled object.` |
| `camera_posx` | `float` | `nil` | `any number` | `Sets the camera posx.` |
| `camera_posy` | `float` | `nil` | `any number` | `Sets the camera posy.` |

### MovingBookshelf
| Property | Type | Default | Values | Description |
|-|-|-|-|-|
| `type` | `string` | `blue` | `blue, green, pink, red, twotone_green, twotone_purple` | `Used for the sprites and icon.` |
| `iconcolor` | `table (float)` | `COLORS.black` | `any RGBA table` | `The icon's color when inactive.` |
| `iconcolor_bright` | `table (float)` | `COLORS.gray` | `any RGBA table` | `The icon's color when active.` |
| `sound` | `string` | `musicbox` | `any sound` | `The sound played when moved.` |
| `max_speed` | `float` | `14` | `any float` | `The max speed the bookshelf can move.` |
| `can_slow_down` | `boolean` | `true` | `true, false` | `Can the bookshelf be slowed down by BreakableBookshelf.` |