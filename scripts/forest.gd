extends Node2D
## Paints a Painted Lands map from forest_terrain.gd: lawn on Ground, cobble
## path, fence, and Mode A dirt islands on Features, Mode B islands as
## halo sprites on Patches, grass deco on Deco, and y-sorted houses, props,
## and the walker on Actors.

const TILE := 16
const SHEET := preload("res://assets/pack/TILESET_brighter.png")
const COZY_SHEET := "res://assets/pack/cozy_farm/buildings.png"
## The Cozy Farm buildings are a little brighter than the Painted Lands
## houses (value 0.42-0.61 against 0.34-0.42): drawn at this value.
const COZY_VALUE := 0.86
const SAIL_FRAMES := 6 # the sails' quarter turn, in pixel-art frames
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
## Houses open onto generated interiors (house_interiors.gd): the randomizer.
@export var interiors := false
## The Cozy Farm art pack's animals (wildlife.gd `mode`): the bunny for the
## drawn rabbit and farm animals round the homes ("pack"), or with
## `cozy_buildings` the deprecated cozy farm table ("farm"). The only Cozy
## Farm art in use.
@export var cozy_animals := false
## The Cozy Farm art pack's buildings (PaintedTerrain `cozy`): its homes in
## place of the Painted Lands houses, farmyard outbuildings, and the cozy-only
## map types. Deprecated with randomizer-painted-cozyfarm (the only scene
## that sets it); docs/deprecated/cozy-farm.md.
@export var cozy_buildings := false

@onready var ground: TileMapLayer = $Ground
@onready var features_layer: TileMapLayer = $Features
@onready var patches: Node2D = $Patches
@onready var deco_layer: TileMapLayer = $Deco
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: PaintedTerrain
var house_interiors: HouseInteriors
# Ambience: one wind that the leaves, streaks, and cloud shadows all follow.
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
var _plant_tops: Array[Sprite2D] = [] # top parts of reeds and water grass, which nod
var _leaf_colors := {} # art name -> {light, dark}
var tone_layers: Array[TileMapLayer] = []
var accent_layer: TileMapLayer
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
	for layer in [ground, features_layer, deco_layer, accent_layer] + tone_layers:
		layer.tile_set = tiles
	_add_ambience()
	if interiors:
		house_interiors = HouseInteriors.new()
		house_interiors.name = "HouseInteriors"
		add_child(house_interiors)
		house_interiors.setup(self)
	build(map_id, recipe)


# Generates `id` and repaints every layer. Safe to call again to replace
# the current map.
func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = PaintedTerrain.new()
	terrain.cozy = cozy_buildings
	report = terrain.generate(map_id, recipe)
	for layer in [ground, features_layer, deco_layer, accent_layer] + tone_layers:
		layer.clear()
	for node in [patches, actors, collision, _bridge_under]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_paint()
	_paint_patches()
	_build_collision()
	_place_houses()
	_place_bridges()
	_place_ridges()
	_place_props()
	_spawn_walker()
	_reset_ambience()
	if house_interiors:
		house_interiors.reset(terrain, actors.get_node("Walker"), _door_leaves)
	print(report)


## For the randomizer menu: the recipe names, in recipe-id order.
func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in (PaintedTerrain.RECIPES.slice(0, PaintedTerrain.RIVER_FIRST) if cozy_buildings else PaintedTerrain.RECIPES):
		out.append(r.name)
	if cozy_buildings:
		for r in PaintedTerrain.COZY_RECIPES:
			out.append(r.name)
	return out


## For the randomizer menu: {id, name, checks}.
func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


func _add_ambience() -> void:
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	streaks = WindStreaks.new()
	streaks.name = "WindStreaks"
	streaks.wind = wind
	add_child(streaks)
	move_child(streaks, actors.get_index()) # under the y-sorted actors
	grass_waves = GrassWaves.new()
	grass_waves.name = "GrassWaves"
	grass_waves.wind = wind
	add_child(grass_waves)
	move_child(grass_waves, actors.get_index()) # light on the grass, under the y-sorted actors
	water_life = WaterLife.new()
	water_life.name = "WaterLife"
	water_life.wind = wind
	add_child(water_life)
	move_child(water_life, actors.get_index()) # ripples under the y-sorted actors
	footsteps = Footsteps.new()
	footsteps.name = "Footsteps"
	footsteps.wind = wind
	footsteps.water_life = water_life
	add_child(footsteps)
	critters = Critters.new()
	critters.name = "Critters"
	critters.wind = wind
	add_child(critters)
	_bridge_under = Node2D.new()
	_bridge_under.name = "Bridges"
	add_child(_bridge_under)
	move_child(_bridge_under, actors.get_index()) # decks under the y-sorted actors
	fire = FireAmbience.new()
	fire.name = "FireAmbience"
	fire.wind = wind
	add_child(fire)
	leaves = AmbientLeaves.new()
	leaves.name = "Leaves"
	leaves.wind = wind
	add_child(leaves)
	drifters = Drifters.new()
	drifters.name = "Drifters"
	drifters.wind = wind
	add_child(drifters)
	wildlife = Wildlife.new()
	wildlife.name = "Wildlife"
	wildlife.mode = ("farm" if cozy_buildings else "pack") if cozy_animals else ""
	add_child(wildlife)
	clouds = CloudShadows.new()
	clouds.name = "CloudShadows"
	clouds.wind = wind
	add_child(clouds)


func _reset_ambience() -> void:
	var map_rect := Rect2(0, 0, PaintedTerrain.WIDTH * TILE, PaintedTerrain.HEIGHT * TILE)
	streaks.bounds = map_rect
	clouds.reset(map_rect)
	var sources: Array[Dictionary] = []
	for prop in terrain.props:
		if not prop.has("art") or not (prop.art in PaintedTerrain.TREES or prop.art in PaintedTerrain.SHADE_TREES):
			continue
		var art: Dictionary = PaintedTerrain.PROPS[prop.art]
		var top_left := Vector2((prop.cell + art.cell) * TILE)
		var size := Vector2(art.region.size * TILE)
		if art.has("splice"): # the crown is drawn lower on spliced trees
			top_left.y += art.splice.y - art.splice.x
		sources.append({
			"crown": Rect2(top_left + Vector2(5, 4), Vector2(size.x - 10, size.y * 0.45)),
			"base_y": top_left.y + art.base.y,
		}.merged(_colors_of(prop.art, Rect2i(art.region.position * TILE, Vector2i(art.region.size.x * TILE, art.region.size.y * TILE / 2)))))
	# The canopy wall (Deep forest) sheds leaves along its lower edge.
	var canopy_cols := {}
	for cell in terrain.canopy:
		canopy_cols[cell.x / 4] = true
	for block in canopy_cols:
		var atlas: Vector2i = terrain.canopy[Vector2i(block * 4, 0)]
		sources.append({
			"crown": Rect2(block * 4 * TILE, TILE, 4 * TILE, 2 * TILE),
			"base_y": 4 * TILE + 8.0,
		}.merged(_colors_of("canopy_%s" % atlas, Rect2i(atlas * TILE, Vector2i(4 * TILE, 4 * TILE)))))
	leaves.set_sources(sources)
	var fires: Array[Dictionary] = []
	for body in actors.get_children():
		var n := String(body.name)
		for kind in ["campfire_big", "campfire", "torch"]:
			if n.begins_with(kind + "_") or n.begins_with(kind + "_b_") or n.begins_with(kind + "_c_"):
				fires.append({"pos": body.position, "kind": kind})
				break
	for house in terrain.houses:
		if PaintedTerrain.CHIMNEYS.has(house.id):
			fires.append({"pos": Vector2(house.origin * TILE + PaintedTerrain.CHIMNEYS[house.id]), "kind": "chimney"})
	for flame in _bridge_lanterns:
		fires.append({"pos": flame + Vector2(0, 6), "kind": "lamp", "flame": flame, "radius": 16, "smoke": false})
	fire.set_fires(fires)
	var open: Array[Vector2i] = []
	for cell in terrain.water:
		if terrain._near_all(cell, terrain.water, 1):
			open.append(cell)
	water_life.setup(open, _plant_tops)
	var walker := actors.get_node_or_null("Walker")
	footsteps.leaves = leaves
	footsteps.setup(terrain, walker)
	critters.walker = walker
	var flowers: Array[Vector2] = []
	var dark: Array[Vector2] = []
	for cell in terrain.deco:
		if terrain._is_flower(terrain.deco[cell]):
			flowers.append(Vector2(cell) * TILE + Vector2(8, 8))
	for y in PaintedTerrain.HEIGHT:
		for x in PaintedTerrain.WIDTH:
			var cell := Vector2i(x, y)
			if terrain._tone_level(cell) >= 1 and not terrain._solid.has(cell):
				dark.append(Vector2(cell) * TILE + Vector2(8, 8))
	for cell in terrain.canopy:
		if cell.y == 3 and not terrain._solid.has(cell + Vector2i(0, 2)):
			dark.append(Vector2(cell) * TILE + Vector2(8, 40))
	var ponds: Array[Rect2] = []
	for r in terrain.ponds:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16)))
	critters.setup(flowers, ponds, dark)
	wildlife.setup(terrain, actors, walker, _pixels, water_life)
	drifters.setup(map_rect, flowers)
	grass_waves.setup(GrassWaves.grass_cells(terrain))


# Leaf colors for a tree, from its sprite: `light` are the brightest common
# foliage (or blossom) colors that still stand out from the lawn, `dark` is
# its darkest common foliage color for the leaf's edge.
func _colors_of(key: String, region: Rect2i) -> Dictionary:
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	var lawn := _pixels.get_pixel(0, 0)
	var counts := {}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var p := _pixels.get_pixel(x, y)
			if p.a < 0.5 or (p.r > p.g and p.r > p.b and p.get_luminance() < 0.5):
				continue # transparent, or trunk and branch browns
			var k := p.to_rgba32()
			counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var common: Array[Color] = []
	for k in keys.slice(0, 10):
		common.append(Color.hex(k))
	var light: Array[Color] = []
	var dark := Color(0.09, 0.25, 0.24)
	var darkest := 2.0
	for c in common:
		var l := c.get_luminance()
		if l < darkest:
			darkest = l
			dark = c
		var off_lawn := absf(c.r - lawn.r) + absf(c.g - lawn.g) + absf(c.b - lawn.b)
		if l > 0.3 and off_lawn > 0.12:
			light.append(c)
	light = light.slice(0, 3)
	if light.is_empty():
		light.append(common[0] if not common.is_empty() else Color(0.35, 0.55, 0.3))
	_leaf_colors[key] = {"light": light, "dark": dark}
	return _leaf_colors[key]


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
		_put(deco_layer, cell, terrain.deco[cell])


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
var _door_leaves := {} # house -> DoorLeaf
var _bridge_under: Node2D # the bridges' decks, under the actors
var _bridge_lanterns: Array[Vector2] = []

## Bridges where the roads cross the rivers (bridges.gd, the Forest kit): the
## deck and its back rail under the walker, the front rail over it.
func _place_bridges() -> void:
	_bridge_lanterns.clear()
	if terrain.bridges.is_empty():
		return
	var tex: Texture2D = load(Bridges.SHEETS.forest)
	for b in terrain.bridges:
		_bridge_lanterns.append_array(Bridges.build(b, tex, _bridge_under, actors))


func _place_houses() -> void:
	_door_leaves.clear()
	for house in terrain.houses + terrain.outbuildings:
		var art: Dictionary = PaintedTerrain.HOUSES[house.id]
		var tex: Texture2D = _cozy_texture() if art.get("sheet", "") == "cozy" else SHEET
		var region: Rect2i = art.region
		var origin := Vector2(house.origin * TILE)
		var eave: int = art.roof_rows * TILE

		var roof := Node2D.new()
		roof.name = "HOUSE_ROOF_%d" % house.id
		roof.position = origin + Vector2(0, eave)
		roof.add_child(_region_sprite(Rect2(Vector2(region.position), Vector2(region.size.x, eave)), Vector2(0, -eave), tex))
		actors.add_child(roof)

		var body := StaticBody2D.new()
		body.name = "HOUSE_BODY_%d" % house.id
		body.collision_mask = 0
		body.position = origin + Vector2(0, region.size.y)
		body.add_child(_region_sprite(
			Rect2(Vector2(region.position + Vector2i(0, eave)), Vector2(region.size.x, region.size.y - eave)),
			Vector2(0, eave - region.size.y), tex))
		if art.has("sails"):
			# The windmill's sails turn over the body with the wind, in front
			# of it (sorted just below its foot).
			var sails := Sails.new()
			sails.frames = _sail_frames(art.sails)
			sails.wind = wind
			sails.position = origin + Vector2(art.sails_hub) + Vector2(0, region.size.y - art.sails_hub.y + 1)
			sails.offset = Vector2(-art.sails.size.x / 2.0, -art.sails.size.y / 2.0 - (region.size.y - art.sails_hub.y + 1))
			actors.add_child(sails)
		for block in art.blocks:
			_add_box(body, Rect2(Vector2(block.position) - Vector2(0, region.size.y), Vector2(block.size)))
		# Loose door and windows hung on the wall (the barn).
		for overlay in art.get("overlays", []):
			var sprite := _region_sprite(Rect2(overlay.src), Vector2(overlay.at) - Vector2(0, region.size.y))
			body.add_child(sprite)
		# A front door that swings open for the walker (homes with interiors).
		if house_interiors and art.has("door_px") and house in terrain.houses:
			var opening: Rect2i = art.door_px
			var src := region.position + opening.position
			for overlay in art.get("overlays", []):
				if Rect2i(overlay.at, overlay.src.size).encloses(opening):
					src = overlay.src.position + opening.position - overlay.at
			var made := DoorLeaf.make_leaf(_pixels, Rect2i(src, opening.size))
			var leaf := DoorLeaf.new()
			leaf.leaf = made.texture
			leaf.edge = made.edge
			leaf.made = true
			leaf.size = opening.size
			leaf.position = Vector2(opening.position) - Vector2(0, region.size.y)
			body.add_child(leaf)
			_door_leaves[house] = leaf
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
	_plant_tops.clear()
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
			var fps: float = PaintedTerrain.PROPS[prop.art].get("fps", 8.0) if prop.has("art") else 8.0
			body.add_child(_flipbook(region, frames, -base, fps))
		elif prop.has("art") and prop.art in PaintedTerrain.SHORE_PLANTS:
			# Reeds and water grass: a planted lower part and a top that nods
			# in the wind (see WaterLife).
			var cut := floorf(region.size.y * 0.55)
			body.add_child(_region_sprite(Rect2(region.position + Vector2(0, cut), Vector2(region.size.x, region.size.y - cut)), Vector2(0, cut) - base))
			var top := _region_sprite(Rect2(region.position, Vector2(region.size.x, cut)), -base)
			body.add_child(top)
			_plant_tops.append(top)
		elif prop.has("art") and PaintedTerrain.PROPS[prop.art].has("splice"):
			# Two pieces: the base rows where the region puts them, the tree
			# above the cut moved down onto them, so the trunk is unbroken.
			var sp: Vector2i = PaintedTerrain.PROPS[prop.art].splice
			body.add_child(_region_sprite(Rect2(region.position + Vector2(0, sp.y), Vector2(region.size.x, region.size.y - sp.y)), Vector2(0, sp.y) - base))
			body.add_child(_region_sprite(Rect2(region.position, Vector2(region.size.x, sp.x)), Vector2(0, sp.y - sp.x) - base))
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


func _region_sprite(region: Rect2, offset: Vector2, tex: Texture2D = SHEET) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.centered = false
	sprite.offset = offset
	return sprite


func _flipbook(first: Rect2, count: int, offset: Vector2, fps := 8.0) -> AnimatedSprite2D:
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
	# Each fire starts on its own frame and runs at its own pace, so no two
	# flicker in step.
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


# ---------------------------------------------------------------- cozy farm

var _cozy_img: Image
var _cozy_tex: Texture2D
var _sails_cache := {}


## The Cozy Farm building sheet, drawn at COZY_VALUE brightness.
func _cozy_image() -> Image:
	if _cozy_img == null:
		_cozy_img = load(COZY_SHEET).get_image()
		if _cozy_img.is_compressed():
			_cozy_img.decompress()
		_cozy_img.convert(Image.FORMAT_RGBA8)
		for y in _cozy_img.get_height():
			for x in _cozy_img.get_width():
				var c := _cozy_img.get_pixel(x, y)
				if c.a > 0.0:
					c.v *= COZY_VALUE
					_cozy_img.set_pixel(x, y, c)
	return _cozy_img


func _cozy_texture() -> Texture2D:
	if _cozy_tex == null:
		_cozy_tex = ImageTexture.create_from_image(_cozy_image())
	return _cozy_tex


## The sails at SAIL_FRAMES angles through a quarter turn (they look the same
## every 90 degrees), each rotated on whole pixels (nearest source pixel), so
## the turning stays pixel art.
func _sail_frames(src: Rect2i) -> Array[Texture2D]:
	if _sails_cache.has(src):
		return _sails_cache[src]
	var img := _cozy_image().get_region(src)
	var n := src.size.x
	var mid := (n - 1) / 2.0
	var out: Array[Texture2D] = []
	for f in SAIL_FRAMES:
		var a := -f * (PI / 2.0) / SAIL_FRAMES
		var ca := cos(a)
		var sa := sin(a)
		var frame := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var dx := x - mid
				var dy := y - mid
				var sx := roundi(mid + dx * ca - dy * sa)
				var sy := roundi(mid + dx * sa + dy * ca)
				if sx >= 0 and sy >= 0 and sx < n and sy < n:
					frame.set_pixel(x, y, img.get_pixel(sx, sy))
		out.append(ImageTexture.create_from_image(frame))
	_sails_cache[src] = out
	return out


## Windmill sails: steps through the rotation frames faster in stronger wind
## (a slow drift in calm air, about a turn every four seconds in a gust).
class Sails extends Sprite2D:
	var frames: Array[Texture2D] = []
	var wind: Wind
	var _phase := 0.0

	func _ready() -> void:
		centered = false
		_phase = randf() * frames.size()

	func _process(delta: float) -> void:
		var strength := wind.strength() if wind else 0.5
		_phase = fmod(_phase + delta * frames.size() * (0.15 + strength * 0.9), frames.size())
		texture = frames[int(_phase)]
