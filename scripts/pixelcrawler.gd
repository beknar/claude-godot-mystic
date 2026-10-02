extends Node2D
## Paints a Pixel Crawler map from PCTerrain: the corner-table ground,
## plateau stamps, per-pixel water with the sheets' own shore colors, island
## stamps, props, the walker, and the ambience of the Painted Lands and Green
## Caves scenes (wind, leaves, streaks, cloud shadows, grass waves, water
## life, critters, drifters, wildlife, footsteps, cold light on glowing plants
## and stones, motes and glints). Sheets in assets/pack/pixel_crawler/.

const TILE := 16
const W := PCTerrain.W
const H := PCTerrain.H
const PACK := "res://assets/pack/pixel_crawler/"
const WALKER_SCENE := preload("res://scenes/forest/walker.tscn")
const GROUND_SRC := 0
const WATER_SRC := 1
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const SPLAT_SHADER := preload("res://shaders/ms_grass_splat.gdshader")
# Painted Lands sprouts and tufts (TILESET_brighter.png, baked on its lawn):
# only their shapes are used, recolored into this biome's own palette.
const PL_SHEET := "res://assets/pack/TILESET_brighter.png"
const PL_TUFTS: Array[Vector2i] = [Vector2i(5, 1), Vector2i(6, 2), Vector2i(7, 3), Vector2i(6, 1)]
const PL_LAWN := Color8(83, 131, 79)
# The Fairy Forest shadow sheet (opaque slate, laid at low opacity) and its
# soft cyan light discs.
const SHADOW_SHEET := "fairy_forest/Shadown"
const SHADOW_BIG := Rect2(1, 16, 110, 48)
const SHADOW_SMALL := Rect2(112, 24, 47, 40)
const SHADOW_OVAL := Rect2(112, 5, 31, 11)
const SHADOW_ALPHA := 0.3
const LIGHT_SHEET := "fairy_forest/Light"
const LIGHT_BIG := Rect2(10, 10, 140, 140)
const LIGHT_SMALL := Rect2(164, 5, 40, 40)

@export var map_id := 170000
@export var recipe := -1
## The Farm forest greens are near pure green (saturation about 0.97); they
## are graded at load: the extreme saturation compressed, hue kept. Other
## biomes keep their colors.
@export var grade_green := true
## maze-pixelcrawler's mazes instead (pc_maze.gd): hedges, canals, crypts,
## cacti and rocks, the Forge's halls and lava, the Sewer's slime channels.
@export var maze := false

@onready var ground_layer: TileMapLayer = $Ground
@onready var water_layer: TileMapLayer = $Water
@onready var cliff_layer: TileMapLayer = $Cliffs
@onready var under: Node2D = $Under
@onready var actors: Node2D = $Actors
@onready var collision: StaticBody2D = $Collision

var terrain: PCTerrain
var report := ""
var _tiles: TileSet
var _textures := {} # sheet name -> Texture2D (graded when needed)
var _images := {} # sheet name -> Image
var _leaf_colors := {}
var _grass := {} # grass cells of this map (footsteps, waves)

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


var shade_group: CanvasGroup
var halos: Node2D


func _ready() -> void:
	# Tree and prop shadows as one group (so overlaps do not darken twice),
	# and the runestones' light, between the ground and the actors.
	shade_group = CanvasGroup.new()
	shade_group.name = "Shadows"
	shade_group.self_modulate = Color(1, 1, 1, SHADOW_ALPHA)
	add_child(shade_group)
	move_child(shade_group, actors.get_index())
	halos = Node2D.new()
	halos.name = "Halos"
	add_child(halos)
	move_child(halos, actors.get_index())
	_add_ambience()
	build(map_id, recipe)


func build(id: int, pinned := -1) -> void:
	map_id = id
	recipe = pinned
	terrain = PCTerrain.new()
	terrain.maze = maze
	report = terrain.generate(map_id, recipe)
	for layer in [ground_layer, water_layer, cliff_layer]:
		layer.clear()
	_crowns.clear()
	for node in [under, actors, collision, shade_group, halos]:
		for child in node.get_children():
			node.remove_child(child)
			child.queue_free()
	_build_tileset()
	_paint()
	_apply_splat()
	_paint_water()
	_build_collision()
	_place_props()
	_place_shadows()
	_spawn_walker()
	_reset_ambience()
	print(report)


func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in (PCMaze.recipes() if maze else PCTerrain.RECIPES):
		out.append(r.name)
	return out


func map_summary() -> Dictionary:
	var checks := "ok"
	for line in report.split("\n"):
		if line.begins_with("  checks:"):
			checks = line.substr(10)
	return {"id": terrain.map_id, "name": "Recipe %d: %s" % [terrain.recipe_id, terrain.recipe.name], "checks": checks}


# ---------------------------------------------------------------- sheets

func _graded_sheet(name: String) -> bool:
	return grade_green and (name.begins_with("farm/") or name.begins_with("green_woods/"))


func _image(name: String) -> Image:
	if not _images.has(name):
		var img: Image = load(PACK + name + ".png").get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		if _graded_sheet(name):
			_grade_image(img)
		_images[name] = img
	return _images[name]


func _tex(name: String) -> Texture2D:
	if not _textures.has(name):
		_textures[name] = ImageTexture.create_from_image(_image(name)) if _graded_sheet(name) else load(PACK + name + ".png")
	return _textures[name]


## One green graded (Farm forest); anything not green comes back unchanged.
## Only the extreme saturation is compressed (above 0.5, to 45 % of the
## excess) and bright greens pulled down a little; hue is kept, so dark grass
## stays green.
func graded(c: Color) -> Color:
	if c.s < 0.5:
		return c
	var w := clampf(minf(c.h - 0.14, 0.50 - c.h) / 0.05, 0.0, 1.0)
	if w <= 0.0:
		return c
	var sat := lerpf(c.s, 0.5 + (c.s - 0.5) * 0.45, w)
	var v := lerpf(c.v, 0.5 + (c.v - 0.5) * 0.8, w)
	return Color.from_hsv(c.h, sat, v, c.a)


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


# ---------------------------------------------------------------- tiles

func _build_tileset() -> void:
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = _tex(terrain.biome.tiles.trim_suffix(".png"))
	src.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(src, GROUND_SRC)
	for layer in [ground_layer, water_layer, cliff_layer]:
		layer.tile_set = _tiles


func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i, animated := false) -> void:
	var src: TileSetAtlasSource = _tiles.get_source(GROUND_SRC)
	if not src.has_tile(atlas):
		src.create_tile(atlas)
		if animated:
			# Lava and slime: four frames three rows apart, all in step.
			src.set_tile_animation_columns(atlas, 1)
			src.set_tile_animation_separation(atlas, Vector2i(0, 2))
			src.set_tile_animation_frames_count(atlas, 4)
			for i in 4:
				src.set_tile_animation_frame_duration(atlas, i, POOL_FRAME)
	layer.set_cell(cell, GROUND_SRC, atlas)


const POOL_FRAME := 0.18 # s per frame of lava and slime


func _paint() -> void:
	var tab: Dictionary = PCTiles.WANG[terrain.recipe.biome]
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var cells: Array = tab.get(terrain.sig(c), tab[terrain.biome.root.repeat(4)])
			var a: Vector2i = cells[0]
			if cells.size() > 1 and _hash(x, y) > 0.55:
				a = cells[1 + int(_hash(y, x) * (cells.size() - 1)) % (cells.size() - 1)]
			_put(ground_layer, c, a)
	for p in terrain.plateaus:
		for piece in p.pieces:
			_put(cliff_layer, piece.cell, piece.atlas)
	# A maze's kit walls and faces, and its animated channels.
	for c: Vector2i in terrain.wall_tiles:
		_put(cliff_layer, c, terrain.wall_tiles[c])
	for c: Vector2i in terrain.pool_tiles:
		_put(water_layer, c, terrain.pool_tiles[c], true)
	if terrain.biome.has("island"):
		var ir: Rect2i = terrain.biome.island
		for at in terrain.islands:
			for y in ir.size.y:
				for x in ir.size.x:
					_put(cliff_layer, at + Vector2i(x, y), ir.position + Vector2i(x, y))


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- ground splat

## Varies the light and the dark ground with the splat shader (the Mana Seed
## one): four textures over pure root ground and four over pure zone ground,
## each the biome's own fill retoned, picked per pixel with a dithered rim.
##   0 sunlit  the fill a little brighter and warmer
##   1 dry     the fill moved toward the patch terrain (earth, dark sand)
##   2 tufts   the fill with Painted Lands sprout and tuft shapes on it,
##             recolored into this palette (blades lighter, stems darker)
##   3 shade   light set: toward the zone terrain; dark set: darker still
func _apply_splat() -> void:
	if terrain.biome.get("indoor", false):
		ground_layer.material = null # a dungeon floor keeps its own tiles
		return
	var b: String = terrain.recipe.biome
	var tab: Dictionary = PCTiles.WANG[b]
	var sheet := _image(terrain.biome.tiles.trim_suffix(".png"))
	var root: String = terrain.biome.root
	var zone: String = terrain.biome.zone
	var patch: String = terrain.biome.patch if terrain.biome.patch != zone else root
	var atlas := Image.create(64, 128, false, Image.FORMAT_RGBA8)
	var tufts := _pl_tufts()
	for set_i in 2:
		var t: String = root if set_i == 0 else zone
		var fills: Array = tab[t.repeat(4)]
		var own := _ranked(sheet, fills)
		var other := _ranked(sheet, tab[(zone if set_i == 0 else root).repeat(4)])
		var dry := _ranked(sheet, tab[(patch if set_i == 0 else root).repeat(4)])
		for li in 4:
			for v in 4:
				var a: Vector2i = fills[v % fills.size()]
				var tile := sheet.get_region(Rect2i(a * TILE, Vector2i(TILE, TILE)))
				match li:
					0:
						var lift: float = 1.06 if b == "green" else 1.14
						_map(tile, func(c: Color) -> Color: return Color.from_hsv(c.h - 0.015, c.s * 0.95, minf(1.0, c.v * lift), c.a))
					1:
						_shift(tile, own, dry, 0.35)
					2:
						_tufts(tile, tufts[v % tufts.size()], own)
					3:
						if set_i == 0:
							_shift(tile, own, other, 0.55)
						else:
							_map(tile, func(c: Color) -> Color: return Color.from_hsv(c.h, minf(1.0, c.s * 1.04), c.v * 0.82, c.a))
				atlas.blit_rect(tile, Rect2i(0, 0, TILE, TILE), Vector2i(v * TILE, (set_i * 4 + li) * TILE))
	var weights := Image.create(W + 1, H + 1, false, Image.FORMAT_RGBA8)
	var fade := Image.create(W + 1, H + 1, false, Image.FORMAT_RGBA8)
	for y in H + 1:
		for x in W + 1:
			var i := y * (W + 1) + x
			var c := Color(0, 0, 0, 0)
			for li in terrain.splat.size():
				c[li] = terrain.splat[li][i]
			weights.set_pixel(x, y, c)
			fade.set_pixel(x, y, Color(terrain.splat_fade[i], terrain.splat_fade_dark[i], 0, 1))
	var mat := ShaderMaterial.new()
	mat.shader = SPLAT_SHADER
	mat.set_shader_parameter("weights", ImageTexture.create_from_image(weights))
	mat.set_shader_parameter("fade", ImageTexture.create_from_image(fade))
	mat.set_shader_parameter("layers", ImageTexture.create_from_image(atlas))
	mat.set_shader_parameter("corners", Vector2(W + 1, H + 1))
	mat.set_shader_parameter("seed", float(map_id % 1000))
	mat.set_shader_parameter("dither", 0.3)
	ground_layer.material = mat


## A fill's colors, most common first.
func _ranked(img: Image, cells: Array) -> Array[Color]:
	var counts := {}
	for a: Vector2i in cells:
		for y in TILE:
			for x in TILE:
				var k := img.get_pixel(a.x * TILE + x, a.y * TILE + y).to_rgba32()
				counts[k] = counts.get(k, 0) + 1
	var keys := counts.keys()
	keys.sort_custom(func(p, q): return counts[p] > counts[q])
	var out: Array[Color] = []
	for k in keys:
		out.append(Color.hex(k))
	return out


func _shift(tile: Image, from: Array[Color], to: Array[Color], t: float) -> void:
	var m := {}
	for i in from.size():
		m[from[i].to_rgba32()] = from[i].lerp(to[mini(i, to.size() - 1)], t)
	for y in TILE:
		for x in TILE:
			var k := tile.get_pixel(x, y).to_rgba32()
			if m.has(k):
				tile.set_pixel(x, y, m[k])


func _map(tile: Image, f: Callable) -> void:
	for y in TILE:
		for x in TILE:
			tile.set_pixel(x, y, f.call(tile.get_pixel(x, y)))


## The Painted Lands tuft tiles as masks: each pixel that is not its lawn,
## with its brightness (0 darkest, 1 lightest of the tuft).
func _pl_tufts() -> Array:
	var img: Image = load(PL_SHEET).get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var out := []
	for a in PL_TUFTS:
		var px := {}
		var lo := 1.0
		var hi := 0.0
		for y in TILE:
			for x in TILE:
				var c := img.get_pixel(a.x * TILE + x, a.y * TILE + y)
				if c.a < 0.5 or Vector3(c.r - PL_LAWN.r, c.g - PL_LAWN.g, c.b - PL_LAWN.b).length() < 0.06:
					continue
				var l := c.get_luminance()
				px[Vector2i(x, y)] = l
				lo = minf(lo, l)
				hi = maxf(hi, l)
		for k in px:
			px[k] = (px[k] - lo) / maxf(0.001, hi - lo)
		out.append(px)
	return out


## Lays a tuft mask on a fill: dark tuft pixels take the fill's darkest color
## darkened, light ones its lightest color lightened, in three steps.
func _tufts(tile: Image, mask: Dictionary, own: Array[Color]) -> void:
	var dark := own[0]
	var light := own[0]
	for c in own:
		if c.get_luminance() < dark.get_luminance():
			dark = c
		if c.get_luminance() > light.get_luminance():
			light = c
	var ramp := [dark.darkened(0.25), dark, light.lightened(0.12), light.lightened(0.28)]
	for p: Vector2i in mask:
		tile.set_pixel(p.x, p.y, ramp[clampi(int(mask[p] * 3.99), 0, 3)])


# ---------------------------------------------------------------- shadows

## Canopy shadows under trees (the shadow sheet's two blobs, by crown size),
## small ovals under rocks, bushes, stones, and graves, all opaque in one
## CanvasGroup drawn at SHADOW_ALPHA; and the sheet's soft light discs round
## the glowing runestones.
func _place_shadows() -> void:
	var tex := _tex(SHADOW_SHEET)
	var light := _tex(LIGHT_SHEET)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for p in terrain.props:
		var art: Dictionary = PCTerrain.prop(p.art)
		var foot := foot_of(p)
		var w: int = art.rect.size.x
		var region := Rect2()
		var at := foot
		match art.tag:
			"tree":
				region = SHADOW_BIG if w >= 90 else (SHADOW_SMALL if w >= 38 else SHADOW_OVAL)
				at = foot + Vector2(6, -4 if region != SHADOW_OVAL else 0)
			"bare", "bush", "stone", "grave", "rune", "cactus", "bone", "wood", "crystal", "clutter", "glow":
				if art.block == Vector2.ZERO and art.tag != "glow":
					continue
				region = SHADOW_OVAL
				at = foot + Vector2(2, 0)
			_:
				continue
		var s := Sprite2D.new()
		s.texture = tex
		s.region_enabled = true
		s.region_rect = region
		s.position = at.floor()
		if art.tag == "tree" and _hash(p.cell.x, p.cell.y * 7) < 0.5:
			s.flip_h = true
		shade_group.add_child(s)
		if art.tag == "rune":
			var h := Sprite2D.new()
			h.texture = light
			h.region_enabled = true
			h.region_rect = LIGHT_BIG if w > 30 else LIGHT_SMALL.grow(0)
			h.scale = Vector2.ONE * (0.8 if w > 30 else 1.6)
			h.material = add
			h.modulate = Color(1, 1, 1, 0.22)
			h.position = foot + Vector2(0, -art.rect.size.y * 0.4)
			halos.add_child(h)


# ---------------------------------------------------------------- water

## The sheets draw water only round their island stamps, so ponds and streams
## are drawn per pixel: a smooth field over the cells (bilinear between cell
## centers, a pixel wobble, an ordered dither) is deep water above 0.5, the
## sheet's two shore colors in a thin band below, and the ground's own pixels
## further out. Each touched cell becomes a generated tile over the ground.
func _paint_water() -> void:
	if terrain.water.is_empty() and terrain.islands.is_empty():
		return
	var wc: Dictionary = terrain.biome.water
	var deep: Color = wc.deep
	var shore: Array = wc.shore
	var bank: Color = wc.bank
	if _graded_sheet(terrain.biome.tiles):
		deep = graded(deep)
	var touched := {}
	for c: Vector2i in terrain.water:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := c + Vector2i(dx, dy)
				if n.x >= 0 and n.y >= 0 and n.x < W and n.y < H:
					touched[n] = true
	var cols := 32
	var img := Image.create(cols * TILE, ((touched.size() + cols - 1) / cols) * TILE, false, Image.FORMAT_RGBA8)
	var ground := _image(terrain.biome.tiles.trim_suffix(".png"))
	var placed := {}
	var n := 0
	for c: Vector2i in touched:
		var at := Vector2i(n % cols, n / cols)
		var g: Vector2i = ground_layer.get_cell_atlas_coords(c)
		var cl: Vector2i = cliff_layer.get_cell_atlas_coords(c)
		var any := false
		for py in TILE:
			for px in TILE:
				var fx := c.x + (px + 0.5) / TILE
				var fy := c.y + (py + 0.5) / TILE
				var wx := c.x * TILE + px
				var wy := c.y * TILE + py
				var v: float = _water_field(fx, fy) + 0.07 * sin(wx * 0.37 + wy * 0.23) + 0.04 * sin(wx * 1.3 - wy * 0.9) + (BAYER[(wy % 4) * 4 + (wx % 4)] / 16.0 - 0.5) * 0.06
				# From the water out: open water, the sheet's two shore blues,
				# then its dark bank shadow on the ground.
				var col := Color(0, 0, 0, 0)
				if v >= 0.52:
					col = deep
				elif v >= 0.44:
					col = shore[0]
				elif v >= 0.37:
					col = shore[1]
				elif v >= 0.32:
					col = bank
				if col.a > 0.0:
					any = true
				img.set_pixel(at.x * TILE + px, at.y * TILE + py, col)
		if any:
			placed[c] = at
			n += 1
	var src := TileSetAtlasSource.new()
	src.texture = ImageTexture.create_from_image(img)
	src.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(src, WATER_SRC)
	for c in placed:
		src.create_tile(placed[c])
		water_layer.set_cell(c, WATER_SRC, placed[c])


## 1 at water cell centers, 0 at land ones, bilinear between.
func _water_field(x: float, y: float) -> float:
	var x0 := floori(x - 0.5)
	var y0 := floori(y - 0.5)
	var tx := x - 0.5 - x0
	var ty := y - 0.5 - y0
	var a := lerpf(_wv(x0, y0), _wv(x0 + 1, y0), tx)
	var b := lerpf(_wv(x0, y0 + 1), _wv(x0 + 1, y0 + 1), tx)
	return lerpf(a, b, ty)


func _wv(x: int, y: int) -> float:
	var c := Vector2i(clampi(x, 0, W - 1), clampi(y, 0, H - 1))
	return 1.0 if terrain.water.has(c) or _island_cell(c) else 0.0


func _island_cell(c: Vector2i) -> bool:
	if not terrain.biome.has("island"):
		return false
	var sz: Vector2i = terrain.biome.island.size
	for at in terrain.islands:
		if Rect2i(at, sz).has_point(c):
			return true
	return false


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
				solid = (k == PCTerrain.WATER and not terrain.stones.has(c)) or k == PCTerrain.CLIFF
			if solid and run < 0:
				run = x
			elif not solid and run >= 0:
				_add_box(Rect2(run * TILE, y * TILE, (x - run) * TILE, TILE))
				run = -1
	# A maze's prop walls (bushes, cacti, rocks): where they are drawn.
	for r: Rect2 in terrain.maze_info.get("boxes", []):
		_add_box(r)
	for r in [Rect2(-TILE, -TILE, (W + 2) * TILE, TILE), Rect2(-TILE, H * TILE, (W + 2) * TILE, TILE),
			Rect2(-TILE, 0, TILE, H * TILE), Rect2(W * TILE, 0, TILE, H * TILE)]:
		_add_box(r)


func _add_box(r: Rect2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = r.size
	shape.shape = rect
	shape.position = r.get_center()
	collision.add_child(shape)


# ---------------------------------------------------------------- props

## A tree's trunk from its sprite: x is the middle of the root flare (the
## opaque span four to ten rows above the bottom), y its width, in px.
var _trunks := {}

func _trunk_of(sheet: String, rect: Rect2i) -> Vector2:
	var key := "%s:%s" % [sheet, rect]
	if _trunks.has(key):
		return _trunks[key]
	var img := _image(sheet)
	var lo := rect.size.x
	var hi := -1
	for r in range(rect.size.y - 10, rect.size.y - 3):
		for x in rect.size.x:
			if img.get_pixel(rect.position.x + x, rect.position.y + r).a > 0.4:
				lo = mini(lo, x)
				hi = maxi(hi, x)
	var out := Vector2(rect.size.x / 2.0, 8.0) if hi < 0 else Vector2((lo + hi + 1) / 2.0, float(hi - lo + 1))
	_trunks[key] = out
	return out


# ---------------------------------------------------------------- canopy fade

## Crowns that hide the walker fade: while the walker stands behind a tree
## (its body inside the crown and its feet above the tree's foot), the tree
## eases to CROWN_FADE alpha, and back when it leaves.
const CROWN_FADE := 0.42
const FADE_RATE := 5.0
var _crowns: Array[Dictionary] = [] # {sprite, foot: y, crown: Rect2}


func _process(delta: float) -> void:
	var walker := actors.get_node_or_null("Walker")
	if walker == null:
		return
	var body := Rect2(walker.position + Vector2(-6, -28), Vector2(12, 28))
	for c in _crowns:
		var spr: Sprite2D = c.sprite
		if not is_instance_valid(spr):
			continue
		var behind: bool = walker.position.y < c.foot - 1.0 and c.crown.intersects(body)
		var want := CROWN_FADE if behind else 1.0
		if not is_equal_approx(spr.modulate.a, want):
			spr.modulate.a = move_toward(spr.modulate.a, want, delta * FADE_RATE)


## A prop's foot: its cell's bottom middle (a maze's wall props and plank
## bridges are nudged: half a cell low, or centred on the channel).
static func foot_of(p: Dictionary) -> Vector2:
	return Vector2(p.cell * TILE) + Vector2(TILE / 2.0, TILE - 1) + p.get("nudge", Vector2.ZERO)


const NODDING := ["bush", "plant", "flower", "glow"]
var _nodders: Array[Sprite2D] = [] # the swaying tops of bushes and plants


func _place_props() -> void:
	_nodders.clear()
	for p in terrain.props:
		var art: Dictionary = PCTerrain.prop(p.art)
		var foot := foot_of(p)
		var rect: Rect2i = art.rect
		var node := StaticBody2D.new()
		node.collision_mask = 0
		node.position = foot
		var s := Sprite2D.new()
		s.texture = _tex(art.sheet)
		s.region_enabled = true
		s.region_rect = Rect2(rect)
		s.centered = false
		var tall: bool = art.tag in ["tree", "bare"]
		var flip: bool = art.tag not in ["tree", "grave", "rune"] and _hash(p.cell.x * 5, p.cell.y * 3) < 0.5
		s.flip_h = flip
		var block: Vector2 = art.block
		var cx := rect.size.x / 2.0
		if tall:
			# Stand the tree on its own trunk (big crowns are not centered on
			# it) and block its root flare, measured from the sprite.
			var tr := _trunk_of(art.sheet, rect)
			cx = tr.x if not flip else rect.size.x - tr.x
			# No wider than the cells the generator reserved for it (art.block;
			# none for a walk-through one), so the walk check and the walker's
			# routes agree with physics.
			if art.block != Vector2.ZERO:
				block = Vector2(minf(maxf(tr.y, 8.0), art.block.x), clampf(tr.y * 0.3, 6.0, 12.0))
		s.offset = -Vector2(cx, rect.size.y - 2)
		node.add_child(s)
		if art.tag in NODDING and rect.size.y >= 12 and rect.size.y <= 64:
			# Bushes, plants, flowers, and bells sway: the top half is its own
			# sprite and leans downwind with the reeds (water_life.gd).
			var cut := floori(rect.size.y * 0.5)
			s.region_rect = Rect2(rect.position.x, rect.position.y + cut, rect.size.x, rect.size.y - cut)
			s.offset = -Vector2(cx, rect.size.y - 2 - cut)
			var top := Sprite2D.new()
			top.texture = s.texture
			top.region_enabled = true
			top.region_rect = Rect2(rect.position.x, rect.position.y, rect.size.x, cut)
			top.centered = false
			top.flip_h = flip
			top.offset = -Vector2(cx, rect.size.y - 2)
			node.add_child(top)
			_nodders.append(top)
		if block != Vector2.ZERO:
			var shape := CollisionShape2D.new()
			var rs := RectangleShape2D.new()
			rs.size = block
			shape.shape = rs
			shape.position = Vector2(0, -block.y / 2.0)
			node.add_child(shape)
		if tall and rect.size.y > 60:
			# The crown: from the top of the sprite down to where the trunk
			# shows below the leaves.
			var top := foot + s.offset
			_crowns.append({"sprite": s, "foot": foot.y, "crown": Rect2(top, Vector2(rect.size.x, rect.size.y * 0.78))})
		if art.tag == "flat" or art.tag == "flower":
			under.add_child(node)
		else:
			actors.add_child(node)
	# Stepping stones where a path crosses a stream.
	var stone: String = {"fairy": "ff_pebble", "green": "fm_stone_b"}.get(terrain.recipe.biome, "")
	if stone != "":
		var art: Dictionary = PCTerrain.PROPS[stone]
		for c: Vector2i in terrain.stones:
			var s := Sprite2D.new()
			s.texture = _tex(art.sheet)
			s.region_enabled = true
			s.region_rect = Rect2(art.rect)
			s.position = Vector2(c * TILE) + Vector2(8, 8)
			under.add_child(s)


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


# Per biome: grass-wave tips and blade flicks (lighter than the ground),
# dust (a little darker than the path or ground), cloud shade, water rings.
const BIOME_FX := {
	"fairy": {"tip": Color(0.3, 0.56, 0.4), "blades": [Color(0.26, 0.5, 0.36), Color(0.2, 0.42, 0.3)],
		"dust": [Color(0.3, 0.29, 0.19), Color(0.24, 0.23, 0.15)], "shade": Color(0.02, 0.1, 0.08, 0.2), "ring": Color(0.5, 0.8, 0.9)},
	"green": {"tip": Color(0.62, 0.78, 0.4), "blades": [Color(0.56, 0.72, 0.36), Color(0.44, 0.62, 0.3)],
		"dust": [Color(0.52, 0.37, 0.16), Color(0.44, 0.31, 0.14)], "shade": Color(0.06, 0.2, 0.1, 0.16), "ring": Color(0.5, 0.7, 1.0)},
	"cemetery": {"tip": Color(0.5, 0.36, 0.25), "blades": [Color(0.48, 0.3, 0.2), Color(0.4, 0.26, 0.17)],
		"dust": [Color(0.3, 0.19, 0.12), Color(0.26, 0.16, 0.1)], "shade": Color(0.05, 0.03, 0.03, 0.2), "ring": Color(0.5, 0.6, 0.6)},
	"desert": {"tip": Color(0.95, 0.72, 0.45), "blades": [Color(0.92, 0.66, 0.38), Color(0.84, 0.58, 0.32)],
		"dust": [Color(0.72, 0.46, 0.24), Color(0.64, 0.4, 0.2)], "shade": Color(0.3, 0.12, 0.05, 0.14), "ring": Color(0.6, 0.7, 0.8)},
	# Dungeons (indoor: no clouds, streaks, grass, or drifters).
	"forge": {"tip": Color(0.4, 0.3, 0.35), "blades": [Color(0.4, 0.3, 0.35)], "dust": [Color(0.3, 0.23, 0.28), Color(0.24, 0.18, 0.22)],
		"shade": Color(0, 0, 0, 0), "ring": Color(1.0, 0.6, 0.3)},
	"sewer": {"tip": Color(0.3, 0.26, 0.18), "blades": [Color(0.3, 0.26, 0.18)], "dust": [Color(0.25, 0.2, 0.14), Color(0.2, 0.16, 0.11)],
		"shade": Color(0, 0, 0, 0), "ring": Color(0.55, 0.85, 0.25)},
}


func _reset_ambience() -> void:
	var b: String = terrain.recipe.biome
	var fx: Dictionary = BIOME_FX[b]
	var indoor: bool = terrain.biome.get("indoor", false)
	var map_rect := Rect2(0, 0, W * TILE, H * TILE)
	for n in [clouds, drifters]:
		n.visible = not indoor
		n.process_mode = Node.PROCESS_MODE_DISABLED if indoor else Node.PROCESS_MODE_INHERIT
	cave_life.bats = indoor or not terrain.wall_tiles.is_empty() # dungeons and crypts
	streaks.bounds = Rect2() if indoor else map_rect
	clouds.shade = fx.shade
	grass_waves.tip = fx.tip
	footsteps.blade_colors = fx.blades
	footsteps.dust_colors = fx.dust
	water_life.ring_color = fx.ring
	water_life.ring_highlight = fx.ring.lightened(0.5)
	water_life.drop_color = fx.ring.lightened(0.3)
	clouds.reset(map_rect)
	var walker := actors.get_node_or_null("Walker")
	water_life.setup(terrain.open_water(), _nodders)
	var sources: Array[Dictionary] = []
	var fires: Array[Dictionary] = []
	var lights: Array[Vector2] = []
	var glinters: Array = []
	var flowers: Array[Vector2] = []
	var dark: Array[Vector2] = []
	for p in terrain.props:
		var art: Dictionary = PCTerrain.prop(p.art)
		var foot := foot_of(p)
		var rect: Rect2i = art.rect
		var top_left := foot - Vector2(rect.size.x / 2.0, rect.size.y - 2)
		match art.tag:
			"tree":
				sources.append({"crown": Rect2(top_left + Vector2(rect.size.x * 0.1, 2), Vector2(rect.size.x * 0.8, rect.size.y * 0.5)),
					"base_y": foot.y}.merged(_colors_of(art.sheet, rect)))
			"glow":
				# Glowing bell flowers: a cold violet light at the bloom.
				var at := top_left + Vector2(rect.size.x * 0.55, rect.size.y * 0.25)
				fires.append({"pos": foot, "kind": "lamp", "radius": 16 if rect.size.y > 40 else 10, "smoke": false, "flame": at, "tint": Color(0.62, 0.5, 1.0)})
				lights.append(at)
			"rune":
				var eye := top_left + Vector2(rect.size.x * 0.5, rect.size.y * 0.5)
				fires.append({"pos": foot, "kind": "lamp", "radius": 18, "smoke": false, "flame": eye, "tint": Color(0.3, 0.85, 1.0)})
				glinters.append([Vector2i(eye) + Vector2i(-2, -2), Vector2i(eye) + Vector2i(2, 1)])
			"crystal":
				glinters.append([Vector2i(top_left) + Vector2i(12, 10), Vector2i(top_left) + Vector2i(24, 20), Vector2i(top_left) + Vector2i(18, 4)])
			"flower", "mushroom":
				flowers.append(foot + Vector2(0, -4))
			"lamp":
				# The sewer's lamps: a warm light at the flame.
				var at := top_left + Vector2(rect.size.x * 0.5, rect.size.y * 0.35)
				fires.append({"pos": foot, "kind": "lamp", "radius": 14, "smoke": false, "flame": at})
				lights.append(at)
	# Lava glows: a warm light every few cells along its rim.
	for c: Vector2i in terrain.pool_tiles:
		if b == "forge" and absi(hash(c)) % 5 == 0:
			var at := Vector2(c * TILE) + Vector2(8, 8)
			fires.append({"pos": at, "kind": "lamp", "radius": 20, "smoke": false, "flame": at, "tint": Color(1.0, 0.55, 0.2)})
			lights.append(at)
	leaves.set_sources(sources)
	fire.set_fires(fires)
	cave_life.setup(terrain.drip_spots(), lights, glinters)
	# Glowworms and fireflies over the dark ground (a crypt maze's corridors
	# get three times as many: little else moves there).
	var every := 3 if terrain.maze and b == "cemetery" else 7
	for c in terrain.zone_cells():
		if (c.x * 7 + c.y * 3) % every == 0 and b != "desert" and not indoor:
			dark.append(Vector2(c * TILE) + Vector2(8, 8))
	# Liveliness anchors without water: a swarm of fireflies.
	for c in terrain.firefly_spots:
		for k in 5:
			dark.append(Vector2(c * TILE) + Vector2(randf_range(-40, 40), randf_range(-24, 24)))
	var ponds: Array[Rect2] = []
	for r in terrain.ponds:
		ponds.append(Rect2(Vector2(r.position) * TILE + Vector2(16, 16), Vector2(r.size) * TILE - Vector2(32, 32)))
	critters.walker = walker
	critters.setup(flowers, ponds, dark)
	drifters.setup(map_rect, flowers)
	_grass = terrain.grass_cells()
	grass_waves.setup(_grass)
	var water := {}
	for c in terrain.water:
		if not terrain.stones.has(c):
			water[c] = true
	footsteps.setup_generic(_surface, water, walker)
	wildlife.setup_from(terrain.wildlife_plan(), water, actors, walker, _image(terrain.biome.tiles.trim_suffix(".png")), water_life)


func _surface(cell: Vector2i) -> String:
	if cell.x < 0 or cell.y < 0 or cell.x >= W or cell.y >= H:
		return "none"
	if terrain.kind[cell.y * W + cell.x] != PCTerrain.OPEN:
		return "none"
	if _grass.has(cell):
		return "grass"
	return "dust"


# Leaf colors from a tree's crown: light foliage colors, edged with its
# darkest leaf color.
func _colors_of(sheet: String, region: Rect2i) -> Dictionary:
	var key := "%s:%s" % [sheet, region]
	if _leaf_colors.has(key):
		return _leaf_colors[key]
	var img := _image(sheet)
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
	var dark := Color(0.1, 0.2, 0.15)
	var darkest := 2.0
	for k in keys.slice(0, 10):
		var c := Color.hex(k)
		if c.get_luminance() < darkest:
			darkest = c.get_luminance()
			dark = c
		if c.get_luminance() > 0.3:
			light.append(c)
	if light.is_empty() and not keys.is_empty():
		light.append(Color.hex(keys[0]).lightened(0.3))
	_leaf_colors[key] = {"light": light, "dark": dark}
	return _leaf_colors[key]
