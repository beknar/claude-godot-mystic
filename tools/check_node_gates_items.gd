extends Node
## Headless check of node-gates' items, buffs, mana, and spin, on the real
## scene (its own save file, erased after):
##   godot --headless --path . res://tools/check_node_gates_items.tscn
## Prints PASS or FAIL per check and a SUMMARY line.

var _scene: Node
var _fails := 0
var _passes := 0


func _ready() -> void:
	GateWorld.save_path = "user://node_gates_items_check.json"
	GateWorld.erase_save()
	_scene = load("res://scenes/node-gates/node-gates.tscn").instantiate()
	add_child(_scene)
	_run.call_deferred()


func _check(name: String, ok: bool, detail := "") -> void:
	if ok:
		_passes += 1
	else:
		_fails += 1
	print("%s %s%s" % ["PASS" if ok else "FAIL", name, "" if detail == "" else " (" + detail + ")"])


func _seconds(t: float) -> void:
	var end := Time.get_ticks_msec() + t * 1000.0 / Engine.time_scale
	while Time.get_ticks_msec() < end:
		await get_tree().physics_frame


func _run() -> void:
	while _scene.walker == null:
		await get_tree().process_frame
	await get_tree().physics_frame
	var m := _scene
	var w: GateWorld = m.world
	var h: Dictionary = w.hero
	for f in m.foes:
		f.queue_free()
	m.foes.clear()
	_check("new bag", w.bag[0].get("id", "") == "healing_small" and w.bag[0].count == 2 and w.bag[1].get("id", "") == "bread", str(w.bag.slice(0, 3)))
	_check("27 slots", w.bag.size() == GateWorld.BAG_SLOTS)
	_check("33 items", GateItems.ids().size() == 33, str(GateItems.ids().size()))

	h.hp = h.max_hp
	m.use_slot(0)
	_check("healing at full health is not used", w.bag[0].count == 2)
	h.hp = 2
	m.use_slot(0)
	_check("small healing potion heals 10%", h.hp == 3 and w.bag[0].count == 1, "hp %d" % h.hp)

	h.mana = 10
	var slot := _slot_of(w, "mana_large", 1)
	m.use_slot(slot)
	_check("large mana potion restores 30%", h.mana >= 40 and h.mana <= 41, "mana %d (40, and maybe a point of the slow refill)" % h.mana)
	_check("used item leaves its slot", w.bag[slot].is_empty())

	Engine.time_scale = 8.0
	slot = _slot_of(w, "speed_wondrous", 1)
	m.use_slot(slot)
	_check("wondrous speed potion: +50% speed", is_equal_approx(m.walker.speed_mult, 1.5), str(m.walker.speed_mult))
	await _seconds(31.0)
	_check("speed wears off after 30 s", is_equal_approx(m.walker.speed_mult, 1.0), str(m.walker.speed_mult))

	h.hp = 1
	slot = _slot_of(w, "steak", 1)
	m.use_slot(slot)
	await _seconds(10.5)
	_check("steak regenerates 9% a second for 10 s", h.hp == h.max_hp and not m.buffs.has("regen"), "hp %d of %d" % [h.hp, h.max_hp])
	Engine.time_scale = 1.0

	h.mana = 30
	var foe := Foe.new()
	foe.setup("slime_green", 0)
	foe.position = m.walker.position + Vector2(18, 0)
	foe.home = foe.position
	foe.map = m
	m.actors.add_child(foe)
	m.foes.append(foe)
	var before := foe.hp
	m.walker.spin_wanted.emit()
	_check("spin costs 20 mana", h.mana == 10, "mana %d" % h.mana)
	await _seconds(0.5)
	_check("spin hits a foe beside the walker", foe.hp < before, "hp %d -> %d" % [before, foe.hp])
	h.mana = 5
	m.walker.spin_wanted.emit()
	_check("no spin without the mana", h.mana == 5)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var counts := {}
	for id in GateItems.roll(40000, rng):
		counts[id] = counts.get(id, 0) + 1
	var common := float(counts.get("healing_small", 0))
	var rare := float(counts.get("steak", 0))
	_check("rolls follow rarity (80 vs 5)", rare > 0 and absf(common / rare - 16.0) < 3.0, "%d small healing, %d steak" % [common, rare])

	w.give("travel_cake", 2)
	w.save()
	var again := GateWorld.new()
	again.load_save()
	_check("the bag survives a save", JSON.stringify(again.bag) == JSON.stringify(w.bag))
	_check("mana survives a save", again.hero.mana == h.mana)

	print("SUMMARY %d passed, %d failed" % [_passes, _fails])
	GateWorld.erase_save()
	get_tree().quit()


# Puts `count` of `id` in the bag and returns its slot.
func _slot_of(w: GateWorld, id: String, count: int) -> int:
	w.give(id, count)
	for i in w.bag.size():
		if not w.bag[i].is_empty() and w.bag[i].id == id:
			return i
	return -1
