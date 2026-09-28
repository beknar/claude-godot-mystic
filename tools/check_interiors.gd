extends SceneTree
## Headless interior check: builds homes of one to six rooms (interior_plan.gd)
## and checks each: the rooms asked for, every room's floor reachable from the
## way out (furniture never closes a door), a hearth, windows; prints totals
## per room count and how often each room type and art piece is used.
##   godot --headless -s res://tools/check_interiors.gd -- [first_seed] [per_count]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 9000
	var per := int(args[1]) if args.size() > 1 else 100
	var types := {}
	var arts := {}
	var bad := 0
	for n in range(1, 7):
		var ok := 0
		var items := 0
		var hearths := 0
		var windows := 0
		var sizes := Vector2.ZERO
		for k in per:
			var p := InteriorPlan.new().generate(first + n * 1000 + k, n)
			var fails := PackedStringArray()
			if p.rooms.size() != n:
				fails.append("rooms %d" % p.rooms.size())
			# Reach: every room has floor reachable from the way out.
			var seen := {p.exit_cell: true}
			var queue: Array[Vector2i] = [p.exit_cell]
			while not queue.is_empty():
				var c: Vector2i = queue.pop_back()
				for o in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var m: Vector2i = c + o
					if not seen.has(m) and p.kind.get(m) == InteriorPlan.FLOOR and not p.blocked.has(m):
						seen[m] = true
						queue.append(m)
			for i in p.rooms.size():
				var r: Rect2i = p.rooms[i].rect
				var any := false
				for y in range(r.position.y + InteriorPlan.FACE_ROWS, r.end.y):
					for x in range(r.position.x, r.end.x):
						any = any or seen.has(Vector2i(x, y))
				if not any:
					fails.append("room %d (%s) cut off" % [i, p.rooms[i].type])
				types[p.rooms[i].type] = types.get(p.rooms[i].type, 0) + 1
			var has_hearth := false
			for it in p.items:
				arts[it.art] = arts.get(it.art, 0) + 1
				var a: Dictionary = InteriorArt.ART.get(it.art, {})
				if a.has("hearth"):
					has_hearth = true
				if a.get("window", false):
					windows += 1
			if has_hearth:
				hearths += 1
			items += p.items.size()
			sizes += Vector2(p.size)
			if fails.is_empty():
				ok += 1
			else:
				bad += 1
				print("seed %d (%d rooms): %s" % [first + n * 1000 + k, n, "; ".join(fails)])
		print("%d rooms: %d/%d ok, mean size %.1fx%.1f, %.1f items, hearth in %d%%, %.1f windows" % [
			n, ok, per, sizes.x / per, sizes.y / per, float(items) / per, hearths * 100 / per, float(windows) / per])
	var t := PackedStringArray()
	for k in types:
		t.append("%s %d" % [k, types[k]])
	print("room types: " + ", ".join(t))
	var keys := arts.keys()
	keys.sort()
	var a2 := PackedStringArray()
	for k in keys:
		a2.append("%s %d" % [k, arts[k]])
	print("art: " + ", ".join(a2))
	print("SUMMARY %d failing of %d" % [bad, per * 6])
	quit()
