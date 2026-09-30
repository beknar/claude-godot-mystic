extends SceneTree
## Headless liveliness estimate for Painted Lands maps, from the calibrated
## proxy (tools/liveliness_coef.json, written by liveliness_analyze.py fit).
## Per map: the predicted share of pixels moving per frame (local motion:
## everything but the cloud shadows, which drift anywhere and add about the
## same everywhere) for the whole scene and for every camera-sized window
## (43x18 cells, every cell offset), the weakest and strongest window, the
## spread, and the quiet share (cells below the calibrated quiet level) of
## the weakest window.
##   godot --headless -s res://tools/liveliness.gd -- <first_id> [count] [recipe] [heat] [caves]
## `heat` also prints a map of predicted motion per cell. `caves` estimates
## Green Caves maps (cave_terrain.gd) with tools/liveliness_coef_caves.json.
## Animals as the randomizers draw them: the Cozy Farm pack animals on
## Green Caves maps; add `pack` for them on Painted Lands maps (the wilds
## tables are drawn), `drawn` for the drawn ones, or `cozy` for the
## deprecated cozy farm randomizer.

const PaintedFeatures := preload("res://scripts/liveliness_features.gd")
const PaintedMaps := preload("res://scripts/forest_terrain.gd")
const CaveFeatures := preload("res://scripts/cave_liveliness_features.gd")
const CaveMaps := preload("res://scripts/cave_terrain.gd")
const FarmFeatures := preload("res://scripts/farm_liveliness_features.gd")
const FarmMaps := preload("res://scripts/farm_terrain.gd")
const VIEW := Vector2i(43, 18)
const SHADES := " .:-=+*#%@"


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var first := int(args[0]) if args.size() > 0 else 120000
	var count := int(args[1]) if args.size() > 1 else 10
	var pinned := int(args[2]) if args.size() > 2 else -1
	var heat := "heat" in args
	var caves := "caves" in args
	# `farm`: the farm randomizer's maps with the Painted Lands weights (not
	# refitted; scripts/farm_liveliness_features.gd says what it misses).
	var farm := "farm" in args
	var Features = FarmFeatures if farm else (CaveFeatures if caves else PaintedFeatures)
	if "cozy" in args:
		PaintedFeatures.animals = "farm" # the cozy farm randomizer (its animals; buildings below)
	elif "pack" in args or (caves and not "drawn" in args):
		PaintedFeatures.animals = "pack"
	var Terrain = FarmMaps if farm else (CaveMaps if caves else PaintedMaps)
	var coef = JSON.parse_string(FileAccess.get_file_as_string("res://tools/liveliness_coef_caves.json" if caves else "res://tools/liveliness_coef.json"))
	if coef == null:
		push_error("no tools/liveliness_coef.json: run the capture and liveliness_analyze.py fit first")
		quit(1)
		return
	var weights: Dictionary = coef.weights
	var quiet: float = coef.quiet
	print("liveliness: local motion, %% of pixels per frame; cloud shadows add about %.2f%% anywhere" % float(coef.cloud_background))
	var W: int = Features.W
	var H: int = Features.H
	var scenes: Array[float] = []
	var weakest: Array[float] = []
	for id in range(first, first + count):
		var t = Terrain.new()
		if not caves and "cozy" in args:
			t.cozy = true # the cozy farm randomizer's buildings and map types
		t.generate(id, pinned)
		var g: Dictionary = Features.grid(t)
		var m := PackedFloat32Array()
		m.resize(W * H)
		m.fill(0.0)
		for f in weights:
			var a: PackedFloat32Array = g[f]
			for i in W * H:
				m[i] += weights[f] * a[i]
		var total := 0.0
		for v in m:
			total += v
		# Windows at every cell offset, from a summed-area table.
		var sat := PackedFloat32Array()
		sat.resize((W + 1) * (H + 1))
		sat.fill(0.0)
		var qsat := sat.duplicate()
		for y in H:
			for x in W:
				var i := (y + 1) * (W + 1) + x + 1
				sat[i] = m[y * W + x] + sat[i - 1] + sat[i - W - 1] - sat[i - W - 2]
				qsat[i] = (1.0 if m[y * W + x] < quiet else 0.0) + qsat[i - 1] + qsat[i - W - 1] - qsat[i - W - 2]
		var lo := INF
		var hi := -INF
		var lo_at := Vector2i.ZERO
		var lo_quiet := 0.0
		var n := float(VIEW.x * VIEW.y)
		for y in H - VIEW.y + 1:
			for x in W - VIEW.x + 1:
				var v := _rect_sum(sat, W, x, y) / n
				if v < lo:
					lo = v
					lo_at = Vector2i(x, y)
					lo_quiet = _rect_sum(qsat, W, x, y) / n
				hi = maxf(hi, v)
		var scene := total / (W * H)
		scenes.append(scene)
		weakest.append(lo)
		# Which effects the weakest window has at all.
		var kinds := PackedStringArray()
		for f in weights:
			if f == "streak" or f == "motes" or f == "bats":
				continue
			var s := 0.0
			for y in range(lo_at.y, lo_at.y + VIEW.y):
				for x in range(lo_at.x, lo_at.x + VIEW.x):
					s += weights[f] * g[f][y * W + x]
			if s / n > quiet * 0.1: # at least a tenth of the quiet level, over the window
				kinds.append(f)
		print("%d r%d %s: scene %.2f%% | windows %.2f..%.2f%%, spread %.2f | weakest at (%d,%d): %.0f%% quiet, has %s" % [
			id, t.recipe_id, t.recipe.name, scene, lo, hi, hi - lo, lo_at.x, lo_at.y, lo_quiet * 100.0,
			", ".join(kinds) if not kinds.is_empty() else "only wind streaks"])
		if heat:
			var sorted := m.duplicate()
			sorted.sort()
			var top := sorted[int(sorted.size() * 0.95)] # a few hot cells do not flatten the rest
			for y in H:
				var row := ""
				for x in W:
					var k := clampi(int(sqrt(m[y * W + x] / maxf(top, 1e-6)) * (SHADES.length() - 1) + 0.5), 0, SHADES.length() - 1)
					row += SHADES[k]
				print("  |" + row + "|")
	scenes.sort()
	weakest.sort()
	print("SUMMARY %d maps: scene median %.2f%%, weakest window median %.2f%%, worst %.2f%%" % [
		count, scenes[scenes.size() / 2], weakest[weakest.size() / 2], weakest[0]])
	quit()


func _rect_sum(sat: PackedFloat32Array, W: int, x: int, y: int) -> float:
	var s := W + 1
	return sat[(y + VIEW.y) * s + x + VIEW.x] - sat[y * s + x + VIEW.x] - sat[(y + VIEW.y) * s + x] + sat[y * s + x]
