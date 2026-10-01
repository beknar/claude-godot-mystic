class_name HouseInteriors
extends Node
## Doors and interiors for the Painted Lands randomizer. Every house gets a
## home behind its door (interior_plan.gd, one to six rooms by the size of
## the building and the map id): walk up onto a doorstep and keep walking
## into the door, and the screen fades to black and opens on the interior, a
## sub-map built far below the outdoor map; walk out through the gap in the
## south wall and you are back on the doorstep, facing out. While indoors the
## outdoor map is hidden and its ambience paused, and the interior has its
## own: hearth and lamp light (fire_ambience.gd), sunbeams from the windows,
## steam, moths, and a cat (interior_life.gd). Each house's interior is built
## once per map and kept, so leaving and coming back finds it the same.

const TILE := 16
const OFFSET := Vector2(0, 20000) # the interior sits far below the map
const FADE := 0.16
## Rooms per building (house ids of PaintedTerrain.HOUSES): the porch
## cottage is the largest, the shed a single room.
const ROOMS := {0: [3, 6], 1: [2, 4], 2: [2, 5], 3: [1, 2], 4: [1, 1], 5: [1, 3],
	# Cozy Farm homes (the cozy farm randomizer), by size; the red barn when
	# a recipe names it as a building (Woodcutter camp).
	10: [2, 3], 11: [3, 5], 12: [2, 4], 13: [2, 4], 14: [1, 3], 15: [2, 4], 16: [2, 3], 20: [1, 3]}

var map: Node2D # forest.gd
var walker: CharacterBody2D
var doors: Array[Dictionary] = [] # {rect (world px, the doorstep's upper part), house, index, step (world px)}
var inside := -1 # door index, or -1 outdoors
var plans := {} # door index -> InteriorPlan
var root: Node2D
var view: Node2D # an InteriorView, or a custom interior (the Farm greenhouse)
var life: InteriorLife
var fire: FireAmbience
var entered := 0 # for tools: times the walker went in

var _fade: ColorRect
var _hidden: Array = [] # [node, visible, process_mode]
var _busy := false
var _cooldown := 0.0
var _map_limits := Rect2i()


func setup(p_map: Node2D) -> void:
	map = p_map
	root = Node2D.new()
	root.name = "Interior"
	root.position = OFFSET
	root.visible = false
	map.add_child(root)
	var layer := CanvasLayer.new()
	layer.name = "Fade"
	layer.layer = 20
	map.add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)


## After every map build: the doors of this map's houses.
## `leaves`: house -> its DoorLeaf (forest.gd), if it has one.
func reset(terrain: PaintedTerrain, p_walker: CharacterBody2D, leaves := {}) -> void:
	var list: Array[Dictionary] = []
	for i in terrain.houses.size():
		var house: Dictionary = terrain.houses[i]
		var art: Dictionary = PaintedTerrain.HOUSES[house.id]
		var d := {"step": house.origin + art.door, "house": house}
		if leaves.has(house):
			d["leaf"] = leaves[house]
		list.append(d)
	reset_doors(list, p_walker)


## Any map: `list` of doors, each {step: the doorstep cell under the door,
## house: {id, ...} (seeds the interior), width (cells, default 1), rooms
## ([min, max], else ROOMS by house id), leaf (optional DoorLeaf: the front
## door, opened as the walker comes up), custom (optional Callable returning
## {view: Node2D with `actors`, plan: InteriorPlan with size and exit_cell,
## fires: Array} for an interior of its own)}.
func reset_doors(list: Array[Dictionary], p_walker: CharacterBody2D) -> void:
	if inside >= 0:
		# Rebuilt while indoors (the menu): drop the interior and the old walker in it.
		_restore_outdoors()
		inside = -1
		root.visible = false
		for c in root.get_children():
			root.remove_child(c)
			c.queue_free()
	_busy = false
	_fade.color.a = 0.0
	walker = p_walker
	doors.clear()
	plans.clear()
	for k in _custom:
		var v: Node = _custom[k].view
		if is_instance_valid(v) and not v.is_inside_tree():
			v.free()
	_custom.clear()
	for i in list.size():
		var d: Dictionary = list[i]
		var step: Vector2i = d.step # the doorstep cell, under the door
		var w: int = d.get("width", 1)
		var door := {"rect": Rect2(Vector2(step * TILE) + Vector2(1, 0), Vector2(TILE * w - 2, 10)), "house": d.house, "index": i,
			"step": Vector2(step * TILE) + Vector2(8 * w, 12)}
		for k in ["rooms", "custom", "leaf"]:
			if d.has(k):
				door[k] = d[k]
		doors.append(door)
	if walker:
		var cam: Camera2D = walker.get_node("Camera")
		_map_limits = Rect2i(cam.limit_left, cam.limit_top, cam.limit_right - cam.limit_left, cam.limit_bottom - cam.limit_top)


## The plan behind door `i` (built once per map).
func plan_for(i: int) -> InteriorPlan:
	if not plans.has(i):
		var house: Dictionary = doors[i].house
		var r: Array = doors[i].get("rooms", ROOMS.get(house.id, [1, 3]))
		var seed := hash(Vector3i(map.map_id, i, house.id))
		var n: int = r[0] + posmod(seed, r[1] - r[0] + 1)
		plans[i] = InteriorPlan.new().generate(seed, n, {"black": true, "exit_width": 1})
	return plans[i]


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	if _busy or not is_instance_valid(walker):
		return
	var feet := walker.global_position
	if inside < 0:
		if _cooldown > 0.0 or not Input.is_action_pressed("move_up"):
			return
		for d in doors:
			if d.rect.has_point(feet):
				enter(d.index)
				return
	else:
		var p: InteriorPlan = plans[inside]
		var exit_rect := Rect2(root.position + view.position + Vector2(p.exit_cell * TILE) + Vector2(0, 4), Vector2(TILE, TILE))
		if exit_rect.has_point(feet) and Input.is_action_pressed("move_down"):
			leave()


# Front doors (DoorLeaf) swing open while the walker is on or just before
# the doorstep, and shut once it has walked off.
func _process(_delta: float) -> void:
	if inside >= 0 or not is_instance_valid(walker):
		return
	var feet := walker.global_position - map.global_position
	for d in doors:
		var leaf = d.get("leaf")
		if leaf == null or not is_instance_valid(leaf):
			continue
		var s: Vector2 = d.step
		var half: float = d.rect.size.x / 2.0 + 9.0
		leaf.open = absf(feet.x - s.x) < half and feet.y > s.y - 16.0 and feet.y < s.y + 22.0


## Goes in through door `i` (fades, builds or reuses the interior).
func enter(i: int, instant := false) -> void:
	_busy = true
	if not instant:
		await _fade_to(1.0)
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	if doors[i].has("custom"):
		_enter_custom(i)
		if not instant:
			await _fade_to(0.0)
		_busy = false
		return
	var p := plan_for(i)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.position = Vector2(-2000, -2000)
	backdrop.size = Vector2(p.size * TILE) + Vector2(4000, 4000)
	root.add_child(backdrop)
	var iv := InteriorView.new()
	view = iv
	view.name = "View"
	root.add_child(view)
	iv.build(p)
	# The view sits at the root's origin, so its space is the root's. The
	# life node goes between the floor layers and the actors: beams on the
	# floor, under the furniture.
	life = InteriorLife.new()
	view.add_child(life)
	view.move_child(life, view.actors.get_index())
	fire = FireAmbience.new()
	root.add_child(fire)
	var fires: Array[Dictionary] = []
	for r in iv.hearths:
		fires.append({"pos": r.end, "kind": "hearth", "flame": r.get_center(), "radius": 30, "smoke": false})
	for l in iv.lamps:
		fires.append({"pos": l, "kind": "lamp", "flame": l, "radius": 14, "smoke": false})
	fire.set_fires(fires)
	# Hide the outdoors and move the walker in, just inside the way out.
	inside = i
	_hide_outdoors()
	walker.reparent(iv.actors, false)
	walker.position = Vector2(p.exit_cell.x * TILE + 8, (p.exit_cell.y - 1) * TILE + 12)
	walker.set("facing", 3) # up
	life.setup([view], iv.actors, walker, true)
	root.visible = true
	_set_camera(Rect2(root.position + view.position, Vector2(p.size * TILE)))
	entered += 1
	_cooldown = 0.5
	if not instant:
		await _fade_to(0.0)
	_busy = false


var _custom := {} # door index -> {view, plan, fires}, built once per map


# An interior of its own (the Farm greenhouse): built once by the door's
# Callable and kept, entered the same way (walker just inside the way out).
func _enter_custom(i: int) -> void:
	if not _custom.has(i):
		_custom[i] = doors[i].custom.call()
	var built: Dictionary = _custom[i]
	var p: InteriorPlan = built.plan
	plans[i] = p
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	backdrop.position = Vector2(-2000, -2000)
	backdrop.size = Vector2(p.size * TILE) + Vector2(4000, 4000)
	root.add_child(backdrop)
	view = built.view
	if view.get_parent():
		view.get_parent().remove_child(view)
	root.add_child(view)
	fire = FireAmbience.new()
	root.add_child(fire)
	var fires: Array[Dictionary] = []
	fires.assign(built.get("fires", []))
	fire.set_fires(fires)
	inside = i
	_hide_outdoors()
	var acts: Node2D = view.get("actors")
	walker.reparent(acts, false)
	walker.position = Vector2(p.exit_cell.x * TILE + 8, (p.exit_cell.y - 1) * TILE + 12)
	walker.set("facing", 3)
	root.visible = true
	_set_camera(Rect2(root.position + view.position, Vector2(p.size * TILE)))
	entered += 1
	_cooldown = 0.5


## Walks back out onto the doorstep.
func leave(instant := false) -> void:
	_busy = true
	if not instant:
		await _fade_to(1.0)
	var d: Dictionary = doors[inside]
	_restore_outdoors()
	walker.reparent(map.actors, false)
	walker.position = d.step
	walker.set("facing", 2) # down
	if d.has("leaf") and is_instance_valid(d.leaf):
		d.leaf.snap_open() # out through the open door; it shuts behind the walker
	if _custom.has(inside) and view and view.get_parent() == root:
		root.remove_child(view) # kept for the next visit
	inside = -1
	root.visible = false
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	var cam: Camera2D = walker.get_node("Camera")
	cam.limit_left = _map_limits.position.x
	cam.limit_top = _map_limits.position.y
	cam.limit_right = _map_limits.end.x
	cam.limit_bottom = _map_limits.end.y
	cam.reset_smoothing()
	_cooldown = 0.6
	if not instant:
		await _fade_to(0.0)
	_busy = false


func _fade_to(a: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", a, FADE)
	await tw.finished


# Hides and pauses everything outdoors (the interior, the fade, and the menu
# stay).
func _hide_outdoors() -> void:
	_hidden.clear()
	for c in map.get_children():
		if c == root or c is CanvasLayer or c == self:
			continue
		_hidden.append([c, c.get("visible"), c.process_mode])
		if c is CanvasItem:
			c.visible = false
		c.process_mode = Node.PROCESS_MODE_DISABLED


func _restore_outdoors() -> void:
	for h in _hidden:
		var n: Node = h[0]
		if not is_instance_valid(n):
			continue
		if n is CanvasItem:
			n.visible = h[1]
		n.process_mode = h[2]
	_hidden.clear()


# Camera limits round the interior, at least a screen wide and tall so a small
# home sits in the middle of the view.
func _set_camera(r: Rect2) -> void:
	var cam: Camera2D = walker.get_node("Camera")
	var view_size := walker.get_viewport_rect().size / cam.zoom
	var grow := Vector2(maxf(0.0, (view_size.x - r.size.x) / 2.0), maxf(0.0, (view_size.y - r.size.y) / 2.0))
	var lim := r.grow_individual(grow.x, grow.y, grow.x, grow.y)
	cam.limit_left = int(lim.position.x)
	cam.limit_top = int(lim.position.y)
	cam.limit_right = int(lim.end.x)
	cam.limit_bottom = int(lim.end.y)
	cam.reset_smoothing()
