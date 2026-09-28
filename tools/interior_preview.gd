extends Node2D
## Interior preview: generated homes of one to six rooms side by side, to
## check layouts and art by eye (and headless, their summaries).
##   godot --path . res://tools/interior_preview.tscn [-- <first_seed> [zoom] [rooms...]]

const TILE := 16

var first := 5000
var zoom := 1.6
var counts: Array[int] = [1, 2, 3, 4, 5, 6]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		first = int(args[0])
	if args.size() > 1:
		zoom = float(args[1])
	if args.size() > 2:
		counts.clear()
		for a in args.slice(2):
			counts.append(int(a))
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(6000, 3000)
	bg.position = Vector2(-100, -100)
	add_child(bg)
	var x := 0
	var y := 0
	var row_h := 0
	for k in counts.size():
		var plan := InteriorPlan.new().generate(first + k, counts[k])
		print("seed %d: %s" % [first + k, plan.summary()])
		var view := InteriorView.new()
		view.position = Vector2(x, y) * TILE
		add_child(view)
		view.build(plan)
		x += plan.size.x + 2
		row_h = maxi(row_h, plan.size.y)
		if x > 60:
			x = 0
			y += row_h + 2
			row_h = 0
	var cam := Camera2D.new()
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	cam.position = Vector2(-16, -16)
	cam.zoom = Vector2(zoom, zoom)
	add_child(cam)
	cam.make_current()
