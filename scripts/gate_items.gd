class_name GateItems
extends RefCounted
## node-gates: the items found in chests, their effects, and their rarity.
##
## - Healing potions restore a share of the walker's hit points, mana potions
##   a share of its mana.
## - Speed potions raise its walking speed by a share for 30 s.
## - Food regenerates a share of its hit points every second for 10 s.
##
## Rarity is the item's weight when a chest rolls its contents (80 is common,
## 5 the rarest), and its tier (1-8) picks the slot frame that shows the
## rarity. Icons come from the most compatible art for Painted Lands maps
## (docs/ui-assets.md):
## - potions: Franuka's Fantasy RPG icon pack, in three bottle sizes (the
##   speed potions are its white flasks in its own greens);
## - fish and fruit: the Painted Lands Farm sheets;
## - nuts, jerky, travel cake, and steak: the Fantasy RPG icon pack;
## - bread, hardtack, and the sweet roll: Cozy Farm's items. No pack in the
##   collection draws a loaf, a biscuit, or a roll, so these are its butter,
##   mozzarella, and goat-cheese icons standing in.

const STACK := 99
const TIER_NAMES := ["", "small", "medium", "large", "uncommon", "wondrous", "rare", "very rare", "legendary"]
const POTION_TIERS := ["small", "medium", "large", "uncommon", "wondrous", "rare", "very_rare", "legendary"]

## Bottles by tier for each potion kind: [sheet, cell index (1-based, 10 per row)].
const BOTTLES := {
	"healing": [["icons", 71], ["icons", 72], ["icons", 73]],
	"mana": [["icons", 74], ["icons", 75], ["icons", 76]],
	"speed": [["colours", 31, "green"], ["colours", 32, "green"], ["colours", 33, "green"]],
}

## Food: [id, name, regen % per second, rarity weight, tier, icon].
const FOODS := [
	["bread", "Bread", 1, 80, 1, ["cozy", Vector2i(2, 3)]],
	["fish", "Fish", 2, 70, 2, ["fish", Vector2i(0, 0)]],
	["fruit", "Fruit", 3, 60, 3, ["crops", Vector2i(9, 12)]],
	["nuts", "Nuts and seeds", 4, 50, 4, ["icons", 102]],
	["jerky", "Jerky", 5, 40, 5, ["colours", 64]],
	["hardtack", "Hardtack", 6, 30, 6, ["cozy", Vector2i(5, 3)]],
	["travel_cake", "Travel cake", 7, 20, 7, ["icons", 104]],
	["sweet_roll", "Sweet roll", 8, 10, 8, ["cozy", Vector2i(4, 3)]],
	["steak", "Well-done steak", 9, 5, 8, ["icons", 103]],
]

static var _items := {}
static var _order: Array[String] = []


## Every item: id -> {id, name, kind (healing, mana, speed, regen), amount
## (a fraction), seconds, weight, tier, icon}.
static func all() -> Dictionary:
	if _items.is_empty():
		_build()
	return _items


static func ids() -> Array[String]:
	all()
	return _order


static func item(id: String) -> Dictionary:
	return all().get(id, {})


static func _build() -> void:
	for kind in ["healing", "mana", "speed"]:
		for t in 8:
			var tier := t + 1
			var bottle: Array = BOTTLES[kind][mini(t, 2)]
			var id := "%s_%s" % [kind, POTION_TIERS[t]]
			_add({"id": id, "name": "%s %s potion" % [TIER_NAMES[tier].capitalize(), kind],
				"kind": kind, "amount": tier * 0.1, "seconds": 30.0 if kind == "speed" else 0.0,
				"weight": 90 - tier * 10, "tier": tier, "icon": bottle})
	for f in FOODS:
		_add({"id": f[0], "name": f[1], "kind": "regen", "amount": f[2] / 100.0, "seconds": 10.0,
			"weight": f[3], "tier": f[4], "icon": f[5]})


static func _add(it: Dictionary) -> void:
	_items[it.id] = it
	_order.append(it.id)


## What the item does, in a line.
static func effect_text(id: String) -> String:
	var it := item(id)
	var pct := roundi(it.amount * 100.0)
	match it.kind:
		"healing":
			return "Restores %d%% of your health" % pct
		"mana":
			return "Restores %d%% of your mana" % pct
		"speed":
			return "+%d%% speed for %d s" % [pct, roundi(it.seconds)]
	return "Regenerates %d%% health a second for %d s" % [pct, roundi(it.seconds)]


## The rarity: the tier's word and the item's chance weight.
static func rarity_text(id: String) -> String:
	var it := item(id)
	var word: String = TIER_NAMES[it.tier] if it.kind != "regen" else ["", "common", "common", "common", "uncommon", "uncommon", "rare", "very rare", "legendary"][it.tier]
	return "Rarity: %s (%d%%)" % [word, it.weight]


## Items for a chest: `count` rolls, each weighted by rarity.
static func roll(count: int, rng: RandomNumberGenerator) -> Array[String]:
	var total := 0
	for id in ids():
		total += item(id).weight
	var out: Array[String] = []
	for i in count:
		var pick := rng.randi_range(1, total)
		for id in ids():
			pick -= item(id).weight
			if pick <= 0:
				out.append(id)
				break
	return out
