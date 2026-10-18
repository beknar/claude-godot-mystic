class_name Foe
extends CharacterBody2D
## node-gates: an enemy. The Green Caves slimes (16 px, their own left and
## right sheets) and four Painted Lands RPG Characters (drawn facing left,
## mirrored for right). It wanders near home, chases the walker along the
## map's flow field (NodeGates.flow_step) once it is close or hurt, winds up
## and strikes when in reach, staggers when hit, and plays its defeat before
## it fades. Stats grow with the node's ring.

signal died(foe: Foe)

enum State { IDLE, CHASE, ATTACK, HURT, DEAD }

const SLIME := "res://assets/pack/green_caves/"
const RPG := "res://assets/pack/rpg_characters/"
## Per kind: art and stats. hp, dmg (half hearts), speed (px/s), aggro
## (cells), reach (px from its feet to the walker's), windup (s before the
## strike can land), cooldown (s between attacks), radius (px, for the
## walker's swing), hit (the attack frame that lands).
const KINDS := {
	"slime_green": {"art": "slime", "dir": "slime green", "hp": 3, "dmg": 1, "speed": 26.0, "aggro": 6, "reach": 15.0, "cooldown": 1.3, "radius": 6.0, "hit": 3},
	"slime_blue": {"art": "slime", "dir": "slime blue", "hp": 5, "dmg": 1, "speed": 32.0, "aggro": 7, "reach": 15.0, "cooldown": 1.1, "radius": 6.0, "hit": 3},
	"cloaked_figure": {"art": "rpg", "dir": "cloaked figure", "prefix": "cloaked_figure", "attack": "attack1", "dead": "defeated", "hp": 7, "dmg": 2, "speed": 38.0, "aggro": 8, "reach": 18.0, "cooldown": 1.2, "radius": 8.0, "hit": 2},
	"samurai": {"art": "rpg", "dir": "samurai", "prefix": "samurai", "attack": "attack1", "dead": "defeated", "hp": 10, "dmg": 2, "speed": 46.0, "aggro": 9, "reach": 21.0, "cooldown": 1.0, "radius": 8.0, "hit": 4},
	"fire_knight": {"art": "rpg", "dir": "fire knight", "prefix": "fire_knight", "attack": "attack1_no_fire", "dead": "defeated", "hp": 14, "dmg": 3, "speed": 34.0, "aggro": 8, "reach": 23.0, "cooldown": 1.3, "radius": 9.0, "hit": 5},
	"dark_knight": {"art": "rpg", "dir": "dark knight", "prefix": "dark_knight", "attack": "attack1", "dead": "defeated", "hp": 20, "dmg": 3, "speed": 30.0, "aggro": 9, "reach": 25.0, "cooldown": 1.4, "radius": 10.0, "hit": 4},
}
## RPG Characters frames: width per animation and where the body stands in
## it (x from the frame's left edge; the feet are on row 30). They face left.
const RPG_FRAMES := {
	"cloaked_figure": {"walk": [32, 15], "attack": [32, 16], "hurt": [32, 15], "dead": [48, 15], "idle": [32, 15]},
	"samurai": {"walk": [48, 32], "attack": [48, 31], "hurt": [48, 32], "dead": [64, 32], "idle": [48, 32]},
	"fire_knight": {"walk": [48, 32], "attack": [64, 32], "hurt": [48, 32], "dead": [64, 32], "idle": [48, 32]},
	"dark_knight": {"walk": [48, 32], "attack": [80, 48], "hurt": [48, 32], "dead": [64, 32], "idle": [48, 32]},
}
const RPG_FEET := 30
## Green Caves slime sheets (16 x 16 frames; the attack is 32 wide, the slime
## standing in the half away from where it lunges). The blue slime's left
## sheets have their own names.
const SLIME_FILES := {
	"slime green": {
		"left": {"idle": "slime_idle_sheet_left", "walk": "slime_walk_sheet_left", "attack": "slimme_attack_sheet_left", "hurt": "slime_hit_sheet_left", "dead": "slime_dead_sheet_left"},
		"right": {"idle": "slime_idle_sheet_right", "walk": "slime_walk_sheet_right", "attack": "slimme_attack_sheet_right", "hurt": "slime_hit_sheet_right", "dead": "slime_dead_sheet_right"},
	},
	"slime blue": {
		"left": {"idle": "slimeB_idle_sheet_left", "walk": "slime_walk_sheet_left", "attack": "slimmeB_attack_sheet_left", "hurt": "slimeB_hit_sheet_left", "dead": "slimeB_dead_shee_leftt"},
		"right": {"idle": "slime_idle_sheet_right", "walk": "slime_walk_sheet_right", "attack": "slimme_attack_sheet_right", "hurt": "slime_hit_sheet_right", "dead": "slime_dead_sheet_right"},
	},
}
const FPS := {"idle": 6.0, "walk": 8.0, "attack": 10.0, "hurt": 12.0, "dead": 9.0}
const BOSS_HP := 3.0
const HURT_TIME := 0.28
const KNOCKBACK := 110.0

static var _frames_cache := {} # kind -> {frames: SpriteFrames, offsets: {anim: Vector2 (facing left)}, widths}

var kind := "slime_green"
var boss := false
var ring := 0
var map: Node # node_gates.gd: flow_step(), walker
var home := Vector2.ZERO
var hp := 1
var max_hp := 1
var dmg := 1
var speed := 30.0
var reach := 15.0
var radius := 6.0
var aggro_px := 96.0
var state := State.IDLE
var facing_left := true

var _art: Dictionary
var _sprite: AnimatedSprite2D
var _anim := ""
var _timer := 0.0
var _cooldown := 0.0
var _struck := false
var _wander_to := Vector2.ZERO
var _knock := Vector2.ZERO
var _flash := 0.0


func setup(p_kind: String, p_ring: int, p_boss := false) -> void:
	kind = p_kind
	ring = p_ring
	boss = p_boss
	_art = KINDS[kind]
	var scale_hp := 1.0 + 0.07 * ring
	max_hp = maxi(1, roundi(_art.hp * scale_hp * (BOSS_HP if boss else 1.0)))
	hp = max_hp
	dmg = _art.dmg + ring / 12 + (1 if boss else 0)
	speed = _art.speed * (1.0 + 0.006 * ring)
	reach = _art.reach
	radius = _art.radius
	aggro_px = _art.aggro * 16.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8, 4) if _art.art == "slime" else Vector2(10, 5)
	var body := CollisionShape2D.new()
	body.shape = shape
	body.position = Vector2(0, -2)
	add_child(body)
	var cached := _frames_for(kind)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = cached.frames
	_sprite.centered = false
	add_child(_sprite)
	if boss:
		_sprite.modulate = Color(1.0, 0.82, 0.82)
	_wander_to = home
	_play("idle")
	_sprite.frame = randi() % maxi(1, cached.frames.get_frame_count(_anim_name("idle")))


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_timer += delta
	if _flash > 0.0:
		_flash -= delta
		_sprite.self_modulate = Color(1, 1, 1, 0.35) if int(_flash * 20.0) % 2 == 0 else Color.WHITE
		if _flash <= 0.0:
			_sprite.self_modulate = Color.WHITE
	var walker: Node2D = map.walker if map else null
	var to_walker := (walker.position - position) if walker else Vector2(9999, 9999)
	match state:
		State.IDLE:
			_idle(delta, to_walker)
		State.CHASE:
			_chase(to_walker)
		State.ATTACK:
			_attack(to_walker, walker)
		State.HURT:
			velocity = _knock
			_knock = _knock.move_toward(Vector2.ZERO, KNOCKBACK * 4.0 * delta)
			if _timer >= HURT_TIME:
				_set_state(State.CHASE)
		State.DEAD:
			velocity = Vector2.ZERO
			return
	if state != State.HURT:
		velocity += _separation()
	move_and_slide()


func _idle(delta: float, to_walker: Vector2) -> void:
	if to_walker.length() < aggro_px and map.walker_active():
		_set_state(State.CHASE)
		return
	if position.distance_to(_wander_to) < 3.0 or _timer > 4.0:
		if _timer > randf_range(1.5, 4.0):
			_timer = 0.0
			var cell: Vector2i = map.wander_cell(home, 3)
			_wander_to = Vector2(cell) * 16.0 + Vector2(8, 12)
		velocity = Vector2.ZERO
		_play("idle")
		return
	var step := (_wander_to - position).normalized()
	velocity = step * speed * 0.45
	_face(step.x)
	_play("walk")


func _chase(to_walker: Vector2) -> void:
	if not map.walker_active():
		_set_state(State.IDLE)
		return
	var d := to_walker.length()
	if d > aggro_px * 2.2:
		_set_state(State.IDLE)
		return
	_face(to_walker.x)
	if d <= reach and absf(to_walker.y) < 12.0:
		velocity = Vector2.ZERO
		if _cooldown <= 0.0:
			_set_state(State.ATTACK)
		else:
			_play("idle")
		return
	var target: Vector2 = map.flow_step(position, to_walker + position)
	# Line up beside the walker (the strikes are sideways), not on top of it.
	if d < 40.0:
		var side := -1.0 if to_walker.x < 0.0 else 1.0
		target = position + to_walker - Vector2(side * reach * 0.8, 0)
	velocity = (target - position).normalized() * speed
	_play("walk")


func _attack(to_walker: Vector2, walker: Node2D) -> void:
	velocity = Vector2.ZERO
	var hit_frame: int = _art.hit
	if _art.art == "slime" and _sprite.frame >= 3 and _sprite.frame <= 4:
		velocity = Vector2(-1.0 if facing_left else 1.0, 0) * speed * 1.6 # the lunge
	if not _struck and _sprite.frame >= hit_frame:
		_struck = true
		var in_front := (to_walker.x < 4.0) if facing_left else (to_walker.x > -4.0)
		if walker and in_front and absf(to_walker.x) <= reach + 6.0 and absf(to_walker.y) < 14.0:
			map.hurt_walker(dmg, position)
	if not _sprite.is_playing() or _sprite.frame >= _sprite.sprite_frames.get_frame_count(_sprite.animation) - 1 and _timer > 0.25:
		_cooldown = _art.cooldown
		_set_state(State.CHASE)


## A hit from the walker: true when it was the killing blow.
func take_hit(amount: int, from: Vector2) -> bool:
	if state == State.DEAD:
		return false
	hp -= amount
	_flash = 0.25
	if hp <= 0:
		_set_state(State.DEAD)
		return true
	_knock = (position - from).normalized() * KNOCKBACK
	_set_state(State.HURT)
	return false


func alive() -> bool:
	return state != State.DEAD


func _set_state(s: State) -> void:
	state = s
	_timer = 0.0
	match s:
		State.IDLE:
			_wander_to = position
			_play("idle")
		State.CHASE:
			_play("walk")
		State.ATTACK:
			_struck = false
			_play("attack", true)
		State.HURT:
			_play("hurt", true)
		State.DEAD:
			collision_layer = 0
			_play("dead", true)
			_sprite.animation_finished.connect(_on_dead_done, CONNECT_ONE_SHOT)


func _on_dead_done() -> void:
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func(): died.emit(self))


func _face(dx: float) -> void:
	if absf(dx) > 1.0:
		var left := dx < 0.0
		if left != facing_left:
			facing_left = left
			_play(_anim, true, true)


func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_parent().get_children():
		if other == self or not (other is Foe) or not other.alive():
			continue
		var d: Vector2 = position - other.position
		if d.length() < 12.0 and d.length() > 0.01:
			push += d.normalized() * (12.0 - d.length()) * 4.0
	return push


func _anim_name(anim: String) -> String:
	if _art.art == "slime":
		return anim + ("_l" if facing_left else "_r")
	return anim


func _play(anim: String, restart := false, keep_frame := false) -> void:
	var name := _anim_name(anim)
	if not restart and _sprite.animation == name and _sprite.is_playing():
		return
	var frame := _sprite.frame
	var progress := _sprite.frame_progress
	_anim = anim
	_sprite.play(name)
	if keep_frame:
		_sprite.set_frame_and_progress(mini(frame, _sprite.sprite_frames.get_frame_count(name) - 1), progress)
	var cached: Dictionary = _frames_cache[kind]
	var off: Vector2 = cached.offsets[name]
	if _art.art == "rpg":
		_sprite.flip_h = not facing_left
		if not facing_left:
			off.x = -(cached.widths[name] + off.x) # the body mirrored within its frame
	_sprite.offset = off


static func _frames_for(p_kind: String) -> Dictionary:
	if _frames_cache.has(p_kind):
		return _frames_cache[p_kind]
	var art: Dictionary = KINDS[p_kind]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var offsets := {}
	var widths := {}
	if art.art == "slime":
		for side in ["left", "right"]:
			var files: Dictionary = SLIME_FILES[art.dir][side]
			for anim in files:
				var tex: Texture2D = load(SLIME + art.dir + "/" + side + "/" + files[anim] + ".png")
				var w := 32 if anim == "attack" else 16
				var name: String = anim + ("_l" if side == "left" else "_r")
				_add_frames(frames, name, tex, w, anim)
				var body := 8
				if anim == "attack":
					body = 24 if side == "left" else 8
				offsets[name] = Vector2(-body, -16)
				widths[name] = w
	else:
		var table: Dictionary = RPG_FRAMES[art.prefix]
		for anim in table:
			var path: String = RPG + art.dir + "/" + (art.prefix + "_idle.png" if anim == "idle" else "Spritesheets/%s_%s-Sheet.png" % [art.prefix, art.get(anim, anim)])
			var tex: Texture2D = load(path)
			_add_frames(frames, anim, tex, table[anim][0], anim)
			offsets[anim] = Vector2(-table[anim][1], -RPG_FEET)
			widths[anim] = table[anim][0]
	_frames_cache[p_kind] = {"frames": frames, "offsets": offsets, "widths": widths}
	return _frames_cache[p_kind]


static func _add_frames(frames: SpriteFrames, name: String, tex: Texture2D, w: int, anim: String) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, FPS[anim])
	frames.set_animation_loop(name, anim in ["idle", "walk"])
	var h := tex.get_height()
	for i in tex.get_width() / w:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * w, 0, w, h)
		frames.add_frame(name, at)
