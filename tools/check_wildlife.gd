extends SceneTree
## Headless wildlife check: which species, groups, and animals each map gets.
##   godot --headless -s res://tools/check_wildlife.gd -- <first_id> [count] [recipe]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 20000
	var count := int(args[1]) if args.size() > 1 else 30
	var pinned := int(args[2]) if args.size() > 2 else -1
	var gen := load("res://scripts/forest_terrain.gd")
	var wild := load("res://scripts/wildlife.gd")
	var species := {}
	var animals := 0
	var empty := 0
	for id in range(first, first + count):
		var t = gen.new()
		t.generate(id, pinned)
		var p: Dictionary = wild.plan(t)
		var per := {}
		for g in p.groups:
			var k: String = g.kind
			if not per.has(k):
				per[k] = []
			per[k].append(g.cells.size())
			animals += g.cells.size()
			species[k] = species.get(k, 0) + g.cells.size()
		var parts := PackedStringArray()
		for k in per:
			parts.append("%s %s" % [k, per[k]])
		if per.is_empty():
			empty += 1
		print("%d r%d %s: %s" % [id, t.recipe_id, t.recipe.name, ", ".join(parts) if not parts.is_empty() else "none"])
	var tally := PackedStringArray()
	for k in species:
		tally.append("%s %d" % [k, species[k]])
	print("SUMMARY %d maps, %d animals (%.1f per map), %d with none; %s" % [count, animals, float(animals) / count, empty, ", ".join(tally)])
	quit()
