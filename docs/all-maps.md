# All maps

Every map this project can currently generate, grouped by the tilesets
drawn on it. A "map type" is one recipe of a scene's generator; each
randomizer builds endless maps from its map types (the map id picks the type
and seeds the layout), and the two fixed scenes pin one map each. Only
current tilesets are listed: The Painted Lands packs (Forest, Green Caves,
Cozy Cottage, Farm – 4 Seasons), Pixel Crawler, and the Cozy Farm animals
(the only part of that pack still in use). The deprecated packs and scenes (Mystic Woods, Mana
Seed, and the cozy farm randomizer with the Cozy Farm buildings) and the
unsuitable pack (Time Fantasy) are left out; the cozy farm randomizer's
record is listed at the end.
Every map below is walked by the Painted Lands walker
(`character_sprite_sheet.png`); the small animals, insects, birds, and
effects drawn in code are on all of them and are not counted as a tileset.
The Cozy Farm animals (`assets/pack/cozy_farm/animals/`, the `cozy_animals`
option) live in the three Painted Lands randomizers (in the farm
randomizer also in every pen): the bunny in place of
the drawn rabbit wherever there is lawn or moss, and farm animals (chickens,
turkeys, pigs, sheep, goats, cows) only round homes. The fixed maps keep the
drawn animals.
Rules for each pack: `docs/painted-lands.md`, `docs/green-caves.md`,
`docs/interiors.md`, `docs/farm.md`, `docs/pixel-crawler.md`.

## Summary

| Tilesets | Scene | Map types |
|---|---|---|
| Painted Lands Forest | `forest` (fixed map), `wilds` (fixed map) | 2 fixed maps |
| Painted Lands Forest + Cozy Farm (bunnies) | `randomizer-paintedlands` | 8 |
| Painted Lands Forest + Cozy Cottage (interiors) + Cozy Farm (bunnies, farm animals) | `randomizer-paintedlands` | 25 |
| Painted Lands Forest + bridges (generated, Forest colors) + Cozy Cottage (interiors) + Cozy Farm (bunnies, farm animals) | `randomizer-paintedlands` (rivers) | 3 |
| Painted Lands Green Caves | `randomizer-greencaves` | 23 |
| Painted Lands Green Caves + Cozy Farm (bunnies) | `randomizer-greencaves` | 3 |
| Painted Lands Green Caves + Cozy Cottage (homes) + Cozy Farm (farm animals) | `randomizer-greencaves` | 7 |
| Painted Lands Farm (spring and summer) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 2 |
| Painted Lands Farm (spring and summer) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 30 (2 of them rivers with bridges) |
| Painted Lands Farm (autumn) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 11 (1 river with bridges) |
| Painted Lands Farm (winter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 9 (1 river with bridges) |
| Painted Lands Farm (spring and summer) + Forest (houses, fires, clutter, summer trees) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 6 |
| Painted Lands Farm (autumn) + Forest (houses, fires, clutter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 3 |
| Painted Lands Farm (winter) + Forest (houses, fires, clutter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 3 |
| Pixel Crawler Fairy Forest | `randomizer-pixelcrawler` | 6 |
| Pixel Crawler Farm forest + Green Woods | `randomizer-pixelcrawler` | 5 |
| Pixel Crawler Cemetery | `randomizer-pixelcrawler` | 3 |
| Pixel Crawler Desert | `randomizer-pixelcrawler` | 3 |

150 map types in all (36 Painted Lands, 33 Green Caves, 52 Farm in three
seasons, 12 farmsteads, 17 Pixel Crawler) and 2 fixed maps.
`randomizer-paintedlands-forest-farm` builds all 100 Painted Lands map types
(the 36 Forest, the 52 Farm, and the 12 farmsteads, which only it builds).

**Bridges.** Where a road or lane crosses a river or a brook on the Painted
Lands maps it goes over a bridge: 24 designs (plank, rope, boards, logs,
boardwalk, clapper slabs, stone, mossy, and sandstone arches, lanterns,
lattice, flowers, trestle, painted rails, and more) drawn for the purpose in
the Forest's and the Farm's own colors, with a snowy Farm set for winter
(`assets/ai/bridges/`, `scripts/bridges.gd`, docs/bridges.md). The Forest
rivers are map types 33-35; the Farm brooks (1 Wheat valley, 11 Riverside
fields, farmstead 54 Hamlet by the mill) and rivers (48-51) bridge every
crossing whose banks allow it (the rest keep stepping stones). Painted Lands and Pixel Crawler never share a map, and
the Cozy Farm animals never go on a Pixel Crawler map.

## Painted Lands Forest

`assets/pack/TILESET_brighter.png`. The fixed scenes have no house doors.

| Scene | Map id | Map type |
|---|---|---|
| `scenes/forest/forest.tscn` | 91003 | 3 Garden (hut in a fence yard with a gate) |
| `scenes/wilds/wilds.tscn` | 75125 | 5 Open meadow |

`randomizer-paintedlands` map types with no house (id % 36), with Cozy Farm
bunnies but no farm animals:

| # | Map type |
|---|---|
| 5 | Open meadow |
| 12 | Wild lane |
| 18 | Sparse wild |
| 20 | Cave mouth |
| 22 | Stone ruins |
| 24 | Rock garden |
| 25 | Deep forest |
| 29 | Walled mesa |

## Painted Lands Forest + Cozy Cottage + Cozy Farm animals

`randomizer-paintedlands`: every house opens onto a furnished interior drawn
from Cozy Cottage (`assets/pack/cozy_cottage/`), and keeps one to three
kinds of Cozy Farm animals: chickens, turkeys, and pigs in its yard, sheep,
goats, and cows on the lawn round it (the kinds vary by map id). Bunnies as
on the other maps.

| # | Map type | Houses (interiors) |
|---|---|---|
| 0 | Pastoral | porch cottage |
| 1 | Crossroads | flower cottage |
| 2 | Pond walk | gable cottage |
| 3 | Garden | hut |
| 4 | Lookout | porch cottage |
| 6 | Twin water | flower cottage |
| 7 | South road | gable cottage |
| 8 | Shore spur | hut |
| 9 | Three-way | porch cottage |
| 10 | West hamlet | flower cottage, hut |
| 11 | East hamlet | gable cottage |
| 13 | Orchard | hut |
| 14 | Shore hamlet | porch cottage |
| 15 | Double lean | flower cottage |
| 16 | Below the rim | gable cottage |
| 17 | Gate road | hut |
| 19 | Switchback | porch cottage |
| 21 | Terraces | hut |
| 23 | Woodcutter camp | shed, barn |
| 26 | Village square | porch, flower, and gable cottages |
| 27 | Hedge garden | gable cottage |
| 28 | Ridgeline | flower cottage |
| 30 | Cottage row | flower cottage, gable cottage, hut |
| 31 | Twin cottages | porch cottage, gable cottage |
| 32 | Manor green | porch cottage, hut |
| 33 | River crossing | hut (a river north to south, the road over a bridge) |
| 34 | River lane | flower cottage (a river west to east, the lane over a bridge) |
| 35 | Twin bridges | porch cottage, hut (two roads, two bridges) |

## Painted Lands Green Caves

`randomizer-greencaves` (id % 33), `assets/pack/green_caves/`. Only the
drawn cave animals (mice, lizards, frogs, voles):

| # | Map type | # | Map type |
|---|---|---|---|
| 0 | Grotto | 16 | Twin pools |
| 1 | Crystal cavern | 17 | Crystal shrine |
| 2 | Flooded hall | 18 | Dark depths |
| 3 | Mine shaft | 19 | Collapsed tunnel |
| 6 | Terrace steps | 21 | Watch post |
| 7 | Ossuary | 23 | Echo chamber |
| 8 | Pillared hall | 24 | Lake terrace |
| 9 | Stalagmite field | 25 | Coal store |
| 10 | Underground spring | 26 | Crossroads cavern |
| 11 | Ore vein | 29 | Treasure vault |
| 12 | Dead grove | | |
| 13 | Cave mouth | | |
| 15 | Rail junction | | |

## Painted Lands Green Caves + Cozy Farm animals

`randomizer-greencaves`: moss floors, with Cozy Farm bunnies among the drawn
cave animals.

| # | Map type |
|---|---|
| 5 | Mossy hollow |
| 20 | Overgrown mine |
| 28 | Sunken garden |

## Painted Lands Green Caves + Cozy Cottage + Cozy Farm animals

`randomizer-greencaves`: homes built into the cave, furnished from Cozy
Cottage, with one to three kinds of Cozy Farm animals: chickens, turkeys,
or pigs in the yard outside each arch, and on the moss floors sheep, goats,
or cows round it too, and bunnies.

| # | Map type | Homes (rooms) | Floor |
|---|---|---|---|
| 4 | Miners' camp | 1 (2-3) | light |
| 14 | Smugglers' cache | 1 (1-2) | dark |
| 22 | Root cellar | 1 (2-3) | dark |
| 27 | Hermit's nook | 1 (1-2) | moss |
| 30 | Hermit's home | 1 (1-2) | moss |
| 31 | Cave hamlet | 3 (1-2 each) | light |
| 32 | Underground manor | 1 (5-6) | dark |

## Painted Lands Farm – 4 Seasons (spring and summer)

`randomizer-paintedlands-farm` (id % 52), `assets/pack/farm/` (the spring
and summer, autumn, and winter tilesets, `crops.png`, the tree, windmill,
and gate animations of each season, and the fish). Each map is wholly one
season: its ground, trees, buildings, windmill, gate, and props all come
from that season's sheets, never mixed. The Cozy Farm animals are on every map (herds in the pens,
poultry and pigs in the yards, bunnies on the lawn). Every building has a
door into its own interior sub-map. No Forest (`TILESET_brighter.png`) tile
is on these maps. This section and the next list the spring and summer map types.

Farm and Cozy Farm animals only (no Cozy Cottage):

| # | Map type | Buildings (interiors) |
|---|---|---|
| 20 | Wildflower meadow | none |
| 28 | Orchard and greenhouse | greenhouse (the Farm sheet's own glasshouse) |

## Painted Lands Farm (spring and summer) + Cozy Cottage + Cozy Farm animals

`randomizer-paintedlands-farm`: farmhouses and the manor open on Cozy
Cottage homes; the barn on a barn (the Farm sheet's barn-yard kit, a Cozy
Cottage plank floor, straw, stalls, hay, and animals inside); the windmill
on a mill floor (Cozy Cottage walls and floor, Farm sheet grain, crates,
and barrels, and the mill machinery, sacks, ladder, and hoist from the
generated mill kit, `assets/ai/mill/`, drawn in the Farm sheet's colors
because no pack has them); the greenhouse on the Farm sheet's own
glasshouse.

| # | Map type | Buildings (rooms) | Farm features |
|---|---|---|---|
| 0 | Homestead | farmhouse (2-4), barn (its own barn interior) | fields, pen, pond |
| 1 | Wheat valley | windmill (its own mill floor), farmhouse (2-4) | wheat, crop rows, brook |
| 2 | Windmill hill | windmill (its own mill floor) | plateaus, wheat, corn rows |
| 3 | Apple orchard | farmhouse (2-4) | apple orchard, pond |
| 4 | Cherry blossom lane | manor (3-6) | cherry orchard |
| 5 | Pumpkin patch | barn (its own barn interior) | pumpkin and melon fields |
| 6 | Kitchen garden | farmhouse (2-4) | small vegetable beds |
| 7 | Greenhouse garden | greenhouse, farmhouse (2-4) | berry and tomato rows, peaches |
| 8 | Barnyard | barn (its own barn interior), farmhouse (2-4) | two pens, corn rows |
| 9 | Sheep meadow | farmhouse (2-4) | two big pens, pond |
| 10 | Duck pond farm | farmhouse (2-4) | lake with an island |
| 11 | Riverside fields | farmhouse (2-4) | brook, crop rows |
| 12 | Farm village | two farmhouses (2-4), manor (3-6) | crossing roads, fields |
| 13 | Market crossroads | manor (3-6), barn (its own barn interior) | market |
| 14 | Sunflower field | farmhouse (2-4) | sunflower rows |
| 15 | Corn rows | windmill (its own mill floor), barn (its own barn interior) | corn rows |
| 16 | Berry patch | farmhouse (2-4) | berry rows, hedges |
| 17 | Hillside terraces | farmhouse (2-4) | plateaus, crop rows |
| 18 | Woodlot | farmhouse (2-4) | canopy wall, trees |
| 19 | Pine ridge | farmhouse (2-4) | plateaus, pines, pond |
| 21 | Old farm | barn (its own barn interior) | dead trees, tall grass |
| 22 | Fishing lake | farmhouse (2-4) | lake with an island |
| 23 | Cattle ranch | barn (its own barn interior), farmhouse (2-4) | big pens |
| 24 | Hayfield | barn (its own barn interior) | wheat, hay |
| 25 | Scarecrow fields | windmill (its own mill floor) | four fields |
| 26 | Twin farms | two farmhouses (2-4) | fields, pen |
| 27 | Stone quarry | farmhouse (2-4) | plateaus with a cave |
| 29 | Harvest fair | manor (3-6), farmhouse (2-4), windmill (its own mill floor) | fields, market |
| 48 | River farm | farmhouse (2-4), barn (its own barn interior) | a river, bridges, fields, pen |
| 49 | Mill on the river | windmill (its own mill floor), farmhouse (2-4) | a river, bridges, wheat |

## Painted Lands Farm (autumn) + Cozy Cottage + Cozy Farm animals

`randomizer-paintedlands-farm`, `farm_autumn.png`: tan and russet grass,
turning trees, straw, the harvest.

| # | Map type | Buildings (rooms) | Farm features |
|---|---|---|---|
| 30 | Autumn homestead | farmhouse (2-4), barn (its own barn interior) | pumpkin and cabbage fields, pen, pond |
| 31 | Pumpkin harvest | barn (its own barn interior) | pumpkin and melon fields |
| 32 | Autumn orchard | farmhouse (2-4) | apple orchard, pond |
| 33 | Golden wheat | windmill (its own mill floor), barn (its own barn interior) | straw, wheat rows, hay |
| 34 | Turning lane | manor (3-6) | turning trees |
| 35 | Autumn market | manor (3-6), barn (its own barn interior) | market, fields |
| 36 | Misty lake | farmhouse (2-4) | lake with an island |
| 37 | Cornfield | windmill (its own mill floor) | corn rows |
| 38 | Old barn in autumn | barn (its own barn interior) | dead trees, straw, hedges |
| 39 | Cider farm | farmhouse (2-4), windmill (its own mill floor) | mixed fruit orchard |
| 50 | Russet river | farmhouse (2-4), barn (its own barn interior) | a river, bridges, apple orchard |

## Painted Lands Farm (winter) + Cozy Cottage + Cozy Farm animals

`randomizer-paintedlands-farm`, `farm_winter.png`: snow, snowy and bare trees,
falling snow; no crops outdoors.

| # | Map type | Buildings (rooms) | Farm features |
|---|---|---|---|
| 40 | Snowy homestead | farmhouse (2-4), barn (its own barn interior) | pen, pond |
| 41 | Winter pasture | farmhouse (2-4) | two big pens |
| 42 | Frozen lake | farmhouse (2-4) | lake with an island |
| 43 | Snowy woodlot | farmhouse (2-4) | snowy canopy wall |
| 44 | Pine hills | farmhouse (2-4) | plateaus, pines, pond |
| 45 | Winter village | farmhouse (2-4), manor (3-6), barn (its own barn interior) | crossing roads |
| 46 | Greenhouse in the snow | greenhouse (its own glasshouse), farmhouse (2-4) | bare orchard |
| 47 | Winter windmill | windmill (its own mill floor), barn (its own barn interior) | pens, hay |
| 51 | Frozen river | farmhouse (2-4), barn (its own barn interior) | a river, snowy bridges, pen |

## Painted Lands forest and farm: the combined randomizer

`randomizer-paintedlands-forest-farm` (id % 100; `scripts/forest_farm.gd`)
holds both Painted Lands pipelines and builds every map type of the two
randomizers above, with the Cozy Farm animals in both: recipes 0-35 are the
Forest map types (`randomizer-paintedlands`, same numbers), 36-87 the Farm
map types (Farm 0-51, in three seasons), and 88-99 the farmsteads below. A
map keeps one ground: Forest lawn and Farm lawn never meet, so the pipeline
not in use is hidden and paused.

### Farmsteads (Farm ground + Forest houses, fires, and clutter)

Farm ground, crops, fences, and trees in the map's season, with the Forest
sheet's (`TILESET_brighter.png`) houses in place of the farmhouses (their
chimneys smoke, and they open on Cozy Cottage homes, rooms in brackets),
campfires with logs, ash, and crates by the doors, lanterns flanking doors
and pen gates, flowerpots, chests, and signs. The summer farmsteads add the
Forest's summer trees, blossoms, and bushes; autumn and winter use only the
Farm trees (Forest trees are summer green only).

| # (Farm #) | Map type | Season | Buildings (rooms) | Features |
|---|---|---|---|---|
| 88 (52) | Cottage homestead | summer | porch house (3-6), barn (barn interior) | fields, pen, pond, campfire |
| 89 (53) | Blossom cottage | summer | flower cottage (2-4) | cherry orchard, strawberry rows |
| 90 (54) | Hamlet by the mill | summer | gabled cottage (2-5), hut (1-2), windmill (its own mill floor) | wheat and corn rows, brook, campfire |
| 91 (55) | Woodcutter's clearing | summer | hut (1-2) | canopy wall, big fire, log piles |
| 92 (56) | Village fair | summer | porch house (3-6), flower cottage (2-4), manor (3-6) | market, two campfires |
| 93 (57) | Greenhouse cottage | summer | greenhouse (its own glasshouse), hut (1-2) | peach orchard, strawberry rows |
| 94 (58) | Lantern lane | autumn | porch house (3-6), flower cottage (2-4) | apple orchard, lantern road |
| 95 (59) | Harvest bonfire | autumn | barn (barn interior), hut (1-2) | pumpkin and corn fields, big fire |
| 96 (60) | Autumn hearths | autumn | gabled cottage (2-5), hut (1-2), windmill (its own mill floor) | crossing roads, pen |
| 97 (61) | Winter hearth | winter | porch house (3-6), barn (barn interior) | pen, pond, campfire |
| 98 (62) | Snowbound hamlet | winter | gabled cottage (2-5), hut (1-2), flower cottage (2-4) | pines, two campfires |
| 99 (63) | Frozen mill | winter | windmill (its own mill floor), hut (1-2) | frozen lake, pen |

## Pixel Crawler

`randomizer-pixelcrawler` (id % 17), `assets/pack/pixel_crawler/`. One biome
per map; biome sheets are never mixed. Every biome also takes its canopy
shadows from the Fairy Forest shadow sheet (`fairy_forest/Shadown.png`), and
its grass tufts from Painted Lands sprout shapes recolored into the biome's
own palette (shapes only, no Painted Lands colors).

Fairy Forest (`fairy_forest/`: Tiles, Props, Tree, Light, Shadown):

| # | Map type |
|---|---|
| 0 | Fairy glade |
| 1 | Runestone circle |
| 2 | Glowbell hollow |
| 3 | Twilight stream |
| 4 | Root ledges |
| 5 | Deep fairy wood |

Farm forest + Green Woods (`farm/`: Tiles, Vegetation, Trees; `green_woods/`
bushes, rocks, crates, barrels; greens graded):

| # | Map type |
|---|---|
| 6 | Greenwood |
| 7 | Forest trail |
| 8 | Island lake |
| 9 | Autumn grove |
| 10 | Crystal thicket |

Cemetery (`cemetery/`: Tiles, Trees):

| # | Map type |
|---|---|
| 11 | Old cemetery |
| 12 | Dead wood |
| 13 | Red pine hill |

Desert (`desert/`: Tiles):

| # | Map type |
|---|---|
| 14 | Dune sea |
| 15 | Bone field |
| 16 | Mesa |

## Deprecated: cozy farm randomizer

`randomizer-painted-cozyfarm` (id % 36, starting at 180033) is deprecated
and not counted above: the Painted Lands terrain with Cozy Farm homes in
place of the Painted Lands houses, farmyard outbuildings (barn, coop, silos,
windmill), three map types of its own (33 Farmstead, 34 Windmill road, 35
Farm village), and the older cozy farm animal table. The scene still runs as
a record; its map types and buildings are in
`docs/deprecated/cozy-farm.md`. Do not build new maps from it.
