class_name MSTerrain
extends RefCounted
## Mana Seed maps (Seliel the Shaper's forest collection: spring, summer,
## autumn, winter; village accessories, fences, weather, extras), built the way
## the Painted Lands and Green Caves generators build theirs: a recipe per id,
## a layout, the sheets' own systems, set pieces, scatter, a liveliness floor,
## and a walk check. Output is corner terrains, stamps, and prop placements;
## manaseed.gd paints them. Sheets in assets/pack/mana_seed/<season>/ share one
## layout, so every recipe can be drawn in any season.
##
## The sheets' systems (cells of 16 px):
##   ground    one corner-Wang sheet (wang.png, 64 columns) with every
##             combination of six terrains on the four corners of a cell
##             (MSWang.TILES): dirt, light grass (snow in winter), dark grass,
##             cobblestone, shallow water, deep water. The ground is a corner
##             grid; each cell takes the tile of its four corners, so any
##             shape blends with the pack's own hand-drawn transitions.
##   cliffs    forest.png: the plateau from the pack's usage guide, a rounded
##             grass top over a banded face, drawn on two layers plus a cast
##             shadow column. It widens by repeating its middle column pair and
##             deepens by repeating a side row (top) and a face row (face).
##             Stairs (14-16, 9-11): top on the lip row, middle on the face,
##             bottom on the foot row.
##   forest    treewall.png: 128 px supertiles, a corner autotile of forest
##             and clearing on an 8-cell grid; canopy.png is the leaves only,
##             drawn over the actors.
##   props     trees.png (three 80x112 trees), 32x32, 48x32, 16x32, 16x16
##             sheets; village accessories (torches, lamp posts, wells,
##             crates, barrels, firewood); the ranch fence; the stone bridge.

const W := 64
const H := 40
const TILE := 16
const PITCH := 8 # tree wall supertiles are 8 cells

# Corner terrains (the Wang colors).
const DIRT := 1
const LIGHT := 2
const DARK := 3
const COBBLE := 4
const SHALLOW := 5
const DEEP := 6

# Cell kinds.
const GRASS := 0
const GROUND := 1 # dirt or cobble (walkable)
const WATER := 2
const TOP := 3 # a plateau top (walkable, raised)
const FACE := 4 # cliff rim and face (blocks)
const STAIR := 5
const WALL := 6 # the forest wall (blocks)

# The usage guide's plateau (forest.png cells), 7 x 8: under layer, second
# layer, and the cast-shadow column. Vector2i(-1, -1) is empty.
const N := Vector2i(-1, -1)
const STAMP_U1 := [
	[N, N, N, N, N, N, N],
	[N, Vector2i(18, 0), N, N, Vector2i(21, 0), N, N],
	[Vector2i(17, 1), N, N, N, N, Vector2i(22, 1), N],
	[N, Vector2i(18, 2), N, N, Vector2i(21, 2), Vector2i(1, 20), N],
	[N, Vector2i(18, 3), Vector2i(19, 3), Vector2i(20, 3), Vector2i(21, 3), Vector2i(1, 20), N],
	[N, Vector2i(18, 4), Vector2i(19, 4), Vector2i(20, 4), Vector2i(21, 4), Vector2i(1, 20), N],
	[Vector2i(17, 5), Vector2i(18, 5), Vector2i(19, 5), Vector2i(20, 5), Vector2i(21, 5), Vector2i(22, 5), N],
	[N, Vector2i(18, 6), Vector2i(19, 6), Vector2i(20, 6), Vector2i(21, 6), N, N],
]
const STAMP_U2 := [
	[N, Vector2i(17, 0), Vector2i(19, 0), Vector2i(20, 0), Vector2i(22, 0), N, N],
	[Vector2i(17, 0), N, N, N, N, Vector2i(22, 0), N],
	[N, N, N, N, N, N, N],
	[Vector2i(17, 2), N, N, N, N, Vector2i(22, 2), N],
	[Vector2i(17, 3), N, N, N, N, Vector2i(22, 3), N],
	[Vector2i(17, 4), N, N, N, N, Vector2i(22, 4), N],
	[N, N, N, N, N, N, N],
	[N, N, N, N, N, N, N],
]
const SHADOW_TOP := Vector2i(13, 10)
const SHADOW_MID := Vector2i(13, 13)
const SHADOW_END := Vector2i(13, 15)
const STAIR_TOP := 9 # forest.png row, columns 14-16
const STAIR_MID := 10
const STAIR_END := 11

# Tree wall supertiles (treewall.png, 6 x 4 of 128 px) by forest corners
# TL, TR, BL, BR (1 = forest), read from the pack's autotile setup image.
const WALL_TILES := {
	"1111": [Vector2i(0, 0), Vector2i(1, 0)],
	"1110": [Vector2i(3, 0)], "1100": [Vector2i(4, 0)], "1101": [Vector2i(5, 0)],
	"1010": [Vector2i(3, 1)], "0101": [Vector2i(5, 1)],
	"1011": [Vector2i(3, 2)], "0011": [Vector2i(4, 2)], "0111": [Vector2i(5, 2)],
	"0001": [Vector2i(1, 2)], "0010": [Vector2i(2, 2)], "0100": [Vector2i(1, 3)], "1000": [Vector2i(2, 3)],
	"0110": [Vector2i(0, 2)], "1001": [Vector2i(0, 3)],
}

## Wall supertile cover: 16 px subtiles that stay drawn once the plain ground
## is cut out (any season), by supertile atlas; rows top to bottom, "#" drawn.
const WALL_COVER := {
	Vector2i(0, 0): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(1, 0): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(2, 0): ["........", "###...##", "###...##", "###...##", "###...##", "###...##", "###....#", "###...##"],
	Vector2i(3, 0): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(4, 0): ["########", "########", "########", "########", "########", "########", "###.####", "###...##"],
	Vector2i(5, 0): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(0, 1): ["########", "########", ".#######", ".#######", "...#####", "........", "#######.", "########"],
	Vector2i(1, 1): ["########", "#######.", "#######.", "#######.", ".#####..", "........", "#######.", "########"],
	Vector2i(2, 1): ["###...##", "###...##", "###...##", "###...##", "###...##", "###...##", "###....#", "##.....#"],
	Vector2i(3, 1): ["########", "#######.", "#######.", "#######.", "######..", "######..", "#######.", "########"],
	Vector2i(4, 1): ["........", "........", "........", "........", "........", "........", "........", "........"],
	Vector2i(5, 1): ["########", "########", ".#######", ".#######", "..######", "..######", "########", "########"],
	Vector2i(0, 2): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(1, 2): ["........", ".#######", "########", "########", "########", ".#######", "########", "########"],
	Vector2i(2, 2): ["........", "####....", "#####...", "#####...", "#####...", "#####...", "########", "########"],
	Vector2i(3, 2): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(4, 2): ["........", "###.####", "########", "########", "########", "########", "########", "########"],
	Vector2i(5, 2): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(0, 3): ["########", "########", "########", "########", "########", "########", "########", "########"],
	Vector2i(1, 3): ["########", "########", ".#######", ".#######", "..######", "...#####", "....####", "......##"],
	Vector2i(2, 3): ["########", "#######.", "#######.", "#######.", "######..", "#####...", "#####...", "###....."],
	Vector2i(3, 3): ["........", "........", "........", "........", "........", "........", "........", "........"],
	Vector2i(4, 3): ["........", "........", "........", "........", "........", "........", "........", "........"],
	Vector2i(5, 3): ["........", "........", "........", "........", "........", "........", "........", "........"],
}

# Ground deco on forest.png, drawn on cells whose corners are all light
# grass: flowers baked on the light grass, and small tufts.
const FLOWER_TILES: Array[Vector2i] = [Vector2i(5, 6), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6), Vector2i(5, 7), Vector2i(6, 7), Vector2i(7, 7), Vector2i(8, 7)]
const TUFT_TILES: Array[Vector2i] = [Vector2i(3, 6), Vector2i(4, 6)]

# Props: sheet (file in the season folder or village/, fences/, extras/),
# rect in px, foot (px in the rect), block (collider w, h at the foot), tag.
const PROPS := {
	"oak": {"sheet": "trees", "rect": Rect2i(0, 0, 80, 112), "foot": Vector2i(40, 108), "block": Vector2(14, 6), "tag": "tree"},
	"round": {"sheet": "trees", "rect": Rect2i(80, 0, 80, 112), "foot": Vector2i(40, 108), "block": Vector2(12, 6), "tag": "tree"},
	"birch": {"sheet": "trees", "rect": Rect2i(160, 0, 80, 112), "foot": Vector2i(40, 106), "block": Vector2(6, 4), "tag": "tree"},
	"bush": {"sheet": "32x32", "rect": Rect2i(0, 0, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(22, 6), "tag": "bush"},
	"berry_bush": {"sheet": "32x32", "rect": Rect2i(32, 0, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(22, 6), "tag": "bush"},
	"boulder": {"sheet": "32x32", "rect": Rect2i(64, 0, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "tag": "stone"},
	"boulder_wet": {"sheet": "32x32", "rect": Rect2i(96, 0, 32, 32), "foot": Vector2i(16, 30), "block": Vector2.ZERO, "tag": "water"},
	"stump": {"sheet": "32x32", "rect": Rect2i(128, 0, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(12, 5), "tag": "wood"},
	"log": {"sheet": "32x32", "rect": Rect2i(160, 0, 32, 32), "foot": Vector2i(20, 29), "block": Vector2(18, 5), "tag": "wood"},
	"lilies": {"sheet": "32x32", "rect": Rect2i(192, 0, 32, 32), "foot": Vector2i(16, 28), "block": Vector2.ZERO, "tag": "water"},
	"big_stump": {"sheet": "48x32", "rect": Rect2i(0, 0, 48, 32), "foot": Vector2i(22, 29), "block": Vector2(18, 6), "tag": "wood"},
	"big_log": {"sheet": "48x32", "rect": Rect2i(48, 0, 48, 32), "foot": Vector2i(24, 27), "block": Vector2(36, 6), "tag": "wood"},
	"birch_log": {"sheet": "48x32", "rect": Rect2i(96, 0, 48, 32), "foot": Vector2i(24, 28), "block": Vector2(38, 5), "tag": "wood"},
	"sprouts": {"sheet": "16x32", "rect": Rect2i(0, 0, 16, 32), "foot": Vector2i(8, 30), "block": Vector2.ZERO, "tag": "deco"},
	"tall_l": {"sheet": "16x32", "rect": Rect2i(16, 0, 16, 32), "foot": Vector2i(8, 30), "block": Vector2.ZERO, "tag": "tall"},
	"tall_m": {"sheet": "16x32", "rect": Rect2i(32, 0, 16, 32), "foot": Vector2i(8, 30), "block": Vector2.ZERO, "tag": "tall"},
	"tall_r": {"sheet": "16x32", "rect": Rect2i(48, 0, 16, 32), "foot": Vector2i(8, 30), "block": Vector2.ZERO, "tag": "tall"},
	"berries_red": {"sheet": "16x32", "rect": Rect2i(64, 0, 16, 32), "foot": Vector2i(8, 28), "block": Vector2(8, 4), "tag": "bush"},
	"berries_blue": {"sheet": "16x32", "rect": Rect2i(80, 0, 16, 32), "foot": Vector2i(8, 28), "block": Vector2(8, 4), "tag": "bush"},
	"rock_s": {"sheet": "16x16", "rect": Rect2i(0, 0, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "stone"},
	"mush_gold": {"sheet": "16x16", "rect": Rect2i(16, 0, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "deco"},
	"mush_gold2": {"sheet": "16x16", "rect": Rect2i(32, 0, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "deco"},
	"mush_brown": {"sheet": "16x16", "rect": Rect2i(48, 0, 16, 16), "foot": Vector2i(8, 14), "block": Vector2.ZERO, "tag": "deco"},
	"mush_cluster": {"sheet": "16x16", "rect": Rect2i(64, 0, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "deco"},
	"fungus": {"sheet": "16x16", "rect": Rect2i(80, 0, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "deco"},
	"leaf": {"sheet": "16x16", "rect": Rect2i(0, 16, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "flat"},
	"plant": {"sheet": "16x16", "rect": Rect2i(16, 16, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "deco"},
	"stick": {"sheet": "16x16", "rect": Rect2i(48, 16, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "flat"},
	"branch": {"sheet": "16x16", "rect": Rect2i(64, 16, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "flat"},
	"lily": {"sheet": "16x16", "rect": Rect2i(0, 32, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "water"},
	"lily_b": {"sheet": "16x16", "rect": Rect2i(16, 32, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "water"},
	"lily_c": {"sheet": "16x16", "rect": Rect2i(32, 32, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "water"},
	"lily_s": {"sheet": "16x16", "rect": Rect2i(48, 32, 16, 16), "foot": Vector2i(8, 12), "block": Vector2.ZERO, "tag": "water"},
	"cattail": {"sheet": "16x16", "rect": Rect2i(64, 32, 16, 16), "foot": Vector2i(8, 14), "block": Vector2.ZERO, "tag": "reed"},
	"cattail_b": {"sheet": "16x16", "rect": Rect2i(80, 32, 16, 16), "foot": Vector2i(8, 14), "block": Vector2.ZERO, "tag": "reed"},
	"pebbles": {"sheet": "16x16", "rect": Rect2i(0, 48, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "flat"},
	"stone_a": {"sheet": "16x16", "rect": Rect2i(16, 48, 16, 16), "foot": Vector2i(8, 13), "block": Vector2.ZERO, "tag": "stone"},
	"stone_b": {"sheet": "16x16", "rect": Rect2i(32, 48, 16, 16), "foot": Vector2i(8, 14), "block": Vector2(10, 4), "tag": "stone"},
	"stone_c": {"sheet": "16x16", "rect": Rect2i(48, 48, 16, 16), "foot": Vector2i(8, 14), "block": Vector2(10, 4), "tag": "stone"},
	"stone_d": {"sheet": "16x16", "rect": Rect2i(64, 48, 16, 16), "foot": Vector2i(8, 14), "block": Vector2(12, 4), "tag": "stone"},
	"fern": {"sheet": "16x16", "rect": Rect2i(0, 64, 16, 16), "foot": Vector2i(8, 14), "block": Vector2.ZERO, "tag": "deco"},
	"fern_b": {"sheet": "16x16", "rect": Rect2i(16, 64, 16, 16), "foot": Vector2i(8, 14), "block": Vector2.ZERO, "tag": "deco"},
	# Village accessories.
	"torch": {"sheet": "village/village anim 16x48", "rect": Rect2i(16, 0, 16, 48), "frames": 4, "step": Vector2i(16, 0), "foot": Vector2i(8, 46), "block": Vector2(4, 3), "tag": "torch"},
	"lamp_post": {"sheet": "village/village accessories 48x80", "rect": Rect2i(240, 80, 48, 80), "foot": Vector2i(24, 76), "block": Vector2(8, 4), "tag": "lamp"},
	"lamp_double": {"sheet": "village/village accessories 48x80", "rect": Rect2i(48, 80, 48, 80), "foot": Vector2i(24, 76), "block": Vector2(8, 4), "tag": "lamp"},
	"lamp_single": {"sheet": "village/village accessories 48x80", "rect": Rect2i(144, 80, 48, 80), "foot": Vector2i(20, 76), "block": Vector2(8, 4), "tag": "lamp"},
	"well": {"sheet": "village/village accessories 48x80", "rect": Rect2i(144, 0, 48, 80), "foot": Vector2i(24, 76), "block": Vector2(36, 12), "tag": "stone"},
	"well_roof": {"sheet": "village/village accessories 48x80", "rect": Rect2i(96, 0, 48, 80), "foot": Vector2i(24, 76), "block": Vector2(36, 12), "tag": "stone"},
	"notice": {"sheet": "village/village accessories 48x80", "rect": Rect2i(192, 0, 48, 80), "foot": Vector2i(24, 77), "block": Vector2(32, 5), "tag": "clutter"},
	"cart": {"sheet": "village/village accessories 48x80", "rect": Rect2i(240, 0, 48, 80), "foot": Vector2i(22, 76), "block": Vector2(30, 6), "tag": "clutter"},
	"chop_stump": {"sheet": "village/village accessories 32x32", "rect": Rect2i(0, 0, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(14, 6), "tag": "wood"},
	"chop_axe": {"sheet": "village/village accessories 32x32", "rect": Rect2i(32, 0, 32, 32), "foot": Vector2i(16, 29), "block": Vector2(14, 6), "tag": "wood"},
	"firewood": {"sheet": "village/village accessories 32x32", "rect": Rect2i(64, 0, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "tag": "wood"},
	"dog_house": {"sheet": "village/village accessories 32x32", "rect": Rect2i(96, 0, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(24, 8), "tag": "clutter"},
	"crate": {"sheet": "village/village accessories 32x32", "rect": Rect2i(0, 32, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(20, 8), "tag": "clutter"},
	"crate_open": {"sheet": "village/village accessories 32x32", "rect": Rect2i(32, 32, 32, 32), "foot": Vector2i(16, 30), "block": Vector2(20, 8), "tag": "clutter"},
	"barrels": {"sheet": "village/village accessories 16x48", "rect": Rect2i(16, 0, 16, 48), "foot": Vector2i(8, 46), "block": Vector2(12, 6), "tag": "clutter"},
	"crate_tall": {"sheet": "village/village accessories 16x48", "rect": Rect2i(32, 0, 16, 48), "foot": Vector2i(8, 46), "block": Vector2(14, 6), "tag": "clutter"},
	"cypress_pot": {"sheet": "village/village accessories 16x48", "rect": Rect2i(0, 0, 16, 48), "foot": Vector2i(8, 46), "block": Vector2(10, 5), "tag": "clutter"},
	"bridge": {"sheet": "extras/bonus bridge", "rect": Rect2i(0, 0, 64, 48), "foot": Vector2i(32, 40), "block": Vector2.ZERO, "tag": "bridge"},
}
const TREE_SETS := {
	"mixed": ["oak", "round", "birch", "round"],
	"oaks": ["oak", "oak", "round"],
	"birches": ["birch", "birch", "round"],
}
const CLUTTER: Array[String] = ["crate", "crate_open", "barrels", "crate_tall"]
const SMALL: Array[String] = ["rock_s", "mush_gold", "mush_gold2", "mush_brown", "mush_cluster", "leaf", "plant", "stick", "branch", "pebbles", "stone_a", "fern", "fern_b"]

# Recipes. seasons: which seasons the id may pick; wall: none / edges /
# heavy (forest wall); zones: share of dark grass; trees: set and count;
# path: layout and terrain; tall: tall grass rows; piece: set piece.
const RECIPES := [
	{"name": "Meadow", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.18, "trees": ["mixed", 14], "ponds": [1, 1], "plateaus": [0, 0], "path": ["cross", DIRT, 1], "tall": 6, "piece": "flowers", "flowers": 90},
	{"name": "Forest glade", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "edges", "zones": 0.32, "trees": ["mixed", 22], "ponds": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT, 1], "tall": 3, "piece": "glade", "flowers": 50},
	{"name": "Lakeside", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.2, "trees": ["mixed", 16], "ponds": [0, 0], "lake": true, "plateaus": [0, 0], "path": ["shore", DIRT, 1], "tall": 4, "piece": "shore", "flowers": 50},
	{"name": "Brookside", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.22, "trees": ["mixed", 18], "ponds": [0, 0], "stream": true, "plateaus": [0, 0], "path": ["cross", DIRT, 2], "tall": 4, "piece": "flowers", "flowers": 60},
	{"name": "Cliffside", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.2, "trees": ["mixed", 16], "ponds": [0, 1], "plateaus": [1, 1], "path": ["to_plateau", DIRT, 1], "tall": 3, "piece": "rocks", "flowers": 40},
	{"name": "Terraces", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.2, "trees": ["mixed", 14], "ponds": [0, 1], "plateaus": [2, 2], "path": ["to_plateau", DIRT, 1], "tall": 3, "piece": "flowers", "flowers": 50},
	{"name": "Old road", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.2, "trees": ["oaks", 16], "ponds": [0, 1], "plateaus": [0, 0], "path": ["road", COBBLE, 2], "tall": 4, "piece": "wayside", "flowers": 40},
	{"name": "Woodcutter's camp", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "edges", "zones": 0.22, "trees": ["oaks", 18], "ponds": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT, 2], "tall": 2, "piece": "woodcut", "flowers": 30},
	{"name": "Village well", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.14, "trees": ["mixed", 12], "ponds": [0, 0], "plateaus": [0, 0], "path": ["plaza", COBBLE, 2], "tall": 2, "piece": "well", "flowers": 40},
	{"name": "Paddock", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.16, "trees": ["mixed", 12], "ponds": [0, 1], "plateaus": [0, 0], "path": ["road", DIRT, 2], "tall": 5, "piece": "paddock", "flowers": 50},
	{"name": "Marsh", "seasons": ["spring", "summer", "autumn"], "wall": "none", "zones": 0.4, "trees": ["birches", 12], "ponds": [5, 7], "plateaus": [0, 0], "path": ["trail", DIRT, 1], "tall": 8, "piece": "reeds", "flowers": 20},
	{"name": "Deep woods", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "heavy", "zones": 0.4, "trees": ["mixed", 20], "ponds": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT, 1], "tall": 2, "piece": "glade", "flowers": 25},
	{"name": "Berry thicket", "seasons": ["spring", "summer", "autumn"], "wall": "edges", "zones": 0.26, "trees": ["round", 14], "ponds": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT, 1], "tall": 3, "piece": "berries", "flowers": 60},
	{"name": "Rocky rise", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.16, "trees": ["birches", 12], "ponds": [0, 1], "plateaus": [1, 2], "path": ["to_plateau", DIRT, 1], "tall": 2, "piece": "rocks", "flowers": 30},
	{"name": "Pond garden", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "edges", "zones": 0.18, "trees": ["mixed", 12], "ponds": [2, 3], "plateaus": [0, 0], "path": ["trail", COBBLE, 1], "tall": 3, "piece": "flowers", "flowers": 80},
	{"name": "Crossroads", "seasons": ["spring", "summer", "autumn", "winter"], "wall": "none", "zones": 0.2, "trees": ["oaks", 14], "ponds": [0, 1], "plateaus": [0, 0], "path": ["cross", COBBLE, 2], "tall": 4, "piece": "wayside", "flowers": 40},
]

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var season := "summer"
var attempt := 0
var corner := PackedByteArray() # (W + 1) * (H + 1) corner terrains
var kind := PackedByteArray() # W * H cell kinds
var wall := PackedByteArray() # (W / PITCH + 1) * (H / PITCH + 1): 1 = forest
var wall_atlas := {} # supertile (i, j) -> treewall.png atlas
var wall_area := {} # cells of supertiles that touch forest
var props: Array[Dictionary] = [] # {art, cell}
var plateaus: Array[Dictionary] = [] # {rect, pieces: [{layer, cell, atlas}], stairs: [cells]}
var ponds: Array[Rect2i] = []
var water := {} # cell -> true (two or more water corners)
var paths := {} # cell -> terrain (DIRT or COBBLE): cells the path runs through
var deco := {} # cell -> forest.png atlas (flowers and tufts)
var tall := {} # cell -> true: tall grass
var bridges := {} # cell -> true: walkable over water
var blocked := {}
var fires: Array[Vector2i] = []
var goals: Array[Vector2i] = []
var spawn := Vector2i.ZERO
var notes: Array[String] = []
var fails: Array[String] = []
var floor_notes: Array[String] = []
var _taken := {}
var _rng := RandomNumberGenerator.new()


## Builds map `id` (recipe `pinned`, or id % RECIPES.size()); returns the report.
func generate(id: int, pinned := -1) -> String:
	map_id = id
	recipe_id = pinned if pinned >= 0 else id % RECIPES.size()
	recipe = RECIPES[recipe_id]
	var ss: Array = recipe.seasons
	season = ss[(id / RECIPES.size()) % ss.size()]
	for a in 30:
		attempt = a
		if _layout() and _reaches_all():
			break
	return _report()


func _layout() -> bool:
	_rng.seed = map_id * 7919 + attempt * 104729
	corner = PackedByteArray()
	corner.resize((W + 1) * (H + 1))
	corner.fill(LIGHT)
	kind = PackedByteArray()
	kind.resize(W * H)
	kind.fill(GRASS)
	wall = PackedByteArray()
	wall.resize((W / PITCH + 1) * (H / PITCH + 1))
	wall.fill(0)
	for d in [water, paths, deco, tall, bridges, blocked, hedges, wall_atlas, wall_area, _taken]:
		d.clear()
	for a in [props, plateaus, ponds, fires, goals]:
		a.clear()
	notes.clear()
	fails.clear()
	floor_notes.clear()
	# Inside the forest wall's clearing when there is one.
	spawn = Vector2i(W / 2 + _rng.randi_range(-10, 10), H - 6 if recipe.wall == "none" else H - PITCH - 3)
	_forest_wall()
	_claim(Rect2i(spawn - Vector2i(2, 2), Vector2i(5, 4)))
	for i in _rng.randi_range(recipe.plateaus[0], recipe.plateaus[1]):
		_plateau()
	if recipe.plateaus[0] > plateaus.size():
		return false
	if recipe.get("lake", false):
		_pond(Vector2i(_rng.randi_range(14, 20), _rng.randi_range(8, 11)), true)
	if recipe.get("stream", false):
		_stream()
	for i in _rng.randi_range(recipe.ponds[0], recipe.ponds[1]):
		_pond(Vector2i(_rng.randi_range(5, 9), _rng.randi_range(4, 6)), false)
	_zones()
	_lay_paths()
	_settle_kinds()
	_piece()
	_settle_kinds()
	_scatter_trees()
	_tall_grass()
	_scatter_small()
	_water_props()
	_ground_deco()
	_liveliness_floor()
	return true


# ---------------------------------------------------------------- grids

func _i(c: Vector2i) -> int:
	return c.y * W + c.x


func _ci(x: int, y: int) -> int:
	return y * (W + 1) + x


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func corner_at(x: int, y: int) -> int:
	return corner[_ci(clampi(x, 0, W), clampi(y, 0, H))]


func _set_corner(x: int, y: int, t: int) -> void:
	if x >= 0 and y >= 0 and x <= W and y <= H:
		corner[_ci(x, y)] = t


## The Wang key of a cell: TL * 1000 + TR * 100 + BL * 10 + BR.
func wang_key(c: Vector2i) -> int:
	return corner_at(c.x, c.y) * 1000 + corner_at(c.x + 1, c.y) * 100 + corner_at(c.x, c.y + 1) * 10 + corner_at(c.x + 1, c.y + 1)


func _count_corners(c: Vector2i, ts: Array) -> int:
	var n := 0
	for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		if corner_at(c.x + o.x, c.y + o.y) in ts:
			n += 1
	return n


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != GRASS:
				return false
	return true


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- forest wall

## The tree wall on its 8-cell corner grid. "edges" rings the map with forest,
## leaving the south middle (the way in) and one or two other gaps open;
## "heavy" also pushes forest in from the edges.
func _forest_wall() -> void:
	var mode: String = recipe.wall
	if mode == "none":
		return
	var gw := W / PITCH + 1
	var gh := H / PITCH + 1
	for j in gh:
		for i in gw:
			if i == 0 or j == 0 or i == gw - 1 or j == gh - 1:
				wall[j * gw + i] = 1
	# The way in under the spawn, and one or two more gaps on other sides.
	wall[(gh - 1) * gw + clampi(roundi(spawn.x / float(PITCH)), 1, gw - 2)] = 0
	var sides := [0, 1, 2]
	_shuffle(sides)
	for s in sides.slice(0, _rng.randi_range(1, 2)):
		match s:
			0: wall[0 * gw + _rng.randi_range(1, gw - 2)] = 0
			1: wall[_rng.randi_range(1, gh - 2) * gw + 0] = 0
			2: wall[_rng.randi_range(1, gh - 2) * gw + gw - 1] = 0
	if mode == "heavy":
		for n in _rng.randi_range(2, 4):
			var i := _rng.randi_range(1, gw - 2)
			var j := _rng.randi_range(1, gh - 3)
			if absi(i * PITCH - spawn.x) < 12 and j * PITCH > H / 2:
				continue
			wall[j * gw + i] = 1
	# Every supertile that touches forest is drawn as trees nearly all over
	# (the clearing shows only as small rounded bits at its clear corners), so
	# its whole area is wall ground: plain light grass, claimed. The drawn
	# cover (WALL_COVER of the chosen variant) less a one-cell rim blocks; the
	# walker can step just under the leaf edge.
	var cover := {}
	for j in H / PITCH:
		for i in W / PITCH:
			var key := wall_key(i, j)
			if key == "":
				continue
			var opts: Array = WALL_TILES[key]
			var atlas: Vector2i = opts[int(_hash(i * 11, j * 7) * opts.size()) % opts.size()]
			wall_atlas[Vector2i(i, j)] = atlas
			var rows: Array = WALL_COVER[atlas]
			for y in PITCH:
				for x in PITCH:
					var c := Vector2i(i * PITCH + x, j * PITCH + y)
					wall_area[c] = true
					_taken[c] = true
					if rows[y][x] == "#":
						cover[c] = true
	for c: Vector2i in cover:
		var inner := true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if _inside(n) and not cover.has(n):
				inner = false
		if inner:
			kind[_i(c)] = WALL


## The supertile at (i, j) (cells 8i..8i+7, 8j..8j+7): its key, or "" if clear.
func wall_key(i: int, j: int) -> String:
	var gw := W / PITCH + 1
	var k := "%d%d%d%d" % [wall[j * gw + i], wall[j * gw + i + 1], wall[(j + 1) * gw + i], wall[(j + 1) * gw + i + 1]]
	return "" if k == "0000" else k


# ---------------------------------------------------------------- plateaus

## A plateau from the guide stamp: width 7 + 2k, height 8 + a (top) + b
## (face); stairs three wide on the face when it is wide enough.
func _plateau() -> void:
	for t in 80:
		var k := _rng.randi_range(1, 4)
		var a := _rng.randi_range(0, 3)
		var b := _rng.randi_range(0, 1)
		var size := Vector2i(7 + 2 * k, 8 + a + b)
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(2, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(r.grow(2)) or r.grow(3).has_point(spawn):
			continue
		var cols: Array[int] = [0, 1]
		for n in k + 1:
			cols.append_array([2, 3])
		cols.append_array([4, 5, 6])
		var rows: Array[int] = [0, 1]
		for n in a + 1:
			rows.append(2)
		rows.append_array([3, 4])
		for n in b + 1:
			rows.append(5)
		rows.append_array([6, 7])
		var pieces: Array[Dictionary] = []
		var solid := {}
		for j in rows.size():
			for i in cols.size():
				var c := at + Vector2i(i, j)
				var u1: Vector2i = STAMP_U1[rows[j]][cols[i]]
				var u2: Vector2i = STAMP_U2[rows[j]][cols[i]]
				if u1 != N:
					pieces.append({"layer": 0, "cell": c, "atlas": u1})
					if u1 != Vector2i(1, 20):
						solid[c] = true
				if u2 != N:
					pieces.append({"layer": 1, "cell": c, "atlas": u2})
					solid[c] = true
		# The cast shadow down the last column.
		var shadow_rows: Array[int] = []
		for j in rows.size():
			if rows[j] >= 2 and rows[j] <= 5:
				shadow_rows.append(j)
		for n in shadow_rows.size():
			var atlas := SHADOW_MID
			if n == 0:
				atlas = SHADOW_TOP
			elif n == shadow_rows.size() - 1:
				atlas = SHADOW_END
			pieces.append({"layer": 2, "cell": at + Vector2i(cols.size() - 1, shadow_rows[n]), "atlas": atlas})
		# Stairs: three columns of the widened middle, on the lip, face, foot.
		var stairs: Array[Vector2i] = []
		var lip := rows.find(4)
		var sx := _rng.randi_range(2, 1 + 2 * (k + 1) - 2)
		for j in range(lip, rows.size()):
			for i in 3:
				var c := at + Vector2i(sx + i, j)
				var row := STAIR_TOP if j == lip else (STAIR_END if j == rows.size() - 1 else STAIR_MID)
				for p in pieces:
					if p.cell == c and p.layer < 2:
						p.atlas = Vector2i(14 + i, row)
				stairs.append(c)
				solid.erase(c)
		# Kinds: pieces block, stairs walk, the open top inside the rim is TOP.
		for j in rows.size():
			for i in cols.size():
				var c := at + Vector2i(i, j)
				_taken[c] = true
				if stairs.has(c):
					kind[_i(c)] = STAIR
				elif solid.has(c):
					kind[_i(c)] = FACE
				elif rows[j] >= 1 and rows[j] <= 3 and cols[i] >= 1 and cols[i] <= 4:
					kind[_i(c)] = TOP
		# The top and its rim sit on light grass.
		for y in range(at.y, r.end.y + 1):
			for x in range(at.x, r.end.x + 1):
				_set_corner(x, y, LIGHT)
		# Keep the stair foot open and nothing standing against the face.
		_claim(Rect2i(at + Vector2i(sx - 1, size.y), Vector2i(5, 2)))
		_claim(Rect2i(at.x, at.y + size.y - 1, size.x, 2))
		var foot := at + Vector2i(sx + 1, size.y)
		plateaus.append({"rect": r, "pieces": pieces, "stairs": stairs, "foot": foot, "top": at + Vector2i(sx + 1, lip - 1)})
		goals.append(at + Vector2i(sx + 1, lip - 1))
		return


# ---------------------------------------------------------------- water

## A pond on the corner grid: a lumpy ellipse, deep inside, a shallow ring on
## the shore. A lake also carries one or two grass islands.
func _pond(size: Vector2i, lake: bool) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 31 + ponds.size() * 7 + attempt
	noise.frequency = 0.18
	for t in 80:
		var at := Vector2i(_rng.randi_range(3, W - size.x - 3), _rng.randi_range(3, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(r.grow(2)):
			continue
		var c0 := Vector2(r.get_center())
		var inside := {}
		for y in range(r.position.y, r.end.y + 1):
			for x in range(r.position.x, r.end.x + 1):
				var d := Vector2((x - c0.x) / (size.x * 0.5), (y - c0.y) / (size.y * 0.5))
				if d.length() + noise.get_noise_2d(x, y) * (0.22 if lake else 0.35) < (1.0 if lake else 0.92):
					inside[Vector2i(x, y)] = true
		if inside.size() < 10:
			continue
		for v: Vector2i in inside:
			var edge := false
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
				if not inside.has(v + o):
					edge = true
			_set_corner(v.x, v.y, SHALLOW if edge else DEEP)
		if lake:
			for n in _rng.randi_range(1, 2):
				var iv := Vector2i(_rng.randi_range(r.position.x + 4, r.end.x - 5), _rng.randi_range(r.position.y + 3, r.end.y - 4))
				var ok := true
				for oy in range(-3, 5):
					for ox in range(-3, 5):
						if corner_at(iv.x + ox, iv.y + oy) != DEEP:
							ok = false
				if ok:
					for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
						_set_corner(iv.x + o.x, iv.y + o.y, LIGHT)
					for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(2, -1), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 1), Vector2i(2, 1), Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
						_set_corner(iv.x + o.x, iv.y + o.y, SHALLOW)
		_claim(r.grow(1))
		ponds.append(r)
		return


## A brook three corners wide from the north edge to the south, meandering,
## with a stone bridge where the path will cross.
func _stream() -> void:
	for t in 30:
		var x := float(_rng.randi_range(12, W - 12))
		var drift := 0.0
		var line: Array[Vector2i] = []
		for y in range(-1, H + 2):
			drift = clampf(drift + _rng.randf_range(-0.35, 0.35), -0.8, 0.8)
			x = clampf(x + drift, 8, W - 8)
			line.append(Vector2i(roundi(x), y))
		# Clear of the spawn and of anything already placed.
		var ok := true
		for v in line:
			if absi(v.x - spawn.x) < 6 and v.y > H - 12:
				ok = false
			for dx in range(-3, 3):
				var c := Vector2i(v.x + dx, v.y)
				if _inside(c) and (_taken.has(c) or kind[_i(c)] != GRASS):
					ok = false
		if not ok:
			continue
		for v in line:
			for dx in range(-1, 2):
				_set_corner(v.x + dx, v.y, DEEP if dx == 0 else SHALLOW)
		for v in line:
			for dx in range(-3, 3):
				var c := Vector2i(v.x + dx, v.y)
				if _inside(c):
					_taken[c] = true
		notes.append("stream")
		_stream_line = line
		return


var _stream_line: Array[Vector2i] = []


# ---------------------------------------------------------------- zones

## Dark grass: a noise field on the corners cut at the recipe's share, only
## on light grass away from water, paths come later and cut through.
func _zones() -> void:
	var share: float = recipe.zones
	if share <= 0.0:
		return
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 13 + attempt
	noise.frequency = 0.045
	noise.fractal_octaves = 2
	var vals := PackedFloat32Array()
	vals.resize((W + 1) * (H + 1))
	for y in H + 1:
		for x in W + 1:
			vals[_ci(x, y)] = noise.get_noise_2d(x, y)
	var sorted := Array(vals)
	sorted.sort()
	var cut: float = sorted[int((1.0 - share) * sorted.size())]
	for y in H + 1:
		for x in W + 1:
			if vals[_ci(x, y)] >= cut and corner[_ci(x, y)] == LIGHT and not _near_plateau(x, y) and not _near_wall(x, y):
				corner[_ci(x, y)] = DARK
	# Two majority passes: lone corners and one-corner notches go, so the
	# zones' outlines are the long soft curves of the pack's sample maps.
	for pass_i in 2:
		var next := corner.duplicate()
		for y in range(1, H):
			for x in range(1, W):
				var t := corner[_ci(x, y)]
				if t != LIGHT and t != DARK:
					continue
				var n := 0
				for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
					if corner[_ci(x + o.x, y + o.y)] == DARK:
						n += 1
				if t == LIGHT and n >= 5 and not _near_plateau(x, y) and not _near_wall(x, y):
					next[_ci(x, y)] = DARK
				elif t == DARK and n <= 3:
					next[_ci(x, y)] = LIGHT
		corner = next


## Within two cells of the forest wall: the wall keeps some baked grass by
## its trunks, so the ground there stays plain light grass.
func _near_wall(x: int, y: int) -> bool:
	for dy in range(-2, 2):
		for dx in range(-2, 2):
			if wall_area.has(Vector2i(x + dx, y + dy)):
				return true
	return false


func _near_plateau(x: int, y: int) -> bool:
	for p in plateaus:
		if p.rect.grow(1).has_point(Vector2i(x, y)) or p.rect.grow(1).has_point(Vector2i(x - 1, y - 1)):
			return true
	return false


# ---------------------------------------------------------------- paths

func _lay_paths() -> void:
	var layout: String = recipe.path[0]
	var t: int = recipe.path[1]
	var width: int = recipe.path[2]
	var hub := Vector2i(W / 2, H / 2)
	for tries in 200:
		var h := Vector2i(W / 2 + _rng.randi_range(-12, 12), H / 2 + _rng.randi_range(-8, 4))
		if kind[_i(h)] == GRASS and not _taken.has(h) and _count_corners(h, [SHALLOW, DEEP]) == 0:
			hub = h
			break
	match layout:
		"cross":
			var y := hub.y
			_route(Vector2i(0, y), Vector2i(W - 1, y), t, width)
			_route(spawn, hub, t, width)
		"road":
			var y := _rng.randi_range(H / 2 - 4, H / 2 + 2)
			_route(Vector2i(0, y), Vector2i(W - 1, y), t, width)
			hub = Vector2i(spawn.x, y)
			_route(spawn, hub, t, width)
		"plaza":
			var pr := Rect2i(hub - Vector2i(5, 3), Vector2i(11, 7))
			for yy in range(pr.position.y, pr.end.y + 1):
				for xx in range(pr.position.x, pr.end.x + 1):
					var d := Vector2((xx - hub.x) / 6.0, (yy - hub.y) / 4.0).length()
					if d + (_hash(xx, yy) - 0.5) * 0.3 < 1.0 and _corner_free(xx, yy):
						_set_corner(xx, yy, t)
			for yy in range(pr.position.y, pr.end.y):
				for xx in range(pr.position.x, pr.end.x):
					if _count_corners(Vector2i(xx, yy), [t]) >= 2:
						paths[Vector2i(xx, yy)] = t
			_route(spawn, hub, t, width)
			_route(hub, Vector2i(W - 1, hub.y + _rng.randi_range(-4, 4)), t, width)
		"shore", "trail", "to_plateau":
			_route(spawn, hub, t, width)
	for p in plateaus:
		_route(p.foot, hub, t, width)
	# Gaps in the forest wall lead somewhere.
	goals.append(hub)


func _corner_free(x: int, y: int) -> bool:
	var t := corner_at(x, y)
	return t == LIGHT or t == DARK or t == DIRT or t == COBBLE


## A* over cells (water, cliffs, and the forest wall solid; a noise cost so
## trails wind), then the route's corners take the path terrain: one corner
## per cell for a narrow trail, all four for a road two cells wide.
var _wander := FastNoiseLite.new()

func _route(a: Vector2i, b: Vector2i, t: int, width: int) -> void:
	_wander.seed = map_id * 7 + attempt
	_wander.frequency = 0.09
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, W, H)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var k := kind[_i(c)]
			var wet := _count_corners(c, [SHALLOW, DEEP])
			if k == WALL or k == FACE or k == TOP or k == STAIR or wall_area.has(c):
				astar.set_point_solid(c, true)
			elif wet > 0:
				# Streams are crossed by a bridge; ponds are walked round.
				astar.set_point_weight_scale(c, 30.0 if _on_stream(c) else 400.0)
			elif paths.has(c):
				astar.set_point_weight_scale(c, 0.5)
			else:
				astar.set_point_weight_scale(c, 1.0 + (_wander.get_noise_2d(x, y) + 1.0) * 1.8)
	a = a.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	b = b.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	for c in [a, b]:
		astar.set_point_solid(c, false)
	var cells := astar.get_id_path(a, b)
	for c in cells:
		if _count_corners(c, [SHALLOW, DEEP]) > 0:
			if _on_stream(c):
				bridges[c] = true
			continue
		if kind[_i(c)] == STAIR:
			continue
		paths[c] = t
		if width >= 2:
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				if _corner_free(c.x + o.x, c.y + o.y) and not _plateau_corner(c.x + o.x, c.y + o.y):
					_set_corner(c.x + o.x, c.y + o.y, t)
		else:
			# A trail: one corner per cell, and now and then a second beside it,
			# so it swells and narrows like a trodden path.
			var extra := Vector2i(c.x + 1 + (1 if _hash(c.x, c.y) < 0.5 else 0), c.y + 1 + (0 if _hash(c.x, c.y) < 0.5 else 1))
			for v in [Vector2i(c.x + 1, c.y + 1), extra]:
				if v == extra and _wander.get_noise_2d(c.x * 3.0, c.y * 3.0) < 0.1:
					continue
				if _corner_free(v.x, v.y) and not _plateau_corner(v.x, v.y):
					_set_corner(v.x, v.y, t)
	_place_bridges()


func _on_stream(c: Vector2i) -> bool:
	for v in _stream_line:
		if v.y == c.y and absi(v.x - c.x) <= 3:
			return true
	return false


func _plateau_corner(x: int, y: int) -> bool:
	for p in plateaus:
		var r: Rect2i = p.rect
		if x >= r.position.x and y >= r.position.y and x <= r.end.x and y <= r.end.y:
			return true
	return false


## One stone bridge per stream crossing: the pack's 64 x 48 arch, across the
## brook where the path meets it.
func _place_bridges() -> void:
	if bridges.is_empty():
		return
	var rows := {}
	for c: Vector2i in bridges:
		rows[c.y] = true
	for y: int in rows:
		var v := Vector2i.ZERO
		for s in _stream_line:
			if s.y == y:
				v = s
		var foot := Vector2i(v.x, y + 1)
		if props.any(func(p: Dictionary) -> bool: return p.art == "bridge" and absi(p.cell.y - foot.y) < 4):
			continue
		props.append({"art": "bridge", "cell": foot})
		for dx in range(-2, 3):
			for dy in range(-1, 1):
				var c := Vector2i(v.x + dx, y + dy)
				if _inside(c):
					bridges[c] = true
					_taken[c] = true


## Cell kinds from the corners: water where two or more corners are water
## (unless bridged); ground where the path runs.
func _settle_kinds() -> void:
	water.clear()
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var k := kind[_i(c)]
			if k == WATER:
				water[c] = true
			if k != GRASS:
				continue
			if _count_corners(c, [SHALLOW, DEEP]) >= 2 and not bridges.has(c):
				kind[_i(c)] = WATER
				water[c] = true
				_taken[c] = true
			elif _count_corners(c, [DIRT, COBBLE]) >= 2 or paths.has(c):
				kind[_i(c)] = GROUND
				_taken[c] = true


# ---------------------------------------------------------------- set pieces

func _piece() -> void:
	var hub: Vector2i = goals[-1]
	match recipe.piece:
		"woodcut":
			var c := _open_spot(Vector2i(8, 6), hub, 10)
			_place("chop_axe", c)
			_place("firewood", c + Vector2i(3, 0))
			_place("chop_stump", c + Vector2i(-3, 1))
			_near(["big_stump", "stump", "stump", "big_log", "log"], 6, c, 7)
			_near(CLUTTER, 2, c, 4)
			_place("torch", c + Vector2i(1, 3))
		"well":
			_place_on_plaza("well_roof", hub + Vector2i(0, -1))
			_near(["barrels", "crate", "crate_open", "crate_tall"], 4, hub, 6)
			_near(["lamp_post", "lamp_double"], 2, hub, 6)
			_near(["notice", "cart"], 1, hub, 7)
			_near(["cypress_pot"], 2, hub, 5)
		"paddock":
			_paddock(hub)
		"wayside":
			_near(["lamp_post", "lamp_single"], 2, hub, 3)
			_near(["notice"], 1, hub, 4)
			_near(["cart", "barrels"], 1, hub, 6)
		"glade":
			_near(["big_stump", "mush_cluster", "mush_gold", "fungus"], 5, hub, 6)
		"berries":
			_near(["berry_bush", "berries_red", "berries_blue", "berry_bush"], 14, hub, 16)
		"rocks":
			_near(["boulder", "stone_b", "stone_c", "stone_d", "boulder"], 8, hub, 14)
		"reeds", "shore", "flowers":
			pass


## The well stands on the plaza itself (props otherwise keep to grass).
func _place_on_plaza(art: String, cell: Vector2i) -> void:
	props.append({"art": art, "cell": cell})
	for dx in range(-1, 2):
		blocked[cell + Vector2i(dx, 0)] = true
	if not _reaches_all():
		props.pop_back()
		for dx in range(-1, 2):
			blocked.erase(cell + Vector2i(dx, 0))


## A ranch-fence paddock off the road (fences.gd paints it): a rectangle
## with a gate on the side facing the hub.
var paddock := Rect2i()

func _paddock(hub: Vector2i) -> void:
	for t in 60:
		var size := Vector2i(_rng.randi_range(9, 13), _rng.randi_range(6, 8))
		var dy := -size.y - 3 if _rng.randf() < 0.5 else 3
		var at := hub + Vector2i(_rng.randi_range(-14, 4), dy)
		var r := Rect2i(at, size)
		if not _free(r.grow(1)):
			continue
		paddock = r
		_claim(r)
		for x in range(r.position.x, r.end.x):
			for y in [r.position.y, r.end.y - 1]:
				blocked[Vector2i(x, y)] = true
		for y in range(r.position.y, r.end.y):
			for x in [r.position.x, r.end.x - 1]:
				blocked[Vector2i(x, y)] = true
		# The gate: two cells in the rail nearest the hub.
		var gy: int = r.end.y - 1 if hub.y > r.get_center().y else r.position.y
		var gx := r.position.x + size.x / 2
		for dx in 2:
			blocked.erase(Vector2i(gx + dx - 1, gy))
		paddock_gate = Vector2i(gx - 1, gy)
		_route(Vector2i(gx, gy + (1 if gy == r.end.y - 1 else -1)), hub, DIRT, 1)
		_near(["cart", "crate", "barrels"], 2, Vector2i(gx, gy), 4)
		# Tall grass fills the yard.
		for y in range(r.position.y + 1, r.end.y - 1):
			for x in range(r.position.x + 1, r.end.x - 1):
				if _rng.randf() < 0.35:
					tall[Vector2i(x, y)] = true
		return


var paddock_gate := Vector2i(-1, -1)


func _open_spot(size: Vector2i, near: Vector2i, radius: int) -> Vector2i:
	for t in 200:
		var c := near + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if _free(Rect2i(c - size / 2, size)):
			return c
	return near


# ---------------------------------------------------------------- scatter

## Props stand on grass cells not claimed by anything; a blocking prop keeps
## every goal reachable or is taken back.
func _place(art: String, cell: Vector2i) -> bool:
	if not _inside(cell) or _taken.has(cell) or kind[_i(cell)] != GRASS or cell == spawn:
		return false
	var p: Dictionary = PROPS[art]
	var w: int = maxi(1, int(ceil(p.rect.size.x / 16.0)) - 1) if p.tag == "tree" else maxi(1, int(ceil(p.block.x / 16.0)))
	var r := Rect2i(cell - Vector2i(w / 2, 0), Vector2i(w, 1))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != GRASS:
				return false
	props.append({"art": art, "cell": cell})
	_claim(r)
	if p.block != Vector2.ZERO:
		blocked[cell] = true
	if p.tag == "torch" or p.tag == "lamp":
		fires.append(cell)
	return true


func _near(arts: Array, count: int, center: Vector2i, radius: int) -> void:
	var put := 0
	for t in count * 24:
		if put >= count:
			return
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if _place(arts[_rng.randi() % arts.size()], c):
			put += 1


## Trees: clusters like the pack's sample maps (three to six trees overlapping
## over bushes), then single trees; they crowd onto the dark grass.
func _scatter_trees() -> void:
	var set_: Array = TREE_SETS.get(recipe.trees[0], [recipe.trees[0]])
	var want: int = recipe.trees[1]
	var placed := 0
	for n in maxi(2, want / 4):
		var c := Vector2i(_rng.randi_range(4, W - 5), _rng.randi_range(4, H - 8))
		if _count_corners(c, [DARK]) < 2 and _rng.randf() < 0.6:
			continue
		for k in _rng.randi_range(3, 6):
			var p := c + Vector2i(_rng.randi_range(-4, 4), _rng.randi_range(-3, 3))
			if _place(set_[_rng.randi() % set_.size()], p):
				placed += 1
				_claim(Rect2i(p - Vector2i(1, 1), Vector2i(3, 2)))
		_near(["bush", "bush", "berry_bush", "fern", "fern_b"], _rng.randi_range(2, 4), c + Vector2i(0, 2), 4)
		for u in _rng.randi_range(1, 2):
			_undergrowth(c + Vector2i(_rng.randi_range(-3, 2), _rng.randi_range(-2, 1)))
	for t in want * 30:
		if placed >= want:
			break
		var c := Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(3, H - 3))
		var near := false
		for p in props:
			if PROPS[p.art].tag == "tree" and Vector2(p.cell - c).length() < 5.0:
				near = true
				break
		if near:
			continue
		if _place(set_[_rng.randi() % set_.size()], c):
			placed += 1
			_claim(Rect2i(c - Vector2i(1, 1), Vector2i(3, 2)))


## Tall grass in rows (the 16x32 left, middle, and right pieces), a few rows
## stacked into a patch; walkable, it rustles as the walker passes.
func _tall_grass() -> void:
	for n in recipe.tall * 2:
		for t in 30:
			var c := Vector2i(_rng.randi_range(2, W - 10), _rng.randi_range(3, H - 6))
			var len := _rng.randi_range(3, 7)
			var rows := _rng.randi_range(1, 3)
			var ok := true
			for dy in rows:
				for dx in len:
					var q := c + Vector2i(dx, dy)
					if not _inside(q) or _taken.has(q) or kind[_i(q)] != GRASS:
						ok = false
			if not ok:
				continue
			for dy in rows:
				var shift := _rng.randi_range(-1, 1) if dy > 0 else 0
				for dx in range(maxi(0, shift), len + mini(0, shift)):
					var q := c + Vector2i(dx, dy)
					tall[q] = true
					_taken[q] = true
			break


## Leafy undergrowth (forest.png 13-15, 0-2, the 3 x 3 bush-mass autotile):
## a mass two or three rows tall and two to six wide; it blocks.
var hedges := {} # cell -> forest.png atlas

func _undergrowth(at: Vector2i) -> bool:
	if season == "winter":
		return false # the snowy sheet draws these cells as snow outlines
	var size := Vector2i(_rng.randi_range(2, 4), 2)
	var r := Rect2i(at, size)
	if not _free(r):
		return false
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var col := 13 if x == r.position.x else (15 if x == r.end.x - 1 else 14)
			var row := 0 if y == r.position.y else (2 if y == r.end.y - 1 else 1)
			hedges[Vector2i(x, y)] = Vector2i(col, row)
			blocked[Vector2i(x, y)] = true
	_claim(r)
	return true


func _scatter_small() -> void:
	# Undergrowth along the forest wall's inner edge.
	for n in 6 if recipe.wall != "none" else 0:
		for t in 20:
			var c := Vector2i(_rng.randi_range(2, W - 8), _rng.randi_range(2, H - 6))
			var by_wall := false
			for o in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, -2), Vector2i(-2, 0), Vector2i(6, 0), Vector2i(0, 3)]:
				var q: Vector2i = c + o
				if _inside(q) and kind[_i(q)] == WALL:
					by_wall = true
			if by_wall and _undergrowth(c):
				break
	var extra := 30 if recipe.piece == "glade" else 22
	_near(["bush", "berry_bush", "boulder", "stone_b", "stone_c", "stump", "log", "big_log", "birch_log"], extra / 2, Vector2i(W / 2, H / 2), W / 2)
	_near(SMALL, extra * 2, Vector2i(W / 2, H / 2), W / 2)


## Lily pads and water rocks on open water, cattails on the shallow rim.
func _water_props() -> void:
	var open: Array[Vector2i] = open_water()
	_shuffle(open)
	var n := 0
	for c in open:
		if n >= mini(3 + open.size() / 12, 14):
			break
		var art: String = ["lily", "lily_b", "lily_c", "lily_s", "lily", "lilies", "boulder_wet"][_rng.randi() % 7]
		if season == "winter" and art != "boulder_wet":
			continue
		props.append({"art": art, "cell": c})
		n += 1
	var shore: Array[Vector2i] = []
	for c: Vector2i in water:
		if _count_corners(c, [SHALLOW]) >= 2 and _count_corners(c, [LIGHT, DARK]) >= 1:
			shore.append(c)
	_shuffle(shore)
	var want := 4 + shore.size() / 8
	if recipe.piece == "reeds":
		want *= 2
	for c in shore.slice(0, want):
		if season != "winter":
			props.append({"art": ["cattail", "cattail_b"][_rng.randi() % 2], "cell": c})


## Flowers and tufts baked on light grass, only where all four corners are
## light grass and nothing stands.
func _ground_deco() -> void:
	var rate: float = recipe.flowers / 1000.0
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != GRASS or _count_corners(c, [LIGHT]) < 4 or tall.has(c):
				continue
			var h := _hash(x, y)
			if h < rate:
				deco[c] = FLOWER_TILES[int(h * 9973.0) % FLOWER_TILES.size()]
			elif h > 1.0 - rate * 0.6:
				deco[c] = TUFT_TILES[int(h * 7919.0) % TUFT_TILES.size()]


# ---------------------------------------------------------------- liveliness

# The Painted Lands floor with its frozen weights (not recalibrated for this
# pack): a weak camera window gets a pair of torches across the path, or a
# lamp post off it.
const LIVE_FLOOR := 0.09
const FLOOR_ANCHORS := 4
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WATER := 6.0
const FLOOR_TORCH := 60.0
const FLOOR_TREE := 8.0

func _liveliness_floor() -> void:
	for n in FLOOR_ANCHORS:
		var weak := _weakest()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR:
			break
		var r: Rect2i = weak.rect
		if _torch_pair(r):
			floor_notes.append("torches")
		elif _lamp(r):
			floor_notes.append("lamp")
		elif _floor_pond(r):
			floor_notes.append("pond")
		else:
			floor_notes.append("no room")
			break
	floor_notes.append("-> %.3f%%" % _weakest().value)


func _torch_pair(r: Rect2i) -> bool:
	var mid := r.get_center()
	var cands: Array[Vector2i] = []
	for c: Vector2i in paths:
		if r.grow(-3).has_point(c) and kind[_i(c)] == GROUND:
			cands.append(c)
	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - mid).length_squared() < (b - mid).length_squared())
	for c: Vector2i in cands.slice(0, 40):
		var across := Vector2i.DOWN if paths.has(c + Vector2i.LEFT) and paths.has(c + Vector2i.RIGHT) else Vector2i.RIGHT
		var a := c
		while _inside(a - across) and kind[_i(a - across)] == GROUND and (a - across - c).length() < 4:
			a -= across
		var b := c
		while _inside(b + across) and kind[_i(b + across)] == GROUND and (b + across - c).length() < 4:
			b += across
		a -= across
		b += across
		var mark := props.size()
		if _place("torch", a) and _place("torch", b) and _reaches_all():
			return true
		_unplace(mark)
	return false


## A lamp post stands only beside a path.
func _lamp(r: Rect2i) -> bool:
	var beside: Array[Vector2i] = []
	for c: Vector2i in paths:
		if not r.grow(-3).has_point(c):
			continue
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if _inside(c + d) and kind[_i(c + d)] == GRASS:
				beside.append(c + d)
	_shuffle(beside)
	for c in beside.slice(0, 60):
		var mark := props.size()
		if _place(["lamp_post", "lamp_single", "lamp_double"][_rng.randi() % 3], c) and _reaches_all():
			return true
		_unplace(mark)
	return false


## Away from paths, a small pond (water moves: sparkles, rings, dragonflies).
func _floor_pond(r: Rect2i) -> bool:
	var before := ponds.size()
	var standing := {}
	for p in props:
		standing[p.cell] = true
		if PROPS[p.art].tag == "tree":
			for dx in range(-1, 2):
				standing[p.cell + Vector2i(dx, 0)] = true
	for t in 40:
		var size := Vector2i(_rng.randi_range(4, 6), _rng.randi_range(3, 4))
		var at := r.get_center() + Vector2i(_rng.randi_range(-14, 10), _rng.randi_range(-6, 3))
		var box := Rect2i(at, size)
		var ok := true
		for y in range(box.position.y - 1, box.end.y + 1):
			for x in range(box.position.x - 1, box.end.x + 1):
				var c := Vector2i(x, y)
				if not _inside(c) or kind[_i(c)] != GRASS or standing.has(c) or tall.has(c) or hedges.has(c) or c == spawn or blocked.has(c):
					ok = false
		if not ok:
			continue
		var saved := corner.duplicate()
		_pond_at(box)
		_settle_kinds()
		if ponds.size() > before and _reaches_all():
			for y in range(box.position.y - 1, box.end.y + 2):
				for x in range(box.position.x - 1, box.end.x + 2):
					deco.erase(Vector2i(x, y))
			return true
		corner = saved
		_settle_kinds_reset(box)
	return false


func _pond_at(r: Rect2i) -> void:
	var c0 := Vector2(r.get_center())
	var inside := {}
	for y in range(r.position.y, r.end.y + 1):
		for x in range(r.position.x, r.end.x + 1):
			var d := Vector2((x - c0.x) / (r.size.x * 0.5), (y - c0.y) / (r.size.y * 0.5))
			if d.length() + (_hash(x, y) - 0.5) * 0.3 < 0.95:
				inside[Vector2i(x, y)] = true
	if inside.size() < 6:
		return
	for v: Vector2i in inside:
		var edge := false
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
			if not inside.has(v + o):
				edge = true
		_set_corner(v.x, v.y, SHALLOW if edge else DEEP)
	_claim(r.grow(1))
	ponds.append(r)


## Undoes a trial pond's cells (the corners are restored by the caller).
func _settle_kinds_reset(r: Rect2i) -> void:
	ponds.pop_back()
	for y in range(r.position.y - 1, r.end.y + 1):
		for x in range(r.position.x - 1, r.end.x + 1):
			var c := Vector2i(x, y)
			if _inside(c) and kind[_i(c)] == WATER:
				kind[_i(c)] = GRASS
				water.erase(c)
			_taken.erase(c)


func _unplace(mark: int) -> void:
	while props.size() > mark:
		var p: Dictionary = props.pop_back()
		_taken.erase(p.cell)
		blocked.erase(p.cell)
		fires.erase(p.cell)


func _weakest() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(W * H)
	m.fill(0.0)
	for c: Vector2i in water:
		m[_i(c)] += FLOOR_WATER
	for p in props:
		if not _inside(p.cell):
			continue
		var tag: String = PROPS[p.art].tag
		if tag == "torch" or tag == "lamp":
			m[_i(p.cell)] += FLOOR_TORCH
		elif tag == "tree":
			m[_i(p.cell)] += FLOOR_TREE
	var best := {"rect": Rect2i(), "value": INF}
	var xs: Array[int] = []
	var ys: Array[int] = []
	for x in range(0, W - FLOOR_VIEW.x + 1, 2):
		xs.append(x)
	for y in range(0, H - FLOOR_VIEW.y + 1, 2):
		ys.append(y)
	xs.append(W - FLOOR_VIEW.x)
	ys.append(H - FLOOR_VIEW.y)
	for y in ys:
		for x in xs:
			var s := 0.0
			for yy in range(y, y + FLOOR_VIEW.y):
				for xx in range(x, x + FLOOR_VIEW.x):
					s += m[yy * W + xx]
			var v := s / float(FLOOR_VIEW.x * FLOOR_VIEW.y)
			if v < best.value:
				best = {"rect": Rect2i(x, y, FLOOR_VIEW.x, FLOOR_VIEW.y), "value": v}
	return best


# ---------------------------------------------------------------- ambience inputs

## Water cells whose eight neighbors are water (ripples, fish, ducks).
func open_water() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in water:
		if bridges.has(c):
			continue
		var all := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not water.has(c + Vector2i(dx, dy)):
					all = false
		if all:
			out.append(c)
	return out


## Cells with grass the walker could stand on (grass waves, blade flicks).
func grass_cells() -> Dictionary:
	var out := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var k := kind[_i(c)]
			if (k == GRASS or k == TOP) and not blocked.has(c) and _count_corners(c, [LIGHT, DARK]) >= 3:
				out[c] = true
	return out


func trunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in props:
		if PROPS[p.art].tag == "tree":
			out.append(p.cell)
	return out


## Dark-grass cells (fireflies, voles).
func dark_cells() -> Dictionary:
	var out := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] == GRASS and _count_corners(c, [DARK]) >= 3:
				out[c] = true
	return out


## The wildlife plan (wildlife.gd plan_from) for this map.
func wildlife_plan() -> Dictionary:
	var grass := grass_cells()
	var dark := dark_cells()
	var land := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if walkable(c):
				land[c] = true
	var tr := trunks()
	var clutter: Array[Vector2i] = []
	var bushes: Array[Vector2i] = []
	var rocks: Array[Vector2i] = []
	for p in props:
		var tag: String = PROPS[p.art].tag
		if tag == "clutter" or tag == "wood":
			clutter.append(p.cell)
		elif tag == "bush":
			bushes.append(p.cell)
		elif tag == "stone":
			rocks.append(p.cell)
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	for c: Vector2i in land:
		var wet := false
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if water.has(c + d) and not bridges.has(c + d):
				wet = true
		if wet:
			h.shore[c] = true
		var is_grass: bool = grass.has(c)
		if is_grass and not wet:
			h.roam[c] = true
			if not dark.has(c):
				h.lawn[c] = true
		if dark.has(c):
			h.dark[c] = true
		if _near_any(c, tr, 2):
			h.trees[c] = true
		if _near_any(c, clutter, 2):
			h.clutter[c] = true
		if _near_any(c, bushes, 2):
			h.bushes[c] = true
		if kind[_i(c)] == TOP or _near_any(c, rocks, 2):
			h.rocky[c] = true
		if is_grass and (paths.has(c + Vector2i.DOWN) or paths.has(c + Vector2i.UP)):
			h.open[c] = true
	for c in open_water():
		h.water[c] = true
	h["_land"] = land
	var ts := {}
	for t in tr:
		ts[t] = true
	h["_trunks"] = ts
	h["_w"] = W
	var quiet: Array[Vector2i] = []
	quiet.append_array(water.keys())
	quiet.append_array(fires)
	quiet.append_array(tr)
	return Wildlife.plan_from(h, map_id, spawn, Wildlife.quiet_from(quiet, W, H))


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
	if bridges.has(c):
		return true
	return k == GRASS or k == GROUND or k == TOP or k == STAIR


func _reaches_all() -> bool:
	for g in goals:
		if not _reaches(spawn, g):
			return false
	return true


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
			var a := kind[_i(c)]
			var b := kind[_i(n)]
			# A plateau top is reached only by its stairs.
			if (a == TOP) != (b == TOP) and not (a == STAIR or b == STAIR):
				continue
			seen[n] = true
			queue.append(n)
	return false


func _report() -> String:
	if not _reaches_all():
		fails.append("spawn does not reach every goal")
	if recipe.plateaus[0] > plateaus.size():
		fails.append("plateaus %d of %d" % [plateaus.size(), recipe.plateaus[0]])
	var trees := trunks().size()
	var lines := PackedStringArray([
		"Mana Seed map %d: recipe %d %s, %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, season, W, H, attempt],
		"  plateaus %d, ponds %d, water %d cells, path %d cells, trees %d, props %d, tall grass %d, fires %d" % [
			plateaus.size(), ponds.size(), water.size(), paths.size(), trees, props.size(), tall.size(), fires.size()],
		"  %s" % ", ".join(notes),
		"  floor: %s" % " ".join(floor_notes),
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	return "\n".join(lines)


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
