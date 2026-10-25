extends StaticBody2D
## Overworld Cave Entrance: checks if player has Cave Torch,
## updates entrance visuals (cave_dark vs cave_light), and teleports to cave.tscn.

const TEX_DARK := preload("res://Tiny Swords (Update 010)/everything/cave_dark.png")
const TEX_LIGHT := preload("res://Tiny Swords (Update 010)/everything/cave_light.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null

var prompt_text: String = "Inspect Dark Cave"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_update_visuals()
	GameState.inventory_changed.connect(_update_visuals)


func _update_visuals() -> void:
	var has_torch := GameState.has_item("cave_torch")
	if sprite != null:
		sprite.texture = TEX_LIGHT if has_torch else TEX_DARK
	if light != null:
		light.visible = has_torch
	prompt_text = "Enter Mystic Cavern" if has_torch else "Inspect Dark Cave"


func interact(_player: Node) -> void:
	if UI.dialogue_open:
		return

	if not GameState.has_item("cave_torch"):
		UI.start_dialogue([
			"Mystic Cavern Entrance:",
			"The descent into the cavern is pitch-black, frigid, and perilous.",
			"Razor-sharp crystal chasms plunge into bottomless darkness. You cannot navigate without a continuous source of light.",
			"Defeat the slimes on the high road and speak with Elder Oakhaven in Mossveil Village to receive the Cave Torch!"
		], "Cave Entrance")
		return

	# Player has the Cave Torch!
	UI.start_dialogue([
		"You hold the burning Cave Torch aloft.",
		"Its warm amber flame illuminates the ancient stone steps spiraling deep into the earth.",
		"Stepping forward, you descend into the Glowing Crystal Cavern..."
	], "Cave Entrance")

	var callback: Callable
	callback = func(spk: String) -> void:
		if spk == "Cave Entrance":
			UI.dialogue_finished.disconnect(callback)
			SceneManager.change_scene("res://scenes/cave.tscn", "entrance")

	UI.dialogue_finished.connect(callback)
