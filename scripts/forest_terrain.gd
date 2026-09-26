class_name PaintedTerrain
extends RefCounted
## Painted Lands map grid (AGENTS.md § Painted Lands) on TILESET_brighter.png.
## Output is atlas coordinates, dirt-blob descriptions, and prop placements.
## Never calls terrain.gd and never uses plains.png.

const WIDTH := 60
const HEIGHT := 40
const ATTEMPTS := 60

# recipe = seed % 20. `houses` lists prefab ids. `water`: P pond, P2 two
# ponds, WP water plants, WR water rocks. `height`: F fence yard, G gate
# line, C plateau, "F between" a fence run between house and pond.
const RECIPES := [
	{"name": "Pastoral", "houses": [0], "water": "P+WP+WR", "height": "F", "path": "trunk + L", "patch": ["R", 2, 3], "props": ["bushes", "LR", "T"], "signs": 1},
	{"name": "Crossroads", "houses": [1], "water": "", "height": "", "path": "2 trunks 90", "patch": ["I", 2, 3], "props": ["bushes", "LR"], "signs": 2},
	{"name": "Pond walk", "houses": [2], "water": "P+WP+WR", "height": "", "path": "skirts shore", "patch": ["R", 2, 2], "props": ["bushes"], "signs": 1},
	{"name": "Garden", "houses": [3], "water": "", "height": "F+G", "path": "through gate", "patch": ["R", 2, 2], "props": ["bushes", "LR", "T"], "signs": 2},
	{"name": "Lookout", "houses": [0], "water": "", "height": "C", "path": "to plateau foot", "patch": ["I", 2, 2], "props": ["LR obstacles"], "signs": 1},
	{"name": "Open meadow", "houses": [], "water": "", "height": "", "path": "edge-to-edge", "patch": ["R", 3, 4], "props": ["bushes", "LR"], "signs": 0},
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

# FLAT_GRASS: one plain cell and three quiet speckles.
const LAWN := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const TUFTS := [Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]
const FLOWERS := [Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5)]

# Grass tone zones, lightest to darkest. Each level is a 3x3 blob set on
# transparent with dithered, rounded edges, its transparent-hole ring for
# inner corners, and flat fills of the same green (plain plus speckles).
# Level 0 sits on the lawn; each deeper level sits inside the one before.
const TONES := [
	{"name": "mid", "blob": Vector2i(12, 6), "ring": Vector2i(12, 9), "fills": [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)], "cover": 0.26},
	{"name": "dark", "blob": Vector2i(15, 6), "ring": Vector2i(15, 9), "fills": [Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1)], "cover": 0.10},
	{"name": "deep", "blob": Vector2i(18, 6), "ring": Vector2i(18, 9), "fills": [Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0)], "cover": 0.035},
]
const FLIP_H := 1
const FLIP_V := 2

# Neighbor bits N=1 E=2 S=4 W=8 -> role in a 3x3 set (offset from its NW).
const ROLES := {
	15: Vector2i(1, 1), 14: Vector2i(1, 0), 11: Vector2i(1, 2), 7: Vector2i(0, 1), 13: Vector2i(2, 1),
	6: Vector2i(0, 0), 12: Vector2i(2, 0), 3: Vector2i(0, 2), 9: Vector2i(2, 2),
}
const NONE := Vector2i(-1, -1)

# Cobble PATH, AGENTS.md table. Open-diagonal bits NE=1 SE=2 SW=4 NW=8.
const PATH_SET := Vector2i(21, 0)
const PATH_FILL := Vector2i(22, 1)
const PATH_INNER := {1: Vector2i(21, 5), 2: Vector2i(21, 3), 4: Vector2i(23, 3), 8: Vector2i(23, 5)}

# PATCH dirt islands: set A has transparent grass (Mode A), set B keeps
# its baked mid green (Mode B halo).
const PATCH_SET_A := Vector2i(30, 0)
const PATCH_SET_B := Vector2i(24, 0)
const PATCH_INNER_A := {2: Vector2i(31, 3), 4: Vector2i(32, 3), 1: Vector2i(31, 4), 8: Vector2i(32, 4)}
const PATCH_INNER_B := {2: Vector2i(24, 3), 4: Vector2i(26, 3), 1: Vector2i(24, 5), 8: Vector2i(26, 5)}
const ROUND_SHAPES := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(4, 2), Vector2i(2, 4)]

# Pond: 3x3 water set with shore on transparent, plus inner corners. The
# sheet repeats the set four times, three columns apart, with the shore a
# little wider each time (35, 38, 41, 44): those are the animation frames.
# Terrain writes frame 0; the painter animates it.
const WATER_SET := Vector2i(35, 0)
const WATER_INNER := {8: Vector2i(35, 3), 1: Vector2i(36, 3), 4: Vector2i(35, 4), 2: Vector2i(36, 4)}
const WATER_FRAMES := 4
const WATER_FRAME_STEP := 3
const WATER_FRAME_REGION := Rect2i(35, 0, 3, 5)

# Plateau: 3x3 rim over the top, then a three-row south face.
const PLATEAU_SET := Vector2i(4, 12)
const PLATEAU_FACE_ROW := 15
const FACE_ROWS := 3
# Stairs cut three wide into the face: steps in rows 24-25 with shaded
# sides, then the mossy bottom step (2, 26) across all three columns.
const STAIRS := [
	[Vector2i(1, 24), Vector2i(2, 24), Vector2i(3, 24)],
	[Vector2i(1, 25), Vector2i(2, 25), Vector2i(3, 25)],
	[Vector2i(2, 26), Vector2i(2, 26), Vector2i(2, 26)],
]

# Fence: rail, east end with post, post. West pieces are the same cells flipped.
const FENCE_RAIL := Vector2i(30, 25)
const FENCE_END := Vector2i(31, 25)
const FENCE_POST := Vector2i(29, 26)

# Houses. `region` is in sheet pixels, anchored on a cell corner. The top
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
	# The same trees with the grass tuft the sheet draws under each trunk.
	"tree_a_base": {"region": Rect2i(29, 11, 4, 6), "cell": Vector2i(-2, -5), "base": Vector2i(34, 92), "block": Vector2(12, 6)},
	"tree_b_base": {"region": Rect2i(33, 11, 5, 7), "cell": Vector2i(-2, -6), "base": Vector2i(40, 106), "block": Vector2(14, 6)},
	# Flowering versions (lavender blossom), rows 18+.
	"bloom_a": {"region": Rect2i(29, 18, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(34, 78), "block": Vector2(12, 6)},
	"bloom_b": {"region": Rect2i(33, 18, 5, 6), "cell": Vector2i(-2, -5), "base": Vector2i(40, 91), "block": Vector2(14, 6)},
	"bloom_a_base": {"region": Rect2i(29, 18, 4, 6), "cell": Vector2i(-2, -5), "base": Vector2i(34, 92), "block": Vector2(12, 6)},
	"bloom_b_base": {"region": Rect2i(33, 18, 5, 7), "cell": Vector2i(-2, -6), "base": Vector2i(40, 106), "block": Vector2(14, 6)},
	"log": {"region": Rect2i(21, 25, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"log_b": {"region": Rect2i(21, 26, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"crate": {"region": Rect2i(21, 27, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"crate_b": {"region": Rect2i(22, 27, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"crate_stack": {"region": Rect2i(22, 28, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 29), "block": Vector2(24, 8)},
	"crate_stack_b": {"region": Rect2i(24, 28, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 29), "block": Vector2(24, 8)},
	"chest": {"region": Rect2i(26, 28, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"chest_b": {"region": Rect2i(27, 28, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"chest_c": {"region": Rect2i(26, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"chest_d": {"region": Rect2i(27, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
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
	"reed_tall": {"region": Rect2i(46, 4, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2.ZERO},
	"reed": {"region": Rect2i(47, 5, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass": {"region": Rect2i(46, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass_b": {"region": Rect2i(47, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass_big": {"region": Rect2i(45, 7, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2.ZERO},
	"lily": {"region": Rect2i(45, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"lily_pair": {"region": Rect2i(44, 5, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"water_rock_big": {"region": Rect2i(48, 5, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2.ZERO},
	"water_rock": {"region": Rect2i(49, 7, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_rock_flat": {"region": Rect2i(49, 8, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
}
const TREES := ["tree_a", "tree_b", "tree_a_base", "tree_b_base", "bloom_a", "bloom_b", "bloom_a_base", "bloom_b_base"]
const LOGS := ["log", "log_b"]
const YARD_CLUTTER := ["crate", "crate_b", "crate_stack", "crate_stack_b", "chest", "chest_b", "chest_c", "chest_d"]
const HEDGES := ["bush_round", "bush_berry"]
const SHRUBS := ["bush_small", "bush_small_b", "shrub_holey", "shrub_flower"]
# Land rocks: the big ones always collide; the 1-cell pebbles never do.
const BIG_ROCKS := ["rock_big", "rock_mid", "rock_tall", "rock_wide"]
const PEBBLES := ["rock_s1", "rock_s2", "rock_s3", "rock_s4"]
const LAND_ROCKS := BIG_ROCKS + PEBBLES
const SHORE_PLANTS := ["reed_tall", "reed", "water_grass", "water_grass_b", "water_grass_big"]
const OPEN_PLANTS := ["lily", "lily_pair"]
const WATER_ROCKS := ["water_rock_big", "water_rock", "water_rock_flat"]
# Eight distinct sign / notice / post cells from the crate-and-fence cluster.
const SIGN := [
	Vector2i(27, 23), Vector2i(27, 24), Vector2i(27, 25), Vector2i(27, 26),
	Vector2i(27, 27), Vector2i(28, 23), Vector2i(28, 24), Vector2i(28, 25),
]

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var attempt := 0

var lawn := {} # cell -> atlas
var features := {} # cell -> atlas: path, water, plateau
var path := {} # cell -> true
var water := {} # cell -> true
var plateau := {} # cell -> true (top and face)
var ledge := {} # plateau cells that block: the rim and the face, not the stairs
var stairs := {} # cell -> true
var deco := {} # cell -> atlas
var tones: Array[Dictionary] = [] # per level: cell -> {atlas, alt}
var blobs: Array[Dictionary] = [] # {rect, cells, shape, mode, tiles, baked}
var ponds: Array[Rect2i] = []
var props: Array[Dictionary] = [] # {art, cell, block} or {sign, cell, block}
var houses: Array[Dictionary] = [] # {id, origin}
var fence := {} # cell -> {atlas, flip}
var gate := Vector2i(-1, -1) # left cell of a two-cell gate
var leans := 0
var spawn := Vector2i.ZERO
var goals: Array[Vector2i] = []
var dropped := PackedStringArray()

var _rng := RandomNumberGenerator.new()
var _taken := {} # objects plus their buffer rings
var _solid := {} # cells an object actually covers
var _blocked := {} # cells the walker cannot enter


func generate(p_map_id: int) -> String:
	map_id = p_map_id
	recipe_id = map_id % 20
	recipe = RECIPES[recipe_id]
	var built := false
	for a in ATTEMPTS:
		attempt = a
		_reset(hash(Vector2i(map_id, a)))
		if _layout() and _autotile_path():
			built = true
			break
	if not built:
		dropped.append("no layout fit after %d attempts" % ATTEMPTS)
	_grow_patches()
	_grass_zones()
	_place_props()
	_place_trees()
	_scatter_deco()
	return _verify()


func walkable(cell: Vector2i) -> bool:
	return _inside(cell) and not _blocked.has(cell)


func _reset(seed_value: int) -> void:
	_rng.seed = seed_value
	for d in [lawn, features, path, water, plateau, ledge, stairs, deco, fence, _taken, _solid, _blocked]:
		d.clear()
	for a in [blobs, ponds, props, houses, goals, tones]:
		a.clear()
	dropped.clear()
	gate = Vector2i(-1, -1)
	leans = 0
	_paint_lawn()


func _paint_lawn() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var h := _hash(x, y, 3)
			lawn[Vector2i(x, y)] = LAWN[0] if h < 0.7 else LAWN[1 + int(h * 97.0) % 3]


# ---------------------------------------------------------------- layouts
# Each recipe places its plateau, ponds, houses, fences, and path. A layout
# returns false when a piece does not fit; generate() then retries with the
# next attempt seed.

func _layout() -> bool:
	match recipe_id:
		0: return _lay_pastoral()
		1: return _lay_crossroads()
		2: return _lay_pond_walk()
		3: return _lay_garden()
		4: return _lay_rim(0)
		5: return _lay_edge_road(_rng.randi_range(HEIGHT / 2 - 6, HEIGHT / 2 + 4))
		6: return _lay_twin_water()
		7: return _lay_south_road()
		8: return _lay_shore_spur()
		9: return _lay_three_way()
		10: return _lay_hamlet(false)
		11: return _lay_hamlet(true)
		12: return _lay_wild_lane()
		13: return _lay_orchard()
		14: return _lay_shore_hamlet()
		15: return _lay_double_lean()
		16: return _lay_rim(3)
		17: return _lay_gate_road()
		18: return _lay_sparse_wild()
		19: return _lay_switchback()
	return false


# 0: trunk from the west edge with one lean, into a fenced yard. Pond south.
func _lay_pastoral() -> bool:
	var h := _place_house(0, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	_yard(h)
	var high := door.y + _rng.randi_range(5, 7)
	var rise := _rng.randi_range(2, 4)
	var low := high + rise
	var k := _pick(6, door.x - 7)
	if k < 0 or low > HEIGHT - 12:
		return false
	if not _route([Vector2i(0, low), Vector2i(k, low), Vector2i(k, high), Vector2i(door.x, high), door]):
		return false
	leans = 1
	spawn = Vector2i(2, low)
	goals = [door]
	return _pond(Rect2i(4, low + 4, WIDTH - 8, HEIGHT - low - 6), "WP+WR")


# 1: two edge-to-edge trunks crossing at 90 degrees, house spur to the trunk.
func _lay_crossroads() -> bool:
	var row := _rng.randi_range(19, 25)
	var col := _rng.randi_range(18, WIDTH - 20)
	var west := _rng.randf() < 0.5
	var zone := Rect2i(4, 4, col - 14, row - 14) if west else Rect2i(col + 5, 4, WIDTH - col - 16, row - 14)
	var h := _place_house(1, zone)
	if h.is_empty():
		return false
	var door := _door(h)
	if abs(door.x - col) < 5 or door.y > row - 4:
		return false
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	if not _route([Vector2i(col, 0), Vector2i(col, HEIGHT - 2)], true):
		return false
	if not _route([door, Vector2i(door.x, row)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(col, 1), Vector2i(WIDTH - 2, row)]
	return true


# 2: the trunk skirts the pond's south shore, then turns north to the house.
func _lay_pond_walk() -> bool:
	if not _pond(Rect2i(5, 12, 26, 14), "WP+WR"):
		return false
	var p := ponds[0]
	var row := p.end.y + 1
	var h := _place_house(2, Rect2i(p.end.x + 3, 4, WIDTH - p.end.x - 13, row - 13))
	if h.is_empty():
		return false
	var door := _door(h)
	if door.y > row - 4:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	spawn = Vector2i(2, row)
	goals = [door]
	return true


# 3: trunk from the west edge, north through the yard gate to the door.
func _lay_garden() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	_yard(h)
	var row := mini(door.y + _rng.randi_range(4, 9), HEIGHT - 5)
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	spawn = Vector2i(2, row)
	goals = [door]
	return true


# 4 and 16: plateau in the north half; the trunk runs along its foot
# (`gap` lawn rows below the face) and on to a house east of it.
func _lay_rim(gap: int) -> bool:
	var top := _plateau(Rect2i(6, 3, WIDTH / 2 - 6, 5))
	if top.size == Vector2i.ZERO:
		return false
	var foot := top.end.y + FACE_ROWS
	var row := foot + gap
	var h := _place_house(0 if recipe_id == 4 else 2, Rect2i(top.end.x + 4, 3, WIDTH - top.end.x - 14, row - 12))
	if h.is_empty():
		return false
	var door := _door(h)
	if door.y > row - 3:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	var sx := _stairs_x()
	if gap > 0 and not _route([Vector2i(sx, row), Vector2i(sx, foot)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(sx + 1, top.end.y - 2)] # the door and the plateau top
	return true


func _stairs_x() -> int:
	var sx := WIDTH
	for c in stairs:
		sx = mini(sx, c.x)
	return sx


# 5: a straight road from the west edge to the east edge.
func _lay_edge_road(row: int) -> bool:
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	spawn = Vector2i(3, row)
	goals = [Vector2i(WIDTH - 2, row)]
	return true


# 6: a vertical trunk from the south edge to the house, a pond each side.
func _lay_twin_water() -> bool:
	var h := _place_house(1, Rect2i(WIDTH / 2 - 8, 3, 10, 4))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(door.x, HEIGHT - 2), door]):
		return false
	var top := door.y + 3
	if not _pond(Rect2i(door.x - 22, top, 19, HEIGHT - top - 3), "WP+WR"):
		return false
	if not _pond(Rect2i(door.x + 5, top, 19, HEIGHT - top - 3), "WP+WR"):
		return false
	spawn = Vector2i(door.x, HEIGHT - 3)
	goals = [door]
	return true


# 7: an edge-to-edge road in the south third, the house spurs down to it.
func _lay_south_road() -> bool:
	var row := _rng.randi_range(HEIGHT * 2 / 3, HEIGHT - 7)
	var h := _place_house(2, Rect2i(8, row - 16, WIDTH - 22, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	if not _route([door, Vector2i(door.x, row)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(WIDTH - 2, row)]
	return true


# 8: trunk to the house, and a spur from the trunk down to the pond shore.
func _lay_shore_spur() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	var row := mini(door.y + _rng.randi_range(4, 7), HEIGHT - 16)
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	if not _pond(Rect2i(4, row + 6, door.x + 2, HEIGHT - row - 8), "WP+WR"):
		return false
	var p := ponds[0]
	var col := clampi(p.get_center().x - 1, 4, door.x - 5)
	var shore := _first_water_below(col, row + 2)
	if shore < 0:
		return false
	if not _route([Vector2i(col, row), Vector2i(col, shore - 3)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(col, shore - 2)]
	return true


# 9: trunk to the house with a branch to the north edge and one to the south.
func _lay_three_way() -> bool:
	var h := _place_house(0, Rect2i(WIDTH / 2, 4, WIDTH / 2 - 12, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	var row := mini(door.y + _rng.randi_range(4, 8), HEIGHT - 8)
	var north := _pick(5, door.x - 16)
	var south := _pick(north + 6, door.x - 6)
	if north < 0 or south < 0:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	if not _route([Vector2i(north, row), Vector2i(north, 0)], true):
		return false
	if not _route([Vector2i(south, row), Vector2i(south, HEIGHT - 2)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(north, 1), Vector2i(south, HEIGHT - 2)]
	return true


# 10 and 11: hamlet with a fenced yard; the trunk comes in from the far edge
# with one lean. West hamlet has two houses (1 and 3) and a second spur.
func _lay_hamlet(east: bool) -> bool:
	var ids: Array = recipe.houses
	var zone := Rect2i(WIDTH - 22, 4, 12, 5) if east else Rect2i(4, 4, 12, 5)
	var a := _place_house(ids[0], zone)
	if a.is_empty():
		return false
	var door := _door(a)
	_yard(a)
	var b := {}
	var door_b := Vector2i(-99, -99)
	if ids.size() > 1:
		b = _place_house(ids[1], Rect2i(door.x + 10, 4, 10, 6))
		if b.is_empty():
			return false
		door_b = _door(b)
	var high := maxi(door.y, door_b.y) + _rng.randi_range(6, 8)
	var rise := _rng.randi_range(2, 4)
	var low := high + rise
	var edge := 0 if east else WIDTH - 2
	var k := _pick(6, door.x - 8) if east else _pick(maxi(door.x, door_b.x) + 6, WIDTH - 8)
	if low > HEIGHT - 12 or k < 0:
		return false
	if not _route([Vector2i(edge, low), Vector2i(k, low), Vector2i(k, high), Vector2i(door.x, high), door]):
		return false
	leans = 1
	if not b.is_empty() and not _route([door_b, Vector2i(door_b.x, high)], true):
		return false
	spawn = Vector2i(2 if east else WIDTH - 3, low)
	goals.assign([door] if b.is_empty() else [door, door_b])
	var pond_zone := Rect2i(WIDTH / 2, low + 4, WIDTH / 2 - 4, HEIGHT - low - 6) if east else Rect2i(4, low + 4, WIDTH / 2 - 4, HEIGHT - low - 6)
	return _pond(pond_zone, "WR" if east else "WP")


# 12: one trunk from the north edge to the south edge; a moisture pond.
func _lay_wild_lane() -> bool:
	var col := _rng.randi_range(12, WIDTH - 14)
	if not _route([Vector2i(col, 0), Vector2i(col, HEIGHT - 2)]):
		return false
	spawn = Vector2i(col, HEIGHT - 3)
	goals = [Vector2i(col, 1)]
	var west := col > WIDTH / 2
	var zone := Rect2i(3, 4, col - 7, HEIGHT - 8) if west else Rect2i(col + 5, 4, WIDTH - col - 8, HEIGHT - 8)
	return _pond(zone, "")


# 13: a short trunk from the door that ends on the lawn.
func _lay_orchard() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	var end := door.y + _rng.randi_range(5, 8)
	if not _route([door, Vector2i(door.x, end)]):
		return false
	spawn = Vector2i(door.x, end + 1)
	goals = [door]
	return true


# 14: short trunk; a pond to the south-east with a fence run along its
# north shore, between the pond and the house.
func _lay_shore_hamlet() -> bool:
	var h := _place_house(0, Rect2i(8, 4, 16, 5))
	if h.is_empty():
		return false
	var door := _door(h)
	var end := door.y + _rng.randi_range(6, 9)
	if not _route([door, Vector2i(door.x, end)]):
		return false
	var size := _cells(HOUSES[0].region.size)
	if not _pond(Rect2i(h.origin.x + size.x + 3, door.y + 1, 22, HEIGHT - door.y - 4), "WP+WR"):
		return false
	var p := ponds[0]
	if not _fence_run(Vector2i(p.position.x, p.position.y - 2), p.size.x):
		return false
	spawn = Vector2i(door.x, end + 1)
	goals = [door]
	return true


# 15: trunk from the west edge with two leans, then north to the door.
func _lay_double_lean() -> bool:
	var h := _place_house(1, Rect2i(WIDTH - 22, 4, 12, 5))
	if h.is_empty():
		return false
	var door := _door(h)
	var r1 := _rng.randi_range(2, 4)
	var r2 := _rng.randi_range(2, 4)
	var top := door.y + _rng.randi_range(4, 6)
	var mid := top + r2
	var low := mid + r1
	var k1 := _rng.randi_range(7, 16)
	var k2 := _pick(k1 + 7, door.x - 7)
	if low > HEIGHT - 5 or k2 < 0:
		return false
	if not _route([Vector2i(0, low), Vector2i(k1, low), Vector2i(k1, mid), Vector2i(k2, mid), Vector2i(k2, top), Vector2i(door.x, top), door]):
		return false
	leans = 2
	spawn = Vector2i(2, low)
	goals = [door]
	return true


# 17: a gate line across the map; the path comes up from the south edge
# through the gate to the house.
func _lay_gate_road() -> bool:
	var h := _place_house(3, Rect2i(WIDTH / 2 - 10, 4, 18, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(door.x, HEIGHT - 2), door]):
		return false
	_gate_line(door.y + 3, door.x)
	spawn = Vector2i(door.x, HEIGHT - 3)
	goals = [door]
	return true


# 18: one straight trunk; a pond only if the moisture field has a blob.
func _lay_sparse_wild() -> bool:
	var row := _rng.randi_range(HEIGHT / 2 - 5, HEIGHT / 2 + 5)
	if not _lay_edge_road(row):
		return false
	var zone := Rect2i(4, row + 5, WIDTH - 8, HEIGHT - row - 7) if row < HEIGHT / 2 else Rect2i(4, 3, WIDTH - 8, row - 6)
	var best := _wettest(zone)
	if _moisture(best) < 0.56:
		dropped.append("pond (no moisture blob)")
		return true
	return _pond(zone, "")


# 19: a U of two 90-degree turns (east, north, back west), then up to the door.
func _lay_switchback() -> bool:
	var h := _place_house(0, Rect2i(8, 3, 14, 3))
	if h.is_empty():
		return false
	var door := _door(h)
	var upper := door.y + _rng.randi_range(4, 6)
	var lower := upper + _rng.randi_range(5, 8)
	var turn := _pick(door.x + 10, WIDTH - 8)
	if lower > HEIGHT - 4 or turn < 0:
		return false
	if not _route([Vector2i(0, lower), Vector2i(turn, lower), Vector2i(turn, upper), Vector2i(door.x, upper), door]):
		return false
	spawn = Vector2i(2, lower)
	goals = [door]
	return true


# Random int in [lo, hi], or -1 when the range is empty.
func _pick(lo: int, hi: int) -> int:
	return -1 if hi < lo else _rng.randi_range(lo, hi)


func _center_zone() -> Rect2i:
	return Rect2i(WIDTH / 2 - 10, 4, 18, 7)


# ---------------------------------------------------------------- pieces

func _place_house(id: int, zone: Rect2i) -> Dictionary:
	var art: Dictionary = HOUSES[id]
	var size := _cells(art.region.size)
	if zone.size.x <= 0 or zone.size.y <= 0:
		return {}
	for i in 40:
		var origin := zone.position + Vector2i(_rng.randi_range(0, zone.size.x), _rng.randi_range(0, zone.size.y))
		var box := Rect2i(origin, size).grow(3)
		if not _rect_free(box):
			continue
		var ok := true
		for other in houses:
			if Vector2(origin - other.origin).length() < 8.0 + size.x:
				ok = false
		if not ok:
			continue
		var h := {"id": id, "origin": origin}
		houses.append(h)
		_claim(Rect2i(origin, size).grow(2))
		for block in art.blocks:
			_block_pixels(origin * 16, block)
		return h
	return {}


func _door(h: Dictionary) -> Vector2i:
	return h.origin + HOUSES[h.id].door


# Fence yard around a house with a two-cell gate under the door.
func _yard(h: Dictionary) -> void:
	var art: Dictionary = HOUSES[h.id]
	var size := _cells(art.region.size)
	var door := _door(h)
	var x0: int = h.origin.x - 2
	var x1: int = h.origin.x + size.x + 1
	var y0: int = h.origin.y - 2
	var y1: int = door.y + 2
	gate = Vector2i(door.x, y1)
	for x in range(x0, x1 + 1):
		_put_fence(Vector2i(x, y0), FENCE_END if x == x0 or x == x1 else FENCE_RAIL, x == x0)
		if x == door.x or x == door.x + 1:
			continue
		var end := x == x0 or x == x1 or x == door.x - 1 or x == door.x + 2
		_put_fence(Vector2i(x, y1), FENCE_END if end else FENCE_RAIL, x == x0 or x == door.x + 2)
	for y in range(y0 + 1, y1):
		_put_fence(Vector2i(x0, y), FENCE_POST, true)
		_put_fence(Vector2i(x1, y), FENCE_POST, false)
	_claim(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1).grow(1))


# A straight horizontal fence run of `length` cells with posts at both ends.
func _fence_run(start: Vector2i, length: int) -> bool:
	if length < 3:
		return false
	for x in range(start.x, start.x + length):
		var c := Vector2i(x, start.y)
		if not _inside(c) or _solid.has(c):
			return false
	for x in range(start.x, start.x + length):
		var end := x == start.x or x == start.x + length - 1
		_put_fence(Vector2i(x, start.y), FENCE_END if end else FENCE_RAIL, x == start.x)
	return true


# A fence line across the whole map with a two-cell gate at `gate_x`.
func _gate_line(row: int, gate_x: int) -> void:
	gate = Vector2i(gate_x, row)
	for x in WIDTH:
		if x == gate_x or x == gate_x + 1:
			continue
		var c := Vector2i(x, row)
		if path.has(c):
			continue
		var post := x == gate_x - 1 or x == gate_x + 2
		_put_fence(c, FENCE_END if post else FENCE_RAIL, x == gate_x + 2)


func _put_fence(c: Vector2i, atlas: Vector2i, flip: bool) -> void:
	fence[c] = {"atlas": atlas, "flip": flip}
	_blocked[c] = true
	_solid[c] = true
	_taken[c] = true


# Plateau: a rectangle at least 4x4 for the top, then a three-row face.
# Returns the top rectangle, or an empty rect when it does not fit.
func _plateau(zone: Rect2i) -> Rect2i:
	for i in 30:
		var size := Vector2i(_rng.randi_range(6, 10), _rng.randi_range(4, 5))
		var at := zone.position + Vector2i(_rng.randi_range(0, zone.size.x), _rng.randi_range(0, zone.size.y))
		var whole := Rect2i(at, size + Vector2i(0, FACE_ROWS))
		if not _rect_free(whole.grow(2)):
			continue
		var top := Rect2i(at, size)
		var cells := {}
		for y in range(top.position.y, top.end.y):
			for x in range(top.position.x, top.end.x):
				cells[Vector2i(x, y)] = true
		for c in cells:
			features[c] = PLATEAU_SET + ROLES[_mask(c, cells, false)]
		var sx := _rng.randi_range(top.position.x + 1, top.end.x - 4)
		for r in FACE_ROWS:
			for x in range(top.position.x, top.end.x):
				var col := 0 if x == top.position.x else (2 if x == top.end.x - 1 else 1)
				var c := Vector2i(x, top.end.y + r)
				if x >= sx and x < sx + 3:
					features[c] = STAIRS[r][x - sx]
					stairs[c] = true
				else:
					features[c] = Vector2i(PLATEAU_SET.x + col, PLATEAU_FACE_ROW + r)
		# The top interior and the rim cells over the stairs are walkable;
		# the rest of the rim and the face are a ledge.
		for y in range(whole.position.y, whole.end.y):
			for x in range(whole.position.x, whole.end.x):
				var c := Vector2i(x, y)
				plateau[c] = true
				_solid[c] = true
				var open := stairs.has(c) or (cells.has(c) and _mask(c, cells, false) == 15)
				open = open or (y == top.end.y - 1 and x >= sx and x < sx + 3)
				if not open:
					ledge[c] = true
					_blocked[c] = true
		_claim(whole.grow(2))
		return top
	return Rect2i()


# Pond: two overlapping rectangles centred on the wettest cell of `zone`,
# autotiled with the water set. A shape the set cannot draw is rejected.
# `extras` adds water plants (WP) and water rocks (WR).
func _pond(zone: Rect2i, extras: String) -> bool:
	zone = zone.intersection(Rect2i(2, 2, WIDTH - 4, HEIGHT - 4))
	if zone.size.x < 6 or zone.size.y < 5:
		return false
	var wet := _wettest(zone)
	for i in 30:
		var a := Rect2i(Vector2i.ZERO, Vector2i(_rng.randi_range(4, 7), _rng.randi_range(3, 5)))
		a.position = wet - a.size / 2
		var b := Rect2i(Vector2i.ZERO, Vector2i(_rng.randi_range(3, 5), _rng.randi_range(3, 4)))
		b.position = a.position + Vector2i(_rng.randi_range(-2, a.size.x - 1), _rng.randi_range(-2, a.size.y - 1))
		var cells := {}
		for r in [a, b]:
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					cells[Vector2i(x, y)] = true
		var box := _bounds(cells)
		if not zone.encloses(box) or cells.size() < 12 or not _rect_free(box.grow(1)):
			continue
		var tiles := {}
		var ok := true
		for c in cells:
			var t := _pool_tile(c, cells, WATER_SET, WATER_INNER)
			if t == NONE:
				ok = false
				break
			tiles[c] = t
		if not ok:
			continue
		var wet_props := _water_props(cells, extras)
		if wet_props.is_empty() and extras != "":
			continue # this shape cannot hold the plants or rocks the recipe asks for
		for c in cells:
			features[c] = tiles[c]
			water[c] = true
			_solid[c] = true
			_blocked[c] = true
		ponds.append(box)
		props.append_array(wet_props)
		_claim(box.grow(2))
		return true
	return false


# Water plants and rocks for a pond shape. Returns an empty list when a
# requested kind does not fit.
func _water_props(cells: Dictionary, extras: String) -> Array[Dictionary]:
	var shore: Array[Vector2i] = []
	var open: Array[Vector2i] = []
	for c in cells:
		if _mask(c, cells, false) == 15 and _open_diagonals(c, cells, false) == 0:
			open.append(c)
		elif c.y > _bounds(cells).position.y:
			shore.append(c) # not on the north rim, so plants read in front of the water
	var used := {}
	var out: Array[Dictionary] = []
	var anywhere: Array[Vector2i] = []
	anywhere.assign(cells.keys())
	if "WR" in extras and _place_wet(WATER_ROCKS, anywhere, cells, used, 2, out) == 0:
		return []
	if "WP" in extras:
		var plants := _place_wet(SHORE_PLANTS, shore, cells, used, 3, out)
		plants += _place_wet(OPEN_PLANTS, open if not open.is_empty() else anywhere, cells, used, 2, out)
		if plants == 0:
			return []
	return out


func _place_wet(arts: Array, spots: Array[Vector2i], cells: Dictionary, used: Dictionary, count: int, out: Array[Dictionary]) -> int:
	var placed := 0
	for i in 40:
		if placed >= count or spots.is_empty():
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c: Vector2i = spots[_rng.randi() % spots.size()]
		var foot := _footprint(art, c)
		var ok := true
		for y in range(foot.position.y - 1, foot.end.y + 1):
			for x in range(foot.position.x - 1, foot.end.x + 1):
				var n := Vector2i(x, y)
				if used.has(n) or (foot.has_point(n) and not cells.has(n)):
					ok = false
		if not ok:
			continue
		out.append({"art": art, "cell": c, "block": false})
		for y in range(foot.position.y, foot.end.y):
			for x in range(foot.position.x, foot.end.x):
				used[Vector2i(x, y)] = true
		placed += 1
	return placed


# Cobble PATH: 2-wide tubes between axis-aligned waypoints. Each waypoint is
# the top-left of a 2x2 block, so a turn is a 2x2 knuckle and a short
# vertical between two horizontals is a lean. `joins` lets the new tubes
# overlap existing path (branches and crossings).
func _route(points: Array, joins := false) -> bool:
	var cells := {}
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		if a.x != b.x and a.y != b.y:
			return false
		var lo := a.min(b)
		var hi := a.max(b)
		for y in range(lo.y, hi.y + 2):
			for x in range(lo.x, hi.x + 2):
				cells[Vector2i(x, y)] = true
	for c in cells:
		if not _inside(c) or _solid.has(c) and not path.has(c):
			return false
		if path.has(c) and not joins:
			return false
	for c in cells:
		path[c] = true
		_solid[c] = true
		_taken[c] = true
	return true


func _autotile_path() -> bool:
	for c in path:
		var tile: Vector2i
		var mask := _mask(c, path, true)
		if mask == 15:
			var open := _open_diagonals(c, path, true)
			tile = PATH_FILL if open == 0 else PATH_INNER.get(open, NONE)
		else:
			tile = PATH_SET + ROLES[mask] if ROLES.has(mask) else NONE
		if tile == NONE:
			return false
		features[c] = tile
	return true


# Tile for a cell of a 3x3-set blob (pond or patch), or NONE if the set has
# no cell for that neighborhood.
func _pool_tile(c: Vector2i, cells: Dictionary, origin: Vector2i, inner: Dictionary) -> Vector2i:
	var mask := _mask(c, cells, false)
	if not ROLES.has(mask):
		return NONE
	if mask == 15:
		var open := _open_diagonals(c, cells, false)
		if open != 0:
			return inner.get(open, NONE)
	return origin + ROLES[mask]


func _first_water_below(col: int, from_row: int) -> int:
	for y in range(from_row, HEIGHT):
		if water.has(Vector2i(col, y)) or water.has(Vector2i(col + 1, y)):
			return y
	return -1


# ---------------------------------------------------------------- tones

# Darker grass zones. A smooth tone value lives on every cell corner and is
# interpolated per pixel, so a zone's outline follows a curved noise contour
# instead of the tile grid. Corners on or next to the path or the plateau
# (their tiles bake light lawn) are pinned low, so contours bend away from
# them. Each level covers a fixed share of the map; deeper levels use higher
# cuts on the same field, so they always sit inside the lighter one.
#   Full cells (every corner above the cut) are tiles from the level's fill.
#   Edge cells (the contour crosses them) are drawn per pixel from that same
#   fill, with a dithered rim where the tone is within TONE_BAND of the cut.
const TONE_FREQ := 0.07
const TONE_BAND := 0.03 # width of the dithered rim, in tone units
const TONE_WOBBLE := 0.035 # pixel-scale noise on the cut, so no edge runs straight
const TONE_ANGLE := 0.61 # the field is sampled rotated, off the tile grid
const TONE_CLEAR := 1.0 # corners this close (cells) to path or plateau stay at 0
const TONE_FADE := 4.5 # ...and the field fades back in by this distance
const TONE_MIN_CELLS := [6, 3, 2]

var tone_cut: Array[float] = []
var tone_edges: Array[Dictionary] = [] # per level: cell -> fill atlas
var _corner := PackedFloat32Array()


func _grass_zones() -> void:
	tone_edges.clear()
	tone_cut.clear()
	_corner.resize((WIDTH + 1) * (HEIGHT + 1))
	var clear := _corner_distance()
	var values: Array[float] = []
	for y in HEIGHT + 1:
		for x in WIDTH + 1:
			var i := y * (WIDTH + 1) + x
			var v := _tone(Vector2i(x, y)) * smoothstep(TONE_CLEAR, TONE_FADE, clear[i])
			_corner[i] = v
			if v > 0.0:
				values.append(v)
	values.sort()
	var kept_below := {}
	for level in TONES.size():
		var cut: float = values[int(values.size() * (1.0 - TONES[level].cover))] if not values.is_empty() else 2.0
		tone_cut.append(cut)
		# Cells this level reaches at all, grouped into components; small
		# specks and anything outside the kept lighter level are dropped.
		var touched := {}
		for y in HEIGHT:
			for x in WIDTH:
				var c := Vector2i(x, y)
				if _cell_max(c) + TONE_BAND * 0.5 + TONE_WOBBLE > cut and (level == 0 or kept_below.has(c)):
					touched[c] = true
		var kept := _drop_small_cells(touched, TONE_MIN_CELLS[level])
		var full := {}
		var edge := {}
		for c in kept:
			var atlas := _tone_fill(level, c)
			if _cell_min(c) - TONE_BAND * 0.5 - TONE_WOBBLE > cut and (level == 0 or tones[level - 1].has(c)):
				full[c] = {"atlas": atlas, "alt": [0, FLIP_H, FLIP_V][int(_hash(c.x, c.y, 23 + level) * 37.0) % 3]}
			else:
				edge[c] = atlas
		tones.append(full)
		tone_edges.append(edge)
		kept_below = kept


# Per-level pixel masks (1 = zone) for the edge cells, full map size. The
# wobble and the dither come from noise images built once per map; every
# level uses the same noisy value against a higher cut, so each level's
# pixels always sit inside the lighter level's.
func tone_masks() -> Array[PackedByteArray]:
	var w := WIDTH * 16
	var h := HEIGHT * 16
	var wobble := _noise_bytes(w, h, 1.0 / 22.0, 2, map_id)
	var dither := _noise_bytes(w, h, 1.0, 1, map_id + 1)
	var masks: Array[PackedByteArray] = []
	var cw := WIDTH + 1
	for level in TONES.size():
		var mask := PackedByteArray()
		mask.resize(w * h)
		var cut := tone_cut[level]
		for c: Vector2i in tone_edges[level]:
			var a := _corner[c.y * cw + c.x]
			var b := _corner[c.y * cw + c.x + 1]
			var d := _corner[(c.y + 1) * cw + c.x]
			var e := _corner[(c.y + 1) * cw + c.x + 1]
			for y in 16:
				var fy := (y + 0.5) / 16.0
				var left := lerpf(a, d, fy)
				var right := lerpf(b, e, fy)
				var row := (c.y * 16 + y) * w + c.x * 16
				for x in 16:
					var i := row + x
					var f := lerpf(left, right, (x + 0.5) / 16.0)
					f += (wobble[i] / 255.0 - 0.5) * 2.0 * TONE_WOBBLE
					f += (dither[i] / 255.0 - 0.5) * TONE_BAND
					if f > cut:
						mask[i] = 1
		masks.append(mask)
	return masks


func _noise_bytes(w: int, h: int, freq: float, octaves: int, seed_value: int) -> PackedByteArray:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.seed = seed_value
	noise.frequency = freq
	noise.fractal_octaves = octaves
	return noise.get_image(w, h).get_data()


func _tone_fill(level: int, c: Vector2i) -> Vector2i:
	var fills: Array = TONES[level].fills
	var h := _hash(c.x, c.y, 11 + level)
	return fills[0] if h < 0.55 else fills[1 + int(h * 101.0) % 3]


func _tone(c: Vector2i) -> float:
	var total := 0.0
	var amp := 1.0
	var freq := TONE_FREQ
	var norm := 0.0
	var rx := c.x * cos(TONE_ANGLE) - c.y * sin(TONE_ANGLE)
	var ry := c.x * sin(TONE_ANGLE) + c.y * cos(TONE_ANGLE)
	for octave in 3:
		total += _value_noise(rx * freq + 70.0, ry * freq + 30.0, 300 + octave) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return total / norm


# Bilinear tone at a point in cell units.
func _tone_at(x: float, y: float) -> float:
	var x0 := clampi(floori(x), 0, WIDTH - 1)
	var y0 := clampi(floori(y), 0, HEIGHT - 1)
	var fx := clampf(x - x0, 0.0, 1.0)
	var fy := clampf(y - y0, 0.0, 1.0)
	var w := WIDTH + 1
	var top := lerpf(_corner[y0 * w + x0], _corner[y0 * w + x0 + 1], fx)
	var bottom := lerpf(_corner[(y0 + 1) * w + x0], _corner[(y0 + 1) * w + x0 + 1], fx)
	return lerpf(top, bottom, fy)


func _cell_min(c: Vector2i) -> float:
	var w := WIDTH + 1
	return minf(minf(_corner[c.y * w + c.x], _corner[c.y * w + c.x + 1]), minf(_corner[(c.y + 1) * w + c.x], _corner[(c.y + 1) * w + c.x + 1]))


func _cell_max(c: Vector2i) -> float:
	var w := WIDTH + 1
	return maxf(maxf(_corner[c.y * w + c.x], _corner[c.y * w + c.x + 1]), maxf(_corner[(c.y + 1) * w + c.x], _corner[(c.y + 1) * w + c.x + 1]))


# Distance, in cells, from each corner to the nearest corner of a path or
# plateau cell (3-4 chamfer over the corner grid).
func _corner_distance() -> PackedFloat32Array:
	var w := WIDTH + 1
	var h := HEIGHT + 1
	var d := PackedFloat32Array()
	d.resize(w * h)
	d.fill(9999.0)
	for c in path.keys() + plateau.keys():
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var q: Vector2i = c + o
			d[q.y * w + q.x] = 0.0
	for y in h:
		for x in w:
			var i := y * w + x
			if x > 0: d[i] = minf(d[i], d[i - 1] + 1.0)
			if y > 0:
				d[i] = minf(d[i], d[i - w] + 1.0)
				if x > 0: d[i] = minf(d[i], d[i - w - 1] + 1.414)
				if x < w - 1: d[i] = minf(d[i], d[i - w + 1] + 1.414)
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if x < w - 1: d[i] = minf(d[i], d[i + 1] + 1.0)
			if y < h - 1:
				d[i] = minf(d[i], d[i + w] + 1.0)
				if x < w - 1: d[i] = minf(d[i], d[i + w + 1] + 1.414)
				if x > 0: d[i] = minf(d[i], d[i + w - 1] + 1.414)
	return d


func _drop_small_cells(on: Dictionary, minimum: int) -> Dictionary:
	var seen := {}
	var out := {}
	for start in on:
		if seen.has(start):
			continue
		var comp: Array[Vector2i] = [start]
		seen[start] = true
		var head := 0
		while head < comp.size():
			var c: Vector2i = comp[head]
			head += 1
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var n: Vector2i = c + Vector2i(dx, dy)
					if on.has(n) and not seen.has(n):
						seen[n] = true
						comp.append(n)
		if comp.size() >= minimum:
			for c in comp:
				out[c] = true
	return out


# ---------------------------------------------------------------- patches

# Round recipes use a rounded rectangle of 4-8 cells; irregular ones join a
# 2x2 arm onto a rectangle, so every cell sits in a 2x2 and every corner has
# a tile. Never a lone cell, a 1xN strip, or a 2-cell L.
func _grow_patches() -> void:
	var shape: String = recipe.patch[0]
	var count := _rng.randi_range(recipe.patch[1], recipe.patch[2])
	var tries := 0
	while blobs.size() < count and tries < 500:
		tries += 1
		var irregular := shape == "I" or (shape == "RI" and blobs.size() % 2 == 1)
		var at := Vector2i(_rng.randi_range(2, WIDTH - 6), _rng.randi_range(2, HEIGHT - 6))
		var placed := {}
		for c in _blob_shape(irregular):
			placed[at + c] = true
		if not _patch_fits(placed):
			continue
		var mode := "A" if (map_id + blobs.size()) % 2 == 0 else "B"
		var blob := {"cells": placed, "rect": _bounds(placed), "shape": "I" if irregular else "R", "mode": mode, "tiles": {}, "baked": {}}
		var ok := true
		for c in placed:
			var a := _pool_tile(c, placed, PATCH_SET_A, PATCH_INNER_A)
			var b := _pool_tile(c, placed, PATCH_SET_B, PATCH_INNER_B)
			if a == NONE:
				ok = false
				break
			blob.tiles[c] = a
			blob.baked[c] = b
		if not ok:
			continue
		blobs.append(blob)
		for c in placed:
			_taken[c] = true
			_solid[c] = true
		_claim(blob.rect.grow(1))
	if blobs.size() < recipe.patch[1]:
		dropped.append("patches (%d of %d fit)" % [blobs.size(), recipe.patch[1]])


func _blob_shape(irregular: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = ROUND_SHAPES[_rng.randi() % ROUND_SHAPES.size()]
	var arm := Vector2i(-99, -99)
	if irregular:
		# A 3x2 or 2x3 base with a 2x2 arm overlapping it by one row or
		# column at a corner: an 8-cell L whose join is an inner corner.
		a = [Vector2i(3, 2), Vector2i(2, 3)][_rng.randi() % 2]
		var arms := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, -1), Vector2i(1, -1)] if a.x == 3 \
			else [Vector2i(1, 0), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(-1, 1)]
		arm = arms[_rng.randi() % arms.size()]
	for y in a.y:
		for x in a.x:
			out.append(Vector2i(x, y))
	if irregular:
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
		if c.x < 1 or c.y < 1 or c.x >= WIDTH - 1 or c.y >= HEIGHT - 1:
			return false
		if _taken.has(c):
			return false
		if _near(c, path, 3) or _near(c, fence, 2) or _near(c, water, 2):
			return false
		for b in blobs:
			if _near(c, b.cells, 4):
				return false
	return true


# ---------------------------------------------------------------- props

func _place_props() -> void:
	var flags: Array = recipe.props
	var obstacles := "LR obstacles" in flags
	if "bushes" in flags or "bushes heavy" in flags:
		var n := 12 if "bushes heavy" in flags else 7
		_scatter_props(HEDGES, n / 2 + 1, 6.0)
		_scatter_props(SHRUBS, n, 5.0)
	if "LR" in flags or obstacles:
		_scatter_props(LAND_ROCKS, 7, 6.0)
	if obstacles:
		# Obstacle recipes add big rocks two to four cells off the path, so
		# they stand in the way without closing it.
		_scatter_props(BIG_ROCKS, 5, 5.0, true)
	if "CF" in flags:
		_scatter_props(["campfire"], 1, 1.0)
	if "T" in flags:
		_place_torches()
	_place_signs(recipe.signs)
	_place_clutter()


# Clutter: a couple of fallen logs anywhere on the lawn, and crates and
# chests just outside each house's buffer. All of it collides.
func _place_clutter() -> void:
	_scatter_props(LOGS, _rng.randi_range(1, 3), 8.0)
	for h in houses:
		var size := _cells(HOUSES[h.id].region.size)
		var near := Rect2i(h.origin, size).grow(6)
		var placed := 0
		for i in 200:
			if placed >= 2:
				break
			var art: String = YARD_CLUTTER[_rng.randi() % YARD_CLUTTER.size()]
			var c := near.position + Vector2i(_rng.randi_range(0, near.size.x - 1), _rng.randi_range(0, near.size.y - 1))
			var foot := _footprint(art, c)
			if not _rect_free(foot) or _near_rect(foot, path, 1):
				continue
			var prop := {"art": art, "cell": c, "block": true}
			props.append(prop)
			_claim(foot.grow(1))
			_solidify(foot)
			_block_collider(prop)
			placed += 1


func _scatter_props(arts: Array, count: int, gap: float, by_path := false) -> Array[Dictionary]:
	var added: Array[Dictionary] = []
	var anchors: Array[Vector2i] = []
	for i in 600:
		if added.size() >= count:
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c := Vector2i(_rng.randi_range(2, WIDTH - 3), _rng.randi_range(2, HEIGHT - 3))
		var foot := _footprint(art, c)
		if not _rect_free(foot) or _near_rect(foot, path, 1) or c.distance_to(spawn) < 4:
			continue
		if by_path and not _near_rect(foot, path, 4):
			continue
		var ok := true
		for a in anchors:
			if Vector2(c - a).length() < gap:
				ok = false
				break
		if not ok:
			continue
		var prop := {"art": art, "cell": c, "block": PROPS[art].block != Vector2.ZERO and not art in PEBBLES}
		props.append(prop)
		added.append(prop)
		anchors.append(c)
		_claim(foot)
		_solidify(foot)
		if prop.block:
			_block_collider(prop)
	return added


# Marks every cell the prop's collider overlaps as unwalkable. The collider
# is `block` wide and tall, centred on the foot pixel and resting on it.
func _block_collider(prop: Dictionary) -> void:
	for c in _collider_cells(prop):
		_blocked[c] = true


func _collider_cells(prop: Dictionary) -> Array[Vector2i]:
	var art: Dictionary = PROPS[prop.art]
	var foot: Vector2 = Vector2((prop.cell + art.cell) * 16 + art.base)
	var box := Rect2(foot - Vector2(art.block.x / 2.0, art.block.y), art.block)
	var out: Array[Vector2i] = []
	for y in range(floori(box.position.y / 16.0), floori((box.end.y - 0.01) / 16.0) + 1):
		for x in range(floori(box.position.x / 16.0), floori((box.end.x - 0.01) / 16.0) + 1):
			out.append(Vector2i(x, y))
	return out


# Torches stand on the two gate posts, or flank the path at the doorstep.
func _place_torches() -> void:
	var spots: Array[Vector2i] = []
	if gate.x >= 0:
		spots = [gate + Vector2i(-1, 0), gate + Vector2i(2, 0)]
	elif not houses.is_empty():
		var door := _door(houses[0])
		spots = [door + Vector2i(-1, 1), door + Vector2i(2, 1)]
	for c in spots:
		if not _inside(c) or (not fence.has(c) and _solid.has(c)):
			continue
		props.append({"art": "torch", "cell": c, "block": false})
		_taken[c] = true
		_solid[c] = true
	if spots.is_empty():
		dropped.append("torches (no gate or house)")


func _place_signs(count: int) -> void:
	if count <= 0:
		return
	var ids := range(SIGN.size())
	for i in range(ids.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	# Beside the gate first, then lawn cells just north of the path.
	var spots: Array[Vector2i] = []
	if gate.x >= 0:
		spots.append(gate + Vector2i(-1, 1))
		spots.append(gate + Vector2i(2, 1))
	var along := path.keys()
	along.sort_custom(func(a, b): return a.x < b.x if a.x != b.x else a.y < b.y)
	for c in along:
		spots.append(c + Vector2i.UP)
		spots.append(c + Vector2i.LEFT)
	var placed := 0
	var last: Array[Vector2i] = []
	for c in spots:
		if placed >= count:
			break
		if not _inside(c) or _solid.has(c):
			continue
		var crowded := false
		for l in last:
			if Vector2(c - l).length() < 6.0:
				crowded = true
		if crowded:
			continue
		props.append({"sign": ids[placed], "cell": c, "block": true})
		_taken[c] = true
		_solid[c] = true
		_blocked[c] = true
		last.append(c)
		placed += 1


func _place_trees() -> void:
	var anchors: Array[Vector2i] = []
	for i in 2500:
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
		var tree := {"art": art, "cell": c, "block": true}
		props.append(tree)
		anchors.append(c)
		_claim(clipped)
		_solidify(clipped)
		_block_collider(tree)


func _scatter_deco() -> void:
	for i in 1400:
		var c := Vector2i(_rng.randi_range(0, WIDTH - 1), _rng.randi_range(0, HEIGHT - 1))
		if _solid.has(c) or deco.has(c) or _taken.has(c) and (water.has(c) or plateau.has(c)):
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


# ---------------------------------------------------------------- verify

func _verify() -> String:
	var fails := PackedStringArray()
	for c in path:
		var t: Vector2i = features.get(c, NONE)
		if t == NONE:
			fails.append("path cell %s has no tile" % c)
		elif t == PATH_FILL and (_mask(c, path, true) != 15 or _open_diagonals(c, path, true) != 0):
			fails.append("fill on a cap or knuckle at %s" % c)
	if houses.size() != recipe.houses.size():
		fails.append("houses %d, recipe wants %d" % [houses.size(), recipe.houses.size()])
	for i in houses.size():
		if i < recipe.houses.size() and houses[i].id != recipe.houses[i]:
			fails.append("house %d is prefab %d, recipe names %d" % [i, houses[i].id, recipe.houses[i]])
	if leans > 2:
		fails.append("%d leans" % leans)
	var want_ponds := 2 if "P2" in recipe.water else (1 if "P" in recipe.water else 0)
	if recipe.water == "P if blob" and "pond (no moisture blob)" in dropped:
		want_ponds = 0
	if ponds.size() != want_ponds:
		fails.append("ponds %d, recipe wants %d" % [ponds.size(), want_ponds])
	if "C" in recipe.height and plateau.is_empty():
		fails.append("no plateau")
	if "C" in recipe.height and not _stairs_ok():
		fails.append("plateau stairs missing or blocked")
	if "F" in recipe.height and fence.is_empty():
		fails.append("no fence")
	if "G" in recipe.height and gate.x < 0:
		fails.append("no gate")
	var tone_notes := PackedStringArray()
	for level in tones.size():
		for c in tones[level]:
			if _cell_min(c) <= tone_cut[level]:
				fails.append("%s tone tile at %s is not fully inside its zone" % [TONES[level].name, c])
			if level > 0 and not (tones[level - 1].has(c) or tone_edges[level - 1].has(c)):
				fails.append("%s tone cell %s is outside %s" % [TONES[level].name, c, TONES[level - 1].name])
		var area := tones[level].size() + tone_edges[level].size() / 2
		tone_notes.append("%s %d%%" % [TONES[level].name, roundi(100.0 * area / (WIDTH * HEIGHT))])
	for c in path.keys() + plateau.keys():
		if tone_cut.size() > 0 and _cell_max(c) + TONE_BAND * 0.5 + TONE_WOBBLE > tone_cut[0]:
			fails.append("grass tone can reach %s cell %s" % ["path" if path.has(c) else "plateau", c])
			break
	var patch_notes := PackedStringArray()
	for b in blobs:
		if b.cells.size() < 3 or b.cells.size() > 8:
			fails.append("patch of %d cells" % b.cells.size())
		for c in b.cells:
			if not _in_square(c, b.cells):
				fails.append("patch cell %s is not in a 2x2" % c)
		patch_notes.append("%s%d/%s" % [b.shape, b.cells.size(), b.mode])
	var counts := {}
	var sign_ids := {}
	for p in props:
		var kind := "sign" if p.has("sign") else _kind(p.art)
		counts[kind] = counts.get(kind, 0) + 1
		if p.has("sign"):
			sign_ids[p.sign] = true
		elif kind == "land rock" and not _land(_footprint(p.art, p.cell)):
			fails.append("land rock off the lawn at %s" % p.cell)
		if kind == "land rock" and p.block != (p.art in BIG_ROCKS):
			fails.append("%s at %s %s" % [p.art, p.cell, "blocks" if p.block else "does not block"])
		if p.get("block", false) and p.has("art") and PROPS[p.art].block != Vector2.ZERO:
			for c in _collider_cells(p):
				if not _blocked.has(c):
					fails.append("%s collider cell %s is walkable in the grid" % [p.art, c])
		elif kind in ["water plant", "water rock"] and not _wet(_footprint(p.art, p.cell)):
			fails.append("%s off the water at %s" % [kind, p.cell])
	var needs := {"bushes": "bush", "bushes heavy": "bush", "LR": "land rock", "LR obstacles": "land rock", "CF": "campfire", "T": "torch"}
	for flag in recipe.props:
		if counts.get(needs[flag], 0) == 0:
			fails.append("recipe asks for %s, none placed" % needs[flag])
	if want_ponds > 0 and "WP" in recipe.water and counts.get("water plant", 0) == 0:
		fails.append("no water plants")
	if want_ponds > 0 and "WR" in recipe.water and counts.get("water rock", 0) == 0:
		fails.append("no water rocks")
	if sign_ids.size() != recipe.signs:
		fails.append("signs %d distinct, recipe wants %d" % [sign_ids.size(), recipe.signs])
	for c in path:
		if _blocked.has(c):
			fails.append("path cell %s is blocked" % c)
	for g in goals:
		if not _reaches(spawn, g):
			fails.append("spawn does not reach %s" % g)
	var house_names := PackedStringArray()
	for h in houses:
		house_names.append(HOUSES[h.id].name)
	var lines := PackedStringArray([
		"Painted Lands map %d: recipe %d %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, WIDTH, HEIGHT, attempt],
		"  houses: %s; ponds %d; plateau %s; fence %d; leans %d" % [", ".join(house_names) if not houses.is_empty() else "none", ponds.size(), "with stairs" if not stairs.is_empty() else ("yes" if not plateau.is_empty() else "no"), fence.size(), leans],
		"  path %d cells (%s), patches %s" % [path.size(), recipe.path, " ".join(patch_notes)],
		"  grass tones: %s" % ", ".join(tone_notes),
		"  props: %s; signs %s" % [str(counts), str(sign_ids.keys())],
		"  walk from %s to %d goals: %s" % [spawn, goals.size(), "ok" if not "spawn does not reach" in "; ".join(fails) else "FAIL"],
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	if not dropped.is_empty():
		lines.append("  dropped: %s" % ", ".join(dropped))
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
	if art in SHORE_PLANTS or art in OPEN_PLANTS:
		return "water plant"
	if art in WATER_ROCKS:
		return "water rock"
	if art in LOGS or art in YARD_CLUTTER:
		return "clutter"
	return art


func _land(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if water.has(Vector2i(x, y)) or plateau.has(Vector2i(x, y)):
				return false
	return true


# Stairs must be a full 3 x FACE_ROWS block, and every stair cell walkable.
func _stairs_ok() -> bool:
	return stairs.size() == 3 * FACE_ROWS and stairs.keys().all(func(c): return not _blocked.has(c))


func _wet(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not water.has(Vector2i(x, y)):
				return false
	return true


# ---------------------------------------------------------------- helpers

func _footprint(art: String, anchor: Vector2i) -> Rect2i:
	var p: Dictionary = PROPS[art]
	return Rect2i(anchor + p.cell, p.region.size)


func _block_pixels(origin_px: Vector2i, r: Rect2i) -> void:
	var p := origin_px + r.position
	for y in range(p.y / 16, (p.y + r.size.y - 1) / 16 + 1):
		for x in range(p.x / 16, (p.x + r.size.x - 1) / 16 + 1):
			_blocked[Vector2i(x, y)] = true
			_solid[Vector2i(x, y)] = true


# Map edges count as path so roads run off the map instead of capping.
func _mask(c: Vector2i, cells: Dictionary, edge_counts: bool) -> int:
	var mask := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = c + dirs[i]
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


# Moisture: 4-octave value-noise fBm at frequency 0.05.
func _moisture(c: Vector2i) -> float:
	var total := 0.0
	var amp := 1.0
	var freq := 0.05
	var norm := 0.0
	for octave in 4:
		total += _value_noise(c.x * freq + 40.0, c.y * freq + 20.0, 100 + octave) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return total / norm


func _wettest(zone: Rect2i) -> Vector2i:
	var best := zone.get_center()
	var wet := -1.0
	for y in range(zone.position.y + 2, zone.end.y - 2):
		for x in range(zone.position.x + 3, zone.end.x - 3):
			var m := _moisture(Vector2i(x, y))
			if m > wet:
				wet = m
				best = Vector2i(x, y)
	return best


func _value_noise(x: float, y: float, salt: int) -> float:
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := x - x0
	var fy := y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var top := lerpf(_hash(x0, y0, salt), _hash(x0 + 1, y0, salt), fx)
	var bottom := lerpf(_hash(x0, y0 + 1, salt), _hash(x0 + 1, y0 + 1, salt), fx)
	return lerpf(top, bottom, fy)


func _hash(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041 + map_id * 2654435761) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
