extends Node2D
## Paints a Mystic Woods map from the terrain.gd grid: grass on Ground,
## animated ponds on Water (water-sheet.png) with lily pads and rocks on
## WaterDeco, plains.png ids (dirt, cobblestone, plateau) on Features, decor on
## Deco, and y-sorted props, fences, roofless stone structures, and the player
## on Actors. Collision is one static body over cliff and water cells, fences,
## and a ring outside the map; props and structures carry their own.

const TILE := 16

const GRASS_TEX := preload("res://assets/pack/sprites/tilesets/grass.png")
const PLAINS_TEX := preload("res://assets/pack/sprites/tilesets/plains.png")
const DECOR_TEX := preload("res://assets/pack/sprites/tilesets/decor_16x16.png")
const OBJECTS_TEX := preload("res://assets/pack/sprites/objects/objects.png")
const WATER_TEX := preload("res://assets/pack/sprites/tilesets/water-sheet.png")
const WATER_DECO_TEX := preload("res://assets/pack/sprites/tilesets/water_decorations.png")
const FENCE_TEX := preload("res://assets/pack/sprites/tilesets/fences.png")
const WALLS_TEX := preload("res://assets/pack/sprites/tilesets/walls/walls.png")
const DOOR_TEX := preload("res://assets/pack/sprites/tilesets/walls/wooden_door.png")
const DOOR_B_TEX := preload("res://assets/pack/sprites/tilesets/walls/wooden_door_b.png")
const CHEST_TEX := {"chest_iron": preload("res://assets/pack/sprites/objects/chest_01.png"), "chest_gold": preload("res://assets/pack/sprites/objects/chest_02.png")}
const ROCK_WATER_TEX := preload("res://assets/pack/sprites/objects/rock_in_water_01-sheet.png")
const LILY_TEX := preload("res://assets/pack/sprites/tilesets/water_lillies.png")
const DUST_TEX := preload("res://assets/pack/sprites/particles/dust_particles_01.png")
const DETAIL_TEX := preload("res://assets/pack/sprites/tilesets/decor_8x8.png")
const FLOOR_TEX := {"wooden": preload("res://assets/pack/sprites/tilesets/floors/wooden.png"),
	"flooring": preload("res://assets/pack/sprites/tilesets/floors/flooring.png"),
	"carpet": preload("res://assets/pack/sprites/tilesets/floors/carpet.png")}
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SRC_GRASS := 0
const SRC_PLAINS := 1
const SRC_DECOR := 2
const SRC_WATER := 3
const SRC_WATER_DECO := 4
const SRC_FENCE := 5
const SRC_ROCK_ANIM := 6
const SRC_LILY_ANIM := 7
const SRC_FLOOR := {"wooden": 8, "flooring": 9, "carpet": 10}
const WATER_FRAMES := 6 # water-sheet.png: six frames, five cells apart
const WATER_FRAME_STEP := 5

# objects.png regions. `cell` is the region's top-left relative to the
# anchor tile, so every sprite lands on the grid. `base` is the foot pixel
# inside the region; it becomes the y-sort origin. `block` is the collider.
const PROP_ART := {
	"tree_a": {"region": Rect2i(0, 80, 48, 64), "cell": Vector2i(-1, -3), "base": Vector2i(23, 57), "block": Vector2(14, 6)},
	"tree_b": {"region": Rect2i(48, 80, 48, 64), "cell": Vector2i(-1, -3), "base": Vector2i(23, 57), "block": Vector2(14, 6)},
	"tree_c": {"region": Rect2i(0, 144, 48, 64), "cell": Vector2i(-1, -3), "base": Vector2i(24, 60), "block": Vector2(12, 5)},
	"tree_d": {"region": Rect2i(48, 144, 48, 64), "cell": Vector2i(-1, -3), "base": Vector2i(24, 60), "block": Vector2(12, 5)},
	"cypress": {"region": Rect2i(128, 96, 32, 48), "cell": Vector2i(-1, -2), "base": Vector2i(16, 45), "block": Vector2(10, 4)},
	"rock_0": {"region": Rect2i(0, 16, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(14, 7)},
	"rock_1": {"region": Rect2i(16, 16, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 13), "block": Vector2(14, 7)},
	"rock_2": {"region": Rect2i(32, 16, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(14, 7)},
	"sign": {"region": Rect2i(0, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(6, 4)},
	"basket": {"region": Rect2i(16, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"drawers": {"region": Rect2i(32, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(14, 6)},
	"barrel": {"region": Rect2i(48, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"pot": {"region": Rect2i(64, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(10, 5)},
	"crate": {"region": Rect2i(80, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(14, 6)},
	"grave": {"region": Rect2i(96, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 5)},
	"skull": {"region": Rect2i(112, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2.ZERO},
	"big_skull": {"region": Rect2i(128, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 5)},
	"table": {"region": Rect2i(160, 0, 32, 16), "cell": Vector2i.ZERO, "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"bench": {"region": Rect2i(48, 16, 32, 16), "cell": Vector2i.ZERO, "base": Vector2i(16, 15), "block": Vector2(28, 5)},
	"pit": {"region": Rect2i(128, 16, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"potted_tree": {"region": Rect2i(144, 32, 16, 32), "cell": Vector2i(0, -1), "base": Vector2i(8, 30), "block": Vector2(10, 5)},
	"pot_sprout": {"region": Rect2i(160, 32, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(10, 5)},
	"log": {"region": Rect2i(96, 96, 32, 16), "cell": Vector2i.ZERO, "base": Vector2i(16, 14), "block": Vector2(28, 6)},
	"log_flower": {"region": Rect2i(96, 80, 32, 16), "cell": Vector2i.ZERO, "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"long_log": {"region": Rect2i(96, 144, 48, 16), "cell": Vector2i.ZERO, "base": Vector2i(24, 14), "block": Vector2(44, 6)},
	"bush": {"region": Rect2i(96, 112, 32, 32), "cell": Vector2i(0, -1), "base": Vector2i(16, 31), "block": Vector2(26, 8)},
	"stump_a": {"region": Rect2i(160, 80, 32, 32), "cell": Vector2i(0, -1), "base": Vector2i(16, 29), "block": Vector2(18, 6)},
	"stump_b": {"region": Rect2i(160, 112, 32, 32), "cell": Vector2i(0, -1), "base": Vector2i(16, 25), "block": Vector2(18, 6)},
	"sapling_a": {"region": Rect2i(128, 80, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"sapling_b": {"region": Rect2i(144, 80, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"pot_empty": {"region": Rect2i(160, 48, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(10, 5)},
	"bed": {"region": Rect2i(176, 32, 16, 32), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2(14, 18)},
	"bookshelf": {"region": Rect2i(192, 32, 16, 32), "cell": Vector2i(0, -1), "base": Vector2i(8, 30), "block": Vector2(14, 6)},
	"stool": {"region": Rect2i(176, 64, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 11), "block": Vector2(10, 4)},
	"small_table": {"region": Rect2i(144, 0, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(14, 6)},
	"long_table": {"region": Rect2i(144, 16, 48, 16), "cell": Vector2i.ZERO, "base": Vector2i(24, 15), "block": Vector2(44, 6)},
	# Set on a table or the floor: they sort just after the table they sit on.
	"potion": {"region": Rect2i(144, 64, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 16), "block": Vector2.ZERO},
	"scroll": {"region": Rect2i(160, 64, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 16), "block": Vector2.ZERO},
	"heart": {"region": Rect2i(128, 32, 16, 16), "cell": Vector2i.ZERO, "base": Vector2i(8, 16), "block": Vector2.ZERO},
}

# Roofless stone structures from walls.png: the wall tops seen from above,
# with the brick face under them; a hut also has a door in its face.
# Regions are in walls.png pixels; the face sits right under the top.
const STRUCTURES := {
	"hut": {"top": Rect2i(16, 9, 48, 39), "face": Rect2i(16, 57, 48, 39), "cells": 3, "door": true},
	"pillar": {"top": Rect2i(0, 9, 16, 39), "face": Rect2i(0, 57, 16, 39), "cells": 1, "door": false},
	"arch": {"top": Rect2i(71, 9, 18, 23), "face": Rect2i(71, 64, 18, 32), "cells": 1, "door": false},
}

@export var map_seed := 21021
@export var include_water := true
## Recipe to build (terrain.gd RECIPES), or -1 for map_seed % recipe count.
## The fixed scenes use 0, the original clearing.
@export var recipe := 0
## Randomizer extras: 8 px detail, dirt spots, the liveliness floor, and the
## ambience (wind, leaves, streaks, cloud shadows, water life, critters,
## animals, footsteps, drifters, grass waves). The fixed scenes leave it off.
@export var enrich := false
@export var player_sheet: Texture2D = preload("res://assets/pack/sprites/characters/player.png")
@export var frame_size := 48

@onready var ground: TileMapLayer = $Ground
@onready var features_layer: TileMapLayer = $Features
@onready var deco_layer: TileMapLayer = $Deco
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain := MysticTerrain.new()
var report := ""
var water_layer: TileMapLayer
var water_deco_layer: TileMapLayer
var _tiles: TileSet
var wind: Wind
var fire: FireAmbience
var floors_layer: TileMapLayer
var rugs_layer: TileMapLayer
var detail_layer: TileMapLayer
var leaves: AmbientLeaves
var streaks: WindStreaks
var clouds: CloudShadows
var water_life: WaterLife
var critters: Critters
var footsteps: Footsteps
var drifters: Drifters
var grass_waves: GrassWaves
var wildlife: Wildlife
var _chests: Array[AnimatedSprite2D] = []
var _objects_image: Image
var _leaf_colors := {}


func _ready() -> void:
	_tiles = _build_tileset()
	water_layer = TileMapLayer.new()
	water_layer.name = "Water"
	add_child(water_layer)
	move_child(water_layer, ground.get_index() + 1)
	water_deco_layer = TileMapLayer.new()
	water_deco_layer.name = "WaterDeco"
	add_child(water_deco_layer)
	move_child(water_deco_layer, water_layer.get_index() + 1)
	floors_layer = TileMapLayer.new()
	floors_layer.name = "Floors"
	add_child(floors_layer)
	move_child(floors_layer, features_layer.get_index() + 1)
	rugs_layer = TileMapLayer.new()
	rugs_layer.name = "Rugs"
	add_child(rugs_layer)
	move_child(rugs_layer, floors_layer.get_index() + 1)
	detail_layer = TileMapLayer.new() # 8 px cells
	detail_layer.name = "Detail"
	add_child(detail_layer)
	move_child(detail_layer, rugs_layer.get_index() + 1)
	detail_layer.tile_set = _detail_tileset()
	for layer in [ground, features_layer, deco_layer, water_layer, water_deco_layer, floors_layer, rugs_layer]:
		layer.tile_set = _tiles
	_objects_image = OBJECTS_TEX.get_image()
	if _objects_image.is_compressed():
		_objects_image.decompress()
	# Fire pits glow and smoke (fire_ambience.gd, which follows the wind).
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	fire = FireAmbience.new()
	fire.name = "FireAmbience"
	fire.wind = wind
	add_child(fire)
	if enrich:
		_add_ambience()
	build(map_seed)


# Generates `id` and repaints every layer. Safe to call again to replace
# the current map (the randomizer's menu does).
func build(id: int) -> void:
	map_seed = id
	terrain = MysticTerrain.new()
	report = terrain.generate(map_seed, include_water, recipe, enrich)
	for layer in [ground, features_layer, deco_layer, water_layer, water_deco_layer, floors_layer, rugs_layer, detail_layer]:
		layer.clear()
	_chests.clear()
	for child in actors.get_children():
		actors.remove_child(child)
		child.queue_free()
	_paint()
	_paint_water()
	_paint_fences()
	_build_collision()
	_place_props()
	_spawn_player()
	var fires: Array[Dictionary] = []
	for c in terrain.fires:
		fires.append({"pos": Vector2(c * TILE) + Vector2(8, 14), "kind": "campfire"})
	fire.set_fires(fires)
	if enrich:
		_reset_ambience()
	print(report)


## For the randomizer menu: the recipe names, in recipe-id order.
func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in MysticTerrain.RECIPES:
		out.append(r.name)
	return out


## For the randomizer menu: {id, name, checks}.
func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": map_seed, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


func _build_tileset() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	tiles.add_source(_atlas(GRASS_TEX, [Vector2i.ZERO]), SRC_GRASS)
	tiles.add_source(_atlas(PLAINS_TEX, MysticTerrain.plains_cells()), SRC_PLAINS)
	tiles.add_source(_atlas(DECOR_TEX, MysticTerrain.TUFTS + MysticTerrain.FLOWERS + MysticTerrain.MUSHROOMS + MysticTerrain.STONES + MysticTerrain.DIRT_SPOTS), SRC_DECOR)
	# Animated things in the water: a rock with water lapping round it, and
	# a bobbing lily, six frames each in a row.
	for pair in [[ROCK_WATER_TEX, SRC_ROCK_ANIM, 0.18], [LILY_TEX, SRC_LILY_ANIM, 0.3]]:
		var anim := _atlas(pair[0], [Vector2i.ZERO])
		anim.set_tile_animation_frames_count(Vector2i.ZERO, 6)
		for f in 6:
			anim.set_tile_animation_frame_duration(Vector2i.ZERO, f, pair[2])
		anim.set_tile_animation_mode(Vector2i.ZERO, TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES)
		tiles.add_source(anim, pair[1])
	for sheet in FLOOR_TEX:
		var tex: Texture2D = FLOOR_TEX[sheet]
		var cells: Array[Vector2i] = []
		for y in tex.get_height() / TILE:
			for x in tex.get_width() / TILE:
				cells.append(Vector2i(x, y))
		tiles.add_source(_atlas(tex, cells), SRC_FLOOR[sheet])
	# Pond: the 3x3 bank-and-water block and the 2x2 island, each animated
	# through the sheet's six frames.
	var water_cells: Array[Vector2i] = []
	for y in 3:
		for x in 3:
			water_cells.append(Vector2i(x, y))
	for c in [Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 1), Vector2i(4, 1)]:
		water_cells.append(c)
	var water := _atlas(WATER_TEX, water_cells)
	for c in water_cells:
		water.set_tile_animation_columns(c, 0)
		water.set_tile_animation_separation(c, Vector2i(WATER_FRAME_STEP - 1, 0))
		water.set_tile_animation_frames_count(c, WATER_FRAMES)
		for f in WATER_FRAMES:
			water.set_tile_animation_frame_duration(c, f, 0.2)
	tiles.add_source(water, SRC_WATER)
	tiles.add_source(_atlas(WATER_DECO_TEX, MysticTerrain.WATER_ROCKS + MysticTerrain.LILIES), SRC_WATER_DECO)
	var fence_cells: Array[Vector2i] = []
	for y in 4:
		for x in 4:
			fence_cells.append(Vector2i(x, y))
	var fences := _atlas(FENCE_TEX, fence_cells)
	for c in fence_cells:
		fences.get_tile_data(c, 0).y_sort_origin = 12 # posts sort near their foot
	tiles.add_source(fences, SRC_FENCE)
	return tiles


func _atlas(texture: Texture2D, cells: Array[Vector2i]) -> TileSetAtlasSource:
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	for c in cells:
		source.create_tile(c)
	return source


func _paint() -> void:
	for y in MysticTerrain.HEIGHT:
		for x in MysticTerrain.WIDTH:
			ground.set_cell(Vector2i(x, y), SRC_GRASS, Vector2i.ZERO)
	for cell in terrain.features:
		features_layer.set_cell(cell, SRC_PLAINS, terrain.features[cell])
	for cell in terrain.deco:
		deco_layer.set_cell(cell, SRC_DECOR, terrain.deco[cell])


# One rectangle per horizontal run of cliff or water, then four walls
# just outside the map.
func _build_collision() -> void:
	for child in collision.get_children():
		collision.remove_child(child)
		child.queue_free()
	for y in MysticTerrain.HEIGHT:
		var x := 0
		while x < MysticTerrain.WIDTH:
			if not _blocked(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < MysticTerrain.WIDTH and _blocked(Vector2i(x, y)):
				x += 1
			_add_box(Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
	for c in terrain.fence:
		_add_box(Rect2(Vector2(c * TILE) + Vector2(1, 8), Vector2(TILE - 2, 7)))
	var w := MysticTerrain.WIDTH * TILE
	var h := MysticTerrain.HEIGHT * TILE
	_add_box(Rect2(-TILE, -TILE, w + 2 * TILE, TILE))
	_add_box(Rect2(-TILE, h, w + 2 * TILE, TILE))
	_add_box(Rect2(-TILE, 0, TILE, h))
	_add_box(Rect2(w, 0, TILE, h))


# Each pond rectangle: bank on the rim, open water inside, islands on top.
func _paint_water() -> void:
	for r in terrain.ponds:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var role := Vector2i(0 if x == r.position.x else (2 if x == r.end.x - 1 else 1),
					0 if y == r.position.y else (2 if y == r.end.y - 1 else 1))
				water_layer.set_cell(Vector2i(x, y), SRC_WATER, role)
	for at in terrain.islands:
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			water_layer.set_cell(at + o, SRC_WATER, Vector2i(3, 0) + o)
	for c in terrain.water_deco:
		water_deco_layer.set_cell(c, SRC_WATER_DECO, terrain.water_deco[c])
	for c in terrain.water_anim:
		water_deco_layer.set_cell(c, SRC_ROCK_ANIM if terrain.water_anim[c] == "rock" else SRC_LILY_ANIM, Vector2i.ZERO)
	for c in terrain.floors:
		var f: Array = terrain.floors[c]
		floors_layer.set_cell(c, SRC_FLOOR[f[0]], f[1])
	for c in terrain.rugs:
		var f: Array = terrain.rugs[c]
		rugs_layer.set_cell(c, SRC_FLOOR[f[0]], f[1])
	for c in terrain.detail:
		detail_layer.set_cell(c, 0, terrain.detail[c])


func _detail_tileset() -> TileSet:
	var t := TileSet.new()
	t.tile_size = Vector2i(8, 8)
	var src := TileSetAtlasSource.new()
	src.texture = DETAIL_TEX
	src.texture_region_size = Vector2i(8, 8)
	for y in 4:
		for x in 4:
			src.create_tile(Vector2i(x, y))
	t.add_source(src, 0)
	return t


# fences.png is a 4x4 autotile: the column says which way the rail runs
# sideways (none, east, both, west), the row which way it runs up and down
# (south, both, north, none). The layer lives in Actors so posts y-sort.
func _paint_fences() -> void:
	if terrain.fence.is_empty():
		return
	var layer := TileMapLayer.new()
	layer.name = "Fences"
	layer.tile_set = _tiles
	layer.y_sort_enabled = true
	actors.add_child(layer)
	for c in terrain.fence:
		var e: bool = terrain.fence.has(c + Vector2i.RIGHT)
		var w: bool = terrain.fence.has(c + Vector2i.LEFT)
		var n: bool = terrain.fence.has(c + Vector2i.UP)
		var s: bool = terrain.fence.has(c + Vector2i.DOWN)
		var col := 2 if e and w else (1 if e else (3 if w else 0))
		var row := 1 if n and s else (0 if s else (2 if n else 3))
		layer.set_cell(c, SRC_FENCE, Vector2i(col, row))


func _blocked(cell: Vector2i) -> bool:
	var k := terrain.kind_at(cell)
	return k == MysticTerrain.CLIFF or k == MysticTerrain.WATER


func _add_box(rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = rect.get_center()
	collision.add_child(node)


func _place_props() -> void:
	for prop in terrain.props:
		if STRUCTURES.has(prop.art):
			_place_structure(prop)
			continue
		if CHEST_TEX.has(prop.art):
			_place_chest(prop)
			continue
		var art: Dictionary = PROP_ART[prop.art]
		var origin: Vector2i = (prop.cell + art.cell) * TILE
		var body := StaticBody2D.new()
		body.name = "%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y]
		body.position = Vector2(origin + art.base)
		body.collision_layer = 1
		body.collision_mask = 0
		var sprite := Sprite2D.new()
		sprite.texture = OBJECTS_TEX
		sprite.region_enabled = true
		sprite.region_rect = Rect2(art.region)
		sprite.centered = false
		sprite.offset = -Vector2(art.base)
		body.add_child(sprite)
		if art.block == Vector2.ZERO:
			actors.add_child(body)
			continue
		var shape := RectangleShape2D.new()
		shape.size = art.block
		var box := CollisionShape2D.new()
		box.shape = shape
		box.position = Vector2(0, -art.block.y / 2.0)
		body.add_child(box)
		actors.add_child(body)


# A structure stands on its anchor (bottom-left) cell: the brick face ends
# two pixels above the cell's bottom and the wall tops sit right on it. It
# sorts at the face's foot and blocks its whole footprint.
func _place_structure(prop: Dictionary) -> void:
	var art: Dictionary = STRUCTURES[prop.art]
	var width: int = art.cells * TILE
	var body := StaticBody2D.new()
	body.name = "%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y]
	body.position = Vector2(prop.cell.x * TILE, prop.cell.y * TILE + TILE - 2)
	body.collision_mask = 0
	var face: Rect2i = art.face
	var top: Rect2i = art.top
	var x := (width - face.size.x) / 2.0
	body.add_child(_walls_sprite(face, Vector2(x, -face.size.y)))
	body.add_child(_walls_sprite(top, Vector2((width - top.size.x) / 2.0, -face.size.y - top.size.y)))
	if art.door:
		# One of the pack's four doors (two styles, shut or ajar), by cell.
		var pick := posmod(prop.cell.x * 7 + prop.cell.y * 3, 4)
		var door := Sprite2D.new()
		door.texture = DOOR_TEX if pick < 2 else DOOR_B_TEX
		door.region_enabled = true
		door.region_rect = Rect2((pick % 2) * 16, 0, 16, 16)
		door.centered = false
		door.offset = Vector2(width / 2.0 - 8, -16)
		body.add_child(door)
	var tall := face.size.y + top.size.y
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, tall - 8)
	var box := CollisionShape2D.new()
	box.shape = shape
	box.position = Vector2(width / 2.0, -(tall - 8) / 2.0)
	body.add_child(box)
	actors.add_child(body)


# A chest (four frames, shut to open) that opens when the player comes near.
func _place_chest(prop: Dictionary) -> void:
	var body := StaticBody2D.new()
	body.name = "%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y]
	body.position = Vector2(prop.cell * TILE) + Vector2(8, 15)
	body.collision_mask = 0
	var frames := SpriteFrames.new()
	frames.set_animation_loop("default", false)
	frames.set_animation_speed("default", 10.0)
	for i in 4:
		var tex := AtlasTexture.new()
		tex.atlas = CHEST_TEX[prop.art]
		tex.region = Rect2(i * 16, 0, 16, 16)
		frames.add_frame("default", tex)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.centered = false
	sprite.offset = Vector2(-8, -15)
	body.add_child(sprite)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 6)
	var box := CollisionShape2D.new()
	box.shape = shape
	box.position = Vector2(0, -3)
	body.add_child(box)
	actors.add_child(body)
	_chests.append(sprite)


func _process(_delta: float) -> void:
	var player := actors.get_node_or_null("Player")
	if player == null:
		return
	for chest in _chests:
		if is_instance_valid(chest) and chest.frame == 0 and not chest.is_playing() \
				and chest.global_position.distance_to(player.global_position) < 24.0:
			chest.play("default")


func _walls_sprite(region: Rect2i, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = WALLS_TEX
	sprite.region_enabled = true
	sprite.region_rect = Rect2(region)
	sprite.centered = false
	sprite.offset = offset
	return sprite


func _spawn_player() -> void:
	var player := PLAYER_SCENE.instantiate()
	player.sheet = player_sheet
	player.frame_size = frame_size
	player.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE / 2.0)
	actors.add_child(player)
	var camera: Camera2D = player.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MysticTerrain.WIDTH * TILE
	camera.limit_bottom = MysticTerrain.HEIGHT * TILE


# ---------------------------------------------------------------- ambience
# The Painted Lands liveliness, with this pack's colors: one wind, leaves from
# the tree crowns, wind streaks, cloud shadows, ripples and fish on the ponds,
# butterflies and dragonflies and fireflies, small animals, footsteps (dust
# puffs from dust_particles_01.png), wind-borne seeds and birds, grass waves.

func _add_ambience() -> void:
	streaks = WindStreaks.new()
	grass_waves = GrassWaves.new()
	grass_waves.tip = Color(0.6, 0.84, 0.58) # lighter than the meadow (80, 155, 102)
	water_life = WaterLife.new()
	water_life.ring_color = Color(0.2, 0.4, 0.6) # deeper than the water (77, 138, 179)
	water_life.ring_highlight = Color(0.86, 0.94, 1.0)
	water_life.drop_color = Color(0.3, 0.5, 0.7)
	footsteps = Footsteps.new()
	footsteps.dust_sheet = DUST_TEX
	critters = Critters.new()
	drifters = Drifters.new()
	wildlife = Wildlife.new()
	leaves = AmbientLeaves.new()
	clouds = CloudShadows.new()
	clouds.shade = Color(17.0 / 255.0, 69.0 / 255.0, 23.0 / 255.0, 0.16) # the darkest leaf green
	for n in [streaks, grass_waves, water_life]:
		add_child(n)
		move_child(n, actors.get_index()) # under the y-sorted actors
	for n in [footsteps, critters, drifters, wildlife, leaves, clouds]:
		add_child(n)
	for n in [streaks, grass_waves, water_life, footsteps, critters, drifters, leaves, clouds]:
		n.wind = wind
	footsteps.water_life = water_life
	footsteps.leaves = leaves


func _reset_ambience() -> void:
	var map_rect := Rect2(0, 0, MysticTerrain.WIDTH * TILE, MysticTerrain.HEIGHT * TILE)
	streaks.bounds = map_rect
	clouds.reset(map_rect)
	var player := actors.get_node_or_null("Player")
	var water := {}
	var open: Array[Vector2i] = []
	var ponds: Array[Rect2] = []
	for r in terrain.ponds:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16)))
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				water[Vector2i(x, y)] = true
				if r.grow(-1).has_point(Vector2i(x, y)) and not terrain._on_island(Vector2i(x, y)):
					open.append(Vector2i(x, y))
	water_life.setup(open, [] as Array[Sprite2D])
	# Leaves from every tree crown.
	var sources: Array[Dictionary] = []
	var trunks: Array[Vector2i] = []
	for prop in terrain.props:
		if not (prop.art in MysticTerrain.TREES or prop.art == "cypress"):
			continue
		var art: Dictionary = PROP_ART[prop.art]
		var top_left := Vector2((prop.cell + art.cell) * TILE)
		var size := Vector2(art.region.size)
		trunks.append(prop.cell)
		sources.append({"crown": Rect2(top_left + Vector2(4, 2), Vector2(size.x - 8, size.y * 0.55)),
			"base_y": top_left.y + art.base.y}.merged(_colors_of(prop.art, art.region)))
	leaves.set_sources(sources)
	var flowers: Array[Vector2] = []
	var dark: Array[Vector2] = []
	var grass := {}
	for y in MysticTerrain.HEIGHT:
		for x in MysticTerrain.WIDTH:
			var c := Vector2i(x, y)
			if terrain.kind_at(c) != MysticTerrain.GRASS or terrain.floors.has(c):
				continue
			if terrain.deco.has(c) and terrain.deco[c] in MysticTerrain.FLOWERS:
				flowers.append(Vector2(c) * TILE + Vector2(8, 8))
			if not terrain._occupied.has(c) or terrain.deco.has(c):
				grass[c] = true
	# Fireflies keep to the shade: cells with trees close on two sides.
	for c in grass:
		var near := 0
		for t in trunks:
			if absi(t.x - c.x) <= 3 and absi(t.y - c.y) <= 3:
				near += 1
		if near >= 2 or terrain.recipe.piece == "hollow":
			dark.append(Vector2(c) * TILE + Vector2(8, 8))
	critters.walker = player
	critters.setup(flowers, ponds, dark)
	drifters.setup(map_rect, flowers)
	grass_waves.setup(grass)
	footsteps.setup_generic(_surface, water, player)
	var habitats := _habitats(grass, water, trunks)
	var quiet_sources: Array[Vector2i] = []
	quiet_sources.append_array(water.keys())
	quiet_sources.append_array(terrain.fires)
	quiet_sources.append_array(trunks)
	var plan := Wildlife.plan_from(habitats, map_seed, terrain.spawn,
		Wildlife.quiet_from(quiet_sources, MysticTerrain.WIDTH, MysticTerrain.HEIGHT))
	wildlife.setup_from(plan, water, actors, player, _objects_image, water_life)


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= MysticTerrain.WIDTH or cell.y >= MysticTerrain.HEIGHT or terrain.floors.has(cell):
		return "none"
	var k := terrain.kind_at(cell)
	if k == MysticTerrain.DIRT or k == MysticTerrain.COBBLE:
		return "dust"
	if k == MysticTerrain.GRASS:
		return "tuft" if terrain.deco.has(cell) else "grass"
	return "none"


# The wildlife habitats (wildlife.gd habitat_cells() keys) for this map.
func _habitats(grass: Dictionary, water: Dictionary, trunks: Array[Vector2i]) -> Dictionary:
	var land := {}
	for y in MysticTerrain.HEIGHT:
		for x in MysticTerrain.WIDTH:
			var c := Vector2i(x, y)
			var k := terrain.kind_at(c)
			if (k == MysticTerrain.GRASS or k == MysticTerrain.DIRT or k == MysticTerrain.COBBLE) and not terrain.blocked.has(c) and not c in trunks:
				land[c] = true
	var near := func(c: Vector2i, cells: Array, r: int) -> bool:
		for o in cells:
			if absi(o.x - c.x) <= r and absi(o.y - c.y) <= r:
				return true
		return false
	var clutter: Array = []
	var bushes: Array = []
	var rocks: Array = []
	for p in terrain.props:
		if p.art in ["log", "log_flower", "long_log", "crate", "barrel", "basket", "sign", "stump_a", "stump_b", "pot", "drawers"]:
			clutter.append(p.cell)
		elif p.art == "bush":
			bushes.append(p.cell)
		elif p.art in ["rock_0", "rock_1", "rock_2", "hut", "pillar", "arch", "grave"]:
			rocks.append(p.cell)
	clutter.append_array(terrain.fence.keys())
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	for c in land:
		var wet := false
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if water.has(c + d):
				wet = true
		if wet:
			h.shore[c] = true
		var is_grass: bool = grass.has(c)
		var by_water: bool = near.call(c, water.keys(), 2)
		if is_grass and not by_water:
			h.lawn[c] = true
			h.roam[c] = true
		if near.call(c, trunks, 2):
			h.trees[c] = true
		if is_grass and near.call(c, trunks, 3) and terrain.recipe.piece == "hollow":
			h.dark[c] = true
		if near.call(c, clutter, 2):
			h.clutter[c] = true
		if near.call(c, bushes, 2):
			h.bushes[c] = true
		if near.call(c, rocks, 2) or terrain.kind_at(c) == MysticTerrain.COBBLE:
			h.rocky[c] = true
		var below: Vector2i = c + Vector2i(0, 1)
		var path_below: bool = below.y < MysticTerrain.HEIGHT and terrain.kind_at(below) in [MysticTerrain.DIRT, MysticTerrain.COBBLE]
		if is_grass and not wet and (path_below or near.call(c, terrain.fence.keys(), 2)):
			h.open[c] = true
	for r in terrain.ponds:
		for y in range(r.position.y + 1, r.end.y - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				if not terrain._on_island(Vector2i(x, y)):
					h.water[Vector2i(x, y)] = true
	h["_land"] = land
	var trunk_set := {}
	for t in trunks:
		trunk_set[t] = true
	h["_trunks"] = trunk_set
	h["_w"] = MysticTerrain.WIDTH
	return h


# Leaf colors for a tree, from its sprite: the brightest common foliage colors
# that stand off the meadow, and the darkest for the leaf's edge.
func _colors_of(key: String, region: Rect2i) -> Dictionary:
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	var lawn := Color8(80, 155, 102)
	var counts := {}
	for y in range(region.position.y, region.position.y + region.size.y / 2):
		for x in range(region.position.x, region.end.x):
			var p := _objects_image.get_pixel(x, y)
			if p.a < 0.5 or (p.r > p.g and p.get_luminance() < 0.5):
				continue
			counts[p.to_rgba32()] = counts.get(p.to_rgba32(), 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var light: Array[Color] = []
	var dark := Color8(17, 69, 23)
	var darkest := 2.0
	for k in keys.slice(0, 10):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.3 and absf(c.r - lawn.r) + absf(c.g - lawn.g) + absf(c.b - lawn.b) > 0.12:
			light.append(c)
	if light.is_empty():
		light.append(Color8(83, 160, 59))
	_leaf_colors[key] = {"light": light.slice(0, 3), "dark": dark}
	return _leaf_colors[key]
