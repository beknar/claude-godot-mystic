extends SceneTree
## Records which parts of the Mystic Woods pack the randomizer's maps actually
## use: generates maps (every recipe, with the randomizer's extras) and writes
## every sheet region placed to .liveliness/pack_usage.json, for
## tools/pack_usage.py to turn into pixel coverage per sheet.
##   godot --headless -s res://tools/pack_usage.gd -- [count]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var count := int(args[0]) if args.size() > 0 else 1600
	var gen := load("res://scripts/terrain.gd")
	var painter := load("res://scripts/clearing.gd")
	var used := {} # "sheet" -> {"x,y,w,h": true} in pixels
	var add := func(sheet: String, r: Rect2i) -> void:
		if not used.has(sheet):
			used[sheet] = {}
		used[sheet]["%d,%d,%d,%d" % [r.position.x, r.position.y, r.size.x, r.size.y]] = true
	var cell := func(sheet: String, a: Vector2i, size := 16) -> void:
		add.call(sheet, Rect2i(a * size, Vector2i(size, size)))
	for i in count:
		var t = gen.new()
		t.generate(100000 + i, true, -1, true)
		for c in t.features:
			cell.call("tilesets/plains.png", t.features[c])
		add.call("tilesets/grass.png", Rect2i(0, 0, 16, 16))
		for c in t.deco:
			cell.call("tilesets/decor_16x16.png", t.deco[c])
		for c in t.detail:
			cell.call("tilesets/decor_8x8.png", t.detail[c], 8)
		for c in t.water_deco:
			cell.call("tilesets/water_decorations.png", t.water_deco[c])
		for c in t.water_anim:
			for f in 6: # animated: every frame is shown
				var sheet: String = "objects/rock_in_water_01-sheet.png" if t.water_anim[c] == "rock" else "tilesets/water_lillies.png"
				cell.call(sheet, Vector2i(f, 0))
		if not t.ponds.is_empty():
			for f in 6:
				for y in 3:
					for x in 3:
						cell.call("tilesets/water-sheet.png", Vector2i(f * 5 + x, y))
				if not t.islands.is_empty():
					for o in [Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 1), Vector2i(4, 1)]:
						cell.call("tilesets/water-sheet.png", Vector2i(f * 5, 0) + o)
		for d in [t.floors, t.rugs]:
			for c in d:
				var sheet: String = {"wooden": "tilesets/floors/wooden.png", "flooring": "tilesets/floors/flooring.png", "carpet": "tilesets/floors/carpet.png"}[d[c][0]]
				cell.call(sheet, d[c][1])
		for c in t.fence:
			var e: bool = t.fence.has(c + Vector2i.RIGHT)
			var w: bool = t.fence.has(c + Vector2i.LEFT)
			var n: bool = t.fence.has(c + Vector2i.UP)
			var s: bool = t.fence.has(c + Vector2i.DOWN)
			cell.call("tilesets/fences.png", Vector2i(2 if e and w else (1 if e else (3 if w else 0)), 1 if n and s else (0 if s else (2 if n else 3))))
		for p in t.props:
			if painter.PROP_ART.has(p.art):
				add.call("objects/objects.png", painter.PROP_ART[p.art].region)
			elif painter.STRUCTURES.has(p.art):
				var st: Dictionary = painter.STRUCTURES[p.art]
				add.call("tilesets/walls/walls.png", st.top)
				add.call("tilesets/walls/walls.png", st.face)
				if st.door:
					var pick := posmod(p.cell.x * 7 + p.cell.y * 3, 4)
					add.call("tilesets/walls/wooden_door.png" if pick < 2 else "tilesets/walls/wooden_door_b.png", Rect2i((pick % 2) * 16, 0, 16, 16))
			elif p.art in ["chest_iron", "chest_gold"]:
				for f in 4:
					cell.call("objects/chest_01.png" if p.art == "chest_iron" else "objects/chest_02.png", Vector2i(f, 0))
	# The walker's dust puff (footsteps.gd with dust_particles_01.png).
	for f in 3:
		add.call("particles/dust_particles_01.png", Rect2i(f * 16, 0, 16, 12))
	var out := {}
	for k in used:
		out[k] = used[k].keys()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.liveliness"))
	FileAccess.open("res://.liveliness/pack_usage.json", FileAccess.WRITE).store_string(JSON.stringify(out))
	print("pack usage: %d maps, %d sheets touched" % [count, out.size()])
	quit()
