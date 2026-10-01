extends Node2D
## randomizer-paintedlands-forest-farm: every Painted Lands map (the forest
## randomizer, 36 types), every farm map (52 types in three seasons), and the
## farmsteads (12 types: Farm ground with the Forest's houses, fires, torches,
## clutter, and summer trees), all with the Cozy Farm animals. The map id picks
## the type; each pipeline keeps its own ground (a map has one ground: Forest
## lawn and Farm lawn never meet), and the one not in use is hidden and
## paused, which also takes its colliders out of the physics space.
##   recipe 0-35   Painted Lands (forest.gd, randomizer-paintedlands; 33-35 rivers)
##   recipe 36-87  farm (farm.gd, randomizer-paintedlands-farm; 84-87 rivers)
##   recipe 88-99  farmsteads (farm.gd with `mixed`)

const FOREST_SCENE := preload("res://scenes/randomizer-paintedlands/randomizer-paintedlands.tscn")
const FARM_SCENE := preload("res://scenes/randomizer-paintedlands-farm/randomizer-paintedlands-farm.tscn")

@export var map_id := 200088 # recipe 88 (200088 % 100): the first farmstead, Cottage homestead

var forest: Node2D
var farm: Node2D
var active: Node2D
var recipe_id := 0


func _ready() -> void:
	forest = _embed(FOREST_SCENE)
	farm = _embed(FARM_SCENE)
	farm.set("mixed", true)
	add_child(forest)
	add_child(farm)
	build(map_id)


# An instance of a randomizer scene without its own menu (this scene has one).
func _embed(scene: PackedScene) -> Node2D:
	var n: Node2D = scene.instantiate()
	var menu := n.get_node_or_null("Menu")
	if menu:
		n.remove_child(menu)
		menu.free()
	return n


func forest_count() -> int:
	return PaintedTerrain.RECIPES.size()


func farm_count() -> int:
	return FarmTerrain.all_recipes(true).size()


## Generates map `id` in the pipeline its recipe belongs to (pinned: a recipe
## index over the whole list).
func build(id: int, pinned := -1) -> void:
	map_id = id
	var total := forest_count() + farm_count()
	recipe_id = pinned if pinned >= 0 else id % total
	if recipe_id < forest_count():
		_activate(forest)
		forest.build(id, recipe_id)
	else:
		_activate(farm)
		farm.build(id, recipe_id - forest_count())
	# The hidden pipeline's camera is switched off, or the viewport falls back
	# to it when the walker is reparented indoors.
	for n in [forest, farm]:
		var cam := _camera(n)
		if cam:
			cam.enabled = n == active
	_camera(active).make_current()


func _activate(p: Node2D) -> void:
	active = p
	for n in [forest, farm]:
		var on: bool = n == p
		n.visible = on
		n.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


# The walker's camera wherever the walker is (outdoors or in a home).
func _camera(p: Node2D) -> Camera2D:
	var found := p.find_children("Camera", "Camera2D", true, false)
	return found[0] if not found.is_empty() else null


## For the randomizer menu: every map type, marked by where it comes from.
func recipe_names() -> Array[String]:
	var out: Array[String] = []
	for r in PaintedTerrain.RECIPES:
		out.append("Forest: %s" % r.name)
	var farm_list := FarmTerrain.all_recipes(true)
	for i in farm_list.size():
		var r: Dictionary = farm_list[i]
		var kind := "Farmstead" if i >= FarmTerrain.RECIPES.size() else "Farm"
		var season: String = r.get("season", "summer")
		out.append("%s%s: %s" % [kind, "" if season == "summer" else " (%s)" % season, r.name])
	return out


func map_summary() -> Dictionary:
	var s: Dictionary = active.map_summary()
	return {"id": map_id, "name": "Recipe %d: %s" % [recipe_id, recipe_names()[recipe_id]], "checks": s.checks}
