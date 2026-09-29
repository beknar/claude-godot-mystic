# Pixel Crawler

Read this before touching `scripts/pc_terrain.gd`, `scripts/pixelcrawler.gd`,
`scripts/pc_tiles.gd`, or the Pixel Crawler randomizer.

**Never break (the looks):**
- One biome per map; never mix biome sheets with each other or with any
  other pack.
- Ground only through the corner tables (`pc_tiles.gd`); `_repair()` must
  leave every cell with a tile (the check fails otherwise).
- Farm forest greens stay graded (`grade_green`); no blinding green.
- Light and dark grass stay varied (splat, pack shadows); no wall of one
  repeating fill.
- Trees stand on their measured trunk; crowns fade while the walker is
  behind them; nothing tall stands in front of a plateau face.
- Desert props stand only on light sand.

**Coordinates:** `pc_terrain.gd` (`PROPS`, `BIOMES`) and `pc_tiles.gd`
are authoritative.

Do not apply this section to the other maps, and do not use their sheets
here. Pack: Anokolisa's Pixel Crawler collection (`I:\game assets\pixel
crawler`), the environment sheets copied to `assets/pack/pixel_crawler/`
(git-ignored): `fairy_forest/` (Tiles, Props, Tree, Light, Shadown),
`farm/` (the Farm Game Assets forest: Tiles, Vegetation, Tree_02-05),
`green_woods/` (Tiles, Props, Trees), `cemetery/` (Tiles, Trees), `desert/`
(Tiles). Indoor sets (Dungeon Prison, Sewer, Forge, Farm interiors) and the
characters are not used. Generator `scripts/pc_terrain.gd` (`PCTerrain`,
64x40), painter `scripts/pixelcrawler.gd`, corner tables
`scripts/pc_tiles.gd` (tile indices only). `tools/check_pc.gd` sweeps maps
headless. The packs' Social mockups were the reference for how pieces
combine.

## Biomes and colors

Four biomes, each self-contained (palettes do not mix):

- **fairy** (Fairy Forest): dark teal grass (12, 82, 44), dark grass
  (12, 66, 40), olive earth (69, 66, 43), dark earth; bright blue water
  (20, 149, 198). Trees in 12 colors (green, olive, purple, teal, three
  shades each) and five sizes; glowing bell flowers and runestones.
- **green** (Farm forest): grass (46, 127, 0) and dark grass (27, 119, 53),
  saturation about 0.97, so graded at load (`grade_green`: saturation above
  0.5 compressed to 45 % of the excess, bright greens pulled down, hue
  kept); earth (163, 116, 46); water (20, 91, 188). Seasonal trees (green,
  yellow, red, orange, bare), crystal tree, Green Woods bushes and crates.
- **cemetery**: brown earth (99, 61, 38), dark earth, grey cobble; red
  pines, dead pines, bare and autumn birches, headstones, boulders.
- **desert**: sand (209, 137, 70), dark sand (134, 71, 46); cacti, tusks,
  dead trees, rocks. Desert props bake light sand at their base, so they
  stand only on sand (`on` in PROPS).

## Sheet systems (cells of 16 px)

- **Ground: corner tables.** Each terrain pair is drawn as a 3 x 3 blob
  beside (or above) its 3 x 3 hole ring: outer corners, edges, fill, and
  inner corners. The tables were read from the sheets by labelling each
  tile's four corners by terrain color (see the header of `pc_tiles.gd`;
  Desert by position, its blob edges sit on the cell borders). Pairs:
  fairy g-e, g-d, d-e, e-k; green e-g, d-g; cemetery e-k, e-c; desert s-k.
  Each biome's terrains nest on a parent (`BIOMES.kids`); after the layout,
  `_repair()` returns the lowest-priority terrain of any cell whose corners
  no tile draws (three terrains, a missing pair, a diagonal) to its parent.
- **Plateaus:** one stamp per biome (Fairy Forest has a grass-topped and an
  earth-topped one), widened by repeating its middle columns and deepened
  by repeating a top row and a face row. Impassable relief (the sheets have
  no stairs); the root ground round it follows its shape.
- **Water:** the sheets draw water only round island stamps (grass island,
  earth island), with no pond corners, so ponds and streams are drawn per
  pixel (`_paint_water`): a smooth field over the water cells with a wobble
  and an ordered dither is open water above 0.52, then the sheet's two shore
  blues, then its dark bank shadow on the ground. Lakes carry the island
  stamp. Streams are crossed on stepping stones.
- **Props:** `PROPS` rects were cut from the sheets by connected opaque
  regions and checked on a contact sheet; Fairy Forest trees come from
  `ff_tree(color, size)`.

## Ground variety

Both the light (root) and dark (zone) ground are varied three ways:

- **Splat** (`_apply_splat`, `shaders/ms_grass_splat.gdshader`, the Mana
  Seed shader): four textures over pure root ground and four over pure zone
  ground, each the biome's own fill retoned: sunlit (brighter and warmer;
  less on the graded Farm greens), dry (toward the patch terrain), tufts,
  and shade (light set toward the zone terrain, dark set darker). Weights
  (`PCTerrain._splat`) are noise raised by context: sunlit away from trees,
  dry by paths and patches, tufts at a finer scale, shade by trunks and
  plateau feet; eligibility fades in over two corners from any other
  terrain, water, or plateau.
- **Painted Lands tufts, recolored:** the tufts layer lays the shapes of
  Painted Lands sprouts `(5, 1)`, `(6, 2)`, `(7, 3)`, `(6, 1)` on the fill,
  colored from the biome's own palette (stems darker than its darkest color,
  blades lighter than its lightest). Painted Lands grass colors are not used:
  measured against the Fairy Forest grass they are close in hue (0.43-0.49
  against 0.41) but far less saturated (0.39-0.63 against 0.85) and bluer
  (median nearest-color distance 24-26); against the Farm grass, 77. Both
  packs' grass fills are nearly flat (two to five colors), so only shapes
  carry over.
- **The pack's shadows and light** (fairy_forest/Shadown.png, Light.png):
  canopy shadows under every tree (the big blob for crowns 90 px wide and
  more, the small one down to 38, an oval below that), ovals under rocks,
  bushes, graves, and cacti, drawn opaque in one CanvasGroup at 0.3 alpha so
  overlaps do not darken twice; the soft cyan light discs (additive, 0.22)
  round the glowing runestones. Nothing tall stands in the seven rows in
  front of a plateau, so its face stays in view.

## Trees: trunks and crowns

- **Trunk from the sprite.** Big crowns are not centered on their trunks
  (the largest Fairy Forest tree's trunk is about 34 px right of its sprite
  middle). `_trunk_of()` reads the opaque span of the root flare (four to ten
  rows above the bottom): the tree stands on its middle, and the collider is
  that span wide (at least 8 px, 6-12 px tall). The generator's tree blocks
  (`ff_tree` sizes, the big Farm and Cemetery trees) reserve the measured
  flares, and every cell a collider spans counts as blocked in the walk check.
- **Crown fade.** While the walker's body overlaps a crown (the sprite's top
  78 %) and its feet are above the tree's foot, the tree eases to 0.42 alpha
  (`CROWN_FADE`), and back when it leaves. Trees under 60 px tall do not fade.

## Pipeline

Recipe (`id % 17`), then: spawn, plateaus, water (ponds, a lake with its
island, or a stream), zones (the zone terrain where a noise field peaks, at
the recipe's share), paths (A* with a strong wander cost), patches (rounded
clearings; dark earth inside some Fairy Forest ones), repair, the set piece,
trees (clusters over undergrowth, then singles), small scatter, the
liveliness floor, the splat fields, then the reach check and a check that
every cell has a tile.

Recipes: 0 Fairy glade, 1 Runestone circle, 2 Glowbell hollow, 3 Twilight
stream, 4 Root ledges, 5 Deep fairy wood (fairy); 6 Greenwood, 7 Forest
trail, 8 Island lake, 9 Autumn grove, 10 Crystal thicket (green); 11 Old
cemetery, 12 Dead wood, 13 Red pine hill (cemetery); 14 Dune sea, 15 Bone
field, 16 Mesa (desert).

## Liveliness (not yet measured)

The Painted Lands set through its generic setups: wind, leaves from every
crown (colors from each tree sprite), wind streaks, cloud shadows and grass
waves and footstep colors per biome (`BIOME_FX`), water life, critters
(butterflies on flowers and mushrooms, dragonflies on ponds, fireflies over
the zone terrain), drifters, wildlife planned from the map. Cold light from
`fire_ambience.gd` (its new optional `tint`): violet on the bell flowers,
teal on the glowing runestones. From Green Caves, `CaveLife` with bats off:
motes in that light, glints on the runestones and the crystal tree. The
sheets have no fires or torches, so the liveliness floor (Painted Lands
frozen weights, not recalibrated) adds a small pond on the grass biomes, or
a swarm of fireflies (with a few glowing bells in the Fairy Forest). Not yet
analyzed or calibrated for this pack.
