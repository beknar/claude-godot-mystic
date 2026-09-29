class_name MSWeather
extends Node2D
## Mana Seed rain and snow (weather effects: eight 32x128 frames in a row),
## tiled over the camera's view, each layer at its own speed; the pack draws
## the heavy fall behind the light one. Aligned to the world, so the fall
## stays put while the view moves over it.

const FRAME := Vector2(32, 128)

var layers: Array[Dictionary] = [] # {tex: Texture2D, fps: float}; first is drawn first
var _time := 0.0


func _ready() -> void:
	z_index = 40 # over the actors, the canopy, and the fire light


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var view := _view().grow(FRAME.y)
	var x0 := floorf(view.position.x / FRAME.x) * FRAME.x
	var y0 := floorf(view.position.y / FRAME.y) * FRAME.y
	for l in layers:
		var frame := int(_time * l.fps) % 8
		var src := Rect2(Vector2(frame * FRAME.x, 0), FRAME)
		var y := y0
		while y < view.end.y:
			var x := x0
			while x < view.end.x:
				draw_texture_rect_region(l.tex, Rect2(Vector2(x, y), FRAME), src)
				x += FRAME.x
			y += FRAME.y


func _view() -> Rect2:
	var inv := get_viewport().get_canvas_transform().affine_inverse()
	var size := get_viewport_rect().size
	return Rect2(inv * Vector2.ZERO, inv.basis_xform(size))
