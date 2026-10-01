# maze-farm (Painted Lands Farm mazes)

`scenes/maze-farm/maze-farm.tscn`: mazes on antarcticbees' Farm - 4 Seasons
sheets (one season per map, never mixed), with the Cozy Farm animals and the
farm's buildings and interiors, and the same Esc menu as the randomizers (its
picker lists the 30 maze types; regenerate makes a new maze of the type).
Starts at map id 420000; map type = id % 30. Read `docs/farm.md` first: the
sheets, the ground's corner table, the water blocks, the painter.

- Generator: `scripts/farm_maze.gd` (`FarmMaze`: the maze types, the
  algorithms, the walls, the clearings, the extras), laid into a
  `FarmTerrain` with `maze` on (`farm_terrain.gd` `_maze_layout` hands it the
  layout, then runs the rest of the farm pipeline on the result: tone zones,
  repair, the trees and scatter round the edge, deco, the liveliness floor,
  the checks).
- Painter: `scripts/farm.gd` with `maze` on: everything a farm map has, plus
  the soft walls' collision where they are drawn (`maze_info.boxes`) and the
  wall bushes drawn half a cell low (a prop's `nudge`).

## How a maze is built

A grid of rooms, each a corridor C cells wide. The walls between them:

- **Overlays** (hedge, green or autumn brown; golden wheat; tall green grass):
  three cells thick round a middle line, the core. The sheet's overlay is a
  corner table with all sixteen mixes, its edge running down the middle of a
  cell (an edge tile is opaque from x = 7), so the core's corners draw one
  full cell of hedge with a half cell either side: a wall about two cells
  wide, a one-cell corridor about two wide.
- **Crops** (corn, sunflowers): a row of the ripe crop on the core cells, on
  dirt (the corner table's `e`, its edge on the half cells). The stalks nod
  in the wind and bend away from the walker in the corridor beside them.
- **Bushes** (summer shrubs; winter's snowy bush or pine bush): a bush on
  every core cell, drawn half a cell low (`nudge`) so it sits centred on the
  wall; they overlap into one hedge.
- **Canals**: two cells of water, laid on the sheet's 2 x 2 water blocks
  (the maze's origin and corridors even), so every shore cell has its tile
  (no one-cell channel, no corner-only join); corridors two cells wide.
- **Collision follows the drawing**: a core cell blocks whole; a half cell
  blocks the quarters whose corner is on the core; a crop wall only its row;
  water as the farm's water. Every wall cell is out of the walk grid, so the
  walker's routes and the animals keep to the corridors.
- **The maze**: `backtrack` (long winding corridors), `prim` (many short
  branches), `kruskal` (even), `sidewinder` (long east-west runs), `rings`
  (rings round the middle, broken once each, one door inward). Each is a
  spanning tree; `braid` opens a share of the dead ends into loops (on the
  canals with bridges, three in four of those loops cross the water on a
  bridge, docs/bridges.md, in the farm's or the snowy set).
- **Clearings**: rooms merged into one open space, a lane kept round what
  stands in it so every corridor into it still joins: a **building** at its
  top facing south (farmhouse, barn, windmill, greenhouse; its doorstep and a
  little yard on the clearing floor, its interior behind the door as on the
  farm maps), a **pen** with a gate and a trough (a herd in every pen), a
  **pond** of water blocks (reeds on the bank), a **crop patch** (bordered
  plots, one crop, walked through), an **orchard** of fruit trees, **hay**
  (bales, a crate, wheat bunches), a **scarecrow** with hay, a **meadow**
  (flowers).
- **The way in and out**: a gap in the west wall (a random room) and one in
  the east wall (the room there farthest from the entrance), each with a
  road of dirt or sand from the map's edge (through the gap on soft walls; up
  to the bank on the canals), barrels or a hay crate either side, and a
  signpost (two different signs); no tree stands where its crown would hide
  a gate. On the moated farmhouse the roads cross a moat four cells wide (open
  water down its middle, fish) on bridges.
- **Extras**: trees growing out of the hedges at pillars (fruit trees on the
  orchard maze, snowy pines on the pine maze; never over a clearing or a
  gate, their crowns fading when the walker is behind them), scarecrows on
  the pillars of the crop and wheat mazes, flower carpets in dead ends and
  single flowers along the corridors, flowerpots, barrels, buckets, boxes,
  and chests in dead ends, wheat bunches, reeds and cattails along the
  canals.
- **The animals**: the Cozy Farm table (`farmland`): poultry and pigs in the
  yard round a door, sheep, goats, and cows in the pens; a maze with no home
  or pen has its flock grazing the grass corridors and its poultry by the
  clearings; bunnies and the drawn small animals throughout.
- **The liveliness floor**: a weak camera window gets a tree out of a hedge
  pillar in it (or in place of a wall bush), else flowers along its
  corridors, else fireflies (not in the snow); up to eight anchors a map.
- Every maze cell, door, gate, and the exit must be reachable from the
  entrance (`FarmMaze.unreached`): an attempt that fails is laid again.

## Map types (30)

| # | Map type | Season | Walls | Maze | Clearings | Extras |
|---|---|---|---|---|---|---|
| 0 | Hedgerow maze | summer | hedge | backtrack | | wall trees, flowers |
| 1 | Branching hedgerows | summer | hedge | prim | pond | flowers, wall trees, reeds |
| 2 | Looping hedges | summer | hedge | kruskal, braid 0.45 | hay | wall trees, pots, flowers |
| 3 | Farmhouse maze | summer | hedge | backtrack | farmhouse | wall trees, pots, flowers |
| 4 | Windmill in the wheat | summer | wheat | prim | windmill | wheat bunches, flowers |
| 5 | Wheat maze | summer | wheat | backtrack | hay | wheat bunches, scarecrows, flowers |
| 6 | Golden rings | summer | wheat | rings | pumpkin patch | wheat bunches, flowers |
| 7 | Corn maze | summer | corn | backtrack | scarecrow | scarecrows, flowers |
| 8 | Maize loops | summer | corn | kruskal, braid 0.3 | pumpkin patch | scarecrows, wheat bunches |
| 9 | Sunflower maze | summer | sunflowers | prim | hay | flowers, wheat bunches |
| 10 | Meadow grass maze | summer | tall grass | sidewinder | two meadows | flowers |
| 11 | Barnyard maze | summer | hedge | kruskal | barn, pen | wall trees, clutter |
| 12 | Pasture maze | summer | hedge | kruskal, braid 0.3 | two pens | wall trees, flowers |
| 13 | Orchard maze | summer | hedge | backtrack | orchard | fruit trees, flowers |
| 14 | Kitchen garden maze | summer | hedge | prim | cabbage and carrot patches | pots, flowers, wall trees |
| 15 | Greenhouse maze | summer | hedge, sand paths | rings | greenhouse | pots, wall trees |
| 16 | Canal maze | summer | canals | backtrack | | reeds, flowers |
| 17 | Bridge canals | summer | canals | kruskal, braid 0.4 over bridges | | bridges, reeds, flowers |
| 18 | Mill canals | summer | canals | prim | windmill | bridges, reeds |
| 19 | Moated farmhouse | summer | hedge in a moat | kruskal | farmhouse | moat with bridges, wall trees, pots |
| 20 | Shrub maze | summer | bushes | backtrack | pond | flowers, reeds |
| 21 | Autumn hedgerows | autumn | hedge (brown) | backtrack | | many wall trees, flowers |
| 22 | Autumn sunflowers | autumn | sunflowers | prim | hay | wheat bunches, scarecrows |
| 23 | Harvest corn maze | autumn | corn | kruskal, braid 0.2 | pumpkin patch | scarecrows, wheat bunches |
| 24 | Autumn homestead maze | autumn | hedge (brown) | kruskal | farmhouse, pen | wall trees, clutter |
| 25 | Russet canals | autumn | canals | kruskal, braid 0.35 over bridges | barn | bridges, reeds |
| 26 | Frozen canals | winter | canals | backtrack | | reeds |
| 27 | Snowbush maze | winter | snowy bushes | kruskal | farmhouse | snowy wall trees, clutter |
| 28 | Pine hedge maze | winter | pine bushes | prim | pen | pines out of the hedge |
| 29 | Frozen mill canals | winter | canals | kruskal, braid 0.3 over bridges | windmill | bridges |

Winter has no overlays or crops on its sheet, so its mazes are canals and
bushes. The pale overlays need dark grass under them to read: the meadow
grass maze leans to the dark tone, the autumn hedges to the pale one; autumn
straw walls were tried and dropped (the straw matches the autumn lawn, and
the tone field cannot darken enough of it).

## Checks

`godot --headless -s res://tools/check_maze_farm.gd -- [first_id] [count] [recipe]`:
each map's type, season, layout attempt, rooms, dead ends, clearings,
buildings, pens, bridges, trees, crops, props, floor notes, and the farm
checks, which for a maze add every maze cell reachable from the entrance.
120 of 120 pass (420000-420119, every type four times), all on the first
layout attempt. `tools/walker_test.tscn -- farm maze` walks every type
(headless, or rendered into `.liveliness_walk_maze_farm`): 0 snags on all
30, the Cozy Farm farm animals reacting on every one (per map, medians of
78 dust puffs, 733 grass and lawn flicks, 50.5 animal reactions).
`tools/liveliness.gd -- 420000 30 -1 farm maze` estimates the liveliness
(scene median 0.31 %, weakest window median 0.18 %, worst 0.08 %; the farm
randomizer 0.43 %, 0.24 %, 0.02 %; the canal mazes about 7 % with their
water);
`tools/liveliness_capture.tscn -- farm maze` films twelve types at rest into
`.liveliness_maze_farm` (`liveliness_analyze.py watch`).

Rendered at rest (12 types of all three seasons, 6 views each): local motion
median 0.41 % (the farm randomizer 0.40 %, the farmsteads 0.55 %, the Forest
mazes 0.25 %), weakest view median 0.31 %, 5 % quiet blocks; no view is
still. Per type, the median view: the hedge mazes 0.27-0.43 % (the autumn
ones lowest), the windmill in the wheat 0.54 %, the corn maze 0.69 % (the
stalks nod), the snowbush maze 0.48 % (the snow), the canals and the moat
about 1.4 % (the water).

Rendered walking (`tools/walker_test.tscn -- farm maze` on the same twelve
maps, the walker's route through every view): 0 snags; local motion median
0.52 % (the farm randomizer 0.51 %, the farmsteads 0.71 %), weakest view
median 0.35 %, 4 % quiet blocks.

## Reject list

A wall that blocks where it is not drawn (or is drawn where it does not
block); bushes with gaps between them; a room the walker cannot reach; a
shore cell with no tile or a one-cell channel; an entrance or exit without
its road, barrels, and sign, or hidden under a crown; a tree whose crown
hides a clearing's building or a gate; a prop standing in a one-cell
corridor; a pen with no herd; a crop floating off its dirt or plot; Forest
art on a farm maze, or two seasons on one map.
