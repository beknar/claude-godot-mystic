class_name GateRoads
extends RefCounted
## node-gates: an opening near the middle of each of the four map edges, so
## the walker can leave the map north, east, south, or west. Laid right after
## the recipe's layout, before the path is autotiled:
##
## - A road already running off that edge is the gate (the crossroads'
##   trunks, the pastoral road from the west).
## - Otherwise a cobble road two cells wide runs in from the edge and joins
##   the recipe's path, in an L or a three-leg dogleg, using the path's own
##   autotile (it is just more path). The edge is moved inward past anything
##   solid on it (the Deep forest's canopy wall), so the road can start at
##   the first open row.
## - Failing every road, a trail: two open lawn cells on the edge reachable
##   from the spawn, kept clear of trees and props.
##
## Each gate is added to the terrain's goals, so hedgerows and brooks that
## would cut it off are dropped, and PaintedTerrain._verify checks that every
## gate is reachable from the spawn.

const SIDES := ["n", "e", "s", "w"]
const CANDIDATES := 14 # edge positions tried per side, middle first
const TARGETS := 6 # nearest path joins tried per edge position
const INSET := 6 # how far in from the edge a gate may start


static func lay(t: PaintedTerrain, rng: RandomNumberGenerator) -> bool:
	t.gate_cells = {}
	for side in SIDES:
		var g := _edge_road(t, side)
		if g.is_empty():
			g = _new_road(t, side, rng)
		if g.is_empty():
			g = _trail(t, side, rng)
		if g.is_empty():
			return false
		t.gate_cells[side] = g
		t.goals.append(g.cell)
	return true


## The two cells of an opening along its edge, from its anchor cell.
static func opening(side: String, cell: Vector2i) -> Array[Vector2i]:
	var along := Vector2i(1, 0) if side in ["n", "s"] else Vector2i(0, 1)
	return [cell, cell + along]


# A road the layout already ran off this edge: the opening nearest the middle.
static func _edge_road(t: PaintedTerrain, side: String) -> Dictionary:
	var best := Vector2i(-1, -1)
	var best_d := 1 << 20
	var n := PaintedTerrain.WIDTH if side in ["n", "s"] else PaintedTerrain.HEIGHT
	for i in n - 1:
		var c := _edge_cell(side, i, 0)
		var ok := true
		for k in opening(side, c):
			if not t.path.has(k):
				ok = false
		if not ok:
			continue
		var d := absi(i - n / 2)
		if d < best_d:
			best_d = d
			best = c
	if best.x < 0:
		return {}
	return {"cell": best, "kind": "road"}


# A new road from the edge (or the first open row in from it) to the path.
static func _new_road(t: PaintedTerrain, side: String, rng: RandomNumberGenerator) -> Dictionary:
	var joins := _joins(t)
	if joins.is_empty():
		return {}
	for i in _positions(side, rng):
		var start := _start(t, side, i)
		if start.x < 0:
			continue
		var near := joins.duplicate()
		near.sort_custom(func(a, b): return _manhattan(a, start) < _manhattan(b, start))
		for target in near.slice(0, TARGETS):
			for shape in _shapes(side, start, target, rng):
				if _try_route(t, shape):
					return {"cell": start, "kind": "road"}
	return {}


# Two open cells on the edge (or a few rows in) that the spawn reaches; the
# ground just inside is claimed, so no tree or prop lands on it.
static func _trail(t: PaintedTerrain, side: String, rng: RandomNumberGenerator) -> Dictionary:
	for i in _positions(side, rng):
		var start := _start(t, side, i)
		if start.x < 0:
			continue
		var ok := true
		for k in opening(side, start):
			if not t.walkable(k) or not t._reaches(t.spawn, k):
				ok = false
		if not ok:
			continue
		var inward := _inward(side)
		for depth in 4:
			for k in opening(side, start):
				var c: Vector2i = k + inward * depth
				if t._inside(c):
					t._taken[c] = true
		return {"cell": start, "kind": "trail"}
	return {}


# Edge positions along a side, nearest the middle first, a little shuffled.
static func _positions(side: String, rng: RandomNumberGenerator) -> Array[int]:
	var n := PaintedTerrain.WIDTH if side in ["n", "s"] else PaintedTerrain.HEIGHT
	var lo := 6 if side in ["n", "s"] else 5
	var hi := n - 8 if side in ["n", "s"] else n - 7
	var scored: Array = []
	for i in range(lo, hi + 1):
		scored.append([absf(i - n / 2.0) + rng.randf() * 6.0, i])
	scored.sort_custom(func(a, b): return a[0] < b[0])
	var out: Array[int] = []
	for s in scored.slice(0, CANDIDATES):
		out.append(s[1])
	return out


# The anchor cell of a two-wide road start at position `i` along `side`,
# moved inward past solid ground (at most INSET rows), or (-1, -1).
static func _start(t: PaintedTerrain, side: String, i: int) -> Vector2i:
	for depth in INSET + 1:
		var c := _edge_cell(side, i, depth)
		var clear := true
		for k in _block(c):
			if not t._inside(k) or (t._solid.has(k) and not t.path.has(k)) or t._blocked.has(k):
				clear = false
		if clear:
			return c
	return Vector2i(-1, -1)


# The anchor (top-left) of a road's 2 x 2 at position `i`, `depth` rows in.
static func _edge_cell(side: String, i: int, depth: int) -> Vector2i:
	match side:
		"n":
			return Vector2i(i, depth)
		"s":
			return Vector2i(i, PaintedTerrain.HEIGHT - 2 - depth)
		"e":
			return Vector2i(PaintedTerrain.WIDTH - 2 - depth, i)
		_:
			return Vector2i(depth, i)


static func _inward(side: String) -> Vector2i:
	return {"n": Vector2i(0, 1), "s": Vector2i(0, -1), "e": Vector2i(-1, 0), "w": Vector2i(1, 0)}[side]


static func _block(c: Vector2i) -> Array[Vector2i]:
	return [c, c + Vector2i(1, 0), c + Vector2i(0, 1), c + Vector2i(1, 1)]


# Path cells a road can end on: the top-left of a 2 x 2 of path, so the new
# two-wide road lies over the tube instead of sticking out of its side.
static func _joins(t: PaintedTerrain) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in t.path:
		var ok := true
		for k in _block(c):
			if not t.path.has(k):
				ok = false
		if ok:
			out.append(c)
	out.sort()
	return out


# Route shapes from `start` to `target`: straight in then across (an L), or a
# dogleg with its middle leg at a random depth. Every leg is axis aligned.
static func _shapes(side: String, start: Vector2i, target: Vector2i, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var vertical := side in ["n", "s"]
	var corner := Vector2i(start.x, target.y) if vertical else Vector2i(target.x, start.y)
	var lo := mini(start.y, target.y) if vertical else mini(start.x, target.x)
	var hi := maxi(start.y, target.y) if vertical else maxi(start.x, target.x)
	if hi - lo >= 8:
		var k := rng.randi_range(lo + 3, hi - 3)
		var a := Vector2i(start.x, k) if vertical else Vector2i(k, start.y)
		var b := Vector2i(target.x, k) if vertical else Vector2i(k, target.y)
		out.append(_clean([start, a, b, target]))
	out.append(_clean([start, corner, target]))
	return out


# Drops repeated points (a leg of length zero).
static func _clean(points: Array) -> Array:
	var out: Array = []
	for p in points:
		if out.is_empty() or out[-1] != p:
			out.append(p)
	return out


# Lays the route as path and keeps it only if the whole path still autotiles.
static func _try_route(t: PaintedTerrain, points: Array) -> bool:
	if points.size() < 2:
		return false
	# Only over open lawn: never across a plateau, water, a fence, or stairs.
	for i in range(points.size() - 1):
		var lo: Vector2i = points[i].min(points[i + 1])
		var hi: Vector2i = points[i].max(points[i + 1])
		for y in range(lo.y, hi.y + 2):
			for x in range(lo.x, hi.x + 2):
				var c := Vector2i(x, y)
				if t.path.has(c):
					continue
				if t.plateau.has(c) or t.water.has(c) or t.fence.has(c) or t.stairs.has(c) or t.ramps.has(c) or t._blocked.has(c):
					return false
	var path_before := t.path.duplicate()
	var solid_before := t._solid.duplicate()
	var taken_before := t._taken.duplicate()
	if t._route(points, true) and t._autotile_path():
		return true
	for c in t.path.keys():
		if not path_before.has(c):
			t.features.erase(c)
	t.path = path_before
	t._solid = solid_before
	t._taken = taken_before
	return false


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
