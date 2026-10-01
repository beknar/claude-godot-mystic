class_name ExitDoor
extends Node2D
## The way out of an interior: a door in the front (south) wall, seen from
## above as the room is, that swings open outward as the walker comes up to
## it and shuts behind it (house_interiors.gd sets `open`; it stands open
## when the walker has just come in). Drawn in whole pixels:
##   closed  the leaf lies across the doorway in the wall's line: planks in
##           the room's woodwork colors, a lit top edge, a latch, the jambs
##           either side;
##   opening it turns on its hinge (the left jamb) out through the doorway in
##           three steps until it lies along the jamb, and daylight falls in
##           through the gap: the doorway lit, a dithered fan of light on the
##           floor just inside.
## The node sits at the doorway's top-left corner (the inner face of the
## front wall); the doorway is `width` px wide and opens downward.

const ANGLES := [0.0, 32.0, 62.0, 90.0] # degrees, closed .. open
const STEP := 0.06
const THICK := 4
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const DAY := Color(1.0, 0.95, 0.8)

var width := 16
var depth := 16 # how far the doorway runs out below the wall line (lit when open)
var wood := Color(0.55, 0.36, 0.24)
var wood_light := Color(0.72, 0.52, 0.34)
var wood_dark := Color(0.3, 0.18, 0.14)
var jambs := true
## The doorstep outside (planks out into the dark under the doorway), for
## interiors whose floor plan has none of its own (the Cozy Cottage homes
## draw theirs as floor).
var stub := false
var stub_wood := Color(0.47, 0.32, 0.23)
var open := false
var step := 0
var _t := 0.0


func _ready() -> void:
	queue_redraw() # (placed just before the actors: over the floor and walls, under the walker)


## The room's woodwork: `trim` the wall trim's color.
func set_wood(trim: Color) -> void:
	wood = trim
	wood_light = trim.lightened(0.28)
	wood_dark = trim.darkened(0.45)


func _process(delta: float) -> void:
	var target := ANGLES.size() - 1 if open else 0
	if step == target:
		_t = 0.0
		return
	_t += delta
	if _t >= STEP:
		_t = 0.0
		step += 1 if target > step else -1
		queue_redraw()


## Straight to open (the walker has just come in through it).
func snap_open() -> void:
	open = true
	step = ANGLES.size() - 1
	queue_redraw()


## Whether a point (the walker's feet, in this node's space) is at the door:
## just inside it, in the doorway, or on its way out.
func near(p: Vector2) -> bool:
	return p.x > -6.0 and p.x < width + 6.0 and p.y > -24.0 and p.y < depth + 6.0


func _draw() -> void:
	var k := float(step) / (ANGLES.size() - 1)
	if stub:
		for y in range(THICK, depth):
			for x in width:
				var c := stub_wood
				if (y - THICK) % 4 == 3:
					c = stub_wood.darkened(0.3) # plank seams
				elif (y - THICK) % 4 == 0:
					c = stub_wood.lightened(0.12)
				if x == 0 or x == width - 1:
					c = stub_wood.darkened(0.45) # its edges
				draw_rect(Rect2(x, y, 1, 1), c)
	if step > 0:
		# Daylight through the gap: the doorway, and a fan on the floor inside.
		draw_rect(Rect2(0, 0, width, depth), Color(DAY, 0.16 * k))
		for y in range(1, 22):
			var half := width / 2.0 + y * 0.45
			var a := (1.0 - y / 22.0) * k
			for x in range(int(width / 2.0 - half), int(width / 2.0 + half) + 1):
				var edge := minf(x - (width / 2.0 - half), (width / 2.0 + half) - x) / 3.0
				if BAYER[(posmod(-y, 4)) * 4 + posmod(x, 4)] / 16.0 < a * clampf(edge, 0.3, 1.0) * 0.75:
					draw_rect(Rect2(x, -y, 1, 1), Color(DAY, 0.2))
	if jambs:
		for jx in [-2, width]:
			draw_rect(Rect2(jx, -1, 2, THICK + 2), wood_dark)
			draw_rect(Rect2(jx, -1, 2, 1), wood_light)
	# The leaf, turned about its hinge (the outer corner of the left jamb):
	# every pixel whose centre falls inside it, shaded across its thickness
	# (the face toward the room lit).
	var ang := deg_to_rad(ANGLES[step])
	var hinge := Vector2(0, THICK)
	var d := Vector2(cos(ang), sin(ang)) # along the leaf
	var n := Vector2(sin(ang), -cos(ang)) # across it, toward the room's face
	var reach := width + THICK
	for y in range(-1, reach + 1):
		for x in range(-1, reach + 1):
			var c := Vector2(x + 0.5, y + 0.5) - hinge
			var u := c.dot(d)
			var v := THICK - c.dot(n) # 0 at the room's face
			if u < 0.0 or u >= width or v < 0.0 or v >= THICK:
				continue
			var col := wood
			if v < 1.0:
				col = wood_light
			elif v >= THICK - 1:
				col = wood_dark
			elif int(u) % 5 == 4:
				col = wood.darkened(0.2) # plank seams
			if int(u) == width - 3 and v >= 1.0 and v < THICK - 1:
				col = Color(0.82, 0.7, 0.42) # the latch
			draw_rect(Rect2(x, y, 1, 1), col)
