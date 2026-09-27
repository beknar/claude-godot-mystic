class_name AmbientLeaves
extends Node2D
## Leaves and petals falling from tree crowns. Each leaf has a ground point
## and a height above it: it spawns in the crown, falls to the ground near
## the trunk, drifts with the wind while it falls, flutters side to side,
## tumbles between one- and two-pixel shapes, lies on the ground for a few
## seconds (skittering along in gusts), then disappears. Colors come from
## the tree's own sprite. Everything is drawn on whole world pixels.

const MAX_LEAVES := 160
const RATE := 0.22 # leaves per second per tree in still air
const GUST_RATE := 1.6 # extra rate multiplier at a full gust
const FALL_SPEED := Vector2(7.0, 12.0) # px/s
const DRIFT := 16.0 # wind carry while falling, px/s at full strength
const SKITTER := 10.0 # wind carry on the ground during gusts
const REST := Vector2(1.5, 3.5) # seconds on the ground

# Tumble shapes: pixel offsets from the leaf position. The first pixel is
# the leaf's light color, the rest its dark edge, so a leaf reads against
# grass of any tone.
const SHAPES := [[Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(0, 0), Vector2i(0, 1)], [Vector2i(0, 0), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], [Vector2i(1, 0), Vector2i(0, 1)]]

var wind: Wind
var _sources: Array[Dictionary] = [] # {crown: Rect2, base_y: float, colors: Array[Color]}
var _leaves: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _spawn_acc := 0.0
var kicked := 0 # leaves the walker has kicked, for tools/walker_test.gd


func _ready() -> void:
	_rng.randomize()
	z_index = 20 # above the y-sorted actors


## `sources`: one per tree, {crown: Rect2 in world pixels, base_y: ground
## line under the trunk, light: Array[Color], dark: Color}.
func set_sources(sources: Array[Dictionary]) -> void:
	_sources = sources
	_leaves.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if wind == null:
		return
	var s := wind.strength()
	_spawn_acc += delta * RATE * _sources.size() * (0.4 + wind.gust * GUST_RATE + s * 0.4)
	while _spawn_acc >= 1.0:
		_spawn_acc -= 1.0
		_spawn()
	var carry := wind.carry(DRIFT)
	for leaf in _leaves:
		leaf.t += delta
		if leaf.h > 0.0:
			leaf.h = maxf(0.0, leaf.h - leaf.fall * delta * (0.75 + 0.25 * cos(leaf.t * leaf.flutter_rate)))
			leaf.ground += carry * delta * leaf.lightness
			leaf.flip -= delta
			if leaf.flip <= 0.0:
				leaf.shape = _rng.randi() % SHAPES.size()
				leaf.flip = _rng.randf_range(0.18, 0.4)
			if leaf.h <= 0.0:
				leaf.rest = _rng.randf_range(REST.x, REST.y)
				leaf.shape = 0 # lies flat
		else:
			leaf.rest -= delta
			if wind.gust > 0.3:
				leaf.ground += wind.carry(SKITTER) * delta * leaf.lightness
	_leaves = _leaves.filter(func(l): return l.h > 0.0 or l.rest > 0.0)
	queue_redraw()


## Fallen leaves within a few pixels of `at` get pushed along `motion`
## (the walker's step), sliding a little way and turning over.
func kick(at: Vector2, motion: Vector2) -> void:
	if motion.length() < 0.1:
		return
	for leaf in _leaves:
		if leaf.h > 0.0:
			continue
		var off: Vector2 = leaf.ground - at
		if off.length() < 7.0:
			var push := motion.normalized() * 1.4 + off.normalized() * 1.0
			leaf.ground += push
			leaf.shape = _rng.randi() % SHAPES.size()
			leaf.rest = maxf(leaf.rest, 0.6)
			kicked += 1


func _spawn() -> void:
	if _sources.is_empty() or _leaves.size() >= MAX_LEAVES:
		return
	var src: Dictionary = _sources[_rng.randi() % _sources.size()]
	var crown: Rect2 = src.crown
	var start := crown.position + Vector2(_rng.randf() * crown.size.x, _rng.randf() * crown.size.y)
	var ground := Vector2(start.x, src.base_y + _rng.randf_range(-3.0, 10.0))
	_leaves.append({
		"ground": ground,
		"h": ground.y - start.y,
		"fall": _rng.randf_range(FALL_SPEED.x, FALL_SPEED.y),
		"t": _rng.randf() * 10.0,
		"flutter_rate": _rng.randf_range(3.0, 5.0),
		"flutter": _rng.randf_range(1.5, 3.5),
		"lightness": _rng.randf_range(0.6, 1.2),
		"color": src.light[_rng.randi() % src.light.size()],
		"edge": src.dark,
		"shape": _rng.randi() % SHAPES.size(),
		"flip": _rng.randf_range(0.18, 0.4),
		"rest": 0.0,
	})


func _draw() -> void:
	for leaf in _leaves:
		var sway: float = sin(leaf.t * leaf.flutter_rate) * leaf.flutter if leaf.h > 0.0 else 0.0
		var p := Vector2(leaf.ground.x + sway, leaf.ground.y - leaf.h).floor()
		var shape: Array = SHAPES[leaf.shape]
		for i in shape.size():
			draw_rect(Rect2(p + Vector2(shape[i]), Vector2.ONE), leaf.color if i == 0 else leaf.edge)
