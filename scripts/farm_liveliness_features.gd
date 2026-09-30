extends RefCounted
## Liveliness proxy for the farm randomizer (FarmTerrain): the same features
## as the Painted Lands proxy (scripts/liveliness_features.gd), worked out
## from the generated farm alone, so tools/liveliness.gd can estimate farm
## maps with the Painted Lands weights (tools/liveliness_coef.json). They are
## not refitted on farm captures: the windmill, the rustling trees, the fish,
## and the snow have no feature of their own, so the estimate runs low where
## they are (the slow capture measures them).
##
##   leaves      leaf fall from each leafy tree's crown to the ground under it
##   water_anim  animated water and shore tiles
##   rings       ripple and fish rings on open water
##   reeds       nodding reeds, wheat bunches, and crop tops
##   butterflies flowers (and flowering crops); none in winter
##   dragonflies ponds; none in winter
##   fireflies   dark and deep grass; none in winter
##   streak, cloud, drift   anywhere (drift none in winter)
##   flames, glow, smoke   the farmsteads' campfires and lanterns, and the
##               chimneys of the Forest houses (as liveliness_features.gd)
##   animals     sprite pixels of the map's animals over their home ranges
##   grass       grass waves on grass and wheat cells; none in winter

const Base := preload("res://scripts/liveliness_features.gd")
const Wild := preload("res://scripts/wildlife.gd")
const TILE := 16
const W := 64
const H := 40
const NAMES := Base.NAMES


static func grid(t) -> Dictionary:
	var g := {}
	for n in NAMES:
		var a := PackedFloat32Array()
		a.resize(W * H)
		a.fill(0.0)
		g[n] = a
	var winter: bool = t.season == "winter"
	g.streak.fill(1.0)
	g.cloud.fill(1.0)
	if not winter:
		g.drift.fill(1.0)
		var waves: Dictionary = t.grass_cells()
		waves.merge(t.wheat_cells())
		for c in waves:
			g.grass[c.y * W + c.x] = 1.0
	# Leaves: each leafy tree's crown (about 64 x 48 px over its trunk) sheds
	# onto the ground below it; bare and dead trees shed nothing.
	for tr in t.trees:
		var art := FarmTiles.tree_art(t.season, tr.art)
		if art.ends_with("dead") or art.ends_with("bare") or (winter and art in ["apple", "cherry", "orange", "peach"]):
			continue
		var foot := Vector2(tr.cell * TILE) + Vector2(8, 15)
		_spread(g.leaves, Rect2(foot + Vector2(-26, -62), Vector2(52, 72)), 1.0)
	for c in t.canopy:
		_spread(g.leaves, Rect2(c.x * TILE, TILE, 4 * TILE, 3 * TILE + 18.0), 1.0)
	# Water: every water and shore tile animates; rings on open water.
	for y in H:
		for x in W:
			var k: String = t.shore_key(Vector2i(x, y))
			if k != "" and k != "?":
				g.water_anim[y * W + x] += 1.0
	var open: Array[Vector2i] = t.open_water()
	if not open.is_empty():
		var n := float(open.size())
		var per := (0.45 * maxf(1.0, n / 40.0) + (0.0 if winter else 2.0 / 8.5)) / n
		for c in open:
			g.rings[c.y * W + c.x] += per
	# Nodding plants: reeds, wheat bunches, and the tops of stalked crops.
	for p in t.props:
		var tag: String = FarmTiles.prop(t.season, p.art).get("tag", "")
		if tag == "reed" or tag == "plant":
			g.reeds[p.cell.y * W + p.cell.x] += 1.0
	for cr in t.crops:
		if cr.crop in FarmTiles.CROPS_NOD:
			g.reeds[cr.cell.y * W + cr.cell.x] += 1.0
	if not winter:
		for r in t.ponds:
			var rect := Rect2(Vector2(r.position) * TILE + Vector2(16, 16), Vector2(r.size) * TILE - Vector2(32, 32))
			_spread(g.dragonflies, rect, 2.0 if rect.get_area() > 4000.0 else 1.0)
		var flowers: Array[Vector2i] = []
		for c in t.deco:
			if t.deco[c] in t.flowers_set:
				flowers.append(c)
		for cr in t.crops:
			if cr.crop in ["sunflower", "strawberry", "pumpkin", "tomato", "berry"] and (cr.cell.x + cr.cell.y) % 3 == 0:
				flowers.append(cr.cell)
		if not flowers.is_empty():
			var bf := PackedFloat32Array()
			bf.resize(W * H)
			bf.fill(0.0)
			var each := clampi(flowers.size() / 10, 3, 8) / float(flowers.size())
			for c in flowers:
				bf[c.y * W + c.x] += each
			g.butterflies = _blur(bf, 2)
		var dark: Array = t.zone_cells().keys().filter(func(c): return (c.x * 7 + c.y * 3) % 7 == 0)
		for c in t.firefly_spots:
			for k in 5:
				dark.append(c)
		if not dark.is_empty():
			var each := clampi(dark.size() / 25, 0, 14) / float(dark.size())
			for c in dark:
				g.fireflies[c.y * W + c.x] += each
	# Fires (the farmsteads): flames, the glow's inner half, and smoke over
	# each campfire and chimney, as the Painted Lands proxy works them out.
	for p in t.props:
		var art: Dictionary = FarmTiles.prop(t.season, p.art)
		if not art.has("fire"):
			continue
		var torch: bool = art.fire == "torch"
		var foot := Vector2(p.cell * TILE) + Vector2(8, 15)
		var size := Vector2(art.rect.size)
		_spread(g.flames, Rect2(foot - Vector2(art.base), size), 1.0)
		var flame := foot + (Vector2(0, -24) if torch else Vector2(0, -8))
		var r := 22 if torch else (40 if art.fire == "campfire" else 52)
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				if Vector2(x, y * 1.25).length() / r < 0.55:
					_spread(g.glow, Rect2(flame + Vector2(x, y), Vector2.ONE), 1.0 / (TILE * TILE))
		if not torch:
			_spread(g.smoke, Rect2(flame + Vector2(-8, -45), Vector2(16, 45)), 1.0)
	for b in t.buildings:
		var bart: Dictionary = FarmTiles.BUILDINGS[b.kind]
		if bart.has("chimney"):
			var vent := Vector2(b.origin * TILE) + Vector2(bart.chimney)
			_spread(g.smoke, Rect2(vent + Vector2(-8, -45), Vector2(16, 45)), Base.CHIMNEY_SMOKE)
	# Animals: the farm's own plan (mode "farmland"), sprite sizes from the
	# Cozy Farm sheets.
	var before: String = Base.animals
	Base.animals = "farmland"
	var plan: Dictionary = t.wildlife_plan("farmland")
	for grp in plan.groups:
		var spec: Dictionary = Wild.table_for("farmland")[grp.kind]
		var home := Vector2(grp.center * TILE) + Vector2(8, 8)
		var r: float = minf(spec.home, 80.0)
		_spread(g.animals, Rect2(home - Vector2(r, r), Vector2(r, r) * 2.0), Base.sprite_area(grp.kind) * grp.cells.size())
	Base.animals = before
	return g


static func block(g: Dictionary, rect: Rect2i) -> Dictionary:
	var out := {}
	for n in NAMES:
		var a: PackedFloat32Array = g[n]
		var s := 0.0
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				s += a[y * W + x]
		out[n] = s / rect.get_area()
	return out


static func _spread(a: PackedFloat32Array, rect: Rect2, total: float) -> void:
	var area := rect.get_area()
	if area <= 0.0:
		return
	for y in range(floori(rect.position.y / TILE), floori((rect.end.y - 0.01) / TILE) + 1):
		for x in range(floori(rect.position.x / TILE), floori((rect.end.x - 0.01) / TILE) + 1):
			if x < 0 or y < 0 or x >= W or y >= H:
				continue
			var part := rect.intersection(Rect2(x * TILE, y * TILE, TILE, TILE)).get_area()
			a[y * W + x] += total * part / area


static func _blur(a: PackedFloat32Array, r: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(W * H)
	out.fill(0.0)
	var k := float((2 * r + 1) * (2 * r + 1))
	for y in H:
		for x in W:
			var v := a[y * W + x]
			if v == 0.0:
				continue
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					out[clampi(y + dy, 0, H - 1) * W + clampi(x + dx, 0, W - 1)] += v / k
	return out
