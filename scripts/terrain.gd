class_name MysticTerrain
extends RefCounted
## Tile-id grid for the Mystic Woods maps (docs/deprecated/mystic-woods.md).
## Output is plains.png / decor_16x16.png atlas coordinates, pond rectangles,
## fences, walled structures, and prop placements. Nothing here paints pixels.
## A recipe (seed % RECIPES.size(), unless pinned) sets the terrain mix and
## the set piece around the goal; recipe 0 is the original clearing.

const GRASS := 0
const DIRT := 1
const CLIFF := 2
const WATER := 3
const COBBLE := 4 # plains.png rows 8-11: cobblestone ground, walkable

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
const COBBLE_ROW := 8 # plains.png rows 8-11 are cobblestone on grass, not water

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
const MUSHROOMS: Array[Vector2i] = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]
# decor_16x16.png row 4: loose dirt spots on a transparent ground.
const DIRT_SPOTS: Array[Vector2i] = [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4)]
# decor_8x8.png (8 px cells): rows 0-2 on the meadow green (stones, sprigs,
# flowers), row 3 on the dirt fill (specks). Detail sits on an 8 px grid.
const DETAIL_GRASS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(0, 1),
	Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]
const DETAIL_DIRT: Array[Vector2i] = [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3)]
const WATER_RIPPLES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0)]
const STONES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
# water_decorations.png: rocks in water (row 0), lily pads (row 1).
const WATER_ROCKS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(5, 0)]
const LILIES: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)]

# Recipes. `cliff`: the height above which ground is cliff. `water`: "noise"
# (the moisture field, cut to rectangles the pond art can draw), "ponds"
# (one to three placed ponds), "lake" (one big lake with islands), or "none".
# `arena`: the goal's flattened radius. `piece`: the set piece at the goal.
# `road`: DIRT or COBBLE. Scatter: `tree_gap`, `trees`, `mushrooms` (share of
# deco spots), `extras` ([arts, count, gap] groups scattered on the lawn).
const RECIPES := [
	{"name": "Clearing", "cliff": 0.64, "water": "noise", "arena": 4, "piece": "shrine"},
	{"name": "Pond glade", "cliff": 0.72, "water": "ponds", "arena": 4, "piece": "shrine", "mushrooms": 0.1},
	{"name": "Lake island", "cliff": 0.76, "water": "lake", "arena": 5, "piece": "lakeside"},
	{"name": "Farmstead", "cliff": 0.7, "water": "noise", "arena": 7, "piece": "farm",
		"extras": [[["stump_a", "stump_b"], 3, 6.0], [["log", "log_flower"], 2, 8.0]]},
	{"name": "Stone ruins", "cliff": 0.62, "water": "none", "arena": 8, "piece": "ruins",
		"extras": [[["pillar", "arch"], 3, 9.0], [["big_skull", "skull"], 3, 7.0]]},
	{"name": "Cottage garden", "cliff": 0.72, "water": "none", "arena": 7, "piece": "cottage",
		"extras": [[["bush"], 3, 7.0]]},
	{"name": "Graveyard", "cliff": 0.68, "water": "none", "arena": 7, "piece": "graveyard", "mushrooms": 0.3,
		"extras": [[["stump_a", "stump_b"], 3, 7.0], [["grave"], 2, 9.0]]},
	{"name": "Cobble crossroads", "cliff": 0.76, "water": "none", "arena": 6, "piece": "plaza", "road": 4},
	{"name": "Rocky highland", "cliff": 0.57, "water": "none", "arena": 4, "piece": "shrine", "cobble_fields": true,
		"trees": ["cypress"], "tree_gap": 7.5, "extras": [[["rock_0", "rock_1", "rock_2"], 10, 5.0]]},
	{"name": "Orchard", "cliff": 0.76, "water": "none", "arena": 11, "piece": "orchard", "trees": ["tree_b", "tree_d"],
		"extras": [[["basket", "crate"], 3, 9.0]]},
	{"name": "Woodcutter's glade", "cliff": 0.7, "water": "noise", "arena": 6, "piece": "woodcutter",
		"extras": [[["stump_a", "stump_b"], 10, 5.0], [["log", "long_log", "log_flower"], 5, 7.0]]},
	{"name": "Campsite", "cliff": 0.68, "water": "ponds", "arena": 6, "piece": "camp"},
	{"name": "Mushroom hollow", "cliff": 0.7, "water": "none", "arena": 5, "piece": "hollow", "tree_gap": 4.6,
		"trees": ["tree_a", "tree_c", "cypress"], "mushrooms": 0.55, "extras": [[["stump_a", "stump_b"], 4, 7.0], [["bush"], 4, 6.0]]},
	{"name": "Abandoned house", "cliff": 0.72, "water": "none", "arena": 7, "piece": "house",
		"extras": [[["sapling_a", "sapling_b"], 4, 6.0], [["bush"], 2, 8.0]]},
	{"name": "Stone chapel", "cliff": 0.68, "water": "ponds", "arena": 9, "piece": "chapel",
		"extras": [[["grave"], 3, 8.0], [["pillar", "arch"], 2, 10.0]]},
	{"name": "Tree nursery", "cliff": 0.76, "water": "noise", "arena": 7, "piece": "nursery", "trees": ["tree_a", "tree_b", "cypress"],
		"extras": [[["sapling_a", "sapling_b"], 6, 4.0], [["pot_empty", "pot_sprout"], 3, 7.0]]},
]

# Cells a piece or extra covers, relative to its anchor (bottom-left cell),
# and whether it blocks the walker.
const PIECE_FOOT := {
	"sign": [Rect2i(0, 0, 1, 1), true], "basket": [Rect2i(0, 0, 1, 1), true], "barrel": [Rect2i(0, 0, 1, 1), true],
	"pot": [Rect2i(0, 0, 1, 1), true], "crate": [Rect2i(0, 0, 1, 1), true], "drawers": [Rect2i(0, 0, 1, 1), true],
	"grave": [Rect2i(0, 0, 1, 1), true], "skull": [Rect2i(0, 0, 1, 1), false], "big_skull": [Rect2i(0, 0, 1, 1), true],
	"pit": [Rect2i(0, 0, 1, 1), true], "pot_sprout": [Rect2i(0, 0, 1, 1), true], "potted_tree": [Rect2i(0, -1, 1, 2), true],
	"bench": [Rect2i(0, 0, 2, 1), true], "table": [Rect2i(0, 0, 2, 1), true], "log": [Rect2i(0, 0, 2, 1), true],
	"log_flower": [Rect2i(0, 0, 2, 1), true], "long_log": [Rect2i(0, 0, 3, 1), true], "bush": [Rect2i(0, -1, 2, 2), true],
	"stump_a": [Rect2i(0, 0, 2, 1), true], "stump_b": [Rect2i(0, 0, 2, 1), true],
	"rock_0": [Rect2i(0, 0, 1, 1), true], "rock_1": [Rect2i(0, 0, 1, 1), true], "rock_2": [Rect2i(0, 0, 1, 1), true],
	"cypress": [Rect2i(-1, -2, 2, 3), true], "tree_a": [Rect2i(-1, -3, 3, 4), true], "tree_b": [Rect2i(-1, -3, 3, 4), true],
	"tree_c": [Rect2i(-1, -3, 3, 4), true], "tree_d": [Rect2i(-1, -3, 3, 4), true],
	"sapling_a": [Rect2i(0, 0, 1, 1), false], "sapling_b": [Rect2i(0, 0, 1, 1), false], "pot_empty": [Rect2i(0, 0, 1, 1), true],
	"chest_iron": [Rect2i(0, 0, 1, 1), true], "chest_gold": [Rect2i(0, 0, 1, 1), true],
	"bed": [Rect2i(0, -1, 1, 2), true], "bookshelf": [Rect2i(0, -1, 1, 2), true], "stool": [Rect2i(0, 0, 1, 1), true],
	"small_table": [Rect2i(0, 0, 1, 1), true], "long_table": [Rect2i(0, 0, 3, 1), true],
	# Small things set on a table or the floor: no footprint of their own.
	"potion": [Rect2i(0, 0, 1, 1), false], "scroll": [Rect2i(0, 0, 1, 1), false], "heart": [Rect2i(0, 0, 1, 1), false],
	# Roofless stone structures from walls.png: wall tops over a brick face.
	"hut": [Rect2i(0, -4, 3, 5), true], "pillar": [Rect2i(0, -4, 1, 5), true], "arch": [Rect2i(0, -3, 1, 4), true],
}

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
var recipe_id := 0
var recipe: Dictionary = RECIPES[0]
var shrine_radius := SHRINE_RADIUS
var cliff_above := CLIFF_ABOVE
var ponds: Array[Rect2i] = []
var islands: Array[Vector2i] = [] # top-left cell of each 2x2 island
var water_deco := {} # cell -> water_decorations.png atlas
var fence := {} # cell -> true
var fires: Array[Vector2i] = [] # fire pit cells
var blocked := {} # cells fences, structures, and set-piece props block
var lane := {} # the route's cells inside the goal arena: kept clear
var floors := {} # cell -> [sheet, atlas]: "wooden" or "flooring" floor tiles under a set piece
var rugs := {} # cell -> [sheet, atlas]: carpet.png rugs lying on a floor (their edges are see-through)
var detail := {} # 8 px cell -> decor_8x8.png atlas
var water_anim := {} # cell -> "rock" | "lily": animated rock_in_water / water_lillies on a pond
var enrich := false # detail, dirt spots, and the liveliness floor (randomizer)
var floor_notes := PackedStringArray()
var piece_notes := PackedStringArray()
var piece_fails := PackedStringArray()

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


## `p_recipe`: a recipe index, or -1 for seed % RECIPES.size(). The fixed
## scenes pin 0, the original clearing.
func generate(p_seed: int, p_include_water := true, p_recipe := 0, p_enrich := false) -> String:
	enrich = p_enrich
	seed_value = p_seed
	recipe_id = p_recipe if p_recipe >= 0 else posmod(p_seed, RECIPES.size())
	recipe = RECIPES[recipe_id]
	include_water = p_include_water and recipe.water == "noise"
	shrine_radius = recipe.arena
	cliff_above = recipe.cliff
	# Recipe 0 is built once, exactly as the original clearing. The others
	# retry with a new layout seed (new goal, ponds, and pieces on the same
	# noise) while the goal cannot be reached.
	var report := ""
	for attempt in (1 if recipe_id == 0 else 8):
		_rng.seed = p_seed + attempt * 7919
		report = _build()
		if _flood_reaches_shrine():
			break
	return report


func _build() -> String:
	kind.resize(WIDTH * HEIGHT)
	for d in [features, deco, water_deco, fence, blocked, lane, _occupied, floors, rugs, detail, water_anim]:
		d.clear()
	for a in [props, ponds, islands, fires]:
		a.clear()
	piece_notes.clear()
	piece_fails.clear()
	floor_notes.clear()

	_sample_biomes()
	for i in 3:
		_smooth()
	_erode(2)
	_cull(CLIFF, 40)
	_cull(WATER, 12)
	_place_arenas()
	_autotile()
	if recipe.water == "ponds" or recipe.water == "lake":
		_lay_ponds(recipe.water == "lake")
	if recipe.get("cobble_fields", false):
		_cobble_fields()
	_carve_route()
	_shape_water()
	_lay_piece()
	_autotile()
	var dirt_dups := _break_duplicates(DIRT, DIRT_FILLS)
	var plateau_dups := _break_duplicates(CLIFF, PLATEAU_FILLS)
	_scatter()
	if enrich:
		_liveliness_floor()
		_scatter_detail()
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
			if h > cliff_above:
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
	_flatten(shrine, shrine_radius)


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
				COBBLE:
					features[cell] = _pool_tile(mask, x, y, k, [Vector2i(2, 1)], COBBLE_ROW)
				WATER:
					pass # ponds are drawn from water-sheet.png by the painter
				CLIFF:
					features[cell] = _pick(x, y, PLATEAU_FILLS) if mask == 15 else PLATEAU_TILES[mask]
					# The randomizer draws the plateau's inside corners with the
					# pack's cells (4-5, 4-6), the same layout as the dirt's.
					if enrich and mask == 15:
						var open := _open_diagonals(x, y, k)
						if open != 0:
							features[cell] = INNER_TILES.get(open, INNER_TILES[open & -open]) + Vector2i(0, 4)


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
	var placed_water: bool = recipe.water == "ponds" or recipe.water == "lake"
	for y in HEIGHT:
		for x in WIDTH:
			match kind[_i(x, y)]:
				CLIFF:
					grid.set_point_weight_scale(Vector2i(x, y), CLIFF_COST)
				WATER:
					if placed_water:
						grid.set_point_solid(Vector2i(x, y)) # placed ponds are kept whole
					else:
						grid.set_point_weight_scale(Vector2i(x, y), WATER_COST)
	var path := grid.get_id_path(spawn, shrine)
	route_length = path.size()
	var road: int = recipe.get("road", DIRT)
	for p in path:
		_stamp_dirt(p, road)
		_stamp_dirt(p + Vector2i.RIGHT, road)
		# Inside the goal arena the route stays lawn, and set pieces keep off it.
		for q in [p, p + Vector2i.RIGHT]:
			if _in_disk(q, shrine, shrine_radius) and _inside(q.x, q.y):
				lane[q] = true


func _stamp_dirt(c: Vector2i, road := DIRT) -> void:
	if c.x <= 0 or c.y <= 0 or c.x >= WIDTH - 1 or c.y >= HEIGHT - 1:
		return
	if _in_arena(c):
		return
	kind[_i(c.x, c.y)] = road


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
	var trees := _poisson(recipe.get("tree_gap", TREE_GAP), 2000, func(c): return _clear(c, FOOTPRINT["tree"], 2))
	var tree_arts: Array = recipe.get("trees", TREES)
	for c in trees:
		_claim(c, FOOTPRINT["tree"])
		props.append({"art": tree_arts[_rng.randi() % tree_arts.size()], "cell": c})
	var rocks := _poisson(ROCK_GAP, 800, func(c): return _clear(c, FOOTPRINT["rock"], 1))
	for c in rocks:
		_claim(c, FOOTPRINT["rock"])
		props.append({"art": ROCKS[_rng.randi() % ROCKS.size()], "cell": c})
	var spots := _poisson(DECO_GAP, 2500, func(c): return _clear(c, FOOTPRINT["rock"], 0))
	for c in spots:
		_claim(c, FOOTPRINT["rock"])
		var pool := FLOWERS if _rng.randf() < 0.45 else TUFTS
		if recipe.has("mushrooms") and _rng.randf() < recipe.mushrooms:
			pool = MUSHROOMS
		deco[c] = pool[_rng.randi() % pool.size()]
	if recipe.piece == "shrine":
		_shrine_prefab()
	for group in recipe.get("extras", []):
		var arts: Array = group[0]
		var spots2 := _poisson(group[2], 1200, func(c): return _piece_fits(arts[0], c, 1, false))
		var added := 0
		for c in spots2:
			if added >= group[1]:
				break
			var art: String = arts[_rng.randi() % arts.size()]
			if _piece_fits(art, c, 1, false):
				_put(art, c)
				added += 1


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
	if _in_disk(anchor, spawn, SPAWN_RADIUS + margin) or _in_disk(anchor, shrine, shrine_radius + margin):
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
		if not (deco[c] in TUFTS or deco[c] in FLOWERS or deco[c] in MUSHROOMS or deco[c] in STONES or deco[c] in DIRT_SPOTS):
			bad_ids += 1
	var counts := [0, 0, 0, 0, 0]
	for k in kind:
		counts[k] += 1
	var reach := _flood_reaches_shrine()
	var lines := PackedStringArray([
		"Mystic Woods seed %d, %dx%d" % [seed_value, WIDTH, HEIGHT],
		"  recipe %d: %s" % [recipe_id, recipe.name],
		"  cells: grass %d, dirt %d, cliff %d, water %d, cobble %d" % counts,
		"  ponds %d, islands %d, fence %d cells, fires %d%s" % [ponds.size(), islands.size(), fence.size(), fires.size(),
			(", " + ", ".join(piece_notes)) if not piece_notes.is_empty() else ""],
		"  spawn %s, shrine %s, route %d, water link %d" % [spawn, shrine, route_length, water_link],
		"  props %d, deco %d" % [props.size(), deco.size()],
		"  ids in pack: %s" % ("ok" if bad_ids == 0 else "%d bad" % bad_ids),
		"  spawn reaches shrine: %s" % ("ok" if reach else "FAIL"),
		"  dirt 3x3 repeats: %d" % dirt_dups,
		"  plateau 3x3 repeats: %d%s" % [plateau_dups, " (plains.png has one clean plateau fill)" if plateau_dups > 0 else ""],
	])
	if not floor_notes.is_empty():
		lines.append("  floor: %s" % " ".join(floor_notes))
	var fails := piece_fails.duplicate()
	if bad_ids > 0:
		fails.append("%d ids not in the pack" % bad_ids)
	if not reach:
		fails.append("spawn does not reach the goal")
	if (recipe.water == "ponds" or recipe.water == "lake") and ponds.is_empty():
		fails.append("no pond")
	lines.append("  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)))
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
			if _inside(n.x, n.y) and not seen.has(n) and kind[_i(n.x, n.y)] in [GRASS, DIRT, COBBLE] and not blocked.has(n):
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
	return _in_disk(c, spawn, SPAWN_RADIUS) or _in_disk(c, shrine, shrine_radius)


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


# ---------------------------------------------------------------- recipes

# Placed ponds: rectangles the pond art draws (a bank on all four sides, open
# water inside), on plain grass two cells clear of cliffs, both arenas, and
# each other. A lake is one big rectangle with one or two 2x2 islands.
func _lay_ponds(lake: bool) -> void:
	var want := 1 if lake else _rng.randi_range(1, 3)
	for attempt in 400:
		if ponds.size() >= want:
			break
		var size := Vector2i(_rng.randi_range(12, 17), _rng.randi_range(8, 11)) if lake \
			else Vector2i(_rng.randi_range(4, 7), _rng.randi_range(3, 5))
		var r := Rect2i(Vector2i(_rng.randi_range(2, WIDTH - size.x - 2), _rng.randi_range(2, HEIGHT - size.y - 2)), size)
		if not _rect_is(r.grow(2), GRASS) or _rect_near_arena(r, 2):
			continue
		var clash := false
		for o in ponds:
			if o.grow(3).intersects(r):
				clash = true
		if clash:
			continue
		_fill_rect(r, WATER)
		ponds.append(r)
		if lake:
			_lay_islands(r)
		_dress_pond(r)


func _lay_islands(r: Rect2i) -> void:
	var inner := r.grow(-2) # open water with at least one water cell around
	for i in 40:
		if islands.size() >= 2 or inner.size.x < 2 or inner.size.y < 2:
			return
		var at := Vector2i(_rng.randi_range(inner.position.x, inner.end.x - 2), _rng.randi_range(inner.position.y, inner.end.y - 2))
		var ok := true
		for o in islands:
			if Rect2i(o, Vector2i(2, 2)).grow(1).intersects(Rect2i(at, Vector2i(2, 2))):
				ok = false
		if ok:
			islands.append(at)


# Lily pads and rocks on some open-water cells (not the bank or islands).
func _dress_pond(r: Rect2i) -> void:
	var open := r.grow(-1)
	for y in range(open.position.y, open.end.y):
		for x in range(open.position.x, open.end.x):
			var c := Vector2i(x, y)
			if _on_island(c) or _rng.randf() > 0.16:
				continue
			var roll := _rng.randf()
			if roll < 0.12:
				water_anim[c] = "rock" # rock_in_water_01-sheet.png, water lapping round it
			elif roll < 0.3:
				water_anim[c] = "lily" # water_lillies.png, bobbing
			elif roll < 0.4:
				water_deco[c] = WATER_RIPPLES[_rng.randi() % WATER_RIPPLES.size()]
			else:
				water_deco[c] = LILIES[_rng.randi() % LILIES.size()] if _rng.randf() < 0.7 else WATER_ROCKS[_rng.randi() % WATER_ROCKS.size()]


func _on_island(c: Vector2i) -> bool:
	for o in islands:
		if Rect2i(o, Vector2i(2, 2)).has_point(c):
			return true
	return false


# "noise" water: each pool from the moisture field is cut to the largest
# rectangle inside it at least 3x3 (the pond art has no inside corners);
# the rest turns back to grass.
func _shape_water() -> void:
	if recipe.water != "noise":
		return
	var seen := {}
	for y in HEIGHT:
		for x in WIDTH:
			var c := Vector2i(x, y)
			if seen.has(c) or kind[_i(x, y)] != WATER:
				continue
			var comp := {c: true}
			var queue: Array[Vector2i] = [c]
			seen[c] = true
			while not queue.is_empty():
				var q: Vector2i = queue.pop_back()
				for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
					var n: Vector2i = q + d
					if _inside(n.x, n.y) and not seen.has(n) and kind[_i(n.x, n.y)] == WATER:
						seen[n] = true
						comp[n] = true
						queue.append(n)
			var best := _largest_rect(comp)
			for k in comp:
				if not best.has_point(k):
					kind[_i(k.x, k.y)] = GRASS
			if best.size.x >= 3 and best.size.y >= 3:
				ponds.append(best)
				_dress_pond(best)
			else:
				for k in comp:
					kind[_i(k.x, k.y)] = GRASS


# Largest axis-aligned rectangle inside `cells` (histogram method).
func _largest_rect(cells: Dictionary) -> Rect2i:
	var lo := Vector2i(WIDTH, HEIGHT)
	var hi := Vector2i(-1, -1)
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var w := hi.x - lo.x + 1
	var heights := PackedInt32Array()
	heights.resize(w)
	heights.fill(0)
	var best := Rect2i()
	for y in range(lo.y, hi.y + 1):
		for i in w:
			heights[i] = heights[i] + 1 if cells.has(Vector2i(lo.x + i, y)) else 0
		for i in w:
			var h := heights[i]
			var j := i
			var run_h := h
			while j < w and heights[j] > 0:
				run_h = mini(run_h, heights[j])
				var r := Rect2i(lo.x + i, y - run_h + 1, j - i + 1, run_h)
				if r.size.x >= 3 and r.size.y >= 3 and r.get_area() > best.get_area():
					best = r
				j += 1
	return best


# Rocky highland: patches of cobblestone from a separate noise, off the arenas.
func _cobble_fields() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var c := Vector2i(x, y)
			if kind[_i(x, y)] == GRASS and not _in_arena(c) and _fbm(x * 0.09 + 7.0, y * 0.09 + 3.0, 300) > 0.6:
				kind[_i(x, y)] = COBBLE
	_cull(COBBLE, 8)


# The set piece around the goal. Everything keeps off the lane (the route's
# last stretch to the goal) and stays inside the goal arena.
func _lay_piece() -> void:
	match recipe.piece:
		"lakeside":
			_near_goal(["bench"], 2)
			_near_goal(["sign"], 1)
			_near_goal(["pot_sprout", "potted_tree"], 2)
		"farm":
			if _fenced_yard(Vector2i(9, 7)):
				var inside := _yard.grow(-1)
				_near_goal(["crate", "barrel", "basket", "pot", "drawers"], _rng.randi_range(5, 7), inside)
				_near_goal(["chest_iron"], 1, inside)
				# A lone hitching post outside the yard (fences.png's single post).
				for i in 30:
					var c := shrine + Vector2i(_rng.randi_range(-6, 6), _rng.randi_range(-6, 6))
					if not _yard.grow(1).has_point(c) and not _near_lane(c) and _piece_fits("sign", c, 0, true) \
							and not fence.has(c + Vector2i.LEFT) and not fence.has(c + Vector2i.RIGHT) \
							and not fence.has(c + Vector2i.UP) and not fence.has(c + Vector2i.DOWN):
						fence[c] = true
						blocked[c] = true
						_occupied[c] = true
						break
			else:
				piece_fails.append("no yard")
		"graveyard":
			if _fenced_yard(Vector2i(9, 7)):
				var graves := 0
				var inside := _yard.grow(-1)
				for y in range(inside.position.y, inside.end.y, 2):
					for x in range(inside.position.x, inside.end.x, 2):
						var c := Vector2i(x, y)
						if not _near_lane(c) and _piece_fits("grave", c, 0, true):
							_put("grave", c)
							graves += 1
				_near_goal(["skull", "big_skull"], 2, inside)
				piece_notes.append("%d graves" % graves)
				if graves < 3:
					piece_fails.append("only %d graves" % graves)
			else:
				piece_fails.append("no yard")
		"ruins":
			_cobble_disk(shrine, 3)
			var walls := _near_goal(["hut"], 1) + _near_goal(["pillar", "arch"], _rng.randi_range(2, 3))
			_near_goal(["skull", "big_skull", "rock_0", "rock_2"], 3)
			_near_goal(["chest_gold"], 1)
			piece_notes.append("%d walls" % walls)
			if walls < 2:
				piece_fails.append("no ruin walls")
		"cottage":
			# North of the goal if it fits there, else anywhere in the arena.
			if _near_goal(["hut"], 1, Rect2i(shrine - Vector2i(4, 5), Vector2i(9, 5))) == 0 and _near_goal(["hut"], 1) == 0:
				piece_fails.append("no cottage")
			_near_goal(["pot_sprout", "potted_tree", "pot", "basket"], 4)
			_near_goal(["bench"], 1)
			_fence_runs(2)
		"plaza":
			_cobble_disk(shrine, 4)
			_near_goal(["bench"], 2)
			_near_goal(["sign"], 2)
			_near_goal(["barrel", "crate", "potted_tree"], 3)
		"orchard":
			var planted := 0
			# Rows of fruit trees on a loose grid, a few tries per slot.
			for gy in range(-1, 2):
				for gx in range(-2, 3):
					var art := "tree_b" if _rng.randf() < 0.5 else "tree_d"
					for t in 4:
						var c := shrine + Vector2i(gx * 4 + _rng.randi_range(-1, 1), gy * 5 + 1 + _rng.randi_range(-1, 1))
						if not _near_lane(c) and _piece_fits(art, c, 0, true):
							_put(art, c)
							planted += 1
							break
			_near_goal(["basket", "crate"], 3)
			piece_notes.append("%d orchard trees" % planted)
			if planted < 3:
				piece_fails.append("only %d orchard trees" % planted)
		"woodcutter", "camp":
			if _near_goal(["pit"], 1, Rect2i(shrine - Vector2i(2, 2), Vector2i(5, 5))) == 0:
				piece_fails.append("no fire pit")
			else:
				var pit: Vector2i = fires[0]
				_near_goal(["log", "long_log"] if recipe.piece == "woodcutter" else ["log", "log_flower"], 3,
					Rect2i(pit - Vector2i(4, 3), Vector2i(9, 7)))
			_near_goal(["crate", "barrel"], 2)
			if not fires.is_empty():
				_bare_earth(fires[0], 3) # trodden earth round the fire
			_dirt_bed(Vector2i(4, 3)) # a cleared patch: a chopping ground or a camp's work floor
			if recipe.piece == "camp":
				_near_goal(["bench"], 1)
				_near_goal(["sign"], 1)
				_near_goal(["chest_iron"], 1)
		"house":
			_lay_house()
		"chapel":
			_lay_chapel()
		"nursery":
			if _fenced_yard(Vector2i(9, 7)):
				var inside := _yard.grow(-1)
				var rows := 0
				for y in range(inside.position.y, inside.end.y, 2):
					for x in range(inside.position.x, inside.end.x):
						var c := Vector2i(x, y)
						var art := "sapling_a" if (x + y) % 3 else "sapling_b"
						if not _near_lane(c) and _piece_fits(art, c, 0, true):
							_put(art, c)
							rows += 1
				_near_goal(["pot_empty", "pot_sprout", "potted_tree", "basket"], 4)
				_bare_earth(_yard.get_center(), 3) # the worked bed between the rows
				_dirt_bed(Vector2i(4, 3)) # a freshly dug seedbed outside the yard
				for i in 12: # the worked soil of the beds
					var c := inside.position + Vector2i(_rng.randi_range(0, inside.size.x - 1), _rng.randi_range(0, inside.size.y - 1))
					if not _occupied.has(c) and not lane.has(c) and kind[_i(c.x, c.y)] == GRASS:
						deco[c] = DIRT_SPOTS[_rng.randi() % DIRT_SPOTS.size()]
						_occupied[c] = true
				piece_notes.append("%d saplings" % rows)
				if rows < 6:
					piece_fails.append("only %d saplings" % rows)
			else:
				piece_fails.append("no yard")
		"hollow":
			_near_goal(["stump_b"], 1, Rect2i(shrine - Vector2i(2, 2), Vector2i(5, 5)))
			for i in 30:
				var c := shrine + Vector2i(_rng.randi_range(-3, 3), _rng.randi_range(-3, 3))
				if _in_disk(c, shrine, shrine_radius - 1) and not lane.has(c) and not _occupied.has(c) and kind[_i(c.x, c.y)] == GRASS:
					deco[c] = MUSHROOMS[_rng.randi() % MUSHROOMS.size()]
					_occupied[c] = true


var _yard := Rect2i()


# A fence around a rectangle centred on the goal, with a gate where the lane
# crosses it (at least two cells wide). Returns false if it does not fit.
func _fenced_yard(size: Vector2i) -> bool:
	var r := Rect2i(shrine - size / 2, size)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not _inside(x, y) or kind[_i(x, y)] != GRASS or not _in_disk(Vector2i(x, y), shrine, shrine_radius):
				return false
	var border: Array[Vector2i] = []
	for x in range(r.position.x, r.end.x):
		border.append(Vector2i(x, r.position.y))
		border.append(Vector2i(x, r.end.y - 1))
	for y in range(r.position.y + 1, r.end.y - 1):
		border.append(Vector2i(r.position.x, y))
		border.append(Vector2i(r.end.x - 1, y))
	var gate := {}
	for c in border:
		if lane.has(c):
			gate[c] = true
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if c + d in border:
					gate[c + d] = true
	if gate.is_empty():
		return false
	for c in border:
		if gate.has(c):
			continue
		fence[c] = true
		blocked[c] = true
		_occupied[c] = true
	_yard = r
	# A sign outside the gate.
	for c in gate:
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var o: Vector2i = c + d
			if not r.has_point(o) and not lane.has(o) and _piece_fits("sign", o, 0, true):
				_put("sign", o)
				return true
	return true


# One or two short fence runs flanking the goal (a garden edge).
func _fence_runs(count: int) -> void:
	for i in count:
		for attempt in 20:
			var horizontal := _rng.randf() < 0.5
			var length := _rng.randi_range(3, 5)
			var start := shrine + Vector2i(_rng.randi_range(-5, 2), _rng.randi_range(-1, 4))
			var cells: Array[Vector2i] = []
			for k in length:
				cells.append(start + (Vector2i(k, 0) if horizontal else Vector2i(0, k)))
			var ok := true
			for c in cells:
				if not _piece_fits("sign", c, 0, true) or _near_lane(c):
					ok = false
			if ok:
				for c in cells:
					fence[c] = true
					blocked[c] = true
					_occupied[c] = true
				break


func _cobble_disk(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if _inside(x, y) and _in_disk(Vector2i(x, y), center, radius) and kind[_i(x, y)] == GRASS:
				kind[_i(x, y)] = COBBLE


# Up to `count` pieces from `arts` on free cells in `area` (default: the goal
# arena), off the lane and not right beside it. Returns how many were placed.
func _near_goal(arts: Array, count: int, area := Rect2i()) -> int:
	if area.size == Vector2i.ZERO:
		area = Rect2i(shrine - Vector2i(shrine_radius, shrine_radius), Vector2i(shrine_radius * 2 + 1, shrine_radius * 2 + 1))
	var placed := 0
	for i in 150:
		if placed >= count:
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c := Vector2i(_rng.randi_range(area.position.x, area.end.x - 1), _rng.randi_range(area.position.y, area.end.y - 1))
		if c == shrine or _near_lane(c) or not _piece_fits(art, c, 0, true):
			continue
		_put(art, c)
		placed += 1
	return placed


func _near_lane(c: Vector2i) -> bool:
	for d in [Vector2i.ZERO, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
		if lane.has(c + d) or c + d == shrine:
			return true
	return false


# Every cell the piece covers is free ground. `in_arena`: inside the goal
# arena; otherwise out on the lawn, clear of both arenas by `margin`.
func _piece_fits(art: String, anchor: Vector2i, margin: int, in_arena: bool) -> bool:
	var foot: Rect2i = PIECE_FOOT[art][0]
	if not in_arena and (_in_disk(anchor, spawn, SPAWN_RADIUS + margin) or _in_disk(anchor, shrine, shrine_radius + margin)):
		return false
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			var c := anchor + Vector2i(x, y)
			if not _inside(c.x, c.y) or _occupied.has(c) or lane.has(c) or blocked.has(c):
				return false
			var k := kind[_i(c.x, c.y)]
			if k != GRASS and k != COBBLE:
				return false
			if in_arena and not _in_disk(c, shrine, shrine_radius):
				return false
	return true


func _put(art: String, anchor: Vector2i) -> void:
	props.append({"art": art, "cell": anchor})
	var foot: Rect2i = PIECE_FOOT[art][0]
	var walls: bool = art in ["hut", "pillar", "arch"]
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			var c := anchor + Vector2i(x, y)
			_occupied[c] = true
			# Walls block their whole footprint; other pieces their foot row.
			if PIECE_FOOT[art][1] and (walls or y == foot.end.y - 1):
				blocked[c] = true
	if art == "pit":
		fires.append(anchor)


func _rect_is(r: Rect2i, k: int) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not _inside(x, y) or kind[_i(x, y)] != k:
				return false
	return true


func _rect_near_arena(r: Rect2i, margin: int) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if _in_disk(c, spawn, SPAWN_RADIUS + margin) or _in_disk(c, shrine, shrine_radius + margin):
				return true
	return false


func _fill_rect(r: Rect2i, k: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			kind[_i(x, y)] = k


# Abandoned house: a plank floor with a red rug, the furniture still standing
# (bed, bookshelf, table with a potion and a scroll, stools, pots), broken
# wall stubs at its corners, and a chest. Open to the sky: no roof art.
func _lay_house() -> void:
	var r := _floor_rect(Vector2i(6, 5))
	if r.size == Vector2i.ZERO:
		piece_fails.append("no floor")
		return
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			floors[Vector2i(x, y)] = ["wooden", Vector2i.ZERO]
	# carpet.png has a red set (rows 0-3) and a blue-stone set (rows 4-7), each
	# with a 3x3 rug, a round 2x2 rug, a runner, a side strip, and a mat.
	var row := 0 if _rng.randf() < 0.5 else 4
	var inner := r.grow(-1)
	if _rng.randf() < 0.6:
		_rug(inner, "carpet", Vector2i(1, row))
	else:
		var c := inner.position + Vector2i(inner.size.x / 2 - 1, inner.size.y / 2 - 1)
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			rugs[c + o] = ["carpet", Vector2i(4, row) + o]
	for k in 3: # the runner along the front of the floor
		rugs[Vector2i(r.position.x + 1 + k, r.end.y - 1)] = ["carpet", Vector2i(1 + k, row + 3)]
	for k in 3: # a strip down the back wall's side
		rugs[Vector2i(r.end.x - 1, r.position.y + k)] = ["carpet", Vector2i(0, row + k)]
	rugs[Vector2i(r.position.x, r.end.y - 1)] = ["carpet", Vector2i(0, row + 3)] # the mat at the door
	var furniture := _near_goal(["bed", "bookshelf"], 2, r) + _near_goal(["stool", "small_table", "pot_empty", "pot_sprout"], 3, r)
	var tables := 0
	for i in 40:
		var c := Vector2i(_rng.randi_range(r.position.x, r.end.x - 2), _rng.randi_range(r.position.y, r.end.y - 1))
		if not _near_lane(c) and _piece_fits("table", c, 0, true):
			_put("table", c)
			props.append({"art": "potion", "cell": c})
			props.append({"art": "scroll", "cell": c + Vector2i.RIGHT})
			tables += 1
			break
	_near_goal(["chest_iron"], 1, r)
	for corner in [r.position + Vector2i(-1, 0), Vector2i(r.end.x, r.position.y), Vector2i(r.position.x - 1, r.end.y), r.end]:
		if _piece_fits("pillar", corner, 0, true):
			_put("pillar" if _rng.randf() < 0.6 else "arch", corner)
	piece_notes.append("house: %d furniture, %d table" % [furniture, tables])
	if furniture + tables < 3:
		piece_fails.append("house has too little furniture")


# Stone chapel: a bordered red stone floor with a round medallion at its
# heart, a blue-stone rug runner, pillars down both sides, a gold chest and a
# heart on the medallion, potted trees at the door.
func _lay_chapel() -> void:
	var r := _floor_rect(Vector2i(7, 5))
	if r.size == Vector2i.ZERO:
		piece_fails.append("no floor")
		return
	_rug(r, "flooring", Vector2i(0, 0))
	var mid := r.position + Vector2i(r.size.x / 2 - 1, r.size.y / 2 - 1)
	for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		floors[mid + o] = ["flooring", Vector2i(3, 0) + o]
	# The blue rug's pieces: a short runner at the door, a single mat.
	var runner_y := r.end.y - 1
	for k in 3:
		var c := Vector2i(mid.x - 1 + k, runner_y)
		if floors.has(c):
			rugs[c] = ["carpet", Vector2i(1 + k, 7)]
	rugs[Vector2i(r.position.x + 1, r.position.y + 1)] = ["carpet", Vector2i(0, 7)]
	var pillars := 0
	for x in [r.position.x - 1, r.end.x]:
		for y in range(r.position.y + 1, r.end.y + 1, 2):
			if _piece_fits("pillar", Vector2i(x, y), 0, true):
				_put("pillar", Vector2i(x, y))
				pillars += 1
	_near_goal(["long_table"], 1, Rect2i(r.position.x + 1, r.position.y, r.size.x - 2, 1)) # the altar at the back
	_near_goal(["chest_gold"], 1, Rect2i(mid, Vector2i(2, 2)))
	props.append({"art": "heart", "cell": mid + Vector2i(1, 1)})
	_near_goal(["potted_tree"], 2, Rect2i(r.position.x, r.end.y, r.size.x, 2))
	piece_notes.append("chapel: %d pillars" % pillars)
	if pillars < 1:
		piece_fails.append("chapel has no pillars")


# A floor rectangle of `size` in the goal arena on plain grass, clear of
# everything (the lane may cross it: floors are walkable).
func _floor_rect(size: Vector2i) -> Rect2i:
	for i in 60:
		var at := shrine - size / 2 + Vector2i(_rng.randi_range(-1, 1), _rng.randi_range(-2, 0))
		var r := Rect2i(at, size)
		var ok := true
		for y in range(r.position.y - 1, r.end.y + 1):
			for x in range(r.position.x - 1, r.end.x + 1):
				if not _inside(x, y) or kind[_i(x, y)] != GRASS or _occupied.has(Vector2i(x, y)) or not _in_disk(Vector2i(x, y), shrine, shrine_radius):
					ok = false
		if ok:
			return r
	return Rect2i()


# A rug or bordered floor drawn from a 3x3 block (corners, edges, fill) at
# `origin` in `sheet`, stretched over `r`. Carpet goes on the rug layer, over
# the floor; flooring is the floor itself.
func _rug(r: Rect2i, sheet: String, origin: Vector2i) -> void:
	var into: Dictionary = rugs if sheet == "carpet" else floors
	if r.size.x < 2 or r.size.y < 2:
		return
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var role := Vector2i(0 if x == r.position.x else (2 if x == r.end.x - 1 else 1),
				0 if y == r.position.y else (2 if y == r.end.y - 1 else 1))
			into[Vector2i(x, y)] = [sheet, origin + role]


# ---------------------------------------------------------------- liveliness
# Randomizer only (`enrich`): the same idea as the Painted Lands floor. Each
# camera-sized window (43 x 18 cells at the Mystic zoom) should have something
# moving; motion is estimated with the Painted Lands weights (animated water,
# fire glow and smoke, falling leaves) and a window under FLOOR gets a small
# pond (over grass and its flowers, never over props), or a fire pit if no
# pond fits (at most two pits). At most five anchors; never cutting off the goal.
const FLOOR := 0.09
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WATER := 9.745 # per animated water cell
const FLOOR_FIRE := 240.0 # glow and smoke of one fire pit
const FLOOR_TREE := 2.084 # leaves of one tree

func _liveliness_floor() -> void:
	var pits := 0
	for n in 6:
		var weak := _weakest_window()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= FLOOR or n == 5:
			if n > 0:
				floor_notes.append("-> %.3f%%" % weak.value)
			return
		var win: Rect2i = weak.rect
		if _floor_pond(win):
			floor_notes.append("pond")
		elif pits < 2 and _floor_pit(win):
			floor_notes.append("fire pit")
			pits += 1
		else:
			floor_notes.append("-> %.3f%%" % weak.value)
			return


func _weakest_window() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(WIDTH * HEIGHT)
	m.fill(0.0)
	for y in HEIGHT:
		for x in WIDTH:
			if kind[_i(x, y)] == WATER:
				m[_i(x, y)] += FLOOR_WATER
	for c in fires:
		m[_i(c.x, c.y)] += FLOOR_FIRE
	for p in props:
		if p.art in TREES or p.art == "cypress":
			m[_i(clampi(p.cell.x, 0, WIDTH - 1), clampi(p.cell.y, 0, HEIGHT - 1))] += FLOOR_TREE
	var best := {"rect": Rect2i(), "value": INF}
	var area := float(FLOOR_VIEW.x * FLOOR_VIEW.y)
	for y in range(0, HEIGHT - FLOOR_VIEW.y + 1, 2):
		for x in range(0, WIDTH - FLOOR_VIEW.x + 1, 2):
			var s := 0.0
			for yy in range(y, y + FLOOR_VIEW.y):
				for xx in range(x, x + FLOOR_VIEW.x):
					s += m[_i(xx, yy)]
			if s / area < best.value:
				best = {"rect": Rect2i(x, y, FLOOR_VIEW.x, FLOOR_VIEW.y), "value": s / area}
	return best


# A small pond near the window's middle on clear grass; undone if the goal
# would be cut off.
func _floor_pond(win: Rect2i) -> bool:
	var inner := win.grow_individual(-8, -3, -8, -3)
	for i in 80:
		var size := Vector2i(_rng.randi_range(4, 6), _rng.randi_range(3, 4))
		var r := Rect2i(Vector2i(_rng.randi_range(inner.position.x, inner.end.x - size.x), _rng.randi_range(inner.position.y, inner.end.y - size.y)), size)
		if not _rect_is(r.grow(1), GRASS) or _rect_near_arena(r, 2) or _rect_has_props(r.grow(1)):
			continue
		_fill_rect(r, WATER)
		if not _flood_reaches_shrine():
			_fill_rect(r, GRASS)
			continue
		ponds.append(r)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				_occupied[Vector2i(x, y)] = true
				deco.erase(Vector2i(x, y))
		_dress_pond(r)
		return true
	return false


func _floor_pit(win: Rect2i) -> bool:
	var inner := win.grow_individual(-8, -3, -8, -3)
	for i in 80:
		var c := Vector2i(_rng.randi_range(inner.position.x, inner.end.x - 1), _rng.randi_range(inner.position.y, inner.end.y - 1))
		if _in_arena(c) or not _piece_fits("pit", c, 0, false) or _rect_occupied(Rect2i(c - Vector2i(2, 1), Vector2i(5, 3))):
			continue
		_put("pit", c)
		if not _flood_reaches_shrine():
			props.pop_back()
			fires.pop_back()
			blocked.erase(c)
			continue
		for o in [Vector2i(-2, 0), Vector2i(1, 0)]:
			if _piece_fits("log", c + o, 0, false):
				_put("log", c + o)
		return true
	return false


# Cells claimed by anything but grass deco (flowers and tufts may be covered).
func _rect_has_props(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if _occupied.has(c) and not deco.has(c):
				return true
	return false


func _rect_occupied(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _occupied.has(Vector2i(x, y)):
				return true
	return false


# Randomizer only: 8 px detail (stones, sprigs, flowers on grass; specks on
# the plain dirt fill) and loose dirt spots beside the path.
func _scatter_detail() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var c := Vector2i(x, y)
			var k := kind[_i(x, y)]
			if k == GRASS and not _occupied.has(c) and not deco.has(c) and not floors.has(c):
				if _rng.randf() < (0.08 if recipe.piece == "ruins" or recipe.get("cobble_fields", false) else 0.02):
					deco[c] = STONES[_rng.randi() % STONES.size()] # a stone in the grass
				elif _rng.randf() < 0.14:
					detail[c * 2 + Vector2i(_rng.randi_range(0, 1), _rng.randi_range(0, 1))] = DETAIL_GRASS[_rng.randi() % DETAIL_GRASS.size()]
				elif _rng.randf() < 0.05 and _count8(x, y, DIRT) > 0:
					deco[c] = DIRT_SPOTS[_rng.randi() % DIRT_SPOTS.size()]
			elif k == DIRT and features.get(c) in DIRT_FILLS and _rng.randf() < 0.3:
				detail[c * 2 + Vector2i(_rng.randi_range(0, 1), _rng.randi_range(0, 1))] = DETAIL_DIRT[_rng.randi() % DETAIL_DIRT.size()]


# Bare earth: the dirt kind on free grass within `radius` of `center` (off the
# lane and anything placed), so the dirt set's fill, inner corners, and the
# 8 px specks show up where people work and gather.
func _bare_earth(center: Vector2i, radius: int) -> void:
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var c := Vector2i(x, y)
			if _inside(x, y) and _in_disk(c, center, radius) and kind[_i(x, y)] == GRASS \
					and not _occupied.has(c) and not lane.has(c) and x > 0 and y > 0 and x < WIDTH - 1 and y < HEIGHT - 1:
				kind[_i(x, y)] = DIRT


# A clear rectangle of bare earth in the goal arena (grass with nothing on it,
# off the lane): its middle cells are the dirt set's plain fill.
func _dirt_bed(size: Vector2i) -> void:
	for i in 60:
		var at := shrine + Vector2i(_rng.randi_range(-shrine_radius, shrine_radius - size.x), _rng.randi_range(-shrine_radius, shrine_radius - size.y))
		var r := Rect2i(at, size)
		var ok := true
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				if not _inside(x, y) or x < 1 or y < 1 or x > WIDTH - 2 or y > HEIGHT - 2 or kind[_i(x, y)] != GRASS \
						or _occupied.has(c) or lane.has(c) or not _in_disk(c, shrine, shrine_radius):
					ok = false
		if ok:
			_fill_rect(r, DIRT)
			return
