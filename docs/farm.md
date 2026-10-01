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
- One season per map (spring and summer, autumn, or winter: the recipe picks
  the sheet for the whole map); never mix seasons, and never a Farm tile
  with a Forest (`TILESET_brighter.png`) ground tile on one map.
- Every door opens: walk into it and the interior sub-map opens.
- `tools/check_farm.gd` passes on a sweep, the headless walker test has no
  snag on any map type, and a screenshot passes the reject list at the end.
- A prop blocks every cell its collider overlaps (colliders are centered on
  the prop's cell); a trunk collider stays in the trunk's cell. Otherwise the
  walker snags on a collider in a cell the generator left open.

**Coordinates:** `scripts/farm_tiles.gd` is authoritative (read from the sheet
by script, then checked by eye); the notes below explain each piece.

## Pack

antarcticbees' **Farm – 4 Seasons 16x16 Tileset** (full version), copied to
`assets/pack/farm/` (git-ignored) with the pack's own folder names:
`tilesets/` (`farm_spring_summer.png`, `farm_autumn.png`, `farm_winter.png`,
`crops.png`, `tileset_explanations.png`, and the no-shadow copies),
`tree animations/`, `windmill animations/`, `fence gate animations/`, and
`fishes.png`. The farmer (a character) is not used.

The autumn and winter sheets rearrange the layout, so each season has its
own tables (`FarmTiles.SEASONS`, read through `get_for`, `prop`,
`building_region`, `tree_art`). Every group was found again on the season's
sheet by matching its shape (alpha and luminance) at every cell offset, then
checked by eye; a piece with no sure match is left out of that season.

| Season | Sheet | Ground tones (a pale, g lawn, d dark, x deep) | What differs |
|---|---|---|---|
| Spring and summer | `farm_spring_summer.png` | pale (162, 177, 108), lawn (105, 150, 84), dark (63, 128, 78), deep (34, 97, 81) | the tables above |
| Autumn | `farm_autumn.png` | pale (198, 172, 104), lawn (177, 137, 77), dark (147, 91, 55); no deep | plots from `(36, 14)`, plateau tops `(42, 0)`, `(42, 6)`, `(53, 0)`, face `(42, 3)`, foot `(42, 5)`, cave `(33, 4)`; hedge blob `(22, 5)`, straw (tall grass and wheat) `(22, 9)`; buildings moved; autumn trees, windmill; crops as in summer |
| Winter | `farm_winter.png` | white pale (217, 225, 233), light blue lawn (187, 210, 238, the snow the pond banks are drawn on), dark (140, 180, 229), deep (104, 148, 218) | water block from row 23, open water `(0, 21)`; plateau tops `(42, 0)`, `(53, 0)`, `(42, 6)`, face `(42, 3)`, foot `(42, 4)` (no tufts), cave `(36, 2)`; one fence; frosty tufts only (no flowers, wheat, tall grass, hedges, mushrooms, or crops); snow drifts and lumps, snow-capped rocks; one farmhouse (the second is the same); snowy and bare trees (fruit trees bare), the winter windmill and gate |

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

Recipe = map id % 52 (30 spring and summer, 10 autumn, 8 winter, then 4
rivers: 2 summer, 1 autumn, 1 winter); the
recipe's `season` picks the sheet for the whole map. Layout, in order: canopy wall (woodlot), plateaus,
water (pond, lake with an island, a brook, or a river three blocks wide;
where a lane crosses a brook or a river it goes over a bridge, else on
stepping stones: docs/bridges.md), buildings (facing south, walls block, roofs walkable behind),
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
  measured trunk (collider from the root flare, at most 14 px so it stays in
  the trunk's cell), resting on frame 0. A gust sweeps across the farm with
  the wind: when it arrives, four trees in five each get their own start, the
  moment the gust front reaches them (0-3 s from the upwind edge to the
  downwind one) plus their own jitter (up to 1.5 s), so no two shake
  together. The walker brushing a trunk rustles it at once and plays the
  falling-leaves overlay; in a gust some crowns shed the blowing-leaves sheet.
  Crowns fade while the walker is behind them. Bare and dead trees shed
  nothing.
- **Crops** stand on their plot; stalked and leafy ones split in two and the
  top nods with the wind (water_life.gd), as do reeds and wheat bunches. The
  walker wades through them (field cells are walkable, with no collider; the
  animals keep out, and roads are routed round): every plant within 11 px of
  its feet bends away from its step (a shear about the plant's foot, so the
  top moves most) and springs back on a damped spring, swaying a few times as
  it settles, and the step flicks leaves like tall grass.
- **Gates** swing open (the four frames) when the walker comes within 30 px.
- **Fish** leap from open water now and then (a pack fish arcs out and
  drops back with a ring).
- **Seasons:** autumn tints the grass waves, blade flicks, cloud shade, and
  tree shadows warm, and its trees shed autumn leaves; winter has no grass
  waves, butterflies, dragonflies, fireflies, drifting seeds, fish jumps,
  lizards, or frogs, but snow falls over the view (drifting with the wind),
  steps kick up snow, and shadows are blue.
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
rooms) and the manor (3–6) open on Cozy Cottage homes (docs/interiors.md). The **barn** opens on a barn (14 x 11 cells): the
farm sheet's barn-yard kit plank wall with its windows across the back
(`BARN_WALL`, `BARN_WINDOW`), a Cozy Cottage plank floor strewn with loose
straw (the wheat overlay's corner table over a noise mask), three stalls
divided by fence rails with a trough and hay in each, hay piles and bales,
crates, barrels, a bucket, and wheat bunches along the side walls, an aisle
to the doorway, and two or three kinds of the Cozy Farm animals living inside
(wildlife.gd with `local_walker`, so they amble off from the walker indoors
too). It is drawn from the spring and summer sheet in every season (there is
no weather indoors) and built once per map. The **greenhouse** opens on the sheet's own
glasshouse (`GREENHOUSE_ROOM`): a glass back wall with vines, a tiled walk,
two soil beds with crops in rows, and pots; the way out is the gap at the
foot of the aisle. The beds are walkable: the walker wades through the crops
and they bend away and spring back as they do outdoors (`GreenhouseView.crops`,
swayed by farm.gd with the walker's position inside the interior). It is the
same greenhouse on every map that has one (Greenhouse garden, Orchard and
greenhouse, Greenhouse in the snow); no other interior grows crops. It is built once per map and kept.

The **windmill** opens on the mill floor (`_build_mill`, 13 x 12 cells, the
same on the farm and the farmstead maps):

- **Room:** Cozy Cottage plaster over a wooden dado (wallpaper column 1 of
  the brown group) and a plank floor, two Cozy Cottage windows throwing
  sunbeams with dust turning in them (interior_life.gd).
- **The machinery** (the mill kit, below): the great spur wheel under the
  ceiling, the upright shaft, the hopper on its frame trickling grain into
  the eye of the runner stone, which turns on its wooden case (the hurst),
  and a spout at the front dribbling flour into an open sack. It turns with
  gusts of its own (`MillView`; the wind outside pauses while the walker is
  in), its flour dust rising faster as it speeds up, and fades while the
  walker is behind it.
- **About it:** a stack of sacks against the back wall under the sack
  hoist's swaying rope and hook, a ladder to the trapdoor in the corner, a
  spare millstone leaning under the right window, sacks, barrels, boxes,
  and a bucket along the side walls (each kept to its own cell, so the
  lanes along the walls stay open), grain crates and wheat by the machine,
  and flour spilled on the floor. A sack the walker brushes shakes and puffs
  flour.
- **Life:** a mill cat (interior_life.gd: sleeps in a sunbeam or by the
  hearth, wanders, greets the walker) and one or two pairs of mice among
  the sacks (wildlife.gd, they dart off from the walker).
- **Winter:** a stone hearth burns in place of the right window (flames
  and glow from fire_ambience.gd).
- **Up the ladder: the cap** (`_build_cap`, the same 13 x 12 so the camera
  stays put, its floor six rows). Walk into the ladder's foot to climb
  (a fade, then the walker at the top of the ladder); walk into the
  ladder's top, coming up through its hatch, to climb back down. A climb
  needs a fresh press, so holding up does not bounce between the floors.
  The floor left behind is hidden and paused (its colliders leave the
  space; the hearth's glow stays below). Up there: the **brake wheel** on
  the windshaft, turning between its frame posts under the brake band, and
  the **wallower** it drives on the top of the upright shaft, which goes down
  through the floor to the spur wheel below (both turn at the mill's speed
  and fade while the walker is behind them); the **sack trap** with the
  hoist rope (over the hoist corner below), grain crates, wheat, sacks, and
  barrels, board walls (Cozy Cottage column 0) and a darker plank floor,
  two small windows whose sunbeams the **sails' shadows** sweep across
  four times a turn (`SailShadow`, faster in a gust), and a pair of mice in
  the grain. No cat up here, and no way out but the ladder.

The mill kit (`assets/ai/mill/mill_kit.png`, `FarmTiles.MILL`) is
generated art, because neither the Farm nor the Cozy Cottage pack draws mill
machinery: `tools/gen_mill_kit.py` draws it on the 16 px grid in the Farm
sheet's own colors (rock greys for the stones, crate and barrel browns for
the wood, plaster creams for the sacking, the sheet's off-whites for flour)
with its dark outline: the machine in 16 frames (a quarter turn of the wheel
and a sixth of the stone per loop, so it loops seamlessly), the sacks, the
ladder, the spare stone, the hook in 3 frames, two flour spills, and for the
cap the brake wheel and wallower in 16 frames (a quarter turn), the sack
trap, and the ladder's top in its hatch.
`tools/check_mill.gd` builds the mill floor of every windmill map type
(48 of 48 pass: machinery, hoist, windows, the winter hearth, every open
floor cell reachable from the door, the ladder's foot reachable, and every
cap floor cell reachable from where the ladder lands).

**Front doors.** The farmhouses, the manor, and the windmill swing their
own drawn doors open as the walker comes up (`door_px`, in the season's
sheet); the Forest houses on the farmsteads get plank doors made in their
doorway frame's colors (`made_leaf`), and the gable cottage the flower
cottage's doorway (it has none of its own). The barn's way in is its
X-braced double door (`door_pair`: two leaves, hinged at the outer jambs,
both swinging in; its doorstep is cells 3-4 under it, the dark openings
either side are stalls); the greenhouse's doorway stands open. A building
does not fade while the walker stands in its doorway, so the door is seen
opening. Inside, every way out is a door too (the barn's, the
mill floor's, and the greenhouse's in a front-wall beam drawn along the
foot, with a doorstep), swinging open as the walker comes up to it; the cap
has a front wall and no door. See docs/interiors.md. At rest the mill floor measured 0.91 %
of its pixels moving per frame, between the barn (0.49 %) and a farmhouse
home with its fire (1.68 %).

## Liveliness floor

The Painted Lands floor with frozen weights (water 6, tree 6, nodding crop 2,
wheat 1.2, pen 0.25 per cell, flower 3, firefly swarm 60) over every camera
window (43 x 18 cells), threshold 0.09 %. A weak window gets a small pond (up
to two ponds on the map), else a wildflower carpet, else fireflies; in winter
(no flowers or fireflies) a pond or a stand of snowy trees. Bare and dead
trees shed no leaves (they have no leaf colors).

Measured (docs/liveliness-farm.md): local motion median 0.40 % at rest and
0.51 % walking over 12 maps of all three seasons (winter 0.42 %, carried by the
snow), level with the Painted Lands randomizer and above Green Caves and
Pixel Crawler.

## Map types (52)

Spring and summer (0-29):

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

Autumn (30-39):

| # | Map type | Buildings | Features |
|---|---|---|---|
| 30 | Autumn homestead | farmhouse, barn | pumpkin and cabbage fields, pen, pond |
| 31 | Pumpkin harvest | barn | pumpkin and melon fields, scarecrows |
| 32 | Autumn orchard | farmhouse | apple orchard, pond |
| 33 | Golden wheat | windmill, barn | straw fields, wheat rows, hay |
| 34 | Turning lane | manor | turning trees along a sand road |
| 35 | Autumn market | manor, barn | market, fields, crossing roads |
| 36 | Misty lake | farmhouse | lake with an island |
| 37 | Cornfield | windmill | corn rows, scarecrows |
| 38 | Old barn in autumn | barn | dead trees, straw, hedges |
| 39 | Cider farm | farmhouse, windmill | mixed fruit orchard |

Winter (40-47):

| # | Map type | Buildings | Features |
|---|---|---|---|
| 40 | Snowy homestead | farmhouse, barn | pen, pond |
| 41 | Winter pasture | farmhouse | two big pens |
| 42 | Frozen lake | farmhouse | lake with an island, pines |
| 43 | Snowy woodlot | farmhouse | snowy canopy wall, trees |
| 44 | Pine hills | farmhouse | plateaus, snowy pines, pond |
| 45 | Winter village | farmhouse, manor, barn | crossing roads |
| 46 | Greenhouse in the snow | greenhouse, farmhouse | bare orchard, crops growing inside the greenhouse |
| 47 | Winter windmill | windmill, barn | pens, hay |

Rivers (48-51): a river three blocks wide from the north edge to the south,
the farm on both banks, every lane that crosses it on a bridge (one is
routed across if none does).

| # | Map type | Season | Buildings | Features |
|---|---|---|---|---|
| 48 | River farm | summer | farmhouse, barn | fields, pen, bridges |
| 49 | Mill on the river | summer | windmill, farmhouse | wheat, fields, bridges |
| 50 | Russet river | autumn | farmhouse, barn | apple orchard, field, bridges |
| 51 | Frozen river | winter | farmhouse, barn | pen, pines, snowy bridges |

## Farmsteads (`randomizer-paintedlands-forest-farm`)

`scripts/forest_farm.gd` holds both Painted Lands pipelines (the Forest
randomizer and this one, each without its own menu) and builds every map
type of both from one menu, id % 100: 0-35 Forest, 36-87 Farm (0-51 here),
88-99 the farmsteads (`FarmTerrain.MIXED_RECIPES`, Farm ids 52-63, built only
when the painter's `mixed` is on). The pipeline not in use is hidden and
paused (its colliders leave the physics space) and its walker camera
switched off, or the viewport falls back to it when the walker goes indoors.

A farmstead is a Farm map (Farm ground, fences, crops, and trees in its one
season) with Forest art from `TILESET_brighter.png` on top, read from
`FarmTiles.FOREST_PROPS` and the `fl_*` entries of `FarmTiles.BUILDINGS`:

- **Houses:** porch house, flower cottage, gabled cottage, hut, in place of
  the farmhouses (they fit every season); measured collision blocks, a door
  onto a Cozy Cottage home (rooms by house), and a smoking chimney.
- **Hearths** (`_hearths`): a campfire (a big one where the recipe says)
  by a home's door, ringed with logs, ash, and crates; lanterns flanking
  each door (a row lower where the door is in a wall) and pen gates;
  flowerpots and crates by the Forest houses; a sign at the hub. Fires and
  chimneys go to `fire_ambience.gd` (flicker, glow, sparks, smoke) and
  count toward the liveliness floor (a fire 1 x the glow weight, a lantern
  0.4).
- **Forest greenery, summer only** (`_forest_trees`): the Forest's green
  trees, blossoms, and berry bushes among the Farm trees, spaced, with crown
  fades and leaf fall. Forest trees are summer green only, so autumn and
  winter farmsteads keep the Farm's own trees; `FarmTiles.prop()` returns
  nothing for them out of summer.
- Never Forest ground: the lawn, paths, and water stay the Farm's.

Measured (docs/liveliness-farm.md, Farmsteads): 0.55 % local motion at rest
and 0.71 % walking over all 12, the liveliest Painted Lands maps measured;
0 snags on every farmstead.

| # | Map type | Season | Buildings | Features |
|---|---|---|---|---|
| 52 | Cottage homestead | summer | porch house, barn | fields, pen, pond, campfire |
| 53 | Blossom cottage | summer | flower cottage | cherry orchard, strawberry rows |
| 54 | Hamlet by the mill | summer | gabled cottage, hut, windmill | wheat and corn rows, brook, campfire |
| 55 | Woodcutter's clearing | summer | hut | canopy wall, big fire, logs |
| 56 | Village fair | summer | porch house, flower cottage, manor | market, two campfires |
| 57 | Greenhouse cottage | summer | greenhouse, hut | peach orchard, strawberry rows |
| 58 | Lantern lane | autumn | porch house, flower cottage | apple orchard, lantern road |
| 59 | Harvest bonfire | autumn | barn, hut | pumpkin and corn fields, big fire |
| 60 | Autumn hearths | autumn | gabled cottage, hut, windmill | crossing roads, pen |
| 61 | Winter hearth | winter | porch house, barn | pen, pond, campfire |
| 62 | Snowbound hamlet | winter | gabled cottage, hut, flower cottage | pines, two campfires |
| 63 | Frozen mill | winter | windmill, hut | frozen lake, pen |

## Checks

`godot --headless -s res://tools/check_farm.gd -- <first_id> [count] [recipe]`
generates maps and prints each one's recipe, buildings, counts, floor notes,
and checks: the walker reaches every door, gate, field, and the hub; every
cell has a ground tile; every shore cell has a shore tile; every building the
recipe names stands. 104 of 104 maps (190000–190103, every map type twice)
pass on the first layout; with `mixed` (the farmsteads too), 128 of 128
(200000-200127). It prints each map's bridges (design and span) and any
stepping stones left. `tools/walker_test.tscn -- farm` walks every map type
headless (0 snags on all 48); the liveliness tools take `farm` too
(docs/liveliness-farm.md).

## Reject list

A tone zone with a straight or stair-step edge, or a darker tone meeting a
road, yard, or shore directly; a raw square of a darker fill; a shore cell
with no rim or a one-cell channel of water; a road that stops short of a door or breaks in two; a field
with no crops or a crop floating off its plot; a pen with no animals; a tree
whose trunk does not block or whose crown hides the walker without fading; a
building that hides the walker without fading; a door that does not open;
on a farmstead, Forest ground, a Forest tree out of summer, or a fire under a
crown.
