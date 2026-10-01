extends SceneTree
## Headless maze check (maze-forest, forest_maze.gd): generates maze maps and
## prints each one's map type, layout attempt, rooms, dead ends, clearings,
## and the Painted Lands checks line, which for a maze includes: every maze
## cell and the exit reachable from the entrance, every hedge cell blocking,
## every path cell tiled, the homes the type names standing.
##   godot --headless -s res://tools/check_maze.gd -- [first_id] [count] [recipe]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 400000
	var count := int(args[1]) if args.size() > 1 else ForestMaze.MAZE_RECIPES.size() * 2
	var pinned := int(args[2]) if args.size() > 2 else -1
	var gen := load("res://scripts/forest_terrain.gd")
	var passed := 0
	var per := {}
	for id in range(first, first + count):
		var t = gen.new()
		t.maze = true
		var report: String = t.generate(id, pinned)
		var checks := ""
		for line in report.split("\n"):
			if line.begins_with("  checks:"):
				checks = line.strip_edges()
		var info: Dictionary = t.maze_info
		var rooms: Vector2i = info.get("rooms", Vector2i.ZERO)
		print("%d r%d %s a%d | rooms %dx%d, dead ends %d, clearings %d, houses %d, bridges %d, props %d | %s" % [id, t.recipe_id, t.recipe.name, t.attempt,
			rooms.x, rooms.y, info.get("dead_ends", 0), info.get("clearings", 0), t.houses.size(), t.bridges.size(), t.props.size(), checks])
		var ok := checks == "checks: ok"
		if ok:
			passed += 1
		var e: Array = per.get(t.recipe.name, [0, 0])
		per[t.recipe.name] = [e[0] + (1 if ok else 0), e[1] + 1]
	var bad := PackedStringArray()
	for k in per:
		if per[k][0] < per[k][1]:
			bad.append("%s %d/%d" % [k, per[k][0], per[k][1]])
	print("SUMMARY passed %d/%d; failing: %s" % [passed, count, ", ".join(bad) if not bad.is_empty() else "none"])
	quit()
