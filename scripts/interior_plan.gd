class_name InteriorPlan
extends RefCounted
## A single-floor home of one to six rooms, as data: which cells are wall
## tops, wall faces, and floor, where the doors and the way out are, what
## each room is, and every piece of furniture and decoration (Cozy Cottage
## art, interior_art.gd) with its position and footprint. interior_view.gd
## paints it; the Green Caves generator builds cave homes from it in place,
## and the Painted Lands randomizer opens one behind every house door.
##
## Layout: a rectangle of rooms split by one-cell walls (binary splits, each
## side at least MIN_W wide and MIN_H tall). A room's top three rows are its
## north wall face; the rest is floor. Every split gets one door between two
## rooms that meet across it, so every room is reachable: a gap in a
## vertical wall, or a doorway through a horizontal wall and the face below
## it. The way out is a gap in the south wall. Furniture never closes a door,
## the way out, or the path between them (flood fill after each piece).

const WALL := 1
const FACE := 2
const FLOOR := 3
const FACE_ROWS := 3
const MIN_W := 4
const WINDOWS := ["window", "window_b", "window_c", "window_d", "window_e", "window_f", "window_panes", "window_panes_b",
	"window_arch", "window_arch_vine", "window_plain"]
const MIN_H := 6
const TILE := 16
const ROOM_SETS := {
	1: [["cottage"]],
	2: [["living", "bedroom"], ["cottage", "bedroom"], ["living", "kitchen"]],
	3: [["living", "kitchen", "bedroom"], ["hall", "kitchen", "bedroom"], ["living", "bedroom", "study"]],
	4: [["living", "kitchen", "bedroom", "study"], ["living", "kitchen", "bedroom", "bath"], ["hall", "kitchen", "bedroom", "dining"]],
	5: [["living", "kitchen", "bedroom", "bath", "study"], ["hall", "kitchen", "bedroom", "bath", "dining"], ["living", "kitchen", "bedroom", "bedroom", "pantry"]],
	6: [["living", "kitchen", "bedroom", "bath", "study", "bedroom"], ["hall", "kitchen", "dining", "bedroom", "bath", "study"], ["living", "kitchen", "bedroom", "bath", "pantry", "bedroom"]],
}

var seed := 0
var size := Vector2i.ZERO
var kind := {} # cell -> WALL | FACE | FLOOR; cells not in it are outside
var room_of := {} # face and floor cell -> room index
var face_row := {} # face cell -> 0..2
var rooms: Array[Dictionary] = [] # {rect, type, paper, floor: {kind, origin}}
var doors: Array[Dictionary] = [] # {cells, dir: "v" | "h", rooms}
var doorway := {} # floor cell in a face row of a door -> face row (the frame is drawn over it)
var exit_cell := Vector2i.ZERO
var items: Array[Dictionary] = [] # {art, pos (local px, bottom middle), flip, place, cells, wood, rect?}
var style := {} # {wood, trim, black, counter}
var blocked := {} # floor cells furniture stands on
var notes := PackedStringArray()

var _rng := RandomNumberGenerator.new()
var _face_used := {} # Vector2i(column, room top) -> true, where tall furniture or a hanging already is
var _keep := {} # floor cells that must stay open (doors, their approach, the way out)


## Builds a home of `n` rooms (1-6). `opts`: black (wall-top fill black, for
## caves and the dark around an interior), trim / wood (force a style),
## exit_width (1, or 3 for a cave home's arched doorway), max_size.
func generate(p_seed: int, n: int, opts := {}) -> InteriorPlan:
	seed = p_seed
	_rng.seed = hash(Vector2i(p_seed, n))
	n = clampi(n, 1, 6)
	style = {
		"wood": opts.get("wood", _rng.randi_range(0, 4)),
		"trim": opts.get("trim", [1, 1, 2, 3, 0][_rng.randi() % 5]),
		"black": opts.get("black", true),
		"counter": ["wood", "marble"][_rng.randi() % 2],
	}
	for attempt in 30:
		if _layout(n, opts):
			break
	_assign_rooms(n)
	_mark_keep()
	for i in rooms.size():
		_furnish(i)
	# Every home keeps a fire: without a living room, the kitchen or the
	# entry gets a cooking hearth.
	if not items.any(func(it): return InteriorArt.ART.get(it.art, {}).has("hearth")):
		var order := range(rooms.size())
		order.sort_custom(func(a, b): return (rooms[a].type == "kitchen") and not (rooms[b].type == "kitchen"))
		var placed := false
		for art in ["hearth_stone", "hearth_brown", "hearth_stone_b", "hearth_white"]:
			for i in order:
				if _wall(i, art, false, true):
					placed = true
					break
			if placed:
				break
	return self


# ---------------------------------------------------------------- layout

func _layout(n: int, opts: Dictionary) -> bool:
	kind.clear()
	room_of.clear()
	face_row.clear()
	rooms.clear()
	doors.clear()
	doorway.clear()
	# Columns and rows of rooms, then random sizes; the splits below vary it.
	var grids := {1: [[1, 1]], 2: [[2, 1], [1, 2]], 3: [[3, 1], [2, 2]], 4: [[2, 2], [3, 2]], 5: [[3, 2]], 6: [[3, 2], [4, 2]]}
	var g: Array = grids[n][_rng.randi() % grids[n].size()]
	var inner := Vector2i(0, 0)
	for i in g[0]:
		inner.x += _rng.randi_range(5, 8) + (1 if i > 0 else 0)
	for j in g[1]:
		inner.y += _rng.randi_range(6, 8) + (1 if j > 0 else 0)
	var cap: Vector2i = opts.get("max_size", Vector2i(40, 24))
	inner = Vector2i(mini(inner.x, cap.x - 2), mini(inner.y, cap.y - 2))
	size = inner + Vector2i(2, 2)
	var leaves: Array[Rect2i] = [Rect2i(1, 1, inner.x, inner.y)]
	var splits: Array[Dictionary] = []
	while leaves.size() < n:
		# Split the largest leaf that can split, across its longer side.
		var order := range(leaves.size())
		order.sort_custom(func(a, b): return leaves[a].get_area() > leaves[b].get_area())
		var done := false
		for li in order:
			var l: Rect2i = leaves[li]
			var can_v := l.size.x >= 2 * MIN_W + 1
			var can_h := l.size.y >= 2 * MIN_H + 1
			if not (can_v or can_h):
				continue
			var vertical := can_v and (not can_h or l.size.x * 0.8 >= l.size.y or _rng.randf() < 0.25)
			if vertical:
				var x := _rng.randi_range(l.position.x + MIN_W, l.end.x - MIN_W - 1)
				var a := Rect2i(l.position.x, l.position.y, x - l.position.x, l.size.y)
				var b := Rect2i(x + 1, l.position.y, l.end.x - x - 1, l.size.y)
				leaves.remove_at(li)
				leaves.append_array([a, b])
				splits.append({"dir": "v", "line": x, "a": a, "b": b})
			else:
				var y := _rng.randi_range(l.position.y + MIN_H, l.end.y - MIN_H - 1)
				var a := Rect2i(l.position.x, l.position.y, l.size.x, y - l.position.y)
				var b := Rect2i(l.position.x, y + 1, l.size.x, l.end.y - y - 1)
				leaves.remove_at(li)
				leaves.append_array([a, b])
				splits.append({"dir": "h", "line": y, "a": a, "b": b})
			done = true
			break
		if not done:
			return false
	# Cells: all wall, then each room's face rows and floor.
	for y in size.y:
		for x in size.x:
			kind[Vector2i(x, y)] = WALL
	for i in leaves.size():
		var r: Rect2i = leaves[i]
		rooms.append({"rect": r})
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				var row := y - r.position.y
				kind[c] = FACE if row < FACE_ROWS else FLOOR
				if row < FACE_ROWS:
					face_row[c] = row
				room_of[c] = i
	# One door per split, between two rooms that meet across it.
	for s in splits:
		if not _door(s, leaves):
			return false
	# The way out: the south wall of a room on the south side.
	var south: Array[int] = []
	for i in leaves.size():
		if leaves[i].end.y == size.y - 1 and leaves[i].size.x >= 3:
			south.append(i)
	if south.is_empty():
		return false
	south.sort_custom(func(a, b): return leaves[a].size.x > leaves[b].size.x)
	var er: Rect2i = leaves[south[0]]
	var ew: int = opts.get("exit_width", 1)
	var lo := er.position.x + (1 if ew == 1 else 1)
	var hi := er.end.x - 1 - (1 if ew == 1 else 1)
	exit_cell = Vector2i(_rng.randi_range(lo, maxi(lo, hi)), size.y - 1)
	kind[exit_cell] = FLOOR
	room_of[exit_cell] = south[0]
	rooms[south[0]]["entry"] = true
	return true


func _door(s: Dictionary, leaves: Array[Rect2i]) -> bool:
	var pairs: Array = []
	for a in leaves:
		for b in leaves:
			if s.dir == "v" and a.end.x == s.line and b.position.x == s.line + 1 and s.a.encloses(a) and s.b.encloses(b):
				# Floor rows both rooms share.
				var y0 := maxi(a.position.y, b.position.y) + FACE_ROWS
				var y1 := mini(a.end.y, b.end.y)
				if y1 - y0 >= 1:
					pairs.append([a, b, y0, y1])
			elif s.dir == "h" and a.end.y == s.line and b.position.y == s.line + 1 and s.a.encloses(a) and s.b.encloses(b):
				var x0 := maxi(a.position.x, b.position.x)
				var x1 := mini(a.end.x, b.end.x)
				if x1 - x0 >= 2:
					pairs.append([a, b, x0, x1])
	if pairs.is_empty():
		return false
	var p: Array = pairs[_rng.randi() % pairs.size()]
	var ia := leaves.find(p[0])
	var ib := leaves.find(p[1])
	var cells: Array[Vector2i] = []
	if s.dir == "v":
		var y := _rng.randi_range(p[2], p[3] - 1)
		var c := Vector2i(s.line, y)
		cells.append(c)
		if y + 1 < p[3]:
			cells.append(c + Vector2i(0, 1)) # two cells tall where there is room
	else:
		var x := _rng.randi_range(p[2], p[3] - 2)
		for dx in 2:
			cells.append(Vector2i(x + dx, s.line))
			for k in FACE_ROWS:
				var f := Vector2i(x + dx, s.line + 1 + k)
				kind[f] = FLOOR
				face_row.erase(f)
				doorway[f] = k
	for c in cells:
		kind[c] = FLOOR
		room_of[c] = ib
	doors.append({"cells": cells, "dir": s.dir, "rooms": [ia, ib]})
	return true


# ---------------------------------------------------------------- rooms

func _assign_rooms(n: int) -> void:
	var sets: Array = ROOM_SETS[n]
	var types: Array = sets[_rng.randi() % sets.size()].duplicate()
	var entry := 0
	for i in rooms.size():
		if rooms[i].get("entry", false):
			entry = i
	# The first type goes to the entry room; bath and pantry to the smallest
	# rooms left, the rest by size.
	var others: Array[int] = []
	for i in rooms.size():
		if i != entry:
			others.append(i)
	others.sort_custom(func(a, b): return rooms[a].rect.get_area() > rooms[b].rect.get_area())
	rooms[entry]["type"] = types.pop_front()
	var small := types.filter(func(t): return t in ["bath", "pantry"])
	var big := types.filter(func(t): return not t in ["bath", "pantry"])
	var ordered: Array = big + small
	for k in others.size():
		rooms[others[k]]["type"] = ordered[k] if k < ordered.size() else "bedroom"
	var papers: Array = InteriorArt.PAPERS[style.trim]
	var hall_paper: int = papers[_rng.randi() % papers.size()]
	for i in rooms.size():
		var t: String = rooms[i].type
		rooms[i]["paper"] = hall_paper if _rng.randf() < 0.35 else papers[_rng.randi() % papers.size()]
		var fl := {}
		if t in ["kitchen", "bath", "pantry"]:
			fl = {"kind": "tiles", "column": InteriorArt.TILES[_rng.randi() % InteriorArt.TILES.size()]}
		elif t == "hall" or (t == "dining" and _rng.randf() < 0.5):
			fl = {"kind": "parquet", "origin": InteriorArt.PARQUET[_rng.randi() % InteriorArt.PARQUET.size()]}
		else:
			fl = {"kind": "planks", "origin": InteriorArt.PLANKS[_rng.randi() % InteriorArt.PLANKS.size()]}
		rooms[i]["floor"] = fl
	notes.append("%d rooms: %s" % [rooms.size(), ", ".join(rooms.map(func(r): return r.type))])


func _mark_keep() -> void:
	_keep.clear()
	for d in doors:
		for c in d.cells:
			_keep[c] = true
			for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if kind.get(c + o) == FLOOR:
					_keep[c + o] = true
		if d.dir == "h":
			# The floor under the doorway and the row in front of it.
			for c in d.cells:
				for k in FACE_ROWS + 1:
					_keep[c + Vector2i(0, 1 + k)] = true
	_keep[exit_cell] = true
	_keep[exit_cell + Vector2i.UP] = true
	_keep[exit_cell + Vector2i(0, -2)] = true


# ---------------------------------------------------------------- furniture

func _furnish(i: int) -> void:
	var r: Rect2i = rooms[i].rect
	var t: String = rooms[i].type
	# The hearth rooms place the fireplace first; their windows come after.
	if not t in ["pantry", "living", "cottage", "bath"] and _rng.randf() < 0.9:
		_face_deco(i, 1, WINDOWS) # a window first, so tall furniture stands beside it
	match t:
		"cottage":
			_wall(i, _pick(["hearth_stone", "hearth_stone_b", "hearth_flowers", "hearth_brown", "hearth_white"]))
			_wall(i, _pick(["bed", "bed_b", "bed_quilt", "bed_narrow"]), true)
			_wall(i, _pick(["wardrobe", "wardrobe_b", "dresser", "dish_shelf"]))
			_counters(i, 2)
			_table_set(i, _pick(["table", "table_b", "table_c"]), 2)
			_rug(i, "medium")
			_floor_deco(i, 2)
			_face_deco(i, 3)
		"living":
			_wall(i, _pick(["hearth_brown", "hearth_white", "hearth_dark", "hearth_flowers", "hearth_flowers_b", "hearth_stone"]))
			_rug(i, _pick(["large", "square"]))
			_wall(i, _pick(["sofa", "loveseat"]))
			_floor_piece(i, _pick(["low_table", "low_table_b", "low_table_c"]), true)
			_floor_piece(i, _pick(["armchair", "armchair_ornate"]))
			_wall(i, _pick(["bookshelf", "bookshelf_b", "plant_shelf", "plant_shelf_b"]))
			_floor_piece(i, _pick(["floor_lamp", "floor_lamp_b", "floor_lamp_c"]))
			_floor_deco(i, 2)
			_face_deco(i, 4)
		"hall":
			_rug(i, _pick(["tall", "wide", "checker"]))
			_wall(i, _pick(["mirror_stand", "cabinet", "low_shelf"]))
			_wall(i, _pick(["plant_shelf", "drawers", "bench"]))
			_floor_deco(i, 3)
			_face_deco(i, 4)
		"kitchen":
			_counters(i, _rng.randi_range(3, mini(7, r.size.x - 1)))
			_wall(i, _pick(["dish_shelf", "dish_shelf_b", "low_shelf"]))
			_table_set(i, _pick(["table", "table_b", "table_c", "table_d", "table_e"]), _rng.randi_range(2, 4))
			_rug(i, "mat")
			_floor_deco(i, 1)
			_face_deco(i, 3, ["herbs", "wall_shelf", "window_panes", "window_panes_b"])
		"bedroom":
			_wall(i, _pick(["bed", "bed_b", "bed_quilt", "bed_narrow"]), true)
			_wall(i, "nightstand")
			_wall(i, _pick(["wardrobe", "wardrobe_b", "wardrobe_vine"]))
			_wall(i, _pick(["dresser", "vanity", "drawers", "drawers_b"]))
			_rug(i, _pick(["medium", "square", "wide"]))
			_floor_deco(i, 2)
			_face_deco(i, 3)
		"study":
			_wall(i, _pick(["bookshelf", "bookshelf_b"]))
			_wall(i, _pick(["bookshelf", "bookshelf_b", "shelf"]))
			_wall(i, _pick(["bookshelf_b", "plant_shelf"]))
			_desk(i)
			_rug(i, _pick(["medium", "wide"]))
			_floor_piece(i, _pick(["floor_lamp", "floor_lamp_b"]))
			_floor_deco(i, 1)
			_face_deco(i, 2)
		"bath":
			if not _wall(i, "tub"):
				_floor_piece(i, "tub")
			_wall(i, _pick(["vanity", "cabinet"]))
			_rug(i, "mat")
			_floor_deco(i, 1)
			_face_deco(i, 2, ["mirror", "window_panes", "hanging_plant", "painting_small"])
		"dining":
			_rug(i, _pick(["large", "square"]))
			_table_set(i, _pick(["long_table", "long_table_b", "table_d", "table_e"]), _rng.randi_range(4, 6))
			_wall(i, _pick(["dish_shelf", "dish_shelf_b", "cabinet"]))
			_floor_deco(i, 2)
			_face_deco(i, 4)
		"pantry":
			_wall(i, _pick(["dish_shelf", "low_shelf"]))
			_wall(i, _pick(["shelf", "dish_shelf_b"]))
			_floor_deco(i, 3, ["basket", "basket_b", "basket"])
			_face_deco(i, 2, ["herbs", "wall_shelf", "hanging_plant"])
	# Something on every table and cabinet top.
	for it in items:
		if it.room == i and it.get("top", InteriorArt.ART.get(it.art, {}).get("top", false)) and not it.get("topped", false) and _rng.randf() < 0.8:
			_top_deco(it)


# Shuffles with the plan's own generator, so a seed always gives the same home.
func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _pick(a: Array) -> String:
	return a[_rng.randi() % a.size()]


## A piece against the north wall: its footprint starts on the first floor
## row, anywhere along the wall that is free.
## `displace`: a tall piece may take the place of a window or painting (which
## is then taken down).
func _wall(i: int, art: String, deep := false, displace := false) -> bool:
	var r: Rect2i = rooms[i].rect
	var cells: Vector2i = InteriorArt.ART[art].cells
	var y := r.position.y + FACE_ROWS
	var xs := range(r.position.x, r.end.x - cells.x + 1)
	_shuffle(xs)
	var tall: bool = InteriorArt.ART[art].rect.size.y > 22
	for x in xs:
		if tall and not displace and range(cells.x).any(func(dx): return _face_used.get(Vector2i(x + dx, r.position.y), false)):
			continue # it would stand in front of a window or a painting
		if _try(i, art, Rect2i(x, y, cells.x, cells.y)):
			if tall:
				for dx in cells.x:
					_face_used[Vector2i(x + dx, r.position.y)] = true
				if displace:
					var lo: int = x * TILE
					var hi: int = (x + cells.x) * TILE
					items = items.filter(func(it): return not (it.room == i and it.place == "face"
						and it.pos.x + InteriorArt.ART[it.art].rect.size.x / 2.0 > lo and it.pos.x - InteriorArt.ART[it.art].rect.size.x / 2.0 < hi))
			return true
	return false


## A free-standing piece somewhere on the floor, off the north wall row.
func _floor_piece(i: int, art: String, near_rug := false) -> bool:
	var r: Rect2i = rooms[i].rect
	var cells: Vector2i = InteriorArt.ART[art].get("cells", Vector2i.ONE)
	var spots: Array[Vector2i] = []
	for y in range(r.position.y + FACE_ROWS + 1, r.end.y - cells.y + 1):
		for x in range(r.position.x, r.end.x - cells.x + 1):
			spots.append(Vector2i(x, y))
	_shuffle(spots)
	if near_rug:
		var center := Vector2(r.get_center()) + Vector2(0, 1.5)
		spots.sort_custom(func(a, b): return Vector2(a).distance_to(center) < Vector2(b).distance_to(center))
	for s in spots:
		if _try(i, art, Rect2i(s, cells)):
			return true
	return false


## A table with chairs round it: front-facing chairs north of it, back-view
## chairs south, side chairs east and west.
func _table_set(i: int, art: String, chairs: int) -> void:
	var r: Rect2i = rooms[i].rect
	var cells: Vector2i = InteriorArt.ART[art].cells
	var spots: Array[Vector2i] = []
	for y in range(r.position.y + FACE_ROWS + 1, r.end.y - cells.y + 1):
		for x in range(r.position.x, r.end.x - cells.x + 1):
			spots.append(Vector2i(x, y))
	var center := Vector2(r.get_center()) + Vector2(0, 1.5)
	spots.sort_custom(func(a, b): return Vector2(a).distance_to(center) < Vector2(b).distance_to(center))
	for s in spots:
		var t := Rect2i(s, cells)
		if not _try(i, art, t):
			continue
		var seats: Array = []
		for dx in range(0, cells.x, 2 if cells.x > 2 else 1):
			seats.append(["chair_front" if style.wood % 2 == 0 else "chair_front_b", Vector2i(t.position.x + dx + (1 if cells.x == 3 else 0), t.position.y - 1), false])
			seats.append(["chair_back" if style.wood % 2 == 0 else "chair_back_b", Vector2i(t.position.x + dx + (1 if cells.x == 3 else 0), t.end.y), false])
		for dy in range(0, cells.y, 2):
			seats.append(["chair_side", Vector2i(t.position.x - 1, t.position.y + dy), true])
			seats.append(["chair_side", Vector2i(t.end.x, t.position.y + dy), false])
		_shuffle(seats)
		var placed := 0
		for s2 in seats:
			if placed >= chairs:
				break
			if _try(i, s2[0], Rect2i(s2[1], Vector2i.ONE), s2[2]):
				placed += 1
		return


func _desk(i: int) -> void:
	var r: Rect2i = rooms[i].rect
	for y in range(r.position.y + FACE_ROWS + 1, r.end.y - 2):
		for x in range(r.position.x, r.end.x - 2):
			var t := Rect2i(x, y, 3, 2)
			if _try(i, _pick(["desk", "desk_b"]), t):
				_try(i, "chair_back" if style.wood % 2 == 0 else "chair_back_b", Rect2i(x + 1, t.end.y, 1, 1))
				return


## A run of counters along the north wall with a sink in it.
func _counters(i: int, length: int) -> void:
	var r: Rect2i = rooms[i].rect
	var y := r.position.y + FACE_ROWS
	length = mini(length, r.size.x)
	var xs := range(r.position.x, r.end.x - length + 1)
	_shuffle(xs)
	for x0: int in xs:
		var ok := true
		for dx in length:
			var c := Vector2i(x0 + dx, y)
			if blocked.has(c) or _keep.has(c) or kind.get(c) != FLOOR:
				ok = false
		if not ok:
			continue
		var kit: Dictionary = InteriorArt.COUNTERS[style.counter]
		var sink_at := _rng.randi_range(0, maxi(0, length - (kit.sink[1] / TILE)))
		var x: int = x0
		while x < x0 + length:
			var part: Array
			if x - x0 == sink_at and x0 + length - x >= kit.sink[1] / TILE:
				part = kit.sink
			else:
				var fits: Array = kit.parts.filter(func(p): return p[1] / TILE <= x0 + length - x)
				part = fits[_rng.randi() % fits.size()]
			var w: int = part[1] / TILE
			var fp := Rect2i(x, y, w, 1)
			for dx in w:
				blocked[Vector2i(x + dx, y)] = true
				pass # counters are low: the wall above them stays free
			items.append({"art": "counter", "rect": Rect2i(part[0], InteriorArt.COUNTER_Y, part[1], InteriorArt.COUNTER_H),
				"pos": Vector2((x + w / 2.0) * TILE, y * TILE + 12), "place": "wall", "cells": fp, "room": i, "flip": false,
				"sink": part == kit.sink, "top": part != kit.sink})
			x += w
		if not _connected():
			for dx in length:
				blocked.erase(Vector2i(x0 + dx, y))
			items = items.filter(func(it): return not (it.art == "counter" and it.room == i))
			continue
		return


func _rug(i: int, size_class: String) -> void:
	var r: Rect2i = rooms[i].rect
	var list: Array = InteriorArt.RUGS[size_class]
	var rect: Rect2i = list[_rng.randi() % list.size()]
	var floor_rect := Rect2i(r.position.x, r.position.y + FACE_ROWS, r.size.x, r.size.y - FACE_ROWS)
	var px := Vector2(floor_rect.get_center()) * TILE + Vector2(_rng.randi_range(-8, 8), 8)
	# Keep it inside the floor.
	var half := Vector2(rect.size) / 2.0
	px.x = clampf(px.x, floor_rect.position.x * TILE + half.x + 2, floor_rect.end.x * TILE - half.x - 2)
	px.y = clampf(px.y, floor_rect.position.y * TILE + half.y + 4, floor_rect.end.y * TILE - half.y - 2)
	if rect.size.x > floor_rect.size.x * TILE - 4 or rect.size.y > floor_rect.size.y * TILE - 6:
		return
	items.append({"art": "rug", "rect": rect, "pos": px.floor() + Vector2(0, half.y), "place": "rug", "room": i, "flip": false})


func _floor_deco(i: int, count: int, arts := ["plant_big", "plant_tall", "plant_leafy", "basket", "floor_lamp_b"]) -> void:
	var r: Rect2i = rooms[i].rect
	var placed := 0
	var corners: Array[Vector2i] = [Vector2i(r.position.x, r.position.y + FACE_ROWS), Vector2i(r.end.x - 1, r.position.y + FACE_ROWS),
		Vector2i(r.position.x, r.end.y - 1), Vector2i(r.end.x - 1, r.end.y - 1)]
	_shuffle(corners)
	for c in corners:
		if placed >= count:
			return
		if _try(i, _pick(arts), Rect2i(c, Vector2i.ONE)):
			placed += 1
	for k in 20:
		if placed >= count:
			return
		var c := Vector2i(_rng.randi_range(r.position.x, r.end.x - 1), r.position.y + FACE_ROWS + (0 if _rng.randf() < 0.6 else _rng.randi_range(1, r.size.y - FACE_ROWS - 1)))
		if _try(i, _pick(arts), Rect2i(c, Vector2i.ONE)):
			placed += 1


## Windows, paintings, vines, and shelves on the room's face, where nothing
## tall stands in front.
func _face_deco(i: int, count: int, arts := []) -> void:
	var r: Rect2i = rooms[i].rect
	if arts.is_empty():
		arts = ["window", "window_b", "window_c", "window_d", "window_e", "window_f", "window_arch", "window_arch_vine", "window_plain",
			"painting", "painting_b", "painting_c", "painting_d", "painting_e", "painting_small", "triptych", "vine", "vine_b", "vine_flower", "hanging_plant", "wall_shelf", "mirror"]
	var has_window := false
	for k in count * 6:
		if count <= 0:
			return
		var art: String = _pick(arts)
		if not has_window and k == 0:
			var windows := arts.filter(func(a): return InteriorArt.ART[a].get("window", false))
			if not windows.is_empty():
				art = _pick(windows)
		var w: int = InteriorArt.ART[art].rect.size.x
		var cells := ceili(w / float(TILE))
		var x := _rng.randi_range(r.position.x, r.end.x - cells)
		var ok := true
		for dx in cells:
			var c := Vector2i(x + dx, r.position.y)
			if _face_used.get(Vector2i(x + dx, r.position.y), false) or kind.get(c) != FACE or kind.get(c + Vector2i(0, 2)) != FACE:
				ok = false
		if not ok:
			continue
		for dx in cells:
			_face_used[Vector2i(x + dx, r.position.y)] = true
		var a: Dictionary = InteriorArt.ART[art]
		var h: int = a.rect.size.y
		var floor_top := (r.position.y + FACE_ROWS) * TILE
		# Tall windows stand on the wall's foot; paintings hang near the middle.
		var bottom: float = floor_top - (2 if h >= 38 else (6 if h >= 30 else 12))
		items.append({"art": art, "pos": Vector2((x + cells / 2.0) * TILE, bottom), "place": "face", "room": i, "flip": false})
		if a.get("window", false):
			has_window = true
		count -= 1


func _top_deco(it: Dictionary) -> void:
	var arts := ["cup", "cup_b", "teapot", "bowl", "fruit", "vase", "vase_b", "vase_c", "potted", "potted_b", "books", "books_b", "lamp", "lamp_b", "lamp_c", "bottles"]
	var t: String = rooms[it.room].type
	if t == "kitchen" or t == "dining" or t == "cottage":
		arts = ["cup", "cup_b", "teapot", "bowl", "fruit", "vase", "bottles", "teapot"]
	elif t == "bedroom" or t == "study":
		arts = ["lamp", "lamp_b", "lamp_c", "books", "books_b", "vase", "potted", "cup"]
	var art: String = _pick(arts)
	var sprite_h: int = it.rect.size.y if it.has("rect") else InteriorArt.ART[it.art].rect.size.y
	var depth: int = it.get("cells", Rect2i(0, 0, 1, 1)).size.y
	# The top surface: the sprite's upper part, a little below its top edge.
	var top_y: float = it.pos.y - sprite_h + (8 if depth > 1 else 6)
	var dx := _rng.randi_range(-6, 6)
	items.append({"art": art, "pos": Vector2(it.pos.x + dx, top_y + 2), "place": "top", "room": it.room, "flip": false, "sort_y": it.pos.y + 0.5})
	it["topped"] = true


## Places `art` on `cells` if the cells are free floor in room `i`, clear of
## the doors, and the home stays connected.
func _try(i: int, art: String, cells: Rect2i, flip := false) -> bool:
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			var c := Vector2i(x, y)
			if kind.get(c) != FLOOR or room_of.get(c) != i or blocked.has(c) or _keep.has(c) or doorway.has(c):
				return false
	for y in range(cells.position.y, cells.end.y):
		for x in range(cells.position.x, cells.end.x):
			blocked[Vector2i(x, y)] = true
	if not _connected():
		for y in range(cells.position.y, cells.end.y):
			for x in range(cells.position.x, cells.end.x):
				blocked.erase(Vector2i(x, y))
		return false
	var a: Dictionary = InteriorArt.ART[art]
	var place: String = a.place
	# Wall pieces stand with their back to the wall: the sprite's foot is a
	# little into the first floor row. Floor pieces stand on their cells.
	var foot_y: float = cells.end.y * TILE - (4 if place == "wall" and cells.size.y == 1 else 2)
	items.append({"art": art, "pos": Vector2((cells.position.x + cells.size.x / 2.0) * TILE, foot_y), "place": place,
		"cells": cells, "room": i, "flip": flip})
	return true


## Every door, the way out, and all open floor stay reachable from the exit.
func _connected() -> bool:
	var seen := {exit_cell: true}
	var queue: Array[Vector2i] = [exit_cell]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + o
			if seen.has(n) or kind.get(n) != FLOOR or blocked.has(n):
				continue
			seen[n] = true
			queue.append(n)
	for d in doors:
		for c in d.cells:
			if not seen.has(c):
				return false
	# Every room keeps some floor you can stand on.
	for i in rooms.size():
		var any := false
		var r: Rect2i = rooms[i].rect
		for y in range(r.position.y + FACE_ROWS, r.end.y):
			for x in range(r.position.x, r.end.x):
				if seen.has(Vector2i(x, y)):
					any = true
		if not any:
			return false
	return true


## Floor cells the walker can reach (for tools and wildlife).
func open_floor() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in kind:
		if kind[c] == FLOOR and not blocked.has(c):
			out.append(c)
	return out


func summary() -> String:
	return "%dx%d, %s, %d items" % [size.x, size.y, ", ".join(notes), items.size()]
