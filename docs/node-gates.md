# Node gates

Read this before touching `scripts/node_gates.gd`, `gate_world.gd`,
`gate_roads.gd`, `gate_items.gd`, `foe.gd`, `gate_walker.gd`,
`node_gates_ui.gd`, `hud_art.gd`, or `scenes/node-gates/`. The maps themselves are the Painted Lands Forest
randomizer's (`docs/painted-lands.md`); every rule there applies.

## What it is

A world of Painted Lands Forest maps joined at their edges. Every map is a
node on a square grid round the first map, **c-0**. Each map has a gate near
the middle of its north, east, south, and west edges; walking out through
one builds the map of the node one step that way and puts the walker just
inside that map's opposite gate.

- **Tilesets:** Painted Lands Forest (`TILESET_brighter.png`), Cozy Cottage
  interiors behind every door (`house_interiors.gd`), Cozy Farm animals round
  the homes (`wildlife.gd` "pack"). Nothing else on the ground.
- **Foes:** the Green Caves pack's two slimes and four of the Painted Lands
  RPG Characters (cloaked figure, samurai, fire knight, dark knight). Both
  are antarcticbees' Painted Lands art.
- **Locks:** a gate to a node not visited yet opens only once every foe on
  the current map is down. A gate to a node already visited always opens.
  Past ring 33 the land ends (no gate).
- **Saving:** `user://node_gates_save.json` (GateWorld). Every node keeps its
  map id, whether it is cleared, the foes still standing (kind, where they
  stood, hit points), and its chest; the hero keeps hearts, mana, coins,
  sword, and the bag. Each node's thumbnail is kept beside the save.
  Written on arriving, on every kill, on clearing, on opening a chest, every
  8 s, from the Esc menu's Quit, and on closing the window. A map comes back
  as it was left. A node saved with no foes and not cleared plans its foes
  again.

## Names and rings

The grid has x east and y north. A node's **ring** is the larger of its two
offsets from c-0, so the eight nodes round c-0 are ring 1.

| Node | Name |
|---|---|
| (0, 0) | `c-0` |
| on an axis | `n-1`, `e-2`, `s-3`, `w-1` |
| on a diagonal | `ne-1`, `nw-2`, `se-3`, `sw-1` |
| off both | the dominant direction and ring, then the offset along the other axis: (1, 2) is `n-2.e1`, (-3, -1) is `w-3.s1` |

## Progression

The ring sets the map type: rings 0 and 1 are Pastoral (map type 0), ring 2
Crossroads (1), and each ring outward the next Painted Lands map type, up
to ring 33, Manor green (32). The river map types (33-35) are not used.
`GateWorld.recipe_for` is `max(0, ring - 1)`.

| Rings | Foes (`GateWorld.POOLS`) | Count |
|---|---|---|
| 0-2 | green slime | 2 (c-0), 3 (ring 1), 4 (ring 2) |
| 3-5 | green and blue slimes | 4, then one more every four rings, at most 9 |
| 6-10 | slimes, cloaked figure | |
| 11-16 | blue slime, cloaked figure, samurai | |
| 17-24 | cloaked figure, samurai, fire knight | |
| 25-32 | samurai, fire knight, dark knight | |
| 33 | fire knight, dark knight, and the manor's lord (a dark knight with three times the hit points) | |

Foes grow with the ring: hit points by 7 % a ring, damage by one half-heart
every 12 rings, speed by 0.6 % a ring (`Foe.setup`). Ring 2's slimes are the
same kind as ring 1's, a little tougher.

**Rewards.** Clearing a node leaves a chest a few steps from the walker
(silver to ring 10, gold from ring 11; the Forest sheet's own chests, open
and shut). Walking into it opens it: coins (3 + 2 per ring), items (one,
plus one every six rings, at most six; ten at ring 33), one more heart
every fourth ring, one more sword point every sixth, and a large reward at
ring 33 (`GateWorld.reward_for`). A bag too full to take an item leaves it.

## Items

Each item a chest holds is rolled by rarity (`GateItems.roll`): an item's
rarity is its weight, so a small potion (80) turns up 16 times as often as a
well-done steak (5). Items stack to 99 in the bag's 27 slots.

| Items | Effect | Rarity (weight) | Icon |
|---|---|---|---|
| Healing potions: small, medium, large, uncommon, wondrous, rare, very rare, legendary | restore 10, 20, ... 80 % of the hit points | 80, 70, ... 10 | Fantasy RPG icon pack red bottles (small, medium, large; the large from uncommon up) |
| Mana potions, the same eight | restore 10 ... 80 % of the mana | 80 ... 10 | its blue bottles |
| Speed potions, the same eight | +10 ... +80 % walking speed for 30 s | 80 ... 10 | its white flasks recolored in its own greens |
| Bread, fish, fruit, nuts and seeds, jerky, hardtack, travel cake, sweet roll, well-done steak | regenerate 1, 2, ... 9 % of the hit points a second for 10 s | 80, 70, 60, 50, 40, 30, 20, 10, 5 | bread, hardtack, sweet roll: Cozy Farm's butter, mozzarella, goat cheese (no pack draws a loaf, a biscuit, or a roll); fish and fruit: the Painted Lands Farm fish and apple; nuts, jerky, travel cake, steak: the Fantasy RPG icon pack |

The rarity tier (1-8) picks one of the icon pack's eight slot frames: dark,
silver, bronze, green (uncommon), teal (wondrous), gold (rare), purple (very
rare), orange (legendary). A potion is not drunk at full health or mana,
nor food eaten at full health; a speed potion weaker than one still running
is not drunk. A new game's bag holds two small healing potions and three
bread.

**Mana** (out of 100, starting at 50) comes back at one a second; a spin
(K) costs 20 and hits every foe within 26 px of the walker for one more
than a swing.

## How it is built

- **Gates** (`gate_roads.gd`, `PaintedTerrain.gates`): laid right after the
  recipe's layout and before the path is autotiled. A road the layout already
  runs off an edge is that edge's gate; otherwise a cobble road two cells
  wide runs in from the edge and joins the recipe's path (an L or a dogleg,
  only over open lawn, kept only if the whole path still autotiles). Where
  the edge itself is solid (the Deep forest's canopy wall), the road starts
  at the first open row in. Failing every road, a trail: two open edge cells
  the spawn reaches, the ground inside claimed so no tree lands on it. The
  gates join the terrain's goals (hedgerows and brooks that would cut one
  off are dropped) and `_verify` checks each is reachable from the spawn.
  A new node whose gates still do not all fit tries the next map ids.
- **Gate marks** (`NodeGates.GateMarks`): chevrons at each gate pointing out
  of the map, pale gold when it opens, red while it is shut, none at the
  world's edge. UI drawn in code, never tiles.
- **Foes** (`foe.gd`): placed on the first visit at least 14 steps (fewer on
  a cramped map) from where the walker came in, on cells with open ground
  all round, six cells apart. They wander near home, chase within their
  aggro range along a flow field (a BFS from the walker's cell over the
  terrain's walkable cells, every 0.25 s), line up beside the walker (their
  strikes are sideways), wind up, and strike on their attack's hit frame;
  a hit staggers them back; on defeat they play their death and fade.
  Slimes use their own left and right sheets (16 x 16; the attack is 32
  wide, the slime in the half away from its lunge). The RPG Characters face
  left and are mirrored for right, each animation anchored where the body
  stands in its frame (`Foe.RPG_FRAMES`: the dark knight's attack frame puts
  the body 48 px in, the rest 15 or 32).
- **The walker** (`gate_walker.gd`, on `scenes/forest/walker.tscn`): the
  Painted Lands walker with a swing on Space or J. The sheet has no attack
  row, so the swing is a drawn pale crescent while the walker leans in on
  its idle frame; it hits every foe within 12 px plus the foe's radius of a
  point 10 px in front. A hit on the walker knocks it back and leaves it
  blinking for 0.9 s. Hearts are two hit points each. At zero the walker is
  carried back to c-0 with full hearts; the map it fell on keeps its foes.
- **HUD art** (`hud_art.gd`): the most compatible UI art for Painted Lands
  maps (docs/ui-assets.md), cut from the pack sheets at load time and
  scaled by whole numbers (4 x): Cozy Farm's wooden plate (a 9-slice for
  every frame and panel; its centre dot and side notches painted over in
  its own colors so it stretches cleanly), its bar (hangers painted out),
  hotbar, inventory panel, and plank button; Franuka's Fantasy RPG icon
  pack for items, rarity frames, hearts, the coin, the sword, the mana drop,
  check and cross.
- **HUD** (`node_gates_ui.gd`): top left, a plate with the node's name and
  map type, its ring and foes left; under it the hearts, the mana bar, and
  the buffs running (icon and seconds left). Top right, the minimap (the map
  captured whole after each build and averaged down to a pixel a cell, at
  4 x, in a plate; the walker blinking white, foes red, the chest gold, the
  gates pale gold or red) with coins and sword under it. Bottom, the hotbar:
  the bag's first nine slots, keys 1-9 use them. A hint line bottom left.
- **Inventory** (I or Tab): Cozy Farm's panel with the bag's 27 slots in its
  grid (the first row is the hotbar), the selected item large in the
  portrait frame with its count on the nameplate, and a plate under it with
  its name, effect, and rarity. Arrows or WASD select, Enter or Space uses,
  X picks up a slot and X again swaps it with another, a double click uses.
- **Map** (M; `Overview`): the current map whole, drawn live at 2 x by a
  viewport sharing the world, in a plate, the walker, foes, and chest
  ringed and a plate on each gate naming the node it leads to; a side plate
  with the node's name and type, its ring, and each gate's destination and
  state.
- **Strategic map** (P; `StrategicMap`): a screen-sized plate. Every node
  visited is its thumbnail (the captured map averaged to 120 x 80, kept as
  `user://node_gates_thumbs/<seed>/<x>_<y>.png`) in a wooden frame with its
  name under it on a small plate and a check (cleared) or a cross (foes
  remain); the walker's node blinks. The moves made are wooden roads, the
  unvisited ways out of cleared nodes faint roads to framed question marks
  with their names. Arrows pan, + and - (or the wheel) step the zoom (1, 2,
  3 x the thumbnail).
- **Menu** (Esc): the plate with plank buttons: resume, inventory, map,
  strategic map, new game (erases the save, asks twice), quit. Esc closes
  whichever screen is open first. Every screen pauses the game.
- **Fonts** (`PixelFonts`, assets/fonts/README.md): node names, coins, and
  the strategic map's node labels in Jersey 10 (labels step through whole
  font-pixel sizes with the zoom); map-type names in Jacquarda Bastarda 9;
  the strategic map's and the menu's titles in Jacquard 12; text, messages,
  and buttons in Pixelify Sans; the hint line and the map's legend in
  Silkscreen. All with a maroon outline one font pixel wide.

## Checks

- `tools/check_node_gates.gd -- [seed] [nodes_per_ring]`: every ring's map
  type at a few nodes, generated as the scene does; all four gates present
  and reachable, room for the ring's foes, every cell with ground, and the
  Forest report's checks.
- `tools/walker_test.tscn -- gates [rings...]`: the walker test on one
  node per ring (0-33 by default), on its own save file, foes off and doors
  shut: the six camera views of each map as for the other scenes, then the
  walker walks to each of the four gates in turn and out through it under
  physics, and each gate is reported reached or missed
  (`.liveliness_walk_gates/headless.json`).
- `tools/check_node_gates_health.tscn -- [rings...]` (headless, `--fixed-fps
  60`): the real scene at one node per ring (0-33), entering by each gate in
  turn: the walker and every foe spawned clear of colliders and on walkable
  ground, every blocking body with its collider and the bodies on their
  layers, everything that moves y-sorted in Actors with its feet on its
  origin, the liveliness floor met, and the build time and a frame's wall
  time with the foes awake and chasing (`base` measures the plain
  randomizer the same way: about 0.7 ms a frame, against about 2 ms here).
- `tools/check_node_gates_items.tscn`: the items on the real scene
  (headless): the new bag, healing, mana, speed (and that it wears off),
  food regeneration, the full-health guard, the spin and its mana, rolls
  following rarity, and the bag and mana surviving a save.
- `tools/snapshot.tscn -- res://scenes/node-gates/node-gates.tscn <out.png> 3
  [map|overview|inventory|menu] tour`: one frame of a screen after a short
  tour (c-0, e-1, ne-1, n-1, back) with a filled bag.
- In the running game: clear c-0 (two slimes), open the chest, walk out a
  gate, come back through the same gate (it opens: visited), press I, M,
  and P.
- Demo reel: `tools/node_gates_demo.tscn` plays the scene by itself through
  the input actions and keys (the HUD; clear c-0 with swings and a spin; the
  chest; the bag (I); healing, mana, food, and speed from the hotbar; the
  whole map (M); the east gate, a shut gate, clear e-1, north; the strategic
  map (P); then ring 26's knights) with captions, on its own save file and
  bag (`user://node_gates_demo.json`, erased at the end). Record it with
  `--write-movie <out>.avi --fixed-fps 30` (the movie is the window's size).

## Reject list (on top of docs/painted-lands.md)

- A gate road that crosses water, a plateau, a fence, or stairs, or ends in
  a stub that does not join the path.
- A gate the walker cannot reach, or a gate mark at the world's edge.
- A foe drawn off its feet (floating, sunk, or jumping sideways between
  animations), or facing away from the walker it strikes.
- A foe that stands inside a trunk, a house, or the water.
- A chest on a road or half in a hedge.
