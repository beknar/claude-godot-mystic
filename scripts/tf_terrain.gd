class_name TFTerrain
extends RefCounted
## Time Fantasy maps (finalbossblues, TimeFantasy_TILES_6.24.17), built the way
## the Painted Lands generator builds its maps: a recipe per seed, a layout,
## autotiled systems, set pieces, scatter, a liveliness floor, and a walk
## check. Output is sheet coordinates and prop placements; timefantasy.gd
## paints them. Sheets in assets/pack/time_fantasy/ (terrain, outside, water,
## house, animated); world.png is never used (it is for a zoomed-out map).
##
## The sheets' systems (cells of 16 px):
##   grass     light fill (2, 1) with a quieter variation (3, 1); darker
##             fills (7, 1), (8, 1), (12, 1) for forest-floor zones; flowers,
##             tufts, mushrooms and pebbles on light grass (1-20, 2-3);
##             autumn: yellow fill (1, 4), variations (2-3, 4), deco (1-12, 5)
##   grounds   one row per ground on a surrounding grass (terrain 22-37,
##             rows 2-7 on green, 9-14 on yellow): 22 fill, 25/34/27/32 grass
##             on the N/S/W/E side, 29/33/35/36 rounded outer corners (grass
##             NW/NE/SW/SE), 23/24/26/30 inner nubs (grass at one diagonal),
##             37 the grass itself. Grounds: dirt, gravel, sand, packed dirt,
##             paving, pit (rows +0..+5).
##   water     per shore: a land sample, a 2x2 of inner corners, a 3x3 pool;
##             three frames 3 columns apart, played 1-2-3-2 (water.png)
##   cliffs    a grass top (1-3, 14) N rim, (1, 16) side (mirrored for E),
##             (1-3, 17) the S rim, a two-row face (1-3, 18-19), stairs
##             (5-8, 22-24), a cave (4, 18-19); grey stone ten columns right
##   houses    a gable roof 7 wide (three roof rows + a two-row gable end) over
##             a two-row wall band with corner posts, door, and windows;
##             6 roof colors, 5 gable ends, 5 wall materials (house.png)

const W := 60
const H := 40
const TILE := 16

# Kinds.
const GRASS := 0
const GROUND := 1 # a path, plaza, or patch (walkable)
const WATER := 2
const TOP := 3 # a plateau top (walkable, raised)
const FACE := 4 # a cliff face (blocks)
const STAIR := 5
const HOUSE := 6 # a house footprint (the lower part blocks)

const GREEN := {"fill": Vector2i(2, 1), "vary": [Vector2i(3, 1)], "row": 2,
	"deco": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
		Vector2i(9, 2), Vector2i(10, 2), Vector2i(11, 2), Vector2i(12, 2), Vector2i(13, 2), Vector2i(14, 2), Vector2i(15, 2), Vector2i(16, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3),
		Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)],
	"flowers": [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2),
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3),
		Vector2i(9, 3), Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3)],
	"rare": [Vector2i(17, 2), Vector2i(18, 2), Vector2i(19, 2), Vector2i(13, 3), Vector2i(14, 3), Vector2i(15, 3), Vector2i(16, 3), Vector2i(17, 3), Vector2i(18, 3), Vector2i(19, 3)],
	"shore": 0}
const AUTUMN := {"fill": Vector2i(1, 4), "vary": [Vector2i(2, 4), Vector2i(3, 4)], "row": 9,
	"deco": [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5),
		Vector2i(9, 5), Vector2i(10, 5), Vector2i(11, 5), Vector2i(12, 5)],
	"flowers": [Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5)],
	"rare": [], "shore": 3}
# Forest-floor tones: row 1 runs light to dark. Mid (9-11, 1) about 0.53
# brightness, deep (7, 8, 12, 1) about 0.47; deep always sits inside mid.
const MID_FILLS: Array[Vector2i] = [Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1)]
const DEEP_FILLS: Array[Vector2i] = [Vector2i(7, 1), Vector2i(8, 1), Vector2i(12, 1)]
const DEEP_SHARE := 0.4 # of the mid zone's share
const ZONE_FLOOR := 0.2 # least mid share on green maps that have zones
const ZONE_FADE := 4 # cells over which zones fade in from paths, water, cliffs
# Ground rows, added to the season's base row.
const DIRT := 0
const GRAVEL := 1
const SAND := 2
const PACKED := 3
const PAVING := 4
# Autotile columns in a ground row.
const P_FILL := 22
const P_EDGE := {1: 25, 4: 34, 8: 27, 2: 32} # the side the grass is on
const P_OUTER := {9: 29, 3: 33, 12: 35, 6: 36} # grass on N+W, N+E, S+W, S+E
const P_INNER := {"NW": 23, "NE": 24, "SW": 26, "SE": 30}
# Water: per shore, the land sample column/row; inner corners at +1..+2,
# the pool at rows +2..+4; frames 3 columns apart.
const SHORES := [
	{"name": "grass", "origin": Vector2i(1, 7)},
	{"name": "deep", "origin": Vector2i(21, 7)}, # darker water, grass shore
	{"name": "sand", "origin": Vector2i(1, 37)},
	{"name": "yellow", "origin": Vector2i(1, 19)},
	{"name": "dirt", "origin": Vector2i(1, 25)},
]
# Cliffs: brown (x 0) and grey stone (x 10).
const CLIFF_BROWN := 0
const CLIFF_GREY := 10
# Houses (house.png).
const ROOF_X: Array[int] = [19, 26, 33, 40, 47, 54] # grey, red, straw, dark, blue, green
const GABLE_ROW: Array[int] = [12, 14, 16, 18, 20] # plaster, vented timber, planks, stone, dark stone
const WALL_ROW: Array[int] = [4, 6, 10, 14, 18] # plaster, plaster (beams), logs, stone, dark stone
const WINDOW_PAIRS := [[10, 11], [12, 13], [14, 15], [16, 17]]

# Props (outside.png unless `sheet`): rect in px, foot (px in the rect),
# block (collider w, h at the foot), tag.
const PROPS := {
	"oak_big": {"rect": Rect2i(532, 16, 89, 96), "foot": Vector2i(45, 92), "block": Vector2(18, 8), "tag": "tree", "cells": Vector2i(3, 2)},
	"tree_giant": {"rect": Rect2i(625, 148, 94, 154), "unsnow": true, "foot": Vector2i(47, 150), "block": Vector2(22, 10), "tag": "tree", "cells": Vector2i(3, 2)},
	"tree_giant_red": {"rect": Rect2i(721, 147, 94, 155), "unsnow": true, "foot": Vector2i(47, 151), "block": Vector2(22, 10), "tag": "tree", "cells": Vector2i(3, 2)},
	"tree_bare": {"rect": Rect2i(629, 18, 90, 108), "erase": Rect2i(0, 58, 26, 26), "foot": Vector2i(45, 104), "block": Vector2(16, 8), "tag": "bare", "cells": Vector2i(3, 2)},
	"tree_bare_white": {"rect": Rect2i(725, 18, 90, 108), "erase": Rect2i(0, 58, 26, 26), "foot": Vector2i(45, 104), "block": Vector2(16, 8), "tag": "bare", "cells": Vector2i(3, 2)},
	"tree_round": {"rect": Rect2i(277, 50, 52, 60), "foot": Vector2i(26, 57), "block": Vector2(12, 6), "tag": "tree", "cells": Vector2i(2, 1)},
	"pine_big": {"rect": Rect2i(404, 56, 40, 52), "foot": Vector2i(20, 50), "block": Vector2(10, 6), "tag": "pine", "cells": Vector2i(2, 1)},
	"pine": {"rect": Rect2i(277, 121, 35, 50), "foot": Vector2i(17, 48), "block": Vector2(10, 6), "tag": "pine", "cells": Vector2i(2, 1)},
	"pine_b": {"rect": Rect2i(320, 120, 32, 48), "foot": Vector2i(16, 46), "block": Vector2(10, 6), "tag": "pine", "cells": Vector2i(2, 1)},
	"pine_small": {"rect": Rect2i(355, 124, 26, 46), "foot": Vector2i(13, 44), "block": Vector2(8, 5), "tag": "pine", "cells": Vector2i(1, 1)},
	"oak": {"rect": Rect2i(388, 129, 39, 47), "foot": Vector2i(19, 45), "block": Vector2(10, 6), "tag": "tree", "cells": Vector2i(2, 1)},
	"oak_orange": {"rect": Rect2i(436, 128, 39, 47), "foot": Vector2i(19, 45), "block": Vector2(10, 6), "tag": "autumn", "cells": Vector2i(2, 1)},
	"oak_yellow": {"rect": Rect2i(484, 129, 39, 47), "foot": Vector2i(19, 45), "block": Vector2(10, 6), "tag": "autumn", "cells": Vector2i(2, 1)},
	"teal": {"rect": Rect2i(277, 185, 35, 50), "foot": Vector2i(17, 48), "block": Vector2(10, 6), "tag": "teal", "cells": Vector2i(2, 1)},
	"teal_b": {"rect": Rect2i(320, 184, 32, 48), "foot": Vector2i(16, 46), "block": Vector2(10, 6), "tag": "teal", "cells": Vector2i(2, 1)},
	"teal_big": {"rect": Rect2i(420, 184, 40, 52), "foot": Vector2i(20, 50), "block": Vector2(10, 6), "tag": "teal", "cells": Vector2i(2, 1)},
	"pink": {"rect": Rect2i(465, 180, 46, 58), "foot": Vector2i(23, 55), "block": Vector2(12, 6), "tag": "pink", "cells": Vector2i(2, 1)},
	"pink_b": {"rect": Rect2i(513, 180, 46, 58), "foot": Vector2i(23, 55), "block": Vector2(12, 6), "tag": "pink", "cells": Vector2i(2, 1)},
	"pink_small": {"rect": Rect2i(567, 198, 20, 36), "foot": Vector2i(10, 34), "block": Vector2(6, 4), "tag": "pink", "cells": Vector2i(1, 1)},
	"sapling": {"rect": Rect2i(275, 279, 26, 23), "foot": Vector2i(13, 21), "block": Vector2(10, 5), "tag": "bush", "cells": Vector2i(2, 1)},
	"sapling_b": {"rect": Rect2i(307, 273, 26, 30), "foot": Vector2i(13, 28), "block": Vector2(10, 5), "tag": "bush", "cells": Vector2i(2, 1)},
	"dead_small": {"rect": Rect2i(496, 65, 32, 46), "foot": Vector2i(16, 44), "block": Vector2(6, 4), "tag": "bare", "cells": Vector2i(2, 1)},
	"stump": {"rect": Rect2i(338, 25, 28, 19), "foot": Vector2i(14, 17), "block": Vector2(14, 6), "tag": "wood", "cells": Vector2i(2, 1)},
	"stump_b": {"rect": Rect2i(370, 25, 28, 19), "foot": Vector2i(14, 17), "block": Vector2(14, 6), "tag": "wood", "cells": Vector2i(2, 1)},
	"stump_mushroom": {"rect": Rect2i(403, 22, 28, 22), "foot": Vector2i(14, 20), "block": Vector2(14, 6), "tag": "wood", "cells": Vector2i(2, 1)},
	"stump_flower": {"rect": Rect2i(434, 25, 28, 20), "foot": Vector2i(14, 18), "block": Vector2(14, 6), "tag": "wood", "cells": Vector2i(2, 1)},
	"stump_giant": {"rect": Rect2i(651, 324, 47, 26), "foot": Vector2i(23, 24), "block": Vector2(24, 8), "tag": "wood", "cells": Vector2i(3, 1)},
	"log": {"rect": Rect2i(291, 22, 45, 20), "foot": Vector2i(22, 18), "block": Vector2(38, 6), "tag": "wood", "cells": Vector2i(3, 1)},
	"barrel": {"rect": Rect2i(193, 25, 14, 18), "foot": Vector2i(7, 17), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"barrel_b": {"rect": Rect2i(209, 25, 14, 18), "foot": Vector2i(7, 17), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"barrel_water": {"rect": Rect2i(225, 25, 14, 18), "foot": Vector2i(7, 17), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"crate": {"rect": Rect2i(81, 33, 14, 15), "foot": Vector2i(7, 14), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"crate_b": {"rect": Rect2i(97, 28, 14, 20), "foot": Vector2i(7, 19), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"crate_stack": {"rect": Rect2i(112, 26, 16, 22), "foot": Vector2i(8, 21), "block": Vector2(14, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"crate_c": {"rect": Rect2i(145, 33, 14, 15), "foot": Vector2i(7, 14), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"apples": {"rect": Rect2i(241, 33, 14, 15), "foot": Vector2i(7, 14), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"produce": {"rect": Rect2i(257, 33, 14, 15), "foot": Vector2i(7, 14), "block": Vector2(12, 5), "tag": "clutter", "cells": Vector2i(1, 1)},
	"pot": {"rect": Rect2i(80, 49, 16, 14), "foot": Vector2i(8, 13), "block": Vector2(10, 4), "tag": "clutter", "cells": Vector2i(1, 1)},
	"pot_b": {"rect": Rect2i(98, 49, 12, 14), "foot": Vector2i(6, 13), "block": Vector2(8, 4), "tag": "clutter", "cells": Vector2i(1, 1)},
	"sign": {"rect": Rect2i(53, 25, 23, 20), "foot": Vector2i(11, 19), "block": Vector2(6, 4), "tag": "clutter", "cells": Vector2i(1, 1)},
	"sign_small": {"rect": Rect2i(32, 96, 16, 15), "foot": Vector2i(8, 14), "block": Vector2(6, 4), "tag": "clutter", "cells": Vector2i(1, 1)},
	"graves": {"rect": Rect2i(178, 55, 62, 25), "foot": Vector2i(31, 24), "block": Vector2(56, 6), "tag": "stone", "cells": Vector2i(4, 1)},
	"grave_cross": {"rect": Rect2i(241, 55, 13, 25), "foot": Vector2i(6, 24), "block": Vector2(6, 4), "tag": "stone", "cells": Vector2i(1, 1)},
	"rock": {"rect": Rect2i(20, 164, 11, 9), "foot": Vector2i(5, 8), "block": Vector2.ZERO, "tag": "stone", "cells": Vector2i(1, 1)},
	"rock_b": {"rect": Rect2i(35, 165, 12, 9), "foot": Vector2i(6, 8), "block": Vector2.ZERO, "tag": "stone", "cells": Vector2i(1, 1)},
	"crystal": {"rect": Rect2i(131, 178, 10, 13), "foot": Vector2i(5, 12), "block": Vector2(6, 4), "tag": "crystal", "cells": Vector2i(1, 1)},
	"crystal_b": {"rect": Rect2i(145, 178, 13, 14), "foot": Vector2i(6, 13), "block": Vector2(8, 4), "tag": "crystal", "cells": Vector2i(1, 1)},
	"crystal_c": {"rect": Rect2i(146, 161, 13, 14), "foot": Vector2i(6, 13), "block": Vector2(8, 4), "tag": "crystal", "cells": Vector2i(1, 1)},
	"tent": {"rect": Rect2i(16, 200, 64, 56), "foot": Vector2i(32, 54), "block": Vector2(56, 14), "tag": "clutter", "cells": Vector2i(4, 2)},
	"firepit": {"rect": Rect2i(27, 290, 26, 22), "foot": Vector2i(13, 18), "block": Vector2(16, 6), "tag": "fire", "cells": Vector2i(2, 1), "flame": Vector2i(13, 10)},
	"firepit_b": {"rect": Rect2i(115, 295, 26, 22), "foot": Vector2i(13, 18), "block": Vector2(16, 6), "tag": "fire", "cells": Vector2i(2, 1), "flame": Vector2i(13, 10)},
	"spit": {"rect": Rect2i(22, 269, 36, 19), "foot": Vector2i(18, 17), "block": Vector2(26, 5), "tag": "clutter", "cells": Vector2i(2, 1)},
	"lily": {"rect": Rect2i(176, 225, 15, 15), "foot": Vector2i(7, 12), "block": Vector2.ZERO, "tag": "water", "cells": Vector2i(1, 1)},
	"lily_b": {"rect": Rect2i(208, 226, 14, 13), "foot": Vector2i(7, 11), "block": Vector2.ZERO, "tag": "water", "cells": Vector2i(1, 1)},
	"reeds": {"rect": Rect2i(240, 226, 13, 11), "foot": Vector2i(6, 10), "block": Vector2.ZERO, "tag": "reed", "cells": Vector2i(1, 1)},
	"reeds_b": {"rect": Rect2i(258, 225, 10, 11), "foot": Vector2i(5, 10), "block": Vector2.ZERO, "tag": "reed", "cells": Vector2i(1, 1)},
	"bridge_h": {"rect": Rect2i(150, 244, 53, 40), "foot": Vector2i(26, 38), "block": Vector2.ZERO, "tag": "bridge", "cells": Vector2i(3, 2)},
	"bridge_v": {"rect": Rect2i(231, 259, 34, 59), "foot": Vector2i(17, 57), "block": Vector2.ZERO, "tag": "bridge", "cells": Vector2i(2, 4)},
	"brazier": {"sheet": "torch", "rect": Rect2i(16, 0, 16, 16), "foot": Vector2i(8, 15), "block": Vector2(8, 4), "tag": "torch", "cells": Vector2i(1, 1), "frames": 5},
}
const TREE_SETS := {
	"green": ["oak", "tree_round", "oak_big", "pine", "pine_b", "pine_small", "sapling", "sapling_b"],
	"pines": ["pine", "pine_b", "pine_small", "pine_big", "pine_small"],
	"autumn": ["oak_orange", "oak_yellow", "oak_orange", "oak_yellow", "tree_bare", "dead_small"],
	"blossom": ["pink", "pink_b", "pink_small", "oak", "tree_round"],
	"teal": ["teal", "teal_b", "teal_big", "pine_small"],
	"dead": ["tree_bare", "tree_bare_white", "dead_small"],
}
const CLUTTER: Array[String] = ["barrel", "barrel_b", "barrel_water", "crate", "crate_b", "crate_stack", "crate_c", "apples", "produce", "pot", "pot_b"]

# Recipes. season: green/autumn; zones: share of dark forest floor; trees:
# [set, count]; ponds/houses/plateaus: [min, max]; lake, stream; path:
# ground row (DIRT, SAND, PAVING...) and layout; piece: the set piece.
const RECIPES := [
	{"name": "Meadow", "season": "green", "zones": 0.12, "trees": ["green", 16], "ponds": [1, 1], "houses": [0, 0], "plateaus": [0, 0], "path": ["cross", DIRT], "piece": "flowers", "flowers": 70},
	{"name": "Village green", "season": "green", "zones": 0.08, "trees": ["green", 12], "ponds": [0, 1], "houses": [3, 4], "plateaus": [0, 0], "path": ["village", PAVING], "piece": "market", "flowers": 40},
	{"name": "Hamlet road", "season": "green", "zones": 0.12, "trees": ["green", 16], "ponds": [0, 1], "houses": [2, 2], "plateaus": [0, 0], "path": ["road", DIRT], "piece": "field", "flowers": 40},
	{"name": "Lakeside", "season": "green", "zones": 0.1, "trees": ["green", 14], "ponds": [0, 0], "lake": true, "houses": [0, 1], "plateaus": [0, 0], "path": ["shore", DIRT], "piece": "dock", "flowers": 40},
	{"name": "Forest glade", "season": "green", "zones": 0.38, "trees": ["green", 34], "ponds": [0, 1], "houses": [0, 0], "plateaus": [0, 0], "path": ["trail", DIRT], "piece": "glade", "flowers": 50},
	{"name": "Pine woods", "season": "green", "zones": 0.3, "trees": ["pines", 38], "ponds": [0, 1], "houses": [0, 1], "plateaus": [0, 1], "path": ["trail", GRAVEL], "piece": "camp", "flowers": 20},
	{"name": "Autumn woods", "season": "autumn", "zones": 0.0, "trees": ["autumn", 30], "ponds": [0, 1], "houses": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT], "piece": "glade", "flowers": 40},
	{"name": "Cliffside", "season": "green", "zones": 0.12, "trees": ["green", 16], "ponds": [0, 1], "houses": [0, 0], "plateaus": [1, 1], "path": ["to_plateau", DIRT], "piece": "cave", "flowers": 40},
	{"name": "Terraces", "season": "green", "zones": 0.1, "trees": ["green", 14], "ponds": [0, 0], "houses": [0, 1], "plateaus": [2, 2], "path": ["to_plateau", DIRT], "piece": "flowers", "flowers": 50},
	{"name": "Stone quarry", "season": "green", "zones": 0.05, "trees": ["pines", 10], "ponds": [0, 1], "houses": [0, 0], "plateaus": [2, 2], "stone": true, "path": ["to_plateau", GRAVEL], "piece": "quarry", "flowers": 15},
	{"name": "Campsite", "season": "green", "zones": 0.2, "trees": ["green", 22], "ponds": [1, 1], "houses": [0, 0], "plateaus": [0, 0], "path": ["trail", DIRT], "piece": "camp", "flowers": 40},
	{"name": "Graveyard", "season": "autumn", "zones": 0.0, "trees": ["dead", 12], "ponds": [0, 0], "houses": [0, 1], "plateaus": [0, 0], "path": ["road", GRAVEL], "piece": "graves", "flowers": 10},
	{"name": "Blossom grove", "season": "green", "zones": 0.08, "trees": ["blossom", 22], "ponds": [1, 1], "houses": [0, 1], "plateaus": [0, 0], "path": ["trail", DIRT], "piece": "flowers", "flowers": 90},
	{"name": "Crystal hollow", "season": "green", "zones": 0.3, "trees": ["teal", 20], "ponds": [1, 1], "shore": "deep", "houses": [0, 0], "plateaus": [0, 1], "path": ["trail", GRAVEL], "piece": "crystals", "flowers": 30},
	{"name": "Farmstead", "season": "green", "zones": 0.08, "trees": ["green", 10], "ponds": [0, 1], "houses": [1, 2], "plateaus": [0, 0], "path": ["road", DIRT], "piece": "field", "flowers": 30},
	{"name": "Market square", "season": "green", "zones": 0.0, "trees": ["blossom", 8], "ponds": [0, 0], "houses": [4, 5], "plateaus": [0, 0], "path": ["village", PAVING], "piece": "market", "flowers": 25},
	{"name": "Riverside", "season": "green", "zones": 0.12, "trees": ["green", 18], "ponds": [0, 0], "stream": true, "houses": [0, 2], "plateaus": [0, 0], "path": ["cross", DIRT], "piece": "flowers", "flowers": 45},
	{"name": "Marsh", "season": "green", "zones": 0.4, "trees": ["dead", 14], "ponds": [3, 4], "shore": "deep", "houses": [0, 0], "plateaus": [0, 0], "path": ["trail", DIRT], "piece": "reeds", "flowers": 15},
	{"name": "Autumn hamlet", "season": "autumn", "zones": 0.0, "trees": ["autumn", 16], "ponds": [0, 1], "houses": [2, 3], "plateaus": [0, 0], "path": ["village", DIRT], "piece": "market", "flowers": 30},
	{"name": "Giant tree", "season": "green", "zones": 0.25, "trees": ["green", 14], "ponds": [0, 1], "houses": [0, 0], "plateaus": [0, 0], "path": ["cross", DIRT], "piece": "giant", "flowers": 60},
]
const ATTEMPTS := 40

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var attempt := 0
var season: Dictionary

var kind := PackedByteArray()
var ground := {} # cell -> atlas (terrain.png): grass, dark grass, deco
var dark := {} # forest-floor zone cells (mid and deep)
var deep := {} # the deep level, inside `dark`
var patches := {} # dirt patch cells (also in `paths`, autotiled with them)
var paths := {} # cell -> ground row (DIRT...), the autotiled grounds
var path_tiles := {} # cell -> atlas (terrain.png)
var water := {} # cell -> atlas of frame 0 (water.png)
var cliffs := {} # cell -> {atlas, flip} (terrain.png)
var plateaus: Array[Dictionary] = [] # {rect, stair (x of the stair's left column), cliff}
var houses: Array[Dictionary] = [] # {origin, roof, gable, wall, interior (5 columns), door (cell in front)}
var props: Array[Dictionary] = [] # {art, cell}
var fires: Array[Vector2i] = []
var ponds: Array[Rect2i] = []
var bridges := {} # walkable cells over the stream (the water is still painted under the bridge)
var blocked := {}
var spawn := Vector2i.ZERO
var goals: Array[Vector2i] = []
var notes := PackedStringArray()
var fails := PackedStringArray()
var floor_notes := PackedStringArray()

var _rng := RandomNumberGenerator.new()
var _taken := {} # cells claimed by structures and props


func generate(p_map_id: int, p_recipe := -1) -> String:
	map_id = p_map_id
	recipe_id = p_recipe if p_recipe >= 0 else posmod(p_map_id, RECIPES.size())
	recipe = RECIPES[recipe_id]
	season = AUTUMN if recipe.season == "autumn" else GREEN
	for a in ATTEMPTS:
		attempt = a
		_rng.seed = hash(Vector2i(map_id, a))
		if _build() and _reaches_all():
			break
	return _report()


func _build() -> bool:
	kind.resize(W * H)
	kind.fill(GRASS)
	for d in [ground, dark, deep, patches, paths, path_tiles, water, cliffs, blocked, bridges, _taken]:
		d.clear()
	zone_field = []
	zone_cut = 0.0
	deep_cut = 0.0
	for a in [plateaus, houses, props, fires, ponds, goals]:
		a.clear()
	notes.clear()
	fails.clear()
	floor_notes.clear()
	spawn = Vector2i(W / 2 + _rng.randi_range(-10, 10), H - 3)
	_claim(Rect2i(spawn - Vector2i(2, 2), Vector2i(5, 4)))
	for i in _rng.randi_range(recipe.plateaus[0], recipe.plateaus[1]):
		_plateau()
	if recipe.get("lake", false):
		_pond(Vector2i(_rng.randi_range(12, 18), _rng.randi_range(7, 10)))
	if recipe.get("stream", false):
		_stream()
	for i in _rng.randi_range(recipe.ponds[0], recipe.ponds[1]):
		_pond(Vector2i(_rng.randi_range(4, 8), _rng.randi_range(3, 5)))
	var want_houses := _rng.randi_range(recipe.houses[0], recipe.houses[1])
	for i in want_houses:
		_house()
	if houses.size() < recipe.houses[0]:
		return false
	_zones()
	_lay_paths()
	_piece()
	_settle_zones()
	_patches()
	_scatter_trees()
	_scatter_small()
	_liveliness_floor()
	_paint_ground()
	_autotile_paths()
	_autotile_water()
	return true


# ---------------------------------------------------------------- plateaus

# A raised grass top with a rounded rim over a two-row rock face; stairs four
# wide cut through the south rim and face, sometimes a cave in the face.
func _plateau() -> void:
	var cliff := CLIFF_GREY if recipe.get("stone", false) else CLIFF_BROWN
	for t in 60:
		var size := Vector2i(_rng.randi_range(9, 16), _rng.randi_range(5, 7))
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(2, H - size.y - 10))
		var r := Rect2i(at, size + Vector2i(0, 2)) # top + face
		if not _free(r.grow(2)):
			continue
		var top := Rect2i(at, size)
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				var col := 0 if x == r.position.x else (2 if x == r.end.x - 1 else 1)
				var row := y - r.position.y
				if row < size.y:
					kind[_i(c)] = TOP
					if row == 0:
						cliffs[c] = {"atlas": Vector2i(cliff + 1 + col, 14), "flip": false}
					elif row == size.y - 1:
						cliffs[c] = {"atlas": Vector2i(cliff + 1 + col, 17), "flip": false}
					elif col == 0:
						cliffs[c] = {"atlas": Vector2i(cliff + 1, 16), "flip": false}
					elif col == 2:
						cliffs[c] = {"atlas": Vector2i(cliff + 1, 16), "flip": true}
				else:
					kind[_i(c)] = FACE
					cliffs[c] = {"atlas": Vector2i(cliff + 1 + col, 18 + row - size.y), "flip": false}
		# Stairs: four columns of the south rim and both face rows.
		var sx := _rng.randi_range(r.position.x + 2, r.end.x - 6)
		for i in 4:
			for k in 3:
				var c := Vector2i(sx + i, top.end.y - 1 + k)
				cliffs[c] = {"atlas": Vector2i(cliff + 5 + i, 22 + k), "flip": false}
				kind[_i(c)] = TOP if k == 0 else STAIR
		# A cave in the face on the other side of the stairs.
		if _rng.randf() < 0.6:
			var cx := r.position.x + 1 if sx - r.position.x > r.end.x - sx - 4 else r.end.x - 2
			if absi(cx - sx) > 1 and absi(cx - (sx + 3)) > 1:
				for k in 2:
					cliffs[Vector2i(cx, top.end.y + k)] = {"atlas": Vector2i(cliff + 4, 18 + k), "flip": false}
		plateaus.append({"rect": r, "top": top, "stair": sx, "cliff": cliff})
		goals.append(Vector2i(sx + 1, top.position.y + 2))
		_claim(r.grow(1))
		for i in range(-1, 5):
			_taken[Vector2i(sx + i, r.end.y)] = true
		return
	notes.append("plateau dropped")


# ---------------------------------------------------------------- water

func _shore() -> Dictionary:
	var name: String = recipe.get("shore", "yellow" if recipe.season == "autumn" else "grass")
	for s in SHORES:
		if s.name == name:
			return s
	return SHORES[0]


# A pond: a rectangle with one or two bumps (so its outline has inner corners).
func _pond(size: Vector2i) -> void:
	for t in 80:
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(2, H - size.y - 6))
		var r := Rect2i(at, size)
		if not _free(r.grow(3)):
			continue
		var cells := {}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				cells[Vector2i(x, y)] = true
		# Bumps on the edges, at least 3x2, so every corner has a tile.
		for b in _rng.randi_range(1, 2):
			var bw := _rng.randi_range(3, maxi(3, size.x - 3))
			var bx := _rng.randi_range(r.position.x + 1, r.end.x - bw - 1)
			var up := _rng.randf() < 0.5
			var by := r.position.y - 2 if up else r.end.y
			var br := Rect2i(bx, by, bw, 2)
			if _free(br.grow(1)):
				for y in range(br.position.y, br.end.y):
					for x in range(br.position.x, br.end.x):
						cells[Vector2i(x, y)] = true
		for c in cells:
			kind[_i(c)] = WATER
			water[c] = Vector2i.ZERO
		ponds.append(r)
		_claim(r.grow(2))
		for c in cells:
			_taken[c] = true
		return
	notes.append("pond dropped")


# A stream three wide from the north edge to the south, bending once, with a
# bridge where the main path crosses it.
func _stream() -> void:
	var x := _rng.randi_range(12, W - 15)
	var bend := _rng.randi_range(12, H - 14)
	var x2 := clampi(x + _rng.randi_range(-8, 8), 6, W - 9)
	for y in range(-1, H + 1):
		var cx := x if y < bend else x2
		for dx in 3:
			var c := Vector2i(cx + dx, y)
			if _inside(c):
				kind[_i(c)] = WATER
				water[c] = Vector2i.ZERO
				_taken[c] = true
		if y == bend:
			for xx in range(mini(x, x2), maxi(x, x2) + 3):
				for dy in 3:
					var c := Vector2i(xx, y + dy - 1)
					if _inside(c):
						kind[_i(c)] = WATER
						water[c] = Vector2i.ZERO
						_taken[c] = true
	# A bridge over the lower run, where the walk from the spawn crosses.
	var by := _rng.randi_range(bend + 4, H - 6)
	var bx := x2 if by >= bend else x
	for dx in 3:
		for dy in 2:
			var c := Vector2i(bx + dx, by + dy)
			if _inside(c):
				kind[_i(c)] = GROUND
				bridges[c] = true
	props.append({"art": "bridge_h", "cell": Vector2i(bx + 1, by + 1)})
	# The banks either side stay open.
	for dy in 2:
		_taken.erase(Vector2i(bx - 1, by + dy))
		_taken.erase(Vector2i(bx + 3, by + dy))
	goals.append(Vector2i(bx - 1, by))
	goals.append(Vector2i(bx + 3, by))
	notes.append("stream at %d/%d, bridge at %d" % [x, x2, by])


# ---------------------------------------------------------------- houses

# A gable house 7 wide and 7 tall (5 roof rows over a 2-row wall band); the
# door is in the middle of the band, the doorstep the cell below it.
func _house() -> void:
	for t in 80:
		var at := Vector2i(_rng.randi_range(2, W - 9), _rng.randi_range(2, H - 16))
		var r := Rect2i(at, Vector2i(7, 7))
		if not _free(Rect2i(at - Vector2i(1, 1), Vector2i(9, 10))):
			continue
		var wall: int = WALL_ROW[_rng.randi() % WALL_ROW.size()]
		var pairs: Array = WINDOW_PAIRS.duplicate()
		if wall >= 14:
			pairs = pairs.slice(0, 2) # the stone walls' last windows carry snow
		var a: Array = pairs[_rng.randi() % pairs.size()]
		var b: Array = pairs[_rng.randi() % pairs.size()]
		var inner := [a[0], a[1], 5, b[0], b[1]]
		if _rng.randf() < 0.3:
			inner = [2, a[0], 5, a[1], 2]
		var h := {"origin": at, "roof": ROOF_X[_rng.randi() % ROOF_X.size()], "gable": GABLE_ROW[_rng.randi() % GABLE_ROW.size()],
			"wall": wall, "interior": inner, "door": at + Vector2i(3, 7), "chimney": _rng.randf() < 0.6}
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var c := Vector2i(x, y)
				kind[_i(c)] = HOUSE
				if y - r.position.y >= 3:
					blocked[c] = true
		houses.append(h)
		goals.append(h.door)
		_claim(Rect2i(at - Vector2i(1, 1), Vector2i(9, 9)))
		_taken.erase(h.door)
		return


# ---------------------------------------------------------------- paths

func _lay_paths() -> void:
	var row: int = recipe.path[1]
	var layout: String = recipe.path[0]
	var pts: Array[Vector2i] = []
	for h in houses:
		pts.append(h.door)
	for p in plateaus:
		pts.append(Vector2i(p.stair + 1, p.rect.end.y))
	var hub := Vector2i(W / 2 + _rng.randi_range(-6, 6), H / 2 + _rng.randi_range(-4, 4))
	match layout:
		"cross":
			_route(Vector2i(0, hub.y), Vector2i(W - 1, hub.y), row)
			_route(spawn, hub, row)
		"road":
			var y := _rng.randi_range(H / 2 - 2, H / 2 + 6)
			_route(Vector2i(0, y), Vector2i(W - 1, y), row)
			_route(spawn, Vector2i(spawn.x, y), row)
			hub = Vector2i(spawn.x, y)
		"village":
			var plaza := Rect2i(hub - Vector2i(4, 3), Vector2i(9, 6))
			if _free_ground(plaza):
				for y in range(plaza.position.y, plaza.end.y):
					for x in range(plaza.position.x, plaza.end.x):
						_set_path(Vector2i(x, y), row)
			_route(spawn, hub, row)
		"shore":
			_route(spawn, hub, row)
		"trail", "to_plateau":
			_route(spawn, hub, row)
	for p in pts:
		_route(p, hub, row)
	goals.append(hub)


# A* over grass (roads avoid water, cliffs, houses), then two wide.
var _wander := FastNoiseLite.new()

func _route(a: Vector2i, b: Vector2i, row: int, around_props := false) -> void:
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
			if k == WATER or k == FACE or k == HOUSE or k == TOP or k == STAIR:
				astar.set_point_solid(c, true)
			elif _taken.has(c) and not paths.has(c):
				if around_props:
					astar.set_point_solid(c, true)
				else:
					astar.set_point_weight_scale(c, 4.0)
			elif not paths.has(c):
				# A noise cost, so paths wind like a trodden trail instead of
				# running dead straight; joining an existing path is cheap.
				astar.set_point_weight_scale(c, 1.0 + 3.0 * _wander.get_noise_2d(x, y) * 0.5 + 1.5)
			else:
				astar.set_point_weight_scale(c, 0.6)
	a = a.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	b = b.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	for c in [a, b]:
		astar.set_point_solid(c, false)
	var cells := astar.get_id_path(a, b)
	for c in cells:
		for o in [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var n: Vector2i = c + o
			if _inside(n) and kind[_i(n)] == GRASS and not (around_props and _taken.has(n)):
				_set_path(n, row)


func _set_path(c: Vector2i, row: int) -> void:
	if _inside(c) and not bridges.has(c) and (kind[_i(c)] == GRASS or kind[_i(c)] == GROUND):
		kind[_i(c)] = GROUND
		paths[c] = row
		_taken[c] = true


func _free_ground(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or kind[_i(c)] != GRASS and kind[_i(c)] != GROUND:
				return false
	return true


# ---------------------------------------------------------------- set pieces

func _piece() -> void:
	var c := _open_spot(Vector2i(5, 4))
	match recipe.piece:
		"camp":
			_place("tent", c)
			_place(["firepit", "firepit_b"][_rng.randi() % 2], c + Vector2i(5, 1))
			_place("log", c + Vector2i(4, 3))
			_place("spit", c + Vector2i(1, 3))
			_near(CLUTTER, 3, c + Vector2i(2, 2), 4)
		"graves":
			for k in 5:
				_place(["graves", "grave_cross", "grave_cross"][k % 3], c + Vector2i((k % 3) * 5 - 3, (k / 3) * 3))
			_near(["dead_small", "tree_bare"], 2, c, 6)
			_near(["brazier"], 2, c, 5)
		"market":
			var hub := goals[-1] if not goals.is_empty() else c
			_near(CLUTTER, 10, hub, 5)
			_near(["sign", "sign_small"], 2, hub, 5)
			_near(["brazier"], 2, hub, 4)
		"field":
			# Packed-dirt field rows beside the road.
			var f := _open_spot(Vector2i(8, 6))
			var fr := Rect2i(f - Vector2i(4, 3), Vector2i(8, 6))
			if _free_ground(fr):
				for y in range(fr.position.y, fr.end.y):
					for x in range(fr.position.x, fr.end.x):
						_set_path(Vector2i(x, y), PACKED)
				_near(["produce", "apples", "barrel"], 3, fr.get_center() + Vector2i(0, 4), 4)
		"dock":
			_near(["barrel", "crate", "crate_stack"], 3, c, 4)
			_near(["brazier"], 1, c, 3)
		"cave":
			_near(["brazier"], 2, c, 4)
			_near(["rock", "rock_b", "log"], 3, c, 5)
		"quarry":
			_near(["rock", "rock_b", "crystal", "crate", "barrel"], 8, c, 6)
		"crystals":
			_near(["crystal", "crystal_b", "crystal_c"], 12, c, 7)
		"reeds":
			pass # reeds come with the ponds
		"giant":
			_place(["tree_giant", "tree_giant_red"][_rng.randi() % 2], c)
			_near(["stump_flower", "stump_mushroom"], 2, c, 5)
		"glade", "flowers":
			_near(["stump_mushroom", "stump_flower", "log"], 3, c, 5)
	# A spur from the network to the camp, graves, giant tree, or quarry, so the
	# path leads somewhere instead of ending in the lawn.
	if recipe.piece in ["camp", "graves", "giant", "quarry", "crystals"] and not goals.is_empty():
		var door := _free_near(c + Vector2i(0, 3), 4)
		if door != Vector2i(-1, -1):
			_route(door, goals[-1], recipe.path[1], true)
	# Every pond gets reeds and lily pads.
	for r in ponds:
		for k in _rng.randi_range(2, 5):
			var p := r.position + Vector2i(_rng.randi_range(1, r.size.x - 2), _rng.randi_range(1, r.size.y - 2))
			if water.has(p):
				props.append({"art": ["lily", "lily_b"][_rng.randi() % 2], "cell": p})
		for k in _rng.randi_range(2, 6 if recipe.piece == "reeds" else 3):
			var p := Vector2i(_rng.randi_range(r.position.x - 1, r.end.x), [r.position.y - 1, r.end.y][_rng.randi() % 2])
			if _inside(p) and kind[_i(p)] == GRASS and not _taken.has(p):
				props.append({"art": ["reeds", "reeds_b"][_rng.randi() % 2], "cell": p})
				_taken[p] = true
	# Clutter by every house door.
	for h in houses:
		_near(CLUTTER, _rng.randi_range(1, 3), h.door + Vector2i(0, 1), 3)


## The free lawn cell nearest `c` within `radius`, or (-1, -1).
func _free_near(c: Vector2i, radius: int) -> Vector2i:
	var best := Vector2i(-1, -1)
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var n := c + Vector2i(dx, dy)
			if _inside(n) and kind[_i(n)] == GRASS and not _taken.has(n) \
					and (best.x < 0 or (n - c).length_squared() < (best - c).length_squared()):
				best = n
	return best


func _open_spot(size: Vector2i) -> Vector2i:
	for t in 200:
		var c := Vector2i(_rng.randi_range(size.x + 2, W - size.x - 3), _rng.randi_range(size.y + 2, H - size.y - 4))
		if _free(Rect2i(c - size / 2, size)):
			return c
	return Vector2i(W / 2, H / 2)


func _near(arts: Array, count: int, center: Vector2i, radius: int) -> void:
	var put := 0
	for t in count * 20:
		if put >= count:
			return
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if _place(arts[_rng.randi() % arts.size()], c):
			put += 1


## Places `art` with its foot on `cell` if its footprint is free grass.
func _place(art: String, cell: Vector2i) -> bool:
	var p: Dictionary = PROPS[art]
	var cells: Vector2i = p.cells
	var r := Rect2i(cell - Vector2i(cells.x / 2, cells.y - 1), cells)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != GRASS or c == spawn:
				return false
	props.append({"art": art, "cell": cell})
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true
	if p.block != Vector2.ZERO:
		blocked[cell] = true
	if p.tag == "fire" or p.tag == "torch":
		fires.append(cell)
	return true


# ---------------------------------------------------------------- scatter

func _scatter_trees() -> void:
	var set_: Array = TREE_SETS[recipe.trees[0]]
	var want: int = recipe.trees[1]
	var placed: Array[Vector2i] = []
	for t in want * 30:
		if placed.size() >= want:
			break
		var c := Vector2i(_rng.randi_range(1, W - 2), _rng.randi_range(2, H - 2))
		# Trees keep a little apart and crowd into the forest-floor zones.
		var near := false
		for p in placed:
			if Vector2(p - c).length() < (3.0 if dark.has(c) else 5.0):
				near = true
				break
		if near or (not dark.has(c) and _rng.randf() < recipe.zones):
			continue
		if _place(set_[_rng.randi() % set_.size()], c):
			placed.append(c)


func _scatter_small() -> void:
	var stones := ["rock", "rock_b"]
	for k in _rng.randi_range(4, 10):
		_place(stones[_rng.randi() % 2], Vector2i(_rng.randi_range(1, W - 2), _rng.randi_range(1, H - 2)))
	for k in _rng.randi_range(1, 3):
		_place(["log", "stump", "stump_b"][_rng.randi() % 3], Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(2, H - 2)))


# ---------------------------------------------------------------- ground

# Forest-floor zones: a smooth noise field cut at the recipe's share; the
# painter draws their rim per pixel so no edge follows the grid.
func _zones() -> void:
	var share: float = recipe.zones
	if share <= 0.0 or recipe.season != "green":
		return
	share = maxf(share, ZONE_FLOOR)
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 13 + attempt
	noise.frequency = 0.06
	var vals: Array[float] = []
	for y in H:
		for x in W:
			vals.append(noise.get_noise_2d(x, y))
	var sorted := vals.duplicate()
	sorted.sort()
	zone_cut = sorted[int((1.0 - share) * sorted.size())]
	# Deep takes a share of the map inside mid, at least 0.1 above the mid cut
	# so mid keeps a band of its own round every deep patch.
	deep_cut = maxf(sorted[int((1.0 - share * DEEP_SHARE) * sorted.size())], zone_cut + 0.1)
	zone_field = vals
	_zone_cells()


## Zones fade out toward paths, water, cliffs, and stairs (their tiles bake
## the light lawn): no zone within one cell, then back in over ZONE_FADE.
## Then specks are dropped (from the field too, so the rims agree).
func _settle_zones() -> void:
	if zone_field.is_empty():
		return
	var dist := {}
	var queue: Array[Vector2i] = []
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != GRASS and kind[_i(c)] != HOUSE:
				dist[c] = 0
				queue.append(c)
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if dist[c] >= ZONE_FADE:
			continue
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if _inside(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var low := zone_cut - 0.25
	for c: Vector2i in dist:
		var d: int = dist[c]
		var i := _i(c)
		var t := clampf((d - 1) / float(ZONE_FADE - 1), 0.0, 1.0)
		zone_field[i] = minf(zone_field[i], lerpf(low, zone_field[i], t))
	_zone_cells()
	for level in [[deep, deep_cut], [dark, zone_cut]]:
		var cells: Dictionary = level[0]
		for comp in _components(cells):
			if comp.size() < 6:
				for c in comp:
					zone_field[_i(c)] = minf(zone_field[_i(c)], level[1] - 0.03)
	_zone_cells()


func _zone_cells() -> void:
	dark.clear()
	deep.clear()
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != GRASS:
				continue
			var v := zone_field[_i(c)]
			if v >= zone_cut:
				dark[c] = true
				if v >= deep_cut:
					deep[c] = true


func _components(cells: Dictionary) -> Array:
	var out := []
	var seen := {}
	for c0: Vector2i in cells:
		if seen.has(c0):
			continue
		var comp: Array[Vector2i] = [c0]
		seen[c0] = true
		var k := 0
		while k < comp.size():
			var c := comp[k]
			k += 1
			for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var n: Vector2i = c + d
				if cells.has(n) and not seen.has(n):
					seen[n] = true
					comp.append(n)
		out.append(comp)
	return out


# ---------------------------------------------------------------- dirt patches

## Bare-earth patches on the light lawn: rounded rectangles (3x3 to 5x3) or two
## joined with arms at least three cells thick, autotiled with the path pieces.
## Their edge tiles bake the light lawn, so a patch stays two cells off the
## zones; three cells from any path, four from another patch.
func _patches() -> void:
	var span: Array = recipe.get("patches", [3, 5])
	var want := _rng.randi_range(span[0], span[1])
	# Packed dirt reads as pale sand here; plain dirt, or gravel on gravel maps.
	var rows: Array[int] = [DIRT]
	if recipe.path[1] == GRAVEL:
		rows.append(GRAVEL)
	var made := 0
	for t in want * 40:
		if made >= want:
			break
		var shape := _patch_shape()
		var at := Vector2i(_rng.randi_range(2, W - 8), _rng.randi_range(2, H - 7))
		var cells: Array[Vector2i] = []
		for r: Rect2i in shape:
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					var c := at + Vector2i(x, y)
					if not cells.has(c):
						cells.append(c)
		if not _patch_fits(cells):
			continue
		var row: int = rows[_rng.randi() % rows.size()]
		for c in cells:
			_set_path(c, row)
			patches[c] = true
		made += 1


func _patch_shape() -> Array[Rect2i]:
	# The sheet's outer corners cut diagonally, so a 2x2 draws as a diamond:
	# three cells each way at least.
	var sizes: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(5, 3), Vector2i(4, 4)]
	var a := Rect2i(Vector2i.ZERO, sizes[_rng.randi() % sizes.size()])
	if _rng.randf() < 0.45:
		return [a]
	var bs := sizes[_rng.randi() % sizes.size()]
	var b: Rect2i
	if _rng.randf() < 0.5:
		# To the east, sharing at least three rows.
		b = Rect2i(Vector2i(a.end.x - 1, _rng.randi_range(-(bs.y - 3), a.size.y - 3)), bs)
	else:
		# To the south, sharing at least three columns.
		b = Rect2i(Vector2i(_rng.randi_range(-(bs.x - 3), a.size.x - 3), a.end.y - 1), bs)
	var o := Vector2i(mini(0, b.position.x), mini(0, b.position.y))
	return [Rect2i(a.position - o, a.size), Rect2i(b.position - o, b.size)]


func _patch_fits(cells: Array[Vector2i]) -> bool:
	for c in cells:
		for dy in range(-4, 5):
			for dx in range(-4, 5):
				var n := c + Vector2i(dx, dy)
				var r := maxi(absi(dx), absi(dy))
				if patches.has(n):
					return false
				if r <= 3 and paths.has(n):
					return false
				if r <= 1 and (not _inside(n) or kind[_i(n)] != GRASS or _taken.has(n) or n == spawn):
					return false
				# The rims draw zone pixels a cell into the lawn.
				if r <= 2 and dark.has(n):
					return false
	return true


var zone_cut := 0.0
var deep_cut := 0.0
var zone_field: Array[float] = []


func _paint_ground() -> void:
	var fill: Vector2i = season.fill
	var vary: Array = season.vary
	var deco: Array = season.deco
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			var h := _hash(x, y)
			var t := fill
			if deep.has(c):
				t = DEEP_FILLS[int(h * 97.0) % DEEP_FILLS.size()]
			elif dark.has(c):
				t = MID_FILLS[int(h * 97.0) % MID_FILLS.size()]
			elif kind[_i(c)] == GRASS and not _taken.has(c) and h > 1.0 - recipe.flowers / 1000.0:
				t = deco[int(h * 997.0) % deco.size()]
			elif h < 0.08 and not vary.is_empty():
				t = vary[int(h * 991.0) % vary.size()]
			ground[c] = t


func _autotile_paths() -> void:
	# Reshape: drop cells with grass on two opposite sides or three sides
	# (no tile draws them), until every cell has a tile.
	for pass_i in 12:
		var drop: Array[Vector2i] = []
		for c in paths:
			var m := _pmask(c)
			var open := 15 - m
			if open == 5 or open == 10 or open == 7 or open == 11 or open == 13 or open == 14 or open == 15:
				drop.append(c)
		if drop.is_empty():
			break
		for c in drop:
			paths.erase(c)
			kind[_i(c)] = GRASS
	var base: int = season.row
	for c in paths:
		var row: int = base + paths[c]
		var open := 15 - _pmask(c)
		var col := P_FILL
		if open == 0:
			# All four sides ground: an inner nub where one diagonal is grass.
			for d in [[Vector2i(-1, -1), "NW"], [Vector2i(1, -1), "NE"], [Vector2i(-1, 1), "SW"], [Vector2i(1, 1), "SE"]]:
				if not _ground_like(c + d[0], paths[c]):
					col = P_INNER[d[1]]
					break
		elif P_EDGE.has(open):
			col = P_EDGE[open]
		elif P_OUTER.has(open):
			col = P_OUTER[open]
		path_tiles[c] = Vector2i(col, row)


# N=1 E=2 S=4 W=8 of neighbors that are the same ground (map edges count).
func _pmask(c: Vector2i) -> int:
	var m := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		if _ground_like(c + dirs[i], paths[c]):
			m |= 1 << i
	return m


func _ground_like(c: Vector2i, row: int) -> bool:
	if not _inside(c):
		return true
	return paths.get(c, -1) == row


func _autotile_water() -> void:
	var s: Dictionary = _shore()
	var o: Vector2i = s.origin
	for c in water:
		var n := _water_at(c + Vector2i.UP)
		var e := _water_at(c + Vector2i.RIGHT)
		var so := _water_at(c + Vector2i.DOWN)
		var w := _water_at(c + Vector2i.LEFT)
		var col := 1 if (w and e) else (0 if not w else 2)
		var row := 1 if (n and so) else (0 if not n else 2)
		var t := o + Vector2i(col, 2 + row)
		if n and so and w and e:
			# Inner corners: land only at one diagonal.
			if not _water_at(c + Vector2i(-1, -1)):
				t = o + Vector2i(1, 0)
			elif not _water_at(c + Vector2i(1, -1)):
				t = o + Vector2i(2, 0)
			elif not _water_at(c + Vector2i(-1, 1)):
				t = o + Vector2i(1, 1)
			elif not _water_at(c + Vector2i(1, 1)):
				t = o + Vector2i(2, 1)
		water[c] = t


func _water_at(c: Vector2i) -> bool:
	return not _inside(c) or water.has(c)


# ---------------------------------------------------------------- liveliness
# The Painted Lands floor: every camera-sized window should have something
# moving; a weak window gets a campfire or a pair of braziers.
const LIVE_FLOOR := 0.09
const FLOOR_ANCHORS := 5
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WATER := 6.0
const FLOOR_FIRE := 240.0
const FLOOR_TORCH := 60.0
const FLOOR_TREE := 2.0

func _liveliness_floor() -> void:
	for n in FLOOR_ANCHORS:
		var weak := _weakest()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR:
			if n > 0:
				floor_notes.append("-> %.3f%%" % weak.value)
			return
		var r: Rect2i = weak.rect
		# A path through the window gets a pair of braziers facing each other
		# across it, unless the window is under half the floor: then a campfire
		# in a clearing first.
		var added := ""
		if weak.value >= LIVE_FLOOR * 0.5 or n % 2 == 1:
			added = "braziers" if _lanterns(r) else ""
		if added == "":
			added = "campfire" if _campfire(r) else ""
		if added == "" and weak.value < LIVE_FLOOR * 0.5:
			added = "braziers" if _lanterns(r) else ""
		if added == "":
			floor_notes.append("no room")
			return
		floor_notes.append(added)
	floor_notes.append("-> %.3f%%" % _weakest().value)


## Two braziers on the grass either side of a path crossing `r`, nearest the
## window's middle first. Both or neither; kept only if every goal still reaches.
func _lanterns(r: Rect2i) -> bool:
	var mid := r.get_center()
	var cands: Array[Vector2i] = []
	for c: Vector2i in paths:
		if r.grow(-3).has_point(c) and kind[_i(c)] == GROUND and not patches.has(c):
			cands.append(c)
	cands.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return (a - mid).length_squared() < (b - mid).length_squared())
	for c: Vector2i in cands.slice(0, 40):
		# Across the path: north-south of a run going east-west, else east-west.
		var across := Vector2i.DOWN if paths.has(c + Vector2i.LEFT) and paths.has(c + Vector2i.RIGHT) else Vector2i.RIGHT
		var a := c
		while paths.has(a - across):
			a -= across
		var b := c
		while paths.has(b + across):
			b += across
		a -= across
		b += across
		if (b - a).length() > 5:
			continue
		if _try_pair(a, b):
			return true
	return false


func _try_pair(a: Vector2i, b: Vector2i) -> bool:
	var mark := props.size()
	if _place("brazier", a) and _place("brazier", b) and _reaches_all():
		return true
	_unplace(mark)
	return false


func _campfire(r: Rect2i) -> bool:
	for t in 60:
		var c := Vector2i(_rng.randi_range(r.position.x + 6, r.end.x - 7), _rng.randi_range(r.position.y + 3, r.end.y - 3))
		var clear := true
		for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2), Vector2i.ZERO]:
			if paths.has(c + d):
				clear = false
		if not clear:
			continue
		var mark := props.size()
		if _place(["firepit", "firepit_b"][_rng.randi() % 2], c) and _reaches_all():
			_near(["log", "stump"], 1, c, 2)
			return true
		_unplace(mark)
	return false


## Takes back every prop placed after `mark`.
func _unplace(mark: int) -> void:
	while props.size() > mark:
		var p: Dictionary = props.pop_back()
		var art: Dictionary = PROPS[p.art]
		var cells: Vector2i = art.cells
		var rr := Rect2i(p.cell - Vector2i(cells.x / 2, cells.y - 1), cells)
		for y in range(rr.position.y, rr.end.y):
			for x in range(rr.position.x, rr.end.x):
				_taken.erase(Vector2i(x, y))
		blocked.erase(p.cell)
		fires.erase(p.cell)


func _weakest() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(W * H)
	m.fill(0.0)
	for c in water:
		m[_i(c)] += FLOOR_WATER
	for p in props:
		var tag: String = PROPS[p.art].tag
		if not _inside(p.cell):
			continue
		if tag == "fire":
			m[_i(p.cell)] += FLOOR_FIRE
		elif tag == "torch":
			m[_i(p.cell)] += FLOOR_TORCH
		elif tag in ["tree", "autumn", "pink", "teal", "pine"]:
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
	for c in water:
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
			if (k == GRASS or k == TOP) and not blocked.has(c) and not cliffs.has(c):
				out[c] = true
	return out


func trunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in props:
		if PROPS[p.art].tag in ["tree", "autumn", "pink", "teal", "pine", "bare"]:
			out.append(p.cell)
	return out


## The wildlife plan (wildlife.gd plan_from) for this map.
func wildlife_plan() -> Dictionary:
	var grass := grass_cells()
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
		elif tag == "stone" or tag == "crystal":
			rocks.append(p.cell)
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	for c in land:
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
		if is_grass and dark.has(c):
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
	return k == GRASS or k == GROUND or k == TOP or k == STAIR or (k == HOUSE and false)


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
	if houses.size() < recipe.houses[0]:
		fails.append("houses %d of %d" % [houses.size(), recipe.houses[0]])
	if recipe.plateaus[0] > plateaus.size():
		fails.append("plateaus %d of %d" % [plateaus.size(), recipe.plateaus[0]])
	var lines := PackedStringArray([
		"Time Fantasy map %d: recipe %d %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, W, H, attempt],
		"  houses %d, plateaus %d, ponds %d, water %d cells, path %d cells, patches %d cells, zone %d cells (deep %d), props %d, fires %d" % [
			houses.size(), plateaus.size(), ponds.size(), water.size(), paths.size() - patches.size(), patches.size(), dark.size(), deep.size(), props.size(), fires.size()],
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
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != GRASS:
				return false
	return true


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func _i(c: Vector2i) -> int:
	return c.y * W + c.x
