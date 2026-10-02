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
| Painted Lands Forest (hedge and canal mazes) + Cozy Farm (bunnies) | `maze-forest` | 19 |
| Painted Lands Forest (mazes with a cottage) + Cozy Cottage (interiors) + Cozy Farm (bunnies, farm animals) | `maze-forest` | 3 |
| Painted Lands Forest (mazes crossed on bridges) + bridges (generated) + Cozy Farm (bunnies) | `maze-forest` | 2 (Lily canals, Moat maze; Canal cottage has its cottage and bridges) |
| Painted Lands Farm (spring and summer mazes: hedges, wheat, corn, sunflowers, tall grass, canals, shrubs) + Cozy Farm (animals) | `maze-farm` | 14 |
| Painted Lands Farm (spring and summer mazes with a farmhouse, barn, windmill, or greenhouse) + Cozy Cottage (interiors) + Cozy Farm (animals) | `maze-farm` | 4 |
| Painted Lands Farm (spring and summer mazes crossed on bridges) + bridges (generated) + Cozy Farm (animals) | `maze-farm` | 3 (Mill canals and Moated farmhouse have their interiors too) |
| Painted Lands Farm (autumn mazes) + Cozy Farm (animals) | `maze-farm` | 3 |
| Painted Lands Farm (autumn mazes with a farmhouse or barn) + Cozy Cottage (interiors) + Cozy Farm (animals) | `maze-farm` | 2 (Russet canals crossed on bridges) |
| Painted Lands Farm (winter mazes: canals, snowy bushes, pines) + Cozy Farm (animals) | `maze-farm` | 2 |
| Painted Lands Farm (winter mazes with a farmhouse or windmill) + Cozy Cottage (interiors) + Cozy Farm (animals) | `maze-farm` | 2 (Frozen mill canals crossed on bridges) |
| Painted Lands Green Caves | `randomizer-greencaves` | 23 |
| Painted Lands Green Caves + Cozy Farm (bunnies) | `randomizer-greencaves` | 3 |
| Painted Lands Green Caves + Cozy Cottage (homes) + Cozy Farm (farm animals) | `randomizer-greencaves` | 7 |
| Painted Lands Green Caves (rock mazes, light and dark floors) | `maze-greencaves` | 13 |
| Painted Lands Green Caves (rock mazes, moss floors) + Cozy Farm (bunnies) | `maze-greencaves` | 5 (Overgrown mine maze with its rails) |
| Painted Lands Green Caves (rock mazes with cave homes) + Cozy Cottage (homes) + Cozy Farm (farm animals; bunnies on moss) | `maze-greencaves` | 4 (Cave hamlet, Smugglers', Root cellar, Hermit's) |
| Painted Lands Green Caves (mine mazes with rail tracks) | `maze-greencaves` | 2 (Mine maze, Rail tunnels) |
| Painted Lands Farm (spring and summer) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 2 |
| Painted Lands Farm (spring and summer) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 30 (2 of them rivers with bridges) |
| Painted Lands Farm (autumn) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 11 (1 river with bridges) |
| Painted Lands Farm (winter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-farm` | 9 (1 river with bridges) |
| Painted Lands Farm (spring and summer) + Forest (houses, fires, clutter, summer trees) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 6 |
| Painted Lands Farm (autumn) + Forest (houses, fires, clutter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 3 |
| Painted Lands Farm (winter) + Forest (houses, fires, clutter) + Cozy Cottage (interiors) + Cozy Farm (animals) | `randomizer-paintedlands-forest-farm` | 3 |
| Pixel Crawler Fairy Forest | `randomizer-pixelcrawler` | 6 |
| Pixel Crawler Fairy Forest (hedge and canal mazes) | `maze-pixelcrawler` | 5 |
| Pixel Crawler Farm forest + Green Woods (hedge and canal mazes) | `maze-pixelcrawler` | 4 |
| Pixel Crawler Cemetery (crypt mazes) | `maze-pixelcrawler` | 4 |
| Pixel Crawler Desert (cactus and rock mazes) | `maze-pixelcrawler` | 3 |
| Pixel Crawler Forge (forge halls, lava channels) | `maze-pixelcrawler` | 4 |
| Pixel Crawler Sewer (slime channels) | `maze-pixelcrawler` | 3 |
| Pixel Crawler Farm forest + Green Woods | `randomizer-pixelcrawler` | 5 |
| Pixel Crawler Cemetery | `randomizer-pixelcrawler` | 3 |
| Pixel Crawler Desert | `randomizer-pixelcrawler` | 3 |

251 map types in all (36 Painted Lands, 24 Forest mazes, 30 Farm mazes, 24 Green Caves mazes, 23 Pixel Crawler mazes, 33 Green Caves,
52 Farm in three seasons, 12 farmsteads, 17 Pixel Crawler) and 2 fixed maps.
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

## Painted Lands Forest mazes

`maze-forest` (id % 24, docs/maze-forest.md): hedge mazes (the Forest
sheet's dark hedge on plain lawn, or its pale hedge on dark grass) and canal
mazes (the pond's water set), walls three cells thick, one visible entrance
in the west wall and one exit in the east (a road in, lanterns, a
signpost), every room reachable. Cozy Farm bunnies throughout; farm animals
round the cottages (Cozy Cottage interiors).

| # | Map type | Walls | Clearings |
|---|---|---|---|
| 0 | Hedge labyrinth | dark hedge | |
| 1 | Branching hedges | dark hedge | |
| 2 | Braided hedges | dark hedge (loops) | |
| 3 | Windswept hedges | dark hedge | |
| 4 | Garden maze | dark hedge | garden |
| 5 | Cottage maze | dark hedge | cottage (hut, Cozy Cottage interior) |
| 6 | Campfire maze | dark hedge | camp |
| 7 | Pond court | dark hedge | pond |
| 8 | Wide avenues | dark hedge, paved avenues | |
| 9 | Path maze | dark hedge, paved | |
| 10 | Rings maze | dark hedge (rings) | old tree |
| 11 | Wooded maze | dark hedge, many trees | |
| 12 | Treasure maze | dark hedge, chests | |
| 13 | Twin cottages | dark hedge | two cottages (huts, Cozy Cottage interiors) |
| 14 | Lantern maze | dark hedge, paved, lanterns | camp |
| 15 | Shade maze | pale hedge on dark grass | |
| 16 | Firefly maze | pale hedge on dark grass | old tree |
| 17 | Moss garden | pale hedge on dark grass (loops) | pond |
| 18 | Canal maze | canals | |
| 19 | Lily canals | canals, bridges | |
| 20 | Moat maze | dark hedge in a moat, bridges | garden |
| 21 | Meadow maze | dark hedge (loops) | three meadows |
| 22 | Canal cottage | canals, paved, bridges | cottage (hut, Cozy Cottage interior) |
| 23 | Stone court | dark hedge (rings), paved | camp |

## Painted Lands Farm mazes

`maze-farm` (id % 30, docs/maze-farm.md): mazes on the Farm - 4 Seasons
sheets, one season per map: overlay walls (hedge, golden wheat, tall
grass), crop rows (corn, sunflowers), bushes (summer shrubs,
winter's snowy and pine bushes), and canals of the sheet's water blocks;
one visible entrance in the west wall and one exit in the east (a road in,
barrels, a signpost), every room reachable. The Cozy Farm animals in every
maze (in the pens, round the doors, or grazing the corridors); interiors
behind every building's door.

| # | Map type | Season | Walls | Clearings |
|---|---|---|---|---|
| 0 | Hedgerow maze | summer | hedge | |
| 1 | Branching hedgerows | summer | hedge | pond |
| 2 | Looping hedges | summer | hedge (loops) | hay |
| 3 | Farmhouse maze | summer | hedge | farmhouse (interior) |
| 4 | Windmill in the wheat | summer | wheat | windmill (mill floor and cap) |
| 5 | Wheat maze | summer | wheat | hay |
| 6 | Golden rings | summer | wheat (rings) | pumpkin patch |
| 7 | Corn maze | summer | corn | scarecrow |
| 8 | Maize loops | summer | corn (loops) | pumpkin patch |
| 9 | Sunflower maze | summer | sunflowers | hay |
| 10 | Meadow grass maze | summer | tall grass | two meadows |
| 11 | Barnyard maze | summer | hedge | barn (interior), pen |
| 12 | Pasture maze | summer | hedge (loops) | two pens |
| 13 | Orchard maze | summer | hedge, fruit trees | orchard |
| 14 | Kitchen garden maze | summer | hedge | two crop patches |
| 15 | Greenhouse maze | summer | hedge (rings), sand paths | greenhouse (interior) |
| 16 | Canal maze | summer | canals | |
| 17 | Bridge canals | summer | canals, bridges | |
| 18 | Mill canals | summer | canals, bridges | windmill |
| 19 | Moated farmhouse | summer | hedge in a moat, bridges | farmhouse |
| 20 | Shrub maze | summer | bushes | pond |
| 21 | Autumn hedgerows | autumn | brown hedge, many trees | |
| 22 | Autumn sunflowers | autumn | sunflowers | hay |
| 23 | Harvest corn maze | autumn | corn (loops) | pumpkin patch |
| 24 | Autumn homestead maze | autumn | brown hedge | farmhouse, pen |
| 25 | Russet canals | autumn | canals, bridges | barn |
| 26 | Frozen canals | winter | canals | |
| 27 | Snowbush maze | winter | snowy bushes | farmhouse |
| 28 | Pine hedge maze | winter | pine bushes | pen |
| 29 | Frozen mill canals | winter | canals, bridges | windmill |

## Painted Lands Green Caves mazes

`maze-greencaves` (id % 24, docs/maze-greencaves.md): rock mazes on the
Green Caves sheet, walls of its wall mass two cells wide (black tops over
their faces, the sheet's junction corners and rounded ends), on light,
dark, or moss floors; one visible entrance in the west wall and one exit in
the east (torches over the gap, a signpost), every room reachable. The
cave's drawn animals; Cozy Farm bunnies on the moss floors and farm animals
round the cave homes.

| # | Map type | Floor | Clearings |
|---|---|---|---|
| 0 | Rock labyrinth | light | |
| 1 | Branching tunnels | light | pool |
| 2 | Looping caverns | light (loops) | camp |
| 3 | Crystal maze | light | crystal ring |
| 4 | Stalagmite maze | light | cones |
| 5 | Spring maze | light | two pools |
| 6 | Flooded maze | light, wide | lake |
| 7 | Echo halls | light, wide | |
| 8 | Pillared maze | light (rings) | shrine |
| 9 | Cave hamlet maze | light | two cave homes |
| 10 | Mine maze | dark, rails | mine |
| 11 | Rail tunnels | dark, rails (loops) | coal |
| 12 | Ossuary maze | dark, skull faces | bones |
| 13 | Treasure vault maze | dark | vault |
| 14 | Smugglers' maze | dark | cave home, cache |
| 15 | Ore vein maze | dark | |
| 16 | Dark depths maze | dark, wide (loops) | pool |
| 17 | Root cellar maze | dark | cave home |
| 18 | Mossy labyrinth | moss | |
| 19 | Overgrown mine maze | moss, rails | grove |
| 20 | Sunken garden maze | moss | grove, pool |
| 21 | Hermit's maze | moss | cave home, camp |
| 22 | Fern hollows | moss, wide | two groves |
| 23 | Moss rings | moss (rings) | pool |

## Pixel Crawler mazes

`maze-pixelcrawler` (id % 23, docs/maze-pixelcrawler.md): one biome per map;
walls of the biome's own art: bushes, cacti, or rocks standing on the
wall's line, per-pixel canals, the Cemetery's crypt and the Forge's walls
from their plus-shaped samples, the Forge's lava and the Sewer's slime as
animated channels; one visible entrance in the west wall and one exit in
the east (markers either side), every room reachable. The drawn animals.

| # | Map type | Biome | Walls |
|---|---|---|---|
| 0 | Fairy hedge maze | Fairy Forest | bushes |
| 1 | Glowbell hedges | Fairy Forest | bushes |
| 2 | Fairy canals | Fairy Forest | canals |
| 3 | Runestone hedges | Fairy Forest | bushes (rings) |
| 4 | Mushroom hollow maze | Fairy Forest | bushes |
| 5 | Greenwood hedges | Farm forest | bushes |
| 6 | Forest canals | Farm forest | canals |
| 7 | Woodcutter's maze | Farm forest | bushes |
| 8 | Crystal hedges | Farm forest | bushes |
| 9 | Crypt maze | Cemetery | crypt walls |
| 10 | Catacombs | Cemetery | crypt walls |
| 11 | Crypt rings | Cemetery | crypt walls (rings) |
| 12 | Haunted crypts | Cemetery | crypt walls (loops) |
| 13 | Cactus maze | Desert | cacti |
| 14 | Rock maze | Desert | rocks |
| 15 | Bone canyon | Desert | rocks and cacti |
| 16 | Forge halls | Forge | forge walls |
| 17 | Lava channels | Forge | lava |
| 18 | Foundry maze | Forge | forge walls |
| 19 | Forge rings | Forge | forge walls (rings) |
| 20 | Slime canals | Sewer | slime |
| 21 | Sewer junctions | Sewer | slime, plank bridges |
| 22 | Overflow tunnels | Sewer | slime (wide) |

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
