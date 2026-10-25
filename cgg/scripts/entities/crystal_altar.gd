extends StaticBody2D
## Crystal Altar containing the sacred Piece of Elixir (spec §9 story quest).

@onready var light: PointLight2D = $PointLight2D if has_node("PointLight2D") else null
@onready var relic_sprite: Label = $RelicGlow if has_node("RelicGlow") else null

var prompt_text: String = "Claim Piece of Elixir"


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_update_state()
	GameState.inventory_changed.connect(_update_state)


func _update_state() -> void:
	var claimed := GameState.has_item("elixir_shard")
	prompt_text = "Inspect Crystal Altar" if claimed else "Claim Piece of Elixir"
	if relic_sprite != null:
		relic_sprite.visible = not claimed
	if light != null:
		light.energy = 0.8 if claimed else 1.8


func _physics_process(_delta: float) -> void:
	if light != null:
		var claimed := GameState.has_item("elixir_shard")
		var base_e: float = 0.8 if claimed else 1.8
		light.energy = base_e + 0.2 * sin(Time.get_ticks_msec() * 0.005)
	if relic_sprite != null and relic_sprite.visible:
		relic_sprite.position.y = -42.0 + 4.0 * sin(Time.get_ticks_msec() * 0.004)


func interact(_player: Node) -> void:
	if UI.dialogue_open:
		return

	if not GameState.has_item("elixir_shard"):
		GameState.add_item("elixir_shard")
		GameState.set_flag("has_elixir_shard", true)
		UI.show_toast("✨ Acquired: Piece of Elixir (💎) - Added to Bag [B]")
		AudioManager.play_select()
		UI.start_dialogue([
			"Ancient Crystal Altar:",
			"You reach toward the radiant crystal shard levitating above the carved altar.",
			"As your fingers touch its crystal facets, a brilliant azure pulse resonates through the cavern and into your soul.",
			"A warm echo of your father's voice reaches your ears: 'Arjun... believe in the light. Take this piece of the Elixir and restore our homeland.'",
			"You place the Sacred Piece of Elixir safely into your satchel [B] and tool hotbar!"
		], "Crystal Altar")
	else:
		UI.start_dialogue([
			"Ancient Crystal Altar:",
			"The carved stone altar hums with peaceful ancient magic.",
			"The Piece of Elixir is already safely resting in your satchel."
		], "Crystal Altar")
