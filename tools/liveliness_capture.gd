extends Node2D
## Liveliness calibration capture, rendered (run with a window, not
## headless). For each planned map it builds the map, hides the walker (so
## only the scene itself moves), lets the leaves reach their steady state,
## then films six camera views that tile the map, 25 s each at 8 fps.
##
## Every frame is written raw (RGB, one byte per channel, at world-pixel
## resolution, 688x288) to .liveliness/raw/<map>_<view>.rgb. When a view ends,
## a JSON beside it records the view, the proxy features of each 6x6-cell
## block, and what the ambience actually did in each block, averaged over
## the frames: leaves in the air and on the ground, streak pixels, rings,
## drops, butterflies, dragonflies, fireflies, smoke puffs, animal pixels,
## cloud edges, and the wind. tools/liveliness_analyze.py measures the frames and fits the proxy.
##   godot --path . res://tools/liveliness_capture.tscn [-- <map_id> ... [quick] [caves]]
## `caves` films Green Caves maps (randomizer-greencaves) into
## .liveliness_caves, with the cave features and cave_life.gd counts.
## `farm` films the farm randomizer (randomizer-paintedlands-farm) into
## .liveliness_farm and `pc` the Pixel Crawler randomizer into .liveliness_pc:
## measured only (no proxy features per block), each view's cloud shade
## recorded so the analyzer can tell cloud rims apart.

const PaintedFeatures := preload("res://scripts/liveliness_features.gd")
const CaveFeatures := preload("res://scripts/cave_liveliness_features.gd")
const MAP_SCENE := preload("res://scenes/wilds/wilds.tscn")
const CAVE_SCENE := preload("res://scenes/randomizer-greencaves/randomizer-greencaves.tscn")
const TILE := 16
const ZOOM := 5
const VIEW := Vector2i(43, 18) # cells on screen at 3440x1440, zoom 5
const BLOCK := 6 # cells per block side
const BLOCKS := Vector2i(7, 3) # blocks per view (42x18 cells)
const FPS := 8.0
const WARMUP := 12.0 # s after a build: leaves take ~10 s to fill the air and the ground
const SETTLE := 2.0 # s after a camera move: streaks spawn only in view
const RECORD := 25.0 # s per view
# Maps chosen for coverage (lawn, forest, water, fire, village, plateaus,
# hedges, rocks, lake, ridge), then eight held back to test the fit (three
# originals, and one each of the recipes given ponds, torches, or fires).
const CALIBRATE := [120005, 120025, 120006, 120023, 120026, 120021, 120027, 120024, 120012, 120028]
const HOLDOUT := [120000, 120010, 120020, 120001, 120004, 120009, 120013, 120015]
# Caves: eight for the fit (every floor, pools, lake, rails, terrace, camp,
# crystals, moss), four held back.
const CAVE_CALIBRATE := [130021, 130022, 130023, 130025, 130026, 130027, 130004, 130010]
const CAVE_HOLDOUT := [130009, 130014, 130018, 130028]
const VIEWS := [Vector2i(0, 0), Vector2i(17, 0), Vector2i(0, 11), Vector2i(17, 11), Vector2i(0, 22), Vector2i(17, 22)]
const FARM_SCENE := preload("res://scenes/randomizer-paintedlands-farm/randomizer-paintedlands-farm.tscn")
const PC_SCENE := preload("res://scenes/randomizer-pixelcrawler/randomizer-pixelcrawler.tscn")
# Farm: twelve map types across the three seasons (id % 52: summer 0-29,
# autumn 30-39, winter 40-47, rivers 48-51; the same twelve as measured
# before the rivers, at new ids); Pixel Crawler: two of each biome's kinds.
const FARM_MAPS := [190008, 190011, 190016, 190026, 190031, 190037, 190038, 190041, 190043, 190046, 190048, 190052]
const PC_MAPS := [170000, 170003, 170004, 170006, 170008, 170011, 170013, 170015]

var _forest: Node2D
var _caves := false
var _farm := false
var _pc := false
var _views: Array = VIEWS # from the map's size (a farm or Pixel Crawler map is 64 wide)
var Features = PaintedFeatures
var _camera: Camera2D
var _plan: Array = []
var _map_i := -1
var _view_i := 0
var _state := ""
var _timer := 0.0
var _next_frame := 0.0
var _file: FileAccess
var _grid: Dictionary
var _frames := 0
var _samples := 0
var _obs := {}
var _wind := Vector3.ZERO # strength, gust, base sums
var _times: Array[float] = []
var _out := ""
var _drawn := 0 # Engine frames drawn at the last capture
var _last_hash := 0
var _same := 0 # consecutive identical frames
var _warmup := WARMUP
var _record := RECORD


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a == "quick": # smoke test: short warm-up and views
			_warmup = 2.0
			_record = 3.0
		elif a == "caves":
			_caves = true
			Features = CaveFeatures
		elif a == "farm":
			_farm = true
		elif a == "pc":
			_pc = true
		elif a in ["cozy", "pack", "drawn", "mixed"] or a.begins_with("out="):
			pass
		else:
			_plan.append(int(a))
	if _plan.is_empty():
		if _farm:
			_plan = FARM_MAPS.duplicate()
		elif _pc:
			_plan = PC_MAPS.duplicate()
		else:
			_plan = CAVE_CALIBRATE + CAVE_HOLDOUT if _caves else CALIBRATE + HOLDOUT
	var suffix := "_farm" if _farm else ("_pc" if _pc else ("_caves" if _caves else ""))
	_out = ProjectSettings.globalize_path("res://.liveliness%s/raw" % suffix)
	if _farm or _pc:
		_views = [Vector2i(0, 0), Vector2i(21, 0), Vector2i(0, 11), Vector2i(21, 11), Vector2i(0, 22), Vector2i(21, 22)]
	# `cozy`: the deprecated cozy farm randomizer's settings (Cozy Farm
	# animals and buildings); `pack`: the Cozy Farm animals as
	# randomizer-paintedlands draws them; `drawn`: the drawn animals (Green
	# Caves draws the pack ones by default); `out=<dir>`:
	# film into res://<dir>/raw instead.
	var cozy := "cozy" in args
	for a in args:
		if a.begins_with("out="):
			_out = ProjectSettings.globalize_path("res://%s/raw" % a.substr(4))
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.remove_absolute(_out + "/ALL_DONE")
	_forest = (FARM_SCENE if _farm else (PC_SCENE if _pc else (CAVE_SCENE if _caves else MAP_SCENE))).instantiate()
	if _farm:
		_forest.interiors = false
		# `mixed`: with the farmsteads (randomizer-paintedlands-forest-farm).
		_forest.mixed = "mixed" in OS.get_cmdline_user_args()
	if cozy:
		_forest.cozy_animals = true
		_forest.cozy_buildings = true
		PaintedFeatures.animals = "farm"
	elif "pack" in args:
		_forest.cozy_animals = true
		PaintedFeatures.animals = "pack"
	elif "drawn" in args:
		_forest.cozy_animals = false
	elif _caves:
		PaintedFeatures.animals = "pack"
	add_child(_forest)
	_camera = Camera2D.new()
	_camera.zoom = Vector2(ZOOM, ZOOM)
	_camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(_camera)
	_next_map()


func _next_map() -> void:
	_map_i += 1
	if _map_i >= _plan.size():
		FileAccess.open(_out + "/ALL_DONE", FileAccess.WRITE).store_string("done")
		print("liveliness capture: all done")
		get_tree().quit()
		return
	var id: int = _plan[_map_i]
	_forest.build(id, -1)
	# Fixed seeds for every effect, so a map's capture can be run again.
	seed(id)
	var keys := ["wind", "leaves", "fire", "water_life", "critters", "footsteps", "cave_life"] if _caves else \
		["wind", "leaves", "streaks", "clouds", "fire", "water_life", "critters", "footsteps"]
	for key in keys:
		var node: Node = _forest.get(key)
		if node and node.get("_rng"):
			node.get("_rng").seed = id * 31 + key.hash()
	# Wind._ready() would reseed at random, so set its starting state here.
	var w: Node = _forest.wind
	var rng: RandomNumberGenerator = w.get("_rng")
	w.angle = rng.randf_range(-PI, PI)
	w.set("_from_angle", w.angle)
	w.set("_to_angle", w.angle)
	w.set("_turn_t", 1.0)
	w.base_strength = rng.randf_range(0.35, 0.75)
	w.gust = 0.0
	w.set("_gust_t", -1.0)
	w.set("_next_turn", rng.randf_range(20.0, 40.0))
	w.set("_next_gust", rng.randf_range(6.0, 16.0))
	if _farm or _pc:
		_forest.clouds.reset(Rect2(0, 0, 64 * TILE, 40 * TILE))
	elif not _caves:
		_forest.clouds.reset(Rect2(0, 0, Features.W * TILE, Features.H * TILE))
	var walker: Node2D = _forest.actors.get_node_or_null("Walker")
	if walker:
		walker.get_node("Camera").enabled = false
		walker.visible = false
		walker.process_mode = Node.PROCESS_MODE_DISABLED
		walker.position = Vector2(-9999, -9999) # nothing near it to scare
	_forest.footsteps.process_mode = Node.PROCESS_MODE_DISABLED
	_camera.make_current()
	_grid = {} if (_farm or _pc) else Features.grid(_forest.terrain)
	_view_i = 0
	_aim()
	_state = "warm"
	_timer = _warmup
	print("liveliness capture: map %d (recipe %d %s), %d of %d" % [id, _forest.terrain.recipe_id, _forest.terrain.recipe.name, _map_i + 1, _plan.size()])


func _aim() -> void:
	_camera.position = Vector2(_views[_view_i] * TILE)


func _process(delta: float) -> void:
	match _state:
		"warm", "settle":
			_timer -= delta
			if _timer <= 0.0:
				_start_view()
		"stalled":
			# Wait until the window draws again, then redo the view.
			if DisplayServer.window_can_draw() and Engine.get_frames_drawn() > _drawn + 10:
				print("liveliness capture: window drawing again, redoing map %d view %d" % [_plan[_map_i], _view_i])
				_state = "settle"
				_timer = SETTLE
		"record":
			_timer += delta
			if _timer >= _next_frame:
				_next_frame += 1.0 / FPS
				_capture()
			if _timer >= _record:
				_finish_view()


func _start_view() -> void:
	var stem := "%d_%d" % [_plan[_map_i], _view_i]
	_file = FileAccess.open("%s/%s.rgb" % [_out, stem], FileAccess.WRITE)
	_frames = 0
	_samples = 0
	_obs.clear()
	_wind = Vector3.ZERO
	_times.clear()
	_same = 0
	_drawn = Engine.get_frames_drawn()
	_timer = 0.0
	_next_frame = 0.0
	_state = "record"


func _capture() -> void:
	# A minimized window, a locked screen, or a sleeping display stops drawing,
	# and the viewport keeps returning its last frame. Never record that:
	# drop the view and redo it once drawing resumes.
	if not DisplayServer.window_can_draw() or (_frames > 0 and Engine.get_frames_drawn() == _drawn):
		_stall()
		return
	_drawn = Engine.get_frames_drawn()
	var img := get_viewport().get_texture().get_image()
	var world := Vector2i(img.get_width() / ZOOM, img.get_height() / ZOOM)
	img.resize(world.x, world.y, Image.INTERPOLATE_NEAREST)
	var size := VIEW * TILE
	if world != size:
		img = img.get_region(Rect2i(Vector2i.ZERO, size)) # the camera's top left is the view's
	img.convert(Image.FORMAT_RGB8)
	var data := img.get_data()
	var h := hash(data)
	_same = _same + 1 if h == _last_hash else 0
	_last_hash = h
	if _same >= 24: # 3 s of identical frames: the picture is frozen
		_stall()
		return
	_file.store_buffer(data)
	_frames += 1
	_times.append(_timer)
	_sample()


func _stall() -> void:
	_file.close()
	DirAccess.remove_absolute("%s/%d_%d.rgb" % [_out, _plan[_map_i], _view_i])
	_same = 0
	_drawn = Engine.get_frames_drawn()
	_state = "stalled"
	print("liveliness capture: window stopped drawing (minimized, covered, or screen locked?); waiting to redo map %d view %d" % [_plan[_map_i], _view_i])


# What each effect is doing in each block right now.
func _sample() -> void:
	_samples += 1
	var f := _forest
	for leaf in f.leaves._leaves:
		_count("leaves_air" if leaf.h > 0.0 else "leaves_rest", Vector2(leaf.ground.x, leaf.ground.y - leaf.h))
	if _caves:
		_sample_caves()
	else:
		for s in f.streaks._streaks:
			for p in s.trail:
				_count("streak_px", p)
	for r in f.water_life._rings:
		_count("rings", r.pos)
	for d in f.water_life._drops:
		_count("drops", d.pos)
	for b in f.critters._butterflies:
		_count("butterflies", b.pos)
	for d in f.critters._dragonflies:
		_count("dragonflies", d.pos)
	for ff in f.critters._fireflies:
		_count("fireflies", ff.pos)
	for p in f.fire._puffs:
		_count("smoke", p.pos)
	for a in f.wildlife._animals:
		if is_instance_valid(a) and a.visible:
			_count_area("animals", a.pos, PaintedFeatures.sprite_area(a.kind) if not (_farm or _pc) else 30.0)
	# A cloud shadow's moving rim is what changes pixels; count blocks its
	# outline box cuts through.
	for sprite in ([] if _caves else f.clouds._clouds):
		var size: Vector2 = sprite.texture.get_size()
		var rect := Rect2(sprite.position - size / 2.0, size)
		for i in BLOCKS.x * BLOCKS.y:
			var b := _block_rect(i)
			if rect.intersects(b) and not rect.encloses(b):
				_bump("cloud_edge", i, 1.0)
	_wind += Vector3(f.wind.strength(), f.wind.gust, f.wind.base_strength)


# cave_life.gd: drops and splashes, warm and pale motes, glints, bats.
func _sample_caves() -> void:
	var life: Node = _forest.cave_life
	for d in life._drops:
		_count("drips", d.pos)
	for s in life._splashes:
		if s.t < 0.3:
			_count("drips", s.pos)
	for m in life._motes:
		_count("warm" if m.warm else "pale", m.pos)
	for g in life._glints:
		_count("glints", Vector2(g.pos))
	for b in life._bats:
		_count("bats", b.pos)


func _block_rect(i: int) -> Rect2:
	var cell: Vector2i = _views[_view_i] + Vector2i(i % BLOCKS.x, i / BLOCKS.x) * BLOCK
	return Rect2(Vector2(cell * TILE), Vector2(BLOCK * TILE, BLOCK * TILE))


func _count(key: String, pos: Vector2) -> void:
	var local := pos - Vector2(_views[_view_i] * TILE)
	var bx := floori(local.x / (BLOCK * TILE))
	var by := floori(local.y / (BLOCK * TILE))
	if bx >= 0 and by >= 0 and bx < BLOCKS.x and by < BLOCKS.y:
		_bump(key, by * BLOCKS.x + bx, 1.0)


func _count_area(key: String, pos: Vector2, area: float) -> void:
	var local := pos - Vector2(_views[_view_i] * TILE)
	var bx := floori(local.x / (BLOCK * TILE))
	var by := floori(local.y / (BLOCK * TILE))
	if bx >= 0 and by >= 0 and bx < BLOCKS.x and by < BLOCKS.y:
		_bump(key, by * BLOCKS.x + bx, area)


func _bump(key: String, i: int, v: float) -> void:
	if not _obs.has(key):
		var a := PackedFloat32Array()
		a.resize(BLOCKS.x * BLOCKS.y)
		a.fill(0.0)
		_obs[key] = a
	_obs[key][i] += v


func _finish_view() -> void:
	_file.close()
	var id: int = _plan[_map_i]
	var blocks: Array = []
	var cells := float(BLOCK * BLOCK)
	for i in BLOCKS.x * BLOCKS.y:
		var cell: Vector2i = _views[_view_i] + Vector2i(i % BLOCKS.x, i / BLOCKS.x) * BLOCK
		var obs := {}
		for key in _obs:
			obs[key] = _obs[key][i] / _samples / cells # per cell, per frame
		var feats: Dictionary = {} if _grid.is_empty() else Features.block(_grid, Rect2i(cell, Vector2i(BLOCK, BLOCK)))
		blocks.append({"cell": [cell.x, cell.y], "features": feats, "observed": obs})
	var meta := {
		"map": id, "recipe": _forest.terrain.recipe_id, "recipe_name": _forest.terrain.recipe.name,
		"holdout": id in (CAVE_HOLDOUT if _caves else HOLDOUT), "pack": "farm" if _farm else ("pc" if _pc else ("caves" if _caves else "painted")),
		"shade": [_forest.clouds.shade.r * 255.0, _forest.clouds.shade.g * 255.0, _forest.clouds.shade.b * 255.0, _forest.clouds.shade.a] if not _caves else [], "view": _view_i, "origin": [_views[_view_i].x, _views[_view_i].y],
		"size": [VIEW.x * TILE, VIEW.y * TILE], "block_px": BLOCK * TILE, "blocks_xy": [BLOCKS.x, BLOCKS.y],
		"frames": _frames, "times": _times, "fps": FPS,
		"wind": {"strength": _wind.x / _samples, "gust": _wind.y / _samples, "base": _wind.z / _samples},
		"blocks": blocks,
	}
	var stem := "%d_%d" % [id, _view_i]
	# The JSON is written last: the analyzer takes it as the sign the frames are complete.
	var tmp := "%s/%s.json.part" % [_out, stem]
	FileAccess.open(tmp, FileAccess.WRITE).store_string(JSON.stringify(meta))
	DirAccess.rename_absolute(tmp, "%s/%s.json" % [_out, stem])
	print("liveliness capture: map %d view %d, %d frames" % [id, _view_i, _frames])
	_view_i += 1
	if _view_i >= _views.size():
		_next_map()
	else:
		_aim()
		_state = "settle"
		_timer = SETTLE
