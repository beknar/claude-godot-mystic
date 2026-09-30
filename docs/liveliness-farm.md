# Liveliness: the farm randomizer against the other randomizers

`randomizer-paintedlands-farm` (all three seasons), measured 2026-09-30 with
three tests, and set against the Painted Lands, Green Caves, and Pixel
Crawler randomizers:

- **Walker test, headless:** `tools/walker_test.tscn -- farm` walks a route
  through the six camera views of every farm map type (48 maps, 190000-190047,
  288 views, 25 s each) and counts what the scene does back and where the
  walker snags.
- **Slow sampling:** `tools/liveliness_capture.tscn -- farm` (rendered, walker
  hidden, 6 views x 25 s at 8 fps per map) on 12 maps across the seasons,
  measured by `tools/liveliness_analyze.py watch`. Pixel Crawler: the same on
  8 maps (`-- pc`).
- **Slow walker test:** `tools/walker_test.tscn -- farm out=...` rendered on
  the same 12 maps (the walker walking each view, its own sprite masked out),
  measured the same way; Pixel Crawler on its 8.
- **Fast estimate:** `tools/liveliness.gd -- <first> <count> -1 farm` (the
  calibrated proxy's features worked out from the farm, with the Painted
  Lands weights; not refitted, see below).

Motion is the share of pixels changing per frame (%), local (cloud-shadow
rims apart; each pack's own cloud shade is now recorded with the view so the
analyzer can tell them apart). Quiet: blocks (6 x 6 cells) under 0.05 %.

## Fixed on the way

- **Greenhouse in the snow froze the game** when the walker moved: the bare
  winter fruit trees (and the dead trees of the old-farm maps) have no leaf
  colors, and a falling leaf picked from an empty list (a division by zero;
  the debugger then holds the game). Bare and dead trees now shed nothing.
- **The walker snagged** 60 times on 22 of 48 farm maps (first headless run):
  a prop's collider (centered on its cell, 24 px for a trough or a hay crate)
  reached into the next cell, which the generator left open, and tree
  colliders sized from a wide root flare did the same. Props now block every
  cell their collider overlaps and trunk colliders stay in the trunk's cell
  (at most 14 px): the rerun had **0 snags on all 48 maps**, and the 96-map
  check still passes.
- **Winter's liveliness floor** used fireflies, which winter does not draw;
  a weak winter window now gets a small pond (up to two per map) or a stand
  of snowy trees.

## Summary

| Scene | Maps | At rest: local motion (median of maps) | At rest: weakest view (median) | Quiet blocks | Walking: local motion | Walking: weakest view | Walking / rest | Fast estimate (scene / weakest window) |
|---|---|---|---|---|---|---|---|---|
| **Farm** (all seasons) | 12 (walk 12) | **0.40 %** (0.27-0.65) | **0.27 %** | 6 % | **0.51 %** (0.34-0.79) | **0.32 %** | x1.3 | 0.58 % / 0.23 % (48 maps) |
| Farm, spring and summer | 6 | 0.41 % | 0.29 % | | 0.51 % | | | 0.54 % / 0.25 % (30) |
| Farm, autumn | 4 | 0.37 % | 0.24 % | | 0.48 % | | | 0.57 % / 0.24 % (10) |
| Farm, winter | 2 | 0.42 % | 0.28 % | | 0.54 % | | | 0.54 % / 0.12 % (8) |
| Painted Lands, drawn animals (2026-09-28; walking on 13 of the 18 maps) | 18 (walk 13) | 0.49 % (0.32-0.84) | 0.28 % | 0 % | 0.46 % | 0.27 % | x0.9 | |
| Painted Lands, Cozy Farm animals and buildings (2026-09-29) | 18 (walk 13) | 0.59 % (0.32-0.94) | 0.35 % | 0 % | 0.66 % | 0.41 % | x1.1 | |
| Painted Lands randomizer as it is now (Cozy Farm animals, no buildings) | | not refilmed; between the two rows above | | | | | | 0.66 % / 0.36 % (30) |
| Green Caves (calibration capture, 2026-09-27) | 12 | 0.38 % (0.28-0.45) | 0.23 % | 65 % | not filmed | | | 0.41 % / 0.33 % (30) |
| **Pixel Crawler** | 8 (walk 8) | **0.14 %** (0.04-0.20) | **0.11 %** | 6 % | **0.41 %** (0.06-0.79) | **0.19 %** | x2.9 | no proxy |

What it says:

- **The farm sits with the Painted Lands scenes**, a little below the forest
  randomizer at rest (0.40 % against 0.49-0.59 %) and level with it while
  walking (0.51 % against 0.46-0.66 %); its weakest views (0.27 %) match the
  forest's (0.28-0.35 %). It is livelier than the caves at rest (0.38 %), which
  still have two-thirds of their blocks quiet against the farm's 6 %.
- **Winter is as lively as summer** (0.42 % against 0.41 % at rest, 0.54 %
  against 0.51 % walking): the falling snow moves in every view where the
  butterflies, fireflies, grass waves, and drifters of the other seasons are
  gone. Autumn is the quietest farm season (0.37 %).
- **The walker wakes the farm up** (x1.1-1.6 per map, median x1.3): animals
  amble off, dust and snow puffs, blades flick, trees rustle and fade, gates
  swing open.
- **Pixel Crawler is by far the quietest at rest** (0.14 %); its Cemetery and
  Desert maps are almost still (Old cemetery 0.07 %, Red pine hill 0.08 %,
  Bone field 0.04 %, 53-83 % quiet blocks). Walking nearly triples it (x2.9:
  its big crowns fade round the walker, dust, startled animals), but the
  desert stays still (0.06 %). It snagged 11 times on 4 of its 8 maps; its
  liveliness had not been measured before.
- **The fast estimate is only a rough guide for the farm** (Spearman 0.36
  against the measured maps): it uses the Painted Lands weights, has no
  feature for the windmill, the rustling trees, the fish, or the snow, and so
  reads winter far too low (0.12 % weakest window against 0.28 % measured).
  Fitting farm weights would need the capture's per-block features for the
  farm (not written yet).

## Farm, map by map

At rest: the slow capture; walking: the slow walker test (same maps, final
code); fast: the proxy on the same map id.

| Map | Map type | At rest | Weakest view | Quiet blocks | Walking | Walking weakest | Walking / rest | Fast scene | Fast weakest |
|---|---|---|---|---|---|---|---|---|---|
| 190032 | 0 Homestead | 0.43 % | 0.28 % | 0 % | 0.57 % | 0.33 % | x1.3 | 0.60 % | 0.50 % |
| 190035 | 3 Apple orchard | 0.65 % | 0.33 % | 2 % | 0.79 % | 0.50 % | x1.2 | 0.88 % | 0.28 % |
| 190040 | 8 Barnyard | 0.39 % | 0.34 % | 6 % | 0.36 % | 0.31 % | x0.9 | 0.58 % | 0.23 % |
| 190050 | 18 Woodlot | 0.56 % | 0.30 % | 3 % | 0.78 % | 0.51 % | x1.4 | 0.64 % | 0.34 % |
| 190055 | 23 Cattle ranch | 0.28 % | 0.23 % | 12 % | 0.44 % | 0.27 % | x1.6 | 0.41 % | 0.20 % |
| 190061 | 29 Harvest fair | 0.27 % | 0.16 % | 10 % | 0.34 % | 0.15 % | x1.3 | 0.29 % | 0.16 % |
| 190062 | 30 Autumn homestead | 0.37 % | 0.26 % | 5 % | 0.43 % | 0.27 % | x1.2 | 0.70 % | 0.23 % |
| 190065 | 33 Golden wheat | 0.57 % | 0.21 % | 3 % | 0.69 % | 0.32 % | x1.2 | 0.34 % | 0.17 % |
| 190067 | 35 Autumn market | 0.34 % | 0.21 % | 8 % | 0.47 % | 0.31 % | x1.4 | 0.67 % | 0.17 % |
| 190070 | 38 Old barn in autumn | 0.36 % | 0.29 % | 2 % | 0.50 % | 0.32 % | x1.4 | 0.38 % | 0.21 % |
| 190072 | 40 Snowy homestead | 0.41 % | 0.31 % | 18 % | 0.51 % | 0.39 % | x1.3 | 0.46 % | 0.22 % |
| 190076 | 44 Pine hills | 0.43 % | 0.26 % | 13 % | 0.56 % | 0.46 % | x1.3 | 0.46 % | 0.04 % |

The quietest farm map is Harvest fair (0.27 % at rest, its weakest view
0.16 %, hardly livelier walking): the market and three buildings fill the
middle of the map with still props.

## Walker test, every map (headless)

Per map (six views of 25 s, about 11,900 px walked), median over the maps:

| Scene | Maps | Animal reactions | Dust puffs | Grass flicks (lawn and tufts) | Leaves kicked | Insects scattered | Snags |
|---|---|---|---|---|---|---|---|
| Farm (all 48 types, rerun 2026-09-30 after the fixes below) | 48 | 56 | 209 | 704 | 3 | 6 | 0 |
| Painted Lands, Cozy Farm animals (as now) | 30 | 61 | 151 | 737 | 11 | 8 | 0 |
| Painted Lands, drawn animals | 30 | 48 | 118 | 744 | 13 | 8 | 0 |
| Green Caves | 30 | 26 | 1290 | 0 | 0 | 1 | 0 |

Every farm map finished without a script error; Greenhouse in the snow
(190030) walked cleanly after the fix.

**Reactions counted once:** a penned animal at its fence with nowhere to
amble to used to be "scared" again every frame the walker stood near (up to
3,225 counts for one kind on one map, and no visible reaction). An animal
that finds no way off now stays put and looks again a second later, and only
a real reaction is counted (wildlife.gd, every scene); the farm row is the
rerun with it (at most 25 reactions of one kind in one view). The Painted
Lands and Green Caves rows are from before this change; with no pens their
counts were not affected much.

**Also changed since the measurements:** the walker now wades through the
crops (they bend and spring back), trees rustle one by one as a gust sweeps
across the farm, and the barn opens on a barn of its own (docs/farm.md). The
walker's test routes keep off the fields, so the measured numbers stand.

## Running them again

```
godot --headless --fixed-fps 60 --path . res://tools/walker_test.tscn -- farm [map ids]
godot --path . res://tools/liveliness_capture.tscn -- farm        # with python3 tools/liveliness_analyze.py watch .liveliness_farm
godot --path . res://tools/walker_test.tscn -- farm out=<dir>      # with ... watch <dir>
godot --headless -s res://tools/liveliness.gd -- 190000 48 -1 farm
python3 tools/liveliness_analyze.py compare .liveliness_farm,<dir>,...
```

`pc` in place of `farm` runs the Pixel Crawler randomizer. The rendered runs
need the game window visible for their whole length (about 3 minutes a map);
one farm capture stopped silently at map 5 and was resumed from there.
