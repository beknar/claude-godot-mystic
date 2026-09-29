## Which pack (read this first)

This repo has four map languages. Do not mix their pipelines, sheets,
or “done” checks.

| Maps | Pack | Code | Rules in this file |
|---|---|---|---|
| clearing, grove, hollow, ford, heath | Mystic Woods: `plains.png`, `grass.png` under `assets/pack/` | `scripts/terrain.gd`, `scripts/clearing.gd` | § Mystic Woods |
| forest | Painted Lands: `assets/pack/TILESET_brighter.png` | `scripts/forest_terrain.gd` | § Painted Lands |
| randomizer-greencaves | Green Caves: `assets/pack/green_caves/green_caves_tileset.png` | `scripts/cave_terrain.gd`, `scripts/caves.gd` | § Green Caves |
| randomizer-timefantasy (experimental; the pack is not suitable for new maps) | Time Fantasy: `assets/pack/time_fantasy/` (terrain, outside, water, house, animated) | `scripts/tf_terrain.gd`, `scripts/timefantasy.gd` | § Time Fantasy |

`docs/scene-assembly.md` §0–5 is shared inventory. §6 is Painted Lands
only (20-recipe forest generator). Mystic Woods generation stays under
§ Mystic Woods.

Heath and forest both use seed `91003` on the current scenes. That is
coincidence. Heath still runs the Mystic Woods pipeline with
`include_water` false. Forest never calls `terrain.gd`.

## Scene assembly (backgrounds + playing field)

Doctrine: assemble from the pack for that map. Do not invent a new
art style or generate a full painted backdrop unless that pack is
missing a tile.

Source of truth:
- Pack root: `assets/pack/`
- Manifest: `docs/art-pack.md` and `assets/pack/tileset.json` (if present)
- Procedure: `docs/scene-assembly.md`
- Skills: `game-asset-core`, `game-tilesets` (seam checks). Maps: `generate2dmap`.

Hard rules (both packs)
1. Read the pack for *this* scene before drawing. List tile size, grid,
   camera, palette, and layer names.
2. All world art snaps to that pack’s tile size (16px here). No
   free-placed bitmaps that ignore the grid.
3. Playing field = tilemap layers, not one flattened JPEG:
   ground → terrain transitions → props/deco → collision/occluders →
   actors/UI (code, not baked into tiles).
4. Match that pack: pixel density, outline weight, lighting, saturation.
   If a generated tile fights the pack, discard it and reuse pack tiles.
5. Never generate a unique “hero rock” as a repeating ground tile.
   Distinctive motifs belong on the prop layer once.
6. New tiles only when *that* pack lacks a terrain or transition.
   Generate at exact cell size, then verify a 3×3 PIL composite
   (`game-tilesets`). Painted Lands dirt caps, edges, knuckles, houses,
   patches, bushes, rocks, signs, and fires already exist — do not
   generate replacements for those cells.
7. Collision comes from a layer or tile flags, not from guessing
   opaque pixels on the background.
8. Characters and UI stay separate sprites. Do not paint them into
   the background.

Done means: map loads on-grid, that pack’s tiles dominate the screen,
collision matches walkable ground, and a screenshot sits next to a
strip from the same pack.

## What this project can do

Godot 4.6, GL Compatibility. Window 3440×1440, camera zoom 5, nearest
filtering, so each 16px tile is 80 screen pixels.

Player (`scripts/player.gd`, `player.png`, 48×48, 6 columns):

- Eight-direction movement at 80 px/s. `Input.get_vector` normalizes
  diagonals. `CharacterBody2D` motion mode is floating.
- Four facings. Any horizontal input, including a diagonal, plays the
  side row. Pure up plays the back. Pure down plays the face. Left is
  `flip_h` on the side row. Idle is always row 0, facing the camera.
  Stored facing stays put while idle, and the swing uses that facing.
- Space plays attack rows 6–8 and locks movement until the clip ends.
  Only columns 0–3 of those rows have art. Columns 4 and 5 are blank
  and must not be played. The hitbox is on during frames 2 and 3,
  layer `hitbox`, mask `hurtbox`. Nothing occupies `hurtbox` yet.
- Feet sit on frame row 42. Sprite offset puts that row on the body
  origin so y-sort and the collision box share the feet.

Physics layers, in order: `world`, `player`, `enemy`, `hurtbox`, `hitbox`.
The player is on `player` and collides with `world`.

Mystic Woods maps (pipeline: § Mystic Woods):

- `scenes/clearing/clearing.tscn` — seed `21021`, `player.png`
- `scenes/grove/grove.tscn` — seed `90511`, `assets/ai/characters/wanderer.png`
- `scenes/hollow/hollow.tscn` — seed `44107`, `assets/ai/characters/scout.png`
- `scenes/ford/ford.tscn` — seed `12809`, `assets/ai/characters/warrior-16x16-sheet.png`
  (6×10 of 16×16, same row order as `player.png`; `frame_size` 16)
- `scenes/heath/heath.tscn` — seed `91003`, `include_water` false,
  `assets/ai/characters/red-fighter-16x16.png`. Heath does not control
  a character. `Lineup` places all five Mystic Woods sheets 72px apart
  on one foot line.

Painted Lands map (pipeline: § Painted Lands):

- `scenes/forest/forest.tscn` — current seed `91003` (not the heath
  generator), `assets/pack/TILESET_brighter.png`.
  `assets/pack/character_sprite_sheet.png` is 6×4 frames of 16×32 (two
  tiles tall, feet on frame row 31). Rows face right, left (row 0
  mirrored), down, up. Columns 3–5 repeat 0–2 with a ground shadow;
  idle is column 3, walk is 3, 4, 3, 5. No attack row. Movement is
  still eight-direction.
  The scene pins recipe 3 (`recipe = 3`). New seeds use
  `recipe = seed % 30` from the table below.
- `scenes/wilds/wilds.tscn` — map id `75125`, recipe 5 Open meadow
  (pinned: `recipe = 5`).
  No house. A straight cobble road runs from edge to edge. Round dirt
  blobs, bushes, and land rocks. No pond and no signs.
- `scenes/randomizer-paintedlands/randomizer-paintedlands.tscn` — the wilds
  settings (starts at map id `75125`) plus an Esc menu that regenerates from a
  random new id with the same generator. Any of the 30 recipes can come up, or
  be pinned. Its first map is pinned to recipe 5.

Mystic Woods randomizer:

- `scenes/randomizer-mysticwoods/randomizer-mysticwoods.tscn` — the Mystic
  Woods pipeline (`terrain.gd` + `clearing.gd`, `player.png`), starting at the
  clearing's seed `21021` (`recipe = -1`: seed % 16, `enrich = true`), with the
  same Esc menu (`randomizer_menu.gd`): it shows the map id, recipe, and checks,
  regenerates from a random new seed, and can pin any of the 16 Mystic Woods
  recipes. The
  menu works with any map script that has `build(id)`, `map_summary()`, and
  `recipe_names()`.

Green Caves randomizer:

- `scenes/randomizer-greencaves/randomizer-greencaves.tscn` — the Green Caves
  pipeline (`cave_terrain.gd` + `caves.gd`), starting at map id `130021`
  (`recipe = -1`: id % 30), with the Painted Lands walker
  (`scenes/forest/walker.tscn`) and the same Esc menu, titled
  "Green Caves randomizer".

Time Fantasy randomizer:

- `scenes/randomizer-timefantasy/randomizer-timefantasy.tscn` — the Time
  Fantasy pipeline (`tf_terrain.gd` + `timefantasy.gd`), starting at map id
  `150000` (`recipe = -1`: id % 20), with the Painted Lands walker and the same
  Esc menu, titled "Time Fantasy randomizer". Experimental only: the Time
  Fantasy tilesets are no longer considered suitable for any map in this
  project (§ Time Fantasy).

There is no health, enemy, or save. The editor addon
`addons/godot_mcp` is how this repo is driven from the Godot MCP server.

## Art directories

`assets/pack/` holds *hand-painted* sheets for both languages:

- Mystic Woods: `plains.png`, `grass.png`, and the original woods set
- Painted Lands: `TILESET_brighter.png`
- Green Caves: `green_caves/green_caves_tileset.png` (+ `explanations.png`,
  the pack's own guide). Its slimes are characters and are not used.
- Cozy Cottage interiors: `cozy_cottage/` (§ Interiors).
- Time Fantasy: `time_fantasy/` (§ Time Fantasy). Not an antarcticbees pack
  and never mixed with them. No longer suitable for any map in this project
  (its ground tiles clash with Painted Lands and are too repetitive and hard
  on the eyes by themselves); do not use it for new maps.

**What goes with what:** `docs/painted-lands-art-fit.md` is the one art
reference for combining the antarcticbees tilesets (Forest, Green Caves,
Cozy Cottage, and Farm – 4 Seasons, which is not in the project yet and would
go to `assets/pack/farm/`, git-ignored). Read it before putting one pack's
art on another pack's maps: it lists every pairing and three-pack map idea,
what fits as it is, what needs a color remap, what never mixes, and counts,
with sheet coordinates.

`assets/ai/` is generated in Grok Build (`assets/ai/README.md`).
Never put a generated sheet in `assets/pack/`. The wanderer sheet
matches the player grid: 48×48, 6 columns, 10 rows, attack columns
0–3 only.

---

# Mystic Woods

Do not apply this section to `forest.tscn` or `TILESET_brighter.png`.

`scripts/terrain.gd` writes a tile-id grid. `scripts/clearing.gd` paints
it. Clearing seed `21021`, size 70×46. Same grid every launch for that
seed. Output is atlas coordinates, never a painted bitmap.

`plains.png` is 6×12 cells of 16px:

- Rows 0–3: dirt on meadow grass. Rounded outer corners and a
  one-tile east-west trail live here.
- Rows 4–6: cliff top and the south-facing wall. The sheet has no
  north-facing wall. A plateau reads as higher ground because the
  south rim uses the wall tiles.
- Rows 8–11: cobblestone on grass (not water: the pack's water is
  `water-sheet.png`). Same corner layout as the dirt block, eight rows
  down; used for plazas, cobbled roads, and rocky fields.
- Meadow fill is the single cell in `grass.png`, color `(80, 155, 102)`.
  Cliff-top green `(83, 160, 59)` stays on the plateau and is not
  mixed into that fill.

Pipeline, in order:

1. Height and moisture are value-noise fBm, 4 octaves, amplitude
   halved and frequency doubled each octave. Height samples at
   `(x * 0.055, y * 0.055)`. Moisture samples at
   `(x * 0.05 + 40, y * 0.05 + 20)`.
2. Biome thresholds. Height above `0.64` is cliff. Height below `0.36`
   and moisture below `0.40` is water. Everything else is grass.
3. Three cellular passes. A cliff or water cell with fewer than 4 of
   its 8 neighbors of the same kind becomes grass. A grass cell with
   6 or more becomes that kind.
4. Two erode passes on cliffs. A cliff cell with fewer than 2 cardinal
   cliff neighbors becomes grass. Then drop cliff components smaller
   than 40 cells and water components smaller than 12.
5. Prefab arenas. Spawn is `(width/2, height * 0.62)`, flattened to
   grass in a disk of radius 5. The shrine is the farthest of 40
   seeded candidates and is flattened in a disk of radius 4.
6. Autotile from the 4 cardinal neighbors. Bits are N=1, E=2, S=4,
   W=8. The pack paints the rounded corner into the two-neighbor
   tile, which is how an 8-neighbor corner is represented with this
   sheet. Fully surrounded dirt and plateau cells pick a fill variant
   from the hash of the cell so a 3×3 interior does not repeat.
7. Carve, then autotile again. A* from spawn to shrine treats cliff
   cost as 12 and water cost as 8. The route and the cell to its east
   become dirt, two tiles wide, and the arenas and the map edge stay
   grass. (The old one-cell water link toward the west column is gone:
   the pond art cannot draw a channel, and water is cut to rectangles.)
8. If two fully interior 3×3 dirt windows or plateau windows share
   the same nine ids, the center cell of the later window changes
   variant.
9. Poisson scatter on grass outside the arenas. Trees at least 6.5
   tiles apart, flowers and tufts 3.2, blocking rocks 8. The shrine
   prefab is a small tree, two rocks, and a flower from the pack,
   placed on the shrine tile.
10. Verify before the scene is trusted. Every id exists in the pack.
    A grass-and-dirt flood fill from the spawn reaches the shrine.
    Interior dirt 3×3s and plateau 3×3s are unique. The report string
    is printed from `clearing.gd`.

Painting order: grass on `Ground` for every cell, feature ids on
`Features`, flowers on `Deco`, y-sorted trees and the shrine on
`Actors`. Collision is a static body on cliff cells, water cells, and
a ring outside the map. Grass and dirt stay open.

When extending Mystic Woods, add biomes as more ids from `plains.png`
or another *Mystic Woods* sheet. Keep this pipeline: noise, thresholds,
smooth, carve, re-autotile, scatter, then the three checks above.

### Mystic Woods recipes

`terrain.gd` `RECIPES`; `recipe = seed % 16` unless pinned. Recipe 0 is the
pipeline above, built exactly as before (clearing and grove pin it). The
others tune the cliff threshold, the water, the goal arena's radius, and
the scatter, add a set piece around the goal, and retry with a new layout
seed (same noise) until the walker reaches the goal. Set pieces keep off the
lane (the route's last stretch inside the arena, and the cells beside it);
fences, walls, and blocking pieces count as solid in the reach check.

| # | Recipe | Water | Set piece and scatter |
|---|---|---|---|
| 0 | Clearing | noise | shrine prefab (the original) |
| 1 | Pond glade | 1–3 ponds | shrine prefab, some mushrooms |
| 2 | Lake island | one lake, 1–2 islands | benches, sign, potted plants on the shore |
| 3 | Farmstead | noise | fenced 9 × 7 yard with a gate on the lane and a sign; crates, barrels, baskets, pots, drawers inside; stumps and logs |
| 4 | Stone ruins | none | cobble patch, a roofless stone hut, pillars and arches, skulls, rocks |
| 5 | Cottage garden | none | stone hut with its door, potted plants, pots, basket, bench, short fence runs, bushes |
| 6 | Graveyard | none | fenced yard with rows of gravestones and skulls; stumps, mushrooms |
| 7 | Cobble crossroads | none | cobblestone road and a plaza with benches, signs, barrels, potted trees |
| 8 | Rocky highland | none | more cliffs, cobblestone rock fields, cypresses, many rocks |
| 9 | Orchard | none | fruit trees on a loose grid around the goal and across the map; baskets, crates |
| 10 | Woodcutter's glade | noise | fire pit ringed with logs; many stumps and logs |
| 11 | Campsite | 1–3 ponds | fire pit with log seats, bench, crates, sign |
| 12 | Mushroom hollow | none | dense trees and cypresses, mushrooms everywhere, a stump at the goal |
| 13 | Abandoned house | none | plank floor (`wooden.png`) with a rug (red or blue-stone set, 3 × 3 or round, runner, side strip, door mat), bed, bookshelf, a table with a potion and a scroll, stools, pots, an iron chest, wall stubs at the corners; saplings |
| 14 | Stone chapel | 1–3 ponds | bordered red stone floor (`flooring.png`) with its round medallion, a blue-stone runner and mat, pillars down both sides, the long table as an altar, a gold chest and a heart, potted trees; graves |
| 15 | Tree nursery | noise | fenced yard with rows of saplings, empty pots and sprouts, dirt spots, trodden and dug earth |

Chests (`chest_01.png` iron, `chest_02.png` gold; Farmstead, Stone ruins,
Campsite, house, chapel) play their four frames open when the player comes
within 24 px. Huts hang one of the four doors (`wooden_door.png`,
`wooden_door_b.png`, shut or ajar) by cell. Ponds carry animated rocks
(`rock_in_water_01-sheet.png`) and lilies (`water_lillies.png`) and the
ripple decorations.

**Randomizer extras (`enrich`, off in the fixed scenes):** 8 px detail from
`decor_8x8.png` on an 8 px layer (stones, sprigs, and flowers on the meadow
green; specks on the plain dirt fill), stones and dirt spots from
`decor_16x16.png`, bare earth round fire pits and in dug beds, the plateau's
inside corners (`plains.png` 4–5, 4–6), and a liveliness floor: each 43 × 18
window's motion is estimated with the Painted Lands weights (water, fire,
leaves), and a window under 0.09 % gets a small pond (over grass and flowers,
never props) or a fire pit (at most two), up to five anchors. The scene also
runs the Painted Lands ambience in this pack's colors: wind, leaves from the
tree crowns, streaks, cloud shadows (darkest leaf green), water life (rings
deeper than the water), butterflies, dragonflies, and fireflies (in shade),
small animals (`wildlife.gd` with habitats built from this map), footsteps
(dust puffs from `dust_particles_01.png`, grass flicks), drifters, and grass
waves. `tools/pack_usage.gd` and `tools/pack_usage.py` measure how much of the
pack the maps use.

Water uses `water-sheet.png`: a 3 × 3 bank-and-water autotile and a 2 × 2
island, six frames five cells apart (tile animation). The art has no inner
corners, so every pond is a rectangle: noise water is cut to the largest
rectangle at least 3 × 3 inside each pool, and placed ponds are rectangles
two cells clear of cliffs and arenas, which the route goes around. Lily pads
and water rocks (`water_decorations.png`) dot the open water. Fences use
`fences.png` as a 4 × 4 autotile (column: the rail sideways, row: the rail up
and down) on a y-sorted layer. Roofless stone structures come from
`walls.png` (wall tops over a brick face, `wooden_door.png` on a hut). Fire
pits glow and smoke through `fire_ambience.gd`. `tools/check_mystic.gd`
sweeps recipes headless.

---

# Painted Lands

Do not apply this section to clearing, grove, hollow, ford, or heath.
Do not call `terrain.gd` from forest.

Sheet: `assets/pack/TILESET_brighter.png`, 16×16 cells.
Code: `scripts/forest_terrain.gd`.

## How to use these notes

Two jobs, one sheet:

1. **How each system draws** — cobble path table, patch islands,
   water shores, four house prefabs, y-sort. Methods never change.
   Do not invent pixels or swap in Mystic Woods dirt from `plains.png`.
2. **Where systems go** — 20-recipe generator. A new seed changes
   recipe, house prefab, path graph, dirt *islands* (not just roads),
   bushes, rocks, signs, and fires.

A screenshot that only has cobble roads + one porch cottage + flowers
has failed the variety rules, even if the road autotile is perfect.

The 3×3 block at atlas columns 35–37, rows 0–2 (inner corners
`(35–36, 3–4)`) is the **water autotile source on the sheet**, not the
size of the lake in the world. The sheet repeats it at columns 38, 41, and
44 with the shore a little wider each time; those are four animation
frames (tile animation, separation 2 columns, 0.35 s each).

Quadrant labels describe how to *pick* a 16×16 atlas cell. Never slice
that cell into four world tiles. Never split a cell to fake a 45° road.

## Dirt: two families (do not collapse them)

**PATH** — diamond cobble tube. Atlas `(21–23, *)` only. Walkable road.

**PATCH** — dirt *islands* on grass. Not a road. Not cobble. Not a
single square of fill. Walkable.

The square stubs in the last screenshot happened because a PATCH cell
was a raw fill (or one 8×8 quadrant) with no neighbor tiles to supply
the grass corners. A visible patch is a **mini-blob + autotile**, the
same idea as a pond.

### Patch blob (shape)

1. Pick a seed cell on lawn, ≥3 tiles from any cobble PATH cell and
   ≥2 from house / water / fence.
2. Grow a 4-connected blob of 3–8 cells (irregular recipes: CA or
   drunkard, then drop 1-cell diagonals). Round recipes: a 2×2, a
   3×2, or a plus. Never a lone 1×1 fill. Never a 1×N strip.
   Never a 2-cell L (one cell south of one end). A 2-cell patch must
   be a straight 2×1 with cap tiles on both ends.
3. If the blob is still one cell after grow, replace that cell with a
   **standalone rounded island** tile (dirt-on-grass cap with grass
   on three or four sides from the PATCH atlas). Do not leave a square.
4. Min 4 tiles between two blobs.

### Patch autotile (paint)

Use the **dirt-on-grass family**, not cobble and not a subdivided
quarter sitting alone:

```
PATCH atlas (same roles as PATH, different cells)
Set A, transparent grass        Set B, baked mid-green grass
NW (30,0) N (31,0) NE (32,0)    NW (24,0) N (25,0) NE (26,0)
 W (30,1) F (31,1)  E (32,1)     W (24,1) F (25,1)  E (26,1)
SW (30,2) S (31,2) SE (32,2)    SW (24,2) S (25,2) SE (26,2)
```

Set A has no baked grass: the lawn under the cell shows through, which
is Mode A below. Set B keeps its mid green (`(83, 131, 79)`, the same
as lawn cell `(4, 0)`) and is only used with the Mode B halo. Pick one
set per blob. `(27–29, 0–2)` is the same dirt on dark green.

`(18–20, 0–2)` is **not dirt**. It is darker grass on mid green, the
accent-grass family below. Never use it as a PATCH.

Inner corners (fully surrounded cell, one open diagonal):

| Open diagonal | Set A | Set B |
|---|---|---|
| SE | `(31,3)` | `(24,3)` |
| SW | `(32,3)` | `(26,3)` |
| NE | `(31,4)` | `(24,5)` |
| NW | `(32,4)` | `(26,5)` |

Rows 6–8 of each set (`(21–32, 6–8)`) are ragged sparse-dirt versions of
the same 3×3 layout, with inner corners in rows 9–10 (`(22–23, 9–10)`,
`(25–26, 9–10)`, `(28–29, 9–10)`, `(31–32, 9–10)`). Irregular blobs use the
ragged set of the same mode (transparent or the lawn-baked `(21–23, 6–8)`
on lawn, mid or dark baked inside a zone); round blobs use the smooth sets. The dirt sets have no standalone one-cell island
and no three-sided cap, so a round blob is a rounded rectangle (2×2,
3×2, 2×3, 4×2, 2×4) and an irregular blob is two rectangles joined with
arms at least two cells thick.

Neighbor bits N=1 E=2 S=4 W=8 on the blob mask:

- 15 → F `(31,1)` or `(25,1)`, or an inner corner when a diagonal is open
- one grass side → matching EDGE
- two adjacent grass sides → OUTER corner (NW/NE/SW/SE)
- three grass sides, or two opposite sides → no tile exists; reshape
  the blob
- a cell with no painted blob neighbor is illegal; delete it

Do not place F on the outline. Do not place an EDGE without its
opposite-side partner when the blob is two cells tall or wide.
Do not use PATH `(22,1)` or a lone 8×8 quadrant as the patch.

Reject a square dirt tooth on the lawn.

### Patch grass (the dark-green rectangle)

PATCH atlas cells bake their *own* grass into the tile. That grass is
a different green from FLAT_GRASS, so a raw stamp draws a dark square
behind the dirt. Never leave that AABB visible.

After the blob is autotiled, pick **one paint mode per blob**
(`(seed + blob_i) % 2`):

**Mode A — match the lawn (default half).**  
Keep beige / dirt / brown pixels. Replace every baked-grass pixel in
the PATCH cells with the FLAT_GRASS pixel already on that world cell
(same speckle variant). Equivalent: blit dirt with grass treated as
transparent. The dirt outline stays rounded; the lawn color is
continuous. No second green.

**Mode B — accent grass, organic halo.**  
Keep the baked darker green, but it may only exist inside an organic
halo, never as the tile rectangle.

1. Dirt mask = beige/brown pixels of the autotiled blob.
2. Halo = that mask dilated 2–4 pixels with a 1-octave noise wobble
   so the halo edge is lumpy, not a circle or a box. Then AND with
   the 16px cells the blob occupies plus at most one neighbor ring.
3. Darker grass is painted only on `halo minus dirt`. Outside the
   halo, FLAT_GRASS stays.
4. Soften the halo rim with the lawn speckle (copy 30–50% of rim
   pixels from the destination FLAT_GRASS). No straight 16px edge of
   dark green against light green.

A 2×2 of PATCH tiles whose dark grass meets in a larger rectangle is
a Mode B failure — run the halo mask or fall back to Mode A.

An L of two dirt cells with square meeting corners is a blob failure.
Grow the third cell of the L or drop one cell, then autotile OUTER
corners. Two touching mounds that are not a 4-connected blob with
edge/corner tiles must be rebuilt.

Reject a dark-green square or rectangle under a dirt mound.
Reject an L-shaped or stair-shaped dirt cluster with square corners.

### Accent grass patches (no dirt)

A lone darker-green tile on the lawn (the circled square in the
middle of the last screenshot) is the same AABB bug without dirt.

If the recipe wants worn / darker grass as its own feature:

1. Never stamp one atlas cell of dark grass and leave its 16×16 edge.
2. Grow a 4-connected grass-accent blob of 3–8 cells, *or* a single
   cell that is then painted with Mode A or Mode B below — never a
   raw square.
3. **Mode A:** recolor every pixel of that tile to the destination
   FLAT_GRASS (the accent disappears; do not place the tile).
4. **Mode B:** keep the darker green only inside a noisy halo:
   start from the intended accent shape (not the tile rectangle),
   wobble the rim 2–4 px, mix 30–50% rim pixels with lawn speckle.
   Outside the halo, FLAT_GRASS stays.

A 1×1 dark-green square with a hard edge is always a reject, whether
or not dirt sits on it. Prefer Mode A unless the recipe explicitly
wants accent grass.

### Grass tone zones (every map)

Large zones of darker grass, three nested levels, painted between the
lawn and the features:

| Level | Blob on transparent | Hole ring (inner corners) | Fill (plain, speckles) |
|---|---|---|---|
| mid | `(12–14, 6–8)` | `(12–14, 9–11)` | `(4, 0)`, `(5–7, 0)` |
| dark | `(15–17, 6–8)` | `(15–17, 9–11)` | `(8, 1)`, `(9–11, 1)` |
| deep | `(18–20, 6–8)` | `(18–20, 9–11)` | `(8, 0)`, `(9–11, 0)` |

The rows 0–5 versions of these blobs bake the lighter tone into the cell;
use the transparent ones.

1. A smooth tone field (3-octave value noise, sampled rotated so its
   lattice is off the tile grid) lives on every cell corner.
2. Corners within one cell of the path or the plateau are 0 and the field
   fades back in over about four cells, so zones bend away from the path
   and never touch its baked lawn.
3. Each level covers a fixed share of the map (about 25 %, 11 %, 6 %),
   using a quantile cut on the same field, so deeper levels always sit
   inside lighter ones. Specks smaller than a few cells are dropped.
4. Cells fully inside a level are fill tiles (random plain/speckle, random
   mirror). Cells the contour crosses are drawn per pixel from that same
   fill wherever field + pixel-scale wobble + dither is above the cut. The
   rim is organic and dithered; no edge follows a 16 px line.

Reject a tone zone with a straight edge, a stair-step outline, a darker
level touching the lawn directly, or any tone pixel on a path cell.

Cut gaps: the dark cut is at least 0.12 above the mid cut and the deep cut
at least 0.11 above the dark cut, so each lighter tone keeps a band wide
enough to stand on its own around the darker one.

**Dirt islands inside a zone.** When an island's cells are at least 95 %
one tone (at most 5 % of the next darker) and its one-cell ring at least
85 % (at most 15 %), it uses the dirt set whose baked grass *is* that
tone, as plain tiles with no halo: Mode M, set B `(24–26, 0–5)` on mid;
Mode D, `(27–29, 0–2)` with inner corners `(27, 3)`, `(29, 3)`, `(27, 5)`,
`(29, 5)` on dark. Half the island placement tries start inside a zone.
On plain lawn, Mode A or B as above.

**Grass accents.** Small blobs of the next darker tone from the baked sets
`(12–20, 0–2)`, with the hole rings `(12–20, 3–5)` for inner corners and
for ring-shaped accents (a 5×5 whose center 3×3 is the ring). An accent
goes only where the ground under it and its ring is exactly the tone
baked into the cell: mid on plain lawn, dark on pure mid, deep on pure
dark. Two to four per map (more on Hedge garden). Lawn cells sometimes
use `(0, 17)` (lawn with a tuft), and mid and dark fills sometimes
`(11, 15)` and `(11, 21)`.

**Deco by tone.** On lawn and mid: sprouts `(5–7, 1–3)`, `(6–7, 5)` and
flowers `(8–10, 2–7)`. On dark and deep: mostly the darkest sprouts
`(5–7, 4)`, `(5, 5)`. Flower carpets `(5–7, 6–8)`: one to three per map on
plain lawn, either the whole 3×3 or its four corner cells as a 2×2, at
least six cells apart.

### Hedgerows

Dark hedge `(0–2, 1–3)` (inner corners `(3–4, 1–2)`) and light hedge
`(0–2, 5–7)` (inner corners `(3–4, 5–6)`), autotiled as rows two cells
thick, 5–10 long, sometimes an L. On recipes with bushes or a fence yard,
one to three rows. The dark hedge goes only on plain lawn; the light hedge
only where the row and its ring are at least 90 % dark tone. Hedges block;
a row that would cut the spawn off from any goal is not placed. Never a
lone 3×3 hedge square.

## Dirt path atlas (cobble PATH only)

## Dirt path atlas (cobble PATH only)

Classify a sand *path* cell by its four 8×8 quadrants, written
NW NE / SW SE. G = grass in that quadrant of the atlas cell. D = dirt.

| Role | Quadrants | Atlas cell | Use |
|---|---|---|---|
| Fill | DD/DD | `(22, 1)` | Interior only. A 2-wide tube has no fill cell. |
| North edge | GG/DD | `(22, 0)` | Grass on the north. |
| South edge | DD/GG | `(22, 2)` | Grass on the south. |
| West edge | GD/GD | `(21, 1)` | Grass on the west. |
| East edge | DG/DG | `(23, 1)` | Grass on the east. |
| NW cap | GG/GD | `(21, 0)` | North cell of a west end. |
| NE cap | GG/DG | `(23, 0)` | North cell of an east end. |
| SW corner | GD/GG | `(21, 2)` | South cell of a west end. |
| SE corner | DG/GG | `(23, 2)` | South cell of an east end. |
| Inner NW | GD/DD | `(23, 5)` | Inside crotch. |
| Inner NE | DG/DD | `(21, 5)` | Inside crotch. |
| Inner SW | DD/GD | `(23, 3)` | Inside crotch. |
| Inner SE | DD/DG | `(21, 3)` | Inside crotch. |

Neighbor bits: N=1, E=2, S=4, W=8. Fill is mask 15 only.

## Dirt path — rounded ends, 90°, approx 45°

4-connected only. No 1-tile jog. No 45° fill line. No sliced cells.

Widen to 2 when a run is ≥4. Both rows of a tube end in the same
column. Autotile, then force end columns:

```
West: (21, 0) over (21, 2)
East: (23, 0) over (23, 2)
```

90° = 2×2 knuckle (outer cap + inner bite + edges). Never a 2×2 of
fill. Force after autotile.

Approx 45° = two knuckles + riser of 2–4 tiles. At most two leans
per map. Example east-north-east:

```
Lower: inner (23,5) / east (23,1)
       south (22,2) / outer (23,2)
Upper: outer (21,0) / north (22,0)
       west  (21,1) / inner (21,3)
```

## Houses (0 or 1, unless the recipe names more)

Default is **zero or one** house per map. Two only on recipes 10 (West
hamlet), 23 (Woodcutter camp), 31 (Twin cottages), and 32 (Manor green),
three only on 26 (Village square) and 30 (Cottage row); those recipes name
every prefab. In the randomizer every house has a door into an interior
(§ Interiors).

The sheet has four complete buildings. Never mix tiles from two
prefabs. Regions are in sheet cells; the doorstep is the cell the path
ends on, relative to the region's top-left. When the recipe has exactly one house,
`house_id = (seed // 20) % 4` unless the recipe names an id.

| id | Name | What it is | Region | Roof rows | Doorstep |
|---|---|---|---|---|---|
| 0 | Porch cottage | Large purple-roof house with wooden deck | `(38–45, 10–14)` | 2 | `(3, 5)` |
| 1 | Flower cottage | White walls, flowering vine on the wall | `(38–45, 15–19)` | 2 | `(2, 4)` |
| 2 | Gable cottage | Tall pointed roof, large windows | `(38–45, 25–29)` | 2 | `(2, 4)` |
| 3 | Hut | Small wood hut with door and deck | `(46–48, 9–12)` | 2 | `(1, 4)` |
| 4 | Shed | The hut kit's second wall, no deck | `(46–48, 13–15)` | 1 | `(1, 3)` |
| 5 | Barn | The doorless copy of the porch cottage, with the loose door `(46, 25)`, windows `(47, 24–25)`, `(47, 26)`, and door `(46, 26)` hung on its walls | `(38–45, 20–24)` | 2 | `(2, 5)` |

Houses 0–2 end two pixels into column 45; the hut-kit deck starts at
x 728 in row 19, so clip region widths to 115 px. The shed and barn are
outbuildings; only recipes that name them (23) place them.

Split every placed prefab:

- `HOUSE_BODY` — walls, door, porch. Collision. Sort Y = doorstep.
- `HOUSE_ROOF` — gables + overhang. No collision. Sort Y = eave.

Recipes with `Houses = 0` place none. Recipes with `Houses = 2` place
two prefabs (different ids, ≥8 tiles apart, each with body/roof).

## Props that must appear when the recipe asks

All of these exist on `TILESET_brighter.png`. If a recipe flag is set
and none are placed, the seed has failed. Do not substitute flowers
for these.

**Bushes** — round bushes `(21–22, 22–23)` and `(23–24, 22–23)` (dense,
may block `world`); small bushes `(21–22, 24)` and `(23–24, 24)`,
holey shrub `(47–48, 20–21)`, flowering shrub `(46–48, 22–23)` (loose,
deco). Place on lawn. The square hedge `(0–2, 1–3)` reads as a
dark-green lawn rectangle; do not place it.

**Land rocks** — stones whose *bottom pixels are grass*, in the crate /
rock pile cluster: `(25–26, 23–24)`, `(25–26, 25)`, `(25–26, 26–27)`,
`(23, 25)`, `(24, 25)`, `(23, 26)`, `(24, 26)`, `(23–24, 27)`. Lawn only.
The big rocks — `(25–26, 23–24)`, `(25–26, 25)`, `(25–26, 26–27)`,
`(23–24, 27)` — always block (`world`). The four 1-cell pebbles never
block. "LR obstacles" adds extra big rocks two to four cells off the path,
so they stand in the way without closing it.

**Water plants** — reeds / cattails / water grass beside the water
autotile block. Only on WATER_SHORE or the first water ring.

**Water rocks** — stones whose *bottom pixels are water*, in the same
water-prop cluster (including the rock/creature sitting in water).
Only on water or shore. Never on lawn.

**Campfire** — the fire strip at the bottom of the prop cluster,
`(29–32, 29)` (four frames; use frame 0 as the tile, animate if the scene
already supports it). Y-sorted actor. Collision. At most one from the
recipe; the liveliness floor may add more (below).

**Torches** — the standing torches `(35, 26–27)`, `(36, 26–27)`,
`(37, 26–27)`, each one cell wide and two tall. Each has a thin post collider
(4 × 5 px) at its foot and sorts at its foot, so a character north of it
walks behind the flame. Place
on fence posts, gate sides, or the house approach, or (liveliness floor)
as a pair of wayside lanterns facing each other across the path. No collision
required.

**Trees** — `(29–32, 11–15)` and `(33–37, 11–16)`, and their flowering
versions seven rows down. Each can take the grass tuft the sheet draws in
the row under its trunk (region one row taller). That row starts a second trunk
base under the tree's own root flare, so the grassy-base variants (and the
shade trees, whose shade row does the same) are spliced: the flare rows are
dropped and the tree above is drawn that many pixels lower onto the base
(`splice` in `PROPS`), so one trunk runs into the grass. Never `(25–28, 11–15)`
or `(25–28, 18–22)`: both carry a stray foliage band in the base row.

**Clutter** — every map: one to three fallen logs `(21–22, 25)`,
`(21–22, 26)` on the lawn. Every house: two crates or chests just outside
its buffer — crates `(21, 27)`, `(22, 27)`, stacks `(22–23, 28–29)`,
`(24–25, 28–29)`, chests `(26–27, 28–29)`. All clutter blocks. A crate is
never a sign.

**Signs** — ten distinct sign / notice / post tiles in the crate and
fence cluster: `(27, 23–27)` and `(28, 23–27)`. Enumerate them in
`forest_terrain.gd` as `SIGN[0..9]`.
A recipe that lists signs must pick 1–3 different ids from those ten,
never the same id three times, never a crate standing in for a sign.

**More props** — torch variants `(36, 26–27)`, `(37, 26–27)`; a third
crate stack `(20–21, 28–29)`; tall grass `(20, 27)` near doors; a
flowerpot `(46, 20–21)` beside cottage and hut doorsteps; the plank deck
`(46–48, 19)` at the shed door; a second water-grass clump `(47–48, 7–8)`.
Both campfires are two rows tall (flames reach row 28).

**Canopy wall** (recipe 25) — the seamless 4×4 canopy blocks
`(21–24, 11–14)` (plain) or `(21–24, 18–21)` (blossom) fill the top four
rows and block; trees with grassy bases stand three to four cells apart in
front so their crowns cover the canopy's straight lower edge.

**Shade trees** — `(25–28, 11–15)` and `(25–28, 18–22)` carry dark ground
shade in their base row; they grow only on the darkest grass, where the
shade matches the ground.

**Camp props** — big campfire `(34–37, 28–29)` (four frames) with ash
`(28, 29)` beside it, burning between a camp's buildings.

**Rock outcrops** — a small raised top on a short face, one per tone:
light `(9–10, 12–17)`, mid `(18–19, 12–15)`, dark `(18–19, 18–21)`, stone
`(18–19, 24–27)`. Each takes the tone of the ground under it (all stone
on Stone ruins). They block; one that would cut off a goal is not placed.

**Vines** — flowering `(5, 18–19)`, leafy `(6, 18–19)`, and a hanging
column `(34, 25–27)`, one to three per plateau face, clear of the cuts.

**Fence with grass** — rails `(32–33, 25)`, `(32–33, 27)` and post
`(32, 26)` are the plain pieces with grass at the foot; about a third of
rails and posts use them.

## Pond, fences, cliffs

Pond: compact blob from moisture. Fill only where water is surrounded.
The first pond on a map is a lake 60 % of the time (always on recipe 12):
an 8–11 × 7–9 rectangle with two or three bumps straddling its edges. Its
center, inset two cells, is deep water from `(36–38, 6–8)` (the shallow
part of that set is the pond fill), with two or three animated sparkles
`(47–50, 2)`, `(47–50, 3)` on the deep cells. A second deep pool goes in
a bump when a 3×3 or larger rectangle fits two cells from the shore and
two from the first pool. Open water scrolls: full shallow cells use
`(47–50, 0)` and half the deep interior `(47–50, 1)` (four frames, random
start); the other half uses the seamless deep fills `(40–43, 5–8)`. Open
water right beside a deep pool uses the still shallow frame the sheet
draws around the deep set (`(35–39, 5–9)` minus the deep 3×3).
Shore on every water–lawn edge. Then water plants / water rocks per
recipe. No 1-tile canals. World size is the blob, not 5×3.

Fences: 4-connected rails, real corners, min run 3. Plain-rail variants
`(29, 25)`, `(29–30, 27)`, a second east end `(31, 27)` and post
`(31, 26)`, and the shorter back rails `(29–30, 24)` on a yard's north
row. Rail `(30, 25)`,
east end with post `(31, 25)`, post `(29, 26)`; west ends and west posts
are the same cells flipped horizontally. Torches may sit
on posts. Signs may sit next to a gate, not on the rail tile.

Cliffs: only recipes 4 and 16. Blob ≥4 tiles both axes. Cap
`(4–6, 12–14)` + three-row south face `(4–6, 15–17)` + corners. Else omit.
Cut a three-wide stair into the face: `(1–3, 24)`, `(1–3, 25)`, then
`(2, 26)` across all three. The path reaches the stair foot (recipe 16
adds a spur). The plateau top interior and the rim cells over the stairs
are walkable; the rest of the rim and the face block.

Plateau trees: every light, mid, or dark plateau top gets one tree (two on
a top at least 14 wide), a plain crown `tree_a`, `tree_b`, `bloom_a`, or
`bloom_b` (the grassy-base variants bake lawn green), trunk on an interior
row, the landing above the stairs or ramp kept open. A tree that would cut
the spawn off from a goal is not placed. Stone tops get none.

The cliff kit comes in four tones — light, mid, dark, stone — each with a
3×3 top and a 4×4 ramp (a two-wide gap through the face with shaded
rock sides, rim row first):

| Tone | Top | Ramp |
|---|---|---|
| light | `(4–6, 12–14)` | `(0–3, 12–15)` |
| mid | `(15–17, 12–14)` | `(11–14, 12–15)` |
| dark | `(15–17, 18–20)` | `(11–14, 18–21)` |
| stone | `(15–17, 24–26)` | `(11–14, 24–27)` |

Only the light set has rock-with-grass for the ramp's bottom side cells;
every ramp uses `(0, 15)` and `(3, 15)` there. Ramps go only on light and
stone tops: a mid or dark ramp would carry its green straight into the
light lawn at the foot, so those tops use stairs. A cave mouth
`(7–9, 18–20)` can be cut into the face instead (three wide; the bottom
middle is the walkable entrance). About a fifth of plain face columns are
the vine-covered face `(0–1, 18–20)`.

More of the kit: each plateau picks one of two rock faces, `(4–6, 15–17)`
or `(2–4, 18–20)`, with plain rock `(2–3, 16)` for some middle cells; the
south rim of light, mid, and dark tops uses the six rim variants in rows
23, 22, and 21 (columns 0–5); stairs are flanked by the shaded rock
`(0, 24–26)` and `(4, 24–26)`; a one-wide stair `(5, 24)`, `(5, 25)`,
`(2, 26)` serves some mid and dark tops; stone tops sprinkle in
`(11, 27)`.

**Rock ridges.** `(7–8, 12–17)`, `(14–17, 15–17)`, `(14–17, 21–23)`,
`(14–17, 27–29)` are one set in four tones: a low rock wall one cell of
rock thick, with a rim above and below and rounded caps where it stops,
so a gap between two segments is a pass. Each piece is a column three
cells tall (rim, rock, rim):

| Tone | West cap | Body | East cap |
|---|---|---|---|
| light | `(7, 12–14)` | `(8, 12–14)`, `(7, 15–17)` | `(8, 15–17)` |
| mid | `(16, 15–17)` | `(14, 15–17)`, `(17, 15–17)` | `(15, 15–17)` |
| dark | `(16, 21–23)` | `(14, 21–23)`, `(17, 21–23)` | `(15, 21–23)` |
| stone | `(16, 27–29)` | `(14, 27–29)`, `(17, 27–29)` | `(15, 27–29)` |

The rims bake their tone's ground, so a ridge stands only on that ground:
light on plain lawn, mid, dark, and stone on a plateau top of the same
tone. A ridge is an upright wall whose base is the bottom of the rock.
Its collider straddles the base: 13 px up into the rock (a character
behind the wall shows only its head) and 8 px down into the lower rim (one
in front stops with about half its body over the face), trimmed to the
rock's width in each piece (the rounded caps
are narrower), so a gap is as wide as it looks. The rim and rock are also
drawn as a y-sorted overlay (the two cells minus their baked ground),
sorted at the base: a character standing right behind the wall shows only
its head over the rim, and one in front is drawn over the lower half of
the face. Grass zones fade away from ridges as they do from the path. Ridgeline (28) and Walled mesa
(29) use them.

Not used: the thin diagonal hedge pieces `(0–1, 4)`, `(0–1, 8)`, which
draw as scattered leaf bits.

## Ambience (Painted Lands scenes)

Motion lives outside the tile art, in four scripts that `forest.gd` adds:

- `scripts/wind.gd` (`Wind`) — the one wind every effect reads. Its
  heading eases to a new direction every 20–40 s (over about 4 s), base
  strength drifts between 0.3 and 0.8, and gusts rise and fall on top every
  6–16 s.
- `scripts/ambient_leaves.gd` — leaves fall from every tree crown (and the
  canopy wall's lower edge), flutter, tumble between two- and three-pixel
  shapes, drift with the wind, lie on the ground a few seconds, and skitter
  in gusts. Colors come from each tree's sprite: a light foliage or blossom
  color that stands off the lawn, edged with the tree's darkest green, so a
  leaf reads on any grass tone. More fall in gusts.
- `scripts/wind_streaks.gd` — pale one-pixel wisps skim along the wind in
  view, fading toward the tail; about a third curl into a small eddy. More
  in gusts. Drawn under the y-sorted actors.
- `scripts/cloud_shadows.gd` — three lumpy cloud shadows in translucent
  deep-grass green with a narrow ordered-dither rim, drifting with the wind
  and wrapping in on the upwind side.
- `scripts/fire_ambience.gd` — every campfire and torch gets a warm pixel
  glow (a round light in solid steps joined by ordered dither, drawn
  additively over the scene) that flickers out of step with the others;
  big fires glow widest, torches smallest. Campfires send up a thin column
  of smoke puffs (2×2 knots loosening into 3×3) that rise, bend with the
  wind, and fade. Every house with a hearth (the three cottages and the hut;
  not the shed or barn) sends up a thinner column, 0.6 of a campfire's, from
  its roof peak (`CHIMNEYS` in `forest_terrain.gd`; the sheet draws no
  chimneys).
- `scripts/drifters.gd` — what the wind carries through any view: dandelion
  seeds (a pale core and a paler tuft, riding the wind, bobbing and lifting,
  more in gusts), pollen specks hanging over flowers, and every 22–40 s a
  flock of four to seven birds crossing the view in a loose V, flapping,
  their shadows gliding 26 px below them. Spawned in and around the view.
- `scripts/grass_waves.gd` — light passing over the grass: each gust sends
  one or two fronts, and a faint one passes every 7–12 s; a front is a band
  40 px across the wind rolling downwind at about 42 px/s, lighting a
  dithered scatter of pale blade tips (leaning a pixel downwind) on grass
  cells only, strongest in the band's middle. Nothing on the map moves (this
  is not flower sway); it is drawn under the actors.
- `scripts/water_life.gd` — ripple rings spread now and then on open water
  (water cells whose eight neighbors are water), drawn as flattened pixel
  circles in the deep-water teal with a pale inner highlight while young,
  since the pond surface is pale. Every 8–18 s a fish jumps: droplets arc
  up and fall back with rings. Reeds and water grass are split into a
  planted base and a top that leans one pixel downwind in strong wind,
  each plant at its own moment.
- `scripts/critters.gd` — butterflies (3–8 per map, four wing colors)
  flutter from flower to flower, rest with wings open, get pushed about in
  gusts but always arrive, and scatter when the walker comes within 26 px;
  dragonflies (one or two per pond) dart over open water in quick eased
  bursts and hover, and dart off from the walker; fireflies (up to 14)
  drift over dark and deep grass and under the canopy wall, pulsing with a
  faint cross of glow at the peak.
- `scripts/wildlife.gd` (`Wildlife`) — ten small animals drawn in code as
  tiny pixel sprites (a rabbit is 7 px tall beside the 32 px walker) in
  colors snapped to the sheet's palette, each y-sorted on `Actors`:
  rabbit (lawn), squirrel (by trunks), vole (dark grass), mouse (by logs,
  crates, fences), hedgehog (by bushes and hedges), frog (shore), duck (open
  water), sparrow (lawn near paths and fences), lizard (plateau tops, rocks,
  ridges), fox (anywhere on the ground, 35 % of maps, one). Green plateau
  tops count as lawn and open ground too. `plan()` picks four to seven
  eligible species per map from the map id, one to three groups each at
  least eight cells apart and six from the spawn, so every map has its own
  population and the same map always the same one. Groups that do not need
  trees or water settle in the quietest of six candidate spots: farthest
  from water, campfires, torches, trees, and the groups already placed, so
  animals fill the parts of the map nothing else moves in. Each
  animal idles, wanders around its group's home, and reacts to the walker
  its own way: rabbits and the fox run, squirrels run up a tree, voles,
  mice, and lizards dash and hide, hedgehogs curl up, frogs jump into the
  water, ducks paddle off, and a sparrow flock flies to a new spot.
- `scripts/footsteps.gd` — the ground answers the walker every 9 px of
  travel: puffs of dust behind it on cobble and dirt, grass blades flicking
  up from tufts and flowers (three) and, on 60 % of steps, from plain grass
  (one or two; not on stone tops, stairs, or ramps), in sunlit blade colors
  lighter than any grass tone so they read, a ripple ring at the shore when it walks
  beside water, and fallen leaves near its feet kicked aside. Bits start a
  few pixels behind the walker so its sprite never hides them.

Torches: the three torch cells `(35–37, 26–27)` are one torch in three
flame frames, played at about 7 fps like the campfires; every fire
flipbook starts on a random frame at a slightly different speed, so no
two fires flicker in step.

Everything moves on whole world pixels and uses the sheet's colors; no
new sheet art (the animals are drawn in code, their colors snapped to the
sheet). Map generation is unchanged; the animal population is chosen from
the finished map.

## Streams

A recipe whose water is `S if room` (every land-only recipe but Open meadow,
which the wilds scene pins dry) gets, on 70 % of its maps, a brook three
cells wide after the layout. It enters from a map edge and meanders in a staircase of straight
runs, at least four cells between turns, turning sideways and back to its
flow but never doubling back, 22–46 steps long. It runs off another edge, or
rises from a spring: a 5 × 5 pool at the end inside the map. Three to six
2 × 2 bulges on its banks keep the edges from running straight. Cells past
the map edge count as water, so it flows off the map with no shore there.
It keeps two cells from the path and off everything already claimed, so it
never needs a bridge, and it is dropped if it would cut the spawn off from a
goal. Tiles, the scrolling surface on open cells, and water plants are the
pond's. Its middle row is open water, so it ripples and fish jump there, and
frogs and ducks can live on it. Streams do not count as ponds.

## Liveliness floor

Every camera-sized window (43 × 18 cells) should have something moving in
it. After the props, trees, and deco are placed, the generator works out the
liveliness estimate (`scripts/liveliness_features.gd` with weights frozen in
`forest_terrain.gd` from the 2026-09-27 calibration, so recalibrating never
rearranges a map) for every window. While the weakest window is under 0.09 %
of pixels moving per frame, it gets a motion anchor near its middle: a pair
of wayside lanterns (torches) facing each other across the path if the path
crosses it, otherwise a campfire in a clearing clear of the path; a window
under half the floor gets the campfire first. At most three anchors per map;
an anchor that would cut the spawn off from a goal is not placed. The report
line `floor:` gives the weakest window before and after and what was added.

## Forest generator

```
seed = map_id
recipe = seed % 30                # or the scene's pinned recipe
n_houses = recipe.houses          # 0, 1, or 2 only if table says 2
house_ids = named id, else (seed // 20) % 4 for the first;
            second house = (first + 1 + seed) % 4
height, moist = fBm(seed, 4 octaves, freq 0.055 / 0.05)
pond_mask = CA(low+wet); drop <12 cells and tetrominoes
plateau_mask = CA(high); drop <40; keep only if recipe.plateau
flatten spawn disk and each house disk
path = A* 4-connected; widen 2; autotile PATH table; force caps
patches = grow 3–8 cell blobs (no 2-cell L); autotile PATCH atlas;
          Mode A or B grass paint; never a dark-green tile rectangle
          or a lone square fill; min 3 tiles from cobble
grass_accents = optional; Mode A (recolor away) or Mode B (noisy halo);
                never a raw dark-green 16×16 stamp
extras = fences/gate/plateau/pond per recipe
props  = bushes, land rocks, water plants/rocks, campfire,
         torches, signs per recipe
trees  = Poisson
verify walk + reject list
```

### Recipe table (`recipe = seed % 30`)

Houses = 0, 1, or 2 (2 only here when written). P/P2 = pond(s).
P if room = a pond in whichever quarter of the map has room for one after
the layout (dropped, not failed, when none fits), so a road-and-lawn recipe
still has water moving somewhere. S if room = a stream (below), dropped if
none fits.
F = fence yard. G = gate line. C = plateau. L = approx-45° lean.
Patch = count of *blobs* after autotile (R round shape, I irregular
shape). Props: bushes, land rocks (LR), water plants (WP), water
rocks (WR), campfire (CF), torches (T), signs (S).

| # | Name | Houses | Water | Height | Path | Patch blobs | Props |
|---|---|---|---|---|---|---|---|
| 0 | Pastoral | 1×0 | P + WP + WR | F | trunk + L | R 2–3 | bushes, LR, T, S=1 |
| 1 | Crossroads | 1×1 | P if room + WP | none | 2 trunks 90° | I 2–3 | bushes, LR, T, S=2 |
| 2 | Pond walk | 1×2 | P + WP + WR | none | skirts shore | R 2 | bushes, S=1 |
| 3 | Garden | 1×3 | S if room | F+G | through gate | R 2 | bushes, LR, T, S=2 |
| 4 | Lookout | 1×0 | S if room | C | to plateau foot | I 2 | LR obstacles, CF, T, S=1 |
| 5 | Open meadow | 0 | none | none | edge-to-edge | R 3–4 | bushes, LR, no signs |
| 6 | Twin water | 1×1 | P2 + WP + WR | none | between blobs | R 1–2 | S=1 |
| 7 | South road | 1×2 | S if room | none | south third | I 2–3 | bushes, CF, T |
| 8 | Shore spur | 1×3 | P + WP + WR | none | trunk + spur | R 2 | S=2, T |
| 9 | Three-way | 1×0 | P if room + WP | none | +2 branches 90° | I 2–3 | bushes, LR, T, S=3 |
| 10 | West hamlet | **2** (1 and 3) | P + WP | F | from east, L | RI 2 | CF, T, S=2 |
| 11 | East hamlet | 1×2 | P + WR | F | from west, L | R 2 | T, S=1, bushes |
| 12 | Wild lane | 0 | moisture P | none | 1 trunk | I 3–4 | bushes, LR obstacles |
| 13 | Orchard | 1×3 | P if room + WP | none | short trunk | R 2 | bushes heavy, T, S=1 |
| 14 | Shore hamlet | 1×0 | P + WP + WR | F between | short trunk | R 1–2 | CF, T, S=2 |
| 15 | Double lean | 1×1 | P if room + WP | none | two L | I 2–3 | LR, T, S=1 |
| 16 | Below the rim | 1×2 | S if room | C | lawn south of plateau | I 2 | LR, S=1, T |
| 17 | Gate road | 1×3 | S if room | G | through gate | R 2 | T on gate, S=2 |
| 18 | Sparse wild | 0 | P if blob | none | 1 trunk | I 1–2 | LR only |
| 19 | Switchback | 1×0 | S if room | none | U of two 90° | RI 2 | bushes, CF, S=1 |
| 20 | Cave mouth | 0 | S if room | C (light, cave) | to the cave | I 2–3 | bushes, LR, T by the cave, S=1 |
| 21 | Terraces | 1×3 | S if room | C2 (light + ramp, mid/dark + stairs) | along the terraces | RI 2 | bushes, LR, CF, T, S=1 |
| 22 | Stone ruins | 0 | S if room | C (stone, ramp) | to the ramp | I 1–2 | LR obstacles, stone outcrops, ruins clutter, T, S=2 |
| 23 | Woodcutter camp | **2** (4 and 5) | S if room | F | trunk + spur | I 2 | big CF + ash, logs heavy, S=1 |
| 24 | Rock garden | 0 | P + WP + WR | none | edge + L | R 2–3 | outcrops, bushes |
| 25 | Deep forest | 0 | S if room | none | 1 trunk | I 1–2 | canopy wall, logs heavy, bushes, S=1; darker tone cover |
| 26 | Village square | **3** (0, 1, 2) | S if room | none | plaza + 2 trunks | R 1–2 | T at plaza corners, S=3 |
| 27 | Hedge garden | 1×2 | S if room | F+G | through gate | R 2 | hedges heavy, carpets heavy, T, S=1 |
| 28 | Ridgeline | 1×1 | S if room | R (light ridge across the map, two passes) | through the pass | I 2–3 | bushes, LR, T at the pass, S=1 |
| 29 | Walled mesa | 0 | S if room | C+R (14–18 × 7–8 top in stone, mid, or dark; ridge walls on it, each end two walkable columns short of the outer rim) | to the mesa | R 1–2 | LR, outcrops, T, S=1 |
| 30 | Cottage row | **3** (1, 2, 3) | S if room | none | plaza + 2 trunks | R 1–2 | bushes, carpets heavy, T, S=2 |
| 31 | Twin cottages | **2** (0 and 2) | P + WP | F | from east, L | RI 2 | bushes, T, S=1 |
| 32 | Manor green | **2** (0 and 3) | S if room | none | plaza + 2 trunks | R 2–3 | bushes, LR, T, S=2 |

Recipes 30–32 use the village and hamlet layouts with other buildings: in
the randomizer every house opens onto an interior (§ Interiors), so these
put homes of different sizes side by side. The hut must come last in a row.

`1×N` means one house of prefab N. Only recipes 10, 23, 31, and 32 place two
houses and 26 and 30 three. Recipes 5, 12, 18, 20, 22, 24, 25, 29 place zero. C2 is two plateaus.
The forest and wilds scenes pin recipes 3 and 5, so adding recipes
never changes those maps.

If a flag cannot be placed without breaking autotile, drop *that extra*
only. Do not drop patch blobs, bushes, or signs just to keep the old
pastoral screenshot.

Reject a Painted Lands screenshot if: lawn is a motif stamp; fill sits
on a cap or knuckle; pond corners are square wave tiles; a cliff
fragment is orphaned; the actor draws through `HOUSE_BODY`; a 1-tile
stair fakes 45°; a PATCH cell is a square fill or a lone quadrant;
two houses appear on a recipe that lists 0 or 1; a PATCH sits on a
dark-green square/rectangle of baked grass; a lone dark-green grass
tile shows its 16×16 edge; a dirt blob is an L or stair of square
cells; land rocks sit in water or water rocks on lawn; a crate
stands in for a sign.

---

# Green Caves

Do not apply this section to the Mystic Woods or Painted Lands maps, and do
not use their sheets here. Sheet: `assets/pack/green_caves/green_caves_tileset.png`,
50×19 cells of 16px. Generator `scripts/cave_terrain.gd` (60×40), painter
`scripts/caves.gd`. The walker is the Painted Lands one.

## Sheet systems

- **Floors.** Light `(0–1, 0–1)` (199, 197, 193); dark `(3–4, 0–1)` (162, 160,
  160); mossy `(0–3, 9)`, `(0–1, 10)`. `(2, 0–1)` carry dark splotches: not
  plain floor.
- **Dark zones** on the light floor: the blob on transparent `(0–2, 6–8)`,
  inner corners `(3, 6)` SE open, `(4, 6)` SW, `(3, 7)` NE, `(4, 7)` NW. Noise
  cut at the recipe's share, specks under 10 cells dropped, trimmed until every
  cell has a tile. Small patches baked on light floor: `(0–2, 3–5)`.
- **Wall mass** (solid rock, black top): top 3×3 `(5–7, 11–13)`, two face rows
  `(5–7, 14–15)`; face variants: rim `(10–16, 16)` over faces `(10–16, 17–18)`
  (14–16 mossy), `17` is the skull column (Ossuary only). Doorway `(5–7, 9–10)`
  cut into the back wall's face.
- **Terrace** (raised walkable top): `(5–7, 0–2)` over faces `(5–7, 3–4)`;
  variants rim `(10–16, 5)`, faces `(10–16, 6–7)`. Stairs `(10–12, 8–10)`
  with sides `(9, 8–10)` and `(13, 8–10)` replace the rim and both face rows of
  three columns. The top is entered only by its stairs (lip colliders on the
  other three sides).
- **Pools**: water in a rectangle with a one-cell stone ring. Ring N `(22, 2)`,
  S `(22, 0)`, W `(23, 1)`, E `(21, 1)`; corners NW `(27, 2)`, NE `(26, 2)`,
  SW `(27, 1)`, SE `(26, 1)`. Water edges top `(22, 3)`, left `(24, 1)`, right
  `(20, 1)`, corners TL `(28, 3)`, TR `(25, 3)`, BL `(28, 0)`, BR `(25, 0)`.
  These animate in four frames stacked four rows apart (columns 1, separation
  (0, 3)); open water `(29–32, 7)` in four frames side by side; all in step.
  Lakes have deep water `(30–35, 0–1)` inset two cells. Stalagmites `(30–31,
  4–5)` and weed `(34, 5)` stand in water on the WaterDeco layer over the
  water; sparkles `(29–32, 9)`, `(29–32, 10)` animate on a third of open water.
  The ring is the dark floor's grey, so every pool sits in a rounded dark
  halo (on light and moss floors).
- **Rails**: straight `(16, 8)`, `(15, 9)`; curves ES `(15, 8)`, WS `(17, 8)`,
  EN `(15, 10)`, WN `(17, 10)`. Walkable.
- **Props** (`CaveTerrain.PROPS`, region in px, foot, collider): rocks and ore
  `(33–48, 12–13)`, crystals `(29–31, 14–15)`, cones `(46–48, 5–7)`, plants
  and grass `(41–45, 5–8)`, trees `(36–45, 0–5)` (the signpost baked beside
  the first is erased), rock trees `(35–43, 15–18)`, bushes `(46–49, 0–5)`,
  branches `(36–41, 5–6)`, chests, boards, skulls, ladder, trough, crates,
  barrels, signpost, carts `(18–19, 5–8)`, coal `(18, 9–10)`, pillars
  `(29–33, 16–18)`, campfire `(16–19, 0–1)` and torch `(16–19, 4)` in four
  frames, ash `(15, 1)`.

## Pipeline

spawn near the bottom → back wall (2–3 rows, doorway, face variants) →
terraces with stairs → homes (recipes that have them) → lake, pools → rock islands (4–8 × 3–4) → goal (the
farthest open spot) → rails from spawn to goal (at most two bends) → the
recipe's set piece at the goal → dark zones + halos → floor patches → floor
→ scatter ×1.4 plus 10–16 small floor bits → wall torches in pairs →
liveliness floor → reach check (spawn to goal and to every terrace top; up
to 40 layout attempts).

## Recipes (`recipe = id % 33`)

| # | Name | Floor | Set piece / features |
|---|---|---|---|
| 0 | Grotto | light | cairn, a pool |
| 1 | Crystal cavern | light | crystal ring, crystal rock tree |
| 2 | Flooded hall | light | lake + pools |
| 3 | Mine shaft | dark | mine (carts, coal, crates), rails |
| 4 | Miners' camp | light | campfire camp, a home of 2–3 rooms |
| 5 | Mossy hollow | moss | grove, pools, tufts |
| 6 | Terrace steps | light | two terraces, goal on top |
| 7 | Ossuary | dark | bones, skull faces |
| 8 | Pillared hall | light | colonnade, no islands |
| 9 | Stalagmite field | light | cones everywhere |
| 10 | Underground spring | light | 3–4 pools |
| 11 | Ore vein | dark | ore, rails |
| 12 | Dead grove | light | dead trees, branches |
| 13 | Cave mouth | light | signpost and torches |
| 14 | Smugglers' cache | dark | crates, barrels, chests, a home of 1–2 rooms |
| 15 | Rail junction | light | mine, rails |
| 16 | Twin pools | light | two pools |
| 17 | Crystal shrine | light | pillar gate, crystals, terrace |
| 18 | Dark depths | dark | islands, pools |
| 19 | Collapsed tunnel | light | 4–6 islands, rocks |
| 20 | Overgrown mine | moss | mine, rails, plants |
| 21 | Watch post | light | terrace top with signpost and torch |
| 22 | Root cellar | dark | barrels, trough, rock tree, a home of 2–3 rooms |
| 23 | Echo chamber | light | open hall, large zones |
| 24 | Lake terrace | light | lake + terrace |
| 25 | Coal store | dark | coal, carts, rails |
| 26 | Crossroads cavern | light | signpost and boards |
| 27 | Hermit's nook | moss | camp, a home of 1–2 rooms |
| 28 | Sunken garden | moss | grove, pools |
| 29 | Treasure vault | dark | chests, pillars, violet crystals, terrace |
| 30 | Hermit's home | moss | a home of 1–2 rooms, grove, a pool |
| 31 | Cave hamlet | light | three homes of 1–2 rooms, camp |
| 32 | Underground manor | dark | one home of 5–6 rooms, pillar gate, crystals |

**Homes** (`_home()`): an InteriorPlan (§ Interiors) built into the cave.
Its wall ring is cave rock toward the cave floor and the Cozy Cottage trim
toward the rooms (wall tops composed per quarter cell, the cottage black
recoloured to the rock's fill), and two rows of cave face under its south
wall carry the arched doorway `(5–7, 9–10)` over the way out (the arch's
middle column walkable). Interior floor is kind `HOME` (walkable; mice live
there). A cave home has no sunbeams; its hearths and lamps glow through
`fire_ambience.gd` ("hearth", "lamp") and it has its own life
(`interior_life.gd`). Homes go before pools and islands, and a map retries its
layout until every home the recipe asks for fits and the entry room is
reachable.

## Ambience and liveliness

`caves.gd` adds wind (a draft), water life (ripples, fish, rings in teal),
footsteps (grey dust on floor, blade flicks on moss and tufts, shore
ripples), fire ambience (torch and campfire glow and smoke; flames at the
cave sprites' height), leaves from mossy trees and bushes, critters
(glowworms over moss, dark floor, and dark zones; moths at flowering plants;
dragonflies over pools), wildlife (mice by clutter and bones, lizards by rocks
and ore, frogs on the banks, voles on moss), and `scripts/cave_life.gd`:
drips from every face and into open water, warm dust motes in fire light and
pale ones everywhere, crystal and ore glints, and bat flights. No clouds, wind
streaks, drifters, or grass waves underground.

Liveliness floor: every 43×18 window should reach 0.2 % on the frozen
weights in `cave_terrain.gd` (from the rendered cave calibration: pool cells
0.65, sparkles 0.16, campfire 139, torch 30.5, mossy trees 4.17, a home's
hearth 60, a lamp 12); weak windows
get a campfire (with a branch) or a torch pair, up to six. Calibration:
`docs/liveliness-calibration-caves.md` (12 maps filmed, 4 held back). The estimate is `scripts/cave_liveliness_features.gd` with
`tools/liveliness_coef_caves.json` (`tools/liveliness.gd ... caves`).

---

# Interiors (Cozy Cottage)

Pack: The Painted Lands – Interior Cozy Cottage Tileset (antarcticbees),
`assets/pack/cozy_cottage/` (git-ignored). Sheets: `wallpapers_and_floors.png`,
`furniture.png` (five wood tones, 288 px apart), `decoration.png`. Catalog
`scripts/interior_art.gd`; generator `scripts/interior_plan.gd`; painter
`scripts/interior_view.gd`; life `scripts/interior_life.gd`; the Painted Lands
doors `scripts/house_interiors.gd`. Used by the Green Caves homes and the
Painted Lands randomizer's houses; never on the outdoor maps themselves.

Sheet systems:

- Wallpaper groups at rows 0, 5, 10, 15: a lip (wall top edged toward the
  room) over three face rows; one trim color each (cream, brown, mid, dark),
  matching the wall-top frames at `(0, 20)`, `(5, 20)`, `(10, 20)`, `(15, 20)`
  (3×3, trim on the side toward the room; nubs for a room only diagonal in
  the next two columns, rows 0–1 of the frame) and their black-filled copies
  nine rows lower (used everywhere: the void round an interior is black).
- Doorways: two-wide openings with a transparent hole; group starts
  `DOORWAY` = 29, 34, 34, 38.
- Floors: planks in 2×4 blocks from `(28–44, 20–23)`, parquet 2×2 from rows
  25–28, tiles `(20–27, 21–23)` (kitchens, baths, pantries).
- Furniture and decoration: `InteriorArt.ART` (rect, footprint cells, place:
  wall, floor, face, top). Fireplaces are their own art in any wood tone.
  Kitchen counters are modules along the north wall (`COUNTERS`, wood or
  marble tops, one sink). Left out: fridges, washers, stoves, screens.

Layout (`InteriorPlan.generate(seed, rooms, opts)`): a rectangle split into
one to six rooms by one-cell walls (each room at least 4 wide and 6 tall: three
face rows and three floor rows); each split gets a door (a gap two cells tall
in a vertical wall, or a two-wide doorway through a horizontal wall and the
face under it, drawn with the group's door frame); the way out is a gap in the
south wall of a south room (three wide, the arch's, in caves). Room sets by
count (the first is the entry room): 1 cottage; 2 living/bedroom,
cottage/bedroom, living/kitchen; 3 living, kitchen, bedroom (or hall …, or
study); 4–6 add study, bath, dining, pantry, a second bedroom. Bath and pantry
take the smallest rooms.

Furnishing: a window first (not in hearth rooms, baths, or pantries), then the
room's set (cottage: hearth, bed, wardrobe, counters, table and chairs;
living: hearth, rug, sofa, low table, armchair, bookshelf, floor lamp; hall;
kitchen: counters with a sink, dish shelf, table and chairs; bedroom: bed,
nightstand, wardrobe, dresser or vanity; study: bookshelves, desk and chair;
bath: tub, vanity; dining: long table and chairs; pantry: shelves, baskets),
floor plants and baskets in corners, hangings on the face (windows,
paintings, vines, herbs, shelves, mirrors) where nothing tall stands, and
something on every table and cabinet top. Tall wall furniture never stands in
front of a hanging. A piece is placed only if every door, the way out, and
some floor of every room stay reachable from the way out; door cells, their
approach, and the doorway rows are kept clear. Every home has a fire: without
a living room, a cooking hearth takes a wall (displacing a hanging).
`tools/check_interiors.gd` checks 600 homes; `tools/interior_preview.tscn`
shows six side by side.

Life (`interior_life.gd`): flickering flames in every fireplace opening
(y-sorted just in front of it), dappled sunbeams from each window (Painted
Lands; slanted, dithered, dimming as clouds pass, leaf shadows moving across
them, dust motes turning in them), steam from cups and teapots, a moth round
half the lamps, and a house cat in 70 % of homes (four coats: sleeps by the
hearth or in a sunbeam, stretches, wanders, sits and flicks its tail, comes to
sit by the walker or trots off). Hearth and lamp light come from
`fire_ambience.gd` (radius 30 and 14, no smoke). `tools/sim_interior.gd`
measures it headless: about 0.59 % of a home's pixels change per frame
(quietest 0.33 %), comparable with the outdoor camera windows.

Painted Lands doors (`house_interiors.gd`, `forest.gd` `interiors = true` in
the randomizer only): walking up into a door from its doorstep fades to black
and opens the house's interior, a sub-map 20000 px below the map (rooms by
building: porch cottage 3–6, flower cottage 2–4, gable cottage 2–5, hut 1–2,
shed 1, barn 1–3, from the map id and house index; built once per map). The
outdoor map is hidden and paused, the walker is moved inside above the way
out, and the camera is limited to the home (centered when smaller than the
screen). Walking down through the way out returns to the doorstep facing out.
Regenerating from the menu while indoors drops the interior first.

---

# Time Fantasy

**Not suitable for this project.** Consider the Time Fantasy tilesets no
longer suitable for any map here: the prevalent ground tiles are incompatible
with, or clash with, the Painted Lands tiles, and on their own they are too
repetitive and a strain on the eyes. Do not use them for new maps or mix them
into existing ones. This section records how the existing experimental scene was built.

Do not apply this section to the other maps, and do not use their sheets
here. Sheets: `assets/pack/time_fantasy/` (finalbossblues'
TimeFantasy_TILES_6.24.17: `terrain.png`, `outside.png`, `water.png`,
`house.png`, `animated/`, and the pack's `guide.png`). `world.png` is never
used: it is drawn for a zoomed-out strategic map. Generator
`scripts/tf_terrain.gd` (`TFTerrain`, 60×40), painter `scripts/timefantasy.gd`.
The walker is the Painted Lands one. `tools/check_tf.gd` sweeps maps headless.

## Sheet systems (cells of 16 px)

- **Grass.** Light fill `terrain (2, 1)` (99, 162, 63), the only true base;
  `(3, 1)` is a quiet variation. Other cells in row 1 are not variations
  (they checker). Row 1 runs light to dark: `(9–11, 1)` is the mid forest
  floor, `(7, 1)`, `(8, 1)`, `(12, 1)` the deep one. Deco on light grass `(1–20, 2–3)`. Autumn: gold fill `(1, 4)`
  (183, 157, 50), variations `(2–3, 4)`, deco `(1–12, 5)`.
- **Grounds.** Columns 22–37, one row per ground: rows 2–7 on green grass and
  9–14 on gold (dirt, gravel, sand, packed dirt, paving, pit). Column 22 fill;
  grass on the N/S/W/E side 25/34/27/32; rounded outer corners NW/NE/SW/SE
  29/33/35/36; inner nubs 23/24/26/30; 28 and 31 diagonal crossings (unused);
  37 the grass. A cell whose grass would be on two opposite sides has no tile:
  the path is reshaped (the cell dropped) before autotiling. Paths are two
  wide.
- **Water** (`water.png`). Per shore (grass `(1, 7)`, deep on grass
  `(21, 7)`, sand `(1, 37)`, gold `(1, 19)`, dirt `(1, 25)`): a land sample
  at the origin, inner corners at +(1..2, 0..1), a 3×3 pool at +(0..2, 2..4);
  three frames three columns apart, played 1-2-3-2 (0.28 s). Built into a
  generated atlas so each tile animates.
- **Cliffs.** Brown (x + 0) or grey stone (x + 10): N rim `(1–3, 14)`, west
  side `(1, 16)` (flipped for the east), S rim `(1–3, 17)`, a two-row face
  `(1–3, 18–19)`, stairs four wide `(5–8, 22–24)`, a cave mouth
  `(4, 18–19)`. A plateau top is reached only by its stairs.
- **Houses** (`house.png`). A gable roof seven wide: roof rows 9–11 at
  `ROOF_X` (grey, red, straw, dark, blue, green), a two-row gable end at
  `GABLE_ROW`, a wall band at `WALL_ROW` (plaster, beamed plaster, logs,
  stone, dark stone) with posts in columns 1 and 3, fill 2, door 5, and
  window pairs. Stone walls use only the first two window pairs (the others
  carry snow). Each house is composed into one sprite, y-sorted at its wall
  foot; the lower part blocks.
- **Props** (`outside.png`, `PROPS` in `tf_terrain.gd`: rect, foot, collider,
  tag). Trees by set (green, pines, autumn, blossom, teal, dead), stumps,
  logs, rocks, crystals, clutter, graves, tent, spit, signs, firepits (with
  the `animated/fireplace.png` flames in the pit), braziers
  (`animated/torch.png` column 1, five frames). The bare trees' loose
  knothole piece is erased from their crop (`erase`), and the snow on the
  giant trees' roots is dropped (`unsnow`). On autumn maps, green grass
  painted at a prop's foot is recolored to the gold grass; pines are not
  used there.

**Green grade.** Out of the box the greens are loud beside Painted Lands
(lawn (100, 163, 63), saturation 0.62 against 0.40, and every grass cell a
four-color speckle with a brightness spread of about 32, where Painted Lands
lawn cells are flat). `timefantasy.gd` grades `terrain`, `outside`, `water`,
and `house` once at load (about 0.35 s), greens only (hue 0.19–0.45, fading
over 0.05): hue +0.02, saturation × 0.68, brightness pulled 40 % toward 0.56
(calms the speckle), then × 0.9. The lawn becomes (96, 139, 81). Dirt, roofs,
flowers, gold autumn grass, and water keep their colors; the green season's
blade and wave tips go through the same grade. `grade = false` shows the
sheets as drawn. The pack files are never changed. The squeeze also narrows
the gap between grass tones, so the deep fills (used only by the zones) are
then dimmed × 0.86 (`DEEP_VALUE`): lawn 0.54, mid 0.48, deep 0.39 brightness.

## Pipeline

Recipe (`id % 20`), then: plateaus, ponds (rectangles with bumps), a stream
with a bridge (Riverside), houses, forest-floor zones, paths (A* with a noise cost
so they wind; two wide; layouts cross, road, village plaza, shore, trail, to
the plateau stairs), the set piece, then a spur from the path to it (camp,
graves, giant tree, quarry, crystals), the zones settled, dirt patches, tree
scatter (crowding into the zones),
small scatter and flowers, the liveliness floor, then autotiling. Checks: the
spawn reaches every goal.

**Forest-floor zones** (green season only, like the Painted Lands tone
zones): one noise field, two nested levels. Mid covers the recipe's share
(at least 0.2 when the recipe has zones), deep 0.4 of that, its cut at least
0.1 above mid's so mid keeps a band round it. After the paths and set piece,
the field is pulled down near paths, water, cliffs, and stairs (their tiles
bake the light lawn): no zone within one cell, fading back in over four.
Components under six cells are dropped from the field too. Cells inside a
level take its fills; cells where levels meet are drawn per pixel from the
field (bilinear, wobble, Bayer dither), so no edge follows the grid.

**Dirt patches** (every map, 3–5, `patches` in a recipe overrides): rounded
rectangles 3×3 to 5×3 or two joined with arms at least three thick (the
sheet's diagonal outer corners turn a 2×2 into a diamond), in dirt, or gravel
on gravel-road recipes (packed dirt reads as pale sand). The ground tiles bake
the light lawn, so a patch stays two cells off the zones, three from any path,
four from another patch. They are `paths` cells autotiled with the paths
(`patches` marks them; wayside braziers never stand on them).

Recipes: 0 Meadow, 1 Village green, 2 Hamlet road, 3 Lakeside, 4 Forest
glade, 5 Pine woods, 6 Autumn woods, 7 Cliffside, 8 Terraces, 9 Stone quarry,
10 Campsite, 11 Graveyard, 12 Blossom grove, 13 Crystal hollow, 14 Farmstead,
15 Market square, 16 Riverside, 17 Marsh, 18 Autumn hamlet, 19 Giant tree.

## Liveliness

The Painted Lands ambience through its generic setups: wind, leaves from every
crown (colors from each tree's sprite), wind streaks, cloud shadows (green, or
brown on autumn), grass waves and footstep blades (sunlit tips lighter than
the season's grass), water life on open water, critters (butterflies,
dragonflies, fireflies in the zones), wildlife planned from the finished map,
drifters, fire glow and smoke (firepits, braziers, and chimney smoke from 60 %
of houses). Liveliness floor with the Painted Lands frozen weights: while the
weakest 43×18 window is under 0.09 %, it gets a campfire in a clearing (off
the path) or a pair of braziers facing each other across a path in the
window (both or neither), at most five anchors, each kept only if every goal
still reaches.

