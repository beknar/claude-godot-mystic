class_name PixelFonts
extends RefCounted
## The game's pixel fonts (assets/fonts/README.md): each loaded once with
## antialiasing, hinting, and subpixel positioning off, so its glyphs stay on
## whole pixels, and sized at whole multiples of its pixel grid (`size`), so
## one font pixel is always a whole number of screen pixels.
##
## Roles: BODY (text, HUD, messages, menus), TITLE (titles and map-type
## names; words only, its digits are old-style), BIG_TITLE, NUMBERS (node
## names, coins, counts), TINY (hints and legends). Pixel Crawler maps use
## their own pair: PC_BODY and NUMBERS for headings.

enum Role { BODY, TITLE, BIG_TITLE, NUMBERS, TINY, PC_BODY }

const DIR := "res://assets/fonts/"
## Per role: the file and the font size at which one font pixel is one
## screen pixel.
const FONTS := {
	Role.BODY: ["PixelifySans.ttf", 11.0],
	Role.TITLE: ["JacquardaBastarda9.ttf", 13.0],
	Role.BIG_TITLE: ["Jacquard12.ttf", 21.0],
	Role.NUMBERS: ["Jersey10.ttf", 1400.0 / 75.0],
	Role.TINY: ["Silkscreen.ttf", 8.0],
	Role.PC_BODY: ["KenneyPixel.ttf", 16.0],
}

static var _cache := {}


static func font(role: Role) -> FontFile:
	if _cache.has(role):
		return _cache[role]
	var f: FontFile = load(DIR + FONTS[role][0])
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	f.multichannel_signed_distance_field = false
	_cache[role] = f
	return f


## The font size that draws `role` with each font pixel `scale` screen pixels
## wide.
static func size(role: Role, scale: int) -> int:
	return roundi(FONTS[role][1] * maxi(1, scale))


## Sets a control's font and size (theme overrides) for `role` at `scale`,
## with a dark outline one font pixel wide.
static func apply(control: Control, role: Role, scale: int, outline := Color(0.16, 0.05, 0.12)) -> void:
	control.add_theme_font_override("font", font(role))
	control.add_theme_font_size_override("font_size", size(role, scale))
	if outline.a > 0.0:
		control.add_theme_color_override("font_outline_color", outline)
		control.add_theme_constant_override("outline_size", scale * 2)
