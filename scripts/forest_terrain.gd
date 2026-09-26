class_name PaintedTerrain
extends RefCounted
## Painted Lands map grid (AGENTS.md § Painted Lands) on TILESET_brighter.png.
## Output is atlas coordinates, dirt-blob descriptions, and prop placements.
## Never calls terrain.gd and never uses plains.png.

const WIDTH := 60
const HEIGHT := 40

# recipe = seed % 20. `houses` lists prefab ids. `height` flags: F fence
# yard, G gate line, C plateau. `path`: gate, edge, or a style this build
# does not draw yet (it falls back to a trunk and the report says so).
const RECIPES := [
	{"name": "Pastoral", "houses": [0], "water": "P+WP+WR", "height": "F", "path": "trunk+L", "patch": ["R", 2, 3], "props": ["bushes", "LR", "T"], "signs": 1},
	{"name": "Crossroads", "houses": [1], "water": "", "height": "", "path": "two trunks 90", "patch": ["I", 2, 3], "props": ["bushes", "LR"], "signs": 2},
	{"name": "Pond walk", "houses": [2], "water": "P+WP+WR", "height": "", "path": "skirts shore", "patch": ["R", 2, 2], "props": ["bushes"], "signs": 1},
	{"name": "Garden", "houses": [3], "water": "", "height": "F+G", "path": "gate", "patch": ["R", 2, 2], "props": ["bushes", "LR", "T"], "signs": 2},
	{"name": "Lookout", "houses": [0], "water": "", "height": "C", "path": "to plateau foot", "patch": ["I", 2, 2], "props": ["LR obstacles"], "signs": 1},
	{"name": "Open meadow", "houses": [], "water": "", "height": "", "path": "edge", "patch": ["R", 3, 4], "props": ["bushes", "LR"], "signs": 0},
	{"name": "Twin water", "houses": [1], "water": "P2+WP+WR", "height": "", "path": "between blobs", "patch": ["R", 1, 2], "props": [], "signs": 1},
	{"name": "South road", "houses": [2], "water": "", "height": "", "path": "south third", "patch": ["I", 2, 3], "props": ["bushes", "CF", "T"], "signs": 0},
	{"name": "Shore spur", "houses": [3], "water": "P+WP+WR", "height": "", "path": "trunk + spur", "patch": ["R", 2, 2], "props": ["T"], "signs": 2},
	{"name": "Three-way", "houses": [0], "water": "", "height": "", "path": "+2 branches 90", "patch": ["I", 2, 3], "props": ["bushes", "LR"], "signs": 3},
	{"name": "West hamlet", "houses": [1, 3], "water": "P+WP", "height": "F", "path": "from east, L", "patch": ["RI", 2, 2], "props": ["CF", "T"], "signs": 2},
	{"name": "East hamlet", "houses": [2], "water": "P+WR", "height": "F", "path": "from west, L", "patch": ["R", 2, 2], "props": ["T", "bushes"], "signs": 1},
	{"name": "Wild lane", "houses": [], "water": "moisture P", "height": "", "path": "1 trunk", "patch": ["I", 3, 4], "props": ["bushes", "LR obstacles"], "signs": 0},
	{"name": "Orchard", "houses": [3], "water": "", "height": "", "path": "short trunk", "patch": ["R", 2, 2], "props": ["bushes heavy"], "signs": 1},
	{"name": "Shore hamlet", "houses": [0], "water": "P+WP+WR", "height": "F between", "path": "short trunk", "patch": ["R", 1, 2], "props": ["CF", "T"], "signs": 2},
	{"name": "Double lean", "houses": [1], "water": "", "height": "", "path": "two L", "patch": ["I", 2, 3], "props": ["LR"], "signs": 1},
	{"name": "Below the rim", "houses": [2], "water": "", "height": "C", "path": "lawn south of plateau", "patch": ["I", 2, 2], "props": ["LR", "T"], "signs": 1},
	{"name": "Gate road", "houses": [3], "water": "", "height": "G", "path": "through gate", "patch": ["R", 2, 2], "props": ["T"], "signs": 2},
	{"name": "Sparse wild", "houses": [], "water": "P if blob", "height": "", "path": "1 trunk", "patch": ["I", 1, 2], "props": ["LR"], "signs": 0},
	{"name": "Switchback", "houses": [0], "water": "", "height": "", "path": "U of two 90", "patch": ["RI", 2, 2], "props": ["bushes", "CF"], "signs": 1},
]
const DRAWN_PATHS := ["gate", "edge", "through gate"]

# FLAT_GRASS: one plain cell and three quiet speckles.
const LAWN := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const TUFTS := [Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]
const FLOWERS := [Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5)]

# Cobble PATH, AGENTS.md table. Neighbor bits N=1 E=2 S=4 W=8.
const PATH_FILL := Vector2i(22, 1)
const PATH_TILES := {
	14: Vector2i(22, 0), 11: Vector2i(22, 2), 7: Vector2i(21, 1), 13: Vector2i(23, 1),
	6: Vector2i(21, 0), 12: Vector2i(23, 0), 3: Vector2i(21, 2), 9: Vector2i(23, 2),
}
# Fully surrounded cell with one open diagonal. Bits NE=1 SE=2 SW=4 NW=8.
const PATH_INNER := {1: Vector2i(21, 5), 2: Vector2i(21, 3), 4: Vector2i(23, 3), 8: Vector2i(23, 5)}

# PATCH dirt islands. On this sheet (18-20, 0-2) is darker grass, not dirt,
# so the two dirt sets are (30-32, 0-2), whose grass is transparent (Mode A),
# and (24-26, 0-2), whose grass is the baked mid green (Mode B). Roles are
# offsets inside the 3x3 set. Inner corners sit in rows 3-5 of each set.
const PATCH_SET_A := Vector2i(30, 0)
const PATCH_SET_B := Vector2i(24, 0)
const PATCH_ROLES := {
	15: Vector2i(1, 1), 14: Vector2i(1, 0), 11: Vector2i(1, 2), 7: Vector2i(0, 1), 13: Vector2i(2, 1),
	6: Vector2i(0, 0), 12: Vector2i(2, 0), 3: Vector2i(0, 2), 9: Vector2i(2, 2),
}
const PATCH_INNER_A := {2: Vector2i(31, 3), 4: Vector2i(32, 3), 1: Vector2i(31, 4), 8: Vector2i(32, 4)}
const PATCH_INNER_B := {2: Vector2i(24, 3), 4: Vector2i(26, 3), 1: Vector2i(24, 5), 8: Vector2i(26, 5)}
const ROUND_SHAPES := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(4, 2), Vector2i(2, 4)]

# Fence: rail (30,25), east end with post (31,25), post (29,26). West ends
# and west posts are the same cells flipped.
const FENCE_RAIL := Vector2i(30, 25)
const FENCE_END := Vector2i(31, 25)
const FENCE_POST := Vector2i(29, 26)

# Houses. `region` is in sheet pixels, anchored on a cell corner. Rows above
# `roof_rows` are HOUSE_ROOF; the rest is HOUSE_BODY. `door` is the doorstep
# cell relative to the region's top-left cell. `blocks` are body colliders
# in region pixels.
const HOUSES := {
	0: {"name": "Porch cottage", "region": Rect2i(608, 160, 115, 80), "roof_rows": 2, "door": Vector2i(3, 5), "blocks": [Rect2i(14, 32, 100, 45)]},
	1: {"name": "Flower cottage", "region": Rect2i(608, 240, 115, 80), "roof_rows": 2, "door": Vector2i(2, 4), "blocks": [Rect2i(22, 32, 58, 30), Rect2i(64, 32, 50, 46)]},
	2: {"name": "Gable cottage", "region": Rect2i(608, 400, 115, 80), "roof_rows": 2, "door": Vector2i(2, 4), "blocks": [Rect2i(22, 32, 58, 30), Rect2i(64, 32, 50, 46)]},
	3: {"name": "Hut", "region": Rect2i(736, 160, 48, 48), "roof_rows": 1, "door": Vector2i(1, 3), "blocks": [Rect2i(0, 16, 48, 30)]},
}

# Props. `region` in cells, `cell` = region top-left relative to the anchor
# tile, `base` = foot pixel inside the region (y-sort origin).
const PROPS := {
	"tree_a": {"region": Rect2i(29, 11, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(34, 78), "block": Vector2(12, 6)},
	"tree_b": {"region": Rect2i(33, 11, 5, 6), "cell": Vector2i(-2, -5), "base": Vector2i(40, 91), "block": Vector2(14, 6)},
	"bush_round": {"region": Rect2i(21, 22, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2(26, 8)},
	"bush_berry": {"region": Rect2i(23, 22, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2(26, 8)},
	"bush_small": {"region": Rect2i(21, 24, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"bush_small_b": {"region": Rect2i(23, 24, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"shrub_holey": {"region": Rect2i(47, 20, 2, 2), "cell": Vector2i(0, -1), "base": Vector2i(14, 31), "block": Vector2.ZERO},
	"shrub_flower": {"region": Rect2i(46, 22, 3, 2), "cell": Vector2i(-1, -1), "base": Vector2i(19, 31), "block": Vector2.ZERO},
	"rock_big": {"region": Rect2i(25, 23, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 30), "block": Vector2(26, 8)},
	"rock_mid": {"region": Rect2i(25, 25, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 14), "block": Vector2(22, 6)},
	"rock_tall": {"region": Rect2i(25, 26, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(15, 31), "block": Vector2(20, 8)},
	"rock_s1": {"region": Rect2i(23, 25, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(10, 5)},
	"rock_s2": {"region": Rect2i(24, 25, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(7, 15), "block": Vector2(10, 5)},
	"rock_s3": {"region": Rect2i(23, 26, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(10, 5)},
	"rock_s4": {"region": Rect2i(24, 26, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(7, 15), "block": Vector2(10, 5)},
	"rock_wide": {"region": Rect2i(23, 27, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(15, 15), "block": Vector2(22, 6)},
	"torch": {"region": Rect2i(35, 26, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 27), "block": Vector2.ZERO},
	"campfire": {"region": Rect2i(29, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6), "frames": 4},
}
const TREES := ["tree_a", "tree_b"]
const HEDGES := ["bush_round", "bush_berry"]
const SHRUBS := ["bush_small", "bush_small_b", "shrub_holey", "shrub_flower"]
const LAND_ROCKS := ["rock_big", "rock_mid", "rock_tall", "rock_s1", "rock_s2", "rock_s3", "rock_s4", "rock_wide"]
# Eight distinct sign / notice / post cells from the crate-and-fence cluster.
const SIGN := [
	Vector2i(27, 23), Vector2i(27, 24), Vector2i(27, 25), Vector2i(27, 26),
	Vector2i(27, 27), Vector2i(28, 23), Vector2i(28, 24), Vector2i(28, 25),
]

var map_id := 0
var recipe_id := 0
var recipe: Dictionary

var lawn := {} # cell -> atlas
var features := {} # cell -> {atlas, flip}
var path := {} # cell -> true
var deco := {} # cell -> atlas
var blobs: Array[Dictionary] = [] # {rect, cells, shape, mode, tiles: cell -> atlas, baked: cell -> atlas}
var props: Array[Dictionary] = [] # {art, cell} or {sign, cell}
var houses: Array[Dictionary] = [] # {id, origin}
var fence := {} # cell -> {atlas, flip}
var spawn := Vector2i.ZERO
var goal := Vector2i.ZERO
var skipped := PackedStringArray()

var _rng := RandomNumberGenerator.new()
var _taken := {} # objects plus their buffer rings
var _solid := {} # cells an object actually covers
var _blocked := {}


func generate(p_map_id: int) -> String:
	map_id = p_map_id
	recipe_id = map_id % 20
	recipe = RECIPES[recipe_id]
	_rng.seed = map_id
	for d in [lawn, features, path, deco, fence, _taken, _solid, _blocked]:
		d.clear()
	blobs.clear()
	props.clear()
	houses.clear()
	skipped.clear()

	_note_unbuilt()
	_paint_lawn()
	_place_houses()
	if "F" in recipe.height:
		_fence_yard()
	_lay_path()
	_autotile_path()
	_grow_patches()
	_place_props()
	_place_trees()
	_scatter_deco()
	return _verify()


func walkable(cell: Vector2i) -> bool:
	return _inside(cell) and not _blocked.has(cell)


func _note_unbuilt() -> void:
	if recipe.water != "":
		skipped.append("water (%s)" % recipe.water)
	if "C" in recipe.height:
		skipped.append("plateau")
	if recipe.height == "G":
		skipped.append("gate line")
	if not recipe.path in DRAWN_PATHS:
		skipped.append("path style '%s' (drawn as a trunk)" % recipe.path)


func _paint_lawn() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var h := _hash(x, y, 3)
			lawn[Vector2i(x, y)] = LAWN[0] if h < 0.7 else LAWN[1 + int(h * 97.0) % 3]


# Houses: 0, 1, or 2 prefabs, named by the recipe. Each claims its region
# plus a two-cell ring.
func _place_houses() -> void:
	for id in recipe.houses:
		var art: Dictionary = HOUSES[id]
		var size := _cells(art.region.size)
		for attempt in 60:
			var origin := Vector2i(
				_rng.randi_range(WIDTH / 2 - 12, WIDTH / 2 + 12 - size.x),
				_rng.randi_range(5, HEIGHT / 2 - 4))
			var box := Rect2i(origin, size).grow(3)
			if not _rect_free(box):
				continue
			if not houses.is_empty() and Vector2(origin - houses[0].origin).length() < 8.0:
				continue
			houses.append({"id": id, "origin": origin})
			_claim(Rect2i(origin, size).grow(2))
			_solidify(Rect2i(origin, size))
			for block in art.blocks:
				_block_pixels(origin * 16, block)
			break


# Fence yard around the first house with a two-cell gate under the door.
func _fence_yard() -> void:
	if houses.is_empty():
		return
	var h: Dictionary = houses[0]
	var art: Dictionary = HOUSES[h.id]
	var size := _cells(art.region.size)
	var door: Vector2i = h.origin + art.door
	var x0: int = h.origin.x - 2
	var x1: int = h.origin.x + size.x + 1
	var y0: int = h.origin.y - 2
	var y1: int = door.y + 2
	for x in range(x0, x1 + 1):
		for y in [y0, y1]:
			if y == y1 and (x == door.x or x == door.x + 1):
				continue # gate
			var atlas := FENCE_RAIL
			var flip := false
			if x == x0 or (y == y1 and x == door.x + 2):
				atlas = FENCE_END
				flip = true
			elif x == x1 or (y == y1 and x == door.x - 1):
				atlas = FENCE_END
			fence[Vector2i(x, y)] = {"atlas": atlas, "flip": flip}
	for y in range(y0 + 1, y1):
		fence[Vector2i(x0, y)] = {"atlas": FENCE_POST, "flip": true}
		fence[Vector2i(x1, y)] = {"atlas": FENCE_POST, "flip": false}
	for c in fence:
		_blocked[c] = true
		_solid[c] = true
	_claim(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1).grow(1))


# Cobble PATH, always two wide, 4-connected, no jogs. `edge` is a straight
# road across the map. Every other style leads from the west edge to the
# doorstep as one L: a horizontal trunk, then a vertical run up to the door
# (through the gate when there is a yard).
func _lay_path() -> void:
	if recipe.path == "edge" or houses.is_empty():
		var row := _rng.randi_range(HEIGHT / 2 - 6, HEIGHT / 2 + 4)
		_path_rect(Rect2i(0, row, WIDTH, 2))
		spawn = Vector2i(3, row)
		goal = Vector2i(WIDTH - 2, row)
		return
	var art: Dictionary = HOUSES[houses[0].id]
	var door: Vector2i = houses[0].origin + art.door
	var bottom := door.y + (4 if "F" in recipe.height else 2)
	var row := mini(_rng.randi_range(bottom, bottom + 5), HEIGHT - 4)
	_path_rect(Rect2i(0, row, door.x + 2, 2))
	_path_rect(Rect2i(door.x, door.y, 2, row - door.y + 2))
	spawn = Vector2i(3, row)
	goal = door


func _path_rect(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if _inside(c):
				path[c] = true
				_taken[c] = true
				_solid[c] = true


func _autotile_path() -> void:
	for c in path:
		var mask := _mask(c, path, true)
		var tile: Vector2i
		if mask == 15:
			var open := _open_diagonals(c, path, true)
			tile = PATH_INNER.get(open, PATH_FILL)
		else:
			tile = PATH_TILES.get(mask, Vector2i(-1, -1))
		features[c] = {"atlas": tile, "flip": false}


# PATCH blobs. Round recipes use a rounded rectangle of 4-8 cells; irregular
# ones join two overlapping rectangles into an L or T whose arms are two
# cells thick, so there is never a lone cell, a 1xN strip, or a 2-cell L.
func _grow_patches() -> void:
	var shape: String = recipe.patch[0]
	var count := _rng.randi_range(recipe.patch[1], recipe.patch[2])
	var attempts := 0
	while blobs.size() < count and attempts < 400:
		attempts += 1
		var irregular := shape == "I" or (shape == "RI" and blobs.size() % 2 == 1)
		var cells := _blob_shape(irregular)
		var at := Vector2i(_rng.randi_range(2, WIDTH - 6), _rng.randi_range(2, HEIGHT - 6))
		var placed := {}
		for c in cells:
			placed[at + c] = true
		if not _patch_fits(placed):
			continue
		var mode := "A" if (map_id + blobs.size()) % 2 == 0 else "B"
		var blob := {"cells": placed, "rect": _bounds(placed), "shape": "I" if irregular else "R", "mode": mode, "tiles": {}, "baked": {}}
		_autotile_patch(blob)
		blobs.append(blob)
		for c in placed:
			_taken[c] = true
			_solid[c] = true
		_claim(blob.rect.grow(1))


func _blob_shape(irregular: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = ROUND_SHAPES[_rng.randi() % ROUND_SHAPES.size()]
	for y in a.y:
		for x in a.x:
			out.append(Vector2i(x, y))
	if irregular:
		# Second 2x2 arm hanging off one side, flush with a corner.
		var arm: Vector2i = [Vector2i(a.x, 0), Vector2i(a.x, a.y - 2), Vector2i(0, a.y), Vector2i(a.x - 2, a.y)][_rng.randi() % 4]
		for y in 2:
			for x in 2:
				var c: Vector2i = arm + Vector2i(x, y)
				if not c in out:
					out.append(c)
	return out


func _patch_fits(cells: Dictionary) -> bool:
	if cells.size() < 3 or cells.size() > 8:
		return false
	for c in cells:
		if not _inside(c) or c.x < 1 or c.y < 1 or c.x >= WIDTH - 1 or c.y >= HEIGHT - 1:
			return false
		if _taken.has(c):
			return false
		if _near(c, path, 3) or _near(c, fence, 2):
			return false
		for b in blobs:
			if _near(c, b.cells, 4):
				return false
	return true


func _autotile_patch(blob: Dictionary) -> void:
	for c in blob.cells:
		var mask := _mask(c, blob.cells, false)
		var role: Vector2i = PATCH_ROLES.get(mask, Vector2i(-1, -1))
		var a := PATCH_SET_A + role
		var b := PATCH_SET_B + role
		if mask == 15:
			var open := _open_diagonals(c, blob.cells, false)
			if open != 0:
				a = PATCH_INNER_A.get(open, a)
				b = PATCH_INNER_B.get(open, b)
		blob.tiles[c] = a
		blob.baked[c] = b


# Props per recipe flag, then signs and torches by the gate or the road.
func _place_props() -> void:
	var flags: Array = recipe.props
	var obstacles := "LR obstacles" in flags
	if "bushes" in flags or "bushes heavy" in flags:
		var n := 12 if "bushes heavy" in flags else 7
		_scatter_props(HEDGES, n / 2 + 1, 6.0)
		_scatter_props(SHRUBS, n, 5.0)
	if "LR" in flags or obstacles:
		_scatter_props(LAND_ROCKS, 7, 6.0, obstacles)
	if "CF" in flags:
		_scatter_props(["campfire"], 1, 1.0)
	if "T" in flags:
		_place_torches()
	_place_signs(recipe.signs)


func _scatter_props(arts: Array, count: int, gap: float, may_block := true) -> Array[Dictionary]:
	var added: Array[Dictionary] = []
	var anchors: Array[Vector2i] = []
	for attempt in 600:
		if added.size() >= count:
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c := Vector2i(_rng.randi_range(2, WIDTH - 3), _rng.randi_range(2, HEIGHT - 3))
		var foot := _footprint(art, c)
		if not _rect_free(foot) or _near_rect(foot, path, 1) or c.distance_to(spawn) < 4:
			continue
		var ok := true
		for a in anchors:
			if Vector2(c - a).length() < gap:
				ok = false
				break
		if not ok:
			continue
		var prop := {"art": art, "cell": c, "block": may_block and PROPS[art].block != Vector2.ZERO}
		props.append(prop)
		added.append(prop)
		anchors.append(c)
		_claim(foot)
		_solidify(foot)
		if prop.block:
			_blocked[c] = true
	return added


func _place_torches() -> void:
	var spots: Array[Vector2i] = []
	if not fence.is_empty():
		for c in fence:
			if fence[c].atlas == FENCE_END and c.y == _fence_bottom() and _is_gate_post(c):
				spots.append(c)
	elif not houses.is_empty():
		spots = [goal + Vector2i(-1, 0), goal + Vector2i(2, 0)]
	else:
		skipped.append("torches (no gate or house)")
	for c in spots:
		props.append({"art": "torch", "cell": c, "block": false})
		_taken[c] = true
		_solid[c] = true


func _place_signs(count: int) -> void:
	if count <= 0:
		return
	var ids := range(SIGN.size())
	for i in range(ids.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	# Lawn cells beside the path, preferring the gate, then along the trunk.
	var spots: Array[Vector2i] = []
	if not fence.is_empty():
		var y := _fence_bottom() + 1
		spots.append(Vector2i(goal.x - 1, y))
		spots.append(Vector2i(goal.x + 2, y))
	var along := path.keys()
	along.sort_custom(func(a, b): return a.x < b.x if a.x != b.x else a.y < b.y)
	for c in along:
		spots.append(c + Vector2i.UP)
	var placed := 0
	var last := Vector2i(-99, -99)
	for c in spots:
		if placed >= count:
			break
		if not _inside(c) or _solid.has(c) or Vector2(c - last).length() < 6.0:
			continue
		props.append({"sign": ids[placed], "cell": c, "block": true})
		_taken[c] = true
		_solid[c] = true
		_blocked[c] = true
		last = c
		placed += 1


func _place_trees() -> void:
	var anchors: Array[Vector2i] = []
	for attempt in 2500:
		var art: String = TREES[_rng.randi() % TREES.size()]
		var c := Vector2i(_rng.randi_range(0, WIDTH - 1), _rng.randi_range(2, HEIGHT - 1))
		var foot := _footprint(art, c)
		var clipped := foot.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
		if not _rect_free(clipped) or _near_rect(clipped, path, 1) or c.distance_to(spawn) < 5:
			continue
		var ok := true
		for a in anchors:
			if Vector2(c - a).length() < 6.5:
				ok = false
				break
		if not ok:
			continue
		props.append({"art": art, "cell": c, "block": true})
		anchors.append(c)
		_claim(clipped)
		_solidify(clipped)
		_blocked[c] = true


func _scatter_deco() -> void:
	for attempt in 1400:
		var c := Vector2i(_rng.randi_range(0, WIDTH - 1), _rng.randi_range(0, HEIGHT - 1))
		if _solid.has(c) or deco.has(c):
			continue
		var crowded := false
		for d in deco:
			if Vector2(c - d).length() < 2.6:
				crowded = true
				break
		if crowded:
			continue
		var pool := FLOWERS if _rng.randf() < 0.4 else TUFTS
		deco[c] = pool[_rng.randi() % pool.size()]


# Walk check plus the Painted Lands reject list that can be tested on data.
func _verify() -> String:
	var fails := PackedStringArray()
	for c in path:
		var t: Vector2i = features[c].atlas
		if t.x < 0:
			fails.append("path cell %s has no table entry" % c)
		if t == PATH_FILL and (_mask(c, path, true) != 15 or _open_diagonals(c, path, true) != 0):
			fails.append("fill on a cap or knuckle at %s" % c)
	if houses.size() != recipe.houses.size():
		fails.append("houses %d, recipe wants %d" % [houses.size(), recipe.houses.size()])
	var patch_notes := PackedStringArray()
	for b in blobs:
		if b.cells.size() < 3 or b.cells.size() > 8:
			fails.append("patch of %d cells" % b.cells.size())
		for c in b.cells:
			if not _in_square(c, b.cells):
				fails.append("patch cell %s is not in a 2x2" % c)
		patch_notes.append("%s%d/%s" % [b.shape, b.cells.size(), b.mode])
	var want: int = recipe.patch[1]
	if blobs.size() < want:
		fails.append("patches %d < %d" % [blobs.size(), want])
	var counts := {}
	var sign_ids := {}
	for p in props:
		var kind := "sign" if p.has("sign") else _kind(p.art)
		counts[kind] = counts.get(kind, 0) + 1
		if p.has("sign"):
			sign_ids[p.sign] = true
	for flag in recipe.props:
		var need: String = {"bushes": "bush", "bushes heavy": "bush", "LR": "land rock", "LR obstacles": "land rock", "CF": "campfire", "T": "torch"}[flag]
		if counts.get(need, 0) == 0:
			fails.append("recipe asks for %s, none placed" % need)
	if sign_ids.size() != recipe.signs:
		fails.append("signs %d distinct, recipe wants %d" % [sign_ids.size(), recipe.signs])
	var reach := _reaches(spawn, goal)
	if not reach:
		fails.append("spawn does not reach %s" % goal)
	var house_names := PackedStringArray()
	for h in houses:
		house_names.append(HOUSES[h.id].name)
	var lines := PackedStringArray([
		"Painted Lands map %d: recipe %d %s, %dx%d" % [map_id, recipe_id, recipe.name, WIDTH, HEIGHT],
		"  houses: %s" % (", ".join(house_names) if not houses.is_empty() else "none"),
		"  path %d cells, fence %d cells, patches %s" % [path.size(), fence.size(), " ".join(patch_notes)],
		"  props: %s" % str(counts),
		"  signs: %s" % str(sign_ids.keys()),
		"  walk %s -> %s: %s" % [spawn, goal, "ok" if reach else "FAIL"],
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	if not skipped.is_empty():
		lines.append("  not built yet: %s" % ", ".join(skipped))
	return "\n".join(lines)


func _reaches(from: Vector2i, to: Vector2i) -> bool:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c == to:
			return true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if walkable(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return false


func _kind(art: String) -> String:
	if art in TREES:
		return "tree"
	if art in HEDGES or art in SHRUBS:
		return "bush"
	if art in LAND_ROCKS:
		return "land rock"
	return art


func _fence_bottom() -> int:
	var y := 0
	for c in fence:
		y = maxi(y, c.y)
	return y


func _is_gate_post(c: Vector2i) -> bool:
	return c.x == goal.x - 1 or c.x == goal.x + 2


func _footprint(art: String, anchor: Vector2i) -> Rect2i:
	var p: Dictionary = PROPS[art]
	return Rect2i(anchor + p.cell, p.region.size)


func _block_pixels(origin_px: Vector2i, r: Rect2i) -> void:
	var p := origin_px + r.position
	for y in range(p.y / 16, (p.y + r.size.y - 1) / 16 + 1):
		for x in range(p.x / 16, (p.x + r.size.x - 1) / 16 + 1):
			_blocked[Vector2i(x, y)] = true


func _mask(c: Vector2i, cells: Dictionary, edge_counts: bool) -> int:
	var mask := 0
	for i in 4:
		var n: Vector2i = c + [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT][i]
		if cells.has(n) or (edge_counts and not _inside(n)):
			mask |= 1 << i
	return mask


func _open_diagonals(c: Vector2i, cells: Dictionary, edge_counts: bool) -> int:
	var open := 0
	var diags := [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for i in 4:
		var n: Vector2i = c + diags[i]
		if not (cells.has(n) or (edge_counts and not _inside(n))):
			open |= 1 << i
	return open


func _in_square(c: Vector2i, cells: Dictionary) -> bool:
	for o in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		var tl: Vector2i = c + o
		if cells.has(tl) and cells.has(tl + Vector2i.RIGHT) and cells.has(tl + Vector2i.DOWN) and cells.has(tl + Vector2i.ONE):
			return true
	return false


func _near(c: Vector2i, cells: Dictionary, dist: int) -> bool:
	for y in range(c.y - dist, c.y + dist + 1):
		for x in range(c.x - dist, c.x + dist + 1):
			if cells.has(Vector2i(x, y)):
				return true
	return false


func _near_rect(r: Rect2i, cells: Dictionary, dist: int) -> bool:
	var g := r.grow(dist)
	for y in range(g.position.y, g.end.y):
		for x in range(g.position.x, g.end.x):
			if cells.has(Vector2i(x, y)):
				return true
	return false


func _rect_free(r: Rect2i) -> bool:
	if r.position.x < 0 or r.position.y < 0 or r.end.x > WIDTH or r.end.y > HEIGHT:
		return false
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _taken.has(Vector2i(x, y)):
				return false
	return true


func _solidify(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_solid[Vector2i(x, y)] = true


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _bounds(cells: Dictionary) -> Rect2i:
	var lo: Vector2i = cells.keys()[0]
	var hi := lo
	for c in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	return Rect2i(lo, hi - lo + Vector2i.ONE)


func _cells(px: Vector2i) -> Vector2i:
	return Vector2i(ceili(px.x / 16.0), ceili(px.y / 16.0))


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < WIDTH and c.y < HEIGHT


func _hash(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041 + map_id * 2654435761) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
