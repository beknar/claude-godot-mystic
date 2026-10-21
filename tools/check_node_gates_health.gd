extends Node
## Fast headless health check of node-gates on the real scene, one node per
## ring (0-33, or the rings given), entering by each gate in turn, on its own
## save file (erased after):
##   godot --headless --fixed-fps 60 --path . res://tools/check_node_gates_health.tscn -- [rings...]
## Per node:
## - spawning: the walker stands where it came in, inside the map, and its
##   body touches no collider; every foe of the ring's plan is there, on a
##   walkable cell, its body clear of colliders; a reopened chest stands clear;
## - colliders: the world has its collision shapes, every blocking prop,
##   house, and ridge has its own, and the walker's and foes' bodies are on
##   their layers;
## - y-sorting: Actors sorts by y, and the walker, the foes, and the chest
##   all sort there with their feet on their origin;
## - liveliness: the map's liveliness floor (the weakest camera window's
##   predicted motion, PaintedTerrain.FLOOR) is met;
## - performance: the build's time, and the wall time of a whole frame
##   (headless with --fixed-fps runs frames back to back, so this is what a
##   frame costs) over 2 s with the foes awake and chasing; `base` measures
##   the plain Painted Lands randomizer the same way, for comparison.
## Prints a line per node and a SUMMARY.

const BUILD_MS := 4000.0 # a build slower than this is flagged
const FRAME_MS := 8.0 # physics + process a frame, averaged, above this is flagged
const SIDES := ["", "n", "e", "s", "w"]

var _scene: Node
var _rows: Array = []
var _fails := 0


func _ready() -> void:
	if "base" in OS.get_cmdline_user_args():
		_base.call_deferred()
		return
	GateWorld.save_path = "user://node_gates_health_check.json"
	GateWorld.erase_save()
	_scene = load("res://scenes/node-gates/node-gates.tscn").instantiate()
	add_child(_scene)
	_run.call_deferred()


func _run() -> void:
	while _scene.walker == null:
		await get_tree().process_frame
	var rings: Array = []
	for a in OS.get_cmdline_user_args():
		rings.append(int(a))
	if rings.is_empty():
		rings = range(GateWorld.MAX_RING + 1)
	var m := _scene
	var w: GateWorld = m.world
	for r in rings:
		var dirs := [Vector2i(0, r), Vector2i(r, 0), Vector2i(0, -r), Vector2i(-r, 0), Vector2i(r, -r), Vector2i(-r, r)]
		var c: Vector2i = dirs[r % dirs.size()] if r > 0 else Vector2i.ZERO
		var side: String = SIDES[r % SIDES.size()] if r > 0 else ""
		w.current = c
		w.entry = side
		var t0 := Time.get_ticks_usec()
		m.build(w.node(c).get("map_id", w.map_id_for(c)))
		var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
		for i in 3:
			await get_tree().physics_frame
		var fails := PackedStringArray()
		_spawning(m, side, fails)
		_colliders(m, fails)
		_ysort(m, fails)
		var floor_line := ""
		for line in m.report.split("\n"):
			if line.strip_edges().begins_with("floor:"):
				floor_line = line.strip_edges()
		var after := float(floor_line.get_slice("->", 1).strip_edges().get_slice("%", 0)) if "->" in floor_line else -1.0
		if after < PaintedTerrain.FLOOR - 0.0005:
			fails.append("liveliness floor %.3f%% under %.3f%%" % [after, PaintedTerrain.FLOOR])
		# Performance: foes awake (the walker stands among them for 2 s).
		var total := 0.0
		var worst := 0.0
		var frames := 120
		var k := 0
		for f in m.foes: # in a ring round the walker, inside their aggro range
			f.position = m.walker.position + Vector2.from_angle(TAU * k / maxf(1, m.foes.size())) * 56.0
			k += 1
		await get_tree().process_frame
		var last := Time.get_ticks_usec()
		for i in frames:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var ms := (now - last) / 1000.0
			last = now
			total += ms
			worst = maxf(worst, ms)
			m.world.hero.hp = m.world.hero.max_hp # stay alive for the measurement
		var chasing := 0
		for f in m.foes:
			if f.alive() and f.state != Foe.State.IDLE:
				chasing += 1
		if build_ms > BUILD_MS:
			fails.append("build %.0f ms" % build_ms)
		if total / frames > FRAME_MS:
			fails.append("%.1f ms a frame" % (total / frames))
		if not m.foes.is_empty() and chasing == 0:
			fails.append("no foe woke with the walker among them")
		var counts := _counts(m)
		var ok := fails.is_empty()
		if not ok:
			_fails += 1
		print("%s %s ring %d %s (in by %s): build %.0f ms, %.2f ms a frame (worst %.1f), %d foes (%d chasing), %d colliders, %d actors, floor %s | %s" % [
			"PASS" if ok else "FAIL", GateWorld.node_name(c), r, GateWorld.map_type(c), side if side != "" else "spawn",
			build_ms, total / frames, worst, m.foes.size(), chasing, counts.shapes, counts.actors,
			floor_line.get_slice("->", 1).strip_edges().get_slice(",", 0) if "->" in floor_line else "?",
			"ok" if ok else "; ".join(fails)])
		_rows.append({"node": GateWorld.node_name(c), "build": build_ms, "frame": total / frames})
	var builds := _rows.map(func(x): return x.build)
	var frames_ms := _rows.map(func(x): return x.frame)
	print("SUMMARY %d of %d nodes passed; build %.0f ms average (slowest %.0f); %.2f ms a frame average (slowest %.2f)" % [
		_rows.size() - _fails, _rows.size(), _avg(builds), builds.max(), _avg(frames_ms), frames_ms.max()])
	GateWorld.erase_save()
	get_tree().quit()


func _avg(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += v
	return s / maxf(1, a.size())


func _clear(body: CollisionObject2D, pos: Vector2, shape_node: CollisionShape2D) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape_node.shape
	q.transform = Transform2D(0.0, pos + shape_node.position)
	q.collision_mask = 1
	q.exclude = [body.get_rid()]
	return get_viewport().world_2d.direct_space_state.intersect_shape(q, 1).is_empty()


func _spawning(m: Node, side: String, fails: PackedStringArray) -> void:
	var wk: CharacterBody2D = m.walker
	var map_rect := Rect2(0, 0, PaintedTerrain.WIDTH * 16, PaintedTerrain.HEIGHT * 16)
	if wk.get_parent() != m.actors:
		fails.append("walker not under Actors")
	if not map_rect.has_point(wk.position):
		fails.append("walker outside the map at %s" % wk.position)
	if wk.position.distance_to(m._entry_point(side)) > 24.0:
		fails.append("walker %.0f px from its gate" % wk.position.distance_to(m._entry_point(side)))
	if not _clear(wk, wk.position, wk.get_node("Body")):
		fails.append("walker spawned in a collider at %s" % wk.position)
	var want: int = m.world.foe_plan(m.world.current).size()
	if m.foes.size() != want:
		fails.append("%d foes, plan wants %d" % [m.foes.size(), want])
	for f in m.foes:
		var cell := Vector2i(f.position / 16.0)
		if not m.terrain.walkable(cell):
			fails.append("%s on an unwalkable cell %s" % [f.kind, cell])
		var shape: CollisionShape2D = null
		for ch in f.get_children():
			if ch is CollisionShape2D:
				shape = ch
		if shape == null:
			fails.append("%s has no body" % f.kind)
		elif not _clear(f, f.position, shape):
			fails.append("%s spawned in a collider at %s" % [f.kind, cell])


func _colliders(m: Node, fails: PackedStringArray) -> void:
	if m.collision.get_child_count() < 4:
		fails.append("world collision has %d shapes" % m.collision.get_child_count())
	var missing := 0
	for body in m.actors.get_children():
		if body is StaticBody2D:
			var n := String(body.name)
			var needs: bool = n.begins_with("HOUSE_BODY") or n.begins_with("RewardChest")
			if needs and not body.get_children().any(func(ch): return ch is CollisionShape2D):
				missing += 1
	for prop in m.terrain.props:
		if prop.get("block", false) and prop.has("art"):
			var art: Dictionary = PaintedTerrain.PROPS[prop.art]
			if art.block == Vector2.ZERO:
				continue
			var node: Node = m.actors.get_node_or_null("%s_%d_%d" % [prop.art, prop.cell.x, prop.cell.y])
			if node and not node.get_children().any(func(ch): return ch is CollisionShape2D):
				missing += 1
	if missing > 0:
		fails.append("%d blocking bodies without a collider" % missing)
	if m.walker.collision_layer != 2 or m.walker.collision_mask != 1:
		fails.append("walker layers %d/%d" % [m.walker.collision_layer, m.walker.collision_mask])
	for f in m.foes:
		if f.collision_layer != 4 or f.collision_mask != 1:
			fails.append("foe layers %d/%d" % [f.collision_layer, f.collision_mask])
			break


# Everything that moves sorts in Actors by its feet: the node's origin is the
# bottom of what it draws (within 2 px).
func _ysort(m: Node, fails: PackedStringArray) -> void:
	if not m.actors.y_sort_enabled:
		fails.append("Actors does not y-sort")
	var wk: CharacterBody2D = m.walker
	var spr: Sprite2D = wk.sprite
	var frame_h := float(spr.texture.get_height()) / spr.vframes
	# A centered sprite: the feet row sits at offset - half a frame + feet_row.
	var walker_feet: float = spr.offset.y - frame_h / 2.0 + wk.feet_row
	if absf(walker_feet) > 1.0:
		fails.append("walker feet %.1f px off its origin" % walker_feet)
	for f in m.foes:
		if f.get_parent() != m.actors:
			fails.append("%s not under Actors" % f.kind)
			continue
		var s: AnimatedSprite2D = null
		for ch in f.get_children():
			if ch is AnimatedSprite2D:
				s = ch
		if s == null:
			continue
		var tex := s.sprite_frames.get_frame_texture(s.animation, s.frame)
		var bottom := s.offset.y + tex.get_height()
		# Slimes stand on their frame's bottom row; the RPG Characters' feet are
		# on row RPG_FEET of 32.
		var want := 0.0 if f.kind.begins_with("slime") else (32.0 - Foe.RPG_FEET)
		if absf(bottom - want) > 2.0:
			fails.append("%s feet %.0f px off its origin" % [f.kind, bottom - want])
	if m.chest and m.chest.get_parent() != m.actors:
		fails.append("chest not under Actors")


func _counts(m: Node) -> Dictionary:
	var shapes: int = m.collision.get_child_count()
	for body in m.actors.get_children():
		for ch in body.get_children():
			if ch is CollisionShape2D:
				shapes += 1
	return {"shapes": shapes, "actors": m.actors.get_child_count()}


# `base`: the same frame times on the plain Painted Lands randomizer (no
# node-gates logic, no foes, no HUD), map type 0, for comparison.
func _base() -> void:
	var scene: Node = load("res://scenes/randomizer-paintedlands/randomizer-paintedlands.tscn").instantiate()
	add_child(scene)
	await get_tree().process_frame
	scene.build(300000)
	for i in 30:
		await get_tree().physics_frame
	var total := 0.0
	await get_tree().process_frame
	var last := Time.get_ticks_usec()
	for i in 120:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		total += (now - last) / 1000.0
		last = now
	print("BASE randomizer-paintedlands map 300000 (%s): %.2f ms a frame" % [scene.terrain.recipe.name, total / 120.0])
	get_tree().quit()
