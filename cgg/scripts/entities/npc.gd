extends StaticBody2D
class_name NPC
## Interactive NPC with physical collision, facing direction, speech animations,
## and multi-stage dialogue support driven by story flags.

signal dialogue_started(npc_name: String)
signal dialogue_completed(npc_name: String)

@export var npc_name: String = "Villager"
@export var prompt_text: String = "E - Talk"
@export var dialogue_lines: Array[String] = []
@export var dialogue_lines_alt: Array[String] = []
@export var required_flag: String = ""
@export var grant_flag: String = ""
@export var grant_item: String = ""

@onready var sprite: Node2D = $Sprite2D if has_node("Sprite2D") else $AnimatedSprite2D
@onready var interact_area: Area2D = $InteractArea

var _base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group("npc")
	collision_layer = 1
	collision_mask = 0
	if sprite != null:
		_base_scale = sprite.scale
		# If it's an AnimatedSprite2D, play its default animation
		if sprite is AnimatedSprite2D and (sprite as AnimatedSprite2D).sprite_frames != null:
			var anim_names := (sprite as AnimatedSprite2D).sprite_frames.get_animation_names()
			if not anim_names.is_empty():
				(sprite as AnimatedSprite2D).play(anim_names[0])
	
	if interact_area != null:
		interact_area.collision_layer = 64  # Layer 7: interactable
		interact_area.collision_mask = 0


func interact(player: Node) -> void:
	if UI.dialogue_open:
		return

	# Face towards player
	if sprite != null and player is Node2D:
		var dir_x: float = (player as Node2D).global_position.x - global_position.x
		if "flip_h" in sprite:
			sprite.flip_h = dir_x < 0.0
		# Little speech bounce
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(_base_scale.x * 0.9, _base_scale.y * 1.15), 0.1)
		tw.tween_property(sprite, "scale", _base_scale, 0.15)

	# Determine dialogue stage based on story flags
	var lines: Array[String] = dialogue_lines
	if not required_flag.is_empty() and GameState.has_flag(required_flag) and not dialogue_lines_alt.is_empty():
		lines = dialogue_lines_alt

	if lines.is_empty():
		return

	dialogue_started.emit(npc_name)
	UI.start_dialogue(lines, npc_name)

	# Connect one-shot completion handler to grant flag
	var callback: Callable
	callback = func(spk: String) -> void:
		if spk == npc_name:
			UI.dialogue_finished.disconnect(callback)
			if not grant_flag.is_empty():
				GameState.set_flag(grant_flag, true)
			if not grant_item.is_empty() and not GameState.has_item(grant_item):
				GameState.add_item(grant_item)
				var info: Dictionary = GameState.get_item_info(grant_item)
				UI.show_toast("📦 Acquired: %s (%s) - Added to Bag [B]" % [str(info.get("name", grant_item)), str(info.get("icon", "🔥"))])
			dialogue_completed.emit(npc_name)
	
	UI.dialogue_finished.connect(callback)
