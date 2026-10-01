class_name DoorLeaf
extends Node2D
## A house's front door that swings open as the walker comes up to it and
## shuts again once it has gone (house_interiors.gd sets `open`), drawn over
## the building's doorway in whole pixels as a child of the building's
## sprite (so it sorts and fades with the building).
##
## The leaf turns inward on its hinge: it narrows toward the hinge side in
## three steps, darkening as it turns from the light, its edge (the door's
## thickness) showing, and the dark of the room behind it opens up. Two
## kinds of leaf:
##   pack  the door the building's own sheet draws (the region under it):
##         closed, it is the building as drawn;
##   made  a plank door for a doorway the sheet leaves open (the Painted
##         Lands Forest houses), drawn in the colors of the doorway's own
##         frame (make_leaf), so closed it reads as part of the house.

const WIDTH := [1.0, 0.7, 0.45, 0.25] # leaf width share, closed .. open
const SHADE := [1.0, 0.84, 0.7, 0.58] # the leaf darkens as it turns away
const STEP := 0.055 # seconds per step
const INSIDE := Color(0.13, 0.08, 0.09) # the room behind, unlit from here

var leaf: Texture2D
var size := Vector2i.ZERO
var made := false # a made leaf is drawn closed too (it covers an open doorway)
var hinge_left := true
var edge := Color(0.45, 0.31, 0.22)
var open := false
var step := 0
var _t := 0.0


func _ready() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	var target := WIDTH.size() - 1 if open else 0
	if step == target:
		_t = 0.0
		return
	_t += delta
	if _t >= STEP:
		_t = 0.0
		step += 1 if target > step else -1
		queue_redraw()


## Straight to fully open (the walker stepping out of the house).
func snap_open() -> void:
	open = true
	step = WIDTH.size() - 1
	queue_redraw()


func _draw() -> void:
	if step == 0:
		if made:
			draw_texture(leaf, Vector2.ZERO)
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(size)), INSIDE)
	var w := maxi(1, roundi(size.x * WIDTH[step]))
	var x0 := 0 if hinge_left else size.x - w
	var s: float = SHADE[step]
	draw_texture_rect(leaf, Rect2(x0, 0, w, size.y), false, Color(s, s, s))
	# The door's thickness along its free edge.
	var ex := x0 + w if hinge_left else x0 - 1
	draw_rect(Rect2(ex, 0, 1, size.y), Color(edge.r * s, edge.g * s, edge.b * s))


## A plank leaf `size` for an open doorway at `opening` (px in `img`), in the
## colors of the doorway frame beside it: the darkest for the outline and the
## seams, the middle for the planks, the lightest for the lit edge, the
## braces, and the latch.
static func make_leaf(img: Image, opening: Rect2i) -> Dictionary:
	var cols: Array[Color] = []
	for y in range(opening.position.y, opening.end.y):
		for x in [opening.position.x - 2, opening.position.x - 1, opening.end.x, opening.end.x + 1]:
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				cols.append(c)
	cols.sort_custom(func(a: Color, b: Color) -> bool: return a.get_luminance() < b.get_luminance())
	var dark: Color = cols[0]
	var mid: Color = cols[cols.size() / 2]
	var light: Color = cols[cols.size() - 1]
	if mid.get_luminance() - dark.get_luminance() < 0.04:
		mid = mid.lightened(0.12)
	if light.get_luminance() - mid.get_luminance() < 0.04:
		light = light.lightened(0.15)
	var w := opening.size.x
	var h := opening.size.y
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var c := mid
			if x == 0:
				c = light
			elif x % 3 == 0:
				c = dark
			if y == 0 or y == h - 1:
				c = dark
			elif (y == 2 or y == h - 3) and x > 0:
				c = light.lerp(mid, 0.5) # the braces
			out.set_pixel(x, y, c)
	out.set_pixel(w - 2, h / 2, light) # the latch
	out.set_pixel(w - 2, h / 2 + 1, dark)
	return {"texture": ImageTexture.create_from_image(out), "edge": light.lerp(mid, 0.4)}
