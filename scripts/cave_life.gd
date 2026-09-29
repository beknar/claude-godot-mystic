class_name CaveLife
extends Node2D
## Cave ambience, in place of the outdoor sky effects (clouds, seeds, birds,
## grass waves), all in and around the camera's view:
##   drips   - drops fall from the rock faces to the floor at their foot and
##             burst into a two-pixel splash with a wet spot that dries; over
##             a pool they fall from the dark above and ring the water;
##   motes   - dust hangs in the torch and fire light, drifting and turning
##             warm near the flame, and a few pale specks drift in the draft
##             everywhere else;
##   glints  - crystals and ore catch the light: a pixel flares into a small
##             cross and fades, each crystal on its own beat;
##   bats    - now and then one to four bats flit across the view in a
##             jittery weave, wings flicking.
## Drawn on whole world pixels in the sheet's colors.

const DRIP_EVERY := Vector2(0.25, 0.7) # seconds between drips in view
const DRIP_FALL := 90.0 # px/s
const DROP := Color(0.62, 0.8, 0.84)
const WET := Color(0.36, 0.42, 0.46, 0.55)
const MOTE_WARM := Color(1.0, 0.86, 0.55)
const MOTE_PALE := Color(0.86, 0.88, 0.86)
const MOTES_PER_LIGHT := 4
const MAX_PALE := 10
const GLINT := Color(0.96, 1.0, 1.0)
const GLINT_EVERY := Vector2(1.2, 3.5)
const BATS_EVERY := Vector2(8.0, 16.0)
const BAT := Color(0.1, 0.08, 0.12)
const BAT_SPEED := 46.0

var wind: Wind
var water_life: WaterLife
var view_override := Rect2() # set by headless tools; otherwise the camera's view
var bats := true # outdoor scenes may turn the bat flights off
var parts := ["drips", "warm", "pale", "glints", "bats"] # what pixels() draws (headless tools measure one at a time)
var _drip_spots: Array[Dictionary] = [] # {top: Vector2, floor: Vector2, water: bool}
var _lights: Array[Vector2] = []
var _glinters: Array[Dictionary] = [] # {points: Array[Vector2i], next: float}
var _drops: Array[Dictionary] = []
var _splashes: Array[Dictionary] = []
var _motes: Array[Dictionary] = []
var _glints: Array[Dictionary] = []
var _bats: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _drip_acc := 1.0
var _next_bats := 6.0
var _time := 0.0
var stats := {"drips": 0, "glints": 0, "bats": 0} # for tools


func _ready() -> void:
	_rng.randomize()
	z_index = 23 # over the actors (drops fall in front of faces), under fire light


## `drips`: {top, floor, water} world points where drops start and land.
## `lights`: world positions of flames. `glinters`: world pixels of each
## crystal or ore that can flash, one array per prop.
func setup(drips: Array[Dictionary], lights: Array[Vector2], glinters: Array) -> void:
	_drip_spots = drips
	_lights = lights
	_glinters.clear()
	for pts in glinters:
		if not pts.is_empty():
			_glinters.append({"points": pts, "next": _rng.randf_range(0.0, GLINT_EVERY.y)})
	for a in [_drops, _splashes, _motes, _glints, _bats]:
		a.clear()
	_next_bats = _rng.randf_range(4.0, BATS_EVERY.x)


func _process(delta: float) -> void:
	_time += delta
	var view := _view().grow(16.0)
	_update_drips(delta, view)
	_update_motes(delta, view)
	_update_glints(delta, view)
	_update_bats(delta, view)
	queue_redraw()


func _update_drips(delta: float, view: Rect2) -> void:
	var near: Array[Dictionary] = []
	for d in _drip_spots:
		if view.has_point(d.floor):
			near.append(d)
	_drip_acc -= delta
	if _drip_acc <= 0.0:
		_drip_acc = _rng.randf_range(DRIP_EVERY.x, DRIP_EVERY.y) * clampf(12.0 / maxf(near.size(), 1.0), 0.6, 3.0)
		if not near.is_empty():
			var d: Dictionary = near[_rng.randi() % near.size()]
			_drops.append({"pos": d.top, "floor": d.floor, "water": d.water})
	for d in _drops:
		d.pos.y += DRIP_FALL * delta
	var landed := _drops.filter(func(d): return d.pos.y >= d.floor.y)
	_drops = _drops.filter(func(d): return d.pos.y < d.floor.y)
	for d in landed:
		stats.drips += 1
		if d.water and water_life:
			water_life._ring(d.floor, 0.0)
		else:
			_splashes.append({"pos": d.floor, "t": 0.0, "side": _rng.randi_range(0, 1)})
	for s in _splashes:
		s.t += delta
	_splashes = _splashes.filter(func(s): return s.t < 2.2)


func _update_motes(delta: float, view: Rect2) -> void:
	var warm := 0
	for m in _motes:
		if m.warm:
			warm += 1
	# Warm motes in the light of each flame in view.
	for l in _lights:
		if not view.has_point(l) or _rng.randf() > delta * 2.0 or warm >= MOTES_PER_LIGHT * 6:
			continue
		var n := 0
		for m in _motes:
			if m.warm and m.home == l:
				n += 1
		if n < MOTES_PER_LIGHT:
			_motes.append({"pos": l + Vector2(_rng.randf_range(-14, 14), _rng.randf_range(-22, 2)), "home": l, "warm": true,
				"t": 0.0, "life": _rng.randf_range(3.0, 6.0), "phase": _rng.randf() * TAU})
	if _motes.size() - warm < MAX_PALE and _rng.randf() < delta * 1.5:
		_motes.append({"pos": view.position + Vector2(_rng.randf() * view.size.x, _rng.randf() * view.size.y), "home": Vector2.INF,
			"warm": false, "t": 0.0, "life": _rng.randf_range(5.0, 9.0), "phase": _rng.randf() * TAU})
	var carry := wind.carry(5.0) if wind else Vector2.ZERO
	for m in _motes:
		m.t += delta
		var swirl := Vector2(sin(_time * 0.9 + m.phase) * 3.0, cos(_time * 0.7 + m.phase * 1.3) * 2.5 - (1.5 if m.warm else 0.3))
		m.pos += (carry * (0.4 if m.warm else 1.0) + swirl) * delta
	_motes = _motes.filter(func(m): return m.t < m.life)


func _update_glints(delta: float, view: Rect2) -> void:
	for g in _glinters:
		g.next -= delta
		if g.next > 0.0:
			continue
		g.next = _rng.randf_range(GLINT_EVERY.x, GLINT_EVERY.y)
		var p: Vector2i = g.points[_rng.randi() % g.points.size()]
		if view.has_point(Vector2(p)):
			_glints.append({"pos": p, "t": 0.0, "life": _rng.randf_range(0.35, 0.6)})
			stats.glints += 1
	for g in _glints:
		g.t += delta
	_glints = _glints.filter(func(g): return g.t < g.life)


# A few bats weave across the view: a straight heading with a jittery
# sideways wobble and small speed changes, wings flicking fast.
func _update_bats(delta: float, view: Rect2) -> void:
	_next_bats -= delta
	if bats and _next_bats <= 0.0 and _bats.is_empty():
		_next_bats = _rng.randf_range(BATS_EVERY.x, BATS_EVERY.y)
		var heading := Vector2.RIGHT.rotated(_rng.randf() * TAU)
		var start := view.get_center() - heading * (view.size.length() * 0.55) + heading.orthogonal() * _rng.randf_range(-view.size.y * 0.3, view.size.y * 0.3)
		for i in _rng.randi_range(2, 5):
			_bats.append({"pos": start - heading * i * 14.0 + heading.orthogonal() * _rng.randf_range(-10, 10), "heading": heading,
				"phase": _rng.randf() * TAU, "flap": _rng.randf() * TAU, "t": 0.0, "speed": BAT_SPEED * _rng.randf_range(0.85, 1.15)})
			stats.bats += 1
	for b in _bats:
		b.t += delta
		b.flap += delta * 22.0
		var side: Vector2 = b.heading.orthogonal() * (sin(_time * 5.0 + b.phase) * 30.0 + sin(_time * 11.0 + b.phase * 2.0) * 12.0)
		b.pos += (b.heading * b.speed * (0.8 + 0.3 * sin(_time * 3.0 + b.phase)) + side) * delta
	_bats = _bats.filter(func(b): return b.t < 3.0 or view.grow(60.0).has_point(b.pos))


func _view() -> Rect2:
	if view_override.size != Vector2.ZERO:
		return view_override
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


## Every pixel drawn right now, {Vector2i: Color}, for headless measuring.
func pixels() -> Dictionary:
	var out := {}
	if not "drips" in parts:
		return _pixels_rest(out)
	for s in _splashes:
		var p := Vector2i(Vector2(s.pos).floor())
		var wet := Color(WET, WET.a * clampf(1.0 - (s.t - 0.2) / 2.0, 0.0, 1.0))
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
			out[p + o] = wet
		if s.t < 0.22:
			var k: int = 1 + int(s.t / 0.11)
			out[p + Vector2i(-k, -k)] = DROP
			out[p + Vector2i(k, -k)] = DROP
	for d in _drops:
		var p := Vector2i(Vector2(d.pos).floor())
		out[p] = DROP
		out[p + Vector2i(0, -1)] = Color(DROP, 0.5)
	return _pixels_rest(out)


func _pixels_rest(out: Dictionary) -> Dictionary:
	for m in _motes:
		if not ("warm" if m.warm else "pale") in parts:
			continue
		var a := clampf(minf(m.t / 0.8, (m.life - m.t) / 1.0), 0.0, 1.0)
		var c: Color = MOTE_WARM if m.warm else MOTE_PALE
		# Motes turn in the light: bright, then dim, then bright again.
		a *= 0.45 + 0.4 * absf(sin(_time * 1.6 + m.phase))
		out[Vector2i(Vector2(m.pos).floor())] = Color(c, a)
	for g in _glints:
		if not "glints" in parts:
			break
		var k: float = 1.0 - absf(g.t / g.life * 2.0 - 1.0)
		out[g.pos] = Color(GLINT, 0.6 + 0.4 * k)
		if k > 0.4:
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				out[g.pos + o] = Color(GLINT, 0.7 * k)
	for b in _bats:
		if not "bats" in parts:
			break
		var at := Vector2i(Vector2(b.pos).floor())
		out[at] = BAT
		out[at + Vector2i(0, 1)] = BAT
		var up := sin(b.flap) > 0.0
		for s in [-1, 1]:
			out[at + Vector2i(s, 0)] = BAT
			out[at + Vector2i(2 * s, -1 if up else 1)] = BAT
	return out


func _draw() -> void:
	var px := pixels()
	for p in px:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), px[p])
