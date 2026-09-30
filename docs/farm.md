# Painted Lands, Farm – 4 Seasons

Read this before touching `scripts/farm_terrain.gd`, `scripts/farm.gd`,
`scripts/farm_tiles.gd`, or `scenes/randomizer-paintedlands-farm`.

**Never break (the looks):**
- Blend ground only through the sheet's own tiles: the corner table for lawn,
  sand, and dirt; tone zones per pixel from each tone's own fill (never a
  raw rectangle of a darker fill).
- Build ponds from 2 x 2 blocks so every shore cell has a tile; no one-cell
  channel, spit, or corner-only join.
- Zones bend away from roads, yards, water, plateaus, buildings, fields, and
  fences, and never touch their baked lawn.
- One season per map (spring and summer only so far); never mix a Farm tile
  with a Forest (`TILESET_brighter.png`) ground tile on one map.
- Every door opens: walk into it and the interior sub-map opens.
- `tools/check_farm.gd` passes on a sweep, and a screenshot passes the reject
  list at the end.

**Coordinates:** `scripts/farm_tiles.gd` is authoritative (read from the sheet
by script, then checked by eye); the notes below explain each piece.

## Pack

antarcticbees' **Farm – 4 Seasons 16x16 Tileset** (full version), copied to
`assets/pack/farm/` (git-ignored) with the pack's own folder names:
`tilesets/` (`farm_spring_summer.png`, `farm_autumn.png`, `farm_winter.png`,
`crops.png`, `tileset_explanations.png`, and the no-shadow copies),
`tree animations/`, `windmill animations/`, `fence gate animations/`, and
`fishes.png`. The farmer (a character) is not used.

The autumn and winter sheets rearrange the layout (autumn has three grass
tones, not four), so each season needs its own tables. Only spring and
summer are built; a season would be a second set of tables in
`farm_tiles.gd`.

## The sheet's systems (`farm_spring_summer.png`, 16 px cells)

| System | Where | How it is used |
|---|---|---|
| Ground | blobs and holes at `(27–38, 0–5)` and `(27–38, 12–23)`, fills at `(19–26, 0–1)` | a corner table (`FarmTiles.WANG`): lawn `g`, pale `a`, dark `d`, deep `x`, sand `s`, dirt `e`; every pair the sheet blends has 14 of the 16 mixes (no diagonals); a cell no tile draws returns its lowest-priority terrain to its parent |
| Tone zones | fills: pale `(19–22, 0)`, dark `(23–26, 0)`, deep `(23–26, 1)` | drawn per pixel from the fill (below), not from the blob tiles |
| Water | four frames stacked 5 rows apart from `(0–8, 21–25)`; open water `(13–16, 19–20)` | edge shores: a rock lip inside the land cell, a ripple inside the water cell; 12 land and 12 water tiles by neighbors |
| Plateaus | tops (rim blobs) lawn `(45–47, 0–2)`, pale `(45–47, 6–8)`, dark `(52–54, 6–8)`; face `(45–47, 3)`, foot `(45–47, 5)`; cave `(36–38, 4–5)` | stretched stamps, impassable |
| Plots | dry `(40–43, 14–17)`, wet `(52–55, 14–17)`, ragged wet `(52–55, 18–21)` | a 3 x 3 block, a one-wide column, a one-tall row, a single plot |
| Overlay blobs | hedge `(22–26, 6–9)`, tall grass `(22–26, 10–13)`, wheat `(22–26, 14–17)` | corner tables with all 16 mixes (diagonals too) on transparent ground |
| Fences | plain `(11–13, 12–14)`, grassy `(14–16, 12–14)`; gate sheet (4 frames) | a 3 x 3 frame round a pen |
| Deco | sprouts `(19–26, 2–3)`, flowers `(19–24, 4–5)`, tufts `(25–26, 4)` | by tone |
| Props | trees, logs, stumps, rocks, mushrooms, bushes, crates, barrels, chests, bucket, mailbox, pots, scarecrow, wheat bunches, reeds, signs, hay, troughs | `FarmTiles.PROPS` (px rects) |
| Buildings | farmhouses `(816, 384)`, `(912, 384)`, manor `(1008, 384)`, barn `(816, 480)`, greenhouse `(1024, 96)` | `FarmTiles.BUILDINGS`: region, door cell, colliders, rooms |
| Greenhouse interior | `(64–74, 11–22)` | the greenhouse's own interior sub-map |

`crops.png`: sixteen crops in growth stages, young to ripe (a tall stage
takes the cell above): carrot, potato, corn, cabbage, cauliflower,
watermelon, leek, pumpkin, sunflower, berry, onion, strawberry, wheat, beet,
tomato, pepper (`FarmTiles.CROPS`).

Animations: the trees (`tree animations/spring and summer/trees_cut_down/`,
eight frames each: the tree rustles and a leaf drops; basic trees 1–4, the
pine, apple, cherry, orange, and peach, plain, blossom or flowers, and
fruit), their falling-leaves overlays, the leaves blowing in the wind
(`leaves_wind/`, eight 64 px frames; cherry petals for the blossom), the
windmill (four 96 x 128 frames), the gate (four 16 px frames), and the fish.

## Generator (`scripts/farm_terrain.gd`, `FarmTerrain`, 64 x 40)

Recipe = map id % 30. Layout, in order: canopy wall (woodlot), plateaus,
water (pond, lake with an island, or a brook with stepping stones where the
road crosses), buildings (facing south, walls block, roofs walkable behind),
roads and yards (dirt or sand by recipe; edge to edge, crossing, or lanes;
long routes wind through an offset waypoint; routes keep off locked lawn
corners), pens, fields, orchard, wheat / tall grass / hedge blobs (lumpy
polar outlines), tone field, repair, set pieces, trees (clusters on dark
grass, then singles), small scatter, deco, the liveliness floor, and the walk
check (up to 30 layout attempts).

**Ponds** are a rectangle of blocks with a lobe (an L or a T) nine times in
ten, an island in lakes; `_clean_blocks` adds a block where two meet only at
a corner and fills a land block with water on three sides. **Brooks** run a
block wide and jog one block every three to six (a lazy bend).

**Tone zones** (`tone_field`, per corner): 3-octave noise sampled rotated,
multiplied by a fade that is 0 within about 1.5 corners of anything the zones
keep clear of and 1 beyond 4.5, with the keep-out distance itself wobbled by a
second noise so an edge near a straight road does not run parallel to it.
Cuts are quantiles of the open ground: pale at `recipe.pale`, dark at
`1 - recipe.zones`, deep at `1 - zones * 0.35`, with pale at most -0.08, dark
at least 0.08, and deep at least 0.12 above dark. farm.gd draws a cell the
level covers everywhere as the fill tile and a cell its contour crosses per
pixel: bilinear between the corners, plus a wobble of about three pixels of
the field's own slope and a dither. Deep sits inside dark (one wobble).

**Fields** are bordered blocks or one-tall crop rows with a lane between;
one crop per field, most ripe, some a stage younger, a few gaps. **Pens** are
fence frames with a gate on the south side; a trough inside most.
**Orchards** are rows of fruit trees with a little jitter.

## Painter (`scripts/farm.gd`)

Layers: ground (corner table), three tone layers (tiles plus a per-pixel
edge sprite each), water (animated shore and open-water tiles), features
(plots, blobs, fences, plateau stamps), deco, tree shadows (one CanvasGroup
of dithered ovals in the deep tone), under (flat props, gates, stepping
stones), and y-sorted actors (buildings, trees, crops, props, the walker,
the animals).

- **Buildings** are one sprite sorted at the foot, colliders from their
  walls; they fade to 55 % while the walker is behind them. The windmill is
  the animated sheet, sped up by the wind.
- **Trees** are AnimatedSprite2D on the pack's sheets, standing on their
  measured trunk (collider from the root flare), resting on frame 0. A gust's
  onset sets most rustling (each tree a moment apart); the walker brushing a
  trunk rustles it and plays the falling-leaves overlay; in a gust some
  crowns shed the blowing-leaves sheet. Crowns fade while the walker is
  behind them.
- **Crops** stand on their plot; stalked and leafy ones split in two and the
  top nods with the wind (water_life.gd), as do reeds and wheat bunches.
- **Gates** swing open (the four frames) when the walker comes within 30 px.
- **Fish** leap from open water now and then (a pack fish arcs out and
  drops back with a ring).
- Ambience as the Painted Lands scenes: wind, streaks, cloud shadows, grass
  waves (lawn and wheat), water life, footsteps (dust on roads, blade flicks,
  tuft rustle in wheat and deco), critters (butterflies at flowers, blossom
  trees, and flowering crops; dragonflies at ponds; fireflies on dark grass),
  drifters, falling leaves.
- **Animals** (`cozy_animals`): wildlife.gd `mode = "farmland"`, the Cozy
  Farm table with two to four farm kinds, grazers first; poultry and pigs in
  the yards round the doors, sheep, goats, and cows in the pens (every pen
  gets a herd), bunnies on the lawn, and the drawn small animals and birds.

## Interiors

Every building has a door (house_interiors.gd `reset_doors`): walk into it
and the screen fades to a sub-map far below the farm. Farmhouses (2–4
rooms), the manor (3–6), the barn (1–2), and the windmill (1) open on Cozy
Cottage homes (docs/interiors.md). The **greenhouse** opens on the sheet's own
glasshouse (`GREENHOUSE_ROOM`): a glass back wall with vines, a tiled walk,
two soil beds with crops in rows, and pots; the way out is the gap at the
foot of the aisle. It is built once per map and kept.

## Liveliness floor

The Painted Lands floor with frozen weights (water 6, tree 6, nodding crop 2,
wheat 1.2, pen 0.25 per cell, flower 3, firefly swarm 60) over every camera
window (43 x 18 cells), threshold 0.09 %. A weak window gets a small pond (up
to two ponds on the map), else a wildflower carpet, else fireflies.

## Map types (30)

| # | Map type | Buildings | Features |
|---|---|---|---|
| 0 | Homestead | farmhouse, barn | fields, pen, pond, road |
| 1 | Wheat valley | windmill, farmhouse | wheat, crop rows, brook |
| 2 | Windmill hill | windmill | plateaus, wheat, corn rows |
| 3 | Apple orchard | farmhouse | apple orchard, pond |
| 4 | Cherry blossom lane | manor | cherry orchard (petals), sand road |
| 5 | Pumpkin patch | barn | pumpkin and melon fields, scarecrows |
| 6 | Kitchen garden | farmhouse | small crop-row beds, pots |
| 7 | Greenhouse garden | greenhouse, farmhouse | berry and tomato rows, peach trees |
| 8 | Barnyard | barn, farmhouse | two pens, corn rows |
| 9 | Sheep meadow | farmhouse | two big pens, pond |
| 10 | Duck pond farm | farmhouse | lake with an island, fields |
| 11 | Riverside fields | farmhouse | brook, crop rows |
| 12 | Farm village | two farmhouses, manor | crossing roads, fields |
| 13 | Market crossroads | manor, barn | market crates and barrels, crossing roads |
| 14 | Sunflower field | farmhouse | sunflower rows, scarecrows |
| 15 | Corn rows | windmill, barn | corn rows, scarecrows |
| 16 | Berry patch | farmhouse | strawberry and berry rows, hedges |
| 17 | Hillside terraces | farmhouse | plateaus, crop rows |
| 18 | Woodlot | farmhouse | canopy wall, thirty trees, logs |
| 19 | Pine ridge | farmhouse | plateaus, pines, pond |
| 20 | Wildflower meadow | none | tall grass, flower carpets, pond |
| 21 | Old farm | barn | dead trees, tall grass, hedges |
| 22 | Fishing lake | farmhouse | lake with an island, reeds |
| 23 | Cattle ranch | barn, farmhouse | two or three big pens |
| 24 | Hayfield | barn | wheat, tall grass, hay |
| 25 | Scarecrow fields | windmill | four fields, scarecrows |
| 26 | Twin farms | two farmhouses | fields, pen, road |
| 27 | Stone quarry | farmhouse | plateaus with a cave, rocks |
| 28 | Orchard and greenhouse | greenhouse | mixed fruit orchard, strawberry rows |
| 29 | Harvest fair | manor, farmhouse, windmill | fields, market, crossing roads |

## Checks

`godot --headless -s res://tools/check_farm.gd -- <first_id> [count] [recipe]`
generates maps and prints each one's recipe, buildings, counts, floor notes,
and checks: the walker reaches every door, gate, field, and the hub; every
cell has a ground tile; every shore cell has a shore tile; every building the
recipe names stands. 90 of 90 maps (190000–190089) pass on the first layout.

## Reject list

A tone zone with a straight or stair-step edge, or a darker tone meeting a
road, yard, or shore directly; a raw square of a darker fill; a shore cell
with no rim or a one-cell channel of water; a road that stops short of a door or breaks in two; a field
with no crops or a crop floating off its plot; a pen with no animals; a tree
whose trunk does not block or whose crown hides the walker without fading; a
building that hides the walker without fading; a door that does not open.
