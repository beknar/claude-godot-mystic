class_name WaterLife
extends Node2D
## Life on ponds and lakes: ripple rings that spread on open water now and
## then, a rare fish jump (a few droplets arcing up and falling back, then a
## ring), and reeds and water grass that nod with the wind. Rings and drops
## are drawn as single pixels on whole world pixels in pale water colors;
## plants nod by shifting the top part of their sprite a pixel downwind.

const RIPPLE_RATE := 0.45 # rings per second per 40 open water cells
const RING_LIFE := Vector2(1.8, 2.6)
const RING_SPEED := 5.0 # px/s
const JUMP_EVERY := Vector2(8.0, 18.0) # seconds between fish jumps per pond
# The pond surface is pale with white glints, so rings use the deep-water
# teal (with a pale highlight just inside while young) to read against it.
const RING_COLOR := Color(0.32, 0.61, 0.68)
const RING_HIGHLIGHT := Color(0.93, 0.97, 1.0)
const DROP_COLOR := Color(0.23, 0.55, 0.6)

var wind: Wind
var _cells: Array[Vector2i] = [] # open water cells (not shore)
var _rings: Array[Dictionary] = []
var _drops: Array[Dictionary] = []
var _plants: Array[Dictionary] = [] # {top: Sprite2D, phase}
var _rng := RandomNumberGenerator.new()
var _ripple_acc := 0.0
var _next_jump := 5.0
var _time := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 0 # under the y-sorted actors (placed before them)


## `open_cells`: water cells whose eight neighbors are water. `plants`: the
## top sprites of water plants, to nod.
func setup(open_cells: Array[Vector2i], plants: Array[Sprite2D]) -> void:
	_cells = open_cells
	_rings.clear()
	_drops.clear()
	_plants.clear()
	for p in plants:
		_plants.append({"top": p, "phase": _rng.randf() * TAU, "x": p.position.x})
	_next_jump = _rng.randf_range(3.0, JUMP_EVERY.y)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if not _cells.is_empty():
		_ripple_acc += delta * RIPPLE_RATE * maxf(1.0, _cells.size() / 40.0)
		while _ripple_acc >= 1.0:
			_ripple_acc -= 1.0
			var c: Vector2i = _cells[_rng.randi() % _cells.size()]
			_ring(Vector2(c * 16) + Vector2(_rng.randf_range(2, 14), _rng.randf_range(2, 14)), 0.0)
		_next_jump -= delta
		if _next_jump <= 0.0:
			_next_jump = _rng.randf_range(JUMP_EVERY.x, JUMP_EVERY.y)
			_jump()
	for r in _rings:
		r.t += delta
	_rings = _rings.filter(func(r): return r.t < r.life)
	for d in _drops:
		d.t += delta
		d.vel.y += 60.0 * delta
		d.pos += d.vel * delta
		if d.t > 0.2 and d.pos.y >= d.floor_y:
			d.done = true
			if d.ring:
				_ring(Vector2(d.pos.x, d.floor_y), 0.0)
	_drops = _drops.filter(func(d): return not d.done)
	_nod()
	queue_redraw()


func _ring(at: Vector2, start_radius: float) -> void:
	_rings.append({"pos": at.floor(), "t": 0.0, "life": _rng.randf_range(RING_LIFE.x, RING_LIFE.y), "r0": start_radius})


# A fish jump: droplets spray up from one spot and fall back; the biggest
# makes a ring where it lands, and the spot itself rings at once.
func _jump() -> void:
	var c: Vector2i = _cells[_rng.randi() % _cells.size()]
	var at := Vector2(c * 16) + Vector2(8, 8)
	_ring(at, 1.0)
	for i in _rng.randi_range(4, 6):
		_drops.append({"pos": at, "vel": Vector2(_rng.randf_range(-9, 9), _rng.randf_range(-30, -18)),
			"t": 0.0, "floor_y": at.y + _rng.randf_range(-1, 2), "done": false, "ring": i == 0})


# Water plants lean their top part one pixel downwind while the wind is
# strong enough, each at its own moment, so a gust visibly passes through.
func _nod() -> void:
	if wind == null:
		return
	var dx := signf(wind.direction().x) if absf(wind.direction().x) > 0.2 else 0.0
	for p in _plants:
		var push: float = wind.strength() + 0.35 * sin(_time * 1.3 + p.phase)
		p.top.position.x = p.x + (dx if push > 0.85 else 0.0)


func _draw() -> void:
	for r in _rings:
		var k: float = r.t / r.life
		var radius: float = r.r0 + RING_SPEED * r.t
		var a := 1.0 if k < 0.55 else 1.0 - (k - 0.55) / 0.45
		_draw_ring(r.pos, radius, Color(RING_COLOR, a))
		if k < 0.5 and radius > 2.0:
			_draw_ring(r.pos, radius - 1.0, Color(RING_HIGHLIGHT, 0.7 * (1.0 - k * 2.0)))
	for d in _drops:
		draw_rect(Rect2(Vector2(d.pos).floor(), Vector2.ONE), DROP_COLOR)


# A flattened pixel circle (water seen from above at an angle): one pixel
# per step around it, no duplicates, no anti-aliasing.
func _draw_ring(center: Vector2, radius: float, color: Color) -> void:
	if radius < 1.0:
		draw_rect(Rect2(center, Vector2.ONE), color)
		return
	var seen := {}
	var steps := int(radius * 7.0) + 8
	for i in steps:
		var ang := TAU * i / steps
		var p := (center + Vector2(cos(ang) * radius, sin(ang) * radius * 0.55)).floor()
		if seen.has(p):
			continue
		seen[p] = true
		draw_rect(Rect2(p, Vector2.ONE), color)
