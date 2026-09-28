class_name Drifters
extends Node2D
## Things the wind carries through every view, wherever it is on the map:
##   dandelion seeds - a pale core with a paler tuft, riding the wind, bobbing
##                     and slowly lifting, more of them in gusts;
##   pollen          - single warm specks that hang over flowers, drifting;
##   a bird flock    - now and then four to seven birds cross the view in a
##                     loose V, flapping, with their shadows gliding over the
##                     ground below them.
## All of it spawns in and around the camera's view (like the wind streaks),
## is drawn on whole world pixels, and uses the sheet's pale and dark tones.

const SEED_RATE := 0.9 # seeds per second at base wind
const SEED_GUST := 2.2 # extra multiplier at a full gust
const MAX_SEEDS := 18
const SEED_LIFE := Vector2(6.0, 10.0)
const SEED_CARRY := 24.0 # px/s at full wind strength
const SEED_CORE := Color(0.96, 0.95, 0.88)
const SEED_TUFT := Color(0.88, 0.9, 0.84, 0.7)
const POLLEN_RATE := 0.6 # per second, when flowers are in view
const MAX_POLLEN := 10
const POLLEN := Color(0.97, 0.86, 0.45)
const FLOCK_EVERY := Vector2(22.0, 40.0) # seconds between flocks
const BIRD_SPEED := 52.0
const BIRD := Color(0.17, 0.16, 0.2)
const BIRD_SHADOW := Color(0.05, 0.14, 0.12, 0.28)
const SHADOW_DROP := 26.0 # px from a bird to its shadow on the ground

var wind: Wind
var bounds := Rect2()
var view_override := Rect2() # set by headless tools; otherwise the camera's view
var _flowers: Array[Vector2] = []
var _seeds: Array[Dictionary] = []
var _pollen: Array[Dictionary] = []
var _birds: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _seed_acc := 0.0
var _pollen_acc := 0.0
var _next_flock := 8.0
var _time := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 24 # over the actors and the leaves; under fire light and cloud shadows


func setup(map_rect: Rect2, flowers: Array[Vector2]) -> void:
	bounds = map_rect
	_flowers = flowers
	_seeds.clear()
	_pollen.clear()
	_birds.clear()
	_next_flock = _rng.randf_range(4.0, FLOCK_EVERY.x)


func _process(delta: float) -> void:
	if wind == null:
		return
	_time += delta
	var view := _view().grow(24.0)
	_seed_acc += delta * SEED_RATE * (0.4 + wind.base_strength * 0.8 + wind.gust * SEED_GUST)
	while _seed_acc >= 1.0:
		_seed_acc -= 1.0
		if _seeds.size() < MAX_SEEDS:
			_seeds.append({"pos": _upwind_point(view), "t": 0.0, "life": _rng.randf_range(SEED_LIFE.x, SEED_LIFE.y),
				"phase": _rng.randf() * TAU, "lift": _rng.randf_range(1.0, 4.0), "lightness": _rng.randf_range(0.7, 1.2)})
	var carry := wind.carry(SEED_CARRY)
	for s in _seeds:
		s.t += delta
		var bob := Vector2(cos(_time * 1.3 + s.phase) * 3.0, sin(_time * 2.1 + s.phase) * 4.0 - s.lift)
		s.pos += (carry * s.lightness + bob) * delta
	_seeds = _seeds.filter(func(s): return s.t < s.life and view.grow(40.0).has_point(s.pos))
	_update_pollen(delta, view)
	_update_birds(delta, view)
	queue_redraw()


func _update_pollen(delta: float, view: Rect2) -> void:
	var near: Array[Vector2] = []
	for f in _flowers:
		if view.has_point(f):
			near.append(f)
	if not near.is_empty():
		_pollen_acc += delta * POLLEN_RATE * minf(3.0, near.size() / 4.0)
		while _pollen_acc >= 1.0:
			_pollen_acc -= 1.0
			if _pollen.size() < MAX_POLLEN:
				var at: Vector2 = near[_rng.randi() % near.size()]
				_pollen.append({"pos": at + Vector2(_rng.randf_range(-6, 6), _rng.randf_range(-12, -4)), "t": 0.0,
					"life": _rng.randf_range(3.0, 5.0), "phase": _rng.randf() * TAU})
	var carry := wind.carry(6.0)
	for p in _pollen:
		p.t += delta
		p.pos += (carry + Vector2(sin(_time * 1.7 + p.phase) * 2.0, cos(_time * 1.1 + p.phase) * 1.5 - 1.0)) * delta
	_pollen = _pollen.filter(func(p): return p.t < p.life)


# A flock enters on one side of the view and flies straight across it,
# roughly with the wind, in a loose V behind a leader.
func _update_birds(delta: float, view: Rect2) -> void:
	_next_flock -= delta
	if _next_flock <= 0.0 and _birds.is_empty():
		_next_flock = _rng.randf_range(FLOCK_EVERY.x, FLOCK_EVERY.y)
		var heading := wind.direction().rotated(_rng.randf_range(-0.6, 0.6))
		var start := view.get_center() - heading * (view.size.length() * 0.6) + heading.orthogonal() * _rng.randf_range(-view.size.y * 0.3, view.size.y * 0.3)
		var n := _rng.randi_range(4, 7)
		for i in n:
			var rank := (i + 1) / 2
			var side := -1.0 if i % 2 == 1 else 1.0
			var offset := -heading * rank * 7.0 + heading.orthogonal() * side * rank * 6.0
			_birds.append({"pos": start + offset + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)),
				"vel": heading * BIRD_SPEED * _rng.randf_range(0.95, 1.05), "flap": _rng.randf() * TAU, "t": 0.0})
	for b in _birds:
		b.t += delta
		b.pos += b.vel * delta
		b.flap += delta * 10.0
	_birds = _birds.filter(func(b): return b.t < 3.0 or view.grow(60.0).has_point(b.pos))


func _upwind_point(view: Rect2) -> Vector2:
	# Mostly from inside the view (seeds let go of plants there), some from
	# the upwind edge.
	if _rng.randf() < 0.6:
		return view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y)
	var d := wind.direction()
	var p := view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y)
	if absf(d.x) > absf(d.y):
		p.x = view.position.x if d.x > 0.0 else view.end.x
	else:
		p.y = view.position.y if d.y > 0.0 else view.end.y
	return p


func _view() -> Rect2:
	if view_override.size != Vector2.ZERO:
		return view_override
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


## Every pixel drawn right now, {Vector2i: Color}, for headless measuring.
func pixels() -> Dictionary:
	var out := {}
	for s in _seeds:
		var a := _fade(s)
		var p := Vector2i(Vector2(s.pos).floor())
		out[p] = Color(SEED_CORE, a)
		var tuft := p + (Vector2i(0, -1) if fmod(_time * 3.0 + s.phase, 2.0) < 1.0 else Vector2i(1, -1))
		out[tuft] = Color(SEED_TUFT, SEED_TUFT.a * a)
	for p in _pollen:
		out[Vector2i(Vector2(p.pos).floor())] = Color(POLLEN, 0.85 * _fade(p))
	for b in _birds:
		var at := Vector2i(Vector2(b.pos).floor())
		var up := sin(b.flap) > 0.0
		var shadow := at + Vector2i(0, int(SHADOW_DROP))
		for o in _bird_shape(up):
			out[shadow + o] = BIRD_SHADOW
		for o in _bird_shape(up):
			out[at + o] = BIRD
	return out


func _fade(d: Dictionary) -> float:
	return clampf(minf(d.t / 0.6, (d.life - d.t) / 0.8), 0.0, 1.0)


# A three-pixel bird seen from below: wings up (a V) or down (a flat line).
func _bird_shape(up: bool) -> Array[Vector2i]:
	if up:
		return [Vector2i(-1, -1), Vector2i(0, 0), Vector2i(1, -1)]
	return [Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)]


func _draw() -> void:
	var px := pixels()
	for p in px:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), px[p])
