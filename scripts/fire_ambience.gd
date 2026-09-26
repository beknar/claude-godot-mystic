class_name FireAmbience
extends Node2D
## Warm light and smoke for campfires and torches. Each fire gets a pixel
## glow (a round light made of solid, ordered-dither steps, so it stays
## pixel art) drawn additively over the scene, flickering out of step with
## the others; big fires glow wider. Campfires also send up a thin trail of
## single-pixel smoke puffs that rise, bend with the wind, and fade.

const GLOW_TINT := Color(1.0, 0.62, 0.25)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const SMOKE_RATE := 4.0 # puffs per second per campfire
const SMOKE_LIFE := Vector2(2.6, 3.8)
const SMOKE_RISE := 12.0 # px/s
const SMOKE_BEND := 14.0 # wind carry at full strength
const SMOKE_COLORS := [Color(0.78, 0.76, 0.72), Color(0.62, 0.62, 0.6), Color(0.5, 0.5, 0.5)]

var wind: Wind
var _fires: Array[Dictionary] = [] # {pos, radius, glow: Sprite2D, phase, smoke: bool, flame: Vector2}
var _puffs: Array[Dictionary] = []
var _glow_cache := {} # radius -> texture
var _rng := RandomNumberGenerator.new()
var _smoke_acc := 0.0
var _time := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 25 # above the y-sorted actors, so the light falls on them


## `fires`: {pos: foot position, kind: "torch" | "campfire" | "campfire_big"}.
func set_fires(fires: Array[Dictionary]) -> void:
	for f in _fires:
		f.glow.queue_free()
	_fires.clear()
	_puffs.clear()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	for f in fires:
		var torch: bool = f.kind == "torch"
		var radius := 22 if torch else (40 if f.kind == "campfire" else 52)
		var flame: Vector2 = f.pos + (Vector2(0, -24) if torch else Vector2(0, -8))
		var glow := Sprite2D.new()
		glow.texture = _glow(radius)
		glow.material = add
		glow.position = flame.floor()
		add_child(glow)
		_fires.append({"radius": radius, "glow": glow, "phase": _rng.randf() * TAU,
			"smoke": not torch, "flame": flame, "rate": _rng.randf_range(7.0, 11.0)})
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for f in _fires:
		# Flicker: two out-of-step waves plus a little noise, never dark.
		var fl: float = 0.78 + 0.12 * sin(_time * f.rate + f.phase) + 0.07 * sin(_time * f.rate * 2.3 + f.phase * 1.7) + _rng.randf_range(-0.03, 0.03)
		f.glow.modulate = Color(fl, fl, fl, 1.0)
		var s := 1.0 + 0.04 * sin(_time * f.rate * 0.5 + f.phase)
		f.glow.scale = Vector2(s, s)
	if wind == null:
		return
	var smokers := _fires.filter(func(f): return f.smoke)
	_smoke_acc += delta * SMOKE_RATE * smokers.size()
	while _smoke_acc >= 1.0 and not smokers.is_empty():
		_smoke_acc -= 1.0
		var f: Dictionary = smokers[_rng.randi() % smokers.size()]
		_puffs.append({"pos": f.flame + Vector2(_rng.randf_range(-2, 2), -4), "t": 0.0,
			"life": _rng.randf_range(SMOKE_LIFE.x, SMOKE_LIFE.y), "wobble": _rng.randf() * TAU})
	var bend := wind.carry(SMOKE_BEND)
	for p in _puffs:
		p.t += delta
		var rise: float = SMOKE_RISE * (1.0 - 0.4 * p.t / p.life)
		p.pos += (Vector2(0, -rise) + bend * minf(1.0, p.t / 0.8)) * delta
		p.pos.x += sin(p.t * 3.0 + p.wobble) * 4.0 * delta
	_puffs = _puffs.filter(func(p): return p.t < p.life)
	queue_redraw()


func _draw() -> void:
	for p in _puffs:
		var k: float = p.t / p.life
		var c: Color = SMOKE_COLORS[mini(int(k * 3.0), 2)]
		c.a = 0.85 * (1.0 - k * k) * minf(1.0, p.t / 0.25)
		var at := Vector2(p.pos).floor()
		# A puff is a 2x2 knot that loosens into three and then four pixels
		# of a 3x3 as it rises, so the column thickens and thins out.
		var cells: Array = [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
		if k > 0.45:
			cells = [Vector2(0, 0), Vector2(2, 0), Vector2(1, 1), Vector2(0, 2), Vector2(2, 2)]
		for o in cells:
			draw_rect(Rect2(at + o, Vector2.ONE), c)


# A round light that brightens in steps toward the middle, the steps joined
# by an ordered dither, so its edge is pixel art rather than a blur.
func _glow(radius: int) -> ImageTexture:
	if _glow_cache.has(radius):
		return _glow_cache[radius]
	var size := radius * 2 + 1
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var d := Vector2(x - radius, (y - radius) * 1.25).length() / radius # a little flattened
			if d >= 1.0:
				continue
			var v := pow(1.0 - d, 1.6) * 0.42 # brightness 0..0.42
			var level := v * 4.0 # four steps
			var step := floorf(level)
			if level - step > BAYER[(y % 4) * 4 + (x % 4)] / 16.0:
				step += 1.0
			var a := step / 4.0 * 0.42
			if a <= 0.0:
				continue
			img.set_pixel(x, y, Color(GLOW_TINT.r * a, GLOW_TINT.g * a, GLOW_TINT.b * a, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_glow_cache[radius] = tex
	return tex
