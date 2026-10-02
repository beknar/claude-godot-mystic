class_name CaveTerrain
extends RefCounted
## Green Caves maps (The Painted Lands - Green Caves Tileset, antarcticbees):
## the same approach as forest_terrain.gd (a recipe per seed, a layout,
## autotiled systems, set pieces, scatter, a walk check, and a liveliness
## floor), with the cave's own sheet. Output is atlas coordinates on
## assets/pack/green_caves/green_caves_tileset.png and prop placements;
## scripts/caves.gd paints them. Nothing here draws pixels.
##
## The sheet's systems (cells):
##   floor     light (0-1, 0-1), dark (3-4, 0-1), mossy (0-3, 9-10)
##   dark zone a blob on transparent (0-2, 6-8) with inner corners (3-4, 6-7):
##             the dark floor laid over the light one
##   wall mass solid rock seen from above: black top with a rim (5-7, 11-13),
##             its face on the two cells below (5-7, 14-15); face variants
##             (10-17, 16-18), the cave doorway (5-7, 9-10)
##   terrace   raised walkable floor (5-7, 0-2) over a face (5-7, 3-4); face
##             variants (10-17, 5-7); stairs (9-13, 8-10)
##   pool      land-on-water: the stone ring (21-23, 0-2) and plus inner
##             corners (25-28, 0-3); water edges (20/24, 1), (22, 3) and
##             corners; open water (29-32, 7); all four frames apart
##   rails     one track: straight (16, 8) / (15, 9), curves (15, 8) (17, 8)
##             (15, 10) (17, 10)
## The pool ring, the terrace top, and the dark floor are one grey (162), so
## every pool sits in a dark zone and its ring disappears into it.

const W := 60
const H := 40
const TILE := 16

# Kinds.
const FLOOR := 0
const WALL := 1 # wall mass top
const FACE := 2 # a wall or terrace face (blocks)
const TERRACE := 3 # raised walkable floor
const STAIR := 4
const WATER := 5
const HOME := 6 # floor inside a home (and its doorway): walkable, painted by interior_view.gd

const ROLES := {15: Vector2i(1, 1), 14: Vector2i(1, 0), 11: Vector2i(1, 2), 7: Vector2i(0, 1), 13: Vector2i(2, 1),
	6: Vector2i(0, 0), 12: Vector2i(2, 0), 3: Vector2i(0, 2), 9: Vector2i(2, 2)}
const LIGHT_FLOOR: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
const DARK_FLOOR: Array[Vector2i] = [Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 1), Vector2i(4, 1)]
const MOSS_FLOOR: Array[Vector2i] = [Vector2i(0, 9), Vector2i(1, 9), Vector2i(2, 9), Vector2i(3, 9), Vector2i(0, 10), Vector2i(1, 10)]
const ZONE := Vector2i(0, 6)
const ZONE_INNER := {2: Vector2i(3, 6), 4: Vector2i(4, 6), 1: Vector2i(3, 7), 8: Vector2i(4, 7)} # open diagonal NE=1 SE=2 SW=4 NW=8
const WALL_TOP := Vector2i(5, 11)
const WALL_FACE := Vector2i(5, 14)
const WALL_FACE_VARIANTS: Array[int] = [10, 11, 12, 13, 14, 15, 16] # columns: rim at row 16, face rows 17-18 (14-16 mossy)
const DOORWAY := Vector2i(5, 9)
const TERRACE_TOP := Vector2i(5, 0)
const TERRACE_FACE := Vector2i(5, 3)
const TERRACE_FACE_VARIANTS: Array[int] = [10, 11, 12, 13, 14, 15, 16] # rim at row 5, face rows 6-7 (14-16 mossy)
const SKULL_FACE := 17 # the skull column of both variant sets
const ACCENT := Vector2i(0, 3) # dark floor patch baked on light floor, inner corners (3-4, 3-4)
const ACCENT_INNER := {2: Vector2i(3, 3), 4: Vector2i(4, 3), 1: Vector2i(3, 4), 8: Vector2i(4, 4)}
const STAIRS := Vector2i(10, 8) # three wide, three tall; sides (9, 8) and (13, 8)
const OPEN_WATER := Vector2i(29, 7)
const DEEP: Array[Vector2i] = [Vector2i(30, 0), Vector2i(31, 0), Vector2i(32, 0), Vector2i(33, 0), Vector2i(34, 0), Vector2i(35, 0),
	Vector2i(30, 1), Vector2i(31, 1), Vector2i(32, 1), Vector2i(33, 1), Vector2i(34, 1), Vector2i(35, 1)]
const RAIL_H := Vector2i(16, 8)
const RAIL_V := Vector2i(15, 9)
const RAIL_CURVE := {"ES": Vector2i(15, 8), "WS": Vector2i(17, 8), "EN": Vector2i(15, 10), "WN": Vector2i(17, 10)}
const TUFTS: Array[Vector2i] = [Vector2i(46, 7), Vector2i(47, 7), Vector2i(48, 7), Vector2i(49, 7), Vector2i(46, 8), Vector2i(47, 8), Vector2i(48, 8), Vector2i(49, 8)]

# Props: region (px), foot (px in the region), collider, footprint (cells
# relative to the anchor, the foot's cell), and a kind tag the ambience and
# the habitats read.
const PROPS := {
	"rock_skull": {"region": Rect2i(528, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(26, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "rock"},
	"rock_small": {"region": Rect2i(560, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(18, 6), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "rock"},
	"boulder": {"region": Rect2i(592, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(26, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "rock"},
	"rock": {"region": Rect2i(624, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "rock"},
	"rock_moss": {"region": Rect2i(656, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "rock"},
	"ore_silver": {"region": Rect2i(688, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "ore"},
	"ore_dark": {"region": Rect2i(720, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "ore"},
	"ore_gold": {"region": Rect2i(752, 192, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "ore"},
	"crystal_cyan": {"region": Rect2i(464, 224, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(10, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"crystal_blue": {"region": Rect2i(480, 224, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(10, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"crystal_violet": {"region": Rect2i(496, 224, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(10, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"shard_cyan": {"region": Rect2i(464, 240, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"shard_blue": {"region": Rect2i(480, 240, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"shard_violet": {"region": Rect2i(496, 240, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "crystal"},
	"cone": {"region": Rect2i(736, 80, 16, 32), "foot": Vector2i(8, 31), "block": Vector2(10, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "rock"},
	"cone_b": {"region": Rect2i(752, 80, 16, 32), "foot": Vector2i(8, 31), "block": Vector2(10, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "rock"},
	"cone_small": {"region": Rect2i(768, 96, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "rock"},
	"plant": {"region": Rect2i(704, 80, 16, 32), "foot": Vector2i(8, 31), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "plant"},
	"plant_flower": {"region": Rect2i(720, 80, 16, 32), "foot": Vector2i(8, 31), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "flower"},
	"grass_clump": {"region": Rect2i(672, 112, 32, 32), "foot": Vector2i(16, 30), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 2, 1), "tag": "plant"},
	"tree_dead": {"region": Rect2i(576, 0, 48, 80), "foot": Vector2i(24, 79), "block": Vector2(12, 6), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree", "erase": Rect2i(0, 44, 16, 36)},
	"tree_mossy": {"region": Rect2i(624, 0, 48, 80), "foot": Vector2i(24, 79), "block": Vector2(12, 6), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree"},
	"tree_tall": {"region": Rect2i(672, 0, 48, 80), "foot": Vector2i(24, 79), "block": Vector2(12, 6), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree"},
	"tree_slim": {"region": Rect2i(720, 32, 16, 48), "foot": Vector2i(8, 47), "block": Vector2(8, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "tree"},
	"rock_tree": {"region": Rect2i(560, 240, 48, 64), "foot": Vector2i(24, 62), "block": Vector2(26, 8), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree"},
	"rock_tree_moss": {"region": Rect2i(608, 240, 48, 64), "foot": Vector2i(24, 62), "block": Vector2(26, 8), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree"},
	"rock_tree_crystal": {"region": Rect2i(656, 240, 48, 64), "foot": Vector2i(24, 62), "block": Vector2(26, 8), "foot_cells": Rect2i(0, -1, 3, 2), "tag": "tree"},
	"bush": {"region": Rect2i(736, 32, 64, 48), "foot": Vector2i(32, 46), "block": Vector2(44, 10), "foot_cells": Rect2i(0, -1, 4, 2), "tag": "bush"},
	"bush_small": {"region": Rect2i(736, 0, 64, 32), "foot": Vector2i(32, 28), "block": Vector2(40, 8), "foot_cells": Rect2i(0, 0, 4, 1), "tag": "bush"},
	"branch": {"region": Rect2i(576, 88, 48, 24), "foot": Vector2i(24, 22), "block": Vector2(40, 6), "foot_cells": Rect2i(0, 0, 3, 1), "tag": "clutter"},
	"branch_moss": {"region": Rect2i(624, 88, 48, 24), "foot": Vector2i(24, 22), "block": Vector2(40, 6), "foot_cells": Rect2i(0, 0, 3, 1), "tag": "clutter"},
	"chest": {"region": Rect2i(528, 96, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(14, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"chest_b": {"region": Rect2i(544, 96, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(14, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"chest_open": {"region": Rect2i(560, 96, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(14, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"board": {"region": Rect2i(528, 112, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(8, 4), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"board_b": {"region": Rect2i(528, 128, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(8, 4), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"skull": {"region": Rect2i(544, 112, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "bones"},
	"skull_b": {"region": Rect2i(544, 128, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "bones"},
	"ladder": {"region": Rect2i(528, 144, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(12, 4), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"trough": {"region": Rect2i(544, 144, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(14, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"crates": {"region": Rect2i(560, 112, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(22, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "clutter"},
	"crate": {"region": Rect2i(576, 144, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(14, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"barrel": {"region": Rect2i(592, 112, 32, 32), "foot": Vector2i(16, 31), "block": Vector2(16, 6), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "clutter"},
	"barrel_b": {"region": Rect2i(624, 112, 32, 32), "foot": Vector2i(16, 31), "block": Vector2(16, 6), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "clutter"},
	"signpost": {"region": Rect2i(576, 48, 16, 48), "foot": Vector2i(8, 47), "block": Vector2(6, 4), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"cart": {"region": Rect2i(288, 80, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(22, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "clutter"},
	"cart_empty": {"region": Rect2i(288, 112, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(22, 8), "foot_cells": Rect2i(0, 0, 2, 1), "tag": "clutter"},
	"coal": {"region": Rect2i(288, 144, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"coal_pile": {"region": Rect2i(288, 160, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(12, 5), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
	"pillar": {"region": Rect2i(464, 256, 16, 48), "foot": Vector2i(8, 47), "block": Vector2(14, 8), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "rock"},
	"pillars": {"region": Rect2i(496, 256, 48, 48), "foot": Vector2i(24, 47), "block": Vector2(44, 8), "foot_cells": Rect2i(0, 0, 3, 1), "tag": "rock"},
	# Animated: four frames 16 px apart to the right.
	"campfire": {"region": Rect2i(256, 0, 16, 32), "foot": Vector2i(8, 31), "block": Vector2(12, 6), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "fire", "frames": 4},
	"torch": {"region": Rect2i(256, 64, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(4, 4), "foot_cells": Rect2i(0, 0, 1, 1), "tag": "torch", "frames": 4},
	"embers": {"region": Rect2i(240, 16, 16, 16), "foot": Vector2i(8, 15), "block": Vector2.ZERO, "foot_cells": Rect2i(0, 0, 1, 1), "tag": "clutter"},
}
const ROCKS: Array[String] = ["rock_skull", "rock_small", "boulder", "rock", "rock_moss"]
const ORES: Array[String] = ["ore_silver", "ore_dark", "ore_gold"]
const CRYSTALS: Array[String] = ["crystal_cyan", "crystal_blue", "crystal_violet", "shard_cyan", "shard_blue", "shard_violet"]
const CONES: Array[String] = ["cone", "cone_b", "cone_small"]
const TREES: Array[String] = ["tree_dead", "tree_mossy", "tree_tall", "tree_slim", "rock_tree", "rock_tree_moss", "rock_tree_crystal"]
const PLANTS: Array[String] = ["plant", "plant_flower", "grass_clump"]
const CLUTTER: Array[String] = ["crates", "crate", "barrel", "barrel_b", "trough", "ladder"]

# Recipes. floor: light, dark, moss. band: the back wall across the top.
# islands, terraces, pools: [min, max]. lake: one big pool with deep water.
# rails: a mine track from the spawn to the goal. zones: share of light
# floor darkened. piece: the set piece at the goal. scatter: [art list
# name, count]. torches: pairs of wall torches along the back wall.
const RECIPES := [
	{"name": "Grotto", "floor": "light", "band": true, "islands": [1, 2], "terraces": [0, 1], "pools": [1, 1], "zones": 0.18, "piece": "cairn", "scatter": [["ROCKS", 8], ["CRYSTALS", 4], ["CONES", 3]], "torches": 1},
	{"name": "Crystal cavern", "floor": "light", "band": true, "islands": [1, 3], "terraces": [0, 0], "pools": [0, 1], "zones": 0.3, "piece": "crystal_ring", "scatter": [["CRYSTALS", 22], ["ROCKS", 4]], "torches": 0},
	{"name": "Flooded hall", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [1, 2], "lake": true, "zones": 0.2, "piece": "cairn", "scatter": [["CONES", 5], ["PLANTS", 4], ["ROCKS", 4]], "torches": 1},
	{"name": "Mine shaft", "floor": "dark", "band": true, "islands": [1, 2], "terraces": [0, 0], "pools": [0, 0], "rails": true, "zones": 0.0, "piece": "mine", "scatter": [["ORES", 5], ["ROCKS", 4], ["CLUTTER", 3]], "torches": 3},
	{"name": "Miners' camp", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [0, 1], "zones": 0.15, "piece": "camp", "scatter": [["CLUTTER", 6], ["ORES", 3], ["ROCKS", 3]], "torches": 2, "homes": [1, 1], "rooms": [2, 3]},
	{"name": "Mossy hollow", "floor": "moss", "band": true, "islands": [1, 2], "terraces": [0, 1], "pools": [1, 2], "zones": 0.0, "piece": "grove", "scatter": [["PLANTS", 14], ["TREES", 4], ["TUFTS", 30]], "torches": 0},
	{"name": "Terrace steps", "floor": "light", "band": true, "islands": [0, 1], "terraces": [2, 2], "pools": [0, 1], "zones": 0.2, "piece": "terrace_top", "scatter": [["ROCKS", 6], ["CRYSTALS", 3]], "torches": 1},
	{"name": "Ossuary", "floor": "dark", "band": true, "islands": [1, 2], "terraces": [0, 1], "pools": [0, 0], "zones": 0.0, "piece": "bones", "scatter": [["BONES", 10], ["ROCKS", 5]], "faces": "skull", "torches": 2},
	{"name": "Pillared hall", "floor": "light", "band": true, "islands": [0, 0], "terraces": [0, 0], "pools": [0, 0], "zones": 0.35, "piece": "colonnade", "scatter": [["ROCKS", 3], ["CRYSTALS", 3]], "torches": 3},
	{"name": "Stalagmite field", "floor": "light", "band": true, "islands": [1, 2], "terraces": [0, 0], "pools": [0, 1], "zones": 0.2, "piece": "cairn", "scatter": [["CONES", 22], ["ROCKS", 6]], "torches": 0},
	{"name": "Underground spring", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [3, 4], "zones": 0.15, "piece": "spring", "scatter": [["PLANTS", 8], ["CONES", 4], ["TUFTS", 12]], "torches": 0},
	{"name": "Ore vein", "floor": "dark", "band": true, "islands": [1, 3], "terraces": [0, 0], "pools": [0, 0], "rails": true, "zones": 0.0, "piece": "mine", "scatter": [["ORES", 14], ["ROCKS", 4]], "torches": 2},
	{"name": "Dead grove", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 1], "pools": [0, 1], "zones": 0.25, "piece": "grove", "scatter": [["TREES", 6], ["BRANCHES", 4], ["ROCKS", 4]], "torches": 0},
	{"name": "Cave mouth", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [0, 1], "zones": 0.15, "piece": "doorway", "scatter": [["ROCKS", 6], ["PLANTS", 4], ["TUFTS", 10]], "torches": 2},
	{"name": "Smugglers' cache", "floor": "dark", "band": true, "islands": [1, 2], "terraces": [0, 1], "pools": [0, 0], "zones": 0.0, "piece": "cache", "scatter": [["CLUTTER", 8], ["ROCKS", 3]], "torches": 2, "homes": [1, 1], "rooms": [1, 2]},
	{"name": "Rail junction", "floor": "light", "band": true, "islands": [1, 2], "terraces": [0, 0], "pools": [0, 1], "rails": true, "zones": 0.15, "piece": "mine", "scatter": [["ROCKS", 5], ["ORES", 4], ["CLUTTER", 3]], "torches": 2},
	{"name": "Twin pools", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [2, 2], "zones": 0.2, "piece": "spring", "scatter": [["PLANTS", 6], ["CONES", 4], ["CRYSTALS", 3]], "torches": 1},
	{"name": "Crystal shrine", "floor": "light", "band": true, "islands": [0, 1], "terraces": [1, 1], "pools": [0, 1], "zones": 0.25, "piece": "shrine", "scatter": [["CRYSTALS", 12], ["ROCKS", 3]], "torches": 2},
	{"name": "Dark depths", "floor": "dark", "band": true, "islands": [2, 3], "terraces": [0, 0], "pools": [1, 2], "zones": 0.0, "piece": "cairn", "scatter": [["ROCKS", 8], ["CONES", 6], ["CRYSTALS", 3]], "torches": 1},
	{"name": "Collapsed tunnel", "floor": "light", "band": true, "islands": [4, 6], "terraces": [0, 0], "pools": [0, 0], "zones": 0.2, "piece": "cairn", "scatter": [["ROCKS", 14], ["BRANCHES", 2]], "torches": 1},
	{"name": "Overgrown mine", "floor": "moss", "band": true, "islands": [1, 2], "terraces": [0, 0], "pools": [0, 1], "rails": true, "zones": 0.0, "piece": "mine", "scatter": [["PLANTS", 10], ["TREES", 3], ["TUFTS", 20], ["ORES", 3]], "torches": 1},
	{"name": "Watch post", "floor": "light", "band": true, "islands": [0, 1], "terraces": [1, 1], "pools": [0, 1], "zones": 0.2, "piece": "terrace_top", "scatter": [["ROCKS", 5], ["CLUTTER", 3]], "torches": 2},
	{"name": "Root cellar", "floor": "dark", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [0, 1], "zones": 0.0, "piece": "cellar", "scatter": [["TREES", 4], ["CLUTTER", 5], ["BRANCHES", 2]], "torches": 2, "homes": [1, 1], "rooms": [2, 3]},
	{"name": "Echo chamber", "floor": "light", "band": true, "islands": [0, 0], "terraces": [0, 0], "pools": [0, 1], "zones": 0.4, "piece": "cairn", "scatter": [["ROCKS", 5], ["CRYSTALS", 5], ["CONES", 3]], "torches": 0},
	{"name": "Lake terrace", "floor": "light", "band": true, "islands": [0, 0], "terraces": [1, 1], "pools": [1, 1], "lake": true, "zones": 0.2, "piece": "terrace_top", "scatter": [["CONES", 4], ["PLANTS", 4]], "torches": 1},
	{"name": "Coal store", "floor": "dark", "band": true, "islands": [1, 2], "terraces": [0, 0], "pools": [0, 0], "rails": true, "zones": 0.0, "piece": "coal", "scatter": [["CLUTTER", 4], ["ORES", 4]], "torches": 2},
	{"name": "Crossroads cavern", "floor": "light", "band": true, "islands": [2, 3], "terraces": [0, 0], "pools": [0, 1], "zones": 0.2, "piece": "crossroads", "scatter": [["ROCKS", 6], ["PLANTS", 3]], "torches": 2},
	{"name": "Hermit's nook", "floor": "moss", "band": true, "islands": [1, 2], "terraces": [0, 1], "pools": [0, 1], "zones": 0.0, "piece": "camp", "scatter": [["BRANCHES", 3], ["PLANTS", 6], ["TUFTS", 14], ["TREES", 2]], "torches": 0, "homes": [1, 1], "rooms": [1, 2]},
	{"name": "Sunken garden", "floor": "moss", "band": true, "islands": [0, 1], "terraces": [0, 1], "pools": [1, 2], "zones": 0.0, "piece": "grove", "scatter": [["TREES", 5], ["PLANTS", 10], ["TUFTS", 24]], "torches": 0},
	{"name": "Treasure vault", "floor": "dark", "band": true, "islands": [0, 1], "terraces": [1, 1], "pools": [0, 0], "zones": 0.0, "piece": "vault", "scatter": [["CRYSTALS", 8], ["ROCKS", 3]], "torches": 3},
	{"name": "Hermit's home", "floor": "moss", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [1, 1], "zones": 0.0, "piece": "grove", "scatter": [["PLANTS", 10], ["TUFTS", 24], ["TREES", 3], ["BRANCHES", 2]], "torches": 1, "homes": [1, 1], "rooms": [1, 2]},
	{"name": "Cave hamlet", "floor": "light", "band": true, "islands": [0, 1], "terraces": [0, 0], "pools": [0, 1], "zones": 0.2, "piece": "camp", "scatter": [["CLUTTER", 6], ["PLANTS", 4], ["ROCKS", 3]], "torches": 2, "homes": [3, 3], "rooms": [1, 2]},
	{"name": "Underground manor", "floor": "dark", "band": true, "islands": [0, 0], "terraces": [0, 0], "pools": [0, 1], "zones": 0.0, "piece": "shrine", "scatter": [["CRYSTALS", 6], ["PLANTS", 4], ["ROCKS", 2]], "torches": 3, "homes": [1, 1], "rooms": [5, 6]},
]
const ATTEMPTS := 40

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var attempt := 0
var enrich := true

var kind := PackedByteArray()
var floor_tiles := {} # cell -> atlas
var zone := {} # dark floor zone cells
var zone_tiles := {} # cell -> atlas (the transparent blob set)
var features := {} # cell -> atlas: walls, faces, terraces, stairs, pools, rails
var anim := {} # cell -> "pool" | "open": water tiles that animate (four frames)
var deco := {} # cell -> atlas: small tufts
var water_deco := {} # cell -> atlas: stalagmites and weed standing in water, over the water
var sparkles := {} # cell -> atlas: animated glints on open water (four frames side by side)
var accents := {} # cell -> atlas: small dark floor patches baked on the light floor
var props: Array[Dictionary] = [] # {art, cell}
var fires: Array[Vector2i] = [] # campfire and torch cells
var pools: Array[Rect2i] = []
var terraces: Array[Rect2i] = []
var islands: Array[Rect2i] = []
var homes: Array[Dictionary] = [] # {origin: Vector2i, plan: InteriorPlan, door: Vector2i (the arch's walkable cell)}
var rails := {} # cell -> true
var blocked := {} # cells the walker cannot enter
var spawn := Vector2i.ZERO
var goal := Vector2i.ZERO
var goals: Array[Vector2i] = []
var notes := PackedStringArray()
var fails := PackedStringArray()
var floor_notes := PackedStringArray()

var _rng := RandomNumberGenerator.new()
var _occupied := {} # cells claimed by structures, pools and their rings, props
## Lays maze-greencaves' mazes instead (cave_maze.gd, CaveMaze.MAZE_RECIPES):
## the maze's walls, clearings, and gates, then the rest of this pipeline.
var maze := false
var maze_info := {}
var _maze = null # the CaveMaze of the attempt
var _maze_ok := true


## Builds map `p_map_id` with recipe `p_recipe` (-1: map id % recipe count). Returns
## the report; its "  checks:" line is "ok" when the map passes.
func generate(p_map_id: int, p_recipe := -1, p_enrich := true) -> String:
	map_id = p_map_id
	enrich = p_enrich
	var list: Array = CaveMaze.recipes() if maze else RECIPES
	recipe_id = p_recipe if p_recipe >= 0 else posmod(p_map_id, list.size())
	recipe = list[recipe_id]
	for a in ATTEMPTS:
		attempt = a
		_rng.seed = hash(Vector2i(map_id, a))
		_build()
		if _maze_ok and _reaches_all() and homes.size() >= recipe.get("homes", [0, 0])[0]:
			break
	return _report()


func _build() -> void:
	kind.resize(W * H)
	kind.fill(FLOOR)
	for d in [floor_tiles, zone, zone_tiles, features, anim, deco, water_deco, sparkles, accents, rails, blocked, _occupied]:
		d.clear()
	for a in [props, fires, pools, terraces, islands, goals, homes]:
		a.clear()
	notes.clear()
	fails.clear()
	floor_notes.clear()
	maze_info.clear()
	if maze:
		_maze_build()
		return
	spawn = Vector2i(W / 2 + _rng.randi_range(-8, 8), H - 4)
	_claim_disk(spawn, 3)
	if recipe.band:
		_back_wall()
	for i in _rng.randi_range(recipe.terraces[0], recipe.terraces[1]):
		_terrace()
	var h: Array = recipe.get("homes", [0, 0])
	for i in _rng.randi_range(h[0], h[1]):
		_home()
	if recipe.get("lake", false):
		_pool(Vector2i(_rng.randi_range(9, 14), _rng.randi_range(5, 7)), true)
	for i in _rng.randi_range(recipe.pools[0], recipe.pools[1]):
		_pool(Vector2i(_rng.randi_range(3, 7), _rng.randi_range(2, 4)), false)
	for i in _rng.randi_range(recipe.islands[0], recipe.islands[1]):
		_island()
	_pick_goal()
	if recipe.get("rails", false):
		_lay_rails()
	_lay_piece()
	_zones()
	_accents()
	_paint_floor()
	_scatter()
	if enrich:
		_liveliness_floor()


## A maze map (maze-greencaves): CaveMaze lays the walls, clearings, gates,
## and extras; then the dark zones, floor patches, floor, the scatter in the
## antechambers, and the liveliness floor, as on any cave map. Every maze
## cell must be reachable from the entrance.
func _maze_build() -> void:
	_maze = CaveMaze.new(self, _rng)
	_maze_ok = _maze.lay()
	if not _maze_ok:
		return
	_zones()
	_accents()
	_paint_floor()
	_maze.claim_corridors()
	_scatter()
	if enrich:
		_maze_floor()
	_maze_ok = _maze.unreached().is_empty()


# ---------------------------------------------------------------- structures

# The back wall: a band of solid rock across the top, its face below, with a
# cave doorway in the face and some face variants (moss, skulls).
func _back_wall() -> void:
	var rows := _rng.randi_range(2, 3)
	var cells := {}
	for y in rows:
		for x in W:
			cells[Vector2i(x, y)] = true
	_raise(cells, WALL, WALL_TOP, WALL_FACE, 16, WALL_FACE_VARIANTS, recipe.get("faces", ""))
	# The doorway: three face columns replaced by the opening.
	var dx := _rng.randi_range(4, W - 7)
	for i in 3:
		for k in 2:
			features[Vector2i(dx + i, rows + k)] = DOORWAY + Vector2i(i, k)
	notes.append("back wall %d rows, doorway at %d" % [rows, dx])


# A home built into the cave (interior_plan.gd): its ring of walls is cave
# rock toward the cave and the Cozy Cottage trim toward the rooms, and two
# rows of cave face under its south wall carry an arched doorway to the way
# out. Rooms: the recipe's range; each home its own style.
func _home() -> void:
	var rr: Array = recipe.get("rooms", [1, 2])
	var n := _rng.randi_range(rr[0], rr[1])
	var plan := InteriorPlan.new().generate(map_id * 7919 + attempt * 131 + homes.size() * 17, n,
		{"black": true, "exit_width": 3, "max_size": Vector2i(30, 18)})
	var need := plan.size + Vector2i(0, 2)
	for i in 120:
		var at := Vector2i(_rng.randi_range(2, W - need.x - 2), _rng.randi_range(4, H - need.y - 5))
		if not _free(Rect2i(at, need).grow(2)):
			continue
		_home_at(at, plan)
		return
	notes.append("home dropped (no room)")


## Home `plan` built into the cave with its top-left at `at` (as _home lays it).
func _home_at(at: Vector2i, plan: InteriorPlan) -> void:
	var need := plan.size + Vector2i(0, 2)
	for c in plan.kind:
		var k: int = plan.kind[c]
		kind[_i(at + c)] = WALL if k == InteriorPlan.WALL else (FACE if k == InteriorPlan.FACE else HOME)
	for c in plan.blocked:
		blocked[at + c] = true
	# The cave face under the south wall, with the arch at the way out.
	var ex: int = plan.exit_cell.x
	for x in plan.size.x:
		for k in 2:
			var c := at + Vector2i(x, plan.size.y + k)
			if absi(x - ex) <= 1:
				features[c] = DOORWAY + Vector2i(x - ex + 1, k)
				kind[_i(c)] = HOME if x == ex else FACE
			else:
				var col := 0 if x == 0 else (2 if x == plan.size.x - 1 else 1)
				features[c] = WALL_FACE + Vector2i(col, k)
				kind[_i(c)] = FACE
	var door := at + Vector2i(ex, plan.size.y + 1)
	homes.append({"origin": at, "plan": plan, "door": door})
	# Keep the approach to the arch open, and the home off-limits to scatter.
	_claim(Rect2i(at, need).grow(1))
	_claim(Rect2i(door + Vector2i(-1, 1), Vector2i(3, 2)))
	# The walker must be able to get in: the entry room is a goal.
	for d in [Vector2i(0, -2), Vector2i(0, -3), Vector2i(0, -4)]:
		var inside: Vector2i = at + plan.exit_cell + d
		if kind[_i(inside)] == HOME and not blocked.has(inside):
			goals.append(inside)
			break
	notes.append("home %d rooms %s" % [plan.rooms.size(), ",".join(plan.rooms.map(func(r): return r.type))])


# A rock island: a solid rectangle of wall mass (3-7 x 2-3) with its face.
func _island() -> void:
	for i in 60:
		var size := Vector2i(_rng.randi_range(4, 8), _rng.randi_range(3, 4))
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(6, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(Rect2i(r.position, r.size + Vector2i(0, 2)).grow(2)):
			continue
		var cells := {}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells[Vector2i(x, y)] = true
		_raise(cells, WALL, WALL_TOP, WALL_FACE, 16, WALL_FACE_VARIANTS, recipe.get("faces", ""))
		islands.append(r)
		_claim(Rect2i(r.position, r.size + Vector2i(0, 2)).grow(1))
		return


# A terrace: raised walkable floor (5-9 x 3-4) over its face, with stairs
# three wide cut into the face.
func _terrace() -> void:
	for i in 60:
		var size := Vector2i(_rng.randi_range(6, 10), _rng.randi_range(3, 4))
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(6, H - size.y - 10))
		var r := Rect2i(at, size)
		if not _free(Rect2i(r.position, r.size + Vector2i(0, 3)).grow(2)):
			continue
		var cells := {}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells[Vector2i(x, y)] = true
		_raise(cells, TERRACE, TERRACE_TOP, TERRACE_FACE, 5, TERRACE_FACE_VARIANTS, "")
		# Stairs: they replace the rim cell and the two face cells of three
		# columns; the columns beside them get the stair sides.
		var sx := _rng.randi_range(r.position.x + 1, r.end.x - 4)
		var y0 := r.end.y - 1
		for c in 3:
			for k in 3:
				var cell := Vector2i(sx + c, y0 + k)
				features[cell] = STAIRS + Vector2i(c, k)
				kind[_i(cell)] = STAIR if k > 0 else TERRACE
		for k in 3:
			features[Vector2i(sx - 1, y0 + k)] = Vector2i(9, 8 + k)
			features[Vector2i(sx + 3, y0 + k)] = Vector2i(13, 8 + k)
		terraces.append(r)
		goals.append(Vector2i(sx + 1, r.position.y + 1)) # the top must be reachable
		_claim(Rect2i(r.position, r.size + Vector2i(0, 2)).grow(1))
		# Keep the foot of the stairs clear.
		for c in range(-1, 4):
			_occupied[Vector2i(sx + c, y0 + 3)] = true
		return


# Marks `cells` as `k`, autotiles their top from `top` (a 3x3 block whose
# bottom row is the rim over the face), and paints the two face rows under
# every bottom-edge cell from `face`; `variant_cols` give face variants whose
# rim sits at `variant_rim_row` and face rows below it.
func _raise(cells: Dictionary, k: int, top: Vector2i, face: Vector2i, variant_rim_row: int, variant_cols: Array[int], style: String) -> void:
	for c in cells:
		kind[_i(c)] = k
		var m := _mask_edge(c, cells)
		features[c] = top + ROLES.get(m, Vector2i(1, 1))
	for c in cells:
		if cells.has(c + Vector2i.DOWN) or c.y + 1 >= H:
			continue
		var west: bool = cells.has(c + Vector2i.LEFT) or c.x == 0
		var east: bool = cells.has(c + Vector2i.RIGHT) or c.x == W - 1
		var col := 1 if west and east else (0 if not west else 2)
		var use_variant := col == 1 and _rng.randf() < (0.6 if style == "skull" else 0.35)
		if use_variant:
			var v: int = variant_cols[_rng.randi() % variant_cols.size()]
			if style == "skull" and _rng.randf() < 0.6:
				v = SKULL_FACE
			features[c] = Vector2i(v, variant_rim_row)
			for d in 2:
				_face(c + Vector2i(0, 1 + d), Vector2i(v, variant_rim_row + 1 + d))
		else:
			for d in 2:
				_face(c + Vector2i(0, 1 + d), face + Vector2i(col, d))


func _face(c: Vector2i, atlas: Vector2i) -> void:
	if c.y >= H:
		return
	kind[_i(c)] = FACE
	features[c] = atlas


# A pool: water in a rectangle, a one-cell stone ring round it, and a dark
# zone under ring and margin so the ring's grey matches the floor. A lake is
# larger and has deep water in its middle and stalagmites standing in it.
func _pool(size: Vector2i, lake: bool) -> void:
	for i in 80:
		var r := Rect2i(Vector2i(_rng.randi_range(3, W - size.x - 3), _rng.randi_range(7, H - size.y - 7)), size)
		if not _free(r.grow(3)):
			continue
		_pool_at(r, lake)
		return


## The pool in rectangle `r` (its ring one cell outside it), as _pool lays it.
func _pool_at(r: Rect2i, lake: bool) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			kind[_i(c)] = WATER
			var n := y == r.position.y
			var s := y == r.end.y - 1
			var w := x == r.position.x
			var e := x == r.end.x - 1
			var t := OPEN_WATER
			if n and w:
				t = Vector2i(28, 3)
			elif n and e:
				t = Vector2i(25, 3)
			elif s and w:
				t = Vector2i(28, 0)
			elif s and e:
				t = Vector2i(25, 0)
			elif n:
				t = Vector2i(22, 3)
			elif w:
				t = Vector2i(24, 1)
			elif e:
				t = Vector2i(20, 1)
			features[c] = t
			anim[c] = "open" if t == OPEN_WATER else "pool"
	# The ring: stone with the bank toward the water.
	for x in range(r.position.x, r.end.x):
		_ring(Vector2i(x, r.position.y - 1), Vector2i(22, 2))
		_ring(Vector2i(x, r.end.y), Vector2i(22, 0))
	for y in range(r.position.y, r.end.y):
		_ring(Vector2i(r.position.x - 1, y), Vector2i(23, 1))
		_ring(Vector2i(r.end.x, y), Vector2i(21, 1))
	_ring(r.position - Vector2i.ONE, Vector2i(27, 2))
	_ring(Vector2i(r.end.x, r.position.y - 1), Vector2i(26, 2))
	_ring(Vector2i(r.position.x - 1, r.end.y), Vector2i(27, 1))
	_ring(r.end, Vector2i(26, 1))
	if lake:
		# Deep water in the middle, inset two cells, and stalagmites in it.
		var core := r.grow(-2)
		for y in range(core.position.y, core.end.y):
			for x in range(core.position.x, core.end.x):
				features[Vector2i(x, y)] = DEEP[posmod(x, 6) + 6 * posmod(y, 2)]
				anim.erase(Vector2i(x, y))
	var open: Array[Vector2i] = []
	for y in range(r.position.y + 1, r.end.y - 1):
		for x in range(r.position.x + 1, r.end.x - 1):
			if features[Vector2i(x, y)] == OPEN_WATER:
				open.append(Vector2i(x, y))
	for k in (_rng.randi_range(1, 3) if lake else _rng.randi_range(0, 1)):
		if open.is_empty():
			break
		var c: Vector2i = open.pop_at(_rng.randi() % open.size())
		if features.get(c + Vector2i.DOWN) == OPEN_WATER and c.y + 1 < r.end.y - 1:
			# A stalagmite standing in the water, two cells tall.
			var col := 30 + _rng.randi() % 2
			water_deco[c] = Vector2i(col, 4)
			water_deco[c + Vector2i.DOWN] = Vector2i(col, 5)
			blocked[c + Vector2i.DOWN] = true
		else:
			water_deco[c] = Vector2i(34, 5) # water weed
	# Sparkles on about a third of the open water left.
	for c in open:
		if _rng.randf() < 0.35 and not water_deco.has(c):
			sparkles[c] = Vector2i(29, 9 + _rng.randi() % 2)
	pools.append(r)
	# The dark zone round the pool: a rounded, lumpy halo two to four
	# cells past the ring.
	for y in range(r.position.y - 5, r.end.y + 5):
		for x in range(r.position.x - 5, r.end.x + 5):
			var c := Vector2i(x, y)
			if not _inside(c) or kind[_i(c)] != FLOOR:
				continue
			var dx := maxf(maxf(r.position.x - x, x - (r.end.x - 1)), 0.0)
			var dy := maxf(maxf(r.position.y - y, y - (r.end.y - 1)), 0.0)
			var reach := 2.6 + 1.6 * absf(sin(x * 0.9 + y * 0.6 + map_id))
			if Vector2(dx, dy).length() <= reach:
				zone[c] = true
	_claim(r.grow(1))


func _ring(c: Vector2i, atlas: Vector2i) -> void:
	if _inside(c):
		features[c] = atlas
		anim[c] = "pool"


# ---------------------------------------------------------------- goal, rails

# The goal: the farthest of a few open cells from the spawn, with room for a
# set piece around it.
func _pick_goal() -> void:
	var best := -1.0
	for i in 60:
		var c := Vector2i(_rng.randi_range(6, W - 7), _rng.randi_range(8, H - 12))
		if not _free(Rect2i(c - Vector2i(3, 3), Vector2i(7, 7))):
			continue
		var d := Vector2(c - spawn).length()
		if d > best:
			best = d
			goal = c
	if best < 0.0:
		goal = Vector2i(W / 2, H / 2)
	goals.append(goal)


# A mine track from the spawn to the goal: at most two bends, straight runs
# with curve cells at the turns, on free floor.
func _lay_rails() -> void:
	var a := spawn + Vector2i(0, -2)
	var b := goal + Vector2i(0, 2)
	for tries in 40:
		var mid := _rng.randi_range(mini(a.x, b.x), maxi(a.x, b.x))
		var ym := _rng.randi_range(mini(a.y, b.y) + 1, maxi(a.y, b.y) - 1) if absi(a.y - b.y) > 2 else a.y
		var pts: Array[Vector2i] = [a, Vector2i(a.x, ym), Vector2i(b.x, ym), b]
		if tries % 2 == 1:
			pts = [a, Vector2i(mid, a.y), Vector2i(mid, b.y), b]
		var cells: Array[Vector2i] = []
		for k in range(pts.size() - 1):
			var p := pts[k]
			var q := pts[k + 1]
			var step := Vector2i(signi(q.x - p.x), signi(q.y - p.y))
			var c := p
			while c != q:
				if cells.is_empty() or cells[-1] != c:
					cells.append(c)
				c += step
		cells.append(b)
		var ok := cells.size() > 3
		for c in cells:
			if not _inside(c) or kind[_i(c)] != FLOOR or (_occupied.has(c) and Vector2(c - spawn).length() > 3.5):
				ok = false
				break
		if not ok:
			continue
		for i in cells.size():
			var c: Vector2i = cells[i]
			var dirs := {}
			for o in [cells[i - 1] if i > 0 else null, cells[i + 1] if i + 1 < cells.size() else null]:
				if o != null:
					dirs[o - c] = true
			var t := RAIL_H
			if dirs.has(Vector2i.UP) or dirs.has(Vector2i.DOWN):
				t = RAIL_V
			if dirs.size() == 2 and not (dirs.has(Vector2i.LEFT) and dirs.has(Vector2i.RIGHT)) and not (dirs.has(Vector2i.UP) and dirs.has(Vector2i.DOWN)):
				var key := ("E" if dirs.has(Vector2i.RIGHT) else "W") + ("S" if dirs.has(Vector2i.DOWN) else "N")
				t = RAIL_CURVE[key]
			features[c] = t
			rails[c] = true
		notes.append("rails %d cells" % cells.size())
		return
	notes.append("rails dropped (no clear route)")


# ---------------------------------------------------------------- set pieces

func _lay_piece() -> void:
	var g := goal
	match recipe.piece:
		"cairn":
			_near(["boulder", "rock"], 2, g, 3)
			_near(["crystal_cyan", "crystal_blue", "crystal_violet"], 2, g, 2)
		"crystal_ring":
			for k in 8:
				var a := TAU * k / 8.0
				_try(CRYSTALS[_rng.randi() % 3], g + Vector2i(roundi(cos(a) * 3.0), roundi(sin(a) * 2.0)))
			_near(["rock_tree_crystal"], 1, g, 4)
		"mine":
			_near(["cart", "cart_empty"], 2, g, 3)
			_near(["coal_pile", "coal"], 3, g, 3)
			_near(["crates", "barrel"], 2, g, 4)
			_near(["torch"], 2, g, 3)
		"camp":
			_try("campfire", g)
			_near(["branch", "branch_moss"], 2, g, 3)
			_near(["crates", "barrel", "chest"], 3, g, 4)
			_near(["embers"], 1, g, 2)
		"grove":
			_near(["tree_mossy", "rock_tree_moss", "tree_dead"], 3, g, 5)
			_near(["bush", "bush_small"], 1, g, 5)
			_near(["plant", "plant_flower"], 4, g, 3)
		"terrace_top":
			if not terraces.is_empty():
				var t: Rect2i = terraces[0]
				goal = Vector2i(t.get_center().x, t.position.y + 1)
				_near(["signpost", "torch"], 2, t.get_center(), 3, true)
				_near(["chest", "crystal_blue"], 1, t.get_center(), 3, true)
		"bones":
			_near(["skull", "skull_b", "rock_skull"], 6, g, 4)
			_near(["pillar"], 2, g, 4)
		"colonnade":
			for x in range(g.x - 6, g.x + 7, 3):
				_try("pillar", Vector2i(x, g.y - 3))
				_try("pillar", Vector2i(x, g.y + 3))
			_try("chest", g + Vector2i(1, 0))
		"spring":
			_near(["plant", "plant_flower", "grass_clump"], 4, g, 4)
			_near(["cone", "cone_small"], 2, g, 4)
		"doorway":
			_near(["signpost"], 1, g, 3)
			_near(["torch"], 2, g, 3)
			_near(["rock", "boulder"], 2, g, 4)
		"cache":
			_near(["crates", "crate", "barrel", "barrel_b", "chest", "chest_b"], 6, g, 4)
			_near(["ladder", "board"], 2, g, 4)
		"shrine":
			_try("pillars", g + Vector2i(-1, -2))
			_near(["crystal_violet", "crystal_cyan", "crystal_blue"], 4, g, 3)
			_try("chest_open", g + Vector2i(0, 1))
		"cellar":
			_near(["barrel", "barrel_b", "crates", "trough"], 5, g, 4)
			_near(["rock_tree", "tree_dead"], 1, g, 5)
		"coal":
			_near(["coal_pile", "coal"], 6, g, 4)
			_near(["cart", "cart_empty"], 2, g, 4)
		"crossroads":
			_try("signpost", g)
			_near(["board", "board_b"], 2, g, 3)
		"vault":
			_near(["chest", "chest_b", "chest_open"], 3, g, 3)
			_near(["pillar"], 4, g, 4)
			_near(["crystal_violet", "shard_violet"], 3, g, 3)


# Places up to `count` of `arts` on free floor within `radius` of `center`
# (on a terrace top when `on_terrace`).
func _near(arts: Array, count: int, center: Vector2i, radius: int, on_terrace := false) -> int:
	var placed := 0
	for i in 80:
		if placed >= count:
			break
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if c == goal and not on_terrace:
			continue
		if _try(arts[_rng.randi() % arts.size()], c, on_terrace):
			placed += 1
	return placed


func _try(art: String, anchor: Vector2i, on_terrace := false) -> bool:
	var p: Dictionary = PROPS[art]
	var foot: Rect2i = p.foot_cells
	var want := TERRACE if on_terrace else FLOOR
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			var c := anchor + Vector2i(x, y)
			if not _inside(c) or kind[_i(c)] != want or _occupied.has(c) or rails.has(c) or c == spawn:
				return false
			if not on_terrace and _in_lane(c):
				return false
	props.append({"art": art, "cell": anchor})
	for y in range(foot.position.y, foot.end.y):
		for x in range(foot.position.x, foot.end.x):
			_occupied[anchor + Vector2i(x, y)] = true
	if p.block != Vector2.ZERO:
		for x in range(foot.position.x, foot.end.x):
			blocked[anchor + Vector2i(x, foot.end.y - 1)] = true
	if p.tag == "fire" or p.tag == "torch":
		fires.append(anchor)
	return true


# The straight lane from the spawn to the goal stays open near both ends.
func _in_lane(c: Vector2i) -> bool:
	return Vector2(c - goal).length() < 1.5 or Vector2(c - spawn).length() < 2.5


# ---------------------------------------------------------------- floor

# Dark floor zones: a smooth noise field cut at the recipe's share, grown
# round every pool, then trimmed to shapes the blob set can draw.
func _zones() -> void:
	var share: float = recipe.zones
	if share > 0.0 and recipe.floor == "light":
		var noise := FastNoiseLite.new()
		noise.seed = map_id * 31 + attempt
		noise.frequency = 0.07
		var values: Array[float] = []
		for y in H:
			for x in W:
				values.append(noise.get_noise_2d(x, y))
		var sorted := values.duplicate()
		sorted.sort()
		var cut: float = sorted[int((1.0 - share) * sorted.size())]
		for y in H:
			for x in W:
				if values[y * W + x] >= cut and kind[_i(Vector2i(x, y))] == FLOOR:
					zone[Vector2i(x, y)] = true
	if recipe.floor == "dark":
		zone.clear() # the dark floor is the zone's own grey; moss keeps its pool halos
		return
	# Trim: cells the blob set cannot draw (a lone cell, a one-wide strip, two
	# open diagonals) are dropped until every cell has a tile.
	while true:
		var drop: Array[Vector2i] = []
		for c in zone:
			if not ROLES.has(_mask(c, zone)):
				drop.append(c)
			elif _mask(c, zone) == 15 and _open(c, zone) != 0 and not ZONE_INNER.has(_open(c, zone)):
				drop.append(c)
		if drop.is_empty():
			break
		for c in drop:
			zone.erase(c)
	_drop_specks(zone, 10)
	for c in zone:
		var m := _mask(c, zone)
		var o := _open(c, zone)
		zone_tiles[c] = ZONE_INNER[o] if m == 15 and o != 0 else ZONE + ROLES[m]


# Two to four small dark patches baked on the light floor (the sheet's own
# blob with light corners), away from the zones.
func _accents() -> void:
	if recipe.floor != "light":
		return
	var want := _rng.randi_range(2, 4)
	for i in 80:
		if want == 0:
			return
		var size := Vector2i(_rng.randi_range(2, 4), _rng.randi_range(2, 3))
		var at := Vector2i(_rng.randi_range(1, W - size.x - 1), _rng.randi_range(5, H - size.y - 1))
		var ok := true
		for y in range(at.y - 1, at.y + size.y + 1):
			for x in range(at.x - 1, at.x + size.x + 1):
				var c := Vector2i(x, y)
				if not _inside(c) or kind[_i(c)] != FLOOR or zone.has(c) or accents.has(c) or rails.has(c):
					ok = false
		if not ok:
			continue
		var cells := {}
		for y in range(at.y, at.y + size.y):
			for x in range(at.x, at.x + size.x):
				cells[Vector2i(x, y)] = true
		for c in cells:
			accents[c] = ACCENT + ROLES.get(_mask(c, cells), Vector2i(1, 1))
		want -= 1


# Removes 4-connected pieces of `cells` smaller than `min_size`.
func _drop_specks(cells: Dictionary, min_size: int) -> void:
	var seen := {}
	for start in cells.keys():
		if seen.has(start):
			continue
		var part: Array[Vector2i] = [start]
		seen[start] = true
		var i := 0
		while i < part.size():
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var n: Vector2i = part[i] + d
				if cells.has(n) and not seen.has(n):
					seen[n] = true
					part.append(n)
			i += 1
		if part.size() < min_size:
			for c in part:
				cells.erase(c)


func _paint_floor() -> void:
	var tiles: Array[Vector2i] = LIGHT_FLOOR
	if recipe.floor == "dark":
		tiles = DARK_FLOOR
	elif recipe.floor == "moss":
		tiles = MOSS_FLOOR
	for y in H:
		for x in W:
			floor_tiles[Vector2i(x, y)] = tiles[posmod(x * 7 + y * 13 + map_id, tiles.size())]


# ---------------------------------------------------------------- scatter

func _scatter() -> void:
	var lists := {"ROCKS": ROCKS, "ORES": ORES, "CRYSTALS": CRYSTALS, "CONES": CONES, "TREES": TREES, "PLANTS": PLANTS,
		"CLUTTER": CLUTTER, "BONES": ["skull", "skull_b", "rock_skull"], "BRANCHES": ["branch", "branch_moss"]}
	for pair in recipe.scatter:
		var name: String = pair[0]
		if name == "TUFTS":
			var put := 0
			for i in 400:
				if put >= pair[1]:
					break
				var c := Vector2i(_rng.randi_range(1, W - 2), _rng.randi_range(1, H - 2))
				if kind[_i(c)] == FLOOR and not _occupied.has(c) and not rails.has(c) and not deco.has(c):
					deco[c] = TUFTS[_rng.randi() % TUFTS.size()]
					put += 1
			continue
		var arts: Array = lists[name]
		var placed := 0
		var want := roundi(pair[1] * 1.4)
		for i in 400:
			if placed >= want:
				break
			var c := Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(4, H - 3))
			if Vector2(c - goal).length() < 4.0 or Vector2(c - spawn).length() < 4.0:
				continue
			if _try(arts[_rng.randi() % arts.size()], c):
				placed += 1
	# Small floor bits everywhere: pebbles, shards, coal, a skull.
	var bits: Array[String] = ["cone_small", "shard_cyan", "shard_blue", "coal", "cone_small", "skull"]
	var put := 0
	var want_bits := _rng.randi_range(10, 16)
	for i in 300:
		if put >= want_bits:
			break
		var c := Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(4, H - 3))
		if Vector2(c - spawn).length() >= 3.0 and _try(bits[_rng.randi() % bits.size()], c):
			put += 1
	# Wall torches along the back wall's face, in pairs.
	for i in recipe.torches:
		for t in 30:
			var x := _rng.randi_range(3, W - 6)
			var y := _face_bottom(x)
			if y < 0:
				continue
			if _try("torch", Vector2i(x, y + 1)) and _try("torch", Vector2i(x + 3, y + 1)):
				break


# The first floor row under the back wall's face at column x, or -1.
func _face_bottom(x: int) -> int:
	for y in range(0, 8):
		if kind[_i(Vector2i(x, y))] == FACE and kind[_i(Vector2i(x, y + 1))] == FLOOR:
			return y
	return -1


# ---------------------------------------------------------------- liveliness
# The Painted Lands floor: every 43 x 18 window should have something moving.
# Motion is estimated with the calibrated weights (animated water, fire glow
# and smoke, the leaves of mossy trees); a window under FLOOR gets a torch
# pair on a free spot, a campfire, or a small pool. At most five anchors.
const LIVE_FLOOR := 0.2
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_ANCHORS := 6
# Frozen from the 2026-09-27 cave calibration (tools/liveliness_coef_caves.json,
# weight x feature per anchor), so a new calibration never changes existing maps.
const FLOOR_WATER := 0.652 # per animated pool cell
const FLOOR_SPARKLE := 0.162 # per sparkle cell
const FLOOR_FIRE := 139.0 # a campfire: glow 4.75 cells x 21.18, smoke 38.2
const FLOOR_TORCH := 30.5 # a torch: glow 1.44 cells x 21.18
const FLOOR_TREE := 4.17
const FLOOR_HEARTH := 60.0 # a home's hearth: glow, no smoke (estimated from the torch and campfire glows)
const FLOOR_LAMP := 12.0 # a lamp in a home

func _liveliness_floor() -> void:
	var added := 0
	for n in FLOOR_ANCHORS + 1:
		var weak := _weakest_window()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR or n == FLOOR_ANCHORS:
			if n > 0:
				floor_notes.append("-> %.3f%%" % weak.value)
			return
		var win: Rect2i = weak.rect
		var inner := win.grow_individual(-8, -3, -8, -3)
		var c := Vector2i(_rng.randi_range(inner.position.x, inner.end.x - 1), _rng.randi_range(inner.position.y, inner.end.y - 1))
		var done := false
		for t in 40:
			c = Vector2i(_rng.randi_range(inner.position.x, inner.end.x - 1), _rng.randi_range(inner.position.y, inner.end.y - 1))
			if (added % 3 != 2 or t > 20) and _try("campfire", c):
				_near(["branch", "branch_moss"], 1, c, 2)
				done = true
				floor_notes.append("campfire")
				break
			if _try("torch", c) and _try("torch", c + Vector2i(3, 0)):
				done = true
				floor_notes.append("torches")
				break
		if not done:
			floor_notes.append("-> %.3f%%" % weak.value)
			return
		added += 1


## In a maze: a campfire in a dead end of the weak window, or a pair of wall
## torches on its faces (CaveMaze.floor_anchor); up to twice the anchors.
func _maze_floor() -> void:
	for n in FLOOR_ANCHORS * 2 + 1:
		var weak := _weakest_window()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR or n == FLOOR_ANCHORS * 2 or not _maze.floor_anchor(weak.rect):
			floor_notes.append("-> %.3f%%" % weak.value)
			return
		floor_notes.append("anchor")


func _weakest_window() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(W * H)
	m.fill(0.0)
	for c in anim:
		m[_i(c)] += FLOOR_WATER
	for c in sparkles:
		m[_i(c)] += FLOOR_SPARKLE
	for h in homes:
		for it in h.plan.items:
			var a: Dictionary = InteriorArt.ART.get(it.art, {})
			var cell: Vector2i = h.origin + Vector2i(it.pos / TILE)
			if not _inside(cell):
				continue
			if a.has("hearth"):
				m[_i(cell)] += FLOOR_HEARTH
			elif a.has("lamp"):
				m[_i(cell)] += FLOOR_LAMP
	for p in props:
		var tag: String = PROPS[p.art].tag
		var c: Vector2i = p.cell
		if not _inside(c):
			continue
		if tag == "fire":
			m[_i(c)] += FLOOR_FIRE
		elif tag == "torch":
			m[_i(c)] += FLOOR_TORCH
		elif p.art in ["tree_mossy", "rock_tree_moss"]:
			m[_i(c)] += FLOOR_TREE
	var best := {"rect": Rect2i(), "value": INF}
	var area := float(FLOOR_VIEW.x * FLOOR_VIEW.y)
	# Every other offset, and always the last one on each axis (the map's
	# right and bottom edge).
	var xs: Array[int] = []
	var ys: Array[int] = []
	for x in range(0, W - FLOOR_VIEW.x + 1, 2):
		xs.append(x)
	for y in range(0, H - FLOOR_VIEW.y + 1, 2):
		ys.append(y)
	if xs[-1] != W - FLOOR_VIEW.x:
		xs.append(W - FLOOR_VIEW.x)
	if ys[-1] != H - FLOOR_VIEW.y:
		ys.append(H - FLOOR_VIEW.y)
	for y in ys:
		for x in xs:
			var s := 0.0
			for yy in range(y, y + FLOOR_VIEW.y):
				for xx in range(x, x + FLOOR_VIEW.x):
					s += m[yy * W + xx]
			if s / area < best.value:
				best = {"rect": Rect2i(x, y, FLOOR_VIEW.x, FLOOR_VIEW.y), "value": s / area}
	return best


# ---------------------------------------------------------------- ambience inputs
# What the painter hands the effect scripts, here so that the liveliness
# estimate (scripts/cave_liveliness_features.gd) sees exactly the same.

## Every water cell of every pool.
func water_cells() -> Dictionary:
	var out := {}
	for r in pools:
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				out[Vector2i(x, y)] = true
	return out


## Water cells away from the pool's edge, without stalagmites or weed: where
## ripples, fish, and drips from above can be.
func open_water() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r in pools:
		for y in range(r.position.y + 1, r.end.y - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				if not water_deco.has(Vector2i(x, y)):
					out.append(Vector2i(x, y))
	return out


## Drip spots in world pixels, {top, floor, water}: two per face cell over
## floor, falling from the face's top to just past its foot, and one in
## three open water cells, from the dark above.
func drip_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for y in H - 1:
		for x in W:
			if kind[_i(Vector2i(x, y))] == FACE and kind[_i(Vector2i(x, y + 1))] == FLOOR:
				for i in 2:
					var px := x * TILE + 3 + absi(hash(Vector3i(x, y, i))) % 10
					out.append({"top": Vector2(px, (y - 1) * TILE + 6), "floor": Vector2(px, (y + 1) * TILE + 2), "water": false})
	for c in open_water():
		if absi(hash(c)) % 3 == 0:
			var p := Vector2(c * TILE) + Vector2(8, 8)
			out.append({"top": p - Vector2(0, 40), "floor": p, "water": true})
	return out


## Where the glowworms (critters.gd fireflies) drift: one in three open
## floor cells on moss, on the dark floor, or in a dark zone.
func glow_cells() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != FLOOR or blocked.has(c):
				continue
			if (recipe.floor != "light" or zone.has(c)) and absi(hash(c)) % 3 == 0:
				out.append(Vector2(c * TILE) + Vector2(8, 8))
	return out


## Anchor cells of trees and bushes (squirrel trunks, quiet sources).
func trunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in props:
		if PROPS[p.art].tag in ["tree", "bush"]:
			out.append(p.cell)
	return out


## The wildlife plan (wildlife.gd plan_from): mice by clutter and bones,
## frogs on the pool banks, lizards by rocks and ore, voles on moss and by
## tufts. The outdoor species find no habitat in a cave, so none are planned.
## `p_mode` "pack": the Cozy Farm bunny and farm animals by the homes too.
func wildlife_plan(p_mode := "") -> Dictionary:
	var water := water_cells()
	var land := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if walkable(c) and (kind[_i(c)] == FLOOR or kind[_i(c)] == HOME):
				land[c] = true
	var clutter: Array[Vector2i] = []
	var rocks: Array[Vector2i] = []
	for p in props:
		var tag: String = PROPS[p.art].tag
		if tag == "clutter" or tag == "bones":
			clutter.append(p.cell)
		elif tag == "rock" or tag == "ore":
			rocks.append(p.cell)
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	var moss: bool = recipe.floor == "moss"
	for c in land:
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i(0, 2), Vector2i(0, -2), Vector2i(2, 0), Vector2i(-2, 0)]:
			if water.has(c + d):
				h.shore[c] = true
		if _near_any(c, clutter, 2) or kind[_i(c)] == HOME:
			h.clutter[c] = true # mice by crates and bones, and in every home
		if _near_any(c, rocks, 2):
			h.rocky[c] = true
		if (moss or deco.has(c)) and not h.shore.has(c):
			h.dark[c] = true
	if p_mode == "pack":
		# The Cozy Farm animals (wildlife.gd PACK_SPECIES): bunnies on the
		# moss floors, and poultry and pigs in the yard outside each home's
		# arch, sheep and goats on the moss round it.
		var open_floor := {}
		var grazing := {}
		for c in land:
			if kind[_i(c)] == FLOOR:
				open_floor[c] = true
				if moss and not h.shore.has(c):
					grazing[c] = true
		h.lawn = grazing
		var doors: Array[Vector2i] = []
		for home in homes:
			doors.append(home.door + Vector2i(0, 1))
		Wildlife.add_homesteads(h, doors, open_floor, grazing)
	h["_land"] = land
	var trunk_set := {}
	var tr := trunks()
	for t in tr:
		trunk_set[t] = true
	h["_trunks"] = trunk_set
	h["_w"] = W
	var quiet: Array[Vector2i] = []
	quiet.append_array(water.keys())
	quiet.append_array(fires)
	quiet.append_array(tr)
	return Wildlife.plan_from(h, map_id, spawn, Wildlife.quiet_from(quiet, W, H), p_mode)


func _near_any(c: Vector2i, cells: Array[Vector2i], r: int) -> bool:
	for o in cells:
		if absi(o.x - c.x) <= r and absi(o.y - c.y) <= r:
			return true
	return false


# ---------------------------------------------------------------- checks

func walkable(c: Vector2i) -> bool:
	if not _inside(c) or blocked.has(c):
		return false
	var k := kind[_i(c)]
	return k == FLOOR or k == TERRACE or k == STAIR or k == HOME


func _reaches_all() -> bool:
	for g in goals:
		if not _reaches(spawn, g):
			return false
	return true


# Walk over floor, stairs, and terrace tops; a terrace top is entered only
# from its stairs (the rim above a face is a drop).
func _reaches(from: Vector2i, to: Vector2i) -> bool:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c == to:
			return true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if seen.has(n) or not walkable(n):
				continue
			var ka := kind[_i(c)]
			var kb := kind[_i(n)]
			if (ka == FLOOR and kb == TERRACE) or (ka == TERRACE and kb == FLOOR):
				continue
			seen[n] = true
			queue.append(n)
	return false


func _report() -> String:
	var counts := [0, 0, 0, 0, 0, 0, 0]
	for k in kind:
		counts[k] += 1
	if not _reaches_all():
		fails.append("spawn does not reach every goal")
	if recipe.get("rails", false) and rails.is_empty():
		fails.append("no rails")
	if (recipe.pools[0] > 0 or recipe.get("lake", false)) and pools.is_empty():
		fails.append("no pool")
	if recipe.get("homes", [0, 0])[0] > homes.size():
		fails.append("homes %d of %d" % [homes.size(), recipe.homes[0]])
	if recipe.terraces[0] > 0 and terraces.is_empty():
		fails.append("no terrace")
	if maze:
		if not maze_info.has("corridors"):
			fails.append("no maze laid")
		else:
			var cut: Array[Vector2i] = _maze.unreached()
			if not cut.is_empty():
				fails.append("%d maze cells cut off" % cut.size())
	var lines := PackedStringArray([
		"Green Caves map %d: recipe %d %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, W, H, attempt],
		"  cells: floor %d, wall %d, face %d, terrace %d, stair %d, water %d, home %d" % counts,
		"  pools %d, terraces %d, islands %d, homes %d, rails %d, zone %d cells, props %d, fires %d" % [pools.size(), terraces.size(),
			islands.size(), homes.size(), rails.size(), zone.size(), props.size(), fires.size()],
		"  %s" % ", ".join(notes),
	])
	if not floor_notes.is_empty():
		lines.append("  floor: %s" % " ".join(floor_notes))
	lines.append("  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)))
	return "\n".join(lines)


# ---------------------------------------------------------------- helpers

func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _occupied.has(c) or kind[_i(c)] != FLOOR:
				return false
	return true


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_occupied[Vector2i(x, y)] = true


func _claim_disk(c: Vector2i, radius: int) -> void:
	for y in range(c.y - radius, c.y + radius + 1):
		for x in range(c.x - radius, c.x + radius + 1):
			if Vector2(x - c.x, y - c.y).length() <= radius:
				_occupied[Vector2i(x, y)] = true


# Cardinal mask (N=1 E=2 S=4 W=8); outside the map counts as the same kind.
func _mask_edge(c: Vector2i, cells: Dictionary) -> int:
	var m := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = c + dirs[i]
		if cells.has(n) or not _inside(n):
			m |= 1 << i
	return m


func _mask(c: Vector2i, cells: Dictionary) -> int:
	var m := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		if cells.has(c + dirs[i]):
			m |= 1 << i
	return m


func _open(c: Vector2i, cells: Dictionary) -> int:
	var o := 0
	var diags := [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for i in 4:
		if not cells.has(c + diags[i]):
			o |= 1 << i
	return o


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func _i(c: Vector2i) -> int:
	return c.y * W + c.x
