class_name ForestMaze
extends RefCounted
## maze-forest: hedge (and canal) mazes on the Painted Lands Forest sheet,
## laid into a PaintedTerrain (forest_terrain.gd with `maze` on) so the rest
## of the Painted Lands pipeline paints and fills them as any Forest map:
## grass tones, dirt patches, deco, the trees and bushes round the edge, the
## ambience, the Cozy Farm animals, the homes and their interiors.
##
## A maze is a grid of rooms: each room a corridor C cells wide (1 on the
## hedge mazes, 2 where the corridors are paved or bridged, 3 on the
## avenues), every wall three cells thick (the sheet's 3x3 hedge blob, or
## the pond's water set, autotiled with their inner corners): the sheet
## draws a hedge (or a pond's water) inside its tiles with a margin of
## grass, so a three-cell wall shows about two cells of hedge with a full
## row through its middle, and a one-cell corridor between two of them
## reads about two cells wide. The walls collide where they are drawn
## (forest.gd), so the walker walks what it sees. A maze algorithm decides
## which walls come down; every room is reachable from the entrance (a
## spanning tree, plus loops where the type braids). Some types merge rooms
## into clearings (a cottage, a pond, a camp, a garden, an old tree). The
## entrance is a gap in the west wall, the exit one in the east wall (the
## room there farthest from the entrance), each with a road running in from
## the map's edge, lanterns either side, and a signpost.
##
## Recipe keys (MAZE_RECIPES): wall "dark" (the dark hedge, on plain lawn) |
## "light" (the pale hedge, on dark grass) | "water" (canals); algo
## "backtrack" (long winding corridors) | "prim" (many short branches) |
## "kruskal" (even) | "sidewinder" (long east-west runs) | "rings" (rings
## round the middle, one way through each); braid (share of dead ends
## opened into loops); corridor (2 or 3); floor "lawn" | "path";
## clearings: [[kind, rooms wide, rooms tall, where]]; extras: chests,
## flowers, pots, lanterns, wall_trees, moat, bridges, blooms. Plus the
## Painted Lands keys the rest of the pipeline reads (houses, water, height,
## path, patch, props, signs, tones).

const W := 60
const H := 40
const TILE := 16

const MAZE_RECIPES := [
	{"name": "Hedge labyrinth", "wall": "dark", "algo": "backtrack", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["wall_trees", "flowers"]},
	{"name": "Branching hedges", "wall": "dark", "algo": "prim", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["flowers", "blooms", "wall_trees"]},
	{"name": "Braided hedges", "wall": "dark", "algo": "backtrack", "braid": 0.5, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["wall_trees", "flowers"]},
	{"name": "Windswept hedges", "wall": "dark", "algo": "sidewinder", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["flowers", "wall_trees"]},
	{"name": "Garden maze", "wall": "dark", "algo": "kruskal", "braid": 0.15, "corridor": 1, "floor": "lawn", "clearings": [["garden", 2, 2, "center"]], "extras": ["flowers", "pots", "wall_trees"]},
	{"name": "Cottage maze", "wall": "dark", "algo": "backtrack", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [["cottage", 2, 2, "center"]], "houses": [3], "extras": ["pots", "wall_trees", "flowers"]},
	{"name": "Campfire maze", "wall": "dark", "algo": "prim", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [["camp", 2, 2, "center"]], "extras": ["blooms", "wall_trees", "flowers"]},
	{"name": "Pond court", "wall": "dark", "algo": "kruskal", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [["pond", 3, 2, "center"]], "water": "P", "extras": ["flowers", "wall_trees"]},
	{"name": "Wide avenues", "wall": "dark", "algo": "kruskal", "braid": 0.2, "corridor": 3, "floor": "path", "clearings": [], "extras": ["wall_trees", "lanterns", "flowers"]},
	{"name": "Path maze", "wall": "dark", "algo": "backtrack", "braid": 0.0, "corridor": 2, "floor": "path", "clearings": [], "extras": ["pots", "wall_trees", "flowers"]},
	{"name": "Rings maze", "wall": "dark", "algo": "rings", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [["tree", 2, 2, "center"]], "extras": ["flowers", "wall_trees"]},
	{"name": "Wooded maze", "wall": "dark", "algo": "backtrack", "braid": 0.2, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["wall_trees", "wall_trees", "blooms", "flowers"]},
	{"name": "Treasure maze", "wall": "dark", "algo": "prim", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["chests", "lanterns", "wall_trees", "flowers"]},
	{"name": "Twin cottages", "wall": "dark", "algo": "kruskal", "braid": 0.15, "corridor": 1, "floor": "lawn", "clearings": [["cottage", 2, 2, "west"], ["cottage", 2, 2, "east"]], "houses": [3, 3], "extras": ["pots", "wall_trees", "flowers"]},
	{"name": "Lantern maze", "wall": "dark", "algo": "backtrack", "braid": 0.15, "corridor": 2, "floor": "path", "clearings": [["camp", 2, 2, "center"]], "extras": ["lanterns", "wall_trees", "flowers"]},
	{"name": "Shade maze", "wall": "light", "algo": "backtrack", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["blooms", "wall_trees", "flowers"], "tones": [0.97, 0.9, 0.25]},
	{"name": "Firefly maze", "wall": "light", "algo": "prim", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [["tree", 2, 2, "center"]], "extras": ["blooms", "wall_trees"], "tones": [0.97, 0.92, 0.35]},
	{"name": "Moss garden", "wall": "light", "algo": "kruskal", "braid": 0.4, "corridor": 1, "floor": "lawn", "clearings": [["pond", 3, 2, "center"]], "water": "P", "extras": ["flowers", "wall_trees"], "tones": [0.97, 0.88, 0.2]},
	{"name": "Canal maze", "wall": "water", "algo": "backtrack", "braid": 0.0, "corridor": 1, "floor": "lawn", "clearings": [], "extras": ["flowers"]},
	{"name": "Lily canals", "wall": "water", "algo": "kruskal", "braid": 0.35, "corridor": 2, "floor": "lawn", "clearings": [], "extras": ["bridges", "flowers"]},
	{"name": "Moat maze", "wall": "dark", "algo": "kruskal", "braid": 0.1, "corridor": 1, "floor": "lawn", "clearings": [["garden", 2, 2, "center"]], "extras": ["moat", "pots", "wall_trees"]},
	{"name": "Meadow maze", "wall": "dark", "algo": "kruskal", "braid": 0.25, "corridor": 1, "floor": "lawn", "clearings": [["meadow", 2, 2, "random"], ["meadow", 2, 2, "random"], ["meadow", 2, 2, "random"]], "extras": ["flowers", "blooms", "wall_trees"]},
	{"name": "Canal cottage", "wall": "water", "algo": "prim", "braid": 0.15, "corridor": 2, "floor": "path", "clearings": [["cottage", 2, 2, "center"]], "houses": [3], "extras": ["bridges", "pots", "flowers"]},
	{"name": "Stone court", "wall": "dark", "algo": "rings", "braid": 0.1, "corridor": 3, "floor": "path", "clearings": [["camp", 2, 2, "center"]], "extras": ["lanterns", "pots", "wall_trees", "flowers"]},
]

## The Painted Lands keys every maze shares (forest_terrain.gd reads them).
const BASE := {"houses": [], "water": "", "height": "", "path": "maze", "patch": ["R", 2, 3], "props": ["bushes", "LR"], "signs": 0, "tones": [0.16, 0.04, 0.01]}


static func recipes() -> Array:
	var out: Array = []
	for r in MAZE_RECIPES:
		var full: Dictionary = BASE.duplicate(true)
		full.merge(r, true)
		out.append(full)
	return out


var t # the PaintedTerrain being laid out
var r: Dictionary
var rng: RandomNumberGenerator
var c_w := 2 # corridor width
var wt := 3 # wall thickness
var step := 5 # corridor + wall
var cols := 13
var rows := 8
var origin := Vector2i(3, 3)
var size := Vector2i.ZERO
var open := {} # Vector3i(i, j, d) -> true: d 0 = the wall east of room (i, j), 1 = south
var clear_rooms := {} # Vector2i room -> clearing index
var clearings: Array[Rect2i] = [] # in rooms
var walls := {} # wall cells
var corridors := {} # walkable maze cells
var entrance_row := 0
var exit_row := 0
var bridge_walls: Array[Vector3i] = [] # braid links bridged over canals


func _init(p_t, p_rng: RandomNumberGenerator) -> void:
	t = p_t
	r = t.recipe
	rng = p_rng


## Lays the maze into the terrain; false if this attempt does not fit.
func lay() -> bool:
	c_w = r.get("corridor", 1)
	wt = r.get("wall_thickness", 3)
	step = c_w + wt
	var moat: bool = "moat" in r.extras
	var margin := Vector2i(3 + (4 if moat else 0), 3 + (4 if moat else 0))
	cols = (W - 2 * margin.x - wt) / step
	rows = (H - 2 * margin.y - wt) / step
	size = Vector2i(cols * step + wt, rows * step + wt)
	origin = (Vector2i(W, H) - size) / 2
	_carve_maze()
	_place_clearings()
	_braid(r.get("braid", 0.0))
	entrance_row = rng.randi_range(1, rows - 2)
	exit_row = _farthest_east(entrance_row)
	_build_cells()
	if not _paint_walls():
		return false
	_entrances(moat)
	if moat and not _moat():
		return false
	if not _fill_clearings():
		return false
	_extras()
	if not unreached().is_empty():
		return false
	t.maze_info = {"entrance": Vector2i(0, _row_y(entrance_row)), "exit": Vector2i(W - 1, _row_y(exit_row)),
		"corridors": corridors, "walls": walls, "rooms": Vector2i(cols, rows), "dead_ends": _dead_ends().size(), "clearings": clearings.size()}
	return true


## The maze cells the walker cannot reach from the spawn (none, on a good
## map); the exit counts as one.
func unreached() -> Array[Vector2i]:
	var seen := {t.spawn: true}
	var queue: Array[Vector2i] = [t.spawn]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if seen.has(n) or not t._inside(n) or t._blocked.has(n):
				continue
			seen[n] = true
			queue.append(n)
	var out: Array[Vector2i] = []
	for c in corridors:
		if not t._blocked.has(c) and not seen.has(c):
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


func _neighbors(i: int, j: int) -> Array[Vector3i]:
	# Vector3i(ni, nj, wall key index) for the in-grid neighbours.
	var out: Array[Vector3i] = []
	if i + 1 < cols: out.append(Vector3i(i + 1, j, 0))
	if i > 0: out.append(Vector3i(i - 1, j, 1))
	if j + 1 < rows: out.append(Vector3i(i, j + 1, 2))
	if j > 0: out.append(Vector3i(i, j - 1, 3))
	return out


# The wall between room (i, j) and its neighbour (ni, nj), as its key.
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
	var seen := {Vector2i(0, 0): true}
	var stack: Array[Vector2i] = [Vector2i(0, rng.randi_range(0, rows - 1))]
	seen[stack[0]] = true
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
	# (0, 0) was marked seen before the walk started elsewhere: join it.
	if _links(0, 0).is_empty():
		open[_wall_key(0, 0, 1, 0)] = true


func _prim() -> void:
	var start := Vector2i(rng.randi_range(0, cols - 1), rng.randi_range(0, rows - 1))
	var inside := {start: true}
	var frontier: Array[Vector3i] = [] # (room inside, wall to outside as packed)
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
	var find := func(find_ref: Callable, x: Vector2i) -> Vector2i:
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
		var ra: Vector2i = find.call(find, a)
		var rb: Vector2i = find.call(find, b)
		if ra != rb:
			parent[ra] = rb
			open[key] = true


func _sidewinder() -> void:
	for j in rows:
		var run_start := 0
		for i in cols:
			var close_out := i == cols - 1 or (j > 0 and rng.randf() < 0.4)
			if j == 0:
				if i + 1 < cols:
					open[Vector3i(i, j, 0)] = true
				continue
			if close_out:
				var k := rng.randi_range(run_start, i)
				open[Vector3i(k, j - 1, 1)] = true
				run_start = i + 1
			else:
				open[Vector3i(i, j, 0)] = true


# Rings round the middle: each ring a loop with one wall left across it, and
# one door to the next ring in, at a random place; spurs off the rings.
func _rings() -> void:
	var depth := mini(cols, rows) / 2
	var ring_of := func(i: int, j: int) -> int:
		return mini(mini(i, j), mini(cols - 1 - i, rows - 1 - j))
	for j in rows:
		for i in cols:
			var k: int = ring_of.call(i, j)
			for n in _neighbors(i, j):
				if n.z in [1, 3]:
					continue # each wall once (east and south)
				if ring_of.call(n.x, n.y) == k:
					open[_wall_key(i, j, n.x, n.y)] = true
	for k in depth:
		# Break the ring once (so it is not a loop round and round).
		var ring: Array[Vector3i] = []
		for key in open.keys():
			if ring_of.call(key.x, key.y) == k:
				ring.append(key)
		if ring.size() > 2:
			open.erase(ring[rng.randi() % ring.size()])
		# A door inward.
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
	# Any room the breaks cut off gets joined back (a spur).
	_join_islands()


func _join_islands() -> void:
	var seen := {Vector2i(0, entrance_row): true}
	var queue: Array[Vector2i] = [Vector2i(0, entrance_row)]
	while true:
		while not queue.is_empty():
			var c: Vector2i = queue.pop_back()
			for l in _links(c.x, c.y):
				if not seen.has(l):
					seen[l] = true
					queue.append(l)
		if seen.size() == cols * rows:
			return
		# Join one unreached room that touches the reached part.
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


# Opens a share of the dead ends into a neighbour: loops (on canal mazes
# with bridges, some of them over the water instead).
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
		if r.wall == "water" and "bridges" in r.extras and rng.randf() < 0.7:
			bridge_walls.append(key) # stays water; a bridge goes over it
		else:
			open[key] = true


# The room farthest (by the maze) from the entrance among the east column.
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
	for j in rows:
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
		for tries in 30:
			var at: Vector2i
			match where:
				"center": at = Vector2i((cols - cw) / 2, (rows - ch) / 2)
				"west": at = Vector2i(rng.randi_range(1, cols / 3 - 1), rng.randi_range(1, rows - ch - 1))
				"east": at = Vector2i(rng.randi_range(cols * 2 / 3, cols - cw - 1), rng.randi_range(1, rows - ch - 1))
				_: at = Vector2i(rng.randi_range(1, cols - cw - 1), rng.randi_range(1, rows - ch - 1))
			var rect := Rect2i(at, Vector2i(cw, ch))
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


# Cells: every wall cell, then the open ones taken out (corridors, the
# opened walls, the pillars inside a clearing).
func _build_cells() -> void:
	walls.clear()
	corridors.clear()
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
			# Inside a clearing the pillars come down too.
			if clear_rooms.has(Vector2i(i, j)) and clear_rooms.get(Vector2i(i + 1, j), -1) == clear_rooms[Vector2i(i, j)] \
					and clear_rooms.get(Vector2i(i, j + 1), -1) == clear_rooms[Vector2i(i, j)] and clear_rooms.get(Vector2i(i + 1, j + 1), -1) == clear_rooms[Vector2i(i, j)]:
				for y in wt:
					for x in wt:
						_open_cell(p + Vector2i(c_w + x, c_w + y))
	# The entrance and the exit: gaps in the outer wall.
	for y in c_w:
		for x in wt:
			_open_cell(Vector2i(origin.x + x, _row_y(entrance_row) + y))
			_open_cell(Vector2i(origin.x + size.x - wt + x, _row_y(exit_row) + y))


func _open_cell(c: Vector2i) -> void:
	walls.erase(c)
	corridors[c] = true


# ---------------------------------------------------------------- painting

func _paint_walls() -> bool:
	var kind: String = r.wall
	var tiles := {}
	for c in walls:
		var tl: Vector2i
		if kind == "water":
			tl = t._pool_tile(c, walls, t.WATER_SET, t.WATER_INNER)
		else:
			tl = t._hedge_tile(c, walls, t.HEDGE_SETS[1 if kind == "light" else 0])
		if tl == t.NONE:
			return false
		tiles[c] = tl
	for c in walls:
		if kind == "water":
			var tl: Vector2i = tiles[c]
			if tl == t.WATER_SET + Vector2i(1, 1):
				tl = t.SHALLOW_SURFACE
			t.features[c] = tl
			t.water[c] = true
		else:
			t.hedge[c] = tiles[c]
		t._solid[c] = true
		t._blocked[c] = true
		t._taken[c] = true
	if kind == "water":
		t.streams.append({"cells": walls.duplicate()})
		t.props.append_array(_lilies())
	# The corridors: kept clear of trees, rocks, and hedgerows (deco, tones,
	# and the walker's company still come); the floor paved on path mazes.
	for c in corridors:
		t._taken[c] = true
		if r.floor == "path":
			t.path[c] = true
	# Bridges over the canals where a braid crossed the water.
	for key in bridge_walls:
		_bridge_over(key)
	return true


func _lilies() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in t._water_props(walls, "WP"):
		if rng.randf() < 0.5:
			out.append(p)
	return out


func _bridge_over(key: Vector3i) -> void:
	var p := _room_px(key.x, key.y)
	var b: Dictionary
	if key.z == 0:
		# Across the wall east of the room: deck rows of the corridor.
		b = {"design": 0, "origin": Vector2i(p.x + c_w - 1, p.y), "span": wt + 2, "across": true}
	else:
		b = {"design": 0, "origin": Vector2i(p.x, p.y + c_w - 1), "span": wt + 2, "across": false}
	b.design = Bridges.pick_design(t.map_id * 3 + t.bridges.size() * 7, false)
	for c in Bridges.deck_cells(b):
		t.water.erase(c)
		t._blocked.erase(c)
		t._solid.erase(c)
		corridors[c] = true
	t.bridges.append(b)


# The roads in and out, lanterns either side of each gap, and a signpost.
func _entrances(moat: bool) -> void:
	var ys := [_row_y(entrance_row), _row_y(exit_row)]
	var sign_a := rng.randi_range(0, 9)
	var sign_ids := [sign_a, (sign_a + rng.randi_range(1, 9)) % 10] # two different signposts
	for k in 2:
		var y: int = ys[k]
		# The road: two wide (or the corridor's width), through the gap
		# where the corridor is as wide, else up to the wall.
		var lane := maxi(2, c_w)
		var through := c_w >= 2
		var x0 := 0 if k == 0 else (origin.x + size.x - wt if through else origin.x + size.x)
		var x1 := (origin.x + wt - 1 if through else origin.x - 1) if k == 0 else W - 1
		for x in range(x0, x1 + 1):
			for dy in lane:
				var c := Vector2i(x, y + dy)
				t.path[c] = true
				t._taken[c] = true
				t._solid[c] = true
				corridors[c] = true
		# Lanterns at the gap, outside the wall.
		var lx := origin.x - 1 if k == 0 else origin.x + size.x
		for ly in [y - 1, y + lane]:
			var cell := Vector2i(lx, ly)
			if t._inside(cell) and not t._blocked.has(cell):
				t.props.append({"art": "torch", "cell": cell, "block": true})
				t._block_collider(t.props.back())
				t._taken[cell] = true
				t._taken[cell + Vector2i.UP] = true
		# A signpost by the road.
		var sx := lx + (-1 if k == 0 else 1)
		var sc := Vector2i(sx, y - 2)
		if t._inside(sc) and not t._blocked.has(sc):
			t.props.append({"sign": sign_ids[k], "cell": sc, "block": true})
			t._taken[sc] = true
			t._solid[sc] = true
			t._blocked[sc] = true
	t.spawn = Vector2i(1, ys[0])
	t.goals.assign([Vector2i(W - 2, ys[1])])


# A moat round the maze, two cells wide, the roads crossing it on bridges.
func _moat() -> bool:
	# Three cells wide (open water down its middle), a cell of bank between
	# it and the maze.
	var ring := Rect2i(origin - Vector2i(4, 4), size + Vector2i(8, 8))
	var cells := {}
	for y in range(ring.position.y, ring.end.y):
		for x in range(ring.position.x, ring.end.x):
			var inner := x >= ring.position.x + 3 and x < ring.end.x - 3 and y >= ring.position.y + 3 and y < ring.end.y - 3
			if not inner:
				cells[Vector2i(x, y)] = true
	var tiles := {}
	for c in cells:
		var tl: Vector2i = t._pool_tile(c, cells, t.WATER_SET, t.WATER_INNER)
		if tl == t.NONE:
			return false
		tiles[c] = tl
	var crossings: Array[Dictionary] = []
	for k in 2:
		var y := _row_y(entrance_row if k == 0 else exit_row)
		var x := ring.position.x - 1 if k == 0 else ring.end.x - 4 # from the bank outside to the bank inside
		crossings.append({"design": Bridges.pick_design(t.map_id + k * 11, false), "origin": Vector2i(x, y), "span": 5, "across": true})
	var deck := {}
	for b in crossings:
		for c in Bridges.deck_cells(b):
			deck[c] = true
	for c in cells:
		var tl: Vector2i = tiles[c]
		if tl == t.WATER_SET + Vector2i(1, 1):
			tl = t.SHALLOW_SURFACE
		t.features[c] = tl
		t._taken[c] = true
		if deck.has(c):
			t.path.erase(c) # the road's water under the deck
			continue
		t.water[c] = true
		t._solid[c] = true
		t._blocked[c] = true
	# The roads stop at the moat; the bridges carry them over to the bank
	# by the maze.
	for k in 2:
		var y := _row_y(entrance_row if k == 0 else exit_row)
		var xs := range(ring.position.x, origin.x) if k == 0 else range(origin.x + size.x, ring.end.x)
		for x in xs:
			for dy in maxi(2, c_w):
				t.path.erase(Vector2i(x, y + dy))
	t.bridges.append_array(crossings)
	t.streams.append({"cells": cells})
	t.props.append_array(_lilies_on(cells, deck))
	return true


func _lilies_on(cells: Dictionary, deck: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var wet := {}
	for c in cells:
		if not deck.has(c):
			wet[c] = true
	for p in t._water_props(wet, "WP"):
		var near := false
		for c in deck:
			if absi(c.x - p.cell.x) <= 2 and absi(c.y - p.cell.y) <= 2:
				near = true
		if not near and rng.randf() < 0.5:
			out.append(p)
	return out


# What fills each clearing.
func _fill_clearings() -> bool:
	var house_k := 0
	for n in clearings.size():
		var spec: Array = r.clearings[n]
		var rect := clearings[n]
		var px := Rect2i(_room_px(rect.position.x, rect.position.y), Vector2i(rect.size.x * step - wt, rect.size.y * step - wt))
		# A clearing is grass, even where the corridors are paved.
		for y in range(px.position.y, px.end.y):
			for x in range(px.position.x, px.end.x):
				t.path.erase(Vector2i(x, y))
		match spec[0]:
			"cottage":
				var ids: Array = r.get("houses", [3])
				var id: int = ids[house_k % ids.size()]
				house_k += 1
				if not _cottage(id, px):
					return false
			"pond":
				_free_rect(px)
				if not t._pond(px, "WP"):
					return false
				_retake(px)
			"camp":
				var mid := px.position + px.size / 2
				_prop("campfire", mid)
				_prop("log", mid + Vector2i(-2, 0))
				_prop("ash", mid + Vector2i(1, 1))
				_prop(["crate", "crate_b", "crate_stack"][rng.randi() % 3], px.position + Vector2i(px.size.x - 1, 0))
				_prop(["chest", "chest_b"][rng.randi() % 2], px.position)
			"garden":
				_carpet(px.position)
				_carpet(px.end - Vector2i(2, 2))
				_prop(["bloom_a", "bloom_b"][rng.randi() % 2], Vector2i(px.end.x - 2, px.position.y + 1))
				_prop("flowerpot", Vector2i(px.position.x, px.end.y - 1))
				_prop("flowerpot", Vector2i(px.end.x - 1, px.end.y - 1))
			"tree":
				var mid := px.position + px.size / 2
				_prop(["tree_a", "tree_b", "bloom_a", "shade_tree"][rng.randi() % 4], mid + Vector2i(0, 1))
				_prop(["bush_round", "bush_berry"][rng.randi() % 2], mid + Vector2i(-2, 2))
			"meadow":
				for k in 3:
					var c := px.position + Vector2i(rng.randi_range(0, px.size.x - 1), rng.randi_range(0, px.size.y - 1))
					_prop("tall_grass", c)
				_carpet(px.position + Vector2i(rng.randi_range(0, maxi(0, px.size.x - 3)), rng.randi_range(0, maxi(0, px.size.y - 3))))
	return true


func _free_rect(px: Rect2i) -> void:
	for y in range(px.position.y, px.end.y):
		for x in range(px.position.x, px.end.x):
			t._taken.erase(Vector2i(x, y))


func _retake(px: Rect2i) -> void:
	for y in range(px.position.y, px.end.y):
		for x in range(px.position.x, px.end.x):
			t._taken[Vector2i(x, y)] = true


# A home in the clearing: its body at the top, its doorstep on the clearing
# floor, a little paved yard in front.
func _cottage(id: int, px: Rect2i) -> bool:
	var art: Dictionary = t.HOUSES[id]
	var cells: Vector2i = t._cells(art.region.size)
	var door: Vector2i = art.door
	var o := Vector2i(px.position.x + (px.size.x - cells.x) / 2, px.position.y)
	if cells.x > px.size.x or door.y + 1 > px.size.y:
		return false
	t.houses.append({"id": id, "origin": o})
	for block in art.blocks:
		t._block_pixels(o * TILE, block)
	var step_cell: Vector2i = o + door
	# A little paved yard in front of the door where two rows fit (the
	# path tiles draw nothing narrower).
	var pad: Array[Vector2i] = []
	for y in [step_cell.y, step_cell.y + 1]:
		for x in [step_cell.x, step_cell.x + 1]:
			var c := Vector2i(x, y)
			if px.has_point(c) and not t._blocked.has(c):
				pad.append(c)
	if pad.size() == 4:
		for c in pad:
			t.path[c] = true
	t.goals.append(step_cell)
	return true


func _prop(art: String, cell: Vector2i) -> void:
	if not t._inside(cell) or t._blocked.has(cell) or t.path.has(cell) and art != "torch":
		return
	var p := {"art": art, "cell": cell, "block": t.PROPS[art].block != Vector2.ZERO and not art in t.PEBBLES}
	t.props.append(p)
	if p.block:
		t._block_collider(p)


func _carpet(at: Vector2i) -> void:
	for y in 2:
		for x in 2:
			var c := at + Vector2i(x, y)
			if corridors.has(c) and not t._blocked.has(c) and not t.path.has(c):
				t.deco[c] = t.FLOWER_CARPET + Vector2i(x * 2, y * 2)


# The extras along the corridors.
func _extras() -> void:
	var ends := _dead_ends()
	var ex: Array = r.extras
	if "chests" in ex:
		var n := 0
		for d in ends:
			if n >= 5 or d.x == 0 or d.x == cols - 1:
				continue
			var p := _room_px(d.x, d.y)
			_prop(["chest", "chest_b", "chest_c", "chest_d"][rng.randi() % 4], p + _dead_end_corner(d))
			n += 1
	if "flowers" in ex:
		var n := 0
		for d in ends:
			if n >= 4 or rng.randf() < 0.4:
				continue
			_carpet(_room_px(d.x, d.y))
			n += 1
	if "pots" in ex:
		var n := 0
		for d in ends:
			if n >= 4 or rng.randf() < 0.5:
				continue
			_prop("flowerpot", _room_px(d.x, d.y) + _dead_end_corner(d))
			n += 1
	if "blooms" in ex:
		# Single flowers along the corridors.
		var keys: Array = corridors.keys()
		for k in 18:
			var c: Vector2i = keys[rng.randi() % keys.size()]
			if not t.deco.has(c) and not t.path.has(c) and not t._blocked.has(c):
				t.deco[c] = t.FLOWERS[rng.randi() % t.FLOWERS.size()]
	if "lanterns" in ex:
		var n := 0
		for j in rows:
			for i in cols:
				if n >= 7 or clear_rooms.has(Vector2i(i, j)) or _links(i, j).size() < 3 or rng.randf() < 0.4:
					continue
				# On the hedge at the junction's corner (the pillar), lighting
				# the crossing without standing in it.
				var cell := _room_px(i, j) + Vector2i(-1, -1)
				if not walls.has(cell):
					continue
				t.props.append({"art": "torch", "cell": cell, "block": true})
				t._block_collider(t.props.back())
				n += 1
	if "wall_trees" in ex:
		var want := 6 * ex.count("wall_trees")
		var placed := 0
		for k in 200:
			if placed >= want:
				break
			# A pillar where walls meet, not on the outer wall.
			var i := rng.randi_range(1, cols - 1)
			var j := rng.randi_range(2, rows - 1)
			var pillar := origin + Vector2i(i * step, j * step)
			# The trunk's collider reaches a cell west of the anchor: the
			# pillar's right column keeps it on the hedge.
			var anchor := pillar + Vector2i(wt - 1, rng.randi_range(0, wt - 1))
			if not walls.has(anchor) or not walls.has(anchor + Vector2i.LEFT):
				continue
			# Not over a clearing (a home, a pond, a camp) or the ways in
			# and out: the crown would hide them.
			var crowded := false
			for rect in clearings:
				var px := Rect2i(_room_px(rect.position.x, rect.position.y), Vector2i(rect.size.x * step - wt, rect.size.y * step - wt))
				if px.grow(3).has_point(anchor) or px.grow(3).has_point(anchor + Vector2i(0, -4)):
					crowded = true
			for gate_y in [_row_y(entrance_row), _row_y(exit_row)]:
				if absi(anchor.y - gate_y) <= 4 and (anchor.x <= origin.x + wt + 2 or anchor.x >= origin.x + size.x - wt - 3):
					crowded = true
			if crowded:
				continue
			var near := false
			for p in t.props:
				if p.has("art") and String(p.art) in t.TREES + t.SHADE_TREES and Vector2(p.cell - anchor).length() < 6.0:
					near = true
			if near:
				continue
			var tree := {"art": t.TREES[rng.randi() % t.TREES.size()], "cell": anchor, "block": true}
			var hits := false
			for cc in t._collider_cells(tree):
				if not walls.has(cc):
					hits = true
			if hits:
				continue
			t.props.append(tree)
			t._block_collider(tree)
			placed += 1


# The far corner of a dead end (away from its one way in).
func _dead_end_corner(d: Vector2i) -> Vector2i:
	var l: Vector2i = _links(d.x, d.y)[0] - d
	var x := 0 if l.x > 0 else c_w - 1
	var y := 0 if l.y > 0 else c_w - 1
	if l.x != 0:
		y = rng.randi_range(0, c_w - 1)
	else:
		x = rng.randi_range(0, c_w - 1)
	return Vector2i(x, y)
