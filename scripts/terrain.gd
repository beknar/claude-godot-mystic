class_name MysticTerrain
extends RefCounted
## Tile-id grid for the Mystic Woods maps (AGENTS.md § Mystic Woods).
## Output is plains.png / decor_16x16.png atlas coordinates plus prop
## placements. Nothing here paints pixels.

const GRASS := 0
const DIRT := 1
const CLIFF := 2
const WATER := 3

const WIDTH := 70
const HEIGHT := 46

const CLIFF_ABOVE := 0.64
const WATER_BELOW := 0.36
const DRY_ABOVE := 0.40

const SPAWN_RADIUS := 5
const SHRINE_RADIUS := 4
const SHRINE_CANDIDATES := 40

const CLIFF_COST := 12.0
const WATER_COST := 8.0

const TREE_GAP := 6.5
const DECO_GAP := 3.2
const ROCK_GAP := 8.0

# Cardinal mask, N=1 E=2 S=4 W=8, to the dirt block in plains.png rows 0-3.
# The two-neighbor cells carry the rounded outer corner. Water uses the
# same layout at WATER_ROW.
const DIRT_TILES := {
	0: Vector2i(0, 3), 1: Vector2i(0, 2), 2: Vector2i(1, 3), 3: Vector2i(1, 2),
	4: Vector2i(0, 0), 5: Vector2i(0, 1), 6: Vector2i(1, 0), 7: Vector2i(1, 1),
	8: Vector2i(3, 3), 9: Vector2i(3, 2), 10: Vector2i(2, 3), 11: Vector2i(2, 2),
	12: Vector2i(3, 0), 13: Vector2i(3, 1), 14: Vector2i(2, 0), 15: Vector2i(2, 1),
}
const WATER_ROW := 8

# Plateau in rows 4-7. Rows 6 and 7 carry the south-facing wall; the sheet
# has no north wall, so the south rim is what reads as higher ground.
const PLATEAU_TILES := {
	0: Vector2i(0, 7), 1: Vector2i(0, 6), 2: Vector2i(1, 7), 3: Vector2i(1, 6),
	4: Vector2i(0, 4), 5: Vector2i(0, 5), 6: Vector2i(1, 4), 7: Vector2i(1, 5),
	8: Vector2i(3, 7), 9: Vector2i(3, 6), 10: Vector2i(2, 7), 11: Vector2i(2, 6),
	12: Vector2i(3, 4), 13: Vector2i(3, 5), 14: Vector2i(2, 4), 15: Vector2i(2, 5),
}

# A fully surrounded dirt or water cell whose diagonal is open gets the
# pack's inner-corner cell. Open-diagonal bits: NE=1 SE=2 SW=4 NW=8.
const INNER_TILES := {
	2: Vector2i(4, 0), 4: Vector2i(5, 0), 1: Vector2i(4, 1), 8: Vector2i(5, 1),
	10: Vector2i(4, 2), 5: Vector2i(5, 2),
}

# Clean interior fills. plains.png has exactly one per terrain; every other
# look-alike cell carries a grass or hole fragment cut at its edge.
const DIRT_FILLS: Array[Vector2i] = [Vector2i(2, 1)]
const PLATEAU_FILLS: Array[Vector2i] = [Vector2i(2, 5)]

# decor_16x16.png cells. Their background is the meadow green.
const TUFTS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(3, 1)]
const FLOWERS: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]

const TREES: Array[String] = ["tree_a", "tree_b", "tree_c", "tree_d"]
const ROCKS: Array[String] = ["rock_0", "rock_1", "rock_2"]

# Cells a prop covers, relative to its anchor tile.
const FOOTPRINT := {
	"tree": Rect2i(-1, -3, 3, 4),
	"cypress": Rect2i(-1, -2, 2, 3),
	"rock": Rect2i(0, 0, 1, 1),
}

var seed_value := 0
var include_water := true

var kind := PackedByteArray()
var features := {} # Vector2i cell -> Vector2i plains.png atlas
var deco := {} # Vector2i cell -> Vector2i decor_16x16.png atlas
var props: Array[Dictionary] = [] # {art, cell}
var spawn := Vector2i.ZERO
var shrine := Vector2i.ZERO
var route_length := 0
var water_link := 0

var _rng := RandomNumberGenerator.new()
var _occupied := {}


static func plains_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in 12:
		for x in 6:
			if x >= 4 and y in [3, 7, 11]:
				continue # blank on the sheet
			cells.append(Vector2i(x, y))
	return cells


func generate(p_seed: int, p_include_water := true) -> String:
	seed_value = p_seed
	include_water = p_include_water
	_rng.seed = p_seed
	kind.resize(WIDTH * HEIGHT)
	features.clear()
	deco.clear()
	props.clear()
	_occupied.clear()

	_sample_biomes()
	for i in 3:
		_smooth()
	_erode(2)
	_cull(CLIFF, 40)
	_cull(WATER, 12)
	_place_arenas()
	_autotile()
	_carve_route()
	if include_water:
		_stamp_water_link()
	_autotile()
	var dirt_dups := _break_duplicates(DIRT, DIRT_FILLS)
	var plateau_dups := _break_duplicates(CLIFF, PLATEAU_FILLS)
	_scatter()
	return _verify(dirt_dups, plateau_dups)


func kind_at(cell: Vector2i) -> int:
	return kind[_i(cell.x, cell.y)]


# 1-2. Noise and biome thresholds.
func _sample_biomes() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var h := _fbm(x * 0.055, y * 0.055, 0)
			var m := _fbm(x * 0.05 + 40.0, y * 0.05 + 20.0, 100)
			var k := GRASS
			if h > CLIFF_ABOVE:
				k = CLIFF
			elif h < WATER_BELOW and m < DRY_ABOVE and include_water:
				k = WATER
			kind[_i(x, y)] = k


# 3. One cellular pass for both solid kinds.
func _smooth() -> void:
	var next := kind.duplicate()
	for y in HEIGHT:
		for x in WIDTH:
			var k := kind[_i(x, y)]
			if k == CLIFF or k == WATER:
				if _count8(x, y, k) < 4:
					next[_i(x, y)] = GRASS
			elif k == GRASS:
				for t in [CLIFF, WATER]:
					if _count8(x, y, t) >= 6:
						next[_i(x, y)] = t
						break
	kind = next


# 4. Cliff erosion, then drop specks.
func _erode(passes: int) -> void:
	for p in passes:
		var next := kind.duplicate()
		for y in HEIGHT:
			for x in WIDTH:
				if kind[_i(x, y)] == CLIFF and _count4(x, y, CLIFF) < 2:
					next[_i(x, y)] = GRASS
		kind = next


func _cull(k: int, minimum: int) -> void:
	var seen := PackedByteArray()
	seen.resize(WIDTH * HEIGHT)
	for start in WIDTH * HEIGHT:
		if seen[start] or kind[start] != k:
			continue
		var comp: Array[int] = [start]
		seen[start] = 1
		var head := 0
		while head < comp.size():
			var c := _xy(comp[head])
			head += 1
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var n: Vector2i = c + d
				if _inside(n.x, n.y) and not seen[_i(n.x, n.y)] and kind[_i(n.x, n.y)] == k:
					seen[_i(n.x, n.y)] = 1
					comp.append(_i(n.x, n.y))
		if comp.size() < minimum:
			for i in comp:
				kind[i] = GRASS


# 5. Spawn and shrine arenas.
func _place_arenas() -> void:
	spawn = Vector2i(WIDTH / 2, int(HEIGHT * 0.62))
	_flatten(spawn, SPAWN_RADIUS)
	var best := -1.0
	for i in SHRINE_CANDIDATES:
		var c := Vector2i(_rng.randi_range(4, WIDTH - 5), _rng.randi_range(4, HEIGHT - 5))
		var d := Vector2(c - spawn).length()
		if d > best:
			best = d
			shrine = c
	_flatten(shrine, SHRINE_RADIUS)


func _flatten(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if _inside(x, y) and _in_disk(Vector2i(x, y), center, radius):
				kind[_i(x, y)] = GRASS


# 6. Cardinal autotile.
func _autotile() -> void:
	features.clear()
	for y in HEIGHT:
		for x in WIDTH:
			var k := kind[_i(x, y)]
			if k == GRASS:
				continue
			var mask := _mask(x, y, k)
			var cell := Vector2i(x, y)
			match k:
				DIRT:
					features[cell] = _pool_tile(mask, x, y, k, DIRT_FILLS, 0)
				WATER:
					features[cell] = _pool_tile(mask, x, y, k, [Vector2i(2, 1)], WATER_ROW)
				CLIFF:
					features[cell] = _pick(x, y, PLATEAU_FILLS) if mask == 15 else PLATEAU_TILES[mask]


func _pool_tile(mask: int, x: int, y: int, k: int, fills: Array, row: int) -> Vector2i:
	var tile: Vector2i = DIRT_TILES[mask]
	if mask == 15:
		var open := _open_diagonals(x, y, k)
		if INNER_TILES.has(open):
			tile = INNER_TILES[open]
		elif open != 0:
			tile = INNER_TILES[open & -open] # lowest open corner; no double cell for this shape
		else:
			tile = _pick(x, y, fills)
	return tile + Vector2i(0, row)


# 7. A* spawn to shrine, two tiles wide, then the west water link.
func _carve_route() -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, WIDTH, HEIGHT)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.update()
	for y in HEIGHT:
		for x in WIDTH:
			match kind[_i(x, y)]:
				CLIFF:
					grid.set_point_weight_scale(Vector2i(x, y), CLIFF_COST)
				WATER:
					grid.set_point_weight_scale(Vector2i(x, y), WATER_COST)
	var path := grid.get_id_path(spawn, shrine)
	route_length = path.size()
	for p in path:
		_stamp_dirt(p)
		_stamp_dirt(p + Vector2i.RIGHT)


func _stamp_dirt(c: Vector2i) -> void:
	if c.x <= 0 or c.y <= 0 or c.x >= WIDTH - 1 or c.y >= HEIGHT - 1:
		return
	if _in_arena(c):
		return
	kind[_i(c.x, c.y)] = DIRT


func _stamp_water_link() -> void:
	var start := Vector2i(-1, -1)
	for x in WIDTH:
		for y in HEIGHT:
			if kind[_i(x, y)] == WATER:
				start = Vector2i(x, y)
				break
		if start.x >= 0:
			break
	if start.x < 0:
		return
	for x in range(start.x - 1, -1, -1):
		var k := kind[_i(x, start.y)]
		if k == CLIFF:
			break
		if k == DIRT or _in_arena(Vector2i(x, start.y)):
			continue
		kind[_i(x, start.y)] = WATER
		water_link += 1


# 8. Repeated interior 3x3 windows. Returns windows left repeated because
# the sheet has no other clean fill to swap in.
func _break_duplicates(k: int, fills: Array[Vector2i]) -> int:
	var seen := {}
	var unresolved := 0
	for y in range(1, HEIGHT - 1):
		for x in range(1, WIDTH - 1):
			if not _interior_window(x, y, k):
				continue
			var key := _window_key(x, y)
			if not seen.has(key):
				seen[key] = true
				continue
			var center := Vector2i(x, y)
			var swapped := false
			for f in fills:
				if f != features[center]:
					features[center] = f
					swapped = true
					break
			if swapped and not seen.has(_window_key(x, y)):
				seen[_window_key(x, y)] = true
			else:
				unresolved += 1
	return unresolved


func _interior_window(x: int, y: int, k: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cx := x + dx
			var cy := y + dy
			if kind[_i(cx, cy)] != k or _mask(cx, cy, k) != 15:
				return false
	return true


func _window_key(x: int, y: int) -> String:
	var parts := PackedStringArray()
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			parts.append(str(features[Vector2i(x + dx, y + dy)]))
	return ",".join(parts)


# 9. Poisson scatter on open grass, then the shrine prefab.
func _scatter() -> void:
	var trees := _poisson(TREE_GAP, 2000, func(c): return _clear(c, FOOTPRINT["tree"], 2))
	for c in trees:
		_claim(c, FOOTPRINT["tree"])
		props.append({"art": TREES[_rng.randi() % TREES.size()], "cell": c})
	var rocks := _poisson(ROCK_GAP, 800, func(c): return _clear(c, FOOTPRINT["rock"], 1))
	for c in rocks:
		_claim(c, FOOTPRINT["rock"])
		props.append({"art": ROCKS[_rng.randi() % ROCKS.size()], "cell": c})
	var spots := _poisson(DECO_GAP, 2500, func(c): return _clear(c, FOOTPRINT["rock"], 0))
	for c in spots:
		_claim(c, FOOTPRINT["rock"])
		var pool := FLOWERS if _rng.randf() < 0.45 else TUFTS
		deco[c] = pool[_rng.randi() % pool.size()]
	_shrine_prefab()


func _shrine_prefab() -> void:
	props.append({"art": "cypress", "cell": shrine})
	props.append({"art": "rock_0", "cell": shrine + Vector2i(-2, 0)})
	props.append({"art": "rock_2", "cell": shrine + Vector2i(1, 0)})
	deco[shrine + Vector2i(0, 1)] = FLOWERS[2]


func _poisson(gap: float, budget: int, allow: Callable) -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	for i in budget:
		var c := Vector2i(_rng.randi_range(1, WIDTH - 2), _rng.randi_range(1, HEIGHT - 2))
		if not allow.call(c):
			continue
		var ok := true
		for p in placed:
			if Vector2(c - p).length() < gap:
				ok = false
				break
		if ok:
			placed.append(c)
	return placed


# Every covered cell is unclaimed grass inside the map, and the anchor keeps
# `margin` cells of extra room from both arenas.
func _clear(anchor: Vector2i, foot: Rect2i, margin: int) -> bool:
	if _in_disk(anchor, spawn, SPAWN_RADIUS + margin) or _in_disk(anchor, shrine, SHRINE_RADIUS + margin):
		return false
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			var c := anchor + Vector2i(x, y)
			if not _inside(c.x, c.y) or kind[_i(c.x, c.y)] != GRASS or _occupied.has(c):
				return false
	return true


func _claim(anchor: Vector2i, foot: Rect2i) -> void:
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			_occupied[anchor + Vector2i(x, y)] = true


# 10. Checks the scene reports before it is trusted.
func _verify(dirt_dups: int, plateau_dups: int) -> String:
	var valid := {}
	for c in plains_cells():
		valid[c] = true
	var bad_ids := 0
	for c in features:
		if not valid.has(features[c]):
			bad_ids += 1
	for c in deco:
		if not (deco[c] in TUFTS or deco[c] in FLOWERS):
			bad_ids += 1
	var counts := [0, 0, 0, 0]
	for k in kind:
		counts[k] += 1
	var reach := _flood_reaches_shrine()
	var lines := PackedStringArray([
		"Mystic Woods seed %d, %dx%d" % [seed_value, WIDTH, HEIGHT],
		"  cells: grass %d, dirt %d, cliff %d, water %d" % counts,
		"  spawn %s, shrine %s, route %d, water link %d" % [spawn, shrine, route_length, water_link],
		"  props %d, deco %d" % [props.size(), deco.size()],
		"  ids in pack: %s" % ("ok" if bad_ids == 0 else "%d bad" % bad_ids),
		"  spawn reaches shrine: %s" % ("ok" if reach else "FAIL"),
		"  dirt 3x3 repeats: %d" % dirt_dups,
		"  plateau 3x3 repeats: %d%s" % [plateau_dups, " (plains.png has one clean plateau fill)" if plateau_dups > 0 else ""],
	])
	return "\n".join(lines)


func _flood_reaches_shrine() -> bool:
	var seen := {spawn: true}
	var queue: Array[Vector2i] = [spawn]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c == shrine:
			return true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if _inside(n.x, n.y) and not seen.has(n) and kind[_i(n.x, n.y)] in [GRASS, DIRT]:
				seen[n] = true
				queue.append(n)
	return false


func _mask(x: int, y: int, k: int) -> int:
	var mask := 0
	if _same(x, y - 1, k):
		mask |= 1
	if _same(x + 1, y, k):
		mask |= 2
	if _same(x, y + 1, k):
		mask |= 4
	if _same(x - 1, y, k):
		mask |= 8
	return mask


func _open_diagonals(x: int, y: int, k: int) -> int:
	var open := 0
	if not _same(x + 1, y - 1, k):
		open |= 1
	if not _same(x + 1, y + 1, k):
		open |= 2
	if not _same(x - 1, y + 1, k):
		open |= 4
	if not _same(x - 1, y - 1, k):
		open |= 8
	return open


# Cliffs and water run off the map edge; dirt never reaches it.
func _same(x: int, y: int, k: int) -> bool:
	if not _inside(x, y):
		return k != DIRT
	return kind[_i(x, y)] == k


func _count8(x: int, y: int, k: int) -> int:
	var n := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if (dx != 0 or dy != 0) and _inside(x + dx, y + dy) and kind[_i(x + dx, y + dy)] == k:
				n += 1
	return n


func _count4(x: int, y: int, k: int) -> int:
	var n := 0
	for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if _inside(x + d.x, y + d.y) and kind[_i(x + d.x, y + d.y)] == k:
			n += 1
	return n


func _pick(x: int, y: int, options: Array) -> Vector2i:
	return options[int(_hash(x, y, 7) * options.size()) % options.size()]


func _in_arena(c: Vector2i) -> bool:
	return _in_disk(c, spawn, SPAWN_RADIUS) or _in_disk(c, shrine, SHRINE_RADIUS)


func _in_disk(c: Vector2i, center: Vector2i, radius: int) -> bool:
	var d := c - center
	return d.x * d.x + d.y * d.y <= radius * radius


func _inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT


func _i(x: int, y: int) -> int:
	return y * WIDTH + x


func _xy(i: int) -> Vector2i:
	return Vector2i(i % WIDTH, i / WIDTH)


# Value-noise fBm: 4 octaves, amplitude halves and frequency doubles.
func _fbm(x: float, y: float, salt: int) -> float:
	var total := 0.0
	var amp := 1.0
	var freq := 1.0
	var norm := 0.0
	for octave in 4:
		total += _value_noise(x * freq, y * freq, salt + octave) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return total / norm


func _value_noise(x: float, y: float, salt: int) -> float:
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := x - x0
	var fy := y - y0
	var sx := fx * fx * (3.0 - 2.0 * fx)
	var sy := fy * fy * (3.0 - 2.0 * fy)
	var top := lerpf(_hash(x0, y0, salt), _hash(x0 + 1, y0, salt), sx)
	var bottom := lerpf(_hash(x0, y0 + 1, salt), _hash(x0 + 1, y0 + 1, salt), sx)
	return lerpf(top, bottom, sy)


func _hash(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041 + seed_value * 2654435761) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
