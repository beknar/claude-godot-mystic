# claude-godot-mystic

A top-down pixel-art action RPG prototype in Godot 4.6 (GL Compatibility).
Maps are assembled on a 16px grid from two hand-painted tile packs and a
seeded procedural generator. They are never painted as one backdrop.

`AGENTS.md` holds the binding rules. `docs/scene-assembly.md` holds the
shared inventory, composition steps, and QC checklist. This README gives an
overview; when the two disagree, `AGENTS.md` wins.

> **Status:** built so far: `scenes/clearing/clearing.tscn` (the main scene),
> `scenes/grove/grove.tscn`, `scenes/forest/forest.tscn`,
> `scenes/wilds/wilds.tscn`, `scenes/randomizer-paintedlands/randomizer-paintedlands.tscn`,
> `scenes/randomizer-mysticwoods/randomizer-mysticwoods.tscn`, the
> player and walker scenes, the Mystic Woods and Painted Lands generators,
> both art packs, the AI character sheets, and `addons/godot_mcp`. Hollow,
> ford, and heath are not built yet. The Painted Lands generator draws all
> 30 recipes.

## Running

Open the folder in Godot 4.6 and press F5, or run:

```
Godot_v4.6.1-stable_win64.exe --path E:\code\claude-godot-mystic
```

Display: window 3440×1440, camera zoom 5, nearest filtering. Each 16px tile
is 80 screen pixels.

## Two map languages

Each map belongs to one pack. Don't mix pipelines, sheets, or "done" checks
between them.

| Maps | Pack | Sheets (`assets/pack/`) | Generator |
|---|---|---|---|
| clearing, grove, hollow, ford, heath | Mystic Woods | `plains.png`, `grass.png` | `scripts/terrain.gd` + `scripts/clearing.gd` |
| forest, wilds | Painted Lands | `TILESET_brighter.png` | `scripts/forest_terrain.gd` |

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
| `scenes/randomizer-paintedlands/randomizer-paintedlands.tscn` | starts at 75125, then any | `character_sprite_sheet.png` |
| `scenes/randomizer-mysticwoods/randomizer-mysticwoods.tscn` | starts at 21021, then any | `player.png` |

The Painted Lands randomizer runs the Painted Lands generator with the wilds
settings; the Mystic Woods randomizer runs the Mystic Woods generator the
same way, with its own 13 recipes (clearing, pond glade, lake island,
farmstead, stone ruins, cottage garden, graveyard, cobble crossroads, rocky
highland, orchard, woodcutter's glade, campsite, mushroom hollow) in the
recipe picker. `tools/check_mystic.gd` sweeps them headless.
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
walker comes near. `tools/check_wildlife.gd` (same arguments as
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

`recipe = seed % 30` selects one of 30 recipes (Pastoral, Crossroads,
Pond walk, …, Switchback, then Cave mouth, Terraces, Stone ruins, Woodcutter
camp, Rock garden, Deep forest, Village square, Hedge garden, Ridgeline,
Walled mesa). The forest and wilds scenes pin recipes 3 and 5. The
recipe sets houses (0, 1, 2 on recipes 10 and 23, 3 on 26
only), water, fences, gates, plateau, path shape, dirt-patch blobs, and
props. The full table is in `AGENTS.md`.

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

Where the sheet differs from the `AGENTS.md` atlas notes, the code follows
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

## Editor automation

The project is driven from Claude Code through the Godot MCP server
(`@satelliteoflove/godot-mcp`). It talks to the `addons/godot_mcp` editor
plugin over WebSocket port 6550.
