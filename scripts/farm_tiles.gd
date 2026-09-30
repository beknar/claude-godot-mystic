class_name FarmTiles
extends RefCounted
## The Farm - 4 Seasons sheets (antarcticbees), spring and summer edition, as
## data: the corner table of the ground, the water shores, tilled plots, the
## hedge, tall grass, and wheat overlays, fences, deco, crops, buildings,
## animated trees, and props. Sheets in assets/pack/farm/ (git-ignored).
## Coordinates are cells of 16 px on tilesets/farm_spring_summer.png unless
## a rect says px. Read from the sheet by script (classifying each tile's
## corners by terrain color), then checked by eye.

const PACK := "res://assets/pack/farm/"
const SHEET := "tilesets/farm_spring_summer"
const CROPS_SHEET := "tilesets/crops"

# Ground terrains (letters in the corner table):
#   g lawn (105, 150, 84), the root
#   a pale grass (162, 177, 108), sunny dry patches, nested in the lawn
#   d dark grass (63, 128, 78), nested in the lawn
#   x deep grass (34, 97, 81), nested in the dark
#   s sand (214, 196, 150), yards; e dirt (174, 141, 98), roads and patches
# Every pair the sheet blends has 14 of the 16 corner mixes (no diagonals):
# a-g, g-d, d-x, and sand and dirt on each grass. Key: the terrains at the
# TL, TR, BL, BR corners; value: atlas cells, plain fill first.
const WANG := {
	"aaaa": [Vector2i(19, 0), Vector2i(20, 0), Vector2i(21, 0), Vector2i(22, 0), Vector2i(28, 4), Vector2i(28, 13), Vector2i(28, 19)],
	"aaae": [Vector2i(27, 21)],
	"aaag": [Vector2i(27, 0)],
	"aaas": [Vector2i(27, 15)],
	"aaea": [Vector2i(29, 21)],
	"aaee": [Vector2i(28, 20), Vector2i(28, 21)],
	"aaga": [Vector2i(29, 0)],
	"aagg": [Vector2i(28, 0), Vector2i(28, 5)],
	"aasa": [Vector2i(29, 15)],
	"aass": [Vector2i(28, 14), Vector2i(28, 15)],
	"aeaa": [Vector2i(27, 23)],
	"aeae": [Vector2i(29, 19), Vector2i(27, 22)],
	"aeee": [Vector2i(29, 20)],
	"agaa": [Vector2i(27, 2)],
	"agag": [Vector2i(27, 1), Vector2i(29, 4)],
	"aggg": [Vector2i(29, 5)],
	"asaa": [Vector2i(27, 17)],
	"asas": [Vector2i(29, 13), Vector2i(27, 16)],
	"asss": [Vector2i(29, 14)],
	"dddd": [Vector2i(23, 0), Vector2i(24, 0), Vector2i(25, 0), Vector2i(26, 0), Vector2i(31, 1), Vector2i(34, 4), Vector2i(34, 13), Vector2i(34, 19)],
	"ddde": [Vector2i(33, 21)],
	"dddg": [Vector2i(30, 3)],
	"ddds": [Vector2i(33, 15)],
	"dddx": [Vector2i(33, 0)],
	"dded": [Vector2i(35, 21)],
	"ddee": [Vector2i(34, 20), Vector2i(34, 21)],
	"ddgd": [Vector2i(32, 3)],
	"ddgg": [Vector2i(31, 2), Vector2i(31, 3)],
	"ddsd": [Vector2i(35, 15)],
	"ddss": [Vector2i(34, 14), Vector2i(34, 15)],
	"ddxd": [Vector2i(35, 0)],
	"ddxx": [Vector2i(34, 0), Vector2i(34, 5)],
	"dedd": [Vector2i(33, 23)],
	"dede": [Vector2i(35, 19), Vector2i(33, 22)],
	"deee": [Vector2i(35, 20)],
	"dgdd": [Vector2i(30, 5)],
	"dgdg": [Vector2i(32, 1), Vector2i(30, 4)],
	"dggg": [Vector2i(32, 2)],
	"dsdd": [Vector2i(33, 17)],
	"dsds": [Vector2i(35, 13), Vector2i(33, 16)],
	"dsss": [Vector2i(35, 14)],
	"dxdd": [Vector2i(33, 2)],
	"dxdx": [Vector2i(33, 1), Vector2i(35, 4)],
	"dxxx": [Vector2i(35, 5)],
	"eaaa": [Vector2i(29, 23)],
	"eaea": [Vector2i(27, 19), Vector2i(29, 22)],
	"eaee": [Vector2i(27, 20)],
	"eddd": [Vector2i(35, 23)],
	"eded": [Vector2i(33, 19), Vector2i(35, 22)],
	"edee": [Vector2i(33, 20)],
	"eeaa": [Vector2i(28, 18), Vector2i(28, 23)],
	"eeae": [Vector2i(29, 18)],
	"eedd": [Vector2i(34, 18), Vector2i(34, 23)],
	"eede": [Vector2i(35, 18)],
	"eeea": [Vector2i(27, 18)],
	"eeed": [Vector2i(33, 18)],
	"eeee": [Vector2i(28, 22), Vector2i(31, 22), Vector2i(34, 22), Vector2i(37, 22)],
	"eeeg": [Vector2i(30, 18)],
	"eeex": [Vector2i(36, 18)],
	"eege": [Vector2i(32, 18)],
	"eegg": [Vector2i(31, 18), Vector2i(31, 23)],
	"eexe": [Vector2i(38, 18)],
	"eexx": [Vector2i(37, 18), Vector2i(37, 23)],
	"egee": [Vector2i(30, 20)],
	"egeg": [Vector2i(30, 19), Vector2i(32, 22)],
	"eggg": [Vector2i(32, 23)],
	"exee": [Vector2i(36, 20)],
	"exex": [Vector2i(36, 19), Vector2i(38, 22)],
	"exxx": [Vector2i(38, 23)],
	"gaaa": [Vector2i(29, 2)],
	"gaga": [Vector2i(29, 1), Vector2i(27, 4)],
	"gagg": [Vector2i(27, 5)],
	"gddd": [Vector2i(32, 5)],
	"gdgd": [Vector2i(30, 1), Vector2i(32, 4)],
	"gdgg": [Vector2i(30, 2)],
	"geee": [Vector2i(32, 20)],
	"gege": [Vector2i(32, 19), Vector2i(30, 22)],
	"gegg": [Vector2i(30, 23)],
	"ggaa": [Vector2i(28, 2), Vector2i(28, 3)],
	"ggag": [Vector2i(29, 3)],
	"ggdd": [Vector2i(31, 0), Vector2i(31, 5)],
	"ggdg": [Vector2i(32, 0)],
	"ggee": [Vector2i(31, 20), Vector2i(31, 21)],
	"ggeg": [Vector2i(32, 21)],
	"ggga": [Vector2i(27, 3)],
	"gggd": [Vector2i(30, 0)],
	"ggge": [Vector2i(30, 21)],
	"gggg": [Vector2i(19, 1), Vector2i(20, 1), Vector2i(21, 1), Vector2i(22, 1), Vector2i(28, 1), Vector2i(31, 4), Vector2i(31, 13), Vector2i(31, 19)],
	"gggs": [Vector2i(30, 15)],
	"ggsg": [Vector2i(32, 15)],
	"ggss": [Vector2i(31, 14), Vector2i(31, 15)],
	"gsgg": [Vector2i(30, 17)],
	"gsgs": [Vector2i(32, 13), Vector2i(30, 16)],
	"gsss": [Vector2i(32, 14)],
	"saaa": [Vector2i(29, 17)],
	"sasa": [Vector2i(27, 13), Vector2i(29, 16)],
	"sass": [Vector2i(27, 14)],
	"sddd": [Vector2i(35, 17)],
	"sdsd": [Vector2i(33, 13), Vector2i(35, 16)],
	"sdss": [Vector2i(33, 14)],
	"sggg": [Vector2i(32, 17)],
	"sgsg": [Vector2i(30, 13), Vector2i(32, 16)],
	"sgss": [Vector2i(30, 14)],
	"ssaa": [Vector2i(28, 12), Vector2i(28, 17)],
	"ssas": [Vector2i(29, 12)],
	"ssdd": [Vector2i(34, 12), Vector2i(34, 17)],
	"ssds": [Vector2i(35, 12)],
	"ssgg": [Vector2i(31, 12), Vector2i(31, 17)],
	"ssgs": [Vector2i(32, 12)],
	"sssa": [Vector2i(27, 12)],
	"sssd": [Vector2i(33, 12)],
	"sssg": [Vector2i(30, 12)],
	"ssss": [Vector2i(28, 16), Vector2i(31, 16), Vector2i(34, 16), Vector2i(37, 16)],
	"sssx": [Vector2i(36, 12)],
	"ssxs": [Vector2i(38, 12)],
	"ssxx": [Vector2i(37, 12), Vector2i(37, 17)],
	"sxss": [Vector2i(36, 14)],
	"sxsx": [Vector2i(36, 13), Vector2i(38, 16)],
	"sxxx": [Vector2i(38, 17)],
	"xddd": [Vector2i(35, 2)],
	"xdxd": [Vector2i(35, 1), Vector2i(33, 4)],
	"xdxx": [Vector2i(33, 5)],
	"xeee": [Vector2i(38, 20)],
	"xexe": [Vector2i(38, 19), Vector2i(36, 22)],
	"xexx": [Vector2i(36, 23)],
	"xsss": [Vector2i(38, 14)],
	"xsxs": [Vector2i(38, 13), Vector2i(36, 16)],
	"xsxx": [Vector2i(36, 17)],
	"xxdd": [Vector2i(34, 2), Vector2i(34, 3)],
	"xxdx": [Vector2i(35, 3)],
	"xxee": [Vector2i(37, 20), Vector2i(37, 21)],
	"xxex": [Vector2i(38, 21)],
	"xxss": [Vector2i(37, 14), Vector2i(37, 15)],
	"xxsx": [Vector2i(38, 15)],
	"xxxd": [Vector2i(33, 3)],
	"xxxe": [Vector2i(36, 21)],
	"xxxs": [Vector2i(36, 15)],
	"xxxx": [Vector2i(23, 1), Vector2i(24, 1), Vector2i(25, 1), Vector2i(26, 1), Vector2i(34, 1), Vector2i(37, 13), Vector2i(37, 19)],}
# Repair: a cell mixing terrains no tile draws returns its lowest-priority
# terrain to the parent (deep first, then dark, pale, sand, dirt).
const PARENT := {"a": ["g", 3], "d": ["g", 2], "x": ["d", 1], "s": ["g", 4], "e": ["g", 5]}

# Water: four frames stacked five rows apart (the tile animation steps down),
# the shore rim inside the land cells (lawn with a rock lip) and the ripple
# inside the water cells. Land cells by where the water is (sides, or one
# diagonal only); water cells by where the land is.
const WATER_FRAMES := 4
const WATER_STEP := 5 # rows between frames
const WATER_DURATION := 0.28
const SHORE_LAND := {
	"N": Vector2i(2, 22), "S": Vector2i(2, 24), "W": Vector2i(1, 23), "E": Vector2i(3, 23),
	"NW": Vector2i(1, 22), "NE": Vector2i(3, 22), "SW": Vector2i(1, 24), "SE": Vector2i(3, 24),
	"nw": Vector2i(6, 22), "ne": Vector2i(7, 22), "sw": Vector2i(6, 23), "se": Vector2i(7, 23),
}
const SHORE_WATER := {
	"S": Vector2i(2, 21), "N": Vector2i(2, 25), "E": Vector2i(0, 23), "W": Vector2i(4, 23),
	"se": Vector2i(0, 21), "sw": Vector2i(4, 21), "ne": Vector2i(0, 25), "nw": Vector2i(4, 25),
	"ES": Vector2i(5, 21), "WS": Vector2i(8, 21), "NE": Vector2i(5, 24), "NW": Vector2i(8, 24),
}
# Open water: four frames side by side (two variants a row apart), and the
# sparkle overlay frames under them.
const WATER_OPEN: Array[Vector2i] = [Vector2i(13, 19), Vector2i(13, 20)]
const WATER_OPEN_STEP := 1 # columns between frames
const WATER_SPARKLE := Vector2i(13, 21)

# Tilled plots: a bordered field as a 3 x 3 block, a one-wide column (top,
# middle, bottom), a one-tall row (west, middle, east), and a single plot.
# dry: light soil, sand rim; wet: dark soil, sand rim; ragged: dark soil
# whose rim is broken to transparent (sits on grass).
const PLOTS := {
	"dry": {"at": Vector2i(40, 14), "col": 43, "row": 17},
	"wet": {"at": Vector2i(52, 14), "col": 55, "row": 17},
	"ragged": {"at": Vector2i(52, 18), "col": 55, "row": 21},
}

# Overlay blobs on transparent ground, corner tables with all sixteen mixes
# (diagonals too). Key: TL TR BL BR, 1 = the blob. hedge: dark bushes;
# tall: young green wheat or tall grass; wheat: ripe golden wheat.
const BLOB_BASE := {"hedge": Vector2i(22, 6), "tall": Vector2i(22, 10), "wheat": Vector2i(22, 14)}
const BLOB := {
	"0001": Vector2i(0, 0), "0011": Vector2i(1, 0), "0010": Vector2i(2, 0),
	"0101": Vector2i(0, 1), "1111": Vector2i(1, 1), "1010": Vector2i(2, 1),
	"0100": Vector2i(0, 2), "1100": Vector2i(1, 2), "1000": Vector2i(2, 2),
	"1110": Vector2i(3, 0), "1101": Vector2i(4, 0), "1011": Vector2i(3, 1), "0111": Vector2i(4, 1),
	"1001": Vector2i(0, 3), "0110": Vector2i(1, 3),
}

# Fences: a 3 x 3 frame (posts and rails), plain and grassy.
const FENCE := {"plain": Vector2i(11, 12), "grassy": Vector2i(14, 12)}
const GATE_SHEET := "fence gate animations/gate_spring_summer_autumn-Sheet" # 4 frames of 16 px

# Deco tiles on transparent (cells): sprouts and tufts, flowers.
const SPROUTS: Array[Vector2i] = [Vector2i(19, 2), Vector2i(20, 2), Vector2i(21, 2), Vector2i(22, 2), Vector2i(19, 3), Vector2i(20, 3), Vector2i(21, 3), Vector2i(25, 2), Vector2i(26, 2)]
const SPROUTS_DARK: Array[Vector2i] = [Vector2i(23, 2), Vector2i(24, 2), Vector2i(22, 3), Vector2i(23, 3), Vector2i(24, 3), Vector2i(26, 3)]
const FLOWERS: Array[Vector2i] = [Vector2i(19, 4), Vector2i(20, 4), Vector2i(21, 4), Vector2i(22, 4), Vector2i(23, 4), Vector2i(24, 4),
	Vector2i(19, 5), Vector2i(20, 5), Vector2i(21, 5), Vector2i(22, 5), Vector2i(23, 5), Vector2i(24, 5)]
const TUFTS: Array[Vector2i] = [Vector2i(25, 4), Vector2i(26, 4)]

# Crops (tilesets/crops.png): growth stages, young to ripe, as cells; a
# stage marked tall takes the cell above too.
const CROPS := {
	"carrot": [[0, 1], [1, 1], [2, 1], [3, 1, 1]],
	"potato": [[0, 3], [1, 3], [2, 3], [3, 3, 1]],
	"corn": [[0, 5], [1, 5], [2, 5, 1], [3, 5, 1], [4, 5, 1]],
	"cabbage": [[0, 6], [1, 6], [2, 6], [3, 6], [4, 6]],
	"cauliflower": [[0, 7], [1, 7], [2, 7], [3, 7], [4, 7]],
	"watermelon": [[0, 8], [1, 8], [2, 8], [3, 8], [4, 8]],
	"leek": [[0, 10], [1, 10], [2, 10], [3, 10, 1], [4, 10, 1]],
	"pumpkin": [[0, 11], [1, 11], [2, 11], [3, 11], [4, 11]],
	"sunflower": [[0, 13], [1, 13], [2, 13, 1], [3, 13, 1], [4, 13, 1]],
	"berry": [[9, 1], [10, 1], [11, 1, 1], [12, 1, 1], [13, 1, 1]],
	"onion": [[9, 3], [10, 3], [11, 3], [12, 3, 1], [13, 3, 1]],
	"strawberry": [[9, 4], [10, 4], [11, 4], [12, 4], [13, 4]],
	"wheat": [[9, 6], [10, 6], [11, 6], [12, 6, 1], [13, 6, 1]],
	"beet": [[9, 7], [10, 7], [11, 7], [12, 7], [13, 7]],
	"tomato": [[9, 9], [10, 9], [11, 9], [12, 9, 1], [13, 9, 1]],
	"pepper": [[9, 11], [10, 11, 1], [11, 11, 1], [12, 11, 1], [13, 11, 1]],
}
# Crops that sway (a tall stalk or leafy top nods with the wind).
const CROPS_NOD := ["corn", "sunflower", "wheat", "leek", "tomato", "pepper", "berry", "onion", "carrot"]

# Buildings: region in px on the sheet (cell-aligned), the door cell under
# the door (walkable, relative to the region's top-left cell), how many
# cells wide the doorway is, body colliders in region px, and the rooms
# behind the door. The windmill is the animated sheet (four frames), drawn
# 8 px left so its door sits on a cell. The greenhouse opens on its own
# interior (the sheet's glasshouse floor), not a Cozy Cottage home.
const BUILDINGS := {
	"farmhouse": {"region": Rect2i(816, 384, 96, 96), "door": Vector2i(2, 5), "door_w": 1,
		"blocks": [Rect2i(4, 50, 86, 30)], "rooms": [2, 4]},
	"farmhouse_b": {"region": Rect2i(912, 384, 96, 96), "door": Vector2i(2, 5), "door_w": 1,
		"blocks": [Rect2i(4, 50, 86, 30)], "rooms": [2, 4]},
	"manor": {"region": Rect2i(1008, 384, 112, 112), "door": Vector2i(3, 6), "door_w": 1,
		"blocks": [Rect2i(8, 52, 100, 44)], "rooms": [3, 6]},
	"barn": {"region": Rect2i(816, 480, 128, 96), "door": Vector2i(2, 5), "door_w": 2,
		"blocks": [Rect2i(13, 52, 102, 28), Rect2i(13, 80, 19, 16), Rect2i(64, 80, 51, 16)], "rooms": [1, 2]},
	"greenhouse": {"region": Rect2i(1024, 96, 96, 80), "door": Vector2i(2, 4), "door_w": 2,
		"blocks": [Rect2i(4, 24, 88, 40), Rect2i(4, 64, 28, 16), Rect2i(64, 64, 28, 16)], "rooms": [1, 1], "custom": "greenhouse"},
	"windmill": {"anim": "windmill animations/windmill_spring_summerSheet", "frames": 4, "frame": Vector2i(96, 128), "shift": Vector2i(-8, 0),
		"region": Rect2i(0, 0, 80, 128), "door": Vector2i(2, 7), "door_w": 1,
		"blocks": [Rect2i(18, 80, 46, 32), Rect2i(18, 112, 14, 16), Rect2i(48, 112, 16, 16)], "rooms": [1, 1]},
}
# The greenhouse interior on the sheet: 11 x 12 cells from (64, 11); the
# back wall is three rows, the way out a gap in the bottom row.
const GREENHOUSE_ROOM := Rect2i(64, 11, 11, 12)
const GREENHOUSE_EXIT := Vector2i(5, 11)

# Trees from the animation sheets: eight frames side by side (the tree
# rustles, a leaf or two drops), and the falling-leaves overlay of the same
# frame size played when the walker brushes the trunk.
const TREE_DIR := "tree animations/spring and summer/trees_cut_down/"
const TREES := {
	"oak": {"sheet": "basic/tree_basic_1-Sheet", "falling": "basic/leaves_falling_basic-Sheet"},
	"oak_b": {"sheet": "basic/tree_basic_2-Sheet", "falling": ""},
	"elm": {"sheet": "basic/tree_basic_3-Sheet", "falling": ""},
	"elm_b": {"sheet": "basic/tree_basic_4-Sheet", "falling": ""},
	"pine": {"sheet": "basic/tree_pine-Sheet", "falling": ""},
	"oak_bare": {"sheet": "basic/tree_basic_1_no_leaves-Sheet", "falling": ""},
	"oak_dead": {"sheet": "basic/tree_basic_1_dead-Sheet", "falling": ""},
	"elm_dead": {"sheet": "basic/tree_basic_3_dead-Sheet", "falling": ""},
	"apple": {"sheet": "fruit trees/apple/tree_apple-Sheet", "falling": "fruit trees/apple/apple_leaves_falling-Sheet", "fruit": true},
	"apple_fruit": {"sheet": "fruit trees/apple/tree_apple_fruit-Sheet", "falling": "fruit trees/apple/apple_leaves_falling-Sheet", "fruit": true},
	"apple_flowers": {"sheet": "fruit trees/apple/tree_apple_flowers-Sheet", "falling": "fruit trees/apple/apple_leaves_falling-Sheet", "fruit": true},
	"cherry": {"sheet": "fruit trees/cherry/tree_cherry-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling-Sheet", "fruit": true},
	"cherry_bloom": {"sheet": "fruit trees/cherry/tree_cherry_bloom-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling-Sheet", "fruit": true, "petals": true},
	"cherry_fruit": {"sheet": "fruit trees/cherry/tree_cherry_fruit-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling-Sheet", "fruit": true},
	"orange": {"sheet": "fruit trees/orange/tree_orange-Sheet", "falling": "fruit trees/orange/orange_leaves_falling-Sheet", "fruit": true},
	"orange_fruit": {"sheet": "fruit trees/orange/tree_orange_fruit-Sheet", "falling": "fruit trees/orange/orange_leaves_falling-Sheet", "fruit": true},
	"orange_flowers": {"sheet": "fruit trees/orange/tree_orange_flowers-Sheet", "falling": "fruit trees/orange/orange_leaves_falling-Sheet", "fruit": true},
	"peach": {"sheet": "fruit trees/peach/tree_peach-Sheet", "falling": "fruit trees/peach/peach_leaves_falling-Sheet", "fruit": true},
	"peach_fruit": {"sheet": "fruit trees/peach/tree_peach_fruit-Sheet", "falling": "fruit trees/peach/peach_leaves_falling-Sheet", "fruit": true},
	"peach_flowers": {"sheet": "fruit trees/peach/tree_peach_flowers-Sheet", "falling": "fruit trees/peach/peach_leaves_falling-Sheet", "fruit": true},
}
const TREE_FRAMES := 8
# Leaves blowing off a crown in a gust (eight frames of 64 px).
const WIND_LEAVES := {
	"basic": "tree animations/spring and summer/leaves_wind/leaves_wind_basic_spritesheet",
	"apple": "tree animations/spring and summer/leaves_wind/wind_leaves_apple_spritesheet",
	"cherry": "tree animations/spring and summer/leaves_wind/wind_leaves_cherry_spritesheet",
	"cherry_bloom": "tree animations/spring and summer/leaves_wind/flowers_cherryspritesheet",
	"orange": "tree animations/spring and summer/leaves_wind/wind_leaves_orange_spritesheet",
	"peach": "tree animations/spring and summer/leaves_wind/wind_leaves_peach_spritesheet",
}
const TREE_SETS := {
	"wild": ["oak", "oak_b", "elm", "elm_b", "oak", "elm"],
	"pines": ["pine", "pine", "pine", "oak_b", "elm_b"],
	"old": ["oak_dead", "elm_dead", "oak_bare", "oak", "elm"],
	"apple": ["apple_fruit", "apple", "apple_fruit", "apple_flowers"],
	"cherry": ["cherry_bloom", "cherry_bloom", "cherry", "cherry_fruit"],
	"orange": ["orange_fruit", "orange", "orange_flowers"],
	"peach": ["peach_fruit", "peach_flowers", "peach"],
	"mixed_fruit": ["apple_fruit", "cherry_fruit", "orange_fruit", "peach_fruit", "cherry_bloom"],
}

# Static props: rect in px on the farm sheet, collider (w, h at the foot;
# zero walks through), tag. Big canopy block: the seamless 4 x 4 crowns.
const CANOPY := Rect2i(0, 0, 64, 64)
const PROPS := {
	"dead_tree": {"rect": Rect2i(256, 24, 43, 56), "block": Vector2(10, 6), "tag": "bare"},
	"dead_tree_s": {"rect": Rect2i(130, 20, 29, 44), "block": Vector2(8, 5), "tag": "bare"},
	"dead_tree_big": {"rect": Rect2i(83, 152, 49, 71), "block": Vector2(14, 6), "tag": "bare"},
	"bush": {"rect": Rect2i(144, 128, 32, 32), "block": Vector2(22, 6), "tag": "bush"},
	"bush_b": {"rect": Rect2i(176, 128, 32, 32), "block": Vector2(22, 6), "tag": "bush"},
	"bush_pine": {"rect": Rect2i(211, 129, 26, 31), "block": Vector2(14, 5), "tag": "bush"},
	"rock": {"rect": Rect2i(242, 109, 29, 19), "block": Vector2(24, 7), "tag": "stone"},
	"rock_b": {"rect": Rect2i(242, 128, 26, 16), "block": Vector2(22, 6), "tag": "stone"},
	"rock_big": {"rect": Rect2i(241, 154, 29, 22), "block": Vector2(24, 8), "tag": "stone"},
	"pebble": {"rect": Rect2i(210, 167, 11, 8), "block": Vector2.ZERO, "tag": "flat"},
	"pebble_b": {"rect": Rect2i(226, 167, 11, 8), "block": Vector2.ZERO, "tag": "flat"},
	"mushroom_red": {"rect": Rect2i(195, 81, 10, 14), "block": Vector2.ZERO, "tag": "mushroom"},
	"mushroom": {"rect": Rect2i(209, 83, 14, 12), "block": Vector2.ZERO, "tag": "mushroom"},
	"mushroom_s": {"rect": Rect2i(227, 84, 10, 11), "block": Vector2.ZERO, "tag": "mushroom"},
	"mushrooms": {"rect": Rect2i(246, 80, 20, 16), "block": Vector2.ZERO, "tag": "mushroom"},
	"mushroom_b": {"rect": Rect2i(275, 82, 12, 13), "block": Vector2.ZERO, "tag": "mushroom"},
	"log": {"rect": Rect2i(209, 98, 31, 14), "block": Vector2(28, 5), "tag": "wood"},
	"log_moss": {"rect": Rect2i(208, 113, 32, 15), "block": Vector2(28, 5), "tag": "wood"},
	"log_s": {"rect": Rect2i(144, 9, 16, 7), "block": Vector2.ZERO, "tag": "wood"},
	"stump": {"rect": Rect2i(195, 116, 11, 12), "block": Vector2(8, 4), "tag": "wood"},
	"stump_b": {"rect": Rect2i(57, 128, 22, 16), "block": Vector2(16, 5), "tag": "wood"},
	"crates_tuft": {"rect": Rect2i(4, 246, 26, 23), "block": Vector2(22, 7), "tag": "clutter"},
	"crate_stack": {"rect": Rect2i(37, 246, 22, 20), "block": Vector2(18, 6), "tag": "clutter"},
	"crate_open": {"rect": Rect2i(65, 226, 24, 14), "block": Vector2(22, 6), "tag": "clutter"},
	"crate": {"rect": Rect2i(65, 242, 24, 14), "block": Vector2(22, 6), "tag": "clutter"},
	"box": {"rect": Rect2i(65, 257, 15, 15), "block": Vector2(13, 5), "tag": "clutter"},
	"box_b": {"rect": Rect2i(81, 257, 15, 15), "block": Vector2(13, 5), "tag": "clutter"},
	"barrel": {"rect": Rect2i(55, 279, 18, 25), "block": Vector2(14, 6), "tag": "clutter"},
	"barrel_b": {"rect": Rect2i(87, 279, 18, 25), "block": Vector2(14, 6), "tag": "clutter"},
	"bucket": {"rect": Rect2i(99, 227, 11, 13), "block": Vector2.ZERO, "tag": "clutter"},
	"planter": {"rect": Rect2i(100, 245, 23, 20), "block": Vector2(20, 6), "tag": "clutter"},
	"mailbox": {"rect": Rect2i(130, 240, 12, 32), "block": Vector2(6, 4), "tag": "clutter"},
	"pot_plant": {"rect": Rect2i(115, 272, 12, 25), "block": Vector2(8, 4), "tag": "clutter"},
	"pot_plant_b": {"rect": Rect2i(131, 277, 11, 20), "block": Vector2(8, 4), "tag": "clutter"},
	"chest": {"rect": Rect2i(176, 274, 16, 14), "block": Vector2(14, 5), "tag": "clutter"},
	"scarecrow": {"rect": Rect2i(196, 240, 40, 48), "block": Vector2(8, 5), "tag": "scarecrow"},
	"wheat_bunch": {"rect": Rect2i(2, 306, 44, 29), "block": Vector2.ZERO, "tag": "plant"},
	"wheat_bunch_b": {"rect": Rect2i(48, 309, 31, 22), "block": Vector2.ZERO, "tag": "plant"},
	"wheat_bunch_c": {"rect": Rect2i(82, 308, 26, 23), "block": Vector2.ZERO, "tag": "plant"},
	"reeds": {"rect": Rect2i(129, 305, 31, 15), "block": Vector2.ZERO, "tag": "reed"},
	"reeds_b": {"rect": Rect2i(163, 309, 27, 20), "block": Vector2.ZERO, "tag": "reed"},
	"reeds_s": {"rect": Rect2i(145, 323, 15, 12), "block": Vector2.ZERO, "tag": "reed"},
	"cattail": {"rect": Rect2i(115, 317, 4, 19), "block": Vector2.ZERO, "tag": "reed"},
	"cattail_b": {"rect": Rect2i(121, 315, 4, 20), "block": Vector2.ZERO, "tag": "reed"},
	"sign": {"rect": Rect2i(144, 160, 16, 16), "block": Vector2(8, 4), "tag": "sign"},
	"sign_arrow": {"rect": Rect2i(160, 160, 16, 16), "block": Vector2(6, 4), "tag": "sign"},
	"sign_post": {"rect": Rect2i(144, 192, 16, 16), "block": Vector2(6, 4), "tag": "sign"},
	"hay": {"rect": Rect2i(1092, 498, 42, 28), "block": Vector2(36, 8), "tag": "hay"},
	"hay_big": {"rect": Rect2i(1088, 529, 48, 31), "block": Vector2(42, 9), "tag": "hay"},
	"hay_crate": {"rect": Rect2i(964, 488, 26, 19), "block": Vector2(24, 6), "tag": "clutter"},
	"trough": {"rect": Rect2i(948, 524, 26, 15), "block": Vector2(24, 6), "tag": "clutter"},
	"trough_water": {"rect": Rect2i(980, 524, 26, 15), "block": Vector2(24, 6), "tag": "clutter"},
	"stone_slab": {"rect": Rect2i(272, 112, 32, 16), "block": Vector2.ZERO, "tag": "flat"},
}

# Plateaus: a raised top (a 3 x 3 rim blob of one tone) over a rock face of
# two rows (the upper face row, then the foot row with grass tufts on
# transparent). Widened by repeating the middle column, deepened by
# repeating the middle top row. The cave: a three-wide face with a mouth.
const PLATEAU_TOPS := {"g": Vector2i(45, 0), "a": Vector2i(45, 6), "d": Vector2i(52, 6)}
const PLATEAU_FACE := Vector2i(45, 3) # three columns; the foot row is two rows down
const PLATEAU_FOOT := Vector2i(45, 5)
const PLATEAU_CAVE := Vector2i(36, 4) # three columns, two rows

# Fish (fishes.png): seven 16 px fish for the jumps.
const FISH: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]


## A crop stage's region in px on the crops sheet (tall stages take the
## cell above).
static func crop_rect(crop: String, stage: int) -> Rect2i:
	var st: Array = CROPS[crop][clampi(stage, 0, CROPS[crop].size() - 1)]
	var tall: bool = st.size() > 2
	return Rect2i(st[0] * 16, (st[1] - (1 if tall else 0)) * 16, 16, 32 if tall else 16)


# ---------------------------------------------------------------- seasons

# Autumn (farm_autumn.png): three grass tones, a pale (198, 172, 104),
# lawn g (177, 137, 77), dark d (147, 91, 55); no deep. Read the same way.
const AUTUMN_WANG := {
	"aaaa": [Vector2i(19, 0), Vector2i(20, 0), Vector2i(21, 0), Vector2i(22, 0), Vector2i(28, 4), Vector2i(28, 13), Vector2i(28, 19)],
	"aaae": [Vector2i(27, 21)],
	"aaag": [Vector2i(27, 0)],
	"aaas": [Vector2i(27, 15)],
	"aaea": [Vector2i(29, 21)],
	"aaee": [Vector2i(28, 20), Vector2i(28, 21)],
	"aaga": [Vector2i(29, 0)],
	"aagg": [Vector2i(28, 0), Vector2i(28, 5)],
	"aasa": [Vector2i(29, 15)],
	"aass": [Vector2i(28, 14), Vector2i(28, 15)],
	"aeaa": [Vector2i(27, 23)],
	"aeae": [Vector2i(29, 19), Vector2i(27, 22)],
	"aeee": [Vector2i(29, 20)],
	"agaa": [Vector2i(27, 2)],
	"agag": [Vector2i(27, 1), Vector2i(29, 4)],
	"aggg": [Vector2i(29, 5)],
	"asaa": [Vector2i(27, 17)],
	"asas": [Vector2i(29, 13), Vector2i(27, 16)],
	"asss": [Vector2i(29, 14)],
	"dddd": [Vector2i(23, 0), Vector2i(24, 0), Vector2i(25, 0), Vector2i(26, 0), Vector2i(31, 1), Vector2i(34, 13), Vector2i(34, 19)],
	"ddde": [Vector2i(33, 21)],
	"dddg": [Vector2i(30, 3)],
	"ddds": [Vector2i(33, 15)],
	"dded": [Vector2i(35, 21)],
	"ddee": [Vector2i(34, 20), Vector2i(34, 21)],
	"ddgd": [Vector2i(32, 3)],
	"ddgg": [Vector2i(31, 2), Vector2i(31, 3)],
	"ddsd": [Vector2i(35, 15)],
	"ddss": [Vector2i(34, 14), Vector2i(34, 15)],
	"dedd": [Vector2i(33, 23)],
	"dede": [Vector2i(35, 19), Vector2i(33, 22)],
	"deee": [Vector2i(35, 20)],
	"dgdd": [Vector2i(30, 5)],
	"dgdg": [Vector2i(32, 1), Vector2i(30, 4)],
	"dggg": [Vector2i(32, 2)],
	"dsdd": [Vector2i(33, 17)],
	"dsds": [Vector2i(35, 13), Vector2i(33, 16)],
	"dsss": [Vector2i(35, 14)],
	"eaaa": [Vector2i(29, 23)],
	"eaea": [Vector2i(27, 19), Vector2i(29, 22)],
	"eaee": [Vector2i(27, 20)],
	"eddd": [Vector2i(35, 23)],
	"eded": [Vector2i(33, 19), Vector2i(35, 22)],
	"edee": [Vector2i(33, 20)],
	"eeaa": [Vector2i(28, 18), Vector2i(28, 23)],
	"eeae": [Vector2i(29, 18)],
	"eedd": [Vector2i(34, 18), Vector2i(34, 23)],
	"eede": [Vector2i(35, 18)],
	"eeea": [Vector2i(27, 18)],
	"eeed": [Vector2i(33, 18)],
	"eeee": [Vector2i(28, 22), Vector2i(31, 22), Vector2i(34, 22)],
	"eeeg": [Vector2i(30, 18)],
	"eege": [Vector2i(32, 18)],
	"eegg": [Vector2i(31, 18), Vector2i(31, 23)],
	"egee": [Vector2i(30, 20)],
	"egeg": [Vector2i(30, 19), Vector2i(32, 22)],
	"eggg": [Vector2i(32, 23)],
	"gaaa": [Vector2i(29, 2)],
	"gaga": [Vector2i(29, 1), Vector2i(27, 4)],
	"gagg": [Vector2i(27, 5)],
	"gddd": [Vector2i(32, 5)],
	"gdgd": [Vector2i(30, 1), Vector2i(32, 4)],
	"gdgg": [Vector2i(30, 2)],
	"geee": [Vector2i(32, 20)],
	"gege": [Vector2i(32, 19), Vector2i(30, 22)],
	"gegg": [Vector2i(30, 23)],
	"ggaa": [Vector2i(28, 2), Vector2i(28, 3)],
	"ggag": [Vector2i(29, 3)],
	"ggdd": [Vector2i(31, 0), Vector2i(31, 5)],
	"ggdg": [Vector2i(32, 0)],
	"ggee": [Vector2i(31, 20), Vector2i(31, 21)],
	"ggeg": [Vector2i(32, 21)],
	"ggga": [Vector2i(27, 3)],
	"gggd": [Vector2i(30, 0)],
	"ggge": [Vector2i(30, 21)],
	"gggg": [Vector2i(19, 1), Vector2i(20, 1), Vector2i(21, 1), Vector2i(22, 1), Vector2i(28, 1), Vector2i(31, 4), Vector2i(31, 13), Vector2i(31, 19)],
	"gggs": [Vector2i(30, 15)],
	"ggsg": [Vector2i(32, 15)],
	"ggss": [Vector2i(31, 14), Vector2i(31, 15)],
	"gsgg": [Vector2i(30, 17)],
	"gsgs": [Vector2i(32, 13), Vector2i(30, 16)],
	"gsss": [Vector2i(32, 14)],
	"saaa": [Vector2i(29, 17)],
	"sasa": [Vector2i(27, 13), Vector2i(29, 16)],
	"sass": [Vector2i(27, 14)],
	"sddd": [Vector2i(35, 17)],
	"sdsd": [Vector2i(33, 13), Vector2i(35, 16)],
	"sdss": [Vector2i(33, 14)],
	"sggg": [Vector2i(32, 17)],
	"sgsg": [Vector2i(30, 13), Vector2i(32, 16)],
	"sgss": [Vector2i(30, 14)],
	"ssaa": [Vector2i(28, 12), Vector2i(28, 17)],
	"ssas": [Vector2i(29, 12)],
	"ssdd": [Vector2i(34, 12), Vector2i(34, 17)],
	"ssds": [Vector2i(35, 12)],
	"ssgg": [Vector2i(31, 12), Vector2i(31, 17)],
	"ssgs": [Vector2i(32, 12)],
	"sssa": [Vector2i(27, 12)],
	"sssd": [Vector2i(33, 12)],
	"sssg": [Vector2i(30, 12)],
	"ssss": [Vector2i(28, 16), Vector2i(31, 16), Vector2i(34, 16)],
}
# Winter (farm_winter.png): four snow tones, a white (217, 225, 233), lawn
# g the light blue (187, 210, 238) the pond banks are drawn on, dark d
# (140, 180, 229), deep x (104, 148, 218).
const WINTER_WANG := {
	"aaaa": [Vector2i(25, 4), Vector2i(25, 13), Vector2i(25, 19), Vector2i(25, 7)],
	"aaae": [Vector2i(24, 21)],
	"aaag": [Vector2i(24, 0)],
	"aaas": [Vector2i(24, 15)],
	"aaea": [Vector2i(26, 21)],
	"aaee": [Vector2i(25, 20), Vector2i(25, 21)],
	"aaga": [Vector2i(26, 0)],
	"aagg": [Vector2i(25, 0), Vector2i(25, 5)],
	"aasa": [Vector2i(26, 15)],
	"aass": [Vector2i(25, 14), Vector2i(25, 15)],
	"aeaa": [Vector2i(24, 23)],
	"aeae": [Vector2i(26, 19), Vector2i(24, 22)],
	"aeee": [Vector2i(26, 20)],
	"agaa": [Vector2i(24, 2)],
	"agag": [Vector2i(24, 1), Vector2i(26, 4)],
	"aggg": [Vector2i(26, 5)],
	"asaa": [Vector2i(24, 17)],
	"asas": [Vector2i(26, 13), Vector2i(24, 16)],
	"asss": [Vector2i(26, 14)],
	"dddd": [Vector2i(28, 1), Vector2i(31, 4), Vector2i(31, 13), Vector2i(31, 19), Vector2i(31, 7)],
	"ddde": [Vector2i(30, 21)],
	"dddg": [Vector2i(27, 3)],
	"ddds": [Vector2i(30, 15)],
	"dddx": [Vector2i(30, 0)],
	"dded": [Vector2i(32, 21)],
	"ddee": [Vector2i(31, 20), Vector2i(31, 21)],
	"ddgd": [Vector2i(29, 3)],
	"ddgg": [Vector2i(28, 2), Vector2i(28, 3)],
	"ddsd": [Vector2i(32, 15)],
	"ddss": [Vector2i(31, 14), Vector2i(31, 15)],
	"ddxd": [Vector2i(32, 0)],
	"ddxx": [Vector2i(31, 0), Vector2i(31, 5)],
	"dedd": [Vector2i(30, 23)],
	"dede": [Vector2i(32, 19), Vector2i(30, 22)],
	"deee": [Vector2i(32, 20)],
	"dgdd": [Vector2i(27, 5)],
	"dgdg": [Vector2i(29, 1), Vector2i(27, 4)],
	"dggg": [Vector2i(29, 2)],
	"dsdd": [Vector2i(30, 17)],
	"dsds": [Vector2i(32, 13), Vector2i(30, 16)],
	"dsss": [Vector2i(32, 14)],
	"dxdd": [Vector2i(30, 2)],
	"dxdx": [Vector2i(30, 1), Vector2i(32, 4)],
	"dxxx": [Vector2i(32, 5)],
	"eaaa": [Vector2i(26, 23)],
	"eaea": [Vector2i(24, 19), Vector2i(26, 22)],
	"eaee": [Vector2i(24, 20)],
	"eddd": [Vector2i(32, 23)],
	"eded": [Vector2i(30, 19), Vector2i(32, 22)],
	"edee": [Vector2i(30, 20)],
	"eeaa": [Vector2i(25, 18), Vector2i(25, 23)],
	"eeae": [Vector2i(26, 18)],
	"eedd": [Vector2i(31, 18), Vector2i(31, 23)],
	"eede": [Vector2i(32, 18)],
	"eeea": [Vector2i(24, 18)],
	"eeed": [Vector2i(30, 18)],
	"eeee": [Vector2i(25, 22), Vector2i(28, 22), Vector2i(31, 22), Vector2i(34, 22)],
	"eeeg": [Vector2i(27, 18)],
	"eeex": [Vector2i(33, 18)],
	"eege": [Vector2i(29, 18)],
	"eegg": [Vector2i(28, 18), Vector2i(28, 23)],
	"eexe": [Vector2i(35, 18)],
	"eexx": [Vector2i(34, 18), Vector2i(34, 23)],
	"egee": [Vector2i(27, 20)],
	"egeg": [Vector2i(27, 19), Vector2i(29, 22)],
	"eggg": [Vector2i(29, 23)],
	"exee": [Vector2i(33, 20)],
	"exex": [Vector2i(33, 19), Vector2i(35, 22)],
	"exxx": [Vector2i(35, 23)],
	"gaaa": [Vector2i(26, 2)],
	"gaga": [Vector2i(26, 1), Vector2i(24, 4)],
	"gagg": [Vector2i(24, 5)],
	"gddd": [Vector2i(29, 5)],
	"gdgd": [Vector2i(27, 1), Vector2i(29, 4)],
	"gdgg": [Vector2i(27, 2)],
	"geee": [Vector2i(29, 20)],
	"gege": [Vector2i(29, 19), Vector2i(27, 22)],
	"gegg": [Vector2i(27, 23)],
	"ggaa": [Vector2i(25, 2), Vector2i(25, 3)],
	"ggag": [Vector2i(26, 3)],
	"ggdd": [Vector2i(28, 0), Vector2i(28, 5)],
	"ggdg": [Vector2i(29, 0)],
	"ggee": [Vector2i(28, 20), Vector2i(28, 21)],
	"ggeg": [Vector2i(29, 21)],
	"ggga": [Vector2i(24, 3)],
	"gggd": [Vector2i(27, 0)],
	"ggge": [Vector2i(27, 21)],
	"gggg": [Vector2i(25, 1), Vector2i(28, 4), Vector2i(28, 13), Vector2i(28, 19), Vector2i(28, 7)],
	"gggs": [Vector2i(27, 15)],
	"ggsg": [Vector2i(29, 15)],
	"ggss": [Vector2i(28, 14), Vector2i(28, 15)],
	"gsgg": [Vector2i(27, 17)],
	"gsgs": [Vector2i(29, 13), Vector2i(27, 16)],
	"gsss": [Vector2i(29, 14)],
	"saaa": [Vector2i(26, 17)],
	"sasa": [Vector2i(24, 13), Vector2i(26, 16)],
	"sass": [Vector2i(24, 14)],
	"sddd": [Vector2i(32, 17)],
	"sdsd": [Vector2i(30, 13), Vector2i(32, 16)],
	"sdss": [Vector2i(30, 14)],
	"sggg": [Vector2i(29, 17)],
	"sgsg": [Vector2i(27, 13), Vector2i(29, 16)],
	"sgss": [Vector2i(27, 14)],
	"ssaa": [Vector2i(25, 12), Vector2i(25, 17)],
	"ssas": [Vector2i(26, 12)],
	"ssdd": [Vector2i(31, 12), Vector2i(31, 17)],
	"ssds": [Vector2i(32, 12)],
	"ssgg": [Vector2i(28, 12), Vector2i(28, 17)],
	"ssgs": [Vector2i(29, 12)],
	"sssa": [Vector2i(24, 12)],
	"sssd": [Vector2i(30, 12)],
	"sssg": [Vector2i(27, 12)],
	"ssss": [Vector2i(25, 16), Vector2i(28, 16), Vector2i(31, 16), Vector2i(34, 16)],
	"sssx": [Vector2i(33, 12)],
	"ssxs": [Vector2i(35, 12)],
	"ssxx": [Vector2i(34, 12), Vector2i(34, 17)],
	"sxss": [Vector2i(33, 14)],
	"sxsx": [Vector2i(33, 13), Vector2i(35, 16)],
	"sxxx": [Vector2i(35, 17)],
	"xddd": [Vector2i(32, 2)],
	"xdxd": [Vector2i(32, 1), Vector2i(30, 4)],
	"xdxx": [Vector2i(30, 5)],
	"xeee": [Vector2i(35, 20)],
	"xexe": [Vector2i(35, 19), Vector2i(33, 22)],
	"xexx": [Vector2i(33, 23)],
	"xsss": [Vector2i(35, 14)],
	"xsxs": [Vector2i(35, 13), Vector2i(33, 16)],
	"xsxx": [Vector2i(33, 17)],
	"xxdd": [Vector2i(31, 2), Vector2i(31, 3)],
	"xxdx": [Vector2i(32, 3)],
	"xxee": [Vector2i(34, 20), Vector2i(34, 21)],
	"xxex": [Vector2i(35, 21)],
	"xxss": [Vector2i(34, 14), Vector2i(34, 15)],
	"xxsx": [Vector2i(35, 15)],
	"xxxd": [Vector2i(30, 3)],
	"xxxe": [Vector2i(33, 21)],
	"xxxs": [Vector2i(33, 15)],
	"xxxx": [Vector2i(31, 1), Vector2i(34, 13), Vector2i(34, 19), Vector2i(34, 7)],
}

# What each season draws where it differs from spring and summer (the
# constants above). Sheets rearrange their groups, so every group was found
# again on the season's sheet by matching its shape (alpha and luminance);
# pieces with no sure match are left out of that season.
const SEASONS := {
	"summer": {},
	"autumn": {
		"sheet": "tilesets/farm_autumn",
		"wang": AUTUMN_WANG,
		"open": [Vector2i(13, 19)],
		"plots": {"dry": {"at": Vector2i(36, 14), "col": 39, "row": 17}, "wet": {"at": Vector2i(48, 14), "col": 51, "row": 17},
			"ragged": {"at": Vector2i(48, 18), "col": 51, "row": 21}},
		"blobs": {"hedge": Vector2i(22, 5), "tall": Vector2i(22, 9), "wheat": Vector2i(22, 9)},
		"sprouts": [Vector2i(19, 2), Vector2i(20, 2), Vector2i(21, 2), Vector2i(22, 2), Vector2i(23, 2), Vector2i(24, 2), Vector2i(19, 3), Vector2i(20, 3), Vector2i(21, 3), Vector2i(22, 3)],
		"sprouts_dark": [Vector2i(23, 3), Vector2i(24, 3), Vector2i(26, 2)],
		"flowers": [Vector2i(19, 4), Vector2i(20, 4), Vector2i(21, 4), Vector2i(22, 4), Vector2i(23, 4), Vector2i(24, 4)],
		"tufts": [Vector2i(25, 3), Vector2i(26, 3)],
		"plateau_tops": {"g": Vector2i(42, 0), "a": Vector2i(42, 6), "d": Vector2i(53, 0)},
		"plateau_face": Vector2i(42, 3), "plateau_foot": Vector2i(42, 5), "plateau_cave": Vector2i(33, 4),
		"props": {"bush_pine": Rect2i(179, 129, 26, 31), "hay": Rect2i(980, 402, 42, 28), "hay_big": Rect2i(1024, 401, 48, 31),
			"hay_crate": Rect2i(980, 312, 26, 19), "trough": Rect2i(964, 348, 26, 15), "trough_water": Rect2i(996, 348, 26, 15)},
		"no_props": ["bush_b", "crate_open", "crate", "box", "box_b"],
		"buildings": {"farmhouse": Vector2i(960, 208), "farmhouse_b": Vector2i(1056, 208), "manor": Vector2i(960, 96), "barn": Vector2i(848, 352),
			"greenhouse": Vector2i(768, 464)},
		"windmill": "windmill animations/windmill_autumn-Sheet",
		"greenhouse_room": Rect2i(48, 34, 11, 12),
		"tree_dir": "tree animations/autumn/trees_cut_down/",
		"trees": {
			"oak": {"sheet": "basic/tree_basic1_autumn-Sheet", "falling": ""},
			"oak_b": {"sheet": "basic/tree_basic2_autumn-Sheet", "falling": "basic/basic_autumn_leaves_falling-Sheet"},
			"elm": {"sheet": "basic/tree_basic3_autumn-Sheet", "falling": ""},
			"elm_b": {"sheet": "basic/tree_basic4_autumn-Sheet", "falling": ""},
			"pine": {"sheet": "basic/tree_pine_autumn-Sheet", "falling": ""},
			"oak_bare": {"sheet": "basic/tree_basic1_autumn_no_leaves-Sheet", "falling": ""},
			"oak_dead": {"sheet": "basic/tree_basic1_autumn_dead-Sheet", "falling": ""},
			"elm_dead": {"sheet": "basic/tree_basic3_autumn_dead-Sheet", "falling": ""},
			"apple": {"sheet": "fruit trees/apple/tree_apple_autumn-Sheet", "falling": "fruit trees/apple/apple_leaves_falling_autumn-Sheet"},
			"apple_fruit": {"sheet": "fruit trees/apple/tree_apple_autumn_fruits-Sheet", "falling": "fruit trees/apple/apple_leaves_falling_autumn-Sheet"},
			"apple_flowers": {"sheet": "fruit trees/apple/tree_apple_autumn_flowers-Sheet", "falling": "fruit trees/apple/apple_leaves_falling_autumn-Sheet"},
			"cherry": {"sheet": "fruit trees/cherry/tree_cherry_autumn-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling_autumn-Sheet"},
			"cherry_bloom": {"sheet": "fruit trees/cherry/tree_cherry_autumn_bloom-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling_autumn-Sheet", "petals": true},
			"cherry_fruit": {"sheet": "fruit trees/cherry/tree_cherry_autumn_fruits-Sheet", "falling": "fruit trees/cherry/cherry_leaves_falling_autumn-Sheet"},
			"orange": {"sheet": "fruit trees/orange/tree_orange_autumn-Sheet", "falling": "fruit trees/orange/orange_leaves_falling_autumn-Sheet"},
			"orange_fruit": {"sheet": "fruit trees/orange/tree_orange_autumn_fruits-Sheet", "falling": "fruit trees/orange/orange_leaves_falling_autumn-Sheet"},
			"orange_flowers": {"sheet": "fruit trees/orange/tree_orange_autumn_flowers-Sheet", "falling": "fruit trees/orange/orange_leaves_falling_autumn-Sheet"},
			"peach": {"sheet": "fruit trees/peach/tree_peach_autumn-Sheet", "falling": "fruit trees/peach/peach_leaves_falling_autumn-Sheet"},
			"peach_fruit": {"sheet": "fruit trees/peach/tree_peach_autumn_fruits-Sheet", "falling": "fruit trees/peach/peach_leaves_falling_autumn-Sheet"},
			"peach_flowers": {"sheet": "fruit trees/peach/tree_peach_autumn_flowers-Sheet", "falling": "fruit trees/peach/peach_leaves_falling_autumn-Sheet"},
		},
		"wind_leaves": {
			"basic": "tree animations/autumn/leaves_wind/leaves_wind_basic_spritesheet_autumn",
			"apple": "tree animations/autumn/leaves_wind/leaves_apple_autumn_Sheet",
			"cherry": "tree animations/autumn/leaves_wind/leaves_cherry_autumn_Sheet",
			"cherry_bloom": "tree animations/autumn/leaves_wind/flowers_cherry_autumn_Sheet",
			"orange": "tree animations/autumn/leaves_wind/leaves_orange_autumn_Sheet",
			"peach": "tree animations/autumn/leaves_wind/leaves_peach_autumn_Sheet",
		},
	},
	"winter": {
		"sheet": "tilesets/farm_winter",
		"wang": WINTER_WANG,
		"water_origin": Vector2i(0, 23),
		"open": [Vector2i(0, 21)],
		"plots": {"dry": {"at": Vector2i(37, 14), "col": 40, "row": 17}, "wet": {"at": Vector2i(49, 14), "col": 52, "row": 17},
			"ragged": {"at": Vector2i(49, 18), "col": 52, "row": 21}},
		"blobs": {},
		"fence": {"plain": Vector2i(13, 11), "grassy": Vector2i(13, 11)},
		"sprouts": [Vector2i(15, 18), Vector2i(15, 19)],
		"sprouts_dark": [Vector2i(15, 18), Vector2i(15, 19)],
		"flowers": [],
		"tufts": [],
		"plateau_tops": {"g": Vector2i(42, 0), "a": Vector2i(53, 0), "d": Vector2i(42, 6)},
		"plateau_face": Vector2i(42, 3), "plateau_foot": Vector2i(42, 4), "plateau_cave": Vector2i(36, 2),
		"props": {"dead_tree_big": Rect2i(115, 152, 49, 71), "bush": Rect2i(96, 288, 32, 32), "bush_pine": Rect2i(131, 289, 26, 31),
			"rock": Rect2i(162, 237, 29, 19), "rock_b": Rect2i(130, 240, 26, 16), "rock_big": Rect2i(97, 234, 29, 22),
			"log": Rect2i(161, 258, 31, 14), "log_s": Rect2i(160, 57, 16, 7), "stump": Rect2i(259, 132, 11, 12), "stump_b": Rect2i(73, 128, 22, 16),
			"crate_stack": Rect2i(5, 230, 22, 20), "barrel": Rect2i(39, 279, 18, 25), "barrel_b": Rect2i(71, 279, 18, 25),
			"bucket": Rect2i(291, 211, 11, 13), "planter": Rect2i(132, 261, 23, 20), "mailbox": Rect2i(258, 208, 12, 32),
			"pot_plant": Rect2i(99, 256, 12, 25), "pot_plant_b": Rect2i(115, 261, 11, 20), "chest": Rect2i(288, 194, 16, 14),
			"scarecrow": Rect2i(164, 288, 40, 48), "reeds": Rect2i(177, 353, 31, 15), "reeds_b": Rect2i(147, 357, 27, 20),
			"reeds_s": Rect2i(177, 371, 15, 12), "cattail": Rect2i(211, 365, 4, 19), "cattail_b": Rect2i(217, 363, 4, 20),
			"sign": Rect2i(176, 192, 16, 16), "sign_arrow": Rect2i(192, 192, 16, 16), "sign_post": Rect2i(192, 176, 16, 16),
			"hay": Rect2i(804, 418, 42, 28), "hay_big": Rect2i(800, 449, 48, 31), "trough": Rect2i(708, 508, 26, 15), "trough_water": Rect2i(740, 508, 26, 15)},
		"no_props": ["bush_b", "pebble", "pebble_b", "mushroom_red", "mushroom", "mushroom_s", "mushrooms", "mushroom_b", "log_moss",
			"crates_tuft", "wheat_bunch", "wheat_bunch_b", "wheat_bunch_c", "hay_crate", "stone_slab"],
		# Winter's own: snow drifts and lumps (flat), snow-capped rocks.
		"new_props": {
			"snow_drift": {"rect": Rect2i(208, 265, 32, 18), "block": Vector2.ZERO, "tag": "flat"},
			"snow_drift_b": {"rect": Rect2i(208, 297, 32, 18), "block": Vector2.ZERO, "tag": "flat"},
			"snow_lump": {"rect": Rect2i(257, 277, 14, 10), "block": Vector2.ZERO, "tag": "flat"},
			"snow_lump_b": {"rect": Rect2i(257, 292, 14, 11), "block": Vector2.ZERO, "tag": "flat"},
			"snow_lump_c": {"rect": Rect2i(257, 309, 14, 10), "block": Vector2.ZERO, "tag": "flat"},
			"rock_snow": {"rect": Rect2i(194, 237, 29, 19), "block": Vector2(24, 7), "tag": "stone"},
			"rock_snow_b": {"rect": Rect2i(226, 240, 26, 16), "block": Vector2(22, 6), "tag": "stone"},
		},
		"buildings": {"farmhouse": Vector2i(704, 368), "farmhouse_b": Vector2i(704, 368), "manor": Vector2i(592, 352), "barn": Vector2i(576, 464),
			"greenhouse": Vector2i(976, 96)},
		"windmill": "windmill animations/windmill_winter-Sheet",
		"gate": "fence gate animations/gate_winter-Sheet",
		"greenhouse_room": Rect2i(61, 11, 11, 12),
		"crops": false,
		"tree_dir": "tree animations/winter/trees_cut_down/",
		"trees": {
			"oak": {"sheet": "basic trees/tree_basic1_winter-Sheet", "falling": ""},
			"oak_b": {"sheet": "basic trees/tree_basic2_winter-Sheet", "falling": ""},
			"elm": {"sheet": "basic trees/tree_basic3_winter-Sheet", "falling": ""},
			"elm_b": {"sheet": "basic trees/tree_basic4_winter-Sheet", "falling": ""},
			"pine": {"sheet": "basic trees/tree_pine_snow_winter-Sheet", "falling": ""},
			"pine_b": {"sheet": "basic trees/tree_pine_winter-Sheet", "falling": ""},
			"oak_bare": {"sheet": "basic trees/tree_basic1_winter_no_leaves-Sheet", "falling": ""},
			"oak_dead": {"sheet": "basic trees/tree_basic1_winter_dead-Sheet", "falling": ""},
			"elm_dead": {"sheet": "basic trees/tree_basic3_winter_dead-Sheet", "falling": ""},
			"apple": {"sheet": "fruit trees/tree_apple_winter-Sheet", "falling": ""},
			"cherry": {"sheet": "fruit trees/tree_cherry_winter-Sheet", "falling": ""},
			"orange": {"sheet": "fruit trees/tree_orange_winter-Sheet", "falling": ""},
			"peach": {"sheet": "fruit trees/tree_peach_winter-Sheet", "falling": ""},
		},
		"tree_sets": {
			"wild": ["oak", "oak_b", "elm", "elm_b", "pine", "oak"],
			"pines": ["pine", "pine", "pine_b", "pine", "elm_b"],
			"old": ["oak_dead", "elm_dead", "oak_bare", "oak", "pine_b"],
			"orchard": ["apple", "cherry", "orange", "peach"],
		},
		"wind_leaves": {"basic": "tree animations/winter/leaves_wind/leaves_wind_winter_Sheet"},
	},
}


## A season's value for `key`, else the spring and summer one.
static func get_for(season: String, key: String) -> Variant:
	var s: Dictionary = SEASONS.get(season, {})
	if s.has(key):
		return s[key]
	match key:
		"sheet": return SHEET
		"wang": return WANG
		"water_origin": return Vector2i(0, 21)
		"open": return WATER_OPEN
		"plots": return PLOTS
		"blobs": return BLOB_BASE
		"fence": return FENCE
		"sprouts": return SPROUTS
		"sprouts_dark": return SPROUTS_DARK
		"flowers": return FLOWERS
		"tufts": return TUFTS
		"plateau_tops": return PLATEAU_TOPS
		"plateau_face": return PLATEAU_FACE
		"plateau_foot": return PLATEAU_FOOT
		"plateau_cave": return PLATEAU_CAVE
		"windmill": return BUILDINGS.windmill.anim
		"gate": return GATE_SHEET
		"greenhouse_room": return GREENHOUSE_ROOM
		"crops": return true
		"tree_dir": return TREE_DIR
		"trees": return TREES
		"tree_sets": return TREE_SETS
		"wind_leaves": return WIND_LEAVES
	return null


## A prop's data in a season ({} when the season's sheet has none).
static func prop(season: String, art: String) -> Dictionary:
	var s: Dictionary = SEASONS.get(season, {})
	if art in s.get("no_props", []):
		return {}
	if s.get("new_props", {}).has(art):
		return s.new_props[art]
	if not PROPS.has(art):
		return {}
	var p: Dictionary = PROPS[art]
	if s.get("props", {}).has(art):
		p = p.duplicate()
		p.rect = s.props[art]
	return p


## A building's region on a season's sheet (spring's, moved).
static func building_region(season: String, kind: String) -> Rect2i:
	var r: Rect2i = BUILDINGS[kind].region
	var moved: Dictionary = SEASONS.get(season, {}).get("buildings", {})
	if moved.has(kind):
		return Rect2i(moved[kind], r.size)
	return r


## A tree kind a season has (winter's fruit trees are bare: every fruit
## variant becomes the plain winter tree of its kind).
static func tree_art(season: String, art: String) -> String:
	var trees: Dictionary = get_for(season, "trees")
	if trees.has(art):
		return art
	for k in ["apple", "cherry", "orange", "peach"]:
		if art.begins_with(k) and trees.has(k):
			return k
	if art.begins_with("pine") and trees.has("pine"):
		return "pine"
	return "oak"
