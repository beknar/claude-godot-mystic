extends SceneTree
## Headless check of the windmill interior (farm.gd _build_mill): builds the
## mill floor of every windmill on a sweep of farm and farmstead maps and
## prints what stands in it; fails a mill whose open floor the walker cannot
## reach from the way in, or that is missing its machinery, ladder, hoist,
## windows, or (in winter) its hearth.
##   godot --headless -s res://tools/check_mill.gd -- [first_id] [count]
## Every recipe with a windmill (farm and farmsteads, `mixed`), each `count`
## times from `first_id`.

const FARM_SCENE := "res://scenes/randomizer-paintedlands-farm/randomizer-paintedlands-farm.tscn"

var _farm: Node2D
var _passed := 0
var _total := 0


func _initialize() -> void:
	_farm = load(FARM_SCENE).instantiate()
	_farm.set("mixed", true)
	_farm.set("interiors", false)
	root.add_child(_farm)
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 210000
	var count := int(args[1]) if args.size() > 1 else 2
	var recipes: Array = FarmTerrain.all_recipes(true)
	for r in recipes.size():
		if not "windmill" in recipes[r].get("buildings", []):
			continue
		for k in count:
			var id := first + r * 101 + k
			_farm.build(id, r)
			var t = _farm.terrain
			for i in t.buildings.size():
				if t.buildings[i].kind == "windmill":
					_check(id, t, i)
	print("SUMMARY passed %d/%d" % [_passed, _total])
	quit()


func _check(id: int, t, index: int) -> void:
	_total += 1
	var built: Dictionary = _farm._build_mill(index)
	var mv = built.view
	var plan: InteriorPlan = built.plan
	var fails := PackedStringArray()
	if mv.machine == null:
		fails.append("no machinery")
	if mv.hook == null:
		fails.append("no hoist")
	if mv.windows.is_empty():
		fails.append("no window")
	var winter: bool = t.season == "winter"
	if winter and mv.hearths.is_empty():
		fails.append("no hearth in winter")
	var names := {}
	for n in mv.actors.get_children():
		var spr: Node = n.get_child(0) if n.get_child_count() > 0 else null
		if spr is Sprite2D:
			names[str(spr.region_rect)] = true
	# Reach: every open floor cell from the cell inside the way out.
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(Vector2i.ZERO, plan.size)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	var open := []
	for y in plan.size.y:
		for x in plan.size.x:
			var c := Vector2i(x, y)
			var ok: bool = plan.kind.get(c) == InteriorPlan.FLOOR and not plan.blocked.has(c)
			astar.set_point_solid(c, not ok)
			if ok:
				open.append(c)
	var start := plan.exit_cell
	var cut: Array[Vector2i] = []
	for c in open:
		if astar.get_id_path(start, c).is_empty() and c != start:
			cut.append(c)
	if not cut.is_empty():
		fails.append("floor cells cut off: %s" % str(cut))
	var ok := fails.is_empty()
	if ok:
		_passed += 1
	print("%d r%d %s (%s): %d sacks, %d blocked cells, %d open, %d windows, %s | %s" % [id, t.recipe_id, t.recipe.name, t.season,
		mv.sacks.size(), plan.blocked.size(), open.size(), mv.windows.size(), "hearth" if not mv.hearths.is_empty() else "no hearth",
		"ok" if ok else ", ".join(fails)])
	mv.free()
