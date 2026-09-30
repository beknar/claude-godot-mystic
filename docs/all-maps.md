# All maps

Every map this project can currently generate, grouped by the tilesets
drawn on it. A "map type" is one recipe of a scene's generator; each
randomizer builds endless maps from its map types (the map id picks the type
and seeds the layout), and the two fixed scenes pin one map each. Only
current tilesets are listed: The Painted Lands packs (Forest, Green Caves,
Cozy Cottage), Pixel Crawler, and the Cozy Farm animals (the only part of
that pack still in use). The deprecated packs and scenes (Mystic Woods, Mana
Seed, and the cozy farm randomizer with the Cozy Farm buildings) and the
unsuitable pack (Time Fantasy) are left out; the cozy farm randomizer's
record is listed at the end.
Every map below is walked by the Painted Lands walker
(`character_sprite_sheet.png`); the small animals, insects, birds, and
effects drawn in code are on all of them and are not counted as a tileset.
The Cozy Farm animals (`assets/pack/cozy_farm/animals/`, the `cozy_animals`
option) live in the two Painted Lands randomizers only: the bunny in place of
the drawn rabbit wherever there is lawn or moss, and farm animals (chickens,
turkeys, pigs, sheep, goats, cows) only round homes. The fixed maps keep the
drawn animals.
Rules for each pack: `docs/painted-lands.md`, `docs/green-caves.md`,
`docs/interiors.md`, `docs/pixel-crawler.md`.

## Summary

| Tilesets | Scene | Map types |
|---|---|---|
| Painted Lands Forest | `forest` (fixed map), `wilds` (fixed map) | 2 fixed maps |
| Painted Lands Forest + Cozy Farm (bunnies) | `randomizer-paintedlands` | 8 |
| Painted Lands Forest + Cozy Cottage (interiors) + Cozy Farm (bunnies, farm animals) | `randomizer-paintedlands` | 25 |
| Painted Lands Green Caves | `randomizer-greencaves` | 23 |
| Painted Lands Green Caves + Cozy Farm (bunnies) | `randomizer-greencaves` | 3 |
| Painted Lands Green Caves + Cozy Cottage (homes) + Cozy Farm (farm animals) | `randomizer-greencaves` | 7 |
| Pixel Crawler Fairy Forest | `randomizer-pixelcrawler` | 6 |
| Pixel Crawler Farm forest + Green Woods | `randomizer-pixelcrawler` | 5 |
| Pixel Crawler Cemetery | `randomizer-pixelcrawler` | 3 |
| Pixel Crawler Desert | `randomizer-pixelcrawler` | 3 |

83 map types in all (33 Painted Lands, 33 Green Caves, 17 Pixel Crawler)
and 2 fixed maps. Painted Lands and Pixel Crawler never share a map, and
the Cozy Farm animals never go on a Pixel Crawler map.

## Painted Lands Forest

`assets/pack/TILESET_brighter.png`. The fixed scenes have no house doors.

| Scene | Map id | Map type |
|---|---|---|
| `scenes/forest/forest.tscn` | 91003 | 3 Garden (hut in a fence yard with a gate) |
| `scenes/wilds/wilds.tscn` | 75125 | 5 Open meadow |

`randomizer-paintedlands` map types with no house (id % 33), with Cozy Farm
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
