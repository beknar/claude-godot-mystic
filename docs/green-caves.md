# Green Caves

Read this before touching `scripts/cave_terrain.gd`, `scripts/caves.gd`, or
the Green Caves randomizer.

**Never break (the looks):**
- Walls, terraces, pools, and rails only from the sheet's own pieces; a
  terrace top is reached only by its stairs.
- Every pool sits in its stone ring and dark-floor halo; lakes keep deep
  water inset two cells.
- Dark zones are trimmed until every cell has a tile; no bare corners.
- Every camera window reaches the cave liveliness floor (0.2 %).
- Homes: rock toward the cave, Cozy Cottage trim toward the rooms, the
  arched doorway over the way out.

Mazes on this sheet (`maze-greencaves`, `cave_maze.gd`): `docs/maze-greencaves.md`.

**Coordinates:** `cave_terrain.gd` (`PROPS`, the sheet constants) is
authoritative; the cells below explain each piece's role.

Do not apply this section to the Mystic Woods or Painted Lands maps, and do
not use their sheets here. Sheet: `assets/pack/green_caves/green_caves_tileset.png`,
50×19 cells of 16px. Generator `scripts/cave_terrain.gd` (60×40), painter
`scripts/caves.gd`. The walker is the Painted Lands one.

## Sheet systems

- **Floors.** Light `(0–1, 0–1)` (199, 197, 193); dark `(3–4, 0–1)` (162, 160,
  160); mossy `(0–3, 9)`, `(0–1, 10)`. `(2, 0–1)` carry dark splotches: not
  plain floor.
- **Dark zones** on the light floor: the blob on transparent `(0–2, 6–8)`,
  inner corners `(3, 6)` SE open, `(4, 6)` SW, `(3, 7)` NE, `(4, 7)` NW. Noise
  cut at the recipe's share, specks under 10 cells dropped, trimmed until every
  cell has a tile. Small patches baked on light floor: `(0–2, 3–5)`.
- **Wall mass** (solid rock, black top): top 3×3 `(5–7, 11–13)`, two face rows
  `(5–7, 14–15)`; face variants: rim `(10–16, 16)` over faces `(10–16, 17–18)`
  (14–16 mossy), `17` is the skull column (Ossuary only). Doorway `(5–7, 9–10)`
  cut into the back wall's face.
- **Terrace** (raised walkable top): `(5–7, 0–2)` over faces `(5–7, 3–4)`;
  variants rim `(10–16, 5)`, faces `(10–16, 6–7)`. Stairs `(10–12, 8–10)`
  with sides `(9, 8–10)` and `(13, 8–10)` replace the rim and both face rows of
  three columns. The top is entered only by its stairs (lip colliders on the
  other three sides).
- **Pools**: water in a rectangle with a one-cell stone ring. Ring N `(22, 2)`,
  S `(22, 0)`, W `(23, 1)`, E `(21, 1)`; corners NW `(27, 2)`, NE `(26, 2)`,
  SW `(27, 1)`, SE `(26, 1)`. Water edges top `(22, 3)`, left `(24, 1)`, right
  `(20, 1)`, corners TL `(28, 3)`, TR `(25, 3)`, BL `(28, 0)`, BR `(25, 0)`.
  These animate in four frames stacked four rows apart (columns 1, separation
  (0, 3)); open water `(29–32, 7)` in four frames side by side; all in step.
  Lakes have deep water `(30–35, 0–1)` inset two cells. Stalagmites `(30–31,
  4–5)` and weed `(34, 5)` stand in water on the WaterDeco layer over the
  water; sparkles `(29–32, 9)`, `(29–32, 10)` animate on a third of open water.
  The ring is the dark floor's grey, so every pool sits in a rounded dark
  halo (on light and moss floors).
- **Rails**: straight `(16, 8)`, `(15, 9)`; curves ES `(15, 8)`, WS `(17, 8)`,
  EN `(15, 10)`, WN `(17, 10)`. Walkable.
- **Props** (`CaveTerrain.PROPS`, region in px, foot, collider): rocks and ore
  `(33–48, 12–13)`, crystals `(29–31, 14–15)`, cones `(46–48, 5–7)`, plants
  and grass `(41–45, 5–8)`, trees `(36–45, 0–5)` (the signpost baked beside
  the first is erased), rock trees `(35–43, 15–18)`, bushes `(46–49, 0–5)`,
  branches `(36–41, 5–6)`, chests, boards, skulls, ladder, trough, crates,
  barrels, signpost, carts `(18–19, 5–8)`, coal `(18, 9–10)`, pillars
  `(29–33, 16–18)`, campfire `(16–19, 0–1)` and torch `(16–19, 4)` in four
  frames, ash `(15, 1)`.

## Pipeline

spawn near the bottom → back wall (2–3 rows, doorway, face variants) →
terraces with stairs → homes (recipes that have them) → lake, pools → rock islands (4–8 × 3–4) → goal (the
farthest open spot) → rails from spawn to goal (at most two bends) → the
recipe's set piece at the goal → dark zones + halos → floor patches → floor
→ scatter ×1.4 plus 10–16 small floor bits → wall torches in pairs →
liveliness floor → reach check (spawn to goal and to every terrace top; up
to 40 layout attempts).

## Recipes (`recipe = id % 33`)

| # | Name | Floor | Set piece / features |
|---|---|---|---|
| 0 | Grotto | light | cairn, a pool |
| 1 | Crystal cavern | light | crystal ring, crystal rock tree |
| 2 | Flooded hall | light | lake + pools |
| 3 | Mine shaft | dark | mine (carts, coal, crates), rails |
| 4 | Miners' camp | light | campfire camp, a home of 2–3 rooms |
| 5 | Mossy hollow | moss | grove, pools, tufts |
| 6 | Terrace steps | light | two terraces, goal on top |
| 7 | Ossuary | dark | bones, skull faces |
| 8 | Pillared hall | light | colonnade, no islands |
| 9 | Stalagmite field | light | cones everywhere |
| 10 | Underground spring | light | 3–4 pools |
| 11 | Ore vein | dark | ore, rails |
| 12 | Dead grove | light | dead trees, branches |
| 13 | Cave mouth | light | signpost and torches |
| 14 | Smugglers' cache | dark | crates, barrels, chests, a home of 1–2 rooms |
| 15 | Rail junction | light | mine, rails |
| 16 | Twin pools | light | two pools |
| 17 | Crystal shrine | light | pillar gate, crystals, terrace |
| 18 | Dark depths | dark | islands, pools |
| 19 | Collapsed tunnel | light | 4–6 islands, rocks |
| 20 | Overgrown mine | moss | mine, rails, plants |
| 21 | Watch post | light | terrace top with signpost and torch |
| 22 | Root cellar | dark | barrels, trough, rock tree, a home of 2–3 rooms |
| 23 | Echo chamber | light | open hall, large zones |
| 24 | Lake terrace | light | lake + terrace |
| 25 | Coal store | dark | coal, carts, rails |
| 26 | Crossroads cavern | light | signpost and boards |
| 27 | Hermit's nook | moss | camp, a home of 1–2 rooms |
| 28 | Sunken garden | moss | grove, pools |
| 29 | Treasure vault | dark | chests, pillars, violet crystals, terrace |
| 30 | Hermit's home | moss | a home of 1–2 rooms, grove, a pool |
| 31 | Cave hamlet | light | three homes of 1–2 rooms, camp |
| 32 | Underground manor | dark | one home of 5–6 rooms, pillar gate, crystals |

**Homes** (`_home()`): an InteriorPlan (`docs/interiors.md`) built into the cave.
Its wall ring is cave rock toward the cave floor and the Cozy Cottage trim
toward the rooms (wall tops composed per quarter cell, the cottage black
recoloured to the rock's fill), and two rows of cave face under its south
wall carry the arched doorway `(5–7, 9–10)` over the way out (the arch's
middle column walkable). Interior floor is kind `HOME` (walkable; mice live
there). A cave home has no sunbeams; its hearths and lamps glow through
`fire_ambience.gd` ("hearth", "lamp") and it has its own life
(`interior_life.gd`). Homes go before pools and islands, and a map retries its
layout until every home the recipe asks for fits and the entry room is
reachable.

## Ambience and liveliness

`caves.gd` adds wind (a draft), water life (ripples, fish, rings in teal),
footsteps (grey dust on floor, blade flicks on moss and tufts, shore
ripples), fire ambience (torch and campfire glow and smoke; flames at the
cave sprites' height), leaves from mossy trees and bushes, critters
(glowworms over moss, dark floor, and dark zones; moths at flowering plants;
dragonflies over pools), wildlife (mice by clutter and bones, lizards by rocks
and ore, frogs on the banks, voles on moss; with `cozy_animals`, set in the
randomizer, also the Cozy Farm bunnies on moss floors and, on the map types
with homes, chickens, turkeys, and pigs in the yard outside each arch and
sheep, goats, or cows on the moss round it: "Cozy Farm animals" in
`docs/painted-lands.md`), and `scripts/cave_life.gd`:
drips from every face and into open water, warm dust motes in fire light and
pale ones everywhere, crystal and ore glints, and bat flights. No clouds, wind
streaks, drifters, or grass waves underground.

Liveliness floor: every 43×18 window should reach 0.2 % on the frozen
weights in `cave_terrain.gd` (from the rendered cave calibration: pool cells
0.65, sparkles 0.16, campfire 139, torch 30.5, mossy trees 4.17, a home's
hearth 60, a lamp 12); weak windows
get a campfire (with a branch) or a torch pair, up to six. Calibration:
`docs/liveliness-calibration-caves.md` (12 maps filmed, 4 held back). The estimate is `scripts/cave_liveliness_features.gd` with
`tools/liveliness_coef_caves.json` (`tools/liveliness.gd ... caves`).
