class_name PCTerrain
extends RefCounted
## Pixel Crawler maps (Anokolisa's Pixel Crawler packs: Fairy Forest, the Farm
## forest, Cemetery, Desert), built the way the Painted Lands and Green Caves
## generators build theirs: a recipe per id, a layout, the sheets' own
## systems, set pieces, scatter, a liveliness floor, and a walk check. Output
## is a corner-terrain grid, stamps, water, and prop placements;
## pixelcrawler.gd paints them. Sheets in assets/pack/pixel_crawler/<pack>/.
##
## The sheets' systems (cells of 16 px):
##   ground    per biome, pairs of terrains drawn as a 3 x 3 blob beside (or
##             under) its 3 x 3 hole ring: corners, edges, fill, and inner
##             corners. Read into corner tables (PCTiles.WANG): each cell takes
##             the tile of the terrains at its four corners. Terrains nest on
##             a parent; a cell mixing terrains no tile draws is repaired by
##             returning its lowest-priority terrain to that terrain's parent.
##   plateaus  one stamp per biome (a raised top over a root, rock, or earth
##             face), widened by repeating its middle columns and deepened by
##             repeating a top row and a face row. Impassable relief.
##   water     the sheets draw water only round island stamps, so ponds and
##             streams are drawn per pixel from the sheet's water and shore
##             colors (pixelcrawler.gd); the island stamps sit in lakes.
##   props     trees, bushes, rocks, flowers, mushrooms, runestones, cacti,
##             bones, graves (rects in PROPS).

const W := 64
const H := 40
const TILE := 16

# Cell kinds.
const OPEN := 0
const WATER := 1
const CLIFF := 2 # plateau (blocks)

# Biomes: sheet folder, ground terrains (root first; each other terrain: its
# parent and repair priority), the path terrain, the patch terrain, the zone
# terrain and the one nested in patches, and the plateau stamp.
const BIOMES := {
	"fairy": {"dir": "fairy_forest", "tiles": "fairy_forest/Tiles.png", "root": "g",
		"kids": {"d": ["g", 1], "e": ["g", 3], "k": ["e", 2]},
		"path": "e", "patch": "e", "zone": "d", "inner": "k",
		"stamp": {"at": Vector2i(0, 0), "cols": [0, 1, 2, 3, 4, 5], "rows": [0, 1, 2, 3, 4, 5, 6, 7], "mid": [2, 3], "top": 2, "face": 5},
		"stamp_b": {"at": Vector2i(6, 0), "cols": [0, 1, 2, 3, 4, 5], "rows": [0, 1, 2, 3, 4, 5, 6, 7], "mid": [2, 3], "top": 2, "face": 5},
		"water": {"deep": Color8(20, 149, 198), "shore": [Color8(27, 123, 163), Color8(19, 99, 110)], "bank": Color8(7, 45, 38)},
		"island": Rect2i(7, 12, 5, 5)},
	"green": {"dir": "farm", "tiles": "farm/Tiles.png", "root": "g",
		"kids": {"d": ["g", 1], "e": ["g", 3]},
		"path": "e", "patch": "e", "zone": "d", "inner": "",
		"stamp": {"at": Vector2i(0, 0), "cols": [0, 1, 2, 3, 4, 5], "rows": [0, 1, 2, 3, 4, 5, 6], "mid": [2, 3], "top": 2, "face": 5},
		"water": {"deep": Color8(20, 91, 188), "shore": [Color8(38, 114, 220), Color8(65, 145, 255)], "bank": Color8(101, 69, 23)},
		"island": Rect2i(12, 8, 6, 5)},
	"cemetery": {"dir": "cemetery", "tiles": "cemetery/Tiles.png", "root": "e",
		"kids": {"k": ["e", 1], "c": ["e", 3]},
		"path": "c", "patch": "k", "zone": "k", "inner": "",
		"stamp": {"at": Vector2i(0, 0), "cols": [0, 1, 2, 3, 4], "rows": [0, 1, 2, 3, 4, 5, 6], "mid": [2], "top": 2, "face": 5}},
	"desert": {"dir": "desert", "tiles": "desert/Tiles.png", "root": "s",
		"kids": {"k": ["s", 1]},
		"path": "", "patch": "k", "zone": "k", "inner": "",
		"stamp": {"at": Vector2i(0, 0), "cols": [0, 1, 2, 3, 4, 5], "rows": [0, 1, 2, 3, 4, 5, 6], "mid": [2, 3], "top": 2, "face": 5}},
	# Dungeons (maze-pixelcrawler only, pc_maze.gd): one floor terrain, no
	# plateaus or per-pixel water; walls, lava, and slime are the sheets' own
	# tiles (PCMaze kits). indoor: no clouds, streaks, grass, or drifters.
	"forge": {"dir": "forge", "tiles": "forge/Tiles.png", "root": "f", "kids": {}, "path": "", "patch": "f", "zone": "f", "inner": "", "indoor": true},
	"sewer": {"dir": "sewer", "tiles": "sewer/Tiles.png", "root": "b", "kids": {}, "path": "", "patch": "b", "zone": "b", "inner": "", "indoor": true},
}

# Props: sheet (under the pack folder), rect in px, block (collider w, h at
# the foot; zero walks through), tag, and optionally on: the only terrain it
# stands on (desert props bake light sand at their base). The foot is the
# rect's bottom middle.
const PROPS := {
	# Fairy Forest (fairy_forest/Props.png, Tree.png).
	"ff_bush_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(1, 0, 63, 48), "block": Vector2(40, 8), "tag": "bush"},
	"ff_bush_big_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(1, 96, 63, 48), "block": Vector2(40, 8), "tag": "bush"},
	"ff_bush_rust": {"sheet": "fairy_forest/Props", "rect": Rect2i(1, 48, 63, 48), "block": Vector2(40, 8), "tag": "bush"},
	"ff_bush": {"sheet": "fairy_forest/Props", "rect": Rect2i(65, 16, 47, 32), "block": Vector2(30, 6), "tag": "bush"},
	"ff_bush_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(65, 112, 47, 32), "block": Vector2(30, 6), "tag": "bush"},
	"ff_bush_rust_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(117, 66, 40, 29), "block": Vector2(24, 6), "tag": "bush"},
	"ff_shrub": {"sheet": "fairy_forest/Props", "rect": Rect2i(117, 18, 40, 29), "block": Vector2(24, 6), "tag": "bush"},
	"ff_shrub_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(160, 121, 31, 23), "block": Vector2.ZERO, "tag": "bush"},
	"ff_shrub_rust_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(160, 73, 30, 22), "block": Vector2.ZERO, "tag": "bush"},
	"ff_bell_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(293, 0, 38, 46), "block": Vector2(12, 5), "tag": "glow"},
	"ff_bell_big_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(293, 48, 38, 48), "block": Vector2(12, 5), "tag": "glow"},
	"ff_bell": {"sheet": "fairy_forest/Props", "rect": Rect2i(338, 16, 28, 30), "block": Vector2.ZERO, "tag": "glow"},
	"ff_bell_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(369, 20, 27, 26), "block": Vector2.ZERO, "tag": "glow"},
	"ff_bell_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(404, 22, 22, 24), "block": Vector2.ZERO, "tag": "glow"},
	"ff_bell_xs": {"sheet": "fairy_forest/Props", "rect": Rect2i(432, 28, 16, 19), "block": Vector2.ZERO, "tag": "glow"},
	"ff_vine_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(289, 97, 45, 62), "block": Vector2(10, 5), "tag": "plant"},
	"ff_vine": {"sheet": "fairy_forest/Props", "rect": Rect2i(341, 117, 22, 42), "block": Vector2.ZERO, "tag": "plant"},
	"ff_vine_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(369, 129, 24, 31), "block": Vector2.ZERO, "tag": "plant"},
	"ff_mush_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(293, 163, 18, 29), "block": Vector2.ZERO, "tag": "mushroom"},
	"ff_mush": {"sheet": "fairy_forest/Props", "rect": Rect2i(321, 165, 15, 27), "block": Vector2.ZERO, "tag": "mushroom"},
	"ff_mush_s": {"sheet": "fairy_forest/Props", "rect": Rect2i(337, 176, 13, 16), "block": Vector2.ZERO, "tag": "mushroom"},
	"ff_mush_xs": {"sheet": "fairy_forest/Props", "rect": Rect2i(355, 178, 11, 14), "block": Vector2.ZERO, "tag": "mushroom"},
	"ff_rock": {"sheet": "fairy_forest/Props", "rect": Rect2i(5, 224, 37, 32), "block": Vector2(28, 8), "tag": "stone"},
	"ff_rock_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(99, 226, 59, 44), "block": Vector2(46, 10), "tag": "stone"},
	"ff_rock_moss": {"sheet": "fairy_forest/Props", "rect": Rect2i(50, 273, 43, 46), "block": Vector2(32, 8), "tag": "stone"},
	"ff_rock_moss_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(99, 273, 59, 45), "block": Vector2(46, 10), "tag": "stone"},
	"ff_pebble": {"sheet": "fairy_forest/Props", "rect": Rect2i(33, 259, 14, 12), "block": Vector2.ZERO, "tag": "flat"},
	"ff_pebble_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(33, 307, 14, 12), "block": Vector2.ZERO, "tag": "flat"},
	"ff_rune": {"sheet": "fairy_forest/Props", "rect": Rect2i(179, 241, 28, 31), "block": Vector2(18, 6), "tag": "stone"},
	"ff_rune_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(212, 232, 42, 40), "block": Vector2(30, 8), "tag": "stone"},
	"ff_rune_glow": {"sheet": "fairy_forest/Props", "rect": Rect2i(179, 289, 28, 31), "block": Vector2(18, 6), "tag": "rune"},
	"ff_rune_glow_big": {"sheet": "fairy_forest/Props", "rect": Rect2i(212, 280, 42, 40), "block": Vector2(30, 8), "tag": "rune"},
	"ff_sprout": {"sheet": "fairy_forest/Props", "rect": Rect2i(211, 6, 11, 8), "block": Vector2.ZERO, "tag": "flat"},
	"ff_sprout_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(226, 4, 13, 11), "block": Vector2.ZERO, "tag": "flat"},
	"ff_sprout_c": {"sheet": "fairy_forest/Props", "rect": Rect2i(224, 20, 15, 11), "block": Vector2.ZERO, "tag": "flat"},
	"ff_leaf": {"sheet": "fairy_forest/Props", "rect": Rect2i(257, 5, 14, 7), "block": Vector2.ZERO, "tag": "flat"},
	"ff_fern": {"sheet": "fairy_forest/Props", "rect": Rect2i(226, 97, 11, 31), "block": Vector2.ZERO, "tag": "plant"},
	"ff_fern_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(242, 96, 11, 32), "block": Vector2.ZERO, "tag": "plant"},
	"ff_fern_c": {"sheet": "fairy_forest/Props", "rect": Rect2i(211, 101, 10, 26), "block": Vector2.ZERO, "tag": "plant"},
	"ff_flower": {"sheet": "fairy_forest/Props", "rect": Rect2i(195, 132, 11, 9), "block": Vector2.ZERO, "tag": "flower"},
	"ff_flower_b": {"sheet": "fairy_forest/Props", "rect": Rect2i(212, 132, 10, 9), "block": Vector2.ZERO, "tag": "flower"},
	"ff_flower_c": {"sheet": "fairy_forest/Props", "rect": Rect2i(226, 130, 12, 12), "block": Vector2.ZERO, "tag": "flower"},
	"ff_stump": {"sheet": "fairy_forest/Props", "rect": Rect2i(272, 1, 16, 15), "block": Vector2(10, 4), "tag": "wood"},
	"ff_stump_vine": {"sheet": "fairy_forest/Tree", "rect": Rect2i(14, 1360, 68, 96), "block": Vector2(40, 10), "tag": "wood"},
	"ff_stump_vine_s": {"sheet": "fairy_forest/Tree", "rect": Rect2i(105, 1392, 54, 64), "block": Vector2(30, 8), "tag": "wood"},
	# Farm forest (farm/Vegetation.png, Tree_04/05.png).
	"fm_tree_green": {"sheet": "farm/Tree_05", "rect": Rect2i(1, 0, 106, 160), "block": Vector2(50, 12), "tag": "tree"},
	"fm_tree_yellow": {"sheet": "farm/Tree_05", "rect": Rect2i(113, 0, 106, 160), "block": Vector2(50, 12), "tag": "tree"},
	"fm_tree_red": {"sheet": "farm/Tree_05", "rect": Rect2i(1, 160, 106, 160), "block": Vector2(50, 12), "tag": "tree"},
	"fm_tree_orange": {"sheet": "farm/Tree_05", "rect": Rect2i(113, 160, 106, 160), "block": Vector2(50, 12), "tag": "tree"},
	"fm_tree_bare": {"sheet": "farm/Tree_05", "rect": Rect2i(225, 2, 100, 158), "block": Vector2(40, 10), "tag": "bare"},
	"fm_tree_m_green": {"sheet": "farm/Tree_04", "rect": Rect2i(3, 2, 73, 126), "block": Vector2(28, 8), "tag": "tree"},
	"fm_tree_m_yellow": {"sheet": "farm/Tree_04", "rect": Rect2i(83, 2, 73, 126), "block": Vector2(28, 8), "tag": "tree"},
	"fm_tree_m_red": {"sheet": "farm/Tree_04", "rect": Rect2i(3, 130, 73, 126), "block": Vector2(28, 8), "tag": "tree"},
	"fm_tree_m_orange": {"sheet": "farm/Tree_04", "rect": Rect2i(83, 130, 73, 126), "block": Vector2(28, 8), "tag": "tree"},
	"fm_tree_s": {"sheet": "farm/Vegetation", "rect": Rect2i(2, 3, 44, 45), "block": Vector2(10, 5), "tag": "tree"},
	"fm_stump": {"sheet": "farm/Tree_05", "rect": Rect2i(23, 326, 61, 42), "block": Vector2(34, 8), "tag": "wood"},
	"fm_stump_s": {"sheet": "farm/Tree_04", "rect": Rect2i(328, 9, 28, 23), "block": Vector2(18, 5), "tag": "wood"},
	"fm_crystal": {"sheet": "farm/Vegetation", "rect": Rect2i(147, 2, 39, 46), "block": Vector2(12, 5), "tag": "crystal"},
	"fm_dead": {"sheet": "farm/Vegetation", "rect": Rect2i(99, 2, 39, 46), "block": Vector2(10, 5), "tag": "bare"},
	"fm_fern": {"sheet": "farm/Vegetation", "rect": Rect2i(64, 80, 48, 29), "block": Vector2.ZERO, "tag": "plant"},
	"fm_fern_dry": {"sheet": "farm/Vegetation", "rect": Rect2i(64, 112, 48, 29), "block": Vector2.ZERO, "tag": "plant"},
	"fm_reeds": {"sheet": "farm/Vegetation", "rect": Rect2i(112, 68, 32, 27), "block": Vector2.ZERO, "tag": "plant"},
	"fm_log": {"sheet": "farm/Vegetation", "rect": Rect2i(113, 97, 30, 14), "block": Vector2(26, 5), "tag": "wood"},
	"fm_rock_tall": {"sheet": "farm/Vegetation", "rect": Rect2i(178, 98, 28, 44), "block": Vector2(20, 6), "tag": "stone"},
	"fm_rock": {"sheet": "farm/Vegetation", "rect": Rect2i(114, 115, 28, 27), "block": Vector2(22, 6), "tag": "stone"},
	"fm_stone": {"sheet": "farm/Vegetation", "rect": Rect2i(145, 115, 14, 11), "block": Vector2.ZERO, "tag": "flat"},
	"fm_stone_b": {"sheet": "farm/Vegetation", "rect": Rect2i(160, 113, 16, 14), "block": Vector2.ZERO, "tag": "flat"},
	"fm_mush": {"sheet": "farm/Vegetation", "rect": Rect2i(129, 50, 14, 14), "block": Vector2.ZERO, "tag": "mushroom"},
	"fm_mush_b": {"sheet": "farm/Vegetation", "rect": Rect2i(147, 81, 11, 14), "block": Vector2.ZERO, "tag": "mushroom"},
	"fm_mush_c": {"sheet": "farm/Vegetation", "rect": Rect2i(163, 81, 11, 14), "block": Vector2.ZERO, "tag": "mushroom"},
	"fm_flower": {"sheet": "farm/Vegetation", "rect": Rect2i(53, 149, 7, 6), "block": Vector2.ZERO, "tag": "flower"},
	"fm_flower_b": {"sheet": "farm/Vegetation", "rect": Rect2i(53, 165, 7, 6), "block": Vector2.ZERO, "tag": "flower"},
	"fm_flower_c": {"sheet": "farm/Vegetation", "rect": Rect2i(53, 181, 7, 6), "block": Vector2.ZERO, "tag": "flower"},
	"fm_flower_d": {"sheet": "farm/Vegetation", "rect": Rect2i(100, 149, 8, 7), "block": Vector2.ZERO, "tag": "flower"},
	"fm_flower_e": {"sheet": "farm/Vegetation", "rect": Rect2i(100, 181, 8, 7), "block": Vector2.ZERO, "tag": "flower"},
	"fm_sprout": {"sheet": "farm/Vegetation", "rect": Rect2i(66, 68, 13, 9), "block": Vector2.ZERO, "tag": "flat"},
	"fm_sprout_b": {"sheet": "farm/Vegetation", "rect": Rect2i(35, 69, 10, 8), "block": Vector2.ZERO, "tag": "flat"},
	"gw_bush": {"sheet": "green_woods/Props", "rect": Rect2i(0, 32, 48, 28), "block": Vector2(30, 6), "tag": "bush"},
	"gw_bush_b": {"sheet": "green_woods/Props", "rect": Rect2i(0, 64, 48, 28), "block": Vector2(30, 6), "tag": "bush"},
	"gw_rock": {"sheet": "green_woods/Props", "rect": Rect2i(82, 2, 28, 28), "block": Vector2(22, 6), "tag": "stone"},
	"gw_rock_tall": {"sheet": "green_woods/Props", "rect": Rect2i(82, 34, 28, 44), "block": Vector2(20, 6), "tag": "stone"},
	"gw_crate": {"sheet": "green_woods/Props", "rect": Rect2i(112, 9, 32, 23), "block": Vector2(28, 6), "tag": "clutter"},
	"gw_barrels": {"sheet": "green_woods/Props", "rect": Rect2i(112, 41, 32, 23), "block": Vector2(28, 6), "tag": "clutter"},
	# Cemetery (cemetery/Trees.png, Tiles.png).
	"cm_pine_big": {"sheet": "cemetery/Trees", "rect": Rect2i(1, 2, 95, 206), "block": Vector2(32, 10), "tag": "tree"},
	"cm_pine": {"sheet": "cemetery/Trees", "rect": Rect2i(226, 114, 43, 102), "block": Vector2(12, 6), "tag": "tree"},
	"cm_dead_big": {"sheet": "cemetery/Trees", "rect": Rect2i(96, 0, 80, 208), "block": Vector2(32, 10), "tag": "bare"},
	"cm_dead": {"sheet": "cemetery/Trees", "rect": Rect2i(176, 9, 48, 151), "block": Vector2(12, 6), "tag": "bare"},
	"cm_dead_s": {"sheet": "cemetery/Trees", "rect": Rect2i(225, 9, 30, 103), "block": Vector2(10, 5), "tag": "bare"},
	"cm_birch_bare": {"sheet": "cemetery/Trees", "rect": Rect2i(1, 208, 47, 160), "block": Vector2(10, 5), "tag": "bare"},
	"cm_birch_bare_s": {"sheet": "cemetery/Trees", "rect": Rect2i(48, 209, 32, 126), "block": Vector2(8, 5), "tag": "bare"},
	"cm_birch": {"sheet": "cemetery/Trees", "rect": Rect2i(113, 216, 95, 168), "block": Vector2(18, 6), "tag": "tree"},
	"cm_twigs": {"sheet": "cemetery/Trees", "rect": Rect2i(52, 336, 35, 31), "block": Vector2.ZERO, "tag": "plant"},
	"cm_boulder": {"sheet": "cemetery/Tiles", "rect": Rect2i(162, 96, 61, 64), "block": Vector2(44, 10), "tag": "stone"},
	"cm_rock": {"sheet": "cemetery/Tiles", "rect": Rect2i(129, 130, 31, 28), "block": Vector2(22, 6), "tag": "stone"},
	"cm_rock_s": {"sheet": "cemetery/Tiles", "rect": Rect2i(128, 97, 31, 14), "block": Vector2(18, 4), "tag": "stone"},
	"cm_pebble": {"sheet": "cemetery/Tiles", "rect": Rect2i(98, 100, 12, 9), "block": Vector2.ZERO, "tag": "flat"},
	"cm_thorn": {"sheet": "cemetery/Tiles", "rect": Rect2i(83, 115, 9, 12), "block": Vector2.ZERO, "tag": "plant"},
	"cm_thorn_b": {"sheet": "cemetery/Tiles", "rect": Rect2i(99, 116, 9, 27), "block": Vector2.ZERO, "tag": "plant"},
	"cm_daisies": {"sheet": "cemetery/Tiles", "rect": Rect2i(112, 113, 16, 16), "block": Vector2.ZERO, "tag": "flower"},
	"cm_marigolds": {"sheet": "cemetery/Tiles", "rect": Rect2i(128, 113, 16, 16), "block": Vector2.ZERO, "tag": "flower"},
	"cm_leaves": {"sheet": "cemetery/Tiles", "rect": Rect2i(146, 116, 13, 10), "block": Vector2.ZERO, "tag": "flat"},
	"cm_grave": {"sheet": "cemetery/Tiles", "rect": Rect2i(336, 64, 16, 32), "block": Vector2(12, 5), "tag": "grave"},
	"cm_grave_b": {"sheet": "cemetery/Tiles", "rect": Rect2i(352, 64, 16, 32), "block": Vector2(12, 5), "tag": "grave"},
	"cm_grave_slab": {"sheet": "cemetery/Tiles", "rect": Rect2i(368, 64, 16, 32), "block": Vector2(12, 5), "tag": "grave"},
	"cm_grave_cross": {"sheet": "cemetery/Tiles", "rect": Rect2i(384, 64, 16, 32), "block": Vector2(10, 5), "tag": "grave"},
	# Desert (desert/Tiles.png).
	"ds_tusk": {"sheet": "desert/Tiles", "rect": Rect2i(180, 211, 53, 70), "block": Vector2(30, 8), "tag": "bone", "on": "s"},
	"ds_tusk_b": {"sheet": "desert/Tiles", "rect": Rect2i(244, 209, 39, 47), "block": Vector2(24, 6), "tag": "bone", "on": "s"},
	"ds_tusk_s": {"sheet": "desert/Tiles", "rect": Rect2i(243, 259, 26, 29), "block": Vector2(14, 5), "tag": "bone", "on": "s"},
	"ds_dead_tree": {"sheet": "desert/Tiles", "rect": Rect2i(289, 215, 62, 73), "block": Vector2(10, 5), "tag": "bare", "on": "s"},
	"ds_dead_tree_s": {"sheet": "desert/Tiles", "rect": Rect2i(354, 256, 23, 28), "block": Vector2.ZERO, "tag": "bare", "on": "s"},
	"ds_rock": {"sheet": "desert/Tiles", "rect": Rect2i(176, 295, 44, 41), "block": Vector2(36, 10), "tag": "stone", "on": "s"},
	"ds_rock_s": {"sheet": "desert/Tiles", "rect": Rect2i(226, 297, 30, 39), "block": Vector2(22, 8), "tag": "stone", "on": "s"},
	"ds_bush": {"sheet": "desert/Tiles", "rect": Rect2i(256, 292, 32, 26), "block": Vector2(22, 6), "tag": "bush", "on": "s"},
	"ds_cactus": {"sheet": "desert/Tiles", "rect": Rect2i(320, 299, 16, 51), "block": Vector2(10, 5), "tag": "cactus", "on": "s"},
	"ds_cactus_arm": {"sheet": "desert/Tiles", "rect": Rect2i(360, 299, 32, 51), "block": Vector2(12, 5), "tag": "cactus", "on": "s"},
	"ds_cactus_thin": {"sheet": "desert/Tiles", "rect": Rect2i(290, 311, 12, 40), "block": Vector2(8, 4), "tag": "cactus", "on": "s"},
	"ds_cactus_s": {"sheet": "desert/Tiles", "rect": Rect2i(336, 325, 16, 26), "block": Vector2(10, 4), "tag": "cactus", "on": "s"},
	"ds_reeds": {"sheet": "desert/Tiles", "rect": Rect2i(192, 352, 32, 48), "block": Vector2.ZERO, "tag": "plant", "on": "s"},
	"ds_tuft": {"sheet": "desert/Tiles", "rect": Rect2i(176, 336, 16, 16), "block": Vector2.ZERO, "tag": "flat", "on": "s"},
	"ds_tuft_b": {"sheet": "desert/Tiles", "rect": Rect2i(192, 336, 16, 16), "block": Vector2.ZERO, "tag": "flat", "on": "s"},
	# Forge (forge/Tiles.png).
	"fg_arch": {"sheet": "forge/Tiles", "rect": Rect2i(224, 0, 48, 77), "block": Vector2.ZERO, "tag": "flat"},
	"fg_banner": {"sheet": "forge/Tiles", "rect": Rect2i(282, 8, 22, 61), "block": Vector2.ZERO, "tag": "flat"},
	"fg_chest_open": {"sheet": "forge/Tiles", "rect": Rect2i(240, 88, 32, 24), "block": Vector2(26, 8), "tag": "clutter"},
	"fg_chest": {"sheet": "forge/Tiles", "rect": Rect2i(240, 115, 32, 29), "block": Vector2(26, 8), "tag": "clutter"},
	"fg_statue": {"sheet": "forge/Tiles", "rect": Rect2i(194, 150, 28, 58), "block": Vector2(20, 8), "tag": "stone"},
	"fg_statue_broken": {"sheet": "forge/Tiles", "rect": Rect2i(226, 164, 28, 44), "block": Vector2(20, 8), "tag": "stone"},
	"fg_barrel_skull": {"sheet": "forge/Tiles", "rect": Rect2i(112, 249, 16, 23), "block": Vector2(12, 5), "tag": "clutter"},
	"fg_barrel": {"sheet": "forge/Tiles", "rect": Rect2i(128, 249, 16, 23), "block": Vector2(12, 5), "tag": "clutter"},
	"fg_barrel_b": {"sheet": "forge/Tiles", "rect": Rect2i(144, 249, 16, 23), "block": Vector2(12, 5), "tag": "clutter"},
	"fg_rack": {"sheet": "forge/Tiles", "rect": Rect2i(160, 249, 48, 23), "block": Vector2(44, 6), "tag": "clutter"},
	"fg_barrel_water": {"sheet": "forge/Tiles", "rect": Rect2i(112, 282, 16, 22), "block": Vector2(12, 5), "tag": "clutter"},
	"fg_rack_b": {"sheet": "forge/Tiles", "rect": Rect2i(160, 282, 48, 22), "block": Vector2(44, 6), "tag": "clutter"},
	"fg_rubble": {"sheet": "forge/Tiles", "rect": Rect2i(83, 99, 9, 11), "block": Vector2.ZERO, "tag": "flat"},
	"fg_rubble_b": {"sheet": "forge/Tiles", "rect": Rect2i(116, 115, 10, 8), "block": Vector2.ZERO, "tag": "flat"},
	# Sewer (sewer/Props.png).
	"sw_lamp": {"sheet": "sewer/Props", "rect": Rect2i(100, 5, 9, 20), "block": Vector2.ZERO, "tag": "lamp"},
	"sw_lantern": {"sheet": "sewer/Props", "rect": Rect2i(5, 10, 6, 15), "block": Vector2.ZERO, "tag": "lamp"},
	"sw_crate": {"sheet": "sewer/Props", "rect": Rect2i(32, 9, 16, 23), "block": Vector2(14, 6), "tag": "clutter"},
	"sw_barrel": {"sheet": "sewer/Props", "rect": Rect2i(48, 10, 16, 22), "block": Vector2(14, 6), "tag": "clutter"},
	"sw_crate_broken": {"sheet": "sewer/Props", "rect": Rect2i(32, 41, 16, 23), "block": Vector2(14, 6), "tag": "clutter"},
	"sw_barrel_broken": {"sheet": "sewer/Props", "rect": Rect2i(48, 44, 16, 20), "block": Vector2(14, 6), "tag": "clutter"},
	"sw_chest": {"sheet": "sewer/Props", "rect": Rect2i(130, 42, 28, 40), "block": Vector2(24, 8), "tag": "clutter"},
	"sw_outlet": {"sheet": "sewer/Props", "rect": Rect2i(112, 40, 16, 16), "block": Vector2.ZERO, "tag": "flat"},
	"sw_chain": {"sheet": "sewer/Props", "rect": Rect2i(163, 1, 10, 40), "block": Vector2.ZERO, "tag": "flat"},
	"sw_bottle": {"sheet": "sewer/Props", "rect": Rect2i(98, 145, 12, 15), "block": Vector2.ZERO, "tag": "flat"},
	"sw_bottle_b": {"sheet": "sewer/Props", "rect": Rect2i(114, 165, 10, 11), "block": Vector2.ZERO, "tag": "flat"},
	"sw_bottle_c": {"sheet": "sewer/Props", "rect": Rect2i(132, 181, 7, 11), "block": Vector2.ZERO, "tag": "flat"},
	"sw_planks": {"sheet": "sewer/Props", "rect": Rect2i(97, 194, 77, 29), "block": Vector2.ZERO, "tag": "flat"}, # across a channel, east-west
	"sw_planks_v": {"sheet": "sewer/Props", "rect": Rect2i(67, 144, 26, 96), "block": Vector2.ZERO, "tag": "flat"}, # north-south
}

# Fairy Forest trees (fairy_forest/Tree.png): six color rows of 224 px, left
# half green (rows 0-2) and purple (3-5), right half (+624) olive and teal;
# in each row six sizes.
const FF_TREE_SIZES := [[2, 9, 186, 215], [198, 30, 133, 194], [336, 78, 111, 146], [471, 134, 50, 90], [531, 165, 40, 59]]
const FF_TREE_COLORS := {"green": [0, 0], "green_b": [1, 0], "green_c": [2, 0], "purple": [3, 0], "purple_b": [4, 0], "purple_c": [5, 0],
	"olive": [0, 1], "olive_b": [1, 1], "olive_c": [2, 1], "teal": [3, 1], "teal_b": [4, 1], "teal_c": [5, 1]}


static func ff_tree(color: String, size: int) -> Dictionary:
	var cr: Array = FF_TREE_COLORS[color]
	var s: Array = FF_TREE_SIZES[size]
	# Root flares measured from the sprites (the painter sizes the collider
	# from the sprite too; these reserve the cells).
	var blocks := [Vector2(44, 12), Vector2(34, 10), Vector2(30, 9), Vector2(20, 6), Vector2(12, 5)]
	return {"sheet": "fairy_forest/Tree", "rect": Rect2i(s[0] + cr[1] * 624, cr[0] * 224 + s[1], s[2], s[3]), "block": blocks[size], "tag": "tree"}


## Every prop, Fairy Forest trees included (keys "ff_tree:<color>:<size>").
static func prop(key: String) -> Dictionary:
	if key.begins_with("ff_tree:"):
		var p := key.split(":")
		return ff_tree(p[1], int(p[2]))
	return PROPS[key]


# Recipes: biome; zones (share of the zone terrain); patches (clearings of the
# patch terrain, count); trees [set, count]; water: none / pond / lake /
# stream; plateaus [min, max]; path layout; piece; scatter sets; grade (Farm
# greens toned down).
const RECIPES := [
	{"name": "Fairy glade", "biome": "fairy", "zones": 0.3, "patches": [3, 5], "trees": ["ff_mixed", 26], "water": "pond", "plateaus": [0, 1], "path": "trail", "piece": "glade"},
	{"name": "Runestone circle", "biome": "fairy", "zones": 0.34, "patches": [2, 3], "trees": ["ff_teal", 24], "water": "none", "plateaus": [0, 1], "path": "trail", "piece": "runes"},
	{"name": "Glowbell hollow", "biome": "fairy", "zones": 0.4, "patches": [2, 4], "trees": ["ff_purple", 28], "water": "pond", "plateaus": [0, 0], "path": "trail", "piece": "bells"},
	{"name": "Twilight stream", "biome": "fairy", "zones": 0.3, "patches": [3, 4], "trees": ["ff_mixed", 24], "water": "stream", "plateaus": [0, 1], "path": "cross", "piece": "glade"},
	{"name": "Root ledges", "biome": "fairy", "zones": 0.3, "patches": [2, 4], "trees": ["ff_green", 22], "water": "none", "plateaus": [2, 3], "path": "trail", "piece": "rocks"},
	{"name": "Deep fairy wood", "biome": "fairy", "zones": 0.46, "patches": [1, 2], "trees": ["ff_mixed", 40], "water": "pond", "plateaus": [0, 1], "path": "trail", "piece": "mushrooms"},
	{"name": "Greenwood", "biome": "green", "zones": 0.34, "patches": [3, 5], "trees": ["fm_summer", 22], "water": "pond", "plateaus": [0, 1], "path": "cross", "piece": "glade"},
	{"name": "Forest trail", "biome": "green", "zones": 0.36, "patches": [2, 4], "trees": ["fm_summer", 28], "water": "none", "plateaus": [0, 2], "path": "road", "piece": "camp"},
	{"name": "Island lake", "biome": "green", "zones": 0.3, "patches": [2, 3], "trees": ["fm_summer", 18], "water": "lake", "plateaus": [0, 0], "path": "trail", "piece": "shore"},
	{"name": "Autumn grove", "biome": "green", "zones": 0.36, "patches": [3, 5], "trees": ["fm_autumn", 24], "water": "pond", "plateaus": [0, 1], "path": "trail", "piece": "glade"},
	{"name": "Crystal thicket", "biome": "green", "zones": 0.4, "patches": [2, 3], "trees": ["fm_summer", 26], "water": "none", "plateaus": [1, 2], "path": "trail", "piece": "crystals"},
	{"name": "Old cemetery", "biome": "cemetery", "zones": 0.28, "patches": [3, 5], "trees": ["cm_mixed", 16], "water": "none", "plateaus": [0, 1], "path": "cross", "piece": "graves"},
	{"name": "Dead wood", "biome": "cemetery", "zones": 0.34, "patches": [2, 4], "trees": ["cm_dead", 24], "water": "none", "plateaus": [0, 2], "path": "trail", "piece": "rocks"},
	{"name": "Red pine hill", "biome": "cemetery", "zones": 0.3, "patches": [2, 3], "trees": ["cm_pines", 20], "water": "none", "plateaus": [1, 2], "path": "trail", "piece": "graves"},
	{"name": "Dune sea", "biome": "desert", "zones": 0.24, "patches": [3, 5], "trees": ["ds_cacti", 18], "water": "none", "plateaus": [0, 1], "path": "none", "piece": "cacti"},
	{"name": "Bone field", "biome": "desert", "zones": 0.3, "patches": [3, 5], "trees": ["ds_dead", 10], "water": "none", "plateaus": [0, 1], "path": "none", "piece": "bones"},
	{"name": "Mesa", "biome": "desert", "zones": 0.26, "patches": [2, 4], "trees": ["ds_cacti", 12], "water": "none", "plateaus": [2, 3], "path": "none", "piece": "rocks"},
]

const TREE_SETS := {
	"ff_mixed": ["ff_tree:green:0", "ff_tree:green_b:1", "ff_tree:teal:1", "ff_tree:green:2", "ff_tree:purple:1", "ff_tree:olive:2", "ff_tree:green_c:3", "ff_tree:teal_b:2", "ff_tree:green:4"],
	"ff_teal": ["ff_tree:teal:0", "ff_tree:teal_b:1", "ff_tree:teal:2", "ff_tree:green_b:1", "ff_tree:teal_c:3", "ff_tree:green:2"],
	"ff_purple": ["ff_tree:purple:0", "ff_tree:purple_b:1", "ff_tree:purple:2", "ff_tree:green:1", "ff_tree:purple_c:3", "ff_tree:teal:2"],
	"ff_green": ["ff_tree:green:0", "ff_tree:green_b:1", "ff_tree:green:2", "ff_tree:olive:1", "ff_tree:green_c:3", "ff_tree:olive_b:2"],
	"fm_summer": ["fm_tree_green", "fm_tree_m_green", "fm_tree_yellow", "fm_tree_m_yellow", "fm_tree_green", "fm_tree_s"],
	"fm_autumn": ["fm_tree_red", "fm_tree_orange", "fm_tree_m_red", "fm_tree_m_orange", "fm_tree_yellow", "fm_tree_bare"],
	"cm_mixed": ["cm_pine_big", "cm_pine", "cm_dead", "cm_birch", "cm_birch_bare", "cm_dead_s"],
	"cm_dead": ["cm_dead_big", "cm_dead", "cm_dead_s", "cm_birch_bare", "cm_birch_bare_s", "cm_birch"],
	"cm_pines": ["cm_pine_big", "cm_pine", "cm_pine", "cm_birch", "cm_dead"],
	"ds_cacti": ["ds_cactus", "ds_cactus_arm", "ds_cactus_thin", "ds_cactus_s", "ds_bush"],
	"ds_dead": ["ds_dead_tree", "ds_dead_tree_s", "ds_bush", "ds_cactus_arm"],
}
# Undergrowth and small scatter by biome: [bushes and rocks, small ground bits].
const SCATTER := {
	"fairy": [["ff_bush", "ff_bush_b", "ff_shrub", "ff_shrub_s", "ff_bush_rust_s", "ff_shrub_rust_s", "ff_rock", "ff_rock_moss", "ff_stump", "ff_vine", "ff_vine_s", "ff_bush_big"],
		["ff_sprout", "ff_sprout_b", "ff_sprout_c", "ff_leaf", "ff_pebble", "ff_pebble_b", "ff_fern", "ff_fern_b", "ff_fern_c", "ff_mush_s", "ff_mush_xs", "ff_flower", "ff_flower_b", "ff_flower_c"]],
	"green": [["gw_bush", "gw_bush_b", "fm_fern", "fm_fern", "fm_rock", "fm_stump_s", "fm_log", "gw_rock", "fm_tree_s"],
		["fm_sprout", "fm_sprout_b", "fm_stone", "fm_stone_b", "fm_mush", "fm_mush_b", "fm_flower", "fm_flower_b", "fm_flower_c", "fm_flower_d", "fm_flower_e"]],
	"cemetery": [["cm_rock", "cm_rock_s", "cm_twigs", "cm_thorn_b", "cm_rock"],
		["cm_pebble", "cm_thorn", "cm_leaves", "cm_daisies", "cm_marigolds", "cm_leaves"]],
	"desert": [["ds_rock", "ds_rock_s", "ds_bush", "ds_cactus_s", "ds_dead_tree_s"],
		["ds_tuft", "ds_tuft_b", "ds_tuft"]],
	"forge": [["fg_barrel", "fg_barrel_b", "fg_barrel_skull", "fg_barrel_water", "fg_rack"],
		["fg_rubble", "fg_rubble_b", "fg_rubble"]],
	"sewer": [["sw_crate", "sw_barrel", "sw_crate_broken", "sw_barrel_broken"],
		["sw_bottle", "sw_bottle_b", "sw_bottle_c", "sw_outlet"]],
}

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var biome: Dictionary
var attempt := 0
var corner := PackedStringArray() # (W + 1) * (H + 1) terrain letters
var kind := PackedByteArray()
var plateaus: Array[Dictionary] = [] # {rect, pieces: [{cell, atlas}]}
var water := {} # cell -> true
var islands: Array[Vector2i] = [] # island stamp top-left cells
var ponds: Array[Rect2i] = []
var paths := {} # cell -> true
var props: Array[Dictionary] = [] # {art, cell}
var blocked := {}
var goals: Array[Vector2i] = []
var spawn := Vector2i.ZERO
var notes: Array[String] = []
var fails: Array[String] = []
var floor_notes: Array[String] = []
var firefly_spots: Array[Vector2i] = [] # liveliness anchors drawn by fireflies
var _locked := {} # corners that must stay root (plateau feet, water banks)
var splat: Array[PackedFloat32Array] = [] # per layer (sunlit, dry, tufts, shade), per corner weight
var splat_fade := PackedFloat32Array() # per corner: 1 deep in pure root ground
var splat_fade_dark := PackedFloat32Array() # the same for the zone terrain
var _taken := {}
var _rng := RandomNumberGenerator.new()
## Lays maze-pixelcrawler's mazes instead (pc_maze.gd, PCMaze.MAZE_RECIPES).
var maze := false
var maze_info := {}
var wall_tiles := {} # cell -> atlas on the biome sheet: kit walls and faces
var pool_tiles := {} # cell -> atlas (frame 0): animated lava or slime
var _maze = null


func generate(id: int, pinned := -1) -> String:
	map_id = id
	var list: Array = PCMaze.recipes() if maze else RECIPES
	recipe_id = pinned if pinned >= 0 else id % list.size()
	recipe = list[recipe_id]
	biome = BIOMES[recipe.biome]
	for a in 30:
		attempt = a
		if _layout() and _reaches_all():
			break
	return _report()


func _layout() -> bool:
	_rng.seed = map_id * 7919 + attempt * 104729
	corner = PackedStringArray()
	corner.resize((W + 1) * (H + 1))
	corner.fill(biome.root)
	kind = PackedByteArray()
	kind.resize(W * H)
	kind.fill(OPEN)
	for d in [water, paths, blocked, _locked, _taken, stones, wall_tiles, pool_tiles, maze_info, _prop_cells]:
		d.clear()
	for a in [plateaus, islands, ponds, props, goals, firefly_spots]:
		a.clear()
	notes.clear()
	fails.clear()
	floor_notes.clear()
	if maze:
		return _maze_layout()
	spawn = Vector2i(W / 2 + _rng.randi_range(-10, 10), H - 5)
	_claim(Rect2i(spawn - Vector2i(2, 2), Vector2i(5, 4)))
	for i in _rng.randi_range(recipe.plateaus[0], recipe.plateaus[1]):
		_plateau()
	match recipe.water:
		"pond":
			for i in _rng.randi_range(1, 2):
				_pond(Vector2i(_rng.randi_range(5, 9), _rng.randi_range(4, 6)), false)
		"lake":
			_pond(Vector2i(_rng.randi_range(18, 24), _rng.randi_range(11, 14)), true)
		"stream":
			_stream()
	_zones()
	_lay_paths()
	_patches()
	_repair()
	_piece()
	_scatter_trees()
	_scatter_small()
	_liveliness_floor()
	_splat()
	return true


## A maze map (maze-pixelcrawler): PCMaze lays the walls, clearings, gates,
## and extras; then the repair, the trees and scatter in the antechambers
## (outdoors), the liveliness floor, the splat. Every maze cell must be
## reachable from the entrance.
func _maze_layout() -> bool:
	_maze = PCMaze.new(self, _rng)
	if not _maze.lay():
		return false
	_repair()
	if not biome.get("indoor", false):
		_scatter_trees()
		_scatter_small()
	else:
		# A dungeon's antechambers: a little clutter, a few bits, not a carpet.
		var sets: Array = SCATTER[recipe.biome]
		_near(sets[0], 8, Vector2i(W / 2, H / 2), W / 2)
		_near(sets[1], 10, Vector2i(W / 2, H / 2), W / 2)
	_maze_floor()
	_splat()
	return _maze.unreached().is_empty()


## The floor in a maze: a glowing or moving anchor in a corridor of the weak
## window where the biome has one (PCMaze.floor_anchor), else fireflies.
func _maze_floor() -> void:
	for n in FLOOR_ANCHORS * 3:
		var weak := _weakest()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR:
			break
		var r: Rect2i = weak.rect
		if _maze.floor_anchor(r):
			floor_notes.append("anchor")
		else:
			var cells: Array = maze_info.get("corridors", {}).keys().filter(func(c): return r.grow(-4).has_point(c) and walkable(c))
			if cells.is_empty():
				break
			cells.sort()
			firefly_spots.append(cells[_rng.randi() % cells.size()])
			floor_notes.append("fireflies")
	floor_notes.append("-> %.3f%%" % _weakest().value)


## Drips from the faces of a maze's kit walls (CaveLife), in world pixels.
func drip_spots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(maze_info.get("drips", []))
	return out


# ---------------------------------------------------------------- grids

func _i(c: Vector2i) -> int:
	return c.y * W + c.x


func _ci(x: int, y: int) -> int:
	return y * (W + 1) + x


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < W and c.y < H


func corner_at(x: int, y: int) -> String:
	return corner[_ci(clampi(x, 0, W), clampi(y, 0, H))]


func _set_corner(x: int, y: int, t: String) -> void:
	if x >= 0 and y >= 0 and x <= W and y <= H and not _locked.has(Vector2i(x, y)):
		corner[_ci(x, y)] = t


## The terrain letters at a cell's TL, TR, BL, BR corners.
func sig(c: Vector2i) -> String:
	return corner_at(c.x, c.y) + corner_at(c.x + 1, c.y) + corner_at(c.x, c.y + 1) + corner_at(c.x + 1, c.y + 1)


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _free(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != OPEN:
				return false
	return true


## Root ground (grass, earth, sand) round a set of cells, following its shape:
## every corner within 1.5 corners of the cells, so no zone or patch edge
## meets the water and no straight-edged box shows round it.
func _lock_round(cells: Array[Vector2i]) -> void:
	var seen := {}
	for c in cells:
		for dy in range(-1, 3):
			for dx in range(-1, 3):
				var v := Vector2i(c.x + dx, c.y + dy)
				if seen.has(v) or v.x < 0 or v.y < 0 or v.x > W or v.y > H:
					continue
				# Distance from the corner to the cell's square, in corners.
				var d := Vector2(maxf(0.0, maxf(c.x - v.x, v.x - c.x - 1)), maxf(0.0, maxf(c.y - v.y, v.y - c.y - 1)))
				if d.length() <= 1.0:
					seen[v] = true
					corner[_ci(v.x, v.y)] = biome.root
					_locked[v] = true


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263 + map_id * 1442695041) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return float(h & 0xFFFF) / 65536.0


# ---------------------------------------------------------------- plateaus

## A plateau from the biome's stamp, widened (middle columns repeated) and
## deepened (top row and face row repeated). It stands on plain root ground.
func _plateau() -> void:
	var st: Dictionary = biome.stamp
	if biome.has("stamp_b") and _rng.randf() < 0.5:
		st = biome.stamp_b
	for t in 60:
		var cols: Array[int] = []
		var mid: Array = st.mid
		var reps := _rng.randi_range(0, 3)
		for c in st.cols:
			cols.append(c)
			if c == mid[-1]:
				for r in reps:
					for m in mid:
						cols.append(m)
		var rows: Array[int] = []
		var top_reps := _rng.randi_range(0, 2)
		var face_reps := _rng.randi_range(0, 1)
		for r in st.rows:
			rows.append(r)
			if r == st.top:
				for k in top_reps:
					rows.append(r)
			if r == st.face:
				for k in face_reps:
					rows.append(r)
		var size := Vector2i(cols.size(), rows.size())
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(2, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(r.grow(2)) or r.grow(3).has_point(spawn):
			continue
		var pieces: Array[Dictionary] = []
		for j in rows.size():
			for i in cols.size():
				var a: Vector2i = st.at + Vector2i(cols[i], rows[j])
				pieces.append({"cell": at + Vector2i(i, j), "atlas": a})
		# Everything but the foot row blocks.
		for j in rows.size() - 1:
			for i in cols.size():
				var c := at + Vector2i(i, j)
				kind[_i(c)] = CLIFF
		_claim(r.grow(1))
		# Keep the face in view: nothing tall stands just in front of it.
		_claim(Rect2i(r.position.x - 2, r.end.y, r.size.x + 4, 7))
		var foot: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				foot.append(Vector2i(x, y))
		_lock_round(foot)
		plateaus.append({"rect": r, "pieces": pieces})
		return


# ---------------------------------------------------------------- water

## A pond: a lumpy ellipse of water cells, on plain root ground. A lake may
## carry the biome's island stamp.
func _pond(size: Vector2i, lake: bool) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 31 + ponds.size() * 7 + attempt
	noise.frequency = 0.2
	for t in 80:
		var at := Vector2i(_rng.randi_range(3, W - size.x - 3), _rng.randi_range(3, H - size.y - 8))
		var r := Rect2i(at, size)
		if not _free(r.grow(2)):
			continue
		var c0 := Vector2(r.get_center())
		var cells: Array[Vector2i] = []
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var d := Vector2((x + 0.5 - c0.x) / (size.x * 0.5), (y + 0.5 - c0.y) / (size.y * 0.5))
				if d.length() + noise.get_noise_2d(x, y) * 0.3 < 0.95:
					cells.append(Vector2i(x, y))
		if cells.size() < 8:
			continue
		for c in cells:
			water[c] = true
			kind[_i(c)] = WATER
		if lake and biome.has("island"):
			var isz: Vector2i = biome.island.size
			for k in 24:
				var ip := Vector2i(r.get_center()) - isz / 2 + Vector2i(_rng.randi_range(-4, 4), _rng.randi_range(-2, 2))
				var ok := true
				for y in range(ip.y - 1, ip.y + isz.y + 1):
					for x in range(ip.x - 1, ip.x + isz.x + 1):
						if not water.has(Vector2i(x, y)):
							ok = false
				if not ok:
					continue
				islands.append(ip)
				# The island is land: grass or earth, out of reach from the shore.
				for y in range(ip.y, ip.y + isz.y):
					for x in range(ip.x, ip.x + isz.x):
						var ic := Vector2i(x, y)
						water.erase(ic)
						kind[_i(ic)] = CLIFF
				break
		_claim(r.grow(1))
		_lock_round(cells)
		ponds.append(r)
		return


## A brook two to three cells wide from the north edge to the south,
## meandering, clear of the spawn; the path crosses it on stepping stones.
var _stream_cells := {}

func _stream() -> void:
	for t in 30:
		var x := float(_rng.randi_range(12, W - 12))
		var drift := 0.0
		var cells: Array[Vector2i] = []
		var ok := true
		for y in range(0, H):
			drift = clampf(drift + _rng.randf_range(-0.3, 0.3), -0.7, 0.7)
			x = clampf(x + drift, 6, W - 7)
			var wdt := 2 if _hash(int(x), y) < 0.6 else 3
			for dx in wdt:
				cells.append(Vector2i(roundi(x) + dx, y))
		for c in cells:
			if _taken.has(c) or kind[_i(c)] != OPEN or absi(c.x - spawn.x) < 5 and c.y > H - 10:
				ok = false
		if not ok:
			continue
		for c in cells:
			water[c] = true
			kind[_i(c)] = WATER
			_stream_cells[c] = true
			_claim(Rect2i(c - Vector2i(1, 0), Vector2i(3, 1)))
		_lock_round(cells)
		notes.append("stream")
		return


# ---------------------------------------------------------------- zones

## The zone terrain (dark grass, dark earth, dark sand) where a smooth noise
## peaks, at the recipe's share; the patch terrain's inner terrain later.
func _zones() -> void:
	var z: String = biome.zone
	var noise := FastNoiseLite.new()
	noise.seed = map_id * 13 + attempt
	noise.frequency = 0.05
	noise.fractal_octaves = 2
	var vals: Array[float] = []
	for y in H + 1:
		for x in W + 1:
			vals.append(noise.get_noise_2d(x, y))
	var sorted := vals.duplicate()
	sorted.sort()
	var cut: float = sorted[int((1.0 - recipe.zones) * sorted.size())]
	for y in H + 1:
		for x in W + 1:
			if vals[_ci(x, y)] >= cut and corner[_ci(x, y)] == biome.root:
				_set_corner(x, y, z)


# ---------------------------------------------------------------- paths

func _lay_paths() -> void:
	var hub := Vector2i(W / 2, H / 2)
	for tries in 200:
		var h := Vector2i(W / 2 + _rng.randi_range(-12, 12), H / 2 + _rng.randi_range(-8, 4))
		if kind[_i(h)] == OPEN and not _taken.has(h):
			hub = h
			break
	goals.append(hub)
	var t: String = biome.path
	if t == "" or recipe.path == "none":
		return
	match recipe.path:
		"cross":
			_route(Vector2i(0, hub.y), Vector2i(W - 1, hub.y), t)
			_route(spawn, hub, t)
		"road":
			var y := _rng.randi_range(H / 2 - 4, H / 2 + 2)
			_route(Vector2i(0, y), Vector2i(W - 1, y), t)
			_route(spawn, Vector2i(spawn.x, y), t)
		_:
			_route(spawn, hub, t)


var _wander := FastNoiseLite.new()

## A* over cells (water, cliffs solid; a noise cost so it winds); the route's
## corners take the path terrain two wide, swelling here and there.
func _route(a: Vector2i, b: Vector2i, t: String) -> void:
	_wander.seed = map_id * 7 + attempt
	_wander.frequency = 0.12
	var astar := AStarGrid2D.new()
	astar.region = Rect2i(0, 0, W, H)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] == CLIFF:
				astar.set_point_solid(c, true)
			elif kind[_i(c)] == WATER:
				# Streams are crossed on stepping stones; ponds walked round.
				astar.set_point_weight_scale(c, 25.0 if _stream_cells.has(c) else 400.0)
			elif paths.has(c):
				astar.set_point_weight_scale(c, 0.5)
			else:
				astar.set_point_weight_scale(c, 1.0 + (_wander.get_noise_2d(x, y) + 1.0) * 3.5)
	a = a.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	b = b.clamp(Vector2i.ZERO, Vector2i(W - 1, H - 1))
	for c in [a, b]:
		astar.set_point_solid(c, false)
	for c in astar.get_id_path(a, b):
		if kind[_i(c)] == WATER:
			if _stream_cells.has(c):
				stones[c] = true
			continue
		paths[c] = true
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			_set_corner(c.x + o.x, c.y + o.y, t)
		if _wander.get_noise_2d(c.x * 3.0, c.y * 3.0) > 0.25:
			_set_corner(c.x + 2, c.y + 1, t)


var stones := {} # stream cells the path crosses on stepping stones


# ---------------------------------------------------------------- patches

## Clearings of the patch terrain (rounded blobs), and in the Fairy Forest
## darker earth inside some of them.
func _patches() -> void:
	var t: String = biome.patch
	var inner: String = biome.inner
	var want := _rng.randi_range(recipe.patches[0], recipe.patches[1])
	var made := 0
	for tries in want * 30:
		if made >= want:
			break
		var size := Vector2i(_rng.randi_range(3, 7), _rng.randi_range(3, 5))
		var at := Vector2i(_rng.randi_range(2, W - size.x - 2), _rng.randi_range(2, H - size.y - 2))
		var ok := true
		for y in range(at.y, at.y + size.y + 1):
			for x in range(at.x, at.x + size.x + 1):
				if _locked.has(Vector2i(x, y)):
					ok = false
		if not ok:
			continue
		var c0 := Vector2(at) + Vector2(size) * 0.5
		for y in range(at.y, at.y + size.y + 1):
			for x in range(at.x, at.x + size.x + 1):
				var d := Vector2((x - c0.x) / (size.x * 0.5), (y - c0.y) / (size.y * 0.5))
				if d.length() + (_hash(x, y) - 0.5) * 0.4 < 1.0:
					_set_corner(x, y, t)
		if inner != "" and _rng.randf() < 0.6 and size.x >= 5 and size.y >= 4:
			var ic := Vector2i(c0)
			for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0)]:
				_set_corner(ic.x + o.x, ic.y + o.y, inner)
		made += 1


## Cells mixing terrains no tile draws: the lowest-priority terrain in the cell
## returns to its parent, until every cell has a tile.
func _repair() -> void:
	var tab: Dictionary = PCTiles.WANG[recipe.biome]
	var kids: Dictionary = biome.kids
	for it in 30:
		var bad := 0
		for y in H:
			for x in W:
				var c := Vector2i(x, y)
				var s := sig(c)
				if tab.has(s):
					continue
				bad += 1
				var low := ""
				for ch in s:
					if ch != biome.root and (low == "" or kids[ch][1] < kids[low][1]):
						low = ch
				if low == "":
					continue
				var par: String = kids[low][0]
				for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
					if corner_at(x + o.x, y + o.y) == low:
						corner[_ci(x + o.x, y + o.y)] = par
		if bad == 0:
			return
	notes.append("repair left cells")


# ---------------------------------------------------------------- set pieces

func _piece() -> void:
	var hub: Vector2i = goals[-1]
	match recipe.piece:
		"runes":
			# A ring of runestones round the hub, the glowing ones facing in.
			var n := _rng.randi_range(5, 7)
			for k in n:
				var a := TAU * k / n + _rng.randf_range(-0.2, 0.2)
				var c := hub + Vector2i(roundi(cos(a) * 6.0), roundi(sin(a) * 4.0))
				_place(["ff_rune_glow", "ff_rune", "ff_rune_glow_big", "ff_rune_big"][k % 4], c)
		"bells":
			_near(["ff_bell_big", "ff_bell_big_b", "ff_bell", "ff_bell_b", "ff_bell_s", "ff_bell_xs"], 12, hub, 8)
			_near(["ff_vine_big", "ff_vine"], 3, hub, 7)
		"glade":
			if recipe.biome == "fairy":
				_near(["ff_bell", "ff_bell_s", "ff_mush_big", "ff_mush", "ff_rune_glow"], 5, hub, 6)
			else:
				_near(["fm_mush", "fm_mush_b", "fm_stump_s", "fm_log", "fm_fern"], 5, hub, 6)
		"mushrooms":
			_near(["ff_mush_big", "ff_mush", "ff_mush_s", "ff_mush_xs", "ff_stump_vine", "ff_stump_vine_s"], 12, hub, 9)
		"rocks":
			var arts: Array = SCATTER[recipe.biome][0].filter(func(a: String) -> bool: return PROPS[a].tag == "stone")
			if recipe.biome == "cemetery":
				arts.append("cm_boulder")
			_near(arts, 8, hub, 12)
		"camp":
			_near(["gw_crate", "gw_barrels", "fm_log", "fm_stump"], 4, hub, 4)
		"shore":
			for p in ponds:
				_near(["fm_reeds", "fm_reeds", "fm_rock"], 6, p.get_center(), maxi(p.size.x, p.size.y) / 2 + 2)
		"crystals":
			_near(["fm_crystal", "fm_crystal", "fm_rock_tall"], 5, hub, 7)
		"graves":
			var rows := _rng.randi_range(2, 3)
			for j in rows:
				for i in _rng.randi_range(4, 6):
					_place(["cm_grave", "cm_grave_b", "cm_grave_slab", "cm_grave_cross"][(i + j) % 4], hub + Vector2i(-6 + i * 2, -3 + j * 3))
			_near(["cm_daisies", "cm_marigolds", "cm_thorn"], 6, hub, 7)
		"cacti":
			_near(["ds_cactus", "ds_cactus_arm", "ds_cactus_thin", "ds_cactus_s"], 8, hub, 10)
		"bones":
			_near(["ds_tusk", "ds_tusk_b", "ds_tusk_s", "ds_tusk_s"], 6, hub, 10)


# ---------------------------------------------------------------- scatter

## Props stand on open cells not claimed; a blocking prop keeps every goal
## reachable or is taken back (checked once at the end, see _layout).
func _place(art: String, cell: Vector2i) -> bool:
	if not _inside(cell) or _taken.has(cell) or kind[_i(cell)] != OPEN or cell == spawn or paths.has(cell):
		return false
	var p: Dictionary = prop(art)
	# Props that bake a patch of ground at their base stand only on it.
	if p.has("on") and sig(cell) != String(p.on).repeat(4):
		return false
	var r := collider_cells(cell, p)
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := Vector2i(x, y)
			if not _inside(c) or _taken.has(c) or kind[_i(c)] != OPEN or paths.has(c):
				return false
	props.append({"art": art, "cell": cell})
	_claim(r)
	if p.block != Vector2.ZERO:
		# Every cell the collider spans (a wide root flare spans three).
		for x in range(r.position.x, r.end.x):
			blocked[Vector2i(x, cell.y)] = true
	return true


## The cells a prop's collider overlaps: it is centred on the cell's middle
## (pixelcrawler.gd), so a wide one reaches into the cells either side.
static func collider_cells(cell: Vector2i, p: Dictionary) -> Rect2i:
	if p.block.x <= 0.0:
		return Rect2i(cell, Vector2i.ONE)
	var cx := cell.x * TILE + TILE / 2.0
	var x0 := floori((cx - p.block.x / 2.0) / TILE)
	var x1 := floori((cx + p.block.x / 2.0 - 0.01) / TILE)
	return Rect2i(x0, cell.y, x1 - x0 + 1, 1)


func _near(arts: Array, count: int, center: Vector2i, radius: int) -> void:
	var put := 0
	for t in count * 24:
		if put >= count:
			return
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		if _place(arts[_rng.randi() % arts.size()], c):
			put += 1


## Trees in clusters over undergrowth (the mockups' layered canopies), then
## singles; they crowd onto the zone terrain.
func _scatter_trees() -> void:
	var set_: Array = TREE_SETS[recipe.trees[0]]
	var want: int = recipe.trees[1]
	var under: Array = SCATTER[recipe.biome][0]
	var placed := 0
	for n in maxi(2, want / 5):
		var c := Vector2i(_rng.randi_range(3, W - 4), _rng.randi_range(3, H - 6))
		if not sig(c).contains(biome.zone) and _rng.randf() < 0.5:
			continue
		for k in _rng.randi_range(3, 5):
			var p := c + Vector2i(_rng.randi_range(-5, 5), _rng.randi_range(-3, 3))
			if _place(set_[_rng.randi() % set_.size()], p):
				placed += 1
				_claim(Rect2i(p - Vector2i(1, 1), Vector2i(3, 2)))
		_near(under, _rng.randi_range(2, 4), c + Vector2i(0, 2), 5)
	for t in want * 30:
		if placed >= want:
			break
		var c := Vector2i(_rng.randi_range(2, W - 3), _rng.randi_range(3, H - 3))
		var near := false
		for p in props:
			if prop(p.art).tag in ["tree", "bare", "cactus"] and Vector2(p.cell - c).length() < 4.0:
				near = true
				break
		if near:
			continue
		if _place(set_[_rng.randi() % set_.size()], c):
			placed += 1
			_claim(Rect2i(c - Vector2i(1, 1), Vector2i(3, 2)))


func _scatter_small() -> void:
	var sets: Array = SCATTER[recipe.biome]
	_near(sets[0], 14, Vector2i(W / 2, H / 2), W / 2)
	_near(sets[1], 70, Vector2i(W / 2, H / 2), W / 2)


# ---------------------------------------------------------------- grass splat

## Weight fields for the ground splat (pixelcrawler.gd draws it with
## shaders/ms_grass_splat.gdshader): four layers over pure root ground and
## four over the pure zone terrain. Each is value noise raised by context
## (sunlit away from trees, dry by paths and patches, tufts at a finer scale,
## shade by trunks and plateaus), cut at its share of the eligible corners
## with a soft band. Eligibility fades in over two corners from any other
## terrain, water, or plateau, so no Wang transition tile is overdrawn.
const SPLAT_SHARE := [0.2, 0.14, 0.16, 0.18]

func _splat() -> void:
	var n := (W + 1) * (H + 1)
	splat_fade = _eligible(biome.root)
	splat_fade_dark = _eligible(biome.zone)
	var bare: Array[Vector2i] = []
	var shade: Array[Vector2i] = []
	for y in H + 1:
		for x in W + 1:
			var t := corner[_ci(x, y)]
			if t != biome.root and t != biome.zone:
				bare.append(Vector2i(x, y))
	for p in props:
		if prop(p.art).tag in ["tree", "bare"]:
			shade.append(p.cell + Vector2i(1, 1))
	for pl in plateaus:
		var r: Rect2i = pl.rect
		for x in range(r.position.x, r.end.x + 1):
			shade.append(Vector2i(x, r.end.y))
	var near_bare := _corner_near(bare, 4)
	var near_shade := _corner_near(shade, 5)
	splat.clear()
	for li in 4:
		var noise := FastNoiseLite.new()
		noise.seed = map_id * 101 + li * 7919 + attempt
		noise.frequency = 0.15 if li == 2 else 0.065
		noise.fractal_octaves = 2
		var vals := PackedFloat32Array()
		vals.resize(n)
		var eligible: Array[float] = []
		for y in H + 1:
			for x in W + 1:
				var i := _ci(x, y)
				var v := noise.get_noise_2d(x, y) * 0.5 + 0.5
				match li:
					0: v -= near_shade[i] * 0.3
					1: v += near_bare[i] * 0.3
					3: v += near_shade[i] * 0.35
				vals[i] = v
				if splat_fade[i] > 0.0 or splat_fade_dark[i] > 0.0:
					eligible.append(v)
		var field := PackedFloat32Array()
		field.resize(n)
		field.fill(0.0)
		if not eligible.is_empty():
			eligible.sort()
			var cut: float = eligible[clampi(int((1.0 - SPLAT_SHARE[li]) * eligible.size()), 0, eligible.size() - 1)]
			for i in n:
				field[i] = clampf((vals[i] - cut) / 0.08 + 0.5, 0.0, 1.0)
		splat.append(field)


## Per corner: how deep inside pure terrain `t` it lies (Euclidean distance,
## up to 4 corners, to any other terrain, water, or plateau), ramping from 0
## at one corner to 1 at three.
func _eligible(t: String) -> PackedFloat32Array:
	var n := (W + 1) * (H + 1)
	var dist := PackedFloat32Array()
	dist.resize(n)
	dist.fill(5.0)
	for y in H + 1:
		for x in W + 1:
			if corner[_ci(x, y)] == t and not _blocked_corner(x, y):
				continue
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var qx := x + dx
					var qy := y + dy
					if qx < 0 or qy < 0 or qx > W or qy > H:
						continue
					var d := Vector2(dx, dy).length()
					if d < dist[_ci(qx, qy)]:
						dist[_ci(qx, qy)] = d
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = clampf((dist[i] - 1.0) / 2.0, 0.0, 1.0)
	return out


## A corner next to water, a plateau, or an island (their art or pixels meet
## the ground there).
func _blocked_corner(x: int, y: int) -> bool:
	for o in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0)]:
		var c := Vector2i(x + o.x, y + o.y)
		if _inside(c) and kind[_i(c)] != OPEN:
			return true
	return false


func _corner_near(sources: Array[Vector2i], radius: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize((W + 1) * (H + 1))
	out.fill(0.0)
	for s: Vector2i in sources:
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var x := s.x + dx
				var y := s.y + dy
				if x < 0 or y < 0 or x > W or y > H:
					continue
				var v := 1.0 - Vector2(dx, dy).length() / float(radius + 1)
				if v > out[_ci(x, y)]:
					out[_ci(x, y)] = v
	return out


# ---------------------------------------------------------------- liveliness

# The Painted Lands floor with its frozen weights (not recalibrated for this
# pack). These sheets have no fires or torches, so a weak window gets a small
# pond (water moves) on grass biomes, or a swarm of fireflies over a patch of
# glowing plants or shade.
const LIVE_FLOOR := 0.09
const FLOOR_ANCHORS := 4
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WATER := 6.0
const FLOOR_GLOW := 30.0
const FLOOR_TREE := 6.0

func _liveliness_floor() -> void:
	for n in FLOOR_ANCHORS:
		var weak := _weakest()
		if n == 0:
			floor_notes.append("weakest window %.3f%%" % weak.value)
		if weak.value >= LIVE_FLOOR:
			break
		var r: Rect2i = weak.rect
		if recipe.biome in ["fairy", "green"] and _floor_pond(r):
			floor_notes.append("pond")
		else:
			var c := r.get_center() + Vector2i(_rng.randi_range(-8, 8), _rng.randi_range(-3, 3))
			firefly_spots.append(c.clamp(Vector2i(1, 1), Vector2i(W - 2, H - 2)))
			if recipe.biome == "fairy":
				_near(["ff_bell", "ff_bell_s", "ff_bell_xs"], 3, c, 3)
			floor_notes.append("fireflies")
	floor_notes.append("-> %.3f%%" % _weakest().value)


func _floor_pond(r: Rect2i) -> bool:
	for t in 30:
		var size := Vector2i(_rng.randi_range(5, 7), _rng.randi_range(4, 5))
		var at := r.get_center() + Vector2i(_rng.randi_range(-14, 10), _rng.randi_range(-6, 3))
		var box := Rect2i(at, size)
		var ok := box.position.x > 1 and box.position.y > 1 and box.end.x < W - 1 and box.end.y < H - 1
		if ok:
			for y in range(box.position.y - 1, box.end.y + 1):
				for x in range(box.position.x - 1, box.end.x + 1):
					var c := Vector2i(x, y)
					if kind[_i(c)] != OPEN or blocked.has(c) or paths.has(c) or c == spawn or _prop_at(c):
						ok = false
		if not ok:
			continue
		var c0 := Vector2(box.get_center())
		var cells: Array[Vector2i] = []
		for y in range(box.position.y, box.end.y):
			for x in range(box.position.x, box.end.x):
				var d := Vector2((x + 0.5 - c0.x) / (size.x * 0.5), (y + 0.5 - c0.y) / (size.y * 0.5))
				if d.length() + (_hash(x * 3, y * 5) - 0.5) * 0.5 < 1.0:
					cells.append(Vector2i(x, y))
		for c in cells:
			water[c] = true
			kind[_i(c)] = WATER
		if _reaches_all():
			ponds.append(box)
			return true
		for c in cells:
			water.erase(c)
			kind[_i(c)] = OPEN
	return false


var _prop_cells := {}

func _prop_at(c: Vector2i) -> bool:
	if _prop_cells.size() != props.size():
		_prop_cells.clear()
		for p in props:
			_prop_cells[p.cell] = true
	return _prop_cells.has(c)


func _weakest() -> Dictionary:
	var m := PackedFloat32Array()
	m.resize(W * H)
	m.fill(0.0)
	for c: Vector2i in water:
		m[_i(c)] += FLOOR_WATER
	for c: Vector2i in pool_tiles:
		m[_i(c)] += FLOOR_WATER # lava and slime move as water does
	for c in firefly_spots:
		m[_i(c)] += FLOOR_GLOW * 2.0
	for p in props:
		if not _inside(p.cell):
			continue
		var tag: String = prop(p.art).tag
		if tag == "glow" or tag == "rune" or tag == "lamp":
			m[_i(p.cell)] += FLOOR_GLOW
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

func open_water() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in water:
		if stones.has(c):
			continue
		var all := true
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				if not water.has(c + Vector2i(dx, dy)):
					all = false
		if all:
			out.append(c)
	return out


## Cells the walker could stand on with the root or zone terrain under them
## (grass waves and blade flicks on the grass biomes).
func grass_cells() -> Dictionary:
	var out := {}
	if recipe.biome not in ["fairy", "green"]:
		return out
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] != OPEN or blocked.has(c):
				continue
			var s := sig(c)
			if not s.contains("e") and not s.contains("k"):
				out[c] = true
	return out


func zone_cells() -> Dictionary:
	var out := {}
	for y in H:
		for x in W:
			var c := Vector2i(x, y)
			if kind[_i(c)] == OPEN and sig(c).count(biome.zone) >= 3:
				out[c] = true
	return out


func trunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for p in props:
		if prop(p.art).tag in ["tree", "bare"]:
			out.append(p.cell)
	return out


func wildlife_plan() -> Dictionary:
	var grass := grass_cells()
	var zones := zone_cells()
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
		var tag: String = prop(p.art).tag
		if tag in ["clutter", "wood", "grave", "bone"]:
			clutter.append(p.cell)
		elif tag in ["bush", "plant", "cactus"]:
			bushes.append(p.cell)
		elif tag in ["stone", "rune"]:
			rocks.append(p.cell)
	var h := {"lawn": {}, "trees": {}, "dark": {}, "clutter": {}, "bushes": {}, "shore": {}, "water": {}, "open": {}, "rocky": {}, "roam": {}}
	var desert: bool = recipe.biome == "desert"
	for c: Vector2i in land:
		var wet := false
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			if water.has(c + d):
				wet = true
		if wet:
			h.shore[c] = true
		if not wet:
			h.roam[c] = true
			if grass.has(c) and not zones.has(c):
				h.lawn[c] = true
		if zones.has(c) and not desert:
			h.dark[c] = true
		if _near_any(c, tr, 2):
			h.trees[c] = true
		if _near_any(c, clutter, 2):
			h.clutter[c] = true
		if _near_any(c, bushes, 2):
			h.bushes[c] = true
		if desert or _near_any(c, rocks, 2):
			h.rocky[c] = true
		if paths.has(c + Vector2i.DOWN) or paths.has(c + Vector2i.UP):
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
	if stones.has(c):
		return true
	return kind[_i(c)] == OPEN


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
			seen[n] = true
			queue.append(n)
	return false


func _report() -> String:
	if not _reaches_all():
		fails.append("spawn does not reach every goal")
	var tab: Dictionary = PCTiles.WANG[recipe.biome]
	var untiled := 0
	for y in H:
		for x in W:
			if not tab.has(sig(Vector2i(x, y))):
				untiled += 1
	if untiled > 0:
		fails.append("%d cells without a tile" % untiled)
	if maze:
		if not maze_info.has("corridors"):
			fails.append("no maze laid")
		else:
			var cut: Array[Vector2i] = _maze.unreached()
			if not cut.is_empty():
				fails.append("%d maze cells cut off" % cut.size())
	var lines := PackedStringArray([
		"Pixel Crawler map %d: recipe %d %s (%s), %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, recipe.biome, W, H, attempt],
		"  plateaus %d, ponds %d, islands %d, water %d cells, path %d cells, trees %d, props %d" % [
			plateaus.size(), ponds.size(), islands.size(), water.size(), paths.size(), trunks().size(), props.size()],
		"  %s" % ", ".join(notes),
		"  floor: %s" % " ".join(floor_notes),
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	return "\n".join(lines)
