# Mana Seed (not to be used)

**Not to be used in future development in this project.** This section
records how the existing scene was built.

Do not apply this section to the other maps, and do not use their sheets
here. Pack: Seliel the Shaper's Mana Seed collection (the "complete rpg
creator bundle"), copied to `assets/pack/mana_seed/` (git-ignored):

- `<season>/` for spring, summer, autumn (the "leaves" set), and winter (the
  "snowy" set), each with the same file names and the same layout:
  `wang.png` (ground), `forest.png` (cliffs, undergrowth, deco),
  `trees.png` (three 80x112 trees), `16x16.png`, `16x32.png`, `32x32.png`,
  `48x32.png` (props), `tallgrass.png` (the walk-through rustle),
  `sparkles.png` (water sparkles), `waterfall.png`, `treewall.png` and
  `canopy.png` (the forest wall and its leaves-only overlay).
- `village/` (Village Accessories), `fences/` (Fences & Walls), `weather/`
  (Weather Effects), `extras/` (bonus bridge, shadows, decks, stairs).

Generator `scripts/ms_terrain.gd` (`MSTerrain`, 64x40), painter
`scripts/manaseed.gd`, weather `scripts/ms_weather.gd`, the corner table
`scripts/ms_wang.gd` (indices read from the pack's TSX, no art).
`tools/check_ms.gd` sweeps maps headless. The pack's Tiled usage-guide and
sample maps were the reference for how pieces combine.

## Sheet systems (cells of 16 px)

- **Ground: corner Wang.** `wang.png` (64 columns) holds every combination
  of six terrains on a cell's four corners (1296 tiles plus fill variants):
  dirt, light grass (snow in winter), dark grass, cobblestone, shallow water,
  deep water. The map is a (W + 1) x (H + 1) corner grid; each cell takes
  `MSWang.TILES[TL * 1000 + TR * 100 + BL * 10 + BR]`, so any shape blends
  with the pack's own hand-drawn transitions and nothing is ever reshaped.
  Fills pick a variant by hash, mostly the plain one; cobble's red-stone
  variants are rare. Deep water is flat: the sparkles overlay moves on it.
- **Plateaus** (forest.png): the usage guide's plateau, a rounded grass top
  over a banded face on two layers (under: 17-22 x 0-7 pieces plus the
  shaded ground (1, 20); second layer: the side and corner pieces) and a
  cast-shadow column (13, 10 / 13 / 15). It widens by repeating its middle
  column pair and deepens by repeating the side row (top) and face row 5.
  Stairs three wide: (14-16, 9) on the lip row, (14-16, 10) on the face,
  (14-16, 11) on the foot. The top is reached only by its stairs. In autumn
  the face and the stairs are both grey stone.
- **Forest wall** (treewall.png): 128 px supertiles on an 8-cell corner grid
  (forest or clearing). A supertile touching forest is drawn as trees nearly
  all over (clearing shows only as small rounded bits at its clear corners),
  so its whole 8 x 8 area is wall ground: plain light grass, nothing placed.
  The painter cuts every 16 px subtile that is exactly a ground tile of the
  season's sheets out of the wall texture, so the map's own ground shows
  through; `WALL_COVER` lists the subtiles that stay drawn, and that cover
  less a one-cell rim blocks (the walker steps just under the leaf edge).
  `canopy.png` is drawn over the actors.
- **Undergrowth** (forest.png 13-15, 0-2): a 3 x 3 bush-mass autotile, used
  as two-row masses under tree clusters and along the wall; it blocks. Not in
  winter (the snowy sheet draws those cells as snow outlines).
- **Props:** trees (oak, round, birch) in clusters over bushes, then single;
  bushes and berry bushes, boulders, stumps, logs, mushrooms, ferns, sticks,
  pebbles; lily pads and wet rocks on open water, cattails on the shallow
  rim; tall grass rows (16x32 left, middle, right pieces) that play the
  rustle as the walker enters. Village: animated torch (village anim 16x48,
  frames 1-4), lamp posts, well, notice board, cart, crates, barrels,
  firewood, chopping stumps, potted cypress. Ranch fence: top and bottom
  rows west end / rail / east end, sides the rail edge-on (0, 1) with a post
  (3, 1) every third cell. Stone bridge (extras) where a road crosses a
  brook.
- **Ground deco:** flowers baked on light grass (forest.png 5-8, 6-7) and
  tufts (3-4, 6), only on cells whose four corners are light grass.

## Pipeline

Recipe (`id % 21`) and season (`(id / 21) % seasons`), then: forest wall,
spawn (inside the clearing when there is a wall), plateaus, lake or brook
(three corners wide, meandering, off the spawn), ponds (lumpy ellipses:
shallow rim, deep inside; a lake may carry grass islands), dark-grass zones
(corner noise cut at the recipe's share, two majority passes, kept off the
plateaus and the wall), paths (A* with a wander cost; roads two cells wide,
trails one corner wide swelling to two; the wall, cliffs, and ponds are
solid, a brook is crossed by the bridge), cell kinds, the light-grass limit,
cell kinds again, the set piece, trees,
undergrowth, tall grass, small props, water props, ground deco, the
liveliness floor, the grass splat fields, then the reach check (plateau tops
only by their stairs).

Recipes: 0 Meadow, 1 Forest glade (wall), 2 Lakeside, 3 Brookside, 4
Cliffside, 5 Terraces, 6 Old road (cobble), 7 Woodcutter's camp (wall), 8
Village well (cobble plaza), 9 Paddock (ranch fence), 10 Marsh (5-7 ponds,
no winter), 11 Deep woods (heavy wall), 12 Berry thicket (no winter), 13
Rocky rise, 14 Pond garden, 15 Crossroads, and three where the grass itself
is the feature: 16 Wildflower meadow (flower splat heavy, no winter), 17
Sunlit heath (straw splat heavy, tall grass, open), 18 Mossy hollow (moss and
lush splat, wall, ponds), and two from the light-grass limit: 19 Stony
barrens (rocky ground half the replaced grass, boulders, straw splat) and
20 Dusky woodland (all shade: dark grass, many trees, moss splat). A recipe's
`splat` scales the season's shares, `ground` sets its light-grass
replacement mix.

## Light-grass limit

Plain light grass (a cell whose four corners are light grass) shows on at
most 30 % of the visible map (`LIGHT_LIMIT`; the cells under the forest
wall do not count). After the paths, `_limit_light()` takes the excess down
to about 28 %: first dirt and rocky ground (the Wang cobblestone) by the
recipe's `ground` mix (default dark 0.75, dirt 0.15, rock 0.1; Sunlit heath
dirt-heavy, Rocky rise and Stony barrens rock-heavy, Marsh, Mossy hollow,
Dusky woodland nearly all dark), each where its own low-frequency noise
peaks, two corners off any path, spurs trimmed so the patches are round;
then the dark-grass zones grow, highest zone noise first. Corners by the
plateaus, the wall, and the spawn stay. Rocky ground gets pebbles and
stones. The report line shows `light grass N%` and the check fails a map
over the limit. Winter is exempt: its light terrain is snow.

## Grass splat

So no grass is one repeating green across the view, the Ground layer runs
`shaders/ms_grass_splat.gdshader`. Over pure light grass, and with a second
layer set over pure dark grass (the fade texture's green channel), each
pixel takes one of four grass textures, or keeps the base:

- **lush**, **dry**, **moss**: the season's own light-grass fill with its four
  colors (base, two blades, shadow) moved rank for rank part of the way
  toward a partner palette (`SPLAT_SOURCES` in `manaseed.gd`): lush toward a
  greener grass, dry toward straw, moss toward the season's dark grass (a
  true middle tone). The pack's pixels and shading stay; only the tone
  shifts. Importing another season's grass as drawn was too strong (autumn
  gold read as dirt, spring dark as blue-grey).
- **flowers**: forest.png's flower grass (5-8, 6) as drawn.
- Dark set (`SPLAT_DARK`): the season's dark fill moved toward the light
  grass (lush), toward dirt (dry), and toward itself darkened (moss); flowers
  are the flower tiles' blossoms laid on the dark fill. Winter's dark is bare
  earth, with snowless grass, snow, and earth patches on it as drawn.
- Winter: lush and dry are the snowless winter sheet's grass and bare earth
  as drawn (`winter/wang_clean.png`), grass and earth showing through snow;
  each capped at 14 % and drawn with a tighter dither.

Weights are per map corner (`MSTerrain._splat`): value noise per layer
(flowers at a finer scale), raised by context (lush within five corners of
water, dry within four of dirt, cobble, and rocks, moss within four of
trunks and the forest wall), cut at the layer's share of the eligible
corners (`SPLAT_SHARE` by season) with a soft band. Eligibility (`splat_fade`)
is the Euclidean corner distance to anything that is not free light grass
(other terrain, plateaus, the wall), ramping in over two corners, so the
splat never meets a Wang transition tile or baked grass (plateau rims, wall
trunk grass) at a seam, and its edge round a pond or path is round. The
shader picks the strongest layer over 0.5 after an ordered dither and a small
wobble, so layers meet in crisp dithered pixel rims, never blended colors;
the fade acts as an edge, not a dimmer. The flower deco tiles have their
baked light grass cut out (`DECO_SRC`), so they sit on whatever grass is
under them. The shader's world position comes from the model matrix: the
layer draws in quadrants whose VERTEX is local.


## Liveliness (not yet measured)

The Painted Lands set through its generic setups: wind, leaves from every
crown (colors from the season's tree sprites; none in winter), wind streaks,
cloud shadows (the season's shade), grass waves and blade flicks (tips
lighter than the season's grass; snow puffs in winter), water life (rings in
a tint paler than the season's water), critters (butterflies on flowers,
dragonflies on ponds, fireflies over dark grass in summer and autumn),
drifters, wildlife planned from the map, footsteps, fire glow (torches and
lamp posts). From Green Caves, `CaveLife` with bats off: warm motes in torch
and lamp light, pale motes, glints on wet rocks. From the pack: tile-animated
water sparkles, the tall-grass rustle, and weather (winter snow, light and
sometimes heavy behind it; light rain on some spring and autumn maps and
more often on the marsh). Liveliness floor with the Painted Lands frozen
weights, not recalibrated: a weak window gets torches facing each other
across a path, a lamp post beside a path, or a small pond away from paths.
The liveliness has not been analyzed or calibrated for this pack yet.
