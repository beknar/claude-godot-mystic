extends CanvasLayer
## node-gates: the HUD (this node's name and map type, foes left, hearts,
## coins, sword), messages, the fade between maps, the strategic map (M or
## Tab), and the Escape menu. UI only, drawn in code over the map.

const FONT_SIZE := 40
const HEART := [".XX.XX.", "XXXXXXX", "XXXXXXX", ".XXXXX.", "..XXX..", "...X..."]

var map: Node # node_gates.gd
var _title: Label
var _status: Label
var _coins: Label
var _hearts: Control
var _hint: Label
var _toast: Label
var _toast_tween: Tween
var _fade: ColorRect
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
	_title.text = "%s · %s" % [GateWorld.node_name(c), GateWorld.map_type(c)]
	var left: int = map.foes_left()
	var state := "Cleared: every gate is open" if w.cleared(c) else ("%d foe%s left" % [left, "" if left == 1 else "s"])
	_status.text = "Ring %d of %d · %s" % [GateWorld.ring(c), GateWorld.MAX_RING, state]
	_coins.text = "%d coins · sword %d" % [w.hero.coins, w.hero.damage]
	_hearts.queue_redraw()
	if _strategic.visible:
		_strategic.queue_redraw()


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.6)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


## Fades the screen to `alpha` (1 black, 0 clear); await it.
func fade(alpha: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, 0.22)
	await tw.finished


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if key == KEY_ESCAPE:
		if _strategic.visible:
			_show_map(false)
		else:
			_show_menu(not _menu.visible)
		get_viewport().set_input_as_handled()
	elif key == KEY_M or key == KEY_TAB:
		if not _menu.visible:
			_show_map(not _strategic.visible)
		get_viewport().set_input_as_handled()


func _show_map(open: bool) -> void:
	_strategic.visible = open
	if open:
		_strategic.recenter()
	get_tree().paused = open or _menu.visible


func _show_menu(open: bool) -> void:
	_menu.visible = open
	_confirm.text = "New game (erases the save)"
	_confirm.set_meta("armed", false)
	get_tree().paused = open or _strategic.visible
	if open:
		_menu.get_node("Margin/Box/Resume").grab_focus()


func _on_new_game() -> void:
	if not _confirm.get_meta("armed", false):
		_confirm.text = "Press again to erase the save"
		_confirm.set_meta("armed", true)
		return
	_show_menu(false)
	map.new_game()


func _build() -> void:
	_title = _label(Vector2(28, 16), FONT_SIZE)
	_status = _label(Vector2(28, 16 + FONT_SIZE + 12), FONT_SIZE * 3 / 4)
	_hearts = Hearts.new()
	_hearts.ui = self
	_hearts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_hearts.offset_left = -28
	_hearts.offset_right = -28
	_hearts.offset_top = 22
	add_child(_hearts)
	_coins = _label(Vector2.ZERO, FONT_SIZE * 3 / 4)
	_coins.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_coins.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_coins.offset_right = -28
	_coins.offset_top = 22 + 6 * 6 + 16
	_hint = _label(Vector2.ZERO, FONT_SIZE * 5 / 8)
	_hint.text = "Arrows or WASD move · Space or J swing · M map · Esc menu"
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hint.offset_left = 28
	_hint.offset_top = -64
	_hint.modulate.a = 0.8
	_toast = _label(Vector2.ZERO, FONT_SIZE)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.offset_top = 160
	_toast.modulate.a = 0.0

	_strategic = StrategicMap.new()
	_strategic.ui = self
	_strategic.set_anchors_preset(Control.PRESET_FULL_RECT)
	_strategic.visible = false
	add_child(_strategic)

	_menu = PanelContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER)
	_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_menu.grow_vertical = Control.GROW_DIRECTION_BOTH
	_menu.visible = false
	add_child(_menu)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	_menu.add_child(margin)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)
	var heading := Label.new()
	heading.text = "Node gates"
	heading.add_theme_font_size_override("font_size", FONT_SIZE * 3 / 2)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)
	var info := Label.new()
	info.text = "Clear a map of foes to open its gates.\nVisited maps always open. The game saves as you go."
	info.add_theme_font_size_override("font_size", FONT_SIZE * 3 / 4)
	info.custom_minimum_size = Vector2(900, 0)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	_button(box, "Resume", func(): _show_menu(false)).name = "Resume"
	_button(box, "Strategic map", func(): _show_menu(false); _show_map(true))
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


func _label(at: Vector2, size: int) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	return l


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


static func draw_heart(canvas: CanvasItem, at: Vector2, px: float, fill: float) -> void:
	for y in HEART.size():
		var row: String = HEART[y]
		for x in row.length():
			if row[x] != "X":
				continue
			var lit := (x + 0.5) / row.length() <= fill
			var c := Color(0.86, 0.2, 0.22) if lit else Color(0.22, 0.12, 0.14, 0.85)
			canvas.draw_rect(Rect2(at + Vector2(x, y) * px, Vector2(px, px)), c)


## Hearts in the top right: two hit points each, filled from the left.
class Hearts extends Control:
	const PX := 6.0
	var ui: Node

	func _draw() -> void:
		if ui == null or ui.map == null:
			return
		var h: Dictionary = ui.map.world.hero
		var count := int(ceil(h.max_hp / 2.0))
		var width := 7 * PX + 8
		for i in count:
			var fill := clampf((h.hp - i * 2) / 2.0, 0.0, 1.0)
			var at := Vector2(-(count - i) * width, 0)
			draw_rect(Rect2(at - Vector2(PX, PX), Vector2(9 * PX, 8 * PX)), Color(0, 0, 0, 0.35))
			ui.draw_heart(self, at, PX, fill)


## The strategic map: every node visited as a dot on the world grid, the
## moves made between them as lines, the ways a cleared node opens as faint
## rings, and the walker's node ringed and named. Arrows or WASD pan, + and -
## zoom; M, Tab, or Escape close it.
class StrategicMap extends Control:
	const SPACING := 128.0
	var ui: Node
	var pan := Vector2.ZERO
	var zoom := 1.0

	func recenter() -> void:
		var c: Vector2i = ui.map.world.current
		pan = -Vector2(c.x, -c.y) * SPACING
		queue_redraw()

	func _process(delta: float) -> void:
		if not visible:
			return
		var move := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
			move.x += 1
		if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
			move.x -= 1
		if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
			move.y += 1
		if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
			move.y -= 1
		if move != Vector2.ZERO:
			pan += move * 600.0 * delta / zoom
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom = minf(2.5, zoom * 1.15)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom = maxf(0.25, zoom / 1.15)
			queue_redraw()

	func _unhandled_key_input(event: InputEvent) -> void:
		if not visible or not event.pressed:
			return
		if event.physical_keycode in [KEY_EQUAL, KEY_KP_ADD]:
			zoom = minf(2.5, zoom * 1.25)
			queue_redraw()
		elif event.physical_keycode in [KEY_MINUS, KEY_KP_SUBTRACT]:
			zoom = maxf(0.25, zoom / 1.25)
			queue_redraw()

	func _at(c: Vector2i) -> Vector2:
		return size / 2.0 + (Vector2(c.x, -c.y) * SPACING + pan) * zoom

	func _draw() -> void:
		var w: GateWorld = ui.map.world
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.07, 0.96))
		# The rings, faintly: every fourth, and the end of the world.
		for r in range(4, GateWorld.MAX_RING + 1, 4) + [GateWorld.MAX_RING]:
			var a := _at(Vector2i(-r, r)) - Vector2(SPACING, SPACING) * zoom * 0.5
			var b := _at(Vector2i(r, -r)) + Vector2(SPACING, SPACING) * zoom * 0.5
			var col := Color(0.6, 0.8, 0.6, 0.06 if r != GateWorld.MAX_RING else 0.22)
			draw_rect(Rect2(a, b - a), col, false, 2.0)
		# Ways out of cleared nodes not taken yet.
		for c in w.nodes:
			if not w.cleared(c):
				continue
			for side in GateWorld.DIRS:
				var n: Vector2i = c + GateWorld.DIRS[side]
				if w.visited(n) or not GateWorld.in_world(n):
					continue
				draw_line(_at(c), _at(n), Color(0.85, 0.8, 0.55, 0.3), 3.0)
				draw_arc(_at(n), 14.0 * zoom, 0, TAU, 24, Color(0.85, 0.8, 0.55, 0.55), 3.0)
		for l in w.links:
			var ends: PackedStringArray = l.split("|")
			draw_line(_at(GateWorld.unkey(ends[0])), _at(GateWorld.unkey(ends[1])), Color(0.92, 0.86, 0.62, 0.9), 7.0)
		for c in w.nodes:
			var p := _at(c)
			var col := Color(0.55, 0.82, 0.45) if w.cleared(c) else Color(0.92, 0.5, 0.28)
			draw_circle(p, 22.0 * zoom, col)
			draw_arc(p, 22.0 * zoom, 0, TAU, 32, Color(0.05, 0.08, 0.07), 3.0)
			if zoom >= 0.6 or c == w.current:
				var name := GateWorld.node_name(c)
				draw_string(font, p + Vector2(-150, 34 * zoom + 22), name, HORIZONTAL_ALIGNMENT_CENTER, 300, 28 if c != w.current else 34, Color(0.92, 0.92, 0.86, 0.9) if c != w.current else Color.WHITE)
		var here := _at(w.current)
		draw_arc(here, 32.0 * zoom, 0, TAU, 40, Color.WHITE, 4.0)
		var head := "You are at %s · %s · ring %d" % [GateWorld.node_name(w.current), GateWorld.map_type(w.current), GateWorld.ring(w.current)]
		draw_string(font, Vector2(48, 80), "Strategic map", HORIZONTAL_ALIGNMENT_LEFT, -1, 56, Color(0.95, 0.92, 0.8))
		draw_string(font, Vector2(48, 140), head, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color(0.95, 0.92, 0.8))
		var cleared := 0
		for c in w.nodes:
			if w.cleared(c):
				cleared += 1
		draw_string(font, Vector2(48, 190), "%d nodes visited, %d cleared" % [w.nodes.size(), cleared], HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(0.8, 0.8, 0.75))
		var y := size.y - 60
		draw_circle(Vector2(60, y - 10), 10, Color(0.55, 0.82, 0.45))
		draw_string(font, Vector2(80, y), "cleared", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.85, 0.85, 0.8))
		draw_circle(Vector2(230, y - 10), 10, Color(0.92, 0.5, 0.28))
		draw_string(font, Vector2(250, y), "foes remain", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.85, 0.85, 0.8))
		draw_arc(Vector2(450, y - 10), 8, 0, TAU, 20, Color(0.85, 0.8, 0.55, 0.6), 2.0)
		draw_string(font, Vector2(470, y), "open, not visited", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.85, 0.85, 0.8))
		draw_string(font, Vector2(760, y), "Arrows pan · + and - zoom · M or Esc to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.7, 0.7, 0.66))
