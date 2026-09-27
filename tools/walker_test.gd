extends Node2D
## Walker test: the walker walks a route through each of the six camera views
## of a map (the same views as tools/liveliness_capture.gd) for 25 s, past the
## animals, a stretch of cobble, a dirt island, tufts and flowers, the shore,
## and the ground under a tree, and counts what the scene does back: animals
## that react (by species), dust puffs, grass flicks, shore ripples, kicked
## leaves, scattered butterflies and dragonflies.
##
## Headless (counts only; fast with --fixed-fps):
##   godot --headless --fixed-fps 60 --path . res://tools/walker_test.tscn -- [map_id ...]
##   writes .liveliness_walk/headless.json
## With a window (counts plus frames, for liveliness while walking):
##   godot --path . res://tools/walker_test.tscn -- [map_id ...]
##   writes frames and a JSON per view to .liveliness_walk/raw/, measured by
##   python3 tools/liveliness_analyze.py watch .liveliness_walk

const Wild := preload("res://scripts/wildlife.gd")
const MAP_SCENE := preload("res://scenes/wilds/wilds.tscn")
const TILE := 16
const ZOOM := 5
const VIEW := Vector2i(43, 18)
const BLOCK := 6
const BLOCKS := Vector2i(7, 3)
const VIEWS := [Vector2i(0, 0), Vector2i(17, 0), Vector2i(0, 11), Vector2i(17, 11), Vector2i(0, 22), Vector2i(17, 22)]
const FPS := 8.0
const WARMUP := 12.0
const SETTLE := 2.0
const RECORD := 25.0
const RENDERED_MAPS := [120005, 120025, 120006, 120023, 120026, 120021, 120027, 120024, 120012, 120028, 120000, 120010, 120020]
const ARRIVE := 3.0 # px from a route point that counts as there
const STUCK_TIME := 1.0 # s without getting closer before the walker is moved on

var _headless := false
var _forest: Node2D
var _walker: CharacterBody2D
var _camera: Camera2D
var _plan: Array = []
var _map_i := -1
var _view_i := 0
var _state := ""
var _timer := 0.0
var _next_frame := 0.0
var _route: Array[Vector2] = []
var _route_i := 0
var _best := INF
var _stuck := 0.0
var _snags := 0
var _snag_at: Array = [] # [walker cell, goal cell] per snag, in the view's results
var _start := {}
var _results: Array = []
var _file: FileAccess
var _frames := 0
var _drawn := 0
var _walk_log: Array = [] # per frame: [x, y, sprite frame] relative to the view
var _times: Array[float] = []
var _travel := 0.0
var _last := Vector2.ZERO
var _out := ""


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	for a in OS.get_cmdline_user_args():
		_plan.append(int(a))
	if _plan.is_empty():
		if _headless:
			for r in 30:
				_plan.append(120000 + r)
		else:
			_plan = RENDERED_MAPS.duplicate()
	_out = ProjectSettings.globalize_path("res://.liveliness_walk")
	DirAccess.make_dir_recursive_absolute(_out + "/raw")
	DirAccess.remove_absolute(_out + "/raw/ALL_DONE")
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
		_finish()
		return
	var id: int = _plan[_map_i]
	_forest.build(id, -1)
	seed(id)
	_walker = _forest.actors.get_node("Walker")
	_walker.get_node("Camera").enabled = false
	_camera.make_current()
	_view_i = 0
	_aim()
	_state = "warm"
	_timer = WARMUP
	print("walker test: map %d (recipe %d %s), %d of %d" % [id, _forest.terrain.recipe_id, _forest.terrain.recipe.name, _map_i + 1, _plan.size()])


func _aim() -> void:
	_camera.position = Vector2(VIEWS[_view_i] * TILE)
	_release()


func _physics_process(delta: float) -> void:
	match _state:
		"warm", "settle":
			_release()
			_timer -= delta
			if _timer <= 0.0:
				_start_view()
		"stalled":
			if DisplayServer.window_can_draw() and Engine.get_frames_drawn() > _drawn + 10:
				_state = "settle"
				_timer = SETTLE
		"record":
			_timer += delta
			_steer(delta)
			_travel += _walker.position.distance_to(_last)
			_last = _walker.position
			if not _headless and _timer >= _next_frame:
				_next_frame += 1.0 / FPS
				_capture()
			if _timer >= RECORD:
				_finish_view()


# Heads for the next route point with analog strengths, so all eight
# directions come out of Input.get_vector the way a player's keys would.
func _steer(delta: float) -> void:
	if _route.size() < 2:
		_release()
		return
	var goal := _route[_route_i]
	var to := goal - _walker.position
	if to.length() < ARRIVE:
		_route_i = (_route_i + 1) % _route.size()
		_best = INF
		_stuck = 0.0
		return
	if to.length() < _best - 0.5:
		_best = to.length()
		_stuck = 0.0
	else:
		_stuck += delta
		if _stuck > STUCK_TIME: # snagged on a corner: move on to the point
			_snag_at.append([Vector2i(_walker.position / TILE), Vector2i(goal / TILE)])
			_walker.position = goal
			_snags += 1
			_stuck = 0.0
			return
	var d := to.normalized()
	_press("move_right", d.x)
	_press("move_left", -d.x)
	_press("move_down", d.y)
	_press("move_up", -d.y)


func _press(action: String, v: float) -> void:
	if v > 0.05:
		Input.action_press(action, clampf(v, 0.0, 1.0))
	else:
		Input.action_release(action)


func _release() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)


# A loop through the view: every animal in it (up to four), a cobble cell, a
# dirt island cell, two tuft or flower cells, a shore cell, and the ground
# under a tree, joined by A* paths that stay inside the view.
func _make_route() -> Array[Vector2]:
	var t: PaintedTerrain = _forest.terrain
	var view := Rect2i(VIEWS[_view_i], VIEW)
	var inner := view.grow(-1)
	var land: Dictionary = Wild.habitat_cells(t)["_land"]
	var astar := AStarGrid2D.new()
	astar.region = view
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	# Each open cell gets a point where the walker's body actually fits (the
	# wall of a ridge reaches into the rim below it, torches and rocks have
	# posts); a cell with no such point is closed.
	var spot := {}
	for y in range(view.position.y, view.end.y):
		for x in range(view.position.x, view.end.x):
			var c := Vector2i(x, y)
			var p := _free_point(c) if land.has(c) else Vector2.INF
			astar.set_point_solid(c, p == Vector2.INF)
			if p != Vector2.INF:
				spot[c] = p
	var picks: Array[Vector2i] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([t.map_id, _view_i])
	var animals := 0
	for a in _forest.wildlife._animals:
		var c := Vector2i(a.pos / TILE)
		if animals < 4 and inner.has_point(c) and land.has(c):
			picks.append(c)
			animals += 1
	var kinds := {"path": [], "dirt": [], "deco": [], "shore": [], "tree": []}
	for y in range(inner.position.y, inner.end.y):
		for x in range(inner.position.x, inner.end.x):
			var c := Vector2i(x, y)
			if not land.has(c):
				continue
			if t.path.has(c):
				kinds.path.append(c)
			if t.deco.has(c):
				kinds.deco.append(c)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if t.water.has(c + d):
					kinds.shore.append(c)
					break
	for b in t.blobs:
		for c in b.cells:
			if inner.has_point(c) and land.has(c):
				kinds.dirt.append(c)
	for c in Wild.habitat_cells(t)["_trunks"]:
		var below: Vector2i = c + Vector2i(0, 1)
		if inner.has_point(below) and land.has(below):
			kinds.tree.append(below)
	for k in ["path", "dirt", "deco", "deco", "shore", "tree"]:
		if not kinds[k].is_empty():
			picks.append(kinds[k][rng.randi() % kinds[k].size()])
	if picks.is_empty():
		return []
	# Nearest-neighbor order from the first pick, then A* legs between them.
	var order: Array[Vector2i] = [picks.pop_front()]
	while not picks.is_empty():
		var last: Vector2i = order[-1]
		var best := 0
		for i in picks.size():
			if Vector2(picks[i] - last).length() < Vector2(picks[best] - last).length():
				best = i
		order.append(picks.pop_at(best))
	# Join each pick to the last one reached; a pick with no path to it inside
	# the view (a yard whose gate is off screen) is skipped. The walker then
	# walks the route back, so every step of the loop is a real path.
	order = order.filter(func(c): return not astar.is_point_solid(c))
	if order.is_empty():
		return []
	var route: Array[Vector2] = [spot[order[0]]]
	var at: Vector2i = order[0]
	for i in range(1, order.size()):
		var leg := astar.get_id_path(at, order[i])
		if leg.is_empty():
			continue
		for c in leg.slice(1):
			route.append(spot[c])
		at = order[i]
	var back := route.slice(1, route.size() - 1)
	back.reverse()
	route.append_array(back)
	return route


# The first spot in `cell` where the walker's body box touches no world collider.
func _free_point(cell: Vector2i) -> Vector2:
	var body: CollisionShape2D = _walker.get_node("Body")
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = body.shape
	q.collision_mask = _walker.collision_mask
	q.exclude = [_walker.get_rid()]
	var space := get_world_2d().direct_space_state
	for off in [Vector2(8, 10), Vector2(8, 13), Vector2(8, 15), Vector2(8, 7), Vector2(5, 12), Vector2(11, 12)]:
		var p: Vector2 = Vector2(cell * TILE) + off
		q.transform = Transform2D(0.0, p + body.position)
		if space.intersect_shape(q, 1).is_empty():
			return p
	return Vector2.INF


func _counters() -> Dictionary:
	var f := _forest
	return {
		"steps": f.footsteps.stats.steps, "dust": f.footsteps.stats.dust, "grass": f.footsteps.stats.grass,
		"shore": f.footsteps.stats.shore, "leaves": f.leaves.kicked,
		"butterflies": f.critters.scattered.butterflies, "dragonflies": f.critters.scattered.dragonflies,
		"animals": f.wildlife.scared.duplicate(),
	}


func _start_view() -> void:
	# Planned here, inside a physics step after the settle, so every collider
	# of a freshly built map is in the physics space the route is checked against.
	_route = _make_route()
	_route_i = 0
	if not _route.is_empty():
		_walker.position = _route[0]
	_start = _counters()
	_snags = 0
	_snag_at.clear()
	_travel = 0.0
	_last = _walker.position
	_timer = 0.0
	_next_frame = 0.0
	_frames = 0
	_walk_log.clear()
	_times.clear()
	_best = INF
	_stuck = 0.0
	if not _headless:
		_file = FileAccess.open("%s/raw/%d_%d.rgb" % [_out, _plan[_map_i], _view_i], FileAccess.WRITE)
		_drawn = Engine.get_frames_drawn()
	_state = "record"


func _capture() -> void:
	if not DisplayServer.window_can_draw() or (_frames > 0 and Engine.get_frames_drawn() == _drawn):
		_file.close()
		DirAccess.remove_absolute("%s/raw/%d_%d.rgb" % [_out, _plan[_map_i], _view_i])
		_release()
		_state = "stalled"
		print("walker test: window stopped drawing; waiting to redo map %d view %d" % [_plan[_map_i], _view_i])
		return
	_drawn = Engine.get_frames_drawn()
	var img := get_viewport().get_texture().get_image()
	var world := Vector2i(img.get_width() / ZOOM, img.get_height() / ZOOM)
	img.resize(world.x, world.y, Image.INTERPOLATE_NEAREST)
	if world != VIEW * TILE:
		img = img.get_region(Rect2i(Vector2i.ZERO, VIEW * TILE))
	img.convert(Image.FORMAT_RGB8)
	_file.store_buffer(img.get_data())
	_frames += 1
	_times.append(_timer)
	var local := _walker.position - Vector2(VIEWS[_view_i] * TILE)
	_walk_log.append([snappedf(local.x, 0.01), snappedf(local.y, 0.01), _walker.get_node("Sprite").frame])


func _finish_view() -> void:
	_release()
	var now := _counters()
	var got := {}
	for k in now:
		if k == "animals":
			var per := {}
			for kind in now.animals:
				var n: int = now.animals[kind] - _start.animals.get(kind, 0)
				if n > 0:
					per[kind] = n
			got[k] = per
		else:
			got[k] = now[k] - _start[k]
	var id: int = _plan[_map_i]
	var in_view := {}
	for a in _forest.wildlife._animals:
		if Rect2i(VIEWS[_view_i], VIEW).has_point(Vector2i(a.home / TILE)):
			in_view[a.kind] = in_view.get(a.kind, 0) + 1
	var row := {"map": id, "recipe": _forest.terrain.recipe_id, "recipe_name": _forest.terrain.recipe.name,
		"view": _view_i, "origin": [VIEWS[_view_i].x, VIEWS[_view_i].y], "seconds": RECORD,
		"route_points": _route.size(), "travel": snappedf(_travel, 0.1), "snags": _snags, "snag_at": str(_snag_at),
		"animals_homed_here": in_view, "counts": got}
	_results.append(row)
	if not _headless:
		_file.close()
		var meta := row.duplicate()
		meta.merge({"holdout": false, "size": [VIEW.x * TILE, VIEW.y * TILE], "block_px": BLOCK * TILE,
			"blocks_xy": [BLOCKS.x, BLOCKS.y], "frames": _frames, "times": _times, "fps": FPS,
			"walker": _walk_log, "blocks": []})
		var stem := "%d_%d" % [id, _view_i]
		var tmp := "%s/raw/%s.json.part" % [_out, stem]
		FileAccess.open(tmp, FileAccess.WRITE).store_string(JSON.stringify(meta))
		DirAccess.rename_absolute(tmp, "%s/raw/%s.json" % [_out, stem])
	_view_i += 1
	if _view_i >= VIEWS.size():
		_print_map(id)
		_next_map()
	else:
		_aim()
		_state = "settle"
		_timer = SETTLE


func _print_map(id: int) -> void:
	var sum := {}
	var animals := {}
	var travel := 0.0
	var snags := 0
	for r in _results:
		if r.map != id:
			continue
		travel += r.travel
		snags += r.snags
		for k in r.counts:
			if k == "animals":
				for kind in r.counts.animals:
					animals[kind] = animals.get(kind, 0) + r.counts.animals[kind]
			else:
				sum[k] = sum.get(k, 0) + r.counts[k]
	var parts := PackedStringArray()
	for kind in animals:
		parts.append("%s %d" % [kind, animals[kind]])
	print("walker test: map %d done: walked %.0f px (%d snags); steps %d, dust %d, grass %d, shore %d, leaves %d, butterflies %d, dragonflies %d; animals: %s" % [
		id, travel, snags, sum.steps, sum.dust, sum.grass, sum.shore, sum.leaves, sum.butterflies, sum.dragonflies,
		", ".join(parts) if not parts.is_empty() else "none"])


func _finish() -> void:
	var fname := "headless.json" if _headless else "rendered_counts.json"
	FileAccess.open("%s/%s" % [_out, fname], FileAccess.WRITE).store_string(JSON.stringify(_results))
	if not _headless:
		FileAccess.open(_out + "/raw/ALL_DONE", FileAccess.WRITE).store_string("done")
	print("walker test: all done")
	get_tree().quit()
