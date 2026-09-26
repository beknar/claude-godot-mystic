extends Node2D
## Paints a Mystic Woods map from the terrain.gd grid: grass on Ground,
## plains.png ids on Features, decor on Deco, y-sorted props and the player
## on Actors. Collision is one static body over cliff and water cells plus
## a ring outside the map.

const TILE := 16

const GRASS_TEX := preload("res://assets/pack/sprites/tilesets/grass.png")
const PLAINS_TEX := preload("res://assets/pack/sprites/tilesets/plains.png")
const DECOR_TEX := preload("res://assets/pack/sprites/tilesets/decor_16x16.png")
const OBJECTS_TEX := preload("res://assets/pack/sprites/objects/objects.png")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")

const SRC_GRASS := 0
const SRC_PLAINS := 1
const SRC_DECOR := 2

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
}

@export var map_seed := 21021
@export var include_water := true
@export var player_sheet: Texture2D = preload("res://assets/pack/sprites/characters/player.png")
@export var frame_size := 48

@onready var ground: TileMapLayer = $Ground
@onready var features_layer: TileMapLayer = $Features
@onready var deco_layer: TileMapLayer = $Deco
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain := MysticTerrain.new()


func _ready() -> void:
	var report := terrain.generate(map_seed, include_water)
	var tiles := _build_tileset()
	for layer in [ground, features_layer, deco_layer]:
		layer.tile_set = tiles
		layer.clear()
	_paint()
	_build_collision()
	_place_props()
	_spawn_player()
	print(report)


func _build_tileset() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	tiles.add_source(_atlas(GRASS_TEX, [Vector2i.ZERO]), SRC_GRASS)
	tiles.add_source(_atlas(PLAINS_TEX, MysticTerrain.plains_cells()), SRC_PLAINS)
	tiles.add_source(_atlas(DECOR_TEX, MysticTerrain.TUFTS + MysticTerrain.FLOWERS), SRC_DECOR)
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
	var w := MysticTerrain.WIDTH * TILE
	var h := MysticTerrain.HEIGHT * TILE
	_add_box(Rect2(-TILE, -TILE, w + 2 * TILE, TILE))
	_add_box(Rect2(-TILE, h, w + 2 * TILE, TILE))
	_add_box(Rect2(-TILE, 0, TILE, h))
	_add_box(Rect2(w, 0, TILE, h))


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
		var shape := RectangleShape2D.new()
		shape.size = art.block
		var box := CollisionShape2D.new()
		box.shape = shape
		box.position = Vector2(0, -art.block.y / 2.0)
		body.add_child(box)
		actors.add_child(body)


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
