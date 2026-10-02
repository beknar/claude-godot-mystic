# Project overview

The engine setup, player, scenes, and art directories. Moved out of
`AGENTS.md`; read it when you need the details.

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

Mystic Woods maps (deprecated; docs/deprecated/mystic-woods.md):

- `scenes/clearing/clearing.tscn` — seed `21021`, `player.png`
- `scenes/grove/grove.tscn` — seed `90511`, `assets/ai/characters/wanderer.png`
- `scenes/hollow/hollow.tscn` — seed `44107`, `assets/ai/characters/scout.png`
- `scenes/ford/ford.tscn` — seed `12809`, `assets/ai/characters/warrior-16x16-sheet.png`
  (6×10 of 16×16, same row order as `player.png`; `frame_size` 16)
- `scenes/heath/heath.tscn` — seed `91003`, `include_water` false,
  `assets/ai/characters/red-fighter-16x16.png`. Heath does not control
  a character. `Lineup` places all five Mystic Woods sheets 72px apart
  on one foot line.

Painted Lands maps (docs/painted-lands.md):

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
  settings (starts at map id `75101`, recipe 5 Open meadow) plus an Esc menu that regenerates from a
  random new id with the same generator. Any of the 30 recipes can come up, or
  be pinned. Its first map is pinned to recipe 5.

Painted Lands cozy farm randomizer (deprecated):

- `scenes/randomizer-painted-cozyfarm/randomizer-painted-cozyfarm.tscn` — the
  Painted Lands randomizer with Cozy Farm homes, farmyard buildings, three
  cozy-only map types (id % 36), and the Cozy Farm animals, starting at map
  id `180033`. Deprecated: only the Cozy Farm animals stay in use
  (docs/deprecated/cozy-farm.md).

Mystic Woods randomizer (deprecated):

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

Painted Lands Green Caves mazes (docs/maze-greencaves.md):

- `scenes/maze-greencaves/maze-greencaves.tscn` — `caves.gd` with `maze` on:
  the maze types of `cave_maze.gd` (24, id % 24) laid into the Green Caves
  pipeline, starting at map id `440016`, with the Painted Lands walker, cave
  homes, the Cozy Farm animals, and the same Esc menu, titled "Green Caves
  maze".

Painted Lands farm randomizer (docs/farm.md):

- `scenes/randomizer-paintedlands-farm/randomizer-paintedlands-farm.tscn` —
  the Farm – 4 Seasons pipeline (`farm_terrain.gd` + `farm.gd`, tables in
  `farm_tiles.gd`), starting at map id `190008` (recipe 0 Homestead;
  `recipe = -1`: id % 52), in spring and summer, autumn, or winter (one
  season per map, by recipe), with the Painted Lands walker,
  interiors behind every door, the Cozy Farm animals, and the same Esc menu,
  titled "Painted Lands farm randomizer".

Painted Lands Forest mazes (docs/maze-forest.md):

- `scenes/maze-forest/maze-forest.tscn` — `forest.gd` with `maze` on: the
  maze types of `forest_maze.gd` (24, id % 24) laid into the Painted Lands
  pipeline, starting at map id `400000`, with the Painted Lands walker,
  interiors in the cottages, the Cozy Farm animals, and the same Esc menu,
  titled "Painted Lands forest maze".

Painted Lands Farm mazes (docs/maze-farm.md):

- `scenes/maze-farm/maze-farm.tscn` — `farm.gd` with `maze` on: the maze
  types of `farm_maze.gd` (30, id % 30, in three seasons) laid into the farm
  pipeline, starting at map id `420000`, with the Painted Lands walker,
  interiors behind every building's door, the Cozy Farm animals, and the
  same Esc menu, titled "Painted Lands farm maze".

Painted Lands forest and farm randomizer (docs/farm.md, Farmsteads):

- `scenes/randomizer-paintedlands-forest-farm/randomizer-paintedlands-forest-farm.tscn` —
  `forest_farm.gd` holds the Forest and Farm pipelines (each scene embedded
  without its own menu) and builds all 100 Painted Lands map types, id % 100:
  0-35 Forest, 36-87 Farm, 88-99 the farmsteads (Farm ground with Forest
  houses, fires, lanterns, and clutter). Starts at map id `200088` (recipe 88,
  Cottage homestead). The pipeline not in use is hidden and paused. Same
  walker, interiors, Cozy Farm animals, and Esc menu, titled "Painted Lands
  forest and farm randomizer".

Mana Seed randomizer (not to be used in new work):

- `scenes/randomizer-manaseed/randomizer-manaseed.tscn` — the Mana Seed
  pipeline (`ms_terrain.gd` + `manaseed.gd`), starting at map id `160000`
  (`recipe = -1`: id % 21; the season from the id), with the Painted Lands
  walker and the same Esc menu, titled "Mana Seed randomizer".

Pixel Crawler randomizer:

- `scenes/randomizer-pixelcrawler/randomizer-pixelcrawler.tscn` — the Pixel
  Crawler pipeline (`pc_terrain.gd` + `pixelcrawler.gd`), starting at map id
  `170000` (`recipe = -1`: id % 17; each recipe belongs to one biome), with
  the Painted Lands walker and the same Esc menu, titled "Pixel Crawler
  randomizer".

Time Fantasy randomizer (not suitable):

- `scenes/randomizer-timefantasy/randomizer-timefantasy.tscn` — the Time
  Fantasy pipeline (`tf_terrain.gd` + `timefantasy.gd`), starting at map id
  `150000` (`recipe = -1`: id % 20), with the Painted Lands walker and the same
  Esc menu, titled "Time Fantasy randomizer". Experimental only: the Time
  Fantasy tilesets are no longer considered suitable for any map in this
  project (docs/deprecated/time-fantasy.md).

There is no health, enemy, or save. The editor addon
`addons/godot_mcp` is how this repo is driven from the Godot MCP server.

## Art directories

`assets/pack/` holds the purchased, hand-painted sheets (git-ignored):

- Mystic Woods: `plains.png`, `grass.png`, and the original woods set
- Painted Lands: `TILESET_brighter.png`
- Green Caves: `green_caves/green_caves_tileset.png` (+ `explanations.png`,
  the pack's own guide). Its slimes are characters and are not used.
- Cozy Cottage interiors: `cozy_cottage/` (docs/interiors.md).
- Farm – 4 Seasons: `farm/` (docs/farm.md): `tilesets/` (the seasonal
  sheets, `crops.png`), `tree animations/`, `windmill animations/`,
  `fence gate animations/`, `fishes.png`. All three seasons in use (one per
  map).
- Mana Seed: `mana_seed/` (docs/deprecated/mana-seed.md): the four seasonal forests copied
  under one set of file names per season, plus `village/`, `fences/`,
  `weather/`, `extras/`. Not an antarcticbees pack; not mixed with them.
- Pixel Crawler: `pixel_crawler/` (docs/pixel-crawler.md): the Fairy Forest,
  Farm forest, Green Woods, Cemetery, and Desert asset sheets. Not an
  antarcticbees pack; biomes are never mixed with each other or other packs.
- Time Fantasy: `time_fantasy/` (docs/deprecated/time-fantasy.md). Not an antarcticbees pack
  and never mixed with them. No longer suitable for any map in this project
  (its ground tiles clash with Painted Lands and are too repetitive and hard
  on the eyes by themselves); do not use it for new maps.

**What goes with what:** `docs/painted-lands-art-fit.md` is the one art
reference for combining the antarcticbees tilesets (Forest, Green Caves,
Cozy Cottage, and Farm – 4 Seasons, in `assets/pack/farm/`, git-ignored,
with its own randomizer). Read it before putting one pack's
art on another pack's maps: it lists every pairing and three-pack map idea,
what fits as it is, what needs a color remap, what never mixes, and counts,
with sheet coordinates.

`assets/ai/` is generated in Grok Build (`assets/ai/README.md`).
Never put a generated sheet in `assets/pack/`. The wanderer sheet
matches the player grid: 48×48, 6 columns, 10 rows, attack columns
0–3 only.
