class_name Footsteps
extends Node2D
## The ground answers the walker. Every few pixels of travel, the cell under
## its feet decides the effect:
##   cobble path or a dirt island - a small puff of dust that spreads and
##     settles, drifting a little with the wind;
##   a tuft or flower            - a few blades of grass flick up and fall;
##   next to water               - a ripple ring at the nearest shore;
## and fallen leaves near its feet are kicked aside. Drawn on whole world
## pixels above the actors, starting a few pixels behind the walker so the
## walker's own sprite never hides them.

const STEP := 9.0 # px of travel between steps
const DUST := [Color(0.6, 0.49, 0.38), Color(0.52, 0.42, 0.33)] # darker than the path it rises from
const BLADES := [Color(0.48, 0.6, 0.4), Color(0.35, 0.52, 0.33)]
const SHORE_EVERY := 0.6 # seconds between shore ripples

var wind: Wind
var walker: Node2D
var terrain: PaintedTerrain
var leaves: AmbientLeaves
var water_life: WaterLife
var _bits: Array[Dictionary] = [] # {pos, vel, t, life, color, gravity}
var _last := Vector2.INF
var _heading := Vector2.DOWN
var _prev_heading_from := Vector2.ZERO
var _travel := 0.0
var _shore_cool := 0.0
var _dirt := {} # cells of dirt islands
var _rng := RandomNumberGenerator.new()
var stats := {"steps": 0, "dust": 0, "grass": 0, "shore": 0} # events, for tools/walker_test.gd


func _ready() -> void:
	_rng.randomize()
	z_index = 21 # above the walker; bits start behind its feet, so they read as a trail


func setup(p_terrain: PaintedTerrain, p_walker: Node2D) -> void:
	terrain = p_terrain
	walker = p_walker
	_bits.clear()
	_last = Vector2.INF
	_dirt.clear()
	for b in terrain.blobs:
		for c in b.cells:
			_dirt[c] = true


func _process(delta: float) -> void:
	_shore_cool -= delta
	if is_instance_valid(walker) and terrain != null:
		var feet := walker.global_position
		if _last != Vector2.INF:
			_travel += feet.distance_to(_last)
			if leaves:
				leaves.kick(feet, feet - _last)
		_last = feet
		if _travel >= STEP:
			_travel = 0.0
			_step(feet, _heading)
		if feet.distance_to(_prev_heading_from) > 0.5:
			_heading = (feet - _prev_heading_from).normalized()
			_prev_heading_from = feet
	for b in _bits:
		b.t += delta
		b.vel.y += b.gravity * delta
		b.pos += b.vel * delta
		if wind and b.gravity == 0.0:
			b.pos += wind.carry(6.0) * delta
	_bits = _bits.filter(func(b): return b.t < b.life)
	queue_redraw()


func _step(feet: Vector2, heading: Vector2) -> void:
	var cell := Vector2i(floori(feet.x / 16.0), floori((feet.y - 1.0) / 16.0))
	# Bits start just behind the walker (and out to its sides when walking
	# up or down), where its sprite does not cover them.
	var behind := feet - heading * 7.0 + Vector2(0, 1)
	stats.steps += 1
	if terrain.path.has(cell) or _dirt.has(cell):
		stats.dust += 1
		for i in _rng.randi_range(4, 5):
			_bits.append({"pos": behind + Vector2(_rng.randf_range(-5, 5), _rng.randf_range(-1, 1)),
				"vel": Vector2(_rng.randf_range(-8, 8), _rng.randf_range(-8, -3)) - heading * 6.0, "t": 0.0,
				"life": _rng.randf_range(0.5, 0.8), "color": DUST[_rng.randi() % DUST.size()], "gravity": 0.0})
	elif terrain.deco.has(cell):
		stats.grass += 1
		for i in 3:
			_bits.append({"pos": behind + Vector2(_rng.randf_range(-4, 4), -1), "vel": Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-26, -16)),
				"t": 0.0, "life": 0.45, "color": BLADES[_rng.randi() % BLADES.size()], "gravity": 90.0})
	if water_life and _shore_cool <= 0.0:
		for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			if terrain.water.has(cell + d):
				water_life._ring(Vector2(cell + d) * 16.0 + Vector2(8, 8) - Vector2(d) * 5.0, 0.0)
				stats.shore += 1
				_shore_cool = SHORE_EVERY
				break


func _draw() -> void:
	for b in _bits:
		var k: float = b.t / b.life
		var c: Color = b.color
		c.a = 1.0 if k < 0.5 else 2.0 * (1.0 - k)
		var p := Vector2(b.pos).floor()
		# Dust puffs are 2x2 while young, then a single pixel as they thin.
		var size := Vector2(2, 2) if b.gravity == 0.0 and k < 0.55 else Vector2.ONE
		draw_rect(Rect2(p, size), c)
