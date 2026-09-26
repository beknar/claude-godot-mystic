class_name CloudShadows
extends Node2D
## Soft cloud shadows drifting across the map with the wind. Each shadow is
## a lumpy blob of translucent deep-grass green with a dithered rim (a 4x4
## ordered dither), generated once at world-pixel resolution and moved on
## whole pixels, so it reads as pixel art rather than a blur. A shadow that
## drifts off the map comes back on the upwind side.

const COUNT := 3
const SHADE := Color(23.0 / 255.0, 63.0 / 255.0, 62.0 / 255.0, 0.16) # deep grass tone
const SPEED := 7.0 # px/s at full wind strength
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var wind: Wind
var bounds := Rect2()
var _clouds: Array[Sprite2D] = []
var _pos: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	z_index = 30 # over everything in the world, under the menu's canvas layer


## Places the shadows at random over `map_rect`.
func reset(map_rect: Rect2) -> void:
	bounds = map_rect
	for c in _clouds:
		c.queue_free()
	_clouds.clear()
	_pos.clear()
	for i in COUNT:
		var sprite := Sprite2D.new()
		sprite.centered = true
		sprite.texture = _make_cloud()
		add_child(sprite)
		_clouds.append(sprite)
		_pos.append(bounds.position + Vector2(_rng.randf() * bounds.size.x, _rng.randf() * bounds.size.y))
		sprite.position = _pos[i].floor()


func _process(delta: float) -> void:
	if wind == null or _clouds.is_empty():
		return
	var v := wind.carry(SPEED)
	for i in _clouds.size():
		_pos[i] += v * delta * (0.85 + 0.1 * i)
		var half := _clouds[i].texture.get_size() / 2.0
		var area := bounds.grow_individual(half.x, half.y, half.x, half.y)
		if not area.has_point(_pos[i]):
			_pos[i] = _upwind_spawn(half)
		_clouds[i].position = _pos[i].floor()


# A point just outside the map on the side the wind blows from.
func _upwind_spawn(half: Vector2) -> Vector2:
	var d := wind.direction()
	var p := bounds.position + Vector2(_rng.randf() * bounds.size.x, _rng.randf() * bounds.size.y)
	if absf(d.x) > absf(d.y):
		p.x = bounds.position.x - half.x + 1.0 if d.x > 0.0 else bounds.end.x + half.x - 1.0
	else:
		p.y = bounds.position.y - half.y + 1.0 if d.y > 0.0 else bounds.end.y + half.y - 1.0
	return p


func _make_cloud() -> ImageTexture:
	var w := _rng.randi_range(170, 260)
	var h := _rng.randi_range(100, 150)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	# A few overlapping ellipses make the lumpy outline.
	var lobes: Array[Vector4] = [] # cx, cy, rx, ry
	for i in _rng.randi_range(4, 6):
		lobes.append(Vector4(_rng.randf_range(0.25, 0.75) * w, _rng.randf_range(0.35, 0.65) * h,
			_rng.randf_range(0.18, 0.3) * w, _rng.randf_range(0.22, 0.34) * h))
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.frequency = 0.05
	for y in h:
		for x in w:
			var f := 0.0
			for l in lobes:
				var dx := (x - l.x) / l.z
				var dy := (y - l.y) / l.w
				f = maxf(f, 1.0 - (dx * dx + dy * dy))
			f += noise.get_noise_2d(x, y) * 0.07
			if f <= 0.0:
				continue
			# Solid inside, ordered dither across the rim.
			var t := clampf(f / 0.12, 0.0, 1.0)
			if t < 1.0 and BAYER[(y % 4) * 4 + (x % 4)] / 16.0 >= t:
				continue
			img.set_pixel(x, y, SHADE)
	return ImageTexture.create_from_image(img)
