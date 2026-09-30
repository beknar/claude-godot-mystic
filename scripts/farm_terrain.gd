class_name FarmTerrain
extends RefCounted
## Farm maps from antarcticbees' Farm - 4 Seasons sheets (spring and summer),
## built the way the Painted Lands generators build theirs: a recipe per map
## id, a layout, the sheet's own systems, set pieces, scatter, a liveliness
## floor, and a walk check. Output is a corner-terrain grid (FarmTiles.WANG),
## water cells, and placements (buildings, fields and crops, pens, trees,
## blobs, props, deco); farm.gd paints them. Tables in farm_tiles.gd.
##
## The sheet's systems (cells of 16 px):
##   ground    lawn with pale, dark, and deep grass zones, sand yards and dirt
##             roads, read into a corner table; a cell mixing terrains no
##             tile draws returns its lowest-priority terrain to its parent.
##   water     edge shores (a rock lip inside the land cell, a ripple inside
##             the water cell); ponds are built from 2 x 2 blocks so every
##             shore cell has a tile, animated in four frames.
##   plateaus  a raised top (rim blob) over a two-row rock face, stretched.
##   fields    tilled plots (bordered blocks or one-tall crop rows) with a
##             crop in every plot; wheat, tall grass, and hedges as overlay
##             blobs; fenced pens with a gate and animals inside.
##   buildings farmhouses, a manor, a barn, a greenhouse, and the windmill,
##             each with a door into its own interior (farm.gd).

const W := 64
const H := 40
const TILE := 16

# Cell kinds.
const OPEN := 0
const WATER := 1
const CLIFF := 2 # plateau (blocks)
const SOLID := 3 # building walls
const FIELD := 4 # tilled plots with crops
const FENCE := 5

# Recipes (map id % 48): 30 in spring and summer, 10 in autumn, 8 in winter;
# season: the sheet for the whole map (never mixed). buildings: kinds
# (FarmTiles.BUILDINGS); fields [min, max] and the
# crops they grow, rows (one-tall crop rows) or blocks; pens [min, max];
# orchard [tree set, trees]; wheat / tall / hedge: overlay blobs; water;
# plateaus [min, max]; trees [set, count]; zones (dark share) and pale
# (pale share); path: road (edge to edge), cross, lane (spawn to doors);
# ground of paths and yards: e dirt or s sand; piece: a set piece.
const RECIPES := [
	{"name": "Homestead", "buildings": ["farmhouse", "barn"], "fields": [2, 2], "crops": ["cabbage", "carrot", "potato", "beet"], "rows": false, "pens": [1, 1], "water": "pond", "trees": ["wild", 12], "zones": 0.24, "pale": 0.12, "path": "road", "ground": "e", "piece": "farmyard"},
	{"name": "Wheat valley", "buildings": ["windmill", "farmhouse_b"], "fields": [1, 1], "crops": ["wheat"], "rows": true, "wheat": [3, 4], "water": "stream", "trees": ["wild", 8], "zones": 0.2, "pale": 0.18, "path": "road", "ground": "e", "piece": "hay"},
	{"name": "Windmill hill", "buildings": ["windmill"], "fields": [1, 2], "crops": ["corn", "wheat"], "rows": true, "wheat": [1, 2], "plateaus": [1, 2], "trees": ["wild", 10], "zones": 0.22, "pale": 0.16, "path": "lane", "ground": "e", "piece": "hay"},
	{"name": "Apple orchard", "buildings": ["farmhouse"], "orchard": ["apple", 16], "water": "pond", "trees": ["wild", 6], "zones": 0.24, "pale": 0.1, "path": "lane", "ground": "e", "piece": "harvest"},
	{"name": "Cherry blossom lane", "buildings": ["manor"], "orchard": ["cherry", 14], "trees": ["wild", 6], "zones": 0.2, "pale": 0.12, "path": "road", "ground": "s", "piece": "garden"},
	{"name": "Pumpkin patch", "buildings": ["barn"], "fields": [3, 3], "crops": ["pumpkin", "pumpkin", "watermelon"], "rows": false, "trees": ["wild", 8], "zones": 0.18, "pale": 0.2, "path": "lane", "ground": "e", "piece": "scarecrows"},
	{"name": "Kitchen garden", "buildings": ["farmhouse"], "fields": [3, 4], "crops": ["carrot", "cabbage", "leek", "onion", "beet", "cauliflower"], "rows": true, "trees": ["wild", 10], "zones": 0.22, "pale": 0.12, "path": "lane", "ground": "s", "piece": "garden", "small_fields": true},
	{"name": "Greenhouse garden", "buildings": ["greenhouse", "farmhouse_b"], "fields": [2, 2], "crops": ["strawberry", "tomato", "pepper"], "rows": true, "orchard": ["peach", 6], "trees": ["wild", 6], "zones": 0.2, "pale": 0.12, "path": "lane", "ground": "s", "piece": "garden"},
	{"name": "Barnyard", "buildings": ["barn", "farmhouse"], "pens": [2, 2], "fields": [1, 1], "crops": ["corn"], "rows": true, "trees": ["wild", 8], "zones": 0.22, "pale": 0.14, "path": "road", "ground": "e", "piece": "farmyard"},
	{"name": "Sheep meadow", "buildings": ["farmhouse_b"], "pens": [2, 2], "water": "pond", "trees": ["wild", 12], "zones": 0.26, "pale": 0.12, "path": "lane", "ground": "e", "piece": "meadow", "big_pens": true},
	{"name": "Duck pond farm", "buildings": ["farmhouse"], "fields": [1, 2], "crops": ["cabbage", "beet"], "rows": false, "water": "lake", "trees": ["wild", 10], "zones": 0.24, "pale": 0.1, "path": "lane", "ground": "e", "piece": "shore"},
	{"name": "Riverside fields", "buildings": ["farmhouse_b"], "fields": [3, 3], "crops": ["carrot", "potato", "onion", "leek"], "rows": true, "water": "stream", "trees": ["wild", 8], "zones": 0.2, "pale": 0.14, "path": "lane", "ground": "e", "piece": "shore"},
	{"name": "Farm village", "buildings": ["farmhouse", "farmhouse_b", "manor"], "fields": [2, 2], "crops": ["cabbage", "carrot", "cauliflower"], "rows": false, "trees": ["wild", 8], "zones": 0.18, "pale": 0.12, "path": "cross", "ground": "e", "piece": "village"},
	{"name": "Market crossroads", "buildings": ["manor", "barn"], "fields": [1, 1], "crops": ["pumpkin", "watermelon"], "rows": false, "trees": ["wild", 8], "zones": 0.18, "pale": 0.12, "path": "cross", "ground": "s", "piece": "market"},
	{"name": "Sunflower field", "buildings": ["farmhouse_b"], "fields": [3, 3], "crops": ["sunflower"], "rows": true, "trees": ["wild", 8], "zones": 0.2, "pale": 0.2, "path": "lane", "ground": "e", "piece": "scarecrows"},
	{"name": "Corn rows", "buildings": ["windmill", "barn"], "fields": [3, 4], "crops": ["corn"], "rows": true, "trees": ["wild", 6], "zones": 0.18, "pale": 0.16, "path": "road", "ground": "e", "piece": "scarecrows"},
	{"name": "Berry patch", "buildings": ["farmhouse_b"], "fields": [3, 3], "crops": ["strawberry", "berry", "berry"], "rows": true, "trees": ["wild", 12], "zones": 0.26, "pale": 0.1, "path": "lane", "ground": "s", "piece": "garden", "hedge": [1, 2]},
	{"name": "Hillside terraces", "buildings": ["farmhouse"], "fields": [2, 3], "crops": ["cabbage", "potato", "leek"], "rows": true, "plateaus": [2, 3], "trees": ["wild", 8], "zones": 0.22, "pale": 0.14, "path": "lane", "ground": "e", "piece": "farmyard"},
	{"name": "Woodlot", "buildings": ["farmhouse_b"], "trees": ["wild", 30], "canopy": true, "zones": 0.34, "pale": 0.06, "path": "road", "ground": "e", "piece": "woodcutter"},
	{"name": "Pine ridge", "buildings": ["farmhouse"], "plateaus": [1, 2], "water": "pond", "trees": ["pines", 22], "zones": 0.32, "pale": 0.06, "path": "lane", "ground": "e", "piece": "woodcutter"},
	{"name": "Wildflower meadow", "buildings": [], "tall": [2, 3], "water": "pond", "trees": ["wild", 14], "zones": 0.22, "pale": 0.22, "path": "lane", "ground": "e", "piece": "meadow", "flowers": 3},
	{"name": "Old farm", "buildings": ["barn"], "fields": [1, 1], "crops": ["potato"], "rows": false, "tall": [2, 3], "trees": ["old", 14], "zones": 0.36, "pale": 0.06, "path": "lane", "ground": "e", "piece": "old", "hedge": [1, 2]},
	{"name": "Fishing lake", "buildings": ["farmhouse_b"], "water": "lake", "trees": ["wild", 14], "zones": 0.26, "pale": 0.1, "path": "lane", "ground": "s", "piece": "shore"},
	{"name": "Cattle ranch", "buildings": ["barn", "farmhouse"], "pens": [2, 3], "trees": ["wild", 8], "zones": 0.2, "pale": 0.16, "path": "road", "ground": "e", "piece": "farmyard", "big_pens": true},
	{"name": "Hayfield", "buildings": ["barn"], "wheat": [3, 4], "tall": [1, 2], "trees": ["wild", 8], "zones": 0.16, "pale": 0.22, "path": "lane", "ground": "e", "piece": "hay"},
	{"name": "Scarecrow fields", "buildings": ["windmill"], "fields": [4, 4], "crops": ["cabbage", "corn", "pumpkin", "carrot", "wheat"], "rows": true, "trees": ["wild", 6], "zones": 0.18, "pale": 0.16, "path": "road", "ground": "e", "piece": "scarecrows"},
	{"name": "Twin farms", "buildings": ["farmhouse", "farmhouse_b"], "fields": [2, 3], "crops": ["cabbage", "carrot", "corn", "tomato"], "rows": false, "pens": [1, 1], "trees": ["wild", 8], "zones": 0.2, "pale": 0.12, "path": "road", "ground": "e", "piece": "farmyard"},
	{"name": "Stone quarry", "buildings": ["farmhouse_b"], "plateaus": [2, 3], "cave": true, "trees": ["wild", 8], "zones": 0.18, "pale": 0.2, "path": "lane", "ground": "s", "piece": "quarry"},
	{"name": "Orchard and greenhouse", "buildings": ["greenhouse"], "orchard": ["mixed_fruit", 14], "fields": [1, 1], "crops": ["strawberry"], "rows": true, "trees": ["wild", 6], "zones": 0.2, "pale": 0.12, "path": "lane", "ground": "s", "piece": "garden"},
	{"name": "Harvest fair", "buildings": ["manor", "farmhouse", "windmill"], "fields": [2, 2], "crops": ["pumpkin", "corn", "sunflower"], "rows": false, "trees": ["wild", 6], "zones": 0.16, "pale": 0.14, "path": "cross", "ground": "e", "piece": "market"},
	# Autumn (farm_autumn.png): the harvest, turning trees, straw.
	{"name": "Autumn homestead", "season": "autumn", "buildings": ["farmhouse", "barn"], "fields": [2, 2], "crops": ["pumpkin", "cabbage", "potato"], "rows": false, "pens": [1, 1], "water": "pond", "trees": ["wild", 12], "zones": 0.24, "pale": 0.14, "path": "road", "ground": "e", "piece": "farmyard"},
	{"name": "Pumpkin harvest", "season": "autumn", "buildings": ["barn"], "fields": [3, 3], "crops": ["pumpkin", "pumpkin", "watermelon"], "rows": false, "trees": ["wild", 10], "zones": 0.2, "pale": 0.18, "path": "lane", "ground": "e", "piece": "scarecrows"},
	{"name": "Autumn orchard", "season": "autumn", "buildings": ["farmhouse_b"], "orchard": ["apple", 16], "water": "pond", "trees": ["wild", 6], "zones": 0.22, "pale": 0.12, "path": "lane", "ground": "e", "piece": "harvest"},
	{"name": "Golden wheat", "season": "autumn", "buildings": ["windmill", "barn"], "wheat": [3, 4], "fields": [1, 1], "crops": ["wheat"], "rows": true, "trees": ["wild", 8], "zones": 0.18, "pale": 0.22, "path": "road", "ground": "e", "piece": "hay"},
	{"name": "Turning lane", "season": "autumn", "buildings": ["manor"], "trees": ["wild", 26], "zones": 0.3, "pale": 0.14, "path": "road", "ground": "s", "piece": "garden", "flowers": 1},
	{"name": "Autumn market", "season": "autumn", "buildings": ["manor", "barn"], "fields": [1, 2], "crops": ["pumpkin", "corn"], "rows": false, "trees": ["wild", 8], "zones": 0.18, "pale": 0.14, "path": "cross", "ground": "s", "piece": "market"},
	{"name": "Misty lake", "season": "autumn", "buildings": ["farmhouse_b"], "water": "lake", "trees": ["wild", 14], "zones": 0.28, "pale": 0.1, "path": "lane", "ground": "e", "piece": "shore"},
	{"name": "Cornfield", "season": "autumn", "buildings": ["windmill"], "fields": [3, 4], "crops": ["corn"], "rows": true, "trees": ["wild", 6], "zones": 0.18, "pale": 0.18, "path": "road", "ground": "e", "piece": "scarecrows"},
	{"name": "Old barn in autumn", "season": "autumn", "buildings": ["barn"], "tall": [2, 3], "hedge": [1, 2], "trees": ["old", 14], "zones": 0.34, "pale": 0.08, "path": "lane", "ground": "e", "piece": "old"},
	{"name": "Cider farm", "season": "autumn", "buildings": ["farmhouse", "windmill"], "orchard": ["mixed_fruit", 12], "trees": ["wild", 6], "zones": 0.2, "pale": 0.14, "path": "lane", "ground": "e", "piece": "harvest"},
	# Winter (farm_winter.png): snow, bare and snowy trees, no crops.
	{"name": "Snowy homestead", "season": "winter", "buildings": ["farmhouse", "barn"], "pens": [1, 1], "water": "pond", "trees": ["wild", 12], "zones": 0.14, "pale": 0.16, "path": "road", "ground": "e", "piece": "farmyard"},
	{"name": "Winter pasture", "season": "winter", "buildings": ["farmhouse"], "pens": [2, 2], "trees": ["wild", 10], "zones": 0.13, "pale": 0.2, "path": "lane", "ground": "e", "piece": "meadow", "big_pens": true},
	{"name": "Frozen lake", "season": "winter", "buildings": ["farmhouse"], "water": "lake", "trees": ["pines", 14], "zones": 0.14, "pale": 0.16, "path": "lane", "ground": "s", "piece": "shore"},
	{"name": "Snowy woodlot", "season": "winter", "buildings": ["farmhouse"], "trees": ["wild", 28], "canopy": true, "zones": 0.20, "pale": 0.12, "path": "road", "ground": "e", "piece": "woodcutter"},
	{"name": "Pine hills", "season": "winter", "buildings": ["farmhouse"], "plateaus": [2, 3], "water": "pond", "trees": ["pines", 20], "zones": 0.18, "pale": 0.14, "path": "lane", "ground": "e", "piece": "woodcutter"},
	{"name": "Winter village", "season": "winter", "buildings": ["farmhouse", "manor", "barn"], "trees": ["wild", 8], "zones": 0.12, "pale": 0.18, "path": "cross", "ground": "e", "piece": "village"},
	{"name": "Greenhouse in the snow", "season": "winter", "buildings": ["greenhouse", "farmhouse"], "orchard": ["orchard", 10], "trees": ["wild", 6], "zones": 0.13, "pale": 0.16, "path": "lane", "ground": "s", "piece": "garden"},
	{"name": "Winter windmill", "season": "winter", "buildings": ["windmill", "barn"], "pens": [1, 2], "trees": ["wild", 8], "zones": 0.13, "pale": 0.18, "path": "road", "ground": "e", "piece": "hay"},
]

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var season := "summer" # summer (spring and summer sheet), autumn, or winter: the whole map
# The season's tables (FarmTiles.get_for).
var wang: Dictionary
var plots_tab: Dictionary
var fence_tab: Dictionary
var sprouts_set: Array = []
var sprouts_dark: Array = []
var flowers_set: Array = []
var tufts_set: Array = []
var attempt := 0
var corner := PackedStringArray() # (W + 1) * (H + 1) terrain letters
var kind := PackedByteArray()
var water := {} # cell -> true
var stream := {} # stream cells
var stones := {} # stream cells the path crosses on stepping stones
var ponds: Array[Rect2i] = []
var islands: Array[Vector2i] = [] # a cell near the middle of each lake island
var plateaus: Array[Dictionary] = [] # {rect, pieces: [{cell, atlas}]}
var buildings: Array[Dictionary] = [] # {kind, origin (cell), door (cell), door_w}
var fields: Array[Dictionary] = [] # {rect, set, crop, rows}
var plots := {} # cell -> atlas (plot tiles)
var crops: Array[Dictionary] = [] # {cell, crop, stage}
var blobs := {"wheat": {}, "tall": {}, "hedge": {}} # kind -> {corner: true}
var pens: Array[Dictionary] = [] # {rect, gate}
var fence := {} # cell -> atlas
var gates: Array[Vector2i] = []
var trees: Array[Dictionary] = [] # {art, cell}
var canopy: Array[Vector2i] = [] # top-left cells of 4 x 4 canopy blocks
var props: Array[Dictionary] = [] # {art, cell}
var deco := {} # cell -> atlas
var paths := {} # cell -> true
var blocked := {}
var goals: Array[Vector2i] = []
var spawn := Vector2i.ZERO
var notes: Array[String] = []
var fails: Array[String] = []
var floor_notes: Array[String] = []
var firefly_spots: Array[Vector2i] = []
var _taken := {}
var _locked := {} # corners that must stay lawn (water, plateau feet, buildings)
var _rng := RandomNumberGenerator.new()


func generate(id: int, pinned := -1) -> String:
	map_id = id
	recipe_id = pinned if pinned >= 0 else id % RECIPES.size()
	recipe = RECIPES[recipe_id]
	season = recipe.get("season", "summer")
	wang = FarmTiles.get_for(season, "wang")
	plots_tab = FarmTiles.get_for(season, "plots")
	fence_tab = FarmTiles.get_for(season, "fence")
	sprouts_set = FarmTiles.get_for(season, "sprouts")
	sprouts_dark = FarmTiles.get_for(season, "sprouts_dark")
	flowers_set = FarmTiles.get_for(season, "flowers")
	tufts_set = FarmTiles.get_for(season, "tufts")
	if flowers_set.is_empty():
		flowers_set = sprouts_set # winter: frosty tufts where flowers would be
	for a in 30:
		attempt = a
		if _layout() and _reaches_all():
			break
	return _report()


func _layout() -> bool:
	_rng.seed = map_id * 7919 + attempt * 104729
	corner = PackedStringArray()
	corner.resize((W + 1) * (H + 1))
	corner.fill("g")
	kind = PackedByteArray()
	kind.resize(W * H)
	kind.fill(OPEN)
	for d in [water, stream, stones, paths, blocked, _taken, _locked, plots, fence, deco]:
		d.clear()
	for k in blobs:
		blobs[k].clear()
	for a in [ponds, islands, plateaus, buildings, fields, crops, pens, gates, trees, canopy, props, goals, firefly_spots]:
		a.clear()
	notes.clear()
	fails.clear()
	floor_notes.clear()
	_prop_cells.clear()
	spawn = Vector2i(W / 2 + _rng.randi_range(-10, 10), H - 3)
	_claim(Rect2i(spawn - Vector2i(2, 2), Vector2i(5, 3)))
	if recipe.get("canopy", false):
		_canopy()
	for i in _rng.randi_range(recipe.get("plateaus", [0, 0])[0], recipe.get("plateaus", [0, 0])[1]):
		_plateau()
	match recipe.get("water", "none"):
		"pond":
			_pond(Vector2i(_rng.randi_range(3, 5), _rng.randi_range(2, 3)))
		"lake":
			_pond(Vector2i(_rng.randi_range(8, 10), _rng.randi_range(5, 6)), true)
		"stream":
			_stream()
	for b in recipe.buildings:
		if not _building(b):
			return false
	_lay_paths()
	var pr: Array = recipe.get("pens", [0, 0])
	for i in _rng.randi_range(pr[0], pr[1]):
		_pen()
	var fr: Array = recipe.get("fields", [0, 0])
	for i in _rng.randi_range(fr[0], fr[1]):
		_field(i)
	if recipe.has("orchard"):
		_orchard()
	for k in ["wheat", "tall", "hedge"]:
		var r: Array = recipe.get(k, [0, 0])
		for i in _rng.randi_range(r[0], r[1]):
			_blob(k)
	_zones()
	_repair()
	_piece()
	_scatter_trees()
	_scatter_small()
	_deco()
	_liveliness_floor()
	return true


# ---------------------------------------------------------------- grids

func _i(c: Vector2i) -> int:
	return c.y * W + c.x


func _ci(x: int, y: int) -> int:
	return y * (W + 1) + x


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func corner_at(x: int, y: int) -> String:
	return corner[_ci(clampi(x, 0, W), clampi(y, 0, H))]


func _set_corner(x: int, y: int, t: String) -> void:
	if x >= 0 and y >= 0 and x <= W and y <= H and not _locked.has(Vector2i(x, y)):
		corner[_ci(x, y)] = t


## The terrain letters at a cell's TL, TR, BL, BR corners.
func sig(c: Vector2i) -> String:
	return corner_at(c.x, c.y) + corner_at(c.x + 1, c.y) + corner_at(c.x, c.y + 1) + corner_at(c.x + 1, c.y + 1)


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != OPEN or paths.has(c):
				return false
	return true


## Lawn round a set of cells, following their shape (every corner within one
## corner of them), locked so no zone, yard, or road edge meets them.
func _lock_round(cells: Array[Vector2i], reach := 1.0) -> void:
	for c in cells:
		for dy in range(-2, 4):
			for dx in range(-2, 4):
				var v := Vector2i(c.x + dx, c.y + dy)
				if v.x < 0 or v.y < 0 or v.x > W or v.y > H:
					continue
				var d := Vector2(maxf(0.0, maxf(c.x - v.x, v.x - c.x - 1)), maxf(0.0, maxf(c.y - v.y, v.y - c.y - 1)))
				if d.length() <= reach:
					corner[_ci(v.x, v.y)] = "g"
					_locked[v] = true


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- canopy

## Woodlot: the sheet's seamless 4 x 4 crown block along the top edge, a wall
## the walker cannot pass; trees stand in front of it (see _scatter_trees).
func _canopy() -> void:
	for bx in range(0, W, 4):
		canopy.append(Vector2i(bx, 0))
		for y in 3:
			for x in range(bx, mini(bx + 4, W)):
				kind[_i(Vector2i(x, y))] = CLIFF
	_claim(Rect2i(0, 0, W, 5))
	notes.append("canopy wall")


# ---------------------------------------------------------------- plateaus

## A plateau: a rim-blob top of one tone (widened by repeating its middle
## column, deepened by repeating its middle row) over a two-row rock face.
## Impassable relief standing on plain lawn; on the quarry a cave mouth
## opens in the face.
func _plateau() -> void:
	var tops: Dictionary = FarmTiles.get_for(season, "plateau_tops")
	var tones := ["g", "g", "a", "d"].filter(func(k): return tops.has(k))
	var tone: String = tones[_rng.randi() % tones.size()]
	var top: Vector2i = FarmTiles.get_for(season, "plateau_tops")[tone]
	for t in 60:
		var w := _rng.randi_range(4, 9)
		var th := _rng.randi_range(3, 5) # top rows
		var size := Vector2i(w, th + 2)
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(5 if canopy.size() > 0 else 2, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(r.grow(2)) or r.grow(3).has_point(spawn):
			continue
		var pieces: Array[Dictionary] = []
		for j in size.y:
			for i in w:
				var col := 0 if i == 0 else (2 if i == w - 1 else 1)
				var a := Vector2i.ZERO
				if j < th:
					var row := 0 if j == 0 else (2 if j == th - 1 else 1)
					a = top + Vector2i(col, row)
				elif j == th:
					a = FarmTiles.get_for(season, "plateau_face") + Vector2i(col, 0)
				else:
					a = FarmTiles.get_for(season, "plateau_foot") + Vector2i(col, 0)
				pieces.append({"cell": at + Vector2i(i, j), "atlas": a, "foot": j == size.y - 1})
		if recipe.get("cave", false) and w >= 5 and plateaus.is_empty():
			var cx := _rng.randi_range(1, w - 4)
			for p in pieces:
				var rel: Vector2i = p.cell - at
				if rel.x >= cx and rel.x < cx + 3 and rel.y >= th:
					p.atlas = FarmTiles.get_for(season, "plateau_cave") + Vector2i(rel.x - cx, rel.y - th)
			notes.append("cave")
		# Everything but the foot row blocks.
		for j in size.y - 1:
			for i in w:
				kind[_i(at + Vector2i(i, j))] = CLIFF
		_claim(r.grow(1))
		# Keep the face in view: nothing tall stands just in front of it.
		_claim(Rect2i(r.position.x - 2, r.end.y, r.size.x + 4, 6))
		var foot: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				foot.append(Vector2i(x, y))
		_lock_round(foot)
		plateaus.append({"rect": r, "pieces": pieces, "tone": tone})
		return


# ---------------------------------------------------------------- water

## A pond or lake as the sheet draws them: a rectangle of 2 x 2 blocks (its
## rim tiles round the corners), often with a second, overlapping lobe (an
## L or a T), and on a lake a grass island; blocks keep every shore cell one
## the sheet has a tile for (no one-cell channel or spit).
func _pond(bsize: Vector2i, lake := false) -> void:
	for t in 80:
		var at := Vector2i(_rng.randi_range(1, W / 2 - bsize.x - 3), _rng.randi_range(2 if canopy.is_empty() else 3, H / 2 - bsize.y - 4))
		var blocks := {}
		for by in range(at.y, at.y + bsize.y):
			for bx in range(at.x, at.x + bsize.x):
				blocks[Vector2i(bx, by)] = true
		if _rng.randf() < 0.9:
			# A lobe: part of one side, pushed out by one or two blocks.
			var lw := maxi(2, int(bsize.x * _rng.randf_range(0.4, 0.7)))
			var lh := maxi(2, int(bsize.y * _rng.randf_range(0.4, 0.8)))
			var side := _rng.randi() % 4
			var push := _rng.randi_range(1, 2)
			var lo := Vector2i.ZERO
			match side:
				0: lo = Vector2i(at.x + _rng.randi_range(0, bsize.x - lw), at.y - push)
				1: lo = Vector2i(at.x + _rng.randi_range(0, bsize.x - lw), at.y + bsize.y - lh + push)
				2: lo = Vector2i(at.x - push, at.y + _rng.randi_range(0, bsize.y - lh))
				3: lo = Vector2i(at.x + bsize.x - lw + push, at.y + _rng.randi_range(0, bsize.y - lh))
			for by in range(lo.y, lo.y + lh):
				for bx in range(lo.x, lo.x + lw):
					if bx >= 1 and by >= 1 and bx < W / 2 - 1 and by < H / 2 - 2:
						blocks[Vector2i(bx, by)] = true
		var island: Array[Vector2i] = []
		if lake and bsize.x >= 6 and bsize.y >= 5:
			var ib := at + Vector2i(_rng.randi_range(2, bsize.x - 4), _rng.randi_range(2, bsize.y - 4))
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				blocks.erase(ib + o)
				island.append(ib + o)
		_clean_blocks(blocks)
		var cells := _block_cells(blocks)
		var box := Rect2i(cells[0], Vector2i.ONE)
		for c in cells:
			box = box.expand(c).expand(c + Vector2i.ONE)
		if not _free(box.grow(2)):
			continue
		for c in cells:
			water[c] = true
			kind[_i(c)] = WATER
		_claim(box.grow(1))
		_lock_round(cells, 1.0)
		ponds.append(box)
		if not island.is_empty():
			notes.append("island")
			var ic := island[0] * 2 + Vector2i(1, 1)
			islands.append(ic)
		return


## A brook from the north edge to the south, two cells wide (one block),
## widening to two blocks where it shifts sideways so no corner-only join.
func _stream() -> void:
	for t in 30:
		var bx := _rng.randi_range(6, W / 2 - 7)
		var blocks := {}
		var ok := true
		var run := _rng.randi_range(3, 6) # blocks before the next jog
		var lean := 1 if _rng.randf() < 0.5 else -1
		for by in range(0 if canopy.is_empty() else 2, H / 2):
			blocks[Vector2i(bx, by)] = true
			run -= 1
			if run <= 0 and by < H / 2 - 1:
				# A jog of one block, mostly the same way (a lazy bend).
				if _rng.randf() < 0.25:
					lean = -lean
				var nx := clampi(bx + lean, 4, W / 2 - 5)
				blocks[Vector2i(nx, by)] = true
				bx = nx
				run = _rng.randi_range(3, 6)
		_clean_blocks(blocks)
		var cells := _block_cells(blocks)
		for c in cells:
			if _taken.has(c) or kind[_i(c)] != OPEN or (absi(c.x - spawn.x) < 4 and c.y > H - 6):
				ok = false
				break
		if not ok:
			continue
		for c in cells:
			water[c] = true
			stream[c] = true
			kind[_i(c)] = WATER
			_claim(Rect2i(c - Vector2i(1, 0), Vector2i(3, 1)))
		_lock_round(cells, 1.0)
		notes.append("stream")
		return


## Blocks that meet only at a corner get a third block (an L), and one-block
## holes are filled, so every shore cell is one the sheet draws.
func _clean_blocks(blocks: Dictionary) -> void:
	for it in 4:
		var changed := false
		var keys := blocks.keys()
		for b: Vector2i in keys:
			for d in [Vector2i(1, 1), Vector2i(-1, 1)]:
				var o: Vector2i = b + d
				if blocks.has(o) and not blocks.has(Vector2i(o.x, b.y)) and not blocks.has(Vector2i(b.x, o.y)):
					blocks[Vector2i(o.x, b.y)] = true
					changed = true
		# Fill land blocks with water on three or four sides.
		var cand := {}
		for b: Vector2i in blocks:
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				cand[b + d] = true
		for b: Vector2i in cand:
			if blocks.has(b):
				continue
			var n := 0
			for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if blocks.has(b + d):
					n += 1
			if n >= 3:
				blocks[b] = true
				changed = true
		if not changed:
			return


func _block_cells(blocks: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for b: Vector2i in blocks:
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var c: Vector2i = b * 2 + o
			if _inside(c):
				out.append(c)
	return out


# ---------------------------------------------------------------- buildings

## A building on free lawn, facing south, with room in front of its door for
## the yard; its walls block, its roof rows are walkable (behind the house).
func _building(k: String) -> bool:
	var art: Dictionary = FarmTiles.BUILDINGS[k]
	var size := Vector2i(ceili(art.region.size.x / 16.0), ceili(art.region.size.y / 16.0))
	for t in 120:
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(3 if canopy.is_empty() else 5, H - size.y - 7))
		var r := Rect2i(at, size)
		# The house, a ring round it, and three rows in front of the door.
		if not _free(r.grow(1)) or not _free(Rect2i(at.x + art.door.x - 2, at.y + size.y, art.door_w + 4, 3)):
			continue
		var near := false
		for b in buildings:
			if Vector2(b.origin - at).length() < 12.0:
				near = true
		if near:
			continue
		var door: Vector2i = at + art.door
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				if _blocks_cell(art, c - at):
					kind[_i(c)] = SOLID
		for i in art.door_w:
			kind[_i(door + Vector2i(i, 0))] = OPEN
		_claim(r.grow(1))
		_claim(Rect2i(door.x - 2, door.y + 1, art.door_w + 4, 3))
		buildings.append({"kind": k, "origin": at, "door": door, "door_w": art.door_w})
		goals.append(door + Vector2i(0, 1))
		return true
	notes.append("no room for %s" % k)
	return false


## Whether a building's colliders cover most of a cell (relative cell).
func _blocks_cell(art: Dictionary, rel: Vector2i) -> bool:
	var cell := Rect2i(rel * TILE, Vector2i(TILE, TILE))
	for b: Rect2i in art.blocks:
		var i := cell.intersection(b)
		if i.size.x * i.size.y >= 96:
			return true
	return false


# ---------------------------------------------------------------- paths

## Roads of dirt or sand: edge to edge (road), two crossing (cross), or only
## lanes; a lane from the spawn and from every door joins them. Each door has
## a yard of the same ground in front of it.
func _lay_paths() -> void:
	var t: String = recipe.ground
	var hub := Vector2i(W / 2, H / 2)
	for tries in 200:
		var h := Vector2i(W / 2 + _rng.randi_range(-12, 12), H / 2 + _rng.randi_range(-8, 4))
		if kind[_i(h)] == OPEN and not _taken.has(h):
			hub = h
			break
	goals.append(hub)
	var road_y := -1
	match recipe.path:
		"road":
			road_y = _rng.randi_range(H / 2 - 5, H / 2 + 3)
			_route(Vector2i(0, road_y), Vector2i(W - 1, road_y), t)
		"cross":
			road_y = hub.y
			_route(Vector2i(0, hub.y), Vector2i(W - 1, hub.y), t)
			_route(Vector2i(hub.x, 0 if canopy.is_empty() else 4), hub, t)
	_route(spawn, hub, t)
	for b in buildings:
		var front: Vector2i = b.door + Vector2i(0, 1)
		_route(front, hub if road_y < 0 else _nearest_path(front), t)
		_yard(b, t)


func _nearest_path(from: Vector2i) -> Vector2i:
	var best := Vector2i(W / 2, H / 2)
	var bd := INF
	for c: Vector2i in paths:
		var d := Vector2(c - from).length()
		if d < bd and d > 2.0:
			bd = d
			best = c
	return best


var _wander := FastNoiseLite.new()

## A lane that winds: a long route passes through a waypoint pushed off the
## straight line by a fifth of its length (either side).
func _route(a: Vector2i, b: Vector2i, t: String) -> void:
	var span := Vector2(b - a)
	if span.length() > 12.0:
		var side := span.orthogonal().normalized() * span.length() * _rng.randf_range(0.12, 0.22) * (1.0 if _rng.randf() < 0.5 else -1.0)
		var mid := (Vector2(a) + span * _rng.randf_range(0.35, 0.65) + side).round()
		var m := Vector2i(mid).clamp(Vector2i(1, 1), Vector2i(W - 2, H - 2))
		if kind[_i(m)] == OPEN and not _taken.has(m):
			_route_leg(a, m, t)
			_route_leg(m, b, t)
			return
	_route_leg(a, b, t)


## A* over cells (water, cliffs, walls, fences solid; streams crossed on
## stepping stones); a noise cost so it winds. The route's corners take the
## path terrain, two wide, swelling here and there.
func _route_leg(a: Vector2i, b: Vector2i, t: String) -> void:
	_wander.seed = map_id * 7 + attempt
	_wander.frequency = 0.12
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, W, H)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var k := kind[_i(c)]
			if k == CLIFF or k == SOLID or k == FIELD or k == FENCE:
				astar.set_point_solid(c, true)
			elif k == WATER:
				astar.set_point_weight_scale(c, 25.0 if stream.has(c) else 400.0)
			elif paths.has(c):
				astar.set_point_weight_scale(c, 0.5)
			elif _near_water(c) or _touches_lock(c):
				astar.set_point_weight_scale(c, 12.0)
			elif _taken.has(c):
				astar.set_point_weight_scale(c, 3.0)
			else:
				astar.set_point_weight_scale(c, 1.0 + (_wander.get_noise_2d(x, y) + 1.0) * 3.5)
	a = a.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	b = b.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	for c in [a, b]:
		astar.set_point_solid(c, false)
	for c in astar.get_id_path(a, b):
		if kind[_i(c)] == WATER:
			if stream.has(c):
				stones[c] = true
			continue
		paths[c] = true
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_set_corner(c.x + o.x, c.y + o.y, t)
		if _wander.get_noise_2d(c.x * 3.0, c.y * 3.0) > 0.3:
			_set_corner(c.x + 2, c.y + 1, t)


## A cell with a corner locked to the lawn (round water, plateaus, fields):
## a path there would lose its ground.
func _touches_lock(c: Vector2i) -> bool:
	for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if _locked.has(c + o):
			return true
	return false


func _near_water(c: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if water.has(c + Vector2i(dx, dy)):
				return true
	return false


## A rounded yard of path ground in front of a door.
func _yard(b: Dictionary, t: String) -> void:
	var c0 := Vector2(b.door) + Vector2(b.door_w * 0.5, 2.2)
	var rx: float = 2.6 + b.door_w * 0.5
	for y in range(b.door.y, b.door.y + 5):
		for x in range(b.door.x - 4, b.door.x + b.door_w + 5):
			var d := Vector2((x - c0.x) / rx, (y - c0.y) / 2.2)
			if d.length() + (_hash(x, y) - 0.5) * 0.3 < 1.0:
				_set_corner(x, y, t)
	for i in b.door_w:
		paths[b.door + Vector2i(i, 1)] = true


# ---------------------------------------------------------------- fields

## A tilled field near a home (or anywhere): a bordered block of plots, or
## one-tall crop rows with a lane of grass between them. One crop per field,
## most of it ripe.
func _field(index: int) -> void:
	var crop_list: Array = recipe.get("crops", ["cabbage"])
	var crop: String = crop_list[index % crop_list.size()]
	var rows: bool = recipe.get("rows", false)
	var small: bool = recipe.get("small_fields", false)
	var sets := ["dry", "wet", "ragged"]
	var set_: String = sets[_rng.randi() % sets.size()]
	for t in 120:
		var w := _rng.randi_range(3, 5) if small else _rng.randi_range(5, 9)
		var h := (_rng.randi_range(2, 3) * 2 - 1) if rows else (_rng.randi_range(2, 3) if small else _rng.randi_range(3, 5))
		var at := Vector2i(_rng.randi_range(2, W - w - 2), _rng.randi_range(3 if canopy.is_empty() else 5, H - h - 5))
		if not buildings.is_empty() and t < 80:
			var b: Dictionary = buildings[_rng.randi() % buildings.size()]
			at = b.door + Vector2i(_rng.randi_range(-16, 12), _rng.randi_range(-8, 8))
		var r := Rect2i(at, Vector2i(w, h))
		if r.position.x < 1 or r.position.y < 1 or r.end.x > W - 1 or r.end.y > H - 2:
			continue
		if not _free(r.grow(1)):
			continue
		var cells: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			if rows and (y - r.position.y) % 2 == 1:
				continue # the lane between two crop rows
			for x in range(r.position.x, r.end.x):
				cells.append(Vector2i(x, y))
		for c in cells:
			plots[c] = _plot_tile(set_, c, r, rows)
			kind[_i(c)] = FIELD
			var stage: int = FarmTiles.CROPS[crop].size() - 1
			if _hash(c.x * 3, c.y * 5) < 0.18:
				stage -= 1
			if _hash(c.x * 7, c.y * 11) < 0.05:
				continue # a gap: harvested, or not come up yet
			crops.append({"cell": c, "crop": crop, "stage": stage})
		_claim(r.grow(1))
		var ring: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				ring.append(Vector2i(x, y))
		_lock_round(ring, 0.5)
		fields.append({"rect": r, "set": set_, "crop": crop, "rows": rows})
		goals.append(Vector2i(r.position.x + w / 2, r.end.y))
		return


## The plot tile for a cell of a field: blocks use the 3 x 3 (and the one-wide
## column or row when the field is that thin); crop rows use the one-tall row.
func _plot_tile(set_: String, c: Vector2i, r: Rect2i, rows: bool) -> Vector2i:
	var p: Dictionary = plots_tab[set_]
	var at: Vector2i = p.at
	var w := r.size.x
	var x := 0 if c.x == r.position.x else (2 if c.x == r.end.x - 1 else 1)
	if rows or r.size.y == 1:
		if w == 1:
			return Vector2i(p.col, p.row)
		return Vector2i(at.x + x, p.row)
	var y := 0 if c.y == r.position.y else (2 if c.y == r.end.y - 1 else 1)
	if w == 1:
		return Vector2i(p.col, at.y + y)
	return at + Vector2i(x, y)


# ---------------------------------------------------------------- pens

## A fenced pen with a gate on the side nearest the road; the animals live
## inside (wildlife.gd pasture). The gate is walkable, the rails block.
func _pen() -> void:
	var big: bool = recipe.get("big_pens", false)
	for t in 120:
		var w := _rng.randi_range(9, 13) if big else _rng.randi_range(7, 10)
		var h := _rng.randi_range(6, 8) if big else _rng.randi_range(5, 7)
		var at := Vector2i(_rng.randi_range(2, W - w - 2), _rng.randi_range(3 if canopy.is_empty() else 5, H - h - 4))
		if not buildings.is_empty() and t < 70:
			var b: Dictionary = buildings[_rng.randi() % buildings.size()]
			at = b.door + Vector2i(_rng.randi_range(-18, 10), _rng.randi_range(-10, 6))
		var r := Rect2i(at, Vector2i(w, h))
		if r.position.x < 1 or r.position.y < 1 or r.end.x > W - 1 or r.end.y > H - 2 or not _free(r.grow(1)):
			continue
		var gate := Vector2i(r.position.x + _rng.randi_range(2, w - 3), r.end.y - 1)
		var style := "grassy" if _rng.randf() < 0.5 else "plain"
		var base: Vector2i = fence_tab[style]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				var edge_x := 0 if x == r.position.x else (2 if x == r.end.x - 1 else 1)
				var edge_y := 0 if y == r.position.y else (2 if y == r.end.y - 1 else 1)
				if edge_x == 1 and edge_y == 1:
					continue
				if c == gate:
					continue
				fence[c] = base + Vector2i(edge_x, edge_y)
				kind[_i(c)] = FENCE
		gates.append(gate)
		_claim(r.grow(1))
		pens.append({"rect": r, "gate": gate})
		goals.append(gate + Vector2i(0, 1))
		# A trough and hay inside some pens.
		if _rng.randf() < 0.7:
			_place("trough_water" if _rng.randf() < 0.5 else "trough", r.position + Vector2i(_rng.randi_range(2, w - 3), 1), true)
		return


func pen_cells() -> Dictionary:
	var out := {}
	for p in pens:
		var r: Rect2i = p.rect
		for y in range(r.position.y + 1, r.end.y - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				var c := Vector2i(x, y)
				if kind[_i(c)] == OPEN and not blocked.has(c):
					out[c] = true
	return out


# ---------------------------------------------------------------- orchard

## Fruit trees in rows (the orchard's grid, a little jitter), with grass
## between them.
func _orchard() -> void:
	var set_: Array = _tree_set(recipe.orchard[0])
	var want: int = recipe.orchard[1]
	var cols := clampi(int(sqrt(want * 1.6)), 3, 6)
	var rows := ceili(float(want) / cols)
	var step := Vector2i(5, 4)
	for t in 60:
		var at := Vector2i(_rng.randi_range(3, W - cols * step.x - 2), _rng.randi_range(4 if canopy.is_empty() else 7, H - rows * step.y - 4))
		var r := Rect2i(at - Vector2i(1, 2), Vector2i(cols * step.x, rows * step.y + 1))
		if not _free(r):
			continue
		var put := 0
		for j in rows:
			for i in cols:
				var c := at + Vector2i(i * step.x + _rng.randi_range(0, 1), j * step.y + _rng.randi_range(0, 1))
				if _place_tree(set_[(i + j) % set_.size()], c):
					put += 1
		notes.append("orchard %d" % put)
		_claim(r)
		return


# ---------------------------------------------------------------- blobs

## Wheat, tall grass, or a hedge: an organic blob of corners (the overlay
## sets have every corner mix). Wheat and tall grass are walked through; a
## hedge blocks where it covers a cell.
func _blob(k: String) -> void:
	if not FarmTiles.get_for(season, "blobs").has(k):
		return
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 17 + blobs[k].size() + attempt * 3
	noise.frequency = 0.3
	for t in 60:
		var size := Vector2i(_rng.randi_range(7, 13), _rng.randi_range(5, 8)) if k != "hedge" else Vector2i(_rng.randi_range(6, 10), _rng.randi_range(3, 4))
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(3 if canopy.is_empty() else 6, H - size.y - 5))
		var r := Rect2i(at, size)
		if not _free(r.grow(1)):
			continue
		var c0 := Vector2(r.get_center())
		var got := {}
		# A lumpy outline: the radius at each bearing swells and dents with a
		# noise round the rim, so no side runs straight.
		var phase := _rng.randf() * 100.0
		for y in range(r.position.y + 1, r.end.y):
			for x in range(r.position.x + 1, r.end.x):
				var d := Vector2((x - c0.x) / (size.x * 0.5), (y - c0.y) / (size.y * 0.5))
				var ang := d.angle()
				var rim := 0.86 + 0.22 * noise.get_noise_2d(cos(ang) * 3.0 + phase, sin(ang) * 3.0) + 0.1 * noise.get_noise_2d(x * 2.0, y * 2.0)
				if d.length() < rim:
					got[Vector2i(x, y)] = true
		if got.size() < 6:
			continue
		for v in got:
			blobs[k][v] = true
		_claim(r)
		if k == "hedge":
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var c := Vector2i(x, y)
					if blob_sig(k, c) == "1111":
						blocked[c] = true
		return


## A tree set of the season (winter has its own sets; kinds it lacks
## become the season's own, FarmTiles.tree_art).
func _tree_set(name: String) -> Array:
	var sets: Dictionary = FarmTiles.get_for(season, "tree_sets")
	var arts: Array = sets.get(name, FarmTiles.TREE_SETS.get(name, ["oak"]))
	return arts.map(func(a): return FarmTiles.tree_art(season, a))


## The overlay corners of a blob kind at a cell (TL TR BL BR, 1 = blob).
func blob_sig(k: String, c: Vector2i) -> String:
	var b: Dictionary = blobs[k]
	var s := ""
	for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		s += "1" if b.has(c + o) else "0"
	return s


# ---------------------------------------------------------------- zones

## Pale, dark, and deep grass zones, drawn per pixel by farm.gd from each
## tone's own fill (as the Painted Lands forest draws its tone zones, so no
## zone edge follows the tile grid): one smooth field per corner (sampled
## rotated so its lattice is off the grid), faded to the lawn value near
## roads, yards, water, plateaus, buildings, fields, and fences, so zones
## bend away from them and never meet their baked lawn. Low values are pale,
## high values dark, the highest deep; each level a quantile of the open
## ground, so dark always rings deep and pale never touches dark.
var tone_field := PackedFloat32Array() # per corner, 0 = lawn
var tone_cuts := {"a": -1.0, "d": 1.0, "x": 1.0}

func _zones() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 13 + attempt
	noise.frequency = 0.05
	noise.fractal_octaves = 3
	var n := (W + 1) * (H + 1)
	var vals := PackedFloat32Array()
	vals.resize(n)
	var ang := 0.6
	for y in H + 1:
		for x in W + 1:
			var rx: float = x * cos(ang) - y * sin(ang)
			var ry: float = x * sin(ang) + y * cos(ang)
			vals[_ci(x, y)] = noise.get_noise_2d(rx, ry)
	# Distance (in corners, up to 5) from anything the zones keep clear of.
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(6.0)
	var sources: Array[Vector2i] = []
	for y in H + 1:
		for x in W + 1:
			var i := _ci(x, y)
			if corner[i] != "g" or _locked.has(Vector2i(x, y)) or _blocked_corner(x, y):
				sources.append(Vector2i(x, y))
	for c in sources:
		for dy in range(-5, 6):
			for dx in range(-5, 6):
				var q := Vector2i(c.x + dx, c.y + dy)
				if q.x < 0 or q.y < 0 or q.x > W or q.y > H:
					continue
				var d := Vector2(dx, dy).length()
				if d < dist[_ci(q.x, q.y)]:
					dist[_ci(q.x, q.y)] = d
	tone_field = PackedFloat32Array()
	tone_field.resize(n)
	var open: Array[float] = []
	# The keep-out distance wobbles (a second noise), so a zone's edge near a
	# straight road or field does not run parallel to it.
	var wob := FastNoiseLite.new()
	wob.seed = map_id * 29 + attempt
	wob.frequency = 0.18
	for y in H + 1:
		for x in W + 1:
			var i := _ci(x, y)
			var fade := clampf((dist[i] - 1.5 + wob.get_noise_2d(x, y) * 2.2) / 3.0, 0.0, 1.0)
			tone_field[i] = vals[i] * fade
			if dist[i] >= 5.0:
				open.append(vals[i])
	if open.size() < 20:
		return
	open.sort()
	var m := open.size()
	var dark: float = recipe.zones
	tone_cuts = {
		"a": open[clampi(int(recipe.pale * m), 0, m - 1)],
		"d": open[clampi(int((1.0 - dark) * m), 0, m - 1)],
		"x": open[clampi(int((1.0 - dark * 0.35) * m), 0, m - 1)],
	}
	# Keep the levels apart: pale well below the lawn, deep well above dark.
	tone_cuts.a = minf(tone_cuts.a, -0.08)
	tone_cuts.d = maxf(tone_cuts.d, 0.08)
	tone_cuts.x = maxf(tone_cuts.x, tone_cuts.d + 0.12)
	if not wang.has("xxxx"):
		tone_cuts.x = INF # autumn draws no deep grass
	elif season == "winter":
		tone_cuts.x = maxf(tone_cuts.x, open[clampi(int((1.0 - dark * 0.15) * m), 0, m - 1)]) # little of the deepest blue


## A corner next to a cell that is not open ground (water, cliff, walls,
## plots, fence).
func _blocked_corner(x: int, y: int) -> bool:
	for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var c := Vector2i(x + o.x, y + o.y)
		if _inside(c) and kind[_i(c)] != OPEN:
			return true
	return false


## The tone of a cell from the field at its middle: -1 pale, 0 lawn, 1 dark,
## 2 deep.
func tone_level(c: Vector2i) -> int:
	if tone_field.is_empty():
		return 0
	var v := (tone_field[_ci(c.x, c.y)] + tone_field[_ci(c.x + 1, c.y)] + tone_field[_ci(c.x, c.y + 1)] + tone_field[_ci(c.x + 1, c.y + 1)]) * 0.25
	if v >= tone_cuts.x:
		return 2
	if v >= tone_cuts.d:
		return 1
	if v <= tone_cuts.a:
		return -1
	return 0


## Cells mixing terrains no tile draws: the lowest-priority terrain in the cell
## returns to its parent, until every cell has a tile.
func _repair() -> void:
	var tab: Dictionary = wang
	var par: Dictionary = FarmTiles.PARENT
	for it in 40:
		var bad := 0
		for y in H:
			for x in W:
				var s := sig(Vector2i(x, y))
				if tab.has(s):
					continue
				bad += 1
				var low := ""
				for ch in s:
					if ch != "g" and (low == "" or par[ch][1] < par[low][1]):
						low = ch
				if low == "":
					continue
				for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					if corner_at(x + o.x, y + o.y) == low:
						corner[_ci(x + o.x, y + o.y)] = par[low][0]
		if bad == 0:
			return
	notes.append("repair left cells")


# ---------------------------------------------------------------- set pieces

func _piece() -> void:
	var hub: Vector2i = goals[0] if not goals.is_empty() else Vector2i(W / 2, H / 2)
	var home: Vector2i = buildings[0].door + Vector2i(0, 2) if not buildings.is_empty() else hub
	match recipe.piece:
		"farmyard":
			_near(["crate", "crate_stack", "barrel", "barrel_b", "hay_crate", "bucket", "box"], 4, home, 4)
			_near(["hay", "hay_big"], 2, home, 6)
		"hay":
			_near(["hay", "hay_big", "hay", "wheat_bunch", "wheat_bunch_b", "wheat_bunch_c"], 7, hub, 10)
		"harvest":
			_near(["crate_open", "crate", "barrel", "box", "box_b", "planter"], 5, home, 4)
		"garden":
			_near(["pot_plant", "pot_plant_b", "planter", "bucket"], 4, home, 3)
		"scarecrows":
			for f in fields:
				var r: Rect2i = f.rect
				_place("scarecrow", Vector2i(r.position.x + r.size.x / 2, r.position.y - 1), true)
			_near(["crate_open", "hay_crate", "wheat_bunch"], 2, home, 5)
		"meadow":
			_near(["hay", "wheat_bunch_b", "bush", "bush_b"], 4, hub, 10)
		"shore":
			for p in ponds:
				_near(["reeds", "reeds_b", "reeds_s", "cattail", "cattail_b"], 8, p.get_center(), maxi(p.size.x, p.size.y) / 2 + 2)
		"village":
			for b in buildings:
				_near(["crate", "barrel", "pot_plant", "mailbox"], 2, b.door + Vector2i(0, 2), 3)
			_place("sign_arrow", hub + Vector2i(2, -2), true)
		"market":
			_near(["crate_open", "crate_open", "crate", "crate_stack", "barrel", "barrel_b", "box", "box_b", "hay_crate", "planter"], 12, hub, 6)
			_place("sign", hub + Vector2i(-2, -2), true)
		"woodcutter":
			_near(["log", "log_moss", "stump", "stump_b", "log_s"], 7, home, 7)
		"old":
			_near(["dead_tree", "dead_tree_s", "log_moss", "stump_b", "crates_tuft"], 6, hub, 10)
		"quarry":
			_near(["rock_big", "rock", "rock_b", "rock_big", "pebble", "pebble_b"], 12, hub, 12)
	for b in buildings:
		if b.kind.begins_with("farmhouse") and _rng.randf() < 0.7:
			_place("mailbox", b.door + Vector2i(-2, 2), true)
	if recipe.get("flowers", 0) > 0:
		for i in recipe.flowers:
			_flower_carpet()


## A carpet of flowers (deco cells) on open lawn: wildflower patches.
func _flower_carpet() -> void:
	for t in 40:
		var c := Vector2i(_rng.randi_range(4, W - 6), _rng.randi_range(4, H - 6))
		var ok := true
		for y in range(c.y - 2, c.y + 3):
			for x in range(c.x - 3, c.x + 4):
				var v := Vector2i(x, y)
				if not _inside(v) or kind[_i(v)] != OPEN or paths.has(v) or _taken.has(v):
					ok = false
		if not ok:
			continue
		for y in range(c.y - 2, c.y + 3):
			for x in range(c.x - 3, c.x + 4):
				if Vector2(x - c.x, (y - c.y) * 1.4).length() + _hash(x, y) * 1.2 < 3.6:
					var h := _hash(x * 3, y * 7)
					if h < 0.62:
						deco[Vector2i(x, y)] = flowers_set[_rng.randi() % flowers_set.size()]
					elif h < 0.8:
						deco[Vector2i(x, y)] = sprouts_set[_rng.randi() % sprouts_set.size()]
		_claim(Rect2i(c - Vector2i(3, 2), Vector2i(7, 5)))
		return


# ---------------------------------------------------------------- scatter

## Props stand on open cells not claimed (unless `force`, for set pieces the
## recipe asks for); a blocking prop is taken back if it cuts a goal off
## (checked at the end, see _layout).
func _place(art: String, cell: Vector2i, force := false) -> bool:
	if not _inside(cell) or kind[_i(cell)] != OPEN or cell == spawn or paths.has(cell) or _prop_at(cell) or blocked.has(cell):
		return false
	if not force and _taken.has(cell):
		return false
	var p: Dictionary = FarmTiles.prop(season, art)
	if p.is_empty():
		return false # not drawn in this season
	var w: int = maxi(1, int(ceil(p.block.x / 16.0)))
	var r := Rect2i(cell - Vector2i(w / 2, 0), Vector2i(w, 1))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or kind[_i(c)] != OPEN or paths.has(c) or blocked.has(c):
				return false
	props.append({"art": art, "cell": cell})
	_prop_cells[cell] = true
	_claim(r)
	if p.block != Vector2.ZERO:
		for x in range(r.position.x, r.end.x):
			blocked[Vector2i(x, cell.y)] = true
	return true


## A tree from the animation sheets at `cell` (its trunk cell); the trunk
## blocks, and a ring round it stays clear of other trees.
func _place_tree(art: String, cell: Vector2i) -> bool:
	if not _inside(cell) or cell.y < 3 or kind[_i(cell)] != OPEN or paths.has(cell) or blocked.has(cell) or cell == spawn:
		return false
	for o in [Vector2i(-1, 0), Vector2i(1, 0)]:
		if not _inside(cell + o) or kind[_i(cell + o)] != OPEN:
			return false
	for t in trees:
		if Vector2(t.cell - cell).length() < 2.5:
			return false
	trees.append({"art": art, "cell": cell})
	blocked[cell] = true
	_claim(Rect2i(cell - Vector2i(1, 1), Vector2i(3, 2)))
	return true


func _near(arts: Array, count: int, center: Vector2i, radius: int) -> void:
	var put := 0
	for t in count * 30:
		if put >= count:
			return
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if _place(arts[_rng.randi() % arts.size()], c):
			put += 1


## Trees in clusters (the mockups' layered crowns, undergrowth round them),
## then singles; they crowd onto the darker grass. On the woodlot a row
## stands in front of the canopy wall so the crowns cover its straight edge.
func _scatter_trees() -> void:
	var set_: Array = _tree_set(recipe.trees[0])
	var want: int = recipe.trees[1]
	var placed := 0
	if not canopy.is_empty():
		for x in range(2, W - 2, 4):
			if _place_tree(set_[_rng.randi() % set_.size()], Vector2i(x + _rng.randi_range(0, 1), 4 + _rng.randi_range(0, 1))):
				placed += 1
	for n in maxi(2, want / 5):
		var c := Vector2i(_rng.randi_range(3, W - 4), _rng.randi_range(4, H - 5))
		if tone_level(c) < 1 and _rng.randf() < 0.5:
			continue
		for k in _rng.randi_range(3, 5):
			var p := c + Vector2i(_rng.randi_range(-5, 5), _rng.randi_range(-3, 3))
			if not _taken.has(p) and _place_tree(set_[_rng.randi() % set_.size()], p):
				placed += 1
		_near(["bush", "bush_b", "bush_pine", "stump", "mushroom", "mushrooms", "log_s"], _rng.randi_range(2, 3), c + Vector2i(0, 2), 5)
	for t in want * 30:
		if placed >= want:
			break
		var c := Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(4, H - 3))
		if _taken.has(c):
			continue
		var near := false
		for tr in trees:
			if Vector2(tr.cell - c).length() < 4.0:
				near = true
				break
		if near:
			continue
		if _place_tree(set_[_rng.randi() % set_.size()], c):
			placed += 1


func _scatter_small() -> void:
	_near(["bush", "bush_b", "bush_pine", "rock", "rock_b", "log", "stump", "stump_b"], 8, Vector2i(W / 2, H / 2), W / 2)
	_near(["pebble", "pebble_b", "mushroom_red", "mushroom", "mushroom_s", "mushroom_b", "log_s"], 14, Vector2i(W / 2, H / 2), W / 2)
	for p in ponds:
		_near(["reeds", "reeds_b", "reeds_s", "cattail", "cattail_b"], 4, p.get_center(), maxi(p.size.x, p.size.y) / 2 + 2)


## Sprouts, tufts, and flowers on plain grass cells: sprouts and flowers on
## the lawn and pale grass, the darkest sprouts on dark and deep grass; and
## on plateau tops (inside the rim).
func _deco() -> void:
	for pl in plateaus:
		var r: Rect2i = pl.rect
		var top_rows: int = r.size.y - 2
		for y in range(r.position.y + 1, r.position.y + top_rows - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				var h := _hash(x * 13, y * 7)
				if h < 0.22:
					var set_: Array = sprouts_dark if pl.tone == "d" else sprouts_set
					deco[Vector2i(x, y)] = set_[int(_hash(y, x * 3) * set_.size()) % set_.size()]
				elif h < 0.3 and pl.tone != "d":
					deco[Vector2i(x, y)] = flowers_set[int(_hash(y * 5, x) * flowers_set.size()) % flowers_set.size()]
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if deco.has(c) or kind[_i(c)] != OPEN or paths.has(c) or _prop_at(c) or blocked.has(c):
				continue
			var s := sig(c)
			if s != "gggg":
				continue
			var h := _hash(x * 5 + 1, y * 3 + 7)
			if season == "winter":
				h = h * 3.0 + 0.04 # a frosty tuft here and there, not a carpet
			if tone_level(c) <= 0:
				if h < 0.05:
					deco[c] = flowers_set[int(_hash(y, x) * flowers_set.size()) % flowers_set.size()]
				elif h < 0.15:
					deco[c] = sprouts_set[int(_hash(y, x) * sprouts_set.size()) % sprouts_set.size()]
				elif h < 0.17:
					deco[c] = tufts_set[int(_hash(y, x) * 2.0) % tufts_set.size()] if not tufts_set.is_empty() else sprouts_set[0]
			elif h < 0.12:
				deco[c] = sprouts_dark[int(_hash(y, x) * sprouts_dark.size()) % sprouts_dark.size()]


# ---------------------------------------------------------------- liveliness

# The Painted Lands floor with its frozen weights: water moves, trees rustle
# and shed, crops nod, wheat waves, animals graze in pens, flowers draw
# butterflies. A weak window gets a small pond, or a flower carpet, or a
# swarm of fireflies.
const LIVE_FLOOR := 0.09
const FLOOR_ANCHORS := 4
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WATER := 6.0
const FLOOR_TREE := 6.0
const FLOOR_CROP := 2.0
const FLOOR_WHEAT := 1.2
const FLOOR_PEN := 2.5
const FLOOR_FLOWER := 3.0
const FLOOR_GLOW := 30.0

func _liveliness_floor() -> void:
	for n in FLOOR_ANCHORS:
		var weak := _weakest()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR:
			break
		var r: Rect2i = weak.rect
		if ponds.size() < 2 and _floor_pond(r):
			floor_notes.append("pond")
		elif _floor_flowers(r):
			floor_notes.append("flowers")
		else:
			var c := r.get_center() + Vector2i(_rng.randi_range(-8, 8), _rng.randi_range(-3, 3))
			firefly_spots.append(c.clamp(Vector2i(1, 1), Vector2i(W - 2, H - 2)))
			floor_notes.append("fireflies")
	floor_notes.append("-> %.3f%%" % _weakest().value)


## A carpet of wildflowers in the weak window (butterflies and bees come).
func _floor_flowers(r: Rect2i) -> bool:
	var before := deco.size()
	for t in 30:
		var c := r.get_center() + Vector2i(_rng.randi_range(-14, 14), _rng.randi_range(-5, 5))
		var ok := true
		for y in range(c.y - 2, c.y + 3):
			for x in range(c.x - 3, c.x + 4):
				var v := Vector2i(x, y)
				if not _inside(v) or kind[_i(v)] != OPEN or paths.has(v) or _prop_at(v) or blocked.has(v) or sig(v) != "gggg":
					ok = false
		if not ok:
			continue
		for y in range(c.y - 2, c.y + 3):
			for x in range(c.x - 3, c.x + 4):
				if Vector2(x - c.x, (y - c.y) * 1.4).length() + _hash(x, y) * 1.2 < 3.6:
					var h := _hash(x * 3, y * 7)
					if h < 0.62:
						deco[Vector2i(x, y)] = flowers_set[_rng.randi() % flowers_set.size()]
					elif h < 0.8:
						deco[Vector2i(x, y)] = sprouts_set[_rng.randi() % sprouts_set.size()]
		return deco.size() > before
	return false


func _floor_pond(r: Rect2i) -> bool:
	for t in 30:
		var bsize := Vector2i(_rng.randi_range(3, 4), _rng.randi_range(2, 3))
		var at := (r.get_center() / 2) + Vector2i(_rng.randi_range(-7, 5), _rng.randi_range(-3, 1))
		var box := Rect2i(at * 2, bsize * 2)
		if box.position.x < 2 or box.position.y < 2 or box.end.x > W - 2 or box.end.y > H - 2:
			continue
		var ok := true
		for y in range(box.position.y - 1, box.end.y + 1):
			for x in range(box.position.x - 1, box.end.x + 1):
				var c := Vector2i(x, y)
				if kind[_i(c)] != OPEN or blocked.has(c) or paths.has(c) or c == spawn or _prop_at(c):
					ok = false
		if not ok:
			continue
		var blocks := {}
		for by in range(at.y, at.y + bsize.y):
			for bx in range(at.x, at.x + bsize.x):
				blocks[Vector2i(bx, by)] = true
		_clean_blocks(blocks)
		var cells := _block_cells(blocks)
		for c in cells:
			water[c] = true
			kind[_i(c)] = WATER
		if _reaches_all():
			ponds.append(box)
			_lock_round(cells, 1.0)
			_repair()
			_zones()
			for c in cells:
				deco.erase(c)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					for c in cells:
						deco.erase(c + Vector2i(dx, dy))
			return true
		for c in cells:
			water.erase(c)
			kind[_i(c)] = OPEN
	return false


var _prop_cells := {}

func _prop_at(c: Vector2i) -> bool:
	return _prop_cells.has(c)


func _weakest() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(W * H)
	m.fill(0.0)
	for c: Vector2i in water:
		m[_i(c)] += FLOOR_WATER
	for t in trees:
		m[_i(t.cell)] += FLOOR_TREE
	for cr in crops:
		if cr.crop in FarmTiles.CROPS_NOD:
			m[_i(cr.cell)] += FLOOR_CROP
	for k in ["wheat", "tall"]:
		for v: Vector2i in blobs[k]:
			if _inside(v):
				m[_i(v)] += FLOOR_WHEAT
	for c: Vector2i in pen_cells():
		m[_i(c)] += FLOOR_PEN / 10.0
	for c: Vector2i in deco:
		if deco[c] in flowers_set:
			m[_i(c)] += FLOOR_FLOWER
	for c in firefly_spots:
		m[_i(c)] += FLOOR_GLOW * 2.0
	var best := {"rect": Rect2i(), "value": INF}
	var xs: Array[int] = []
	var ys: Array[int] = []
	for x in range(0, W - FLOOR_VIEW.x + 1, 2):
		xs.append(x)
	for y in range(0, H - FLOOR_VIEW.y + 1, 2):
		ys.append(y)
	xs.append(W - FLOOR_VIEW.x)
	ys.append(H - FLOOR_VIEW.y)
	for y in ys:
		for x in xs:
			var s := 0.0
			for yy in range(y, y + FLOOR_VIEW.y):
				for xx in range(x, x + FLOOR_VIEW.x):
					s += m[yy * W + xx]
			var v := s / float(FLOOR_VIEW.x * FLOOR_VIEW.y)
			if v < best.value:
				best = {"rect": Rect2i(x, y, FLOOR_VIEW.x, FLOOR_VIEW.y), "value": v}
	return best


# ---------------------------------------------------------------- ambience inputs

func open_water() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in water:
		if stones.has(c):
			continue
		var all := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not water.has(c + Vector2i(dx, dy)):
					all = false
		if all:
			out.append(c)
	return out


## Cells the walker stands on with grass (any tone) or a wheat or tall-grass
## blob under them (grass waves, blade flicks).
func grass_cells() -> Dictionary:
	var out := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != OPEN or blocked.has(c):
				continue
			var s := sig(c)
			if not "e" in s and not "s" in s:
				out[c] = true
	return out


## Cells of wheat and tall grass (all four corners in the blob).
func wheat_cells() -> Dictionary:
	var out := {}
	for k in ["wheat", "tall"]:
		for y in H:
			for x in W:
				var c := Vector2i(x, y)
				if blob_sig(k, c) == "1111":
					out[c] = true
	return out


func zone_cells() -> Dictionary:
	var out := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != OPEN:
				continue
			if tone_level(c) >= 1:
				out[c] = true
	return out


func trunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for t in trees:
		out.append(t.cell)
	for p in props:
		if FarmTiles.prop(season, p.art).tag == "bare":
			out.append(p.cell)
	return out


## The wildlife plan (wildlife.gd plan_from), with the pack table's farm
## habitats when `p_mode` is "farmland" (or "pack"): poultry and pigs in the yards by the
## doors, sheep, goats, and cows in the pens (or on the lawn round a home
## when the map has no pen).
func wildlife_plan(p_mode := "") -> Dictionary:
	var grass := grass_cells()
	var zones := zone_cells()
	var land := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if walkable(c) and not gates.has(c):
				land[c] = true
	var tr := trunks()
	var clutter: Array[Vector2i] = []
	var bushes: Array[Vector2i] = []
	var rocks: Array[Vector2i] = []
	for p in props:
		var tag: String = FarmTiles.prop(season, p.art).tag
		if tag in ["clutter", "wood", "hay"]:
			clutter.append(p.cell)
		elif tag in ["bush", "plant", "reed"]:
			bushes.append(p.cell)
		elif tag == "stone":
			rocks.append(p.cell)
	for c: Vector2i in fence:
		clutter.append(c)
	for pl in plateaus:
		var r: Rect2i = pl.rect
		for x in range(r.position.x, r.end.x):
			rocks.append(Vector2i(x, r.end.y))
	var hedge_cells: Array[Vector2i] = []
	for c: Vector2i in blocked:
		if blob_sig("hedge", c) != "0000":
			hedge_cells.append(c)
	bushes.append_array(hedge_cells)
	var pen := pen_cells()
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	for c: Vector2i in land:
		var wet := false
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if water.has(c + d):
				wet = true
		if wet:
			h.shore[c] = true
		var in_pen: bool = pen.has(c)
		if not wet and not in_pen:
			h.roam[c] = true
			if grass.has(c) and not zones.has(c):
				h.lawn[c] = true
		if zones.has(c) and not in_pen:
			h.dark[c] = true
		if _near_any(c, tr, 2):
			h.trees[c] = true
		if _near_any(c, clutter, 2):
			h.clutter[c] = true
		if _near_any(c, bushes, 2):
			h.bushes[c] = true
		if _near_any(c, rocks, 2):
			h.rocky[c] = true
		if (paths.has(c + Vector2i.DOWN) or paths.has(c + Vector2i.UP)) and not in_pen:
			h.open[c] = true
	for c in open_water():
		h.water[c] = true
	if p_mode in ["pack", "farmland"]:
		var doors: Array[Vector2i] = []
		for b in buildings:
			doors.append(b.door + Vector2i(0, 1))
		var outside := {}
		for c: Vector2i in land:
			if not pen.has(c):
				outside[c] = true
		Wildlife.add_homesteads(h, doors, outside, h.lawn)
		if not pen.is_empty():
			h.pasture = pen
	h["_land"] = land
	var ts := {}
	for t in tr:
		ts[t] = true
	h["_trunks"] = ts
	h["_w"] = W
	var quiet: Array[Vector2i] = []
	quiet.append_array(water.keys())
	quiet.append_array(tr)
	var plan := Wildlife.plan_from(h, map_id, spawn, Wildlife.quiet_from(quiet, W, H), p_mode)
	if p_mode == "farmland":
		_herd_every_pen(plan)
	if season == "winter":
		# Lizards and frogs keep out of the snow.
		plan.groups = plan.groups.filter(func(g): return not g.kind in ["lizard", "frog"])
	return plan


## A pen the plan left empty gets a herd of its own (sheep, goats, or cows,
## by pen), so no fence closes on bare grass.
func _herd_every_pen(plan: Dictionary) -> void:
	var grazers := ["sheep", "goat", "cow"]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_id, "pens"])
	for i in pens.size():
		var r: Rect2i = pens[i].rect
		var inner := Rect2i(r.position + Vector2i.ONE, r.size - Vector2i(2, 2))
		var has := false
		for g in plan.groups:
			if inner.has_point(g.center):
				has = true
		if has:
			continue
		var cells: Array[Vector2i] = []
		for y in range(inner.position.y, inner.end.y):
			for x in range(inner.position.x, inner.end.x):
				var c := Vector2i(x, y)
				if walkable(c):
					cells.append(c)
		if cells.size() < 6:
			continue
		var kind_: String = grazers[(i + rng.randi_range(0, 2)) % grazers.size()]
		var center: Vector2i = cells[cells.size() / 2]
		for k in range(cells.size() - 1, 0, -1):
			var j := rng.randi_range(0, k)
			var tmp := cells[k]
			cells[k] = cells[j]
			cells[j] = tmp
		var n := rng.randi_range(2, 4) if kind_ != "cow" else rng.randi_range(1, 3)
		plan.groups.append({"kind": kind_, "center": center, "cells": cells.slice(0, n)})


func _near_any(c: Vector2i, cells: Array[Vector2i], r: int) -> bool:
	for o in cells:
		if absi(o.x - c.x) <= r and absi(o.y - c.y) <= r:
			return true
	return false


# ---------------------------------------------------------------- checks

func walkable(c: Vector2i) -> bool:
	if not _inside(c) or blocked.has(c):
		return false
	if stones.has(c):
		return true
	return kind[_i(c)] == OPEN


func _reaches_all() -> bool:
	for g in goals:
		if not _reaches(spawn, g):
			return false
	return true


func _reaches(from: Vector2i, to: Vector2i) -> bool:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c == to:
			return true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if seen.has(n) or not walkable(n):
				continue
			seen[n] = true
			queue.append(n)
	return false


## Every map's checks: the walker reaches every goal (doors, gates, fields,
## the hub), every cell has a ground tile, every water cell and shore cell a
## shore tile (farm.gd shore_tile).
func _report() -> String:
	if not _reaches_all():
		fails.append("spawn does not reach every goal")
	var untiled := 0
	for y in H:
		for x in W:
			if not wang.has(sig(Vector2i(x, y))):
				untiled += 1
	if untiled > 0:
		fails.append("%d cells without a tile" % untiled)
	var shoreless := 0
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if shore_key(c) == "?":
				shoreless += 1
	if shoreless > 0:
		fails.append("%d shore cells without a tile" % shoreless)
	for k in recipe.buildings:
		if not buildings.any(func(b): return b.kind == k):
			fails.append("no %s" % k)
	var names := PackedStringArray()
	for b in buildings:
		names.append(b.kind)
	var lines := PackedStringArray([
		"Farm map %d: recipe %d %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, W, H, attempt],
		"  buildings %s; fields %d (%d crops), pens %d, trees %d, props %d, water %d cells, path %d cells, plateaus %d" % [
			", ".join(names) if not names.is_empty() else "none", fields.size(), crops.size(), pens.size(), trees.size(), props.size(), water.size(), paths.size(), plateaus.size()],
		"  %s" % ", ".join(notes),
		"  floor: %s" % " ".join(floor_notes),
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	return "\n".join(lines)


## The shore tile key for a cell: "" plain (neither water nor shore), "open"
## for open water, a SHORE_LAND or SHORE_WATER key, or "?" when the sheet has
## no tile for that mix (never, when ponds are built from blocks).
func shore_key(c: Vector2i) -> String:
	var here := water.has(c)
	var n := water.has(c + Vector2i.UP)
	var s := water.has(c + Vector2i.DOWN)
	var w := water.has(c + Vector2i.LEFT)
	var e := water.has(c + Vector2i.RIGHT)
	var nw := water.has(c + Vector2i(-1, -1))
	var ne := water.has(c + Vector2i(1, -1))
	var sw := water.has(c + Vector2i(-1, 1))
	var se := water.has(c + Vector2i(1, 1))
	if not here:
		if not (n or s or w or e or nw or ne or sw or se):
			return ""
		if (n and s) or (w and e):
			return "?"
		var k := ""
		if n:
			k = "N"
		elif s:
			k = "S"
		if w:
			k += "W"
		elif e:
			k += "E"
		if k != "":
			return k
		var diag := int(nw) + int(ne) + int(sw) + int(se)
		if diag != 1:
			return "?"
		return "nw" if nw else ("ne" if ne else ("sw" if sw else "se"))
	# A water cell: where the land is.
	var ln := not n and _inside(c + Vector2i.UP)
	var ls := not s and _inside(c + Vector2i.DOWN)
	var lw := not w and _inside(c + Vector2i.LEFT)
	var le := not e and _inside(c + Vector2i.RIGHT)
	if (ln and ls) or (lw and le):
		return "?"
	if ln or ls or lw or le:
		if ln and le:
			return "NE"
		if ln and lw:
			return "NW"
		if ls and le:
			return "ES"
		if ls and lw:
			return "WS"
		return "N" if ln else ("S" if ls else ("W" if lw else "E"))
	var lnw := not nw and _inside(c + Vector2i(-1, -1))
	var lne := not ne and _inside(c + Vector2i(1, -1))
	var lsw := not sw and _inside(c + Vector2i(-1, 1))
	var lse := not se and _inside(c + Vector2i(1, 1))
	var diag := int(lnw) + int(lne) + int(lsw) + int(lse)
	if diag == 0:
		return "open"
	if diag != 1:
		return "?"
	return "nw" if lnw else ("ne" if lne else ("sw" if lsw else "se"))
