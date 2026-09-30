extends SceneTree
## Headless wildlife check: which species, groups, and animals each map gets.
##   godot --headless -s res://tools/check_wildlife.gd -- <first_id> [count] [recipe] [pack] [caves]
## `pack`: the Cozy Farm animals (wildlife.gd `mode = "pack"`), as
## randomizer-paintedlands and randomizer-greencaves draw them. `caves`:
## Green Caves maps (cave_terrain.gd).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var nums := Array(args).filter(func(a): return a.is_valid_int())
	var first := int(nums[0]) if nums.size() > 0 else 20000
	var count := int(nums[1]) if nums.size() > 1 else 30
	var pinned := int(nums[2]) if nums.size() > 2 else -1
	var caves := "caves" in args
	var mode := "pack" if "pack" in args else ""
	var gen := load("res://scripts/cave_terrain.gd" if caves else "res://scripts/forest_terrain.gd")
	var wild := load("res://scripts/wildlife.gd")
	var species := {}
	var animals := 0
	var empty := 0
	for id in range(first, first + count):
		var t = gen.new()
		t.generate(id, pinned)
		var p: Dictionary = t.wildlife_plan(mode) if caves else (wild.plan(t) if mode == "" else wild.plan_from(wild.habitat_cells(t), t.map_id, t.spawn, wild.quiet_field(t), mode))
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
