class_name InteriorArt
extends RefCounted
## The Cozy Cottage interior pack (antarcticbees), catalogued for the
## interior generator (interior_plan.gd) and painter (interior_view.gd).
## Sheets in assets/pack/cozy_cottage/: wallpapers_and_floors.png (walls,
## wall tops, floors), furniture.png (five wood tones, each 288 px below the
## last), decoration.png (windows, paintings, rugs, lamps, plants, tableware).
## Modern items (fridges, washers, stoves, screens) are left out.

const WALLS := preload("res://assets/pack/cozy_cottage/wallpapers_and_floors.png")
const FURNITURE := preload("res://assets/pack/cozy_cottage/furniture.png")
const DECORATION := preload("res://assets/pack/cozy_cottage/decoration.png")
const TILE := 16
const WOOD_STEP := 288 # px between the furniture sheet's wood tones

## Wallpaper groups: the rows of the lip (a wall top edged toward the room)
## and three face rows under it; the trim color matches one wall-top frame.
## Frames are 3x3 with inner-corner nubs in the two columns after them; the
## black-filled copies sit nine rows lower.
const GROUP_ROW := [0, 5, 10, 15]
const FRAME := [Vector2i(0, 20), Vector2i(5, 20), Vector2i(10, 20), Vector2i(15, 20)]
const BLACK_ROWS := 9
## Wallpaper columns per group that read as cozy (plain, stripes, wainscot,
## wood, flower panels), and the first column of each group's doorway.
const PAPERS := [
	[1, 2, 3, 6, 8, 10, 11, 13, 17, 19, 21, 23, 26],
	[0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 19, 20, 21, 22, 26, 28, 30],
	[0, 1, 2, 3, 4, 5, 6, 7, 9, 11, 12, 13, 14, 19, 20, 21, 22, 26, 28, 30],
	[0, 1, 2, 3, 4, 6, 7, 9, 11, 12, 13, 14, 19, 20, 21, 22, 26, 28, 30, 32, 34],
]
const DOORWAY := [29, 34, 34, 38]

## Floors: plank blocks two cells wide and four tall, parquet blocks 2x2,
## and single-column tiles repeating every three rows.
const PLANKS: Array[Vector2i] = [Vector2i(28, 20), Vector2i(30, 20), Vector2i(32, 20), Vector2i(34, 20),
	Vector2i(37, 20), Vector2i(39, 20), Vector2i(41, 20), Vector2i(43, 20)]
const PARQUET: Array[Vector2i] = [Vector2i(29, 25), Vector2i(33, 25), Vector2i(29, 27), Vector2i(33, 27), Vector2i(38, 25), Vector2i(40, 25)]
const TILES: Array[int] = [20, 21, 22, 23, 24, 25, 26, 27]

## Furniture (brown-tone rects; add wood * WOOD_STEP to y) and decoration.
## cells: footprint (w, depth) in cells; place: "wall" (back to the north
## wall, footprint on the first floor row), "floor", "face" (hung on the wall
## face), "rug" (under everything), "top" (on a table or cabinet).
## sink/lamp/hearth/steam/window mark what the ambience uses.
const ART := {
	# wall furniture
	"wardrobe": {"rect": Rect2i(624, 6, 31, 50), "cells": Vector2i(2, 1), "place": "wall"},
	"wardrobe_b": {"rect": Rect2i(656, 8, 31, 48), "cells": Vector2i(2, 1), "place": "wall"},
	"wardrobe_vine": {"rect": Rect2i(688, 8, 31, 48), "cells": Vector2i(2, 1), "place": "wall"},
	"bookshelf": {"rect": Rect2i(561, 13, 30, 43), "cells": Vector2i(2, 1), "place": "wall"},
	"bookshelf_b": {"rect": Rect2i(593, 13, 30, 43), "cells": Vector2i(2, 1), "place": "wall"},
	"plant_shelf": {"rect": Rect2i(433, 13, 30, 43), "cells": Vector2i(2, 1), "place": "wall"},
	"plant_shelf_b": {"rect": Rect2i(465, 13, 30, 43), "cells": Vector2i(2, 1), "place": "wall"},
	"shelf": {"rect": Rect2i(497, 13, 30, 43), "cells": Vector2i(2, 1), "place": "wall"},
	"dresser": {"rect": Rect2i(65, 12, 46, 44), "cells": Vector2i(3, 1), "place": "wall"},
	"vanity": {"rect": Rect2i(32, 12, 32, 44), "cells": Vector2i(2, 1), "place": "wall"},
	"drawers": {"rect": Rect2i(756, 28, 24, 30), "cells": Vector2i(2, 1), "place": "wall", "top": true},
	"drawers_b": {"rect": Rect2i(788, 28, 24, 30), "cells": Vector2i(2, 1), "place": "wall", "top": true},
	"nightstand": {"rect": Rect2i(816, 39, 16, 19), "cells": Vector2i(1, 1), "place": "wall", "top": true},
	"cabinet": {"rect": Rect2i(835, 34, 27, 21), "cells": Vector2i(2, 1), "place": "wall", "top": true},
	"low_shelf": {"rect": Rect2i(865, 34, 30, 21), "cells": Vector2i(2, 1), "place": "wall"},
	"dish_shelf": {"rect": Rect2i(897, 34, 30, 21), "cells": Vector2i(2, 1), "place": "wall"},
	"dish_shelf_b": {"rect": Rect2i(929, 34, 30, 21), "cells": Vector2i(2, 1), "place": "wall"},
	"sofa": {"rect": Rect2i(628, 234, 40, 30), "cells": Vector2i(3, 1), "place": "wall"},
	"loveseat": {"rect": Rect2i(547, 231, 42, 33), "cells": Vector2i(3, 1), "place": "wall"},
	"bed": {"rect": Rect2i(545, 119, 30, 57), "cells": Vector2i(2, 3), "place": "wall"},
	"bed_b": {"rect": Rect2i(577, 119, 30, 57), "cells": Vector2i(2, 3), "place": "wall"},
	"bed_narrow": {"rect": Rect2i(610, 115, 26, 54), "cells": Vector2i(2, 3), "place": "wall"},
	"bed_quilt": {"rect": Rect2i(515, 120, 26, 56), "cells": Vector2i(2, 3), "place": "wall"},
	# fireplaces (their own art, the same for every wood tone)
	"hearth_white": {"rect": Rect2i(768, 448, 32, 53), "cells": Vector2i(2, 1), "place": "wall", "hearth": Rect2i(10, 38, 12, 11), "fixed": true},
	"hearth_dark": {"rect": Rect2i(800, 448, 32, 53), "cells": Vector2i(2, 1), "place": "wall", "hearth": Rect2i(10, 38, 12, 11), "fixed": true},
	"hearth_brown": {"rect": Rect2i(832, 448, 32, 53), "cells": Vector2i(2, 1), "place": "wall", "hearth": Rect2i(10, 38, 12, 11), "fixed": true},
	"hearth_flowers": {"rect": Rect2i(710, 519, 36, 29), "cells": Vector2i(3, 1), "place": "wall", "hearth": Rect2i(12, 13, 12, 12), "fixed": true},
	"hearth_flowers_b": {"rect": Rect2i(758, 519, 36, 29), "cells": Vector2i(3, 1), "place": "wall", "hearth": Rect2i(12, 13, 12, 12), "fixed": true},
	"hearth_stone": {"rect": Rect2i(566, 522, 36, 26), "cells": Vector2i(3, 1), "place": "wall", "hearth": Rect2i(12, 10, 12, 12), "fixed": true},
	"hearth_stone_b": {"rect": Rect2i(614, 522, 36, 26), "cells": Vector2i(3, 1), "place": "wall", "hearth": Rect2i(12, 10, 12, 12), "fixed": true},
	# floor furniture
	"table": {"rect": Rect2i(2, 71, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"table_b": {"rect": Rect2i(98, 71, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"table_c": {"rect": Rect2i(194, 71, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"table_d": {"rect": Rect2i(290, 71, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"table_e": {"rect": Rect2i(386, 71, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"low_table": {"rect": Rect2i(2, 113, 44, 23), "cells": Vector2i(3, 1), "place": "floor", "top": true},
	"low_table_b": {"rect": Rect2i(146, 113, 44, 23), "cells": Vector2i(3, 1), "place": "floor", "top": true},
	"low_table_c": {"rect": Rect2i(338, 113, 44, 23), "cells": Vector2i(3, 1), "place": "floor", "top": true},
	"desk": {"rect": Rect2i(194, 23, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"desk_b": {"rect": Rect2i(338, 23, 44, 33), "cells": Vector2i(3, 2), "place": "floor", "top": true},
	"long_table": {"rect": Rect2i(10, 144, 22, 48), "cells": Vector2i(2, 3), "place": "floor", "top": true},
	"long_table_b": {"rect": Rect2i(106, 144, 22, 48), "cells": Vector2i(2, 3), "place": "floor", "top": true},
	"bench": {"rect": Rect2i(96, 196, 32, 18), "cells": Vector2i(2, 1), "place": "floor"},
	"armchair": {"rect": Rect2i(596, 233, 24, 31), "cells": Vector2i(2, 1), "place": "floor"},
	"armchair_ornate": {"rect": Rect2i(515, 231, 26, 33), "cells": Vector2i(2, 1), "place": "floor"},
	"chair_front": {"rect": Rect2i(689, 115, 14, 29), "cells": Vector2i(1, 1), "place": "floor"},
	"chair_front_b": {"rect": Rect2i(769, 114, 14, 30), "cells": Vector2i(1, 1), "place": "floor"},
	"chair_back": {"rect": Rect2i(864, 66, 15, 30), "cells": Vector2i(1, 1), "place": "floor"},
	"chair_back_b": {"rect": Rect2i(880, 66, 15, 27), "cells": Vector2i(1, 1), "place": "floor"},
	"chair_side": {"rect": Rect2i(721, 114, 13, 27), "cells": Vector2i(1, 1), "place": "floor"},
	"stool": {"rect": Rect2i(913, 125, 14, 16), "cells": Vector2i(1, 1), "place": "floor"},
	"tub": {"rect": Rect2i(869, 164, 38, 23), "cells": Vector2i(3, 1), "place": "wall", "fixed": true},
	"mirror_stand": {"rect": Rect2i(5, 16, 22, 40), "cells": Vector2i(1, 1), "place": "wall"},
	# decoration, floor
	"plant_big": {"rect": Rect2i(112, 7, 14, 24), "cells": Vector2i(1, 1), "place": "floor", "deco": true},
	"plant_tall": {"rect": Rect2i(98, 9, 12, 22), "cells": Vector2i(1, 1), "place": "floor", "deco": true},
	"plant_leafy": {"rect": Rect2i(49, 11, 14, 20), "cells": Vector2i(1, 1), "place": "floor", "deco": true},
	"floor_lamp": {"rect": Rect2i(8, 332, 16, 35), "cells": Vector2i(1, 1), "place": "floor", "deco": true, "lamp": Vector2i(8, 6)},
	"floor_lamp_b": {"rect": Rect2i(11, 379, 10, 36), "cells": Vector2i(1, 1), "place": "floor", "deco": true, "lamp": Vector2i(5, 5)},
	"floor_lamp_c": {"rect": Rect2i(51, 480, 10, 36), "cells": Vector2i(1, 1), "place": "floor", "deco": true, "lamp": Vector2i(5, 5)},
	"basket": {"rect": Rect2i(275, 57, 11, 14), "cells": Vector2i(1, 1), "place": "floor", "deco": true},
	"basket_b": {"rect": Rect2i(291, 57, 11, 14), "cells": Vector2i(1, 1), "place": "floor", "deco": true},
	# decoration, on tables and cabinets
	"cup": {"rect": Rect2i(48, 114, 7, 7), "place": "top", "deco": true, "steam": true},
	"cup_b": {"rect": Rect2i(72, 110, 7, 7), "place": "top", "deco": true, "steam": true},
	"teapot": {"rect": Rect2i(100, 112, 9, 10), "place": "top", "deco": true, "steam": true},
	"bowl": {"rect": Rect2i(100, 96, 8, 7), "place": "top", "deco": true},
	"fruit": {"rect": Rect2i(258, 3, 11, 12), "place": "top", "deco": true},
	"vase": {"rect": Rect2i(149, 0, 7, 15), "place": "top", "deco": true},
	"vase_b": {"rect": Rect2i(181, 0, 7, 15), "place": "top", "deco": true},
	"vase_c": {"rect": Rect2i(213, 1, 7, 14), "place": "top", "deco": true},
	"potted": {"rect": Rect2i(35, 18, 10, 13), "place": "top", "deco": true},
	"potted_b": {"rect": Rect2i(83, 17, 10, 14), "place": "top", "deco": true},
	"books": {"rect": Rect2i(1, 71, 14, 15), "place": "top", "deco": true},
	"books_b": {"rect": Rect2i(33, 64, 14, 15), "place": "top", "deco": true},
	"bottles": {"rect": Rect2i(275, 21, 7, 10), "place": "top", "deco": true},
	"lamp": {"rect": Rect2i(1, 428, 14, 19), "place": "top", "deco": true, "lamp": Vector2i(7, 5)},
	"lamp_b": {"rect": Rect2i(33, 428, 14, 19), "place": "top", "deco": true, "lamp": Vector2i(7, 5)},
	"lamp_c": {"rect": Rect2i(89, 428, 14, 19), "place": "top", "deco": true, "lamp": Vector2i(7, 5)},
	# decoration, on the wall face
	"window": {"rect": Rect2i(401, 0, 31, 44), "place": "face", "deco": true, "window": true},
	"window_b": {"rect": Rect2i(433, 0, 31, 44), "place": "face", "deco": true, "window": true},
	"window_c": {"rect": Rect2i(529, 0, 31, 44), "place": "face", "deco": true, "window": true},
	"window_d": {"rect": Rect2i(400, 177, 31, 44), "place": "face", "deco": true, "window": true},
	"window_e": {"rect": Rect2i(432, 321, 31, 44), "place": "face", "deco": true, "window": true},
	"window_f": {"rect": Rect2i(400, 369, 31, 44), "place": "face", "deco": true, "window": true},
	"window_panes": {"rect": Rect2i(403, 275, 25, 35), "place": "face", "deco": true, "window": true},
	"window_panes_b": {"rect": Rect2i(467, 275, 25, 35), "place": "face", "deco": true, "window": true},
	"window_arch": {"rect": Rect2i(403, 49, 26, 39), "place": "face", "deco": true, "window": true},
	"window_arch_vine": {"rect": Rect2i(401, 97, 30, 39), "place": "face", "deco": true, "window": true},
	"window_plain": {"rect": Rect2i(400, 225, 31, 39), "place": "face", "deco": true, "window": true},
	"painting": {"rect": Rect2i(145, 180, 14, 21), "place": "face", "deco": true},
	"painting_b": {"rect": Rect2i(161, 212, 14, 21), "place": "face", "deco": true},
	"painting_c": {"rect": Rect2i(1, 228, 14, 18), "place": "face", "deco": true},
	"painting_d": {"rect": Rect2i(49, 260, 14, 18), "place": "face", "deco": true},
	"painting_e": {"rect": Rect2i(97, 276, 14, 18), "place": "face", "deco": true},
	"painting_small": {"rect": Rect2i(2, 197, 12, 15), "place": "face", "deco": true},
	"triptych": {"rect": Rect2i(96, 211, 48, 23), "place": "face", "deco": true},
	"mirror": {"rect": Rect2i(935, 67, 18, 20), "place": "face", "furniture": true},
	"wall_shelf": {"rect": Rect2i(914, 4, 28, 8), "place": "face", "furniture": true},
	"herbs": {"rect": Rect2i(4, 102, 23, 19), "place": "face", "deco": true},
	"vine": {"rect": Rect2i(272, 87, 26, 41), "place": "face", "deco": true},
	"vine_b": {"rect": Rect2i(305, 135, 29, 39), "place": "face", "deco": true},
	"vine_flower": {"rect": Rect2i(272, 183, 26, 41), "place": "face", "deco": true},
	"hanging_plant": {"rect": Rect2i(131, 73, 10, 23), "place": "face", "deco": true},
}
## Wall items whose art is on the decoration sheet (plants, lamps) have
## "deco"; face items from the furniture sheet have "furniture".

## Rugs by size class (decoration sheet rects).
const RUGS := {
	"large": [Rect2i(7, 534, 67, 42), Rect2i(183, 534, 67, 42), Rect2i(7, 582, 67, 42), Rect2i(7, 630, 67, 42), Rect2i(7, 678, 67, 42)],
	"square": [Rect2i(290, 226, 42, 44), Rect2i(338, 226, 42, 44), Rect2i(242, 322, 42, 44), Rect2i(163, 370, 42, 44), Rect2i(210, 370, 42, 44), Rect2i(178, 450, 42, 44), Rect2i(226, 450, 42, 44)],
	"wide": [Rect2i(291, 275, 42, 25), Rect2i(339, 275, 42, 25), Rect2i(291, 307, 42, 25), Rect2i(323, 355, 42, 25), Rect2i(179, 419, 42, 25), Rect2i(227, 419, 42, 25), Rect2i(179, 499, 42, 25), Rect2i(227, 499, 42, 25)],
	"tall": [Rect2i(260, 275, 25, 42), Rect2i(340, 307, 25, 42), Rect2i(372, 307, 25, 42), Rect2i(292, 339, 25, 42), Rect2i(260, 371, 25, 42), Rect2i(148, 419, 25, 42), Rect2i(276, 419, 25, 42), Rect2i(148, 467, 25, 42)],
	"medium": [Rect2i(84, 528, 39, 23), Rect2i(133, 528, 39, 23), Rect2i(84, 560, 39, 23), Rect2i(133, 560, 39, 23), Rect2i(181, 624, 37, 28), Rect2i(229, 624, 37, 28), Rect2i(277, 624, 37, 28), Rect2i(181, 656, 37, 28)],
	"checker": [Rect2i(193, 209, 25, 35), Rect2i(225, 209, 25, 35), Rect2i(193, 257, 25, 35), Rect2i(225, 257, 25, 35), Rect2i(149, 305, 35, 25), Rect2i(197, 305, 35, 25), Rect2i(149, 337, 35, 25), Rect2i(197, 337, 35, 25)],
	"mat": [Rect2i(339, 385, 26, 15), Rect2i(339, 401, 26, 15), Rect2i(339, 417, 26, 15), Rect2i(339, 433, 26, 15), Rect2i(339, 449, 26, 15), Rect2i(339, 465, 26, 15)],
}

## Kitchen counter modules (furniture sheet, brown tone), in two tops. Each
## is [x, width]; the strip's rows are y 72-106.
const COUNTER_Y := 72
const COUNTER_H := 34
const COUNTERS := {
	"wood": {"parts": [[480, 16], [496, 16], [512, 32], [544, 32], [576, 16], [592, 32], [624, 16]], "sink": [800, 32]},
	"marble": {"parts": [[640, 32], [672, 16], [688, 16], [704, 32], [736, 16], [752, 16], [768, 32]], "sink": [832, 16]},
}


## The sprite rect for `name` in wood tone `wood` (0-4); fixed art ignores it.
static func rect_of(name: String, wood: int) -> Rect2i:
	var a: Dictionary = ART[name]
	var r: Rect2i = a.rect
	if not a.has("deco") and not a.get("fixed", false):
		r.position.y += wood * WOOD_STEP
	return r


static func sheet_of(name: String) -> Texture2D:
	var a: Dictionary = ART[name]
	return DECORATION if a.has("deco") else FURNITURE


## The frame (3x3 + nubs) for trim group `trim`, black-filled or not.
static func frame(trim: int, black: bool) -> Vector2i:
	return FRAME[trim] + Vector2i(0, BLACK_ROWS if black else 0)
