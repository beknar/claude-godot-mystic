extends Node2D
## Paints a Farm map from FarmTerrain (antarcticbees' Farm - 4 Seasons,
## spring and summer): the corner-table ground, animated water shores, the
## plateau stamps, tilled plots with a crop in each (their tops nod in the
## wind), wheat, tall grass, and hedges, fences with gates that swing open
## for the walker, buildings with doors into their own interiors (a
## sub-map far below the farm; the greenhouse opens on the sheet's own
## glasshouse), the windmill turning with the wind, the pack's animated trees
## (they rustle in gusts and when brushed, shed leaves, blow petals), fish
## that jump in the ponds, the Cozy Farm animals, and the ambience of the
## Painted Lands scenes (wind, streaks, cloud shadows, grass waves, water
## life, footsteps, critters, drifters, falling leaves). Sheets in
## assets/pack/farm/ (git-ignored); tables in farm_tiles.gd.

const TILE := 16
const W := FarmTerrain.W
const H := FarmTerrain.H
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const CROWN_FADE := 0.42
const HOUSE_FADE := 0.55
const FADE_RATE := 5.0
const BRUSH := 14.0 # px from a trunk that shakes the tree
const GATE_OPEN := 30.0 # px: a gate swings open for the walker this close
const SHADE := Color(0.08, 0.24, 0.2, 0.28) # tree shadows, the deep grass tone

@export var map_id := 190008 # recipe 0, Homestead (id % 52)
@export var recipe := -1
## Buildings open onto interiors (house_interiors.gd): a sub-map per door.
@export var interiors := true
## The Cozy Farm art pack's animals (wildlife.gd `mode = "farmland"`): the
## bunny for the drawn rabbit, farm animals in the pens and yards.
@export var cozy_animals := true
## The farmstead map types too (Forest houses, fires, and trees on Farm
## ground): randomizer-paintedlands-forest-farm sets it.
@export var mixed := false

@onready var ground_layer: TileMapLayer = $Ground
@onready var water_layer: TileMapLayer = $Water
@onready var feature_layer: TileMapLayer = $Features
@onready var deco_layer: TileMapLayer = $Deco
@onready var under: Node2D = $Under
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: FarmTerrain
var report := ""
var house_interiors: HouseInteriors
var _tiles: TileSet
var _src: TileSetAtlasSource
var _src_id := 0
var _srcs := {} # season -> [source id, TileSetAtlasSource]
var season := "summer"
var _sheet := FarmTiles.SHEET # the season's tileset
var _images := {}
var _textures := {}
var _frames_cache := {} # sheet -> SpriteFrames
var _trunks := {}
var _leaf_colors := {}
var _grass := {}
var _wheat := {}
var _shade: CanvasGroup
var _tone_layers: Array[TileMapLayer] = []
# Tone zones (pale, dark, deep): their fill tiles on the farm sheet, plain
# first, and whether a level is below its cut (pale) or above it.
# (The fills are the season's plain tiles of that terrain, FarmTiles.WANG.)
const TONES := [
	{"key": "a", "sign": -1.0},
	{"key": "d", "sign": 1.0},
	{"key": "x", "sign": 1.0},
]

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
var fish: FishJumps
var snow: Snowfall

# Things that move in _process.
var _crowns: Array[Dictionary] = [] # {sprite, foot: y, crown: Rect2}
var _houses: Array[Dictionary] = [] # {node, foot: y, rect: Rect2, door: Rect2 (the doorway, never faded for)}
var _trees: Array[Dictionary] = [] # {sprite: AnimatedSprite2D, foot: Vector2, falling: String, leaves: String, cool, crown: Rect2}
var _gates: Array[Dictionary] = [] # {sprite: Sprite2D, pos, frame: float}
var _mills: Array[AnimatedSprite2D] = []
var _gust_was := false
var _time := 0.0
var _last_feet := Vector2.ZERO
var _crops: Array[Dictionary] = [] # {node, foot: Vector2, skew, vel}


func _ready() -> void:
	for i in TONES.size():
		var layer := TileMapLayer.new()
		layer.name = "Tone_%s" % TONES[i].key
		add_child(layer)
		move_child(layer, ground_layer.get_index() + 1 + i)
		_tone_layers.append(layer)
	_shade = CanvasGroup.new()
	_shade.name = "Shadows"
	_shade.self_modulate = Color(1, 1, 1, SHADE.a)
	add_child(_shade)
	move_child(_shade, actors.get_index())
	_build_tileset()
	_add_ambience()
	if interiors:
		house_interiors = HouseInteriors.new()
		house_interiors.name = "HouseInteriors"
		add_child(house_interiors)
		house_interiors.setup(self)
	build(map_id, recipe)


func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = FarmTerrain.new()
	terrain.mixed = mixed
	report = terrain.generate(map_id, recipe)
	_use_season(terrain.season)
	for layer in [ground_layer, water_layer, feature_layer, deco_layer] + _tone_layers:
		layer.clear()
	for node in [under, actors, collision, _shade] + _tone_layers:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_crowns.clear()
	_houses.clear()
	_trees.clear()
	_gates.clear()
	_mills.clear()
	_paint()
	_build_collision()
	_place_buildings()
	_place_bridges()
	_place_trees()
	_place_crops()
	_place_props()
	_place_gates()
	_spawn_walker()
	_reset_ambience()
	if house_interiors:
		house_interiors.reset_doors(_doors(), actors.get_node("Walker"))
	print(report)


func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in FarmTerrain.all_recipes(mixed):
		out.append(r.name)
	return out


func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


# ---------------------------------------------------------------- sheets

func _image(name: String) -> Image:
	if not _images.has(name):
		var img: Image = _tex(name).get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[name] = img
	return _images[name]


func _tex(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = load(FarmTiles.PACK + name + ".png")
	return _textures[name]


## Eight (or `count`) frames side by side, `size` each.
func _frames(sheet: String, count: int, size: Vector2i, fps: float, loop: bool) -> SpriteFrames:
	var key := "%s:%d:%s" % [sheet, count, loop]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var sf := SpriteFrames.new()
	sf.set_animation_speed("default", fps)
	sf.set_animation_loop("default", loop)
	var tex := _tex(sheet)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * size.x, 0, size.x, size.y)
		sf.add_frame("default", at)
	_frames_cache[key] = sf
	return sf


func _build_tileset() -> void:
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(TILE, TILE)
	_use_season("summer")
	for layer in [ground_layer, water_layer, feature_layer, deco_layer] + _tone_layers:
		layer.tile_set = _tiles


## The atlas source of a season's sheet (one per season, made once).
func _use_season(p_season: String) -> void:
	season = p_season
	_sheet = FarmTiles.get_for(season, "sheet")
	if not _srcs.has(season):
		var src := TileSetAtlasSource.new()
		src.texture = _tex(_sheet)
		src.texture_region_size = Vector2i(TILE, TILE)
		var id := _srcs.size()
		_tiles.add_source(src, id)
		_srcs[season] = [id, src]
	_src_id = _srcs[season][0]
	_src = _srcs[season][1]


## A tile from the farm sheet; `anim` "shore" steps down five rows per frame,
## "open" steps right one column.
func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i, anim := "") -> void:
	if not _src.has_tile(atlas):
		_src.create_tile(atlas)
		if anim == "shore":
			_src.set_tile_animation_columns(atlas, 1)
			_src.set_tile_animation_separation(atlas, Vector2i(0, FarmTiles.WATER_STEP - 1))
		if anim != "":
			_src.set_tile_animation_frames_count(atlas, FarmTiles.WATER_FRAMES)
			for i in FarmTiles.WATER_FRAMES:
				_src.set_tile_animation_frame_duration(atlas, i, FarmTiles.WATER_DURATION)
	layer.set_cell(cell, _src_id, atlas)


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- paint

func _paint() -> void:
	var open_tiles: Array = FarmTiles.get_for(season, "open")
	# The shore tables are spring's (frames from row 21); a season's block may
	# sit elsewhere.
	var shore_shift: Vector2i = FarmTiles.get_for(season, "water_origin") - Vector2i(0, 21)
	var blob_base: Dictionary = FarmTiles.get_for(season, "blobs")
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var s := terrain.sig(c)
			var cells: Array = terrain.wang.get(s, terrain.wang["gggg"])
			var a: Vector2i = cells[0]
			# Fills: mostly plain, now and then a tufted variant.
			if cells.size() > 1 and s == s[0].repeat(4) and _hash(x, y) > 0.72:
				a = cells[1 + int(_hash(y, x) * (cells.size() - 1)) % (cells.size() - 1)]
			_put(ground_layer, c, a)
			# Water and its shores.
			var k := terrain.shore_key(c)
			if k == "open":
				_put(water_layer, c, open_tiles[int(_hash(x * 3, y) * 2.0) % open_tiles.size()], "open")
			elif k != "" and k != "?":
				var tab: Dictionary = FarmTiles.SHORE_WATER if terrain.water.has(c) else FarmTiles.SHORE_LAND
				_put(water_layer, c, tab[k] + shore_shift, "shore")
			# Plots, overlay blobs, fences.
			if terrain.plots.has(c):
				_put(feature_layer, c, terrain.plots[c])
			else:
				for bk in ["wheat", "tall", "hedge"]:
					var bs := terrain.blob_sig(bk, c)
					if bs != "0000" and FarmTiles.BLOB.has(bs) and blob_base.has(bk):
						_put(feature_layer, c, blob_base[bk] + FarmTiles.BLOB[bs])
						break
			if terrain.fence.has(c):
				_put(feature_layer, c, terrain.fence[c])
			if terrain.deco.has(c) and not terrain.water.has(c) and terrain.shore_key(c) == "":
				_put(deco_layer, c, terrain.deco[c])
	for p in terrain.plateaus:
		for piece in p.pieces:
			_put(feature_layer, piece.cell, piece.atlas)
	_paint_tones()


## Tone zones drawn per pixel (the Painted Lands forest's way): a cell the
## level's field covers everywhere (with room for the wobble) is its fill
## tile; a cell the contour crosses is drawn pixel by pixel from the same
## fill wherever the field, bilinear between the corners, plus a pixel-scale
## wobble and dither, passes the cut. The rim is organic and dithered; no
## edge follows the tile grid.
func _paint_tones() -> void:
	if terrain.tone_field.is_empty():
		return
	var sheet := _image(_sheet)
	var field := terrain.tone_field
	for li in TONES.size():
		var tone: Dictionary = TONES[li]
		var layer: TileMapLayer = _tone_layers[li]
		var sgn: float = tone.sign
		var cut: float = sgn * float(terrain.tone_cuts[tone.key])
		var fills: Array = terrain.wang.get(String(tone.key).repeat(4), [])
		if fills.is_empty() or is_inf(cut):
			continue
		var img := Image.create(W * TILE, H * TILE, false, Image.FORMAT_RGBA8)
		var any := false
		for y in H:
			for x in W:
				var u00 := sgn * field[y * (W + 1) + x]
				var u10 := sgn * field[y * (W + 1) + x + 1]
				var u01 := sgn * field[(y + 1) * (W + 1) + x]
				var u11 := sgn * field[(y + 1) * (W + 1) + x + 1]
				var lo := minf(minf(u00, u10), minf(u01, u11))
				var hi := maxf(maxf(u00, u10), maxf(u01, u11))
				# The wobble is about three pixels of the field's own slope in
				# this cell, so the rim is equally ragged wherever it runs.
				var amp := maxf(hi - lo, 0.004) * 0.2
				if hi + amp * 1.5 < cut:
					continue
				var nf := mini(fills.size(), 4)
				var fill: Vector2i = fills[0] if _hash(x * 7 + li, y * 3) < 0.7 or nf < 2 else fills[1 + int(_hash(y + li, x) * 3.0) % (nf - 1)]
				if lo - amp * 1.5 >= cut:
					_put(layer, Vector2i(x, y), fill)
					continue
				any = true
				for py in TILE:
					var ty := (py + 0.5) / TILE
					for px in TILE:
						var tx := (px + 0.5) / TILE
						var u := lerpf(lerpf(u00, u10, tx), lerpf(u01, u11, tx), ty)
						var wx := x * TILE + px
						var wy := y * TILE + py
						u += amp * (0.55 * sin(wx * 0.9 + wy * 0.37) + 0.35 * sin(wx * 0.31 - wy * 0.83) + (_hash(wx, wy) - 0.5) * 0.9)
						if u >= cut:
							img.set_pixel(wx, wy, sheet.get_pixel(fill.x * TILE + px, fill.y * TILE + py))
		if any:
			var spr := Sprite2D.new()
			spr.texture = ImageTexture.create_from_image(img)
			spr.centered = false
			layer.add_child(spr)


# ---------------------------------------------------------------- collision

func _build_collision() -> void:
	collision.collision_layer = 1
	for y in H:
		var run := -1
		for x in W + 1:
			var solid := false
			if x < W:
				var c := Vector2i(x, y)
				var k := terrain.kind[y * W + x]
				solid = (k == FarmTerrain.WATER and not terrain.stones.has(c) and not terrain.bridge_cells.has(c)) or k == FarmTerrain.CLIFF \
					or k == FarmTerrain.FENCE or terrain.blob_sig("hedge", c) == "1111"
			if solid and run < 0:
				run = x
			elif not solid and run >= 0:
				_add_box(collision, Rect2(run * TILE, y * TILE, (x - run) * TILE, TILE))
				run = -1
	for r in [Rect2(-TILE, -TILE, (W + 2) * TILE, TILE), Rect2(-TILE, H * TILE, (W + 2) * TILE, TILE),
			Rect2(-TILE, 0, TILE, H * TILE), Rect2(W * TILE, 0, TILE, H * TILE)]:
		_add_box(collision, r)


func _add_box(parent: Node, r: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	parent.add_child(shape)


# ---------------------------------------------------------------- buildings

## Each building is one sprite sorted at its foot, its walls colliding; while
## the walker is behind it, it fades so the walker stays in sight. The
## windmill's sails turn faster in a stronger wind.
var _door_leaves: Array = [] # by building index: its DoorLeaf, or null

## Bridges where the lanes cross the brook or the river (bridges.gd): the
## deck and its back rail under the walker, the front rail over it, the
## lanterns' flames glowing.
func _place_bridges() -> void:
	if terrain.bridges.is_empty():
		return
	var tex: Texture2D = load(Bridges.SHEETS["farm_winter" if season == "winter" else "farm"])
	for b in terrain.bridges:
		for flame in Bridges.build(b, tex, under, actors):
			_fires.append({"pos": flame + Vector2(0, 6), "kind": "lamp", "flame": flame, "radius": 16, "smoke": false})


func _place_buildings() -> void:
	_fires.clear()
	_door_leaves.clear()
	for b in terrain.buildings:
		var art: Dictionary = FarmTiles.BUILDINGS[b.kind]
		var origin := Vector2(b.origin * TILE)
		var size := Vector2(art.region.size)
		var region := FarmTiles.building_region(season, b.kind)
		var body := StaticBody2D.new()
		body.name = "building_%s" % b.kind
		body.collision_mask = 0
		body.position = origin + Vector2(0, size.y)
		var sprite: Node2D
		if art.has("anim"):
			var mill := AnimatedSprite2D.new()
			var fr: Vector2i = art.frame
			mill.sprite_frames = _frames(FarmTiles.get_for(season, "windmill"), art.frames, fr, 4.0, true)
			mill.centered = false
			mill.offset = Vector2(art.shift) + Vector2(0, -fr.y)
			mill.play("default")
			mill.frame = randi() % art.frames
			_mills.append(mill)
			sprite = mill
		else:
			var s := Sprite2D.new()
			s.texture = _forest_tex() if art.get("sheet", "") == "forest" else _tex(_sheet)
			s.region_enabled = true
			s.region_rect = Rect2(region)
			s.centered = false
			s.offset = Vector2(0, -size.y)
			sprite = s
		body.add_child(sprite)
		var forest_sheet: bool = art.get("sheet", "") == "forest"
		for overlay in art.get("overlays", []):
			var o := Sprite2D.new()
			o.texture = _forest_tex()
			o.region_enabled = true
			o.region_rect = Rect2(overlay.src)
			o.centered = false
			o.offset = Vector2(overlay.at) + Vector2(0, -size.y)
			sprite.add_child(o)
		# The front door, swinging open for the walker (door_leaf.gd): the
		# sheet's own door, or a plank leaf in an open doorway's frame colors.
		_door_leaves.append(null)
		if art.has("door_px") and interiors:
			var opening: Rect2i = art.door_px
			var leaf := DoorLeaf.new()
			leaf.size = opening.size
			if art.get("made_leaf", false):
				var src := region.position + opening.position
				for overlay in art.get("overlays", []):
					if Rect2i(overlay.at, overlay.src.size).encloses(opening):
						src = overlay.src.position + opening.position - overlay.at
				var made := DoorLeaf.make_leaf(_forest_image(), Rect2i(src, opening.size))
				leaf.leaf = made.texture
				leaf.edge = made.edge
				leaf.made = true
			else:
				var at := AtlasTexture.new()
				if art.has("anim"):
					at.atlas = _tex(FarmTiles.get_for(season, "windmill"))
					at.region = Rect2(opening) # frame 0 sits at the sheet's corner
				else:
					at.atlas = _tex(_sheet)
					at.region = Rect2(Rect2i(region.position + opening.position, opening.size))
				leaf.leaf = at
			leaf.position = (sprite as Node2D).get("offset") + Vector2(opening.position)
			sprite.add_child(leaf)
			_door_leaves[-1] = leaf
		elif art.has("door_pair") and interiors:
			# A double door: both leaves, the sheet's own, turning inward on
			# their outer hinges.
			var pair: Array = []
			for k in 2:
				var half: Rect2i = art.door_pair[k]
				var leaf := DoorLeaf.new()
				leaf.size = half.size
				leaf.hinge_left = k == 0
				var at := AtlasTexture.new()
				at.atlas = _tex(_sheet)
				at.region = Rect2(Rect2i(region.position + half.position, half.size))
				leaf.leaf = at
				leaf.position = (sprite as Node2D).get("offset") + Vector2(half.position)
				sprite.add_child(leaf)
				pair.append(leaf)
			_door_leaves[-1] = pair
		for block: Rect2i in art.blocks:
			_add_box(body, Rect2(Vector2(block.position) - Vector2(0, size.y), Vector2(block.size)))
		actors.add_child(body)
		# (The doorstep and the doorway above it do not fade the building: the
		# walker going in watches the door open.)
		var step_px := Vector2(b.door * TILE)
		_houses.append({"node": sprite, "foot": origin.y + size.y, "rect": Rect2(origin, size),
			"door": Rect2(step_px + Vector2(-4, -20), Vector2(art.door_w * TILE + 8, 40))})
		if art.has("chimney"):
			_fires.append({"pos": origin + Vector2(art.chimney), "kind": "chimney"})


## The doors for house_interiors.gd: every building opens on a Cozy Cottage
## home (rooms by building) except the greenhouse, whose interior is the
## sheet's own glasshouse, the barn (a barn), and the windmill (the mill
## floor).
func _doors() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids := FarmTiles.BUILDINGS.keys()
	for i in terrain.buildings.size():
		var b: Dictionary = terrain.buildings[i]
		var art: Dictionary = FarmTiles.BUILDINGS[b.kind]
		var d := {"step": b.door, "house": {"id": 100 + ids.find(b.kind)}, "width": art.door_w, "rooms": art.rooms}
		if i < _door_leaves.size() and _door_leaves[i] != null:
			d["leaf"] = _door_leaves[i]
		if art.get("custom", "") == "greenhouse":
			d["custom"] = _build_greenhouse.bind(i)
		elif b.kind == "barn":
			d["custom"] = _build_barn.bind(i)
		elif b.kind == "windmill":
			d["custom"] = _build_mill.bind(i)
		out.append(d)
	return out


## The greenhouse interior: the sheet's glasshouse (back wall of glass and
## vines, a tiled walk, two soil beds and an aisle between them) with crops
## growing in the beds and pots by the wall; the way out is the gap at the
## foot of the aisle.
func _build_greenhouse(index: int) -> Dictionary:
	var room: Rect2i = FarmTiles.get_for(season, "greenhouse_room")
	var view := Node2D.new()
	view.name = "Greenhouse"
	var layer := TileMapLayer.new()
	layer.tile_set = _tiles
	view.add_child(layer)
	for y in room.size.y:
		for x in room.size.x:
			_put(layer, Vector2i(x, y), room.position + Vector2i(x, y))
	var acts := Node2D.new()
	acts.name = "Actors"
	acts.y_sort_enabled = true
	view.add_child(acts)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	view.add_child(body)
	var w := room.size.x
	var h := room.size.y
	# Walls: the glass back wall, the frame down the sides, the foot row but
	# for the way out.
	_add_box(body, Rect2(0, 0, w * TILE, 3 * TILE + 6))
	_add_box(body, Rect2(0, 0, TILE, h * TILE))
	_add_box(body, Rect2((w - 1) * TILE, 0, TILE, h * TILE))
	var ex: Vector2i = FarmTiles.GREENHOUSE_EXIT
	_add_box(body, Rect2(0, (h - 1) * TILE + 12, ex.x * TILE, TILE))
	_add_box(body, Rect2((ex.x + 1) * TILE, (h - 1) * TILE + 12, (w - ex.x - 1) * TILE, TILE))
	# The beds (rows 4-10, either side of the aisle) grow crops in rows; the
	# walker wades through them as it does outdoors, and they bend and spring
	# back (_sway_crops, with the walker's position inside the interior).
	var crop_names := ["strawberry", "tomato", "pepper", "carrot", "cabbage", "leek"]
	var indoor_crops: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_id, index, "greenhouse"])
	var crops_tex := _tex(FarmTiles.CROPS_SHEET)
	for side in 2:
		var x0 := 1 if side == 0 else ex.x + 1
		for yy in range(4, 11):
			if (yy - 4) % 2 == 1:
				continue
			var crop: String = crop_names[rng.randi() % crop_names.size()]
			for xx in range(x0, x0 + 4):
				var stage: int = FarmTiles.CROPS[crop].size() - 1 - (1 if rng.randf() < 0.3 else 0)
				var r := FarmTiles.crop_rect(crop, stage)
				var plant := Node2D.new()
				plant.position = Vector2(xx * TILE + TILE / 2.0, (yy + 1) * TILE - 1) # its foot, mid-cell
				plant.add_child(_crop_sprite(crops_tex, Rect2(r), Vector2(-TILE / 2.0, -r.size.y + 1)))
				acts.add_child(plant)
				indoor_crops.append({"node": plant, "foot": plant.position, "skew": 0.0, "vel": 0.0})
	# Pots along the back wall's walk.
	for xx in [1, 3, 7, 9]:
		var art: Dictionary = FarmTiles.prop(season, "pot_plant" if xx % 4 == 1 else "pot_plant_b")
		var s := Sprite2D.new()
		s.texture = _tex(_sheet)
		s.region_enabled = true
		s.region_rect = Rect2(art.rect)
		s.centered = false
		s.position = Vector2(xx * TILE + 8, 4 * TILE - 2)
		s.offset = Vector2(-art.rect.size.x / 2.0, -art.rect.size.y)
		acts.add_child(s)
	var plan := InteriorPlan.new()
	plan.size = room.size
	plan.exit_cell = ex
	var holder := GreenhouseView.new()
	holder.name = "View"
	holder.add_child(view)
	holder.actors = acts
	holder.crops = indoor_crops
	# The way out: a glass-house door in the gap of the foot frame.
	holder.exit_door = _exit_door(view, acts, Vector2(ex.x * TILE, (h - 1) * TILE + 12 - ExitDoor.THICK), Color("#317747"))
	return {"view": holder, "plan": plan, "fires": []}


## The barn interior: a hayloft barn from the sheet's barn-yard kit (spring
## and summer sheet; there is no weather indoors): a plank floor strewn with
## straw (the wheat overlay as loose straw), the kit's plank wall with its
## windows across the back, stalls divided by fence rails with a trough and
## hay in each, hay piles, bales, crates, barrels, and a bucket along the
## walls, an aisle down the middle to the doorway, and the farm's animals
## living inside (Cozy Farm cows, pigs, sheep, goats, chickens), grazing,
## dozing, and ambling off from the walker.
const BARN_SIZE := Vector2i(14, 11)
const BARN_WALL := [Vector2i(63, 34), Vector2i(64, 34), Vector2i(65, 34)] # the plank wall (upper row; the lower is a row down)
const BARN_WINDOW := [Vector2i(60, 34), Vector2i(61, 34), Vector2i(62, 34)] # the wall with a band of windows
const BARN_PLANKS := Vector2i(37, 20) # Cozy Cottage plank floor (2 x 4 tiles), a plain barn brown
const BARN_RAIL := Vector2i(11, 13) # a fence post and rail, upright (a stall divider)

func _build_barn(index: int) -> Dictionary:
	var size := BARN_SIZE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_id, index, "barn"])
	var view := Node2D.new()
	view.name = "Barn"
	var tiles := _summer_tiles()
	var floor_layer := TileMapLayer.new()
	floor_layer.tile_set = tiles
	view.add_child(floor_layer)
	var straw_layer := TileMapLayer.new()
	straw_layer.tile_set = tiles
	view.add_child(straw_layer)
	var put := func(layer: TileMapLayer, c: Vector2i, a: Vector2i, sid: int) -> void:
		var src: TileSetAtlasSource = tiles.get_source(sid)
		if not src.has_tile(a):
			src.create_tile(a)
		layer.set_cell(c, sid, a)
	# The back wall: two rows, windows in two places.
	for x in size.x:
		var win := (x >= 3 and x <= 5) or (x >= 8 and x <= 10)
		var set_: Array = BARN_WINDOW if win else BARN_WALL
		var a: Vector2i = set_[(x - (3 if x < 8 else 8)) % 3] if win else set_[x % 3]
		put.call(floor_layer, Vector2i(x, 0), a, 0)
		put.call(floor_layer, Vector2i(x, 1), a + Vector2i(0, 1), 0)
	# The floor: Cozy Cottage planks (the pack's own seamless floor), and
	# loose straw in patches (corner mask, the wheat overlay's corner table,
	# so the straw has ragged edges).
	for y in range(2, size.y):
		for x in size.x:
			put.call(floor_layer, Vector2i(x, y), BARN_PLANKS + Vector2i(posmod(x, 2), posmod(y, 4)), 1)
	var noise := FastNoiseLite.new()
	noise.seed = rng.randi()
	noise.frequency = 0.28
	var straw := {}
	for y in range(3, size.y + 1):
		for x in size.x + 1:
			if noise.get_noise_2d(x, y) > 0.18:
				straw[Vector2i(x, y)] = true
	for y in range(2, size.y):
		for x in size.x:
			var sig := ""
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				sig += "1" if straw.has(Vector2i(x, y) + o) else "0"
			if sig != "0000" and FarmTiles.BLOB.has(sig):
				put.call(straw_layer, Vector2i(x, y), FarmTiles.BLOB_BASE.wheat + FarmTiles.BLOB[sig], 0)
	var acts := Node2D.new()
	acts.name = "Actors"
	acts.y_sort_enabled = true
	view.add_child(acts)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	view.add_child(body)
	var exit := Vector2i(size.x / 2, size.y - 1)
	# Walls: the back wall, the sides, the front but for the doorway.
	_add_box(body, Rect2(0, 0, size.x * TILE, 2 * TILE + 6))
	_add_box(body, Rect2(-TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(size.x * TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(0, size.y * TILE - 2, exit.x * TILE, TILE))
	_add_box(body, Rect2((exit.x + 1) * TILE, size.y * TILE - 2, (size.x - exit.x - 1) * TILE, TILE))
	var taken := {}
	var sheet := _tex(FarmTiles.SHEET)
	var place := func(art: String, c: Vector2i) -> void:
		var p: Dictionary = FarmTiles.prop("summer", art)
		var rect: Rect2i = p.rect
		var n := StaticBody2D.new()
		n.collision_mask = 0
		n.position = Vector2(c * TILE) + Vector2(TILE / 2.0, TILE - 1)
		var sp := Sprite2D.new()
		sp.texture = sheet
		sp.region_enabled = true
		sp.region_rect = Rect2(rect)
		sp.centered = false
		sp.offset = -Vector2(rect.size.x / 2.0, rect.size.y - 1)
		sp.flip_h = rng.randf() < 0.5 and art.begins_with("hay")
		n.add_child(sp)
		if p.block != Vector2.ZERO:
			_add_box(n, Rect2(Vector2(-p.block.x / 2.0, -p.block.y), p.block))
			var w := int(ceil(p.block.x / TILE))
			for dx in range(-(w / 2), w - w / 2):
				taken[c + Vector2i(dx, 0)] = true
		taken[c] = true
		acts.add_child(n)
	# Stalls along the back wall: fence rails dividing them, a trough and hay
	# in each.
	var rails := {}
	for sx in [4, 9]:
		for y in range(2, 5):
			var r := Vector2i(sx, y)
			put.call(straw_layer, r, BARN_RAIL, 0)
			rails[r] = true
			taken[r] = true
		_add_box(body, Rect2(sx * TILE + 2, 2 * TILE, 5, 3 * TILE))
	for stall in [Vector2i(1, 2), Vector2i(6, 2), Vector2i(11, 2)]:
		place.call("trough_water" if rng.randf() < 0.5 else "trough", stall + Vector2i(1, 0))
		place.call(["hay", "hay_crate", "wheat_bunch_b"][rng.randi() % 3], stall + Vector2i(rng.randi_range(0, 1) * 2, 2))
	# Along the side walls: hay piles and bales, crates, barrels, a bucket.
	var side := ["hay_big", "hay", "barrel", "barrel_b", "crate_stack", "crate", "box", "bucket", "wheat_bunch", "hay_crate"]
	for y in range(6, size.y - 1, 2):
		for x in [1, size.x - 2]:
			if rng.randf() < 0.75:
				place.call(side[rng.randi() % side.size()], Vector2i(x, y))
	# The animals: two or three kinds of the farm's, a few of each, on the
	# open floor (not the aisle's doorway).
	var floor_cells := {}
	for y in range(2, size.y):
		for x in size.x:
			var c := Vector2i(x, y)
			if not taken.has(c) and not rails.has(c) and x > 0 and x < size.x - 1:
				floor_cells[c] = true # (the outer columns stay clear: a cow is wider than a cell)
	var habitats := {"_land": floor_cells, "_trunks": {}, "_w": size.x}
	for k in ["lawn", "trees", "dark", "clutter", "bushes", "shore", "water", "open", "rocky", "roam", "yard", "pasture"]:
		habitats[k] = floor_cells if k in ["yard", "pasture", "clutter", "roam"] else {}
	var kinds := ["cow", "pig", "sheep", "goat", "chicken"]
	for i in range(kinds.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = kinds[i]
		kinds[i] = kinds[j]
		kinds[j] = tmp
	var cells: Array = floor_cells.keys().filter(func(c): return c.y < size.y - 2 or absi(c.x - exit.x) > 1)
	var groups: Array = []
	for k in kinds.slice(0, rng.randi_range(2, 3)):
		var n := rng.randi_range(2, 3) if k != "cow" else rng.randi_range(1, 2)
		var pick: Array = []
		for t in n:
			pick.append(cells[rng.randi() % cells.size()])
		groups.append({"kind": k, "center": pick[0], "cells": pick})
	var animals := Wildlife.new()
	animals.name = "Animals"
	animals.mode = "farmland"
	animals.local_walker = true
	view.add_child(animals)
	var walker := actors.get_node_or_null("Walker")
	animals.setup_from({"habitats": habitats, "groups": groups}, {}, acts, walker, _image(FarmTiles.SHEET), null)
	var plan := InteriorPlan.new()
	plan.size = size
	plan.exit_cell = exit
	var holder := GreenhouseView.new()
	holder.name = "View"
	holder.add_child(view)
	holder.actors = acts
	# The front wall and the barn door in it.
	var barn_wood := Color(0.42, 0.27, 0.2)
	_front_wall(view, acts, size.x * TILE, size.y * TILE - ExitDoor.THICK, Vector2(exit.x * TILE, TILE), barn_wood)
	holder.exit_door = _exit_door(view, acts, Vector2(exit.x * TILE, size.y * TILE - ExitDoor.THICK), barn_wood)
	return {"view": holder, "plan": plan, "fires": []}


## The windmill interior: the mill floor. Whitewashed walls over a wooden
## dado and a plank floor (Cozy Cottage); in the middle the machinery from
## the mill kit (FarmTiles.MILL): the great spur wheel turning under the
## ceiling, the shaft, the hopper trickling grain into the runner stone on
## its hurst, flour dribbling from the spout into an open sack. The sack
## hoist hangs over a stack of sacks, a ladder climbs to the trapdoor, sacks,
## grain crates, and barrels line the walls, and flour lies spilled. Two
## windows throw sunbeams (dust turning in them), a mill cat dozes, mice dart
## among the sacks; in winter a hearth burns in place of the right window.
const MILL_SIZE := Vector2i(13, 12)
const MILL_PAPER := 1 # Cozy Cottage wallpaper column: plaster over a wooden dado
const MILL_TRIM := 10 # the first row of its brown group (the top band; the face is the three below)
const MILL_PLANKS := Vector2i(39, 20) # Cozy Cottage plank floor (2 x 4 tiles)
const MILL_FLOOR_Y := 4 # first floor row (a band and three face rows above)
const MILL_WINDOWS := ["window_arch", "window_panes", "window_plain"]

func _build_mill(index: int) -> Dictionary:
	var size := MILL_SIZE
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_id, index, "mill"])
	var winter := season == "winter"
	var view := Node2D.new()
	view.name = "Mill"
	var tiles := _summer_tiles()
	var floor_layer := TileMapLayer.new()
	floor_layer.tile_set = tiles
	view.add_child(floor_layer)
	var put := func(c: Vector2i, a: Vector2i) -> void:
		var src: TileSetAtlasSource = tiles.get_source(1)
		if not src.has_tile(a):
			src.create_tile(a)
		floor_layer.set_cell(c, 1, a)
	for x in size.x:
		put.call(Vector2i(x, 0), Vector2i(MILL_PAPER, MILL_TRIM))
		for r in 3:
			put.call(Vector2i(x, 1 + r), Vector2i(MILL_PAPER, MILL_TRIM + 1 + r))
	for y in range(MILL_FLOOR_Y, size.y):
		for x in size.x:
			put.call(Vector2i(x, y), MILL_PLANKS + Vector2i(posmod(x, 2), posmod(y, 4)))
	var plan := InteriorPlan.new()
	plan.size = size
	var exit := Vector2i(size.x / 2, size.y - 1)
	plan.exit_cell = exit
	for y in size.y:
		for x in size.x:
			plan.kind[Vector2i(x, y)] = InteriorPlan.WALL if y == 0 else (InteriorPlan.FACE if y < MILL_FLOOR_Y else InteriorPlan.FLOOR)
	var kit := _mill_tex()
	var floor_top := float(MILL_FLOOR_Y * TILE)
	# Under everything that stands: flour spilled on the floor, the windows
	# on the wall face.
	var under := Node2D.new()
	view.add_child(under)
	var mv := MillView.new()
	var windows: Array[Dictionary] = []
	var win_art: String = MILL_WINDOWS[rng.randi() % MILL_WINDOWS.size()]
	for wx in ([2] if winter else [2, 9]):
		var wr: Rect2i = InteriorArt.ART[win_art].rect
		var bottom := floor_top - (2 if wr.size.y >= 38 else (6 if wr.size.y >= 30 else 12))
		var at := Vector2((wx + 1) * TILE, bottom) + Vector2(-wr.size.x / 2.0, -wr.size.y).floor()
		under.add_child(_region_sprite(InteriorArt.DECORATION, wr, at))
		windows.append({"rect": Rect2(at, Vector2(wr.size)), "floor_y": floor_top})
	# Sunbeams and their dust, and the mill cat (interior_life.gd), between
	# the floor and the actors.
	var life := InteriorLife.new()
	view.add_child(life)
	var acts := Node2D.new()
	acts.name = "Actors"
	acts.y_sort_enabled = true
	view.add_child(acts)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	view.add_child(body)
	# Walls: the back wall to a little into the first floor row, the sides,
	# the front but for the doorway.
	_add_box(body, Rect2(0, 0, size.x * TILE, floor_top + 4))
	_add_box(body, Rect2(-TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(size.x * TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(0, size.y * TILE - 2, exit.x * TILE, TILE))
	_add_box(body, Rect2((exit.x + 1) * TILE, size.y * TILE - 2, (size.x - exit.x - 1) * TILE, TILE))
	# One standing thing: a sprite at its foot, its collider, the cells it
	# stands on (the cat and the mice keep off them).
	var stand := func(tex: Texture2D, rect: Rect2i, base: Vector2, block: Vector2, foot: Vector2, flip: bool) -> StaticBody2D:
		var n := StaticBody2D.new()
		n.collision_mask = 0
		n.position = foot
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.region_enabled = true
		sp.region_rect = Rect2(rect)
		sp.centered = false
		sp.flip_h = flip
		sp.offset = -Vector2(rect.size.x - base.x if flip else base.x, base.y)
		n.add_child(sp)
		if block != Vector2.ZERO:
			_add_box(n, Rect2(Vector2(-block.x / 2.0, -block.y), block))
			for cy in range(floori((foot.y - block.y) / TILE), floori((foot.y - 0.01) / TILE) + 1):
				for cx in range(floori((foot.x - block.x / 2.0) / TILE), floori((foot.x + block.x / 2.0 - 0.01) / TILE) + 1):
					plan.blocked[Vector2i(cx, cy)] = true
		acts.add_child(n)
		return n
	var kit_item := func(art: String, foot: Vector2, flip: bool) -> StaticBody2D:
		var a: Dictionary = FarmTiles.MILL[art]
		return stand.call(kit, a.rect, a.base, a.block, foot, flip)
	var farm_item := func(art: String, foot: Vector2, flip: bool) -> StaticBody2D:
		var a: Dictionary = FarmTiles.prop("summer", art)
		var r: Rect2i = a.rect
		return stand.call(_tex(FarmTiles.SHEET), r, Vector2(r.size.x / 2.0, r.size.y - 1), a.block, foot, flip)
	var cell_foot := func(c: Vector2i) -> Vector2:
		return Vector2(c * TILE) + Vector2(TILE / 2.0, TILE - 2)
	# The machinery, in the middle of the floor, its wheel up by the ceiling.
	var m: Dictionary = FarmTiles.MILL.machine
	var machine := stand.call(kit, m.rect, m.base, m.block, Vector2(size.x * TILE / 2.0, 7 * TILE + 14), false) as StaticBody2D
	var turning := _flipbook(kit, Rect2(m.rect), m.frames, 6.0)
	turning.offset = -m.base
	var still := machine.get_child(0)
	machine.remove_child(still)
	still.free()
	machine.add_child(turning)
	machine.move_child(turning, 0)
	mv.machine = turning
	mv.machine_rect = Rect2(machine.position - m.base, Vector2(m.rect.size))
	var spout := machine.position + Vector2(-20, -10)
	# An open sack under the spout catching the flour, and flour about it.
	mv.sacks.append(kit_item.call("sack_open", Vector2(spout.x, machine.position.y + 14), false))
	var spills: Array[Vector2] = [Vector2(spout.x - 12, machine.position.y + 8), Vector2(spout.x + 14, machine.position.y + 20)]
	# The hoist corner: a stack of sacks against the back wall, the hoist's
	# rope and hook hanging over it.
	var stack_foot := Vector2(TILE + 2, floor_top + 12)
	mv.sacks.append(kit_item.call("sacks", stack_foot, rng.randf() < 0.5))
	spills.append(stack_foot + Vector2(18, 6))
	var h: Dictionary = FarmTiles.MILL.hook
	var hook_frames := SpriteFrames.new()
	hook_frames.set_animation_speed("default", 2.5)
	for i in [0, 1, 2, 1]:
		var at := AtlasTexture.new()
		at.atlas = kit
		at.region = Rect2(Vector2(h.rect.position) + Vector2(i * h.step, 0), Vector2(h.rect.size))
		hook_frames.add_frame("default", at)
	var hook := AnimatedSprite2D.new()
	hook.sprite_frames = hook_frames
	hook.centered = false
	hook.play("default")
	var hook_node := Node2D.new()
	hook_node.position = stack_foot + Vector2(0, 1)
	hook.offset = Vector2(-h.base.x, 4.0 - hook_node.position.y)
	hook_node.add_child(hook)
	acts.add_child(hook_node)
	mv.hook = hook
	# The ladder up to the trapdoor, in the right-hand corner.
	kit_item.call("ladder", Vector2((size.x - 1) * TILE + 8, floor_top + 12), false)
	# Winter: a hearth by the ladder, burning.
	var fires: Array[Dictionary] = []
	if winter:
		var hearth := "hearth_stone" if rng.randf() < 0.5 else "hearth_stone_b"
		var ha: Dictionary = InteriorArt.ART[hearth]
		var hr: Rect2i = ha.rect
		var foot := Vector2(10.5 * TILE, floor_top + 12)
		stand.call(InteriorArt.FURNITURE, hr, Vector2(hr.size.x / 2.0, hr.size.y), Vector2(hr.size.x - 4, 6), foot, false)
		var opening := Rect2(foot + Vector2(-hr.size.x / 2.0, -hr.size.y).floor() + Vector2(ha.hearth.position), Vector2(ha.hearth.size))
		mv.hearths.append(opening)
		fires.append({"pos": opening.end, "kind": "hearth", "flame": opening.get_center(), "radius": 30, "smoke": false})
	else:
		# A spare millstone leaning on the wall under the right window.
		kit_item.call("stone", Vector2(9.5 * TILE, floor_top + 12), rng.randf() < 0.5)
	# Along the side walls: sacks, grain, barrels, crates, a bucket.
	# (Only narrow things: a wall cell is 16 px and nothing hangs over the
	# room's edge.)
	var sides := ["sack", "sack", "sack_b", "sack_open", "barrel", "barrel_b", "box", "bucket"]
	for y in range(6, size.y - 1, 2):
		for x in [0, size.x - 1]:
			if rng.randf() > 0.8:
				continue
			var art: String = sides[rng.randi() % sides.size()]
			var foot: Vector2 = cell_foot.call(Vector2i(x, y))
			# Kept to its own cell, so the lane along the wall stays open.
			var kit_art := FarmTiles.MILL.has(art)
			var a: Dictionary = FarmTiles.MILL[art] if kit_art else FarmTiles.prop("summer", art)
			var r: Rect2i = a.rect
			var base: Vector2 = a.base if kit_art else Vector2(r.size.x / 2.0, r.size.y - 1)
			var block: Vector2 = a.block
			if block != Vector2.ZERO:
				block.x = minf(block.x, 14.0)
			var n: StaticBody2D = stand.call(kit if kit_art else _tex(FarmTiles.SHEET), r, base, block, foot, rng.randf() < 0.5)
			if kit_art:
				mv.sacks.append(n)
				if rng.randf() < 0.5:
					spills.append(foot + Vector2(10 if x == 0 else -10, 2))
	# A few sacks by the machine, waiting to be carted off.
	var by := Vector2i(exit.x + 2 + rng.randi_range(0, 1), 9)
	mv.sacks.append(kit_item.call("sack" if rng.randf() < 0.6 else "sack_b", cell_foot.call(by), rng.randf() < 0.5))
	if rng.randf() < 0.6:
		mv.sacks.append(kit_item.call("sack", cell_foot.call(by + Vector2i(1, 0)), rng.randf() < 0.5))
	# Grain waiting for the stones, on the open floor by the machine.
	farm_item.call(["hay_crate", "wheat_bunch_b"][rng.randi() % 2], cell_foot.call(Vector2i(3, 7)), false)
	if rng.randf() < 0.6:
		farm_item.call(["hay_crate", "crate_stack"][rng.randi() % 2], cell_foot.call(Vector2i(9, 7)), rng.randf() < 0.5)
	for i in spills.size():
		var a: Dictionary = FarmTiles.MILL["flour" if i % 2 == 0 else "flour_b"]
		under.add_child(_region_sprite(kit, a.rect, (spills[i] - a.base).floor()))
	# Flour dust over the stones and at the spout, livelier as the wheel
	# speeds up; a puff when the walker brushes a sack.
	mv.dust = _flour_dust(Vector2(machine.position.x, machine.position.y - 26), Vector2(18, 4), 8)
	mv.spout_dust = _flour_dust(spout + Vector2(0, 8), Vector2(2, 1), 4)
	mv.puff = _flour_dust(Vector2.ZERO, Vector2(4, 2), 10)
	mv.puff.emitting = false
	mv.puff.one_shot = true
	for d in [mv.dust, mv.spout_dust, mv.puff]:
		view.add_child(d)
	# The mice, among the sacks along the walls and the back.
	var floor_cells := {}
	var clutter := {}
	for y in range(MILL_FLOOR_Y, size.y):
		for x in size.x:
			var c := Vector2i(x, y)
			if plan.blocked.has(c) or c == exit or c == exit - Vector2i(0, 1):
				continue
			floor_cells[c] = true
			if x <= 1 or x >= size.x - 2 or y == MILL_FLOOR_Y:
				clutter[c] = true
	var habitats := {"_land": floor_cells, "_trunks": {}, "_w": size.x}
	for k in ["lawn", "trees", "dark", "clutter", "bushes", "shore", "water", "open", "rocky", "roam", "yard", "pasture"]:
		habitats[k] = clutter if k == "clutter" else {}
	var spots: Array = clutter.keys()
	var groups: Array = []
	for g in rng.randi_range(1, 2):
		var pick: Array = []
		for t in rng.randi_range(1, 2):
			pick.append(spots[rng.randi() % spots.size()])
		groups.append({"kind": "mouse", "center": pick[0], "cells": pick})
	var animals := Wildlife.new()
	animals.name = "Animals"
	animals.mode = "farmland"
	animals.local_walker = true
	view.add_child(animals)
	var walker := actors.get_node_or_null("Walker")
	animals.setup_from({"habitats": habitats, "groups": groups}, {}, acts, walker, _image(FarmTiles.SHEET), null)
	# The front wall and the mill door in it.
	var mill_wood := Color(0.42, 0.3, 0.23)
	_front_wall(view, acts, size.x * TILE, size.y * TILE - ExitDoor.THICK, Vector2(exit.x * TILE, TILE), mill_wood)
	mv.exit_door = _exit_door(view, acts, Vector2(exit.x * TILE, size.y * TILE - ExitDoor.THICK), mill_wood)
	mv.name = "View"
	mv.add_child(view)
	mv.actors = acts
	mv.plan = plan
	mv.windows = windows
	mv.room_rects = [Rect2(0, floor_top, size.x * TILE, (size.y - MILL_FLOOR_Y) * TILE)]
	mv.walker = walker
	mv.gust_base = wind.base_strength if wind else 0.5
	mv.seed_noise(rng.randi())
	life.setup([mv], acts, walker, true)
	# Up the ladder: the cap.
	mv.ladder_foot = Rect2((size.x - 1) * TILE, floor_top + 2, TILE, 18)
	mv.ground_arrive = Vector2((size.x - 1) * TILE + 8, floor_top + 26)
	var cap := _build_cap(mv, rng, walker)
	cap.visible = false
	cap.process_mode = Node.PROCESS_MODE_DISABLED
	mv.add_child(cap)
	mv.ground = view
	mv.cap = cap
	return {"view": mv, "plan": plan, "fires": fires}


## The cap, up the ladder from the mill floor: the brake wheel on the
## windshaft (the sails turn it from outside) driving the wallower on top of
## the upright shaft, which goes down through the floor to the spur wheel
## below; the sack trap with the hoist rope; grain bins, sacks, and barrels;
## boards all round, two small windows the sails sweep past (their shadows
## cross the sunbeams), mice in the grain. The ladder comes up through its
## hatch in the corner; walk into it to climb down. Same size as the mill
## floor, so the camera stays put; its floor is shorter (no way out below).
const CAP_FLOOR_ROWS := 6
const CAP_PAPER := 0 # Cozy Cottage wallpaper column 0: boards all the way up
const CAP_PLANKS := Vector2i(43, 20)

func _build_cap(mv: MillView, rng: RandomNumberGenerator, walker: Node2D) -> Node2D:
	var size := MILL_SIZE
	var cap := Node2D.new()
	cap.name = "Cap"
	var tiles := _summer_tiles()
	var floor_layer := TileMapLayer.new()
	floor_layer.tile_set = tiles
	cap.add_child(floor_layer)
	var src: TileSetAtlasSource = tiles.get_source(1)
	var put := func(c: Vector2i, a: Vector2i) -> void:
		if not src.has_tile(a):
			src.create_tile(a)
		floor_layer.set_cell(c, 1, a)
	for x in size.x:
		put.call(Vector2i(x, 0), Vector2i(CAP_PAPER, MILL_TRIM))
		for r in 3:
			put.call(Vector2i(x, 1 + r), Vector2i(CAP_PAPER, MILL_TRIM + 1 + r))
		for y in range(MILL_FLOOR_Y, MILL_FLOOR_Y + CAP_FLOOR_ROWS):
			put.call(Vector2i(x, y), CAP_PLANKS + Vector2i(posmod(x, 2), posmod(y, 4)))
	var floor_top := float(MILL_FLOOR_Y * TILE)
	var bottom := float((MILL_FLOOR_Y + CAP_FLOOR_ROWS) * TILE)
	var under := Node2D.new()
	cap.add_child(under)
	var windows: Array[Dictionary] = []
	for wx in [2, 9]:
		var wr: Rect2i = InteriorArt.ART["window_panes"].rect
		var at := Vector2((wx + 1) * TILE, floor_top - 6) + Vector2(-wr.size.x / 2.0, -wr.size.y).floor()
		under.add_child(_region_sprite(InteriorArt.DECORATION, wr, at))
		windows.append({"rect": Rect2(at, Vector2(wr.size)), "floor_y": floor_top})
	var life := InteriorLife.new()
	cap.add_child(life)
	var shadow := SailShadow.new()
	shadow.windows = windows
	shadow.mill = mv
	cap.add_child(shadow)
	var acts := Node2D.new()
	acts.name = "Actors"
	acts.y_sort_enabled = true
	cap.add_child(acts)
	var body := StaticBody2D.new()
	body.collision_mask = 0
	cap.add_child(body)
	_add_box(body, Rect2(0, 0, size.x * TILE, floor_top + 4))
	_add_box(body, Rect2(-TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(size.x * TILE, 0, TILE, size.y * TILE))
	_add_box(body, Rect2(0, bottom - 2, size.x * TILE, TILE))
	_front_wall(cap, acts, size.x * TILE, bottom - ExitDoor.THICK, Vector2(-99, 0), Color(0.36, 0.24, 0.19))
	var kit := _mill_tex()
	var blocked := {}
	var stand := func(tex: Texture2D, rect: Rect2i, base: Vector2, block: Vector2, foot: Vector2, flip: bool) -> StaticBody2D:
		var n := StaticBody2D.new()
		n.collision_mask = 0
		n.position = foot
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.region_enabled = true
		sp.region_rect = Rect2(rect)
		sp.centered = false
		sp.flip_h = flip
		sp.offset = -Vector2(rect.size.x - base.x if flip else base.x, base.y)
		n.add_child(sp)
		if block != Vector2.ZERO:
			_add_box(n, Rect2(Vector2(-block.x / 2.0, -block.y), block))
			for cy in range(floori((foot.y - block.y) / TILE), floori((foot.y - 0.01) / TILE) + 1):
				for cx in range(floori((foot.x - block.x / 2.0) / TILE), floori((foot.x + block.x / 2.0 - 0.01) / TILE) + 1):
					blocked[Vector2i(cx, cy)] = true
		acts.add_child(n)
		return n
	# (Clutter keeps to its own cell, so no corner is walled off.)
	var kit_item := func(art: String, foot: Vector2, flip: bool) -> StaticBody2D:
		var a: Dictionary = FarmTiles.MILL[art]
		var block: Vector2 = a.block
		if block != Vector2.ZERO and art not in ["hatch", "trap"]:
			block.x = minf(block.x, 14.0)
		return stand.call(kit, a.rect, a.base, block, foot, flip)
	var farm_item := func(art: String, foot: Vector2, flip: bool) -> StaticBody2D:
		var a: Dictionary = FarmTiles.prop("summer", art)
		var r: Rect2i = a.rect
		var block: Vector2 = a.block
		if block != Vector2.ZERO:
			block.x = minf(block.x, 14.0)
		return stand.call(_tex(FarmTiles.SHEET), r, Vector2(r.size.x / 2.0, r.size.y - 1), block, foot, flip)
	# The brake wheel over the shaft from the mill floor (the same column).
	var m: Dictionary = FarmTiles.MILL.brake
	var wheel: StaticBody2D = stand.call(kit, m.rect, m.base, m.block, Vector2(size.x * TILE / 2.0, floor_top + 3 * TILE + 14), false)
	var turning := _flipbook(kit, Rect2(m.rect), m.frames, 6.0)
	turning.offset = -m.base
	var still := wheel.get_child(0)
	wheel.remove_child(still)
	still.free()
	wheel.add_child(turning)
	wheel.move_child(turning, 0)
	mv.cap_machine = turning
	mv.cap_machine_rect = Rect2(wheel.position - m.base, Vector2(m.rect.size))
	# The ladder's top in its hatch, over the ladder below.
	kit_item.call("hatch", Vector2((size.x - 1) * TILE + 8, floor_top + TILE + 14), false)
	mv.hatch_front = Rect2((size.x - 1) * TILE, floor_top + TILE + 15, TILE, 18)
	mv.cap_arrive = Vector2((size.x - 1) * TILE + 8, floor_top + 3 * TILE + 8) # clear of the hatch's front, so holding up does not climb straight back
	# The sack trap over the hoist corner below.
	kit_item.call("trap", Vector2(1.5 * TILE, floor_top + TILE + 14), false)
	# Grain bins, sacks, and barrels round the walls.
	var sides := ["sack", "sack_b", "sacks", "barrel", "barrel_b", "box", "hay_crate", "wheat_bunch_b"]
	for c in [Vector2i(0, 7), Vector2i(0, 8), Vector2i(12, 8), Vector2i(10, 4), Vector2i(3, 8), Vector2i(9, 8)]:
		if rng.randf() > 0.75:
			continue
		var art: String = sides[rng.randi() % sides.size()]
		if c.x in [0, 12] and art in ["hay_crate", "wheat_bunch_b", "sacks"]:
			art = "sack"
		var foot := Vector2(c * TILE) + Vector2(8, 14)
		if FarmTiles.MILL.has(art):
			mv.sacks.append(kit_item.call(art, foot, rng.randf() < 0.5))
		else:
			farm_item.call(art, foot, rng.randf() < 0.5)
	for i in rng.randi_range(1, 3):
		var a: Dictionary = FarmTiles.MILL["flour" if i % 2 == 0 else "flour_b"]
		var at := Vector2(rng.randf_range(2, 11) * TILE, rng.randf_range(5.5, 8.5) * TILE)
		under.add_child(_region_sprite(kit, a.rect, (at - a.base).floor()))
	# Mice in the grain.
	var floor_cells := {}
	var clutter := {}
	for y in range(MILL_FLOOR_Y, MILL_FLOOR_Y + CAP_FLOOR_ROWS):
		for x in size.x:
			var c := Vector2i(x, y)
			if blocked.has(c):
				continue
			floor_cells[c] = true
			if x <= 1 or x >= size.x - 2 or y == MILL_FLOOR_Y:
				clutter[c] = true
	var habitats := {"_land": floor_cells, "_trunks": {}, "_w": size.x}
	for k in ["lawn", "trees", "dark", "clutter", "bushes", "shore", "water", "open", "rocky", "roam", "yard", "pasture"]:
		habitats[k] = clutter if k == "clutter" else {}
	var spots: Array = clutter.keys()
	var pick: Array = [spots[rng.randi() % spots.size()], spots[rng.randi() % spots.size()]]
	var animals := Wildlife.new()
	animals.name = "Animals"
	animals.mode = "farmland"
	animals.local_walker = true
	cap.add_child(animals)
	animals.setup_from({"habitats": habitats, "groups": [{"kind": "mouse", "center": pick[0], "cells": pick}]}, {}, acts, walker, _image(FarmTiles.SHEET), null)
	# Sunbeams through the two windows (no cat up here: it keeps to the mill
	# floor).
	var info := MillLevel.new()
	info.windows = windows
	info.room_rects = [Rect2(0, floor_top, size.x * TILE, bottom - floor_top)]
	info.plan = InteriorPlan.new()
	life.setup([info], acts, walker, true)
	mv.cap_acts = acts
	mv.cap_blocked = blocked
	return cap


var _mill_texture: Texture2D

func _mill_tex() -> Texture2D:
	if _mill_texture == null:
		_mill_texture = load(FarmTiles.MILL_SHEET)
	return _mill_texture


func _region_sprite(tex: Texture2D, rect: Rect2i, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = Rect2(rect)
	s.centered = false
	s.offset = at
	return s


# Pale flour motes drifting up and fading (one pixel each).
func _flour_dust(at: Vector2, extents: Vector2, amount: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = amount
	p.lifetime = 2.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = extents
	p.direction = Vector2(0, -1)
	p.spread = 50.0
	p.gravity = Vector2(1.5, -2.0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.damping_min = 1.0
	p.damping_max = 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.82, 0.8, 0.78, 0.0))
	ramp.add_point(0.2, Color(0.82, 0.8, 0.78, 0.75))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.84, 0.84, 0.88, 0.0))
	p.color_ramp = ramp
	p.z_index = 21
	return p


## The mill floor's node for house_interiors.gd (`actors`), and for
## interior_life.gd (sunbeams, the hearth, the cat: plan, windows,
## hearths, room_rects, steam, lamps). It turns the machinery with its own
## gusts (the wind outside pauses while the walker is in), fades the
## machinery while the walker is behind it, and shakes a sack the walker
## brushes, with a puff of flour.
class MillView extends GreenhouseView:
	var plan: InteriorPlan
	var windows: Array[Dictionary] = []
	var hearths: Array[Rect2] = []
	var room_rects: Array[Rect2] = []
	var steam: Array[Vector2] = []
	var lamps: Array[Vector2] = []
	var machine: AnimatedSprite2D
	var machine_rect := Rect2()
	var hook: AnimatedSprite2D
	var sacks: Array = []
	var dust: CPUParticles2D
	var spout_dust: CPUParticles2D
	var puff: CPUParticles2D
	var walker: Node2D
	var gust_base := 0.5
	var speed := 1.0
	# The two floors: the mill floor (ground, `actors`) and the cap up the
	# ladder; walking into the ladder climbs, into its top in the hatch
	# climbs back down.
	var ground: Node2D
	var cap: Node2D
	var cap_acts: Node2D
	var cap_machine: AnimatedSprite2D
	var cap_machine_rect := Rect2()
	var cap_blocked := {}
	var ladder_foot := Rect2()
	var hatch_front := Rect2()
	var ground_arrive := Vector2.ZERO
	var cap_arrive := Vector2.ZERO
	var up := false
	var _climbing := false
	var _climb_cool := 0.0
	var _held := false
	var _fade: ColorRect
	var _noise := FastNoiseLite.new()
	var _t := 0.0
	var _cool := {}

	func _ready() -> void:
		var layer := CanvasLayer.new()
		layer.layer = 20
		add_child(layer)
		_fade = ColorRect.new()
		_fade.color = Color(0, 0, 0, 0)
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		layer.add_child(_fade)

	## Up or down the ladder: fade, swap the floors (the one left behind is
	## hidden and paused, its colliders out of the space), the walker at the
	## other end of the ladder, fade back.
	func climb(to_cap: bool) -> void:
		_climbing = true
		var tw := create_tween()
		tw.tween_property(_fade, "color:a", 1.0, 0.22)
		await tw.finished
		var from: Node2D = ground if to_cap else cap
		var to: Node2D = cap if to_cap else ground
		from.visible = false
		from.process_mode = Node.PROCESS_MODE_DISABLED
		to.visible = true
		to.process_mode = Node.PROCESS_MODE_INHERIT
		walker.reparent(cap_acts if to_cap else actors, false)
		walker.position = cap_arrive if to_cap else ground_arrive
		walker.set("facing", 2) # down, off the ladder
		up = to_cap
		# The hearth's glow below stays below.
		var holder := get_parent()
		if holder:
			for c in holder.get_children():
				if c is FireAmbience:
					c.visible = not to_cap
		var cam: Camera2D = walker.get_node_or_null("Camera")
		if cam:
			cam.reset_smoothing()
		tw = create_tween()
		tw.tween_property(_fade, "color:a", 0.0, 0.22)
		await tw.finished
		_climb_cool = 0.4
		_held = true
		_climbing = false

	func seed_noise(s: int) -> void:
		_noise.seed = s
		_noise.frequency = 0.08

	func _process(delta: float) -> void:
		_t += delta
		var gust := gust_base + 0.35 * _noise.get_noise_1d(_t * 10.0) + 0.15 * sin(_t * 0.7)
		speed = clampf(0.45 + gust * 1.2, 0.3, 1.8)
		var in_view := is_instance_valid(walker) and walker.is_visible_in_tree()
		var at := walker.global_position - global_position if in_view else Vector2(-999, -999)
		for pair in [[machine, machine_rect, 18.0], [cap_machine, cap_machine_rect, 12.0]]:
			var mach: AnimatedSprite2D = pair[0]
			if mach == null:
				continue
			mach.speed_scale = speed
			var r: Rect2 = pair[1]
			var behind: bool = r.grow(-6).has_point(at) and at.y < r.end.y - pair[2]
			mach.modulate.a = move_toward(mach.modulate.a, 0.5 if behind else 1.0, delta * 3.0)
		# The ladder: into its foot to climb, into its top to climb down.
		_climb_cool -= delta
		var pressing := Input.is_action_pressed("move_up")
		if not pressing:
			_held = false # a new press climbs again (holding up does not ping-pong)
		if cap and in_view and not _climbing and not _held and _climb_cool <= 0.0 and pressing:
			if not up and ladder_foot.has_point(at):
				climb(true)
			elif up and hatch_front.has_point(at):
				climb(false)
		if hook:
			hook.speed_scale = 0.6 + speed * 0.4
		if dust:
			dust.speed_scale = speed
			spout_dust.speed_scale = speed
		if not is_instance_valid(walker) or not walker.is_visible_in_tree():
			return
		var feet := walker.global_position - global_position
		for s in sacks:
			var k: int = s.get_instance_id()
			_cool[k] = _cool.get(k, 0.0) - delta
			if _cool[k] <= 0.0 and s.position.distance_to(feet) < 11.0:
				_cool[k] = 1.5
				var x0: float = s.position.x
				var tw := create_tween()
				tw.tween_property(s, "position:x", x0 + (1.0 if feet.x < x0 else -1.0), 0.08)
				tw.tween_property(s, "position:x", x0, 0.12)
				puff.position = s.position + Vector2(0, -6)
				puff.restart()


## What interior_life.gd reads of a floor (the cap): windows for its
## sunbeams; an empty plan, so no cat.
class MillLevel extends RefCounted:
	var position := Vector2.ZERO
	var plan: InteriorPlan
	var windows: Array[Dictionary] = []
	var hearths: Array[Rect2] = []
	var room_rects: Array[Rect2] = []
	var steam: Array[Vector2] = []
	var lamps: Array[Vector2] = []


## The sails sweeping past the cap's windows: four times a turn a blade's
## shadow crosses each window and the sunbeam below it, faster in a gust
## (the mill's own speed), dithered on whole pixels.
class SailShadow extends Node2D:
	const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var windows: Array[Dictionary] = []
	var mill: MillView
	var _phase := 0.0

	func _process(delta: float) -> void:
		_phase += delta * (mill.speed if mill else 1.0) * 0.5
		queue_redraw()

	func _draw() -> void:
		var p := fmod(_phase, 1.0)
		if p > 0.4:
			return
		var k := p / 0.4
		for w in windows:
			var r: Rect2 = w.rect
			var fy: float = w.floor_y
			var x0 := r.position.x - 12.0 + k * (r.size.x + 36.0)
			for y in range(int(r.position.y) + 2, int(fy + 34.0)):
				var on_floor := y >= int(fy)
				var bx := x0 + (y - r.position.y) * 0.55
				for dx in 7:
					var x := int(bx) + dx
					if not on_floor and (x < r.position.x + 2 or x > r.end.x - 3 or y > r.end.y - 3):
						continue
					if on_floor and (x < r.position.x + 3 + (y - fy) * 0.55 or x > r.end.x - 3 + (y - fy) * 0.55):
						continue
					if on_floor and BAYER[(y % 4) * 4 + (x % 4)] / 16.0 > 0.5 * (1.0 - (y - fy) / 34.0):
						continue
					draw_rect(Rect2(x, y, 1, 1), Color(0.1, 0.06, 0.06, 0.3 if not on_floor else 0.2))


## The way out of a custom interior: a door at `at` (the doorway's
## top-left on the front wall's line), placed under the actors.
func _exit_door(parent: Node2D, before: Node, at: Vector2, wood: Color) -> ExitDoor:
	var ed := ExitDoor.new()
	ed.name = "ExitDoor"
	ed.position = at
	ed.set_wood(wood)
	ed.stub = true
	ed.depth = 14
	parent.add_child(ed)
	parent.move_child(ed, before.get_index())
	return ed


## The front wall's top along the foot of a custom interior, seen from above
## as the Cozy Cottage homes draw theirs: a beam with a lit edge and a dark
## underside, `gap` px left open for the doorway (x from, width), placed
## under the actors.
func _front_wall(parent: Node2D, before: Node, width: int, y: float, gap: Vector2, wood: Color) -> void:
	var img := Image.create(width, 6, false, Image.FORMAT_RGBA8)
	var rows := [wood.lightened(0.28), wood, wood, wood.darkened(0.2), wood.darkened(0.45), Color(0, 0, 0, 0.55)]
	for x in width:
		if x >= gap.x - 2 and x < gap.x + gap.y + 2:
			continue
		for r in rows.size():
			var c: Color = rows[r]
			if r in [1, 2] and x % 7 == 3:
				c = wood.darkened(0.12)
			img.set_pixel(x, r, c)
	var spr := Sprite2D.new()
	spr.texture = ImageTexture.create_from_image(img)
	spr.centered = false
	spr.position = Vector2(0, y)
	parent.add_child(spr)
	parent.move_child(spr, before.get_index())


var _summer_tileset: TileSet

## A tileset on the spring and summer sheet (the barn's kit is drawn from it
## in every season).
func _summer_tiles() -> TileSet:
	if _summer_tileset == null:
		_summer_tileset = TileSet.new()
		_summer_tileset.tile_size = Vector2i(TILE, TILE)
		var src := TileSetAtlasSource.new()
		src.texture = _tex(FarmTiles.SHEET)
		src.texture_region_size = Vector2i(TILE, TILE)
		_summer_tileset.add_source(src, 0)
		var cozy := TileSetAtlasSource.new()
		cozy.texture = InteriorArt.WALLS # Cozy Cottage walls and floors
		cozy.texture_region_size = Vector2i(TILE, TILE)
		_summer_tileset.add_source(cozy, 1)
	return _summer_tileset


## The greenhouse interior's node for house_interiors.gd (it reads `actors`).
class GreenhouseView extends Node2D:
	var actors: Node2D
	var crops: Array[Dictionary] = [] # plants the walker wades through (as _crops)
	var exit_door: ExitDoor # the way out's door (house_interiors.gd opens it)


# ---------------------------------------------------------------- trees

## A tree from the pack's animation sheets: frame 0 at rest, the eight
## frames played once when a gust passes through or the walker brushes the
## trunk (then a few leaves fall from the crown). The trunk blocks; the crown
## fades while the walker is behind it.
func _place_trees() -> void:
	for t in terrain.trees:
		var trees_tab: Dictionary = FarmTiles.get_for(season, "trees")
		var tree_dir: String = FarmTiles.get_for(season, "tree_dir")
		var art: Dictionary = trees_tab[FarmTiles.tree_art(season, t.art)]
		var sheet: String = tree_dir + art.sheet
		var tex := _tex(sheet)
		var size := Vector2i(tex.get_width() / FarmTiles.TREE_FRAMES, tex.get_height())
		var foot := Vector2(t.cell * TILE) + Vector2(TILE / 2.0, TILE - 1)
		var trunk := _trunk_of(sheet, size)
		var body := StaticBody2D.new()
		body.name = "tree_%s_%d_%d" % [t.art, t.cell.x, t.cell.y]
		body.collision_mask = 0
		body.position = foot
		var spr := AnimatedSprite2D.new()
		spr.sprite_frames = _frames(sheet, FarmTiles.TREE_FRAMES, size, 11.0, false)
		spr.centered = false
		var flip := _hash(t.cell.x * 5, t.cell.y * 3) < 0.5
		spr.flip_h = flip
		var tx: float = trunk.x if not flip else size.x - trunk.x
		spr.offset = -Vector2(tx, size.y - 2)
		spr.frame = 0
		spr.animation_finished.connect(func(): spr.frame = 0) # back to rest
		body.add_child(spr)
		# The trunk's own cell (the generator blocks only it): a wide root
		# flare is walked in front of rather than reaching into the next cell.
		var block := Vector2(clampf(trunk.y, 6.0, 14.0), clampf(trunk.y * 0.5, 4.0, 8.0))
		_add_box(body, Rect2(Vector2(-block.x / 2.0, -block.y), block))
		actors.add_child(body)
		var crown := Rect2(foot + spr.offset, Vector2(size.x, size.y * 0.75))
		_crowns.append({"sprite": spr, "foot": foot.y, "crown": crown})
		var falling: String = art.falling
		var kind_key := "basic"
		for k in ["apple", "cherry", "orange", "peach"]:
			if t.art.begins_with(k):
				kind_key = k
		if art.get("petals", false):
			kind_key = "cherry_bloom"
		var wind_leaves: Dictionary = FarmTiles.get_for(season, "wind_leaves")
		_trees.append({"sprite": spr, "foot": foot, "falling": (tree_dir + falling) if falling != "" else "",
			"size": size, "offset": spr.offset, "flip": flip, "leaves": wind_leaves.get(kind_key, wind_leaves.basic), "cool": randf() * 3.0, "due": -1.0,
			"crown": crown, "sheet": sheet})
		# A soft shadow under the crown, in the deep grass tone.
		var sh := Sprite2D.new()
		sh.texture = _shadow_tex(int(size.x * 0.7), int(size.y * 0.22))
		sh.position = foot + Vector2(3, -2)
		_shade.add_child(sh)


var _shadows := {}

## A dithered oval, opaque; the shadow group draws it at SHADE's alpha.
func _shadow_tex(w: int, h: int) -> Texture2D:
	var key := "%d:%d:%s" % [w, h, season]
	if _shadows.has(key):
		return _shadows[key]
	var img := Image.create(maxi(w, 4), maxi(h, 3), false, Image.FORMAT_RGBA8)
	var sc: Color = SEASON_FX[season].tree_shade
	var c := Color(sc.r, sc.g, sc.b, 1.0)
	for y in img.get_height():
		for x in img.get_width():
			var d := Vector2((x + 0.5) / img.get_width() * 2.0 - 1.0, (y + 0.5) / img.get_height() * 2.0 - 1.0).length()
			if d < 0.8 or (d < 1.0 and (x + y) % 2 == 0):
				img.set_pixel(x, y, c)
	_shadows[key] = ImageTexture.create_from_image(img)
	return _shadows[key]


## A tree's trunk in frame 0: x the middle of the root flare (the opaque span
## three to eight rows above the bottom), y its width.
func _trunk_of(sheet: String, size: Vector2i) -> Vector2:
	if _trunks.has(sheet):
		return _trunks[sheet]
	var img := _image(sheet)
	var lo := size.x
	var hi := -1
	for r in range(size.y - 8, size.y - 2):
		for x in size.x:
			if img.get_pixel(x, r).a > 0.4:
				lo = mini(lo, x)
				hi = maxi(hi, x)
	var out := Vector2(size.x / 2.0, 8.0) if hi < 0 else Vector2((lo + hi + 1) / 2.0, float(hi - lo + 1))
	_trunks[sheet] = out
	return out


# ---------------------------------------------------------------- crops

## A crop in every plot, standing on its cell; its top part nods in the wind
## with the reeds (water_life.gd), when it has a stalk or a leafy top.
var _crop_tops: Array[Sprite2D] = []

func _place_crops() -> void:
	_crop_tops.clear()
	_crops.clear()
	var tex := _tex(FarmTiles.CROPS_SHEET)
	for cr in terrain.crops:
		var r := FarmTiles.crop_rect(cr.crop, cr.stage)
		var foot := Vector2(cr.cell * TILE) + Vector2(0, TILE - 1)
		var node := Node2D.new()
		node.position = foot
		var nod: bool = cr.crop in FarmTiles.CROPS_NOD
		if nod:
			var cut := floori(r.size.y * 0.5)
			node.add_child(_crop_sprite(tex, Rect2(r.position.x, r.position.y + cut, r.size.x, r.size.y - cut), Vector2(0, -(r.size.y - cut) + 1)))
			var top := _crop_sprite(tex, Rect2(r.position.x, r.position.y, r.size.x, cut), Vector2(0, -r.size.y + 1))
			node.add_child(top)
			_crop_tops.append(top)
		else:
			node.add_child(_crop_sprite(tex, Rect2(r), Vector2(0, -r.size.y + 1)))
		actors.add_child(node)
		node.position.x += TILE / 2.0 # the node stands on the plot's middle, so it bends at its foot
		for ch in node.get_children():
			ch.offset.x -= TILE / 2.0
		_crops.append({"node": node, "foot": node.position, "skew": 0.0, "vel": 0.0})


func _crop_sprite(tex: Texture2D, region: Rect2, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.centered = false
	s.offset = offset
	return s


# ---------------------------------------------------------------- props

var _forest_trees: Array[Dictionary] = [] # {crown, foot, rect}: Forest trees shed leaves too
var _fires: Array[Dictionary] = [] # campfires, torches, chimneys (fire_ambience.gd)
var _forest_texture: Texture2D

func _forest_tex() -> Texture2D:
	if _forest_texture == null:
		_forest_texture = load(FarmTiles.FOREST_SHEET)
	return _forest_texture


var _forest_img: Image

func _forest_image() -> Image:
	if _forest_img == null:
		_forest_img = _forest_tex().get_image()
		if _forest_img.is_compressed():
			_forest_img.decompress()
		_forest_img.convert(Image.FORMAT_RGBA8)
	return _forest_img


## Frames side by side from `first`, each starting on its own frame and
## running at its own pace, so no two fires flicker in step.
func _flipbook(tex: Texture2D, first: Rect2, count: int, fps: float) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()
	frames.set_animation_speed("default", fps)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(first.position + Vector2(i * first.size.x, 0), first.size)
		frames.add_frame("default", at)
	var sp := AnimatedSprite2D.new()
	sp.sprite_frames = frames
	sp.centered = false
	sp.play("default")
	sp.frame = randi() % count
	sp.speed_scale = randf_range(0.85, 1.15)
	return sp


func _place_props() -> void:
	_forest_trees.clear()
	for p in terrain.props:
		var art: Dictionary = FarmTiles.prop(season, p.art)
		var rect: Rect2i = art.rect
		var foot := Vector2(p.cell * TILE) + Vector2(TILE / 2.0, TILE - 1)
		var node := StaticBody2D.new()
		node.collision_mask = 0
		node.position = foot
		# Forest props (the farmsteads) come from the Forest sheet and stand on
		# their own foot point; fires and torches are flipbooks.
		var tex := _forest_tex() if art.get("sheet", "") == "forest" else _tex(_sheet)
		var offset: Vector2 = -art.base if art.has("base") else -Vector2(rect.size.x / 2.0, rect.size.y - 1)
		var s: Node2D
		if art.get("frames", 1) > 1:
			var fb := _flipbook(tex, Rect2(rect), art.frames, art.get("fps", 8.0))
			fb.offset = offset
			s = fb
		else:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.region_enabled = true
			sp.region_rect = Rect2(rect)
			sp.centered = false
			sp.offset = offset
			sp.flip_h = art.tag in ["bush", "stone", "wood", "hay", "reed", "plant", "bare", "tree"] and _hash(p.cell.x * 5, p.cell.y * 3) < 0.5
			s = sp
		node.add_child(s)
		if art.block != Vector2.ZERO:
			_add_box(node, Rect2(Vector2(-art.block.x / 2.0, -art.block.y), art.block))
		if art.tag in ["flat", "mushroom"]:
			under.add_child(node)
		else:
			actors.add_child(node)
		if (art.tag == "bare" or art.tag == "tree") and rect.size.y > 40:
			_crowns.append({"sprite": s, "foot": foot.y, "crown": Rect2(foot + offset, Vector2(rect.size.x, rect.size.y * 0.7))})
		if art.tag == "tree":
			_forest_trees.append({"crown": Rect2(foot + offset + Vector2(5, 4), Vector2(rect.size.x - 10, rect.size.y * 0.45)), "foot": foot, "rect": rect})
		if art.has("fire"):
			_fires.append({"pos": foot, "kind": art.fire})
		if art.tag == "reed" or art.tag == "plant":
			# Reeds and wheat bunches nod with the wind (water_life.gd).
			_crop_tops.append(s)
	# The canopy wall (woodlot): seamless crown blocks along the top edge.
	for c in terrain.canopy:
		var s := Sprite2D.new()
		s.texture = _tex(_sheet)
		s.region_enabled = true
		s.region_rect = Rect2(FarmTiles.CANOPY)
		s.centered = false
		s.position = Vector2(c * TILE) + Vector2(0, 64)
		s.offset = Vector2(0, -64)
		actors.add_child(s)
	# Stepping stones where a path crosses the brook.
	for c: Vector2i in terrain.stones:
		for k in 2:
			var art: Dictionary = FarmTiles.prop(season, "pebble" if k == 0 else "pebble_b")
			if art.is_empty():
				art = FarmTiles.prop(season, "snow_lump" if k == 0 else "snow_lump_c")
			var s := Sprite2D.new()
			s.texture = _tex(_sheet)
			s.region_enabled = true
			s.region_rect = Rect2(art.rect)
			s.position = Vector2(c * TILE) + Vector2(5 + k * 7, 5 + k * 6)
			under.add_child(s)


## Pen gates: the pack's gate animation (four frames, closed to open), swung
## open as the walker comes near and closed after.
func _place_gates() -> void:
	var tex := _tex(FarmTiles.get_for(season, "gate"))
	for g in terrain.gates:
		var s := Sprite2D.new()
		s.texture = tex
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, 16, 16)
		s.centered = false
		s.position = Vector2(g * TILE)
		under.add_child(s)
		_gates.append({"sprite": s, "pos": Vector2(g * TILE) + Vector2(8, 12), "frame": 0.0})


func _spawn_walker() -> void:
	var walker := WALKER_SCENE.instantiate()
	walker.name = "Walker"
	walker.position = Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	actors.add_child(walker)
	var cam: Camera2D = walker.get_node("Camera")
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = W * TILE
	cam.limit_bottom = H * TILE


# ---------------------------------------------------------------- motion

func _process(delta: float) -> void:
	var walker := actors.get_node_or_null("Walker")
	if walker == null:
		# Indoors: the crops of an interior that grows them (the greenhouse)
		# bend round the walker the same way.
		if house_interiors and house_interiors.inside >= 0 and house_interiors.view is GreenhouseView \
				and is_instance_valid(house_interiors.walker):
			var gv: GreenhouseView = house_interiors.view
			_sway_crops(delta, house_interiors.walker.position, gv.crops)
		return
	var feet: Vector2 = walker.position
	var body := Rect2(feet + Vector2(-6, -28), Vector2(12, 28))
	for c in _crowns:
		var spr: CanvasItem = c.sprite
		if not is_instance_valid(spr):
			continue
		var behind: bool = feet.y < c.foot - 1.0 and c.crown.intersects(body)
		var want := CROWN_FADE if behind else 1.0
		if not is_equal_approx(spr.modulate.a, want):
			spr.modulate.a = move_toward(spr.modulate.a, want, delta * FADE_RATE)
	for hs in _houses:
		var n: CanvasItem = hs.node
		var behind: bool = feet.y < hs.foot - 2.0 and hs.rect.intersects(body) and not hs.door.has_point(feet)
		var want := HOUSE_FADE if behind else 1.0
		if not is_equal_approx(n.modulate.a, want):
			n.modulate.a = move_toward(n.modulate.a, want, delta * FADE_RATE)
	# The windmill turns with the wind.
	var ws := wind.strength() if wind else 0.5
	for m in _mills:
		m.speed_scale = 0.4 + ws * 1.4
	# Trees rustle as a gust arrives and when brushed. A gust sweeps across the
	# farm with the wind: each tree's turn comes when the gust front reaches
	# it (0-3 s from the upwind edge to the downwind one) plus its own jitter
	# (up to 1.5 s), so no two trees shake together.
	_time += delta
	var gusting := wind != null and wind.gust > 0.25
	if gusting and not _gust_was and not _trees.is_empty():
		var dir := wind.direction()
		var lo := INF
		var hi := -INF
		for t in _trees:
			var along: float = t.foot.dot(dir)
			lo = minf(lo, along)
			hi = maxf(hi, along)
		for t in _trees:
			if randf() < 0.8:
				var k: float = (float(t.foot.dot(dir)) - lo) / maxf(hi - lo, 1.0)
				t.due = _time + k * 3.0 + randf_range(0.0, 1.5)
	for t in _trees:
		t.cool -= delta
		var spr: AnimatedSprite2D = t.sprite
		if not is_instance_valid(spr):
			continue
		var brushed: bool = feet.distance_to(t.foot) < BRUSH
		var due: bool = t.due >= 0.0 and _time >= t.due
		if t.cool <= 0.0 and (brushed or due):
			t.due = -1.0
			spr.frame = 0
			spr.play("default")
			t.cool = randf_range(2.5, 5.0)
			if brushed and t.falling != "":
				_one_shot(t.falling, t.size, t.foot + t.offset, t.flip)
			if gusting and not brushed and randf() < 0.5:
				_wind_leaves(t)
	_gust_was = gusting
	_sway_crops(delta, feet, _crops)
	# Gates swing open for the walker, and shut after.
	for g in _gates:
		var near: bool = feet.distance_to(g.pos) < GATE_OPEN
		g.frame = move_toward(g.frame, 3.0 if near else 0.0, delta * 10.0)
		var s: Sprite2D = g.sprite
		s.region_rect = Rect2(int(round(g.frame)) * 16, 0, 16, 16)


## The walker wades through the crops: each plant it brushes bends away from
## its step (a shear about its foot, the top moving most) and springs back,
## swaying a few times as it settles; a tall stalk bends further.
const CROP_REACH := Vector2(11.0, 7.0) # px from a plant's foot that brushes it
const CROP_SPRING := 140.0
const CROP_DAMP := 7.0

func _sway_crops(delta: float, feet: Vector2, crops: Array[Dictionary]) -> void:
	var step := feet - _last_feet
	_last_feet = feet
	var moving := step.length() > 0.05 and step.length() < 8.0 # (a jump through a door is no step)
	for c in crops:
		var node: Node2D = c.node
		if not is_instance_valid(node):
			continue
		var off: Vector2 = feet - c.foot
		if moving and absf(off.x) < CROP_REACH.x and absf(off.y) < CROP_REACH.y:
			# Pushed away from the walker's side and along its step.
			var away := -signf(off.x) if absf(off.x) > 1.0 else signf(step.x)
			var push: float = away * 0.5 + step.x * 0.08
			c.vel = clampf(c.vel + push * 60.0 * delta, -6.0, 6.0)
			c.skew = clampf(c.skew + push * 2.5 * delta, -0.55, 0.55)
		if absf(c.skew) < 0.002 and absf(c.vel) < 0.01:
			if node.skew != 0.0:
				node.skew = 0.0
			continue
		c.vel += (-CROP_SPRING * c.skew - CROP_DAMP * c.vel) * delta
		c.skew = clampf(c.skew + c.vel * delta, -0.55, 0.55)
		node.skew = c.skew


## An animation played once where it is needed, then gone (falling leaves
## over a brushed tree, leaves blowing off a crown in a gust).
func _one_shot(sheet: String, size: Vector2i, top_left: Vector2, flip: bool) -> void:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = _frames(sheet, FarmTiles.TREE_FRAMES, size, 10.0, false)
	a.centered = false
	a.position = top_left
	a.flip_h = flip
	a.z_index = 5
	add_child(a)
	a.play("default")
	a.animation_finished.connect(a.queue_free)


func _wind_leaves(t: Dictionary) -> void:
	var sheet: String = t.leaves
	var tex := _tex(sheet)
	var size := Vector2i(tex.get_width() / FarmTiles.TREE_FRAMES, tex.get_height())
	var crown: Rect2 = t.crown
	var at := crown.position + Vector2(crown.size.x * 0.5 - size.x * 0.5, crown.size.y * 0.1)
	_one_shot(sheet, size, at.floor(), wind.direction().x < 0.0)


# ---------------------------------------------------------------- ambience

func _add_ambience() -> void:
	wind = Wind.new()
	wind.name = "Wind"
	add_child(wind)
	streaks = WindStreaks.new()
	grass_waves = GrassWaves.new()
	water_life = WaterLife.new()
	fish = FishJumps.new()
	for n in [streaks, grass_waves, water_life, fish]:
		add_child(n)
		move_child(n, actors.get_index())
	footsteps = Footsteps.new()
	critters = Critters.new()
	fire = FireAmbience.new()
	leaves = AmbientLeaves.new()
	drifters = Drifters.new()
	wildlife = Wildlife.new()
	clouds = CloudShadows.new()
	for n in [footsteps, critters, fire, leaves, drifters, wildlife, clouds]:
		add_child(n)
	for n in [streaks, grass_waves, water_life, footsteps, critters, fire, leaves, drifters, clouds]:
		n.wind = wind
	footsteps.water_life = water_life
	footsteps.leaves = leaves
	fish.water_life = water_life
	snow = Snowfall.new()
	snow.name = "Snowfall"
	snow.wind = wind
	add_child(snow)


func _reset_ambience() -> void:
	var map_rect := Rect2(0, 0, W * TILE, H * TILE)
	streaks.bounds = map_rect
	var fx: Dictionary = SEASON_FX[season]
	clouds.shade = fx.shade
	grass_waves.tip = fx.tip
	footsteps.blade_colors = fx.blades
	footsteps.dust_colors = [Color(0.6, 0.47, 0.32), Color(0.52, 0.4, 0.27)]
	var winter := season == "winter"
	snow.visible = winter
	snow.process_mode = Node.PROCESS_MODE_INHERIT if winter else Node.PROCESS_MODE_DISABLED
	drifters.visible = not winter
	drifters.process_mode = Node.PROCESS_MODE_DISABLED if winter else Node.PROCESS_MODE_INHERIT
	water_life.ring_color = Color(0.3, 0.52, 0.6)
	water_life.ring_highlight = Color(0.86, 0.95, 1.0)
	water_life.drop_color = Color(0.55, 0.78, 0.86)
	clouds.reset(map_rect)
	var walker := actors.get_node_or_null("Walker")
	water_life.setup(terrain.open_water(), _crop_tops)
	# Fish leap in open water, not in winter's cold water.
	fish.setup(terrain.open_water() if season != "winter" else ([] as Array[Vector2i]), _tex("fishes"))
	var sources: Array[Dictionary] = []
	var flowers: Array[Vector2] = []
	var dark: Array[Vector2] = []
	for t in _trees:
		var crown: Rect2 = t.crown
		var colors := _colors_of(t.sheet, t.size)
		if colors.light.is_empty():
			continue # a bare or dead tree: no leaves to shed
		sources.append({"crown": Rect2(crown.position + Vector2(crown.size.x * 0.12, 4), Vector2(crown.size.x * 0.76, crown.size.y * 0.55)),
			"base_y": t.foot.y}.merged(colors))
		if t.sheet.contains("bloom") or t.sheet.contains("flowers"):
			flowers.append(crown.get_center())
	# The Forest trees of a farmstead shed their own leaves (and blossom).
	for ft in _forest_trees:
		var r: Rect2i = ft.rect
		sources.append({"crown": ft.crown, "base_y": ft.foot.y}.merged(_colors_of_forest(Rect2i(r.position, Vector2i(r.size.x, r.size.y / 2)))))
		if r.position.y >= 288:
			flowers.append(ft.crown.get_center()) # blossom draws butterflies
	leaves.set_sources(sources)
	# Campfires, torches, and chimneys: flames, glow, smoke (the farmsteads'
	# warmth).
	fire.set_fires(_fires)
	for c: Vector2i in terrain.deco:
		if season != "winter" and terrain.deco[c] in terrain.flowers_set:
			flowers.append(Vector2(c * TILE) + Vector2(8, 8))
	for cr in terrain.crops:
		if cr.crop in ["sunflower", "strawberry", "pumpkin", "tomato", "berry"] and (cr.cell.x + cr.cell.y) % 3 == 0:
			flowers.append(Vector2(cr.cell * TILE) + Vector2(8, 4))
	var zones := terrain.zone_cells()
	for c: Vector2i in zones:
		if (c.x * 7 + c.y * 3) % 7 == 0:
			dark.append(Vector2(c * TILE) + Vector2(8, 8))
	for c in terrain.firefly_spots:
		for k in 5:
			dark.append(Vector2(c * TILE) + Vector2(randf_range(-40, 40), randf_range(-24, 24)))
	var ponds: Array[Rect2] = []
	for r in terrain.ponds:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(16, 16), Vector2(r.size) * TILE - Vector2(32, 32)))
	critters.walker = walker
	if season == "winter":
		# No butterflies, dragonflies, or fireflies in the snow.
		flowers.clear()
		ponds.clear()
		dark.clear()
	critters.setup(flowers, ponds, dark)
	drifters.setup(map_rect, flowers)
	_grass = terrain.grass_cells()
	_wheat = terrain.wheat_cells()
	var waves := _grass.duplicate()
	waves.merge(_wheat)
	grass_waves.setup(waves if season != "winter" else {})
	var water := {}
	for c in terrain.water:
		if not terrain.stones.has(c) and not terrain.bridge_cells.has(c):
			water[c] = true
	footsteps.setup_generic(_surface, water, walker)
	wildlife.mode = "farmland" if cozy_animals else ""
	wildlife.setup_from(terrain.wildlife_plan(wildlife.mode), water, actors, walker, _image(_sheet), water_life)


# Per season: grass-wave tips, blade flicks (snow puffs in winter), cloud shade.
const SEASON_FX := {
	"summer": {"tip": Color(0.72, 0.8, 0.5), "blades": [Color(0.52, 0.68, 0.4), Color(0.42, 0.6, 0.34)], "shade": Color(0.06, 0.2, 0.1, 0.16), "tree_shade": Color(0.08, 0.24, 0.2)},
	"autumn": {"tip": Color(0.86, 0.74, 0.46), "blades": [Color(0.8, 0.64, 0.38), Color(0.66, 0.5, 0.28)], "shade": Color(0.2, 0.1, 0.04, 0.16), "tree_shade": Color(0.36, 0.18, 0.12)},
	"winter": {"tip": Color(0.95, 0.97, 1.0), "blades": [Color(0.94, 0.96, 1.0), Color(0.8, 0.87, 0.97)], "shade": Color(0.12, 0.18, 0.35, 0.14), "tree_shade": Color(0.36, 0.48, 0.72)},
}


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
		return "none"
	var k := terrain.kind[cell.y * W + cell.x]
	if k == FarmTerrain.FIELD:
		return "tuft" # wading through the crops: leaves flick
	if terrain.bridge_cells.has(cell):
		return "none" # boards and stone: no dust, no splash
	if k != FarmTerrain.OPEN and not terrain.stones.has(cell):
		return "none"
	if _wheat.has(cell) or terrain.deco.has(cell):
		return "tuft"
	if _grass.has(cell):
		return "grass"
	return "dust"


## Leaf colors from a Forest tree's crown (on the Forest sheet).
func _colors_of_forest(region: Rect2i) -> Dictionary:
	var key := "forest:%s" % region
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	if not _images.has("forest"):
		var img: Image = _forest_tex().get_image()
		if img.is_compressed():
			img.decompress()
		_images["forest"] = img
	var img: Image = _images["forest"]
	var counts := {}
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var p := img.get_pixel(x, y)
			if p.a < 0.9 or (p.r > p.g and p.get_luminance() < 0.45):
				continue
			var k := p.to_rgba32()
			counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var light: Array[Color] = []
	var dark := Color(0.1, 0.25, 0.2)
	var darkest := 2.0
	for k in keys.slice(0, 10):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.3:
			light.append(c)
	if light.is_empty():
		light.append(Color(0.4, 0.6, 0.35))
	_leaf_colors[key] = {"light": light.slice(0, 3), "dark": dark}
	return _leaf_colors[key]


## Leaf colors from a tree's first frame: light foliage colors, edged with its
## darkest leaf color.
func _colors_of(sheet: String, size: Vector2i) -> Dictionary:
	if _leaf_colors.has(sheet):
		return _leaf_colors[sheet]
	var img := _image(sheet)
	var counts := {}
	for y in range(0, size.y / 2):
		for x in size.x:
			var p := img.get_pixel(x, y)
			if p.a < 0.9 or (p.r > p.g and p.get_luminance() < 0.45):
				continue # transparent, or bark
			var k := p.to_rgba32()
			counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	var light: Array[Color] = []
	var dark := Color(0.1, 0.25, 0.2)
	var darkest := 2.0
	for k in keys.slice(0, 10):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.35:
			light.append(c)
	if light.is_empty() and not keys.is_empty():
		light.append(Color.hex(keys[0]).lightened(0.3))
	_leaf_colors[sheet] = {"light": light.slice(0, 3), "dark": dark}
	return _leaf_colors[sheet]


## Fish that leap from the ponds now and then: one of the pack's fish arcs
## out of open water, turning over, and drops back with a ring.
class FishJumps extends Node2D:
	const EVERY := Vector2(5.0, 12.0)
	var water_life: WaterLife
	var wind: Wind
	var _cells: Array[Vector2i] = []
	var _tex: Texture2D
	var _jumps: Array[Dictionary] = []
	var _next := 4.0

	func setup(cells: Array[Vector2i], tex: Texture2D) -> void:
		_cells = cells
		_tex = tex
		_jumps.clear()
		_next = randf_range(2.0, EVERY.y)

	func _process(delta: float) -> void:
		if _cells.size() >= 4:
			_next -= delta
			if _next <= 0.0:
				_next = randf_range(EVERY.x, EVERY.y) * clampf(24.0 / _cells.size(), 0.4, 1.5)
				var c: Vector2i = _cells[randi() % _cells.size()]
				var at := Vector2(c * 16) + Vector2(randf_range(3, 13), randf_range(5, 12))
				var f: Vector2i = FarmTiles.FISH[randi() % FarmTiles.FISH.size()]
				_jumps.append({"from": at, "to": at + Vector2(randf_range(-12, 12), randf_range(-2, 2)), "t": 0.0, "life": randf_range(0.55, 0.8),
					"fish": f, "flip": randf() < 0.5, "arc": randf_range(9, 14)})
				if water_life:
					water_life._ring(at, 0.0)
		for j in _jumps:
			j.t += delta
			if j.t >= j.life and not j.get("done", false):
				j.done = true
				if water_life:
					water_life._ring(j.to, 1.0)
		_jumps = _jumps.filter(func(j): return j.t < j.life)
		queue_redraw()

	func _draw() -> void:
		for j in _jumps:
			var k: float = j.t / j.life
			var p: Vector2 = j.from.lerp(j.to, k) + Vector2(0, -sin(PI * k) * j.arc)
			var f: Vector2i = j.fish
			var src := Rect2(f.x * 16, f.y * 16, 16, 16)
			var sx := -0.75 if j.flip else 0.75
			draw_set_transform(p.floor(), (k - 0.5) * 2.2 * signf(sx), Vector2(sx, 0.75))
			draw_texture_rect_region(_tex, Rect2(-8, -8, 16, 16), src)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Winter: snow falling over the view, flakes of two sizes drifting with the
## wind and swaying as they fall; a gust sends them sideways.
class Snowfall extends Node2D:
	const COUNT := 90
	const COLORS := [Color(1, 1, 1, 0.95), Color(0.9, 0.94, 1.0, 0.85), Color(0.82, 0.88, 0.98, 0.8)]
	var wind: Wind
	var _flakes: Array[Dictionary] = []

	func _ready() -> void:
		z_index = 40 # over the actors and the crowns

	func _process(delta: float) -> void:
		var view := _view()
		while _flakes.size() < COUNT:
			_flakes.append(_new_flake(view, true))
		var push := wind.carry(18.0) if wind else Vector2.ZERO
		for f in _flakes:
			f.t += delta
			f.pos += Vector2(push.x + sin(f.t * f.sway + f.phase) * 6.0, f.fall) * delta
			if not view.grow(24.0).has_point(f.pos) or f.t > f.life:
				var n := _new_flake(view, false)
				f.pos = n.pos
				f.t = 0.0
				f.life = n.life
		queue_redraw()

	func _new_flake(view: Rect2, anywhere: bool) -> Dictionary:
		var pos := Vector2(randf_range(view.position.x - 20, view.end.x + 20), view.position.y - randf_range(2, 20))
		if anywhere:
			pos.y = randf_range(view.position.y, view.end.y)
		return {"pos": pos, "t": 0.0, "life": randf_range(6.0, 14.0), "fall": randf_range(10.0, 22.0), "sway": randf_range(0.8, 1.8),
			"phase": randf() * TAU, "big": randf() < 0.25, "color": COLORS[randi() % COLORS.size()]}

	func _draw() -> void:
		for f in _flakes:
			var p: Vector2 = f.pos.floor()
			var c: Color = f.color
			draw_rect(Rect2(p, Vector2.ONE), c)
			if f.big:
				draw_rect(Rect2(p + Vector2(1, 0), Vector2.ONE), c)
				draw_rect(Rect2(p + Vector2(0, 1), Vector2.ONE), Color(c, c.a * 0.6))

	func _view() -> Rect2:
		var inv := get_viewport().get_canvas_transform().affine_inverse()
		return Rect2(inv * Vector2.ZERO, inv.basis_xform(get_viewport_rect().size))
