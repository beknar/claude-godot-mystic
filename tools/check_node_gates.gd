extends SceneTree
## Headless node-gates check: for every ring 0-33, generates the map of a few
## nodes the way node_gates.gd does (the ring's map type, the node's map id,
## the next ids when a gate does not fit) and checks that all four gates are
## there and reachable from the spawn and from each other, that the foe plan
## finds room, that every cell has a ground tile, and the report's checks.
##   godot --headless -s res://tools/check_node_gates.gd -- [seed] [nodes_per_ring]

const RETRIES := 6


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var world := GateWorld.new()
	world.new_game(int(args[0]) if args.size() > 0 else 12345)
	var per_ring := int(args[1]) if args.size() > 1 else 2
	var passed := 0
	var total := 0
	var retried := 0
	var kinds := {}
	for r in GateWorld.MAX_RING + 1:
		var coords: Array[Vector2i] = []
		if r == 0:
			coords.append(Vector2i.ZERO)
		var options: Array[Vector2i] = [Vector2i(0, r), Vector2i(r, 0), Vector2i(0, -r), Vector2i(-r, 0), Vector2i(r, r), Vector2i(-r, r / 2), Vector2i(r / 2, -r)]
		for i in per_ring:
			if r > 0:
				coords.append(options[(i * 3 + r) % options.size()])
		for c in coords:
			total += 1
			var t0 := Time.get_ticks_msec()
			var id := world.map_id_for(c)
			var t: PaintedTerrain
			var tries := 0
			var fails := PackedStringArray()
			for k in RETRIES:
				tries = k + 1
				t = PaintedTerrain.new()
				t.gates = true
				t.generate(id + k * 7919, GateWorld.recipe_for(c))
				fails = _gate_fails(t)
				if fails.is_empty():
					break
			if tries > 1:
				retried += 1
			var report := t._verify()
			var checks := "ok"
			for line in report.split("\n"):
				if line.begins_with("  checks:"):
					checks = line.substr(10)
			for y in PaintedTerrain.HEIGHT:
				for x in PaintedTerrain.WIDTH:
					if not t.lawn.has(Vector2i(x, y)):
						fails.append("cell %d,%d has no ground" % [x, y])
			var room := _foe_room(t)
			var plan := world.foe_plan(c)
			if room < plan.size():
				fails.append("room for %d foes, plan wants %d" % [room, plan.size()])
			for p in plan:
				kinds[p.kind] = kinds.get(p.kind, 0) + 1
			var kinds_of := PackedStringArray()
			for side in ["n", "e", "s", "w"]:
				if t.gate_cells.has(side):
					kinds_of.append("%s %s" % [side, t.gate_cells[side].kind])
			var ok := fails.is_empty() and checks == "ok"
			if ok:
				passed += 1
			print("%s ring %d %s (map %d, try %d): %dms | gates %s | foes %d | %s%s" % [
				GateWorld.node_name(c), r, t.recipe.name, t.map_id, tries, Time.get_ticks_msec() - t0,
				", ".join(kinds_of), plan.size(), "ok" if fails.is_empty() else "; ".join(fails),
				"" if checks == "ok" else " | checks: " + checks])
	print("SUMMARY passed %d/%d, %d needed another map id" % [passed, total, retried])
	print("SUMMARY foes: %s" % kinds)
	print("SUMMARY names: %s %s %s %s %s" % [GateWorld.node_name(Vector2i(0, 1)), GateWorld.node_name(Vector2i(1, 1)),
		GateWorld.node_name(Vector2i(-1, -1)), GateWorld.node_name(Vector2i(1, 2)), GateWorld.node_name(Vector2i(-3, -1))])
	quit()


func _gate_fails(t: PaintedTerrain) -> PackedStringArray:
	var out := PackedStringArray()
	for side in ["n", "e", "s", "w"]:
		if not t.gate_cells.has(side):
			out.append("no %s gate" % side)
			continue
		for k in GateRoads.opening(side, t.gate_cells[side].cell):
			if not t.walkable(k) or not t._reaches(t.spawn, k):
				out.append("%s gate cell %s cut off" % [side, k])
	return out


# Cells with open ground all round that the spawn reaches (foes stand there).
func _foe_room(t: PaintedTerrain) -> int:
	var n := 0
	for y in range(1, PaintedTerrain.HEIGHT - 1):
		for x in range(1, PaintedTerrain.WIDTH - 1):
			var ok := true
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if not t.walkable(Vector2i(x + dx, y + dy)):
						ok = false
			if ok:
				n += 1
	return n
