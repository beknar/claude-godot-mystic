# maze-forest (Painted Lands Forest mazes)

`scenes/maze-forest/maze-forest.tscn`: hedge and canal mazes on the Painted
Lands Forest sheet (`TILESET_brighter.png`), with the Cozy Farm animals and
Cozy Cottage homes, and the same Esc menu as the randomizers (its picker
lists the 24 maze types; regenerate makes a new maze of the type). Starts at
map id 400000; map type = id % 24.

- Generator: `scripts/forest_maze.gd` (`ForestMaze`: the maze types, the
  algorithms, the walls, the clearings, the extras), laid into a
  `PaintedTerrain` with `maze` on (`forest_terrain.gd` hands its layout to
  it and runs the rest of the Painted Lands pipeline on the result: grass
  tones, dirt patches, deco, accents, the bushes, rocks, and trees round the
  edge, the liveliness floor, the checks).
- Painter: `scripts/forest.gd` with `maze` on (and `interiors`,
  `cozy_animals`): everything a Painted Lands map has, plus the maze walls'
  collision drawn to the hedge (below).

## How a maze is built

A grid of rooms. Each room is a corridor C cells wide; every wall is three
cells thick:

- **Hedges** are the sheet's 3x3 hedge blob (dark on plain lawn; the pale
  hedge on dark grass), autotiled with its inner corners, so every junction
  and every end draws. The sheet draws the hedge inside its tiles with a
  margin of grass (about 9 px), so a three-cell wall shows about two cells
  of hedge with a full row through its middle, and a one-cell corridor
  between two walls reads about two cells wide. **Canals** are the pond's
  water set the same way (open water down the middle row, fish rings and
  ripples there).
- **Collision follows the drawing**: each wall cell on a wall's edge blocks
  only the opaque part of its tile (forest.gd `_drawn_rect`), the cells
  inside a wall block whole. The walker walks right up to the hedge it sees.
- **Corridors**: 1 cell on the hedge mazes, 2 where the corridors are paved
  or bridged, 3 on the avenues. They are kept clear of trees, rocks, and
  hedgerows (`_taken`), but grass tones, flowers, sprouts, and the animals
  reach them.
- **The maze** (which walls come down): `backtrack` (a depth-first walk:
  long winding corridors), `prim` (randomized Prim: many short branches),
  `kruskal` (even), `sidewinder` (long east-west runs), `rings` (rings
  round the middle, one way through each ring, the rings broken once).
  Each is a spanning tree, so every room is reachable; `braid` opens a share
  of the dead ends into loops (on the canal mazes with bridges, most of
  those loops cross the water on a bridge instead).
- **Clearings**: rooms merged into one open space (walls and pillars inside
  come down): a cottage (a Cozy Cottage home, its door onto the clearing, a
  paved yard where two rows fit; the Cozy Farm animals live round it), a
  pond (the pond pipeline, lilies), a camp (campfire, log, ash, crates, a
  chest), a garden (flower carpets, a blossom tree, flowerpots), an old
  tree, a meadow (tall grass, flowers).
- **The way in and out**: a gap in the west wall (a random room) and one in
  the east wall (the room there farthest from the entrance by the maze),
  each with a road from the map's edge (through the gap where the corridor
  is two wide, up to the wall otherwise), lanterns either side, and a
  signpost (two different signs). On the moat maze the roads cross a moat
  three cells wide on bridges (docs/bridges.md).
- **Extras**: trees growing out of the hedges at pillars (their trunks
  inside the hedge, never over a clearing or a gate; the crowns fade when
  the walker is behind them, and shed leaves), flower carpets in dead ends,
  flowerpots, chests in dead ends (the treasure maze), lanterns on the
  hedge at junctions, single flowers along the corridors.
- **The liveliness floor**: in a maze, a weak camera window gets lanterns
  standing in the hedge beside a corridor (never in it), or a bed of flowers
  in a corridor; up to six anchors a map.
- Every room and the exit must be reachable from the entrance
  (`ForestMaze.unreached`): an attempt that fails is laid again.

## Map types (24)

| # | Map type | Walls | Maze | Corridor | Clearings | Extras |
|---|---|---|---|---|---|---|
| 0 | Hedge labyrinth | dark hedge | backtrack | 1 | | wall trees, flowers |
| 1 | Branching hedges | dark hedge | prim | 1 | | flowers, blooms, wall trees |
| 2 | Braided hedges | dark hedge | backtrack, braid 0.5 | 1 | | wall trees, flowers |
| 3 | Windswept hedges | dark hedge | sidewinder | 1 | | flowers, wall trees |
| 4 | Garden maze | dark hedge | kruskal | 1 | garden | flowers, pots, wall trees |
| 5 | Cottage maze | dark hedge | backtrack | 1 | cottage (hut) | pots, wall trees, flowers |
| 6 | Campfire maze | dark hedge | prim | 1 | camp | blooms, wall trees, flowers |
| 7 | Pond court | dark hedge | kruskal | 1 | pond | flowers, wall trees |
| 8 | Wide avenues | dark hedge | kruskal | 3, paved | | wall trees, lanterns, flowers |
| 9 | Path maze | dark hedge | backtrack | 2, paved | | pots, wall trees, flowers |
| 10 | Rings maze | dark hedge | rings | 1 | old tree | flowers, wall trees |
| 11 | Wooded maze | dark hedge | backtrack | 1 | | many wall trees, blooms, flowers |
| 12 | Treasure maze | dark hedge | prim | 1 | | chests, lanterns, wall trees, flowers |
| 13 | Twin cottages | dark hedge | kruskal | 1 | two cottages | pots, wall trees, flowers |
| 14 | Lantern maze | dark hedge | backtrack | 2, paved | camp | lanterns, wall trees, flowers |
| 15 | Shade maze | pale hedge, dark grass | backtrack | 1 | | blooms, wall trees, flowers |
| 16 | Firefly maze | pale hedge, dark grass | prim | 1 | old tree | blooms, wall trees |
| 17 | Moss garden | pale hedge, dark grass | kruskal, braid 0.4 | 1 | pond | flowers, wall trees |
| 18 | Canal maze | canals | backtrack | 1 | | flowers |
| 19 | Lily canals | canals | kruskal, braid over bridges | 2 | | bridges, flowers |
| 20 | Moat maze | dark hedge, moat round it | kruskal | 1 | garden | moat with bridges, pots, wall trees |
| 21 | Meadow maze | dark hedge | kruskal, braid 0.25 | 1 | three meadows | flowers, blooms, wall trees |
| 22 | Canal cottage | canals | prim | 2, paved | cottage | bridges, pots, flowers |
| 23 | Stone court | dark hedge | rings | 3, paved | camp | lanterns, pots, wall trees, flowers |

## Checks

`godot --headless -s res://tools/check_maze.gd -- [first_id] [count] [recipe]`:
each map's type, layout attempt, rooms, dead ends, clearings, homes,
bridges, and the Painted Lands checks, which for a maze add every maze cell
and the exit reachable from the entrance. 120 of 120 pass (400000-400095,
410000-410119), nearly all on the first attempt. `tools/walker_test.tscn --
maze` walks every type headless (0 snags; per map, medians of 82 dust
puffs, 766 grass and lawn flicks, 35.5 animal reactions); `tools/liveliness.gd
-- 400000 24 -1 pack maze` estimates its liveliness (scene 0.35%, weakest
window 0.19%).

Rendered at rest (`tools/liveliness_capture.tscn -- maze`, 12 types, 6 views
each, then `tools/liveliness_analyze.py watch .liveliness_maze`): local
motion median 0.25% (farm 0.40%, farmsteads 0.55%, caves 0.38%), weakest view
median 0.19%, 13% quiet blocks. Per type, the median view: hedge mazes
0.18-0.29% (the cottage mazes lowest), Pond court and Stone court about
0.40%, Moat maze 2.1%, Canal maze 5.8% (the water). No view is still.

## Reject list

A hedge that blocks where it is not drawn (or is drawn where it does not
block); a room the walker cannot reach; an entrance or exit without its
road, lanterns, and sign; a tree whose crown hides a clearing or a gate; a
lantern, chest, or prop standing in a one-cell corridor; a straight wall of
one fill with no tone, flower, or tree anywhere in view.
