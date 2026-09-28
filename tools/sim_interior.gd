extends SceneTree
## Headless liveliness of the home interiors (interior_life.gd), measured the
## way the rendered capture measures a view: every 1/8 s the pixels the life
## draws are compared with the previous sample, and a pixel moves when its
## color over the floor changes by more than 8/255. Runs homes of one to six
## rooms, sunny (Painted Lands) and not (caves), for two minutes each, and
## prints per home: motion as % of the home's pixels per frame, split into
## hearth flames, sunbeams, steam and moths, and the cat; the hearth and lamp
## glow (fire_ambience.gd, not simulated here) is added from the calibrated
## glow weight; and per-piece weights for the cave estimate.
##   godot --headless -s res://tools/sim_interior.gd [-- <first_seed> <count>]

const SECONDS := 120.0
const DT := 1.0 / 60.0
const FLOOR := Color(0.47, 0.3, 0.2) # mid planks
const GLOW_WEIGHT := 21.18 # % of a camera window per glow cell (tools/liveliness_coef_caves.json)
const WINDOW_CELLS := 43.0 * 18.0

var _groups := ["flames", "sun", "steam+moths", "cat"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 7000
	var count := int(args[1]) if args.size() > 1 else 12
	var per_piece := {"hearth": [0.0, 0], "window": [0.0, 0], "steam": [0.0, 0], "cat": [0.0, 0]}
	var rows := []
	for k in count:
		var n := (k % 6) + 1
		var sunny := k % 12 < 6 or true
		var plan := InteriorPlan.new().generate(first + k, n)
		var view := InteriorView.new()
		root.add_child(view)
		view.build(plan)
		var life := InteriorLife.new()
		view.add_child(life)
		life.setup([view], view.actors, null, sunny)
		var area := float(plan.size.x * plan.size.y * 256)
		var motion := {}
		for g in _groups:
			motion[g] = 0.0
		var last := {}
		var samples := 0
		var every := int(round(1.0 / 8.0 / DT))
		for i in int(SECONDS / DT):
			life._process(DT)
			for c in life._cats:
				c._process(DT)
			if i % every != 0:
				continue
			var now := {
				"flames": {}, "sun": life.beam_pixels(), "steam+moths": life.overlay_pixels(), "cat": {},
			}
			for h in life._hearths:
				now.flames.merge(life.flame_pixels(h), true)
			for c in life._cats:
				now.cat.merge(c.pixels(), true)
			if samples > 0:
				for g in _groups:
					motion[g] += _moved(now[g], last[g]) / area
			last = now
			samples += 1
		var glow := 0.0
		# The glow's flicker, from the calibrated weight: inner half of the light.
		for r in view.hearths:
			glow += _glow_cells(30) * GLOW_WEIGHT / WINDOW_CELLS
		for l in view.lamps:
			glow += _glow_cells(14) * GLOW_WEIGHT / WINDOW_CELLS
		var parts := PackedStringArray()
		var total := 0.0
		for g in _groups:
			var v: float = motion[g] / maxf(samples - 1, 1) * 100.0
			motion[g] = v
			total += v
			parts.append("%s %.3f%%" % [g, v])
		# Glow is per camera window; scale it to the home's area.
		var glow_home := glow * WINDOW_CELLS / (area / 256.0)
		rows.append({"rooms": n, "local": total, "glow": glow_home})
		print("home %d: %d rooms (%s), %dx%d, hearths %d, lamps %d, windows %d, steam %d, cats %d | %s | glow %.3f%% | total %.3f%%" % [
			first + k, n, ", ".join(plan.rooms.map(func(r): return r.type)), plan.size.x, plan.size.y, view.hearths.size(), view.lamps.size(),
			view.windows.size(), view.steam.size(), life._cats.size(), " ".join(parts), glow_home, total + glow_home])
		# Per piece, in % of a camera window (43 x 18 cells), for the estimate.
		var to_window := area / 256.0 / WINDOW_CELLS
		if view.hearths.size() > 0:
			per_piece.hearth[0] += motion.flames * to_window
			per_piece.hearth[1] += view.hearths.size()
		if view.windows.size() > 0:
			per_piece.window[0] += motion.sun * to_window
			per_piece.window[1] += view.windows.size()
		if view.steam.size() + view.lamps.size() > 0:
			per_piece.steam[0] += motion["steam+moths"] * to_window
			per_piece.steam[1] += view.steam.size() + view.lamps.size()
		if life._cats.size() > 0:
			per_piece.cat[0] += motion.cat * to_window
			per_piece.cat[1] += life._cats.size()
		view.queue_free()
	var mean_local := 0.0
	var mean_all := 0.0
	for r in rows:
		mean_local += r.local
		mean_all += r.local + r.glow
	print("SUMMARY %d homes: interior life %.3f%% of the home per frame, with hearth and lamp glow %.3f%%" % [rows.size(), mean_local / rows.size(), mean_all / rows.size()])
	var w := PackedStringArray()
	for k in per_piece:
		w.append("%s %.4f" % [k, per_piece[k][0] / maxf(per_piece[k][1], 1)])
	print("WEIGHTS (%% of a camera window per piece) " + ", ".join(w))
	quit()


func _glow_cells(radius: int) -> float:
	var n := 0
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if Vector2(x, y * 1.25).length() / radius < 0.55:
				n += 1
	return n / 256.0


func _moved(now: Dictionary, last: Dictionary) -> float:
	var moved := 0
	for p in now:
		if _differs(now[p], last.get(p)):
			moved += 1
	for p in last:
		if not now.has(p) and _differs(null, last[p]):
			moved += 1
	return float(moved)


func _differs(a, b) -> bool:
	var ca: Color = FLOOR if a == null else FLOOR.lerp(Color(a.r, a.g, a.b), a.a)
	var cb: Color = FLOOR if b == null else FLOOR.lerp(Color(b.r, b.g, b.b), b.a)
	return maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) > 8.0 / 255.0
