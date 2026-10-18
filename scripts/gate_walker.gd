extends "res://scripts/forest_walker.gd"
## node-gates: the Painted Lands walker with a sword swing and hit points.
## The sheet has no attack row, so the swing is a drawn slash (Slash) in
## front of the walker while it holds its idle frame and leans in. A hit
## knocks it back and leaves it blinking (invulnerable) for a moment.

signal swung(at: Vector2, facing: Vector2)
signal hurt(amount: int)

const SWING_TIME := 0.26
const SWING_COOLDOWN := 0.36
const HIT_DELAY := 0.06
const INVULNERABLE := 0.9
const KNOCKBACK := 140.0
const ATTACK_KEYS := [KEY_SPACE, KEY_J]

var frozen := false # during a gate change, a fade, or a menu
var _swing := 0.0
var _swing_cd := 0.0
var _swing_dir := Vector2.DOWN
var _swing_landed := false
var _invulnerable := 0.0
var _knock := Vector2.ZERO
var _slash: Slash


func _ready() -> void:
	super._ready()
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		for k in ATTACK_KEYS:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event("attack", e)
	_slash = Slash.new()
	_slash.z_index = 5
	add_child(_slash)


func facing_vector() -> Vector2:
	match facing:
		Facing.RIGHT:
			return Vector2.RIGHT
		Facing.LEFT:
			return Vector2.LEFT
		Facing.UP:
			return Vector2.UP
	return Vector2.DOWN


func invulnerable() -> bool:
	return _invulnerable > 0.0


## Damage from a foe at `from`; ignored while blinking.
func take_hit(amount: int, from: Vector2) -> void:
	if _invulnerable > 0.0 or frozen:
		return
	_invulnerable = INVULNERABLE
	_knock = (position - from).normalized() * KNOCKBACK
	if _knock == Vector2.ZERO:
		_knock = -facing_vector() * KNOCKBACK
	hurt.emit(amount)


func _physics_process(delta: float) -> void:
	_swing_cd = maxf(0.0, _swing_cd - delta)
	if _invulnerable > 0.0:
		_invulnerable -= delta
		sprite.visible = int(_invulnerable * 14.0) % 2 == 0 or _invulnerable <= 0.0
	if frozen:
		velocity = Vector2.ZERO
		sprite.frame = facing * COLUMNS + IDLE_FRAME
		return
	if _knock.length() > 1.0:
		velocity = _knock
		_knock = _knock.move_toward(Vector2.ZERO, KNOCKBACK * 6.0 * delta)
		move_and_slide()
		return
	if _swing > 0.0:
		_swing -= delta
		if not _swing_landed and _swing <= SWING_TIME - HIT_DELAY:
			_swing_landed = true
			swung.emit(position + Vector2(0, -6) + _swing_dir * 10.0, _swing_dir)
		var lean := 1.0 - absf(_swing / SWING_TIME - 0.5) * 2.0
		sprite.position = _swing_dir * 2.0 * lean
		velocity = Vector2.ZERO
		move_and_slide()
		if _swing <= 0.0:
			sprite.position = Vector2.ZERO
		return
	if Input.is_action_just_pressed("attack") and _swing_cd <= 0.0:
		_swing = SWING_TIME
		_swing_cd = SWING_COOLDOWN
		_swing_dir = facing_vector()
		_swing_landed = false
		sprite.frame = facing * COLUMNS + IDLE_FRAME
		_slash.play(_swing_dir)
		return
	super._physics_process(delta)


## The sword's sweep: a pale crescent that arcs across the facing side and
## fades, drawn on whole pixels.
class Slash extends Node2D:
	const LIFE := 0.2
	var _t := 0.0
	var _dir := Vector2.DOWN

	func play(dir: Vector2) -> void:
		_dir = dir
		_t = LIFE
		queue_redraw()

	func _process(delta: float) -> void:
		if _t > 0.0:
			_t -= delta
			queue_redraw()

	func _draw() -> void:
		if _t <= 0.0:
			return
		var k := 1.0 - _t / LIFE
		var center := Vector2(0, -8) + _dir * 4.0
		var base := _dir.angle()
		var sweep := lerpf(-1.3, 1.3, minf(1.0, k * 1.6))
		var alpha := 1.0 - k * k
		var steps := 16
		for i in steps + 1:
			var a := base - 1.3 + (sweep + 1.3) * i / float(steps)
			# Thickest in the middle of the sweep, tapering at both tips.
			var thick := 1.0 + 3.0 * sin(PI * i / float(steps))
			for j in int(thick) + 1:
				var r := 13.0 - j
				var p: Vector2 = (center + Vector2.from_angle(a) * r).round()
				var c := Color(1, 1, 0.92, alpha * (0.6 if j == 0 else 0.95))
				draw_rect(Rect2(p, Vector2.ONE), c)
