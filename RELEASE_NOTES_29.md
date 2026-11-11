# Fort 29 — Build your own fort, piece by piece

Everyone must run **Fort 29**. Saves from earlier builds load unchanged.

## What is new

You can now build freely with individual pieces: foundations, floors, walls, doors, stairs and roofs. Each piece costs a few resources from the shared stockpile and appears the moment you click. Pieces snap to a 4 m grid that lines up with the castle rooms, so the two fit together.

A new expedition starts with a small timber shell on the keep: four corner walls, two thatched lookouts and two banners. Everything else is yours to add.

## How to build

1. Press **B** to open the build menu.
2. Press **Tab** to change category (Shift+Tab goes back). The categories are **Towers**, **Gate**, **Frame**, **Timber**, **Stone** and **Roofs**.
3. Choose a piece with the **mouse wheel** or **1–9**.
4. Aim. A green ghost shows where the piece will go; red means it cannot go there, and the line at the bottom of the screen says why.
5. **Click** to build.

| Key | In build mode |
| --- | --- |
| Tab / Shift+Tab | Next / previous category (Page Down / Page Up also work) |
| Wheel, 1–9 | Choose a piece |
| Q | Turn the piece (flips a wall's outer face, turns stairs and roofs) |
| ↑ / ↓ | Raise or lower the storey you are aiming at |
| X or middle click | Take down the piece you are aiming at |
| B or Esc | Close the build menu |

Outside build mode, **Tab** still opens your character sheet.

## The pieces

**Frame:** stone foundation, plank floor, flagstone floor, timber post, stone column, timber stairs, stone stairs, brazier, banner pole.

**Timber:** wall, window, doorway, door, railing, gable.

**Stone:** wall, arrow-slit wall, archway, iron-bound gate (Hearth tier 2), battlement, gable.

**Roofs:** thatch slope, ridge, peak and cap; slate slope, ridge, peak and spire.

Timber is cheap and has about a third of the health of stone. Doors and gates open for dwarves and stay shut to raiders. Braziers give light at night.

## Rules that keep a building standing

- **Foundations** go on level open ground. Castle room floors already count as a floor, so you can build straight onto them.
- **Walls and posts** stand on a foundation or floor, or on top of another wall or post.
- **Floors** rest on walls or posts and reach two tiles past their support.
- **Roofs** rest on wall tops, posts or a floor and reach three tiles.
- **Stairs** span two tiles and climb one storey. Leave the floor above the top tile open.
- **Gables** take the outline of the roof next to them automatically.

If you remove or lose the thing holding a piece up, everything that depended on it falls.

A pitched roof one tile wide is a ridge. Two tiles wide is two slopes back to back. Three tiles wide is slope, peak, slope.

## Taking things down

Aim at a piece in build mode and press **X**. It comes down at once and its materials drop on the ground: the full cost for an undamaged piece, less if it was damaged. Walk over the pile to put it in your pack, then deposit it as usual. Piles stay until collected and are saved with the expedition.

X also salvages a tower or other defense you are standing next to, under the existing salvage rules (daytime, no raiders nearby, half the cost back to the stockpile).

## Raiders and repairs

- Raiders who are walled out attack the piece in front of them. Brutes hit pieces about three times as hard as ordinary raiders, and sapper and bomber blasts damage every piece in range.
- A piece destroyed by raiders drops half its materials. Pieces that collapse with it drop all of theirs.
- Hold **R** next to a damaged piece to repair it: one wood for timber, one stone for stone, per swing.

## Castle rooms still work

The **K** castle planner, room services and upgrades are unchanged. If you place a castle room or a castle wall where pieces stand, those pieces are removed and refunded to the stockpile.

## How the art was made

All 35 piece models were built locally in Blender by `art_source/rig26/build_pieces.py`, using the same painted prop kit as the Fort 28 towers.

## Checked

- 97 automated checks of placement, support, collapse, pickups, damage, repair, doors, gables, saving and the menu (`tests/fort29_test.gd`).
- A four-player session covering late join, three clients racing for one slot, removal and pickup, damage and collapse (`tests/pieces_network_driver.gd`).
- In-engine renders of a demo hall, tower and curtain wall, the starter shell and the build menu.

## Known limits

- Pieces only snap to the grid: no diagonal walls, no half-height walls and no free rotation.
- Foundations need level ground, so you cannot build on the hills or into Hollowback Ridge.
- Roofs wider than three tiles need a floor or an inner wall line to carry the middle.
- Raiders do not plan routes around long piece walls the way they do for the older barricades. They walk toward the hearth and break whatever stops them.
- Flying raiders fly over walls. A floor or roof overhead does shelter a dwarf from them, as castle rooms do.
- Fire does not spread to pieces.
- Pieces have no upgrade levels and do not show cracks; health is shown only when you aim at one in build mode.
- Pieces are not drawn on the minimap or the Siege Watch repair list.
- The engineer's 25% discount applies to towers, not to pieces.
- The fort is limited to 1,600 pieces.
