# Painted Lands (Forest)

Read this before touching `scripts/forest_terrain.gd`, `scripts/forest.gd`,
or any Painted Lands forest scene.

**Never break (the looks):**
- Blend only through the sheet's own autotiles (path tube, patch blobs,
  tone zones, shores); never stamp a raw fill or a lone baked-grass cell,
  never leave a straight or stair-step edge on a zone, patch, or pond.
- Zones fade away from paths and plateaus; a darker tone never touches the
  lawn directly; islands in a zone use the dirt set baked on that tone.
- Houses: only the counts and prefabs the recipe names; never mix tiles
  from two prefabs.
- Cozy Farm buildings only in the cozy farm randomizer, and never on the
  same map as a Painted Lands house.
- Every recipe flag that is set must place its props (bushes, rocks,
  signs, fires); a crate is never a sign.
- Every camera window reaches the liveliness floor.
- Run the reject list at the end of this file on every screenshot.

**Coordinates:** where `forest_terrain.gd` holds a table, the code is
authoritative; the cells below explain each piece's role.

Do not apply this section to clearing, grove, hollow, ford, or heath.
Do not call `terrain.gd` from forest.

Sheet: `assets/pack/TILESET_brighter.png`, 16×16 cells.
Code: `scripts/forest_terrain.gd`.

## How to use these notes

Two jobs, one sheet:

1. **How each system draws** — cobble path table, patch islands,
   water shores, four house prefabs, y-sort. Methods never change.
   Do not invent pixels or swap in Mystic Woods dirt from `plains.png`.
2. **Where systems go** — the recipe generator (33 recipes). A new seed changes
   recipe, house prefab, path graph, dirt *islands* (not just roads),
   bushes, rocks, signs, and fires.

A screenshot that only has cobble roads + one porch cottage + flowers
has failed the variety rules, even if the road autotile is perfect.

The 3×3 block at atlas columns 35–37, rows 0–2 (inner corners
`(35–36, 3–4)`) is the **water autotile source on the sheet**, not the
size of the lake in the world. The sheet repeats it at columns 38, 41, and
44 with the shore a little wider each time; those are four animation
frames (tile animation, separation 2 columns, 0.35 s each).

Quadrant labels describe how to *pick* a 16×16 atlas cell. Never slice
that cell into four world tiles. Never split a cell to fake a 45° road.

## Dirt: two families (do not collapse them)

**PATH** — diamond cobble tube. Atlas `(21–23, *)` only. Walkable road.

**PATCH** — dirt *islands* on grass. Not a road. Not cobble. Not a
single square of fill. Walkable.

Square stubs on the lawn (a known failure) come from a PATCH cell that
was a raw fill (or one 8×8 quadrant) with no neighbor tiles to supply
the grass corners. A visible patch is a **mini-blob + autotile**, the
same idea as a pond.

### Patch blob (shape)

1. Pick a seed cell on lawn, ≥3 tiles from any cobble PATH cell and
   ≥2 from house / water / fence.
2. Grow a 4-connected blob of 3–8 cells (irregular recipes: CA or
   drunkard, then drop 1-cell diagonals). Round recipes: a 2×2, a
   3×2, or a plus. Never a lone 1×1 fill. Never a 1×N strip.
   Never a 2-cell L (one cell south of one end). A 2-cell patch must
   be a straight 2×1 with cap tiles on both ends.
3. If the blob is still one cell after grow, replace that cell with a
   **standalone rounded island** tile (dirt-on-grass cap with grass
   on three or four sides from the PATCH atlas). Do not leave a square.
4. Min 4 tiles between two blobs.

### Patch autotile (paint)

Use the **dirt-on-grass family**, not cobble and not a subdivided
quarter sitting alone:

```
PATCH atlas (same roles as PATH, different cells)
Set A, transparent grass        Set B, baked mid-green grass
NW (30,0) N (31,0) NE (32,0)    NW (24,0) N (25,0) NE (26,0)
 W (30,1) F (31,1)  E (32,1)     W (24,1) F (25,1)  E (26,1)
SW (30,2) S (31,2) SE (32,2)    SW (24,2) S (25,2) SE (26,2)
```

Set A has no baked grass: the lawn under the cell shows through, which
is Mode A below. Set B keeps its mid green (`(83, 131, 79)`, the same
as lawn cell `(4, 0)`) and is only used with the Mode B halo. Pick one
set per blob. `(27–29, 0–2)` is the same dirt on dark green.

`(18–20, 0–2)` is **not dirt**. It is darker grass on mid green, the
accent-grass family below. Never use it as a PATCH.

Inner corners (fully surrounded cell, one open diagonal):

| Open diagonal | Set A | Set B |
|---|---|---|
| SE | `(31,3)` | `(24,3)` |
| SW | `(32,3)` | `(26,3)` |
| NE | `(31,4)` | `(24,5)` |
| NW | `(32,4)` | `(26,5)` |

Rows 6–8 of each set (`(21–32, 6–8)`) are ragged sparse-dirt versions of
the same 3×3 layout, with inner corners in rows 9–10 (`(22–23, 9–10)`,
`(25–26, 9–10)`, `(28–29, 9–10)`, `(31–32, 9–10)`). Irregular blobs use the
ragged set of the same mode (transparent or the lawn-baked `(21–23, 6–8)`
on lawn, mid or dark baked inside a zone); round blobs use the smooth sets. The dirt sets have no standalone one-cell island
and no three-sided cap, so a round blob is a rounded rectangle (2×2,
3×2, 2×3, 4×2, 2×4) and an irregular blob is two rectangles joined with
arms at least two cells thick.

Neighbor bits N=1 E=2 S=4 W=8 on the blob mask:

- 15 → F `(31,1)` or `(25,1)`, or an inner corner when a diagonal is open
- one grass side → matching EDGE
- two adjacent grass sides → OUTER corner (NW/NE/SW/SE)
- three grass sides, or two opposite sides → no tile exists; reshape
  the blob
- a cell with no painted blob neighbor is illegal; delete it

Do not place F on the outline. Do not place an EDGE without its
opposite-side partner when the blob is two cells tall or wide.
Do not use PATH `(22,1)` or a lone 8×8 quadrant as the patch.

Reject a square dirt tooth on the lawn.

### Patch grass (the dark-green rectangle)

PATCH atlas cells bake their *own* grass into the tile. That grass is
a different green from FLAT_GRASS, so a raw stamp draws a dark square
behind the dirt. Never leave that AABB visible.

After the blob is autotiled, pick **one paint mode per blob**
(`(seed + blob_i) % 2`):

**Mode A — match the lawn (default half).**  
Keep beige / dirt / brown pixels. Replace every baked-grass pixel in
the PATCH cells with the FLAT_GRASS pixel already on that world cell
(same speckle variant). Equivalent: blit dirt with grass treated as
transparent. The dirt outline stays rounded; the lawn color is
continuous. No second green.

**Mode B — accent grass, organic halo.**  
Keep the baked darker green, but it may only exist inside an organic
halo, never as the tile rectangle.

1. Dirt mask = beige/brown pixels of the autotiled blob.
2. Halo = that mask dilated 2–4 pixels with a 1-octave noise wobble
   so the halo edge is lumpy, not a circle or a box. Then AND with
   the 16px cells the blob occupies plus at most one neighbor ring.
3. Darker grass is painted only on `halo minus dirt`. Outside the
   halo, FLAT_GRASS stays.
4. Soften the halo rim with the lawn speckle (copy 30–50% of rim
   pixels from the destination FLAT_GRASS). No straight 16px edge of
   dark green against light green.

A 2×2 of PATCH tiles whose dark grass meets in a larger rectangle is
a Mode B failure — run the halo mask or fall back to Mode A.

An L of two dirt cells with square meeting corners is a blob failure.
Grow the third cell of the L or drop one cell, then autotile OUTER
corners. Two touching mounds that are not a 4-connected blob with
edge/corner tiles must be rebuilt.

Reject a dark-green square or rectangle under a dirt mound.
Reject an L-shaped or stair-shaped dirt cluster with square corners.

### Accent grass patches (no dirt)

A lone darker-green tile on the lawn is the same AABB bug without dirt.

If the recipe wants worn / darker grass as its own feature:

1. Never stamp one atlas cell of dark grass and leave its 16×16 edge.
2. Grow a 4-connected grass-accent blob of 3–8 cells, *or* a single
   cell that is then painted with Mode A or Mode B below — never a
   raw square.
3. **Mode A:** recolor every pixel of that tile to the destination
   FLAT_GRASS (the accent disappears; do not place the tile).
4. **Mode B:** keep the darker green only inside a noisy halo:
   start from the intended accent shape (not the tile rectangle),
   wobble the rim 2–4 px, mix 30–50% rim pixels with lawn speckle.
   Outside the halo, FLAT_GRASS stays.

A 1×1 dark-green square with a hard edge is always a reject, whether
or not dirt sits on it. Prefer Mode A unless the recipe explicitly
wants accent grass.

### Grass tone zones (every map)

Large zones of darker grass, three nested levels, painted between the
lawn and the features:

| Level | Blob on transparent | Hole ring (inner corners) | Fill (plain, speckles) |
|---|---|---|---|
| mid | `(12–14, 6–8)` | `(12–14, 9–11)` | `(4, 0)`, `(5–7, 0)` |
| dark | `(15–17, 6–8)` | `(15–17, 9–11)` | `(8, 1)`, `(9–11, 1)` |
| deep | `(18–20, 6–8)` | `(18–20, 9–11)` | `(8, 0)`, `(9–11, 0)` |

The rows 0–5 versions of these blobs bake the lighter tone into the cell;
use the transparent ones.

1. A smooth tone field (3-octave value noise, sampled rotated so its
   lattice is off the tile grid) lives on every cell corner.
2. Corners within one cell of the path or the plateau are 0 and the field
   fades back in over about four cells, so zones bend away from the path
   and never touch its baked lawn.
3. Each level covers a fixed share of the map (about 25 %, 11 %, 6 %),
   using a quantile cut on the same field, so deeper levels always sit
   inside lighter ones. Specks smaller than a few cells are dropped.
4. Cells fully inside a level are fill tiles (random plain/speckle, random
   mirror). Cells the contour crosses are drawn per pixel from that same
   fill wherever field + pixel-scale wobble + dither is above the cut. The
   rim is organic and dithered; no edge follows a 16 px line.

Reject a tone zone with a straight edge, a stair-step outline, a darker
level touching the lawn directly, or any tone pixel on a path cell.

Cut gaps: the dark cut is at least 0.12 above the mid cut and the deep cut
at least 0.11 above the dark cut, so each lighter tone keeps a band wide
enough to stand on its own around the darker one.

**Dirt islands inside a zone.** When an island's cells are at least 95 %
one tone (at most 5 % of the next darker) and its one-cell ring at least
85 % (at most 15 %), it uses the dirt set whose baked grass *is* that
tone, as plain tiles with no halo: Mode M, set B `(24–26, 0–5)` on mid;
Mode D, `(27–29, 0–2)` with inner corners `(27, 3)`, `(29, 3)`, `(27, 5)`,
`(29, 5)` on dark. Half the island placement tries start inside a zone.
On plain lawn, Mode A or B as above.

**Grass accents.** Small blobs of the next darker tone from the baked sets
`(12–20, 0–2)`, with the hole rings `(12–20, 3–5)` for inner corners and
for ring-shaped accents (a 5×5 whose center 3×3 is the ring). An accent
goes only where the ground under it and its ring is exactly the tone
baked into the cell: mid on plain lawn, dark on pure mid, deep on pure
dark. Two to four per map (more on Hedge garden). Lawn cells sometimes
use `(0, 17)` (lawn with a tuft), and mid and dark fills sometimes
`(11, 15)` and `(11, 21)`.

**Deco by tone.** On lawn and mid: sprouts `(5–7, 1–3)`, `(6–7, 5)` and
flowers `(8–10, 2–7)`. On dark and deep: mostly the darkest sprouts
`(5–7, 4)`, `(5, 5)`. Flower carpets `(5–7, 6–8)`: one to three per map on
plain lawn, either the whole 3×3 or its four corner cells as a 2×2, at
least six cells apart.

### Hedgerows

Dark hedge `(0–2, 1–3)` (inner corners `(3–4, 1–2)`) and light hedge
`(0–2, 5–7)` (inner corners `(3–4, 5–6)`), autotiled as rows two cells
thick, 5–10 long, sometimes an L. On recipes with bushes or a fence yard,
one to three rows. The dark hedge goes only on plain lawn; the light hedge
only where the row and its ring are at least 90 % dark tone. Hedges block;
a row that would cut the spawn off from any goal is not placed. Never a
lone 3×3 hedge square.

## Dirt path atlas (cobble PATH only)

Classify a sand *path* cell by its four 8×8 quadrants, written
NW NE / SW SE. G = grass in that quadrant of the atlas cell. D = dirt.

| Role | Quadrants | Atlas cell | Use |
|---|---|---|---|
| Fill | DD/DD | `(22, 1)` | Interior only. A 2-wide tube has no fill cell. |
| North edge | GG/DD | `(22, 0)` | Grass on the north. |
| South edge | DD/GG | `(22, 2)` | Grass on the south. |
| West edge | GD/GD | `(21, 1)` | Grass on the west. |
| East edge | DG/DG | `(23, 1)` | Grass on the east. |
| NW cap | GG/GD | `(21, 0)` | North cell of a west end. |
| NE cap | GG/DG | `(23, 0)` | North cell of an east end. |
| SW corner | GD/GG | `(21, 2)` | South cell of a west end. |
| SE corner | DG/GG | `(23, 2)` | South cell of an east end. |
| Inner NW | GD/DD | `(23, 5)` | Inside crotch. |
| Inner NE | DG/DD | `(21, 5)` | Inside crotch. |
| Inner SW | DD/GD | `(23, 3)` | Inside crotch. |
| Inner SE | DD/DG | `(21, 3)` | Inside crotch. |

Neighbor bits: N=1, E=2, S=4, W=8. Fill is mask 15 only.

## Dirt path — rounded ends, 90°, approx 45°

4-connected only. No 1-tile jog. No 45° fill line. No sliced cells.

Widen to 2 when a run is ≥4. Both rows of a tube end in the same
column. Autotile, then force end columns:

```
West: (21, 0) over (21, 2)
East: (23, 0) over (23, 2)
```

90° = 2×2 knuckle (outer cap + inner bite + edges). Never a 2×2 of
fill. Force after autotile.

Approx 45° = two knuckles + riser of 2–4 tiles. At most two leans
per map. Example east-north-east:

```
Lower: inner (23,5) / east (23,1)
       south (22,2) / outer (23,2)
Upper: outer (21,0) / north (22,0)
       west  (21,1) / inner (21,3)
```

## Houses (0 or 1, unless the recipe names more)

Default is **zero or one** house per map. Two only on recipes 10 (West
hamlet), 23 (Woodcutter camp), 31 (Twin cottages), and 32 (Manor green),
three only on 26 (Village square) and 30 (Cottage row); those recipes name
every prefab. In the randomizer every house has a door into an interior
(`docs/interiors.md`).

The sheet has four complete buildings. Never mix tiles from two
prefabs. Regions are in sheet cells; the doorstep is the cell the path
ends on, relative to the region's top-left. When the recipe has exactly one house,
`house_id = (seed // 20) % 4` unless the recipe names an id.

| id | Name | What it is | Region | Roof rows | Doorstep |
|---|---|---|---|---|---|
| 0 | Porch cottage | Large purple-roof house with wooden deck | `(38–45, 10–14)` | 2 | `(3, 5)` |
| 1 | Flower cottage | White walls, flowering vine on the wall | `(38–45, 15–19)` | 2 | `(2, 4)` |
| 2 | Gable cottage | Tall pointed roof, large windows | `(38–45, 25–29)` | 2 | `(2, 4)` |
| 3 | Hut | Small wood hut with door and deck | `(46–48, 9–12)` | 2 | `(1, 4)` |
| 4 | Shed | The hut kit's second wall, no deck | `(46–48, 13–15)` | 1 | `(1, 3)` |
| 5 | Barn | The doorless copy of the porch cottage, with the loose door `(46, 25)`, windows `(47, 24–25)`, `(47, 26)`, and door `(46, 26)` hung on its walls | `(38–45, 20–24)` | 2 | `(2, 5)` |

Houses 0–2 end two pixels into column 45; the hut-kit deck starts at
x 728 in row 19, so clip region widths to 115 px. The shed and barn are
outbuildings; only recipes that name them (23) place them.

Split every placed prefab:

- `HOUSE_BODY` — walls, door, porch. Collision. Sort Y = doorstep.
- `HOUSE_ROOF` — gables + overhang. No collision. Sort Y = eave.

Recipes with `Houses = 0` place none. Recipes with `Houses = 2` place
two prefabs (different ids, ≥8 tiles apart, each with body/roof).

## Props that must appear when the recipe asks

All of these exist on `TILESET_brighter.png`. If a recipe flag is set
and none are placed, the seed has failed. Do not substitute flowers
for these.

**Bushes** — round bushes `(21–22, 22–23)` and `(23–24, 22–23)` (dense,
may block `world`); small bushes `(21–22, 24)` and `(23–24, 24)`,
holey shrub `(47–48, 20–21)`, flowering shrub `(46–48, 22–23)` (loose,
deco). Place on lawn. The square hedge `(0–2, 1–3)` reads as a
dark-green lawn rectangle; do not place it.

**Land rocks** — stones whose *bottom pixels are grass*, in the crate /
rock pile cluster: `(25–26, 23–24)`, `(25–26, 25)`, `(25–26, 26–27)`,
`(23, 25)`, `(24, 25)`, `(23, 26)`, `(24, 26)`, `(23–24, 27)`. Lawn only.
The big rocks — `(25–26, 23–24)`, `(25–26, 25)`, `(25–26, 26–27)`,
`(23–24, 27)` — always block (`world`). The four 1-cell pebbles never
block. "LR obstacles" adds extra big rocks two to four cells off the path,
so they stand in the way without closing it.

**Water plants** — reeds / cattails / water grass beside the water
autotile block. Only on WATER_SHORE or the first water ring.

**Water rocks** — stones whose *bottom pixels are water*, in the same
water-prop cluster (including the rock/creature sitting in water).
Only on water or shore. Never on lawn.

**Campfire** — the fire strip at the bottom of the prop cluster,
`(29–32, 29)` (four frames; use frame 0 as the tile, animate if the scene
already supports it). Y-sorted actor. Collision. At most one from the
recipe; the liveliness floor may add more (below).

**Torches** — the standing torches `(35, 26–27)`, `(36, 26–27)`,
`(37, 26–27)`, each one cell wide and two tall. Each has a thin post collider
(4 × 5 px) at its foot and sorts at its foot, so a character north of it
walks behind the flame. Place
on fence posts, gate sides, or the house approach, or (liveliness floor)
as a pair of wayside lanterns facing each other across the path. No collision
required.

**Trees** — `(29–32, 11–15)` and `(33–37, 11–16)`, and their flowering
versions seven rows down. Each can take the grass tuft the sheet draws in
the row under its trunk (region one row taller). That row starts a second trunk
base under the tree's own root flare, so the grassy-base variants (and the
shade trees, whose shade row does the same) are spliced: the flare rows are
dropped and the tree above is drawn that many pixels lower onto the base
(`splice` in `PROPS`), so one trunk runs into the grass. Never `(25–28, 11–15)`
or `(25–28, 18–22)`: both carry a stray foliage band in the base row.

**Clutter** — every map: one to three fallen logs `(21–22, 25)`,
`(21–22, 26)` on the lawn. Every house: two crates or chests just outside
its buffer — crates `(21, 27)`, `(22, 27)`, stacks `(22–23, 28–29)`,
`(24–25, 28–29)`, chests `(26–27, 28–29)`. All clutter blocks. A crate is
never a sign.

**Signs** — ten distinct sign / notice / post tiles in the crate and
fence cluster: `(27, 23–27)` and `(28, 23–27)`. Enumerate them in
`forest_terrain.gd` as `SIGN[0..9]`.
A recipe that lists signs must pick 1–3 different ids from those ten,
never the same id three times, never a crate standing in for a sign.

**More props** — torch variants `(36, 26–27)`, `(37, 26–27)`; a third
crate stack `(20–21, 28–29)`; tall grass `(20, 27)` near doors; a
flowerpot `(46, 20–21)` beside cottage and hut doorsteps; the plank deck
`(46–48, 19)` at the shed door; a second water-grass clump `(47–48, 7–8)`.
Both campfires are two rows tall (flames reach row 28).

**Canopy wall** (recipe 25) — the seamless 4×4 canopy blocks
`(21–24, 11–14)` (plain) or `(21–24, 18–21)` (blossom) fill the top four
rows and block; trees with grassy bases stand three to four cells apart in
front so their crowns cover the canopy's straight lower edge.

**Shade trees** — `(25–28, 11–15)` and `(25–28, 18–22)` carry dark ground
shade in their base row; they grow only on the darkest grass, where the
shade matches the ground.

**Camp props** — big campfire `(34–37, 28–29)` (four frames) with ash
`(28, 29)` beside it, burning between a camp's buildings.

**Rock outcrops** — a small raised top on a short face, one per tone:
light `(9–10, 12–17)`, mid `(18–19, 12–15)`, dark `(18–19, 18–21)`, stone
`(18–19, 24–27)`. Each takes the tone of the ground under it (all stone
on Stone ruins). They block; one that would cut off a goal is not placed.

**Vines** — flowering `(5, 18–19)`, leafy `(6, 18–19)`, and a hanging
column `(34, 25–27)`, one to three per plateau face, clear of the cuts.

**Fence with grass** — rails `(32–33, 25)`, `(32–33, 27)` and post
`(32, 26)` are the plain pieces with grass at the foot; about a third of
rails and posts use them.

## Pond, fences, cliffs

Pond: compact blob from moisture. Fill only where water is surrounded.
The first pond on a map is a lake 60 % of the time (always on recipe 12):
an 8–11 × 7–9 rectangle with two or three bumps straddling its edges. Its
center, inset two cells, is deep water from `(36–38, 6–8)` (the shallow
part of that set is the pond fill), with two or three animated sparkles
`(47–50, 2)`, `(47–50, 3)` on the deep cells. A second deep pool goes in
a bump when a 3×3 or larger rectangle fits two cells from the shore and
two from the first pool. Open water scrolls: full shallow cells use
`(47–50, 0)` and half the deep interior `(47–50, 1)` (four frames, random
start); the other half uses the seamless deep fills `(40–43, 5–8)`. Open
water right beside a deep pool uses the still shallow frame the sheet
draws around the deep set (`(35–39, 5–9)` minus the deep 3×3).
Shore on every water–lawn edge. Then water plants / water rocks per
recipe. No 1-tile canals. World size is the blob, not 5×3.

Fences: 4-connected rails, real corners, min run 3. Plain-rail variants
`(29, 25)`, `(29–30, 27)`, a second east end `(31, 27)` and post
`(31, 26)`, and the shorter back rails `(29–30, 24)` on a yard's north
row. Rail `(30, 25)`,
east end with post `(31, 25)`, post `(29, 26)`; west ends and west posts
are the same cells flipped horizontally. Torches may sit
on posts. Signs may sit next to a gate, not on the rail tile.

Cliffs: only recipes 4 and 16. Blob ≥4 tiles both axes. Cap
`(4–6, 12–14)` + three-row south face `(4–6, 15–17)` + corners. Else omit.
Cut a three-wide stair into the face: `(1–3, 24)`, `(1–3, 25)`, then
`(2, 26)` across all three. The path reaches the stair foot (recipe 16
adds a spur). The plateau top interior and the rim cells over the stairs
are walkable; the rest of the rim and the face block.

Plateau trees: every light, mid, or dark plateau top gets one tree (two on
a top at least 14 wide), a plain crown `tree_a`, `tree_b`, `bloom_a`, or
`bloom_b` (the grassy-base variants bake lawn green), trunk on an interior
row, the landing above the stairs or ramp kept open. A tree that would cut
the spawn off from a goal is not placed. Stone tops get none.

The cliff kit comes in four tones — light, mid, dark, stone — each with a
3×3 top and a 4×4 ramp (a two-wide gap through the face with shaded
rock sides, rim row first):

| Tone | Top | Ramp |
|---|---|---|
| light | `(4–6, 12–14)` | `(0–3, 12–15)` |
| mid | `(15–17, 12–14)` | `(11–14, 12–15)` |
| dark | `(15–17, 18–20)` | `(11–14, 18–21)` |
| stone | `(15–17, 24–26)` | `(11–14, 24–27)` |

Only the light set has rock-with-grass for the ramp's bottom side cells;
every ramp uses `(0, 15)` and `(3, 15)` there. Ramps go only on light and
stone tops: a mid or dark ramp would carry its green straight into the
light lawn at the foot, so those tops use stairs. A cave mouth
`(7–9, 18–20)` can be cut into the face instead (three wide; the bottom
middle is the walkable entrance). About a fifth of plain face columns are
the vine-covered face `(0–1, 18–20)`.

More of the kit: each plateau picks one of two rock faces, `(4–6, 15–17)`
or `(2–4, 18–20)`, with plain rock `(2–3, 16)` for some middle cells; the
south rim of light, mid, and dark tops uses the six rim variants in rows
23, 22, and 21 (columns 0–5); stairs are flanked by the shaded rock
`(0, 24–26)` and `(4, 24–26)`; a one-wide stair `(5, 24)`, `(5, 25)`,
`(2, 26)` serves some mid and dark tops; stone tops sprinkle in
`(11, 27)`.

**Rock ridges.** `(7–8, 12–17)`, `(14–17, 15–17)`, `(14–17, 21–23)`,
`(14–17, 27–29)` are one set in four tones: a low rock wall one cell of
rock thick, with a rim above and below and rounded caps where it stops,
so a gap between two segments is a pass. Each piece is a column three
cells tall (rim, rock, rim):

| Tone | West cap | Body | East cap |
|---|---|---|---|
| light | `(7, 12–14)` | `(8, 12–14)`, `(7, 15–17)` | `(8, 15–17)` |
| mid | `(16, 15–17)` | `(14, 15–17)`, `(17, 15–17)` | `(15, 15–17)` |
| dark | `(16, 21–23)` | `(14, 21–23)`, `(17, 21–23)` | `(15, 21–23)` |
| stone | `(16, 27–29)` | `(14, 27–29)`, `(17, 27–29)` | `(15, 27–29)` |

The rims bake their tone's ground, so a ridge stands only on that ground:
light on plain lawn, mid, dark, and stone on a plateau top of the same
tone. A ridge is an upright wall whose base is the bottom of the rock.
Its collider straddles the base: 13 px up into the rock (a character
behind the wall shows only its head) and 8 px down into the lower rim (one
in front stops with about half its body over the face), trimmed to the
rock's width in each piece (the rounded caps
are narrower), so a gap is as wide as it looks. The rim and rock are also
drawn as a y-sorted overlay (the two cells minus their baked ground),
sorted at the base: a character standing right behind the wall shows only
its head over the rim, and one in front is drawn over the lower half of
the face. Grass zones fade away from ridges as they do from the path. Ridgeline (28) and Walled mesa
(29) use them.

Not used: the thin diagonal hedge pieces `(0–1, 4)`, `(0–1, 8)`, which
draw as scattered leaf bits.

## Ambience (Painted Lands scenes)

Motion lives outside the tile art, in four scripts that `forest.gd` adds:

- `scripts/wind.gd` (`Wind`) — the one wind every effect reads. Its
  heading eases to a new direction every 20–40 s (over about 4 s), base
  strength drifts between 0.3 and 0.8, and gusts rise and fall on top every
  6–16 s.
- `scripts/ambient_leaves.gd` — leaves fall from every tree crown (and the
  canopy wall's lower edge), flutter, tumble between two- and three-pixel
  shapes, drift with the wind, lie on the ground a few seconds, and skitter
  in gusts. Colors come from each tree's sprite: a light foliage or blossom
  color that stands off the lawn, edged with the tree's darkest green, so a
  leaf reads on any grass tone. More fall in gusts.
- `scripts/wind_streaks.gd` — pale one-pixel wisps skim along the wind in
  view, fading toward the tail; about a third curl into a small eddy. More
  in gusts. Drawn under the y-sorted actors.
- `scripts/cloud_shadows.gd` — three lumpy cloud shadows in translucent
  deep-grass green with a narrow ordered-dither rim, drifting with the wind
  and wrapping in on the upwind side.
- `scripts/fire_ambience.gd` — every campfire and torch gets a warm pixel
  glow (a round light in solid steps joined by ordered dither, drawn
  additively over the scene) that flickers out of step with the others;
  big fires glow widest, torches smallest. Campfires send up a thin column
  of smoke puffs (2×2 knots loosening into 3×3) that rise, bend with the
  wind, and fade. Every house with a hearth (the three cottages and the hut;
  not the shed or barn) sends up a thinner column, 0.6 of a campfire's, from
  its roof peak (`CHIMNEYS` in `forest_terrain.gd`; the sheet draws no
  chimneys).
- `scripts/drifters.gd` — what the wind carries through any view: dandelion
  seeds (a pale core and a paler tuft, riding the wind, bobbing and lifting,
  more in gusts), pollen specks hanging over flowers, and every 22–40 s a
  flock of four to seven birds crossing the view in a loose V, flapping,
  their shadows gliding 26 px below them. Spawned in and around the view.
- `scripts/grass_waves.gd` — light passing over the grass: each gust sends
  one or two fronts, and a faint one passes every 7–12 s; a front is a band
  40 px across the wind rolling downwind at about 42 px/s, lighting a
  dithered scatter of pale blade tips (leaning a pixel downwind) on grass
  cells only, strongest in the band's middle. Nothing on the map moves (this
  is not flower sway); it is drawn under the actors.
- `scripts/water_life.gd` — ripple rings spread now and then on open water
  (water cells whose eight neighbors are water), drawn as flattened pixel
  circles in the deep-water teal with a pale inner highlight while young,
  since the pond surface is pale. Every 8–18 s a fish jumps: droplets arc
  up and fall back with rings. Reeds and water grass are split into a
  planted base and a top that leans one pixel downwind in strong wind,
  each plant at its own moment.
- `scripts/critters.gd` — butterflies (3–8 per map, four wing colors)
  flutter from flower to flower, rest with wings open, get pushed about in
  gusts but always arrive, and scatter when the walker comes within 26 px;
  dragonflies (one or two per pond) dart over open water in quick eased
  bursts and hover, and dart off from the walker; fireflies (up to 14)
  drift over dark and deep grass and under the canopy wall, pulsing with a
  faint cross of glow at the peak.
- `scripts/wildlife.gd` (`Wildlife`) — ten small animals drawn in code as
  tiny pixel sprites (a rabbit is 7 px tall beside the 32 px walker) in
  colors snapped to the sheet's palette, each y-sorted on `Actors`:
  rabbit (lawn), squirrel (by trunks), vole (dark grass), mouse (by logs,
  crates, fences), hedgehog (by bushes and hedges), frog (shore), duck (open
  water), sparrow (lawn near paths and fences), lizard (plateau tops, rocks,
  ridges), fox (anywhere on the ground, 35 % of maps, one). Green plateau
  tops count as lawn and open ground too. `plan()` picks four to seven
  eligible species per map from the map id, one to three groups each at
  least eight cells apart and six from the spawn, so every map has its own
  population and the same map always the same one. Groups that do not need
  trees or water settle in the quietest of six candidate spots: farthest
  from water, campfires, torches, trees, and the groups already placed, so
  animals fill the parts of the map nothing else moves in. Each
  animal idles, wanders around its group's home, and reacts to the walker
  its own way: rabbits and the fox run, squirrels run up a tree, voles,
  mice, and lizards dash and hide, hedgehogs curl up, frogs jump into the
  water, ducks paddle off, and a sparrow flock flies to a new spot.
- `scripts/footsteps.gd` — the ground answers the walker every 9 px of
  travel: puffs of dust behind it on cobble and dirt, grass blades flicking
  up from tufts and flowers (three) and, on 60 % of steps, from plain grass
  (one or two; not on stone tops, stairs, or ramps), in sunlit blade colors
  lighter than any grass tone so they read, a ripple ring at the shore when it walks
  beside water, and fallen leaves near its feet kicked aside. Bits start a
  few pixels behind the walker so its sprite never hides them.

Torches: the three torch cells `(35–37, 26–27)` are one torch in three
flame frames, played at about 7 fps like the campfires; every fire
flipbook starts on a random frame at a slightly different speed, so no
two fires flicker in step.

Everything moves on whole world pixels and uses the sheet's colors; no
new sheet art (the animals are drawn in code, their colors snapped to the
sheet). Map generation is unchanged; the animal population is chosen from
the finished map.

## Streams

A recipe whose water is `S if room` (every land-only recipe but Open meadow,
which the wilds scene pins dry) gets, on 70 % of its maps, a brook three
cells wide after the layout. It enters from a map edge and meanders in a staircase of straight
runs, at least four cells between turns, turning sideways and back to its
flow but never doubling back, 22–46 steps long. It runs off another edge, or
rises from a spring: a 5 × 5 pool at the end inside the map. Three to six
2 × 2 bulges on its banks keep the edges from running straight. Cells past
the map edge count as water, so it flows off the map with no shore there.
It keeps two cells from the path and off everything already claimed, so it
never needs a bridge, and it is dropped if it would cut the spawn off from a
goal. Tiles, the scrolling surface on open cells, and water plants are the
pond's. Its middle row is open water, so it ripples and fish jump there, and
frogs and ducks can live on it. Streams do not count as ponds.

## Liveliness floor

Every camera-sized window (43 × 18 cells) should have something moving in
it. After the props, trees, and deco are placed, the generator works out the
liveliness estimate (`scripts/liveliness_features.gd` with weights frozen in
`forest_terrain.gd` from the 2026-09-27 calibration, so recalibrating never
rearranges a map) for every window. While the weakest window is under 0.09 %
of pixels moving per frame, it gets a motion anchor near its middle: a pair
of wayside lanterns (torches) facing each other across the path if the path
crosses it, otherwise a campfire in a clearing clear of the path; a window
under half the floor gets the campfire first. At most three anchors per map;
an anchor that would cut the spawn off from a goal is not placed. The report
line `floor:` gives the weakest window before and after and what was added.

## Forest generator

```
seed = map_id
recipe = seed % 30                # or the scene's pinned recipe
n_houses = recipe.houses          # 0, 1, or 2 only if table says 2
house_ids = named id, else (seed // 20) % 4 for the first;
            second house = (first + 1 + seed) % 4
height, moist = fBm(seed, 4 octaves, freq 0.055 / 0.05)
pond_mask = CA(low+wet); drop <12 cells and tetrominoes
plateau_mask = CA(high); drop <40; keep only if recipe.plateau
flatten spawn disk and each house disk
path = A* 4-connected; widen 2; autotile PATH table; force caps
patches = grow 3–8 cell blobs (no 2-cell L); autotile PATCH atlas;
          Mode A or B grass paint; never a dark-green tile rectangle
          or a lone square fill; min 3 tiles from cobble
grass_accents = optional; Mode A (recolor away) or Mode B (noisy halo);
                never a raw dark-green 16×16 stamp
extras = fences/gate/plateau/pond per recipe
props  = bushes, land rocks, water plants/rocks, campfire,
         torches, signs per recipe
trees  = Poisson
verify walk + reject list
```

### Recipe table (`recipe = seed % 30`)

Houses = 0, 1, or 2 (2 only here when written). P/P2 = pond(s).
P if room = a pond in whichever quarter of the map has room for one after
the layout (dropped, not failed, when none fits), so a road-and-lawn recipe
still has water moving somewhere. S if room = a stream (below), dropped if
none fits.
F = fence yard. G = gate line. C = plateau. L = approx-45° lean.
Patch = count of *blobs* after autotile (R round shape, I irregular
shape). Props: bushes, land rocks (LR), water plants (WP), water
rocks (WR), campfire (CF), torches (T), signs (S).

| # | Name | Houses | Water | Height | Path | Patch blobs | Props |
|---|---|---|---|---|---|---|---|
| 0 | Pastoral | 1×0 | P + WP + WR | F | trunk + L | R 2–3 | bushes, LR, T, S=1 |
| 1 | Crossroads | 1×1 | P if room + WP | none | 2 trunks 90° | I 2–3 | bushes, LR, T, S=2 |
| 2 | Pond walk | 1×2 | P + WP + WR | none | skirts shore | R 2 | bushes, S=1 |
| 3 | Garden | 1×3 | S if room | F+G | through gate | R 2 | bushes, LR, T, S=2 |
| 4 | Lookout | 1×0 | S if room | C | to plateau foot | I 2 | LR obstacles, CF, T, S=1 |
| 5 | Open meadow | 0 | none | none | edge-to-edge | R 3–4 | bushes, LR, no signs |
| 6 | Twin water | 1×1 | P2 + WP + WR | none | between blobs | R 1–2 | S=1 |
| 7 | South road | 1×2 | S if room | none | south third | I 2–3 | bushes, CF, T |
| 8 | Shore spur | 1×3 | P + WP + WR | none | trunk + spur | R 2 | S=2, T |
| 9 | Three-way | 1×0 | P if room + WP | none | +2 branches 90° | I 2–3 | bushes, LR, T, S=3 |
| 10 | West hamlet | **2** (1 and 3) | P + WP | F | from east, L | RI 2 | CF, T, S=2 |
| 11 | East hamlet | 1×2 | P + WR | F | from west, L | R 2 | T, S=1, bushes |
| 12 | Wild lane | 0 | moisture P | none | 1 trunk | I 3–4 | bushes, LR obstacles |
| 13 | Orchard | 1×3 | P if room + WP | none | short trunk | R 2 | bushes heavy, T, S=1 |
| 14 | Shore hamlet | 1×0 | P + WP + WR | F between | short trunk | R 1–2 | CF, T, S=2 |
| 15 | Double lean | 1×1 | P if room + WP | none | two L | I 2–3 | LR, T, S=1 |
| 16 | Below the rim | 1×2 | S if room | C | lawn south of plateau | I 2 | LR, S=1, T |
| 17 | Gate road | 1×3 | S if room | G | through gate | R 2 | T on gate, S=2 |
| 18 | Sparse wild | 0 | P if blob | none | 1 trunk | I 1–2 | LR only |
| 19 | Switchback | 1×0 | S if room | none | U of two 90° | RI 2 | bushes, CF, S=1 |
| 20 | Cave mouth | 0 | S if room | C (light, cave) | to the cave | I 2–3 | bushes, LR, T by the cave, S=1 |
| 21 | Terraces | 1×3 | S if room | C2 (light + ramp, mid/dark + stairs) | along the terraces | RI 2 | bushes, LR, CF, T, S=1 |
| 22 | Stone ruins | 0 | S if room | C (stone, ramp) | to the ramp | I 1–2 | LR obstacles, stone outcrops, ruins clutter, T, S=2 |
| 23 | Woodcutter camp | **2** (4 and 5) | S if room | F | trunk + spur | I 2 | big CF + ash, logs heavy, S=1 |
| 24 | Rock garden | 0 | P + WP + WR | none | edge + L | R 2–3 | outcrops, bushes |
| 25 | Deep forest | 0 | S if room | none | 1 trunk | I 1–2 | canopy wall, logs heavy, bushes, S=1; darker tone cover |
| 26 | Village square | **3** (0, 1, 2) | S if room | none | plaza + 2 trunks | R 1–2 | T at plaza corners, S=3 |
| 27 | Hedge garden | 1×2 | S if room | F+G | through gate | R 2 | hedges heavy, carpets heavy, T, S=1 |
| 28 | Ridgeline | 1×1 | S if room | R (light ridge across the map, two passes) | through the pass | I 2–3 | bushes, LR, T at the pass, S=1 |
| 29 | Walled mesa | 0 | S if room | C+R (14–18 × 7–8 top in stone, mid, or dark; ridge walls on it, each end two walkable columns short of the outer rim) | to the mesa | R 1–2 | LR, outcrops, T, S=1 |
| 30 | Cottage row | **3** (1, 2, 3) | S if room | none | plaza + 2 trunks | R 1–2 | bushes, carpets heavy, T, S=2 |
| 31 | Twin cottages | **2** (0 and 2) | P + WP | F | from east, L | RI 2 | bushes, T, S=1 |
| 32 | Manor green | **2** (0 and 3) | S if room | none | plaza + 2 trunks | R 2–3 | bushes, LR, T, S=2 |

Recipes 30–32 use the village and hamlet layouts with other buildings: in
the randomizer every house opens onto an interior (`docs/interiors.md`), so these
put homes of different sizes side by side. The hut must come last in a row.

`1×N` means one house of prefab N. Only recipes 10, 23, 31, and 32 place two
houses and 26 and 30 three. Recipes 5, 12, 18, 20, 22, 24, 25, 29 place zero. C2 is two plateaus.
The forest and wilds scenes pin recipes 3 and 5, so adding recipes
never changes those maps.

If a flag cannot be placed without breaking autotile, drop *that extra*
only. Do not drop patch blobs, bushes, or signs just to keep the old
pastoral screenshot.

Reject a Painted Lands screenshot if: lawn is a motif stamp; fill sits
on a cap or knuckle; pond corners are square wave tiles; a cliff
fragment is orphaned; the actor draws through `HOUSE_BODY`; a 1-tile
stair fakes 45°; a PATCH cell is a square fill or a lone quadrant;
two houses appear on a recipe that lists 0 or 1; a PATCH sits on a
dark-green square/rectangle of baked grass; a lone dark-green grass
tile shows its 16×16 edge; a dirt blob is an L or stair of square
cells; land rocks sit in water or water rocks on lawn; a crate
stands in for a sign.

## Cozy farm randomizer

`scenes/randomizer-painted-cozyfarm/randomizer-painted-cozyfarm.tscn` is the
Painted Lands randomizer (same generator, recipes, interiors, and ambience;
`forest.gd` with `interiors = true`), starting at map id `180033` pinned to
recipe 33 Farmstead, with `cozy_animals = true` (`wildlife.gd` runs its cozy
table: `Wildlife.cozy`, `COZY_SPECIES`, `COZY_SHEETS`) and
`cozy_buildings = true` (below).

- Animals from the Cozy Farm art pack (shubibubi,
  `assets/pack/cozy_farm/animals/`, git-ignored): bunny (grey and brown)
  in place of the drawn rabbit, and chicken, turkey, sheep, goat, pig, and
  cow, about a third of each herd young (the pack's baby sheets), one coat
  per herd. Sheets are 4 frames x 5 rows (walk down, walk up, walk left,
  walk right, sleep); cells 16-24 px (`info.txt` in the pack).
- Kept as drawn: vole, mouse, frog, lizard (too small for the pack's
  animals), duck and sparrow (birds), and every insect in `critters.gd`.
  Squirrel, hedgehog, and fox have no pack counterpart and are left out.
- Habitats: chickens and turkeys on open ground near paths and houses,
  sheep, goats, and cows on the lawn, pigs by clutter, bunnies on the lawn.
  Two to four farm species on every map, six to nine species in all.
- Behavior: bunnies hop and bolt like the rabbit; farm animals graze, amble
  18-40 px away from the walker instead of bolting, and doze now and then
  on the pack's sleep row, waking when the walker comes near.
- Measured against the drawn animals (slow capture, exhaustive walker, and
  fast estimate): `docs/liveliness-cozyfarm.md`. The tools take `cozy` and
  `out=<dir>` for these runs.

**Buildings** (`cozy_buildings = true`; `PaintedTerrain.cozy`): the Cozy
Farm homes stand in for the Painted Lands houses on every map type that has
houses (never both packs on one map), and farm outbuildings fill a farmyard.
Sheet `assets/pack/cozy_farm/buildings.png` (spring versions), drawn at 0.86
brightness (`COZY_VALUE`; the pack runs brighter than the Painted Lands
houses). Measured against the Painted Lands sheet, the homes used sit within
10-17 of its palette (83-98 % of pixels within 24).

| id | Building | Size (px) | Door | Rooms | Chimney |
|---|---|---|---|---|---|
| 10 | Farm cottage | 62 x 73 | (2, 5) | 2-3 | yes |
| 11 | Farmhouse (two wings) | 94 x 73 | (2, 5) | 3-5 | yes |
| 12 | Timber house (purple roof) | 74 x 76 | (2, 5) | 2-4 | yes |
| 13 | A-frame house (green roof) | 77 x 80 | (2, 5) | 2-4 | yes |
| 14 | Thatched cottage | 72 x 74 | (2, 5) | 1-3 | yes |
| 15 | Brick house | 82 x 69 | (1, 5) | 2-4 | no |
| 16 | Long house | 93 x 64 | (2, 4) | 2-3 | yes |
| 20 | Red barn (outbuilding; a home on Woodcutter camp) | 67 x 80 | (1, 5) | 1-3 | no |
| 21 | Coop | 60 x 64 | - | - | no |
| 22, 23 | Red silo, straw silo | 36 x 68 | - | - | no |
| 24 | Windmill (sails turn with the wind) | 56 x 67 | - | - | no |

Left out as the weakest fits: greenhouse (pale glass, lightest outlines),
blue-roof house (a blue the sheet lacks), slime hut (rainbow roof),
hospital, museum, and market (civic), and every fall and winter version.

Map types (`COZY_SWAP`: the home for each prefab a recipe names;
`COZY_FARM`: its outbuildings; houses keep each recipe's count):

| Map types | Homes | Farmyard |
|---|---|---|
| Pastoral | farm cottage | barn, red silo, coop |
| Garden, Gate road | farm cottage | coop |
| Orchard | farm cottage | barn, straw silo |
| Crossroads, Three-way, Below the rim, Ridgeline | timber | - |
| Lookout, Double lean, Terraces | A-frame | - |
| Pond walk, Twin water, East hamlet | thatched | - |
| Shore spur, Shore hamlet | thatched | coop |
| South road, Switchback | long house | red silo |
| Woodcutter camp | long house, red barn | straw silo |
| West hamlet | timber, A-frame | coop |
| Cottage row | thatched, A-frame, timber | - |
| Twin cottages | farm cottage, thatched | coop |
| Village square | timber, A-frame, brick | - |
| Hedge garden | brick | - |
| Manor green | farmhouse, brick | barn |
| Open meadow | none | windmill, straw silo |
| Wild lane, Sparse wild, Cave mouth, Stone ruins, Rock garden, Deep forest, Walled mesa | none | - |

New map types, only in this scene (`COZY_RECIPES`, ids 33-35; recipe =
map id % 36 here, so the Painted Lands scenes keep % 33 and their maps):

- **33 Farmstead** (the Pastoral layout): the farmhouse in its fenced yard,
  a barn, a coop, and both silos, with the pond south.
- **34 Windmill road** (the South road layout): a thatched cottage on the
  road, the windmill, a straw silo, and a coop.
- **35 Farm village** (the Village square layout): farm cottage, timber
  house, and thatched cottage on the square, with a barn, a coop, and the
  windmill.

Outbuildings go on the free lawn closest to the first home's doorstep (80
tries in a window round it), anywhere on the map when there is no home or no
room (the village squares), two cells clear round each, three from any other
building; a spot that would cut the spawn off from a goal is skipped, and the
report check fails a map missing one. They are not entered. Their doorsteps
count as farmyard for the animals (pigs and mice by the barn, chickens at the
coop). The windmill's sails are six pixel-art frames through a quarter turn
(nearest-pixel rotation), stepped faster in stronger wind, drawn in front of
the body. `tools/check_recipes.gd ... cozy` checks the cozy generator and
lists each map's buildings.

