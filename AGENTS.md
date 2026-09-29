# AGENTS.md

Godot 4.6 (GL Compatibility) top-down pixel-art prototype. Maps are generated
from purchased 16 px tile packs by seeded generators and painted as tilemap
layers. This file holds the rules for every session; each pack's full
drawing rules live in its own doc (index below). Read that doc before
changing its generator, painter, or scenes.

## Official asset packs

- The only official packs are **The Painted Lands** (antarcticbees: Forest,
  Green Caves, Cozy Cottage, and the rest) and **Pixel Crawler** (Anokolisa).
- They are used in **separate maps** and never combined, on the ground, in
  props, or in palettes.
- **Cozy Farm** (shubibubi) is used for its **animals only**, in
  `randomizer-painted-cozyfarm` (by request): they replace the drawn animals
  that have a pack counterpart. Its other art is not used.
- **Mana Seed** is not to be used in future development. **Mystic Woods** is
  deprecated. **Time Fantasy** is not suitable (its ground clashes and
  strains the eyes). Their scenes and docs stay as a record only.

## Pack index (read the doc first)

| Pack | Scenes | Code | Doc |
|---|---|---|---|
| Painted Lands, Forest | `forest`, `wilds`, `randomizer-paintedlands`, `randomizer-painted-cozyfarm` | `forest_terrain.gd`, `forest.gd` | `docs/painted-lands.md` |
| Painted Lands, Green Caves | `randomizer-greencaves` | `cave_terrain.gd`, `caves.gd`, `cave_life.gd` | `docs/green-caves.md` |
| Painted Lands, Cozy Cottage | homes in both randomizers above | `interior_*.gd`, `house_interiors.gd` | `docs/interiors.md` |
| Pixel Crawler | `randomizer-pixelcrawler` | `pc_terrain.gd`, `pixelcrawler.gd`, `pc_tiles.gd` | `docs/pixel-crawler.md` |
| Mystic Woods (deprecated) | `clearing`, `grove`, `hollow`, `ford`, `heath`, `randomizer-mysticwoods` | `terrain.gd`, `clearing.gd` | `docs/deprecated/mystic-woods.md` |
| Mana Seed (not to be used) | `randomizer-manaseed` | `ms_*.gd`, `manaseed.gd` | `docs/deprecated/mana-seed.md` |
| Time Fantasy (not suitable) | `randomizer-timefantasy` | `tf_terrain.gd`, `timefantasy.gd` | `docs/deprecated/time-fantasy.md` |

Engine, player, scene list, and art directories: `docs/project-overview.md`.
Combining antarcticbees packs: `docs/painted-lands-art-fit.md`. Shared
inventory and QC: `docs/scene-assembly.md`.

## Hard rules (every map)

1. Read the pack for *this* scene first: tile size, grid, palette, layers.
2. All world art snaps to the pack's 16 px grid. No free-placed backdrops.
3. The playing field is tilemap layers: ground, transitions, props and deco,
   collision, then actors and UI in code (never baked into tiles).
4. Match the pack: pixel density, outline weight, lighting, saturation.
5. Generate new pixels only where the pack lacks a terrain or transition,
   at exact cell size, checked in a 3 x 3 composite, in the pack's colors.
6. Collision comes from terrain kinds, layers, or measured sprite parts,
   never from guessing opaque pixels on a background.
7. Characters and UI stay separate sprites.

## What makes a map look good (all packs)

- Terrains blend only through the pack's own transition tiles (autotiles,
  corner tables). A cell with no drawable tile is repaired, never left.
- No straight or stair-step edges on zones, patches, or water; no raw
  colored squares; rims are organic and dithered.
- No wall of one repeating fill across the view: vary light and dark
  ground (tone zones, splat, pack shadows, deco by tone).
- Paths wind; set pieces, props, and trees cluster like the pack's own
  sample maps or mockups; nothing tall hides a cliff face.
- The walker stays visible: crowns fade when it is behind them; trunks and
  large props block where they are drawn.
- Every camera-sized window (43 x 18 cells) has something moving; the
  liveliness floor adds anchors where it is weak.
- Saturated greens that glare are graded down (the lesson of Time Fantasy
  and the Farm forest).

## Done means

- The pack's headless check passes on a sweep of maps (`tools/check_tf.gd`,
  `check_caves.gd`, `check_recipes.gd`, `check_pc.gd`, ...): the walker
  reaches every goal and every cell has a tile.
- A screenshot in the running game, looked at next to the pack's own art,
  passes that doc's reject list.

## Working rules

- Purchased packs never go in git: `assets/pack/` is ignored; each new pack
  goes under `assets/pack/<name>/` and gets a credit in `README.md`.
- `assets/ai/` holds generated sheets (`assets/ai/README.md`); never put a
  generated sheet in `assets/pack/`.
- Before a commit, check `head -1 scripts/forest.gd` is `extends Node2D`.
- Commit or push only when asked.
- The editor is driven through the Godot MCP addon (`addons/godot_mcp`);
  after adding a script with a new `class_name`, rescan the editor before
  running headless tools.
- Keep this file short: pack-specific rules go in that pack's doc.
