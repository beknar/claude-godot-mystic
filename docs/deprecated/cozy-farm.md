# Cozy farm randomizer (deprecated)

**Deprecated.** `randomizer-painted-cozyfarm` and the Cozy Farm buildings
are no longer used in this project; only the Cozy Farm animals are (see
"Cozy Farm animals" in `docs/painted-lands.md`). This file records how the
existing scene was built. Do not add Cozy Farm buildings or the cozy-only
map types to other scenes.

`scenes/randomizer-painted-cozyfarm/randomizer-painted-cozyfarm.tscn` is the
Painted Lands randomizer (same generator, recipes, interiors, and ambience;
`forest.gd` with `interiors = true`), starting at map id `180033` pinned to
recipe 33 Farmstead, with `cozy_animals = true` and `cozy_buildings = true`
(below).

**Buildings** (`cozy_buildings = true`; `PaintedTerrain.cozy`): the Cozy
Farm homes stand in for the Painted Lands houses on every map type that has
houses (never both packs on one map), and farm outbuildings fill a farmyard.
Sheet `assets/pack/cozy_farm/buildings.png` (spring versions), drawn at 0.86
brightness (`COZY_VALUE`; the pack runs brighter than the Painted Lands
houses). Measured against the Painted Lands sheet, the homes used sit within
10-17 of its palette (83-98 % of pixels within 24).

| id | Building | Size (px) | Door | Rooms | Chimney |
|---|---|---|---|---|---|
| 10 | Farm cottage | 62 x 73 | (2, 5) | 2-3 | yes |
| 11 | Farmhouse (two wings) | 94 x 73 | (2, 5) | 3-5 | yes |
| 12 | Timber house (purple roof) | 74 x 76 | (2, 5) | 2-4 | yes |
| 13 | A-frame house (green roof) | 77 x 80 | (2, 5) | 2-4 | yes |
| 14 | Thatched cottage | 72 x 74 | (2, 5) | 1-3 | yes |
| 15 | Brick house | 82 x 69 | (1, 5) | 2-4 | no |
| 16 | Long house | 93 x 64 | (2, 4) | 2-3 | yes |
| 20 | Red barn (outbuilding; a home on Woodcutter camp) | 67 x 80 | (1, 5) | 1-3 | no |
| 21 | Coop | 60 x 64 | - | - | no |
| 22, 23 | Red silo, straw silo | 36 x 68 | - | - | no |
| 24 | Windmill (sails turn with the wind) | 56 x 67 | - | - | no |

Left out as the weakest fits: greenhouse (pale glass, lightest outlines),
blue-roof house (a blue the sheet lacks), slime hut (rainbow roof),
hospital, museum, and market (civic), and every fall and winter version.

Map types (`COZY_SWAP`: the home for each prefab a recipe names;
`COZY_FARM`: its outbuildings; houses keep each recipe's count):

| Map types | Homes | Farmyard |
|---|---|---|
| Pastoral | farm cottage | barn, red silo, coop |
| Garden, Gate road | farm cottage | coop |
| Orchard | farm cottage | barn, straw silo |
| Crossroads, Three-way, Below the rim, Ridgeline | timber | - |
| Lookout, Double lean, Terraces | A-frame | - |
| Pond walk, Twin water, East hamlet | thatched | - |
| Shore spur, Shore hamlet | thatched | coop |
| South road, Switchback | long house | red silo |
| Woodcutter camp | long house, red barn | straw silo |
| West hamlet | timber, A-frame | coop |
| Cottage row | thatched, A-frame, timber | - |
| Twin cottages | farm cottage, thatched | coop |
| Village square | timber, A-frame, brick | - |
| Hedge garden | brick | - |
| Manor green | farmhouse, brick | barn |
| Open meadow | none | windmill, straw silo |
| Wild lane, Sparse wild, Cave mouth, Stone ruins, Rock garden, Deep forest, Walled mesa | none | - |

New map types, only in this scene (`COZY_RECIPES`, ids 33-35; recipe =
map id % 36 here, so the Painted Lands scenes keep % 33 and their maps):

- **33 Farmstead** (the Pastoral layout): the farmhouse in its fenced yard,
  a barn, a coop, and both silos, with the pond south.
- **34 Windmill road** (the South road layout): a thatched cottage on the
  road, the windmill, a straw silo, and a coop.
- **35 Farm village** (the Village square layout): farm cottage, timber
  house, and thatched cottage on the square, with a barn, a coop, and the
  windmill.

Outbuildings go on the free lawn closest to the first home's doorstep (80
tries in a window round it), anywhere on the map when there is no home or no
room (the village squares), two cells clear round each, three from any other
building; a spot that would cut the spawn off from a goal is skipped, and the
report check fails a map missing one. They are not entered. Their doorsteps
count as farmyard for the animals (pigs and mice by the barn, chickens at the
coop). The windmill's sails are six pixel-art frames through a quarter turn
(nearest-pixel rotation), stepped faster in stronger wind, drawn in front of
the body. `tools/check_recipes.gd ... cozy` checks the cozy generator and
lists each map's buildings.
