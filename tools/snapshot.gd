extends Node
## Saves one frame of a scene to a PNG, for checking UI without the editor:
##   godot --path . res://tools/snapshot.tscn -- <scene> <out.png> [seconds] [map|overview|inventory|menu] [tour]
## `map` opens node-gates' strategic map first, `overview` its map of the
## current node, `inventory` its bag, `menu` the scene's Escape menu.
## `tour` (node-gates) first travels c-0 -> e-1 -> ne-1 -> n-1 and back to
## c-0, so the strategic map has nodes and thumbnails, and fills the bag.
## node-gates runs on its own save file here (erased after), so the player's
## save is untouched.

var _scene: Node
var _out := ""
var _wait := 3.0
var _open := ""
var _tour := false
var _toured := false
var _tour_done := false


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("usage: -- <scene> <out.png> [seconds] [map|menu]")
		get_tree().quit(1)
		return
	_out = args[1]
	if args.size() > 2:
		_wait = float(args[2])
	if args.size() > 3:
		_open = args[3]
	_tour = "tour" in args
	GateWorld.save_path = "user://node_gates_snapshot.json"
	GateWorld.erase_save()
	_scene = load(args[0]).instantiate()
	add_child(_scene)


func _process(delta: float) -> void:
	if _tour and not _toured and _scene.get("walker") != null and not _scene.busy:
		_toured = true
		await _do_tour()
		_wait = 1.5
		_tour_done = true
		return
	_wait -= delta
	if _wait > 0.0 or _out == "" or (_tour and not _tour_done) or (_scene.get("busy") == true):
		return
	var out := _out
	_out = ""
	var ui: Node = _scene.get_node_or_null("UI")
	if _open == "map" and ui:
		ui._show_map(true)
	elif _open == "overview" and ui:
		ui._show_overview(true)
	elif _open == "inventory" and ui:
		ui._show_inventory(true)
	elif _open == "menu":
		var menu: Node = ui if ui and ui.has_method("_show_menu") else _scene.get_node_or_null("Menu")
		if menu and menu.has_method("_show_menu"):
			menu._show_menu(true)
		elif menu:
			menu._set_open(true)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out)
	GateWorld.erase_save()
	get_tree().quit()


func _do_tour() -> void:
	var w = _scene.world
	for id in GateItems.ids():
		if GateItems.item(id).tier <= 4 or id in ["steak", "healing_legendary", "mana_rare", "speed_very_rare"]:
			w.give(id, 1 + randi() % 3)
	for c in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i.ZERO]:
		w.nodes[w.current].cleared = true
		_scene.travel(c, "")
		while _scene.busy:
			await get_tree().process_frame
		for i in 8:
			await get_tree().process_frame
