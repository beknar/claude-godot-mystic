extends SceneTree
## Headless Farm recipe check (randomizer-paintedlands-farm): generates maps
## and prints each one's recipe, buildings, counts, floor notes, and checks
## line (the walker reaches every door, gate, and field; every cell has a
## ground tile and every shore cell a shore tile).
##   godot --headless -s res://tools/check_farm.gd -- <first_id> [count] [recipe]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 190000
	var count := int(args[1]) if args.size() > 1 else 48
	var pinned := int(args[2]) if args.size() > 2 else -1
	var gen = load("res://scripts/farm_terrain.gd")
	if gen == null or not gen.can_instantiate():
		push_error("farm_terrain.gd does not load")
		quit(1)
		return
	var passed := 0
	var per := {}
	for id in range(first, first + count):
		var t = gen.new()
		var report: String = t.generate(id, pinned)
		var checks := ""
		var notes := PackedStringArray()
		for line in report.split("\n"):
			if line.begins_with("  checks:"):
				checks = line.strip_edges()
			elif line.begins_with("  buildings") or line.begins_with("  floor:"):
				notes.append(line.strip_edges())
		print("%d r%d %s a%d | %s | %s" % [id, t.recipe_id, t.recipe.name, t.attempt, " | ".join(notes), checks])
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
