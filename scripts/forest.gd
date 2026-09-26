extends Node2D
## Paints a Painted Lands map from forest_terrain.gd: lawn on Ground, cobble
## path, fence, and Mode A dirt islands on Features, Mode B islands as
## halo sprites on Patches, grass deco on Deco, and y-sorted houses, props,
## and the walker on Actors.

const TILE := 16
const SHEET := preload("res://assets/pack/TILESET_brighter.png")
const SWAY_SHADER := preload("res://shaders/flower_sway.gdshader")
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const SOURCE := 0
const FLIP := 1 # alternative tile id for horizontally flipped cells
# Ridge collider around the wall's base (the bottom of the rock cell): it
# reaches 13 px up into the rock, so a character behind the wall shows only
# its head, and 8 px down into the lower rim, so one in front stops with
# about half its body over the wall face.
const RIDGE_BASE_TOP := 13
const RIDGE_FRONT := 8

@export var map_id := 91003
## Pins the recipe (-1: map_id % recipe count). The fixed scenes pin theirs
## so adding recipes never changes them.
@export var recipe := -1

@onready var ground: TileMapLayer = $Ground
@onready var features_layer: TileMapLayer = $Features
@onready var patches: Node2D = $Patches
@onready var deco_layer: TileMapLayer = $Deco
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: PaintedTerrain
var tone_layers: Array[TileMapLayer] = []
var accent_layer: TileMapLayer
var sway_layer: TileMapLayer # flowers that move in the wind
var report := ""
var _atlas: TileSetAtlasSource
var _pixels: Image


func _ready() -> void:
	_pixels = SHEET.get_image()
	if _pixels.is_compressed():
		_pixels.decompress()
	var tiles := _build_tileset()
	# One layer per grass tone, stacked between the lawn and the features.
	for i in PaintedTerrain.TONES.size():
		var layer := TileMapLayer.new()
		layer.name = "Tone_%s" % PaintedTerrain.TONES[i].name
		add_child(layer)
		move_child(layer, ground.get_index() + 1 + i)
		tone_layers.append(layer)
	# Grass accents sit on the tones, under the features.
	accent_layer = TileMapLayer.new()
	accent_layer.name = "Accents"
	add_child(accent_layer)
	move_child(accent_layer, tone_layers[-1].get_index() + 1)
	sway_layer = TileMapLayer.new()
	sway_layer.name = "DecoSway"
	var sway_material := ShaderMaterial.new()
	sway_material.shader = SWAY_SHADER
	sway_material.set_shader_parameter("art_rows", _art_rows())
	sway_layer.material = sway_material
	add_child(sway_layer)
	move_child(sway_layer, deco_layer.get_index() + 1)
	for layer in [ground, features_layer, deco_layer, accent_layer, sway_layer] + tone_layers:
		layer.tile_set = tiles
	build(map_id, recipe)


# Generates `id` and repaints every layer. Safe to call again to replace
# the current map.
func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = PaintedTerrain.new()
	report = terrain.generate(map_id, recipe)
	for layer in [ground, features_layer, deco_layer, accent_layer, sway_layer] + tone_layers:
		layer.clear()
	for node in [patches, actors, collision]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_paint()
	_paint_patches()
	_build_collision()
	_place_houses()
	_place_ridges()
	_place_props()
	_spawn_walker()
	print(report)


# One texel per atlas cell: R = first row with art, G = last row with art.
# The sway shader leans each flower from its own base to its own top.
func _art_rows() -> ImageTexture:
	var cols := _pixels.get_width() / TILE
	var rows := _pixels.get_height() / TILE
	var img := Image.create(cols, rows, false, Image.FORMAT_RGBA8)
	for cy in rows:
		for cx in cols:
			var first := TILE - 1
			var last := 0
			for y in TILE:
				for x in TILE:
					if _pixels.get_pixel(cx * TILE + x, cy * TILE + y).a > 0.0:
						first = mini(first, y)
						last = maxi(last, y)
						break
			img.set_pixel(cx, cy, Color8(first, last, 0, 255))
	return ImageTexture.create_from_image(img)


func _build_tileset() -> TileSet:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(TILE, TILE)
	_atlas = TileSetAtlasSource.new()
	_atlas.texture = SHEET
	_atlas.texture_region_size = Vector2i(TILE, TILE)
	tiles.add_source(_atlas, SOURCE)
	return tiles


func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i, flip := false, alt_id := -1) -> void:
	if not _atlas.has_tile(atlas):
		_atlas.create_tile(atlas)
		var anim := PaintedTerrain.animation_for(atlas)
		if not anim.is_empty():
			_atlas.set_tile_animation_separation(atlas, Vector2i(anim.step - 1, 0))
			_atlas.set_tile_animation_frames_count(atlas, anim.frames)
			for i in anim.frames:
				_atlas.set_tile_animation_frame_duration(atlas, i, anim.duration)
			if anim.random:
				_atlas.set_tile_animation_mode(atlas, TileSetAtlasSource.TILE_ANIMATION_MODE_RANDOM_START_TIMES)
	var alt := FLIP if flip else maxi(alt_id, 0)
	if alt != 0 and not _atlas.has_alternative_tile(atlas, alt):
		_atlas.create_alternative_tile(atlas, alt)
		var data := _atlas.get_tile_data(atlas, alt)
		data.flip_h = alt == PaintedTerrain.FLIP_H
		data.flip_v = alt == PaintedTerrain.FLIP_V
	layer.set_cell(cell, SOURCE, atlas, alt)


func _paint() -> void:
	for cell in terrain.lawn:
		_put(ground, cell, terrain.lawn[cell])
	for level in terrain.tones.size():
		var cells: Dictionary = terrain.tones[level]
		for cell in cells:
			_put(tone_layers[level], cell, cells[cell].atlas, false, cells[cell].alt)
	_paint_tone_edges()
	for cell in terrain.features:
		_put(features_layer, cell, terrain.features[cell])
	for cell in terrain.fence:
		_put(features_layer, cell, terrain.fence[cell].atlas, terrain.fence[cell].flip)
	for cell in terrain.hedge:
		_put(features_layer, cell, terrain.hedge[cell])
	for cell in terrain.canopy:
		_put(features_layer, cell, terrain.canopy[cell])
	for cell in terrain.accents:
		_put(accent_layer, cell, terrain.accents[cell])
	for blob in terrain.blobs:
		if blob.mode != "B":
			# Mode A: the dirt set whose grass is transparent, so the ground
			# under each cell shows through. Modes M and D: the set whose baked
			# grass is the zone's own tone. None of them adds a second green.
			for cell in blob.tiles:
				_put(features_layer, cell, blob.tiles[cell])
	for cell in terrain.deco:
		_put(sway_layer if terrain.sway.has(cell) else deco_layer, cell, terrain.deco[cell])


# Edge cells of a grass tone zone, drawn per pixel from the zone's own fill
# tile wherever the terrain's tone mask is set. One overlay per level sits
# right above that level's tile layer.
func _paint_tone_edges() -> void:
	var masks := terrain.tone_masks()
	var width := PaintedTerrain.WIDTH * TILE
	for level in masks.size():
		var layer := tone_layers[level]
		for child in layer.get_children():
			layer.remove_child(child)
			child.queue_free()
		var edges: Dictionary = terrain.tone_edges[level]
		if edges.is_empty():
			continue
		var mask: PackedByteArray = masks[level]
		var out := Image.create(width, PaintedTerrain.HEIGHT * TILE, false, Image.FORMAT_RGBA8)
		for cell in edges:
			var src: Vector2i = edges[cell] * TILE
			for y in TILE:
				var row: int = (cell.y * TILE + y) * width + cell.x * TILE
				for x in TILE:
					if mask[row + x]:
						out.set_pixel(cell.x * TILE + x, cell.y * TILE + y, _pixels.get_pixel(src.x + x, src.y + y))
		var sprite := Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(out)
		sprite.centered = false
		layer.add_child(sprite)


# Mode B: keep the baked darker green only inside a lumpy halo around the
# dirt, never as the tile rectangle. The halo is the dirt mask dilated 2-4 px
# with a one-octave noise wobble, limited to the blob cells plus one ring,
# with part of its rim left open so the lawn speckle mixes in.
func _paint_patches() -> void:
	var index := 0
	for blob in terrain.blobs:
		index += 1
		if blob.mode != "B":
			continue
		var area: Rect2i = blob.rect.grow(1)
		var size := area.size * TILE
		var dirt := PackedByteArray()
		dirt.resize(size.x * size.y)
		var out := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
		for cell in blob.tiles:
			var mask_cell: Vector2i = blob.tiles[cell] * TILE
			var baked_cell: Vector2i = blob.baked[cell] * TILE
			var at: Vector2i = (cell - area.position) * TILE
			for y in TILE:
				for x in TILE:
					if _pixels.get_pixel(mask_cell.x + x, mask_cell.y + y).a > 0.5:
						dirt[(at.y + y) * size.x + at.x + x] = 1
						out.set_pixel(at.x + x, at.y + y, _pixels.get_pixel(baked_cell.x + x, baked_cell.y + y))
		var dist := _chamfer(dirt, size)
		var salt := terrain.map_id + index * 131
		for y in size.y:
			for x in size.x:
				var i := y * size.x + x
				if dirt[i]:
					continue
				var reach := 2.0 + 2.0 * _smooth_noise(x / 5.0, y / 5.0, salt)
				var d := dist[i] / 3.0
				if d > reach:
					continue
				if d > reach - 1.5 and _hash(x, y, salt) < 0.4:
					continue # rim: let the lawn speckle through
				out.set_pixel(x, y, _halo_green(blob, area, x, y))
		var sprite := Sprite2D.new()
		sprite.texture = ImageTexture.create_from_image(out)
		sprite.centered = false
		sprite.position = Vector2(area.position * TILE)
		patches.add_child(sprite)


# Darker green from the baked PATCH cell when it has green at that pixel,
# otherwise from the matching mid-green lawn cell (4, 0).
func _halo_green(blob: Dictionary, area: Rect2i, x: int, y: int) -> Color:
	var cell := area.position + Vector2i(x / TILE, y / TILE)
	if blob.baked.has(cell):
		var p := _pixels.get_pixel(blob.baked[cell].x * TILE + x % TILE, blob.baked[cell].y * TILE + y % TILE)
		if p.g > p.r + 0.05:
			return p
	return _pixels.get_pixel(4 * TILE + x % TILE, y % TILE)


# 3-4 chamfer distance to the nearest dirt pixel (units of 1/3 px).
func _chamfer(mask: PackedByteArray, size: Vector2i) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(size.x * size.y)
	for i in d.size():
		d[i] = 0 if mask[i] else 99999
	for y in size.y:
		for x in size.x:
			var i := y * size.x + x
			if x > 0: d[i] = mini(d[i], d[i - 1] + 3)
			if y > 0:
				d[i] = mini(d[i], d[i - size.x] + 3)
				if x > 0: d[i] = mini(d[i], d[i - size.x - 1] + 4)
				if x < size.x - 1: d[i] = mini(d[i], d[i - size.x + 1] + 4)
	for y in range(size.y - 1, -1, -1):
		for x in range(size.x - 1, -1, -1):
			var i := y * size.x + x
			if x < size.x - 1: d[i] = mini(d[i], d[i + 1] + 3)
			if y < size.y - 1:
				d[i] = mini(d[i], d[i + size.x] + 3)
				if x < size.x - 1: d[i] = mini(d[i], d[i + size.x + 1] + 4)
				if x > 0: d[i] = mini(d[i], d[i + size.x - 1] + 4)
	return d


func _build_collision() -> void:
	# Water and plateau: one rectangle per horizontal run.
	for y in PaintedTerrain.HEIGHT:
		var x := 0
		while x < PaintedTerrain.WIDTH:
			if not _solid_ground(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < PaintedTerrain.WIDTH and _solid_ground(Vector2i(x, y)):
				x += 1
			_add_box(collision, Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
	for cell in terrain.fence:
		_add_box(collision, Rect2(Vector2(cell * TILE) + Vector2(0, 8), Vector2(TILE, 8)))
	var w := PaintedTerrain.WIDTH * TILE
	var h := PaintedTerrain.HEIGHT * TILE
	_add_box(collision, Rect2(-TILE, -TILE, w + 2 * TILE, TILE))
	_add_box(collision, Rect2(-TILE, h, w + 2 * TILE, TILE))
	_add_box(collision, Rect2(-TILE, 0, TILE, h))
	_add_box(collision, Rect2(w, 0, TILE, h))


# Each prefab splits into HOUSE_ROOF (no collision, sorted at the eave) and
# HOUSE_BODY (walls, door, porch; collides; sorted at the doorstep).
func _place_houses() -> void:
	for house in terrain.houses:
		var art: Dictionary = PaintedTerrain.HOUSES[house.id]
		var region: Rect2i = art.region
		var origin := Vector2(house.origin * TILE)
		var eave: int = art.roof_rows * TILE

		var roof := Node2D.new()
		roof.name = "HOUSE_ROOF_%d" % house.id
		roof.position = origin + Vector2(0, eave)
		roof.add_child(_region_sprite(Rect2(Vector2(region.position), Vector2(region.size.x, eave)), Vector2(0, -eave)))
		actors.add_child(roof)

		var body := StaticBody2D.new()
		body.name = "HOUSE_BODY_%d" % house.id
		body.collision_mask = 0
		body.position = origin + Vector2(0, region.size.y)
		body.add_child(_region_sprite(
			Rect2(Vector2(region.position + Vector2i(0, eave)), Vector2(region.size.x, region.size.y - eave)),
			Vector2(0, eave - region.size.y)))
		for block in art.blocks:
			_add_box(body, Rect2(Vector2(block.position) - Vector2(0, region.size.y), Vector2(block.size)))
		# Loose door and windows hung on the wall (the barn).
		for overlay in art.get("overlays", []):
			var sprite := _region_sprite(Rect2(overlay.src), Vector2(overlay.at) - Vector2(0, region.size.y))
			body.add_child(sprite)
		actors.add_child(body)


# A ridge is an upright wall: rim and rock are its face, the bottom of the
# rock its base. Both cells stay in the tilemap and also get a y-sorted
# overlay (the two cells with their baked ground cut away) sorted at the
# base, so a character standing right behind the wall is covered up to the
# rim and only its head shows, and one in front is drawn over it. The
# collider is a strip straddling the base, only as wide as the rock in
# that piece (the rounded caps are narrower), so gaps are as wide as they
# look.
func _place_ridges() -> void:
	var cache := {}
	for cell in terrain.ridge_rock:
		var rock: Vector2i = terrain.features[cell]
		if not cache.has(rock):
			cache[rock] = _wall_piece(rock)
		var piece: Dictionary = cache[rock]
		var body := StaticBody2D.new()
		body.collision_mask = 0
		body.position = Vector2(cell.x * TILE, cell.y * TILE + TILE)
		var sprite := Sprite2D.new()
		sprite.texture = piece.texture
		sprite.centered = false
		sprite.offset = Vector2(0, -2 * TILE)
		body.add_child(sprite)
		var span: Vector2i = piece.span
		if span.y > span.x:
			_add_box(body, Rect2(span.x, -RIDGE_BASE_TOP, span.y - span.x, RIDGE_BASE_TOP + RIDGE_FRONT))
		actors.add_child(body)


# Overlay texture (rim cell over rock cell, ground removed) and the stone's
# horizontal span at the base, for one ridge piece.
func _wall_piece(rock: Vector2i) -> Dictionary:
	var ground := {}
	var fill := _ridge_ground(rock)
	for y in TILE:
		for x in TILE:
			ground[_pixels.get_pixel(fill.x * TILE + x, fill.y * TILE + y).to_rgba32()] = true
	var img := Image.create(TILE, 2 * TILE, false, Image.FORMAT_RGBA8)
	var lo := TILE
	var hi := -1
	for part in 2:
		var src := rock + Vector2i(0, part - 1) # rim above, then rock
		for y in TILE:
			for x in TILE:
				var p := _pixels.get_pixel(src.x * TILE + x, src.y * TILE + y)
				if p.a > 0.5 and not ground.has(p.to_rgba32()):
					img.set_pixel(x, part * TILE + y, p)
					if part == 1 and y >= TILE - RIDGE_BASE_TOP:
						lo = mini(lo, x) # stone width at the base
						hi = maxi(hi, x)
	return {"texture": ImageTexture.create_from_image(img), "span": Vector2i(lo, hi + 1)}


# The plain ground tile a ridge piece is baked on.
func _ridge_ground(atlas: Vector2i) -> Vector2i:
	if atlas.x <= 8:
		return Vector2i(0, 0) # light: the lawn
	if atlas.y >= 27:
		return Vector2i(16, 25) # stone top
	if atlas.y >= 21:
		return Vector2i(16, 19) # dark top
	return Vector2i(16, 13) # mid top


func _place_props() -> void:
	for prop in terrain.props:
		var body := StaticBody2D.new()
		body.collision_mask = 0
		var region: Rect2
		var base: Vector2
		var block := Vector2(6, 4)
		var frames := 1
		if prop.has("sign"):
			body.name = "sign_%d" % prop.sign
			region = Rect2(Vector2(PaintedTerrain.SIGN[prop.sign] * TILE), Vector2(TILE, TILE))
			base = Vector2(8, 15)
			body.position = Vector2(prop.cell * TILE) + base
		else:
			var art: Dictionary = PaintedTerrain.PROPS[prop.art]
			body.name = "%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y]
			region = Rect2(Vector2(art.region.position * TILE), Vector2(art.region.size * TILE))
			base = Vector2(art.base)
			block = art.block
			frames = art.get("frames", 1)
			body.position = Vector2((prop.cell + art.cell) * TILE) + base
		if frames > 1:
			body.add_child(_flipbook(region, frames, -base))
		else:
			body.add_child(_region_sprite(region, -base))
		if prop.block and block != Vector2.ZERO:
			_add_box(body, Rect2(Vector2(-block.x / 2.0, -block.y), block))
		actors.add_child(body)


func _spawn_walker() -> void:
	var walker := WALKER_SCENE.instantiate()
	walker.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	actors.add_child(walker)
	var camera: Camera2D = walker.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = PaintedTerrain.WIDTH * TILE
	camera.limit_bottom = PaintedTerrain.HEIGHT * TILE


func _region_sprite(region: Rect2, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = SHEET
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.offset = offset
	return sprite


func _flipbook(first: Rect2, count: int, offset: Vector2) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 8.0)
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
	return sprite


func _add_box(parent: Node, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = rect.get_center()
	parent.add_child(node)


func _smooth_noise(x: float, y: float, salt: int) -> float:
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
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)


func _solid_ground(cell: Vector2i) -> bool:
	return terrain.water.has(cell) or terrain.ledge.has(cell) or terrain.hedge.has(cell) or terrain.canopy.has(cell)
