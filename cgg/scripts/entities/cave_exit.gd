extends Area2D
## Cave Exit Portal: teleports the player back to the overworld surface.

var prompt_text: String = "Leave Cave (Return to Surface)"


func _ready() -> void:
	collision_layer = 64  # Layer 7: interactable
	collision_mask = 2   # Player body layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		UI.show_prompt("[E / Space / Click] Leave Cave (Return to Surface)")


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and not UI.dialogue_open:
		UI.hide_prompt()


var _last_interact_ms: int = 0


func interact(_player: Node) -> void:
	if UI.dialogue_open or (Time.get_ticks_msec() - _last_interact_ms < 600) or (Time.get_ticks_msec() - UI.dialogue_closed_at_ms < 400):
		return
	_last_interact_ms = Time.get_ticks_msec()

	UI.hide_prompt()
	UI.start_dialogue([
		"The carved stone stairway spirals upward toward the forest surface.",
		"You ascend the steps, emerging from the dark crystal depths into the open air..."
	], "Leave Cave")

	var callback: Callable
	callback = func(spk: String) -> void:
		if spk == "Leave Cave":
			UI.dialogue_finished.disconnect(callback)
			SceneManager.change_scene("res://scenes/world.tscn", "cave_exit")

	UI.dialogue_finished.connect(callback)
