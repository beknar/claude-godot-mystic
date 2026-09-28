extends SceneTree
## Headless Green Caves recipe check: generates maps and prints each one's
## recipe, counts, floor notes, and checks line. With `dump`, writes each map
## as JSON to user://caves/<id>.json for a quick offline render.
##   godot --headless -s res://tools/check_caves.gd -- <first_seed> [count] [recipe] [dump]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 130000
	var count := int(args[1]) if args.size() > 1 else 30
	var pinned := int(args[2]) if args.size() > 2 else -1
	var dump := "dump" in args
	var gen := load("res://scripts/cave_terrain.gd")
	var passed := 0
	var per := {}
	if dump:
		DirAccess.make_dir_recursive_absolute("user://caves")
	for id in range(first, first + count):
		var t = gen.new()
		var report: String = t.generate(id, pinned)
		var checks := ""
		var notes := PackedStringArray()
		for line in report.split("\n"):
			if line.begins_with("  checks:"):
				checks = line.strip_edges()
			elif line.begins_with("  pools ") or line.begins_with("  floor:"):
				notes.append(line.strip_edges())
		print("%d r%d %s a%d | %s | %s" % [id, t.recipe_id, t.recipe.name, t.attempt, " | ".join(notes), checks])
		var ok := checks == "checks: ok"
		if ok:
			passed += 1
		var e: Array = per.get(t.recipe.name, [0, 0])
		per[t.recipe.name] = [e[0] + (1 if ok else 0), e[1] + 1]
		if dump:
			_dump(t)
	var bad := PackedStringArray()
	for k in per:
		if per[k][0] < per[k][1]:
			bad.append("%s %d/%d" % [k, per[k][0], per[k][1]])
	print("SUMMARY passed %d/%d; failing: %s" % [passed, count, ", ".join(bad) if not bad.is_empty() else "none"])
	quit()


func _dump(t) -> void:
	var cells := func(d: Dictionary) -> Array:
		var out := []
		for c in d:
			var v = d[c]
			out.append([c.x, c.y, v.x, v.y] if v is Vector2i else [c.x, c.y])
		return out
	var props := []
	for p in t.props:
		props.append([p.art, p.cell.x, p.cell.y])
	var data := {"id": t.map_id, "recipe": t.recipe.name, "floor": cells.call(t.floor_tiles), "zone": cells.call(t.zone_tiles),
		"features": cells.call(t.features), "deco": cells.call(t.deco), "props": props,
		"spawn": [t.spawn.x, t.spawn.y], "goal": [t.goal.x, t.goal.y], "blocked": cells.call(t.blocked)}
	var f := FileAccess.open("user://caves/%d.json" % t.map_id, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
