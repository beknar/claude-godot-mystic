class_name FarmMaze
extends RefCounted
## maze-farm: mazes on antarcticbees' Farm - 4 Seasons sheets (one season per
## map), laid into a FarmTerrain (farm_terrain.gd with `maze` on) so the rest
## of the Farm pipeline paints and fills them as any farm map: grass tones,
## deco, the trees and bushes round the edge, the ambience, the Cozy Farm
## animals, the buildings and their interiors.
##
## A maze is a grid of rooms, each a corridor C cells wide, the walls between
## them three cells thick round a middle line (the wall's core):
##   hedge, wheat, tall    the sheet's overlay blobs (hedge; golden wheat; tall
##                         green grass), their corners
##                         on the core cells, so a wall draws one full cell
##                         with a half cell either side (the overlay's edge
##                         runs down the middle of a cell) and collides
##                         where it is drawn;
##   corn, sunflower       a row of the crop on dirt (the core cells), the
##                         dirt's edge on the half cells; the crops nod in
##                         the wind and bend away from the walker beside them;
##   bush, pine            winter (and summer shrub) bushes standing along the
##                         core, a round or a pine bush on every cell (they
##                         overlap into one hedge), drawn half a cell low so
##                         they sit centred on it;
## or two cells thick of water (canals), laid in the sheet's 2 x 2 water
## blocks so every shore cell has a tile; braids cross them on bridges.
## A maze algorithm decides which walls come down; every room is reachable
## from the entrance (a spanning tree, plus loops where the type braids).
## Some types merge rooms into clearings (a farmhouse, the barn, the windmill,
## the greenhouse, a pen with its herd, a pond, a crop patch, an orchard,
## hay, a scarecrow, a meadow). The entrance is a gap in the west wall, the
## exit one in the east wall (the room there farthest from the entrance),
## each with a road in from the map's edge, a barrel or hay either side, and
## a signpost (two different signs).
##
## Recipe keys (MAZE_RECIPES): season (summer, autumn, winter: the sheet for
## the whole map); wall (above); algo "backtrack" | "prim" | "kruskal" |
## "sidewinder" | "rings"; braid (share of dead ends opened into loops);
## corridor (cells; even on the canals); floor "lawn" | "path"; clearings:
## [[kind, rooms wide, rooms tall, where, arg]]; extras: wall_trees,
## fruit_trees, flowers, pots, clutter, bunches, scarecrows, reeds, bridges,
## moat. Plus the farm keys the rest of the pipeline reads (trees, zones,
## pale, ground).

const W := FarmTerrain.W
const H := FarmTerrain.H
const TILE := 16
const BUILDING_KINDS := ["farmhouse", "farmhouse_b", "manor", "barn", "greenhouse", "windmill"]

const MAZE_RECIPES := [
	# Spring and summer.
	{"name": "Hedgerow maze", "wall": "hedge", "algo": "backtrack", "extras": ["wall_trees", "flowers"]},
	{"name": "Branching hedgerows", "wall": "hedge", "algo": "prim", "braid": 0.1, "clearings": [["pond", 3, 3, "center"]], "extras": ["flowers", "wall_trees", "reeds"]},
	{"name": "Looping hedges", "wall": "hedge", "algo": "kruskal", "braid": 0.45, "clearings": [["hay", 2, 2, "random"]], "extras": ["wall_trees", "pots", "flowers"]},
	{"name": "Farmhouse maze", "wall": "hedge", "algo": "backtrack", "braid": 0.1, "clearings": [["farmhouse", 3, 3, "center"]], "extras": ["wall_trees", "pots", "flowers"]},
	{"name": "Windmill in the wheat", "wall": "wheat", "algo": "prim", "braid": 0.1, "clearings": [["windmill", 3, 3, "center"]], "extras": ["bunches", "flowers"], "pale": 0.18},
	{"name": "Wheat maze", "wall": "wheat", "algo": "backtrack", "clearings": [["hay", 2, 2, "random"]], "extras": ["bunches", "scarecrows", "flowers"], "pale": 0.2},
	{"name": "Golden rings", "wall": "wheat", "algo": "rings", "clearings": [["field", 3, 3, "center", "pumpkin"]], "extras": ["bunches", "flowers"], "pale": 0.18},
	{"name": "Corn maze", "wall": "corn", "algo": "backtrack", "clearings": [["scarecrow", 2, 2, "center"]], "extras": ["scarecrows", "flowers"]},
	{"name": "Maize loops", "wall": "corn", "algo": "kruskal", "braid": 0.3, "clearings": [["field", 3, 3, "random", "pumpkin"]], "extras": ["scarecrows", "bunches"]},
	{"name": "Sunflower maze", "wall": "sunflower", "algo": "prim", "braid": 0.1, "clearings": [["hay", 2, 2, "center"]], "extras": ["flowers", "bunches"], "pale": 0.18},
	{"name": "Meadow grass maze", "wall": "tall", "algo": "sidewinder", "braid": 0.1, "clearings": [["meadow", 2, 2, "random"], ["meadow", 2, 2, "random"]], "extras": ["flowers"], "zones": 0.75, "pale": 0.0}, # the pale grass walls on dark grass
	{"name": "Barnyard maze", "wall": "hedge", "algo": "kruskal", "braid": 0.15, "clearings": [["barn", 3, 3, "west"], ["pen", 3, 3, "east"]], "extras": ["wall_trees", "clutter"]},
	{"name": "Pasture maze", "wall": "hedge", "algo": "kruskal", "braid": 0.3, "clearings": [["pen", 4, 3, "west"], ["pen", 4, 3, "east"]], "extras": ["wall_trees", "flowers"]},
	{"name": "Orchard maze", "wall": "hedge", "algo": "backtrack", "braid": 0.1, "clearings": [["orchard", 3, 3, "center", "mixed_fruit"]], "extras": ["fruit_trees", "flowers"]},
	{"name": "Kitchen garden maze", "wall": "hedge", "algo": "prim", "clearings": [["field", 2, 2, "west", "cabbage"], ["field", 2, 2, "east", "carrot"]], "extras": ["pots", "flowers", "wall_trees"]},
	{"name": "Greenhouse maze", "wall": "hedge", "algo": "rings", "floor": "path", "ground": "s", "clearings": [["greenhouse", 3, 3, "center"]], "extras": ["pots", "wall_trees", "wall_trees"]},
	{"name": "Canal maze", "wall": "water", "algo": "backtrack", "corridor": 2, "extras": ["reeds", "flowers"]},
	{"name": "Bridge canals", "wall": "water", "algo": "kruskal", "braid": 0.4, "corridor": 2, "extras": ["bridges", "reeds", "flowers"]},
	{"name": "Mill canals", "wall": "water", "algo": "prim", "braid": 0.15, "corridor": 2, "clearings": [["windmill", 3, 3, "center"]], "extras": ["bridges", "reeds"]},
	{"name": "Moated farmhouse", "wall": "hedge", "algo": "kruskal", "braid": 0.1, "clearings": [["farmhouse_b", 3, 3, "center"]], "extras": ["moat", "wall_trees", "pots"]},
	{"name": "Shrub maze", "wall": "bush", "algo": "backtrack", "braid": 0.15, "clearings": [["pond", 3, 3, "center"]], "extras": ["flowers", "reeds"]},
	# Autumn (farm_autumn.png): brown hedges, straw, the harvest.
	{"name": "Autumn hedgerows", "season": "autumn", "wall": "hedge", "algo": "backtrack", "extras": ["wall_trees", "wall_trees", "flowers"], "zones": 0.08, "pale": 0.3}, # brown hedges on pale grass
	{"name": "Autumn sunflowers", "season": "autumn", "wall": "sunflower", "algo": "prim", "clearings": [["hay", 2, 2, "center"]], "extras": ["bunches", "scarecrows"]},
	{"name": "Harvest corn maze", "season": "autumn", "wall": "corn", "algo": "kruskal", "braid": 0.2, "clearings": [["field", 3, 3, "center", "pumpkin"]], "extras": ["scarecrows", "bunches"]},
	{"name": "Autumn homestead maze", "season": "autumn", "wall": "hedge", "algo": "kruskal", "braid": 0.15, "clearings": [["farmhouse", 3, 3, "west"], ["pen", 3, 3, "east"]], "extras": ["wall_trees", "clutter"], "zones": 0.08, "pale": 0.3},
	{"name": "Russet canals", "season": "autumn", "wall": "water", "algo": "kruskal", "braid": 0.35, "corridor": 2, "clearings": [["barn", 3, 3, "center"]], "extras": ["bridges", "reeds"]},
	# Winter (farm_winter.png): canals, snowy bushes, no crops or overlays.
	{"name": "Frozen canals", "season": "winter", "wall": "water", "algo": "backtrack", "corridor": 2, "extras": ["reeds"], "zones": 0.14, "pale": 0.16},
	{"name": "Snowbush maze", "season": "winter", "wall": "bush", "algo": "kruskal", "braid": 0.2, "clearings": [["farmhouse", 3, 3, "center"]], "extras": ["wall_trees", "clutter"], "zones": 0.14, "pale": 0.16},
	{"name": "Pine hedge maze", "season": "winter", "wall": "pine", "algo": "prim", "clearings": [["pen", 4, 3, "center"]], "extras": ["wall_trees"], "trees": ["pines", 10], "zones": 0.14, "pale": 0.16},
	{"name": "Frozen mill canals", "season": "winter", "wall": "water", "algo": "kruskal", "braid": 0.3, "corridor": 2, "clearings": [["windmill", 3, 3, "center"]], "extras": ["bridges"], "zones": 0.14, "pale": 0.16},
]

## The keys every maze shares (farm_terrain.gd reads the farm ones).
const BASE := {"season": "summer", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": [],
	"buildings": [], "trees": ["wild", 10], "zones": 0.22, "pale": 0.12, "ground": "e", "piece": "", "path": "maze"}


static func recipes() -> Array:
	var out: Array = []
	for r in MAZE_RECIPES:
		var full: Dictionary = BASE.duplicate(true)
		full.merge(r, true)
		var kinds: Array = []
		for spec in full.clearings:
			if spec[0] in BUILDING_KINDS:
				kinds.append(spec[0])
		full.buildings = kinds
		out.append(full)
	return out


var t # the FarmTerrain being laid out
var r: Dictionary
var rng: RandomNumberGenerator
var wall := "hedge"
var soft := true # not water
var c_w := 1 # corridor width
var wt := 3 # wall thickness
var step := 4 # corridor + wall
var cols := 13
var rows := 7
var origin := Vector2i(4, 4)
var size := Vector2i.ZERO
var open := {} # Vector3i(i, j, d) -> true: d 0 = the wall east of room (i, j), 1 = south
var clear_rooms := {} # Vector2i room -> clearing index
var clearings: Array[Rect2i] = [] # in rooms
var walls := {} # wall cells
var core := {} # the walls' middle line (soft walls)
var corridors := {} # walkable maze cells
var entrance_row := 0
var exit_row := 0
var bridge_walls: Array[Vector3i] = [] # braid links bridged over canals
var gates: Array[Vector2i] = [] # the entrance and the exit (the gap's first cell)
var ring := Rect2i() # the moat


func _init(p_t, p_rng: RandomNumberGenerator) -> void:
	t = p_t
	r = t.recipe
	rng = p_rng


## Lays the maze into the terrain; false if this attempt does not fit.
func lay() -> bool:
	wall = r.wall
	soft = wall != "water"
	c_w = r.corridor
	wt = 3 if soft else 2
	step = c_w + wt
	var moat: bool = "moat" in r.extras
	var margin := 7 if moat else (3 if soft else 4) # a canal maze leaves room for its roads
	cols = (W - 2 * margin - wt) / step
	rows = (H - 2 * margin - wt) / step
	size = Vector2i(cols * step + wt, rows * step + wt)
	origin = (Vector2i(W, H) - size) / 2
	if not soft or moat:
		origin -= Vector2i(origin.x % 2, origin.y % 2) # the water's 2 x 2 blocks
	_carve_maze()
	_place_clearings()
	_braid(r.braid)
	entrance_row = rng.randi_range(1, rows - 2)
	exit_row = _farthest_east(entrance_row)
	_build_cells()
	_paint_walls()
	if moat and not _moat():
		return false
	_entrances(moat)
	if not _fill_clearings():
		return false
	_extras()
	t.maze_info = {"entrance": t.spawn, "exit": t.goals[0], "corridors": corridors, "walls": walls, "core": core,
		"rooms": Vector2i(cols, rows), "dead_ends": _dead_ends().size(), "clearings": clearings.size(), "boxes": _boxes()}
	return true


## The maze cells the walker cannot reach from the spawn (none, on a good
## map); goals (the exit, doors, gates) count too.
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
	for c in corridors:
		if t.walkable(c) and not seen.has(c):
			out.append(c)
	for g in t.goals:
		if not seen.has(g):
			out.append(g)
	return out


# ---------------------------------------------------------------- the grid

func _room_px(i: int, j: int) -> Vector2i:
	return origin + Vector2i(wt + i * step, wt + j * step)


func _row_y(j: int) -> int:
	return origin.y + wt + j * step


## A clearing's floor in cells.
func _clearing_px(rect: Rect2i) -> Rect2i:
	return Rect2i(_room_px(rect.position.x, rect.position.y), Vector2i(rect.size.x * step - wt, rect.size.y * step - wt))


func _neighbors(i: int, j: int) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	if i + 1 < cols: out.append(Vector3i(i + 1, j, 0))
	if i > 0: out.append(Vector3i(i - 1, j, 1))
	if j + 1 < rows: out.append(Vector3i(i, j + 1, 2))
	if j > 0: out.append(Vector3i(i, j - 1, 3))
	return out


## The wall between room (i, j) and its neighbour (ni, nj), as its key.
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


func _carve_maze() -> void:
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


## Rings round the middle: each ring a loop broken once, one door to the next
## ring in at a random place; rooms the breaks cut off are joined back.
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


## Opens a share of the dead ends into a neighbour: loops (on canal mazes
## with bridges, most of them over the water).
func _braid(share: float) -> void:
	if share <= 0.0:
		return
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
		if not soft and "bridges" in r.extras and rng.randf() < 0.75:
			bridge_walls.append(key) # stays water; a bridge goes over it
		else:
			open[key] = true


## The room farthest (by the maze) from the entrance in the east column.
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
	for j in range(1, rows - 1):
		var d: int = dist.get(Vector2i(cols - 1, j), -1)
		if d > bd and absi(j - from_row) >= 1:
			bd = d
			best = j
	return best


# ---------------------------------------------------------------- clearings

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
				"west": at = Vector2i(rng.randi_range(1, maxi(1, cols / 3 - 1)), rng.randi_range(1, maxi(1, rows - ch - 1)))
				"east": at = Vector2i(rng.randi_range(mini(cols * 2 / 3, cols - cw - 1), cols - cw - 1), rng.randi_range(1, maxi(1, rows - ch - 1)))
				_: at = Vector2i(rng.randi_range(1, cols - cw - 1), rng.randi_range(1, maxi(1, rows - ch - 1)))
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


## Cells: every wall cell, then the open ones taken out (corridors, the
## opened walls, the pillars inside a clearing); the walls' core is their
## middle line (cells with wall all round).
func _build_cells() -> void:
	walls.clear()
	corridors.clear()
	core.clear()
	for y in size.y:
		for x in size.x:
			walls[origin + Vector2i(x, y)] = true
	for j in rows:
		for i in cols:
			var p := _room_px(i, j)
			for y in c_w:
				for x in c_w:
					_open_cell(p + Vector2i(x, y))
			if open.has(Vector3i(i, j, 0)):
				for y in c_w:
					for x in wt:
						_open_cell(p + Vector2i(c_w + x, y))
			if open.has(Vector3i(i, j, 1)):
				for y in wt:
					for x in c_w:
						_open_cell(p + Vector2i(x, c_w + y))
			var k: int = clear_rooms.get(Vector2i(i, j), -1)
			if k >= 0 and clear_rooms.get(Vector2i(i + 1, j), -1) == k and clear_rooms.get(Vector2i(i, j + 1), -1) == k \
					and clear_rooms.get(Vector2i(i + 1, j + 1), -1) == k:
				for y in wt:
					for x in wt:
						_open_cell(p + Vector2i(c_w + x, c_w + y))
	for y in c_w:
		for x in wt:
			_open_cell(Vector2i(origin.x + x, _row_y(entrance_row) + y))
			_open_cell(Vector2i(origin.x + size.x - wt + x, _row_y(exit_row) + y))
	if soft:
		for c: Vector2i in walls:
			var all := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if not walls.has(c + Vector2i(dx, dy)):
						all = false
			if all:
				core[c] = true
		# A wall cell with no core beside it would draw nothing: open it.
		for c: Vector2i in walls.keys():
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if core.has(c + Vector2i(dx, dy)):
						near = true
			if not near:
				_open_cell(c)


func _open_cell(c: Vector2i) -> void:
	walls.erase(c)
	corridors[c] = true


# ---------------------------------------------------------------- painting

const CORNERS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]

func _paint_walls() -> void:
	match wall:
		"hedge", "wheat", "tall":
			for c: Vector2i in core:
				for o in CORNERS:
					t.blobs[wall][c + o] = true
		"corn", "sunflower":
			var last: int = FarmTiles.CROPS[wall].size() - 1
			for c: Vector2i in core:
				for o in CORNERS:
					t._set_corner(c.x + o.x, c.y + o.y, "e")
				t.crops.append({"cell": c, "crop": wall, "stage": last - (1 if t._hash(c.x * 3, c.y * 5) < 0.2 else 0)})
		"bush", "pine":
			var arts: Array = ["bush_pine"] if wall == "pine" else (["bush"] if t.season == "winter" else ["bush", "bush_b"])
			for c: Vector2i in core:
				# Centred on the core cell (props stand on their cell's foot).
				t.props.append({"art": arts[(c.x + c.y) % arts.size()], "cell": c, "nudge": Vector2(0, 8)})
				t._prop_cells[c] = true
		"water":
			var cells: Array[Vector2i] = []
			for c: Vector2i in walls:
				t.water[c] = true
				t.kind[t._i(c)] = t.WATER
				cells.append(c)
			t._lock_round(cells, 1.0)
			t.ponds.append(Rect2i(origin, size))
	for c: Vector2i in walls:
		if soft:
			t.blocked[c] = true
		t._taken[c] = true
	# The corridors: kept clear of trees, rocks, and scatter (deco, tones, and
	# the animals still come); paved on path mazes.
	for c: Vector2i in corridors:
		t._taken[c] = true
		if r.floor == "path":
			_pave(c)
	for key in bridge_walls:
		_bridge_over(key)


func _pave(c: Vector2i) -> void:
	t.paths[c] = true
	for o in CORNERS:
		t._set_corner(c.x + o.x, c.y + o.y, r.ground)


## A bridge over the canal between two rooms, its deck along the corridor
## from the last cell of one room to the first of the next.
func _bridge_over(key: Vector3i) -> void:
	var p := _room_px(key.x, key.y)
	var b: Dictionary
	if key.z == 0:
		b = {"origin": Vector2i(p.x + c_w - 1, p.y), "span": wt + 2, "across": true}
	else:
		b = {"origin": Vector2i(p.x, p.y + c_w - 1), "span": wt + 2, "across": false}
	b["design"] = Bridges.pick_design(t.map_id * 3 + t.bridges.size() * 7, t.season == "winter")
	for c in Bridges.deck_cells(b):
		if t.water.has(c):
			t.bridge_cells[c] = true
		corridors[c] = true
	t.bridges.append(b)


## Collision boxes (px) for the soft walls, where they are drawn: a core
## cell whole, a half cell the quarters whose corner is on the core (the
## overlay's edge runs down the cell's middle); a crop wall only its row.
func _boxes() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if not soft:
		return out
	var corners := {}
	for c: Vector2i in core:
		for o in CORNERS:
			corners[c + o] = true
	var crop: bool = wall in ["corn", "sunflower"]
	for y in range(origin.y, origin.y + size.y):
		var run := -1
		for x in range(origin.x, origin.x + size.x + 1):
			var c := Vector2i(x, y)
			var full := core.has(c)
			if full and run < 0:
				run = x
			elif not full and run >= 0:
				out.append(Rect2(run * TILE, y * TILE, (x - run) * TILE, TILE))
				run = -1
			if full or crop or not walls.has(c):
				continue
			var q := [corners.has(c), corners.has(c + Vector2i(1, 0)), corners.has(c + Vector2i(0, 1)), corners.has(c + Vector2i(1, 1))]
			var half := TILE / 2.0
			for row in 2:
				var a: bool = q[row * 2]
				var b: bool = q[row * 2 + 1]
				var py := y * TILE + row * half
				if a and b:
					out.append(Rect2(x * TILE, py, TILE, half))
				elif a:
					out.append(Rect2(x * TILE, py, half, half))
				elif b:
					out.append(Rect2(x * TILE + half, py, half, half))
	return out


## The roads in and out (dirt or sand, from the map's edge through the gap,
## or up to the canal), a barrel or hay either side of each gap, a signpost.
func _entrances(moat: bool) -> void:
	var ys := [_row_y(entrance_row), _row_y(exit_row)]
	var signs := ["sign_arrow", "sign"] if rng.randf() < 0.5 else ["sign_post", "sign_arrow"]
	var flank: Array = ["barrel", "barrel_b"] if rng.randf() < 0.5 else ["hay_crate", "barrel"]
	for k in 2:
		var y: int = ys[k]
		var west := k == 0
		gates.append(Vector2i(origin.x if west else origin.x + size.x - 1, y))
		# The road: the corridor's width, through the gap on soft walls; it
		# stops short of a canal or the moat (their banks stay lawn).
		var outer := origin.x - 1 if west else origin.x + size.x # the cell outside the wall
		var x_wall := origin.x + wt - 1 if west else origin.x + size.x - wt
		var x0 := 0 if west else (x_wall if soft else outer + 1)
		var x1 := (x_wall if soft else outer - 1) if west else W - 1
		if moat:
			if west:
				x1 = ring.position.x - 3
			else:
				x0 = ring.end.x + 2
		for x in range(x0, x1 + 1):
			for dy in c_w:
				var c := Vector2i(x, y + dy)
				if t._inside(c):
					_pave(c)
					t._taken[c] = true
					corridors[c] = true
		# Nothing tall outside the gate (a crown would hide it).
		t._claim(Rect2i(Vector2i(outer - 6 if west else outer, y - 5), Vector2i(7, c_w + 7)))
		# Barrels or hay either side of the gap, outside the wall, and a sign.
		var fx := outer if soft else (outer - 1 if west else outer + 1)
		if moat:
			fx = ring.position.x - 2 if west else ring.end.x + 1
		var below := y + c_w + (1 if moat and c_w < 2 else 0) # clear of the bridge's deck
		_prop(flank[0], Vector2i(fx, y - 1))
		_prop(flank[1], Vector2i(fx, below))
		var out := -1 if west else 1
		if not _prop(signs[k], Vector2i(fx + out, y - 1)):
			_prop(signs[k], Vector2i(fx - out, y - 2))
	t.spawn = Vector2i(1, ys[0])
	t.goals.assign([Vector2i(W - 2, ys[1])])


## A moat round the maze, four cells wide (open water down its middle) with
## a bank between it and the maze, the roads crossing it on bridges.
func _moat() -> bool:
	var end := origin + size + Vector2i(6, 6)
	end += Vector2i(end.x % 2, end.y % 2)
	ring = Rect2i(origin - Vector2i(6, 6), end - origin + Vector2i(6, 6))
	if ring.position.x < 0 or ring.position.y < 2 or ring.end.x > W or ring.end.y > H - 1:
		return false
	var cells: Array[Vector2i] = []
	var inner := ring.grow(-4)
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			if not inner.has_point(Vector2i(x, y)):
				cells.append(Vector2i(x, y))
	for c in cells:
		t.water[c] = true
		t.kind[t._i(c)] = t.WATER
		t._taken[c] = true
	t._lock_round(cells, 1.0)
	t.ponds.append(ring)
	# The bank between the moat and the maze, kept clear.
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			t._taken[Vector2i(x, y)] = true
	for k in 2:
		var y := _row_y(entrance_row if k == 0 else exit_row)
		var b: Dictionary
		if k == 0:
			b = {"origin": Vector2i(ring.position.x - 2, y), "span": origin.x - ring.position.x + 2, "across": true}
		else:
			var x0 := origin.x + size.x
			b = {"origin": Vector2i(x0, y), "span": mini(ring.end.x + 2, W) - x0, "across": true}
		b["design"] = Bridges.pick_design(t.map_id + k * 11, t.season == "winter")
		for c in Bridges.deck_cells(b):
			if t.water.has(c):
				t.bridge_cells[c] = true
			corridors[c] = true
			t._taken[c] = true
		t.bridges.append(b)
	return true


# ---------------------------------------------------------------- clearings

func _fill_clearings() -> bool:
	for n in clearings.size():
		var spec: Array = r.clearings[n]
		var px := _clearing_px(clearings[n])
		var inner := px.grow(-1)
		var what: String = spec[0]
		if what in BUILDING_KINDS:
			if not _building(what, px):
				return false
			continue
		match what:
			"pen":
				_pen(inner)
			"pond":
				if not _pond(inner):
					return false
			"field":
				_field(inner, spec[4] if spec.size() > 4 else "cabbage")
			"orchard":
				var set_: Array = t._tree_set(spec[4] if spec.size() > 4 else "mixed_fruit")
				var k := 0
				for y in range(inner.position.y + 2, inner.end.y, 3):
					for x in range(inner.position.x + 1, inner.end.x - 1, 3):
						if t._place_tree(set_[k % set_.size()], Vector2i(x + rng.randi_range(0, 1), y)):
							k += 1
			"hay":
				var mid := inner.position + inner.size / 2
				_prop(["hay", "hay_big"][rng.randi() % 2], mid, false, inner)
				_prop("wheat_bunch_c", inner.position)
				_prop(["hay_crate", "barrel", "bucket"][rng.randi() % 3], Vector2i(inner.end.x - 1, inner.position.y), false, inner)
				_prop("wheat_bunch_b", Vector2i(inner.position.x, inner.end.y - 1))
			"scarecrow":
				var mid := inner.position + inner.size / 2
				_prop("scarecrow", mid, false, inner)
				_prop("hay", Vector2i(mid.x, inner.end.y - 1), false, inner)
				_prop("wheat_bunch_c", inner.position)
			"meadow":
				_carpet(inner)
				_prop(["wheat_bunch_b", "bush", "bush_b"][rng.randi() % 3], inner.position + inner.size / 2, false, inner)
	return true


## A building at the top of the clearing, facing south, its doorstep on the
## clearing floor with a little yard of the path ground in front.
func _building(k: String, px: Rect2i) -> bool:
	var art: Dictionary = FarmTiles.BUILDINGS[k]
	var cells := Vector2i(ceili(art.region.size.x / 16.0), ceili(art.region.size.y / 16.0))
	var o := Vector2i(px.position.x + (px.size.x - cells.x) / 2, px.position.y)
	var door: Vector2i = o + art.door
	if cells.x > px.size.x or door.y + 1 >= px.end.y:
		return false
	for y in cells.y:
		for x in cells.x:
			var c := o + Vector2i(x, y)
			if t._blocks_cell(art, Vector2i(x, y)):
				t.kind[t._i(c)] = t.SOLID
	for i in art.door_w:
		t.kind[t._i(door + Vector2i(i, 0))] = t.OPEN
	t.buildings.append({"kind": k, "origin": o, "door": door, "door_w": art.door_w})
	t.goals.append(door + Vector2i(0, 1))
	for i in art.door_w:
		for dy in [1, 2]:
			var c := door + Vector2i(i, dy)
			if px.has_point(c):
				_pave(c)
	return true


## A fenced pen filling the clearing but for a lane round it, its gate on
## the south side; a trough inside; the herd comes with the animals.
func _pen(inner: Rect2i) -> void:
	var fence_tab: Dictionary = FarmTiles.get_for(t.season, "fence")
	var base: Vector2i = fence_tab["grassy" if rng.randf() < 0.5 else "plain"]
	var gate := Vector2i(inner.position.x + inner.size.x / 2, inner.end.y - 1)
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var c := Vector2i(x, y)
			var ex := 0 if x == inner.position.x else (2 if x == inner.end.x - 1 else 1)
			var ey := 0 if y == inner.position.y else (2 if y == inner.end.y - 1 else 1)
			if (ex == 1 and ey == 1) or c == gate:
				continue
			t.fence[c] = base + Vector2i(ex, ey)
			t.kind[t._i(c)] = t.FENCE
	t.gates.append(gate)
	t.pens.append({"rect": inner, "gate": gate})
	t.goals.append(gate + Vector2i(0, 1))
	_prop("trough_water" if rng.randf() < 0.5 else "trough", inner.position + Vector2i(inner.size.x / 2, 1), false, inner.grow(-1))


## A pond of the sheet's 2 x 2 water blocks inside the clearing, a lane of
## bank round it; reeds on the bank.
func _pond(inner: Rect2i) -> bool:
	var b0 := Vector2i(ceili(inner.position.x / 2.0), ceili(inner.position.y / 2.0))
	var b1 := Vector2i(inner.end.x / 2, inner.end.y / 2)
	var blocks := {}
	for by in range(b0.y, b1.y):
		for bx in range(b0.x, b1.x):
			blocks[Vector2i(bx, by)] = true
	if blocks.size() < 4:
		return false
	# Round it off: a corner block left out now and then.
	if blocks.size() >= 6 and rng.randf() < 0.6:
		var corner := Vector2i(b0.x if rng.randf() < 0.5 else b1.x - 1, b0.y if rng.randf() < 0.5 else b1.y - 1)
		blocks.erase(corner)
	var cells: Array[Vector2i] = []
	for b: Vector2i in blocks:
		for o in CORNERS:
			cells.append(b * 2 + o)
	for c in cells:
		if not inner.has_point(c):
			return false
	for c in cells:
		t.water[c] = true
		t.kind[t._i(c)] = t.WATER
	t._lock_round(cells, 1.0)
	var box := Rect2i(cells[0], Vector2i.ONE)
	for c in cells:
		box = box.expand(c).expand(c + Vector2i.ONE)
	t.ponds.append(box)
	return true


## A crop patch: a bordered block of plots, one crop, most of it ripe.
func _field(inner: Rect2i, crop: String) -> void:
	if not FarmTiles.get_for(t.season, "crops"):
		return
	var set_: String = ["dry", "wet", "ragged"][rng.randi() % 3]
	var cells: Array[Vector2i] = []
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var c := Vector2i(x, y)
			cells.append(c)
			t.plots[c] = t._plot_tile(set_, c, inner, false)
			t.kind[t._i(c)] = t.FIELD
			var stage: int = FarmTiles.CROPS[crop].size() - 1
			if t._hash(c.x * 3, c.y * 5) < 0.18:
				stage -= 1
			if t._hash(c.x * 7, c.y * 11) < 0.06:
				continue
			t.crops.append({"cell": c, "crop": crop, "stage": stage})
	t._lock_round(cells, 0.5)
	t.fields.append({"rect": inner, "set": set_, "crop": crop, "rows": false})


## A prop on a free cell (or, `on_wall`, on a wall's core); its collider may
## reach into the wall beside it or across `within` (a clearing's floor
## inside its lane), never into another corridor cell.
func _prop(art: String, cell: Vector2i, on_wall := false, within := Rect2i()) -> bool:
	var p: Dictionary = FarmTiles.prop(t.season, art)
	if p.is_empty() or not t._inside(cell) or t._prop_cells.has(cell) or cell == t.spawn or t.paths.has(cell):
		return false
	var k: int = t.kind[t._i(cell)]
	if on_wall:
		if not core.has(cell):
			return false
	elif k != t.OPEN or t.blocked.has(cell) or t.water.has(cell):
		return false
	var cx := cell.x * TILE + TILE / 2.0
	var x0 := floori((cx - p.block.x / 2.0) / TILE) if p.block.x > 0.0 else cell.x
	var x1 := floori((cx + p.block.x / 2.0 - 0.01) / TILE) if p.block.x > 0.0 else cell.x
	for x in range(x0, x1 + 1):
		var c := Vector2i(x, cell.y)
		if c == cell or within.has_point(c):
			continue
		if not t._inside(c) or t.paths.has(c) or (corridors.has(c) and not walls.has(c)) or t.water.has(c):
			return false
	t.props.append({"art": art, "cell": cell})
	t._prop_cells[cell] = true
	t._taken[cell] = true
	if p.block != Vector2.ZERO:
		for x in range(x0, x1 + 1):
			t.blocked[Vector2i(x, cell.y)] = true
	return true


## Flowers (or winter's frosty tufts) over the lawn cells of `rect`.
func _carpet(rect: Rect2i) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := Vector2i(x, y)
			if not _lawn(c):
				continue
			var h: float = t._hash(x * 3, y * 7)
			if h < 0.6:
				t.deco[c] = t.flowers_set[rng.randi() % t.flowers_set.size()]
			elif h < 0.8:
				t.deco[c] = t.sprouts_set[rng.randi() % t.sprouts_set.size()]


func _lawn(c: Vector2i) -> bool:
	return t._inside(c) and t.kind[t._i(c)] == t.OPEN and not t.blocked.has(c) and not t.paths.has(c) \
		and not t._prop_cells.has(c) and not t.water.has(c) and t.sig(c) == "gggg"


# ---------------------------------------------------------------- extras

func _extras() -> void:
	var ends := _dead_ends()
	var ex: Array = r.extras
	var winter: bool = t.season == "winter"
	if "flowers" in ex:
		var n := 0
		for d in ends:
			if n >= 4 or rng.randf() < 0.4:
				continue
			_carpet(Rect2i(_room_px(d.x, d.y), Vector2i(c_w, c_w)))
			n += 1
		# Single flowers along the corridors.
		var keys: Array = corridors.keys()
		keys.sort()
		for k in 18:
			var c: Vector2i = keys[rng.randi() % keys.size()]
			if _lawn(c) and not t.deco.has(c):
				t.deco[c] = t.flowers_set[rng.randi() % t.flowers_set.size()]
	if "pots" in ex:
		var n := 0
		for d in ends:
			if n >= 4 or rng.randf() < 0.5:
				continue
			if _prop(["pot_plant", "pot_plant_b"][rng.randi() % 2], _room_px(d.x, d.y) + _dead_end_corner(d)):
				n += 1
	if "clutter" in ex:
		var n := 0
		for d in ends:
			if n >= 4 or rng.randf() < 0.5:
				continue
			if _prop(["barrel", "barrel_b", "bucket", "box", "chest"][rng.randi() % 5], _room_px(d.x, d.y) + _dead_end_corner(d)):
				n += 1
	if "bunches" in ex and not winter:
		var n := 0
		for d in ends:
			if n >= 5 or rng.randf() < 0.35:
				continue
			if _prop(["wheat_bunch_c", "wheat_bunch_b"][rng.randi() % 2], _room_px(d.x, d.y) + _dead_end_corner(d)):
				n += 1
	if "reeds" in ex:
		var keys: Array = corridors.keys()
		keys.sort()
		for c: Vector2i in keys:
			if rng.randf() > 0.16 or t.bridge_cells.has(c) or not _lawn(c):
				continue
			var wet := false
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if t.water.has(c + d) and not t.bridge_cells.has(c + d):
					wet = true
			if wet and not _near_bridge(c):
				_prop(["reeds", "reeds_s", "cattail", "cattail_b", "reeds_b"][rng.randi() % 5], c)
	if "scarecrows" in ex:
		var n := 0
		for k in 80:
			if n >= 4:
				break
			var c := _pillar(rng.randi_range(1, cols - 1), rng.randi_range(1, rows - 1))
			if not core.has(c) or _crowded(c, 2):
				continue
			var had: Array = t.crops.filter(func(cr): return cr.cell == c)
			for cr in had:
				t.crops.erase(cr)
			if _prop("scarecrow", c, true):
				n += 1
			else:
				t.crops.append_array(had)
	if "wall_trees" in ex or "fruit_trees" in ex:
		var set_: Array = t._tree_set("mixed_fruit" if "fruit_trees" in ex else ("pines" if wall == "pine" else "wild"))
		var want := 6 * (ex.count("wall_trees") + ex.count("fruit_trees"))
		_wall_trees(set_, want, Rect2i(origin, size), 6.0)


## A tree growing out of the hedge at pillars (where walls meet, not the
## outer wall): its trunk inside the hedge, never over a clearing or a gate
## (the crown would hide it), spaced apart.
func _wall_trees(set_: Array, want: int, within: Rect2i, gap: float) -> int:
	if not soft:
		return 0
	var placed := 0
	for k in 200:
		if placed >= want:
			break
		var c := _pillar(rng.randi_range(1, cols - 1), rng.randi_range(1, rows - 1))
		if not within.has_point(c) or not core.has(c) or _crowded(c, 3):
			continue
		# A bush wall's own bush may stand there (the tree takes its place);
		# nothing else.
		var bush: Array = t.props.filter(func(p): return p.cell == c and p.has("nudge"))
		if t._prop_cells.has(c) and bush.is_empty():
			continue
		var near := false
		for tr in t.trees:
			if Vector2(tr.cell - c).length() < gap:
				near = true
		if near:
			continue
		for p in bush:
			t.props.erase(p)
		var had: Array = t.crops.filter(func(cr): return cr.cell == c)
		for cr in had:
			t.crops.erase(cr)
		t.trees.append({"art": set_[rng.randi() % set_.size()], "cell": c})
		t._prop_cells[c] = true
		placed += 1
	return placed


## The core cell of the pillar where the walls round room corners meet.
func _pillar(i: int, j: int) -> Vector2i:
	return origin + Vector2i(i * step + wt / 2, j * step + wt / 2)


## Near a clearing (within `pad` cells) or the ways in and out.
func _crowded(c: Vector2i, pad: int) -> bool:
	for rect in clearings:
		var px := _clearing_px(rect)
		if px.grow(pad).has_point(c) or px.grow(pad).has_point(c + Vector2i(0, -4)):
			return true
	for g in gates:
		if absi(c.y - g.y) <= 4 and absi(c.x - g.x) <= 4:
			return true
	return false


func _near_bridge(c: Vector2i) -> bool:
	for b in t.bridges:
		for d in Bridges.deck_cells(b):
			if absi(d.x - c.x) <= 1 and absi(d.y - c.y) <= 2:
				return true
	return false


## The far corner of a dead end (away from its one way in).
func _dead_end_corner(d: Vector2i) -> Vector2i:
	var l: Vector2i = _links(d.x, d.y)[0] - d
	var x := 0 if l.x > 0 else c_w - 1
	var y := 0 if l.y > 0 else c_w - 1
	if l.x != 0:
		y = rng.randi_range(0, c_w - 1)
	else:
		x = rng.randi_range(0, c_w - 1)
	return Vector2i(x, y)


# ---------------------------------------------------------------- liveliness

## An anchor for a weak camera window: a tree out of a hedge pillar in it
## (it rustles in the gusts and sheds), else flowers along its corridors
## (butterflies come); false if neither fits.
func floor_anchor(rect: Rect2i) -> bool:
	var set_: Array = t._tree_set("pines" if wall == "pine" else "wild")
	if _wall_trees(set_, 2, rect, 5.0) > 0:
		return true
	if t.season == "winter":
		return false
	var cells: Array[Vector2i] = []
	for c: Vector2i in corridors:
		if rect.has_point(c) and _lawn(c) and not t.deco.has(c):
			cells.append(c)
	cells.sort()
	var put := 0
	for k in mini(8, cells.size()):
		var c: Vector2i = cells[rng.randi() % cells.size()]
		if not t.deco.has(c):
			t.deco[c] = t.flowers_set[rng.randi() % t.flowers_set.size()]
			put += 1
	return put > 0
