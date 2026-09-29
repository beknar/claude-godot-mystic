# Mystic Woods (deprecated)

**Deprecated.** Kept as a record of how the Mystic Woods scenes were built.
Do not use Mystic Woods in new development.

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
