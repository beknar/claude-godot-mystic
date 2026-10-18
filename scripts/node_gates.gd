extends "res://scripts/forest.gd"
## node-gates: a world of Painted Lands Forest maps joined at their edges.
## Each map has a gate in the middle of its north, east, south, and west
## edges (gate_roads.gd); walking out through one builds the next map, the
## node one step that way (gate_world.gd: names, rings, map types, foes,
## rewards, and the save file). A new node only opens once every foe on the
## current one is down; a node already visited always opens. Clearing a node
## leaves a chest. Every node's state (foes left and where, the chest) is kept
## in the save file, so a map comes back as it was left. The strategic map
## (M) draws the nodes visited and the moves between them.
##
## Painted Lands Forest tiles, Cozy Cottage interiors behind every door,
## Cozy Farm animals round the homes; the foes are the Green Caves slimes and
## the Painted Lands RPG Characters (foe.gd).

const GATE_SIDES := ["n", "e", "s", "w"]
const FLOW_EVERY := 0.25 # s between flow-field updates
const ARRIVE_GRACE := 0.6 # s after arriving before a gate can trigger
const CHEST_ART := {false: [Vector2i(26, 28), Vector2i(27, 28)], true: [Vector2i(26, 29), Vector2i(27, 29)]} # gold -> [closed, open]
const GATE_RETRIES := 6
const SAVE_EVERY := 8.0 # s between saves of where the foes stand # map ids tried for a new node whose gates do not all fit

@onready var ui: CanvasLayer = $UI

var world := GateWorld.new()
var walker: CharacterBody2D
var foes: Array[Foe] = []
var chest: StaticBody2D
var gate_marks: GateMarks
var busy := false # a gate change, a death, or a new game in progress
var _flow := PackedInt32Array()
var _flow_clock := 0.0
var _flow_cell := Vector2i(-1, -1)
var _arrive := 0.0
var _toast_clock := 0.0
var _save_clock := SAVE_EVERY
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	gates = true
	interiors = true
	cozy_animals = true
	_rng.randomize()
	if not world.load_save():
		world.new_game(_rng.randi_range(1, 1 << 30))
	gate_marks = GateMarks.new()
	gate_marks.name = "GateMarks"
	gate_marks.z_index = 20
	add_child(gate_marks)
	ui.setup(self)
	var c := world.current
	map_id = world.node(c).get("map_id", world.map_id_for(c))
	recipe = GateWorld.recipe_for(c)
	super._ready()


# ---------------------------------------------------------------- building

## Builds the map for the current node (super.build), then its gates, foes,
## and chest. A new node whose gates do not all fit tries the next map ids.
func build(id: int, pinned := -1) -> void:
	var c := world.current
	var fresh := not world.visited(c)
	for i in GATE_RETRIES:
		super.build(id + i * 7919, GateWorld.recipe_for(c))
		if not fresh or _gates_ok():
			break
	if fresh:
		world.nodes[c] = {"map_id": map_id, "cleared": false, "foes": [], "chest": {}, "new": true}
	_enter_node()


func _gates_ok() -> bool:
	for side in GATE_SIDES:
		if not terrain.gate_cells.has(side) or not terrain._reaches(terrain.spawn, terrain.gate_cells[side].cell):
			return false
	return true


func _spawn_walker() -> void:
	walker = WALKER_SCENE.instantiate()
	walker.set_script(preload("res://scripts/gate_walker.gd"))
	walker.name = "Walker"
	walker.position = _entry_point(world.entry)
	actors.add_child(walker)
	walker.swung.connect(_on_swing)
	walker.hurt.connect(_on_hurt)
	var camera: Camera2D = walker.get_node("Camera")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = PaintedTerrain.WIDTH * TILE
	camera.limit_bottom = PaintedTerrain.HEIGHT * TILE
	camera.reset_smoothing()


# Where the walker stands on arriving through `side` (just inside that gate),
# or the map's own spawn.
func _entry_point(side: String) -> Vector2:
	if not terrain.gate_cells.has(side):
		return Vector2(terrain.spawn * TILE) + Vector2(TILE / 2.0, TILE - 1)
	var g: Vector2i = terrain.gate_cells[side].cell
	match side:
		"n":
			return Vector2((g.x + 1) * TILE, (g.y + 1) * TILE + 12)
		"s":
			return Vector2((g.x + 1) * TILE, g.y * TILE + 10)
		"e":
			return Vector2(g.x * TILE + 8, (g.y + 1) * TILE + 6)
	return Vector2((g.x + 1) * TILE + 8, (g.y + 1) * TILE + 6)


func _enter_node() -> void:
	var c := world.current
	var node: Dictionary = world.nodes[c]
	foes.clear()
	chest = null
	if node.get("new", false) or (not node.cleared and node.foes.is_empty()):
		node.erase("new")
		node.foes = _plan_foes(c)
	for f in node.foes:
		_spawn_foe(f)
	if not node.chest.is_empty():
		_place_chest(Vector2i(node.chest.x, node.chest.y), node.chest.opened, GateWorld.reward_for(c).gold)
	_flow_cell = Vector2i(-1, -1)
	_arrive = ARRIVE_GRACE
	gate_marks.setup(self)
	ui.refresh()
	world.save()


# First visit: the foes of the ring's plan, spread over the map away from
# where the walker came in, each on a cell with open ground all round.
func _plan_foes(c: Vector2i) -> Array:
	var plan := world.foe_plan(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_id * 13 + 5
	var start := Vector2i(walker.position / TILE)
	var dist := _distances(start)
	var cells: Array[Vector2i] = []
	var far := 14
	while cells.size() < plan.size() * 3 and far > 4:
		cells.clear()
		for y in range(1, PaintedTerrain.HEIGHT - 1):
			for x in range(1, PaintedTerrain.WIDTH - 1):
				var cell := Vector2i(x, y)
				if dist[y * PaintedTerrain.WIDTH + x] >= far and _open_round(cell):
					cells.append(cell)
		far -= 3
	var out: Array = []
	var placed: Array[Vector2i] = []
	for p in plan:
		var pick := Vector2i(-1, -1)
		for i in 60:
			if cells.is_empty():
				break
			var cell: Vector2i = cells[rng.randi() % cells.size()]
			var spaced := true
			for q in placed:
				if Vector2(cell - q).length() < 6.0:
					spaced = false
			if spaced or i > 40:
				pick = cell
				break
		if pick.x < 0:
			continue
		placed.append(pick)
		var pos := Vector2(pick) * TILE + Vector2(8, 12)
		var stats := Foe.new()
		stats.setup(p.kind, GateWorld.ring(c), p.boss)
		out.append({"kind": p.kind, "x": pos.x, "y": pos.y, "hp": stats.max_hp, "boss": p.boss})
		stats.free()
	return out


func _open_round(cell: Vector2i) -> bool:
	for y in range(-1, 2):
		for x in range(-1, 2):
			if not terrain.walkable(cell + Vector2i(x, y)):
				return false
	return true


func _spawn_foe(f: Dictionary) -> void:
	var foe := Foe.new()
	foe.setup(f.kind, GateWorld.ring(world.current), f.get("boss", false))
	foe.hp = mini(int(f.hp), foe.max_hp)
	foe.position = Vector2(f.x, f.y)
	foe.home = foe.position
	foe.map = self
	foe.name = "Foe_%s_%d" % [f.kind, foes.size()]
	foe.died.connect(_on_foe_died)
	actors.add_child(foe)
	foes.append(foe)


func _place_chest(cell: Vector2i, opened: bool, gold: bool) -> void:
	chest = StaticBody2D.new()
	chest.name = "RewardChest"
	chest.collision_mask = 0
	chest.position = Vector2(cell * TILE) + Vector2(8, 14)
	var sprite := _region_sprite(Rect2(Vector2(CHEST_ART[gold][1 if opened else 0] * TILE), Vector2(TILE, TILE)), Vector2(-8, -14))
	sprite.name = "Sprite"
	chest.add_child(sprite)
	_add_box(chest, Rect2(-6, -6, 12, 6))
	chest.set_meta("opened", opened)
	chest.set_meta("gold", gold)
	actors.add_child(chest)


# ---------------------------------------------------------------- play

func _physics_process(delta: float) -> void:
	if walker == null or busy:
		return
	_toast_clock = maxf(0.0, _toast_clock - delta)
	_arrive = maxf(0.0, _arrive - delta)
	if not walker_active():
		return
	_save_clock -= delta
	if _save_clock <= 0.0:
		_save_clock = SAVE_EVERY
		_store_node()
		world.save()
	_flow_clock -= delta
	var cell := Vector2i(walker.position / TILE)
	if _flow_clock <= 0.0 or cell != _flow_cell:
		_flow_clock = FLOW_EVERY
		_flow_cell = cell
		_flow = _distances(cell)
	if chest and not chest.get_meta("opened") and walker.position.distance_to(chest.position) < 15.0:
		_open_chest()
	if _arrive <= 0.0:
		for side in GATE_SIDES:
			if _at_gate(side):
				_try_gate(side)
				break


func walker_active() -> bool:
	return walker != null and not busy and not walker.frozen and (house_interiors == null or house_interiors.inside < 0) and world.hero.hp > 0


func _at_gate(side: String) -> bool:
	if not terrain.gate_cells.has(side):
		return false
	var g: Vector2i = terrain.gate_cells[side].cell
	var p := walker.position
	match side:
		"n":
			return p.y < g.y * TILE + 8 and p.x > g.x * TILE - 4 and p.x < (g.x + 2) * TILE + 4
		"s":
			return p.y > (g.y + 2) * TILE - 6 and p.x > g.x * TILE - 4 and p.x < (g.x + 2) * TILE + 4
		"e":
			return p.x > (g.x + 2) * TILE - 7 and p.y > g.y * TILE - 4 and p.y < (g.y + 2) * TILE + 6
	return p.x < g.x * TILE + 7 and p.y > g.y * TILE - 4 and p.y < (g.y + 2) * TILE + 6


func gate_state(side: String) -> String:
	var dest: Vector2i = world.current + GateWorld.DIRS[side]
	if not GateWorld.in_world(dest):
		return "edge"
	if world.visited(dest):
		return "visited"
	return "open" if world.cleared(world.current) else "locked"


func _try_gate(side: String) -> void:
	match gate_state(side):
		"edge":
			_toast_once("The land ends here.")
		"locked":
			_toast_once("Defeat every foe to open a new way (%d left)." % foes_left())
		_:
			travel(world.current + GateWorld.DIRS[side], GateWorld.OPPOSITE[side])


func _toast_once(text: String) -> void:
	if _toast_clock <= 0.0:
		ui.toast(text)
		_toast_clock = 2.5


func foes_left() -> int:
	var n := 0
	for f in foes:
		if f.alive():
			n += 1
	return n


## The walker's swing landed at `at`: every foe in reach is hit.
func _on_swing(at: Vector2, _dir: Vector2) -> void:
	for f in foes.duplicate():
		if f.alive() and (f.position + Vector2(0, -6)).distance_to(at) <= 12.0 + f.radius:
			f.take_hit(world.hero.damage, walker.position)


func hurt_walker(amount: int, from: Vector2) -> void:
	if walker_active():
		walker.take_hit(amount, from)


func _on_hurt(amount: int) -> void:
	world.hero.hp = maxi(0, world.hero.hp - amount)
	ui.refresh()
	if world.hero.hp <= 0:
		_die()


func _on_foe_died(foe: Foe) -> void:
	foes.erase(foe)
	foe.queue_free()
	_store_node()
	ui.refresh()
	if foes_left() == 0 and not world.cleared(world.current):
		_clear_node()


func _clear_node() -> void:
	var node: Dictionary = world.nodes[world.current]
	node.cleared = true
	var gold: bool = GateWorld.reward_for(world.current).gold
	var cell := _chest_cell()
	node.chest = {"x": cell.x, "y": cell.y, "opened": false}
	_place_chest(cell, false, gold)
	gate_marks.queue_redraw()
	ui.toast("%s is clear. A chest appeared, and every gate is open." % GateWorld.node_name(world.current))
	ui.refresh()
	world.save()


# An open cell a few steps from the walker for the reward chest.
func _chest_cell() -> Vector2i:
	var start := Vector2i(walker.position / TILE)
	var dist := _distances(start)
	var best := start
	var best_score := 1 << 20
	for y in range(1, PaintedTerrain.HEIGHT - 1):
		for x in range(1, PaintedTerrain.WIDTH - 1):
			var d := dist[y * PaintedTerrain.WIDTH + x]
			var cell := Vector2i(x, y)
			if d < 2 or not _open_round(cell) or terrain.path.has(cell):
				continue
			var score := absi(d - 3)
			if score < best_score:
				best_score = score
				best = cell
	return best


func _open_chest() -> void:
	var node: Dictionary = world.nodes[world.current]
	node.chest.opened = true
	chest.set_meta("opened", true)
	var gold: bool = chest.get_meta("gold")
	chest.get_node("Sprite").region_rect = Rect2(Vector2(CHEST_ART[gold][1] * TILE), Vector2(TILE, TILE))
	var r := GateWorld.reward_for(world.current)
	var h: Dictionary = world.hero
	h.coins += r.coins
	h.max_hp += r.max_hp
	h.damage += r.damage
	h.hp = mini(h.max_hp, h.hp + r.heal + r.max_hp)
	var parts := ["%d coins" % r.coins]
	if r.max_hp > 0:
		parts.append("+%d heart%s" % [r.max_hp / 2, "" if r.max_hp == 2 else "s"])
	if r.damage > 0:
		parts.append("+%d sword" % r.damage)
	parts.append("healed" if r.heal >= 99 else "a little healing")
	ui.toast("Chest: " + ", ".join(parts) + ".")
	ui.refresh()
	world.save()


# Keeps the current node's foes (where they stand, their hit points).
func _store_node() -> void:
	if not world.nodes.has(world.current):
		return
	var out: Array = []
	for f in foes:
		if f.alive():
			out.append({"kind": f.kind, "x": snappedf(f.home.x if f.state == Foe.State.IDLE else f.position.x, 0.1),
				"y": snappedf(f.home.y if f.state == Foe.State.IDLE else f.position.y, 0.1), "hp": f.hp, "boss": f.boss})
	world.nodes[world.current].foes = out


# ---------------------------------------------------------------- travel

## Leaves the current node for `dest`, arriving through its `side` gate ("":
## the map's own spawn).
func travel(dest: Vector2i, side: String) -> void:
	if busy:
		return
	busy = true
	walker.frozen = true
	await ui.fade(1.0)
	_store_node()
	if dest != world.current and (dest - world.current).length() == 1:
		world.links[GateWorld.link_key(world.current, dest)] = true
	world.current = dest
	world.entry = side
	var node := world.node(dest)
	build(node.get("map_id", world.map_id_for(dest)), GateWorld.recipe_for(dest))
	if house_interiors:
		house_interiors.walker = walker
	await ui.fade(0.0)
	busy = false
	ui.refresh()


func _die() -> void:
	if busy:
		return
	walker.frozen = true
	ui.toast("You were defeated. Back to c-0.")
	await get_tree().create_timer(1.2).timeout
	world.hero.hp = world.hero.max_hp
	travel(Vector2i.ZERO, "")


## Erases the save and starts a new world from c-0.
func new_game() -> void:
	if busy:
		return
	GateWorld.erase_save()
	world.new_game(_rng.randi_range(1, 1 << 30))
	busy = true
	walker.frozen = true
	await ui.fade(1.0)
	world.current = Vector2i.ZERO
	world.entry = ""
	build(world.map_id_for(Vector2i.ZERO), 0)
	await ui.fade(0.0)
	busy = false
	ui.refresh()
	ui.toast("A new world. Clear c-0 to open its gates.")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and world.nodes.has(world.current):
		_store_node()
		world.save()


# ---------------------------------------------------------------- foe help

# Steps from every walkable cell to `from` (4-neighbor BFS), -1 where none.
func _distances(from: Vector2i) -> PackedInt32Array:
	var w := PaintedTerrain.WIDTH
	var d := PackedInt32Array()
	d.resize(w * PaintedTerrain.HEIGHT)
	d.fill(-1)
	if not terrain.walkable(from):
		for n in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if terrain.walkable(from + n):
				from = from + n
				break
	if not terrain.walkable(from):
		return d
	d[from.y * w + from.x] = 0
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		var next := d[c.y * w + c.x] + 1
		for n in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var m: Vector2i = c + n
			if terrain.walkable(m) and d[m.y * w + m.x] < 0:
				d[m.y * w + m.x] = next
				queue.append(m)
	return d


## Where a foe at `pos` should head to close on `goal` (the walker): the
## center of the neighboring cell nearest the walker by the flow field, or
## straight at it when close or off the field.
func flow_step(pos: Vector2, goal: Vector2) -> Vector2:
	var w := PaintedTerrain.WIDTH
	var cell := Vector2i(pos / TILE)
	if _flow.is_empty() or not terrain._inside(cell):
		return goal
	var here := _flow[cell.y * w + cell.x]
	if here <= 1:
		return goal
	var best := cell
	var best_d := here
	for y in range(-1, 2):
		for x in range(-1, 2):
			var n := cell + Vector2i(x, y)
			if (x == 0 and y == 0) or not terrain._inside(n):
				continue
			if x != 0 and y != 0 and not (terrain.walkable(cell + Vector2i(x, 0)) and terrain.walkable(cell + Vector2i(0, y))):
				continue
			var nd := _flow[n.y * w + n.x]
			if nd >= 0 and nd < best_d:
				best_d = nd
				best = n
	if best == cell:
		return goal
	return Vector2(best) * TILE + Vector2(8, 10)


## A walkable cell within `r` of `home` for a foe to wander to.
func wander_cell(home: Vector2, r: int) -> Vector2i:
	var h := Vector2i(home / TILE)
	for i in 12:
		var c := h + Vector2i(_rng.randi_range(-r, r), _rng.randi_range(-r, r))
		if terrain.walkable(c):
			return c
	return h


## Chevrons at the gates, pointing out of the map: pale gold when the gate
## opens (a visited node, or every foe here down), red when it is still
## shut, none at the edge of the world. Drawn on whole pixels over the map.
class GateMarks extends Node2D:
	var map: Node
	var _t := 0.0

	func setup(p_map: Node) -> void:
		map = p_map
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		if map == null or map.terrain == null:
			return
		for side in map.GATE_SIDES:
			if not map.terrain.gate_cells.has(side):
				continue
			var state: String = map.gate_state(side)
			if state == "edge":
				continue
			var g: Vector2i = map.terrain.gate_cells[side].cell
			var out: Vector2 = Vector2(GateWorld.DIRS[side].x, -GateWorld.DIRS[side].y)
			var mid: Vector2
			match side:
				"n":
					mid = Vector2((g.x + 1) * 16, g.y * 16 + 5)
				"s":
					mid = Vector2((g.x + 1) * 16, (g.y + 2) * 16 - 5)
				"e":
					mid = Vector2((g.x + 2) * 16 - 5, (g.y + 1) * 16)
				_:
					mid = Vector2(g.x * 16 + 5, (g.y + 1) * 16)
			var col := Color(1.0, 0.93, 0.6) if state != "locked" else Color(0.9, 0.3, 0.25)
			col.a = 0.55 + 0.35 * sin(_t * 3.0)
			var across := Vector2(-out.y, out.x)
			for k in 2:
				var tip := mid + out * (k * 4.0 + 2.0 * sin(_t * 3.0))
				for i in range(-3, 4):
					var p := (tip - out * absf(i) + across * i).round()
					draw_rect(Rect2(p, Vector2.ONE), col)
