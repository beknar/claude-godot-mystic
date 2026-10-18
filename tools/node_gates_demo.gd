extends Node
## Demo reel for node-gates: plays the scene by itself, through the real
## input actions, while the movie writer records it. It clears c-0 of its
## slimes, opens the chest, walks out the east gate, tries a gate on the new
## map before it is clear (shut), clears it, goes north, shows the strategic
## map, then cuts out to ring 26 to fight samurai and knights, and ends on the
## strategic map. Uses its own save file, so the player's save is untouched.
##   godot --path . --write-movie <out>.avi --fixed-fps 30 --resolution 1720x720 res://tools/node_gates_demo.tscn

const DEMO_SAVE := "user://node_gates_demo.json"
const SEED := 12345
const LIMIT := 240.0 # s of game time before giving up
const SWING_EVERY := 0.4

@onready var game: Node = $Game

var _steps: Array[Dictionary] = []
var _step := -1
var _t := 0.0
var _total := 0.0
var _swing_clock := 0.0
var _attack_down := false
var _field := PackedInt32Array()
var _field_cell := Vector2i(-1, -1)
var _field_clock := 0.0
var _last_pos := Vector2.ZERO
var _stuck := 0.0
var _jitter := 0.0
var _jitter_dir := Vector2.ZERO
var _kills_at_start := 0
var _caption: Label
var _caption_tween: Tween


func _enter_tree() -> void:
	GateWorld.save_path = DEMO_SAVE
	GateWorld.erase_save()
	var w := GateWorld.new()
	w.new_game(SEED)
	w.hero.max_hp = 12
	w.hero.hp = 12
	w.save()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	_caption = Label.new()
	_caption.add_theme_font_size_override("font_size", 64)
	_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_caption.add_theme_constant_override("outline_size", 12)
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_caption.offset_bottom = -110
	_caption.modulate.a = 0.0
	layer.add_child(_caption)
	_steps = [
		{"do": "caption", "text": "node-gates: Painted Lands Forest maps joined at their edges"},
		{"do": "wait", "time": 2.5},
		{"do": "caption", "text": "Clear every foe to open the gates"},
		{"do": "clear"},
		{"do": "caption", "text": "Each cleared map leaves a chest"},
		{"do": "chest"},
		{"do": "caption", "text": "Walk out through a gate, and the next node is built"},
		{"do": "gate", "side": "e"},
		{"do": "caption", "text": "e-1: a new node stays shut until this map is clear"},
		{"do": "locked", "side": "n"},
		{"do": "caption", "text": "Slimes near c-0, tougher foes each ring outward"},
		{"do": "clear"},
		{"do": "chest"},
		{"do": "caption", "text": "North to ne-1"},
		{"do": "gate", "side": "n"},
		{"do": "caption", "text": "M: the strategic map of every node visited"},
		{"do": "map", "time": 3.5},
		{"do": "caption", "text": "Further out: ring 26, Deep forest. Samurai, fire knights, dark knights"},
		{"do": "warp", "to": Vector2i(0, 26), "side": "s"},
		{"do": "fight", "kills": 4, "time": 45.0},
		{"do": "caption", "text": "Every node is saved as it was left"},
		{"do": "map", "time": 4.5, "zoom": 0.27, "center": Vector2i(0, 11)},
		{"do": "wait", "time": 0.5},
		{"do": "quit"},
	]
	_next()


func _physics_process(delta: float) -> void:
	_total += delta
	_t += delta
	if _attack_down:
		Input.action_release("attack")
		_attack_down = false
	if _total > LIMIT:
		_quit()
		return
	if game.walker == null or _step >= _steps.size():
		return
	var s: Dictionary = _steps[_step]
	if get_tree().paused and s.do != "map":
		return
	match s.do:
		"wait":
			_set_move(Vector2.ZERO)
			if _t >= s.time:
				_next()
		"clear":
			if game.world.cleared(game.world.current) and game.foes.is_empty():
				_set_move(Vector2.ZERO)
				if _t > 0.6:
					_next()
			else:
				_fight(delta)
				_t = 0.0
		"fight":
			var kills: int = _kills_at_start - game.foes.size()
			if kills >= s.kills or _t >= s.time:
				_set_move(Vector2.ZERO)
				_next()
			else:
				_fight(delta)
		"chest":
			if game.chest == null or game.chest.get_meta("opened"):
				_set_move(Vector2.ZERO)
				if _t > 1.2:
					_next()
			else:
				_move_to(game.chest.position + Vector2(0, 9), delta)
				_t = 0.0
		"gate":
			_gate(s.side, delta, true)
		"locked":
			if game.ui._toast.text.begins_with("Defeat") and game.ui._toast.modulate.a > 0.9:
				_set_move(Vector2.ZERO)
				if s.get("seen", 0.0) == 0.0:
					s.seen = _t
				if _t - s.seen > 1.6:
					_next()
			else:
				_gate(s.side, delta, false)
		"map":
			_set_move(Vector2.ZERO)
			if not s.get("open", false):
				s.open = true
				game.ui._show_map(true)
				if s.has("zoom"): # frame the whole way out, not just the walker's node
					var m: Control = game.ui._strategic
					m.zoom = s.zoom
					m.pan = -Vector2(s.center.x, -s.center.y) * m.SPACING
					m.queue_redraw()
			elif _t >= s.time:
				game.ui._show_map(false)
				_next()
		"warp":
			_set_move(Vector2.ZERO)
			if not s.get("started", false):
				s.started = true
				game.world.hero.max_hp = 30
				game.world.hero.hp = 30
				game.world.hero.damage = 14
				game.travel(s.to, s.side)
			elif not game.busy and game.world.current == s.to and _t > 1.0:
				_kills_at_start = game.foes.size()
				game.ui.refresh()
				_next()
		"quit":
			_quit()


func _next() -> void:
	_step += 1
	_t = 0.0
	while _step < _steps.size() and _steps[_step].do == "caption":
		_show_caption(_steps[_step].text)
		_step += 1


func _show_caption(text: String) -> void:
	_caption.text = text
	if _caption_tween:
		_caption_tween.kill()
	_caption_tween = create_tween()
	_caption_tween.tween_property(_caption, "modulate:a", 1.0, 0.3)
	_caption_tween.tween_interval(3.2)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.5)


func _quit() -> void:
	_set_move(Vector2.ZERO)
	GateWorld.erase_save()
	get_tree().quit()


# Walks to the gate on `side` and on out through it; `through`: wait for the
# next map, else stop at the edge (a shut gate).
func _gate(side: String, delta: float, through: bool) -> void:
	if game.busy:
		_set_move(Vector2.ZERO)
		return
	var s: Dictionary = _steps[_step]
	if through and s.has("from") and game.world.current != s.from:
		_set_move(Vector2.ZERO)
		if _t > 1.0:
			_next()
		return
	if not s.has("from"):
		s.from = game.world.current
	_t = 0.0
	var inside: Vector2 = game._entry_point(side)
	var out := Vector2(GateWorld.DIRS[side].x, -GateWorld.DIRS[side].y)
	if s.get("pushing", false) or game.walker.position.distance_to(inside) < 6.0:
		s.pushing = true
		_set_move(out)
	else:
		_move_to(inside, delta)


# Closes on the nearest foe, lines up beside it, faces it, and swings.
func _fight(delta: float) -> void:
	var w: CharacterBody2D = game.walker
	var target: Foe = null
	var best := 1e9
	for f in game.foes:
		if f.alive() and f.position.distance_to(w.position) < best:
			best = f.position.distance_to(w.position)
			target = f
	if target == null:
		_set_move(Vector2.ZERO)
		return
	var d := target.position - w.position
	_swing_clock -= delta
	if absf(d.y) < 7.0 and absf(d.x) < 24.0 + target.radius * 0.5 and absf(d.x) > 6.0:
		_set_move(Vector2.ZERO)
		w.facing = 0 if d.x > 0.0 else 1 # Facing.RIGHT, Facing.LEFT
		if _swing_clock <= 0.0:
			_swing_clock = SWING_EVERY
			Input.action_press("attack")
			_attack_down = true
		return
	var side := -1.0 if d.x > 0.0 else 1.0
	_move_to(target.position + Vector2(side * 16.0, 0), delta)


# Steps toward `pos` along a breadth-first field over the map's walkable
# cells, with a sideways nudge when the walker is stuck on a corner.
func _move_to(pos: Vector2, delta: float) -> void:
	var w: CharacterBody2D = game.walker
	var t: PaintedTerrain = game.terrain
	var goal := Vector2i(pos / 16.0)
	_field_clock -= delta
	if goal != _field_cell or _field_clock <= 0.0:
		_field_cell = goal
		_field_clock = 0.5
		_field = game._distances(goal)
	var dir := pos - w.position
	var cell := Vector2i(w.position / 16.0)
	var width := PaintedTerrain.WIDTH
	if t._inside(cell) and _field[cell.y * width + cell.x] > 1:
		var here := _field[cell.y * width + cell.x]
		var best := cell
		for y in range(-1, 2):
			for x in range(-1, 2):
				var n := cell + Vector2i(x, y)
				if (x == 0 and y == 0) or not t._inside(n):
					continue
				if x != 0 and y != 0 and not (t.walkable(cell + Vector2i(x, 0)) and t.walkable(cell + Vector2i(0, y))):
					continue
				var nd := _field[n.y * width + n.x]
				if nd >= 0 and nd < here:
					here = nd
					best = n
		if best != cell:
			dir = Vector2(best) * 16.0 + Vector2(8, 10) - w.position
	if w.position.distance_to(_last_pos) < 0.3:
		_stuck += delta
	else:
		_stuck = 0.0
	_last_pos = w.position
	if _stuck > 0.5 and _jitter <= 0.0:
		_jitter = 0.35
		_jitter_dir = Vector2(-dir.y, dir.x).normalized() * (1.0 if randf() < 0.5 else -1.0)
	if _jitter > 0.0:
		_jitter -= delta
		dir = _jitter_dir
	if dir.length() < 2.0:
		_set_move(Vector2.ZERO)
		return
	_set_move(dir.normalized())


func _set_move(v: Vector2) -> void:
	_axis("move_right", maxf(v.x, 0.0))
	_axis("move_left", maxf(-v.x, 0.0))
	_axis("move_down", maxf(v.y, 0.0))
	_axis("move_up", maxf(-v.y, 0.0))


func _axis(action: String, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength > 0.05:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)
