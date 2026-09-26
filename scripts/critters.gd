class_name Critters
extends Node2D
## Small life that moves on its own and notices the walker:
##   butterflies flutter from flower to flower, rest a moment, and scatter
##     when the walker comes close; gusts push them sideways;
##   dragonflies dart about low over ponds in short straight bursts and
##     hover in between, and dart off from the walker;
##   fireflies drift slowly over dark grass and under the forest canopy,
##     pulsing, with a faint glow at the peak of each pulse.
## Each is a few pixels in the pack's palette, drawn on whole world pixels.

const BUTTERFLY_COLORS := [Color(0.95, 0.96, 1.0), Color(0.93, 0.82, 0.42), Color(0.78, 0.72, 0.96), Color(0.93, 0.66, 0.72)]
const BUTTERFLY_BODY := Color(0.22, 0.2, 0.25)
const DRAGONFLY_BODY := Color(0.1, 0.3, 0.36)
const DRAGONFLY_HEAD := Color(0.35, 0.82, 0.78)
const DRAGONFLY_WING := Color(1.0, 1.0, 1.0, 0.9)
const FIREFLY := Color(0.93, 1.0, 0.55)
const SCARE_RADIUS := 26.0 # px from the walker's feet

var wind: Wind
var walker: Node2D
var _butterflies: Array[Dictionary] = []
var _dragonflies: Array[Dictionary] = []
var _fireflies: Array[Dictionary] = []
var _flowers: Array[Vector2] = [] # flower centers in world pixels
var _ponds: Array[Rect2] = [] # open water rects in world pixels
var _rng := RandomNumberGenerator.new()
var _time := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 22 # flying things draw above the y-sorted actors


## `flowers`: world centers of flower cells. `ponds`: world rects over open
## water. `dark`: world centers of dark-grass and canopy-edge cells.
func setup(flowers: Array[Vector2], ponds: Array[Rect2], dark: Array[Vector2]) -> void:
	_flowers = flowers
	_ponds = ponds
	_butterflies.clear()
	_dragonflies.clear()
	_fireflies.clear()
	if not flowers.is_empty():
		for i in clampi(flowers.size() / 10, 3, 8):
			var home: Vector2 = flowers[_rng.randi() % flowers.size()]
			_butterflies.append({"pos": home + Vector2(0, -6), "target": home + Vector2(0, -6), "rest": _rng.randf_range(0.0, 2.0),
				"color": BUTTERFLY_COLORS[_rng.randi() % BUTTERFLY_COLORS.size()], "flap": _rng.randf() * TAU, "flee": 0.0, "vel": Vector2.ZERO})
	for r in ponds:
		for i in (2 if r.get_area() > 4000.0 else 1):
			var p := r.position + Vector2(_rng.randf() * r.size.x, _rng.randf() * r.size.y)
			_dragonflies.append({"pos": p, "target": p, "pond": r, "hover": _rng.randf_range(0.2, 1.2), "flee": 0.0})
	if not dark.is_empty():
		for i in clampi(dark.size() / 25, 0, 14):
			var home: Vector2 = dark[_rng.randi() % dark.size()]
			_fireflies.append({"pos": home + Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-12, 0)), "home": home,
				"phase": _rng.randf() * TAU, "rate": _rng.randf_range(0.7, 1.3), "seed": _rng.randf() * 100.0})
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	var feet := walker.global_position if is_instance_valid(walker) else Vector2(-9999, -9999)
	_update_butterflies(delta, feet)
	_update_dragonflies(delta, feet)
	for f in _fireflies:
		var s: float = f.seed
		var drift := Vector2(sin(_time * 0.4 + s), cos(_time * 0.33 + s * 1.7)) * 6.0
		f.pos = f.pos.lerp(f.home + Vector2(0, -8) + drift, minf(1.0, delta * 0.8))
	queue_redraw()


func _update_butterflies(delta: float, feet: Vector2) -> void:
	for b in _butterflies:
		b.flap += delta * 14.0
		if b.flee > 0.0:
			b.flee -= delta
		elif b.pos.distance_to(feet) < SCARE_RADIUS:
			# Scatter: off away from the walker, then settle on a far flower.
			b.flee = 1.4
			b.rest = 0.0
			b.vel = (b.pos - feet).normalized().rotated(_rng.randf_range(-0.6, 0.6)) * 42.0
			b.target = _far_flower(feet)
		if b.rest > 0.0:
			b.rest -= delta
			if b.rest <= 0.0:
				b.target = _near_flower(b.pos)
			continue
		var to: Vector2 = b.target - b.pos
		if b.flee <= 0.0 and to.length() > 140.0:
			b.target = _near_flower(b.pos) # blown too far: settle for a closer flower
			to = b.target - b.pos
		# Seeking always beats the wind, so a butterfly gets pushed about in
		# a gust but still arrives.
		var want := to.normalized() * clampf(to.length() * 1.5, 8.0, 30.0) if to.length() > 1.0 else Vector2.ZERO
		if b.flee > 0.0:
			want = b.vel
		# Fluttery: a bobbing path plus a push from the wind, stronger in gusts.
		var bob := Vector2(sin(b.flap * 0.23) * 10.0, sin(b.flap * 0.31) * 8.0)
		var gust := wind.carry(8.0) * (0.4 + wind.gust) if wind else Vector2.ZERO
		b.pos += (want + bob + gust) * delta
		if b.flee <= 0.0 and to.length() < 3.0:
			b.rest = _rng.randf_range(1.5, 4.0)


func _update_dragonflies(delta: float, feet: Vector2) -> void:
	for d in _dragonflies:
		if d.flee > 0.0:
			d.flee -= delta
		elif d.pos.distance_to(feet) < SCARE_RADIUS:
			d.flee = 0.8
			d.target = _pond_point(d.pond, feet)
			d.hover = 0.0
		if d.hover > 0.0:
			d.hover -= delta
			if d.hover <= 0.0:
				d.target = _pond_point(d.pond, Vector2(-9999, -9999))
		else:
			# A quick dart that eases in, then hover.
			d.pos = d.pos.lerp(d.target, minf(1.0, delta * 7.0))
			if d.pos.distance_to(d.target) < 0.8:
				d.hover = _rng.randf_range(0.5, 1.6)


# A random flower within 90 px, or else the closest of a few tries.
func _near_flower(from: Vector2) -> Vector2:
	var best: Vector2 = _flowers[0]
	for i in 10:
		var f: Vector2 = _flowers[_rng.randi() % _flowers.size()]
		if f.distance_to(from) < 90.0:
			return f + Vector2(0, -6)
		if f.distance_to(from) < best.distance_to(from):
			best = f
	return best + Vector2(0, -6)


func _far_flower(away_from: Vector2) -> Vector2:
	for i in 8:
		var f: Vector2 = _flowers[_rng.randi() % _flowers.size()]
		if f.distance_to(away_from) > 60.0 and f.distance_to(away_from) < 200.0:
			return f + Vector2(0, -6)
	return _flowers[_rng.randi() % _flowers.size()] + Vector2(0, -6)


# A point over the pond, away from `avoid` when given.
func _pond_point(r: Rect2, avoid: Vector2) -> Vector2:
	var best := r.get_center()
	for i in 6:
		var p := r.position + Vector2(_rng.randf() * r.size.x, _rng.randf() * r.size.y)
		best = p
		if p.distance_to(avoid) > SCARE_RADIUS * 1.5:
			break
	return best


func _draw() -> void:
	for b in _butterflies:
		var p: Vector2 = Vector2(b.pos).floor()
		var open: bool = b.rest > 0.0 or sin(b.flap) > 0.0 # resting butterflies open their wings
		draw_rect(Rect2(p, Vector2.ONE), BUTTERFLY_BODY)
		if open:
			draw_rect(Rect2(p + Vector2(-1, 0), Vector2.ONE), b.color)
			draw_rect(Rect2(p + Vector2(1, 0), Vector2.ONE), b.color)
			draw_rect(Rect2(p + Vector2(-1, -1), Vector2.ONE), b.color)
			draw_rect(Rect2(p + Vector2(1, -1), Vector2.ONE), b.color)
		else:
			draw_rect(Rect2(p + Vector2(0, -1), Vector2.ONE), b.color)
	for d in _dragonflies:
		var p: Vector2 = Vector2(d.pos).floor()
		var dir: Vector2 = (Vector2(d.target) - Vector2(d.pos))
		var horizontal := absf(dir.x) >= absf(dir.y)
		var along := Vector2(1, 0) if horizontal else Vector2(0, 1)
		var across := Vector2(0, 1) if horizontal else Vector2(1, 0)
		var ahead := along if (dir.x if horizontal else dir.y) >= 0.0 else -along
		# A four-pixel body with a bright head at the front, and two-pixel
		# wing strokes on each side that flicker.
		for i in 4:
			draw_rect(Rect2(p + ahead * (1 - i), Vector2.ONE), DRAGONFLY_BODY)
		draw_rect(Rect2(p + ahead * 2, Vector2.ONE), DRAGONFLY_HEAD)
		if fmod(_time * 24.0 + p.x, 2.0) < 1.3:
			for side in [-1, 1]:
				draw_rect(Rect2(p + across * side, Vector2.ONE), DRAGONFLY_WING)
				draw_rect(Rect2(p + across * side * 2 - ahead, Vector2.ONE), DRAGONFLY_WING)
	for f in _fireflies:
		var pulse: float = 0.5 + 0.5 * sin(_time * 2.2 * f.rate + f.phase)
		pulse = pulse * pulse
		if pulse < 0.08:
			continue
		var p: Vector2 = Vector2(f.pos).floor()
		draw_rect(Rect2(p, Vector2.ONE), Color(FIREFLY, pulse))
		if pulse > 0.6: # a faint cross of glow at the peak
			var g := Color(FIREFLY, (pulse - 0.6) * 0.8)
			for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				draw_rect(Rect2(p + o, Vector2.ONE), g)
