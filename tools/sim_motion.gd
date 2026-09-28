extends SceneTree
## Headless measure of the effects the rendered capture has not calibrated
## yet: drifters.gd and grass_waves.gd. Each is simulated in a camera-sized
## view on a few maps for several minutes of game time, and every 1/8 s the
## pixels it draws are compared with the previous sample the way the capture
## compares frames: a pixel moves when its color over the lawn changes by
## more than 8/255 in any channel. Prints the motion (% of view pixels per
## frame) for each, the grass waves' per grass cell, as weights for
## tools/liveliness_coef.json ("drift" and "grass").
##   godot --headless -s res://tools/sim_motion.gd

const Terrain := preload("res://scripts/forest_terrain.gd")
const WindScript := preload("res://scripts/wind.gd")
const DriftScript := preload("res://scripts/drifters.gd")
const WavesScript := preload("res://scripts/grass_waves.gd")
const MAPS := [120005, 120025, 120006, 120021, 120001]
const VIEWS := [Vector2i(0, 0), Vector2i(17, 11), Vector2i(0, 22)]
const VIEW := Vector2i(43, 18)
const SECONDS := 150.0
const DT := 1.0 / 60.0
const LAWN := Color(0.33, 0.51, 0.31)


func _initialize() -> void:
	var drift_total := 0.0
	var waves_total := 0.0
	var grass_share := 0.0
	var runs := 0
	for id in MAPS:
		var t = Terrain.new()
		t.generate(id, -1)
		var flowers: Array[Vector2] = []
		for c in t.deco:
			if t._is_flower(t.deco[c]):
				flowers.append(Vector2(c) * 16 + Vector2(8, 8))
		var grass: Dictionary = WavesScript.grass_cells(t)
		for v in VIEWS:
			var view := Rect2(Vector2(v * 16), Vector2(VIEW * 16))
			var wind: Node = WindScript.new()
			root.add_child(wind)
			var drift: Node2D = DriftScript.new()
			drift.wind = wind
			drift.view_override = view
			drift.visible = false # measured from pixels(); nothing to render headless
			root.add_child(drift)
			drift.setup(Rect2(0, 0, Terrain.WIDTH * 16, Terrain.HEIGHT * 16), flowers)
			var waves: Node2D = WavesScript.new()
			waves.wind = wind
			waves.view_override = view
			waves.visible = false
			root.add_child(waves)
			waves.setup(grass)
			var d := _measure(wind, [drift], view)
			var w := _measure(wind, [waves], view)
			var in_view := 0
			for y in range(v.y, v.y + VIEW.y):
				for x in range(v.x, v.x + VIEW.x):
					if grass.has(Vector2i(x, y)):
						in_view += 1
			var share := float(in_view) / (VIEW.x * VIEW.y)
			print("map %d view %s: drifters %.4f%%, grass waves %.4f%% (grass %.0f%% of view)" % [id, v, d, w, share * 100.0])
			drift_total += d
			waves_total += w
			grass_share += share
			runs += 1
			for n in [wind, drift, waves]:
				n.queue_free()
	var drift_w := drift_total / runs
	var grass_w := waves_total / maxf(grass_share, 0.001) # per grass cell
	print("WEIGHTS drift %.5f grass %.5f" % [drift_w, grass_w])
	quit()


# Steps the wind and the effects (only one set of effects at a time), and
# averages the share of view pixels that change between 8 fps samples.
func _measure(wind: Node, effects: Array, view: Rect2) -> float:
	var frames := int(SECONDS / DT)
	var every := int(round(1.0 / 8.0 / DT))
	var last := {}
	var total := 0.0
	var samples := 0
	for i in frames:
		wind._process(DT)
		for e in effects:
			e._process(DT)
		if i % every != 0:
			continue
		var now := {}
		for e in effects:
			var px: Dictionary = e.pixels()
			for p in px:
				if view.has_point(Vector2(p)): # only what the camera sees
					now[p] = px[p]
		if samples > 0:
			var moved := 0
			for p in now:
				if _differs(now[p], last.get(p)):
					moved += 1
			for p in last:
				if not now.has(p) and _differs(null, last[p]):
					moved += 1
			total += float(moved) / (view.size.x * view.size.y)
		last = now
		samples += 1
	return total / maxi(samples - 1, 1) * 100.0


func _differs(a, b) -> bool:
	var ca: Color = LAWN if a == null else LAWN.lerp(Color(a.r, a.g, a.b), a.a)
	var cb: Color = LAWN if b == null else LAWN.lerp(Color(b.r, b.g, b.b), b.a)
	return maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) > 8.0 / 255.0
