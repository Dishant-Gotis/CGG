extends Node
## Persistent game state (spec §10). One autoload owns everything that must
## survive scene changes. Never store transient animation/hitbox state here.

signal flag_changed(flag: String, value: bool)
signal health_changed(hp: int, max_hp: int)
signal inventory_changed
signal hotbar_changed(active_index: int)

const SAVE_VERSION := 1
const SAVE_PATH := "user://save_v1.json"

const ITEMS: Dictionary = {
	"sword": {
		"id": "sword",
		"name": "Hero's Blade",
		"desc": "A gleaming celestial steel sword summoned with you from the saffron book. Press Q to swing.",
		"type": "Weapon",
		"icon": "⚔️"
	},
	"cave_torch": {
		"id": "cave_torch",
		"name": "Cave Torch",
		"desc": "Burns with an eternal amber flame. Illuminates dark crystal caverns and lets you explore deep caves.",
		"type": "Tool",
		"icon": "🔥"
	},
	"elixir_shard": {
		"id": "elixir_shard",
		"name": "Piece of Elixir",
		"desc": "A radiant crystal shard pulsing with ancient life energy. One of the lost fragments needed to restore the world.",
		"type": "Relic",
		"icon": "💎"
	},
	"forest_mushroom": {
		"id": "forest_mushroom",
		"name": "Glow Mushroom",
		"desc": "Luminescent blue mushroom gathered from the forest. Restores 1 full heart of health.",
		"type": "Consumable",
		"icon": "🍄"
	}
}

## Combat tuning — loaded from data/combat.json, fallback values below are the
## single place for defaults (spec §9: no scattered constants).
const COMBAT_DEFAULTS: Dictionary = {
	"player_speed": 250.0,
	"player_max_health": 10,
	"attack_damage": 1,
	"attack_cooldown": 0.45,
	"attack_window": 0.18,
	"attack_reach": 46.0,
	"invuln_time": 1.0,
	"enemy_speed": 95.0,
	"enemy_hp": 3,
	"enemy_damage": 1,
	"enemy_detection": 300.0,
	"enemy_stop_distance": 42.0,
	"slime_speed": 70.0,
	"slime_hp": 2,
	"knockback": 260.0,
	"practice_target_hp": 3,
}

var combat: Dictionary = {}

var flags: Dictionary = {}
var health: int = 3
var max_health: int = 3
var current_region: String = ""
var pending_spawn: String = ""
var pending_player_position: Variant = null  # Vector2 or null
var inventory: Array[String] = ["sword"]
var hotbar: Array[String] = ["sword", "", "", "", ""]
var active_hotbar_index: int = 0


func _ready() -> void:
	combat = COMBAT_DEFAULTS.duplicate()
	var loaded: Variant = Assets.load_json(Assets.COMBAT_JSON)
	if loaded is Dictionary:
		for key: String in COMBAT_DEFAULTS:
			if (loaded as Dictionary).has(key):
				combat[key] = (loaded as Dictionary)[key]
	max_health = int(combat["player_max_health"])
	health = max_health
	print("[CHECK] GameState ready, combat keys=", combat.size())


func set_flag(flag: String, value: bool = true) -> void:
	if flags.get(flag, false) == value:
		return
	flags[flag] = value
	flag_changed.emit(flag, value)


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)
	health_changed.emit(health, max_health)


func new_game() -> void:
	flags = {}
	inventory = []
	max_health = int(combat["player_max_health"])
	health = max_health
	current_region = ""
	pending_spawn = ""
	pending_player_position = null
	health_changed.emit(health, max_health)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func save_game(position: Vector2) -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"currentRegion": current_region,
		"playerPosition": [position.x, position.y],
		"health": health,
		"inventory": inventory,
		"questFlags": flags,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[GameState] cannot write save: ", SAVE_PATH)
		return
	f.store_string(JSON.stringify(data, "\t"))


## Validates before loading; returns false (leaving state untouched) on any
## malformed/unknown-version data (spec §9).
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var parsed: Variant = Assets.load_json(SAVE_PATH)
	if not (parsed is Dictionary):
		push_warning("[GameState] save invalid, ignoring")
		return false
	var data := parsed as Dictionary
	if int(data.get("version", -1)) != SAVE_VERSION:
		push_warning("[GameState] save version mismatch, ignoring")
		return false
	var pos: Variant = data.get("playerPosition")
	if not (pos is Array) or (pos as Array).size() != 2:
		push_warning("[GameState] save position invalid, ignoring")
		return false
	flags = {}
	var qf: Variant = data.get("questFlags")
	if qf is Dictionary:
		for key: Variant in (qf as Dictionary):
			flags[str(key)] = bool((qf as Dictionary)[key])
	inventory = []
	var inv: Variant = data.get("inventory")
	if inv is Array:
		for item: Variant in (inv as Array):
			inventory.append(str(item))
	current_region = str(data.get("currentRegion", ""))
	max_health = int(combat["player_max_health"])
	health = clampi(int(data.get("health", max_health)), 1, max_health)
	pending_player_position = Vector2(float(pos[0]), float(pos[1]))
	health_changed.emit(health, max_health)
	return true


func add_item(item_id: String) -> bool:
	if not ITEMS.has(item_id):
		push_warning("[GameState] Unknown item_id: ", item_id)
		return false
	if not inventory.has(item_id):
		inventory.append(item_id)
	# Also place in first available hotbar slot if not already in hotbar
	if not hotbar.has(item_id):
		for i: int in range(hotbar.size()):
			if hotbar[i] == "":
				hotbar[i] = item_id
				break
	inventory_changed.emit()
	hotbar_changed.emit(active_hotbar_index)
	return true


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func remove_item(item_id: String) -> bool:
	var idx := inventory.find(item_id)
	if idx == -1:
		return false
	inventory.remove_at(idx)
	for i: int in range(hotbar.size()):
		if hotbar[i] == item_id:
			hotbar[i] = ""
	inventory_changed.emit()
	hotbar_changed.emit(active_hotbar_index)
	return true


func select_hotbar_slot(idx: int) -> void:
	if idx < 0 or idx >= hotbar.size():
		return
	active_hotbar_index = idx
	hotbar_changed.emit(active_hotbar_index)


func get_active_item() -> String:
	if active_hotbar_index >= 0 and active_hotbar_index < hotbar.size():
		return hotbar[active_hotbar_index]
	return ""


func get_item_info(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})
