extends SceneTree
## Headless Mystic Woods recipe check: generates maps and prints each one's
## recipe, what its set piece placed, and its checks line.
##   godot --headless -s res://tools/check_mystic.gd -- <first_seed> [count] [recipe] [enrich]
## `enrich` turns on the randomizer's extras: detail and the liveliness floor.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 30000
	var count := int(args[1]) if args.size() > 1 else 26
	var pinned := int(args[2]) if args.size() > 2 else -1
	var enrich := "enrich" in args
	var gen := load("res://scripts/terrain.gd")
	var passed := 0
	var per := {}
	for id in range(first, first + count):
		var t = gen.new()
		var report: String = t.generate(id, true, pinned, enrich)
		var checks := ""
		var notes := ""
		for line in report.split("\n"):
			if line.begins_with("  checks:"):
				checks = line.strip_edges()
			if line.begins_with("  ponds "):
				notes = line.strip_edges()
			if line.begins_with("  floor:"):
				notes += " | " + line.strip_edges()
		print("%d r%d %s | %s | %s" % [id, t.recipe_id, t.recipe.name, notes, checks])
		var ok := checks == "checks: ok"
		if ok:
			passed += 1
		var e: Array = per.get(t.recipe.name, [0, 0])
		per[t.recipe.name] = [e[0] + (1 if ok else 0), e[1] + 1]
	var parts := PackedStringArray()
	for k in per:
		parts.append("%s %d/%d" % [k, per[k][0], per[k][1]])
	print("SUMMARY passed %d/%d; %s" % [passed, count, ", ".join(parts)])
	quit()
