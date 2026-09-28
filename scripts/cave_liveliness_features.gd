extends RefCounted
## Liveliness proxy for Green Caves maps: how much of each ambient effect a
## map puts on each cell, from the generated terrain alone, with the inputs
## caves.gd hands the effect scripts. Same shape as liveliness_features.gd
## (per-cell densities; weights in tools/liveliness_coef_caves.json):
##
##   leaves      share of one leafy tree's or bush's leaf fall
##   water_anim  animated pool tiles (banks, edges, open water)
##   sparkles    animated sparkles on open water
##   rings       ripple and fish rings per second
##   flames      campfire and torch flipbooks
##   glow        bright part of fire glows, in cells of area
##   smoke       share of one campfire's smoke column
##   butterflies expected moths over this cell (flowering plants)
##   dragonflies expected dragonflies over this cell
##   fireflies   expected glowworms over this cell
##   animals     sprite pixels of the map's animals over their home ranges
##   drips       drip spots landing on this cell (cave_life.gd)
##   warm        share of one flame's warm dust motes
##   glints      crystals and ore that flash
##   motes       pale dust motes (in view anywhere: 1 everywhere)
##   bats        bat flights (in view anywhere: 1 everywhere)

const Terrain := preload("res://scripts/cave_terrain.gd")
const Painter := preload("res://scripts/caves.gd")
const Base := preload("res://scripts/liveliness_features.gd")
const TILE := 16
const W := Terrain.W
const H := Terrain.H
const NAMES := ["leaves", "water_anim", "sparkles", "rings", "flames", "glow", "smoke", "butterflies", "dragonflies",
	"fireflies", "animals", "drips", "warm", "glints", "motes", "bats"]


static func grid(t) -> Dictionary:
	var g := {}
	for n in NAMES:
		var a := PackedFloat32Array()
		a.resize(W * H)
		a.fill(0.0)
		g[n] = a
	g.motes.fill(1.0)
	g.bats.fill(1.0)
	var flowers: Array[Vector2i] = []
	for prop in t.props:
		var art: Dictionary = Terrain.PROPS[prop.art]
		var foot: Vector2 = Painter.foot_of(prop)
		var top_left: Vector2 = foot - Vector2(art.foot)
		match art.tag:
			"fire", "torch":
				var torch: bool = art.tag == "torch"
				_spread(g.flames, Rect2(top_left, Vector2(art.region.size.x / (4 if art.has("frames") else 1), art.region.size.y)), 1.0)
				var flame := foot + (Vector2(0, -10) if torch else Vector2(0, -8))
				var r := 22 if torch else 40
				for y in range(-r, r + 1):
					for x in range(-r, r + 1):
						if Vector2(x, y * 1.25).length() / r < 0.55:
							_add(g.glow, flame + Vector2(x, y), 1.0 / (TILE * TILE))
				if not torch:
					_spread(g.smoke, Rect2(flame + Vector2(-8, -45), Vector2(16, 45)), 1.0)
				_spread(g.warm, Rect2(flame + Vector2(-16, -26), Vector2(32, 30)), 1.0)
			"crystal", "ore":
				_add(g.glints, foot - Vector2(0, 4), 1.0)
			"tree", "bush":
				if prop.art in Painter.LEAFY:
					var crown: Rect2 = Painter.crown_of(prop)
					_spread(g.leaves, Rect2(crown.position, Vector2(crown.size.x, foot.y + 10.0 - crown.position.y)), 1.0)
			"flower":
				flowers.append(prop.cell)
		if prop.art == "rock_tree_crystal":
			_add(g.glints, foot - Vector2(0, 12), 1.0)
	for c in t.anim:
		g.water_anim[c.y * W + c.x] += 1.0
	for c in t.sparkles:
		g.sparkles[c.y * W + c.x] += 1.0
	var open: Array[Vector2i] = t.open_water()
	if not open.is_empty():
		var n := float(open.size())
		var per := (0.45 * maxf(1.0, n / 40.0) + 2.0 / 13.0) / n
		for c in open:
			g.rings[c.y * W + c.x] += per
	for r in t.pools:
		var rect := Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16))
		_spread(g.dragonflies, rect, 2.0 if rect.get_area() > 4000.0 else 1.0)
	for d in t.drip_spots():
		_add(g.drips, d.floor, 1.0) # a splash, or a ring on open water
	if not flowers.is_empty():
		var each := clampi(flowers.size() / 10, 3, 8) / float(flowers.size())
		for c in flowers:
			g.butterflies[c.y * W + c.x] += each
	var dark: Array[Vector2] = t.glow_cells()
	if not dark.is_empty():
		var each := clampi(dark.size() / 25, 0, 14) / float(dark.size())
		for p in dark:
			_add(g.fireflies, p, each)
	var plan: Dictionary = t.wildlife_plan()
	for grp in plan.groups:
		var spec: Dictionary = Wildlife.SPECIES[grp.kind]
		var home := Vector2(grp.center * TILE) + Vector2(8, 8)
		var r: float = minf(spec.home, 80.0)
		_spread(g.animals, Rect2(home - Vector2(r, r), Vector2(r, r) * 2.0), Base.sprite_area(grp.kind) * grp.cells.size())
	return g


static func sprite_area(kind: String) -> float:
	return Base.sprite_area(kind)


## Mean of each feature over the cells of `rect`.
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


static func _add(a: PackedFloat32Array, p: Vector2, v: float) -> void:
	Base._add(a, p, v)


static func _spread(a: PackedFloat32Array, rect: Rect2, total: float) -> void:
	Base._spread(a, rect, total)
