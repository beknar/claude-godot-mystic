extends CanvasLayer
## node-gates' HUD and screens, built from the most compatible UI art for
## Painted Lands maps (HudArt: Cozy Farm's wooden plate, bar, hotbar,
## inventory panel, and plank buttons; Franuka's Fantasy RPG icons) and the
## pixel fonts (PixelFonts), all at whole multiples of their pixels.
##
## - HUD: a plate with the node's name, map type, ring, and foes left;
##   hearts, the mana bar, and the buffs running; the minimap in a plate with
##   coins and sword under it; the hotbar (the bag's first nine slots, keys
##   1-9); a hint line.
## - I: the inventory (the bag's 27 slots on Cozy Farm's panel; the selected
##   item large in its portrait frame, its name, rarity, and effect below).
## - M: the whole current map, live, with the walker, foes, chest, and gates.
## - P: the strategic map: every node visited as a small picture of its map,
##   framed and named, joined by the moves made; the ways out of cleared
##   nodes as framed question marks.
## - Esc: the menu (or closes the screen that is open).

const S := 4 # UI pixels: one art pixel is S screen pixels
const F := PixelFonts.Role
const HEART := 3 # the hearts' scale
const OUTLINE := Color(0.16, 0.05, 0.12)

var map: Node # node_gates.gd
var _plate: PanelContainer
var _title: Label
var _type: Label
var _status: Label
var _vitals: Vitals
var _minimap: Minimap
var _purse: Purse
var _hotbar: Hotbar
var _hint: Label
var _toast: Label
var _toast_tween: Tween
var _fade: ColorRect
var _inventory: Inventory
var _overview: Overview
var _strategic: StrategicMap
var _menu: PanelContainer
var _confirm: Button


func setup(p_map: Node) -> void:
	map = p_map
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()


func refresh() -> void:
	if map == null or map.world == null:
		return
	var w: GateWorld = map.world
	var c := w.current
	_title.text = GateWorld.node_name(c)
	_type.text = GateWorld.map_type(c)
	var left: int = map.foes_left()
	var state := "Cleared: every gate is open" if w.cleared(c) else ("%d foe%s left" % [left, "" if left == 1 else "s"])
	_status.text = "Ring %d of %d · %s" % [GateWorld.ring(c), GateWorld.MAX_RING, state]
	for n in [_vitals, _hotbar, _minimap, _purse]:
		n.queue_redraw()
	if _inventory.visible:
		_inventory.queue_redraw()
	if _strategic.visible:
		_strategic.queue_redraw()
	_layout.call_deferred()


## The map script made a new picture of node `c` (minimap and thumbnail).
func map_captured(c: Vector2i) -> void:
	_strategic.forget(c)
	if map.mini_image:
		_minimap.set_image(map.mini_image)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


## Fades the screen to `alpha` (1 black, 0 clear); await it.
func fade(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, 0.22)
	await tw.finished


func _open_screen() -> Control:
	for s in [_inventory, _overview, _strategic, _menu]:
		if s.visible:
			return s
	return null


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	var open := _open_screen()
	if key == KEY_ESCAPE:
		if open == _menu or open == null:
			_show_menu(open == null)
		else:
			_close(open)
	elif key == KEY_I or key == KEY_TAB:
		_toggle(_inventory)
	elif key == KEY_M:
		_toggle(_overview)
	elif key == KEY_P:
		_toggle(_strategic)
	elif open == null and key >= KEY_1 and key <= KEY_9:
		map.use_slot(key - KEY_1)
	else:
		return
	get_viewport().set_input_as_handled()


func _toggle(screen: Control) -> void:
	if _menu.visible:
		return
	var was := screen.visible
	for s in [_inventory, _overview, _strategic]:
		if s.visible:
			_close(s)
	if not was:
		screen.visible = true
		if screen.has_method("opened"):
			screen.opened()
	get_tree().paused = _open_screen() != null


func _close(screen: Control) -> void:
	screen.visible = false
	if screen.has_method("closed"):
		screen.closed()
	get_tree().paused = _open_screen() != null


## The strategic map (P), for the demo reel.
func _show_map(open: bool) -> void:
	if open != _strategic.visible:
		_toggle(_strategic)


## The whole map (M), for the demo reel.
func _show_overview(open: bool) -> void:
	if open != _overview.visible:
		_toggle(_overview)


## The inventory (I), for the demo reel.
func _show_inventory(open: bool) -> void:
	if open != _inventory.visible:
		_toggle(_inventory)


func _show_menu(open: bool) -> void:
	_menu.visible = open
	_confirm.text = "New game (erases the save)"
	_confirm.set_meta("armed", false)
	get_tree().paused = _open_screen() != null
	if open:
		_menu.get_node("Box/Resume").grab_focus()


func _on_new_game() -> void:
	if not _confirm.get_meta("armed", false):
		_confirm.text = "Press again to erase the save"
		_confirm.set_meta("armed", true)
		return
	_show_menu(false)
	map.new_game()


# ---------------------------------------------------------------- building

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(root)

	# The node's plate, top left.
	_plate = PanelContainer.new()
	_plate.add_theme_stylebox_override("panel", HudArt.plate_style(S, 2))
	_plate.position = Vector2(24, 20)
	root.add_child(_plate)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	_plate.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	col.add_child(row)
	_title = _label(row, F.NUMBERS, 3, HudArt.INK)
	_type = _label(row, F.TITLE, 4, HudArt.INK)
	_type.size_flags_vertical = Control.SIZE_SHRINK_END
	_status = _label(col, F.BODY, 3, HudArt.INK_SOFT)

	_vitals = Vitals.new()
	_vitals.ui = self
	root.add_child(_vitals)

	# The minimap, top right, coins and sword under it.
	_minimap = Minimap.new()
	_minimap.ui = self
	_minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	root.add_child(_minimap)
	_purse = Purse.new()
	_purse.ui = self
	_purse.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	root.add_child(_purse)

	_hotbar = Hotbar.new()
	_hotbar.ui = self
	_hotbar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	root.add_child(_hotbar)

	_hint = _label(root, F.TINY, 3, HudArt.CREAM, true)
	_hint.text = "WASD move · Space swing · K spin · 1-9 items · I bag · M map · P nodes · Esc menu"
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.offset_left = 28
	_hint.offset_top = -48
	_hint.modulate.a = 0.85

	_toast = _label(root, F.BODY, 4, HudArt.CREAM, true)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_top = 300
	_toast.modulate.a = 0.0

	_inventory = Inventory.new()
	_inventory.ui = self
	_overview = Overview.new()
	_overview.ui = self
	_strategic = StrategicMap.new()
	_strategic.ui = self
	for s in [_inventory, _overview, _strategic]:
		s.set_anchors_preset(Control.PRESET_FULL_RECT)
		s.visible = false
		root.add_child(s)

	_menu = PanelContainer.new()
	_menu.add_theme_stylebox_override("panel", HudArt.plate_style(S, 6))
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu.visible = false
	root.add_child(_menu)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 16)
	_menu.add_child(box)
	var heading := _label(box, F.BIG_TITLE, 4, HudArt.INK)
	heading.text = "Node gates"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var info := _label(box, F.BODY, 3, HudArt.INK_SOFT)
	info.text = "Clear a map of foes to open its gates.\nVisited maps always open. The game saves as you go."
	info.custom_minimum_size = Vector2(1000, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(box, "Resume", func(): _show_menu(false)).name = "Resume"
	_button(box, "Inventory", func(): _show_menu(false); _toggle(_inventory))
	_button(box, "Map", func(): _show_menu(false); _toggle(_overview))
	_button(box, "Strategic map", func(): _show_menu(false); _toggle(_strategic))
	_confirm = _button(box, "New game (erases the save)", _on_new_game)
	_button(box, "Quit", func(): map._store_node(); map.world.save(); get_tree().quit())

	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 30
	fade_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(_fade)
	_layout.call_deferred()


# Places the pieces that hang off others: the vitals under the node's plate,
# the purse under the minimap, the hotbar centred at the bottom.
func _layout() -> void:
	_vitals.position = Vector2(28, _plate.position.y + _plate.size.y + 16)
	_minimap.offset_left = -_minimap.custom_minimum_size.x - 24
	_minimap.offset_right = -24
	_minimap.offset_top = 20
	_minimap.offset_bottom = 20 + _minimap.custom_minimum_size.y
	_purse.offset_left = -_purse.custom_minimum_size.x - 24
	_purse.offset_right = -24
	_purse.offset_top = 20 + _minimap.custom_minimum_size.y + 12
	_purse.offset_bottom = _purse.offset_top + _purse.custom_minimum_size.y
	_hotbar.offset_left = -_hotbar.custom_minimum_size.x / 2.0
	_hotbar.offset_right = _hotbar.custom_minimum_size.x / 2.0
	_hotbar.offset_top = -_hotbar.custom_minimum_size.y - 20
	_hotbar.offset_bottom = -20


func _label(parent: Node, role: PixelFonts.Role, scale: int, color: Color, outlined := false) -> Label:
	var l := Label.new()
	PixelFonts.apply(l, role, scale, OUTLINE if outlined else Color(0, 0, 0, 0))
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	PixelFonts.apply(b, F.BODY, 4, Color(0, 0, 0, 0))
	for state in ["normal", "disabled"]:
		b.add_theme_stylebox_override(state, HudArt.button_style(S))
	for state in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(state, HudArt.button_style(S, true))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, HudArt.INK)
	b.custom_minimum_size = Vector2(760, 0)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- drawing help

## An item in a slot: its rarity frame, its icon, and its count.
static func draw_item(ci: CanvasItem, slot: Dictionary, at: Vector2, scale: int, count := true) -> void:
	if slot.is_empty():
		return
	var it := GateItems.item(slot.id)
	ci.draw_texture(HudArt.frame(it.tier, scale), at)
	ci.draw_texture(HudArt.item_icon(slot.id, scale), at)
	if count and slot.count > 1:
		var f := PixelFonts.font(PixelFonts.Role.NUMBERS)
		var fs := PixelFonts.size(PixelFonts.Role.NUMBERS, 2)
		var s := str(slot.count)
		var p := at + Vector2(16 * scale - f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 6, 16 * scale + 6)
		ci.draw_string_outline(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, OUTLINE)
		ci.draw_string(f, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, HudArt.CREAM)


## Draws `s` in a role's font at `scale`; returns its width.
static func text(ci: CanvasItem, role: PixelFonts.Role, scale: int, at: Vector2, s: String, color: Color, outline := false) -> float:
	var f := PixelFonts.font(role)
	var fs := PixelFonts.size(role, scale)
	if outline:
		ci.draw_string_outline(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, scale * 2, OUTLINE)
	ci.draw_string(f, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


## Hearts, the mana bar, and the buffs running, under the node's plate.
class Vitals extends Control:
	var ui: Node

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		if ui and ui.map and not ui.map.buffs.is_empty():
			queue_redraw()

	func _draw() -> void:
		if ui == null or ui.map == null:
			return
		var h: Dictionary = ui.map.world.hero
		var hs: int = HEART
		var x := 0.0
		for i in int(ceil(h.max_hp / 2.0)):
			var fill: int = h.hp - i * 2
			var n := HudArt.HEART_FULL if fill >= 2 else (HudArt.HEART_HALF if fill == 1 else HudArt.HEART_EMPTY)
			draw_texture(HudArt.icon("colours", n, hs), Vector2(x, 0))
			x += 15 * hs
		# The mana bar: Cozy Farm's bar, its coin under the pack's drop, the
		# inside filled with blue.
		var s: int = S
		var y := 16.0 * hs + 8
		draw_texture(HudArt.bar(s), Vector2(0, y))
		var r := HudArt.BAR_FILL
		var frac := clampf(float(h.mana) / maxf(1.0, h.max_mana), 0.0, 1.0)
		var w := roundi(r.size.x * frac)
		if w > 0:
			draw_rect(Rect2(Vector2(r.position * s) + Vector2(0, y), Vector2(w * s, r.size.y * s)), Color8(62, 115, 188))
			draw_rect(Rect2(Vector2(r.position * s) + Vector2(0, y), Vector2(w * s, s)), Color8(114, 170, 228))
		draw_texture(HudArt.icon("icons", HudArt.DROP, 2), Vector2(HudArt.BAR_KNOB.position * s) + Vector2(-4, y - 4))
		ui.text(self, F.NUMBERS, 2, Vector2(HudArt.BAR.size.x * s + 12, y + 44), "%d / %d" % [h.mana, h.max_mana], HudArt.CREAM, true)
		# Buffs: the item's icon and the seconds left.
		var bx := 0.0
		var by := y + HudArt.BAR.size.y * s + 12
		for k in ["speed", "regen"]:
			if not ui.map.buffs.has(k):
				continue
			var b: Dictionary = ui.map.buffs[k]
			draw_texture(HudArt.frame(GateItems.item(b.id).tier, 3), Vector2(bx, by))
			draw_texture(HudArt.item_icon(b.id, 3), Vector2(bx, by))
			ui.text(self, F.NUMBERS, 2, Vector2(bx + 52, by + 40), "%ds" % ceili(b.time), HudArt.CREAM, true)
			bx += 140.0


## The minimap: the map shrunk to a pixel a cell, at 4 x, in a plate, with
## the walker, foes, chest, and the gates marked.
class Minimap extends Control:
	const PX := 4
	var ui: Node
	var _tex: Texture2D
	var _t := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(PaintedTerrain.WIDTH * PX + 48, PaintedTerrain.HEIGHT * PX + 40)

	func set_image(img: Image) -> void:
		var big := img.duplicate()
		big.resize(img.get_width() * PX, img.get_height() * PX, Image.INTERPOLATE_NEAREST)
		_tex = ImageTexture.create_from_image(big)
		queue_redraw()

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		draw_style_box(HudArt.plate_style(S, 0), Rect2(Vector2.ZERO, size))
		var at := Vector2(24, 24)
		if _tex:
			draw_texture(_tex, at)
		else:
			draw_rect(Rect2(at, Vector2(PaintedTerrain.WIDTH, PaintedTerrain.HEIGHT) * PX), Color8(83, 131, 79))
		var m: Node = ui.map
		if m == null or m.walker == null or m.terrain == null:
			return
		for f in m.foes:
			if f.alive():
				draw_rect(Rect2(at + (f.position / 16.0).floor() * PX, Vector2(PX, PX)), Color8(200, 40, 50))
		if m.chest and not m.chest.get_meta("opened"):
			draw_rect(Rect2(at + (m.chest.position / 16.0).floor() * PX - Vector2(0, PX), Vector2(PX, PX)), Color8(255, 210, 70))
		for side in m.GATE_SIDES:
			if not m.terrain.gate_cells.has(side) or m.gate_state(side) == "edge":
				continue
			var g: Vector2i = m.terrain.gate_cells[side].cell
			var col := Color8(255, 236, 150) if m.gate_state(side) != "locked" else Color8(200, 60, 50)
			var across: bool = side in ["n", "s"]
			draw_rect(Rect2(at + Vector2(g) * PX, Vector2(PX * (2 if across else 1), PX * (1 if across else 2))), col)
		if (m.house_interiors == null or m.house_interiors.inside < 0) and int(_t * 3.0) % 2 == 0:
			draw_rect(Rect2(at + (m.walker.position / 16.0).floor() * PX - Vector2(PX, PX), Vector2(PX, PX) * 2), Color.WHITE)


## Coins and the sword under the minimap, on a plate.
class Purse extends Control:
	var ui: Node

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(PaintedTerrain.WIDTH * 4 + 48, 88)

	func _draw() -> void:
		if ui == null or ui.map == null:
			return
		draw_style_box(HudArt.plate_style(S, 0), Rect2(Vector2.ZERO, size))
		var h: Dictionary = ui.map.world.hero
		draw_texture(HudArt.icon("icons", HudArt.COIN, 3), Vector2(28, 18))
		ui.text(self, F.NUMBERS, 3, Vector2(84, 66), str(h.coins), HudArt.INK)
		draw_texture(HudArt.icon("icons", HudArt.SWORD, 3), Vector2(size.x / 2.0 + 20, 18))
		ui.text(self, F.NUMBERS, 3, Vector2(size.x / 2.0 + 76, 66), str(h.damage), HudArt.INK)


## The hotbar: Cozy Farm's bar of nine slots, the bag's first nine items in
## them with their rarity frames, counts, and keys.
class Hotbar extends Control:
	var ui: Node

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(HudArt.HOTBAR.size * 4)

	func _draw() -> void:
		var s: int = S
		draw_texture(HudArt.hotbar(s), Vector2.ZERO)
		var bag: Array = ui.map.world.bag
		for i in 9:
			var inside := Vector2(HudArt.HOTBAR_SLOT0 - HudArt.HOTBAR.position + Vector2i(i * HudArt.HOTBAR_PITCH, 0)) * s
			var at := (inside + Vector2((HudArt.HOTBAR_SLOT.x - 16) * s / 2.0, (HudArt.HOTBAR_SLOT.y - 16) * s / 2.0 + s)).floor()
			ui.draw_item(self, bag[i], at, s)
			ui.text(self, F.TINY, 2, inside + Vector2(6, 20), str(i + 1), HudArt.INK)


## The inventory: Cozy Farm's panel, the bag's 27 slots in its grid (the
## first row is the hotbar), the selected item large in the portrait frame,
## and an info plate under the panel. Arrows (or WASD) select, Enter or Space
## uses, X picks up and drops (swaps) a slot, a click selects and a double
## click uses.
class Inventory extends Control:
	var ui: Node
	var sel := 0
	var held := -1 # a slot picked up with X

	func opened() -> void:
		held = -1
		grab_focus()
		queue_redraw()

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL

	func _origin() -> Vector2:
		return ((size - Vector2(HudArt.INVENTORY.size * S)) / 2.0 - Vector2(0, 120)).floor()

	func _cell_rect(i: int) -> Rect2:
		var s: int = S
		var cell := HudArt.INVENTORY_CELL0 - HudArt.INVENTORY.position + Vector2i(i % 9, i / 9) * HudArt.INVENTORY_PITCH
		return Rect2(_origin() + Vector2(cell * s), Vector2(HudArt.INVENTORY_CELL * s))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in GateWorld.BAG_SLOTS:
				if _cell_rect(i).has_point(event.position):
					sel = i
					if event.double_click:
						ui.map.use_slot(i)
					queue_redraw()
					accept_event()
					return
		if not (event is InputEventKey) or not event.pressed:
			return
		var k: int = event.physical_keycode
		var step := {KEY_LEFT: -1, KEY_A: -1, KEY_RIGHT: 1, KEY_D: 1, KEY_UP: -9, KEY_W: -9, KEY_DOWN: 9, KEY_S: 9}
		if step.has(k):
			sel = posmod(sel + step[k], GateWorld.BAG_SLOTS)
		elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			ui.map.use_slot(sel)
		elif k == KEY_X:
			if held < 0:
				held = sel if not ui.map.world.bag[sel].is_empty() else -1
			else:
				var bag: Array = ui.map.world.bag
				var tmp = bag[held]
				bag[held] = bag[sel]
				bag[sel] = tmp
				held = -1
				ui.map.world.save()
				ui.refresh()
		else:
			return
		queue_redraw()
		accept_event()

	func _draw() -> void:
		var s: int = S
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.04, 0.6))
		var o := _origin()
		draw_texture(HudArt.inventory(s), o)
		var bag: Array = ui.map.world.bag
		for i in GateWorld.BAG_SLOTS:
			var r := _cell_rect(i)
			var at := (r.position + (r.size - Vector2(16, 16) * s) / 2.0).floor()
			ui.draw_item(self, bag[i], at, s)
			if i == held:
				draw_rect(r.grow(-s), Color(1, 0.86, 0.4, 0.35))
			if i == sel:
				draw_rect(r.grow(-s / 2.0), HudArt.CREAM, false, s)
		var slot: Dictionary = bag[sel]
		var portrait := Rect2(o + Vector2((HudArt.INVENTORY_PORTRAIT.position - HudArt.INVENTORY.position) * s), Vector2(HudArt.INVENTORY_PORTRAIT.size * s))
		if not slot.is_empty():
			var big := 7
			var at := (portrait.position + (portrait.size - Vector2(16, 16) * big) / 2.0).floor()
			draw_texture(HudArt.item_icon(slot.id, big), at)
			# The count on the nameplate under the portrait.
			var np := Rect2(o + Vector2((HudArt.INVENTORY_NAMEPLATE.position - HudArt.INVENTORY.position) * s), Vector2(HudArt.INVENTORY_NAMEPLATE.size * s))
			var label := "x%d" % slot.count
			var f := PixelFonts.font(F.NUMBERS)
			var fs := PixelFonts.size(F.NUMBERS, 2)
			ui.text(self, F.NUMBERS, 2, Vector2(np.get_center().x - f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x / 2.0, np.end.y - 8).floor(), label, HudArt.INK)
		# The info plate under the panel.
		var plate := Rect2(o + Vector2(0, HudArt.INVENTORY.size.y * s + 16), Vector2(HudArt.INVENTORY.size.x * s, 200))
		draw_style_box(HudArt.plate_style(s, 0), plate)
		var x := plate.position.x + 48
		var y := plate.position.y + 70
		if slot.is_empty():
			ui.text(self, F.BODY, 4, Vector2(x, y), "An empty slot", HudArt.INK_SOFT)
		else:
			var it := GateItems.item(slot.id)
			var w: float = ui.text(self, F.BODY, 4, Vector2(x, y), it.name, HudArt.INK)
			ui.text(self, F.NUMBERS, 3, Vector2(x + w + 24, y), "x%d" % slot.count, HudArt.INK_SOFT)
			ui.text(self, F.BODY, 3, Vector2(x, y + 50), GateItems.effect_text(slot.id) + ".   " + GateItems.rarity_text(slot.id), HudArt.INK_SOFT)
		ui.text(self, F.TINY, 3, Vector2(x, y + 100), "Arrows select · Enter use · X move · top row: hotbar · I close", HudArt.INK_SOFT)


## The whole current map (M), drawn live by a viewport sharing the world at
## 2 x, in a plate, with the walker, foes, chest, and gates marked, and a
## side plate naming the node and where each gate leads.
class Overview extends Control:
	const ZOOM := 2
	var ui: Node
	var _vp: SubViewport
	var _t := 0.0

	func opened() -> void:
		_vp = SubViewport.new()
		_vp.size = Vector2i(PaintedTerrain.WIDTH * 16 * ZOOM, PaintedTerrain.HEIGHT * 16 * ZOOM)
		_vp.world_2d = ui.map.get_viewport().world_2d
		_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var cam := Camera2D.new()
		cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
		cam.zoom = Vector2(ZOOM, ZOOM)
		_vp.add_child(cam)
		add_child(_vp)
		cam.make_current()
		queue_redraw()

	func closed() -> void:
		if _vp:
			_vp.queue_free()
			_vp = null

	func _process(delta: float) -> void:
		if visible:
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var s: int = S
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.04, 0.75))
		var m: Node = ui.map
		var map_size := Vector2(PaintedTerrain.WIDTH, PaintedTerrain.HEIGHT) * 16 * ZOOM
		var frame := Rect2(Vector2(size.x - map_size.x - 48 - 40, (size.y - map_size.y) / 2.0 - 20).floor(), map_size + Vector2(48, 40))
		draw_style_box(HudArt.plate_style(s, 0), frame)
		var at := frame.position + Vector2(24, 24)
		if _vp:
			draw_texture(_vp.get_texture(), at)
		for f in m.foes:
			if f.alive():
				draw_arc(at + f.position * ZOOM + Vector2(0, -8), 14, 0, TAU, 16, Color8(220, 50, 60), 4)
		if m.chest and not m.chest.get_meta("opened"):
			draw_arc(at + m.chest.position * ZOOM + Vector2(0, -12), 18, 0, TAU, 16, Color8(255, 210, 70), 4)
		# Each gate: a plate on the map's edge naming where it leads.
		for side in m.GATE_SIDES:
			if not m.terrain.gate_cells.has(side) or m.gate_state(side) == "edge":
				continue
			var g: Vector2i = m.terrain.gate_cells[side].cell
			var label := GateWorld.node_name(m.world.current + GateWorld.DIRS[side])
			var f := PixelFonts.font(F.NUMBERS)
			var fs := PixelFonts.size(F.NUMBERS, 2)
			var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var p := at + Vector2(g + Vector2i(1, 1)) * 16 * ZOOM
			var box := Vector2(tw + 32, 52)
			match side:
				"n": p += Vector2(-box.x / 2.0, -16 * ZOOM)
				"s": p += Vector2(-box.x / 2.0, 16 * ZOOM - box.y)
				"e": p += Vector2(16 * ZOOM - box.x, -box.y / 2.0)
				"w": p += Vector2(-16 * ZOOM, -box.y / 2.0)
			var plate := Rect2(p.floor(), box)
			draw_style_box(HudArt.plate_style(2, 0), plate)
			var col := Color8(140, 50, 45) if m.gate_state(side) == "locked" else HudArt.INK
			draw_string(f, Vector2(plate.position.x + 16, plate.end.y - 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if m.house_interiors == null or m.house_interiors.inside < 0:
			var r := 22.0 + 6.0 * sin(_t * 5.0)
			draw_arc(at + m.walker.position * ZOOM + Vector2(0, -16), r, 0, TAU, 24, Color.WHITE, 4)
		# The side plate: the node, then each gate and where it goes.
		var side_plate := Rect2(Vector2(40, frame.position.y), Vector2(frame.position.x - 80, 780))
		draw_style_box(HudArt.plate_style(s, 0), side_plate)
		var x := side_plate.position.x + 44
		var y := side_plate.position.y + 100
		var w: GateWorld = m.world
		var c := w.current
		var nw: float = ui.text(self, F.NUMBERS, 4, Vector2(x, y), GateWorld.node_name(c), HudArt.INK)
		ui.text(self, F.TITLE, 4, Vector2(x + nw + 28, y), GateWorld.map_type(c), HudArt.INK)
		y += 64
		ui.text(self, F.BODY, 3, Vector2(x, y), "Ring %d · %s" % [GateWorld.ring(c), "cleared" if w.cleared(c) else "%d foes left" % m.foes_left()], HudArt.INK_SOFT)
		y += 84
		for side in m.GATE_SIDES:
			var state: String = m.gate_state(side)
			var dest: Vector2i = c + GateWorld.DIRS[side]
			var word: String = {"n": "North", "e": "East", "s": "South", "w": "West"}[side]
			var what := "the land ends" if state == "edge" else ("to %s" % GateWorld.node_name(dest))
			var tag: String = {"edge": "", "visited": "open, visited", "open": "open", "locked": "shut"}[state]
			var dx: float = ui.text(self, F.BODY, 3, Vector2(x, y), word + " gate " + what, HudArt.INK)
			if tag != "":
				ui.text(self, F.TINY, 3, Vector2(x + dx + 20, y), tag, Color8(140, 50, 45) if state == "locked" else HudArt.INK_SOFT)
			y += 58
		y += 40
		ui.text(self, F.TINY, 3, Vector2(x, y), "White ring: you", HudArt.INK_SOFT)
		ui.text(self, F.TINY, 3, Vector2(x, y + 44), "Red rings: foes", Color8(160, 40, 45))
		ui.text(self, F.TINY, 3, Vector2(x, y + 88), "Gold ring: the chest", Color8(150, 110, 30))
		ui.text(self, F.TINY, 3, Vector2(x, y + 150), "M or Esc close · P the nodes", HudArt.INK_SOFT)


## The strategic map (P): a plate as big as the screen, every node visited as
## its thumbnail (the map drawn small) in a frame with its name under it and
## a check (cleared) or cross (foes left), the moves made between nodes as
## wooden roads, the unvisited ways out of cleared nodes as framed question
## marks. Arrows or WASD pan, + and - (or the wheel) step the zoom.
class StrategicMap extends Control:
	const ZOOMS := [1, 2, 3]
	var ui: Node
	var pan := Vector2.ZERO
	var zoom_i := 1
	var _thumbs := {} # node -> Texture2D (or null: none on disk)
	var _t := 0.0

	func opened() -> void:
		center_on(ui.map.world.current)
		grab_focus()

	func center_on(c: Vector2i) -> void:
		pan = -Vector2(c.x, -c.y) * _pitch()
		queue_redraw()

	func _ready() -> void:
		focus_mode = Control.FOCUS_ALL

	func forget(c: Vector2i) -> void:
		_thumbs.erase(c)

	func zoom() -> int:
		return ZOOMS[zoom_i]

	func _pitch() -> Vector2:
		var z := zoom()
		return Vector2(120 * z + 120, 80 * z + 130)

	func _thumb(c: Vector2i) -> Texture2D:
		if not _thumbs.has(c):
			var path: String = ui.map.world.thumb_path(c)
			var tex: Texture2D = null
			if FileAccess.file_exists(path):
				var img := Image.load_from_file(ProjectSettings.globalize_path(path))
				if img:
					tex = ImageTexture.create_from_image(img)
			_thumbs[c] = tex
		return _thumbs[c]

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		var move := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
			move.x += 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
			move.x -= 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
			move.y += 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
			move.y -= 1
		pan += move * 900.0 * delta
		queue_redraw()

	func set_zoom(i: int) -> void:
		var old := _pitch()
		zoom_i = clampi(i, 0, ZOOMS.size() - 1)
		pan = (pan / old * _pitch()).round()
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_zoom(zoom_i + 1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_zoom(zoom_i - 1)
		elif event is InputEventKey and event.pressed:
			if event.physical_keycode in [KEY_EQUAL, KEY_KP_ADD]:
				set_zoom(zoom_i + 1)
			elif event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
				set_zoom(zoom_i - 1)

	func _at(c: Vector2i) -> Vector2:
		return (size / 2.0 + Vector2(c.x, -c.y) * _pitch() + pan).round()

	func _draw() -> void:
		var s: int = S
		var z := zoom()
		var w: GateWorld = ui.map.world
		draw_style_box(HudArt.plate_style(s, 0), Rect2(Vector2.ZERO, size))
		var inner := Rect2(Vector2(24, 24), size - Vector2(48, 40))
		var box := Vector2(120, 80) * z
		# The unvisited ways out of cleared nodes.
		var frontier := {}
		for c in w.nodes:
			if not w.cleared(c):
				continue
			for side in GateWorld.DIRS:
				var n: Vector2i = c + GateWorld.DIRS[side]
				if not w.visited(n) and GateWorld.in_world(n):
					frontier[n] = true
					_road(_at(c), _at(n), z, true)
		for l in w.links:
			var ends: PackedStringArray = l.split("|")
			_road(_at(GateWorld.unkey(ends[0])), _at(GateWorld.unkey(ends[1])), z, false)
		for n in frontier:
			var p := _at(n)
			if not inner.grow(box.x).has_point(p):
				continue
			var r := Rect2(p - box / 2.0, box)
			draw_style_box(HudArt.plate_style(z, 0), r.grow(4 * z))
			ui.text(self, F.NUMBERS, z + 2, p + Vector2(-5 * (z + 2), 6 * (z + 2)), "?", HudArt.INK_SOFT)
			_name(p, box, n, z, HudArt.INK_SOFT)
		for c in w.nodes:
			var p := _at(c)
			if not inner.grow(box.x).has_point(p):
				continue
			var r := Rect2(p - box / 2.0, box)
			draw_style_box(HudArt.plate_style(z, 0), r.grow(4 * z))
			var tex := _thumb(c)
			if tex:
				draw_texture_rect(tex, r, false)
			else:
				draw_rect(r, Color8(83, 131, 79))
			var badge := HudArt.icon("icons", HudArt.CHECK if w.cleared(c) else HudArt.CROSS, z + 1)
			draw_texture(badge, r.position + Vector2(r.size.x - 10 * (z + 1), -6 * (z + 1)))
			if c == w.current and int(_t * 2.5) % 2 == 0:
				draw_rect(r.grow(2 * z), Color.WHITE, false, 2 * z)
			_name(p, box, c, z, HudArt.INK)
		# The header and the legend, on the plate.
		var x := 60.0
		ui.text(self, F.BIG_TITLE, 4, Vector2(x, 110), "Strategic map", HudArt.INK)
		var cur := w.current
		var dx: float = ui.text(self, F.BODY, 4, Vector2(x, 180), "You are at ", HudArt.INK_SOFT)
		dx += ui.text(self, F.NUMBERS, 3, Vector2(x + dx, 180), GateWorld.node_name(cur) + "  ", HudArt.INK)
		dx += ui.text(self, F.TITLE, 4, Vector2(x + dx, 180), GateWorld.map_type(cur), HudArt.INK)
		ui.text(self, F.BODY, 4, Vector2(x + dx, 180), ", ring %d" % GateWorld.ring(cur), HudArt.INK_SOFT)
		var cleared := 0
		for c in w.nodes:
			if w.cleared(c):
				cleared += 1
		ui.text(self, F.BODY, 3, Vector2(x, 236), "%d node%s visited, %d cleared" % [w.nodes.size(), "" if w.nodes.size() == 1 else "s", cleared], HudArt.INK_SOFT)
		var y := size.y - 60
		draw_texture(HudArt.icon("icons", HudArt.CHECK, 3), Vector2(x, y - 40))
		var lx: float = x + 56 + ui.text(self, F.TINY, 3, Vector2(x + 56, y), "cleared", HudArt.INK)
		draw_texture(HudArt.icon("icons", HudArt.CROSS, 3), Vector2(lx + 40, y - 40))
		lx += 96 + ui.text(self, F.TINY, 3, Vector2(lx + 96, y), "foes remain", HudArt.INK)
		ui.text(self, F.NUMBERS, 3, Vector2(lx + 48, y + 4), "?", HudArt.INK_SOFT)
		lx += 84 + ui.text(self, F.TINY, 3, Vector2(lx + 84, y), "open, not visited", HudArt.INK)
		ui.text(self, F.TINY, 3, Vector2(lx + 80, y), "Arrows pan · + and - zoom · P or Esc close · M the map", HudArt.INK_SOFT)

	# A road between two nodes: dark wood with a lighter middle (faint for an
	# unvisited way out).
	func _road(a: Vector2, b: Vector2, z: int, faint: bool) -> void:
		var alpha := 0.45 if faint else 1.0
		draw_line(a, b, Color(Color8(93, 70, 55), alpha), 6.0 * z)
		draw_line(a, b, Color(Color8(173, 158, 128), alpha), 2.0 * z)

	# The node's name under its frame, on a small plate.
	func _name(p: Vector2, box: Vector2, c: Vector2i, z: int, color: Color) -> void:
		var label := GateWorld.node_name(c)
		var f := PixelFonts.font(PixelFonts.Role.NUMBERS)
		var fs := PixelFonts.size(PixelFonts.Role.NUMBERS, z + 1)
		var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var plate := Rect2(Vector2(p.x - tw / 2.0 - 10 * z, p.y + box.y / 2.0 + 8 * z).floor(), Vector2(tw + 20 * z, fs * 0.9 + 8 * z).floor())
		draw_style_box(HudArt.plate_style(z, 0), plate)
		draw_string(f, Vector2(plate.position.x + 10 * z, plate.end.y - 6 * z).floor(), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)
