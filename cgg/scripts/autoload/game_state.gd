extends Node
## Persistent game state (spec §10). One autoload owns everything that must
## survive scene changes. Never store transient animation/hitbox state here.

signal flag_changed(flag: String, value: bool)
signal health_changed(hp: int, max_hp: int)

const SAVE_VERSION := 1
const SAVE_PATH := "user://save_v1.json"

## Combat tuning — loaded from data/combat.json, fallback values below are the
## single place for defaults (spec §9: no scattered constants).
const COMBAT_DEFAULTS: Dictionary = {
	"player_speed": 250.0,
	"player_max_health": 3,
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
var inventory: Array[String] = []


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
