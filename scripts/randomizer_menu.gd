extends CanvasLayer
## Escape menu for a randomizer scene: shows the current map and regenerates
## it from a new seed with the same rules. Works with any map script that
## has build(id), map_summary() -> {id, name, checks}, and recipe_names();
## when there are recipes, a picker can pin the next seed to one of them.

const FONT_SIZE := 40
const MAX_ID := 999_999

@export var map_path: NodePath = ^".."
@export var title := "Randomizer"

@onready var map: Node = get_node(map_path)

var _rng := RandomNumberGenerator.new()
var _panel: PanelContainer
var _info: Label
var _hud: Label
var _recipe: OptionButton
var _regenerate: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_ui()
	_panel.hide()
	_refresh.call_deferred() # the map builds in its own _ready, after this one


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_set_open(not _panel.visible)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	_panel.visible = open
	get_tree().paused = open
	if open:
		_refresh()
		_regenerate.grab_focus()


func _on_regenerate() -> void:
	var id := _rng.randi_range(20, MAX_ID)
	var count: int = map.recipe_names().size()
	var pinned := _recipe.selected - 1 if _recipe else -1
	if pinned >= 0 and count > 0:
		id = id - id % count + pinned
	map.build(id)
	_refresh()
	_set_open(false)


func _refresh() -> void:
	var s: Dictionary = map.map_summary()
	_info.text = "Map %d\n%s\nChecks: %s" % [s.id, s.name, s.checks]
	_hud.text = "Map %d · %s · Esc for menu" % [s.id, s.name]


func _build_ui() -> void:
	_hud = Label.new()
	_hud.position = Vector2(24, 16)
	_hud.add_theme_font_size_override("font_size", FONT_SIZE * 3 / 4)
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 8)
	add_child(_hud)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", FONT_SIZE * 3 / 2)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(heading)

	_info = Label.new()
	_info.add_theme_font_size_override("font_size", FONT_SIZE)
	_info.custom_minimum_size = Vector2(900, 0)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_info)

	var names: Array = map.recipe_names()
	if not names.is_empty():
		_recipe = OptionButton.new()
		_recipe.add_theme_font_size_override("font_size", FONT_SIZE)
		_recipe.get_popup().add_theme_font_size_override("font_size", FONT_SIZE)
		_recipe.add_item("Next recipe: any (seed %% %d)" % names.size())
		for i in names.size():
			_recipe.add_item("Next recipe: %d %s" % [i, names[i]])
		box.add_child(_recipe)

	_regenerate = _button(box, "Regenerate with a new seed", _on_regenerate)
	_button(box, "Resume", func(): _set_open(false))
	_button(box, "Quit", func(): get_tree().quit())


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	b.pressed.connect(action)
	parent.add_child(b)
	return b
