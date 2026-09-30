# All maps

Every map this project can currently generate, grouped by the tilesets
drawn on it. A "map type" is one recipe of a scene's generator; each
randomizer builds endless maps from its map types (the map id picks the type
and seeds the layout), and the two fixed scenes pin one map each. Only
current tilesets are listed: The Painted Lands packs (Forest, Green Caves,
Cozy Cottage) and Pixel Crawler, plus the Cozy Farm animals and buildings
used in the cozy farm randomizer. The deprecated packs (Mystic Woods, Mana
Seed) and the unsuitable one (Time Fantasy) are left out, with their scenes.
Every map below is walked by the Painted Lands walker
(`character_sprite_sheet.png`); the small animals, insects, birds, and
effects drawn in code are on all of them and are not counted as a tileset.
Rules for each pack: `docs/painted-lands.md`, `docs/green-caves.md`,
`docs/interiors.md`, `docs/pixel-crawler.md`.

## Summary

| Tilesets | Scene | Map types |
|---|---|---|
| Painted Lands Forest | `forest` (fixed map), `wilds` (fixed map) | 2 fixed maps |
| Painted Lands Forest | `randomizer-paintedlands` | 8 |
| Painted Lands Forest + Cozy Cottage (interiors) | `randomizer-paintedlands` | 25 |
| Painted Lands Green Caves | `randomizer-greencaves` | 26 |
| Painted Lands Green Caves + Cozy Cottage (homes) | `randomizer-greencaves` | 7 |
| Painted Lands Forest + Cozy Farm (animals) | `randomizer-painted-cozyfarm` | 7 |
| Painted Lands Forest + Cozy Farm (animals, buildings) | `randomizer-painted-cozyfarm` | 1 |
| Painted Lands Forest + Cozy Cottage (interiors) + Cozy Farm (animals, buildings) | `randomizer-painted-cozyfarm` | 28 |
| Pixel Crawler Fairy Forest | `randomizer-pixelcrawler` | 6 |
| Pixel Crawler Farm forest + Green Woods | `randomizer-pixelcrawler` | 5 |
| Pixel Crawler Cemetery | `randomizer-pixelcrawler` | 3 |
| Pixel Crawler Desert | `randomizer-pixelcrawler` | 3 |

119 map types in all (33 Painted Lands, 33 Green Caves, 36 cozy farm, 17
Pixel Crawler) and 2 fixed maps. Painted Lands and Pixel Crawler never share
a map.

## Painted Lands Forest

`assets/pack/TILESET_brighter.png`. The fixed scenes have no house doors.

| Scene | Map id | Map type |
|---|---|---|
| `scenes/forest/forest.tscn` | 91003 | 3 Garden (hut in a fence yard with a gate) |
| `scenes/wilds/wilds.tscn` | 75125 | 5 Open meadow |

`randomizer-paintedlands` map types with no house (id % 33):

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

## Painted Lands Forest + Cozy Cottage

`randomizer-paintedlands`: every house opens onto a furnished interior drawn
from Cozy Cottage (`assets/pack/cozy_cottage/`).

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

## Painted Lands Green Caves

`randomizer-greencaves` (id % 33), `assets/pack/green_caves/`.

| # | Map type | # | Map type |
|---|---|---|---|
| 0 | Grotto | 16 | Twin pools |
| 1 | Crystal cavern | 17 | Crystal shrine |
| 2 | Flooded hall | 18 | Dark depths |
| 3 | Mine shaft | 19 | Collapsed tunnel |
| 5 | Mossy hollow | 20 | Overgrown mine |
| 6 | Terrace steps | 21 | Watch post |
| 7 | Ossuary | 23 | Echo chamber |
| 8 | Pillared hall | 24 | Lake terrace |
| 9 | Stalagmite field | 25 | Coal store |
| 10 | Underground spring | 26 | Crossroads cavern |
| 11 | Ore vein | 28 | Sunken garden |
| 12 | Dead grove | 29 | Treasure vault |
| 13 | Cave mouth | | |
| 15 | Rail junction | | |

## Painted Lands Green Caves + Cozy Cottage

`randomizer-greencaves`: homes built into the cave, furnished from Cozy
Cottage.

| # | Map type | Homes (rooms) |
|---|---|---|
| 4 | Miners' camp | 1 (2-3) |
| 14 | Smugglers' cache | 1 (1-2) |
| 22 | Root cellar | 1 (2-3) |
| 27 | Hermit's nook | 1 (1-2) |
| 30 | Hermit's home | 1 (1-2) |
| 31 | Cave hamlet | 3 (1-2 each) |
| 32 | Underground manor | 1 (5-6) |

## Painted Lands Forest + Cozy Farm

`randomizer-painted-cozyfarm` (id % 36): the Painted Lands terrain with the
Cozy Farm animals (`assets/pack/cozy_farm/animals/`) on every map.

With the animals only (no buildings):

| # | Map type |
|---|---|
| 12 | Wild lane |
| 18 | Sparse wild |
| 20 | Cave mouth |
| 22 | Stone ruins |
| 24 | Rock garden |
| 25 | Deep forest |
| 29 | Walled mesa |

With Cozy Farm buildings (`assets/pack/cozy_farm/buildings.png`) but no
home to enter:

| # | Map type | Farmyard |
|---|---|---|
| 5 | Open meadow | windmill, straw silo |

## Painted Lands Forest + Cozy Cottage + Cozy Farm

`randomizer-painted-cozyfarm`: Cozy Farm homes (each with a Cozy Cottage
interior) in place of the Painted Lands houses, farmyard outbuildings, and
the Cozy Farm animals.

| # | Map type | Homes (interiors) | Farmyard |
|---|---|---|---|
| 0 | Pastoral | farm cottage | barn, red silo, coop |
| 1 | Crossroads | timber house | |
| 2 | Pond walk | thatched cottage | |
| 3 | Garden | farm cottage | coop |
| 4 | Lookout | A-frame house | |
| 6 | Twin water | thatched cottage | |
| 7 | South road | long house | red silo |
| 8 | Shore spur | thatched cottage | coop |
| 9 | Three-way | timber house | |
| 10 | West hamlet | timber house, A-frame house | coop |
| 11 | East hamlet | thatched cottage | |
| 13 | Orchard | farm cottage | barn, straw silo |
| 14 | Shore hamlet | thatched cottage | coop |
| 15 | Double lean | A-frame house | |
| 16 | Below the rim | timber house | |
| 17 | Gate road | farm cottage | coop |
| 19 | Switchback | long house | red silo |
| 21 | Terraces | A-frame house | |
| 23 | Woodcutter camp | long house, red barn | straw silo |
| 26 | Village square | timber house, A-frame house, brick house | |
| 27 | Hedge garden | brick house | |
| 28 | Ridgeline | timber house | |
| 30 | Cottage row | thatched cottage, A-frame house, timber house | |
| 31 | Twin cottages | farm cottage, thatched cottage | coop |
| 32 | Manor green | farmhouse, brick house | barn |
| 33 | Farmstead (cozy only) | farmhouse | barn, coop, red silo, straw silo |
| 34 | Windmill road (cozy only) | thatched cottage | windmill, straw silo, coop |
| 35 | Farm village (cozy only) | farm cottage, timber house, thatched cottage | barn, coop, windmill |

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
