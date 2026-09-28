extends SceneTree
## Headless weights for the Green Caves liveliness proxy, for the effects
## the Painted Lands capture never saw:
##   cave_life.gd - drips, warm motes, pale motes, glints, and bats, each
##     simulated alone in camera-sized views on a few maps for a few minutes
##     of game time, compared every 1/8 s the way the capture compares frames
##     (a pixel moves when its color over the floor changes by more than
##     8/255 in any channel); the weight is motion per unit of the feature
##     scripts/cave_liveliness_features.gd gives the view;
##   water_anim - the pool tiles' own frames, straight from the sheet: the
##     share of a tile's pixels that differ between one frame and the next,
##     times the chance two samples 1/8 s apart straddle a frame change.
## Prints WEIGHTS lines; tools/liveliness_coef_caves.json holds the result.
##   godot --headless -s res://tools/sim_cave.gd

const Terrain := preload("res://scripts/cave_terrain.gd")
const Features := preload("res://scripts/cave_liveliness_features.gd")
const Painter := preload("res://scripts/caves.gd")
const WindScript := preload("res://scripts/wind.gd")
const LifeScript := preload("res://scripts/cave_life.gd")
const SHEET := preload("res://assets/pack/green_caves/green_caves_tileset.png")
const MAPS := [130021, 130023, 130025, 130026, 130027, 130022]
const VIEWS := [Vector2i(0, 0), Vector2i(17, 11), Vector2i(0, 22)]
const VIEW := Vector2i(43, 18)
const SECONDS := 120.0
const DT := 1.0 / 60.0
const FLOORS := {"light": Color(0.78, 0.77, 0.76), "dark": Color(0.64, 0.63, 0.63), "moss": Color(0.72, 0.75, 0.68)}
const PARTS := {"drips": "drips", "warm": "warm", "pale": "motes", "glints": "glints", "bats": "bats"} # part -> feature

var _floor := Color.WHITE


func _initialize() -> void:
	var motion := {}
	var feature := {}
	for p in PARTS:
		motion[p] = 0.0
		feature[p] = 0.0
	var tile_use := {}
	var sparkle_use := {}
	var sheet := SHEET.get_image()
	if sheet.is_compressed():
		sheet.decompress()
	for id in MAPS:
		var t = Terrain.new()
		t.generate(id)
		_floor = FLOORS[t.recipe.floor]
		for c in t.anim:
			var a: Vector2i = t.features[c]
			tile_use[a] = tile_use.get(a, 0) + 1
		for c in t.sparkles:
			var a: Vector2i = t.sparkles[c]
			sparkle_use[a] = sparkle_use.get(a, 0) + 1
		var g: Dictionary = Features.grid(t)
		var lights: Array[Vector2] = []
		var glinters: Array = []
		for prop in t.props:
			var art: Dictionary = Terrain.PROPS[prop.art]
			var foot: Vector2 = Painter.foot_of(prop)
			if art.tag == "fire" or art.tag == "torch":
				lights.append(foot + (Vector2(0, -10) if art.tag == "torch" else Vector2(0, -8)))
			elif art.tag == "crystal" or art.tag == "ore":
				glinters.append(_bright(sheet, art.region, foot - Vector2(art.foot)))
		var line := PackedStringArray()
		for v in VIEWS:
			var view := Rect2(Vector2(v * 16), Vector2(VIEW * 16))
			for p in PARTS:
				var wind: Node = WindScript.new()
				root.add_child(wind)
				var life: Node2D = LifeScript.new()
				life.wind = wind
				life.view_override = view
				life.visible = false
				life.parts = [p]
				root.add_child(life)
				life.setup(t.drip_spots(), lights, glinters)
				var m := _measure(wind, life, view)
				var f := 0.0
				var a: PackedFloat32Array = g[PARTS[p]]
				for y in range(v.y, v.y + VIEW.y):
					for x in range(v.x, v.x + VIEW.x):
						f += a[y * Features.W + x]
				f /= VIEW.x * VIEW.y
				motion[p] += m
				feature[p] += f
				line.append("%s %.4f%%" % [p, m])
				wind.queue_free()
				life.queue_free()
			print("map %d r%d %s view %s: %s" % [id, t.recipe_id, t.recipe.name, v, ", ".join(line)])
			line.clear()
	var out := PackedStringArray()
	for p in PARTS:
		out.append("%s %.5f" % [PARTS[p], motion[p] / maxf(feature[p], 1e-6)])
	print("WEIGHTS " + ", ".join(out))
	# Pool tiles and sparkles: frame-to-frame change straight from the sheet
	# (sparkles over the open water's color).
	var straddle := minf(1.0, (1.0 / 8.0) / Painter.WATER_FRAME)
	var water := _tile_change(sheet, tile_use)
	var sparkle := _tile_change(sheet, sparkle_use)
	print("WEIGHTS water_anim %.5f, sparkles %.5f (tiles change %.0f%% and %.0f%% of pixels per frame step)" % [
		water * straddle * 100.0, sparkle * straddle * 100.0, water * 100.0, sparkle * 100.0])
	quit()


# Mean share of a tile's pixels that change from one frame to the next,
# weighted by how often each tile is used.
func _tile_change(sheet: Image, use: Dictionary) -> float:
	var under := sheet.get_pixelv(Terrain.OPEN_WATER * 16 + Vector2i(8, 8))
	var changed := 0.0
	var uses := 0.0
	for a in use:
		var anim: Dictionary = Painter.animation_for(a)
		var frac := 0.0
		for k in 4:
			var f0 := _frame(a, anim, k)
			var f1 := _frame(a, anim, (k + 1) % 4)
			var n := 0
			for y in 16:
				for x in 16:
					var c0 := sheet.get_pixelv(f0 * 16 + Vector2i(x, y))
					var c1 := sheet.get_pixelv(f1 * 16 + Vector2i(x, y))
					c0 = under.lerp(Color(c0, 1.0), c0.a)
					c1 = under.lerp(Color(c1, 1.0), c1.a)
					if maxf(maxf(absf(c0.r - c1.r), absf(c0.g - c1.g)), absf(c0.b - c1.b)) > 8.0 / 255.0:
						n += 1
			frac += n / 256.0 / 4.0
		changed += frac * use[a]
		uses += use[a]
	return changed / maxf(uses, 1.0)


func _frame(a: Vector2i, anim: Dictionary, k: int) -> Vector2i:
	var sep: Vector2i = anim.separation
	if anim.columns == 1:
		return a + Vector2i(0, k * (1 + sep.y))
	return a + Vector2i(k * (1 + sep.x), 0)


func _bright(sheet: Image, region: Rect2i, top_left: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y in region.size.y:
		for x in region.size.x:
			var p := sheet.get_pixel(region.position.x + x, region.position.y + y)
			if p.a > 0.5 and p.get_luminance() > 0.62:
				out.append(Vector2i(top_left) + Vector2i(x, y))
	return out


func _measure(wind: Node, life: Node, view: Rect2) -> float:
	var frames := int(SECONDS / DT)
	var every := int(round(1.0 / 8.0 / DT))
	var last := {}
	var total := 0.0
	var samples := 0
	for i in frames:
		wind._process(DT)
		life._process(DT)
		if i % every != 0:
			continue
		var now := {}
		var px: Dictionary = life.pixels()
		for p in px:
			if view.has_point(Vector2(p)):
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
	var ca: Color = _floor if a == null else _floor.lerp(Color(a.r, a.g, a.b), a.a)
	var cb: Color = _floor if b == null else _floor.lerp(Color(b.r, b.g, b.b), b.a)
	return maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b)) > 8.0 / 255.0
