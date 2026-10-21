class_name HudArt
extends RefCounted
## node-gates' HUD art, cut from the most compatible UI packs for Painted
## Lands maps (docs/ui-assets.md) at load time, never saved as new sheets:
##
## - Cozy Farm `ui/` (shubibubi): the wooden plate (9-slice frames for the
##   HUD, the maps, and the menus), the bar, the hotbar, the inventory
##   panel, and the plank button.
## - Franuka's Fantasy RPG icon pack: item icons, the eight slot frames that
##   show rarity, hearts, coins, the sword, the mana drop, check and cross.
## - The Painted Lands Farm sheets: the fish and the fruit.
##
## Everything is scaled up by whole numbers with nearest neighbour, so every
## art pixel stays square. Two cleanups are made in the packs' own colors: the
## plate's centre dot and side notches (they would stretch in a 9-slice), and
## the bar's hangers.

const COZY_UI := "res://assets/pack/cozy_farm/ui/UI.png"
const COZY_ALL := "res://assets/pack/cozy_farm/ui/UI_all.png"
const COZY_ITEMS := "res://assets/pack/cozy_farm/ui/items.png"
const ICONS := "res://assets/pack/fantasy_rpg_icons/icons16.png"
const COLOURS := "res://assets/pack/fantasy_rpg_icons/colours16.png"
const CROPS := "res://assets/pack/farm/tilesets/crops.png"
const FISH := "res://assets/pack/farm/fishes.png"

## Pieces (rects on their sheets) and their 9-slice margins (left, top,
## right, bottom).
const PLATE := Rect2i(128, 37, 60, 22)
const PLATE_MARGINS := [6, 6, 6, 4]
const BAR := Rect2i(128, 72, 48, 14) # the bar without its hangers
const BAR_FILL := Rect2i(10, 5, 35, 6) # the bar's inner tan, inside BAR
const BAR_KNOB := Rect2i(3, 5, 6, 6) # the coin at its left end
const HOTBAR := Rect2i(97, 112, 206, 31)
const HOTBAR_SLOT0 := Vector2i(103, 117) # top-left of the first slot's inside, on the sheet
const HOTBAR_PITCH := 22
const HOTBAR_SLOT := Vector2i(18, 21)
const INVENTORY := Rect2i(0, 30, 294, 98)
const INVENTORY_CELL0 := Vector2i(95, 48) # first grid cell, on the sheet
const INVENTORY_PITCH := Vector2i(21, 22)
const INVENTORY_CELL := Vector2i(21, 22)
const INVENTORY_PORTRAIT := Rect2i(32, 45, 32, 59) # the tall frame on the left
const INVENTORY_NAMEPLATE := Rect2i(20, 105, 57, 11)
const BUTTON := Rect2i(390, 320, 53, 41)
const BUTTON_MARGINS := [6, 6, 6, 8]

## Fantasy RPG icon pack cells (1-based, 10 a row).
const FRAMES := [0, 211, 212, 213, 215, 216, 214, 217, 218] # by rarity tier 1-8
const SWORD := 2
const COIN := 81
const DROP := 89
const CHECK := 123
const CROSS := 124
const HEART_FULL := 92 # on the colour-variations sheet
const HEART_HALF := 91
const HEART_EMPTY := 93
const SPEED_ICON := 78 # the green vial, for the speed buff
## The white flasks recolored in the pack's own greens (from its green vial
## and frame).
const GREEN := {Color8(245, 255, 232): Color8(99, 171, 63), Color8(215, 211, 189): Color8(59, 125, 79),
	Color8(43, 43, 69): Color8(40, 53, 64)}

static var _images := {}
static var _cache := {}


static func image(path: String) -> Image:
	if not _images.has(path):
		var img: Image = load(path).get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		_images[path] = img
	return _images[path]


static func _scaled(img: Image, scale: int) -> ImageTexture:
	var out := img.duplicate()
	if scale > 1:
		out.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(out)


static func _cached(key: String, make: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


static func cut(path: String, rect: Rect2i) -> Image:
	return image(path).get_region(rect)


## A 16 x 16 cell of the Fantasy RPG icon sheets (`n` 1-based, 10 a row).
static func icon_cell(sheet: String, n: int) -> Image:
	var c := Vector2i((n - 1) % 10, (n - 1) / 10)
	return cut(ICONS if sheet == "icons" else COLOURS, Rect2i(c * 16, Vector2i(16, 16)))


## An icon by spec: ["icons" or "colours", n(, "green")], or ["cozy",
## "crops", or "fish", Vector2i cell].
static func spec_image(spec: Array) -> Image:
	match spec[0]:
		"icons", "colours":
			var img := icon_cell(spec[0], spec[1])
			if spec.size() > 2 and spec[2] == "green":
				for y in 16:
					for x in 16:
						var p := img.get_pixel(x, y)
						if p.a > 0.0:
							var q: Color = GREEN.get(Color(p.r, p.g, p.b), p)
							img.set_pixel(x, y, Color(q.r, q.g, q.b, p.a))
			return img
		"cozy":
			return cut(COZY_ITEMS, Rect2i(spec[1] * 16, Vector2i(16, 16)))
		"crops":
			return cut(CROPS, Rect2i(spec[1] * 16, Vector2i(16, 16)))
		"fish":
			return cut(FISH, Rect2i(spec[1] * 16, Vector2i(16, 16)))
	return Image.create(16, 16, false, Image.FORMAT_RGBA8)


static func item_icon(id: String, scale: int) -> Texture2D:
	return _cached("item_%s_%d" % [id, scale], func(): return _scaled(spec_image(GateItems.item(id).icon), scale))


static func icon(sheet: String, n: int, scale: int) -> Texture2D:
	return _cached("icon_%s_%d_%d" % [sheet, n, scale], func(): return _scaled(icon_cell(sheet, n), scale))


## The slot frame showing a rarity tier (1-8).
static func frame(tier: int, scale: int) -> Texture2D:
	return icon("icons", FRAMES[clampi(tier, 1, 8)], scale)


## The wooden plate, cleaned for 9-slicing: the centre dot and the side
## notches painted over with the plate's own neighbouring colors.
static func plate(scale: int) -> Texture2D:
	return _cached("plate_%d" % scale, func():
		var img := cut(COZY_UI, PLATE)
		var fill := img.get_pixel(20, 8)
		for y in img.get_height():
			for x in img.get_width():
				var p := img.get_pixel(x, y)
				if p.a > 0.0 and p.is_equal_approx(Color8(80, 62, 54)):
					img.set_pixel(x, y, fill) # the dot
		for row in [8, 15]: # the notches: copy the plain row above
			for x in range(0, 6) + range(img.get_width() - 6, img.get_width()):
				img.set_pixel(x, row, img.get_pixel(x, row - 1))
		return _scaled(img, scale))


static func plate_margins(scale: int) -> Array:
	return PLATE_MARGINS.map(func(m): return m * scale)


## The bar without its hangers (the plain top rows copied over them).
static func bar(scale: int) -> Texture2D:
	return _cached("bar_%d" % scale, func():
		var img := cut(COZY_UI, BAR)
		for y in 2:
			for x in range(5, 12) + range(35, 42): # under both hangers
				img.set_pixel(x, y, img.get_pixel(20, y))
		return _scaled(img, scale))


static func hotbar(scale: int) -> Texture2D:
	return _cached("hotbar_%d" % scale, func(): return _scaled(cut(COZY_UI, HOTBAR), scale))


static func inventory(scale: int) -> Texture2D:
	return _cached("inventory_%d" % scale, func(): return _scaled(cut(COZY_ALL, INVENTORY), scale))


static func button(scale: int, lit := false) -> Texture2D:
	return _cached("button_%d_%s" % [scale, lit], func():
		var img := cut(COZY_ALL, BUTTON)
		if lit:
			for y in img.get_height():
				for x in img.get_width():
					var p := img.get_pixel(x, y)
					if p.a > 0.0:
						img.set_pixel(x, y, p.lightened(0.18))
		return _scaled(img, scale))


## A StyleBox of the wooden plate (panels, map frames).
static func plate_style(scale: int, content := 4) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = plate(scale)
	var m := plate_margins(scale)
	s.texture_margin_left = m[0]
	s.texture_margin_top = m[1]
	s.texture_margin_right = m[2]
	s.texture_margin_bottom = m[3]
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		s.set_content_margin(side, m[side] + content * scale)
	return s


static func button_style(scale: int, lit := false) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = button(scale, lit)
	s.texture_margin_left = BUTTON_MARGINS[0] * scale
	s.texture_margin_top = BUTTON_MARGINS[1] * scale
	s.texture_margin_right = BUTTON_MARGINS[2] * scale
	s.texture_margin_bottom = BUTTON_MARGINS[3] * scale
	s.content_margin_left = 10 * scale
	s.content_margin_right = 10 * scale
	s.content_margin_top = 4 * scale
	s.content_margin_bottom = 6 * scale
	return s


## The text color on the tan plate and planks.
const INK := Color8(80, 62, 54)
const INK_SOFT := Color8(122, 96, 72)
const CREAM := Color8(245, 236, 214)
