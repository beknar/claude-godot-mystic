class_name InteriorLife
extends Node2D
## Life inside a home (interior_view.gd), all on whole pixels in warm,
## pack-like colors:
##   hearth  - flames flicker in every fireplace opening (columns of red,
##             orange, and yellow pixels that rise and fall out of step);
##             their glow comes from fire_ambience.gd ("hearth" and "lamp");
##   sun     - each window throws a slanted beam of light on the floor below
##             it, dithered, brightening and dimming as clouds pass, with
##             dust motes turning in it (Painted Lands; a cave has no sun);
##   steam   - wisps rise from cups and teapots and curl as they fade;
##   moths   - a moth loops round some of the lamps;
##   cat     - a house cat (four coats) sleeps by the hearth or in a sunbeam,
##             wakes, stretches, wanders from spot to spot, sits and flicks
##             its tail, and when the walker comes close either strolls up
##             and sits beside it or trots off somewhere else.
## Flames and the cat are y-sorted with the furniture; beams draw under it,
## steam and moths over it.

const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const FLAME := [Color(0.72, 0.2, 0.12), Color(0.95, 0.45, 0.14), Color(1.0, 0.72, 0.24), Color(1.0, 0.92, 0.55)]
const BEAM := Color(1.0, 0.95, 0.78)
const STEAM := Color(0.96, 0.96, 0.96)
const MOTH := Color(0.9, 0.84, 0.7)
const CAT_COATS := [
	{"B": Color(0.85, 0.52, 0.25), "D": Color(0.6, 0.32, 0.15), "W": Color(0.97, 0.93, 0.86), "P": Color(0.9, 0.6, 0.6), "E": Color(0.3, 0.55, 0.2)},
	{"B": Color(0.55, 0.56, 0.6), "D": Color(0.36, 0.37, 0.42), "W": Color(0.92, 0.92, 0.92), "P": Color(0.88, 0.62, 0.64), "E": Color(0.75, 0.7, 0.25)},
	{"B": Color(0.17, 0.15, 0.19), "D": Color(0.08, 0.07, 0.1), "W": Color(0.92, 0.92, 0.9), "P": Color(0.85, 0.55, 0.58), "E": Color(0.85, 0.8, 0.3)},
	{"B": Color(0.93, 0.86, 0.72), "D": Color(0.72, 0.58, 0.44), "W": Color(0.99, 0.97, 0.93), "P": Color(0.9, 0.62, 0.62), "E": Color(0.35, 0.5, 0.7)},
]
# Facing right; the bottom row stands on the ground line. "T" is the tail
# (body color).
const CAT := {
	"sleep": [["........D.D.", "..BBBBBBBBBD", ".BBBBBBBBBBB", "TBBBBBBBBBBB", ".TTTTBBBBBB."],
		["........DD..", "..BBBBBBBBB.", ".BBBBBBBBBBB", "TBBBBBBBBBBB", ".TTTTBBBBBB."]],
	"sit": [["......D..D", "......DBBD", "......BEBB", "......BBBP", "..T...BBW.", ".T...BBBW.", ".T..BBBBW.", "..TBBBBBB.", "..BBBBBBB.", "..DD..D.D."],
		["......D..D", "......DBBD", "......BEBB", "......BBBP", "......BBW.", "T....BBBW.", "T...BBBBW.", ".TTBBBBBB.", "..BBBBBBB.", "..DD..D.D."]],
	"walk": [["...........D.D", "T..........BBB", ".T........BEBB", "..T.......BBBP", "...BBBBBBBBBB.", "...BBBBBBBBBW.", "...BD.B...BD..", "...D..D....D.."],
		["...........D.D", "...........BBB", "T.........BEBB", ".TT.......BBBP", "...BBBBBBBBBB.", "...BBBBBBBBBW.", "....B.DB..B.D.", "....D..D...D.."]],
	"stretch": [["............D.D", "T...........BBB", ".TBBBBBBBBBBEBB", "..BBBBBBBBBBBBP", "..BD........BD.", "..D..........D."]],
}

var walker: Node2D
var sun := true
var _hearths: Array[Dictionary] = [] # {rect, cols: Array[float], node}
var _beams: Array[Dictionary] = [] # {top: Rect2 (window bottom span), length, room: Rect2, phase, motes}
var _steam_spots: Array[Vector2] = []
var _wisps: Array[Dictionary] = []
var _moths: Array[Dictionary] = []
var _cats: Array[Node2D] = []
var _overlay: Node2D
var _rng := RandomNumberGenerator.new()
var _time := 0.0
var _steam_acc := 0.0


func _ready() -> void:
	_rng.randomize()
	z_index = 0 # under the y-sorted actors (beams on the floor)


## `views`: the homes; `actors`: the y-sorted node the flames and cats join.
func setup(views: Array, actors: Node2D, p_walker: Node2D, p_sun: bool) -> void:
	walker = p_walker
	sun = p_sun
	for h in _hearths:
		if is_instance_valid(h.node):
			h.node.queue_free()
	for c in _cats:
		if is_instance_valid(c):
			c.queue_free()
	_hearths.clear()
	_beams.clear()
	_steam_spots.clear()
	_wisps.clear()
	_moths.clear()
	_cats.clear()
	if _overlay == null:
		_overlay = Node2D.new()
		_overlay.z_index = 22 # steam and moths over everything but the fire light
		_overlay.draw.connect(_draw_overlay)
		add_child(_overlay)
	for v in views:
		for r in v.hearths:
			var flame := Node2D.new()
			flame.position = Vector2(r.get_center().x, r.end.y + 5.0) # sorted just in front of the fireplace (its foot is 4 px below the opening)
			flame.set_meta("rect", r)
			actors.add_child(flame)
			var h := {"rect": r, "node": flame, "cols": [], "next": 0.0}
			for x in int(r.size.x):
				h.cols.append(_rng.randf())
			_hearths.append(h)
			flame.draw.connect(_draw_flame.bind(h))
		for w in v.windows:
			if not sun:
				continue
			var wr: Rect2 = w.rect
			var room := Rect2()
			for rr in v.room_rects:
				if rr.has_point(Vector2(wr.get_center().x, w.floor_y + 4)):
					room = rr
			var top := Rect2(wr.position.x + 3, w.floor_y, wr.size.x - 6, 1)
			var beam := {"top": top, "length": _rng.randf_range(26.0, 40.0), "room": room, "phase": _rng.randf() * 100.0, "motes": []}
			for m in _rng.randi_range(3, 5):
				beam.motes.append({"t": _rng.randf(), "s": _rng.randf(), "phase": _rng.randf() * TAU, "speed": _rng.randf_range(0.03, 0.08)})
			_beams.append(beam)
		_steam_spots.append_array(v.steam)
		for l in v.lamps:
			if _rng.randf() < 0.5:
				_moths.append({"center": l, "phase": _rng.randf() * TAU, "rate": _rng.randf_range(1.5, 2.6), "r": _rng.randf_range(5.0, 9.0), "pos": l})
		if _rng.randf() < 0.7 and not v.plan.open_floor().is_empty():
			_cats.append(_make_cat(v, actors))
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for h in _hearths:
		h.next -= delta
		if h.next <= 0.0:
			h.next = _rng.randf_range(0.07, 0.13)
			for i in h.cols.size():
				h.cols[i] = clampf(h.cols[i] + _rng.randf_range(-0.45, 0.45), 0.15, 1.0)
			h.node.queue_redraw()
	# Steam: a wisp from a random cup every so often.
	if not _steam_spots.is_empty():
		_steam_acc += delta * (1.2 + 0.6 * _steam_spots.size())
		while _steam_acc >= 1.0:
			_steam_acc -= 1.0
			var at: Vector2 = _steam_spots[_rng.randi() % _steam_spots.size()]
			_wisps.append({"pos": at + Vector2(_rng.randf_range(-1, 1), -1), "t": 0.0, "life": _rng.randf_range(1.2, 2.0), "phase": _rng.randf() * TAU})
	for w in _wisps:
		w.t += delta
		w.pos += Vector2(sin(_time * 3.0 + w.phase) * 3.0, -7.0) * delta
	_wisps = _wisps.filter(func(w): return w.t < w.life)
	for m in _moths:
		var a: float = _time * m.rate + m.phase
		m.pos = m.center + Vector2(cos(a) * m.r + sin(a * 2.7) * 2.0, sin(a * 1.3) * m.r * 0.6 + cos(a * 3.1) * 1.5 - 2.0)
	for b in _beams:
		for mo in b.motes:
			mo.t = fmod(mo.t + mo.speed * delta, 1.0)
	queue_redraw()
	_overlay.queue_redraw()


# How bright a window's beam is now: clouds drift over the sun.
func _sun_level(b: Dictionary) -> float:
	var t: float = _time * 0.12 + b.phase
	return clampf(0.62 + 0.25 * sin(t) + 0.15 * sin(t * 2.3 + 1.7), 0.25, 1.0)


func _draw() -> void:
	var px := beam_pixels()
	for p in px:
		draw_rect(Rect2(Vector2(p), Vector2.ONE), px[p])


## Beam and mote pixels {Vector2i: Color}, for drawing and headless measuring.
func beam_pixels() -> Dictionary:
	var out := {}
	for b in _beams:
		var level := _sun_level(b)
		var top: Rect2 = b.top
		var room: Rect2 = b.room
		var length: float = b.length
		for dy in int(length):
			var k := 1.0 - dy / length
			var a := 0.26 * k * level
			var y := int(top.position.y) + dy
			var slant := int(dy * 0.55) # the sun is high in the south-east
			for dx in int(top.size.x):
				var x := int(top.position.x) + dx + slant
				if room.size != Vector2.ZERO and not room.has_point(Vector2(x, y)):
					continue
				# Ordered dither thins the beam toward its far end and edges.
				var edge := minf(dx, top.size.x - 1 - dx) / 3.0
				# Leaves outside the window sway across the sun: soft moving dapples.
				var dapple := 0.2 * sin(x * 0.55 + _time * 1.9 + b.phase) * sin(y * 0.7 - _time * 1.4 + b.phase * 0.5)
				var cover := clampf(k * 1.1 + dapple, 0.0, 1.0) * clampf(edge, 0.35, 1.0) * (0.55 + 0.45 * level)
				if BAYER[(y % 4) * 4 + (x % 4)] / 16.0 < cover:
					out[Vector2i(x, y)] = Color(BEAM, a + 0.06)
		for mo in b.motes:
			var dy2: float = mo.t * length * 0.9
			var x2: float = top.position.x + mo.s * top.size.x + dy2 * 0.55 + sin(_time * 0.8 + mo.phase) * 2.0
			var y2: float = top.position.y + dy2 - 6.0 + cos(_time * 0.6 + mo.phase) * 2.0
			out[Vector2i(int(x2), int(y2))] = Color(BEAM, 0.35 + 0.45 * level * absf(sin(_time * 1.3 + mo.phase)))
	return out


func _draw_overlay() -> void:
	var px := overlay_pixels()
	for p in px:
		_overlay.draw_rect(Rect2(Vector2(p), Vector2.ONE), px[p])


## Steam and moth pixels.
func overlay_pixels() -> Dictionary:
	var out := {}
	for w in _wisps:
		var k: float = w.t / w.life
		var a := 0.55 * (1.0 - k) * minf(1.0, w.t * 4.0)
		var p := Vector2i(Vector2(w.pos).floor())
		out[p] = Color(STEAM, a)
		if k > 0.4:
			out[p + Vector2i(1, 0)] = Color(STEAM, a * 0.6)
	for m in _moths:
		var p := Vector2i(Vector2(m.pos).floor())
		out[p] = Color(MOTH, 0.9)
		if fmod(_time * 14.0 + m.phase, 2.0) < 1.0:
			out[p + Vector2i(-1, -1)] = Color(MOTH, 0.7)
			out[p + Vector2i(1, -1)] = Color(MOTH, 0.7)
		else:
			out[p + Vector2i(-1, 0)] = Color(MOTH, 0.7)
			out[p + Vector2i(1, 0)] = Color(MOTH, 0.7)
	return out


func _draw_flame(h: Dictionary) -> void:
	var px := flame_pixels(h)
	var node: Node2D = h.node
	for p in px:
		node.draw_rect(Rect2(Vector2(p) - node.position, Vector2.ONE), px[p])


## A hearth's flame pixels in world space.
func flame_pixels(h: Dictionary) -> Dictionary:
	var out := {}
	var r: Rect2 = h.rect
	for i in h.cols.size():
		var height := int(round(h.cols[i] * r.size.y * (0.55 + 0.45 * sin(PI * (i + 0.5) / h.cols.size()))))
		for dy in height:
			var k := dy / maxf(height, 1.0)
			var band := 0 if k < 0.25 else (1 if k < 0.6 else (2 if k < 0.9 else 3))
			out[Vector2i(int(r.position.x) + i, int(r.end.y) - 1 - dy)] = FLAME[band]
	return out


## Every pixel this node and its flames and cats draw, for headless tools.
func pixels() -> Dictionary:
	var out := beam_pixels()
	out.merge(overlay_pixels(), true)
	for h in _hearths:
		out.merge(flame_pixels(h), true)
	for c in _cats:
		out.merge(c.pixels(), true)
	return out


# ---------------------------------------------------------------- cat

func _make_cat(v, actors: Node2D) -> Node2D:
	var cat := HouseCat.new()
	cat.coat = CAT_COATS[_rng.randi() % CAT_COATS.size()]
	cat.life = self
	cat.setup(v)
	actors.add_child(cat)
	return cat


class HouseCat:
	extends Node2D

	var coat: Dictionary
	var life: InteriorLife
	var state := "sleep"
	var timer := 0.0
	var frame := 0
	var frame_t := 0.0
	var facing := 1
	var path: PackedVector2Array = []
	var speed := 14.0
	var spots: Array[Vector2] = []
	var cozy: Array[Vector2] = [] # hearth fronts and sunbeams: where it likes to sleep
	var astar := AStarGrid2D.new()
	var origin := Vector2.ZERO
	var reacted := false
	var rng := RandomNumberGenerator.new()

	func setup(v) -> void:
		rng.randomize()
		origin = v.position
		var plan: InteriorPlan = v.plan
		astar.region = Rect2i(Vector2i.ZERO, plan.size)
		astar.cell_size = Vector2(16, 16)
		astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		astar.update()
		for y in plan.size.y:
			for x in plan.size.x:
				var c := Vector2i(x, y)
				var open: bool = plan.kind.get(c) == InteriorPlan.FLOOR and not plan.blocked.has(c)
				astar.set_point_solid(c, not open)
				if open and y < plan.size.y - 1:
					spots.append(origin + Vector2(c * 16) + Vector2(8, 12))
		for h in v.hearths:
			var p: Vector2 = h.get_center() + Vector2(0, 22)
			if _open(p):
				cozy.append(p)
		for w in v.windows:
			var p: Vector2 = Vector2(w.rect.get_center().x + 10, w.floor_y + 20)
			if _open(p):
				cozy.append(p)
		position = (cozy[rng.randi() % cozy.size()] if not cozy.is_empty() else spots[rng.randi() % spots.size()]).floor()
		state = "sleep"
		timer = rng.randf_range(6.0, 16.0)
		z_index = 0

	func _open(p: Vector2) -> bool:
		var c := Vector2i(((p - origin) / 16.0).floor())
		return astar.is_in_boundsv(c) and not astar.is_point_solid(c)

	func _process(delta: float) -> void:
		frame_t += delta
		timer -= delta
		var w: Node2D = life.walker if life else null
		var near := is_instance_valid(w) and w.is_visible_in_tree() and w.global_position.distance_to(global_position) < 22.0
		if near and not reacted and state != "walk":
			reacted = true
			if rng.randf() < 0.45:
				_go_to(w.global_position + Vector2(10 * (1 if rng.randf() < 0.5 else -1), 0), 16.0, "sit") # comes to say hello
			else:
				_go_to(_far_spot(w.global_position), 34.0, "sit") # trots off
		elif not near:
			reacted = false
		match state:
			"sleep":
				if frame_t > 1.6:
					frame_t = 0.0
					frame = 1 - frame
				if timer <= 0.0:
					state = "stretch"
					timer = 1.2
			"stretch":
				if timer <= 0.0:
					state = "sit"
					timer = rng.randf_range(3.0, 7.0)
			"sit":
				if frame_t > rng.randf_range(0.4, 1.4):
					frame_t = 0.0
					frame = 1 - frame # tail flick
				if timer <= 0.0:
					if rng.randf() < 0.4 and not cozy.is_empty():
						_go_to(cozy[rng.randi() % cozy.size()], 14.0, "sleep")
					else:
						_go_to(spots[rng.randi() % spots.size()], 14.0, "sit")
			"walk":
				if frame_t > (0.12 if speed > 20.0 else 0.22):
					frame_t = 0.0
					frame = 1 - frame
				_step(delta)
		queue_redraw()

	func _far_spot(from: Vector2) -> Vector2:
		var best := position
		var d := 0.0
		for i in 8:
			var s: Vector2 = spots[rng.randi() % spots.size()]
			if s.distance_to(from) > d:
				d = s.distance_to(from)
				best = s
		return best

	var _then := "sit"

	func _go_to(target: Vector2, p_speed: float, then: String) -> void:
		var a := Vector2i(((position - origin) / 16.0).floor())
		var b := Vector2i(((target - origin) / 16.0).floor())
		if not astar.is_in_boundsv(a) or not astar.is_in_boundsv(b) or astar.is_point_solid(b):
			b = Vector2i(((spots[rng.randi() % spots.size()] - origin) / 16.0).floor())
		if astar.is_point_solid(a):
			a = b
		var ids := astar.get_id_path(a, b)
		path = PackedVector2Array()
		for c in ids:
			path.append(origin + Vector2(c * 16) + Vector2(8, 12))
		if path.is_empty():
			return
		speed = p_speed
		state = "walk"
		_then = then

	func _step(delta: float) -> void:
		if path.is_empty():
			state = _then
			timer = rng.randf_range(8.0, 20.0) if _then == "sleep" else rng.randf_range(3.0, 8.0)
			return
		var to: Vector2 = path[0] - position
		if to.length() < 1.0:
			path.remove_at(0)
			return
		if absf(to.x) > 0.3:
			facing = 1 if to.x > 0 else -1
		position += to.normalized() * minf(speed * delta, to.length())

	## Sprite pixels in world space.
	func pixels() -> Dictionary:
		var out := {}
		var frames: Array = InteriorLife.CAT[state]
		var rows: Array = frames[mini(frame, frames.size() - 1)]
		var w: int = rows[0].length()
		var base := Vector2i(position.floor())
		for y in rows.size():
			var row: String = rows[y]
			for x in w:
				var ch := row[x]
				if ch == ".":
					continue
				var col: Color = coat.get(ch, coat.B) if ch != "T" else coat.B
				var px := x - w / 2
				if facing < 0:
					px = w - 1 - x - w / 2
				out[base + Vector2i(px, y - rows.size() + 1)] = col
		return out

	func _draw() -> void:
		var px := pixels()
		for p in px:
			draw_rect(Rect2(Vector2(p) - position, Vector2.ONE), px[p])
		# A soft shadow under the cat.
		draw_rect(Rect2(Vector2(-4, 0), Vector2(8, 1)), Color(0, 0, 0, 0.18))
