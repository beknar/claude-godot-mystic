class_name CaveMaze
extends RefCounted
## maze-greencaves: rock mazes on the Green Caves sheet, laid into a
## CaveTerrain (cave_terrain.gd with `maze` on) so the rest of the cave
## pipeline paints and fills them as any cave map: the floor and its dark
## zones, the pools and their halos, the homes, scatter in the antechambers,
## the ambience (drips from every face, glowworms, glints, bats, dust), the
## animals, and the checks.
##
## A maze is a grid of rooms, each a corridor C cells wide (2, or 3 on the
## wide types). Its walls are the sheet's wall mass, two cells wide:
##   a horizontal wall is two rows of black top (rim all round) over the two
##     rows of rock face the sheet hangs under every bottom edge, so it fills
##     a band of four rows between two rows of rooms;
##   a vertical wall is two columns of top (the sheet's left and right edge
##     columns (9-10, 12-14)) from the band above down to the band below;
##   where a vertical wall drops from a horizontal one, the sheet's inner
##     corners (9, 11) and (10, 11) turn the rim down beside it, the faces of
##     the wall either side meeting its edge; a pillar left standing alone
##     ends in the sheet's rounded end (12-13, 12-14).
## Walls and faces block where they are drawn. The top band runs the map's
## width (the cave's back wall), so does the bottom one; the maze stands
## between two antechambers of open floor, the entrance a gap in its west
## wall and the exit one in its east wall (the room there farthest from the
## entrance), each lit by a pair of torches on the face over the gap, with a
## signpost in the antechamber. On the mine types a rail track runs the way
## through, edge to edge.
##
## Recipe keys (MAZE_RECIPES): floor light | dark | moss; algo backtrack |
## prim | kruskal | sidewinder | rings; braid (share of dead ends opened);
## corridor (2 or 3); faces "" | moss | skull (face variants); clearings
## [[kind, rooms wide, rooms tall, where]]; extras: rails, torches, tufts,
## plants, crystals, cones, bones, ores, chests, clutter, carts. Plus the
## cave keys the rest of the pipeline reads (zones, scatter, torches, pools,
## homes, rails).

const W := CaveTerrain.W
const H := CaveTerrain.H
const VW := 2 # a vertical wall's width
const HB := 4 # a horizontal wall's band: two rows of top, two of face

const MAZE_RECIPES := [
	# Light floor.
	{"name": "Rock labyrinth", "floor": "light", "algo": "backtrack", "extras": ["torches", "cones"], "zones": 0.12},
	{"name": "Branching tunnels", "floor": "light", "algo": "prim", "braid": 0.1, "clearings": [["pool", 3, 2, "center"]], "extras": ["torches", "cones", "plants"], "zones": 0.1},
	{"name": "Looping caverns", "floor": "light", "algo": "kruskal", "braid": 0.45, "clearings": [["camp", 2, 2, "random"]], "extras": ["torches", "cones"], "zones": 0.12},
	{"name": "Crystal maze", "floor": "light", "algo": "kruskal", "braid": 0.1, "clearings": [["crystals", 3, 2, "center"]], "extras": ["crystals", "torches"], "zones": 0.16},
	{"name": "Stalagmite maze", "floor": "light", "algo": "sidewinder", "braid": 0.1, "clearings": [["cones", 2, 2, "random"]], "extras": ["cones", "torches"], "zones": 0.12},
	{"name": "Spring maze", "floor": "light", "algo": "prim", "braid": 0.15, "clearings": [["pool", 3, 2, "west"], ["pool", 3, 2, "east"]], "extras": ["plants", "torches"], "zones": 0.1},
	{"name": "Flooded maze", "floor": "light", "algo": "kruskal", "braid": 0.1, "corridor": 3, "clearings": [["lake", 4, 2, "center"]], "extras": ["cones", "plants", "torches"], "zones": 0.12},
	{"name": "Echo halls", "floor": "light", "algo": "backtrack", "braid": 0.1, "corridor": 3, "extras": ["crystals", "cones", "torches"], "zones": 0.2},
	{"name": "Pillared maze", "floor": "light", "algo": "rings", "clearings": [["shrine", 3, 2, "center"]], "extras": ["crystals", "torches"], "zones": 0.16},
	{"name": "Cave hamlet maze", "floor": "light", "algo": "kruskal", "braid": 0.15, "clearings": [["home", 3, 3, "west"], ["home", 3, 3, "east"]], "extras": ["clutter", "torches"], "zones": 0.12},
	# Dark floor.
	{"name": "Mine maze", "floor": "dark", "algo": "backtrack", "clearings": [["mine", 2, 2, "random"]], "extras": ["rails", "ores", "carts", "torches"]},
	{"name": "Rail tunnels", "floor": "dark", "algo": "kruskal", "braid": 0.2, "clearings": [["coal", 2, 2, "random"]], "extras": ["rails", "carts", "torches"]},
	{"name": "Ossuary maze", "floor": "dark", "algo": "backtrack", "faces": "skull", "clearings": [["bones", 2, 2, "center"]], "extras": ["bones", "torches"]},
	{"name": "Treasure vault maze", "floor": "dark", "algo": "prim", "clearings": [["vault", 3, 2, "center"]], "extras": ["chests", "crystals", "torches"]},
	{"name": "Smugglers' maze", "floor": "dark", "algo": "kruskal", "braid": 0.1, "clearings": [["home", 3, 3, "west"], ["cache", 2, 2, "east"]], "extras": ["clutter", "torches"]},
	{"name": "Ore vein maze", "floor": "dark", "algo": "sidewinder", "braid": 0.1, "extras": ["ores", "crystals", "torches"]},
	{"name": "Dark depths maze", "floor": "dark", "algo": "kruskal", "braid": 0.3, "corridor": 3, "clearings": [["pool", 3, 2, "center"]], "extras": ["cones", "torches"]},
	{"name": "Root cellar maze", "floor": "dark", "algo": "backtrack", "braid": 0.1, "clearings": [["home", 3, 3, "center"]], "extras": ["clutter", "torches"]},
	# Moss floor.
	{"name": "Mossy labyrinth", "floor": "moss", "algo": "backtrack", "faces": "moss", "extras": ["tufts", "plants", "torches"]},
	{"name": "Overgrown mine maze", "floor": "moss", "algo": "kruskal", "braid": 0.15, "faces": "moss", "clearings": [["grove", 2, 2, "random"]], "extras": ["rails", "tufts", "plants", "ores"]},
	{"name": "Sunken garden maze", "floor": "moss", "algo": "prim", "braid": 0.2, "faces": "moss", "clearings": [["grove", 3, 2, "west"], ["pool", 3, 2, "east"]], "extras": ["tufts", "plants"]},
	{"name": "Hermit's maze", "floor": "moss", "algo": "kruskal", "braid": 0.15, "clearings": [["home", 3, 3, "west"], ["camp", 2, 2, "east"]], "extras": ["tufts", "plants", "torches"]},
	{"name": "Fern hollows", "floor": "moss", "algo": "sidewinder", "braid": 0.1, "corridor": 3, "faces": "moss", "clearings": [["grove", 2, 2, "random"], ["grove", 2, 2, "random"]], "extras": ["tufts", "plants"]},
	{"name": "Moss rings", "floor": "moss", "algo": "rings", "faces": "moss", "clearings": [["pool", 3, 2, "center"]], "extras": ["tufts", "plants", "torches"]},
]

## The keys every maze shares (cave_terrain.gd reads the cave ones).
const BASE := {"braid": 0.0, "corridor": 2, "faces": "", "clearings": [], "extras": [], "band": false, "islands": [0, 0],
	"terraces": [0, 0], "pools": [0, 0], "zones": 0.0, "piece": "", "torches": 1,
	"scatter": [["ROCKS", 4], ["CONES", 2], ["CRYSTALS", 2]]}


static func recipes() -> Array:
	var out: Array = []
	for r in MAZE_RECIPES:
		var full: Dictionary = BASE.duplicate(true)
		full.merge(r, true)
		var homes := 0
		var pools := 0
		for spec in full.clearings:
			if spec[0] == "home":
				homes += 1
			elif spec[0] == "pool":
				pools += 1
			elif spec[0] == "lake":
				full.lake = true
		full.homes = [homes, homes]
		full.pools = [pools, pools]
		full.rails = "rails" in full.extras
		if full.floor == "moss":
			full.scatter = [["PLANTS", 4], ["TREES", 2], ["TUFTS", 16], ["ROCKS", 2]]
		elif full.floor == "dark":
			full.scatter = [["ROCKS", 4], ["ORES", 2], ["CLUTTER", 2]]
		out.append(full)
	return out


var t # the CaveTerrain being laid out
var r: Dictionary
var rng: RandomNumberGenerator
var c_w := 2
var step := Vector2i(4, 6)
var cols := 12
var rows := 6
var origin := Vector2i.ZERO
var size := Vector2i.ZERO
var open := {} # Vector3i(i, j, d) -> true: d 0 = the wall east of room (i, j), 1 = south
var clear_rooms := {} # Vector2i room -> clearing index
var clearings: Array[Rect2i] = [] # in rooms
var tops := {} # the walls' black tops
var faces := {} # their faces
var corridors := {} # walkable maze cells
var entrance_row := 0
var exit_row := 0
var _prop_at := {} # cells a prop of the maze's stands on


func _init(p_t, p_rng: RandomNumberGenerator) -> void:
	t = p_t
	r = t.recipe
	rng = p_rng


## Lays the maze into the terrain; false if this attempt does not fit.
func lay() -> bool:
	c_w = r.corridor
	step = Vector2i(c_w + VW, c_w + HB)
	var margin := 4
	cols = (W - 2 * margin - VW) / step.x
	rows = (H - HB) / step.y
	size = Vector2i(cols * step.x + VW, rows * step.y + HB)
	origin = Vector2i((W - size.x) / 2, H - size.y)
	_carve_maze()
	_place_clearings()
	_braid(r.braid)
	entrance_row = rng.randi_range(0, rows - 1)
	exit_row = _farthest_east(entrance_row)
	_build_walls()
	_paint_walls()
	_find_corridors()
	_entrances()
	if "rails" in r.extras and not _rails():
		return false
	if not _fill_clearings():
		return false
	_extras()
	t.maze_info = {"entrance": t.spawn, "exit": t.goal, "corridors": corridors, "rooms": Vector2i(cols, rows),
		"dead_ends": _dead_ends().size(), "clearings": clearings.size()}
	return true


## Corridor cells taken from the cave's own scatter (props of its own come
## only where the maze puts them).
func claim_corridors() -> void:
	for c: Vector2i in corridors:
		t._occupied[c] = true


## The maze cells the walker cannot reach from the spawn (none, on a good
## map); goals (the exit, the homes' entry rooms) count too.
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
	return origin + Vector2i(VW + i * step.x, HB + j * step.y)


func _line_top(j: int) -> int:
	return origin.y + j * step.y


func _vline_x(i: int) -> int:
	return origin.x + i * step.x


func _clearing_px(rect: Rect2i) -> Rect2i:
	var p := _room_px(rect.position.x, rect.position.y)
	return Rect2i(p, Vector2i(rect.size.x * step.x - VW, rect.size.y * step.y - HB))


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


## Rings round the middle: each ring a loop broken once, one door inward;
## rooms the breaks cut off are joined back.
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
		if not shut.is_empty():
			var n: Vector2i = shut[rng.randi() % shut.size()]
			open[_wall_key(d.x, d.y, n.x, n.y)] = true


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
				"west": at = Vector2i(rng.randi_range(1, maxi(1, cols / 3 - 1)), rng.randi_range(0, rows - ch))
				"east": at = Vector2i(rng.randi_range(mini(cols * 2 / 3, cols - cw - 1), cols - cw - 1), rng.randi_range(0, rows - ch))
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

## The black tops: the top band (the back wall) and the bottom band across
## the map, every horizontal wall but its gaps, every pillar but those inside
## a clearing, every vertical wall still standing.
func _build_walls() -> void:
	tops.clear()
	faces.clear()
	for y in range(0, origin.y + 2):
		for x in W:
			tops[Vector2i(x, y)] = true
	for x in W:
		for k in 2:
			tops[Vector2i(x, _line_top(rows) + k)] = true
	for j in range(1, rows):
		var y := _line_top(j)
		for x in range(origin.x, origin.x + size.x):
			tops[Vector2i(x, y)] = true
			tops[Vector2i(x, y + 1)] = true
		for i in cols:
			if open.has(Vector3i(i, j - 1, 1)):
				var p := _room_px(i, j)
				for x in c_w:
					for k in 2:
						tops.erase(Vector2i(p.x + x, y + k))
	# Pillars inside a clearing come down.
	for j in range(1, rows):
		for i in range(1, cols):
			var k: int = clear_rooms.get(Vector2i(i - 1, j - 1), -1)
			if k >= 0 and clear_rooms.get(Vector2i(i, j - 1), -1) == k and clear_rooms.get(Vector2i(i - 1, j), -1) == k \
					and clear_rooms.get(Vector2i(i, j), -1) == k:
				for dx in VW:
					for dy in 2:
						tops.erase(Vector2i(_vline_x(i) + dx, _line_top(j) + dy))
	# Vertical walls: from under the band above to the band below.
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
				for dx in VW:
					tops[Vector2i(_vline_x(i) + dx, y)] = true


func _mask(c: Vector2i) -> int:
	var m := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = c + dirs[i]
		if tops.has(n) or not t._inside(n):
			m |= 1 << i
	return m


func _open_at(c: Vector2i) -> bool:
	return t._inside(c) and not tops.has(c)


## The sheet's pieces for the tops, the faces under every bottom edge (moss
## or skull variants on the plain middles), the rounded end under a lone
## pillar.
func _paint_walls() -> void:
	var style: String = r.faces
	var ends := {}
	for c: Vector2i in tops:
		var m := _mask(c)
		var a: Vector2i
		if m == 15:
			var sw := _open_at(c + Vector2i(-1, 1))
			var se := _open_at(c + Vector2i(1, 1))
			a = Vector2i(9, 11) if sw and not se else (Vector2i(10, 11) if se and not sw else Vector2i(6, 12))
		elif m == 7:
			a = Vector2i(9, 12 + posmod(c.y, 3))
		elif m == 13:
			a = Vector2i(10, 12 + posmod(c.y, 3))
		elif m == 3 and _mask(c + Vector2i.RIGHT) == 9 and tops.has(c + Vector2i.RIGHT):
			# A two-wide wall ending downward: the rounded end.
			a = Vector2i(12, 12)
			ends[c] = 0
			ends[c + Vector2i.RIGHT] = 1
		elif ends.has(c):
			a = Vector2i(13, 12)
		else:
			a = CaveTerrain.WALL_TOP + CaveTerrain.ROLES.get(m, Vector2i(1, 1))
		t.features[c] = a
		t.kind[t._i(c)] = CaveTerrain.WALL
	for c: Vector2i in ends:
		t.features[c] = Vector2i(12 + ends[c], 12)
	for c: Vector2i in tops:
		var below := c + Vector2i.DOWN
		if not t._inside(below) or tops.has(below):
			continue
		if ends.has(c):
			for d in 2:
				_face(c + Vector2i(0, 1 + d), Vector2i(12 + ends[c], 13 + d))
			continue
		var west: bool = tops.has(c + Vector2i.LEFT) or c.x == 0
		var east: bool = tops.has(c + Vector2i.RIGHT) or c.x == W - 1
		var col := 1 if west and east else (0 if not west else 2)
		var chance := 0.6 if style in ["moss", "skull"] else 0.3
		if col == 1 and _mask(c) == 11 and rng.randf() < chance:
			var v: int = CaveTerrain.WALL_FACE_VARIANTS[rng.randi() % CaveTerrain.WALL_FACE_VARIANTS.size()]
			if style == "moss":
				v = [14, 15, 16][rng.randi() % 3]
			elif style == "skull" and rng.randf() < 0.6:
				v = CaveTerrain.SKULL_FACE
			elif style == "" and v >= 14:
				v = [10, 11, 12, 13][rng.randi() % 4] # mossy faces on moss mazes
			t.features[c] = Vector2i(v, 16)
			for d in 2:
				_face(c + Vector2i(0, 1 + d), Vector2i(v, 17 + d))
		else:
			for d in 2:
				_face(c + Vector2i(0, 1 + d), CaveTerrain.WALL_FACE + Vector2i(col, d))


func _face(c: Vector2i, atlas: Vector2i) -> void:
	if not t._inside(c) or tops.has(c):
		return
	faces[c] = true
	t.kind[t._i(c)] = CaveTerrain.FACE
	t.features[c] = atlas


func _find_corridors() -> void:
	corridors.clear()
	for y in range(_line_top(0) + 2, _line_top(rows)):
		for x in range(origin.x, origin.x + size.x):
			var c := Vector2i(x, y)
			if not tops.has(c) and not faces.has(c):
				corridors[c] = true


# ---------------------------------------------------------------- gates

func _gate_row(j: int) -> int:
	return _room_px(0, j).y + c_w - 1


## The ways in and out: a gap in the west wall and one in the east, lit by
## torches on the face over the gap, a signpost in the antechamber; the
## walker starts at the west edge, the goal at the east one.
func _entrances() -> void:
	for k in 2:
		var j := entrance_row if k == 0 else exit_row
		var x0 := _vline_x(0 if k == 0 else cols)
		var face_y := _line_top(j) + 3 # the lower face row over the gap
		for dx in VW:
			var c := Vector2i(x0 + dx, face_y)
			if faces.has(c):
				_torch(c)
		var p := _room_px(0, j)
		var sx := x0 - 2 if k == 0 else x0 + VW + 1
		_put("signpost", Vector2i(sx, p.y), Rect2i())
	t.spawn = Vector2i(1, _gate_row(entrance_row))
	t.goal = Vector2i(W - 2, _gate_row(exit_row))
	t.goals.assign([t.goal])


func _torch(c: Vector2i) -> void:
	t.props.append({"art": "torch", "cell": c})
	t.fires.append(c)
	_prop_at[c] = true


## A rail track along the way through: from the west edge through the
## entrance, room to room by the maze, out of the exit to the east edge.
func _rails() -> bool:
	var a := c_w / 2
	var from := Vector2i(0, entrance_row)
	var to := Vector2i(cols - 1, exit_row)
	var prev := {from: from}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for l in _links(c.x, c.y):
			if not prev.has(l):
				prev[l] = c
				queue.append(l)
	if not prev.has(to):
		return false
	var rooms: Array[Vector2i] = [to]
	while rooms[-1] != from:
		rooms.append(prev[rooms[-1]])
	rooms.reverse()
	var pts: Array[Vector2i] = [Vector2i(0, _room_px(0, entrance_row).y + a)]
	for room in rooms:
		pts.append(_room_px(room.x, room.y) + Vector2i(a, a))
	pts.append(Vector2i(W - 1, _room_px(0, exit_row).y + a))
	var cells: Array[Vector2i] = []
	for k in range(pts.size() - 1):
		var p := pts[k]
		var q := pts[k + 1]
		var d := Vector2i(signi(q.x - p.x), signi(q.y - p.y))
		var c := p
		while c != q:
			if cells.is_empty() or cells[-1] != c:
				cells.append(c)
			c += d
	cells.append(pts[-1])
	for c in cells:
		if not t._inside(c) or t.kind[t._i(c)] != CaveTerrain.FLOOR:
			return false
	for i in cells.size():
		var c: Vector2i = cells[i]
		var dirs := {}
		if i > 0:
			dirs[cells[i - 1] - c] = true
		if i + 1 < cells.size():
			dirs[cells[i + 1] - c] = true
		var tile := CaveTerrain.RAIL_V if dirs.has(Vector2i.UP) or dirs.has(Vector2i.DOWN) else CaveTerrain.RAIL_H
		if dirs.size() == 2 and not (dirs.has(Vector2i.LEFT) and dirs.has(Vector2i.RIGHT)) and not (dirs.has(Vector2i.UP) and dirs.has(Vector2i.DOWN)):
			tile = CaveTerrain.RAIL_CURVE[("E" if dirs.has(Vector2i.RIGHT) else "W") + ("S" if dirs.has(Vector2i.DOWN) else "N")]
		t.features[c] = tile
		t.rails[c] = true
	t.notes.append("rails %d cells" % cells.size())
	return true


# ---------------------------------------------------------------- props

## A prop of the maze's on free floor: its footprint on maze floor not taken,
## its collider row only inside `within` (a clearing inside its lane) or, in
## a dead end (`within` the room), anywhere in it.
func _put(art: String, anchor: Vector2i, within: Rect2i, allow_block := true) -> bool:
	var p: Dictionary = CaveTerrain.PROPS[art]
	var foot: Rect2i = p.foot_cells
	if not allow_block and p.block != Vector2.ZERO:
		return false
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			var c := anchor + Vector2i(x, y)
			if not t._inside(c) or t.kind[t._i(c)] != CaveTerrain.FLOOR or _prop_at.has(c) or t.rails.has(c) or c == t.spawn:
				return false
			if p.block != Vector2.ZERO and y == foot.end.y - 1 and corridors.has(c) and not within.has_point(c):
				return false
	t.props.append({"art": art, "cell": anchor})
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			_prop_at[anchor + Vector2i(x, y)] = true
			t._occupied[anchor + Vector2i(x, y)] = true
	if p.block != Vector2.ZERO:
		for x in range(foot.position.x, foot.end.x):
			t.blocked[anchor + Vector2i(x, foot.end.y - 1)] = true
	if p.tag == "fire" or p.tag == "torch":
		t.fires.append(anchor)
	return true


func _near(arts: Array, count: int, center: Vector2i, radius: int, within: Rect2i) -> int:
	var placed := 0
	for i in count * 30:
		if placed >= count:
			break
		var c := center + Vector2i(rng.randi_range(-radius, radius), rng.randi_range(-radius, radius))
		if within.has_point(c) and _put(arts[rng.randi() % arts.size()], c, within):
			placed += 1
	return placed


# ---------------------------------------------------------------- clearings

func _fill_clearings() -> bool:
	for n in clearings.size():
		var spec: Array = r.clearings[n]
		var px := _clearing_px(clearings[n])
		var inner := px.grow(-1) # a lane round what stands in it
		var mid := inner.position + inner.size / 2
		match spec[0]:
			"pool", "lake":
				var w := inner.grow(-1)
				if w.size.x < 2 or w.size.y < 2:
					return false
				t._pool_at(w, spec[0] == "lake")
				_near(["plant", "grass_clump", "cone_small"], 3, mid, 8, px)
			"home":
				if not _home(px):
					return false
			"camp":
				_put("campfire", mid, inner)
				_near(["branch", "branch_moss"], 1, mid, 2, inner)
				_near(["crates", "barrel", "chest"], 2, mid, 3, inner)
				_near(["embers"], 1, mid, 2, inner)
			"crystals":
				for k in 8:
					var ang := TAU * k / 8.0
					# Crystals at the four points, shards between (a ring that
					# never shuts anything in).
					_put(CaveTerrain.CRYSTALS[rng.randi() % 3 + (0 if k % 2 == 0 else 3)], mid + Vector2i(roundi(cos(ang) * minf(3.0, inner.size.x / 2.0 - 1)), roundi(sin(ang) * minf(2.0, inner.size.y / 2.0 - 1))), inner)
				_put("rock_tree_crystal", mid + Vector2i(-1, 0), inner)
			"cones":
				_near(["cone", "cone_b", "cone_small"], 7, mid, 3, inner)
			"shrine":
				_put("pillars", mid + Vector2i(-1, -1), inner)
				_near(["crystal_violet", "crystal_cyan", "crystal_blue"], 4, mid, 3, inner)
				_put("chest_open", mid + Vector2i(0, 1), inner)
			"mine":
				_near(["cart", "cart_empty"], 1, mid, 2, inner)
				_near(["coal_pile", "coal"], 3, mid, 2, inner)
				_near(["crates", "barrel"], 1, mid, 2, inner)
			"coal":
				_near(["coal_pile", "coal"], 5, mid, 2, inner)
				_near(["cart_empty"], 1, mid, 2, inner)
			"bones":
				_near(["skull", "skull_b", "rock_skull"], 5, mid, 2, inner)
				_put("pillar", mid, inner)
			"vault":
				_near(["chest", "chest_b", "chest_open"], 3, mid, 3, inner)
				_near(["pillar"], 2, mid, 3, inner)
				_near(["crystal_violet", "shard_violet"], 3, mid, 3, inner)
			"cache":
				_near(["crates", "crate", "barrel", "barrel_b", "chest", "chest_b"], 4, mid, 2, inner)
				_near(["ladder", "board"], 1, mid, 2, inner)
			"grove":
				_near(["tree_mossy", "rock_tree_moss"], 1, mid, 1, inner)
				_near(["plant", "plant_flower", "grass_clump"], 4, mid, 3, inner)
				for c in _cells(px):
					if rng.randf() < 0.3 and not _prop_at.has(c) and not t.deco.has(c):
						t.deco[c] = CaveTerrain.TUFTS[rng.randi() % CaveTerrain.TUFTS.size()]
	return true


## A cave home (interior_plan.gd, built in as cave_terrain.gd builds them)
## at the top of the clearing, a lane round it, its arched doorway facing
## south; the entry room is a goal.
func _home(px: Rect2i) -> bool:
	var cap := Vector2i(px.size.x - 2, px.size.y - 3)
	if cap.x < 7 or cap.y < 8:
		return false
	var plan := InteriorPlan.new().generate(t.map_id * 7919 + t.attempt * 131 + t.homes.size() * 17, 1,
		{"black": true, "exit_width": 3, "max_size": cap})
	var need: Vector2i = plan.size + Vector2i(0, 2)
	if need.x > px.size.x - 2 or need.y > px.size.y - 1:
		return false
	var at := Vector2i(px.position.x + (px.size.x - need.x) / 2, px.position.y)
	t._home_at(at, plan)
	for y in range(at.y, at.y + need.y):
		for x in range(at.x, at.x + need.x):
			corridors.erase(Vector2i(x, y))
	return true


func _cells(rect: Rect2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			out.append(Vector2i(x, y))
	return out


# ---------------------------------------------------------------- extras

## A dead end's room as a rect.
func _room_rect(d: Vector2i) -> Rect2i:
	return Rect2i(_room_px(d.x, d.y), Vector2i(c_w, c_w))


func _extras() -> void:
	var ex: Array = r.extras
	var ends := _dead_ends()
	var keys: Array = corridors.keys()
	keys.sort()
	var bits: Array[String] = []
	if "cones" in ex: bits.append_array(["cone_small", "cone_small"])
	if "crystals" in ex: bits.append_array(["shard_cyan", "shard_blue", "shard_violet"])
	if "bones" in ex: bits.append_array(["skull", "skull_b"])
	if "ores" in ex: bits.append_array(["coal", "coal"])
	if "plants" in ex: bits.append_array(["plant", "plant_flower", "grass_clump"])
	if bits.is_empty():
		bits = ["cone_small", "shard_cyan", "coal"]
	# Small bits along the corridors (nothing that blocks).
	for k in 40:
		var c: Vector2i = keys[rng.randi() % keys.size()]
		_put(bits[rng.randi() % bits.size()], c, Rect2i(), false)
	if "tufts" in ex:
		for c: Vector2i in keys:
			if rng.randf() < 0.14 and t.kind[t._i(c)] == CaveTerrain.FLOOR and not _prop_at.has(c) and not t.rails.has(c):
				t.deco[c] = CaveTerrain.TUFTS[rng.randi() % CaveTerrain.TUFTS.size()]
	# Dead ends: what blocks stands here, in the far part of the room.
	var dead: Array[String] = []
	if "chests" in ex: dead.append_array(["chest", "chest_b", "chest_open"])
	if "ores" in ex: dead.append_array(["ore_silver", "ore_gold", "ore_dark"])
	if "crystals" in ex: dead.append_array(["crystal_cyan", "crystal_blue", "crystal_violet"])
	if "cones" in ex: dead.append_array(["cone", "cone_b"])
	if "clutter" in ex: dead.append_array(["crate", "barrel", "barrel_b", "trough"])
	if "carts" in ex: dead.append_array(["cart", "cart_empty", "coal_pile"])
	if "bones" in ex: dead.append_array(["rock_skull", "skull"])
	if "plants" in ex: dead.append_array(["rock_tree_moss", "tree_mossy"] if r.floor == "moss" else ["rock_moss"])
	if not dead.is_empty():
		var n := 0
		for d in ends:
			if n >= 8 or rng.randf() < 0.3:
				continue
			var room := _room_rect(d)
			var far := room.position + _far_corner(d)
			if _put(dead[rng.randi() % dead.size()], far, room) or _put(dead[rng.randi() % dead.size()], room.position, room):
				n += 1
	if "torches" in ex:
		_torches(6, Rect2i(origin, size))


## The far corner of a dead end (away from its one way in).
func _far_corner(d: Vector2i) -> Vector2i:
	var l: Vector2i = _links(d.x, d.y)[0] - d
	var x := 0 if l.x > 0 else c_w - 1
	var y := 0 if l.y > 0 else c_w - 1
	if l.x != 0:
		y = rng.randi_range(0, c_w - 1)
	else:
		x = rng.randi_range(0, c_w - 1)
	return Vector2i(x, y)


## Wall torches on the faces over the corridors (the lower face row, a
## middle face with floor below), spaced apart.
func _torches(want: int, within: Rect2i, gap := 6.0) -> int:
	var cands: Array[Vector2i] = []
	for c: Vector2i in faces:
		if within.has_point(c) and not faces.has(c + Vector2i.DOWN) and corridors.has(c + Vector2i.DOWN) \
				and faces.has(c + Vector2i.LEFT) and faces.has(c + Vector2i.RIGHT):
			cands.append(c)
	cands.sort()
	var placed := 0
	for k in 60:
		if placed >= want or cands.is_empty():
			break
		var c: Vector2i = cands[rng.randi() % cands.size()]
		var near := false
		for f in t.fires:
			if Vector2(f - c).length() < gap:
				near = true
		if near:
			continue
		_torch(c)
		placed += 1
	return placed


# ---------------------------------------------------------------- liveliness

## An anchor for a weak camera window: a campfire in a dead end in it (embers
## beside), else a pair of wall torches on its faces, else a campfire in the
## corner of a room in it (a two-wide room stays open round it), else
## torches closer together; false if none fits.
func floor_anchor(rect: Rect2i) -> bool:
	var ends := _dead_ends()
	for k in range(ends.size() - 1, 0, -1): # shuffled with the map's own rng
		var s := rng.randi_range(0, k)
		var tmp := ends[k]
		ends[k] = ends[s]
		ends[s] = tmp
	for d in ends:
		var room := _room_rect(d)
		if not rect.grow(-2).encloses(room):
			continue
		var c := room.position + _far_corner(d)
		var near := false
		for f in t.fires:
			if Vector2(f - c).length() < 6.0:
				near = true
		if not near and _put("campfire", c, room):
			_near(["embers", "branch"], 1, c, 1, room)
			return true
	if _torches(2, rect.grow(-1)) > 0:
		return true
	var rooms: Array[Vector2i] = []
	for j in rows:
		for i in cols:
			var room := _room_rect(Vector2i(i, j))
			if not clear_rooms.has(Vector2i(i, j)) and rect.grow(-2).encloses(room) and i > 0 and i < cols - 1:
				rooms.append(Vector2i(i, j))
	for k in mini(12, rooms.size()):
		var room := _room_rect(rooms[rng.randi() % rooms.size()])
		var c := room.position + Vector2i(rng.randi_range(0, c_w - 1), rng.randi_range(0, c_w - 1))
		var near := false
		for f in t.fires:
			if Vector2(f - c).length() < 5.0:
				near = true
		if not near and _put("campfire", c, room):
			return true
	return _torches(2, rect.grow(-1), 3.0) > 0
