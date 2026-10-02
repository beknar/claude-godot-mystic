# maze-greencaves (Painted Lands Green Caves mazes)

`scenes/maze-greencaves/maze-greencaves.tscn`: rock mazes on the Green Caves
sheet (`assets/pack/green_caves/green_caves_tileset.png`), with cave homes
(Cozy Cottage interiors) and the Cozy Farm animals, and the same Esc menu as
the randomizers (its picker lists the 24 maze types; regenerate makes a new
maze of the type). Starts at map id 440016 (Rock labyrinth); map type =
id % 24. Read `docs/green-caves.md` first: the sheet's systems, the pools,
the homes, the ambience.

- Generator: `scripts/cave_maze.gd` (`CaveMaze`: the maze types, the
  algorithms, the walls, the clearings, the extras), laid into a
  `CaveTerrain` with `maze` on (`cave_terrain.gd` `_maze_build` hands it the
  layout, then runs the rest of the cave pipeline on the result: dark zones,
  floor patches, floor, the scatter in the antechambers, the liveliness
  floor, the checks). Pools and homes go through the cave's own placers
  (`_pool_at`, `_home_at`).
- Painter: `scripts/caves.gd` with `maze` on: everything a cave map has
  (walls and faces collide by kind, as always).

## How a maze is built

A grid of rooms, each a corridor two cells wide (three on the wide types).
The walls are the sheet's wall mass, two cells wide:

- A **horizontal wall** is two rows of black top (rim all round) over the
  two rows of rock face the sheet hangs under every bottom edge: a band of
  four rows between two rows of rooms. Plain middles get the face variants
  (mossy faces on the moss types, skull faces on the ossuary).
- A **vertical wall** is two columns of top, the sheet's left and right edge
  columns `(9-10, 12-14)`, from the band above down to the band below.
- Where a vertical wall drops from a horizontal one, the sheet's inner
  corners `(9, 11)` and `(10, 11)` turn the rim down beside it and the
  faces either side meet its edge; a pillar left standing alone ends in the
  sheet's rounded end `(12-13, 12-14)`. (The sheet has no inner corner for a
  wall rising from a band's top; there the rims meet at the cell corner.)
- The top band runs the map's width (the cave's back wall), and so does the
  bottom one; the maze stands between two **antechambers** of open floor
  (rocks, crystals, cones, plants, the cave's own scatter).
- **The maze**: `backtrack`, `prim`, `kruskal`, `sidewinder`, `rings`, each
  a spanning tree; `braid` opens a share of the dead ends into loops.
- **Clearings**: rooms merged into one hall, a lane kept round what stands
  in it: a **pool** (the cave's pool with its stone ring and dark halo,
  stalagmites and weed, sparkles), a **lake** (deep water), a **home**
  (a cave home of one room, built into the hall's top: rock outside, the
  Cozy Cottage room inside, the arched doorway facing south, its hearth and
  lamps glowing), a **camp** (campfire, branch, crates, embers), a **crystal
  ring** round a crystal rock tree, **cones**, a **shrine** (pillars,
  crystals, an open chest), a **mine** (cart, coal, crates), **coal**,
  **bones**, a **vault** (chests, pillars, violet crystals), a **cache**,
  a **grove** (a mossy tree, plants, tufts).
- **The way in and out**: a gap in the west wall (a random room) and one in
  the east wall (the room there farthest from the entrance), each lit by a
  pair of torches on the face over it, a signpost in the antechamber. On the
  mine types a **rail track** runs the way through, from the west edge
  through every room on the solution to the east edge, curving at the turns.
- **Extras**: wall torches on the faces over the corridors (spaced apart);
  small bits along the corridors that block nothing (cones, shards, coal,
  skulls, plants, grass, tufts on moss); in the dead ends what does block
  (chests, ore, crystals, cones, crates and barrels, carts and coal, a mossy
  tree).
- **The animals**: the cave's drawn ones (mice by clutter and bones, lizards
  by rocks and ore, frogs on the banks, voles on moss) and, the Cozy Farm
  animals where they belong: bunnies on the moss floors, and poultry, pigs,
  sheep, goats, or cows in the yard and on the moss round each home's arch.
- **The liveliness floor** (the cave floor, 0.2 % per camera window): a weak
  window gets a campfire in one of its dead ends, else a pair of wall
  torches on its faces, else a campfire in the corner of one of its rooms,
  else torches closer together; up to twelve anchors.
- Every maze cell, the exit, and every home's entry room must be reachable
  from the entrance (`CaveMaze.unreached`): an attempt that fails is laid
  again.

## Map types (24)

| # | Map type | Floor | Maze | Corridor | Clearings | Extras |
|---|---|---|---|---|---|---|
| 0 | Rock labyrinth | light | backtrack | 2 | | torches, cones |
| 1 | Branching tunnels | light | prim | 2 | pool | torches, cones, plants |
| 2 | Looping caverns | light | kruskal, braid 0.45 | 2 | camp | torches, cones |
| 3 | Crystal maze | light | kruskal | 2 | crystal ring | crystals, torches |
| 4 | Stalagmite maze | light | sidewinder | 2 | cones | cones, torches |
| 5 | Spring maze | light | prim | 2 | two pools | plants, torches |
| 6 | Flooded maze | light | kruskal | 3 | lake | cones, plants, torches |
| 7 | Echo halls | light | backtrack | 3 | | crystals, cones, torches |
| 8 | Pillared maze | light | rings | 2 | shrine | crystals, torches |
| 9 | Cave hamlet maze | light | kruskal | 2 | two homes | clutter, torches |
| 10 | Mine maze | dark | backtrack | 2 | mine | rails, ore, carts, torches |
| 11 | Rail tunnels | dark | kruskal, braid 0.2 | 2 | coal | rails, carts, torches |
| 12 | Ossuary maze | dark, skull faces | backtrack | 2 | bones | bones, torches |
| 13 | Treasure vault maze | dark | prim | 2 | vault | chests, crystals, torches |
| 14 | Smugglers' maze | dark | kruskal | 2 | home, cache | clutter, torches |
| 15 | Ore vein maze | dark | sidewinder | 2 | | ore, crystals, torches |
| 16 | Dark depths maze | dark | kruskal, braid 0.3 | 3 | pool | cones, torches |
| 17 | Root cellar maze | dark | backtrack | 2 | home | clutter, torches |
| 18 | Mossy labyrinth | moss, mossy faces | backtrack | 2 | | tufts, plants, torches |
| 19 | Overgrown mine maze | moss, mossy faces | kruskal | 2 | grove | rails, tufts, plants, ore |
| 20 | Sunken garden maze | moss, mossy faces | prim, braid 0.2 | 2 | grove, pool | tufts, plants |
| 21 | Hermit's maze | moss | kruskal | 2 | home, camp | tufts, plants, torches |
| 22 | Fern hollows | moss, mossy faces | sidewinder | 3 | two groves | tufts, plants |
| 23 | Moss rings | moss, mossy faces | rings | 2 | pool | tufts, plants, torches |

## Checks

`godot --headless -s res://tools/check_maze_caves.gd -- [first_id] [count] [recipe]`:
each map's type, floor, layout attempt, rooms, dead ends, clearings, homes,
pools, rails, props, fires, floor notes, and the cave checks, which for a
maze add every maze cell reachable from the entrance. 120 of 120 pass
(440000-440119, every type five times), 96 on the first layout attempt;
every map reaches the cave floor (0.2 %). `tools/walker_test.tscn -- caves
maze` walks every type (headless, or rendered into
`.liveliness_walk_maze_caves`): 0 snags on all 24 (per map, medians of 862
dust puffs and 19.5 animal reactions; the Cozy Farm animals reacting on the
nine maps with moss floors or homes); `tools/liveliness.gd -- 440016 24 -1 caves
maze` estimates the liveliness (scene median 0.42 %, weakest window median
0.29 %, worst 0.23 %; the Green Caves randomizer 0.39 %, 0.33 %, 0.20 %);
`tools/liveliness_capture.tscn -- caves maze` films twelve types at rest
into `.liveliness_maze_caves` (`liveliness_analyze.py watch`).

Rendered at rest (12 types of all three floors, 6 views each): local motion
median 0.51 % (the Green Caves randomizer 0.38 %), weakest view median
0.33 % (0.23 %), 41 % quiet blocks (65 %); per type, the median view 0.30 %
(the rock labyrinth) to 0.68 % (the hermit's maze, its campfire and home).
Rendered walking (the same twelve, the walker's route through every view):
0 snags, local motion median 0.50 %, weakest view median 0.32 %.

## Reject list

A wall top with no rim where it meets the floor (but the corner noted
above); a face hanging into a corridor; a wall that blocks where it is not
drawn; a room the walker cannot reach; a pool without its ring and halo; an
entrance or exit without its torches and signpost; a prop that blocks in a
corridor (only the dead ends and the clearings hold what blocks); a rail
that breaks or ends short of the map's edge; a home whose arch does not open
onto the hall; Painted Lands Forest or Farm art in a cave.
