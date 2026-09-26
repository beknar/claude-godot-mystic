extends CharacterBody2D
## Eight-direction walker for the Painted Lands character sheet: 6 columns x
## 4 rows of 16x32 (two tiles tall). Rows face right, left, down, up; row 1
## is row 0 mirrored. Columns 3-5 repeat 0-2 with a ground shadow, so idle
## and walk use those. There is no attack row.

const SPEED := 80.0
const COLUMNS := 6
const ROWS := 4
const IDLE_FRAME := 3
const WALK_FRAMES := [3, 4, 3, 5]
const WALK_FPS := 8.0

enum Facing { RIGHT, LEFT, DOWN, UP }

const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
}

@export var feet_row := 31

@onready var sprite: Sprite2D = $Sprite

var facing := Facing.DOWN
var _clock := 0.0


func _ready() -> void:
	_ensure_bindings()
	sprite.hframes = COLUMNS
	sprite.vframes = ROWS
	sprite.offset = Vector2(0, sprite.texture.get_height() / ROWS / 2.0 - feet_row)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	if absf(dir.x) > 0.01:
		facing = Facing.LEFT if dir.x < 0.0 else Facing.RIGHT
	elif dir.y < -0.01:
		facing = Facing.UP
	elif dir.y > 0.01:
		facing = Facing.DOWN
	move_and_slide()
	if velocity == Vector2.ZERO:
		_clock = 0.0
		sprite.frame = facing * COLUMNS + IDLE_FRAME
	else:
		_clock += delta
		sprite.frame = facing * COLUMNS + WALK_FRAMES[int(_clock * WALK_FPS) % WALK_FRAMES.size()]


func _ensure_bindings() -> void:
	for action in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in BINDINGS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
