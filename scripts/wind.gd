class_name Wind
extends Node
## The scene's wind. Every ambient effect reads it, so leaves, streaks, and
## cloud shadows all move the same way and change together. The heading
## eases to a new direction every 20-40 s; gusts rise and fall on top.

const TURN_EVERY := Vector2(20.0, 40.0) # seconds between heading changes
const TURN_TIME := 4.0 # seconds to ease into a new heading
const GUST_EVERY := Vector2(6.0, 16.0)
const GUST_RISE := 1.4
const GUST_FALL := 2.6

var angle := 0.0 # radians, 0 = blowing east
var base_strength := 0.5 # 0..1 without gusts
var gust := 0.0 # 0..1 on top of the base

var _rng := RandomNumberGenerator.new()
var _from_angle := 0.0
var _to_angle := 0.0
var _turn_t := 1.0
var _next_turn := 0.0
var _gust_t := -1.0
var _gust_peak := 0.0
var _next_gust := 0.0


func _ready() -> void:
	_rng.randomize()
	angle = _rng.randf_range(-PI, PI)
	_from_angle = angle
	_to_angle = angle
	base_strength = _rng.randf_range(0.35, 0.75)
	_next_turn = _rng.randf_range(TURN_EVERY.x, TURN_EVERY.y)
	_next_gust = _rng.randf_range(GUST_EVERY.x, GUST_EVERY.y)


func _process(delta: float) -> void:
	_next_turn -= delta
	if _next_turn <= 0.0:
		# A noticeable but not total change of heading.
		_from_angle = angle
		_to_angle = angle + _rng.randf_range(0.7, 1.9) * (1.0 if _rng.randf() < 0.5 else -1.0)
		_turn_t = 0.0
		base_strength = clampf(base_strength + _rng.randf_range(-0.2, 0.2), 0.3, 0.8)
		_next_turn = _rng.randf_range(TURN_EVERY.x, TURN_EVERY.y)
	if _turn_t < 1.0:
		_turn_t = minf(1.0, _turn_t + delta / TURN_TIME)
		angle = lerp_angle(_from_angle, _to_angle, smoothstep(0.0, 1.0, _turn_t))

	_next_gust -= delta
	if _next_gust <= 0.0 and _gust_t < 0.0:
		_gust_t = 0.0
		_gust_peak = _rng.randf_range(0.35, 0.7)
		_next_gust = _rng.randf_range(GUST_EVERY.x, GUST_EVERY.y)
	if _gust_t >= 0.0:
		_gust_t += delta
		if _gust_t < GUST_RISE:
			gust = _gust_peak * smoothstep(0.0, 1.0, _gust_t / GUST_RISE)
		elif _gust_t < GUST_RISE + GUST_FALL:
			gust = _gust_peak * (1.0 - smoothstep(0.0, 1.0, (_gust_t - GUST_RISE) / GUST_FALL))
		else:
			gust = 0.0
			_gust_t = -1.0


## Wind strength, 0 (still) to about 1.5 (strong gust).
func strength() -> float:
	return base_strength + gust


## Unit vector of the heading.
func direction() -> Vector2:
	return Vector2.from_angle(angle)


## Velocity in world pixels per second for something the wind carries at
## `speed` pixels per second at full strength.
func carry(speed: float) -> Vector2:
	return direction() * speed * strength()
