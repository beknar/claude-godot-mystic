# claude-godot-mystic

A top-down pixel-art action RPG prototype in Godot 4.6 (GL Compatibility).
Maps are assembled on a 16px grid from four hand-painted tile families and
seeded procedural generators. They are never painted as one backdrop.

`AGENTS.md` holds the binding rules for every session, and each pack's
drawing rules live in its doc (`docs/painted-lands.md`,
`docs/green-caves.md`, `docs/interiors.md`, `docs/farm.md`,
`docs/pixel-crawler.md`;
deprecated packs in `docs/deprecated/`). `docs/scene-assembly.md` holds the
shared inventory, composition steps, and QC checklist. This README gives an
overview; when the two disagree, `AGENTS.md` wins.

> **Status:** built so far: `scenes/clearing/clearing.tscn` (the main scene),
> `scenes/grove/grove.tscn`, `scenes/forest/forest.tscn`,
> `scenes/wilds/wilds.tscn`, `scenes/randomizer-paintedlands/randomizer-paintedlands.tscn`,
> `scenes/randomizer-mysticwoods/randomizer-mysticwoods.tscn`,
> `scenes/randomizer-greencaves/randomizer-greencaves.tscn`,
> `scenes/randomizer-manaseed/randomizer-manaseed.tscn`,
> `scenes/randomizer-pixelcrawler/randomizer-pixelcrawler.tscn`,
> `scenes/randomizer-timefantasy/randomizer-timefantasy.tscn`, the
> player and walker scenes, the Mystic Woods, Painted Lands, Green Caves, Mana
> Seed, Pixel Crawler, and Time Fantasy generators, the art packs, the AI character sheets, and `addons/godot_mcp`. Hollow,
> ford, and heath are not built yet. The Painted Lands generator draws all
> 30 recipes.

## Art packs (not in the repository)

The purchased packs are licensed for use but not redistribution, so
`assets/pack/` is ignored and the history carries none of it. To run the
project, copy them in locally:

- Mystic Woods 2.2 (Game Endeavor): its `sprites/` folder to `assets/pack/sprites/`
- Painted Lands: `TILESET_brighter.png` and `character_sprite_sheet.png` to `assets/pack/`
- Painted Lands – Green Caves: the pack folder to `assets/pack/green_caves/`
  (`green_caves_tileset.png`, `explanations.png`)
- Painted Lands – Interior Cozy Cottage: the pack folder to
  `assets/pack/cozy_cottage/` (`wallpapers_and_floors.png`, `furniture.png`,
  `decoration.png`)
- Painted Lands – Farm 4 Seasons (FULL VERSION): its `tilesets/` (all three
  seasonal sheets),
  `tree animations/`, `windmill animations/`, and `fence gate animations/`
  folders and `fishes.png` to `assets/pack/farm/`, keeping the pack's names
- Mana Seed (Seliel the Shaper, from the complete rpg creator bundle's
  `mana seed pixel art tileset collection`): per season under
  `assets/pack/mana_seed/<season>/` with the file names the painter expects
  (`wang.png`, `forest.png`, `trees.png`, `16x16.png`, `16x32.png`,
  `32x32.png`, `48x32.png`, `tallgrass.png`, `sparkles.png`,
  `waterfall.png`, `treewall.png`, `canopy.png`; autumn from the "leaves"
  sheets, winter from the "snowy" ones), plus Village Accessories to
  `village/`, Fences & Walls to `fences/`, Weather Effects to `weather/`, and
  `_extras` to `extras/` (see docs/deprecated/mana-seed.md)
- Cozy Farm art pack (shubibubi): its `animals/` folder to
  `assets/pack/cozy_farm/animals/` (the Painted Lands, Green Caves, and farm
  randomizers); `Buildings/buildings.png` to
  `assets/pack/cozy_farm/buildings.png` only for the deprecated cozy farm
  randomizer
- Pixel Crawler (Anokolisa): the environment sheets to
  `assets/pack/pixel_crawler/`: Fairy Forest `Assets/*.png` to
  `fairy_forest/`, the Farm Game Assets forest (`Tiles.png`,
  `Vegetation_01.png` as `Vegetation.png`, `Tree_Model_01/Size_0N.png` as
  `Tree_0N.png`) to `farm/`, Green Woods `Assets/*.png` to `green_woods/`,
  Cemetery and Desert `Assets/*.png` to `cemetery/` and `desert/`
- Time Fantasy tiles (finalbossblues, TimeFantasy_TILES_6.24.17): the
  `TILESETS` folder to `assets/pack/time_fantasy/` (`terrain.png`,
  `outside.png`, `water.png`, `house.png`, `animated/`, `guide.png`)

Then open the project in Godot so it imports them.

## Running

Open the folder in Godot 4.6 and press F5, or run:

```
Godot_v4.6.1-stable_win64.exe --path E:\code\claude-godot-mystic
```

Display: window 3440×1440, camera zoom 5, nearest filtering. Each 16px tile
is 80 screen pixels.

## Official asset packs

> **Official asset packs.** The only official asset packs for development at
> this point are **The Painted Lands** (Forest, Green Caves, Cozy Cottage, and
> the other antarcticbees packs) and **Pixel Crawler** (Anokolisa). They are
> used in separate maps and never combined. The **Mana Seed** packs are not to
> be used in future development in this project. **Mystic Woods** is now
> deprecated. (Time Fantasy was already ruled unsuitable.) Their existing
> scenes and sections stay as a record only.
>
> **The cozy farm randomizer is deprecated.** From now on only the **Cozy
> Farm** animals are used, in `randomizer-paintedlands`,
> `randomizer-greencaves`, `randomizer-paintedlands-farm`, and
> `randomizer-paintedlands-forest-farm`; its buildings and the
> `randomizer-painted-cozyfarm` scene stay as a record only
> (`docs/deprecated/cozy-farm.md`).

## Two map languages

Each map belongs to one pack. Don't mix pipelines, sheets, or "done" checks
between them.

| Maps | Pack | Sheets (`assets/pack/`) | Generator |
|---|---|---|---|
| clearing, grove, hollow, ford, heath | Mystic Woods | `plains.png`, `grass.png` | `scripts/terrain.gd` + `scripts/clearing.gd` |
| forest, wilds | Painted Lands | `TILESET_brighter.png` | `scripts/forest_terrain.gd` |
| randomizer-greencaves | Green Caves | `green_caves/green_caves_tileset.png` | `scripts/cave_terrain.gd` + `scripts/caves.gd` |
| randomizer-paintedlands-farm | Farm – 4 Seasons (spring and summer, autumn, winter; one season per map) | `farm/` (the three seasonal tilesets, crops, tree, windmill, and gate animations, fish) | `scripts/farm_terrain.gd` + `scripts/farm.gd` (`scripts/farm_tiles.gd`) |
| randomizer-paintedlands-forest-farm | Painted Lands Forest and Farm – 4 Seasons (one ground per map) | `TILESET_brighter.png`, `farm/` | `scripts/forest_farm.gd` over `forest.gd` and `farm.gd` (`MIXED_RECIPES` for the farmsteads) |
| randomizer-manaseed | Mana Seed | `mana_seed/` (four seasonal forests, village, fences, weather, extras) | `scripts/ms_terrain.gd` + `scripts/manaseed.gd` |
| randomizer-pixelcrawler | Pixel Crawler | `pixel_crawler/` (Fairy Forest, Farm forest, Green Woods, Cemetery, Desert) | `scripts/pc_terrain.gd` + `scripts/pixelcrawler.gd` |
| randomizer-timefantasy (experimental, not suitable) | Time Fantasy | `time_fantasy/` (terrain, outside, water, house, animated) | `scripts/tf_terrain.gd` + `scripts/timefantasy.gd` |

Heath and forest share seed `91003` by coincidence only. They don't share a
generator.

### Scenes

| Scene | Seed / id | Character sheet |
|---|---|---|
| `scenes/clearing/clearing.tscn` | 21021 | `player.png` |
| `scenes/grove/grove.tscn` | 90511 | `assets/ai/characters/wanderer.png` |
| `scenes/hollow/hollow.tscn` | 44107 | `assets/ai/characters/scout.png` |
| `scenes/ford/ford.tscn` | 12809 | `assets/ai/characters/warrior-16x16-sheet.png` (16px frames) |
| `scenes/heath/heath.tscn` | 91003, no water | Lineup of all five Mystic Woods sheets, no control |
| `scenes/forest/forest.tscn` | 91003 | `character_sprite_sheet.png` (3×4 of 32px) |
| `scenes/wilds/wilds.tscn` | 75125 (recipe 5, Open meadow) | `character_sprite_sheet.png` |
| `scenes/randomizer-paintedlands/randomizer-paintedlands.tscn` | starts at 75101 (recipe 5, Open meadow), then any | `character_sprite_sheet.png` |
| `scenes/maze-forest/maze-forest.tscn` | starts at 400000 (maze type 16, Firefly maze; id % 24), then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/maze-farm/maze-farm.tscn` | starts at 420000 (maze type 0, Hedgerow maze; id % 30), then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-mysticwoods/randomizer-mysticwoods.tscn` | starts at 21021, then any | `player.png` |
| `scenes/randomizer-greencaves/randomizer-greencaves.tscn` | starts at 130021, then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-paintedlands-farm/randomizer-paintedlands-farm.tscn` | starts at 190008 (recipe 0, Homestead), then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-paintedlands-forest-farm/randomizer-paintedlands-forest-farm.tscn` | starts at 200088 (recipe 88, Cottage homestead), then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-manaseed/randomizer-manaseed.tscn` | starts at 160000, then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-painted-cozyfarm/randomizer-painted-cozyfarm.tscn` (deprecated) | starts at 180033 (recipe 33 Farmstead), then any | `character_sprite_sheet.png` |
| `scenes/randomizer-pixelcrawler/randomizer-pixelcrawler.tscn` | starts at 170000, then any | `character_sprite_sheet.png` (the Painted Lands walker) |
| `scenes/randomizer-timefantasy/randomizer-timefantasy.tscn` | starts at 150000, then any | `character_sprite_sheet.png` (the Painted Lands walker) |

The Mana Seed randomizer builds outdoor maps from Seliel the Shaper's forest
collection in all four seasons (the seasonal sheets share one layout, so the
map id picks the season) with 21 recipes (meadow, forest glade, lakeside,
brookside, cliffside, terraces, old road, woodcutter's camp, village well,
paddock, marsh, deep woods, berry thicket, rocky rise, pond garden,
crossroads, wildflower meadow, sunlit heath, mossy hollow, stony barrens,
dusky woodland). Plain light grass covers at most 30 % of a map (outside
winter); the rest is dark grass, dirt, and rocky ground in each recipe's
mix. The grass is texture-splatted: a shader breaks light and dark grass
into lush, straw, moss, and flower patches (the pack's own grass, retoned)
with dithered pixel rims, so the view is never one wall of repeating green. The ground is the pack's corner-Wang sheet (every mix of dirt,
light and dark grass, cobblestone, and shallow and deep water blends with the
pack's own transitions), with plateaus built from the pack's usage guide,
the 128 px forest wall with its canopy overlay, ponds, lakes with islands,
brooks with a stone bridge, tree clusters over undergrowth, tall grass that
rustles as you walk through it, ranch fences, and village props. It runs the
Painted Lands and Green Caves ambience plus the pack's water sparkles and
snow and rain. `tools/check_ms.gd` sweeps it headless. Its liveliness has
not been measured yet.

> **Deprecated: the Painted Lands cozy farm randomizer.** It stays as a
> record only (`docs/deprecated/cozy-farm.md`); don't build new maps from
> it or use the Cozy Farm buildings. It was the Painted Lands randomizer with
> Cozy Farm homes in place of the Painted Lands houses, farmyard
> outbuildings (barn, coop, silos, windmill), and three map types of its own
> (Farmstead, Windmill road, Farm village). Its animals live on in the
> Painted Lands and Green Caves randomizers (the bunny and farm animals by
> the homes; see the small-animals paragraph below).

The Painted Lands farm randomizer builds farms from antarcticbees' Farm – 4
Seasons tileset with 52 recipes in three seasons (four of them rivers
crossed on bridges: river farm, mill on the river, russet river, frozen
river), each map wholly in one
season (the seasons are never mixed): 30 in spring and summer (homestead, wheat valley,
windmill hill, apple orchard, cherry blossom lane, pumpkin patch, kitchen
garden, greenhouse garden, barnyard, sheep meadow, duck pond farm, riverside
fields, farm village, market crossroads, sunflower field, corn rows, berry
patch, hillside terraces, woodlot, pine ridge, wildflower meadow, old farm,
fishing lake, cattle ranch, hayfield, scarecrow fields, twin farms, stone
quarry, orchard and greenhouse, harvest fair), 10 in autumn (autumn
homestead, pumpkin harvest, autumn orchard, golden wheat, turning lane,
autumn market, misty lake, cornfield, old barn in autumn, cider farm), and 8
in winter (snowy homestead, winter pasture, frozen lake, snowy woodlot, pine
hills, winter village, greenhouse in the snow, winter windmill). Autumn has
tan and russet grass, turning trees that shed autumn leaves, straw, and the
harvest; winter has snow in white and blue, snowy and bare trees, snow drifts,
snow falling with the wind, and no crops outdoors (they grow on in the
greenhouse). The ground blends lawn, sand
yards, and dirt roads through the sheet's own corner tiles, with pale, dark,
and deep grass zones drawn per pixel from the sheet's fills; ponds and lakes
(some with an island) and brooks use the sheet's animated shores; tilled
fields and crop rows grow sixteen crops from `crops.png`, their tops nodding
in the wind; wheat, tall grass, and hedges are organic overlay blobs;
fenced pens have gates that swing open for the walker and herds inside;
orchards grow apples, cherries, oranges, and peaches. The pack's animated
trees rustle in gusts and when brushed, dropping leaves (the cherry blossoms
blow petals), the windmill turns with the wind, fish leap in the ponds, and
the Cozy Farm animals graze and doze. Every building has a door into its own
interior, a sub-map far below the farm: farmhouses and the manor open on
Cozy Cottage homes, the barn on a barn with its animals, the windmill on a
working mill floor (the great spur wheel turning under the ceiling, the
shaft, the hopper trickling grain into the turning runner stone, flour
dribbling into a sack, the sack hoist, a ladder to the trapdoor, sacks and
grain, a mill cat and mice, and in winter a hearth; up the ladder, the cap
with the brake wheel turning the wallower, the sack trap, and the sails'
shadows sweeping past the windows), and the greenhouse on the sheet's own
glasshouse with crops in its beds. Front doors swing open as the walker
comes up and shut behind it, in this randomizer and the Painted Lands one,
and inside every way out is a door that swings open the same way, letting
daylight in. `tools/check_farm.gd` sweeps it
headless (docs/farm.md).

**Bridges.** Where a road or a lane crosses a river or a brook on the
Painted Lands maps it goes over a bridge: 24 designs (plank, rope and plank,
boards, log decks and log rails, boardwalk on stilts, clapper slabs, stone,
mossy, and sandstone arches, lantern bridges in stone and in wood, lattice,
flower-planted rails, branch rails, trestle, stone piers, painted rails, a
rustic one-rope bridge, gate posts, mossy slabs, cobbles with bollards, and
a felled trunk), drawn by `tools/gen_bridges.py` in the Forest's and the
Farm's own colors with a snowy set for winter (`assets/ai/bridges/`; the
packs draw none), built piece by piece to span any width, the walker
crossing between the back rail and the front one, the lanterns glowing.
The Painted Lands randomizer has three river map types (river crossing,
river lane, twin bridges) and the farm four (docs/bridges.md).

**Forest mazes.** `maze-forest` builds hedge and canal mazes on the Painted
Lands Forest sheet, 24 types from the same Esc menu (each regenerate a new
maze of the type): long winding labyrinths, branching and braided ones,
windswept runs, rings round an old tree, gardens, a camp, a pond court, a
cottage or two in their clearings (Cozy Cottage interiors, the Cozy Farm
animals round them), paved paths and wide avenues, wooded hedges with trees
growing out of them, a treasure maze with chests in its dead ends, a lantern
maze, pale-hedge mazes on dark grass with fireflies, canals with lilies and
bridges, and a maze in a moat. Walls are three cells thick so the sheet's
hedge draws full, and they collide where they are drawn; every room is
reachable from the one entrance (a road, lanterns, a signpost) to the one
exit. The rest is the Painted Lands pipeline: grass tones, dirt patches,
flowers, bunnies, butterflies, wind, clouds, leaves, lanterns lifting the
quiet stretches (docs/maze-forest.md; `tools/check_maze.gd`).

**Farm mazes.** `maze-farm` builds mazes on the Farm - 4 Seasons sheets, 30
types in spring and summer, autumn, and winter from the same Esc menu: hedge
mazes, golden wheat mazes, corn and sunflower mazes whose
stalks nod and bend away from the walker, tall-grass and shrub mazes, snowy
bush and pine hedge mazes, and canal mazes crossed on bridges, some round a
farmhouse, the barn, the windmill, or the greenhouse (their interiors behind
the doors), pens with their herds, a pond, crop patches, an orchard, hay and
scarecrows, a farmhouse in a moat. Walls collide where they are drawn; every
room is reachable from the one entrance (a road, barrels, a signpost) to
the one exit. The Cozy Farm animals live in every maze, in the pens, by the
doors, or grazing the corridors (docs/maze-farm.md; `tools/check_maze_farm.gd`).

The Painted Lands forest and farm randomizer
(`randomizer-paintedlands-forest-farm`) builds all 100 Painted Lands map
types from one menu: the 36 Forest map types, the 52 Farm map types, and 12
farmsteads of its own, all with the Cozy Farm animals. A farmstead is Farm
ground in one season with the Forest's houses (porch house, flower cottage,
gabled cottage, hut) in place of the farmhouses, chimney smoke, campfires
ringed with logs, ash, and crates by the doors, lanterns flanking the doors
and pen gates, and flowerpots, chests, and signs; in summer the Forest's
green trees, blossoms, and berry bushes grow among the Farm trees. Six are
summer (cottage homestead, blossom cottage, hamlet by the mill,
woodcutter's clearing, village fair, greenhouse cottage), three autumn
(lantern lane, harvest bonfire, autumn hearths), and three winter (winter
hearth, snowbound hamlet, frozen mill). Each map keeps one ground (Forest
lawn and Farm lawn never meet): the scene holds both pipelines and hides and
pauses the one not in use. `tools/check_farm.gd ... mixed` sweeps the
farmsteads.

The Pixel Crawler randomizer builds outdoor maps in four biomes from
Anokolisa's Pixel Crawler sheets, 17 recipes in all: Fairy Forest (glade,
runestone circle, glowbell hollow, twilight stream, root ledges, deep fairy
wood), the Farm forest (greenwood, forest trail, island lake, autumn grove,
crystal thicket; its near-pure greens toned down), Cemetery (old cemetery,
dead wood, red pine hill), and Desert (dune sea, bone field, mesa). The
ground blends through each sheet's own transitions (corner tables read from
the sheets), with stretched plateau stamps, ponds and streams drawn in the
sheets' water colors, island stamps in lakes, layered tree clusters, light
and dark ground varied by a splat (sunlit, dry, tufted, and shaded patches;
the tufts are Painted Lands sprout shapes recolored into the biome's
palette), the pack's own canopy shadows and light discs, and the
Painted Lands and Green Caves ambience (glowing bells and runestones shed a
cold light). `tools/check_pc.gd` sweeps it headless. Its liveliness has not
been measured yet.

> **Time Fantasy is not suitable for this project.** Consider the Time
> Fantasy tilesets no longer suitable for any maps here: the prevalent ground
> tiles are incompatible with, or clash with, the current Painted Lands tiles,
> and on their own they are too repetitive and a strain on the eyes. The
> randomizer below stays as an experiment; don't build new maps from the pack.

The Time Fantasy randomizer builds outdoor maps from the Time Fantasy tiles
(never `world.png`, which is for a zoomed-out map) with 20 recipes (meadow,
village green, hamlet road, lakeside, forest glade, pine woods, autumn woods,
cliffside, terraces, stone quarry, campsite, graveyard, blossom grove,
crystal hollow, farmstead, market square, riverside, marsh, autumn hamlet,
giant tree). Each map has autotiled winding paths (dirt, gravel, paving),
forest-floor zones in two nested tones with dithered organic rims, bare dirt patches, animated ponds with lily pads
and reeds, a stream with a bridge, plateaus with stairs, gable houses
composed from `house.png` (six roof colors, five wall materials), and green
or autumn seasons. It runs the Painted Lands ambience (wind, leaves, streaks,
cloud shadows, grass waves, water life, critters, wildlife, drifters,
footsteps, firepit and brazier glow, chimney smoke) and the same liveliness
floor. `tools/check_tf.gd` sweeps it headless.

The Green Caves randomizer builds cave maps from its own generator with 30
recipes (grotto, crystal cavern, flooded hall, mine shaft, miners' camp,
mossy hollow, terrace steps, ossuary, pillared hall, stalagmite field,
underground spring, ore vein, dead grove, cave mouth, smugglers' cache, rail
junction, twin pools, crystal shrine, dark depths, collapsed tunnel,
overgrown mine, watch post, root cellar, echo chamber, lake terrace, coal
store, crossroads cavern, hermit's nook, sunken garden, treasure vault). Each
map has a back wall with a doorway, rock islands, raised terraces with
stairs, pools and lakes with animated water, mine rails, dark floor zones,
and the pack's props. The Painted Lands walker walks it, with the same Esc
menu and recipe picker. Its ambience is the Painted Lands set adapted to a
cave (fire glow and smoke, water life, glowworms, moths, dragonflies, cave
animals, footsteps, mossy leaf fall) plus `scripts/cave_life.gd` (drips,
dust motes, crystal glints, bats), and it has the same liveliness floor.
`tools/check_caves.gd` sweeps the recipes headless. Seven recipes have homes
built into the cave (Miners' camp, Smugglers' cache, Root cellar, Hermit's
nook, and the new Hermit's home, Cave hamlet with three homes, and
Underground manor with one of five or six rooms): rock-walled, entered
through an arched doorway, furnished inside.

### Interiors

Both randomizers furnish homes with the Cozy Cottage interior pack
(`scripts/interior_plan.gd`, `interior_view.gd`, `interior_life.gd`): one to
six rooms (cottage, living room, hall, kitchen, bedroom, study, bath, dining
room, pantry), doors between them, a way out, windows, wallpaper, floors, and
furniture by room, in five wood tones. In the Painted Lands randomizer every
house has a door: walk up into it from the doorstep and the screen fades into
its interior (a porch cottage has three to six rooms, a hut one or two); walk
out the bottom to return. Three new Painted Lands recipes put several houses
on one map (Cottage row, Twin cottages, Manor green). Inside, fires flicker
in the hearths, lamps glow, sunbeams fall through the windows with dust in
them, cups steam, moths circle the lamps, and most homes have a cat that
naps by the fire or in the sun and comes to say hello or trots off.
`tools/check_interiors.gd` checks 600 homes, `tools/interior_preview.tscn`
shows six, and `tools/sim_interior.gd` measures how lively they are.

The Painted Lands randomizer runs the Painted Lands generator with the wilds
settings; the Mystic Woods randomizer runs the Mystic Woods generator the
same way, with its own 16 recipes (clearing, pond glade, lake island,
farmstead, stone ruins, cottage garden, graveyard, cobble crossroads, rocky
highland, orchard, woodcutter's glade, campsite, mushroom hollow, abandoned
house, stone chapel, tree nursery) in the recipe picker, and the Painted Lands
ambience (wind, leaves, clouds, water life, critters, animals, footsteps,
drifters, grass waves) plus a liveliness floor. `tools/check_mystic.gd` sweeps
the recipes headless; `tools/pack_usage.gd` + `tools/pack_usage.py` report
how much of the pack the maps use.
Press Esc for its menu: it shows the current map id, recipe, and check
result, and **Regenerate with a new seed** builds a fresh map from a random
id with the same rules (`recipe = id % 30`). The recipe picker can pin the
next seed to any of the 30 recipes.

To check every recipe headless:

```
Godot_v4.6.1-stable_win64.exe --headless --path E:\code\claude-godot-mystic -s res://tools/check_recipes.gd -- 100000 1000
```

It prints one line per map with its checks, then a summary of how many
maps passed, how many plateaus got stairs, and how often each prop art was
placed.

To estimate how alive each map looks, per camera-sized window and for the
whole scene:

```
Godot_v4.6.1-stable_win64.exe --headless --path E:\code\claude-godot-mystic -s res://tools/liveliness.gd -- 100000 300 [recipe] [heat]
```

It prints the predicted share of pixels moving per frame (cloud shadows
aside, which add about the same everywhere) for the scene, for the weakest
and strongest 43×18-cell window, and how much of the weakest window is
quiet; `heat` adds a per-cell map. The weights come from a rendered
calibration: `tools/liveliness_capture.tscn` films 18 maps (10 for fitting, 8
held back, including one of each recipe given ponds, torches, or fires) at 8 fps without the walker (about 52 minutes), then
`python3 tools/liveliness_analyze.py watch .liveliness` measures the frames
as they arrive and `... fit .liveliness` writes `tools/liveliness_coef.json`
and `docs/liveliness-calibration.md`. Run the capture again after changing
an effect.

Ponds animate through the sheet's four shore frames. Plateaus have a
three-wide stair up the face, and the top is walkable. Trees come in eight
variants (two shapes, plain or flowering, with or without a grassy base).
Logs lie on the lawn, and crates and chests sit beside each house. Every
map has zones of darker grass in three nested tones with organic, dithered
edges that curve away from the path. Dirt islands inside a zone use the dirt tile
whose grass is that tone, deco follows the tone underneath, and flower
carpets dot the open lawn. Some maps get hedgerows, and many ponds become
lakes with a deep, sparkling center. A shifting wind carries falling leaves and
petals, pale wind streaks, and drifting cloud shadows across every map,
and gusts roll fronts of sunlit blade tips over the grass. Dandelion seeds
and pollen drift through every view, and now and then a flock of birds
crosses overhead with its shadow. Cottages and huts send smoke up from their
roofs, and many land-only maps get a meandering brook. Campfires and torches
flicker with warm light and smoke, ponds ripple, fish jump, and reeds nod
in the wind. Butterflies drift between flowers, dragonflies dart over
ponds, fireflies glow in the dark grass, and the ground reacts to the
walker: dust on paths, grass flicks, shore ripples, and kicked leaves. Every map has its own
population of small animals (rabbits, squirrels, voles, mice, hedgehogs,
frogs, ducks, sparrows, lizards, and now and then a fox) in groups that
keep to their habitat and flee, hide, curl up, dive, or fly off when the
walker comes near. The Painted Lands and Green Caves randomizers draw the
Cozy Farm bunny in place of the rabbit and keep farm animals by the homes
(chickens, turkeys, and pigs in the yard; sheep, goats, and cows on the
pasture), which amble off and doze. `tools/check_wildlife.gd` (same arguments as
`check_recipes.gd`) lists each map's population. To check how the scene answers the
walker, `tools/walker_test.tscn` walks a route through each camera view
(past the animals, cobble, dirt, tufts, flowers, the shore, and trees) and
counts animal reactions, dust puffs, grass flicks, kicked leaves, and
scattered butterflies. Headless it runs all 30 recipes in a few minutes:

```
Godot_v4.6.1-stable_win64.exe --headless --fixed-fps 60 --path E:\code\claude-godot-mystic res://tools/walker_test.tscn
```

With a window it also films the 13 calibration maps (about 38 minutes, the
walker's own sprite masked out); measure with
`python3 tools/liveliness_analyze.py watch .liveliness_walk`, then compare
with the at-rest capture with `... walkcmp .liveliness`.

Green Caves uses the same tools with `caves` added: `tools/check_caves.gd --
<first_id> [count] [recipe] [dump]` checks maps,
`tools/liveliness.gd -- <first_id> <count> -1 caves` estimates them from
`tools/liveliness_coef_caves.json`, `tools/sim_cave.gd` measures the cave-only
effects headless (drips, motes, glints, bats, the pool frames and sparkles),
`tools/liveliness_capture.tscn -- caves` films 12 cave maps into
`.liveliness_caves` (`liveliness_analyze.py watch .liveliness_caves caves`,
then `fit .liveliness_caves caves`, which writes
`docs/liveliness-calibration-caves.md`), and `tools/walker_test.tscn --
caves` walks them.

## Player

`scripts/player.gd` with `player.png` (48×48 frames, 6 columns):

- Eight-direction movement at 80 px/s with a floating `CharacterBody2D`.
- Four facings. Any horizontal input uses the side row, and left is the
  side row with `flip_h`. Idle is row 0.
- Space plays an attack on rows 6–8, columns 0–3 only. The hitbox is live
  on frames 2–3.
- Feet sit on frame row 42, which is also the y-sort and collision origin.

Physics layers, in order: `world`, `player`, `enemy`, `hurtbox`, `hitbox`.
The game has no health, enemies, or saving yet.

## Scene assembly rules (both packs)

1. Inventory the pack for this scene first: tile size, grid, palette, and
   layers.
2. All world art snaps to 16px.
3. The playing field is built from tilemap layers:
   ground → transitions → props/deco → collision → actors/UI.
4. Match the pack's pixel density, outlines, lighting, and saturation.
5. A distinctive motif goes on the prop layer once. It never becomes a
   repeating ground tile.
6. New tiles are allowed only when the pack lacks one. Generate them at
   exact cell size and pass a 3×3 seam check.
7. Collision comes from layers or tile flags. It is never inferred from
   pixels.
8. Characters and UI stay as separate sprites.

A map is **done** when it loads on-grid, pack tiles dominate the screen,
collision matches walkable ground, and a screenshot sits next to a
reference strip from the same pack.

## Mystic Woods pipeline

1. Height and moisture come from 4-octave value-noise fBm.
2. Thresholds: height above 0.64 is cliff. Height below 0.36 with moisture
   below 0.40 is water. Everything else is grass.
3. Three cellular-automaton passes, then two cliff erode passes. Drop cliff
   components under 40 cells and water components under 12.
4. Flatten the spawn arena (r=5) and the shrine arena (r=4).
5. Autotile from 4-neighbor bits (N=1, E=2, S=4, W=8).
6. Carve a 2-wide dirt A* route from spawn to shrine, then autotile again.
7. De-duplicate interior 3×3 windows.
8. Poisson-scatter trees, flowers, and rocks, then place the shrine prefab.
9. Verify: every id is valid, a flood fill from spawn reaches the shrine,
   and interior 3×3 windows are unique.

Layers: `Ground` → `Features` → `Deco` → `Actors` (y-sorted).

`plains.png` has one clean interior fill per terrain: `(2, 1)` dirt,
`(2, 5)` plateau, `(2, 9)` water. Cells `(4–5, 0–2)` and `(4–5, 8–10)` are
inner corners, which the autotile places where a fully surrounded cell has
an open diagonal. Because the plateau has only one fill, large plateaus
report repeated 3×3 windows. The clearing report prints that count.

## Painted Lands pipeline

`recipe = seed % 36` selects one of 36 recipes (Pastoral, Crossroads,
Pond walk, …, Switchback, then Cave mouth, Terraces, Stone ruins, Woodcutter
camp, Rock garden, Deep forest, Village square, Hedge garden, Ridgeline,
Walled mesa, Cottage row, Twin cottages, Manor green, then the rivers River
crossing, River lane, Twin bridges). The forest and wilds scenes pin recipes
3 and 5. The
recipe sets houses (0, 1, 2 on recipes 10 and 23, 3 on 26
only), water, fences, gates, plateau, path shape, dirt-patch blobs, and
props. The full table is in `docs/painted-lands.md`.

Systems:

- **PATH**: cobble tubes from atlas `(21–23, *)`. Runs of 4 or more widen
  to 2. Caps and knuckles are forced, and there are no 1-tile 45° stairs.
- **PATCH**: dirt islands of 3–8 cells, autotiled with `(30–32, 0–2)` or
  `(24–26, 0–2)`. Each blob's grass uses Mode A (recolor to the lawn) or
  Mode B (a noisy halo). A dark-green tile rectangle is never acceptable.
- **WATER**: an autotile source at columns 44–46, rows 0–2, with water
  plants and rocks.
- **Houses**: four prefabs (porch, flower, gable, hut), each split into
  `HOUSE_BODY` (collides) and `HOUSE_ROOF`.
- **Props**: bushes, land rocks, water plants and rocks, campfire, torches,
  and eight `SIGN` tiles, placed per recipe flags.

Layers: Ground → Features → Patches (Mode B halo sprites) → Deco → Actors.

Where the sheet differs from the `docs/painted-lands.md` atlas notes, the code follows
the sheet:

- `(18–20, 0–2)` is darker grass on mid green, not dirt. Dirt islands use
  `(30–32, 0–2)` for Mode A (its grass is transparent, so the lawn shows
  through) and `(24–26, 0–2)` for Mode B (baked mid green kept only inside
  a noisy halo).
- Prefabs: porch cottage `(38–45, 10–14)`, flower cottage `(38–45, 15–19)`,
  gable cottage `(38–45, 25–29)`, hut `(46–48, 10–12)`.
- `assets/pack/character_sprite_sheet.png` is 6×4 frames of 16×32. Rows
  face right, left (a mirror of right), down, and up. Columns 3–5 repeat
  0–2 with a ground shadow, and the walker uses those.
- The square hedge at `(0–2, 1–3)` reads as a dark-green lawn rectangle,
  and the tree at `(25–28, 11–15)` carries a stray foliage band in its
  base row. Neither is placed.

## Art directories

- `assets/pack/`: hand-painted pack sheets only.
- `assets/ai/`: generated art (Grok Build). Never put generated sheets in
  `assets/pack/`.

`docs/painted-lands-art-fit.md` is the reference for what art from the
antarcticbees tilesets goes with what (Forest, Green Caves, Cozy Cottage, and
Farm – 4 Seasons, which has its own randomizer, docs/farm.md).

## Editor automation

The project is driven from Claude Code through the Godot MCP server
(`@satelliteoflove/godot-mcp`). It talks to the `addons/godot_mcp` editor
plugin over WebSocket port 6550.

## Credits

Art (purchased; not included in this repository, see "Art packs" above):

- **Mystic Woods – 16x16 Pixel Art Asset Pack** (v2.2) by
  [Game Endeavor](https://game-endeavor.itch.io/mystic-woods)
  ([@GameEndeavor](https://twitter.com/GameEndeavor)). Tilesets, objects,
  decorations, water, walls, floors, chests, particles, and the player.
  License: commercial use and modification allowed; no redistribution or
  resale, even if modified.
- **The Painted Lands – Forest Tileset** by
  [antarcticbees](https://antarcticbees.itch.io/antarcticbees-the-painted-lands-forest).
  `TILESET_brighter.png` and `character_sprite_sheet.png`. License: use and
  modification in personal and commercial projects.
- **The Painted Lands – Interior Cozy Cottage Tileset** by
  [antarcticbees](https://antarcticbees.itch.io). Wallpapers, floors,
  furniture, and decoration for the home interiors. License: see the pack's
  itch.io page; purchased, not redistributed here.
- **The Painted Lands – Green Caves Tileset** by
  [antarcticbees](https://antarcticbees.itch.io). `green_caves_tileset.png`
  (the pack's slimes are not used). License: see the pack's itch.io page;
  purchased, not redistributed here.
- **Farm – 4 Seasons 16x16 Tileset** (full version) by
  [antarcticbees](https://antarcticbees.itch.io). The spring and summer,
  autumn, and winter tilesets, crops, animated trees, windmills, fence gates,
  and fish in the farm randomizer (the farmer is not used). License: see the pack's itch.io page;
  purchased, not redistributed here.
- **Mana Seed** tilesets by [Seliel the Shaper](https://seliel-the-shaper.itch.io/)
  (Summer, Spring, Autumn, and Winter Forest, Village Accessories, Fences &
  Walls, Weather Effects, and the collection's extras), from the complete
  rpg creator bundle. License: see the pack's readme and itch.io pages;
  purchased, not redistributed here.
- **Cozy Farm** art pack by shubibubi: the farm animals (bunny, chicken,
  turkey, sheep, goat, pig, cow) in the Painted Lands, Green Caves, and farm
  randomizers; its buildings (homes, barn, coop, silos,
  windmill) only in the deprecated cozy farm randomizer. Purchased; not
  redistributed here.
- **Pixel Crawler** by Anokolisa ([Patreon](https://www.patreon.com/Anokolisa)):
  Fairy Forest, Farm Game Assets, Green Woods (Pixel Crawler FREE),
  Cemetery, and Desert environment sheets. License (the packs' Terms.txt):
  credit not required but appreciated; use in commercial projects allowed;
  may be altered; not to be resold or redistributed.
- **Time Fantasy tiles** (TimeFantasy_TILES_6.24.17) by
  [finalbossblues](https://finalbossblues.com) ([timefantasy.net](http://timefantasy.net)).
  `terrain.png`, `outside.png`, `water.png`, `house.png`, and the animated
  torch and fireplace. License: see the pack's readme; purchased, not
  redistributed here.

Other:

- `assets/ai/` character sheets: generated with Grok Build (see
  `assets/ai/README.md`); not part of either pack.
- `addons/godot_mcp`: the Godot MCP editor addon
  ([`@satelliteoflove/godot-mcp`](https://www.npmjs.com/package/@satelliteoflove/godot-mcp)),
  used to drive the editor from the MCP server.
- Engine: [Godot 4.6](https://godotengine.org).
