# Painted Lands art fit: what goes with what

The one reference for combining the antarcticbees tilesets in
`I:\game assets\antarcticbees asset packs` (everything except the
`FULL VERSION NPC - Characters` and `RPG Characters` folders). All of them are
by the same artist, on a 16 px grid, with the same outline weight and
shading, so style is never the problem; **ground color, baked-in ground, and
brightness** are. Read this before putting art from one pack on another's
maps. Pack-specific drawing rules stay in `docs/painted-lands.md`,
`docs/green-caves.md`, and `docs/interiors.md`.

Assessed 2026-09-28 by measuring every sheet's colors against every other
sheet and by test compositions on each ground (grass, cave floor, interior
floor). Pixel coordinates are `x, y, w, h` on the named sheet; cell
coordinates are `(column, row)` of 16 px cells.

## The packs

| Pack | Source folder | Sheets | In the project |
|---|---|---|---|
| **Forest** | `The Painted Lands - Forest Tileset` | `brighter version/TILESET_brighter.png` (816×480), `original version/TILESET.png` (the same art, darker), `explanations.png`, `character_sprite_sheet.png` (the walker) | `assets/pack/TILESET_brighter.png`, `character_sprite_sheet.png`: forest, wilds, randomizer-paintedlands |
| **Green Caves** | `The Painted Lands - Green Caves Tileset` | `green_caves_tileset.png` (800×304), `explanations.png`, slimes (characters) | `assets/pack/green_caves/`: randomizer-greencaves |
| **Cozy Cottage** | `FULL VERSION Interior-Cozy Cottage Tileset by antarcticbees` | `wallpapers_and_floors.png`, `furniture.png` (five wood tones, 288 px apart), `decoration.png`, no-shadow copies | `assets/pack/cozy_cottage/`: every home interior |
| **Farm – 4 Seasons** | `FULL VERSION Farm - 4 Seasons 16x16 Tileset by antarcticbees` | `tilesets/farm_spring_summer.png` (1200×720), `farm_autumn.png`, `farm_winter.png`, `crops.png`, no-shadow copies, `tileset_explanations.png`; tree, windmill, and gate animations; `fishes.png`; the farmer (a character) | not yet; would go to `assets/pack/farm/` (git-ignored) |

Characters (the walker, slimes, farmer) are separate sprites and are not
covered here.

## How close the colors are

Each cell: the median RGB distance from the row sheet's pixels to the
nearest color of the column sheet, and in brackets the share of pixels within
24. Lower and higher-bracket means the row's art sits better on the column's
maps. Brightness (HSV value) and saturation per sheet at the end.

| row → column | Forest br. | Forest orig. | Caves | Cozy walls | Cozy furn. | Cozy deco | Farm spring | Farm autumn | Farm winter | Crops |
|---|---|---|---|---|---|---|---|---|---|---|
| **Forest brighter** | 0 | 6 (100) | 15 (94) | 21 (76) | 16 (90) | 13 (97) | 6 (100) | 6 (100) | 5 (99) | 15 (92) |
| **Forest original** | 7 (100) | 0 | 15 (86) | 22 (55) | 15 (96) | 15 (97) | 7 (100) | 8 (100) | 8 (100) | 19 (88) |
| **Green Caves** | 17 (83) | 14 (96) | 0 | 25 (48) | 12 (79) | 14 (91) | 8 (99) | 8 (99) | 10 (99) | 24 (53) |
| **Cozy walls/floors** | 15 (86) | 16 (69) | 19 (80) | 0 | 4 (100) | 5 (100) | 10 (79) | 9 (79) | 8 (88) | 12 (62) |
| **Cozy furniture** | 17 (74) | 19 (65) | 21 (65) | 3 (93) | 0 | 2 (100) | 14 (84) | 12 (82) | 12 (84) | 15 (68) |
| **Cozy decoration** | 23 (66) | 29 (42) | 24 (51) | 3 (90) | 2 (99) | 0 | 22 (56) | 22 (55) | 18 (76) | 34 (39) |
| **Farm spring/summer** | 10 (97) | 13 (94) | 20 (63) | 18 (64) | 10 (89) | 11 (96) | 0 | 3 (99) | 6 (100) | 10 (89) |
| **Farm autumn** | 14 (88) | 12 (94) | 20 (67) | 8 (83) | 10 (95) | 11 (96) | 4 (100) | 0 | 6 (99) | 10 (88) |
| **Farm winter** | 15 (81) | 16 (69) | 18 (77) | 10 (78) | 7 (98) | 10 (97) | 8 (80) | 8 (74) | 0 | 18 (56) |
| **Crops** | 20 (73) | 22 (62) | 22 (57) | 28 (43) | 9 (87) | 9 (93) | 9 (99) | 5 (99) | 9 (86) | 0 |

| Sheet | Value | Saturation | Main ground color |
|---|---|---|---|
| Forest brighter | 0.52 | 0.37 | lawn `(83, 131, 79)` |
| Forest original | 0.49 | 0.37 | darker lawn |
| Green Caves | 0.44 | 0.37 | light floor `(199, 197, 193)`, dark floor `(162, 160, 160)` |
| Cozy walls/floors | 0.62 | 0.34 | wood planks, pastel papers |
| Cozy furniture | 0.70 | 0.29 | five wood tones |
| Cozy decoration | 0.79 | 0.18 | pastel, very light |
| Farm spring/summer | 0.53 | 0.47 | lawn `(105, 150, 84)` (brighter, greener than Forest) |
| Farm autumn | 0.56 | 0.50 | autumn grass and leaves |
| Farm winter | 0.68 | 0.38 | snow |
| Crops | 0.56 | 0.60 | — |

What the table says: Farm and Forest are near neighbors (Farm is a little
more saturated); Green Caves is its own darker, bluer world (its colors are
all near Farm's larger palette, but not the other way round); Cozy decoration
is pastel and bright, an indoor palette.

## Rules that hold for every combination

1. **A map has one ground.** Lawn, cave floor, or interior floor decides
   the map. Never tile one pack's ground next to another's (Forest lawn
   beside Farm lawn shows a seam; cave floor beside lawn is a hard edge).
2. **Baked ground travels with the sprite.** A prop whose bottom pixels are
   grass, water, or a floor tone goes only on that ground: Forest land rocks
   and Farm crates-on-grass only on lawn; water rocks and reeds only in their
   own pack's water; cave props with rock bases anywhere hard.
3. **Loose props travel.** Wood, stone, metal, and fire with a transparent
   base (crates, barrels, chests, logs, stumps, signs, rocks without grass,
   torches, campfires) sit on any ground of any pack.
4. **Foliage stays outdoors or on moss.** Trees, bushes, and grass belong on
   lawn; in a cave only on a moss floor or a lit grotto.
5. **Interiors stay inside.** Cozy Cottage walls, floors, rugs, and most
   decoration are too light for outdoor ground; they are used behind a door
   (Painted Lands houses) or inside a rock ring (cave homes).
6. **One Forest edition per project.** The project uses the brighter one;
   never mix it with the original (6–7 apart everywhere).
7. **One water per pond.** Forest water is pale, Green Caves water deep teal,
   Farm water bright blue: never join two in one body of water; a map can
   hold separate ponds of different packs only if they are far apart (better:
   use the map's own pack's water).
8. **Seasons are whole maps.** Farm autumn and winter ground does not sit
   beside green lawn; use it for a whole seasonal map.

## Every pairing

### Forest ↔ Green Caves

**Forest art on cave maps**

| Fits | Forest props (`PROPS` in `forest_terrain.gd`) |
|---|---|
| yes, any cave floor | `log`, `log_b`, `crate`, `crate_b`, `crate_stack`, `crate_stack_b`, `crate_stack_c`, `chest`–`chest_d`, signs `(27–28, 23–27)`, `torch`/`torch_b`/`torch_c`, `campfire`, `campfire_big` + `ash`, fence rails and posts without grass `(29–31, 24–27)` |
| on a moss floor or a grotto only | `bush_round`, `bush_berry`, `bush_small`, `bush_small_b`, `shrub_holey`, `shrub_flower`, the trees `tree_a`/`tree_b`/`bloom_*` (not the `*_base` or shade variants), vines `(5–6, 18–19)`, `vine_column` |
| no | land rocks `rock_*` (grass at their base), `tall_grass`, flowers and sprouts, `*_base` trees and shade trees (baked lawn), water plants and water rocks (Forest water), `flowerpot`, `deck`, houses, cliffs, plateaus, ridges, outcrops (baked lawn tones), all lawn and dirt tiles |

**Green Caves art on Forest maps**

| Fits | Green Caves props (`PROPS` in `cave_terrain.gd`) |
|---|---|
| yes, on lawn | `boulder`, `rock`, `rock_small`, `rock_moss`, `rock_skull`, ore (`ore_silver`, `ore_dark`, `ore_gold`) as a mine or ruin, crystals and shards (a magic grove or ruin), stalagmite cones `cone`/`cone_b`/`cone_small` (a rocky outcrop), `tree_dead`, `tree_mossy`, `tree_tall`, `tree_slim`, `rock_tree*`, `bush`, `bush_small`, `branch`/`branch_moss`, `plant`/`plant_flower`/`grass_clump`, `pillar`/`pillars` (ruins), `skull`/`skull_b`, `chest*`, `crates`/`crate`, `barrel*`, `trough`, `ladder`, boards, `signpost`, carts and coal (a mine entrance), `campfire`, `torch`, `embers` |
| no | cave floors, dark zones, wall masses, terraces, stairs, cave pools and their ring, rails (they need the cave floor), the cave doorway |

**Joint maps:** a Forest map with a mine or ruin corner (cave rocks, ore,
carts, pillars, crystals on lawn around the Forest cave mouth
`(7–9, 18–20)`); a moss cave with Forest bushes and trees in a lit grotto.
The two grounds never touch; move between them through a doorway (the
Forest cave mouth or the Green Caves doorway) as separate maps.

### Forest ↔ Cozy Cottage

- **In use:** every Painted Lands house in the randomizer opens onto a Cozy
  Cottage interior (`house_interiors.gd`); the Forest roofs and plank walls
  and the Cozy wood tones read as one house.
- **Cozy outdoors:** potted plants `(49, 11)`, `(98, 9)`, `(112, 7)` on the
  decoration sheet, baskets `(275, 57)`, `(291, 57)`, a bench (furniture
  `(96, 196, 32, 18)`), barrels and crates from the furniture set can stand on
  a porch or by a door. Not outdoors: rugs, lamps, window boxes, wallpaper,
  floors, beds, tables (too light and clearly indoor).
- **Forest indoors:** crates, chests, logs, and a campfire-free `torch` can
  stand in a cottage (storage, workshop, cellar); no plants, rocks, or
  grass.

### Forest ↔ Farm – 4 Seasons

The closest pair: 97 % of Farm spring/summer pixels are within 24 of a
Forest color (median 10).

- **Sprites (spring/summer, 156 of 156):** all fit on Forest lawn. 132 as
  they are: trees (big oaks, dead trees, a pine, bushes), fruit trees in four
  kinds (apple, cherry, orange, peach) as saplings, plain, blossom, fruit,
  and bare (mature ones at `(513–703, 486–720)` in rows of three), logs,
  stumps, mushrooms, rocks, crates, barrels, chests, bucket, hay, wheat,
  troughs, signs, mailbox, scarecrow, fences and gate, and the buildings:
  two farmhouses `(816, 385, 91, 95)`, `(912, 385, 91, 95)`, a larger house
  `(1014, 391, 103, 103)`, a barn `(829, 485, 102, 91)`, the barn yard kit
  `(960, 493, 128, 83)`, a greenhouse (top right), two windmills
  `(776, 587, 80, 117)`, `(872, 587, 80, 117)`. 24 more carry a small tuft of
  Farm grass (flowers, sprouts, fence corners, crates on grass, e.g.
  `(4, 246, 26, 23)`, `(224, 194, 40, 46)`): usable, the tuft a shade
  brighter.
- **Crops (82):** all fit, on the Farm's tilled soil.
- **Terrain without grass (699 of 1,545 spring/summer cells):** fits: tilled
  soil and crop rows (~`(640–1020, 190–350)`), dirt paths, rock faces, the
  greenhouse floor.
- **Terrain with Farm grass baked in (846 cells):** grass tone blobs
  `(432–624, 0–380)`, grass-edged cliffs and paths `(576–1020, 0–190)`, island
  and shore sets `(0–400, 317–656)`. A seam against Forest lawn as they are; a
  nearest-color remap to the Forest palette brings them close (the light
  cliff-top green stays a little brighter). Remap first, or use them only on
  maps that are Farm lawn throughout.
- **Water:** keep Farm ponds separate (bluer).
- **Animations (~130 sheets):** tree chopping, leaves in the wind, falling
  leaves, the windmill (5), the gate (2): fit.
- **Farm autumn:** props and trees fit on Forest lawn (autumn trees next to
  green ones read as a turning tree); the ground does not (whole autumn
  maps).
- **Farm winter:** only as whole winter maps (snow ground, snowy props); a
  Forest house can stand in it (roofs match) but Forest trees are summer
  green.
- **Forest on Farm maps:** every Forest prop and house fits on Farm lawn
  (the same distance the other way); Forest lawn tiles do not (seam).

### Green Caves ↔ Cozy Cottage

- **In use:** cave homes (`cave_terrain.gd` `_home()`): an interior inside a
  ring of cave rock (the Cozy wall-top frames' black recolored to the rock),
  entered through the cave doorway arch.
- **Cozy in the open cave:** barrels, crates, a bench, baskets near a home's
  door; nothing light (rugs, lamps, pastel decoration) outside the ring.
- **Caves indoors:** crystals and shards on shelves or tables, barrels,
  crates, chests, a ladder, ore in a cellar; the cave's campfire only as a
  hearth substitute in a rough home.

### Green Caves ↔ Farm – 4 Seasons

About 52 of the 156 spring/summer sprites suit a cave floor (a third); the
autumn and winter sheets hold more of the same kinds. They read slightly
warmer and brighter than the cave's own props. Pixel boxes on
`farm_spring_summer.png`:

| Kind | Count | Sprites |
|---|---|---|
| Dead trees | 8 | `(130, 20, 29, 44)`, `(258, 24, 39, 56)`, `(92, 73, 49, 71)`, `(83, 152, 47, 71)`, `(750, 408, 57, 56)`, `(722, 502, 39, 58)`, `(722, 584, 39, 56)`, `(722, 664, 39, 56)` |
| Logs | 7 | `(144, 9, 16, 7)`, `(192, 105, 16, 7)`, `(209, 98, 31, 14)`, `(736, 393, 16, 7)`, `(704, 489, 16, 7)`, `(704, 569, 16, 7)`, `(704, 649, 16, 7)` |
| Stumps | 7 | `(172, 4, 12, 12)`, `(195, 116, 11, 12)`, `(57, 128, 22, 16)`, `(755, 390, 12, 10)`, `(732, 486, 12, 10)`, `(731, 566, 12, 10)`, `(731, 646, 12, 10)` |
| Crates | 7 | `(1121, 146, 24, 14)`, `(65, 226, 24, 14)`, `(37, 246, 22, 20)`, `(65, 242, 24, 14)`, `(65, 257, 15, 15)`, `(81, 257, 15, 15)`, `(33, 273, 15, 15)` |
| Mushrooms | 5 | `(195, 81, 10, 14)`, `(209, 83, 14, 12)`, `(227, 84, 10, 11)`, `(246, 80, 20, 16)`, `(275, 82, 12, 13)` |
| Rocks | 3 | `(242, 109, 29, 19)`, `(242, 128, 26, 16)`, `(241, 154, 29, 22)` |
| Chests (rows of three) | 3 | `(144, 242, 48, 14)`, `(144, 258, 48, 14)`, `(144, 274, 48, 14)` |
| Hay | 3 | `(359, 233, 34, 30)`, `(1092, 499, 42, 27)`, `(1088, 529, 48, 31)` |
| Barrels | 2 | `(55, 279, 18, 25)`, `(87, 279, 18, 25)` |
| Troughs | 2 | `(948, 524, 26, 15)`, `(980, 524, 26, 15)` |
| Bucket | 1 | `(99, 227, 11, 13)` |
| Fruit (on tables, in a pantry) | 4 | `(644, 375, 9, 9)`, `(660, 375, 9, 9)`, `(676, 376, 9, 8)`, `(690, 373, 8, 10)` |

Mushrooms are the strongest fit (the caves have none). The crates with a
grass tuft (`(4, 246)`, `(4, 278)`, `(33, 289)`) show green on grey: use the
plain ones. **Not in caves:** all Farm terrain, living trees and bushes,
crops and wheat, buildings, fences, the windmill. **Cave art on Farm maps:**
the same as cave art on Forest maps (rocks, ore, crystals, carts, pillars,
dead and mossy trees, barrels, crates), for a mine or quarry at the edge of a
farm.

### Cozy Cottage ↔ Farm – 4 Seasons

- **Farm buildings get Cozy interiors** the same way Forest houses do: the
  two farmhouses and the larger house (living, kitchen, bedrooms), the barn
  (one or two big rooms: hay, barrels, crates, a workbench from the Cozy
  tables), the greenhouse (tile floor, plant shelves, potted plants, the Farm
  crops in planters), the windmill (a round single room: sacks as barrels
  and crates, a ladder).
- **Farm indoors:** fruit `(644–698, 373–385)`, crops, baskets, barrels,
  crates, hay in a barn, the bucket, mushrooms in a pantry; wheat as a
  decoration in a vase is fine.
- **Cozy outdoors on a farm:** as with Forest (porch plants, baskets,
  benches).
- Cozy decoration is the brightest sheet (value 0.79); on a winter farm map
  (value 0.68) it clashes least.

### Within a pack

- **Forest brighter vs original:** never both.
- **Farm seasons:** spring/summer, autumn, winter share layouts and styles;
  each map picks one season for its ground. Within a season, the no-shadow
  copies are for layered shadows only (use one or the other).
- **Cozy wood tones:** five furniture tones; a home keeps one tone
  (`InteriorPlan.style.wood`). Wallpaper groups match wall-top frames by trim
  color (docs/interiors.md).

## Combinations of three or more

| Map idea | Ground | From each pack |
|---|---|---|
| Farm village with enterable homes | Forest lawn (or Farm lawn remapped) | Forest paths, ponds, houses, props; Farm fields, crops, fruit trees, barn, windmill, fences, scarecrow; Cozy interiors behind every door (farmhouses, barn, greenhouse, windmill) |
| Village with a mine | Forest lawn | Forest village; Green Caves rocks, ore, carts, rails only as props, a pillared mine mouth by the Forest cave mouth; the mine itself a separate Green Caves map through the doorway |
| Underground homestead | Green Caves floor (moss) | cave homes (Cozy interiors), Farm mushrooms, crates, barrels, hay, logs, a Farm dead tree; Forest crates, chests, torches, campfire |
| Seasonal hamlet (autumn or winter) | Farm autumn or winter ground | Farm season trees, props, buildings; Forest houses (roofs match), crates, chests, signs, torches; Cozy interiors |
| Ruined grove | Forest lawn | Forest trees and lawn; Green Caves pillars, crystals, skulls, mossy trees, rocks |
| Farm with a cellar | Farm/Forest lawn outside, Green Caves inside | the cellar a separate cave map (dark floor, a cave home or storage room with Cozy shelves, Farm barrels, crates, fruit) |

## Never

- Forest lawn next to Farm lawn (seam) or next to any cave floor.
- Forest land rocks, tall grass, flowers, `*_base` trees, or outcrops on a
  cave floor (baked lawn).
- Water props of one pack in another pack's water; two packs' water in one
  pond.
- Farm grass-baked terrain on a Forest map without the color remap.
- Cozy rugs, floors, wallpaper, lamps, or beds outdoors.
- Farm autumn or winter ground beside green lawn.
- The two Forest editions together.
- Characters (walker, slimes, farmer, NPC and RPG sheets) painted into any
  tile layer.

## Counts

| From → on | Forest lawn | Green Caves floor | Cozy interior |
|---|---|---|---|
| Forest props (64 in `PROPS`) | all | ~20 (wood, crates, chests, signs, fire; bushes and trees on moss only) | ~10 (crates, chests, logs, torch) |
| Green Caves props (54 in `PROPS`) | ~50 (all but the few that need cave floor context) | all | ~12 (crystals, shards, barrels, crates, chests, ladder, ore) |
| Cozy furniture and decoration | ~10 on a porch (plants, baskets, bench, barrels, crates) | ~6 by a home's door (barrels, crates, bench, baskets) | all |
| Farm spring/summer sprites (156) | 156 (24 with a brighter tuft) | ~52 | ~25 (fruit, crops, baskets, barrels, crates, hay, bucket, mushrooms) |
| Farm spring/summer terrain (1,545 cells) | 699 as they are, 846 after a remap | 0 | 0 |
| Farm crops (82) | 82 | 0 | as decoration (planters, baskets) |
| Farm autumn / winter | props yes, ground as whole maps | similar props | as spring |
| Farm animations (~130) | all | none needed | none |
