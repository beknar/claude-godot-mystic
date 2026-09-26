extends CharacterBody2D
## Eight-direction walker with a facing-based swing, on the Mystic Woods
## character grid (6 columns x 10 rows: idle, walk, attack, death).

const SPEED := 80.0
const COLUMNS := 6
const ROWS := 10

const IDLE_ROW := 0
const WALK_ROW := 3
const ATTACK_ROW := 6
const ATTACK_FRAMES := 4 # columns 4 and 5 of the attack rows are blank
const HIT_FROM := 2
const HIT_TO := 3

const IDLE_FPS := 6.0
const WALK_FPS := 10.0
const ATTACK_FPS := 12.0

enum Facing { DOWN, SIDE, UP }

# Hitbox center per facing, relative to the feet. Side is for facing right.
const HIT_OFFSET := {
	Facing.DOWN: Vector2(0, 2),
	Facing.SIDE: Vector2(14, -9),
	Facing.UP: Vector2(0, -22),
}

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"attack": [KEY_SPACE],
}

@export var sheet: Texture2D
@export var frame_size := 48
@export var feet_row := 42

@onready var sprite: Sprite2D = $Sprite
@onready var hit_shape: CollisionShape2D = $Hitbox/Shape

var facing := Facing.DOWN
var facing_left := false
var attacking := false
var _row := IDLE_ROW
var _clock := 0.0


func _ready() -> void:
	_ensure_bindings()
	if sheet:
		sprite.texture = sheet
	sprite.hframes = COLUMNS
	sprite.vframes = ROWS
	# Puts the feet row on the body origin so y-sort and the body share it.
	sprite.offset = Vector2(0, frame_size / 2.0 - feet_row)
	hit_shape.disabled = true


func _physics_process(delta: float) -> void:
	if attacking:
		velocity = Vector2.ZERO
	else:
		var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = dir * SPEED
		if absf(dir.x) > 0.01:
			facing = Facing.SIDE
			facing_left = dir.x < 0.0
		elif dir.y < -0.01:
			facing = Facing.UP
		elif dir.y > 0.01:
			facing = Facing.DOWN
		if Input.is_action_just_pressed("attack"):
			_start_attack()
	move_and_slide()
	_animate(delta)


func _start_attack() -> void:
	attacking = true
	_clock = 0.0
	var offset: Vector2 = HIT_OFFSET[facing]
	if facing == Facing.SIDE and facing_left:
		offset.x = -offset.x
	hit_shape.position = offset


func _animate(delta: float) -> void:
	_clock += delta
	var row := IDLE_ROW
	var frames := COLUMNS
	var fps := IDLE_FPS
	if attacking:
		row = ATTACK_ROW + facing
		frames = ATTACK_FRAMES
		fps = ATTACK_FPS
		var frame := int(_clock * fps)
		if frame >= ATTACK_FRAMES:
			attacking = false
			hit_shape.disabled = true
			_animate(0.0)
			return
		hit_shape.disabled = frame < HIT_FROM or frame > HIT_TO
	elif velocity != Vector2.ZERO:
		row = WALK_ROW + facing
		fps = WALK_FPS
	if row != _row:
		_row = row
		_clock = 0.0
	sprite.flip_h = facing_left and row % 3 == Facing.SIDE
	sprite.frame = row * COLUMNS + int(_clock * fps) % frames


func _ensure_bindings() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
