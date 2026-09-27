extends SceneTree
## Headless recipe check: generates Painted Lands maps and prints each
## report's checks line.
##   godot --headless -s res://tools/check_recipes.gd -- <first_id> [count] [recipe]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 20000
	var count := int(args[1]) if args.size() > 1 else 20
	var pinned := int(args[2]) if args.size() > 2 else -1
	var gen := load("res://scripts/forest_terrain.gd")
	var arts := {}
	var stairs := 0
	var plateaus := 0
	var passed := 0
	for id in range(first, first + count):
		var t0 := Time.get_ticks_msec()
		var t = gen.new()
		var report: String = t.generate(id, pinned)
		var lines := report.split("\n")
		var tail := PackedStringArray()
		for line in lines:
			if line.begins_with("  checks:") or line.begins_with("  dropped:") or line.begins_with("  grass tones:") or line.begins_with("  hedgerows") or line.begins_with("  path ") or line.begins_with("  floor:"):
				tail.append(line.strip_edges())
		print("%d r%d %s: %dms, attempt %d | %s" % [id, t.recipe_id, t.recipe.name, Time.get_ticks_msec() - t0, t.attempt, " | ".join(tail)])
		if "checks: ok" in tail:
			passed += 1
		for p in t.props:
			var key: String = "sign" if p.has("sign") else p.art
			arts[key] = arts.get(key, 0) + 1
		if not t.plateau.is_empty():
			plateaus += 1
			if not t.stairs.is_empty():
				stairs += 1
	var keys := arts.keys()
	keys.sort()
	var parts := PackedStringArray()
	for k in keys:
		parts.append("%s %d" % [k, arts[k]])
	print("SUMMARY passed %d/%d; plateaus %d, with stairs %d" % [passed, count, plateaus, stairs])
	print("SUMMARY art: " + ", ".join(parts))
	quit()
