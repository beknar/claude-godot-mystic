class_name PCMaze
extends RefCounted
## maze-pixelcrawler: mazes on Anokolisa's Pixel Crawler sheets, one biome
## per map, laid into a PCTerrain (pc_terrain.gd with `maze` on) so the rest
## of the Pixel Crawler pipeline paints and fills them: the ground's corner
## tables, splat and tufts, the trees and scatter in the antechambers, the
## shadows, the ambience, the animals, and the checks.
##
## A maze is a grid of rooms; the walls between them, by kind:
##   kit    the sheet's wall mass (Forge, the Cemetery's crypt), read from its
##          plus-shaped sample: outer corners, edges, the four inner corners,
##          the black top two cells wide, the faces (two rows on the Forge,
##          three on the crypt) under every bottom edge; a band across the top
##          and the bottom of the map; the maze between two antechambers.
##   canal  water two cells wide (Fairy Forest, the Farm forest), drawn per
##          pixel by pixelcrawler.gd as the pack's ponds are; braids cross on
##          stepping stones.
##   pool   the sheet's animated channel (the Forge's lava, the Sewer's
##          slime): a 3 x 3 rimmed blob and its four inner corners, four
##          frames three rows apart; two cells wide; the sewer's braids cross
##          on its plank bridges.
##   props  bushes, cacti, or rocks standing on the wall's middle line, one
##          a cell, drawn half a cell low so they sit centred on it, the wall
##          three cells (a half, the middle, a half) colliding where drawn.
## Every room is reachable from the entrance (a spanning tree, plus loops
## where the type braids); clearings merge rooms; the entrance is a gap in
## the west wall and the exit one in the east (the room there farthest from
## the entrance), each marked either side (glowing runestones, crates, grave
## crosses, tusks, statues, lamps).
##
## Recipe keys (MAZE_RECIPES): biome; wall kit | canal | pool | props; kit
## forge | crypt; pool lava | slime; arts (the wall props); algo, braid,
## corridor; clearings [[kind, rooms wide, rooms tall, where]]; extras:
## flowers, bits, glow, lamps, dead (blocking props in dead ends); gate (the
## markers); plus the pipeline's keys (zones, patches, trees, plateaus,
## water, path, piece).

const W := PCTerrain.W
const H := PCTerrain.H
const TILE := 16

## Wall kits, read from each sheet's plus-shaped sample (cells): the top's
## corners, edges, middle, and inner corners (open NW: the floor at its
## north-west diagonal), and the face rows under a bottom edge (left end,
## middle, right end).
const KITS := {
	"forge": {"tl": Vector2i(0, 1), "t": Vector2i(2, 0), "tr": Vector2i(4, 1), "l": Vector2i(0, 2), "c": Vector2i(2, 2), "r": Vector2i(4, 2),
		"bl": Vector2i(0, 3), "b": Vector2i(2, 4), "br": Vector2i(4, 3),
		"in_nw": Vector2i(1, 1), "in_ne": Vector2i(3, 1), "in_sw": Vector2i(1, 3), "in_se": Vector2i(3, 3),
		"face": {"l": [Vector2i(0, 4), Vector2i(0, 5)], "m": [Vector2i(2, 5), Vector2i(2, 6)], "r": [Vector2i(4, 4), Vector2i(4, 5)]}},
	"crypt": {"tl": Vector2i(15, 16), "t": Vector2i(17, 15), "tr": Vector2i(19, 16), "l": Vector2i(15, 17), "c": Vector2i(17, 17), "r": Vector2i(19, 17),
		"bl": Vector2i(15, 18), "b": Vector2i(17, 19), "br": Vector2i(19, 18),
		"in_nw": Vector2i(16, 16), "in_ne": Vector2i(18, 16), "in_sw": Vector2i(16, 18), "in_se": Vector2i(18, 18),
		"face": {"l": [Vector2i(15, 19), Vector2i(15, 20), Vector2i(15, 21)], "m": [Vector2i(17, 20), Vector2i(17, 21), Vector2i(17, 22)],
			"r": [Vector2i(19, 19), Vector2i(19, 20), Vector2i(19, 21)]}},
}
## Animated channels: the blob's top-left cell (frame 0) and the inner ring's
## (corners land SE, SW, NE, NW at its four corners); frames three rows apart.
const POOLS := {
	"lava": {"blob": Vector2i(19, 13), "ring": Vector2i(22, 13)},
	"slime": {"blob": Vector2i(11, 0), "ring": Vector2i(14, 0)},
}

const MAZE_RECIPES := [
	# Fairy Forest.
	{"name": "Fairy hedge maze", "biome": "fairy", "wall": "props", "arts": ["ff_bush", "ff_bush_b", "ff_shrub"], "algo": "backtrack", "clearings": [["bells", 2, 2, "center"]], "extras": ["flowers", "bits", "glow"], "gate": ["ff_rune_glow"]},
	{"name": "Glowbell hedges", "biome": "fairy", "wall": "props", "arts": ["ff_bush_rust_s", "ff_shrub", "ff_bush"], "algo": "prim", "braid": 0.15, "clearings": [["bells", 2, 2, "random"], ["mushrooms", 2, 2, "random"]], "extras": ["glow", "bits"], "gate": ["ff_rune_glow"]},
	{"name": "Fairy canals", "biome": "fairy", "wall": "canal", "algo": "kruskal", "braid": 0.3, "corridor": 2, "extras": ["flowers", "bits", "glow"], "gate": ["ff_rune_glow"]},
	{"name": "Runestone hedges", "biome": "fairy", "wall": "props", "arts": ["ff_bush", "ff_shrub", "ff_bush_b"], "algo": "rings", "clearings": [["runes", 3, 2, "center"]], "extras": ["flowers", "bits"], "gate": ["ff_rune_glow"]},
	{"name": "Mushroom hollow maze", "biome": "fairy", "wall": "props", "arts": ["ff_bush_rust_s", "ff_bush", "ff_shrub"], "algo": "kruskal", "braid": 0.2, "clearings": [["mushrooms", 2, 2, "random"], ["mushrooms", 2, 2, "random"]], "extras": ["bits", "glow"], "gate": ["ff_rune_glow"], "zones": 0.42},
	# Farm forest.
	{"name": "Greenwood hedges", "biome": "green", "wall": "props", "arts": ["gw_bush", "gw_bush_b"], "algo": "backtrack", "extras": ["flowers", "bits"], "gate": ["gw_crate", "gw_barrels"]},
	{"name": "Forest canals", "biome": "green", "wall": "canal", "algo": "prim", "braid": 0.15, "corridor": 2, "extras": ["flowers", "bits"], "gate": ["gw_crate", "gw_barrels"]},
	{"name": "Woodcutter's maze", "biome": "green", "wall": "props", "arts": ["gw_bush", "gw_bush_b"], "algo": "kruskal", "braid": 0.2, "clearings": [["camp", 2, 2, "random"]], "extras": ["flowers", "bits"], "gate": ["gw_crate", "gw_barrels"]},
	{"name": "Crystal hedges", "biome": "green", "wall": "props", "arts": ["gw_bush_b", "gw_bush"], "algo": "sidewinder", "braid": 0.1, "clearings": [["crystals", 2, 2, "center"]], "extras": ["bits", "flowers"], "gate": ["gw_crate", "gw_barrels"]},
	# Cemetery.
	{"name": "Crypt maze", "biome": "cemetery", "wall": "kit", "kit": "crypt", "algo": "backtrack", "clearings": [["graves", 3, 2, "center"]], "extras": ["bits", "dead"], "gate": ["cm_grave_cross"]},
	{"name": "Catacombs", "biome": "cemetery", "wall": "kit", "kit": "crypt", "algo": "prim", "braid": 0.1, "extras": ["bits", "dead", "flowers"], "gate": ["cm_grave_cross"]},
	{"name": "Crypt rings", "biome": "cemetery", "wall": "kit", "kit": "crypt", "algo": "rings", "clearings": [["graves", 3, 2, "center"]], "extras": ["bits", "flowers"], "gate": ["cm_grave_cross"]},
	{"name": "Haunted crypts", "biome": "cemetery", "wall": "kit", "kit": "crypt", "algo": "kruskal", "braid": 0.3, "clearings": [["deadwood", 2, 2, "random"]], "extras": ["bits", "dead"], "gate": ["cm_grave_cross"]},
	# Desert.
	{"name": "Cactus maze", "biome": "desert", "wall": "props", "arts": ["ds_cactus_thin", "ds_cactus_s", "ds_cactus_thin"], "algo": "backtrack", "extras": ["bits", "reeds", "dead"], "gate": ["ds_tusk_s"], "zones": 0.18},
	{"name": "Rock maze", "biome": "desert", "wall": "props", "arts": ["ds_rock_s", "ds_rock_s", "ds_rock"], "algo": "kruskal", "braid": 0.15, "clearings": [["bones", 2, 2, "center"]], "extras": ["bits", "reeds", "dead"], "gate": ["ds_tusk_s"], "zones": 0.2},
	{"name": "Bone canyon", "biome": "desert", "wall": "props", "arts": ["ds_rock_s", "ds_cactus_s", "ds_rock_s"], "algo": "prim", "clearings": [["bones", 3, 2, "random"]], "extras": ["bits", "reeds", "dead"], "gate": ["ds_tusk_s"], "zones": 0.22},
	# Forge.
	{"name": "Forge halls", "biome": "forge", "wall": "kit", "kit": "forge", "algo": "backtrack", "clearings": [["lava", 3, 2, "center"]], "extras": ["bits", "dead"], "gate": ["fg_statue", "fg_statue_broken"]},
	{"name": "Lava channels", "biome": "forge", "wall": "pool", "pool": "lava", "algo": "kruskal", "braid": 0.3, "corridor": 2, "extras": ["bits", "dead"], "gate": ["fg_statue", "fg_statue_broken"]},
	{"name": "Foundry maze", "biome": "forge", "wall": "kit", "kit": "forge", "algo": "prim", "braid": 0.1, "clearings": [["statues", 3, 2, "random"], ["lava", 2, 2, "random"]], "extras": ["bits", "dead"], "gate": ["fg_statue", "fg_statue_broken"]},
	{"name": "Forge rings", "biome": "forge", "wall": "kit", "kit": "forge", "algo": "rings", "clearings": [["vault", 3, 2, "center"]], "extras": ["bits", "dead"], "gate": ["fg_statue", "fg_statue_broken"]},
	# Sewer.
	{"name": "Slime canals", "biome": "sewer", "wall": "pool", "pool": "slime", "algo": "backtrack", "corridor": 2, "extras": ["bits", "lamps", "dead"], "gate": ["sw_lamp"]},
	{"name": "Sewer junctions", "biome": "sewer", "wall": "pool", "pool": "slime", "algo": "kruskal", "braid": 0.35, "corridor": 2, "extras": ["planks", "bits", "lamps", "dead"], "gate": ["sw_lamp"]},
	{"name": "Overflow tunnels", "biome": "sewer", "wall": "pool", "pool": "slime", "algo": "prim", "braid": 0.15, "corridor": 3, "clearings": [["store", 2, 2, "random"]], "extras": ["planks", "bits", "lamps"], "gate": ["sw_lamp"]},
]

## The keys every maze shares (pc_terrain.gd reads the pipeline ones).
const BASE := {"braid": 0.0, "corridor": 1, "clearings": [], "extras": [], "zones": 0.3, "patches": [0, 0], "plateaus": [0, 0],
	"water": "none", "path": "none", "piece": "", "trees": ["", 0]}
const MARGIN_TREES := {"fairy": ["ff_mixed", 14], "green": ["fm_summer", 12], "cemetery": ["cm_mixed", 10], "desert": ["ds_cacti", 8]}
const FLOWERS := {"fairy": ["ff_flower", "ff_flower_b", "ff_flower_c", "ff_sprout", "ff_sprout_b"], "green": ["fm_flower", "fm_flower_b", "fm_flower_c", "fm_flower_d", "fm_flower_e"],
	"cemetery": ["cm_daisies", "cm_marigolds", "cm_leaves"], "desert": ["ds_tuft", "ds_tuft_b"], "forge": ["fg_rubble", "fg_rubble_b"], "sewer": ["sw_bottle", "sw_bottle_b"]}
const DEAD := {"fairy": ["ff_bell_big", "ff_rune_glow", "ff_stump"], "green": ["fm_rock", "fm_stump_s", "gw_rock"], "cemetery": ["cm_grave", "cm_grave_b", "cm_grave_slab", "cm_grave_cross"],
	"desert": ["ds_cactus_s", "ds_rock_s", "ds_bush"], "forge": ["fg_barrel", "fg_barrel_b", "fg_barrel_skull", "fg_barrel_water"], "sewer": ["sw_crate", "sw_barrel", "sw_crate_broken", "sw_barrel_broken"]}


static func recipes() -> Array:
	var out: Array = []
	for r in MAZE_RECIPES:
		var full: Dictionary = BASE.duplicate(true)
		full.merge(r, true)
		if full.wall == "kit" and not r.has("corridor"):
			full.corridor = 2 # walls two wide over their faces: rooms as wide
		if MARGIN_TREES.has(full.biome):
			full.trees = MARGIN_TREES[full.biome]
		if full.biome in ["forge", "sewer"]:
			full.zones = 0.0
		out.append(full)
	return out


var t # the PCTerrain being laid out
var r: Dictionary
var rng: RandomNumberGenerator
var kind := "kit"
var c_w := 2
var wt := 2 # a wall's thickness (vertical walls)
var hb := 4 # a horizontal wall's band (kit: two rows of top and the faces)
var step := Vector2i(4, 6)
var cols := 13
var rows := 6
var origin := Vector2i.ZERO
var size := Vector2i.ZERO
var open := {}
var clear_rooms := {}
var clearings: Array[Rect2i] = []
var walls := {} # wall cells (kit tops, channel or canal cells, prop walls' three-cell band)
var core := {} # prop walls' middle line
var faces := {} # kit faces
var corridors := {}
var entrance_row := 0
var exit_row := 0
var bridge_walls: Array[Vector3i] = []
var gates: Array[Vector2i] = []
var _prop_at := {}


func _init(p_t, p_rng: RandomNumberGenerator) -> void:
	t = p_t
	r = t.recipe
	rng = p_rng


func lay() -> bool:
	kind = r.wall
	c_w = r.corridor
	match kind:
		"kit":
			wt = 2
			hb = 2 + KITS[r.kit].face.m.size()
		"props":
			wt = 3
			hb = 3
		_:
			wt = 2
			hb = 2
	step = Vector2i(c_w + wt, c_w + hb)
	var margin := 4
	cols = (W - 2 * margin - wt) / step.x
	if kind == "kit":
		rows = (H - hb) / step.y
		size = Vector2i(cols * step.x + wt, rows * step.y + hb)
		origin = Vector2i((W - size.x) / 2, H - size.y)
	else:
		rows = (H - 2 * 3 - hb) / step.y
		size = Vector2i(cols * step.x + wt, rows * step.y + hb)
		origin = (Vector2i(W, H) - size) / 2
	if r.zones > 0.0:
		t._zones()
	_carve()
	_place_clearings()
	_braid(r.braid)
	entrance_row = rng.randi_range(0 if kind == "kit" else 1, rows - (1 if kind == "kit" else 2))
	exit_row = _farthest_east(entrance_row)
	match kind:
		"kit": _kit_walls()
		_: _grid_walls()
	_find_corridors()
	_paint()
	for key in bridge_walls:
		_bridge_over(key)
	_entrances()
	if not _fill_clearings():
		return false
	_extras()
	t.maze_info = {"entrance": t.spawn, "exit": t.goals[0], "corridors": corridors, "rooms": Vector2i(cols, rows),
		"dead_ends": _dead_ends().size(), "clearings": clearings.size(), "boxes": _boxes(), "drips": _drips()}
	return true


func unreached() -> Array[Vector2i]:
	var seen := {t.spawn: true}
	var queue: Array[Vector2i] = [t.spawn]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if seen.has(n) or not t.walkable(n):
				continue
			seen[n] = true
			queue.append(n)
	var out: Array[Vector2i] = []
	for c: Vector2i in corridors:
		if t.walkable(c) and not seen.has(c):
			out.append(c)
	for g in t.goals:
		if not seen.has(g):
			out.append(g)
	return out


# ---------------------------------------------------------------- the grid

func _room_px(i: int, j: int) -> Vector2i:
	return origin + Vector2i(wt + i * step.x, hb + j * step.y)


func _line_top(j: int) -> int:
	return origin.y + j * step.y


func _vline_x(i: int) -> int:
	return origin.x + i * step.x


func _clearing_px(rect: Rect2i) -> Rect2i:
	return Rect2i(_room_px(rect.position.x, rect.position.y), Vector2i(rect.size.x * step.x - wt, rect.size.y * step.y - hb))


func _neighbors(i: int, j: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if i + 1 < cols: out.append(Vector3i(i + 1, j, 0))
	if i > 0: out.append(Vector3i(i - 1, j, 1))
	if j + 1 < rows: out.append(Vector3i(i, j + 1, 2))
	if j > 0: out.append(Vector3i(i, j - 1, 3))
	return out


func _wall_key(i: int, j: int, ni: int, nj: int) -> Vector3i:
	if ni == i + 1: return Vector3i(i, j, 0)
	if ni == i - 1: return Vector3i(ni, nj, 0)
	if nj == j + 1: return Vector3i(i, j, 1)
	return Vector3i(ni, nj, 1)


func _links(i: int, j: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for n in _neighbors(i, j):
		if open.has(_wall_key(i, j, n.x, n.y)):
			out.append(Vector2i(n.x, n.y))
	return out


func _carve() -> void:
	open.clear()
	match r.algo:
		"prim": _prim()
		"kruskal": _kruskal()
		"sidewinder": _sidewinder()
		"rings": _rings()
		_: _backtrack()


func _backtrack() -> void:
	var start := Vector2i(0, rng.randi_range(0, rows - 1))
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	while not stack.is_empty():
		var c: Vector2i = stack.back()
		var next: Array[Vector2i] = []
		for n in _neighbors(c.x, c.y):
			if not seen.has(Vector2i(n.x, n.y)):
				next.append(Vector2i(n.x, n.y))
		if next.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = next[rng.randi() % next.size()]
		open[_wall_key(c.x, c.y, n.x, n.y)] = true
		seen[n] = true
		stack.append(n)


func _prim() -> void:
	var start := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
	var inside := {start: true}
	var edges: Array = []
	for n in _neighbors(start.x, start.y):
		edges.append([start, Vector2i(n.x, n.y)])
	while not edges.is_empty():
		var k := rng.randi() % edges.size()
		var e: Array = edges[k]
		edges[k] = edges.back()
		edges.pop_back()
		var b: Vector2i = e[1]
		if inside.has(b):
			continue
		var a: Vector2i = e[0]
		open[_wall_key(a.x, a.y, b.x, b.y)] = true
		inside[b] = true
		for n in _neighbors(b.x, b.y):
			if not inside.has(Vector2i(n.x, n.y)):
				edges.append([b, Vector2i(n.x, n.y)])


func _kruskal() -> void:
	var parent := {}
	for j in rows:
		for i in cols:
			parent[Vector2i(i, j)] = Vector2i(i, j)
	var find := func(x: Vector2i) -> Vector2i:
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x
	var keys: Array[Vector3i] = []
	for j in rows:
		for i in cols:
			if i + 1 < cols: keys.append(Vector3i(i, j, 0))
			if j + 1 < rows: keys.append(Vector3i(i, j, 1))
	for k in range(keys.size() - 1, 0, -1):
		var s := rng.randi_range(0, k)
		var tmp := keys[k]
		keys[k] = keys[s]
		keys[s] = tmp
	for key in keys:
		var a := Vector2i(key.x, key.y)
		var b := a + (Vector2i(1, 0) if key.z == 0 else Vector2i(0, 1))
		var ra: Vector2i = find.call(a)
		var rb: Vector2i = find.call(b)
		if ra != rb:
			parent[ra] = rb
			open[key] = true


func _sidewinder() -> void:
	for j in rows:
		var run_start := 0
		for i in cols:
			if j == 0:
				if i + 1 < cols:
					open[Vector3i(i, j, 0)] = true
				continue
			if i == cols - 1 or rng.randf() < 0.4:
				var k := rng.randi_range(run_start, i)
				open[Vector3i(k, j - 1, 1)] = true
				run_start = i + 1
			else:
				open[Vector3i(i, j, 0)] = true


func _rings() -> void:
	var depth := mini(cols, rows) / 2
	var ring_of := func(i: int, j: int) -> int:
		return mini(mini(i, j), mini(cols - 1 - i, rows - 1 - j))
	for j in rows:
		for i in cols:
			var k: int = ring_of.call(i, j)
			for n in _neighbors(i, j):
				if n.z in [1, 3]:
					continue
				if ring_of.call(n.x, n.y) == k:
					open[_wall_key(i, j, n.x, n.y)] = true
	for k in depth:
		var ring_keys: Array[Vector3i] = []
		for key in open.keys():
			if ring_of.call(key.x, key.y) == k:
				ring_keys.append(key)
		if ring_keys.size() > 2:
			open.erase(ring_keys[rng.randi() % ring_keys.size()])
		var doors: Array[Vector3i] = []
		for j in rows:
			for i in cols:
				if ring_of.call(i, j) != k:
					continue
				for n in _neighbors(i, j):
					if ring_of.call(n.x, n.y) == k + 1:
						doors.append(_wall_key(i, j, n.x, n.y))
		if not doors.is_empty():
			open[doors[rng.randi() % doors.size()]] = true
	_join_islands()


func _join_islands() -> void:
	var seen := {Vector2i(0, 0): true}
	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	while true:
		while not queue.is_empty():
			var c: Vector2i = queue.pop_back()
			for l in _links(c.x, c.y):
				if not seen.has(l):
					seen[l] = true
					queue.append(l)
		if seen.size() == cols * rows:
			return
		var joined := false
		for j in rows:
			for i in cols:
				if seen.has(Vector2i(i, j)) or joined:
					continue
				for n in _neighbors(i, j):
					if seen.has(Vector2i(n.x, n.y)):
						open[_wall_key(i, j, n.x, n.y)] = true
						seen[Vector2i(i, j)] = true
						queue.append(Vector2i(i, j))
						joined = true
						break
		if not joined:
			return


func _dead_ends() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for j in rows:
		for i in cols:
			if clear_rooms.has(Vector2i(i, j)):
				continue
			if _links(i, j).size() == 1:
				out.append(Vector2i(i, j))
	return out


## Opens a share of the dead ends into loops; on canals with stepping stones
## and on the sewer's channels with planks, most of them cross the water.
func _braid(share: float) -> void:
	if share <= 0.0:
		return
	var crossable: bool = kind == "canal" or (kind == "pool" and "planks" in r.extras)
	for d in _dead_ends():
		if rng.randf() >= share:
			continue
		var shut: Array[Vector2i] = []
		for n in _neighbors(d.x, d.y):
			if not open.has(_wall_key(d.x, d.y, n.x, n.y)):
				shut.append(Vector2i(n.x, n.y))
		if shut.is_empty():
			continue
		var n: Vector2i = shut[rng.randi() % shut.size()]
		var key := _wall_key(d.x, d.y, n.x, n.y)
		if crossable and rng.randf() < 0.7:
			bridge_walls.append(key)
		else:
			open[key] = true


func _farthest_east(from_row: int) -> int:
	var dist := {Vector2i(0, from_row): 0}
	var queue: Array[Vector2i] = [Vector2i(0, from_row)]
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for l in _links(c.x, c.y):
			if not dist.has(l):
				dist[l] = dist[c] + 1
				queue.append(l)
	var best := rows / 2
	var bd := -1
	var lo := 0 if kind == "kit" else 1
	var hi := rows - (1 if kind == "kit" else 2)
	for j in range(lo, hi + 1):
		var d: int = dist.get(Vector2i(cols - 1, j), -1)
		if d > bd:
			bd = d
			best = j
	return best


func _place_clearings() -> void:
	clearings.clear()
	clear_rooms.clear()
	for spec in r.clearings:
		var cw: int = spec[1]
		var ch: int = spec[2]
		var where: String = spec[3]
		for tries in 40:
			var at: Vector2i
			match where:
				"center": at = Vector2i((cols - cw) / 2, (rows - ch) / 2)
				_: at = Vector2i(rng.randi_range(1, cols - cw - 1), rng.randi_range(0, rows - ch))
			var rect := Rect2i(at, Vector2i(cw, ch))
			if rect.end.x > cols or rect.end.y > rows:
				continue
			var free := true
			for other in clearings:
				if other.grow(1).intersects(rect):
					free = false
			if not free:
				if where == "center":
					break
				continue
			clearings.append(rect)
			for j in range(rect.position.y, rect.end.y):
				for i in range(rect.position.x, rect.end.x):
					clear_rooms[Vector2i(i, j)] = clearings.size() - 1
					if i + 1 < rect.end.x:
						open[Vector3i(i, j, 0)] = true
					if j + 1 < rect.end.y:
						open[Vector3i(i, j, 1)] = true
			break


# ---------------------------------------------------------------- walls

## Canal, channel, and prop walls: the maze's rectangle, then the open cells
## (rooms, opened walls, pillars inside a clearing, the gates) taken out.
func _grid_walls() -> void:
	walls.clear()
	for y in size.y:
		for x in size.x:
			walls[origin + Vector2i(x, y)] = true
	for j in rows:
		for i in cols:
			var p := _room_px(i, j)
			_open_rect(Rect2i(p, Vector2i(c_w, c_w)))
			if open.has(Vector3i(i, j, 0)):
				_open_rect(Rect2i(p + Vector2i(c_w, 0), Vector2i(wt, c_w)))
			if open.has(Vector3i(i, j, 1)):
				_open_rect(Rect2i(p + Vector2i(0, c_w), Vector2i(c_w, hb)))
			var k: int = clear_rooms.get(Vector2i(i, j), -1)
			if k >= 0 and clear_rooms.get(Vector2i(i + 1, j), -1) == k and clear_rooms.get(Vector2i(i, j + 1), -1) == k \
					and clear_rooms.get(Vector2i(i + 1, j + 1), -1) == k:
				_open_rect(Rect2i(p + Vector2i(c_w, c_w), Vector2i(wt, hb)))
	_open_rect(Rect2i(Vector2i(origin.x, _room_px(0, entrance_row).y), Vector2i(wt, c_w)))
	_open_rect(Rect2i(Vector2i(origin.x + size.x - wt, _room_px(0, exit_row).y), Vector2i(wt, c_w)))
	if kind == "props":
		core.clear()
		for c: Vector2i in walls:
			var all := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if not walls.has(c + Vector2i(dx, dy)):
						all = false
			if all:
				core[c] = true
		for c: Vector2i in walls.keys():
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if core.has(c + Vector2i(dx, dy)):
						near = true
			if not near:
				walls.erase(c)


func _open_rect(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			walls.erase(Vector2i(x, y))


## Kit walls: the black tops (the top band and the bottom one across the map,
## the horizontal walls but their gaps, the pillars outside clearings, the
## vertical walls still standing); the faces come under every bottom edge.
func _kit_walls() -> void:
	walls.clear()
	for y in range(0, origin.y + 2):
		for x in W:
			walls[Vector2i(x, y)] = true
	for x in W:
		for k in 2:
			walls[Vector2i(x, _line_top(rows) + k)] = true
	for j in range(1, rows):
		var y := _line_top(j)
		for x in range(origin.x, origin.x + size.x):
			walls[Vector2i(x, y)] = true
			walls[Vector2i(x, y + 1)] = true
		for i in cols:
			if open.has(Vector3i(i, j - 1, 1)):
				var p := _room_px(i, j)
				for x in c_w:
					for k in 2:
						walls.erase(Vector2i(p.x + x, y + k))
	for j in range(1, rows):
		for i in range(1, cols):
			var k: int = clear_rooms.get(Vector2i(i - 1, j - 1), -1)
			if k >= 0 and clear_rooms.get(Vector2i(i, j - 1), -1) == k and clear_rooms.get(Vector2i(i - 1, j), -1) == k \
					and clear_rooms.get(Vector2i(i, j), -1) == k:
				for dx in wt:
					for dy in 2:
						walls.erase(Vector2i(_vline_x(i) + dx, _line_top(j) + dy))
	for j in rows:
		for i in cols + 1:
			var shut := true
			if i == 0:
				shut = j != entrance_row
			elif i == cols:
				shut = j != exit_row
			else:
				shut = not open.has(Vector3i(i - 1, j, 0))
			if not shut:
				continue
			for y in range(_line_top(j) + 2, _line_top(j + 1)):
				for dx in wt:
					walls[Vector2i(_vline_x(i) + dx, y)] = true


func _find_corridors() -> void:
	corridors.clear()
	var y0 := _line_top(0) + hb if kind == "kit" else origin.y
	var y1 := _line_top(rows) if kind == "kit" else origin.y + size.y
	for y in range(y0, y1):
		for x in range(origin.x, origin.x + size.x):
			var c := Vector2i(x, y)
			if not walls.has(c) and not faces.has(c):
				corridors[c] = true


func _mask(c: Vector2i, cells: Dictionary) -> int:
	var m := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = c + dirs[i]
		if cells.has(n) or not t._inside(n):
			m |= 1 << i
	return m


func _paint() -> void:
	match kind:
		"kit": _paint_kit()
		"canal":
			var cells: Array[Vector2i] = []
			for c: Vector2i in walls:
				t.water[c] = true
				t.kind[t._i(c)] = t.WATER
				t._taken[c] = true
				cells.append(c)
			t._lock_round(cells)
			t.ponds.append(Rect2i(origin, size))
		"pool": _paint_pool(walls)
		"props": _paint_props()
	for c: Vector2i in corridors:
		t._taken[c] = true


func _paint_kit() -> void:
	var kit: Dictionary = KITS[r.kit]
	faces.clear()
	for c: Vector2i in walls:
		var m := _mask(c, walls)
		var a: Vector2i = kit.c
		match m:
			15:
				if _open(c + Vector2i(-1, -1)): a = kit.in_nw
				elif _open(c + Vector2i(1, -1)): a = kit.in_ne
				elif _open(c + Vector2i(-1, 1)): a = kit.in_sw
				elif _open(c + Vector2i(1, 1)): a = kit.in_se
			14: a = kit.t
			11: a = kit.b
			7: a = kit.l
			13: a = kit.r
			6: a = kit.tl
			12: a = kit.tr
			3: a = kit.bl
			9: a = kit.br
		t.wall_tiles[c] = a
		t.kind[t._i(c)] = t.CLIFF
		t._taken[c] = true
	var rows_f: int = kit.face.m.size()
	for c: Vector2i in walls:
		var below := c + Vector2i.DOWN
		if not t._inside(below) or walls.has(below):
			continue
		var west: bool = walls.has(c + Vector2i.LEFT) or c.x == 0
		var east: bool = walls.has(c + Vector2i.RIGHT) or c.x == W - 1
		var col: String = "m" if west and east else ("l" if not west else "r")
		for d in rows_f:
			var f := c + Vector2i(0, 1 + d)
			if not t._inside(f) or walls.has(f):
				break
			faces[f] = true
			t.wall_tiles[f] = kit.face[col][d]
			t.kind[t._i(f)] = t.CLIFF
			t._taken[f] = true


func _open(c: Vector2i) -> bool:
	return t._inside(c) and not walls.has(c)


## An animated channel (lava, slime): each cell's tile by which of its eight
## neighbours are floor; its cells block (kind WATER), not water to paint.
func _paint_pool(cells: Dictionary) -> void:
	var p: Dictionary = POOLS[r.get("pool", "lava")]
	for c: Vector2i in cells:
		var a := _pool_tile(c, cells, p)
		t.pool_tiles[c] = a
		t.kind[t._i(c)] = t.WATER
		t._taken[c] = true


func _pool_tile(c: Vector2i, cells: Dictionary, p: Dictionary) -> Vector2i:
	var b: Vector2i = p.blob
	var g: Vector2i = p.ring
	var land := func(o: Vector2i) -> bool: return t._inside(c + o) and not cells.has(c + o)
	var n: bool = land.call(Vector2i.UP)
	var s: bool = land.call(Vector2i.DOWN)
	var w: bool = land.call(Vector2i.LEFT)
	var e: bool = land.call(Vector2i.RIGHT)
	if n and w: return b
	if n and e: return b + Vector2i(2, 0)
	if s and w: return b + Vector2i(0, 2)
	if s and e: return b + Vector2i(2, 2)
	if n: return b + Vector2i(1, 0)
	if s: return b + Vector2i(1, 2)
	if w: return b + Vector2i(0, 1)
	if e: return b + Vector2i(2, 1)
	if land.call(Vector2i(1, 1)): return g # floor at the south-east diagonal
	if land.call(Vector2i(-1, 1)): return g + Vector2i(2, 0)
	if land.call(Vector2i(1, -1)): return g + Vector2i(0, 2)
	if land.call(Vector2i(-1, -1)): return g + Vector2i(2, 2)
	return b + Vector2i(1, 1)


func _paint_props() -> void:
	var arts: Array = r.arts
	for c: Vector2i in walls:
		t.blocked[c] = true
		t._taken[c] = true
		# Root ground under the wall (desert props stand on light sand only).
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			t._set_corner(c.x + o.x, c.y + o.y, t.biome.root)
	for c: Vector2i in core:
		var art: String = arts[(c.x * 3 + c.y * 5) % arts.size()]
		t.props.append({"art": art, "cell": c, "nudge": Vector2(0, 8)})
		_prop_at[c] = true


## A crossing over a braid's water: stepping stones over a canal, a plank
## bridge over a sewer channel.
func _bridge_over(key: Vector3i) -> void:
	var p := _room_px(key.x, key.y)
	var cells: Array[Vector2i] = []
	if key.z == 0:
		for x in wt:
			for y in c_w:
				cells.append(p + Vector2i(c_w + x, y))
	else:
		for y in hb:
			for x in c_w:
				cells.append(p + Vector2i(x, c_w + y))
	for c in cells:
		if not walls.has(c):
			continue
		t.stones[c] = true
		corridors[c] = true
	if kind == "pool":
		# The planks lie over the channel, centred on it, their ends on the
		# banks (a prop stands on its foot: the bottom middle of its cell).
		var art := "sw_planks" if key.z == 0 else "sw_planks_v"
		var rect: Rect2i = PCTerrain.prop(art).rect
		var mid := Vector2(p) * TILE + (Vector2(c_w + wt / 2.0, c_w / 2.0) if key.z == 0 else Vector2(c_w / 2.0, c_w + hb / 2.0)) * TILE
		var foot := mid + Vector2(0, rect.size.y / 2.0 - 2)
		var cell := Vector2i(floori(foot.x / TILE), floori(foot.y / TILE))
		t.props.append({"art": art, "cell": cell, "nudge": foot - (Vector2(cell * TILE) + Vector2(TILE / 2.0, TILE - 1))})


## Quarters of the prop walls' half cells (and the middle whole) where the
## props are drawn.
func _boxes() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if kind != "props":
		return out
	var corners := {}
	for c: Vector2i in core:
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			corners[c + o] = true
	for c: Vector2i in walls:
		if core.has(c):
			out.append(Rect2(c * TILE, Vector2(TILE, TILE)))
			continue
		var q := [corners.has(c), corners.has(c + Vector2i(1, 0)), corners.has(c + Vector2i(0, 1)), corners.has(c + Vector2i(1, 1))]
		var half := TILE / 2.0
		for row in 2:
			var a: bool = q[row * 2]
			var b: bool = q[row * 2 + 1]
			var py := c.y * TILE + row * half
			if a and b:
				out.append(Rect2(c.x * TILE, py, TILE, half))
			elif a:
				out.append(Rect2(c.x * TILE, py, half, half))
			elif b:
				out.append(Rect2(c.x * TILE + half, py, half, half))
	return out


## Drips from the kit faces: two per face cell over floor (CaveLife).
func _drips() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c: Vector2i in faces:
		if faces.has(c + Vector2i.DOWN) or not t._inside(c + Vector2i.DOWN) or t.kind[t._i(c + Vector2i.DOWN)] != t.OPEN:
			continue
		for i in 2:
			var px := c.x * TILE + 3 + absi(hash(Vector3i(c.x, c.y, i))) % 10
			out.append({"top": Vector2(px, (c.y - 1) * TILE + 6), "floor": Vector2(px, (c.y + 1) * TILE + 2), "water": false})
	return out


# ---------------------------------------------------------------- gates

func _entrances() -> void:
	var gate: Array = r.gate
	for k in 2:
		var j := entrance_row if k == 0 else exit_row
		var p := _room_px(0, j)
		var west := k == 0
		var x_out := origin.x - 1 if west else origin.x + size.x
		gates.append(Vector2i(x_out, p.y))
		# Markers either side of the gap, outside the wall (a row in when the
		# top band's face stands there).
		var mx := x_out - (1 if west else -1)
		if not _put(gate[0], Vector2i(mx, p.y - 1), Rect2i(), true):
			_put(gate[0], Vector2i(mx - (1 if west else -1), p.y), Rect2i(), true)
		_put(gate[gate.size() - 1], Vector2i(mx, p.y + c_w), Rect2i(), true)
		# Keep the approach clear of trees and scatter.
		t._claim(Rect2i(Vector2i(x_out - 5 if west else x_out, p.y - 3), Vector2i(6, c_w + 5)))
	t.spawn = Vector2i(1, _room_px(0, entrance_row).y + c_w - 1)
	t.goals.assign([Vector2i(W - 2, _room_px(0, exit_row).y + c_w - 1)])
	for c in [t.spawn, t.goals[0]]:
		t._taken[c] = true


# ---------------------------------------------------------------- props

## A prop of the maze's on free floor, its collider row only inside `within`
## (a clearing inside its lane, a dead end's room) or outside the maze;
## `force` places it on cells the antechamber keeps clear.
func _put(art: String, cell: Vector2i, within: Rect2i, force := false, allow_block := true) -> bool:
	var p: Dictionary = PCTerrain.prop(art)
	if not t._inside(cell) or t.kind[t._i(cell)] != t.OPEN or t.blocked.has(cell) or t.stones.has(cell) or _prop_at.has(cell) or cell == t.spawn:
		return false
	if p.block != Vector2.ZERO and not allow_block:
		return false
	if p.has("on") and t.sig(cell) != String(p.on).repeat(4):
		return false
	var rr := PCTerrain.collider_cells(cell, p)
	for x in range(rr.position.x, rr.end.x):
		var c := Vector2i(x, cell.y)
		if p.block == Vector2.ZERO:
			continue
		if not t._inside(c) or t.kind[t._i(c)] != t.OPEN or t.blocked.has(c) or c == t.spawn or (t.goals.size() > 0 and c == t.goals[0]):
			return false
		if corridors.has(c) and not within.has_point(c):
			return false
	t.props.append({"art": art, "cell": cell})
	_prop_at[cell] = true
	t._taken[cell] = true
	if p.block != Vector2.ZERO:
		for x in range(rr.position.x, rr.end.x):
			t.blocked[Vector2i(x, cell.y)] = true
	return true


func _near(arts: Array, count: int, center: Vector2i, radius: int, within: Rect2i, allow_block := true) -> int:
	var placed := 0
	for i in count * 30:
		if placed >= count:
			break
		var c := center + Vector2i(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))
		if within.has_point(c) and _put(arts[rng.randi() % arts.size()], c, within, false, allow_block):
			placed += 1
	return placed


# ---------------------------------------------------------------- clearings

func _fill_clearings() -> bool:
	for n in clearings.size():
		var spec: Array = r.clearings[n]
		var px := _clearing_px(clearings[n])
		var inner := px.grow(-1)
		var mid := inner.position + inner.size / 2
		match spec[0]:
			"bells":
				_near(["ff_bell_big", "ff_bell_big_b"], 1, mid, 1, inner)
				_near(["ff_bell", "ff_bell_b", "ff_bell_s", "ff_bell_xs", "ff_mush", "ff_mush_s"], 5, mid, 3, px, false)
			"mushrooms":
				_near(["ff_mush_big", "ff_mush", "ff_mush_s", "ff_mush_xs", "ff_fern", "ff_fern_b"], 7, mid, 3, px, false)
				_near(["ff_stump"], 1, mid, 1, inner)
			"runes":
				var nr := 6
				for k in nr:
					var ang := TAU * k / nr
					var c := mid + Vector2i(roundi(cos(ang) * minf(4.0, inner.size.x / 2.0 - 1.0)), roundi(sin(ang) * minf(2.0, inner.size.y / 2.0 - 1.0)))
					_put(["ff_rune_glow", "ff_rune"][k % 2] if k % 2 == 0 else "ff_bell_s", c, inner)
				_near(["ff_flower", "ff_flower_b", "ff_flower_c"], 4, mid, 3, px, false)
			"camp":
				_near(["gw_crate", "gw_barrels"], 2, mid, 2, inner)
				_near(["fm_log", "fm_stump_s"], 1, mid, 2, inner)
				_near(["fm_mush", "fm_fern", "fm_flower"], 3, mid, 3, px, false)
			"crystals":
				_near(["fm_crystal"], 2, mid, 2, inner)
				_near(["fm_rock_tall", "fm_stone"], 2, mid, 2, inner)
			"graves":
				for j in range(inner.position.y + 1, inner.end.y, 2):
					for i in range(inner.position.x + 1, inner.end.x - 1, 2):
						_put(["cm_grave", "cm_grave_b", "cm_grave_slab", "cm_grave_cross"][(i + j) % 4], Vector2i(i, j), inner)
				_near(["cm_daisies", "cm_marigolds", "cm_thorn"], 4, mid, 3, px, false)
			"deadwood":
				_near(["cm_dead_s", "cm_birch_bare_s"], 1, mid, 1, inner)
				_near(["cm_twigs", "cm_thorn", "cm_thorn_b", "cm_leaves"], 4, mid, 3, px, false)
			"bones":
				_near(["ds_tusk", "ds_tusk_b", "ds_tusk_s"], 2, mid, 2, inner)
				_near(["ds_tuft", "ds_tuft_b"], 3, mid, 3, px, false)
			"statues":
				_near(["fg_statue", "fg_statue_broken"], 2, mid, 2, inner)
				_near(["fg_chest"], 1, mid, 2, inner)
			"vault":
				_near(["fg_chest", "fg_chest_open"], 2, mid, 2, inner)
				_near(["fg_rack", "fg_rack_b"], 1, mid, 2, inner)
				_near(["fg_barrel", "fg_barrel_skull"], 2, mid, 3, inner)
			"lava":
				var pool := {}
				for c in _cells(inner.grow(-1)):
					pool[c] = true
				if pool.size() < 4:
					return false
				_paint_pool_cells(pool, "lava")
			"store":
				_near(["sw_crate", "sw_barrel", "sw_chest"], 3, mid, 2, inner)
				_near(["sw_lamp", "sw_lantern", "sw_bottle"], 2, mid, 3, px, false)
	return true


func _paint_pool_cells(cells: Dictionary, which: String) -> void:
	var p: Dictionary = POOLS[which]
	for c: Vector2i in cells:
		t.pool_tiles[c] = _pool_tile(c, cells, p)
		t.kind[t._i(c)] = t.WATER


func _cells(rect: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			out.append(Vector2i(x, y))
	return out


# ---------------------------------------------------------------- extras

func _room_rect(d: Vector2i) -> Rect2i:
	return Rect2i(_room_px(d.x, d.y), Vector2i(c_w, c_w))


func _extras() -> void:
	var ex: Array = r.extras
	var b: String = r.biome
	var keys: Array = corridors.keys()
	keys.sort()
	var pools := 0
	if b == "forge" and kind == "kit":
		# Lava welling up at the end of some dead ends (never by a gate): it
		# glows and moves where the halls are otherwise still.
		for d in _dead_ends():
			if pools >= 6 or (d.x == 0 and d.y == entrance_row) or (d.x == cols - 1 and d.y == exit_row):
				continue
			var room := _room_rect(d)
			var cells := {}
			var free := true
			for c in _cells(room):
				cells[c] = true
				if _prop_at.has(c):
					free = false
			if free and rng.randf() < 0.7:
				_paint_pool_cells(cells, "lava")
				for c in cells:
					t._taken[c] = true
				pools += 1
	if "bits" in ex:
		var bits: Array = PCTerrain.SCATTER.get(b, [[], FLOWERS[b]])[1]
		for k in (12 if b in ["forge", "sewer"] else 34):
			_put(bits[rng.randi() % bits.size()], keys[rng.randi() % keys.size()], Rect2i(), false, false)
	if "flowers" in ex:
		for k in 20:
			_put(FLOWERS[b][rng.randi() % FLOWERS[b].size()], keys[rng.randi() % keys.size()], Rect2i(), false, false)
	if "glow" in ex:
		for k in 8:
			_put(["ff_bell_s", "ff_bell_xs", "ff_bell"][rng.randi() % 3], keys[rng.randi() % keys.size()], Rect2i(), false, false)
	if "reeds" in ex:
		# Desert reeds and tufts along the corridors (they nod in the wind).
		for k in 16:
			_put(["ds_reeds", "ds_tuft", "ds_tuft_b"][rng.randi() % 3], keys[rng.randi() % keys.size()], Rect2i(), false, false)
	if "lamps" in ex:
		for k in 10:
			_put(["sw_lamp", "sw_lantern"][rng.randi() % 2], keys[rng.randi() % keys.size()], Rect2i(), false, false)
	if "dead" in ex:
		var n := 0
		for d in _dead_ends():
			if n >= 8 or rng.randf() < 0.3 or t.pool_tiles.has(_room_rect(d).position):
				continue
			var room := _room_rect(d)
			if _put(DEAD[b][rng.randi() % DEAD[b].size()], room.position + _far_corner(d), room):
				n += 1


func _far_corner(d: Vector2i) -> Vector2i:
	var l: Vector2i = _links(d.x, d.y)[0] - d
	var x := 0 if l.x > 0 else c_w - 1
	var y := 0 if l.y > 0 else c_w - 1
	if l.x != 0:
		y = rng.randi_range(0, c_w - 1)
	else:
		x = rng.randi_range(0, c_w - 1)
	return Vector2i(x, y)


# ---------------------------------------------------------------- liveliness

## An anchor for a weak window: something that glows or moves in one of its
## corridors (a glowbell, a lamp) where the biome has one; the caller adds
## fireflies otherwise.
func floor_anchor(rect: Rect2i) -> bool:
	var arts: Array = {"fairy": ["ff_bell", "ff_bell_b", "ff_bell_s"], "sewer": ["sw_lamp", "sw_lantern"]}.get(r.biome, [])
	if arts.is_empty():
		return false
	var cells: Array = corridors.keys().filter(func(c): return rect.grow(-2).has_point(c))
	cells.sort()
	var put := 0
	for k in 20:
		if put >= 3 or cells.is_empty():
			break
		if _put(arts[rng.randi() % arts.size()], cells[rng.randi() % cells.size()], Rect2i(), false, false):
			put += 1
	return put > 0
