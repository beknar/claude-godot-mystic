extends SceneTree
## Headless maze check (maze-greencaves, cave_maze.gd): generates maze maps
## and prints each one's map type, floor, layout attempt, rooms, dead ends,
## clearings, homes, pools, rails, props, fires, the floor notes, and the
## cave checks line, which for a maze includes every maze cell, the exit,
## and every home's entry room reachable from the entrance.
##   godot --headless -s res://tools/check_maze_caves.gd -- [first_id] [count] [recipe]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 440000
	var count := int(args[1]) if args.size() > 1 else CaveMaze.MAZE_RECIPES.size() * 2
	var pinned := int(args[2]) if args.size() > 2 else -1
	var gen := load("res://scripts/cave_terrain.gd")
	var passed := 0
	var per := {}
	for id in range(first, first + count):
		var t = gen.new()
		t.maze = true
		var report: String = t.generate(id, pinned)
		var checks := ""
		var floor_line := ""
		for line in report.split("\n"):
			if line.begins_with("  checks:"):
				checks = line.strip_edges()
			elif line.begins_with("  floor:"):
				floor_line = line.strip_edges()
		var info: Dictionary = t.maze_info
		var rooms: Vector2i = info.get("rooms", Vector2i.ZERO)
		print("%d r%d %s (%s) a%d | rooms %dx%d, dead ends %d, clearings %d, homes %d, pools %d, rails %d, props %d, fires %d | %s | %s" % [
			id, t.recipe_id, t.recipe.name, t.recipe.floor, t.attempt, rooms.x, rooms.y, info.get("dead_ends", 0), info.get("clearings", 0),
			t.homes.size(), t.pools.size(), t.rails.size(), t.props.size(), t.fires.size(), floor_line, checks])
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
