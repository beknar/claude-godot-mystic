extends Node2D
## Paints a Green Caves map from cave_terrain.gd: floor on Ground, dark zones
## and floor patches over it, walls, terraces, stairs, pools, and rails on
## Features, stalagmites and weed on WaterDeco, tufts on Deco, y-sorted props
## and the walker on Actors. The walker, its camera, and the Esc menu are the
## Painted Lands randomizer's.

const TILE := 16
const SHEET := preload("res://assets/pack/green_caves/green_caves_tileset.png")
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const SOURCE := 0
const W := CaveTerrain.W
const H := CaveTerrain.H
const WATER_FRAME := 0.3 # s per water frame
const EDGE := 3.0 # px: the lip of a terrace a walker cannot step over

@export var map_id := 130000
## Pins the recipe (-1: map_id % recipe count).
@export var recipe := -1

@onready var ground: TileMapLayer = $Ground
@onready var zone_layer: TileMapLayer = $Zone
@onready var features_layer: TileMapLayer = $Features
@onready var water_deco: TileMapLayer = $WaterDeco
@onready var deco_layer: TileMapLayer = $Deco
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: CaveTerrain
var wind: Wind
var leaves: AmbientLeaves
var fire: FireAmbience
var water_life: WaterLife
var critters: Critters
var footsteps: Footsteps
var wildlife: Wildlife
var cave_life: CaveLife
var home_life: InteriorLife
var homes_node: Node2D # the homes' InteriorViews, over the floor and under the actors
var home_views: Array = []
var report := ""
var _atlas: TileSetAtlasSource
var _pixels: Image
var _erased := {} # art -> ImageTexture with its erase rect cleared
var _leaf_colors := {}


func _ready() -> void:
	_pixels = SHEET.get_image()
	if _pixels.is_compressed():
		_pixels.decompress()
	var tiles := _build_tileset()
	for layer in [ground, zone_layer, features_layer, water_deco, deco_layer]:
		layer.tile_set = tiles
	homes_node = Node2D.new()
	homes_node.name = "Homes"
	add_child(homes_node)
	move_child(homes_node, actors.get_index())
	_add_ambience()
	build(map_id, recipe)


## Generates `id` and repaints every layer; safe to call again.
func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = CaveTerrain.new()
	report = terrain.generate(map_id, recipe)
	for layer in [ground, zone_layer, features_layer, water_deco, deco_layer]:
		layer.clear()
	for node in [actors, collision, homes_node]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_paint()
	_build_collision()
	_place_props()
	_place_homes()
	_spawn_walker()
	_reset_ambience()
	print(report)


## For the randomizer menu: the recipe names, in recipe-id order.
func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in CaveTerrain.RECIPES:
		out.append(r.name)
	return out


## For the randomizer menu: {id, name, checks}.
func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


# ---------------------------------------------------------------- tiles

func _build_tileset() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	_atlas = TileSetAtlasSource.new()
	_atlas.texture = SHEET
	_atlas.texture_region_size = Vector2i(TILE, TILE)
	tiles.add_source(_atlas, SOURCE)
	return tiles


## Pool tiles (the ring, the banks, the water edges) have four frames stacked
## four rows apart; open water has four frames side by side. All run in step,
## so the bank's lapping matches the water beside it.
static func animation_for(atlas: Vector2i) -> Dictionary:
	if atlas.x >= 20 and atlas.x <= 28 and atlas.y <= 3:
		return {"columns": 1, "separation": Vector2i(0, 3)}
	if atlas == CaveTerrain.OPEN_WATER:
		return {"columns": 4, "separation": Vector2i.ZERO}
	if atlas == Vector2i(29, 9) or atlas == Vector2i(29, 10):
		return {"columns": 4, "separation": Vector2i.ZERO, "random": true} # sparkles, each on its own beat
	return {}


func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i) -> void:
	if not _atlas.has_tile(atlas):
		_atlas.create_tile(atlas)
		var anim := animation_for(atlas)
		if not anim.is_empty():
			_atlas.set_tile_animation_columns(atlas, anim.columns)
			_atlas.set_tile_animation_separation(atlas, anim.separation)
			_atlas.set_tile_animation_frames_count(atlas, 4)
			for i in 4:
				_atlas.set_tile_animation_frame_duration(atlas, i, WATER_FRAME)
			if anim.get("random", false):
				_atlas.set_tile_animation_mode(atlas, TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES)
	layer.set_cell(cell, SOURCE, atlas)


func _paint() -> void:
	for c in terrain.floor_tiles:
		_put(ground, c, terrain.floor_tiles[c])
	for c in terrain.zone_tiles:
		_put(zone_layer, c, terrain.zone_tiles[c])
	for c in terrain.accents:
		_put(zone_layer, c, terrain.accents[c])
	for c in terrain.features:
		_put(features_layer, c, terrain.features[c])
	for c in terrain.water_deco:
		_put(water_deco, c, terrain.water_deco[c])
	for c in terrain.sparkles:
		_put(water_deco, c, terrain.sparkles[c])
	for c in terrain.deco:
		_put(deco_layer, c, terrain.deco[c])


# ---------------------------------------------------------------- collision

func _build_collision() -> void:
	# Rock, faces, and water: one box per horizontal run.
	for y in H:
		var x := 0
		while x < W:
			if not _solid(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < W and _solid(Vector2i(x, y)):
				x += 1
			_add_box(collision, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
	# A terrace top is raised: its north, west, and east lips are walls, so
	# it is entered by its stairs only.
	for r in terrain.terraces:
		_add_box(collision, Rect2(r.position.x * TILE, r.position.y * TILE, r.size.x * TILE, EDGE))
		_add_box(collision, Rect2(r.position.x * TILE, r.position.y * TILE, EDGE, r.size.y * TILE))
		_add_box(collision, Rect2(r.end.x * TILE - EDGE, r.position.y * TILE, EDGE, r.size.y * TILE))
	var w := W * TILE
	var h := H * TILE
	_add_box(collision, Rect2(-TILE, -TILE, w + 2 * TILE, TILE))
	_add_box(collision, Rect2(-TILE, h, w + 2 * TILE, TILE))
	_add_box(collision, Rect2(-TILE, 0, TILE, h))
	_add_box(collision, Rect2(w, 0, TILE, h))


func _solid(c: Vector2i) -> bool:
	var k := terrain.kind[c.y * W + c.x]
	return k == CaveTerrain.WALL or k == CaveTerrain.FACE or k == CaveTerrain.WATER


# ---------------------------------------------------------------- props

func _place_props() -> void:
	for prop in terrain.props:
		var art: Dictionary = CaveTerrain.PROPS[prop.art]
		var body := StaticBody2D.new()
		body.collision_mask = 0
		body.name = "%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y]
		body.position = foot_of(prop)
		var region := Rect2(art.region)
		var foot := Vector2(art.foot)
		var frames: int = art.get("frames", 1)
		if frames > 1:
			body.add_child(_flipbook(region, frames, -foot, 7.0))
		elif art.has("erase"):
			body.add_child(_texture_sprite(_erased_texture(prop.art), -foot))
		else:
			body.add_child(_region_sprite(region, -foot))
		var block: Vector2 = art.block
		if block != Vector2.ZERO:
			_add_box(body, Rect2(Vector2(-block.x / 2.0, -block.y), block))
		actors.add_child(body)


## Homes built into the cave: each plan painted in place, its ring edged with
## the cave's rock toward the cave floor, its furniture among the actors.
func _place_homes() -> void:
	home_views.clear()
	for h in terrain.homes:
		var view := InteriorView.new()
		view.cave_sheet = SHEET
		view.position = Vector2(h.origin * TILE)
		homes_node.add_child(view)
		view.build(h.plan, actors)
		home_views.append(view)


## A prop's foot in world pixels: the bottom middle of its footprint.
static func foot_of(prop: Dictionary) -> Vector2:
	var fc: Rect2i = CaveTerrain.PROPS[prop.art].foot_cells
	return Vector2(prop.cell.x * TILE + fc.size.x * TILE / 2.0, prop.cell.y * TILE + TILE - 1)


func _erased_texture(art_name: String) -> Texture2D:
	if not _erased.has(art_name):
		var art: Dictionary = CaveTerrain.PROPS[art_name]
		var img := _pixels.get_region(art.region)
		img.fill_rect(art.erase, Color(0, 0, 0, 0))
		_erased[art_name] = ImageTexture.create_from_image(img)
	return _erased[art_name]


func _spawn_walker() -> void:
	var walker := WALKER_SCENE.instantiate()
	walker.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	actors.add_child(walker)
	var camera: Camera2D = walker.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = W * TILE
	camera.limit_bottom = H * TILE


func _region_sprite(region: Rect2, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SHEET
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.offset = offset
	return sprite


func _texture_sprite(tex: Texture2D, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.offset = offset
	return sprite


func _flipbook(first: Rect2, count: int, offset: Vector2, fps: float) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	for i in count:
		var tex := AtlasTexture.new()
		tex.atlas = SHEET
		tex.region = Rect2(first.position + Vector2(i * first.size.x, 0), first.size)
		frames.add_frame("default", tex)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = offset
	sprite.play("default")
	sprite.frame = randi() % count
	sprite.speed_scale = randf_range(0.85, 1.15)
	return sprite


func _add_box(parent: Node, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = rect.get_center()
	parent.add_child(node)


# ---------------------------------------------------------------- ambience

func _add_ambience() -> void:
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	water_life = WaterLife.new()
	water_life.ring_color = Color(0.27, 0.55, 0.62) # lighter than the pool's teal
	water_life.ring_highlight = Color(0.72, 0.9, 0.94)
	water_life.drop_color = Color(0.55, 0.78, 0.84)
	add_child(water_life)
	move_child(water_life, actors.get_index()) # ripples under the y-sorted actors
	footsteps = Footsteps.new()
	footsteps.blade_colors = [Color(0.56, 0.72, 0.42), Color(0.44, 0.6, 0.36)] # moss and tufts
	critters = Critters.new()
	fire = FireAmbience.new()
	leaves = AmbientLeaves.new()
	wildlife = Wildlife.new()
	cave_life = CaveLife.new()
	cave_life.water_life = water_life
	home_life = InteriorLife.new()
	home_life.name = "HomeLife"
	add_child(home_life)
	move_child(home_life, actors.get_index()) # under the y-sorted actors
	for n in [footsteps, critters, fire, leaves, wildlife, cave_life]:
		add_child(n)
	for n in [water_life, footsteps, critters, fire, leaves, cave_life]:
		n.wind = wind
	footsteps.water_life = water_life
	footsteps.leaves = leaves


func _reset_ambience() -> void:
	var walker := actors.get_node_or_null("Walker")
	var water := terrain.water_cells()
	var open := terrain.open_water()
	var ponds: Array[Rect2] = []
	for r in terrain.pools:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16)))
	water_life.setup(open, [] as Array[Sprite2D])
	# Fires, leaves, and glints come from the props.
	var fires: Array[Dictionary] = []
	var lights: Array[Vector2] = []
	var sources: Array[Dictionary] = []
	var glinters: Array = []
	var flowers: Array[Vector2] = []
	for prop in terrain.props:
		var art: Dictionary = CaveTerrain.PROPS[prop.art]
		var foot := foot_of(prop)
		var top_left := foot - Vector2(art.foot)
		match art.tag:
			"fire", "torch":
				var torch: bool = art.tag == "torch"
				var flame := foot + (Vector2(0, -10) if torch else Vector2(0, -8))
				fires.append({"pos": foot, "kind": "torch" if torch else "campfire", "flame": flame})
				lights.append(flame)
			"crystal", "ore":
				glinters.append(_bright_pixels(art.region, top_left))
			"tree", "bush":
				if prop.art in LEAFY:
					sources.append({"crown": crown_of(prop), "base_y": foot.y}.merged(_colors_of(prop.art, art.region)))
			"flower":
				flowers.append(foot + Vector2(0, -10))
		if prop.art == "rock_tree_crystal":
			glinters.append(_bright_pixels(Rect2i(art.region.position + Vector2i(0, 40), Vector2i(art.region.size.x, 24)), top_left + Vector2(0, 40)))
	# Homes: hearths and lamps glow (no smoke indoors), and their own life.
	for v in home_views:
		for r in v.hearths:
			fires.append({"pos": r.end, "kind": "hearth", "flame": r.get_center(), "radius": 30, "smoke": false})
			lights.append(r.get_center())
		for l in v.lamps:
			fires.append({"pos": l, "kind": "lamp", "flame": l, "radius": 14, "smoke": false})
	home_life.setup(home_views, actors, walker, false)
	fire.set_fires(fires)
	leaves.set_sources(sources)
	cave_life.setup(terrain.drip_spots(), lights, glinters)
	critters.walker = walker
	critters.setup(flowers, ponds, terrain.glow_cells())
	footsteps.dust_colors = _dust_colors()
	footsteps.setup_generic(_surface, water, walker)
	wildlife.setup_from(terrain.wildlife_plan(), water, actors, walker, _pixels, water_life)


## Mossy trees and bushes shed leaves; bare and dead ones do not.
const LEAFY := ["tree_mossy", "rock_tree_moss", "rock_tree_crystal", "bush", "bush_small"]


## Where a leafy prop's leaves let go, in world pixels.
static func crown_of(prop: Dictionary) -> Rect2:
	var art: Dictionary = CaveTerrain.PROPS[prop.art]
	var top_left := foot_of(prop) - Vector2(art.foot)
	var size := Vector2(art.region.size)
	return Rect2(top_left + Vector2(4, 2), Vector2(size.x - 8, size.y * 0.5))


func _dust_colors() -> Array:
	match terrain.recipe.floor:
		"dark":
			return [Color(0.5, 0.49, 0.5), Color(0.42, 0.42, 0.44)]
		"moss":
			return [Color(0.55, 0.57, 0.52), Color(0.46, 0.5, 0.44)]
	return [Color(0.6, 0.59, 0.57), Color(0.5, 0.5, 0.5)]


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
		return "none"
	var k := terrain.kind[cell.y * W + cell.x]
	if k != CaveTerrain.FLOOR and k != CaveTerrain.TERRACE and k != CaveTerrain.STAIR:
		return "none"
	if terrain.deco.has(cell):
		return "tuft"
	if terrain.recipe.floor == "moss" and k == CaveTerrain.FLOOR:
		return "grass"
	return "dust"


# The bright pixels of a crystal or ore sprite, in world pixels.
func _bright_pixels(region: Rect2i, top_left: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in region.size.y:
		for x in region.size.x:
			var p := _pixels.get_pixel(region.position.x + x, region.position.y + y)
			if p.a > 0.5 and p.get_luminance() > 0.62:
				out.append(Vector2i(top_left) + Vector2i(x, y))
	return out


# Leaf colors for a mossy tree or bush, from its sprite.
func _colors_of(key: String, region: Rect2i) -> Dictionary:
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	var counts := {}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var p := _pixels.get_pixel(x, y)
			if p.a < 0.5 or p.g <= p.r or p.g <= p.b:
				continue # only greens
			var k := p.to_rgba32()
			counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var light: Array[Color] = []
	var dark := Color(0.1, 0.22, 0.16)
	var darkest := 2.0
	for k in keys.slice(0, 8):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.35 and light.size() < 3:
			light.append(c)
	if light.is_empty():
		light.append(Color(0.45, 0.62, 0.35))
	_leaf_colors[key] = {"light": light, "dark": dark}
	return _leaf_colors[key]
