extends RefCounted
## Liveliness proxy: how much of each ambient effect a Painted Lands map
## puts on each cell, worked out from the generated terrain alone (no
## rendering), with the same inputs `forest.gd` hands the effect scripts.
## Every feature is a per-cell density, so a block's feature is the mean of
## its cells. Calibration (tools/liveliness_analyze.py) turns them into
## pixel motion with one weight per feature.
##
##   leaves      share of one tree's leaf fall on this cell (crown to ground)
##   water_anim  animated water tiles
##   rings       ripple and fish rings per second
##   reeds       nodding water plants
##   sparkles    animated sparkles on deep water
##   flames      campfire and torch flipbooks
##   glow        bright part of fire glows, in cells of area
##   smoke       share of one campfire's smoke column (a hearth's column
##               from a house roof counts CHIMNEY_SMOKE of one)
##   butterflies expected butterflies over this cell
##   dragonflies expected dragonflies over this cell
##   fireflies   expected fireflies over this cell
##   streak      wind streaks (spawn anywhere in view: 1 everywhere)
##   cloud       cloud shadows (drift anywhere: 1 everywhere)
##   animals     sprite pixels of the map's animals (wildlife.gd), each
##               spread over its group's home range
##   drift       drifters.gd seeds, pollen, and birds (in view anywhere: 1
##               everywhere)
##   grass       grass_waves.gd light on the grass (1 on grass cells)

const Terrain := preload("res://scripts/forest_terrain.gd")
const Wild := preload("res://scripts/wildlife.gd")
const Waves := preload("res://scripts/grass_waves.gd")
const TILE := 16
const CHIMNEY_SMOKE := 0.6 # fire_ambience.gd CHIMNEY_SMOKE
const W := Terrain.WIDTH
const H := Terrain.HEIGHT
const NAMES := ["leaves", "water_anim", "rings", "reeds", "sparkles", "flames", "glow", "smoke",
	"butterflies", "dragonflies", "fireflies", "streak", "cloud", "animals", "drift", "grass"]


static func grid(t) -> Dictionary:
	var g := {}
	for n in NAMES:
		var a := PackedFloat32Array()
		a.resize(W * H)
		a.fill(0.0)
		g[n] = a
	g.streak.fill(1.0)
	g.cloud.fill(1.0)
	g.drift.fill(1.0)
	for c in Waves.grass_cells(t):
		g.grass[c.y * W + c.x] = 1.0
	# Leaves fall from each crown to the ground under it (and the canopy
	# wall's lower edge sheds too); every source sheds at the same rate.
	for prop in t.props:
		if not prop.has("art"):
			continue
		var art: Dictionary = Terrain.PROPS[prop.art]
		var top_left := Vector2((prop.cell + art.cell) * TILE)
		var size := Vector2(art.region.size * TILE)
		if art.has("splice"): # spliced trees draw their crown lower
			top_left.y += art.splice.y - art.splice.x
		var foot := top_left + Vector2(art.base)
		if prop.art in Terrain.TREES or prop.art in Terrain.SHADE_TREES:
			var crown := Rect2(top_left + Vector2(5, 4), Vector2(size.x - 10, size.y * 0.45))
			_spread(g.leaves, Rect2(crown.position, Vector2(crown.size.x, top_left.y + art.base.y + 10.0 - crown.position.y)), 1.0)
		elif prop.art in Terrain.SHORE_PLANTS:
			_add(g.reeds, top_left, 1.0)
		elif prop.art in Terrain.SPARKLES:
			_add(g.sparkles, top_left, 1.0)
		elif prop.art in Terrain.TORCHES or prop.art in ["campfire", "campfire_big"]:
			var torch: bool = prop.art in Terrain.TORCHES
			_spread(g.flames, Rect2(top_left, size), 1.0)
			var flame := foot + (Vector2(0, -24) if torch else Vector2(0, -8))
			var r := 22 if torch else (40 if prop.art == "campfire" else 52)
			# The glow's inner half, where a flicker step is big enough to see.
			for y in range(-r, r + 1):
				for x in range(-r, r + 1):
					if Vector2(x, y * 1.25).length() / r < 0.55:
						_add(g.glow, flame + Vector2(x, y), 1.0 / (TILE * TILE))
			if not torch:
				_spread(g.smoke, Rect2(flame + Vector2(-8, -45), Vector2(16, 45)), 1.0)
	for h in t.houses:
		if Terrain.CHIMNEYS.has(h.id):
			var vent := Vector2(h.origin * TILE + Terrain.CHIMNEYS[h.id])
			_spread(g.smoke, Rect2(vent + Vector2(-8, -45), Vector2(16, 45)), CHIMNEY_SMOKE)
	var canopy_cols := {}
	for cell in t.canopy:
		canopy_cols[cell.x / 4] = true
	for block in canopy_cols:
		_spread(g.leaves, Rect2(block * 4 * TILE, TILE, 4 * TILE, 3 * TILE + 18.0), 1.0)
	# Water: animated tiles, and rings on open water (cells whose eight
	# neighbors are water) at the ripple rate plus about two rings per jump.
	for cell in t.features:
		if not Terrain.animation_for(t.features[cell]).is_empty():
			g.water_anim[cell.y * W + cell.x] += 1.0
	var open: Array[Vector2i] = []
	for cell in t.water:
		if t._near_all(cell, t.water, 1):
			open.append(cell)
	if not open.is_empty():
		var n := float(open.size())
		var per := (0.45 * maxf(1.0, n / 40.0) + 2.0 / 13.0) / n
		for cell in open:
			g.rings[cell.y * W + cell.x] += per
	for r in t.ponds:
		var rect := Rect2(Vector2(r.position) * TILE + Vector2(8, 8), Vector2(r.size) * TILE - Vector2(16, 16))
		_spread(g.dragonflies, rect, 2.0 if rect.get_area() > 4000.0 else 1.0)
	# Critters: as many as `critters.gd` makes, spread over their homes.
	var flowers: Array[Vector2i] = []
	for cell in t.deco:
		if t._is_flower(t.deco[cell]):
			flowers.append(cell)
	if not flowers.is_empty():
		var bf := PackedFloat32Array()
		bf.resize(W * H)
		bf.fill(0.0)
		var each := clampi(flowers.size() / 10, 3, 8) / float(flowers.size())
		for cell in flowers:
			bf[cell.y * W + cell.x] += each
		g.butterflies = _blur(bf, 2) # they bob and hop between nearby flowers
	var dark: Array[Vector2] = []
	for y in H:
		for x in W:
			var cell := Vector2i(x, y)
			if t._tone_level(cell) >= 1 and not t._solid.has(cell):
				dark.append(Vector2(cell) * TILE + Vector2(8, 0))
	for cell in t.canopy:
		if cell.y == 3 and not t._solid.has(cell + Vector2i(0, 2)):
			dark.append(Vector2(cell) * TILE + Vector2(8, 32))
	if not dark.is_empty():
		var each := clampi(dark.size() / 25, 0, 14) / float(dark.size())
		for p in dark:
			_add(g.fireflies, p, each)
	# Animals: each one's sprite size, spread over its group's home range.
	var plan: Dictionary = Wild.plan(t)
	for grp in plan.groups:
		var spec: Dictionary = Wild.SPECIES[grp.kind]
		var home := Vector2(grp.center * TILE) + Vector2(8, 8)
		var r: float = minf(spec.home, 80.0)
		var total: float = sprite_area(grp.kind) * grp.cells.size()
		_spread(g.animals, Rect2(home - Vector2(r, r), Vector2(r, r) * 2.0), total)
	return g


## Opaque pixels in a species' first idle frame.
static func sprite_area(kind: String) -> float:
	var n := 0
	for row in Wild.SPRITES[kind].idle[0]:
		for ch in row:
			if ch != ".":
				n += 1
	return float(n)


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
	var x := floori(p.x / TILE)
	var y := floori(p.y / TILE)
	if x >= 0 and y >= 0 and x < W and y < H:
		a[y * W + x] += v


# Spreads `total` over `rect` (world pixels) in proportion to the area each
# cell covers.
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
					var xx := clampi(x + dx, 0, W - 1)
					var yy := clampi(y + dy, 0, H - 1)
					out[yy * W + xx] += v / k
	return out
