class_name InteriorView
extends Node2D
## Paints an InteriorPlan with the Cozy Cottage art: floors and wall faces
## on one layer, wall tops on another (composed per cell from quarter-cell
## pieces of the pack's frame, so a top edges every room it touches, with the
## small corner nubs where a room only meets it diagonally), rugs and
## hangings under the actors, furniture as y-sorted actors with colliders on
## their footprint, and door frames over the doorways. Used in place by the
## Green Caves homes (the ring round the home then edges the cave floor with
## the cave's own rock rim) and as the Painted Lands interior sub-map.

const TILE := 16
const WALL_SOURCE := 0
const TOP_SOURCE := 1

var plan: InteriorPlan
var cave_sheet: Texture2D # set for cave homes: the ring's outside edge is cave rock
var actors: Node2D # y-sorted node the furniture joins (defaults to an own one)
var floor_layer: TileMapLayer
var top_layer: TileMapLayer
var rugs: Node2D
var hangings: Node2D
var body: StaticBody2D
## What the ambience needs, in this node's parent space (world pixels when
## the view sits at the map origin): hearth openings, lamp shades, windows
## {rect, floor_y}, steam spots, room floor rects, the way out.
var hearths: Array[Rect2] = []
var lamps: Array[Vector2] = []
var windows: Array[Dictionary] = []
var steam: Array[Vector2] = []
var room_rects: Array[Rect2] = []
var exit_point := Vector2.ZERO
var exit_door: ExitDoor # the way out's door (none in a cave home)

var _walls_img: Image
var _cave_img: Image
var _cave_fill := Color.BLACK
var _top_cache := {} # quadrant key -> atlas coords in the composed source
var _top_img: Image
var _top_source: TileSetAtlasSource
var _tiles: TileSet
var _furn_img: Image


func build(p_plan: InteriorPlan, p_actors: Node2D = null) -> void:
	plan = p_plan
	for c in get_children():
		c.queue_free()
	hearths.clear()
	lamps.clear()
	windows.clear()
	steam.clear()
	room_rects.clear()
	_walls_img = _image(InteriorArt.WALLS)
	if cave_sheet:
		_cave_img = _image(cave_sheet)
		_cave_fill = _cave_img.get_pixel(6 * TILE + 8, 12 * TILE + 8)
	floor_layer = TileMapLayer.new()
	floor_layer.name = "Floor"
	top_layer = TileMapLayer.new()
	top_layer.name = "WallTops"
	rugs = Node2D.new()
	rugs.name = "Rugs"
	hangings = Node2D.new()
	hangings.name = "Hangings"
	body = StaticBody2D.new()
	body.name = "Walls"
	body.collision_mask = 0
	for n in [floor_layer, rugs, hangings, top_layer, body]:
		add_child(n)
	if p_actors:
		actors = p_actors
	else:
		actors = Node2D.new()
		actors.name = "Actors"
		actors.y_sort_enabled = true
		add_child(actors)
	_build_tileset()
	_paint_cells()
	_paint_items()
	_build_collision()
	for r in plan.rooms:
		var rr: Rect2i = r.rect
		room_rects.append(Rect2(position + Vector2(rr.position.x, rr.position.y + InteriorPlan.FACE_ROWS) * TILE,
			Vector2(rr.size.x, rr.size.y - InteriorPlan.FACE_ROWS) * TILE))
	exit_point = position + Vector2(plan.exit_cell * TILE) + Vector2(8, 8)
	# The way out: a wooden door in the front wall (exit_door.gd), under the
	# actors. Cave homes open on an arch instead.
	exit_door = null
	if not cave_sheet:
		exit_door = ExitDoor.new()
		exit_door.name = "ExitDoor"
		exit_door.position = Vector2(plan.exit_cell * TILE)
		exit_door.set_wood(DOOR_WOOD)
		add_child(exit_door)
		if actors.get_parent() == self:
			move_child(exit_door, actors.get_index())


const DOOR_WOOD := Color(0.56, 0.38, 0.26) # the pack's mid furniture brown


func _image(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _build_tileset() -> void:
	_tiles = TileSet.new()
	_tiles.tile_size = Vector2i(TILE, TILE)
	var walls := TileSetAtlasSource.new()
	walls.texture = InteriorArt.WALLS
	walls.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(walls, WALL_SOURCE)
	_top_img = Image.create(16 * TILE, 16 * TILE, false, Image.FORMAT_RGBA8)
	_top_cache.clear()
	floor_layer.tile_set = _tiles
	top_layer.tile_set = _tiles


func _put(layer: TileMapLayer, cell: Vector2i, atlas: Vector2i) -> void:
	var src: TileSetAtlasSource = _tiles.get_source(WALL_SOURCE)
	if not src.has_tile(atlas):
		src.create_tile(atlas)
	layer.set_cell(cell, WALL_SOURCE, atlas)


# ---------------------------------------------------------------- cells

func _paint_cells() -> void:
	var trim: int = plan.style.trim
	var row0: int = InteriorArt.GROUP_ROW[trim]
	var top_cells: Array[Vector2i] = []
	for c in plan.kind:
		var k: int = plan.kind[c]
		if k == InteriorPlan.WALL:
			top_cells.append(c)
			continue
		var room: Dictionary = plan.rooms[plan.room_of.get(c, 0)]
		if k == InteriorPlan.FACE:
			_put(floor_layer, c, Vector2i(room.paper, row0 + 1 + plan.face_row[c]))
		else:
			_put(floor_layer, c, _floor_tile(room.floor, c))
	for c in plan.doorway:
		# The door frame over the floor that runs through the face.
		var x0: int = c.x
		for d in plan.doors:
			if c.x in d.cells.map(func(v): return v.x) and d.dir == "h":
				x0 = d.cells[0].x
		var src := Rect2(Vector2((InteriorArt.DOORWAY[trim] + c.x - x0) * TILE, (row0 + 1 + plan.doorway[c]) * TILE), Vector2(TILE, TILE))
		hangings.add_child(_sprite(InteriorArt.WALLS, src, Vector2(c * TILE), false, false))
	# Wall tops: compose the quarter pieces, then one tile per distinct cell.
	var tops := {}
	for c in top_cells:
		tops[c] = _top_tile(c)
	var tex := ImageTexture.create_from_image(_top_img)
	_top_source = TileSetAtlasSource.new()
	_top_source.texture = tex
	_top_source.texture_region_size = Vector2i(TILE, TILE)
	_tiles.add_source(_top_source, TOP_SOURCE)
	for key in _top_cache:
		_top_source.create_tile(_top_cache[key])
	for c in tops:
		top_layer.set_cell(c, TOP_SOURCE, tops[c])


func _floor_tile(fl: Dictionary, c: Vector2i) -> Vector2i:
	match fl.kind:
		"planks":
			return fl.origin + Vector2i(posmod(c.x, 2), posmod(c.y, 4))
		"parquet":
			return fl.origin + Vector2i(posmod(c.x, 2), posmod(c.y, 2))
	return Vector2i(fl.column, 21 + posmod(c.y, 3))


const ROOM := 1
const OUTSIDE := 2
const SOLID := 0

func _class(c: Vector2i) -> int:
	var k = plan.kind.get(c)
	if k == InteriorPlan.FACE or k == InteriorPlan.FLOOR:
		return ROOM
	if k == null:
		return OUTSIDE if cave_sheet else SOLID
	return SOLID


# The atlas cell for a wall top at `c`, composed from four quarters.
func _top_tile(c: Vector2i) -> Vector2i:
	var parts: Array = []
	for q in 4:
		var vy := -1 if q < 2 else 1
		var hx := -1 if q % 2 == 0 else 1
		var cv := _class(c + Vector2i(0, vy))
		var ch := _class(c + Vector2i(hx, 0))
		var cd := _class(c + Vector2i(hx, vy))
		parts.append(_quarter(q, vy, hx, cv, ch, cd))
	var key := str(parts)
	if not _top_cache.has(key):
		var n := _top_cache.size()
		var at := Vector2i(n % 16, n / 16)
		_top_cache[key] = at
		for q in 4:
			var p: Array = parts[q]
			var img: Image = _walls_img if p[0] == "c" else _cave_img
			var tile: Vector2i = p[1]
			var qo := Vector2i((q % 2) * 8, (q / 2) * 8)
			for y in 8:
				for x in 8:
					var col := img.get_pixel(tile.x * TILE + qo.x + x, tile.y * TILE + qo.y + y)
					if p[0] == "c" and (col.a < 0.5 or (col.r < 0.02 and col.g < 0.02 and col.b < 0.02)):
						# The black-filled frames are see-through inside: fill with
						# the cave rock's color, or black round an interior.
						col = _cave_fill if cave_sheet else Color.BLACK
					_top_img.set_pixel(at.x * TILE + qo.x + x, at.y * TILE + qo.y + y, col)
	return _top_cache[key]


# [sheet, tile] for one quarter of a wall top: the pack's frame edged toward
# a room, the cave rim edged toward the cave floor, a nub where a room only
# touches the diagonal, or plain fill.
func _quarter(q: int, vy: int, hx: int, cv: int, ch: int, cd: int) -> Array:
	var f: Vector2i = InteriorArt.frame(plan.style.trim, plan.style.black)
	if cv == ROOM or ch == ROOM:
		return ["c", f + _role(vy, hx, cv == ROOM, ch == ROOM)]
	if cave_sheet and (cv == OUTSIDE or ch == OUTSIDE):
		return ["k", Vector2i(5, 11) + _role(vy, hx, cv == OUTSIDE, ch == OUTSIDE)]
	if cd == ROOM:
		var nub := {Vector2i(-1, -1): Vector2i(4, 1), Vector2i(1, -1): Vector2i(3, 1), Vector2i(-1, 1): Vector2i(4, 0), Vector2i(1, 1): Vector2i(3, 0)}
		return ["c", f + nub[Vector2i(hx, vy)]]
	if cave_sheet and cd == OUTSIDE:
		return ["k", Vector2i(6, 12)]
	return ["c", f + Vector2i(1, 1)]


# Offset in a 3x3 frame for an edge toward the vertical neighbor, the
# horizontal one, or both.
func _role(vy: int, hx: int, v: bool, h: bool) -> Vector2i:
	var col := 1
	var row := 1
	if h:
		col = 0 if hx < 0 else 2
	if v:
		row = 0 if vy < 0 else 2
	return Vector2i(col, row)


# ---------------------------------------------------------------- items

func _paint_items() -> void:
	var wood: int = plan.style.wood
	for it in plan.items:
		var tex: Texture2D
		var rect: Rect2i
		if it.art == "rug":
			tex = InteriorArt.DECORATION
			rect = it.rect
		elif it.art == "counter":
			tex = InteriorArt.FURNITURE
			rect = it.rect
			rect.position.y += wood * InteriorArt.WOOD_STEP
		else:
			tex = InteriorArt.sheet_of(it.art)
			rect = InteriorArt.rect_of(it.art, wood)
		var foot: Vector2 = it.pos
		var off := Vector2(-rect.size.x / 2.0, -rect.size.y).floor()
		match it.place:
			"rug":
				rugs.add_child(_sprite(tex, Rect2(rect), foot + off, it.flip, false))
				continue
			"face":
				hangings.add_child(_sprite(tex, Rect2(rect), foot + off, it.flip, false))
				var a: Dictionary = InteriorArt.ART[it.art]
				if a.get("window", false):
					windows.append({"rect": Rect2(position + foot + off, Vector2(rect.size)),
						"floor_y": position.y + (plan.rooms[it.room].rect.position.y + InteriorPlan.FACE_ROWS) * TILE})
				continue
		# Actors: y-sorted at the foot (items on a table sort just in front of it).
		var node := Node2D.new()
		var base := Vector2.ZERO if actors.get_parent() == self else position
		node.position = base + Vector2(foot.x, it.get("sort_y", foot.y))
		var spr := _sprite(tex, Rect2(rect), off + Vector2(0, foot.y - it.get("sort_y", foot.y)), it.flip, false)
		node.add_child(spr)
		actors.add_child(node)
		var a2: Dictionary = InteriorArt.ART.get(it.art, {})
		if a2.has("hearth"):
			var h: Rect2i = a2.hearth
			hearths.append(Rect2(position + foot + off + Vector2(h.position), Vector2(h.size)))
		if a2.has("lamp"):
			lamps.append(position + foot + off + Vector2(a2.lamp))
		if a2.get("steam", false):
			steam.append(position + foot + off + Vector2(rect.size.x / 2.0, 0))


func _sprite(tex: Texture2D, region: Rect2, at: Vector2, flip: bool, centered: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = region
	s.centered = centered
	s.offset = at
	s.flip_h = flip
	return s


# ---------------------------------------------------------------- collision

func _build_collision() -> void:
	# Wall tops and faces block as whole cells, one box per horizontal run.
	for y in plan.size.y:
		var x := 0
		while x < plan.size.x:
			if not _solid(Vector2i(x, y)):
				x += 1
				continue
			var start := x
			while x < plan.size.x and _solid(Vector2i(x, y)):
				x += 1
			_box(Rect2(start * TILE, y * TILE, (x - start) * TILE, TILE))
	# Furniture: its footprint, a little inset so the walker can brush past.
	for c in plan.blocked:
		_box(Rect2(Vector2(c * TILE) + Vector2(1, 3), Vector2(TILE - 2, TILE - 4)))


func _solid(c: Vector2i) -> bool:
	var k = plan.kind.get(c)
	return k == InteriorPlan.WALL or k == InteriorPlan.FACE


func _box(r: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = r.size
	var node := CollisionShape2D.new()
	node.shape = shape
	node.position = r.get_center()
	body.add_child(node)
