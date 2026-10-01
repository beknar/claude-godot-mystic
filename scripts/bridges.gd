class_name Bridges
extends RefCounted
## Bridges for the Painted Lands maps' streams and rivers: 24 designs drawn
## by tools/gen_bridges.py in each sheet's own colors (the packs draw none):
## assets/ai/bridges/bridges_forest.png for the Forest maps,
## bridges_farm.png for the farm in spring, summer, and autumn, and
## bridges_farm_winter.png with snow on every upward surface.
##
## A bridge is built from pieces on the 16 px grid, so it spans any width of
## water. Its deck is two cells wide; it runs
##   across (east-west, over water running north-south): pieces w, m/p...,
##     e; each 16 x 56, the deck at rows 12-43 over the bridge's two cell
##     rows, the back rail above, the deck's face and its supports below. The
##     base (back rail, deck, face, supports) draws under the walker; the
##     front rail over it (y-sorted at the deck's front edge);
##   along (north-south, over water running east-west): pieces n, m/p...,
##     s; each 36 x 16 (the deck two cells wide, its shadow on the water to
##     the east), all under the walker.
## Middle pieces alternate plain and post (`p`: a post, lantern, flowers ...)
## so a long bridge has its posts every other cell.

const DESIGNS := ["plank", "plank_rail", "rope_plank", "boards", "log_deck", "log_rail", "boardwalk", "clapper",
	"stone_arch", "mossy_arch", "lantern_stone", "lattice", "flower_rail", "branch_rail", "trestle", "stone_pier",
	"sandstone", "painted", "rustic", "gate_posts", "mossy_slab", "cobble_curb", "lantern_wood", "felled_log"]
## Designs with lanterns on their posts (their flames glow, fire_ambience.gd).
const LANTERNS := ["lantern_stone", "lantern_wood"]
## The mossy and flowered ones, out of place on snow.
const NOT_WINTER := ["mossy_arch", "flower_rail", "mossy_slab"]
const SHEETS := {
	"forest": "res://assets/ai/bridges/bridges_forest.png",
	"farm": "res://assets/ai/bridges/bridges_farm.png",
	"farm_winter": "res://assets/ai/bridges/bridges_farm_winter.png",
}
const ROW := 56
const TILE := 16
const DECK_TOP := 12 # the deck's top row inside an across piece
const DECK_BOT := 44


static func across_rect(design: int, kind: String, front: bool) -> Rect2i:
	return Rect2i((64 if front else 0) + "wmpe".find(kind) * 16, design * ROW, 16, 56)


static func along_rect(design: int, kind: String) -> Rect2i:
	var k := "nmps".find(kind)
	return Rect2i(128 + (k % 2) * 36, design * ROW + (k / 2) * 16, 36, 16)


## The kinds of a bridge's pieces, end to end: `span` cells, ends at both.
static func kinds(span: int, across: bool) -> Array[String]:
	var out: Array[String] = []
	for k in span:
		if k == 0:
			out.append("w" if across else "n")
		elif k == span - 1:
			out.append("e" if across else "s")
		else:
			out.append("p" if k % 2 == 0 else "m")
	return out


## A design for a map: any of the 24, by `pick` (a random number), skipping
## the mossy and flowered ones in winter.
static func pick_design(pick: int, winter: bool) -> int:
	var ok: Array[int] = []
	for i in DESIGNS.size():
		if winter and DESIGNS[i] in NOT_WINTER:
			continue
		ok.append(i)
	return ok[posmod(pick, ok.size())]


## Builds bridge `b` ({design, origin: the deck's top-left cell, span: cells
## end to end, across: east-west or not}) from `tex`: its base sprites go
## under `under` (drawn below the actors), its front rail into `actors`
## (y-sorted). Returns the lantern flames' positions.
static func build(b: Dictionary, tex: Texture2D, under: Node2D, actors: Node2D) -> Array[Vector2]:
	var lanterns: Array[Vector2] = []
	var design: int = b.design
	var origin: Vector2i = b.origin
	var list := kinds(b.span, b.across)
	var lit: bool = DESIGNS[design] in LANTERNS
	for k in list.size():
		var kind := list[k]
		if b.across:
			var at := Vector2((origin.x + k) * TILE, origin.y * TILE - DECK_TOP)
			under.add_child(_sprite(tex, across_rect(design, kind, false), at))
			var front := Node2D.new()
			front.position = Vector2((origin.x + k) * TILE, (origin.y + 2) * TILE - 1)
			var fs := _sprite(tex, across_rect(design, kind, true), Vector2(0, at.y - front.position.y))
			front.add_child(fs)
			actors.add_child(front)
			if lit and kind == "p":
				lanterns.append(at + Vector2(8, DECK_TOP + 1 - 17))
				lanterns.append(at + Vector2(8, DECK_BOT - 1 - 17))
		else:
			var at := Vector2(origin.x * TILE, (origin.y + k) * TILE)
			under.add_child(_sprite(tex, along_rect(design, kind), at))
			if lit and kind == "p":
				lanterns.append(at + Vector2(2, 6))
				lanterns.append(at + Vector2(29, 6))
	return lanterns


## The deck's cells (walkable over the water).
static func deck_cells(b: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var origin: Vector2i = b.origin
	for k in b.span:
		for w in 2:
			out.append(origin + (Vector2i(k, w) if b.across else Vector2i(w, k)))
	return out


static func _sprite(tex: Texture2D, rect: Rect2i, at: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.region_enabled = true
	s.region_rect = Rect2(rect)
	s.centered = false
	s.position = at
	return s
