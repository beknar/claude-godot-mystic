class_name GrassWaves
extends Node2D
## Wind passing over the grass: a front of sunlit blade tips rolls across
## the lawn downwind, the way a gust visibly moves through a meadow. Each
## front is a band across the wind; inside it, a dithered scatter of pale
## tips lights up on grass cells (never on the path, dirt, water, stone, or
## anything solid), brightest in the band's middle, leaning one pixel
## downwind. Every gust sends one or two fronts, and a faint one passes in
## between. Nothing on the map moves: this is light on the grass, drawn under
## the y-sorted actors on whole world pixels. Fronts are only drawn in and
## around the camera's view.

const SPEED := 42.0 # px/s
const BAND := 40.0 # px across a front
const TIPS := 7 # candidate tip pixels per grass cell
const CALM_EVERY := Vector2(7.0, 12.0) # seconds between faint fronts
const TIP := Color(0.78, 0.86, 0.55)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var wind: Wind
var view_override := Rect2() # set by headless tools; otherwise the camera's view
var _grass := {} # cell -> true
var _tips := {} # cell -> Array[Vector2i] pixel offsets in the cell
var _fronts: Array[Dictionary] = [] # {dir, dist, strength}
var _rng := RandomNumberGenerator.new()
var _was_gusting := false
var _next_calm := 4.0


func _ready() -> void:
	_rng.randomize()
	z_index = 0 # placed before the y-sorted actors, so it draws under them


## `grass`: cells the light may play over.
func setup(grass: Dictionary) -> void:
	_grass = grass
	_tips.clear()
	for c in grass:
		var tips: Array[Vector2i] = []
		for i in TIPS:
			var h := absi(hash(Vector3i(c.x, c.y, i)))
			tips.append(Vector2i(h % 16, (h >> 8) % 15 + 1))
		_tips[c] = tips
	_fronts.clear()


## Cells with grass the walker could stand on: not blocked, not the path,
## a dirt island, stairs, a ramp, or a stone plateau top.
static func grass_cells(t: PaintedTerrain) -> Dictionary:
	var out := {}
	var bare := {}
	for b in t.blobs:
		for c in b.cells:
			bare[c] = true
	for info in t.plateaus:
		if info.tone == "stone":
			var top: Rect2i = info.top
			for y in range(top.position.y, top.end.y):
				for x in range(top.position.x, top.end.x):
					bare[Vector2i(x, y)] = true
	for y in PaintedTerrain.HEIGHT:
		for x in PaintedTerrain.WIDTH:
			var c := Vector2i(x, y)
			if not (t._blocked.has(c) or t.path.has(c) or bare.has(c) or t.stairs.has(c) or t.ramps.has(c) or t.water.has(c)):
				out[c] = true
	return out


func _process(delta: float) -> void:
	if wind == null:
		return
	var gusting := wind.gust > 0.2
	if gusting and not _was_gusting:
		for i in _rng.randi_range(1, 2):
			_start_front(0.7 + wind.gust * 0.6, -i * 70.0)
	_was_gusting = gusting
	_next_calm -= delta
	if _next_calm <= 0.0:
		_next_calm = _rng.randf_range(CALM_EVERY.x, CALM_EVERY.y)
		_start_front(0.35 + wind.base_strength * 0.3, 0.0)
	var reach := _view().size.length() + BAND * 2.0
	for f in _fronts:
		f.dist += SPEED * (0.7 + wind.strength() * 0.4) * delta
	_fronts = _fronts.filter(func(f): return f.dist < reach)
	queue_redraw()


# A front starts on the upwind side of the view, `lag` px further back.
func _start_front(strength: float, lag: float) -> void:
	_fronts.append({"dir": wind.direction(), "dist": lag - BAND, "strength": clampf(strength, 0.0, 1.0)})


func _view() -> Rect2:
	if view_override.size != Vector2.ZERO:
		return view_override
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	return inv * get_viewport_rect()


## Every pixel drawn right now, {Vector2i: Color}, for headless measuring.
func pixels() -> Dictionary:
	var out := {}
	if _fronts.is_empty():
		return out
	var view := _view()
	var center := view.get_center()
	var half := view.size / 2.0
	for f in _fronts:
		var d: Vector2 = f.dir
		# Distance along the wind from the view's upwind corner.
		var start := center - Vector2(half.x * signf(d.x), half.y * signf(d.y))
		var lean := Vector2i(roundi(d.x), roundi(d.y))
		var c0 := Vector2i(floori(view.position.x / 16.0), floori(view.position.y / 16.0))
		var c1 := Vector2i(floori(view.end.x / 16.0), floori(view.end.y / 16.0))
		for cy in range(c0.y, c1.y + 1):
			for cx in range(c0.x, c1.x + 1):
				var cell := Vector2i(cx, cy)
				if not _grass.has(cell):
					continue
				var cell_along := (Vector2(cell * 16) + Vector2(8, 8) - start).dot(d)
				if absf(cell_along - f.dist) > BAND * 0.5 + 12.0:
					continue
				for o in _tips[cell]:
					var p: Vector2i = cell * 16 + o
					var k := 1.0 - absf((Vector2(p) - start).dot(d) - f.dist) / (BAND * 0.5)
					if k <= 0.0:
						continue
					var level: float = k * f.strength
					if BAYER[(p.y % 4) * 4 + (p.x % 4)] / 16.0 >= level:
						continue
					out[p + lean] = Color(TIP, 0.55 + 0.4 * level)
	return out


func _draw() -> void:
	var px := pixels()
	for p in px:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), px[p])
