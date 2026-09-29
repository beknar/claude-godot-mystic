# Time Fantasy (not suitable)

**Not suitable for this project.** Consider the Time Fantasy tilesets no
longer suitable for any map here: the prevalent ground tiles are incompatible
with, or clash with, the Painted Lands tiles, and on their own they are too
repetitive and a strain on the eyes. Do not use them for new maps or mix them
into existing ones. This section records how the existing experimental scene was built.

Do not apply this section to the other maps, and do not use their sheets
here. Sheets: `assets/pack/time_fantasy/` (finalbossblues'
TimeFantasy_TILES_6.24.17: `terrain.png`, `outside.png`, `water.png`,
`house.png`, `animated/`, and the pack's `guide.png`). `world.png` is never
used: it is drawn for a zoomed-out strategic map. Generator
`scripts/tf_terrain.gd` (`TFTerrain`, 60×40), painter `scripts/timefantasy.gd`.
The walker is the Painted Lands one. `tools/check_tf.gd` sweeps maps headless.

## Sheet systems (cells of 16 px)

- **Grass.** Light fill `terrain (2, 1)` (99, 162, 63), the only true base;
  `(3, 1)` is a quiet variation. Other cells in row 1 are not variations
  (they checker). Row 1 runs light to dark: `(9–11, 1)` is the mid forest
  floor, `(7, 1)`, `(8, 1)`, `(12, 1)` the deep one. Deco on light grass `(1–20, 2–3)`. Autumn: gold fill `(1, 4)`
  (183, 157, 50), variations `(2–3, 4)`, deco `(1–12, 5)`.
- **Grounds.** Columns 22–37, one row per ground: rows 2–7 on green grass and
  9–14 on gold (dirt, gravel, sand, packed dirt, paving, pit). Column 22 fill;
  grass on the N/S/W/E side 25/34/27/32; rounded outer corners NW/NE/SW/SE
  29/33/35/36; inner nubs 23/24/26/30; 28 and 31 diagonal crossings (unused);
  37 the grass. A cell whose grass would be on two opposite sides has no tile:
  the path is reshaped (the cell dropped) before autotiling. Paths are two
  wide.
- **Water** (`water.png`). Per shore (grass `(1, 7)`, deep on grass
  `(21, 7)`, sand `(1, 37)`, gold `(1, 19)`, dirt `(1, 25)`): a land sample
  at the origin, inner corners at +(1..2, 0..1), a 3×3 pool at +(0..2, 2..4);
  three frames three columns apart, played 1-2-3-2 (0.28 s). Built into a
  generated atlas so each tile animates.
- **Cliffs.** Brown (x + 0) or grey stone (x + 10): N rim `(1–3, 14)`, west
  side `(1, 16)` (flipped for the east), S rim `(1–3, 17)`, a two-row face
  `(1–3, 18–19)`, stairs four wide `(5–8, 22–24)`, a cave mouth
  `(4, 18–19)`. A plateau top is reached only by its stairs.
- **Houses** (`house.png`). A gable roof seven wide: roof rows 9–11 at
  `ROOF_X` (grey, red, straw, dark, blue, green), a two-row gable end at
  `GABLE_ROW`, a wall band at `WALL_ROW` (plaster, beamed plaster, logs,
  stone, dark stone) with posts in columns 1 and 3, fill 2, door 5, and
  window pairs. Stone walls use only the first two window pairs (the others
  carry snow). Each house is composed into one sprite, y-sorted at its wall
  foot; the lower part blocks.
- **Props** (`outside.png`, `PROPS` in `tf_terrain.gd`: rect, foot, collider,
  tag). Trees by set (green, pines, autumn, blossom, teal, dead), stumps,
  logs, rocks, crystals, clutter, graves, tent, spit, signs, firepits (with
  the `animated/fireplace.png` flames in the pit), braziers
  (`animated/torch.png` column 1, five frames). The bare trees' loose
  knothole piece is erased from their crop (`erase`), and the snow on the
  giant trees' roots is dropped (`unsnow`). On autumn maps, green grass
  painted at a prop's foot is recolored to the gold grass; pines are not
  used there.

**Green grade.** Out of the box the greens are loud beside Painted Lands
(lawn (100, 163, 63), saturation 0.62 against 0.40, and every grass cell a
four-color speckle with a brightness spread of about 32, where Painted Lands
lawn cells are flat). `timefantasy.gd` grades `terrain`, `outside`, `water`,
and `house` once at load (about 0.35 s), greens only (hue 0.19–0.45, fading
over 0.05): hue +0.02, saturation × 0.68, brightness pulled 40 % toward 0.56
(calms the speckle), then × 0.9. The lawn becomes (96, 139, 81). Dirt, roofs,
flowers, gold autumn grass, and water keep their colors; the green season's
blade and wave tips go through the same grade. `grade = false` shows the
sheets as drawn. The pack files are never changed. The squeeze also narrows
the gap between grass tones, so the deep fills (used only by the zones) are
then dimmed × 0.86 (`DEEP_VALUE`): lawn 0.54, mid 0.48, deep 0.39 brightness.

## Pipeline

Recipe (`id % 20`), then: plateaus, ponds (rectangles with bumps), a stream
with a bridge (Riverside), houses, forest-floor zones, paths (A* with a noise cost
so they wind; two wide; layouts cross, road, village plaza, shore, trail, to
the plateau stairs), the set piece, then a spur from the path to it (camp,
graves, giant tree, quarry, crystals), the zones settled, dirt patches, tree
scatter (crowding into the zones),
small scatter and flowers, the liveliness floor, then autotiling. Checks: the
spawn reaches every goal.

**Forest-floor zones** (green season only, like the Painted Lands tone
zones): one noise field, two nested levels. Mid covers the recipe's share
(at least 0.2 when the recipe has zones), deep 0.4 of that, its cut at least
0.1 above mid's so mid keeps a band round it. After the paths and set piece,
the field is pulled down near paths, water, cliffs, and stairs (their tiles
bake the light lawn): no zone within one cell, fading back in over four.
Components under six cells are dropped from the field too. Cells inside a
level take its fills; cells where levels meet are drawn per pixel from the
field (bilinear, wobble, Bayer dither), so no edge follows the grid.

**Dirt patches** (every map, 3–5, `patches` in a recipe overrides): rounded
rectangles 3×3 to 5×3 or two joined with arms at least three thick (the
sheet's diagonal outer corners turn a 2×2 into a diamond), in dirt, or gravel
on gravel-road recipes (packed dirt reads as pale sand). The ground tiles bake
the light lawn, so a patch stays two cells off the zones, three from any path,
four from another patch. They are `paths` cells autotiled with the paths
(`patches` marks them; wayside braziers never stand on them).

Recipes: 0 Meadow, 1 Village green, 2 Hamlet road, 3 Lakeside, 4 Forest
glade, 5 Pine woods, 6 Autumn woods, 7 Cliffside, 8 Terraces, 9 Stone quarry,
10 Campsite, 11 Graveyard, 12 Blossom grove, 13 Crystal hollow, 14 Farmstead,
15 Market square, 16 Riverside, 17 Marsh, 18 Autumn hamlet, 19 Giant tree.

## Liveliness

The Painted Lands ambience through its generic setups: wind, leaves from every
crown (colors from each tree's sprite), wind streaks, cloud shadows (green, or
brown on autumn), grass waves and footstep blades (sunlit tips lighter than
the season's grass), water life on open water, critters (butterflies,
dragonflies, fireflies in the zones), wildlife planned from the finished map,
drifters, fire glow and smoke (firepits, braziers, and chimney smoke from 60 %
of houses). Liveliness floor with the Painted Lands frozen weights: while the
weakest 43×18 window is under 0.09 %, it gets a campfire in a clearing (off
the path) or a pair of braziers facing each other across a path in the
window (both or neither), at most five anchors, each kept only if every goal
still reaches.
