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
##   godot --path . res://tools/liveliness_capture.tscn [-- <map_id> ... [quick]]

const Features := preload("res://tools/liveliness_features.gd")
const MAP_SCENE := preload("res://scenes/wilds/wilds.tscn")
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
# hedges, rocks, lake, ridge), then three held back to test the fit.
const CALIBRATE := [120005, 120025, 120006, 120023, 120026, 120021, 120027, 120024, 120012, 120028]
const HOLDOUT := [120000, 120010, 120020]
const VIEWS := [Vector2i(0, 0), Vector2i(17, 0), Vector2i(0, 11), Vector2i(17, 11), Vector2i(0, 22), Vector2i(17, 22)]

var _forest: Node2D
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
		else:
			_plan.append(int(a))
	if _plan.is_empty():
		_plan = CALIBRATE + HOLDOUT
	_out = ProjectSettings.globalize_path("res://.liveliness/raw")
	DirAccess.make_dir_recursive_absolute(_out)
	DirAccess.remove_absolute(_out + "/ALL_DONE")
	_forest = MAP_SCENE.instantiate()
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
	for key in ["wind", "leaves", "streaks", "clouds", "fire", "water_life", "critters", "footsteps"]:
		var node: Node = _forest.get(key)
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
	_forest.clouds.reset(Rect2(0, 0, Features.W * TILE, Features.H * TILE))
	var walker: Node2D = _forest.actors.get_node_or_null("Walker")
	if walker:
		walker.get_node("Camera").enabled = false
		walker.visible = false
		walker.process_mode = Node.PROCESS_MODE_DISABLED
		walker.position = Vector2(-9999, -9999) # nothing near it to scare
	_forest.footsteps.process_mode = Node.PROCESS_MODE_DISABLED
	_camera.make_current()
	_grid = Features.grid(_forest.terrain)
	_view_i = 0
	_aim()
	_state = "warm"
	_timer = _warmup
	print("liveliness capture: map %d (recipe %d %s), %d of %d" % [id, _forest.terrain.recipe_id, _forest.terrain.recipe.name, _map_i + 1, _plan.size()])


func _aim() -> void:
	_camera.position = Vector2(VIEWS[_view_i] * TILE)


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
			_count_area("animals", a.pos, Features.sprite_area(a.kind))
	# A cloud shadow's moving rim is what changes pixels; count blocks its
	# outline box cuts through.
	for sprite in f.clouds._clouds:
		var size: Vector2 = sprite.texture.get_size()
		var rect := Rect2(sprite.position - size / 2.0, size)
		for i in BLOCKS.x * BLOCKS.y:
			var b := _block_rect(i)
			if rect.intersects(b) and not rect.encloses(b):
				_bump("cloud_edge", i, 1.0)
	_wind += Vector3(f.wind.strength(), f.wind.gust, f.wind.base_strength)


func _block_rect(i: int) -> Rect2:
	var cell: Vector2i = VIEWS[_view_i] + Vector2i(i % BLOCKS.x, i / BLOCKS.x) * BLOCK
	return Rect2(Vector2(cell * TILE), Vector2(BLOCK * TILE, BLOCK * TILE))


func _count(key: String, pos: Vector2) -> void:
	var local := pos - Vector2(VIEWS[_view_i] * TILE)
	var bx := floori(local.x / (BLOCK * TILE))
	var by := floori(local.y / (BLOCK * TILE))
	if bx >= 0 and by >= 0 and bx < BLOCKS.x and by < BLOCKS.y:
		_bump(key, by * BLOCKS.x + bx, 1.0)


func _count_area(key: String, pos: Vector2, area: float) -> void:
	var local := pos - Vector2(VIEWS[_view_i] * TILE)
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
		var cell: Vector2i = VIEWS[_view_i] + Vector2i(i % BLOCKS.x, i / BLOCKS.x) * BLOCK
		var obs := {}
		for key in _obs:
			obs[key] = _obs[key][i] / _samples / cells # per cell, per frame
		blocks.append({"cell": [cell.x, cell.y], "features": Features.block(_grid, Rect2i(cell, Vector2i(BLOCK, BLOCK))), "observed": obs})
	var meta := {
		"map": id, "recipe": _forest.terrain.recipe_id, "recipe_name": _forest.terrain.recipe.name,
		"holdout": id in HOLDOUT, "view": _view_i, "origin": [VIEWS[_view_i].x, VIEWS[_view_i].y],
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
	if _view_i >= VIEWS.size():
		_next_map()
	else:
		_aim()
		_state = "settle"
		_timer = SETTLE
