class_name PaintedTerrain
extends RefCounted
## Painted Lands map grid (AGENTS.md § Painted Lands) on TILESET_brighter.png.
## Output is atlas coordinates, dirt-blob descriptions, and prop placements.
## Never calls terrain.gd and never uses plains.png.

const WIDTH := 60
const HEIGHT := 40
const ATTEMPTS := 60

# recipe = seed % 20. `houses` lists prefab ids. `water`: P pond, P2 two
# ponds, WP water plants, WR water rocks. `height`: F fence yard, G gate
# line, C plateau, "F between" a fence run between house and pond.
const RECIPES := [
	{"name": "Pastoral", "houses": [0], "water": "P+WP+WR", "height": "F", "path": "trunk + L", "patch": ["R", 2, 3], "props": ["bushes", "LR", "T"], "signs": 1},
	{"name": "Crossroads", "houses": [1], "water": "P if room+WP", "height": "", "path": "2 trunks 90", "patch": ["I", 2, 3], "props": ["bushes", "LR", "T"], "signs": 2},
	{"name": "Pond walk", "houses": [2], "water": "P+WP+WR", "height": "", "path": "skirts shore", "patch": ["R", 2, 2], "props": ["bushes"], "signs": 1},
	{"name": "Garden", "houses": [3], "water": "S if room", "height": "F+G", "path": "through gate", "patch": ["R", 2, 2], "props": ["bushes", "LR", "T"], "signs": 2},
	{"name": "Lookout", "houses": [0], "water": "S if room", "height": "C", "path": "to plateau foot", "patch": ["I", 2, 2], "props": ["LR obstacles", "CF", "T"], "signs": 1},
	{"name": "Open meadow", "houses": [], "water": "", "height": "", "path": "edge-to-edge", "patch": ["R", 3, 4], "props": ["bushes", "LR"], "signs": 0},
	{"name": "Twin water", "houses": [1], "water": "P2+WP+WR", "height": "", "path": "between blobs", "patch": ["R", 1, 2], "props": [], "signs": 1},
	{"name": "South road", "houses": [2], "water": "S if room", "height": "", "path": "south third", "patch": ["I", 2, 3], "props": ["bushes", "CF", "T"], "signs": 0},
	{"name": "Shore spur", "houses": [3], "water": "P+WP+WR", "height": "", "path": "trunk + spur", "patch": ["R", 2, 2], "props": ["T"], "signs": 2},
	{"name": "Three-way", "houses": [0], "water": "P if room+WP", "height": "", "path": "+2 branches 90", "patch": ["I", 2, 3], "props": ["bushes", "LR", "T"], "signs": 3},
	{"name": "West hamlet", "houses": [1, 3], "water": "P+WP", "height": "F", "path": "from east, L", "patch": ["RI", 2, 2], "props": ["CF", "T"], "signs": 2},
	{"name": "East hamlet", "houses": [2], "water": "P+WR", "height": "F", "path": "from west, L", "patch": ["R", 2, 2], "props": ["T", "bushes"], "signs": 1},
	{"name": "Wild lane", "houses": [], "water": "moisture P", "height": "", "path": "1 trunk", "patch": ["I", 3, 4], "props": ["bushes", "LR obstacles"], "signs": 0},
	{"name": "Orchard", "houses": [3], "water": "P if room+WP", "height": "", "path": "short trunk", "patch": ["R", 2, 2], "props": ["bushes heavy", "T"], "signs": 1},
	{"name": "Shore hamlet", "houses": [0], "water": "P+WP+WR", "height": "F between", "path": "short trunk", "patch": ["R", 1, 2], "props": ["CF", "T"], "signs": 2},
	{"name": "Double lean", "houses": [1], "water": "P if room+WP", "height": "", "path": "two L", "patch": ["I", 2, 3], "props": ["LR", "T"], "signs": 1},
	{"name": "Below the rim", "houses": [2], "water": "S if room", "height": "C", "path": "lawn south of plateau", "patch": ["I", 2, 2], "props": ["LR", "T"], "signs": 1},
	{"name": "Gate road", "houses": [3], "water": "S if room", "height": "G", "path": "through gate", "patch": ["R", 2, 2], "props": ["T"], "signs": 2},
	{"name": "Sparse wild", "houses": [], "water": "P if blob", "height": "", "path": "1 trunk", "patch": ["I", 1, 2], "props": ["LR"], "signs": 0},
	{"name": "Switchback", "houses": [0], "water": "S if room", "height": "", "path": "U of two 90", "patch": ["RI", 2, 2], "props": ["bushes", "CF"], "signs": 1},
	# Recipes past the original twenty use the cliff kit, the extra
	# buildings, and the camp props.
	{"name": "Cave mouth", "houses": [], "water": "S if room", "height": "C", "path": "to the cave", "patch": ["I", 2, 3], "props": ["bushes", "LR", "T"], "signs": 1, "top": "light", "cave": true},
	{"name": "Terraces", "houses": [3], "water": "S if room", "height": "C2", "path": "along the terraces", "patch": ["RI", 2, 2], "props": ["bushes", "LR", "CF", "T"], "signs": 1},
	{"name": "Stone ruins", "houses": [], "water": "S if room", "height": "C", "path": "to the ramp", "patch": ["I", 1, 2], "props": ["LR obstacles", "outcrops", "ruins", "T"], "signs": 2, "top": "stone"},
	{"name": "Woodcutter camp", "houses": [4, 5], "water": "S if room", "height": "F", "path": "trunk + spur", "patch": ["I", 2, 2], "props": ["CF big", "logs heavy"], "signs": 1},
	{"name": "Rock garden", "houses": [], "water": "P+WP+WR", "height": "", "path": "edge + L", "patch": ["R", 2, 3], "props": ["outcrops", "bushes"], "signs": 0},
	{"name": "Deep forest", "houses": [], "water": "S if room", "height": "", "path": "1 trunk", "patch": ["I", 1, 2], "props": ["canopy", "logs heavy", "bushes"], "signs": 1, "tones": [0.45, 0.24, 0.12]},
	{"name": "Village square", "houses": [0, 1, 2], "water": "S if room", "height": "", "path": "plaza + 2 trunks", "patch": ["R", 1, 2], "props": ["T"], "signs": 3},
	{"name": "Hedge garden", "houses": [2], "water": "S if room", "height": "F+G", "path": "through gate", "patch": ["R", 2, 2], "props": ["hedges heavy", "carpets heavy", "T"], "signs": 1},
	# Rock ridges: a low rock wall with a rim above and below and rounded
	# caps where it stops, so a gap between two segments is a pass.
	{"name": "Ridgeline", "houses": [1], "water": "S if room", "height": "R", "path": "through the pass", "patch": ["I", 2, 3], "props": ["bushes", "LR", "T"], "signs": 1},
	{"name": "Walled mesa", "houses": [], "water": "S if room", "height": "C+R", "path": "to the mesa", "patch": ["R", 1, 2], "props": ["LR", "outcrops", "T"], "signs": 1},
]

# FLAT_GRASS: one plain cell and three quiet speckles.
const LAWN := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
const LAWN_FLOWERS := Vector2i(0, 17) # lawn with a tuft and small flowers, used sparingly
const TUFTS := [Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(6, 5), Vector2i(7, 5)]
const FLOWERS := [Vector2i(8, 2), Vector2i(9, 2), Vector2i(10, 2), Vector2i(8, 3), Vector2i(9, 3), Vector2i(10, 3), Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 5),
	Vector2i(8, 4), Vector2i(9, 4), Vector2i(8, 6), Vector2i(9, 6), Vector2i(10, 6), Vector2i(8, 7), Vector2i(9, 7)]
# Deco for the dark and deep grass zones: the darkest sprouts.
const DARK_TUFTS := [Vector2i(5, 4), Vector2i(6, 4), Vector2i(7, 4), Vector2i(5, 5)]
# A 3x3 carpet of small white and lavender flowers, placed whole on lawn.
const FLOWER_CARPET := Vector2i(5, 6)

# Grass tone zones, lightest to darkest. Each level is a 3x3 blob set on
# transparent with dithered, rounded edges, its transparent-hole ring for
# inner corners, and flat fills of the same green (plain plus speckles).
# Level 0 sits on the lawn; each deeper level sits inside the one before.
const TONES := [
	{"name": "mid", "blob": Vector2i(12, 6), "ring": Vector2i(12, 9), "fills": [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)], "cover": 0.30},
	{"name": "dark", "blob": Vector2i(15, 6), "ring": Vector2i(15, 9), "fills": [Vector2i(8, 1), Vector2i(9, 1), Vector2i(10, 1), Vector2i(11, 1)], "cover": 0.10},
	{"name": "deep", "blob": Vector2i(18, 6), "ring": Vector2i(18, 9), "fills": [Vector2i(8, 0), Vector2i(9, 0), Vector2i(10, 0), Vector2i(11, 0)], "cover": 0.035},
]
const FLIP_H := 1
const FLIP_V := 2
# Grass accents: small blobs of the next darker tone on ground that is
# exactly the tone baked into the cell (rows 0-2), with hole rings (rows
# 3-5) for inner corners and ring-shaped accents. `on` is the ground level
# the accent needs (-1 plain lawn, 0 pure mid, 1 pure dark).
const ACCENTS := [
	{"blob": Vector2i(12, 0), "ring": Vector2i(12, 3), "on": -1},
	{"blob": Vector2i(15, 0), "ring": Vector2i(15, 3), "on": 0},
	{"blob": Vector2i(18, 0), "ring": Vector2i(18, 3), "on": 1},
]
# The tone fills with a tuft of the next lighter green, used sparingly.
const TONE_TUFTS := [Vector2i(11, 15), Vector2i(11, 21)]

# Neighbor bits N=1 E=2 S=4 W=8 -> role in a 3x3 set (offset from its NW).
const ROLES := {
	15: Vector2i(1, 1), 14: Vector2i(1, 0), 11: Vector2i(1, 2), 7: Vector2i(0, 1), 13: Vector2i(2, 1),
	6: Vector2i(0, 0), 12: Vector2i(2, 0), 3: Vector2i(0, 2), 9: Vector2i(2, 2),
}
const NONE := Vector2i(-1, -1)

# Cobble PATH, AGENTS.md table. Open-diagonal bits NE=1 SE=2 SW=4 NW=8.
const PATH_SET := Vector2i(21, 0)
const PATH_FILL := Vector2i(22, 1)
# Sand fills for wide paved areas (a plaza's interior).
const PATH_FILLS := [Vector2i(22, 1), Vector2i(33, 0), Vector2i(34, 0), Vector2i(33, 1), Vector2i(34, 1)]
const PATH_INNER := {1: Vector2i(21, 5), 2: Vector2i(21, 3), 4: Vector2i(23, 3), 8: Vector2i(23, 5)}

# PATCH dirt islands: set A has transparent grass (Mode A), set B keeps
# its baked mid green (Mode B halo).
const PATCH_SET_A := Vector2i(30, 0)
const PATCH_SET_B := Vector2i(24, 0)
const PATCH_INNER_A := {2: Vector2i(31, 3), 4: Vector2i(32, 3), 1: Vector2i(31, 4), 8: Vector2i(32, 4)}
const PATCH_INNER_B := {2: Vector2i(24, 3), 4: Vector2i(26, 3), 1: Vector2i(24, 5), 8: Vector2i(26, 5)}
# The same dirt on the dark tone. Its baked grass is exactly the dark fill,
# as set B's is exactly the mid fill, so inside a zone they need no halo.
const PATCH_SET_D := Vector2i(27, 0)
const PATCH_INNER_D := {2: Vector2i(27, 3), 4: Vector2i(29, 3), 1: Vector2i(27, 5), 8: Vector2i(29, 5)}

# Ragged (worn, speckled) dirt, the same 3x3 layout in rows 6-8 with inner
# corners in rows 9-10. Irregular islands use these.
const RAGGED_SET_A := Vector2i(30, 6)
const RAGGED_SET_L := Vector2i(21, 6) # baked lawn green: plain tiles on plain lawn
const RAGGED_INNER_L := {2: Vector2i(22, 9), 4: Vector2i(23, 9), 1: Vector2i(22, 10), 8: Vector2i(23, 10)}
const RAGGED_SET_B := Vector2i(24, 6)
const RAGGED_SET_D := Vector2i(27, 6)
const RAGGED_INNER_A := {2: Vector2i(31, 9), 4: Vector2i(32, 9), 1: Vector2i(31, 10), 8: Vector2i(32, 10)}
const RAGGED_INNER_B := {2: Vector2i(25, 9), 4: Vector2i(26, 9), 1: Vector2i(25, 10), 8: Vector2i(26, 10)}
const RAGGED_INNER_D := {2: Vector2i(28, 9), 4: Vector2i(29, 9), 1: Vector2i(28, 10), 8: Vector2i(29, 10)}

# Hedges: dark and light 3x3 hedge blobs on transparent, with hole rings
# for inner corners. Hedgerows are two cells thick.
const HEDGE_SETS := [
	{"blob": Vector2i(0, 1), "inner": {2: Vector2i(3, 1), 4: Vector2i(4, 1), 1: Vector2i(3, 2), 8: Vector2i(4, 2), 5: Vector2i(2, 4), 10: Vector2i(3, 4)}},
	{"blob": Vector2i(0, 5), "inner": {2: Vector2i(3, 5), 4: Vector2i(4, 5), 1: Vector2i(3, 6), 8: Vector2i(4, 6), 5: Vector2i(2, 8), 10: Vector2i(3, 8)}},
]
const ROUND_SHAPES := [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(4, 2), Vector2i(2, 4)]

# Pond: 3x3 water set with shore on transparent, plus inner corners. The
# sheet repeats the set four times, three columns apart, with the shore a
# little wider each time (35, 38, 41, 44): those are the animation frames.
# Terrain writes frame 0; the painter animates it.
const WATER_SET := Vector2i(35, 0)
const WATER_INNER := {8: Vector2i(35, 3), 1: Vector2i(36, 3), 4: Vector2i(35, 4), 2: Vector2i(36, 4)}
const WATER_FRAMES := 4
const WATER_FRAME_STEP := 3
const WATER_FRAME_REGION := Rect2i(35, 0, 3, 5)
# Deep water: a 3x3 deep-on-shallow set whose shallow part is the pond fill.
const DEEP_SET := Vector2i(36, 6)
const LAKE_CHANCE := 0.6
# Open-water surfaces: four scrolling frames each, one column apart.
const SHALLOW_SURFACE := Vector2i(47, 0)
const DEEP_SURFACE := Vector2i(47, 1)
# Seamless deep fill (the plus-shaped block beside the deep set).
# The shallow frame drawn around the deep set on the sheet: plain pond
# fill, used for open water right beside a deep pool.
const SHALLOW_FRAME := [Vector2i(35, 5), Vector2i(36, 5), Vector2i(37, 5), Vector2i(38, 5), Vector2i(39, 5),
	Vector2i(35, 6), Vector2i(39, 6), Vector2i(35, 7), Vector2i(39, 7), Vector2i(35, 8), Vector2i(39, 8),
	Vector2i(35, 9), Vector2i(36, 9), Vector2i(37, 9), Vector2i(38, 9), Vector2i(39, 9)]
const DEEP_FILLS := [Vector2i(41, 5), Vector2i(42, 5), Vector2i(40, 6), Vector2i(41, 6), Vector2i(42, 6), Vector2i(43, 6),
	Vector2i(40, 7), Vector2i(41, 7), Vector2i(42, 7), Vector2i(43, 7), Vector2i(41, 8), Vector2i(42, 8)]

# Plateau: 3x3 rim over the top, then a three-row south face.
const PLATEAU_SET := Vector2i(4, 12)
const PLATEAU_FACE_ROW := 15
const FACE_ROWS := 3
# The cliff kit comes in four tones. Each has a 3x3 top (rim over grass or
# stone) and a 4x4 ramp: a two-wide gap through the face, rim row first.
# Faces are the shared rock at (4-6, 15-17). Ramps are used only on light
# and stone tops: a mid or dark ramp would carry its green straight into
# the light lawn at the foot. Mid and dark tops use stairs.
const PLATEAU_TOPS := {"light": Vector2i(4, 12), "mid": Vector2i(15, 12), "dark": Vector2i(15, 18), "stone": Vector2i(15, 24)}
const RAMPS := {"light": Vector2i(0, 12), "mid": Vector2i(11, 12), "dark": Vector2i(11, 18), "stone": Vector2i(11, 24)}
const RAMP_WIDTH := 4
const CAVE := Vector2i(7, 18) # 3x3 cave mouth for the face; its bottom middle is open
const VINE_FACES := [Vector2i(0, 18), Vector2i(1, 18)] # face columns overgrown with vines, rows 18-20
const FACE_SETS := [Vector2i(4, 15), Vector2i(2, 18)] # two rock faces (left, middle, right x top, middle, bottom)
const ROCK_FILLS := [Vector2i(2, 16), Vector2i(3, 16)] # plain rock, a middle-row face variant
# South rim variants for each top tone: six per tone, rim over the face.
const RIMS := {"light": Vector2i(0, 23), "mid": Vector2i(0, 22), "dark": Vector2i(0, 21)}
const STAIR_SIDES := [Vector2i(0, 24), Vector2i(4, 24)] # rock beside the stairs, rows 24-26
const NARROW_STAIRS := [Vector2i(5, 24), Vector2i(5, 25), Vector2i(2, 26)] # one-wide stairs
const STONE_TUFT := Vector2i(11, 27) # stone floor with a tuft
# Rock ridges, one set per tone. Each piece is a column three cells tall:
# rim over the rock, the rock, rim under it. W and E are the rounded caps;
# B are two body pieces. The rim cells bake the tone's ground, so a ridge
# sits only on that ground: light on plain lawn, the others on a plateau
# top of their tone.
const RIDGES := {
	"light": {"W": Vector2i(7, 12), "B": [Vector2i(8, 12), Vector2i(7, 15)], "E": Vector2i(8, 15)},
	"mid": {"W": Vector2i(16, 15), "B": [Vector2i(14, 15), Vector2i(17, 15)], "E": Vector2i(15, 15)},
	"dark": {"W": Vector2i(16, 21), "B": [Vector2i(14, 21), Vector2i(17, 21)], "E": Vector2i(15, 21)},
	"stone": {"W": Vector2i(16, 27), "B": [Vector2i(14, 27), Vector2i(17, 27)], "E": Vector2i(15, 27)},
}
# Overhead forest canopy, seamless 4x4 blocks (plain and blossom).
const WALL_INSET := 2 # walkable columns between a mesa wall's end and the outer rim
const CANOPY_BLOCKS := [Vector2i(21, 11), Vector2i(21, 18)]
# Stairs cut three wide into the face: steps in rows 24-25 with shaded
# sides, then the mossy bottom step (2, 26) across all three columns.
const STAIRS := [
	[Vector2i(1, 24), Vector2i(2, 24), Vector2i(3, 24)],
	[Vector2i(1, 25), Vector2i(2, 25), Vector2i(3, 25)],
	[Vector2i(2, 26), Vector2i(2, 26), Vector2i(2, 26)],
]

# Fence: rail, east end with post, post. West pieces are the same cells flipped.
const FENCE_RAIL := Vector2i(30, 25)
const FENCE_END := Vector2i(31, 25)
const FENCE_POST := Vector2i(29, 26)
# The same rail and post with grass growing at the foot.
const FENCE_RAILS_GRASS := [Vector2i(32, 25), Vector2i(33, 25), Vector2i(32, 27), Vector2i(33, 27)]
const FENCE_POST_GRASS := Vector2i(32, 26)
# The rest of the fence cluster: plain rail variants, a second east end and
# post, and the shorter rails the sheet draws for a yard's back (north) row.
const FENCE_RAILS := [Vector2i(29, 25), Vector2i(29, 27), Vector2i(30, 27)]
const FENCE_END_B := Vector2i(31, 27)
const FENCE_POST_B := Vector2i(31, 26)
const FENCE_BACK := [Vector2i(29, 24), Vector2i(30, 24)]

# Houses. `region` is in sheet pixels, anchored on a cell corner. The top
# `roof_rows` are HOUSE_ROOF; the rest is HOUSE_BODY. `door` is the doorstep
# cell relative to the region's top-left cell. `blocks` are body colliders
# in region pixels.
const HOUSES := {
	0: {"name": "Porch cottage", "region": Rect2i(608, 160, 115, 80), "roof_rows": 2, "door": Vector2i(3, 5), "blocks": [Rect2i(14, 32, 100, 45)]},
	1: {"name": "Flower cottage", "region": Rect2i(608, 240, 115, 80), "roof_rows": 2, "door": Vector2i(2, 4), "blocks": [Rect2i(22, 32, 58, 30), Rect2i(64, 32, 50, 46)]},
	2: {"name": "Gable cottage", "region": Rect2i(608, 400, 115, 80), "roof_rows": 2, "door": Vector2i(2, 4), "blocks": [Rect2i(22, 32, 58, 30), Rect2i(64, 32, 50, 46)]},
	3: {"name": "Hut", "region": Rect2i(736, 144, 48, 64), "roof_rows": 2, "door": Vector2i(1, 4), "blocks": [Rect2i(0, 32, 48, 30)]},
	# Outbuildings: the hut kit's second wall (no deck) and the doorless
	# copy of the porch cottage.
	4: {"name": "Shed", "region": Rect2i(736, 208, 48, 48), "roof_rows": 1, "door": Vector2i(1, 3), "blocks": [Rect2i(0, 16, 48, 32)]},
	5: {"name": "Barn", "region": Rect2i(608, 320, 115, 80), "roof_rows": 2, "door": Vector2i(2, 5), "blocks": [Rect2i(14, 32, 100, 45)],
		# The sheet's loose door and windows, hung on the barn's front wall.
		"overlays": [{"src": Rect2i(736, 400, 16, 16), "at": Vector2i(48, 48)}, {"src": Rect2i(752, 384, 16, 32), "at": Vector2i(24, 36)},
			{"src": Rect2i(752, 416, 16, 16), "at": Vector2i(84, 32)}, {"src": Rect2i(736, 416, 16, 16), "at": Vector2i(100, 32)}]},
}

# Props. `region` in cells, `cell` = region top-left relative to the anchor
# tile, `base` = foot pixel inside the region (y-sort origin).
const PROPS := {
	"tree_a": {"region": Rect2i(29, 11, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(34, 78), "block": Vector2(12, 6)},
	"tree_b": {"region": Rect2i(33, 11, 5, 6), "cell": Vector2i(-2, -5), "base": Vector2i(40, 91), "block": Vector2(14, 6)},
	# The same trees with the grass tuft the sheet draws under each trunk.
	"tree_a_base": {"region": Rect2i(29, 11, 4, 6), "cell": Vector2i(-2, -5), "base": Vector2i(34, 92), "block": Vector2(12, 6)},
	"tree_b_base": {"region": Rect2i(33, 11, 5, 7), "cell": Vector2i(-2, -6), "base": Vector2i(40, 106), "block": Vector2(14, 6)},
	# Flowering versions (lavender blossom), rows 18+.
	"bloom_a": {"region": Rect2i(29, 18, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(34, 78), "block": Vector2(12, 6)},
	"bloom_b": {"region": Rect2i(33, 18, 5, 6), "cell": Vector2i(-2, -5), "base": Vector2i(40, 91), "block": Vector2(14, 6)},
	"bloom_a_base": {"region": Rect2i(29, 18, 4, 6), "cell": Vector2i(-2, -5), "base": Vector2i(34, 92), "block": Vector2(12, 6)},
	"bloom_b_base": {"region": Rect2i(33, 18, 5, 7), "cell": Vector2i(-2, -6), "base": Vector2i(40, 106), "block": Vector2(14, 6)},
	"log": {"region": Rect2i(21, 25, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"log_b": {"region": Rect2i(21, 26, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2(28, 6)},
	"crate": {"region": Rect2i(21, 27, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"crate_b": {"region": Rect2i(22, 27, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"crate_stack": {"region": Rect2i(22, 28, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 29), "block": Vector2(24, 8)},
	"crate_stack_b": {"region": Rect2i(24, 28, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 29), "block": Vector2(24, 8)},
	"chest": {"region": Rect2i(26, 28, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"chest_b": {"region": Rect2i(27, 28, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 14), "block": Vector2(12, 6)},
	"chest_c": {"region": Rect2i(26, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"chest_d": {"region": Rect2i(27, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(12, 6)},
	"bush_round": {"region": Rect2i(21, 22, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2(26, 8)},
	"bush_berry": {"region": Rect2i(23, 22, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2(26, 8)},
	"bush_small": {"region": Rect2i(21, 24, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"bush_small_b": {"region": Rect2i(23, 24, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"shrub_holey": {"region": Rect2i(47, 20, 2, 2), "cell": Vector2i(0, -1), "base": Vector2i(14, 31), "block": Vector2.ZERO},
	"shrub_flower": {"region": Rect2i(46, 22, 3, 2), "cell": Vector2i(-1, -1), "base": Vector2i(19, 31), "block": Vector2.ZERO},
	"rock_big": {"region": Rect2i(25, 23, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 30), "block": Vector2(26, 8)},
	"rock_mid": {"region": Rect2i(25, 25, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 14), "block": Vector2(22, 6)},
	"rock_tall": {"region": Rect2i(25, 26, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(15, 31), "block": Vector2(20, 8)},
	"rock_s1": {"region": Rect2i(23, 25, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(10, 5)},
	"rock_s2": {"region": Rect2i(24, 25, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(7, 15), "block": Vector2(10, 5)},
	"rock_s3": {"region": Rect2i(23, 26, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2(10, 5)},
	"rock_s4": {"region": Rect2i(24, 26, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(7, 15), "block": Vector2(10, 5)},
	"rock_wide": {"region": Rect2i(23, 27, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(15, 15), "block": Vector2(22, 6)},
	"torch": {"region": Rect2i(35, 26, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 27), "block": Vector2(4, 5), "frames": 3, "fps": 7.0},
	"torch_b": {"region": Rect2i(35, 26, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 27), "block": Vector2(4, 5), "frames": 3, "fps": 7.0},
	"torch_c": {"region": Rect2i(35, 26, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 27), "block": Vector2(4, 5), "frames": 3, "fps": 7.0},
	"campfire": {"region": Rect2i(29, 28, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2(12, 6), "frames": 4},
	"sparkle": {"region": Rect2i(47, 2, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO, "frames": 4},
	"campfire_big": {"region": Rect2i(34, 28, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2(12, 6), "frames": 4},
	"crate_stack_c": {"region": Rect2i(20, 28, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2(24, 8)},
	"tall_grass": {"region": Rect2i(20, 27, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"flowerpot": {"region": Rect2i(46, 20, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 19), "block": Vector2.ZERO},
	"deck": {"region": Rect2i(46, 19, 3, 1), "cell": Vector2i(-1, 0), "base": Vector2i(24, 15), "block": Vector2.ZERO},
	"water_grass_big_b": {"region": Rect2i(47, 7, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2.ZERO},
	# Shade trees: the trees whose base row carries dark ground shade, only
	# on the darkest grass, where the shade matches the ground.
	"shade_tree": {"region": Rect2i(25, 11, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(32, 79), "block": Vector2(14, 6)},
	"shade_bloom": {"region": Rect2i(25, 18, 4, 5), "cell": Vector2i(-2, -4), "base": Vector2i(32, 79), "block": Vector2(14, 6)},
	"ash": {"region": Rect2i(28, 29, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	# Rock outcrops: a small raised top on a short face, one per tone.
	"outcrop_light": {"region": Rect2i(9, 12, 2, 6), "cell": Vector2i(-1, -5), "base": Vector2i(16, 94), "block": Vector2(24, 8)},
	"outcrop_mid": {"region": Rect2i(18, 12, 2, 4), "cell": Vector2i(-1, -3), "base": Vector2i(16, 62), "block": Vector2(22, 8)},
	"outcrop_dark": {"region": Rect2i(18, 18, 2, 4), "cell": Vector2i(-1, -3), "base": Vector2i(16, 62), "block": Vector2(22, 8)},
	"outcrop_stone": {"region": Rect2i(18, 24, 2, 4), "cell": Vector2i(-1, -3), "base": Vector2i(16, 62), "block": Vector2(22, 8)},
	# Vines hung on a plateau face.
	"vine_flower": {"region": Rect2i(5, 18, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2.ZERO},
	"vine_green": {"region": Rect2i(6, 18, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2.ZERO},
	"vine_column": {"region": Rect2i(34, 25, 1, 3), "cell": Vector2i(0, -2), "base": Vector2i(4, 47), "block": Vector2.ZERO},
	"sparkle_b": {"region": Rect2i(47, 3, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO, "frames": 4},
	"reed_tall": {"region": Rect2i(46, 4, 1, 2), "cell": Vector2i(0, -1), "base": Vector2i(8, 31), "block": Vector2.ZERO},
	"reed": {"region": Rect2i(47, 5, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass": {"region": Rect2i(46, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass_b": {"region": Rect2i(47, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_grass_big": {"region": Rect2i(45, 7, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2.ZERO},
	"lily": {"region": Rect2i(45, 6, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"lily_pair": {"region": Rect2i(44, 5, 2, 1), "cell": Vector2i(-1, 0), "base": Vector2i(16, 15), "block": Vector2.ZERO},
	"water_rock_big": {"region": Rect2i(48, 5, 2, 2), "cell": Vector2i(-1, -1), "base": Vector2i(16, 31), "block": Vector2.ZERO},
	"water_rock": {"region": Rect2i(49, 7, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
	"water_rock_flat": {"region": Rect2i(49, 8, 1, 1), "cell": Vector2i.ZERO, "base": Vector2i(8, 15), "block": Vector2.ZERO},
}
const TREES := ["tree_a", "tree_b", "tree_a_base", "tree_b_base", "bloom_a", "bloom_b", "bloom_a_base", "bloom_b_base"]
const LOGS := ["log", "log_b"]
const YARD_CLUTTER := ["crate", "crate_b", "crate_stack", "crate_stack_b", "crate_stack_c", "chest", "chest_b", "chest_c", "chest_d"]
# The three torch cells (35-37, 26-27) are one torch in three flame frames.
const TORCHES := ["torch", "torch_b", "torch_c"]
const SHADE_TREES := ["shade_tree", "shade_bloom"]
const HEDGES := ["bush_round", "bush_berry"]
const SHRUBS := ["bush_small", "bush_small_b", "shrub_holey", "shrub_flower"]
# Land rocks: the big ones always collide; the 1-cell pebbles never do.
const BIG_ROCKS := ["rock_big", "rock_mid", "rock_tall", "rock_wide"]
const PEBBLES := ["rock_s1", "rock_s2", "rock_s3", "rock_s4"]
const LAND_ROCKS := BIG_ROCKS + PEBBLES
const SHORE_PLANTS := ["reed_tall", "reed", "water_grass", "water_grass_b", "water_grass_big", "water_grass_big_b"]
const OPEN_PLANTS := ["lily", "lily_pair"]
const WATER_ROCKS := ["water_rock_big", "water_rock", "water_rock_flat"]
const SPARKLES := ["sparkle", "sparkle_b"]
const OUTCROPS := {"light": "outcrop_light", "mid": "outcrop_mid", "dark": "outcrop_dark", "stone": "outcrop_stone"}
const VINES := ["vine_flower", "vine_green", "vine_column"]
# Eight distinct sign / notice / post cells from the crate-and-fence cluster.
const SIGN := [
	Vector2i(27, 23), Vector2i(27, 24), Vector2i(27, 25), Vector2i(27, 26),
	Vector2i(27, 27), Vector2i(28, 23), Vector2i(28, 24), Vector2i(28, 25),
	Vector2i(28, 26), Vector2i(28, 27),
]

var map_id := 0
var recipe_id := 0
var recipe: Dictionary
var attempt := 0

var lawn := {} # cell -> atlas
var features := {} # cell -> atlas: path, water, plateau
var path := {} # cell -> true
var water := {} # cell -> true
var plateau := {} # cell -> true (top and face)
var ledge := {} # plateau cells that block: the rim and the face, not the stairs
var stairs := {} # cell -> true
var ramps := {} # walkable ramp cells -> true
var caves: Array[Vector2i] = [] # cave entrance cells
var plateaus: Array[Dictionary] = [] # {top, tone, stairs, ramp, cave} (x of each cut, -1 if none)
var deco := {} # cell -> atlas
var tones: Array[Dictionary] = [] # per level: cell -> {atlas, alt}
var blobs: Array[Dictionary] = [] # {rect, cells, shape, mode, tiles, baked}
var ponds: Array[Rect2i] = []
var streams: Array[Dictionary] = [] # {cells: {cell: true}}, water cells of each stream
var deep := {} # cell -> true
var hedge := {} # cell -> atlas
var accents := {} # cell -> atlas
var accent_count := 0
var plaza := Rect2i()
var carpets := 0
var canopy := {} # cell -> atlas
var ridge := {} # every cell a ridge covers (rims and rock) -> true
var ridge_rock := {} # the rock row, which blocks
var ridges := 0
var hedgerows := 0
var props: Array[Dictionary] = [] # {art, cell, block} or {sign, cell, block}
var houses: Array[Dictionary] = [] # {id, origin}
var fence := {} # cell -> {atlas, flip}
var gate := Vector2i(-1, -1) # left cell of a two-cell gate
var leans := 0
var spawn := Vector2i.ZERO
var goals: Array[Vector2i] = []
var dropped := PackedStringArray()
var floor_notes := PackedStringArray() # what the liveliness floor added, for the report
var floor_before := 0.0 # weakest window's expected motion before and after the floor
var floor_after := 0.0

var _rng := RandomNumberGenerator.new()
var _taken := {} # objects plus their buffer rings
var _solid := {} # cells an object actually covers
var _blocked := {} # cells the walker cannot enter


# recipe = map_id % RECIPES.size(), unless `p_recipe` pins one (the fixed
# forest and wilds scenes do, so their maps survive new recipes).
func generate(p_map_id: int, p_recipe := -1) -> String:
	map_id = p_map_id
	recipe_id = p_recipe if p_recipe >= 0 else map_id % RECIPES.size()
	recipe = RECIPES[recipe_id]
	var built := false
	for a in ATTEMPTS:
		attempt = a
		_reset(hash(Vector2i(map_id, a)))
		if _layout() and _autotile_path():
			built = true
			break
	if not built:
		dropped.append("no layout fit after %d attempts" % ATTEMPTS)
	elif recipe.water.begins_with("P if room"):
		_optional_pond()
	elif recipe.water.begins_with("S if room") and not _stream():
		dropped.append("stream (no room)")
	_grass_zones()
	_grow_patches()
	_grow_hedges()
	_grass_accents()
	_place_props()
	_place_trees()
	_plateau_trees()
	_scatter_deco()
	_liveliness_floor()
	return _verify()


# "P if room": a pond in whichever quarter of the map has room for one, so a
# road-and-lawn recipe still has water moving somewhere; dropped if none fits.
func _optional_pond() -> void:
	var half := Vector2i(WIDTH / 2, HEIGHT / 2)
	var zones: Array[Rect2i] = [Rect2i(Vector2i(2, 2), half - Vector2i(3, 3)), Rect2i(Vector2i(half.x + 1, 2), half - Vector2i(3, 3)),
		Rect2i(Vector2i(2, half.y + 1), half - Vector2i(3, 3)), Rect2i(half + Vector2i(1, 1), half - Vector2i(3, 3))]
	for i in range(zones.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := zones[i]
		zones[i] = zones[j]
		zones[j] = tmp
	for z in zones:
		if _pond(z, "WP" if "WP" in recipe.water else ""):
			return
	dropped.append("pond (no room)")


# "S if room": a brook three cells wide that enters from a map edge and
# meanders in a staircase of straight runs (at least four cells between
# turns, never doubling back) until it runs off another edge or ends in a
# spring. It keeps two cells from the path and everything placed, so it never
# needs a bridge, and it is dropped if it would cut the spawn off from a goal.
# Cells past the map edge count as water, so it flows off the map instead of
# growing a shore there. Tiles, plants, and surfaces are the pond's.
const STREAM_WIDTH := 3
const STREAM_LENGTH := Vector2i(22, 46)

func _stream() -> bool:
	for attempt in 60:
		var side := _rng.randi() % 4
		var start: Vector2i
		var dir: Vector2i
		match side:
			0:
				start = Vector2i(_rng.randi_range(4, WIDTH - 8), -STREAM_WIDTH + 1)
				dir = Vector2i(0, 1)
			1:
				start = Vector2i(_rng.randi_range(4, WIDTH - 8), HEIGHT - 1)
				dir = Vector2i(0, -1)
			2:
				start = Vector2i(-STREAM_WIDTH + 1, _rng.randi_range(4, HEIGHT - 8))
				dir = Vector2i(1, 0)
			_:
				start = Vector2i(WIDTH - 1, _rng.randi_range(4, HEIGHT - 8))
				dir = Vector2i(-1, 0)
		var flow := dir # the way it runs; turns go sideways and back to this
		var p := start
		var squares: Array[Vector2i] = [p]
		var run := 0
		var side_dir := Vector2i(dir.y, dir.x) * (1 if _rng.randf() < 0.5 else -1)
		for i in _rng.randi_range(STREAM_LENGTH.x, STREAM_LENGTH.y):
			run += 1
			if run >= 4 and _rng.randf() < 0.3:
				dir = side_dir if dir == flow else flow
				if dir == flow:
					side_dir = Vector2i(flow.y, flow.x) * (1 if _rng.randf() < 0.5 else -1)
				run = 0
			p += dir
			squares.append(p)
			if not Rect2i(p, Vector2i(STREAM_WIDTH, STREAM_WIDTH)).intersects(Rect2i(0, 0, WIDTH, HEIGHT)):
				break # ran off the far side
		var cells := {}
		for q in squares:
			for y in STREAM_WIDTH:
				for x in STREAM_WIDTH:
					cells[q + Vector2i(x, y)] = true
		# A stream that stops inside the map rises from a spring: a small pool.
		if Rect2i(p, Vector2i(STREAM_WIDTH, STREAM_WIDTH)).intersects(Rect2i(0, 0, WIDTH, HEIGHT)):
			var pool := Rect2i(p - Vector2i(1, 1), Vector2i(STREAM_WIDTH + 2, STREAM_WIDTH + 2))
			for y in range(pool.position.y, pool.end.y):
				for x in range(pool.position.x, pool.end.x):
					cells[Vector2i(x, y)] = true
		_stream_bumps(cells, _rng.randi_range(3, 6))
		var inside := {}
		for c in cells:
			if _inside(c):
				inside[c] = true
		if inside.size() < 40:
			continue
		var clear := true
		for c in inside:
			if _taken.has(c) or _near(c, path, 2) or water.has(c) or plateau.has(c):
				clear = false
				break
		if not clear:
			continue
		var tiles := {}
		for c in inside:
			var t := _pool_tile(c, cells, WATER_SET, WATER_INNER)
			if t == NONE:
				clear = false
				break
			tiles[c] = t
		if not clear:
			continue
		var added: Array[Vector2i] = []
		for c in inside:
			if not _blocked.has(c):
				_blocked[c] = true
				added.append(c)
		var reach := true
		for g in goals:
			if not _reaches(spawn, g):
				reach = false
		if not reach:
			for c in added:
				_blocked.erase(c)
			continue
		var wet_props := _water_props(inside, "WP")
		for c in inside:
			var t: Vector2i = tiles[c]
			if t == WATER_SET + Vector2i(1, 1):
				t = SHALLOW_SURFACE
			features[c] = t
			water[c] = true
			_solid[c] = true
		props.append_array(wet_props)
		for c in inside:
			for y in range(-1, 2):
				for x in range(-1, 2):
					if _inside(c + Vector2i(x, y)):
						_taken[c + Vector2i(x, y)] = true
		streams.append({"cells": inside})
		return true
	return false


# Two-by-two bulges on the banks, so the edges wander instead of running
# straight. A bulge whose cells or neighbors the water set cannot draw is
# taken back off.
func _stream_bumps(cells: Dictionary, count: int) -> void:
	var edge: Array[Vector2i] = []
	for c in cells:
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not cells.has(c + d):
				edge.append(c)
				break
	edge.sort()
	var placed := 0
	for i in 40:
		if placed >= count or edge.is_empty():
			return
		var c: Vector2i = edge[_rng.randi() % edge.size()]
		var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		var o: Vector2i = dirs[_rng.randi() % 4]
		if cells.has(c + o):
			continue
		var t := Vector2i(o.y, o.x) * (1 if _rng.randf() < 0.5 else -1)
		var add: Array[Vector2i] = []
		for k in [c + o, c + o + t, c + o * 2, c + o * 2 + t]:
			if not cells.has(k):
				add.append(k)
		for k in add:
			cells[k] = true
		var ok := true
		for k in add:
			for y in range(-1, 2):
				for x in range(-1, 2):
					var n: Vector2i = k + Vector2i(x, y)
					if cells.has(n) and _pool_tile(n, cells, WATER_SET, WATER_INNER) == NONE:
						ok = false
		if ok:
			placed += 1
		else:
			for k in add:
				cells.erase(k)


func walkable(cell: Vector2i) -> bool:
	return _inside(cell) and not _blocked.has(cell)


func _reset(seed_value: int) -> void:
	_rng.seed = seed_value
	for d in [lawn, features, path, water, deep, hedge, accents, canopy, ridge, ridge_rock, plateau, ledge, stairs, ramps, deco, fence, _taken, _solid, _blocked]:
		d.clear()
	for a in [blobs, ponds, streams, props, houses, goals, tones, caves, plateaus]:
		a.clear()
	dropped.clear()
	floor_notes.clear()
	gate = Vector2i(-1, -1)
	leans = 0
	hedgerows = 0
	ridges = 0
	accent_count = 0
	plaza = Rect2i()
	carpets = 0
	_paint_lawn()


func _paint_lawn() -> void:
	for y in HEIGHT:
		for x in WIDTH:
			var h := _hash(x, y, 3)
			lawn[Vector2i(x, y)] = LAWN[0] if h < 0.7 else (LAWN_FLOWERS if h > 0.985 else LAWN[1 + int(h * 97.0) % 3])


# ---------------------------------------------------------------- layouts
# Each recipe places its plateau, ponds, houses, fences, and path. A layout
# returns false when a piece does not fit; generate() then retries with the
# next attempt seed.

func _layout() -> bool:
	match recipe_id:
		0: return _lay_pastoral()
		1: return _lay_crossroads()
		2: return _lay_pond_walk()
		3: return _lay_garden()
		4: return _lay_rim(0)
		5: return _lay_edge_road(_rng.randi_range(HEIGHT / 2 - 6, HEIGHT / 2 + 4))
		6: return _lay_twin_water()
		7: return _lay_south_road()
		8: return _lay_shore_spur()
		9: return _lay_three_way()
		10: return _lay_hamlet(false)
		11: return _lay_hamlet(true)
		12: return _lay_wild_lane()
		13: return _lay_orchard()
		14: return _lay_shore_hamlet()
		15: return _lay_double_lean()
		16: return _lay_rim(3)
		17: return _lay_gate_road()
		18: return _lay_sparse_wild()
		19: return _lay_switchback()
		20: return _lay_cave()
		21: return _lay_terraces()
		22: return _lay_ruins()
		23: return _lay_camp()
		24: return _lay_rock_garden()
		25: return _lay_deep_forest()
		26: return _lay_village()
		27: return _lay_hedge_garden()
		28: return _lay_ridgeline()
		29: return _lay_walled_mesa()
	return false


# 0: trunk from the west edge with one lean, into a fenced yard. Pond south.
func _lay_pastoral() -> bool:
	var h := _place_house(0, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	_yard(h)
	var high := door.y + _rng.randi_range(5, 7)
	var rise := _rng.randi_range(2, 4)
	var low := high + rise
	var k := _pick(6, door.x - 7)
	if k < 0 or low > HEIGHT - 12:
		return false
	if not _route([Vector2i(0, low), Vector2i(k, low), Vector2i(k, high), Vector2i(door.x, high), door]):
		return false
	leans = 1
	spawn = Vector2i(2, low)
	goals = [door]
	return _pond(Rect2i(4, low + 4, WIDTH - 8, HEIGHT - low - 6), "WP+WR")


# 1: two edge-to-edge trunks crossing at 90 degrees, house spur to the trunk.
func _lay_crossroads() -> bool:
	var row := _rng.randi_range(19, 25)
	var col := _rng.randi_range(18, WIDTH - 20)
	var west := _rng.randf() < 0.5
	var zone := Rect2i(4, 4, col - 14, row - 14) if west else Rect2i(col + 5, 4, WIDTH - col - 16, row - 14)
	var h := _place_house(1, zone)
	if h.is_empty():
		return false
	var door := _door(h)
	if abs(door.x - col) < 5 or door.y > row - 4:
		return false
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	if not _route([Vector2i(col, 0), Vector2i(col, HEIGHT - 2)], true):
		return false
	if not _route([door, Vector2i(door.x, row)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(col, 1), Vector2i(WIDTH - 2, row)]
	return true


# 2: the trunk skirts the pond's south shore, then turns north to the house.
func _lay_pond_walk() -> bool:
	if not _pond(Rect2i(5, 12, 26, 14), "WP+WR"):
		return false
	var p := ponds[0]
	var row := p.end.y + 1
	var h := _place_house(2, Rect2i(p.end.x + 3, 4, WIDTH - p.end.x - 13, row - 13))
	if h.is_empty():
		return false
	var door := _door(h)
	if door.y > row - 4:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	spawn = Vector2i(2, row)
	goals = [door]
	return true


# 3: trunk from the west edge, north through the yard gate to the door.
func _lay_garden() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	_yard(h)
	var row := mini(door.y + _rng.randi_range(4, 9), HEIGHT - 5)
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	spawn = Vector2i(2, row)
	goals = [door]
	return true


# 4 and 16: plateau in the north half; the trunk runs along its foot
# (`gap` lawn rows below the face) and on to a house east of it.
func _lay_rim(gap: int) -> bool:
	var tone := _pick_top()
	var info := _plateau(Rect2i(6, 3, WIDTH / 2 - 6, 5), tone, ["ramp"] if tone == "light" and _rng.randf() < 0.5 else ["stairs"])
	if info.is_empty():
		return false
	var top: Rect2i = info.top
	var foot := top.end.y + FACE_ROWS
	var row := foot + gap
	var h := _place_house(0 if recipe_id == 4 else 2, Rect2i(top.end.x + 4, 3, WIDTH - top.end.x - 14, row - 12))
	if h.is_empty():
		return false
	var door := _door(h)
	if door.y > row - 3:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	var sx := _access_x(info)
	if gap > 0 and not _route([Vector2i(sx, row), Vector2i(sx, foot)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, _top_goal(info)] # the door and the plateau top
	return true


# Column where a path should meet the plateau's way up (stairs or ramp gap).
func _access_x(info: Dictionary) -> int:
	if info.narrow >= 0:
		return info.narrow
	if info.stairs >= 0:
		return info.stairs
	if info.ramp >= 0:
		return info.ramp + 1
	return info.cave


func _top_goal(info: Dictionary) -> Vector2i:
	var top: Rect2i = info.top
	return Vector2i(_access_x(info) + 1, top.end.y - 2)


# Plateau top tone: mostly light, sometimes mid or dark.
func _pick_top() -> String:
	var r := _rng.randf()
	return "light" if r < 0.5 else ("mid" if r < 0.8 else "dark")


# 5: a straight road from the west edge to the east edge.
func _lay_edge_road(row: int) -> bool:
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	spawn = Vector2i(3, row)
	goals = [Vector2i(WIDTH - 2, row)]
	return true


# 6: a vertical trunk from the south edge to the house, a pond each side.
func _lay_twin_water() -> bool:
	var h := _place_house(1, Rect2i(WIDTH / 2 - 8, 3, 10, 4))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(door.x, HEIGHT - 2), door]):
		return false
	var top := door.y + 3
	if not _pond(Rect2i(door.x - 22, top, 19, HEIGHT - top - 3), "WP+WR"):
		return false
	if not _pond(Rect2i(door.x + 5, top, 19, HEIGHT - top - 3), "WP+WR"):
		return false
	spawn = Vector2i(door.x, HEIGHT - 3)
	goals = [door]
	return true


# 7: an edge-to-edge road in the south third, the house spurs down to it.
func _lay_south_road() -> bool:
	var row := _rng.randi_range(HEIGHT * 2 / 3, HEIGHT - 7)
	var h := _place_house(2, Rect2i(8, row - 16, WIDTH - 22, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(0, row), Vector2i(WIDTH - 2, row)]):
		return false
	if not _route([door, Vector2i(door.x, row)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(WIDTH - 2, row)]
	return true


# 8: trunk to the house, and a spur from the trunk down to the pond shore.
func _lay_shore_spur() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	var row := mini(door.y + _rng.randi_range(4, 7), HEIGHT - 16)
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	if not _pond(Rect2i(4, row + 6, door.x + 2, HEIGHT - row - 8), "WP+WR"):
		return false
	var p := ponds[0]
	var col := clampi(p.get_center().x - 1, 4, door.x - 5)
	var shore := _first_water_below(col, row + 2)
	if shore < 0:
		return false
	if not _route([Vector2i(col, row), Vector2i(col, shore - 3)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(col, shore - 2)]
	return true


# 9: trunk to the house with a branch to the north edge and one to the south.
func _lay_three_way() -> bool:
	var h := _place_house(0, Rect2i(WIDTH / 2, 4, WIDTH / 2 - 12, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	var row := mini(door.y + _rng.randi_range(4, 8), HEIGHT - 8)
	var north := _pick(5, door.x - 16)
	var south := _pick(north + 6, door.x - 6)
	if north < 0 or south < 0:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	if not _route([Vector2i(north, row), Vector2i(north, 0)], true):
		return false
	if not _route([Vector2i(south, row), Vector2i(south, HEIGHT - 2)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, Vector2i(north, 1), Vector2i(south, HEIGHT - 2)]
	return true


# 10 and 11: hamlet with a fenced yard; the trunk comes in from the far edge
# with one lean. West hamlet has two houses (1 and 3) and a second spur.
func _lay_hamlet(east: bool) -> bool:
	var ids: Array = recipe.houses
	var zone := Rect2i(WIDTH - 22, 4, 12, 5) if east else Rect2i(4, 4, 12, 5)
	var a := _place_house(ids[0], zone)
	if a.is_empty():
		return false
	var door := _door(a)
	_yard(a)
	var b := {}
	var door_b := Vector2i(-99, -99)
	if ids.size() > 1:
		b = _place_house(ids[1], Rect2i(door.x + 10, 4, 10, 6))
		if b.is_empty():
			return false
		door_b = _door(b)
	var high := maxi(door.y, door_b.y) + _rng.randi_range(6, 8)
	var rise := _rng.randi_range(2, 4)
	var low := high + rise
	var edge := 0 if east else WIDTH - 2
	var k := _pick(6, door.x - 8) if east else _pick(maxi(door.x, door_b.x) + 6, WIDTH - 8)
	if low > HEIGHT - 12 or k < 0:
		return false
	if not _route([Vector2i(edge, low), Vector2i(k, low), Vector2i(k, high), Vector2i(door.x, high), door]):
		return false
	leans = 1
	if not b.is_empty() and not _route([door_b, Vector2i(door_b.x, high)], true):
		return false
	spawn = Vector2i(2 if east else WIDTH - 3, low)
	goals.assign([door] if b.is_empty() else [door, door_b])
	var pond_zone := Rect2i(WIDTH / 2, low + 4, WIDTH / 2 - 4, HEIGHT - low - 6) if east else Rect2i(4, low + 4, WIDTH / 2 - 4, HEIGHT - low - 6)
	return _pond(pond_zone, "WR" if east else "WP")


# 12: one trunk from the north edge to the south edge; a moisture pond.
func _lay_wild_lane() -> bool:
	var col := _rng.randi_range(12, WIDTH - 14)
	if not _route([Vector2i(col, 0), Vector2i(col, HEIGHT - 2)]):
		return false
	spawn = Vector2i(col, HEIGHT - 3)
	goals = [Vector2i(col, 1)]
	var west := col > WIDTH / 2
	var zone := Rect2i(3, 4, col - 7, HEIGHT - 8) if west else Rect2i(col + 5, 4, WIDTH - col - 8, HEIGHT - 8)
	return _pond(zone, "")


# 13: a short trunk from the door that ends on the lawn.
func _lay_orchard() -> bool:
	var h := _place_house(3, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	var end := door.y + _rng.randi_range(5, 8)
	if not _route([door, Vector2i(door.x, end)]):
		return false
	spawn = Vector2i(door.x, end + 1)
	goals = [door]
	return true


# 14: short trunk; a pond to the south-east with a fence run along its
# north shore, between the pond and the house.
func _lay_shore_hamlet() -> bool:
	var h := _place_house(0, Rect2i(8, 4, 16, 5))
	if h.is_empty():
		return false
	var door := _door(h)
	var end := door.y + _rng.randi_range(6, 9)
	if not _route([door, Vector2i(door.x, end)]):
		return false
	var size := _cells(HOUSES[0].region.size)
	if not _pond(Rect2i(h.origin.x + size.x + 3, door.y + 1, 22, HEIGHT - door.y - 4), "WP+WR"):
		return false
	var p := ponds[0]
	if not _fence_run(Vector2i(p.position.x, p.position.y - 2), p.size.x):
		return false
	spawn = Vector2i(door.x, end + 1)
	goals = [door]
	return true


# 15: trunk from the west edge with two leans, then north to the door.
func _lay_double_lean() -> bool:
	var h := _place_house(1, Rect2i(WIDTH - 22, 4, 12, 5))
	if h.is_empty():
		return false
	var door := _door(h)
	var r1 := _rng.randi_range(2, 4)
	var r2 := _rng.randi_range(2, 4)
	var top := door.y + _rng.randi_range(4, 6)
	var mid := top + r2
	var low := mid + r1
	var k1 := _rng.randi_range(7, 16)
	var k2 := _pick(k1 + 7, door.x - 7)
	if low > HEIGHT - 5 or k2 < 0:
		return false
	if not _route([Vector2i(0, low), Vector2i(k1, low), Vector2i(k1, mid), Vector2i(k2, mid), Vector2i(k2, top), Vector2i(door.x, top), door]):
		return false
	leans = 2
	spawn = Vector2i(2, low)
	goals = [door]
	return true


# 17: a gate line across the map; the path comes up from the south edge
# through the gate to the house.
func _lay_gate_road() -> bool:
	var h := _place_house(3, Rect2i(WIDTH / 2 - 10, 4, 18, 6))
	if h.is_empty():
		return false
	var door := _door(h)
	if not _route([Vector2i(door.x, HEIGHT - 2), door]):
		return false
	_gate_line(door.y + 3, door.x)
	spawn = Vector2i(door.x, HEIGHT - 3)
	goals = [door]
	return true


# 18: one straight trunk; a pond only if the moisture field has a blob.
func _lay_sparse_wild() -> bool:
	var row := _rng.randi_range(HEIGHT / 2 - 5, HEIGHT / 2 + 5)
	if not _lay_edge_road(row):
		return false
	var zone := Rect2i(4, row + 5, WIDTH - 8, HEIGHT - row - 7) if row < HEIGHT / 2 else Rect2i(4, 3, WIDTH - 8, row - 6)
	var best := _wettest(zone)
	if _moisture(best) < 0.56:
		dropped.append("pond (no moisture blob)")
		return true
	return _pond(zone, "")


# 19: a U of two 90-degree turns (east, north, back west), then up to the door.
func _lay_switchback() -> bool:
	var h := _place_house(0, Rect2i(8, 3, 14, 3))
	if h.is_empty():
		return false
	var door := _door(h)
	var upper := door.y + _rng.randi_range(4, 6)
	var lower := upper + _rng.randi_range(5, 8)
	var turn := _pick(door.x + 10, WIDTH - 8)
	if lower > HEIGHT - 4 or turn < 0:
		return false
	if not _route([Vector2i(0, lower), Vector2i(turn, lower), Vector2i(turn, upper), Vector2i(door.x, upper), door]):
		return false
	spawn = Vector2i(2, lower)
	goals = [door]
	return true


# 20: a plateau with a cave mouth in its face; the trunk leads to the cave
# and torches flank it.
func _lay_cave() -> bool:
	var info := _plateau(Rect2i(12, 3, WIDTH - 30, 6), "light", ["cave"])
	if info.is_empty():
		return false
	var top: Rect2i = info.top
	var foot := top.end.y + FACE_ROWS
	var row := mini(foot + _rng.randi_range(3, 6), HEIGHT - 5)
	var cx: int = info.cave
	if not _route([Vector2i(0, row), Vector2i(cx, row), Vector2i(cx, foot)]):
		return false
	spawn = Vector2i(2, row)
	goals = [caves[0]]
	return true


# 21: two terraces side by side, one reached by a ramp, one by stairs; the
# trunk runs along their feet to a hut in the east.
func _lay_terraces() -> bool:
	var a := _plateau(Rect2i(4, 3, 10, 5), "light", ["ramp"])
	if a.is_empty():
		return false
	var b := _plateau(Rect2i(a.top.end.x + 4, 3, 10, 5), "mid" if _rng.randf() < 0.5 else "dark", ["narrow"] if _rng.randf() < 0.5 else ["stairs"])
	if b.is_empty():
		return false
	var foot: int = maxi(a.top.end.y, b.top.end.y) + FACE_ROWS
	var row := foot + _rng.randi_range(3, 5)
	var h := _place_house(3, Rect2i(b.top.end.x + 4, 3, WIDTH - b.top.end.x - 12, row - 10))
	if h.is_empty():
		return false
	var door := _door(h)
	if door.y > row - 3 or row > HEIGHT - 4:
		return false
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	for info in [a, b]:
		var x := _access_x(info)
		var info_foot: int = info.top.end.y + FACE_ROWS
		if not _route([Vector2i(x, row), Vector2i(x, info_foot)], true):
			return false
	spawn = Vector2i(2, row)
	goals = [door, _top_goal(a), _top_goal(b)]
	return true


# 22: a raised stone platform with a stone ramp, stone outcrops around it,
# and the clutter of an old camp.
func _lay_ruins() -> bool:
	var info := _plateau(Rect2i(14, 5, WIDTH - 34, 6), "stone", ["ramp"])
	if info.is_empty():
		return false
	var top: Rect2i = info.top
	var foot := top.end.y + FACE_ROWS
	var row := mini(foot + _rng.randi_range(3, 6), HEIGHT - 5)
	var x := _access_x(info)
	if not _route([Vector2i(0, row), Vector2i(x, row), Vector2i(x, foot)]):
		return false
	spawn = Vector2i(2, row)
	goals = [_top_goal(info)]
	return true


# 23: a shed in a fenced yard and a barn beside it; logs, a big fire.
func _lay_camp() -> bool:
	var shed := _place_house(4, Rect2i(10, 4, 12, 5))
	if shed.is_empty():
		return false
	var door := _door(shed)
	_yard(shed)
	var barn := _place_house(5, Rect2i(door.x + 12, 4, 14, 5))
	if barn.is_empty():
		return false
	var door_b := _door(barn)
	var row := mini(maxi(door.y + 4, door_b.y + 3) + _rng.randi_range(2, 5), HEIGHT - 5)
	if not _route([Vector2i(0, row), Vector2i(door_b.x, row), door_b]):
		return false
	if not _route([door, Vector2i(door.x, row)], true):
		return false
	spawn = Vector2i(2, row)
	goals = [door, door_b]
	return true


# 24: an edge-to-edge road with one lean, a lake, and rock outcrops.
func _lay_rock_garden() -> bool:
	var high := _rng.randi_range(12, 16)
	var low := high + _rng.randi_range(2, 4)
	var k := _rng.randi_range(18, WIDTH - 20)
	if not _route([Vector2i(0, low), Vector2i(k, low), Vector2i(k, high), Vector2i(WIDTH - 2, high)]):
		return false
	leans = 1
	spawn = Vector2i(2, low)
	goals = [Vector2i(WIDTH - 2, high)]
	return _pond(Rect2i(4, low + 5, WIDTH - 8, HEIGHT - low - 7), "WP+WR")


# 25: an overhead canopy wall along the north edge, trees standing in front
# of it to break its straight lower edge, a trunk through dark woods.
func _lay_deep_forest() -> bool:
	var block: Vector2i = CANOPY_BLOCKS[_rng.randi() % CANOPY_BLOCKS.size()]
	var depth := 4
	for y in depth:
		for x in WIDTH:
			var c := Vector2i(x, y)
			canopy[c] = block + Vector2i(x % 4, y % 4)
			_solid[c] = true
			_taken[c] = true
			_blocked[c] = true
	var x := _rng.randi_range(0, 2)
	while x < WIDTH:
		var art: String = ["tree_a_base", "tree_b_base", "bloom_a_base", "bloom_b_base"][_rng.randi() % 4]
		var c := Vector2i(x, depth + 2 + _rng.randi_range(0, 1))
		var tree := {"art": art, "cell": c, "block": true}
		props.append(tree)
		_claim(Rect2i(c.x - 2, depth, 5, c.y - depth + 1))
		_block_collider(tree)
		x += _rng.randi_range(3, 4) # close enough that the crowns overlap
	var row := _rng.randi_range(HEIGHT / 2, HEIGHT - 8)
	return _lay_edge_road(row)


# 26: a paved square with three houses on its north side, spurs from their
# doors, and trunks from the square to the west and east edges.
func _lay_village() -> bool:
	var ids: Array = recipe.houses
	var doors: Array[Vector2i] = []
	var x := 4
	for id in ids:
		var h := _place_house(id, Rect2i(x, 4, 4, 3))
		if h.is_empty():
			return false
		doors.append(_door(h))
		x = h.origin.x + _cells(HOUSES[id].region.size).x + 8 # houses keep 8 + width apart
	var top := 0
	for d in doors:
		top = maxi(top, d.y)
	top += 3
	var left: int = doors[0].x - 2
	var right: int = doors[doors.size() - 1].x + 3
	plaza = Rect2i(left, top, right - left + 1, 5)
	if plaza.end.y > HEIGHT - 4:
		return false
	for yy in range(plaza.position.y, plaza.end.y):
		for xx in range(plaza.position.x, plaza.end.x):
			var c := Vector2i(xx, yy)
			if _solid.has(c):
				return false
			path[c] = true
			_solid[c] = true
			_taken[c] = true
	for d in doors:
		if not _route([d, Vector2i(d.x, top)], true):
			return false
	var mid := top + 1
	if not _route([Vector2i(0, mid), Vector2i(left, mid)], true):
		return false
	if not _route([Vector2i(right - 1, mid), Vector2i(WIDTH - 2, mid)], true):
		return false
	spawn = Vector2i(2, mid)
	goals.assign(doors + [Vector2i(WIDTH - 2, mid)])
	return true


# 27: a gable cottage in a gated yard, hedgerows and flower carpets
# everywhere else.
func _lay_hedge_garden() -> bool:
	var h := _place_house(2, _center_zone())
	if h.is_empty():
		return false
	var door := _door(h)
	_yard(h)
	var row := mini(door.y + _rng.randi_range(5, 8), HEIGHT - 5)
	if not _route([Vector2i(0, row), Vector2i(door.x, row), door]):
		return false
	spawn = Vector2i(2, row)
	goals = [door]
	return true


# A ridge segment from x0 to x1 (inclusive) with its rock on row `y`.
# `on_top` is set when it stands on a plateau top (the plateau already owns
# the cells); otherwise every cell must be free lawn.
func _ridge(x0: int, x1: int, y: int, tone: String, on_top := false) -> bool:
	if x1 - x0 < 2:
		return false
	var pieces: Dictionary = RIDGES[tone]
	for x in range(x0, x1 + 1):
		for dy in [-1, 0, 1]:
			var c := Vector2i(x, y + dy)
			if not _inside(c) or ridge.has(c) or path.has(c):
				return false
			if not on_top and _solid.has(c):
				return false
	for x in range(x0, x1 + 1):
		var piece: Vector2i = pieces.W if x == x0 else (pieces.E if x == x1 else pieces.B[int(_hash(x, y, 73) * 2.0) % 2])
		for dy in [-1, 0, 1]:
			var c := Vector2i(x, y + dy)
			features[c] = piece + Vector2i(0, dy + 1)
			ridge[c] = true
			_solid[c] = true
			_taken[c] = true
		ridge_rock[Vector2i(x, y)] = true
		_blocked[Vector2i(x, y)] = true
	ridges += 1
	return true


# 28: a light rock ridge across the map. The path from the south edge runs
# through one pass to a house in the north; a second pass opens elsewhere.
func _lay_ridgeline() -> bool:
	var h := _place_house(1, Rect2i(WIDTH / 2 - 10, 3, 16, 4))
	if h.is_empty():
		return false
	var door := _door(h)
	var y := door.y + _rng.randi_range(5, 8)
	if y > HEIGHT - 8:
		return false
	if not _route([Vector2i(door.x, HEIGHT - 2), door]):
		return false
	var other := _pick(4, door.x - 8) if _rng.randf() < 0.5 else _pick(door.x + 8, WIDTH - 6)
	if other < 0:
		return false
	var passes := [[door.x, door.x + 1], [other, other + 1]]
	passes.sort_custom(func(a, b): return a[0] < b[0])
	var x := 0
	for p in passes:
		if not _ridge(x, p[0] - 1, y, "light"):
			return false
		x = p[1] + 1
	if not _ridge(x, WIDTH - 1, y, "light"):
		return false
	# Keep the open pass and the ground either side of it clear of props.
	_claim(Rect2i(other - 1, y - 3, 4, 7))
	spawn = Vector2i(door.x, HEIGHT - 3)
	goals = [door, Vector2i(other, y - 3), Vector2i(other, y + 3)]
	return true


# 29: a large plateau whose top carries ruined ridge walls in its own tone,
# with a gap through them; the trunk leads to its ramp or stairs.
func _lay_walled_mesa() -> bool:
	var r := _rng.randf()
	var tone := "stone" if r < 0.5 else ("mid" if r < 0.75 else "dark")
	var access := ["ramp"] if tone == "stone" else ["stairs"]
	var info := _plateau(Rect2i(8, 3, WIDTH - 32, 4), tone, access, Vector2i(14, 7), Vector2i(18, 8))
	if info.is_empty():
		return false
	var top: Rect2i = info.top
	# Walls on the top's interior: rims on interior rows, rock between.
	# The wall's rim sits one row above its rock; leave a full walkable row
	# between that rim and the plateau's own north rim. Each end stops
	# WALL_INSET columns short of the outer rim, so there is a passage around
	# both ends as well as the gap in the middle.
	var wy := _rng.randi_range(top.position.y + 3, top.end.y - 3)
	var x0 := top.position.x + 1 + WALL_INSET # first wall column
	var x1 := top.end.x - 2 - WALL_INSET # last wall column
	var gap := _pick(x0 + 3, x1 - 4)
	if gap < 0:
		return false
	if not _ridge(x0, gap - 1, wy, tone, true):
		return false
	if not _ridge(gap + 2, x1, wy, tone, true):
		return false
	var foot := top.end.y + FACE_ROWS
	var row := mini(foot + _rng.randi_range(3, 6), HEIGHT - 5)
	var ax := _access_x(info)
	if not _route([Vector2i(0, row), Vector2i(ax, row), Vector2i(ax, foot)]):
		return false
	spawn = Vector2i(2, row)
	# The top, behind the wall through the gap, and both end passages on the
	# wall's row (proves a character can walk around each end).
	goals = [_top_goal(info), Vector2i(gap, wy - 2), Vector2i(x0 - 1, wy), Vector2i(x1 + 1, wy)]
	return true


# Random int in [lo, hi], or -1 when the range is empty.
func _pick(lo: int, hi: int) -> int:
	return -1 if hi < lo else _rng.randi_range(lo, hi)


func _center_zone() -> Rect2i:
	return Rect2i(WIDTH / 2 - 10, 4, 18, 7)


# ---------------------------------------------------------------- pieces

func _place_house(id: int, zone: Rect2i) -> Dictionary:
	var art: Dictionary = HOUSES[id]
	var size := _cells(art.region.size)
	if zone.size.x <= 0 or zone.size.y <= 0:
		return {}
	for i in 40:
		var origin := zone.position + Vector2i(_rng.randi_range(0, zone.size.x), _rng.randi_range(0, zone.size.y))
		var box := Rect2i(origin, size).grow(3)
		if not _rect_free(box):
			continue
		var ok := true
		for other in houses:
			if Vector2(origin - other.origin).length() < 8.0 + size.x:
				ok = false
		if not ok:
			continue
		var h := {"id": id, "origin": origin}
		houses.append(h)
		_claim(Rect2i(origin, size).grow(2))
		for block in art.blocks:
			_block_pixels(origin * 16, block)
		return h
	return {}


func _door(h: Dictionary) -> Vector2i:
	return h.origin + HOUSES[h.id].door


# Fence yard around a house with a two-cell gate under the door.
func _yard(h: Dictionary) -> void:
	var art: Dictionary = HOUSES[h.id]
	var size := _cells(art.region.size)
	var door := _door(h)
	var x0: int = h.origin.x - 2
	var x1: int = h.origin.x + size.x + 1
	var y0: int = h.origin.y - 2
	var y1: int = door.y + 2
	gate = Vector2i(door.x, y1)
	for x in range(x0, x1 + 1):
		if x != x0 and x != x1 and _hash(x, y0, 61) < 0.5:
			_put_fence(Vector2i(x, y0), FENCE_BACK[int(_hash(x, y0, 67) * 2.0) % 2], false) # the shorter back rails
			continue
		_put_fence(Vector2i(x, y0), FENCE_END if x == x0 or x == x1 else FENCE_RAIL, x == x0)
		if x == door.x or x == door.x + 1:
			continue
		var end := x == x0 or x == x1 or x == door.x - 1 or x == door.x + 2
		_put_fence(Vector2i(x, y1), FENCE_END if end else FENCE_RAIL, x == x0 or x == door.x + 2)
	for y in range(y0 + 1, y1):
		_put_fence(Vector2i(x0, y), FENCE_POST, true)
		_put_fence(Vector2i(x1, y), FENCE_POST, false)
	_claim(Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1).grow(1))


# A straight horizontal fence run of `length` cells with posts at both ends.
func _fence_run(start: Vector2i, length: int) -> bool:
	if length < 3:
		return false
	for x in range(start.x, start.x + length):
		var c := Vector2i(x, start.y)
		if not _inside(c) or _solid.has(c):
			return false
	for x in range(start.x, start.x + length):
		var end := x == start.x or x == start.x + length - 1
		_put_fence(Vector2i(x, start.y), FENCE_END if end else FENCE_RAIL, x == start.x)
	return true


# A fence line across the whole map with a two-cell gate at `gate_x`.
func _gate_line(row: int, gate_x: int) -> void:
	gate = Vector2i(gate_x, row)
	for x in WIDTH:
		if x == gate_x or x == gate_x + 1:
			continue
		var c := Vector2i(x, row)
		if path.has(c):
			continue
		var post := x == gate_x - 1 or x == gate_x + 2
		_put_fence(c, FENCE_END if post else FENCE_RAIL, x == gate_x + 2)


func _put_fence(c: Vector2i, atlas: Vector2i, flip: bool) -> void:
	# Some rails and posts have grass growing at the foot.
	var h := _hash(c.x, c.y, 53)
	if atlas == FENCE_RAIL and h < 0.35:
		atlas = FENCE_RAILS_GRASS[int(h * 997.0) % FENCE_RAILS_GRASS.size()]
	elif atlas == FENCE_RAIL and h < 0.6:
		atlas = FENCE_RAILS[int(h * 997.0) % FENCE_RAILS.size()]
	elif atlas == FENCE_POST and h < 0.35:
		atlas = FENCE_POST_GRASS
	elif atlas == FENCE_POST and not flip and h < 0.6:
		atlas = FENCE_POST_B
	elif atlas == FENCE_END and h < 0.4:
		atlas = FENCE_END_B
	fence[c] = {"atlas": atlas, "flip": flip}
	_blocked[c] = true
	_solid[c] = true
	_taken[c] = true


# Plateau: a rectangle at least 4x4 for the top, then a three-row face.
# `tone` picks the top and ramp set. `access` lists the cuts made in the
# face: "stairs" (three wide), "ramp" (a two-wide gap with shaded sides, four
# wide in all), "cave" (three wide, entrance at the bottom middle). Returns
# {top, tone, stairs, ramp, cave} with the x of each cut (-1 if absent), or
# an empty dictionary when it does not fit.
func _plateau(zone: Rect2i, tone: String, access: Array, min_size := Vector2i(6, 4), max_size := Vector2i(10, 5)) -> Dictionary:
	var top_set: Vector2i = PLATEAU_TOPS[tone]
	var ramp_set: Vector2i = RAMPS[tone]
	var widths := {"stairs": 3, "ramp": RAMP_WIDTH, "cave": 3, "narrow": 1}
	var need := 2
	for a in access:
		need += widths[a] + 1
	for i in 30:
		var size := Vector2i(_rng.randi_range(maxi(min_size.x, need), maxi(max_size.x, need + 2)), _rng.randi_range(min_size.y, max_size.y))
		var at := zone.position + Vector2i(_rng.randi_range(0, maxi(zone.size.x, 0)), _rng.randi_range(0, maxi(zone.size.y, 0)))
		var whole := Rect2i(at, size + Vector2i(0, FACE_ROWS))
		if not _rect_free(whole.grow(2)):
			continue
		var top := Rect2i(at, size)
		var cells := {}
		for y in range(top.position.y, top.end.y):
			for x in range(top.position.x, top.end.x):
				cells[Vector2i(x, y)] = true
		for c in cells:
			var mask := _mask(c, cells, false)
			var tile: Vector2i = top_set + ROLES[mask]
			var h := _hash(c.x, c.y, 29)
			if mask == 11 and RIMS.has(tone):
				tile = RIMS[tone] + Vector2i(int(h * 6.0) % 6, 0) # south rim variants
			elif mask == 15 and tone == "stone" and h < 0.12:
				tile = STONE_TUFT
			features[c] = tile
		# Face first (one of two rock faces), with a few vine-covered columns
		# and plain-rock middles, then the cuts.
		var face_set: Vector2i = FACE_SETS[int(_hash(at.x, at.y, 43) * 2.0) % 2]
		for r in FACE_ROWS:
			for x in range(top.position.x, top.end.x):
				var col := 0 if x == top.position.x else (2 if x == top.end.x - 1 else 1)
				var face := face_set + Vector2i(col, r)
				var h := _hash(x, top.end.y + r, 31)
				if col == 1 and _hash(x, top.end.y, 31) < 0.22:
					face = VINE_FACES[int(_hash(x, 0, 37) * 2.0) % 2] + Vector2i(0, r)
				elif col == 1 and r == 1 and h > 0.8:
					face = ROCK_FILLS[int(h * 97.0) % 2]
				features[Vector2i(x, top.end.y + r)] = face
		var info := {"top": top, "tone": tone, "stairs": -1, "ramp": -1, "cave": -1, "narrow": -1}
		var open := {}
		var x := top.position.x + 1 + _rng.randi_range(0, maxi(0, size.x - need))
		for a in access:
			info[a] = x
			match a:
				"stairs":
					for r in FACE_ROWS:
						for k in 3:
							var c := Vector2i(x + k, top.end.y + r)
							features[c] = STAIRS[r][k]
							stairs[c] = true
							open[c] = true
					for k in 3:
						open[Vector2i(x + k, top.end.y - 1)] = true
					# Rock with shading on each side of the stairs.
					for r in FACE_ROWS:
						if x - 1 > top.position.x:
							features[Vector2i(x - 1, top.end.y + r)] = STAIR_SIDES[0] + Vector2i(0, r)
						if x + 3 < top.end.x - 1:
							features[Vector2i(x + 3, top.end.y + r)] = STAIR_SIDES[1] + Vector2i(0, r)
				"narrow":
					for r in FACE_ROWS:
						var c := Vector2i(x, top.end.y + r)
						features[c] = NARROW_STAIRS[r]
						stairs[c] = true
						open[c] = true
					open[Vector2i(x, top.end.y - 1)] = true
				"ramp":
					for r in FACE_ROWS + 1:
						for k in RAMP_WIDTH:
							var c := Vector2i(x + k, top.end.y - 1 + r)
							features[c] = ramp_set + Vector2i(k, r)
							if r == FACE_ROWS and (k == 0 or k == RAMP_WIDTH - 1):
								# Only the light set has rock-with-grass here.
								features[c] = RAMPS.light + Vector2i(k, r)
							if k == 1 or k == 2:
								ramps[c] = true
								open[c] = true
				"cave":
					for r in FACE_ROWS:
						for k in 3:
							features[Vector2i(x + k, top.end.y + r)] = CAVE + Vector2i(k, r)
					var door := Vector2i(x + 1, top.end.y + FACE_ROWS - 1)
					caves.append(door)
					open[door] = true
			x += widths[a] + 1
		# The top interior and the cut openings are walkable; the rest of
		# the rim and the face are a ledge.
		for y in range(whole.position.y, whole.end.y):
			for xx in range(whole.position.x, whole.end.x):
				var c := Vector2i(xx, y)
				plateau[c] = true
				_solid[c] = true
				if not (open.has(c) or (cells.has(c) and _mask(c, cells, false) == 15)):
					ledge[c] = true
					_blocked[c] = true
		_claim(whole.grow(2))
		plateaus.append(info)
		return info
	return {}


# Pond: two overlapping rectangles centred on the wettest cell of `zone`,
# autotiled with the water set. A shape the set cannot draw is rejected.
# `extras` adds water plants (WP) and water rocks (WR).
func _pond(zone: Rect2i, extras: String) -> bool:
	zone = zone.intersection(Rect2i(2, 2, WIDTH - 4, HEIGHT - 4))
	if zone.size.x < 6 or zone.size.y < 5:
		return false
	var wet := _wettest(zone)
	# The first pond on a map is often a lake: big enough for a deep center.
	var lake := ponds.is_empty() and (recipe_id == 12 or _rng.randf() < LAKE_CHANCE)
	for i in 60:
		if i == 30:
			lake = false
		var a := Rect2i(Vector2i.ZERO, Vector2i(_rng.randi_range(8, 11), _rng.randi_range(7, 9)) if lake else Vector2i(_rng.randi_range(4, 7), _rng.randi_range(3, 5)))
		a.position = wet - a.size / 2
		var b := Rect2i(Vector2i.ZERO, Vector2i(_rng.randi_range(3, 5), _rng.randi_range(3, 4)))
		b.position = a.position + Vector2i(_rng.randi_range(-2, a.size.x - 1), _rng.randi_range(-2, a.size.y - 1))
		var parts: Array[Rect2i] = [a, b]
		if lake:
			# Bumps straddling the lake's edges, so the outline is not a box.
			parts = [a]
			for k in _rng.randi_range(2, 3):
				var bump := Rect2i(Vector2i.ZERO, Vector2i(_rng.randi_range(3, 5), _rng.randi_range(3, 4)))
				var side := _rng.randi() % 4
				var along := Vector2i(_rng.randi_range(a.position.x, a.end.x - bump.size.x), _rng.randi_range(a.position.y, a.end.y - bump.size.y))
				bump.position = [Vector2i(along.x, a.position.y - bump.size.y / 2 - 1), Vector2i(a.end.x - bump.size.x / 2 + 1, along.y),
					Vector2i(along.x, a.end.y - bump.size.y / 2 + 1), Vector2i(a.position.x - bump.size.x / 2 - 1, along.y)][side]
				parts.append(bump)
		var cells := {}
		for r in parts:
			for y in range(r.position.y, r.end.y):
				for x in range(r.position.x, r.end.x):
					cells[Vector2i(x, y)] = true
		var box := _bounds(cells)
		if not zone.encloses(box) or cells.size() < 12 or not _rect_free(box.grow(1)):
			continue
		var tiles := {}
		var ok := true
		for c in cells:
			var t := _pool_tile(c, cells, WATER_SET, WATER_INNER)
			if t == NONE:
				ok = false
				break
			tiles[c] = t
		if not ok:
			continue
		# Deep center: the main rectangle inset by two cells, if every cell
		# there is at least two cells from the shore.
		var core := a.grow(-2) if lake else Rect2i()
		var deep_cells := {}
		if core.size.x >= 3 and core.size.y >= 3:
			for y in range(core.position.y, core.end.y):
				for x in range(core.position.x, core.end.x):
					deep_cells[Vector2i(x, y)] = true
			for c in deep_cells:
				if not _near_all(c, cells, 2):
					deep_cells.clear()
					break
		var wet_props := _water_props(cells, extras, deep_cells)
		if wet_props.is_empty() and extras != "":
			continue # this shape cannot hold the plants or rocks the recipe asks for
		if lake and not deep_cells.is_empty():
			_second_pool(cells, deep_cells)
		for c in cells:
			# Open water (a full fill cell) scrolls; the shore keeps its frames.
			# Right beside a deep pool it is the still frame the sheet draws
			# around the deep set.
			var t: Vector2i = tiles[c]
			if t == WATER_SET + Vector2i(1, 1):
				t = SHALLOW_SURFACE
				if not deep_cells.has(c) and _near(c, deep_cells, 1):
					t = SHALLOW_FRAME[int(_hash(c.x, c.y, 47) * 997.0) % SHALLOW_FRAME.size()]
			features[c] = t
			water[c] = true
			_solid[c] = true
			_blocked[c] = true
		for c in deep_cells:
			var mask := _mask(c, deep_cells, false)
			var tile: Vector2i = DEEP_SET + ROLES[mask]
			if mask == 15 and _open_diagonals(c, deep_cells, false) == 0:
				var h := _hash(c.x, c.y, 41)
				tile = DEEP_SURFACE if h < 0.5 else DEEP_FILLS[int(h * 997.0) % DEEP_FILLS.size()]
			features[c] = tile
			deep[c] = true
		ponds.append(box)
		props.append_array(wet_props)
		_claim(box.grow(2))
		return true
	return false


# A second deep pool in one of the lake's bumps: the largest rectangle of at
# least 3x3 whose cells are all two cells from the shore and one clear cell
# from the first pool (so the two never meet at a corner the set cannot draw).
func _second_pool(cells: Dictionary, deep_cells: Dictionary) -> void:
	var box := _bounds(cells)
	var best := Rect2i()
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			for w in range(5, 2, -1):
				for h in range(4, 2, -1):
					var r := Rect2i(x, y, w, h)
					if r.get_area() <= best.get_area():
						continue
					var ok := true
					for yy in range(r.position.y, r.end.y):
						for xx in range(r.position.x, r.end.x):
							var c := Vector2i(xx, yy)
							if not _near_all(c, cells, 2) or _near(c, deep_cells, 2):
								ok = false
					if ok:
						best = r
	for y in range(best.position.y, best.end.y):
		for x in range(best.position.x, best.end.x):
			deep_cells[Vector2i(x, y)] = true


# True when every cell within `dist` (Chebyshev) of c is in `cells`.
func _near_all(c: Vector2i, cells: Dictionary, dist: int) -> bool:
	for y in range(c.y - dist, c.y + dist + 1):
		for x in range(c.x - dist, c.x + dist + 1):
			if not cells.has(Vector2i(x, y)):
				return false
	return true


# Water plants and rocks for a pond shape. Returns an empty list when a
# requested kind does not fit.
func _water_props(cells: Dictionary, extras: String, deep_cells := {}) -> Array[Dictionary]:
	var shore: Array[Vector2i] = []
	var open: Array[Vector2i] = []
	for c in cells:
		if _mask(c, cells, false) == 15 and _open_diagonals(c, cells, false) == 0:
			open.append(c)
		elif c.y > _bounds(cells).position.y:
			shore.append(c) # not on the north rim, so plants read in front of the water
	var used := {}
	var out: Array[Dictionary] = []
	var anywhere: Array[Vector2i] = []
	anywhere.assign(cells.keys())
	if "WR" in extras and _place_wet(WATER_ROCKS, anywhere, cells, used, 2, out) == 0:
		return []
	if "WP" in extras:
		var plants := _place_wet(SHORE_PLANTS, shore, cells, used, 3, out)
		plants += _place_wet(OPEN_PLANTS, open if not open.is_empty() else anywhere, cells, used, 2, out)
		if plants == 0:
			return []
	if not deep_cells.is_empty():
		var sparkle_spots: Array[Vector2i] = []
		sparkle_spots.assign(deep_cells.keys())
		_place_wet(SPARKLES, sparkle_spots, cells, used, 3, out)
	return out


func _place_wet(arts: Array, spots: Array[Vector2i], cells: Dictionary, used: Dictionary, count: int, out: Array[Dictionary]) -> int:
	var placed := 0
	for i in 40:
		if placed >= count or spots.is_empty():
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c: Vector2i = spots[_rng.randi() % spots.size()]
		var foot := _footprint(art, c)
		var ok := true
		for y in range(foot.position.y - 1, foot.end.y + 1):
			for x in range(foot.position.x - 1, foot.end.x + 1):
				var n := Vector2i(x, y)
				if used.has(n) or (foot.has_point(n) and not cells.has(n)):
					ok = false
		if not ok:
			continue
		out.append({"art": art, "cell": c, "block": false})
		for y in range(foot.position.y, foot.end.y):
			for x in range(foot.position.x, foot.end.x):
				used[Vector2i(x, y)] = true
		placed += 1
	return placed


# Cobble PATH: 2-wide tubes between axis-aligned waypoints. Each waypoint is
# the top-left of a 2x2 block, so a turn is a 2x2 knuckle and a short
# vertical between two horizontals is a lean. `joins` lets the new tubes
# overlap existing path (branches and crossings).
func _route(points: Array, joins := false) -> bool:
	var cells := {}
	for i in range(points.size() - 1):
		var a: Vector2i = points[i]
		var b: Vector2i = points[i + 1]
		if a.x != b.x and a.y != b.y:
			return false
		var lo := a.min(b)
		var hi := a.max(b)
		for y in range(lo.y, hi.y + 2):
			for x in range(lo.x, hi.x + 2):
				cells[Vector2i(x, y)] = true
	for c in cells:
		if not _inside(c) or _solid.has(c) and not path.has(c):
			return false
		if path.has(c) and not joins:
			return false
	for c in cells:
		path[c] = true
		_solid[c] = true
		_taken[c] = true
	return true


func _autotile_path() -> bool:
	for c in path:
		var tile: Vector2i
		var mask := _mask(c, path, true)
		if mask == 15:
			var open := _open_diagonals(c, path, true)
			tile = PATH_FILLS[int(_hash(c.x, c.y, 59) * 997.0) % PATH_FILLS.size()] if open == 0 else PATH_INNER.get(open, NONE)
		else:
			tile = PATH_SET + ROLES[mask] if ROLES.has(mask) else NONE
		if tile == NONE:
			return false
		features[c] = tile
	return true


# Tile for a cell of a 3x3-set blob (pond or patch), or NONE if the set has
# no cell for that neighborhood.
func _pool_tile(c: Vector2i, cells: Dictionary, origin: Vector2i, inner: Dictionary) -> Vector2i:
	var mask := _mask(c, cells, false)
	if not ROLES.has(mask):
		return NONE
	if mask == 15:
		var open := _open_diagonals(c, cells, false)
		if open != 0:
			return inner.get(open, NONE)
	return origin + ROLES[mask]


func _first_water_below(col: int, from_row: int) -> int:
	for y in range(from_row, HEIGHT):
		if water.has(Vector2i(col, y)) or water.has(Vector2i(col + 1, y)):
			return y
	return -1


# Tile animation for an atlas cell, or {} for a still tile. Pond shore
# frames repeat three columns apart; open-water surfaces scroll through four
# neighbouring cells and start at random times.
static func animation_for(atlas: Vector2i) -> Dictionary:
	if WATER_FRAME_REGION.has_point(atlas):
		return {"frames": WATER_FRAMES, "step": WATER_FRAME_STEP, "duration": 0.35, "random": false}
	if atlas == SHALLOW_SURFACE or atlas == DEEP_SURFACE:
		return {"frames": 4, "step": 1, "duration": 0.3, "random": true}
	return {}


# ---------------------------------------------------------------- tones

# Darker grass zones. A smooth tone value lives on every cell corner and is
# interpolated per pixel, so a zone's outline follows a curved noise contour
# instead of the tile grid. Corners on or next to the path or the plateau
# (their tiles bake light lawn) are pinned low, so contours bend away from
# them. Each level covers a fixed share of the map; deeper levels use higher
# cuts on the same field, so they always sit inside the lighter one.
#   Full cells (every corner above the cut) are tiles from the level's fill.
#   Edge cells (the contour crosses them) are drawn per pixel from that same
#   fill, with a dithered rim where the tone is within TONE_BAND of the cut.
const TONE_FREQ := 0.07
const TONE_BAND := 0.03 # width of the dithered rim, in tone units
const TONE_WOBBLE := 0.035 # pixel-scale noise on the cut, so no edge runs straight
const TONE_ANGLE := 0.61 # the field is sampled rotated, off the tile grid
const TONE_CLEAR := 1.0 # corners this close (cells) to path or plateau stay at 0
const TONE_FADE := 4.5 # ...and the field fades back in by this distance
const TONE_MIN_CELLS := [6, 3, 2]
const TONE_GAP := [0.0, 0.12, 0.11] # minimum cut step above the lighter level

var tone_cut: Array[float] = []
var _masks: Array[PackedByteArray] = []
var tone_edges: Array[Dictionary] = [] # per level: cell -> fill atlas
var _corner := PackedFloat32Array()


func _grass_zones() -> void:
	tone_edges.clear()
	tone_cut.clear()
	_corner.resize((WIDTH + 1) * (HEIGHT + 1))
	var clear := _corner_distance()
	var values: Array[float] = []
	for y in HEIGHT + 1:
		for x in WIDTH + 1:
			var i := y * (WIDTH + 1) + x
			var v := _tone(Vector2i(x, y)) * smoothstep(TONE_CLEAR, TONE_FADE, clear[i])
			_corner[i] = v
			if v > 0.0:
				values.append(v)
	values.sort()
	var kept_below := {}
	for level in TONES.size():
		var cover: float = recipe.get("tones", [TONES[0].cover, TONES[1].cover, TONES[2].cover])[level]
		var cut: float = values[int(values.size() * (1.0 - cover))] if not values.is_empty() else 2.0
		if level > 0:
			# Keep a band of each lighter tone wide enough to stand on its own
			# (and to hold a dirt island in that tone) around the darker one.
			cut = maxf(cut, tone_cut[level - 1] + TONE_GAP[level])
		tone_cut.append(cut)
		# Cells this level reaches at all, grouped into components; small
		# specks and anything outside the kept lighter level are dropped.
		var touched := {}
		for y in HEIGHT:
			for x in WIDTH:
				var c := Vector2i(x, y)
				if _cell_max(c) + TONE_BAND * 0.5 + TONE_WOBBLE > cut and (level == 0 or kept_below.has(c)):
					touched[c] = true
		var kept := _drop_small_cells(touched, TONE_MIN_CELLS[level])
		var full := {}
		var edge := {}
		for c in kept:
			var atlas := _tone_fill(level, c)
			if _cell_min(c) - TONE_BAND * 0.5 - TONE_WOBBLE > cut and (level == 0 or tones[level - 1].has(c)):
				full[c] = {"atlas": atlas, "alt": [0, FLIP_H, FLIP_V][int(_hash(c.x, c.y, 23 + level) * 37.0) % 3]}
			else:
				edge[c] = atlas
		tones.append(full)
		tone_edges.append(edge)
		kept_below = kept
	_masks = _build_masks()


# Per-level pixel masks (1 = zone) for the edge cells, full map size. The
# wobble and the dither come from noise images built once per map; every
# level uses the same noisy value against a higher cut, so each level's
# pixels always sit inside the lighter level's.
func tone_masks() -> Array[PackedByteArray]:
	return _masks


func _build_masks() -> Array[PackedByteArray]:
	var w := WIDTH * 16
	var h := HEIGHT * 16
	var wobble := _noise_bytes(w, h, 1.0 / 22.0, 2, map_id)
	var dither := _noise_bytes(w, h, 1.0, 1, map_id + 1)
	var masks: Array[PackedByteArray] = []
	var cw := WIDTH + 1
	for level in TONES.size():
		var mask := PackedByteArray()
		mask.resize(w * h)
		var cut := tone_cut[level]
		for c: Vector2i in tone_edges[level]:
			var a := _corner[c.y * cw + c.x]
			var b := _corner[c.y * cw + c.x + 1]
			var d := _corner[(c.y + 1) * cw + c.x]
			var e := _corner[(c.y + 1) * cw + c.x + 1]
			for y in 16:
				var fy := (y + 0.5) / 16.0
				var left := lerpf(a, d, fy)
				var right := lerpf(b, e, fy)
				var row := (c.y * 16 + y) * w + c.x * 16
				for x in 16:
					var i := row + x
					var f := lerpf(left, right, (x + 0.5) / 16.0)
					f += (wobble[i] / 255.0 - 0.5) * 2.0 * TONE_WOBBLE
					f += (dither[i] / 255.0 - 0.5) * TONE_BAND
					if f > cut:
						mask[i] = 1
		masks.append(mask)
	return masks


func _noise_bytes(w: int, h: int, freq: float, octaves: int, seed_value: int) -> PackedByteArray:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.seed = seed_value
	noise.frequency = freq
	noise.fractal_octaves = octaves
	return noise.get_image(w, h).get_data()


func _tone_fill(level: int, c: Vector2i) -> Vector2i:
	var fills: Array = TONES[level].fills
	var h := _hash(c.x, c.y, 11 + level)
	if level < TONE_TUFTS.size() and h > 0.97:
		return TONE_TUFTS[level]
	return fills[0] if h < 0.55 else fills[1 + int(h * 101.0) % 3]


func _tone(c: Vector2i) -> float:
	var total := 0.0
	var amp := 1.0
	var freq := TONE_FREQ
	var norm := 0.0
	var rx := c.x * cos(TONE_ANGLE) - c.y * sin(TONE_ANGLE)
	var ry := c.x * sin(TONE_ANGLE) + c.y * cos(TONE_ANGLE)
	for octave in 3:
		total += _value_noise(rx * freq + 70.0, ry * freq + 30.0, 300 + octave) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return total / norm


# Bilinear tone at a point in cell units.
func _tone_at(x: float, y: float) -> float:
	var x0 := clampi(floori(x), 0, WIDTH - 1)
	var y0 := clampi(floori(y), 0, HEIGHT - 1)
	var fx := clampf(x - x0, 0.0, 1.0)
	var fy := clampf(y - y0, 0.0, 1.0)
	var w := WIDTH + 1
	var top := lerpf(_corner[y0 * w + x0], _corner[y0 * w + x0 + 1], fx)
	var bottom := lerpf(_corner[(y0 + 1) * w + x0], _corner[(y0 + 1) * w + x0 + 1], fx)
	return lerpf(top, bottom, fy)


func _cell_min(c: Vector2i) -> float:
	var w := WIDTH + 1
	return minf(minf(_corner[c.y * w + c.x], _corner[c.y * w + c.x + 1]), minf(_corner[(c.y + 1) * w + c.x], _corner[(c.y + 1) * w + c.x + 1]))


func _cell_max(c: Vector2i) -> float:
	var w := WIDTH + 1
	return maxf(maxf(_corner[c.y * w + c.x], _corner[c.y * w + c.x + 1]), maxf(_corner[(c.y + 1) * w + c.x], _corner[(c.y + 1) * w + c.x + 1]))


# Distance, in cells, from each corner to the nearest corner of a path or
# plateau cell (3-4 chamfer over the corner grid).
func _corner_distance() -> PackedFloat32Array:
	var w := WIDTH + 1
	var h := HEIGHT + 1
	var d := PackedFloat32Array()
	d.resize(w * h)
	d.fill(9999.0)
	for c in path.keys() + plateau.keys() + ridge.keys():
		for o in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			var q: Vector2i = c + o
			d[q.y * w + q.x] = 0.0
	for y in h:
		for x in w:
			var i := y * w + x
			if x > 0: d[i] = minf(d[i], d[i - 1] + 1.0)
			if y > 0:
				d[i] = minf(d[i], d[i - w] + 1.0)
				if x > 0: d[i] = minf(d[i], d[i - w - 1] + 1.414)
				if x < w - 1: d[i] = minf(d[i], d[i - w + 1] + 1.414)
	for y in range(h - 1, -1, -1):
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if x < w - 1: d[i] = minf(d[i], d[i + 1] + 1.0)
			if y < h - 1:
				d[i] = minf(d[i], d[i + w] + 1.0)
				if x < w - 1: d[i] = minf(d[i], d[i + w + 1] + 1.414)
				if x > 0: d[i] = minf(d[i], d[i + w - 1] + 1.414)
	return d


func _drop_small_cells(on: Dictionary, minimum: int) -> Dictionary:
	var seen := {}
	var out := {}
	for start in on:
		if seen.has(start):
			continue
		var comp: Array[Vector2i] = [start]
		seen[start] = true
		var head := 0
		while head < comp.size():
			var c: Vector2i = comp[head]
			head += 1
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var n: Vector2i = c + Vector2i(dx, dy)
					if on.has(n) and not seen.has(n):
						seen[n] = true
						comp.append(n)
		if comp.size() >= minimum:
			for c in comp:
				out[c] = true
	return out


# ---------------------------------------------------------------- patches

# Round recipes use a rounded rectangle of 4-8 cells; irregular ones join a
# 2x2 arm onto a rectangle, so every cell sits in a 2x2 and every corner has
# a tile. Never a lone cell, a 1xN strip, or a 2-cell L.
func _grow_patches() -> void:
	var shape: String = recipe.patch[0]
	var count := _rng.randi_range(recipe.patch[1], recipe.patch[2])
	var zone_cells: Array[Vector2i] = []
	zone_cells.assign(tones[0].keys() if not tones.is_empty() else [])
	var dark_cells: Array[Vector2i] = []
	dark_cells.assign(tones[1].keys() if tones.size() > 1 else [])
	var tries := 0
	while blobs.size() < count and tries < 500:
		tries += 1
		var irregular := shape == "I" or (shape == "RI" and blobs.size() % 2 == 1)
		var at := Vector2i(_rng.randi_range(2, WIDTH - 6), _rng.randi_range(2, HEIGHT - 6))
		# Every other try starts inside a grass zone, alternating mid and dark.
		var pool: Array[Vector2i] = dark_cells if tries % 4 == 0 and not dark_cells.is_empty() else zone_cells
		if tries % 2 == 0 and not pool.is_empty():
			at = pool[_rng.randi() % pool.size()]
		var placed := {}
		for c in _blob_shape(irregular):
			placed[at + c] = true
		if not _patch_fits(placed):
			continue
		# Inside a single grass tone the dirt set whose baked grass is that
		# tone draws as plain tiles (M on mid, D on dark). On the lawn, Mode A
		# or Mode B as before.
		var inside := _tone_around(placed)
		var mode := "M" if inside == 0 else ("D" if inside == 1 else ("A" if (map_id + blobs.size()) % 2 == 0 else "B"))
		var blob := {"cells": placed, "rect": _bounds(placed), "shape": "I" if irregular else "R", "mode": mode, "tiles": {}, "baked": {}}
		# Round islands use the smooth dirt sets; irregular ones the ragged
		# (worn, speckled) sets of the same tones.
		var sets := {"A": [PATCH_SET_A, PATCH_INNER_A], "M": [PATCH_SET_B, PATCH_INNER_B], "D": [PATCH_SET_D, PATCH_INNER_D], "baked": [PATCH_SET_B, PATCH_INNER_B]}
		if irregular:
			sets = {"A": [RAGGED_SET_A, RAGGED_INNER_A], "M": [RAGGED_SET_B, RAGGED_INNER_B], "D": [RAGGED_SET_D, RAGGED_INNER_D], "baked": [RAGGED_SET_B, RAGGED_INNER_B],
				"L": [RAGGED_SET_L, RAGGED_INNER_L]}
			# On plain lawn, half the ragged islands use the set whose baked
			# grass is the lawn green, as plain tiles (mode L).
			if mode == "A" and _tone_share(0, placed) == 0.0 and _hash(at.x, at.y, 71) < 0.5:
				mode = "L"
				blob.mode = "L"
		var chosen: Array = sets.get(mode, sets.A)
		var ok := true
		for c in placed:
			var a := _pool_tile(c, placed, chosen[0], chosen[1])
			var b := _pool_tile(c, placed, sets.baked[0], sets.baked[1])
			if a == NONE:
				ok = false
				break
			blob.tiles[c] = a
			blob.baked[c] = b
		if not ok:
			continue
		blobs.append(blob)
		for c in placed:
			_taken[c] = true
			_solid[c] = true
		_claim(blob.rect.grow(1))
	if blobs.size() < recipe.patch[1]:
		dropped.append("patches (%d of %d fit)" % [blobs.size(), recipe.patch[1]])


# The tone level a blob sits in, or -1. The blob's own cells must be at
# least 95% that level and at most 5% the level above; its one-cell ring at
# least 85% and at most 15%. The baked grass in a dirt tile only shows at
# the blob's rim, so this keeps the tile's grass and the ground the same
# green there.
func _tone_around(cells: Dictionary) -> int:
	var ring := {}
	for c in cells:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var n: Vector2i = c + Vector2i(dx, dy)
				if not cells.has(n):
					ring[n] = true
	for level in [1, 0]:
		if _tone_share(level, cells) >= 0.95 and _tone_share(level + 1, cells) <= 0.05 \
				and _tone_share(level, ring) >= 0.85 and _tone_share(level + 1, ring) <= 0.15:
			return level
	return -1


func _tone_share(level: int, cells: Dictionary) -> float:
	if level >= tones.size():
		return 0.0
	var n := 0
	for c in cells:
		n += _tone_pixels(level, c)
	return n / (256.0 * cells.size())


# How many of a cell's 256 pixels belong to a tone level.
func _tone_pixels(level: int, c: Vector2i) -> int:
	if tones[level].has(c):
		return 256
	if not tone_edges[level].has(c):
		return 0
	var w := WIDTH * 16
	var n := 0
	var mask: PackedByteArray = _masks[level]
	for y in 16:
		var row := (c.y * 16 + y) * w + c.x * 16
		for x in 16:
			n += mask[row + x]
	return n


func _blob_shape(irregular: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var a: Vector2i = ROUND_SHAPES[_rng.randi() % ROUND_SHAPES.size()]
	var arm := Vector2i(-99, -99)
	if irregular:
		# A 3x2 or 2x3 base with a 2x2 arm overlapping it by one row or
		# column at a corner: an 8-cell L whose join is an inner corner.
		a = [Vector2i(3, 2), Vector2i(2, 3)][_rng.randi() % 2]
		var arms := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, -1), Vector2i(1, -1)] if a.x == 3 \
			else [Vector2i(1, 0), Vector2i(1, 1), Vector2i(-1, 0), Vector2i(-1, 1)]
		arm = arms[_rng.randi() % arms.size()]
	for y in a.y:
		for x in a.x:
			out.append(Vector2i(x, y))
	if irregular:
		for y in 2:
			for x in 2:
				var c: Vector2i = arm + Vector2i(x, y)
				if not c in out:
					out.append(c)
	return out


func _patch_fits(cells: Dictionary) -> bool:
	if cells.size() < 3 or cells.size() > 8:
		return false
	for c in cells:
		if c.x < 1 or c.y < 1 or c.x >= WIDTH - 1 or c.y >= HEIGHT - 1:
			return false
		if _taken.has(c):
			return false
		if _near(c, path, 3) or _near(c, fence, 2) or _near(c, water, 2):
			return false
		for b in blobs:
			if _near(c, b.cells, 4):
				return false
	return true


# ---------------------------------------------------------------- hedges

# Hedgerows: two cells thick, straight (2 x 4-9) or an L of two such runs,
# autotiled with a hedge blob set so every end and corner is rounded. They
# block. A hedgerow that would cut the spawn off from any goal is removed.
func _grow_hedges() -> void:
	var flags: Array = recipe.props
	if not ("bushes" in flags or "bushes heavy" in flags or "hedges heavy" in flags or "F" in recipe.height):
		return
	var want := _rng.randi_range(1, 3 if "bushes heavy" in flags else 2)
	if "hedges heavy" in flags:
		want = _rng.randi_range(4, 6)
	for i in 300:
		if hedgerows >= want:
			break
		var cells := _hedge_shape()
		var at := Vector2i(_rng.randi_range(1, WIDTH - 10), _rng.randi_range(1, HEIGHT - 10))
		var placed := {}
		for c in cells:
			placed[at + c] = true
		var ok := true
		for c in placed:
			if not _inside(c) or _taken.has(c) or _near(c, path, 2) or _near(c, fence, 1) or c.distance_to(spawn) < 5:
				ok = false
				break
		if not ok:
			continue
		# Contrast with the ground: the dark hedge on plain lawn, the light
		# (pale sage) hedge only deep inside a dark zone. Anywhere between,
		# neither reads as a hedge, so the row is not placed.
		var ring := _bounds(placed).grow(1)
		var around := {}
		for y in range(ring.position.y, ring.end.y):
			for x in range(ring.position.x, ring.end.x):
				around[Vector2i(x, y)] = true
		var set_i := -1
		if _tone_share(0, around) == 0.0:
			set_i = 0
		elif _tone_share(1, around) >= 0.9:
			set_i = 1
		if set_i < 0:
			continue
		var tiles := {}
		for c in placed:
			var t := _hedge_tile(c, placed, HEDGE_SETS[set_i])
			if t == NONE:
				ok = false
				break
			tiles[c] = t
		if not ok:
			continue
		for c in placed:
			_blocked[c] = true
		var reachable := true
		for g in goals:
			if not _reaches(spawn, g):
				reachable = false
		if not reachable:
			for c in placed:
				_blocked.erase(c)
			continue
		for c in placed:
			hedge[c] = tiles[c]
			_solid[c] = true
		_claim(_bounds(placed).grow(1))
		hedgerows += 1


# Hedge tile: the blob set with inner corners (one or two opposite open
# diagonals). The sheet's thin diagonal pieces (0-1, 4) and (0-1, 8) draw
# as scattered leaf bits, not a hedge, so they are not used.
func _hedge_tile(c: Vector2i, cells: Dictionary, hedge_set: Dictionary) -> Vector2i:
	return _pool_tile(c, cells, hedge_set.blob, hedge_set.inner)


func _hedge_shape() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var kind := _rng.randf()
	if kind < 0.2:
		# A diagonal hedge: 2x2 blocks each one cell down and across.
		var dx := 1 if _rng.randf() < 0.5 else -1
		for b in _rng.randi_range(3, 5):
			for y in 2:
				for x in 2:
					var c := Vector2i(4 + b * dx + x, b + y)
					if not c in out:
						out.append(c)
		return out

	var length := _rng.randi_range(5, 10)
	var horizontal := _rng.randf() < 0.5
	for i in length:
		for t in 2:
			out.append(Vector2i(i, t) if horizontal else Vector2i(t, i))
	if _rng.randf() < 0.35:
		# An L: a second run from one end, turning 90 degrees.
		var arm := _rng.randi_range(3, 6)
		for i in range(2, arm + 2):
			for t in 2:
				var c := Vector2i(length - 2 + t, i) if horizontal else Vector2i(i, length - 2 + t)
				if not c in out:
					out.append(c)
	return out


# ---------------------------------------------------------------- accents

# Grass accents: small blobs of the next darker tone, from the baked sets,
# only where the ground is exactly the tone baked into the cell (plain lawn,
# pure mid, or pure dark), so no rectangle shows. Rounded rectangles, Ls
# (hole-ring inner corners), and rings (a 5x5 with the hole ring inside).
func _grass_accents() -> void:
	var want := _rng.randi_range(2, 4) + (3 if "carpets heavy" in recipe.props else 0)
	for i in 400:
		if accent_count >= want:
			return
		var shape := _rng.randf()
		var cells := {}
		var ring_cells := {}
		var at := Vector2i(_rng.randi_range(1, WIDTH - 7), _rng.randi_range(1, HEIGHT - 7))
		if shape < 0.15:
			for y in 5:
				for x in 5:
					cells[at + Vector2i(x, y)] = true
					if x >= 1 and x <= 3 and y >= 1 and y <= 3:
						ring_cells[at + Vector2i(x, y)] = Vector2i(x - 1, y - 1)
		else:
			for c in _blob_shape(shape > 0.7):
				cells[at + c] = true
		var around := {}
		for c in cells:
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					around[c + Vector2i(dx, dy)] = true
		var ok := true
		for c in around:
			if not _inside(c) or _solid.has(c) or accents.has(c) or lawn.get(c, NONE) == LAWN_FLOWERS:
				ok = false
				break
		if not ok:
			continue
		var level := -2
		if _tone_share(0, around) == 0.0:
			level = -1
		elif _tone_share(0, around) == 1.0 and _tone_share(1, around) == 0.0:
			level = 0
		elif _tone_share(1, around) == 1.0 and _tone_share(2, around) == 0.0:
			level = 1
		if level == -2:
			continue
		var a: Dictionary = ACCENTS[level + 1]
		var inner := {2: a.ring, 4: a.ring + Vector2i(2, 0), 1: a.ring + Vector2i(0, 2), 8: a.ring + Vector2i(2, 2)}
		var tiles := {}
		for c in cells:
			var t: Vector2i = a.ring + ring_cells[c] if ring_cells.has(c) else _pool_tile(c, cells, a.blob, inner)
			if t == NONE:
				ok = false
				break
			tiles[c] = t
		if not ok:
			continue
		for c in tiles:
			accents[c] = tiles[c]
		accent_count += 1


# ---------------------------------------------------------------- props

func _place_props() -> void:
	var flags: Array = recipe.props
	var obstacles := "LR obstacles" in flags
	if "bushes" in flags or "bushes heavy" in flags:
		var n := 12 if "bushes heavy" in flags else 7
		_scatter_props(HEDGES, n / 2 + 1, 6.0)
		_scatter_props(SHRUBS, n, 5.0)
	if "LR" in flags or obstacles:
		_scatter_props(LAND_ROCKS, 7, 6.0)
	if obstacles:
		# Obstacle recipes add big rocks two to four cells off the path, so
		# they stand in the way without closing it.
		_scatter_props(BIG_ROCKS, 5, 5.0, true)
	if "CF" in flags:
		_scatter_props(["campfire"], 1, 1.0)
	if "CF big" in flags:
		# The camp fire burns between the buildings, with ash beside it.
		var center := spawn
		if houses.size() >= 2:
			center = (_door(houses[0]) + _door(houses[1])) / 2 + Vector2i(0, 3)
		elif not houses.is_empty():
			center = _door(houses[0]) + Vector2i(0, 4)
		_prop_near(["campfire_big"], center, 5, 1)
		for p in props:
			if p.has("art") and p.art == "campfire_big":
				_prop_near(["ash"], p.cell, 2, 2)
	if "logs heavy" in flags:
		_scatter_props(LOGS, 6, 5.0)
	if "ruins" in flags:
		for info in plateaus:
			_prop_near(YARD_CLUTTER, info.top.get_center(), 9, 4)
	if "yard clutter" in flags:
		for h in houses:
			_prop_near(YARD_CLUTTER, _door(h), 6, 2)
	if "outcrops" in flags:
		_place_outcrops(_rng.randi_range(5, 8), "stone" if "ruins" in flags else "")
	_hang_vines()
	if "T" in flags:
		_place_torches()
	_place_signs(recipe.signs)
	_place_clutter()


# Clutter: a couple of fallen logs anywhere on the lawn, and crates and
# chests just outside each house's buffer. All of it collides.
func _place_clutter() -> void:
	_scatter_props(LOGS, _rng.randi_range(1, 3), 8.0)
	for h in houses:
		var door := _door(h)
		if h.id == 4:
			props.append({"art": "deck", "cell": door, "block": false}) # porch planks at the shed door
		# A flowerpot beside the doorstep of a cottage or hut, if the ground is free.
		for side in [Vector2i(-1, 0), Vector2i(2, 0)]:
			var pot: Vector2i = door + side
			if h.id <= 3 and _inside(pot) and not _solid.has(pot):
				props.append({"art": "flowerpot", "cell": pot, "block": false})
				_solid[pot] = true
				_taken[pot] = true
				break
		_prop_near(["tall_grass"], door, 5, 1)
		var size := _cells(HOUSES[h.id].region.size)
		var near := Rect2i(h.origin, size).grow(6)
		var placed := 0
		for i in 200:
			if placed >= 2:
				break
			var art: String = YARD_CLUTTER[_rng.randi() % YARD_CLUTTER.size()]
			var c := near.position + Vector2i(_rng.randi_range(0, near.size.x - 1), _rng.randi_range(0, near.size.y - 1))
			var foot := _footprint(art, c)
			if not _rect_free(foot) or _near_rect(foot, path, 1):
				continue
			var prop := {"art": art, "cell": c, "block": true}
			props.append(prop)
			_claim(foot.grow(1))
			_solidify(foot)
			_block_collider(prop)
			placed += 1


func _scatter_props(arts: Array, count: int, gap: float, by_path := false) -> Array[Dictionary]:
	var added: Array[Dictionary] = []
	var anchors: Array[Vector2i] = []
	for i in 600:
		if added.size() >= count:
			break
		var art: String = arts[_rng.randi() % arts.size()]
		var c := Vector2i(_rng.randi_range(2, WIDTH - 3), _rng.randi_range(2, HEIGHT - 3))
		var foot := _footprint(art, c)
		if not _rect_free(foot) or _near_rect(foot, path, 1) or c.distance_to(spawn) < 4:
			continue
		if by_path and not _near_rect(foot, path, 4):
			continue
		var ok := true
		for a in anchors:
			if Vector2(c - a).length() < gap:
				ok = false
				break
		if not ok:
			continue
		var prop := {"art": art, "cell": c, "block": PROPS[art].block != Vector2.ZERO and not art in PEBBLES}
		props.append(prop)
		added.append(prop)
		anchors.append(c)
		_claim(foot)
		_solidify(foot)
		if prop.block:
			_block_collider(prop)
	return added


# Marks every cell the prop's collider overlaps as unwalkable. The collider
# is `block` wide and tall, centred on the foot pixel and resting on it.
func _block_collider(prop: Dictionary) -> void:
	for c in _collider_cells(prop):
		_blocked[c] = true


func _collider_cells(prop: Dictionary) -> Array[Vector2i]:
	var art: Dictionary = PROPS[prop.art]
	var foot: Vector2 = Vector2((prop.cell + art.cell) * 16 + art.base)
	var box := Rect2(foot - Vector2(art.block.x / 2.0, art.block.y), art.block)
	var out: Array[Vector2i] = []
	for y in range(floori(box.position.y / 16.0), floori((box.end.y - 0.01) / 16.0) + 1):
		for x in range(floori(box.position.x / 16.0), floori((box.end.x - 0.01) / 16.0) + 1):
			out.append(Vector2i(x, y))
	return out


# Torches stand on the two gate posts, flank a cave mouth, flank the path
# at the doorstep, or flank the foot of a plateau's ramp or stairs.
func _place_torches() -> void:
	var spots: Array[Vector2i] = []
	if not caves.is_empty():
		spots = [caves[0] + Vector2i(-2, 1), caves[0] + Vector2i(2, 1)]
	elif recipe.height == "R" and not houses.is_empty():
		var door := _door(houses[0])
		for c in ridge_rock:
			if c.x == door.x - 1 or c.x == door.x + 2:
				spots.append(c + Vector2i(0, 2))
	elif gate.x >= 0:
		spots = [gate + Vector2i(-1, 0), gate + Vector2i(2, 0)]
	elif not houses.is_empty():
		var door := _door(houses[0])
		spots = [door + Vector2i(-1, 1), door + Vector2i(2, 1)]
	elif not plateaus.is_empty():
		# Either side of the foot of the first plateau's way up.
		var info: Dictionary = plateaus[0]
		var foot: int = info.top.end.y + FACE_ROWS
		var x0: int = info.ramp if info.ramp >= 0 else info.stairs
		var w := RAMP_WIDTH if info.ramp >= 0 else 3
		spots = [Vector2i(x0 - 1, foot), Vector2i(x0 + w, foot)]
	if plaza.size != Vector2i.ZERO:
		spots = [plaza.position + Vector2i(-1, -1), Vector2i(plaza.end.x, plaza.position.y - 1),
			Vector2i(plaza.position.x - 1, plaza.end.y), plaza.end]
	for c in spots:
		if not _inside(c) or (not fence.has(c) and _solid.has(c)):
			continue
		# A thin post collider at the foot; the torch sorts at its foot, so a
		# character north of it passes behind the flame.
		var torch := {"art": TORCHES[_rng.randi() % TORCHES.size()], "cell": c, "block": true}
		props.append(torch)
		_block_collider(torch)
		_taken[c] = true
		_solid[c] = true
	if spots.is_empty():
		dropped.append("torches (no gate or house)")


# Props of `arts` on free lawn within `radius` of `center`.
func _prop_near(arts: Array, center: Vector2i, radius: int, count: int) -> void:
	var placed := 0
	for i in 200:
		if placed >= count:
			return
		var art: String = arts[_rng.randi() % arts.size()]
		var c := center + Vector2i(_rng.randi_range(-radius, radius), _rng.randi_range(-radius, radius))
		var foot := _footprint(art, c)
		if not _rect_free(foot) or _near_rect(foot, path, 1):
			continue
		var prop := {"art": art, "cell": c, "block": PROPS[art].block != Vector2.ZERO}
		props.append(prop)
		_claim(foot.grow(1))
		_solidify(foot)
		if prop.block:
			_block_collider(prop)
		placed += 1


# Rock outcrops on free lawn, each in the tone of the ground under it (or
# all stone). They block; one that would cut off a goal is not placed.
func _place_outcrops(count: int, only: String) -> void:
	var placed := 0
	for i in 400:
		if placed >= count:
			return
		var c := Vector2i(_rng.randi_range(2, WIDTH - 3), _rng.randi_range(6, HEIGHT - 2))
		var tone := only
		if tone == "":
			var level := _tone_level(c)
			tone = "light" if level < 0 else ("mid" if level == 0 else "dark")
		var art: String = OUTCROPS[tone]
		var foot := _footprint(art, c)
		if not _rect_free(foot) or _near_rect(foot, path, 1) or c.distance_to(spawn) < 5:
			continue
		var prop := {"art": art, "cell": c, "block": true}
		_block_collider(prop)
		var reachable := true
		for g in goals:
			if not _reaches(spawn, g):
				reachable = false
		if not reachable:
			for cell in _collider_cells(prop):
				_blocked.erase(cell)
			continue
		props.append(prop)
		_claim(foot.grow(1))
		_solidify(foot)
		placed += 1


# One to three vines hung on each plateau face, away from the cuts.
func _hang_vines() -> void:
	for info in plateaus:
		var top: Rect2i = info.top
		var bottom := top.end.y + FACE_ROWS - 1
		var hung := 0
		for i in 30:
			if hung >= 3:
				break
			var x := _rng.randi_range(top.position.x + 1, top.end.x - 2)
			var c := Vector2i(x, bottom)
			var clear := ledge.has(c)
			for k in ["stairs", "ramp", "cave", "narrow"]:
				var w: int = {"stairs": 3, "ramp": RAMP_WIDTH, "cave": 3, "narrow": 1}[k]
				if info[k] >= 0 and x >= info[k] - 1 and x <= info[k] + w:
					clear = false # keep clear of the cuts
			for p in props:
				if p.has("art") and p.art in VINES and abs(p.cell.x - x) < 2 and p.cell.y == bottom:
					clear = false
			if not clear:
				continue
			var art: String = VINES[_rng.randi() % VINES.size()]
			props.append({"art": art, "cell": c, "block": false})
			hung += 1


func _place_signs(count: int) -> void:
	if count <= 0:
		return
	var ids := range(SIGN.size())
	for i in range(ids.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var t = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	# Beside the gate first, then lawn cells just north of the path.
	var spots: Array[Vector2i] = []
	if gate.x >= 0:
		spots.append(gate + Vector2i(-1, 1))
		spots.append(gate + Vector2i(2, 1))
	var along := path.keys()
	along.sort_custom(func(a, b): return a.x < b.x if a.x != b.x else a.y < b.y)
	for c in along:
		spots.append(c + Vector2i.UP)
		spots.append(c + Vector2i.LEFT)
	var placed := 0
	var last: Array[Vector2i] = []
	for c in spots:
		if placed >= count:
			break
		if not _inside(c) or _solid.has(c):
			continue
		var crowded := false
		for l in last:
			if Vector2(c - l).length() < 6.0:
				crowded = true
		if crowded:
			continue
		props.append({"sign": ids[placed], "cell": c, "block": true})
		_taken[c] = true
		_solid[c] = true
		_blocked[c] = true
		last.append(c)
		placed += 1


func _place_trees() -> void:
	var anchors: Array[Vector2i] = []
	for i in 2500:
		var art: String = TREES[_rng.randi() % TREES.size()]
		var c := Vector2i(_rng.randi_range(0, WIDTH - 1), _rng.randi_range(2, HEIGHT - 1))
		# On the darkest grass, the shade trees (their base row is shade).
		var shade := tones.size() > 2 and tones[2].has(c)
		if shade:
			art = SHADE_TREES[_rng.randi() % SHADE_TREES.size()]
		var foot := _footprint(art, c)
		var clipped := foot.intersection(Rect2i(0, 0, WIDTH, HEIGHT))
		if not _rect_free(clipped) or _near_rect(clipped, path, 1) or c.distance_to(spawn) < 5:
			continue
		var ok := true
		for a in anchors:
			if Vector2(c - a).length() < 6.5:
				ok = false
				break
		if not ok:
			continue
		var tree := {"art": art, "cell": c, "block": true}
		props.append(tree)
		anchors.append(c)
		_claim(clipped)
		_solidify(clipped)
		_block_collider(tree)


# ---------------------------------------------------------------- liveliness floor
# Every camera-sized window should have something moving in it. After the map
# is placed, the liveliness estimate (scripts/liveliness_features.gd with the
# weights below) is worked out for every 43x18-cell window; while the weakest
# is under FLOOR, it gets a motion anchor: a pair of wayside lanterns (the
# torch) flanking the path if the path crosses it, otherwise a campfire in a
# clearing. At most FLOOR_ANCHORS per map; an anchor that would cut the spawn
# off from a goal is not placed. The weights are frozen here from the
# 2026-09-27 calibration, so recalibrating never rearranges a map.
const FLOOR := 0.09 # % of pixels moving per frame
const FLOOR_ANCHORS := 3
const FLOOR_VIEW := Vector2i(43, 18)
const FLOOR_WEIGHTS := {"leaves": 2.084, "water_anim": 9.745, "sparkles": 25.091, "glow": 22.858, "smoke": 132.027,
	"butterflies": 1.173, "fireflies": 0.983, "streak": 0.005, "animals": 0.243}

func _liveliness_floor() -> void:
	var features = load("res://scripts/liveliness_features.gd") # load, not preload: it preloads this script
	floor_notes.clear()
	var tried := {}
	for n in FLOOR_ANCHORS + 2:
		var weakest := _weakest_window(features, tried)
		if n == 0:
			floor_before = weakest.value
		floor_after = weakest.value
		if weakest.value >= FLOOR or floor_notes.size() >= FLOOR_ANCHORS or weakest.rect.size == Vector2i.ZERO:
			return
		var note := _floor_anchor(weakest.rect, weakest.value < FLOOR * 0.5)
		if note == "":
			tried[weakest.rect.position] = true # nothing fits here; look at the next weakest
		else:
			floor_notes.append(note)


# The window with the least expected motion, skipping `tried` origins:
# {rect, value}.
func _weakest_window(features, tried: Dictionary) -> Dictionary:
	var g: Dictionary = features.grid(self)
	var m := PackedFloat32Array()
	m.resize(WIDTH * HEIGHT)
	m.fill(0.0)
	for f in FLOOR_WEIGHTS:
		var a: PackedFloat32Array = g[f]
		var w: float = FLOOR_WEIGHTS[f]
		for i in WIDTH * HEIGHT:
			m[i] += w * a[i]
	var sat := PackedFloat32Array()
	sat.resize((WIDTH + 1) * (HEIGHT + 1))
	sat.fill(0.0)
	var s := WIDTH + 1
	for y in HEIGHT:
		for x in WIDTH:
			var i := (y + 1) * s + x + 1
			sat[i] = m[y * WIDTH + x] + sat[i - 1] + sat[i - s] - sat[i - s - 1]
	var best := {"rect": Rect2i(), "value": INF}
	var area := float(FLOOR_VIEW.x * FLOOR_VIEW.y)
	var lowest := INF
	for y in HEIGHT - FLOOR_VIEW.y + 1:
		for x in WIDTH - FLOOR_VIEW.x + 1:
			var v := (sat[(y + FLOOR_VIEW.y) * s + x + FLOOR_VIEW.x] - sat[y * s + x + FLOOR_VIEW.x]
				- sat[(y + FLOOR_VIEW.y) * s + x] + sat[y * s + x]) / area
			lowest = minf(lowest, v)
			if not tried.has(Vector2i(x, y)) and v < best.value:
				best = {"rect": Rect2i(x, y, FLOOR_VIEW.x, FLOOR_VIEW.y), "value": v}
	if best.value == INF:
		best.value = lowest
	return best


# Lanterns across the path if the path crosses the window's middle, else a
# campfire; a very quiet window (`big`) gets the campfire first. Returns a
# note, or "" if nothing fit.
func _floor_anchor(win: Rect2i, big: bool) -> String:
	var inner := win.grow_individual(-6, -3, -6, -3)
	var order := ["campfire", "lanterns"] if big else ["lanterns", "campfire"]
	for kind in order:
		if kind == "lanterns" and _floor_lanterns(inner):
			return "lanterns"
		if kind == "campfire" and _floor_campfire(inner):
			return "campfire"
	return ""


# Two torches facing each other across the path, on free lawn.
func _floor_lanterns(inner: Rect2i) -> bool:
	var cells: Array = path.keys().filter(func(c): return inner.has_point(c))
	cells.sort()
	for i in range(cells.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = cells[i]
		cells[i] = cells[j]
		cells[j] = tmp
	for c in cells.slice(0, 40):
		for d in [Vector2i(0, 1), Vector2i(1, 0)]:
			var a: Vector2i = c
			while path.has(a - d):
				a -= d
			var b: Vector2i = c
			while path.has(b + d):
				b += d
			var spots: Array[Vector2i] = [a - d, b + d]
			var ok := true
			for p in spots:
				if not _inside(p) or _taken.has(p) or _solid.has(p) or water.has(p) or plateau.has(p) or hedge.has(p) or ridge.has(p):
					ok = false
			if not ok:
				continue
			var torches: Array[Dictionary] = []
			for p in spots:
				torches.append({"art": TORCHES[_rng.randi() % TORCHES.size()], "cell": p, "block": true})
			if not _try_block(torches):
				continue
			for t in torches:
				props.append(t)
				_taken[t.cell] = true
				_solid[t.cell] = true
				deco.erase(t.cell)
			return true
	return false


# A campfire on free lawn, clear of the path.
func _floor_campfire(inner: Rect2i) -> bool:
	for i in 120:
		var c := Vector2i(_rng.randi_range(inner.position.x, inner.end.x - 1), _rng.randi_range(inner.position.y, inner.end.y - 1))
		var foot := _footprint("campfire", c)
		if not _rect_free(foot.grow(1)) or _near_rect(foot, path, 1):
			continue
		var fire := {"art": "campfire", "cell": c, "block": true}
		if not _try_block([fire]):
			continue
		props.append(fire)
		_claim(foot.grow(1))
		_solidify(foot)
		for y in range(foot.position.y, foot.end.y):
			for x in range(foot.position.x, foot.end.x):
				deco.erase(Vector2i(x, y))
		return true
	return false


# Blocks the props' collider cells if every goal stays reachable; true if so.
func _try_block(new_props: Array) -> bool:
	var added: Array[Vector2i] = []
	for p in new_props:
		for c in _collider_cells(p):
			if not _blocked.has(c):
				_blocked[c] = true
				added.append(c)
	for g in goals:
		if not _reaches(spawn, g):
			for c in added:
				_blocked.erase(c)
			return false
	return true


# Plateau tops get one or two trees on light, mid, and dark tops (the plain
# crowns: the grassy-base variants bake lawn green), set back from the rim and
# the way up. A tree that would cut the spawn off from a goal is not placed.
const PLATEAU_TREES := ["tree_a", "tree_b", "bloom_a", "bloom_b"]

func _plateau_trees() -> void:
	for info in plateaus:
		if info.tone == "stone":
			continue
		var top: Rect2i = info.top
		var want := 2 if top.size.x >= 14 else 1
		var placed: Array[Vector2i] = []
		for i in 150:
			if placed.size() >= want:
				break
			var art: String = PLATEAU_TREES[_rng.randi() % PLATEAU_TREES.size()]
			var c := Vector2i(_rng.randi_range(top.position.x + 2, top.end.x - 3), _rng.randi_range(top.position.y + 1, top.end.y - 2))
			var foot := _footprint(art, c)
			if foot.position.x < 0 or foot.end.x > WIDTH:
				continue # a crown may reach past the top edge; the trunk may not
			var near := false
			for p in placed:
				if Vector2(c - p).length() < 5.0:
					near = true
			for x in [info.stairs, info.ramp, info.cave, info.narrow]:
				if x >= 0 and c.x >= x - 1 and c.x <= x + RAMP_WIDTH and c.y >= top.end.y - 2:
					near = true # keep the landing at the top of the way up open
			if near:
				continue
			var tree := {"art": art, "cell": c, "block": true}
			var cells := _collider_cells(tree)
			var ok := true
			# The whole top counts as solid ground; other props on it (outcrops)
			# mark their colliders blocked, so that is the test.
			for k in cells + [c]:
				if not plateau.has(k) or ledge.has(k) or stairs.has(k) or ramps.has(k) or ridge.has(k) or _blocked.has(k):
					ok = false
			if not ok:
				continue
			for k in cells:
				_blocked[k] = true
			var reach := true
			for g in goals:
				if not _reaches(spawn, g):
					reach = false
			if not reach:
				for k in cells:
					_blocked.erase(k)
				continue
			props.append(tree)
			placed.append(c)
			for k in cells + [c]:
				_solid[k] = true
				_taken[k] = true


# Grass deco picked by the ground under it: flowers and sprouts on the lawn
# and mid zones, the darkest sprouts on dark and deep zones. A few 3x3
# flower carpets go on open lawn.
func _scatter_deco() -> void:
	# Flower carpets: the whole 3x3, or just its four corner cells as a
	# compact 2x2 cluster. At least five cells apart, on plain lawn.
	var want_carpets := _rng.randi_range(1, 3) + (4 if "carpets heavy" in recipe.props else 0)
	var placed_carpets: Array[Vector2i] = []
	for i in 600:
		if carpets >= want_carpets:
			break
		var small := _rng.randf() < 0.5
		var cells: Array[Vector2i] = []
		var roles: Array[Vector2i] = []
		for y in 3:
			for x in 3:
				if small and (x == 1 or y == 1):
					continue
				roles.append(Vector2i(x, y))
				cells.append(Vector2i(mini(x, 1), mini(y, 1)) if small else Vector2i(x, y))
		var at := Vector2i(_rng.randi_range(1, WIDTH - 4), _rng.randi_range(1, HEIGHT - 4))
		var ok := true
		for p in placed_carpets:
			if Vector2(at - p).length() < 6.0:
				ok = false
		for c in cells:
			var n := at + c
			if _solid.has(n) or deco.has(n) or accents.has(n) or _tone_level(n) >= 0 or _near(n, path, 1):
				ok = false
		if not ok:
			continue
		for k in cells.size():
			deco[at + cells[k]] = FLOWER_CARPET + roles[k]
		placed_carpets.append(at)
		carpets += 1
	for i in 1400:
		var c := Vector2i(_rng.randi_range(0, WIDTH - 1), _rng.randi_range(0, HEIGHT - 1))
		if _solid.has(c) or deco.has(c):
			continue
		var crowded := false
		for d in range(-2, 3):
			for e in range(-2, 3):
				if (d != 0 or e != 0) and deco.has(c + Vector2i(d, e)) and Vector2(d, e).length() < 2.6:
					crowded = true
		if crowded:
			continue
		var pool: Array
		if _tone_level(c) >= 1:
			pool = DARK_TUFTS if _rng.randf() < 0.85 else FLOWERS
		else:
			pool = FLOWERS if _rng.randf() < 0.4 else TUFTS
		deco[c] = pool[_rng.randi() % pool.size()]


# True for a flower deco tile: a single flower or part of a flower carpet.
func _is_flower(atlas: Vector2i) -> bool:
	return atlas in FLOWERS or Rect2i(FLOWER_CARPET, Vector2i(3, 3)).has_point(atlas)


# Darkest tone level with a tile or edge at c, or -1 for plain lawn.
func _tone_level(c: Vector2i) -> int:
	for level in range(tones.size() - 1, -1, -1):
		if tones[level].has(c) or tone_edges[level].has(c):
			return level
	return -1


# ---------------------------------------------------------------- verify

func _verify() -> String:
	var fails := PackedStringArray()
	for c in path:
		var t: Vector2i = features.get(c, NONE)
		if t == NONE:
			fails.append("path cell %s has no tile" % c)
		elif t in PATH_FILLS and (_mask(c, path, true) != 15 or _open_diagonals(c, path, true) != 0):
			fails.append("fill on a cap or knuckle at %s" % c)
	if houses.size() != recipe.houses.size():
		fails.append("houses %d, recipe wants %d" % [houses.size(), recipe.houses.size()])
	for i in houses.size():
		if i < recipe.houses.size() and houses[i].id != recipe.houses[i]:
			fails.append("house %d is prefab %d, recipe names %d" % [i, houses[i].id, recipe.houses[i]])
	if leans > 2:
		fails.append("%d leans" % leans)
	var want_ponds := 2 if "P2" in recipe.water else (1 if "P" in recipe.water else 0)
	if recipe.water == "P if blob" and "pond (no moisture blob)" in dropped:
		want_ponds = 0
	if recipe.water.begins_with("P if room") and "pond (no room)" in dropped:
		want_ponds = 0
	if ponds.size() != want_ponds:
		fails.append("ponds %d, recipe wants %d" % [ponds.size(), want_ponds])
	if "C" in recipe.height and plateau.is_empty():
		fails.append("no plateau")
	if "C" in recipe.height:
		for info in plateaus:
			if info.stairs < 0 and info.ramp < 0 and info.cave < 0 and info.narrow < 0:
				fails.append("plateau with no way up")
		if recipe.height == "C2" and plateaus.size() < 2:
			fails.append("terraces need two plateaus")
		if recipe.get("cave", false) and caves.is_empty():
			fails.append("no cave mouth")
	for c in stairs.keys() + ramps.keys() + caves:
		if _blocked.has(c):
			fails.append("plateau opening %s is blocked" % c)
	if "F" in recipe.height and fence.is_empty():
		fails.append("no fence")
	if "G" in recipe.height and gate.x < 0:
		fails.append("no gate")
	for c in hedge:
		if hedge[c] == NONE:
			fails.append("hedge cell %s has no tile" % c)
		if not _blocked.has(c):
			fails.append("hedge cell %s is walkable" % c)
	for c in deep:
		if not _near_all(c, water, 1):
			fails.append("deep water at %s touches the shore" % c)
	for b in blobs:
		if b.mode in ["M", "D"] and _tone_around(b.cells) != (0 if b.mode == "M" else 1):
			fails.append("patch in mode %s is not inside its tone" % b.mode)
	var tone_notes := PackedStringArray()
	for level in tones.size():
		for c in tones[level]:
			if _cell_min(c) <= tone_cut[level]:
				fails.append("%s tone tile at %s is not fully inside its zone" % [TONES[level].name, c])
			if level > 0 and not (tones[level - 1].has(c) or tone_edges[level - 1].has(c)):
				fails.append("%s tone cell %s is outside %s" % [TONES[level].name, c, TONES[level - 1].name])
		var area := tones[level].size() + tone_edges[level].size() / 2
		tone_notes.append("%s %d%%" % [TONES[level].name, roundi(100.0 * area / (WIDTH * HEIGHT))])
	for c in path.keys() + plateau.keys():
		if tone_cut.size() > 0 and _cell_max(c) + TONE_BAND * 0.5 + TONE_WOBBLE > tone_cut[0]:
			fails.append("grass tone can reach %s cell %s" % ["path" if path.has(c) else "plateau", c])
			break
	var patch_notes := PackedStringArray()
	for b in blobs:
		if b.cells.size() < 3 or b.cells.size() > 8:
			fails.append("patch of %d cells" % b.cells.size())
		for c in b.cells:
			if not _in_square(c, b.cells):
				fails.append("patch cell %s is not in a 2x2" % c)
		patch_notes.append("%s%d/%s" % [b.shape, b.cells.size(), b.mode])
	var counts := {}
	var sign_ids := {}
	for p in props:
		var kind := "sign" if p.has("sign") else _kind(p.art)
		counts[kind] = counts.get(kind, 0) + 1
		if p.has("sign"):
			sign_ids[p.sign] = true
		elif kind == "land rock" and not _land(_footprint(p.art, p.cell)):
			fails.append("land rock off the lawn at %s" % p.cell)
		if kind == "land rock" and p.block != (p.art in BIG_ROCKS):
			fails.append("%s at %s %s" % [p.art, p.cell, "blocks" if p.block else "does not block"])
		if p.get("block", false) and p.has("art") and PROPS[p.art].block != Vector2.ZERO:
			for c in _collider_cells(p):
				if not _blocked.has(c):
					fails.append("%s collider cell %s is walkable in the grid" % [p.art, c])
		elif kind in ["water plant", "water rock"] and not _wet(_footprint(p.art, p.cell)):
			fails.append("%s off the water at %s" % [kind, p.cell])
	var needs := {"bushes": "bush", "bushes heavy": "bush", "LR": "land rock", "LR obstacles": "land rock", "CF": "campfire", "T": "torch",
		"CF big": "campfire_big", "logs heavy": "clutter", "ruins": "clutter", "outcrops": "outcrop", "yard clutter": "clutter"}
	if "R" in recipe.height and ridges < 2:
		fails.append("ridge with fewer than two segments")
	for c in ridge_rock:
		if not _blocked.has(c):
			fails.append("ridge rock %s is walkable" % c)
	for c in ridge:
		if features.get(c, NONE) == NONE:
			fails.append("ridge cell %s has no tile" % c)
	if "canopy" in recipe.props and canopy.is_empty():
		fails.append("no canopy")
	if "hedges heavy" in recipe.props and hedgerows < 3:
		fails.append("hedges heavy but %d hedgerows" % hedgerows)
	if "carpets heavy" in recipe.props and carpets < 3:
		fails.append("carpets heavy but %d carpets" % carpets)
	if recipe.path.begins_with("plaza") and plaza.size == Vector2i.ZERO:
		fails.append("no plaza")
	for c in accents:
		if accents[c] == NONE:
			fails.append("accent cell %s has no tile" % c)
	for flag in recipe.props:
		if needs.has(flag) and counts.get(needs[flag], 0) == 0:
			fails.append("recipe asks for %s, none placed" % needs[flag])
	if want_ponds > 0 and "WP" in recipe.water and counts.get("water plant", 0) == 0:
		fails.append("no water plants")
	if want_ponds > 0 and "WR" in recipe.water and counts.get("water rock", 0) == 0:
		fails.append("no water rocks")
	if sign_ids.size() != recipe.signs:
		fails.append("signs %d distinct, recipe wants %d" % [sign_ids.size(), recipe.signs])
	for c in path:
		if _blocked.has(c):
			fails.append("path cell %s is blocked" % c)
	for g in goals:
		if not _reaches(spawn, g):
			fails.append("spawn does not reach %s" % g)
	var house_names := PackedStringArray()
	for h in houses:
		house_names.append(HOUSES[h.id].name)
	var lines := PackedStringArray([
		"Painted Lands map %d: recipe %d %s, %dx%d (layout attempt %d)" % [map_id, recipe_id, recipe.name, WIDTH, HEIGHT, attempt],
		"  hedgerows %d; ridges %d; accents %d; carpets %d; canopy %d cells; deep water %d cells; plateaus %s" % [hedgerows, ridges, accent_count, carpets, canopy.size(), deep.size(), ", ".join(plateaus.map(func(i): return "%s %s" % [i.tone, "+".join(["stairs", "ramp", "cave", "narrow"].filter(func(k): return i[k] >= 0))]))],
		"  houses: %s; ponds %d; plateau %s; fence %d; leans %d" % [", ".join(house_names) if not houses.is_empty() else "none", ponds.size(), "with stairs" if not stairs.is_empty() else ("yes" if not plateau.is_empty() else "no"), fence.size(), leans],
		"  path %d cells (%s), patches %s" % [path.size(), recipe.path, " ".join(patch_notes)],
		"  grass tones: %s" % ", ".join(tone_notes),
		"  props: %s; signs %s" % [str(counts), str(sign_ids.keys())],
		"  walk from %s to %d goals: %s" % [spawn, goals.size(), "ok" if not "spawn does not reach" in "; ".join(fails) else "FAIL"],
		"  checks: %s" % ("ok" if fails.is_empty() else "; ".join(fails)),
	])
	if not dropped.is_empty():
		lines.append("  dropped: %s" % ", ".join(dropped))
	lines.append("  floor: weakest window %.3f%% -> %.3f%%%s" % [floor_before, floor_after,
		(", added " + ", ".join(floor_notes)) if not floor_notes.is_empty() else ""])
	return "\n".join(lines)


func _reaches(from: Vector2i, to: Vector2i) -> bool:
	var seen := {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if c == to:
			return true
		for d in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var n: Vector2i = c + d
			if walkable(n) and not seen.has(n):
				seen[n] = true
				queue.append(n)
	return false


func _kind(art: String) -> String:
	if art in TREES or art in SHADE_TREES:
		return "tree"
	if art in HEDGES or art in SHRUBS:
		return "bush"
	if art in LAND_ROCKS:
		return "land rock"
	if art in SHORE_PLANTS or art in OPEN_PLANTS:
		return "water plant"
	if art in WATER_ROCKS:
		return "water rock"
	if art in TORCHES:
		return "torch"
	if art in SPARKLES:
		return "sparkle"
	if art in OUTCROPS.values():
		return "outcrop"
	if art in VINES:
		return "vine"
	if art in LOGS or art in YARD_CLUTTER:
		return "clutter"
	return art


func _land(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if water.has(Vector2i(x, y)) or plateau.has(Vector2i(x, y)):
				return false
	return true



func _wet(r: Rect2i) -> bool:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if not water.has(Vector2i(x, y)):
				return false
	return true


# ---------------------------------------------------------------- helpers

func _footprint(art: String, anchor: Vector2i) -> Rect2i:
	var p: Dictionary = PROPS[art]
	return Rect2i(anchor + p.cell, p.region.size)


func _block_pixels(origin_px: Vector2i, r: Rect2i) -> void:
	var p := origin_px + r.position
	for y in range(p.y / 16, (p.y + r.size.y - 1) / 16 + 1):
		for x in range(p.x / 16, (p.x + r.size.x - 1) / 16 + 1):
			_blocked[Vector2i(x, y)] = true
			_solid[Vector2i(x, y)] = true


# Map edges count as path so roads run off the map instead of capping.
func _mask(c: Vector2i, cells: Dictionary, edge_counts: bool) -> int:
	var mask := 0
	var dirs := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for i in 4:
		var n: Vector2i = c + dirs[i]
		if cells.has(n) or (edge_counts and not _inside(n)):
			mask |= 1 << i
	return mask


func _open_diagonals(c: Vector2i, cells: Dictionary, edge_counts: bool) -> int:
	var open := 0
	var diags := [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
	for i in 4:
		var n: Vector2i = c + diags[i]
		if not (cells.has(n) or (edge_counts and not _inside(n))):
			open |= 1 << i
	return open


func _in_square(c: Vector2i, cells: Dictionary) -> bool:
	for o in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
		var tl: Vector2i = c + o
		if cells.has(tl) and cells.has(tl + Vector2i.RIGHT) and cells.has(tl + Vector2i.DOWN) and cells.has(tl + Vector2i.ONE):
			return true
	return false


func _near(c: Vector2i, cells: Dictionary, dist: int) -> bool:
	for y in range(c.y - dist, c.y + dist + 1):
		for x in range(c.x - dist, c.x + dist + 1):
			if cells.has(Vector2i(x, y)):
				return true
	return false


func _near_rect(r: Rect2i, cells: Dictionary, dist: int) -> bool:
	var g := r.grow(dist)
	for y in range(g.position.y, g.end.y):
		for x in range(g.position.x, g.end.x):
			if cells.has(Vector2i(x, y)):
				return true
	return false


func _rect_free(r: Rect2i) -> bool:
	if r.position.x < 0 or r.position.y < 0 or r.end.x > WIDTH or r.end.y > HEIGHT:
		return false
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if _taken.has(Vector2i(x, y)):
				return false
	return true


func _solidify(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_solid[Vector2i(x, y)] = true


func _claim(r: Rect2i) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_taken[Vector2i(x, y)] = true


func _bounds(cells: Dictionary) -> Rect2i:
	var lo: Vector2i = cells.keys()[0]
	var hi := lo
	for c in cells:
		lo = lo.min(c)
		hi = hi.max(c)
	return Rect2i(lo, hi - lo + Vector2i.ONE)


func _cells(px: Vector2i) -> Vector2i:
	return Vector2i(ceili(px.x / 16.0), ceili(px.y / 16.0))


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < WIDTH and c.y < HEIGHT


# Moisture: 4-octave value-noise fBm at frequency 0.05.
func _moisture(c: Vector2i) -> float:
	var total := 0.0
	var amp := 1.0
	var freq := 0.05
	var norm := 0.0
	for octave in 4:
		total += _value_noise(c.x * freq + 40.0, c.y * freq + 20.0, 100 + octave) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.0
	return total / norm


func _wettest(zone: Rect2i) -> Vector2i:
	var best := zone.get_center()
	var wet := -1.0
	for y in range(zone.position.y + 2, zone.end.y - 2):
		for x in range(zone.position.x + 3, zone.end.x - 3):
			var m := _moisture(Vector2i(x, y))
			if m > wet:
				wet = m
				best = Vector2i(x, y)
	return best


func _value_noise(x: float, y: float, salt: int) -> float:
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := x - x0
	var fy := y - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var top := lerpf(_hash(x0, y0, salt), _hash(x0 + 1, y0, salt), fx)
	var bottom := lerpf(_hash(x0, y0 + 1, salt), _hash(x0 + 1, y0 + 1, salt), fx)
	return lerpf(top, bottom, fy)


func _hash(x: int, y: int, salt: int) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 1442695041 + map_id * 2654435761) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	h = h ^ (h >> 16)
	return float(h & 0xFFFFFF) / float(0xFFFFFF)
