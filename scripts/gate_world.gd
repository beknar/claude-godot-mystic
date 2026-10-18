class_name GateWorld
extends RefCounted
## node-gates: the world graph and its save file. Every map is a node on a
## square grid round the first map (c-0); walking off a map's north, east,
## south, or west edge moves one node that way. A node's ring is its distance
## from c-0 (the larger of the two offsets, so the eight nodes round c-0 are
## ring 1), and the ring sets the map type and the foes:
##
## - ring 0 and 1: Pastoral (the first Painted Lands map type)
## - ring 2: Crossroads, ring 3: Pond walk, ... ring r: map type r - 1, up to
##   ring 33: Manor green (map type 32). The river map types (33-35) are not
##   used. Beyond ring 33 the land ends.
##
## Names: the direction from c-0 and the ring, "n-1", "ne-1", "sw-3". A node
## off the axes and diagonals adds its offset along the other axis: "n-2.e1"
## is two north and one east, "e-3.s2" three east and two south.

## The save file; the demo reel (tools/node_gates_demo.gd) points it elsewhere.
static var save_path := "user://node_gates_save.json"
const VERSION := 1
const MAX_RING := 33
const DIRS := {"n": Vector2i(0, 1), "e": Vector2i(1, 0), "s": Vector2i(0, -1), "w": Vector2i(-1, 0)}
const OPPOSITE := {"n": "s", "s": "n", "e": "w", "w": "e"}
const START_HERO := {"hp": 6, "max_hp": 6, "damage": 2, "coins": 0}

## Foes by ring: the kinds (Foe.KINDS) a ring draws from. Rings 0-2 are the
## basic slimes (ring 2's a little tougher through the ring scaling).
const POOLS := [
	[0, ["slime_green"]],
	[3, ["slime_green", "slime_blue"]],
	[6, ["slime_green", "slime_blue", "cloaked_figure"]],
	[11, ["slime_blue", "cloaked_figure", "samurai"]],
	[17, ["cloaked_figure", "samurai", "fire_knight"]],
	[25, ["samurai", "fire_knight", "dark_knight"]],
	[33, ["fire_knight", "dark_knight"]],
]

var seed_value := 0
var current := Vector2i.ZERO
## The side the walker came in through on the current node ("" on c-0 or
## after a load: the map's own spawn).
var entry := ""
var hero := START_HERO.duplicate()
var nodes := {} # Vector2i -> {cleared, foes: Array[{kind, x, y, hp, boss}], chest: {x, y, opened} or {}}
var links := {} # "x,y|x,y" (sorted) -> true: the moves made between nodes


static func ring(c: Vector2i) -> int:
	return maxi(absi(c.x), absi(c.y))


static func node_name(c: Vector2i) -> String:
	if c == Vector2i.ZERO:
		return "c-0"
	var r := ring(c)
	var ns := "n" if c.y > 0 else ("s" if c.y < 0 else "")
	var ew := "e" if c.x > 0 else ("w" if c.x < 0 else "")
	if c.x == 0 or c.y == 0 or absi(c.x) == absi(c.y):
		return "%s%s-%d" % [ns, ew, r]
	if absi(c.y) > absi(c.x):
		return "%s-%d.%s%d" % [ns, r, ew, absi(c.x)]
	return "%s-%d.%s%d" % [ew, r, ns, absi(c.y)]


## The Painted Lands map type (PaintedTerrain.RECIPES index) for a node.
static func recipe_for(c: Vector2i) -> int:
	return maxi(0, ring(c) - 1)


static func map_type(c: Vector2i) -> String:
	return PaintedTerrain.RECIPES[recipe_for(c)].name


static func in_world(c: Vector2i) -> bool:
	return ring(c) <= MAX_RING


static func key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func unkey(s: String) -> Vector2i:
	var parts := s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))


static func link_key(a: Vector2i, b: Vector2i) -> String:
	var ka := key(a)
	var kb := key(b)
	return ka + "|" + kb if ka < kb else kb + "|" + ka


## The map id a node is generated from: the same for a node for the whole
## game, different between games.
func map_id_for(c: Vector2i) -> int:
	var h := (seed_value * 1442695041 + (c.x + 4096) * 374761393 + (c.y + 4096) * 668265263) & 0x7FFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7FFFFFFF
	h = h ^ (h >> 16)
	return 20 + h % 900000


## The foes a node starts with: kinds and boss flags (Foe places them).
func foe_plan(c: Vector2i) -> Array[Dictionary]:
	var r := ring(c)
	var rng := RandomNumberGenerator.new()
	rng.seed = map_id_for(c) * 31 + 7
	var pool: Array = POOLS[0][1]
	for p in POOLS:
		if r >= p[0]:
			pool = p[1]
	var count := 2 if r == 0 else (3 if r == 1 else mini(4 + (r - 2) / 4, 9))
	var out: Array[Dictionary] = []
	for i in count:
		out.append({"kind": pool[rng.randi() % pool.size()], "boss": false})
	if r == MAX_RING:
		out.append({"kind": "dark_knight", "boss": true}) # the manor's lord
	return out


## The reward in a cleared node's chest: coins, healing, and every few rings a
## lasting gain. Basic near c-0, richer outward.
static func reward_for(c: Vector2i) -> Dictionary:
	var r := ring(c)
	var out := {"coins": 3 + r * 2, "heal": 2 if r <= 2 else 99, "max_hp": 0, "damage": 0, "gold": r >= 11}
	if r > 0 and r % 4 == 0:
		out.max_hp = 2
	if r > 0 and r % 6 == 0:
		out.damage = 1
	if r == MAX_RING:
		out.coins += 100
		out.max_hp = 4
		out.damage = 2
	return out


func node(c: Vector2i) -> Dictionary:
	return nodes.get(c, {})


func visited(c: Vector2i) -> bool:
	return nodes.has(c)


func cleared(c: Vector2i) -> bool:
	return nodes.has(c) and nodes[c].get("cleared", false)


func new_game(p_seed: int) -> void:
	seed_value = p_seed
	current = Vector2i.ZERO
	entry = ""
	hero = START_HERO.duplicate()
	nodes = {}
	links = {}


func save() -> void:
	var out_nodes := {}
	for c in nodes:
		out_nodes[key(c)] = nodes[c]
	var data := {
		"version": VERSION,
		"seed": seed_value,
		"current": key(current),
		"entry": entry,
		"hero": hero,
		"nodes": out_nodes,
		"links": links.keys(),
	}
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## Loads the save file; false (and a fresh world) when there is none.
func load_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return false
	seed_value = int(parsed.seed)
	current = unkey(parsed.current)
	entry = String(parsed.get("entry", ""))
	hero = START_HERO.duplicate()
	for k in parsed.hero:
		hero[k] = int(parsed.hero[k])
	nodes = {}
	for k in parsed.nodes:
		var n: Dictionary = parsed.nodes[k]
		for f in n.get("foes", []):
			f.x = float(f.x)
			f.y = float(f.y)
			f.hp = int(f.hp)
		nodes[unkey(k)] = n
	links = {}
	for l in parsed.links:
		links[String(l)] = true
	return true


static func erase_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
