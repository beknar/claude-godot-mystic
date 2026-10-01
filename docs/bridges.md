# Bridges (Painted Lands rivers and brooks)

Neither the Painted Lands Forest sheet nor the Farm – 4 Seasons sheet draws
a bridge, so the bridges are generated (AGENTS.md rule 5): every color comes
from the sheet the bridge stands on, the outline is that sheet's own dark,
and every piece is on the 16 px grid.

- Generator: `tools/gen_bridges.py` (`python3 tools/gen_bridges.py
  [preview.png]` also writes a preview of every design over water between
  banks, in both kits).
- Sheets: `assets/ai/bridges/bridges_forest.png` (TILESET_brighter.png's
  colors), `bridges_farm.png` (farm_spring_summer.png's; spring, summer, and
  autumn), `bridges_farm_winter.png` (the farm set with snow on every
  surface that faces up, thick at the deck's edges and on the rails, trodden
  thin down the middle, in farm_winter.png's snow colors).
- Code: `scripts/bridges.gd` (`Bridges`: designs, rects, `build`,
  `deck_cells`); the Farm places them in `farm_terrain.gd`
  (`_bridge_crossings`) and `farm.gd` (`_place_bridges`), the Forest in
  `forest_terrain.gd` (`_river`, `_bridge_rivers`) and `forest.gd`
  (`_place_bridges`).

## Pieces

A bridge's deck is two cells wide (a road's width) and runs from the bank
before the water to the bank after it, so it spans any width of water:

- **Across** (east-west, over water running north-south): pieces 16 x 56,
  `w` (west end), `m` and `p` (middles, `p` with a post, a lantern, a
  flower box, a bollard), `e` (east end). The deck fills rows 12-43 over the
  bridge's two cell rows; the back rail stands above it (to row 2, over the
  water north of the bridge); the deck's front face and what holds it up
  hang below (to row 55, over the water south of it), with the deck's
  shadow on the water. Two layers: the **base** (back rail, deck, face,
  supports) draws under the walker; the **front** rail draws over it,
  y-sorted at the deck's front edge, so the walker crossing shows above the
  back rail and behind the front one.
- **Along** (north-south, over water running east-west): pieces 36 x 16,
  `n`, `m`, `p`, `s`: the deck between rails at x 0-4 and 27-31, the deck's
  end face showing on the south end, its shadow on the water to the east.
  All under the walker.

Middles alternate `m` and `p`, so posts and lanterns come every other cell.
Sheet layout: one 56 px row per design, across base at x 0-63, across
front at x 64-127, along pieces at x 128-199.

## The 24 designs

| # | Design | Deck | Rails | Under |
|---|---|---|---|---|
| 0 | plank | planks across | none | beams |
| 1 | plank_rail | planks | posts and two rails | beams |
| 2 | rope_plank | gappy planks | rope between posts | a thin post |
| 3 | boards | boards along the walk (red wood) | curb | beams |
| 4 | log_deck | round logs | none | the logs' ends |
| 5 | log_rail | split logs | a log rail | beams |
| 6 | boardwalk | thin planks | none | stilts with a brace |
| 7 | clapper | big stone slabs | none | stone piers |
| 8 | stone_arch | cobbles | stone parapets | an arch per cell |
| 9 | mossy_arch | cool cobbles | mossy parapets | arches with moss |
| 10 | lantern_stone | stone blocks | low parapets, lanterns | arches |
| 11 | lattice | planks (red wood) | lattice rails | beams |
| 12 | flower_rail | planks | rails planted with flowers | beams |
| 13 | branch_rail | gappy planks | twisting branches | a thin post |
| 14 | trestle | planks (red wood) | posts and rails | X-braced trestle |
| 15 | stone_pier | boards | curb | stone piers |
| 16 | sandstone | sandstone blocks | sandstone parapets | arches |
| 17 | painted | planks | rails painted cream | beams |
| 18 | rustic | rough planks | one rope, posts every cell | a thin post |
| 19 | gate_posts | planks (red wood) | rails, tall capped gate posts at the ends | beams |
| 20 | mossy_slab | stone slabs with moss | none | piers |
| 21 | cobble_curb | sandy cobbles | stone curb, bollards | arches |
| 22 | lantern_wood | boards | posts and rails, lanterns | stilts |
| 23 | felled_log | two trunks side by side | none | the trunks' ends |

The lanterns' flames flicker and glow (fire_ambience.gd, `lamp`).
Winter skips the mossy and flowered designs (mossy_arch, flower_rail,
mossy_slab). Each bridge on a map is a different design; the first is picked
by the map id.

## Where they go

- **Farm**: a lane crosses a brook or a river where the path A* finds it
  cheapest (the water costs 25 a cell). Each crossing becomes a bridge
  (`_bridge_crossings`): its two rows are the crossing's busiest row and the
  one beside it, its ends stand a cell back from the water on open ground
  (the corners next to the water are kept for the shore, so the lane's
  ground can only meet the bridge there), and the lane is joined to both
  ends. A crossing whose ends would not stand on open ground keeps its
  stepping stones. The deck's water cells (`bridge_cells`) stay water for
  the tiles but are walkable: no collider, no splash, no ducks or fish
  rings under them. The rivers (map types 48-51, `"water": "river"`, three
  blocks wide) route a lane across if no lane crosses, so every river has
  its bridge.
- **Forest**: the river map types (33 River crossing, 34 River lane, 35
  Twin bridges) lay a river four cells wide from edge to edge first
  (`_river`: the pond's tiles, bank bulges, straight for four cells either
  side of each crossing so the road crosses square), route the roads over
  the dry crossing cells, then give the crossing cells back their water
  tiles and lay a bridge over each (`_bridge_rivers`). The other Forest
  brooks still keep away from the paths.

## Checks

`tools/check_recipes.gd` and `tools/check_farm.gd` (the walker reaches
every goal over the bridges); `check_farm.gd` prints each map's bridges
(design and span) and any stones left. The headless walker test crossed the
river and brook maps with no snags.

## Reject list

A bridge end over water or short of the lane; a deck that does not cover
the crossing; a rail that hides the walker on the deck (the front rail only
covers its feet); a mossy or flowered bridge in the snow; two bridges of one
design on one map.
