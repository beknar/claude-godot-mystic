class_name Wildlife
extends Node
## Small animals living on a Painted Lands map, drawn in code as tiny pixel
## sprites (a rabbit is 7 px tall next to the 32 px walker) in colors snapped
## to the tileset's own palette. Each species keeps to its habitat, idles,
## wanders around its home, and answers the walker in its own way:
##   rabbit    lawn, in small groups; hops, freezes, bolts away
##   squirrel  by tree trunks; scampers, sits up, runs up its tree to hide
##   vole      dark grass; darts in short dashes, dives into the grass
##   mouse     by logs, crates, and fences; scurries, slips out of sight
##   hedgehog  by bushes and hedges; waddles, curls into a ball
##   frog      on the shore; sits, hops, jumps into the water with a ring
##   duck      on open water; paddles slowly, paddles off
##   sparrow   flocks on the lawn near paths and houses; peck, then the
##             whole flock flies off and lands somewhere else
##   lizard    on plateau tops, rocks, and ridges; basks, darts to cover
##   fox       rare, one per map; trots over a wide range, lopes away
## Which species live on a map, how many groups, how big, and where are
## decided by `plan()` from the map id, so every generated map has its own
## population, and the same map always has the same one.

const TILE := 16
const W := PaintedTerrain.WIDTH
const H := PaintedTerrain.HEIGHT
const SHADOW := Color(0.05, 0.14, 0.12, 0.3)
const RIPPLE := Color(0.93, 0.97, 1.0, 0.8)

# Sprites face right; the bottom row stands on the ground line. Letters are
# palette keys, "." is empty. Colors are snapped to the sheet at setup.
const SPRITES := {
	"rabbit": {
		"palette": {"B": Color(0.64, 0.54, 0.44), "D": Color(0.46, 0.37, 0.3), "W": Color(0.95, 0.93, 0.88), "K": Color(0.16, 0.12, 0.12), "P": Color(0.86, 0.62, 0.62)},
		"idle": [[".....DB.", ".....BP.", "....BBBB", ".BBBBBKB", "WBBBBBB.", ".DBBBBD.", "..DD.DD."],
			["....DB..", "....BP..", "....BBBB", ".BBBBBKB", "WBBBBBB.", ".DBBBBD.", "..DD.DD."]],
		"move": [[".......DB", ".......BP", "......BBB", "WBBBBBBKB", ".DBBBBBB.", "DD....D.."],
			[".....DB.", ".....BP.", "....BBBB", ".BBBBBKB", "WBBBBBB.", ".DBBBBD.", "..DD.DD."]],
	},
	"squirrel": {
		"palette": {"R": Color(0.74, 0.4, 0.2), "D": Color(0.52, 0.26, 0.14), "W": Color(0.93, 0.84, 0.7), "K": Color(0.16, 0.1, 0.08)},
		"idle": [["RR......", "RRD..R..", ".RR.RRR.", ".DR.RKR.", ".DRRRRW.", "..DRRW..", "..DDRD.."],
			[".RR.....", "RRD..R..", ".RR.RRR.", ".DR.RKR.", ".DRRRRW.", "..DRRW..", "..DDRD.."]],
		"move": [["RR......", "DRR...R.", ".DRRRRRK", "..RRRRWR", "...D..D."],
			[".RR.....", "DRR...R.", "..RRRRRK", "..RRRRWR", "..D....D"]],
	},
	"vole": {
		"palette": {"V": Color(0.44, 0.34, 0.27), "D": Color(0.3, 0.23, 0.18), "K": Color(0.12, 0.09, 0.08), "P": Color(0.82, 0.62, 0.56)},
		"idle": [[".VVV.", "VVVKV", "DVVVP"], [".VVV.", "VVVVK", "DVVVP"]],
		"move": [["..VVV.", "DVVVKP", ".D.D.."], ["..VVV.", "DVVVKP", "..D.D."]],
	},
	"mouse": {
		"palette": {"M": Color(0.68, 0.62, 0.55), "D": Color(0.5, 0.45, 0.4), "K": Color(0.12, 0.1, 0.1), "P": Color(0.88, 0.68, 0.66), "T": Color(0.78, 0.62, 0.58)},
		"idle": [["....PM..", "T...MMMK", ".TTDMMM."], ["....PM..", "....MMMK", "TTTDMMM."]],
		"move": [["....PM..", "TT.MMMMK", "..T.D.D."], ["....PM..", ".TTMMMMK", "T...D..D"]],
	},
	"hedgehog": {
		"palette": {"S": Color(0.42, 0.35, 0.28), "s": Color(0.66, 0.58, 0.46), "F": Color(0.8, 0.68, 0.54), "K": Color(0.12, 0.1, 0.1), "D": Color(0.3, 0.24, 0.2)},
		"idle": [[".sSsS..", "sSsSsSF", "SsSsSFK", ".D..D.."], [".sSsS..", "sSsSsS.", "SsSsSFF", ".D..D.K"]],
		"move": [[".sSsS..", "sSsSsSF", "SsSsSFK", ".D..D.."], [".sSsS..", "sSsSsSF", "SsSsSFK", "..D..D."]],
		"curl": [[".sSs.", "sSsSs", "SsSsS", ".SsS."]],
	},
	"frog": {
		"palette": {"G": Color(0.62, 0.76, 0.3), "D": Color(0.2, 0.33, 0.18), "Y": Color(0.9, 0.86, 0.5), "K": Color(0.1, 0.12, 0.08)},
		"idle": [["..DKG", ".DGGG", "DDGYD"], ["..DKG", ".DGGY", "DDGYD"]],
		"move": [["....KG", "GGGGGG", "D....D"], ["...KG", ".GGGG", "DDGYD"]],
	},
	"duck": {
		"palette": {"H": Color(0.2, 0.45, 0.36), "W": Color(0.95, 0.95, 0.92), "B": Color(0.62, 0.54, 0.44), "D": Color(0.4, 0.34, 0.28), "Y": Color(0.92, 0.74, 0.3), "K": Color(0.1, 0.1, 0.1)},
		"idle": [[".....HH.", ".....HKY", ".....W..", "DBBBBBB.", ".DBBBB.."], [".....HH.", ".....HKY", "D....W..", ".BBBBBB.", ".DBBBB.."]],
		"move": [[".....HH.", ".....HKY", ".....W..", "DBBBBBB.", ".DBBBB.."], [".....HH.", ".....HKY", "D....W..", ".BBBBBB.", ".DBBBB.."]],
	},
	"sparrow": {
		"palette": {"B": Color(0.56, 0.43, 0.31), "D": Color(0.36, 0.28, 0.21), "W": Color(0.86, 0.8, 0.7), "K": Color(0.1, 0.08, 0.06), "Y": Color(0.72, 0.62, 0.42)},
		"idle": [["..BB.", "D.BKY", "DBBW.", "..D.."], [".....", "DBB..", "DBBBK", "..DY."]],
		"move": [["..BB.", "D.BKY", "DBBW.", "..D.."], ["..BB.", "D.BKY", "DBBW.", ".D.D."]],
		"fly": [[".B.B.", "DBBBK", "..W.."], [".....", "DBBBK", "B.W.B"]],
	},
	"lizard": {
		"palette": {"L": Color(0.56, 0.56, 0.33), "D": Color(0.38, 0.38, 0.22), "K": Color(0.1, 0.1, 0.06)},
		"idle": [["......LK", "DDLLLLLL", "...D..D."], ["D.....LK", ".DLLLLLL", "...D..D."]],
		"move": [["......LK", "DLLLLLLL", "..D..D.."], ["......LK", "DDLLLLLL", "....D..D"]],
	},
	"fox": {
		"palette": {"O": Color(0.82, 0.46, 0.2), "D": Color(0.55, 0.28, 0.14), "W": Color(0.95, 0.92, 0.86), "K": Color(0.16, 0.1, 0.1)},
		"idle": [[".........D.D", ".........OOO", "........OOKO", "OO.....OOOWK", "WOOOOOOOOW..", ".OOOOOOOO...", "..D.D..D.D.."],
			["........D..D", ".........OOO", "........OOKO", "OO.....OOOWK", "WOOOOOOOOW..", ".OOOOOOOO...", "..D.D..D.D.."]],
		"move": [[".........D.D", ".........OOO", "........OOKO", "OO.....OOOWK", "WOOOOOOOOW..", ".OOOOOOOO...", "..D.D..D.D.."],
			[".........D.D", ".........OOO", "........OOKO", "OO.....OOOWK", "WOOOOOOOOW..", ".OOOOOOOO...", "...DD...DD.."]],
	},
}
# end sprites

# habitat, groups per map (min, max), animals per group (min, max), speeds
# in px/s, scare radius and home range in px, how it moves ("walk", "hop",
# "dart"), what it does when scared, idle seconds, animation fps.
const SPECIES := {
	"rabbit": {"habitat": "lawn", "groups": Vector2i(1, 2), "size": Vector2i(2, 4), "speed": 18.0, "flee": 70.0, "scare": 44.0, "home": 56.0, "gait": "hop", "react": "run", "idle": Vector2(1.5, 4.0), "fps": 8.0},
	"squirrel": {"habitat": "trees", "groups": Vector2i(1, 3), "size": Vector2i(1, 2), "speed": 26.0, "flee": 60.0, "scare": 40.0, "home": 48.0, "gait": "dart", "react": "climb", "idle": Vector2(1.0, 3.0), "fps": 10.0},
	"vole": {"habitat": "dark", "groups": Vector2i(1, 3), "size": Vector2i(2, 3), "speed": 20.0, "flee": 45.0, "scare": 30.0, "home": 32.0, "gait": "dart", "react": "hide", "idle": Vector2(0.8, 2.5), "fps": 12.0},
	"mouse": {"habitat": "clutter", "groups": Vector2i(1, 2), "size": Vector2i(1, 3), "speed": 22.0, "flee": 50.0, "scare": 30.0, "home": 28.0, "gait": "dart", "react": "hide", "idle": Vector2(0.8, 2.5), "fps": 12.0},
	"hedgehog": {"habitat": "bushes", "groups": Vector2i(1, 2), "size": Vector2i(1, 1), "speed": 7.0, "flee": 0.0, "scare": 32.0, "home": 40.0, "gait": "walk", "react": "curl", "idle": Vector2(2.0, 5.0), "fps": 4.0},
	"frog": {"habitat": "shore", "groups": Vector2i(1, 3), "size": Vector2i(2, 4), "speed": 16.0, "flee": 40.0, "scare": 30.0, "home": 24.0, "gait": "hop", "react": "dive", "idle": Vector2(2.5, 6.0), "fps": 8.0},
	"duck": {"habitat": "water", "groups": Vector2i(1, 2), "size": Vector2i(1, 3), "speed": 6.0, "flee": 22.0, "scare": 50.0, "home": 60.0, "gait": "walk", "react": "paddle", "idle": Vector2(2.0, 5.0), "fps": 3.0},
	"sparrow": {"habitat": "open", "groups": Vector2i(1, 2), "size": Vector2i(3, 6), "speed": 10.0, "flee": 70.0, "scare": 40.0, "home": 30.0, "gait": "hop", "react": "fly", "idle": Vector2(0.6, 2.0), "fps": 8.0},
	"lizard": {"habitat": "rocky", "groups": Vector2i(1, 3), "size": Vector2i(1, 2), "speed": 30.0, "flee": 70.0, "scare": 28.0, "home": 24.0, "gait": "dart", "react": "hide", "idle": Vector2(2.0, 6.0), "fps": 12.0},
	"fox": {"habitat": "roam", "groups": Vector2i(1, 1), "size": Vector2i(1, 1), "speed": 20.0, "flee": 55.0, "scare": 64.0, "home": 140.0, "gait": "walk", "react": "run", "idle": Vector2(2.0, 5.0), "fps": 8.0},
}
# The cozy farm table (randomizer-painted-cozyfarm, `cozy = true`): the
# larger animals drawn from the Cozy Farm art pack's sheets (4 frames x 5
# rows: walk down, walk up, walk left, walk right, sleep), the tiny ones and
# the birds kept as drawn above. Squirrel, hedgehog, and fox have no pack
# counterpart and give way to the farm animals. Farm animals amble a short
# way from the walker instead of bolting, and doze now and then.
const COZY_DIR := "res://assets/pack/cozy_farm/animals/"
const COZY_SHEETS := {
	"bunny": {"cell": 17, "files": ["bunny_animations", "bunny_grey animation"], "baby": {"cell": 16, "files": ["bunny_baby animation", "bunny_baby_grey animation"]}},
	"chicken": {"cell": 16, "files": ["chicken animation", "chicken_brown animation"], "baby": {"cell": 16, "files": ["chicken_baby animation"]}},
	"turkey": {"cell": 17, "files": ["turkey animation"]},
	"sheep": {"cell": 17, "files": ["sheep animation"], "baby": {"cell": 16, "files": ["sheep_baby animation"]}},
	"goat": {"cell": 19, "files": ["goat animation", "goat_stripe animation"], "baby": {"cell": 16, "files": ["goat_baby animation", "goat_baby_stripe animation"]}},
	"pig": {"cell": 20, "files": ["pig animation", "pig_stripe animation"], "baby": {"cell": 16, "files": ["pig_baby animation", "pig_baby_stripe animation"]}},
	"cow": {"cell": 24, "files": ["cow animation", "cow_black animation", "cow_brown animation"], "baby": {"cell": 21, "files": ["cow_baby animation", "cow_baby_black animation", "cow_baby_brown animation"]}},
}
const COZY_SPECIES := {
	"bunny": {"habitat": "lawn", "groups": Vector2i(1, 2), "size": Vector2i(2, 4), "speed": 18.0, "flee": 70.0, "scare": 44.0, "home": 56.0, "gait": "hop", "react": "run", "idle": Vector2(1.5, 4.0), "fps": 8.0},
	"chicken": {"habitat": "open", "groups": Vector2i(1, 2), "size": Vector2i(3, 6), "speed": 9.0, "flee": 34.0, "scare": 26.0, "home": 40.0, "gait": "walk", "react": "amble", "idle": Vector2(0.8, 2.5), "fps": 5.0},
	"turkey": {"habitat": "open", "groups": Vector2i(1, 1), "size": Vector2i(2, 3), "speed": 8.0, "flee": 28.0, "scare": 28.0, "home": 44.0, "gait": "walk", "react": "amble", "idle": Vector2(1.5, 4.0), "fps": 5.0, "sleep": 0.1},
	"sheep": {"habitat": "lawn", "groups": Vector2i(1, 2), "size": Vector2i(3, 5), "speed": 7.0, "flee": 20.0, "scare": 30.0, "home": 60.0, "gait": "walk", "react": "amble", "idle": Vector2(2.0, 5.0), "fps": 5.0, "sleep": 0.2},
	"goat": {"habitat": "lawn", "groups": Vector2i(1, 2), "size": Vector2i(2, 4), "speed": 10.0, "flee": 26.0, "scare": 28.0, "home": 56.0, "gait": "walk", "react": "amble", "idle": Vector2(1.5, 4.0), "fps": 5.0, "sleep": 0.12},
	"pig": {"habitat": "clutter", "groups": Vector2i(1, 1), "size": Vector2i(1, 3), "speed": 7.0, "flee": 20.0, "scare": 26.0, "home": 44.0, "gait": "walk", "react": "amble", "idle": Vector2(2.0, 5.0), "fps": 5.0, "sleep": 0.25},
	"cow": {"habitat": "lawn", "groups": Vector2i(1, 1), "size": Vector2i(2, 3), "speed": 6.0, "flee": 16.0, "scare": 34.0, "home": 72.0, "gait": "walk", "react": "amble", "idle": Vector2(2.5, 6.0), "fps": 4.0, "sleep": 0.18},
	"vole": SPECIES.vole, "mouse": SPECIES.mouse, "frog": SPECIES.frog, "duck": SPECIES.duck, "sparrow": SPECIES.sparrow, "lizard": SPECIES.lizard,
}
const COZY_PER_MAP := Vector2i(6, 9)
const COZY_FARM := ["chicken", "turkey", "sheep", "goat", "pig", "cow"]
const FOX_CHANCE := 0.35
const SPECIES_PER_MAP := Vector2i(4, 7)
const MIN_HABITAT := 6 # cells a species needs before it can live on a map
const GROUP_GAP := 8 # cells between two groups of one species
const QUIET_TRIES := 6 # candidate spots a group compares before settling
const QUIET_CAP := 14.0 # cells; farther than this from any motion counts the same

static var _sheet_colors := {} # sheet instance id -> Array[Color]

var walker: Node2D
var water_life: WaterLife
## The cozy farm table and the pack's sheets instead of the drawn animals
## that have a pack counterpart (set before setup).
var cozy := false
var summary := ""
var scared := {} # species -> times an animal reacted to the walker, for tools/walker_test.gd
var _animals: Array[Animal] = []
var _habitat := {} # species -> {cell: true}
var _land := {} # cells a land animal may cross
var _water := {}
var _trunks: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()


class Animal extends Node2D:
	var kind := ""
	var spec: Dictionary
	var frames: Dictionary # anim -> Array of rows
	var colors: Dictionary # key -> Color
	var pos := Vector2.ZERO
	var home := Vector2.ZERO
	var target := Vector2.ZERO
	var state := "idle"
	var timer := 0.0
	var t := 0.0
	var anim := "idle"
	var frame := 0
	var facing := 1
	var height := 0.0
	var flock: Array = [] # sparrows: the birds that fly together
	var sheet: Texture2D # cozy farm: the pack sheet (4 x 5 cells) instead of `frames`
	var cell := 16
	var dir := Vector2.RIGHT # last direction of travel (picks the sheet row)
	var fly_from := Vector2.ZERO
	var fly_k := 0.0
	var fly_time := 1.0
	var arc := 10.0

	func _draw() -> void:
		if sheet:
			_draw_sheet()
			return
		var rows: Array = frames[anim][frame % frames[anim].size()]
		var h: int = rows.size()
		var w: int = rows[0].length()
		var ox := -w / 2
		var lift := roundi(height)
		if kind == "duck":
			# A pale waterline that laps at the sides.
			var lap := 1 if fmod(t, 1.2) < 0.6 else 0
			draw_rect(Rect2(ox - 1 - lap, -1, 1, 1), RIPPLE)
			draw_rect(Rect2(ox + w + lap, -1, 1, 1), RIPPLE)
		elif state != "hidden":
			draw_rect(Rect2(ox + 1, 0, maxi(1, w - 2), 1), SHADOW)
		for y in h:
			var row: String = rows[y]
			for x in w:
				var key := row[x]
				if key == ".":
					continue
				var dx := x if facing > 0 else w - 1 - x
				draw_rect(Rect2(ox + dx, y - h - lift, 1, 1), colors[key])


	# A pack animal: walk rows by direction of travel (down, up, left, right),
	# the side row's first frame when still, the sleep row dozing; its feet
	# (the cell's bottom) on the ground line, with the drawn shadow.
	func _draw_sheet() -> void:
		var row := 3 if facing > 0 else 2
		var col := 0
		if state == "sleep":
			row = 4
			col = int(t * 1.6) % 4
		elif anim == "move":
			if absf(dir.y) > absf(dir.x) * 1.4:
				row = 0 if dir.y > 0.0 else 1
			col = int(t * spec.fps) % 4
		elif anim == "idle":
			col = frame % 2
		var w := cell
		if state != "hidden":
			draw_rect(Rect2(-w / 2 + 3, 0, w - 6, 1), SHADOW)
		draw_texture_rect_region(sheet, Rect2(-w / 2, -w + 1 - roundi(height), w, w), Rect2(col * w, row * w, w, w))


func _ready() -> void:
	_rng.randomize()


## Species, groups, and home cells for map `t`, from its map id.
## Returns {habitats: {species: {cell: true}}, groups: [{kind, center, cells}]}.
static func plan(t: PaintedTerrain) -> Dictionary:
	var habitats := habitat_cells(t)
	habitats["_w"] = W
	return plan_from(habitats, t.map_id, t.spawn, quiet_field(t))


## The plan for any map: `habitats` as habitat_cells() returns them (plus
## "_w", the map width), the map id, the walker's spawn cell, and quiet_from()
## over the things that already move.
static func plan_from(habitats: Dictionary, map_id: int, spawn: Vector2i, quiet: PackedFloat32Array, cozy_table := false) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([map_id, "wildlife"])
	var w: int = habitats.get("_w", W)
	var table: Dictionary = COZY_SPECIES if cozy_table else SPECIES
	var eligible: Array[String] = []
	for kind in table:
		if habitats[table[kind].habitat].size() < (12 if kind == "duck" else MIN_HABITAT):
			continue
		if kind == "fox" and rng.randf() >= FOX_CHANCE:
			continue
		eligible.append(kind)
	for i in range(eligible.size() - 1, 0, -1): # shuffle with the map's rng
		var j := rng.randi_range(0, i)
		var tmp := eligible[i]
		eligible[i] = eligible[j]
		eligible[j] = tmp
	var per: Vector2i = COZY_PER_MAP if cozy_table else SPECIES_PER_MAP
	if cozy_table:
		# A farm always has farm animals: two to four kinds lead the list.
		var farm := eligible.filter(func(k): return k in COZY_FARM)
		var rest := eligible.filter(func(k): return not k in COZY_FARM)
		eligible = farm.slice(0, rng.randi_range(2, 4)) + rest + farm.slice(4)
	var chosen := eligible.slice(0, rng.randi_range(per.x, per.y))
	var placed: Array[Vector2i] = [] # group centers of every species so far
	var groups: Array[Dictionary] = []
	for kind in chosen:
		var spec: Dictionary = table[kind]
		var cells: Array = habitats[spec.habitat].keys()
		cells.sort() # dictionary order is not part of the seed
		var centers: Array[Vector2i] = []
		# Groups that do not need trees or water settle where the scene is
		# quietest: the best of a few candidates by distance from water,
		# fires, trees, and the groups already placed.
		var seek_quiet: bool = not spec.habitat in ["trees", "shore", "water"]
		for g in rng.randi_range(spec.groups.x, spec.groups.y):
			var best := Vector2i(-1, -1)
			var best_q := -1.0
			var found := 0
			for attempt in 24:
				if found >= (QUIET_TRIES if seek_quiet else 1):
					break
				var c: Vector2i = cells[rng.randi() % cells.size()]
				if Vector2(c - spawn).length() < 6.0:
					continue # not right on top of the walker
				var near := false
				for other in centers:
					if Vector2(c - other).length() < GROUP_GAP:
						near = true
				if near:
					continue
				found += 1
				var q: float = quiet[c.y * w + c.x]
				for other in placed:
					q = minf(q, Vector2(c - other).length())
				if q > best_q:
					best_q = q
					best = c
			if best.x >= 0:
				var c := best
				centers.append(c)
				placed.append(c)
				var around: Array[Vector2i] = []
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						if habitats[spec.habitat].has(c + Vector2i(dx, dy)):
							around.append(c + Vector2i(dx, dy))
				for i in range(around.size() - 1, 0, -1):
					var j := rng.randi_range(0, i)
					var tmp := around[i]
					around[i] = around[j]
					around[j] = tmp
				groups.append({"kind": kind, "center": c, "cells": around.slice(0, rng.randi_range(spec.size.x, spec.size.y))})
	return {"habitats": habitats, "groups": groups}


## Per cell, the distance in cells (capped at QUIET_CAP) to the nearest thing
## that already keeps the scene moving: water, a campfire or torch, a tree.
static func quiet_field(t: PaintedTerrain) -> PackedFloat32Array:
	var front: Array[Vector2i] = []
	for c in t.water:
		front.append(c)
	for p in t.props:
		if p.has("art") and (p.art in PaintedTerrain.TREES or p.art in PaintedTerrain.SHADE_TREES or p.art in PaintedTerrain.TORCHES or p.art in ["campfire", "campfire_big"]):
			front.append(p.cell)
	return quiet_from(front, W, H)


## Distance in cells (capped at QUIET_CAP) from `sources` on a w x h map.
static func quiet_from(sources: Array[Vector2i], w: int, h: int) -> PackedFloat32Array:
	var W := w
	var H := h
	var d := PackedFloat32Array()
	d.resize(W * H)
	d.fill(QUIET_CAP)
	var front: Array[Vector2i] = sources.duplicate()
	for c in front:
		if c.x >= 0 and c.y >= 0 and c.x < W and c.y < H:
			d[c.y * W + c.x] = 0.0
	# Breadth-first, eight neighbors, so the distance is in whole cells.
	var i := 0
	while i < front.size():
		var c: Vector2i = front[i]
		i += 1
		var v := d[c.y * W + c.x] + 1.0
		if v >= QUIET_CAP:
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n := c + Vector2i(dx, dy)
				if n.x < 0 or n.y < 0 or n.x >= W or n.y >= H or d[n.y * W + n.x] <= v:
					continue
				d[n.y * W + n.x] = v
				front.append(n)
	return d


static func habitat_cells(t: PaintedTerrain) -> Dictionary:
	var land := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if not (t.water.has(c) or t._blocked.has(c) or t.ledge.has(c) or t.hedge.has(c) or t.canopy.has(c) or t.ridge_rock.has(c)):
				land[c] = true
	var trunks := {}
	var clutter := {}
	var bushes := {}
	var rocks := {}
	for p in t.props:
		if not p.has("art"):
			clutter[p.cell] = true # signs
			continue
		var art: Dictionary = PaintedTerrain.PROPS[p.art]
		var foot := Vector2i((Vector2((p.cell + art.cell) * TILE) + Vector2(art.base)) / TILE)
		if p.art in PaintedTerrain.TREES or p.art in PaintedTerrain.SHADE_TREES:
			trunks[foot] = true
		elif p.art in PaintedTerrain.LOGS or p.art in PaintedTerrain.YARD_CLUTTER:
			clutter[foot] = true
		elif p.art in PaintedTerrain.HEDGES or p.art in PaintedTerrain.SHRUBS:
			bushes[foot] = true
		elif p.art in PaintedTerrain.BIG_ROCKS or p.art in PaintedTerrain.OUTCROPS.values():
			rocks[foot] = true
	for c in t.fence:
		clutter[c] = true
	for c in t.hedge:
		bushes[c] = true
	for c in t.ridge:
		rocks[c] = true
	# Green plateau tops (not stone) are ground too: rabbits and sparrow
	# flocks live up there as well as on the lawn.
	var green_top := {}
	for info in t.plateaus:
		if info.tone == "stone":
			continue
		var top: Rect2i = info.top
		for y in range(top.position.y, top.end.y):
			for x in range(top.position.x, top.end.x):
				var c := Vector2i(x, y)
				if land.has(c) and t.plateau.has(c) and not t.stairs.has(c) and not t.ramps.has(c):
					green_top[c] = true
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	for c in land:
		var tone := t._tone_level(c)
		var wet := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if t.water.has(c + d):
				wet = true
		if wet:
			h.shore[c] = true
		var on_ground: bool = not t.plateau.has(c) and not t.path.has(c)
		if (on_ground or green_top.has(c)) and tone <= 0 and not _near(c, t.water, 2):
			h.lawn[c] = true
		if on_ground and tone >= 1:
			h.dark[c] = true
		if on_ground and not wet:
			h.roam[c] = true
		if _near(c, trunks, 2):
			h.trees[c] = true
		if _near(c, clutter, 2):
			h.clutter[c] = true
		if _near(c, bushes, 2):
			h.bushes[c] = true
		if (t.plateau.has(c) and not t.stairs.has(c)) or _near(c, rocks, 2):
			h.rocky[c] = true
		if (on_ground and tone <= 0 and not wet and (_near(c, t.path, 3) or _near(c, t.fence, 3))) or green_top.has(c):
			h.open[c] = true
	for c in t.water:
		if t._near_all(c, t.water, 1):
			h.water[c] = true
	h["_land"] = land
	h["_trunks"] = trunks
	return h


static func _near(c: Vector2i, cells: Dictionary, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if cells.has(c + Vector2i(dx, dy)):
				return true
	return false


## Places the map's animals as y-sorted children of `actors`.
func setup(t: PaintedTerrain, actors: Node2D, p_walker: Node2D, sheet: Image, p_water_life: WaterLife) -> void:
	var p := plan(t) if not cozy else plan_from(habitat_cells(t), t.map_id, t.spawn, quiet_field(t), true)
	setup_from(p, t.water, actors, p_walker, sheet, p_water_life)


## Any map: a plan from plan_from(), its water cells, and the sheet whose
## palette the animals wear.
func setup_from(p: Dictionary, water: Dictionary, actors: Node2D, p_walker: Node2D, sheet: Image, p_water_life: WaterLife) -> void:
	walker = p_walker
	water_life = p_water_life
	_animals.clear()
	_habitat = p.habitats
	_land = _habitat["_land"]
	_water = water
	_trunks.clear()
	for c in _habitat["_trunks"]:
		_trunks.append(Vector2(c * TILE) + Vector2(8, 12))
	var counts := {}
	for g in p.groups:
		var flock: Array = []
		var spec: Dictionary = (COZY_SPECIES if cozy else SPECIES)[g.kind]
		var colors := {}
		if SPRITES.has(g.kind):
			for key in SPRITES[g.kind].palette:
				colors[key] = _snap(SPRITES[g.kind].palette[key], sheet)
		var coat := _rng.randi() # one coat per group, so a herd matches
		for cell in g.cells:
			var a := Animal.new()
			a.name = "%s_%d_%d" % [g.kind, cell.x, cell.y]
			a.kind = g.kind
			a.spec = spec
			if cozy and COZY_SHEETS.has(g.kind):
				# About a third of a herd are young, when the pack has them.
				var set_: Dictionary = COZY_SHEETS[g.kind]
				if set_.has("baby") and _rng.randf() < 0.33:
					set_ = set_.baby
				var files: Array = set_.files
				a.sheet = load(COZY_DIR + files[coat % files.size()] + ".png")
				a.cell = set_.cell
			else:
				a.frames = SPRITES[g.kind]
			a.colors = colors
			a.pos = Vector2(cell * TILE) + Vector2(_rng.randf_range(3, 13), _rng.randf_range(6, 14))
			a.home = Vector2(g.center * TILE) + Vector2(8, 8)
			a.facing = 1 if _rng.randf() < 0.5 else -1
			a.timer = _rng.randf_range(0.0, spec.idle.y)
			a.t = _rng.randf() * 10.0
			a.position = a.pos.floor()
			actors.add_child(a)
			_animals.append(a)
			flock.append(a)
		if g.kind == "sparrow":
			for a in flock:
				a.flock = flock
		counts[g.kind] = counts.get(g.kind, 0) + g.cells.size()
	var parts := PackedStringArray()
	for kind in counts:
		parts.append("%s %d" % [kind, counts[kind]])
	summary = "  wildlife: " + (", ".join(parts) if not parts.is_empty() else "none")
	print(summary)


func _process(delta: float) -> void:
	var feet := walker.global_position if is_instance_valid(walker) and walker.visible else Vector2(-9999, -9999)
	for a in _animals:
		if not is_instance_valid(a):
			continue
		_update(a, delta, feet)
		a.position = a.pos.floor()
		a.queue_redraw()


func _update(a: Animal, delta: float, feet: Vector2) -> void:
	var spec := a.spec
	a.t += delta
	var near: bool = a.pos.distance_to(feet) < spec.scare
	match a.state:
		"idle":
			a.anim = "idle"
			# Mostly still, now and then an ear flick, a peck, a sniff.
			a.frame = 1 if fmod(a.t * 0.7 + a.home.x, 3.0) > 2.4 else 0
			a.timer -= delta
			if near:
				_scare(a, feet)
			elif a.timer <= 0.0 and a.sheet and _rng.randf() < spec.get("sleep", 0.0):
				a.state = "sleep"
				a.timer = _rng.randf_range(6.0, 16.0)
			elif a.timer <= 0.0:
				var to := _wander_target(a)
				if to != Vector2.INF:
					a.target = to
					a.state = "move"
				else:
					a.timer = _rng.randf_range(spec.idle.x, spec.idle.y)
		"move":
			if near:
				_scare(a, feet)
			elif _step(a, spec.speed, delta):
				a.state = "idle"
				a.height = 0.0
				a.timer = _rng.randf_range(spec.idle.x, spec.idle.y)
		"flee":
			if _step(a, spec.flee, delta):
				a.height = 0.0
				match spec.react:
					"hide", "climb":
						_hide(a, 5.0, 12.0)
					"dive":
						if water_life:
							water_life._ring(a.pos + Vector2(0, -1), 0.0)
						_hide(a, 6.0, 14.0)
					_:
						a.state = "idle"
						a.timer = _rng.randf_range(3.0, 6.0) # stays wary a while
		"sleep":
			# Dozing; wakes when the walker comes close or in its own time.
			a.timer -= delta
			if near or a.timer <= 0.0:
				a.state = "idle"
				a.timer = _rng.randf_range(spec.idle.x, spec.idle.y)
		"curl":
			a.anim = "curl"
			a.frame = 0
			if near:
				a.timer = 3.0
			a.timer -= delta
			if a.timer <= 0.0:
				a.state = "idle"
				a.timer = _rng.randf_range(1.0, 3.0)
		"hidden":
			a.timer -= delta
			if a.timer <= 0.0 and a.home.distance_to(feet) > spec.scare * 1.6:
				var back := _wander_target(a)
				if back != Vector2.INF:
					a.pos = back
					a.visible = true
					a.state = "idle"
					a.timer = _rng.randf_range(spec.idle.x, spec.idle.y)
		"fly":
			a.anim = "fly"
			a.frame = int(a.t * 12.0) % 2
			a.fly_k += delta / a.fly_time
			if a.fly_k >= 0.0:
				var k := minf(a.fly_k, 1.0)
				a.pos = a.fly_from.lerp(a.target, k)
				a.height = sin(PI * k) * a.arc + (2.0 if k < 1.0 else 0.0)
				if k >= 1.0:
					a.height = 0.0
					a.z_index = 0
					a.state = "idle"
					a.timer = _rng.randf_range(spec.idle.x, spec.idle.y)


# Moves toward the target; true on arrival. Hoppers bob, darters go in bursts.
func _step(a: Animal, speed: float, delta: float) -> bool:
	a.anim = "move"
	a.frame = int(a.t * a.spec.fps) % 2
	var to := a.target - a.pos
	if absf(to.x) > 0.5:
		a.facing = 1 if to.x > 0.0 else -1
	if to.length() > 0.5:
		a.dir = to.normalized()
	var v := speed
	match a.spec.gait:
		"hop":
			var phase := fmod(a.t * 2.2, 1.0)
			a.height = sin(PI * phase) * (2.0 if a.kind != "sparrow" else 1.0)
			a.frame = 0 if phase < 0.7 else 1
			v *= 1.6 if phase < 0.7 else 0.0
		"dart":
			v *= 0.25 + 1.5 * maxf(0.0, sin(a.t * 7.0))
	if to.length() <= v * delta or to.length() < 0.5:
		a.pos = a.target
		return true
	a.pos += to.normalized() * v * delta
	return false


func _scare(a: Animal, feet: Vector2) -> void:
	var spec := a.spec
	scared[a.kind] = scared.get(a.kind, 0) + 1
	match spec.react:
		"curl":
			a.state = "curl"
			a.timer = 3.0
		"fly":
			_fly_off(a.flock if not a.flock.is_empty() else [a], feet)
		"climb":
			var best := Vector2.INF
			for tr in _trunks:
				if tr.distance_to(a.pos) < 80.0 and (best == Vector2.INF or tr.distance_to(a.pos) < best.distance_to(a.pos)):
					best = tr
			if best != Vector2.INF:
				a.target = best
				a.state = "flee"
			else:
				_flee_away(a, feet, 30.0, 70.0)
		"dive":
			var best := Vector2.INF
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var c := Vector2i(floori(a.pos.x / TILE) + dx, floori(a.pos.y / TILE) + dy)
					if _water.has(c):
						var p := Vector2(c * TILE) + Vector2(8, 8)
						if best == Vector2.INF or p.distance_to(a.pos) < best.distance_to(a.pos):
							best = p
			if best != Vector2.INF:
				a.target = best
				a.state = "flee"
			else:
				_flee_away(a, feet, 10.0, 24.0)
		"hide":
			_flee_away(a, feet, 10.0, 24.0)
		"amble":
			# Farm animals just move a little way off.
			_flee_away(a, feet, 18.0, 40.0)
		_:
			_flee_away(a, feet, 50.0, 110.0)


# Runs to a reachable point away from the walker.
func _flee_away(a: Animal, feet: Vector2, lo: float, hi: float) -> void:
	var away := (a.pos - feet).angle()
	for i in 14:
		var d := _rng.randf_range(lo, hi) * (1.0 if i < 10 else 0.5)
		var p := a.pos + Vector2.from_angle(away + _rng.randf_range(-1.1, 1.1)) * d
		if _can_stand(a, p) and _clear(a, a.pos, p):
			a.target = p
			a.state = "flee"
			return
	if a.spec.react in ["hide"]:
		_hide(a, 4.0, 9.0)


func _hide(a: Animal, lo: float, hi: float) -> void:
	a.state = "hidden"
	a.visible = false
	a.timer = _rng.randf_range(lo, hi)


# Sparrows: the whole flock takes off, a beat apart, and lands together
# somewhere well away from the walker.
func _fly_off(flock: Array, feet: Vector2) -> void:
	var lead: Animal = flock[0]
	var spot := Vector2.INF
	var cells: Array = _habitat[lead.spec.habitat].keys()
	for i in 20:
		var c: Vector2i = cells[_rng.randi() % cells.size()]
		var p := Vector2(c * TILE) + Vector2(8, 10)
		var d := p.distance_to(lead.pos)
		if d > 70.0 and d < 170.0 and p.distance_to(feet) > 90.0:
			spot = p
			break
	if spot == Vector2.INF:
		spot = lead.pos + (lead.pos - feet).normalized() * 90.0
	for a in flock:
		if a.state == "fly":
			continue
		a.state = "fly"
		a.fly_from = a.pos
		a.target = spot + Vector2(_rng.randf_range(-10, 10), _rng.randf_range(-6, 6))
		a.home = spot
		a.fly_time = maxf(0.8, a.fly_from.distance_to(a.target) / a.spec.flee)
		a.fly_k = -_rng.randf_range(0.0, 0.35) / a.fly_time
		a.arc = 10.0 + a.fly_from.distance_to(a.target) * 0.1
		a.facing = 1 if a.target.x > a.pos.x else -1
		a.z_index = 22 # over the tree crowns while in the air


# A random reachable spot in the animal's habitat around its home.
func _wander_target(a: Animal) -> Vector2:
	var cells: Dictionary = _habitat[a.spec.habitat]
	for i in 12:
		var p: Vector2 = a.home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * a.spec.home
		var c := Vector2i(floori(p.x / TILE), floori(p.y / TILE))
		if cells.has(c) and (a.state == "hidden" or _clear(a, a.pos, p)):
			return p
	return Vector2.INF


func _can_stand(a: Animal, p: Vector2) -> bool:
	var c := Vector2i(floori(p.x / TILE), floori(p.y / TILE))
	return _habitat.water.has(c) if a.kind == "duck" else _land.has(c)


func _clear(a: Animal, from: Vector2, to: Vector2) -> bool:
	var n := int(from.distance_to(to) / 4.0) + 1
	for i in n + 1:
		if not _can_stand(a, from.lerp(to, float(i) / n)):
			return false
	return true


# The nearest color on the tileset, so every animal wears the pack's palette.
static func _snap(c: Color, sheet: Image) -> Color:
	if sheet == null:
		return c
	var key := sheet.get_instance_id()
	if not _sheet_colors.has(key):
		var seen := {}
		for y in range(0, sheet.get_height(), 2):
			for x in range(0, sheet.get_width(), 2):
				var p := sheet.get_pixel(x, y)
				if p.a > 0.9:
					seen[p.to_rgba32()] = true
		var colors: Array[Color] = []
		for k in seen:
			colors.append(Color.hex(k))
		_sheet_colors[key] = colors
	var best := c
	var dist := INF
	for s: Color in _sheet_colors[key]:
		var d: float = (s.r - c.r) ** 2 + (s.g - c.g) ** 2 + (s.b - c.b) ** 2
		if d < dist:
			dist = d
			best = s
	return best
