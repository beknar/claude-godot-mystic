extends Node2D
## Paints a Mana Seed map from MSTerrain: the corner-Wang ground, ground deco,
## plateau stamps, the forest wall and its canopy, water sparkles, props,
## tall grass, weather, the walker, and the ambience of the Painted Lands and
## Green Caves scenes (wind, leaves, streaks, cloud shadows, grass waves, water
## life, critters, drifters, wildlife, footsteps, fire light, motes and
## glints). The season's sheets come from assets/pack/mana_seed/<season>/.

const TILE := 16
const W := MSTerrain.W
const H := MSTerrain.H
const PACK := "res://assets/pack/mana_seed/"
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const WANG_SRC := 0
const FOREST_SRC := 1
const SPARKLE_SRC := 2
const WALL_SRC := 0 # on the 128 px wall and canopy tile sets

@export var map_id := 160000
@export var recipe := -1

@onready var ground_layer: TileMapLayer = $Ground
@onready var deco_layer: TileMapLayer = $Deco
@onready var cliff_layer: TileMapLayer = $Cliffs
@onready var cliff2_layer: TileMapLayer = $Cliffs2
@onready var sparkle_layer: TileMapLayer = $Sparkles
@onready var wall_layer: TileMapLayer = $Wall
@onready var shade_layer: TileMapLayer = $Shade
@onready var canopy_layer: TileMapLayer = $Canopy
@onready var under: Node2D = $Under
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: MSTerrain
var report := ""
var _tiles: TileSet
var _wall_tiles: TileSet
var _canopy_tiles: TileSet
var _sheets := {} # name -> Texture2D for this season
var _images := {} # name -> Image
var _leaf_colors := {}
var _last_tall := Vector2i(-1, -1)
var weather: Node2D

var wind: Wind
var streaks: WindStreaks
var grass_waves: GrassWaves
var water_life: WaterLife
var footsteps: Footsteps
var critters: Critters
var fire: FireAmbience
var leaves: AmbientLeaves
var drifters: Drifters
var wildlife: Wildlife
var clouds: CloudShadows
var cave_life: CaveLife


func _ready() -> void:
	_add_ambience()
	build(map_id, recipe)


func _process(_delta: float) -> void:
	# Tall grass rustles where the walker steps into it.
	var walker := actors.get_node_or_null("Walker")
	if walker == null or terrain == null:
		return
	var cell := Vector2i((walker.position / TILE).floor())
	if cell != _last_tall:
		_last_tall = cell
		if terrain.tall.has(cell):
			_rustle(cell)


## Generates `id` and repaints everything; safe to call again.
func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = MSTerrain.new()
	report = terrain.generate(map_id, recipe)
	_load_season(terrain.season)
	for layer in [ground_layer, deco_layer, cliff_layer, cliff2_layer, sparkle_layer, wall_layer, shade_layer, canopy_layer]:
		layer.clear()
	for node in [under, actors, collision]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_build_tilesets()
	_paint()
	_build_collision()
	_place_props()
	_place_tall_grass()
	_spawn_walker()
	_set_weather()
	_reset_ambience()
	print(report)


func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in MSTerrain.RECIPES:
		out.append(r.name)
	return out


func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s, %s" % [terrain.recipe_id, terrain.recipe.name, terrain.season], "checks": checks}


# ---------------------------------------------------------------- sheets

func _load_season(s: String) -> void:
	_sheets.clear()
	_images.clear()
	for n in ["wang", "forest", "16x16", "16x32", "32x32", "48x32", "trees", "tallgrass", "sparkles", "treewall", "canopy"]:
		_sheets[n] = load(PACK + s + "/" + n + ".png")


func _sheet(name: String) -> Texture2D:
	if not _sheets.has(name):
		_sheets[name] = load(PACK + name + ".png")
	return _sheets[name]


func _image(name: String) -> Image:
	if not _images.has(name):
		var img := _sheet(name).get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[name] = img
	return _images[name]


# ---------------------------------------------------------------- tiles

func _build_tilesets() -> void:
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(TILE, TILE)
	for pair in [[WANG_SRC, "wang"], [FOREST_SRC, "forest"]]:
		var src := TileSetAtlasSource.new()
		src.texture = _sheets[pair[1]]
		src.texture_region_size = Vector2i(TILE, TILE)
		_tiles.add_source(src, pair[0])
	# Sparkles: three rows of four frames at 0.6 s.
	var sp := TileSetAtlasSource.new()
	sp.texture = _sheets.sparkles
	sp.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(sp, SPARKLE_SRC)
	for row in 3:
		sp.create_tile(Vector2i(0, row))
		sp.set_tile_animation_columns(Vector2i(0, row), 4)
		sp.set_tile_animation_frames_count(Vector2i(0, row), 4)
		for f in 4:
			sp.set_tile_animation_frame_duration(Vector2i(0, row), f, 0.6)
	for layer in [ground_layer, deco_layer, cliff_layer, cliff2_layer, sparkle_layer, shade_layer]:
		layer.tile_set = _tiles
	_wall_tiles = _big_tileset(_open_wall(terrain.season))
	_canopy_tiles = _big_tileset(_sheets.canopy)
	wall_layer.tile_set = _wall_tiles
	canopy_layer.tile_set = _canopy_tiles


## The tree wall with its plain ground cut out: the supertiles bake the grass
## of their clearing half, which would hide the map's own ground (ponds, paths,
## dark grass) behind straight 128 px edges. Every 16 px subtile that is
## exactly a ground tile of this season's sheets (the pack built the wall from
## them) turns transparent; grass by the trunks and the trees' shadows stay.
var _open_walls := {}

func _open_wall(s: String) -> Texture2D:
	if _open_walls.has(s):
		return _open_walls[s]
	var ground := {}
	var wang := _image("wang")
	for r in wang.get_height() / TILE:
		for c in wang.get_width() / TILE:
			ground[wang.get_region(Rect2i(c * TILE, r * TILE, TILE, TILE)).get_data()] = true
	var forest := _image("forest")
	for r in 6:
		for c in 5:
			ground[forest.get_region(Rect2i(c * TILE, r * TILE, TILE, TILE)).get_data()] = true
	var img := _image("treewall").duplicate()
	var clear := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y in img.get_height() / TILE:
		for x in img.get_width() / TILE:
			var at := Vector2i(x * TILE, y * TILE)
			if ground.has(img.get_region(Rect2i(at, Vector2i(TILE, TILE))).get_data()):
				img.blit_rect(clear, Rect2i(0, 0, TILE, TILE), at)
	var tex := ImageTexture.create_from_image(img)
	_open_walls[s] = tex
	return tex


func _big_tileset(tex: Texture2D) -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(128, 128)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(128, 128)
	ts.add_source(src, WALL_SRC)
	return ts


func _put(layer: TileMapLayer, source: int, cell: Vector2i, atlas: Vector2i) -> void:
	var src: TileSetAtlasSource = layer.tile_set.get_source(source)
	if not src.has_tile(atlas):
		src.create_tile(atlas)
	layer.set_cell(cell, source, atlas)


func _paint() -> void:
	# Ground: each cell takes the Wang tile of its four corners; fills pick a
	# variant by hash, mostly the plain one (cobble's red stones are rare).
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var key := terrain.wang_key(c)
			var ids: Array = MSWang.TILES[key]
			var id: int = ids[0]
			if ids.size() > 1:
				var h := _hash(x, y)
				var plain := 0.55 if key != 4444 else 0.8
				if h >= plain:
					id = ids[1 + int((h - plain) / (1.0 - plain) * (ids.size() - 1)) % (ids.size() - 1)]
			_put(ground_layer, WANG_SRC, c, Vector2i(id % 64, id / 64))
	for c in terrain.deco:
		_put(deco_layer, FOREST_SRC, c, terrain.deco[c])
	for c in terrain.hedges:
		_put(cliff2_layer, FOREST_SRC, c, terrain.hedges[c])
	# Plateaus: the stamp's two layers and its cast shadow.
	for p in terrain.plateaus:
		for piece in p.pieces:
			var layer: TileMapLayer = [cliff_layer, cliff2_layer, shade_layer][piece.layer]
			_put(layer, FOREST_SRC, piece.cell, piece.atlas)
	# Sparkles on a scatter of deep open water.
	for c in terrain.open_water():
		if terrain.wang_key(c) == 6666 and _hash(c.x * 3, c.y * 5) < 0.3:
			sparkle_layer.set_cell(c, SPARKLE_SRC, Vector2i(0, int(_hash(c.y, c.x) * 3.0)))
	# The forest wall and its canopy, 128 px supertiles.
	for st: Vector2i in terrain.wall_atlas:
		_put(wall_layer, WALL_SRC, st, terrain.wall_atlas[st])
		_put(canopy_layer, WALL_SRC, st, terrain.wall_atlas[st])


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- collision

func _build_collision() -> void:
	collision.collision_layer = 1
	# Blocking cells in horizontal runs: water (not bridged), cliff faces, the
	# forest wall; a ring outside the map.
	for y in H:
		var run := -1
		for x in W + 1:
			var solid := false
			if x < W:
				var c := Vector2i(x, y)
				var k := terrain.kind[y * W + x]
				solid = (k == MSTerrain.WATER and not terrain.bridges.has(c)) or k == MSTerrain.FACE or k == MSTerrain.WALL or terrain.hedges.has(c)
			if solid and run < 0:
				run = x
			elif not solid and run >= 0:
				_add_box(Rect2(run * TILE, y * TILE, (x - run) * TILE, TILE))
				run = -1
	for r in [Rect2(-TILE, -TILE, (W + 2) * TILE, TILE), Rect2(-TILE, H * TILE, (W + 2) * TILE, TILE),
			Rect2(-TILE, 0, TILE, H * TILE), Rect2(W * TILE, 0, TILE, H * TILE)]:
		_add_box(r)
	# Paddock rails.
	if terrain.paddock.size != Vector2i.ZERO:
		var r := terrain.paddock
		for x in range(r.position.x, r.end.x):
			for y in [r.position.y, r.end.y - 1]:
				if terrain.blocked.has(Vector2i(x, y)):
					_add_box(Rect2(x * TILE, y * TILE + 8, TILE, 6))
		for y in range(r.position.y, r.end.y):
			for x in [r.position.x, r.end.x - 1]:
				if terrain.blocked.has(Vector2i(x, y)):
					_add_box(Rect2(x * TILE + 5, y * TILE, 6, TILE))


func _add_box(r: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	collision.add_child(shape)


# ---------------------------------------------------------------- props

static func foot_of(p: Dictionary) -> Vector2:
	return Vector2(p.cell * TILE) + Vector2(TILE / 2.0, TILE - 1)


func _place_props() -> void:
	for p in terrain.props:
		var art: Dictionary = MSTerrain.PROPS[p.art]
		var foot := foot_of(p)
		var tex := _sheet(art.sheet)
		var node := StaticBody2D.new()
		node.collision_mask = 0
		node.name = "%s_%d_%d" % [p.art, p.cell.x, p.cell.y]
		node.position = foot
		var off := -Vector2(art.foot)
		if art.get("frames", 1) > 1:
			node.add_child(_flipbook(tex, Rect2(art.rect), art.frames, off, Vector2(art.step), 7.0))
		else:
			var s := _sprite(tex, Rect2(art.rect), off)
			if art.tag != "tree" and art.tag != "bridge" and _hash(p.cell.x * 5, p.cell.y * 3) < 0.5:
				s.flip_h = true
				s.offset.x = -(art.rect.size.x - art.foot.x)
			node.add_child(s)
		if art.block != Vector2.ZERO:
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = art.block
			shape.shape = rect
			shape.position = Vector2(0, -art.block.y / 2.0)
			node.add_child(shape)
		if art.tag in ["water", "flat", "bridge"]:
			under.add_child(node) # lies flat: lily pads, sticks, the bridge deck
		else:
			actors.add_child(node)
	_place_fence()


func _sprite(tex: Texture2D, region: Rect2, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.offset = offset
	return s


func _flipbook(tex: Texture2D, first: Rect2, count: int, offset: Vector2, step: Vector2, fps: float) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(first.position + step * i, first.size)
		frames.add_frame("default", at)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames
	s.centered = false
	s.offset = offset
	s.play()
	s.frame = randi() % count
	s.speed_scale = randf_range(0.85, 1.15)
	return s


## The paddock's ranch fence (fences/ranch style fence 16x16): the top and
## bottom rows run west end (0), rail and post (1), east end (2); the sides are
## the rail seen edge-on (0, 1) with a post (3, 1) every third cell; beside the
## gate the rail ends on the matching end piece.
func _place_fence() -> void:
	var r := terrain.paddock
	if r.size == Vector2i.ZERO:
		return
	var tex := _sheet("fences/ranch style fence 16x16")
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not terrain.blocked.has(c):
				continue
			var atlas: Vector2i
			if y == r.position.y or y == r.end.y - 1:
				var row := 0 if y == r.position.y else 2
				var west := x == r.position.x or not terrain.blocked.has(c + Vector2i.LEFT)
				var east := x == r.end.x - 1 or not terrain.blocked.has(c + Vector2i.RIGHT)
				atlas = Vector2i(0 if west else (2 if east else 1), row)
			else:
				atlas = Vector2i(3, 1) if (y - r.position.y) % 3 == 0 else Vector2i(0, 1)
			var s := _sprite(tex, Rect2(atlas * 16, Vector2(16, 16)), Vector2(-8, -15))
			var n := Node2D.new()
			n.position = Vector2(c * TILE) + Vector2(8, 15)
			n.add_child(s)
			actors.add_child(n)


## Tall grass: the 16x32 left, middle, and right pieces along each row,
## y-sorted so the walker wades into it.
func _place_tall_grass() -> void:
	var tex: Texture2D = _sheets["16x32"]
	for c: Vector2i in terrain.tall:
		var l := terrain.tall.has(c + Vector2i.LEFT)
		var r := terrain.tall.has(c + Vector2i.RIGHT)
		var piece := 32 if l and r else (16 if r else (48 if l else 32))
		var s := _sprite(tex, Rect2(piece, 0, 16, 32), Vector2(-8, -30))
		var n := Node2D.new()
		n.name = "Tall_%d_%d" % [c.x, c.y]
		n.position = Vector2(c * TILE) + Vector2(8, 14)
		n.add_child(s)
		actors.add_child(n)


## The pack's tall grass effect (five 32x32 frames) played once where the
## walker steps in.
func _rustle(cell: Vector2i) -> void:
	var s := _flipbook(_sheets.tallgrass, Rect2(0, 0, 32, 32), 5, Vector2(-16, -30), Vector2(32, 0), 14.0)
	s.frame = 0
	s.speed_scale = 1.0
	s.sprite_frames.set_animation_loop("default", false)
	var n := Node2D.new()
	n.position = Vector2(cell * TILE) + Vector2(8, 15)
	n.add_child(s)
	actors.add_child(n)
	s.animation_finished.connect(n.queue_free)


func _spawn_walker() -> void:
	var walker := WALKER_SCENE.instantiate()
	walker.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	actors.add_child(walker)
	var cam: Camera2D = walker.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * TILE
	cam.limit_bottom = H * TILE


# ---------------------------------------------------------------- weather

## Snow in winter (the pack's light fall, and heavy behind it on some maps),
## light rain on some marsh and autumn maps; drawn over the view.
func _set_weather() -> void:
	if weather:
		weather.queue_free()
		weather = null
	var kinds: Array = []
	var h := _hash(map_id, 17)
	match terrain.season:
		"winter":
			kinds = [["weather/weather effects, snow heavy anim 32x128", 10.0]] if h < 0.4 else []
			kinds.append(["weather/weather effects, snow light anim 32x128", 5.7])
		"autumn", "spring":
			if h < 0.12 or terrain.recipe.name == "Marsh" and h < 0.4:
				kinds = [["weather/weather effects, rain light anim 32x128", 20.0]]
	if kinds.is_empty():
		return
	weather = MSWeather.new()
	for k in kinds:
		weather.layers.append({"tex": _sheet(k[0]), "fps": k[1]})
	add_child(weather)


# ---------------------------------------------------------------- ambience

func _add_ambience() -> void:
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	streaks = WindStreaks.new()
	grass_waves = GrassWaves.new()
	water_life = WaterLife.new()
	for n in [streaks, grass_waves, water_life]:
		add_child(n)
		move_child(n, actors.get_index())
	footsteps = Footsteps.new()
	critters = Critters.new()
	fire = FireAmbience.new()
	leaves = AmbientLeaves.new()
	drifters = Drifters.new()
	wildlife = Wildlife.new()
	clouds = CloudShadows.new()
	cave_life = CaveLife.new()
	cave_life.bats = false
	for n in [footsteps, critters, fire, leaves, drifters, wildlife, clouds, cave_life]:
		add_child(n)
	for n in [streaks, grass_waves, water_life, footsteps, critters, fire, leaves, drifters, clouds, cave_life]:
		n.wind = wind
	footsteps.water_life = water_life
	footsteps.leaves = leaves
	cave_life.water_life = water_life


# Per season: grass-wave tips and blade flicks (lighter than the season's
# light grass), dust (a little darker than the dirt, or snow), cloud shade,
# water rings (paler than the deep water).
const SEASON_FX := {
	"spring": {"tip": Color(0.62, 0.8, 0.46), "blades": [Color(0.6, 0.78, 0.44), Color(0.48, 0.68, 0.36)],
		"dust": [Color(0.52, 0.36, 0.3), Color(0.44, 0.3, 0.26)], "shade": Color(0.1, 0.24, 0.14, 0.16), "ring": Color(0.3, 0.6, 0.72)},
	"summer": {"tip": Color(0.68, 0.72, 0.44), "blades": [Color(0.64, 0.7, 0.42), Color(0.52, 0.6, 0.34)],
		"dust": [Color(0.4, 0.33, 0.27), Color(0.34, 0.28, 0.23)], "shade": Color(0.08, 0.18, 0.1, 0.16), "ring": Color(0.2, 0.36, 0.62)},
	"autumn": {"tip": Color(0.9, 0.74, 0.44), "blades": [Color(0.86, 0.68, 0.38), Color(0.74, 0.54, 0.28)],
		"dust": [Color(0.42, 0.34, 0.3), Color(0.36, 0.29, 0.26)], "shade": Color(0.26, 0.16, 0.06, 0.16), "ring": Color(0.36, 0.36, 0.28)},
	"winter": {"tip": Color(0.95, 0.97, 1.0), "blades": [Color(0.94, 0.96, 1.0), Color(0.84, 0.88, 0.94)],
		"dust": [Color(0.94, 0.95, 0.98), Color(0.84, 0.86, 0.92)], "shade": Color(0.16, 0.2, 0.32, 0.14), "ring": Color(0.24, 0.34, 0.42)},
}


func _reset_ambience() -> void:
	var fx: Dictionary = SEASON_FX[terrain.season]
	var winter := terrain.season == "winter"
	var map_rect := Rect2(0, 0, W * TILE, H * TILE)
	streaks.bounds = map_rect
	clouds.shade = fx.shade
	grass_waves.tip = fx.tip
	footsteps.blade_colors = fx.blades
	footsteps.dust_colors = fx.dust
	water_life.ring_color = fx.ring
	water_life.ring_highlight = fx.ring.lightened(0.5)
	water_life.drop_color = fx.ring.lightened(0.3)
	clouds.reset(map_rect)
	var walker := actors.get_node_or_null("Walker")
	water_life.setup(terrain.open_water(), [] as Array[Sprite2D])
	var sources: Array[Dictionary] = []
	var fires: Array[Dictionary] = []
	var lights: Array[Vector2] = []
	var glinters: Array = []
	for p in terrain.props:
		var art: Dictionary = MSTerrain.PROPS[p.art]
		var foot := foot_of(p)
		var rect: Rect2i = art.rect
		var top_left := foot - Vector2(art.foot)
		match art.tag:
			"tree":
				if not winter:
					sources.append({"crown": Rect2(top_left + Vector2(8, 4), Vector2(rect.size.x - 16, rect.size.y * 0.5)),
						"base_y": foot.y}.merged(_colors_of(p.art, rect)))
			"torch":
				fires.append({"pos": foot, "kind": "torch", "flame": foot + Vector2(0, -40)})
				lights.append(foot + Vector2(0, -40))
			"lamp":
				fires.append({"pos": foot, "kind": "lamp", "radius": 26, "smoke": false, "flame": foot + Vector2(0, -44)})
				lights.append(foot + Vector2(0, -44))
			"water":
				if p.art == "boulder_wet":
					glinters.append([Vector2i(foot) + Vector2i(-6, -20), Vector2i(foot) + Vector2i(4, -16)])
	leaves.set_sources(sources)
	fire.set_fires(fires)
	cave_life.setup([] as Array[Dictionary], lights, glinters)
	var flowers: Array[Vector2] = []
	for c in terrain.deco:
		if terrain.deco[c] in MSTerrain.FLOWER_TILES:
			flowers.append(Vector2(c * TILE) + Vector2(8, 8))
	var dark: Array[Vector2] = []
	if terrain.season == "summer" or terrain.season == "autumn":
		for c in terrain.dark_cells():
			if not terrain.blocked.has(c) and (c.x * 7 + c.y * 3) % 6 == 0:
				dark.append(Vector2(c * TILE) + Vector2(8, 8))
	var ponds: Array[Rect2] = []
	if not winter:
		for r in terrain.ponds:
			ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(16, 16), Vector2(r.size) * TILE - Vector2(32, 32)))
	if winter:
		flowers.clear()
	critters.walker = walker
	critters.setup(flowers, ponds, dark)
	drifters.setup(map_rect, flowers)
	grass_waves.setup(terrain.grass_cells() if not winter else {})
	var water := {}
	for c in terrain.water:
		if not terrain.bridges.has(c):
			water[c] = true
	footsteps.setup_generic(_surface, water, walker)
	wildlife.setup_from(terrain.wildlife_plan(), water, actors, walker, _image("wang"), water_life)


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
		return "none"
	var k := terrain.kind[cell.y * W + cell.x]
	if k == MSTerrain.GROUND or k == MSTerrain.STAIR:
		return "dust"
	if k != MSTerrain.GRASS and k != MSTerrain.TOP:
		return "none"
	if terrain.season == "winter":
		return "dust"
	return "tuft" if terrain.tall.has(cell) or terrain.deco.has(cell) else "grass"


# Leaf colors from a tree's crown: light foliage colors that stand off the
# grass, edged with its darkest leaf color.
func _colors_of(key: String, region: Rect2i) -> Dictionary:
	if _leaf_colors.has(key + terrain.season):
		return _leaf_colors[key + terrain.season]
	var img := _image("trees")
	var counts := {}
	for y in range(region.position.y, region.position.y + region.size.y / 2):
		for x in range(region.position.x, region.end.x):
			var p := img.get_pixel(x, y)
			if p.a < 0.9:
				continue
			var k := p.to_rgba32()
			counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var light: Array[Color] = []
	var dark := Color(0.1, 0.25, 0.15)
	var darkest := 2.0
	for k in keys.slice(0, 10):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.45:
			light.append(c)
	if light.is_empty():
		light.append(Color.hex(keys[0]).lightened(0.3))
	_leaf_colors[key + terrain.season] = {"light": light, "dark": dark}
	return _leaf_colors[key + terrain.season]
