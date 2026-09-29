extends Node2D
## Paints a Time Fantasy map from tf_terrain.gd: grass and forest-floor
## zones on Ground (the zone rims drawn per pixel, so no edge follows the
## grid), paths and patches on Paths, animated water (frames 1-2-3-2) on
## Water, cliffs and stairs on Cliffs, bridges under the actors, and houses,
## trees, props, and the walker as y-sorted actors. The walker and the Esc
## menu are the Painted Lands randomizer's; the ambience is the Painted Lands
## set (wind, leaves, streaks, cloud shadows, grass waves, water life,
## critters, drifters, wildlife, footsteps, fire light and smoke).

const TILE := 16
const TERRAIN := preload("res://assets/pack/time_fantasy/terrain.png")
const WATER_SHEET := preload("res://assets/pack/time_fantasy/water.png")
const OUTSIDE := preload("res://assets/pack/time_fantasy/outside.png")
const HOUSES := preload("res://assets/pack/time_fantasy/house.png")
const TORCH := preload("res://assets/pack/time_fantasy/animated/torch.png")
const FIREPLACE := preload("res://assets/pack/time_fantasy/animated/fireplace.png")
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const W := TFTerrain.W
const H := TFTerrain.H
const T_SRC := 0 # terrain.png
const WATER_SRC := 1 # generated: every water tile with frames 1-2-3-2
const ZONE_SRC := 2 # generated: zone rim tiles
const FLIP := 1
const WATER_FRAME := 0.28

@export var map_id := 150000
@export var recipe := -1
## The Time Fantasy greens are loud next to Painted Lands (saturation 0.62
## against 0.40, and every grass cell a high-contrast four-color speckle).
## The sheets are graded once at load, greens only: hue nudged toward
## blue-green, saturation scaled, brightness pulled toward a pivot (which calms
## the speckle), then dimmed. Dirt, roofs, flowers, and water keep their colors.
@export var grade := true
@export var grade_hue := 0.02
@export var grade_saturation := 0.68
@export var grade_contrast := 0.6
@export var grade_value := 0.9
const DEEP_VALUE := 0.86 # the deep forest floor, after the grade

@onready var ground_layer: TileMapLayer = $Ground
@onready var path_layer: TileMapLayer = $Paths
@onready var water_layer: TileMapLayer = $Water
@onready var cliff_layer: TileMapLayer = $Cliffs
@onready var under: Node2D = $Under
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: TFTerrain
var report := ""
var wind: Wind
var leaves: AmbientLeaves
var streaks: WindStreaks
var clouds: CloudShadows
var fire: FireAmbience
var water_life: WaterLife
var critters: Critters
var footsteps: Footsteps
var wildlife: Wildlife
var drifters: Drifters
var grass_waves: GrassWaves
var _tiles: TileSet
var _terrain_img: Image
var _water_img: Image
var _outside_img: Image
var _house_img: Image
var _autumn_cache := {}
const SNOW := ["4476c0", "88b6e2", "b3e3ef"]
var _autumn_ramp: Array = []
var _terrain_tex: ImageTexture
var _outside_tex: ImageTexture
var _leaf_colors := {}


func _ready() -> void:
	_terrain_img = _image(TERRAIN)
	_water_img = _image(WATER_SHEET)
	_outside_img = _image(OUTSIDE)
	_house_img = _image(HOUSES)
	if grade:
		for img in [_terrain_img, _water_img, _outside_img, _house_img]:
			_grade_image(img)
		# The grade's squeeze leaves deep only 0.03 below mid; the deep fills are
		# used by the zones alone (rims are drawn from this image), so they
		# drop further to step the levels like Painted Lands.
		for c: Vector2i in TFTerrain.DEEP_FILLS:
			for y in TILE:
				for x in TILE:
					var col := _terrain_img.get_pixel(c.x * TILE + x, c.y * TILE + y)
					if col.a > 0.0:
						col.v *= DEEP_VALUE
						_terrain_img.set_pixel(c.x * TILE + x, c.y * TILE + y, col)
	_terrain_tex = ImageTexture.create_from_image(_terrain_img)
	_outside_tex = ImageTexture.create_from_image(_outside_img)
	_add_ambience()
	build(map_id, recipe)


## One green graded (see `grade`); anything not green comes back unchanged.
func graded(c: Color) -> Color:
	if not grade or c.s < 0.15:
		return c
	# Full weight on greens (hue 0.19-0.45), fading out over 0.05 either side.
	var w := clampf(minf(c.h - 0.14, 0.50 - c.h) / 0.05, 0.0, 1.0)
	if w <= 0.0:
		return c
	var h := c.h + grade_hue * w
	var sat := c.s * lerpf(1.0, grade_saturation, w)
	var v := 0.56 + (c.v - 0.56) * lerpf(1.0, grade_contrast, w)
	v *= lerpf(1.0, grade_value, w)
	return Color.from_hsv(h, sat, clampf(v, 0.0, 1.0), c.a)


func _grade_image(img: Image) -> void:
	var seen := {}
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var k := c.to_rgba32()
			if not seen.has(k):
				seen[k] = graded(c)
			img.set_pixel(x, y, seen[k])


func _image(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


## Generates `id` and repaints everything; safe to call again.
func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = TFTerrain.new()
	report = terrain.generate(map_id, recipe)
	for layer in [ground_layer, path_layer, water_layer, cliff_layer]:
		layer.clear()
	for node in [under, actors, collision]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_build_tileset()
	_paint()
	_build_collision()
	_place_houses()
	_place_props()
	_spawn_walker()
	_reset_ambience()
	print(report)


func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in TFTerrain.RECIPES:
		out.append(r.name)
	return out


func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


# ---------------------------------------------------------------- tiles

func _build_tileset() -> void:
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(TILE, TILE)
	var t := TileSetAtlasSource.new()
	t.texture = _terrain_tex
	t.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(t, T_SRC)
	for layer in [ground_layer, path_layer, water_layer, cliff_layer]:
		layer.tile_set = _tiles


func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i, flip := false) -> void:
	var src: TileSetAtlasSource = _tiles.get_source(T_SRC)
	if not src.has_tile(atlas):
		src.create_tile(atlas)
	var alt := 0
	if flip:
		if not src.has_alternative_tile(atlas, FLIP):
			src.create_alternative_tile(atlas, FLIP)
			src.get_tile_data(atlas, FLIP).flip_h = true
		alt = FLIP
	layer.set_cell(cell, T_SRC, atlas, alt)


func _paint() -> void:
	# Ground, with the forest-floor rims drawn per pixel.
	var rims := {}
	for c in terrain.ground:
		var t: Vector2i = terrain.ground[c]
		if _is_rim(c):
			rims[c] = true
		else:
			_put(ground_layer, c, t)
	_paint_rims(rims)
	for c in terrain.path_tiles:
		_put(path_layer, c, terrain.path_tiles[c])
	_paint_water()
	for c in terrain.cliffs:
		var e: Dictionary = terrain.cliffs[c]
		_put(cliff_layer, c, e.atlas, e.flip)


# A cell on the edge of a forest-floor level: a neighbor sits at another
# level (lawn, mid, deep).
func _is_rim(c: Vector2i) -> bool:
	if terrain.dark.is_empty():
		return false
	var l := _level(c)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var n := c + Vector2i(dx, dy)
			if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H and _level(n) != l:
				return true
	return false


func _level(c: Vector2i) -> int:
	return 2 if terrain.deep.has(c) else (1 if terrain.dark.has(c) else 0)


# Each rim cell is drawn per pixel: the zone's smooth field, sampled between
# cell centers, plus a pixel wobble and an ordered dither; above the deep cut
# is deep grass, above the mid cut mid grass, below it the light lawn.
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

func _paint_rims(rims: Dictionary) -> void:
	if rims.is_empty():
		return
	var cols := 32
	var img := Image.create(cols * TILE, ((rims.size() + cols - 1) / cols) * TILE, false, Image.FORMAT_RGBA8)
	var src := TileSetAtlasSource.new()
	var n := 0
	var placed := {}
	for c in rims:
		var at := Vector2i(n % cols, n / cols)
		# The cell's own fill for its level; the others' first fill. A flower
		# on a rim cell gives way to the plain lawn.
		var own: Vector2i = terrain.ground[c]
		var lvl := _level(c)
		var tiles: Array[Vector2i] = [terrain.season.fill, TFTerrain.MID_FILLS[0], TFTerrain.DEEP_FILLS[0]]
		if lvl > 0 or own == terrain.season.fill or terrain.season.vary.has(own):
			tiles[lvl] = own
		for py in TILE:
			for px in TILE:
				var fx: float = c.x + (px + 0.5) / TILE - 0.5
				var fy: float = c.y + (py + 0.5) / TILE - 0.5
				var v: float = _field(fx, fy) + 0.012 * sin((c.x * 16 + px) * 0.9 + (c.y * 16 + py) * 0.7) + (BAYER[(py % 4) * 4 + (px % 4)] / 16.0 - 0.5) * 0.02
				var from: Vector2i = tiles[2] if v >= terrain.deep_cut else (tiles[1] if v >= terrain.zone_cut else tiles[0])
				img.set_pixel(at.x * TILE + px, at.y * TILE + py, _terrain_img.get_pixel(from.x * TILE + px, from.y * TILE + py))
		placed[c] = at
		n += 1
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(src, ZONE_SRC)
	for c in placed:
		src.create_tile(placed[c])
		ground_layer.set_cell(c, ZONE_SRC, placed[c])


# The zone field between cell centers (bilinear).
func _field(x: float, y: float) -> float:
	var x0 := clampi(floori(x), 0, W - 1)
	var y0 := clampi(floori(y), 0, H - 1)
	var x1 := mini(x0 + 1, W - 1)
	var y1 := mini(y0 + 1, H - 1)
	var tx := clampf(x - x0, 0.0, 1.0)
	var ty := clampf(y - y0, 0.0, 1.0)
	var f: Array[float] = terrain.zone_field
	var a := lerpf(f[y0 * W + x0], f[y0 * W + x1], tx)
	var b := lerpf(f[y1 * W + x0], f[y1 * W + x1], tx)
	return lerpf(a, b, ty)


# Water: every water tile in use gets a strip of four frames (1-2-3-2 of the
# sheet's three, which sit three columns apart), played by tile animation.
func _paint_water() -> void:
	if terrain.water.is_empty():
		return
	var uniq := {}
	for c in terrain.water:
		uniq[terrain.water[c]] = true
	var list := uniq.keys()
	var img := Image.create(4 * TILE, list.size() * TILE, false, Image.FORMAT_RGBA8)
	var row_of := {}
	for i in list.size():
		var a: Vector2i = list[i]
		for f in 4:
			var k: int = [0, 1, 2, 1][f]
			img.blit_rect(_water_img, Rect2i((a.x + 3 * k) * TILE, a.y * TILE, TILE, TILE), Vector2i(f * TILE, i * TILE))
		row_of[a] = i
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(src, WATER_SRC)
	for i in list.size():
		var at := Vector2i(0, i)
		src.create_tile(at)
		src.set_tile_animation_columns(at, 4)
		src.set_tile_animation_frames_count(at, 4)
		for f in 4:
			src.set_tile_animation_frame_duration(at, f, WATER_FRAME)
	for c in terrain.water:
		water_layer.set_cell(c, WATER_SRC, Vector2i(0, row_of[terrain.water[c]]))


# ---------------------------------------------------------------- collision

func _build_collision() -> void:
	for y in H:
		var x := 0
		while x < W:
			if not _solid(Vector2i(x, y)):
				x += 1
				continue
			var s := x
			while x < W and _solid(Vector2i(x, y)):
				x += 1
			_box(collision, Rect2(s * TILE, y * TILE, (x - s) * TILE, TILE))
	# A plateau top is raised: its north, west, and east lips are walls.
	for p in terrain.plateaus:
		var r: Rect2i = p.top
		_box(collision, Rect2(r.position.x * TILE, r.position.y * TILE, r.size.x * TILE, 4))
		_box(collision, Rect2(r.position.x * TILE, r.position.y * TILE, 4, (r.size.y + 2) * TILE))
		_box(collision, Rect2(r.end.x * TILE - 4, r.position.y * TILE, 4, (r.size.y + 2) * TILE))
	var w := W * TILE
	var h := H * TILE
	_box(collision, Rect2(-TILE, -TILE, w + 2 * TILE, TILE))
	_box(collision, Rect2(-TILE, h, w + 2 * TILE, TILE))
	_box(collision, Rect2(-TILE, 0, TILE, h))
	_box(collision, Rect2(w, 0, TILE, h))


func _solid(c: Vector2i) -> bool:
	var k := terrain.kind[c.y * W + c.x]
	if k == TFTerrain.WATER or k == TFTerrain.FACE:
		return true
	return k == TFTerrain.HOUSE and terrain.blocked.has(c)


func _box(parent: Node, r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = r.get_center()
	parent.add_child(node)


# ---------------------------------------------------------------- houses

# Each house is composed into one sprite (roof, gable end, wall band) and
# sorted at its wall's foot, so the walker passes behind the roof.
func _place_houses() -> void:
	for h in terrain.houses:
		var img := Image.create(7 * TILE, 7 * TILE, false, Image.FORMAT_RGBA8)
		var rows := [9, 10, 11, h.gable, h.gable + 1]
		for dy in 5:
			for dx in 7:
				img.blend_rect(_house_img, Rect2i((h.roof + dx) * TILE, rows[dy] * TILE, TILE, TILE), Vector2i(dx * TILE, dy * TILE))
		var cols: Array = [1] + h.interior + [3]
		for dx in 7:
			for k in 2:
				img.blend_rect(_house_img, Rect2i(cols[dx] * TILE, (h.wall + k) * TILE, TILE, TILE), Vector2i(dx * TILE, (5 + k) * TILE))
		var body := Node2D.new()
		body.name = "house_%d_%d" % [h.origin.x, h.origin.y]
		body.position = Vector2(h.origin * TILE) + Vector2(0, 7 * TILE)
		var s := Sprite2D.new()
		s.texture = ImageTexture.create_from_image(img)
		s.centered = false
		s.offset = Vector2(0, -7 * TILE)
		body.add_child(s)
		actors.add_child(body)


# ---------------------------------------------------------------- props

func _place_props() -> void:
	for p in terrain.props:
		var art: Dictionary = TFTerrain.PROPS[p.art]
		var foot := foot_of(p)
		var rect: Rect2i = art.rect
		var tex: Texture2D = TORCH if art.get("sheet", "") == "torch" else _outside_tex
		var node := StaticBody2D.new()
		node.collision_mask = 0
		node.name = "%s_%d_%d" % [p.art, p.cell.x, p.cell.y]
		node.position = foot
		var off := -Vector2(art.foot)
		if art.get("frames", 1) > 1:
			node.add_child(_flipbook(tex, Rect2(rect), art.frames, off, Vector2(0, TILE)))
		elif tex == _outside_tex and (terrain.recipe.season == "autumn" or art.has("erase") or art.has("unsnow")):
			node.add_child(_sprite(_prop_tex(p.art, terrain.recipe.season == "autumn"), Rect2(Vector2.ZERO, rect.size), off))
		else:
			node.add_child(_sprite(tex, Rect2(rect), off))
		if art.has("flame"):
			# The pit's fire: the fireplace flames, animated, in the pit.
			var fl: Vector2i = art.flame
			node.add_child(_flipbook(FIREPLACE, Rect2(0, 0, 16, 16), 5, off + Vector2(fl) - Vector2(8, 14), Vector2(0, TILE)))
		if art.block != Vector2.ZERO:
			_box(node, Rect2(Vector2(-art.block.x / 2.0, -art.block.y), art.block))
		if art.tag == "bridge":
			node.position = foot
			under.add_child(node) # bridges lie on the water, under everything
		else:
			actors.add_child(node)


## A prop cut out of the sheet as its own texture: `erase` clears a piece the
## sheet draws beside it (the bare trees' loose knothole), and on autumn maps
## the green grass the sheet paints round its foot turns to the autumn grass:
## each green pixel in the bottom rows takes the autumn fill color nearest its
## brightness. Crowns above stay as drawn.
func _prop_tex(key: String, autumn: bool) -> ImageTexture:
	var ck := "%s:%s" % [key, autumn]
	if _autumn_cache.has(ck):
		return _autumn_cache[ck]
	if _autumn_ramp.is_empty():
		var seen := {}
		var fill: Vector2i = TFTerrain.AUTUMN.fill
		for y in TILE:
			for x in TILE:
				var c := _terrain_img.get_pixel(fill.x * TILE + x, fill.y * TILE + y)
				seen[c.to_html(false)] = c
		_autumn_ramp = seen.values()
		_autumn_ramp.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	var art: Dictionary = TFTerrain.PROPS[key]
	var rect: Rect2i = art.rect
	var img := _outside_img.get_region(rect)
	if art.has("erase"):
		img.fill_rect(art.erase, Color(0, 0, 0, 0))
	if art.has("unsnow"):
		# The giant trees' roots end in flecks of snow; the green maps have none.
		for y in range(rect.size.y - 12, rect.size.y):
			for x in rect.size.x:
				if img.get_pixel(x, y).to_html(false) in SNOW:
					img.set_pixel(x, y, Color(0, 0, 0, 0))
	if not autumn:
		var plain := ImageTexture.create_from_image(img)
		_autumn_cache[ck] = plain
		return plain
	var lo: float = _autumn_ramp[0].get_luminance()
	var hi: float = _autumn_ramp[-1].get_luminance()
	for y in range(maxi(0, art.foot.y - 7), rect.size.y):
		for x in rect.size.x:
			var c := img.get_pixel(x, y)
			if c.a < 0.5 or c.g < c.r + 0.06 or c.g < c.b + 0.06:
				continue
			# Grass greens span about 0.25-0.75 luminance; spread them over the ramp.
			var t := clampf((c.get_luminance() - 0.25) / 0.5, 0.0, 1.0)
			var want := lerpf(lo, hi, t)
			var best: Color = _autumn_ramp[0]
			for a: Color in _autumn_ramp:
				if absf(a.get_luminance() - want) < absf(best.get_luminance() - want):
					best = a
			img.set_pixel(x, y, best)
	var tex := ImageTexture.create_from_image(img)
	_autumn_cache[ck] = tex
	return tex


static func foot_of(p: Dictionary) -> Vector2:
	return Vector2(p.cell * TILE) + Vector2(TILE / 2.0, TILE - 1)


func _sprite(tex: Texture2D, region: Rect2, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.offset = offset
	return s


func _flipbook(tex: Texture2D, first: Rect2, count: int, offset: Vector2, step: Vector2) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", 8.0)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(first.position + step * i, first.size)
		frames.add_frame("default", at)
	var s := AnimatedSprite2D.new()
	s.sprite_frames = frames
	s.centered = false
	s.offset = offset
	s.play("default")
	s.frame = randi() % count
	s.speed_scale = randf_range(0.85, 1.15)
	return s


func _spawn_walker() -> void:
	var walker := WALKER_SCENE.instantiate()
	walker.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	actors.add_child(walker)
	var cam: Camera2D = walker.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * TILE
	cam.limit_bottom = H * TILE


# ---------------------------------------------------------------- ambience

func _add_ambience() -> void:
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	streaks = WindStreaks.new()
	grass_waves = GrassWaves.new()
	grass_waves.tip = Color(0.74, 0.9, 0.5) # sunlit tips, lighter than the grass (99, 162, 63)
	water_life = WaterLife.new()
	water_life.ring_color = Color(0.36, 0.55, 0.86)
	water_life.ring_highlight = Color(0.86, 0.94, 1.0)
	water_life.drop_color = Color(0.5, 0.7, 0.95)
	for n in [streaks, grass_waves, water_life]:
		add_child(n)
		move_child(n, actors.get_index())
	footsteps = Footsteps.new()
	footsteps.dust_colors = [Color(0.62, 0.44, 0.28), Color(0.52, 0.36, 0.24)] # darker than the dirt
	footsteps.blade_colors = [Color(0.7, 0.88, 0.42), Color(0.56, 0.78, 0.34)]
	critters = Critters.new()
	fire = FireAmbience.new()
	leaves = AmbientLeaves.new()
	drifters = Drifters.new()
	wildlife = Wildlife.new()
	clouds = CloudShadows.new()
	clouds.shade = Color(0.08, 0.24, 0.12, 0.16)
	for n in [footsteps, critters, fire, leaves, drifters, wildlife, clouds]:
		add_child(n)
	for n in [streaks, grass_waves, water_life, footsteps, critters, fire, leaves, drifters, clouds]:
		n.wind = wind
	footsteps.water_life = water_life
	footsteps.leaves = leaves


func _reset_ambience() -> void:
	var map_rect := Rect2(0, 0, W * TILE, H * TILE)
	streaks.bounds = map_rect
	# Shadows in the season's darkest grass: green, or brown on autumn gold.
	var autumn: bool = terrain.recipe.season == "autumn"
	clouds.shade = Color(0.24, 0.16, 0.04, 0.16) if autumn else Color(0.08, 0.24, 0.12, 0.16)
	# Sunlit blades and wave tips, lighter than the gold (183, 157, 50) or green (99, 162, 63) grass.
	grass_waves.tip = Color(0.95, 0.86, 0.5) if autumn else graded(Color(0.74, 0.9, 0.5))
	footsteps.blade_colors = [Color(0.93, 0.82, 0.4), Color(0.84, 0.7, 0.3)] if autumn else [graded(Color(0.7, 0.88, 0.42)), graded(Color(0.56, 0.78, 0.34))]
	clouds.reset(map_rect)
	var walker := actors.get_node_or_null("Walker")
	water_life.setup(terrain.open_water(), [] as Array[Sprite2D])
	var sources: Array[Dictionary] = []
	var fires: Array[Dictionary] = []
	for p in terrain.props:
		var art: Dictionary = TFTerrain.PROPS[p.art]
		var foot := foot_of(p)
		var rect: Rect2i = art.rect
		var top_left := foot - Vector2(art.foot)
		match art.tag:
			"tree", "autumn", "pink", "teal", "pine":
				sources.append({"crown": Rect2(top_left + Vector2(4, 2), Vector2(rect.size.x - 8, rect.size.y * 0.55)),
					"base_y": foot.y}.merged(_colors_of(p.art, rect)))
			"fire":
				fires.append({"pos": foot, "kind": "campfire", "flame": foot + Vector2(0, -8)})
			"torch":
				fires.append({"pos": foot, "kind": "torch", "flame": foot + Vector2(0, -10)})
	# Houses with a hearth send smoke up from the roof peak.
	for h in terrain.houses:
		if h.chimney:
			fires.append({"pos": Vector2(h.origin * TILE) + Vector2(3.5 * TILE, 6), "kind": "chimney"})
	leaves.set_sources(sources)
	fire.set_fires(fires)
	var flowers: Array[Vector2] = []
	var dark: Array[Vector2] = []
	var flower_tiles: Array = terrain.season.flowers
	for c in terrain.ground:
		if terrain.ground[c] in flower_tiles:
			flowers.append(Vector2(c * TILE) + Vector2(8, 8))
	for c in terrain.dark:
		if not terrain.blocked.has(c) and (c.x * 7 + c.y * 3) % 5 == 0:
			dark.append(Vector2(c * TILE) + Vector2(8, 8))
	var ponds: Array[Rect2] = []
	for r in terrain.ponds:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16)))
	critters.walker = walker
	critters.setup(flowers, ponds, dark)
	drifters.setup(map_rect, flowers)
	grass_waves.setup(terrain.grass_cells())
	var water := {}
	for c in terrain.water:
		if not terrain.bridges.has(c):
			water[c] = true
	footsteps.setup_generic(_surface, water, walker)
	wildlife.setup_from(terrain.wildlife_plan(), water, actors, walker, _terrain_img, water_life)


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
		return "none"
	if terrain.paths.has(cell):
		return "dust"
	var k := terrain.kind[cell.y * W + cell.x]
	if k != TFTerrain.GRASS and k != TFTerrain.TOP:
		return "none"
	var t: Vector2i = terrain.ground.get(cell, Vector2i.ZERO)
	return "tuft" if t in terrain.season.deco else "grass"


# Leaf colors from a tree's crown: light foliage colors that stand off the
# grass, edged with its darkest leaf color.
func _colors_of(key: String, region: Rect2i) -> Dictionary:
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	var counts := {}
	for y in range(region.position.y, region.position.y + region.size.y / 2):
		for x in range(region.position.x, region.end.x):
			var p := _outside_img.get_pixel(x, y)
			if p.a < 0.5 or (p.r > p.g and p.r > p.b and p.get_luminance() < 0.45):
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
		if c.get_luminance() > 0.35 and light.size() < 3:
			light.append(c)
	if light.is_empty():
		light.append(Color(0.5, 0.7, 0.35))
	_leaf_colors[key] = {"light": light, "dark": dark}
	return _leaf_colors[key]
