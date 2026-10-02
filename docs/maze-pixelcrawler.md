# maze-pixelcrawler (Pixel Crawler mazes)

`scenes/maze-pixelcrawler/maze-pixelcrawler.tscn`: mazes on Anokolisa's
Pixel Crawler sheets, one biome per map (never mixed), with the same Esc
menu as the randomizers (its picker lists the 23 maze types; regenerate
makes a new maze of the type). Starts at map id 460000 (Fairy hedge maze);
map type = id % 23. Read `docs/pixel-crawler.md` first: the sheets, the
corner tables, the per-pixel water, the splat, the painter.

- Generator: `scripts/pc_maze.gd` (`PCMaze`: the maze types, the wall kits,
  the algorithms, the clearings, the extras), laid into a `PCTerrain` with
  `maze` on (`pc_terrain.gd` `_maze_layout`: the maze, then the repair, the
  trees and scatter in the antechambers, the liveliness floor, the splat).
- Painter: `scripts/pixelcrawler.gd` with `maze` on: the kit walls on the
  cliff layer, the lava and slime animated on the water layer, the prop
  walls nudged half a cell low and colliding where drawn
  (`maze_info.boxes`), and the indoor biomes' ambience.
- Two indoor biomes join the four outdoor ones (`PCTerrain.BIOMES`
  `indoor`): **Forge** (`assets/pack/pixel_crawler/forge/Tiles.png`) and
  **Sewer** (`sewer/Tiles.png`, `sewer/Props.png`), copied from the
  collection (`Pixel Crawler - Forge`, `Pixel Crawler - Sewer`; the Dungeon
  Prison sheets from `Pixel Crawler - FREE` are copied to `prison/` but not
  used: its walls are one cell thin with capsule rims and the sheet has no
  plus-shaped sample to read them from). Each is one floor (its own fills
  in `PCTiles.WANG`), no splat, no clouds, streaks, grass waves, or
  drifters; bats and drips from the faces (CaveLife), the lava's warm glow,
  the sewer lamps' light.

## How a maze is built

A grid of rooms; the walls between them by kind:

- **Kit walls** (Forge, the Cemetery's crypt): the sheet's wall mass read
  from its plus-shaped sample (`PCMaze.KITS`): outer corners, edges, the
  middle, and all four inner corners, the black top two cells wide, and the
  faces under every bottom edge (two rows on the Forge: bricks, then the
  sill; three on the crypt), left end, middle, right end. A band runs
  across the top of the map and the bottom; the maze stands between two
  antechambers. Corridors two cells wide. Tops and faces block.
- **Canals** (Fairy Forest, the Farm forest): water two cells wide, drawn per
  pixel by the painter as the pack's ponds are (open water, the two shore
  blues, the dark bank); the braids cross on stepping stones.
- **Channels** (the Forge's lava, the Sewer's slime): the sheet's animated
  blob (a 3 x 3 rimmed pool and its four inner corners, four frames three
  rows apart, `PCMaze.POOLS`), two cells wide, each cell's tile by which of
  its eight neighbours are floor; the sewer's braids cross on its plank
  bridges (the across and the along plank, centred on the channel).
- **Prop walls** (bushes in the Fairy Forest and the Farm forest, cacti or
  rocks in the desert): one prop on every cell of the wall's middle line,
  drawn half a cell low so it sits centred, the wall three cells (a half,
  the middle, a half) colliding where drawn; the ground under them stays the
  root (desert props stand on light sand only). Corridors one cell wide.
- **The maze**: `backtrack`, `prim`, `kruskal`, `sidewinder`, `rings`,
  spanning trees; `braid` opens a share of the dead ends into loops.
- **Clearings**: glowbells, mushrooms, a runestone ring (glowing stones and
  bells, never closed), a camp (crates, barrels, a log), crystals, graves in
  rows, dead wood, tusks and bones, statues, a vault (chests, racks,
  barrels), a lava pool, a sewer store (crates, a chest, lamps).
- **The way in and out**: a gap in the west wall and one in the east (the
  room there farthest from the entrance), marked either side outside the
  wall: glowing runestones (fairy), crates and barrels (Farm forest), grave
  crosses (cemetery), tusks (desert), statues (forge), lamps (sewer); the
  approach kept clear of trees.
- **Extras**: the biome's small bits along the corridors (sprouts, pebbles,
  mushrooms, flowers, leaves, tufts, rubble, bottles), flowers, small
  glowbells (fairy), lamps (sewer), reeds and tufts (desert), and in the
  dead ends what blocks (a big glowbell, a runestone, rocks, stumps, graves,
  cacti, desert bushes, barrels, crates). In the Forge's walled halls up to
  six dead ends fill with lava (the sheet's 2 x 2 pool, glowing; never a
  gate's room).
- **Motion**: the tops of bushes, plants, flowers, and bells sway downwind
  (the hedge walls too; `pixelcrawler.gd` splits each into a still bottom
  and a nodding top, water_life.gd's reed nod); bats fly in the Forge, the
  Sewer, and the crypts; drips fall from the kit faces; fireflies drift three
  times as thick over a crypt maze's dark corridors; the lava and slime
  animate and the lava glows.
- **The animals**: the drawn ones, as on the Pixel Crawler randomizer
  (`wildlife_plan`, no Cozy Farm: its outline-less art does not sit with
  Pixel Crawler's heavy outlines, and the dungeons have no place for farm
  animals).
- **The liveliness floor** (the Painted Lands frozen weights, 0.09 %): lava
  and slime count as water; a weak window gets glowbells (fairy) or lamps
  (sewer) along its corridors, else fireflies; up to twelve anchors.
- Every maze cell and the exit must be reachable from the entrance
  (`PCMaze.unreached`): an attempt that fails is laid again.

## Map types (23)

| # | Map type | Biome | Walls | Maze | Clearings |
|---|---|---|---|---|---|
| 0 | Fairy hedge maze | fairy | bushes | backtrack | glowbells |
| 1 | Glowbell hedges | fairy | rust and green bushes | prim | glowbells, mushrooms |
| 2 | Fairy canals | fairy | canals, stepping stones | kruskal, braid 0.3 | |
| 3 | Runestone hedges | fairy | bushes | rings | runestone ring |
| 4 | Mushroom hollow maze | fairy | bushes | kruskal | two mushroom glades |
| 5 | Greenwood hedges | Farm forest | Green Woods bushes | backtrack | |
| 6 | Forest canals | Farm forest | canals, stepping stones | prim | |
| 7 | Woodcutter's maze | Farm forest | bushes | kruskal | camp |
| 8 | Crystal hedges | Farm forest | bushes | sidewinder | crystals |
| 9 | Crypt maze | cemetery | crypt walls | backtrack | graves |
| 10 | Catacombs | cemetery | crypt walls | prim | |
| 11 | Crypt rings | cemetery | crypt walls | rings | graves |
| 12 | Haunted crypts | cemetery | crypt walls | kruskal, braid 0.3 | dead wood |
| 13 | Cactus maze | desert | cacti | backtrack | |
| 14 | Rock maze | desert | rocks | kruskal | bones |
| 15 | Bone canyon | desert | rocks and cacti | prim | bones |
| 16 | Forge halls | forge | forge walls | backtrack | lava pool |
| 17 | Lava channels | forge | lava | kruskal, braid 0.3 | |
| 18 | Foundry maze | forge | forge walls | prim | statues, lava pool |
| 19 | Forge rings | forge | forge walls | rings | vault |
| 20 | Slime canals | sewer | slime | backtrack | |
| 21 | Sewer junctions | sewer | slime, plank bridges | kruskal, braid 0.35 | |
| 22 | Overflow tunnels | sewer | slime (wide), plank bridges | prim | store |

## Checks

`godot --headless -s res://tools/check_maze_pc.gd -- [first_id] [count] [recipe]`:
each map's type, biome, layout attempt, rooms, dead ends, clearings, wall
and channel tiles, stones, props, floor notes, and the checks (every cell
tiled, every maze cell and the exit reachable from the entrance). 115 of
115 pass (460000-460114, every type five times), all on the first layout
attempt; every map reaches the floor (lowest 0.093 %). The Pixel Crawler
randomizer still passes (34 of 34). `tools/walker_test.tscn -- pc maze`
walks every type (headless, or rendered into `.liveliness_walk_maze_pc`):
0 snags on all 23 (per map, medians of 1076 dust puffs and 27 animal
reactions), once the colliders agreed with the walk grid (see
`docs/pixel-crawler.md`; the first run snagged 82 times in the
antechambers, on rocks, crates, and trees whose colliders reached a cell
the grid thought open);
`tools/liveliness_capture.tscn -- pc maze` films twelve types of all six
biomes at rest into `.liveliness_maze_pc`.

Rendered at rest (12 types of all six biomes, 6 views each): local motion
median 0.155 % (the Pixel Crawler randomizer 0.140 %), weakest view median
0.092 %, 6 % quiet blocks; walking, 0.37 % and 0.138 %, 0 snags. Per type,
the median view at rest: the fairy hedges 0.56 % (swaying bushes, bells),
the Green Woods hedges 0.21 %, the canals 0.10-0.15 %, the Forge's halls
0.14-0.15 % (lava dead ends), the lava channels 2.6 %, the slime 1.1 %;
quietest the crypts (0.08 %) and the cactus maze (0.06 %), as quiet as the
randomizer's own quietest views (0.04 %). Before the swaying tops, the lava
dead ends, the crypt bats, and the desert reeds the median was 0.103 % with
31 % quiet blocks. There is no fast estimate for
Pixel Crawler maps (`tools/liveliness.gd` has no calibrated features for
this pack); the generator's own floor estimate stands in for it.

## Reject list

A wall that blocks where it is not drawn; a kit wall with a missing rim or
a face hanging into a corridor; a channel cell with no tile; a prop wall
with gaps; a room the walker cannot reach; a gate without its markers; a
prop that blocks in a corridor; two biomes on one map; art from any other
pack.
