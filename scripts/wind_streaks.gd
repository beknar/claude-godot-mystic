class_name WindStreaks
extends Node2D
## Thin wisps that skim across the ground along the wind, a few at a time,
## more during gusts. Some curl into a small eddy partway through. Each is a
## trail of single pixels behind a moving head, brightest at the head and
## fading toward the tail, drawn on whole world pixels. They spawn only in
## and around the camera's view.

const MAX_STREAKS := 8
const RATE := 0.25 # streaks per second in still air
const GUST_RATE := 3.0 # extra multiplier at a full gust
const SPEED := 55.0 # px/s at full strength
const TRAIL := 16 # pixels in the trail
const LIFE := Vector2(1.3, 2.3)
const EDDY_CHANCE := 0.35
const COLOR := Color(0.84, 0.88, 0.76)

var wind: Wind
var bounds := Rect2() # map rect in world pixels
var _streaks: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _spawn_acc := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 0 # placed before the y-sorted actors, so it draws under them


func _process(delta: float) -> void:
	if wind == null:
		return
	_spawn_acc += delta * RATE * (0.3 + wind.gust * GUST_RATE + wind.base_strength * 0.5)
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		_spawn()
	for s in _streaks:
		s.t += delta
		var heading: float = wind.angle + s.bend
		var life_frac: float = s.t / s.life
		if s.eddy and life_frac > 0.35 and life_frac < 0.8:
			s.curl += delta * 7.0 * s.spin # one quick loop
		heading += s.curl
		var speed: float = SPEED * wind.strength() * s.pace
		s.head += Vector2.from_angle(heading) * speed * delta
		var px: Vector2 = s.head.floor()
		if s.trail.is_empty() or s.trail[0] != px:
			s.trail.push_front(px)
			if s.trail.size() > TRAIL:
				s.trail.pop_back()
	_streaks = _streaks.filter(func(s): return s.t < s.life)
	queue_redraw()


func _spawn() -> void:
	if _streaks.size() >= MAX_STREAKS:
		return
	var view := _view_rect().grow(32.0).intersection(bounds)
	if view.size.x <= 0.0:
		return
	var start := view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y)
	_streaks.append({
		"head": start,
		"trail": [],
		"t": 0.0,
		"life": _rng.randf_range(LIFE.x, LIFE.y),
		"bend": _rng.randf_range(-0.25, 0.25),
		"pace": _rng.randf_range(0.8, 1.2),
		"eddy": _rng.randf() < EDDY_CHANCE,
		"spin": 1.0 if _rng.randf() < 0.5 else -1.0,
		"curl": 0.0,
	})


func _view_rect() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


func _draw() -> void:
	for s in _streaks:
		var n: int = s.trail.size()
		# Fade in at birth and out at death, and along the trail.
		var life_alpha: float = minf(1.0, minf(s.t / 0.25, (s.life - s.t) / 0.4))
		for i in n:
			var along := 1.0 - float(i) / TRAIL
			var a := 0.5 * life_alpha * (0.35 + 0.65 * along)
			if a <= 0.02:
				continue
			draw_rect(Rect2(s.trail[i], Vector2.ONE), Color(COLOR, a))
