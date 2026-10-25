extends Area2D
## Cave Exit Portal: teleports the player back to the overworld surface.

var prompt_text: String = "Return to Surface"


func _ready() -> void:
	collision_layer = 64
	collision_mask = 0


func interact(_player: Node) -> void:
	if UI.dialogue_open:
		return

	UI.start_dialogue([
		"You step onto the carved stone stairway, ascending from the glowing crystal depths...",
		"Daylight filters down from the surface as you emerge into the open air."
	], "Cave Stairs")

	var callback: Callable
	callback = func(spk: String) -> void:
		if spk == "Cave Stairs":
			UI.dialogue_finished.disconnect(callback)
			SceneManager.change_scene("res://scenes/world.tscn", "cave_exit")

	UI.dialogue_finished.connect(callback)
