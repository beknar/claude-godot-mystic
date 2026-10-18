# Node gates

Read this before touching `scripts/node_gates.gd`, `gate_world.gd`,
`gate_roads.gd`, `foe.gd`, `gate_walker.gd`, `node_gates_ui.gd`, or
`scenes/node-gates/`. The maps themselves are the Painted Lands Forest
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
  stood, hit points), and its chest; the hero keeps hearts, coins, and sword.
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
and shut). Walking into it opens it: coins (3 + 2 per ring), healing (a
heart near c-0, all of it from ring 3), one more heart every fourth ring,
one more sword point every sixth, and a large reward at ring 33
(`GateWorld.reward_for`).

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
- **Strategic map** (M or Tab; `NodeGatesUI.StrategicMap`): every node
  visited as a dot (green when cleared, orange while foes remain), the moves
  made between nodes as lines, the unvisited ways out of cleared nodes as
  faint rings, the walker's node ringed in white and named in the header
  with its map type and ring. Arrows pan, + and - zoom.
- **HUD**: the node's name and map type, its ring, foes left (or cleared),
  hearts, coins, and sword. Esc: resume, strategic map, new game (erases the
  save, asks twice), quit.

## Checks

- `tools/check_node_gates.gd -- [seed] [nodes_per_ring]`: every ring's map
  type at a few nodes, generated as the scene does; all four gates present
  and reachable, room for the ring's foes, every cell with ground, and the
  Forest report's checks.
- In the running game: clear c-0 (two slimes), open the chest, walk out a
  gate, come back through the same gate (it opens: visited), press M.

## Reject list (on top of docs/painted-lands.md)

- A gate road that crosses water, a plateau, a fence, or stairs, or ends in
  a stub that does not join the path.
- A gate the walker cannot reach, or a gate mark at the world's edge.
- A foe drawn off its feet (floating, sunk, or jumping sideways between
  animations), or facing away from the walker it strikes.
- A foe that stands inside a trunk, a house, or the water.
- A chest on a road or half in a hedge.
