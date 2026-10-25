extends Node2D
## Glowing Crystal Cavern controller (spec §9):
## Dark moody ambient light, camera limits matching map dimensions,
## exit back to surface, and crystal cavern ambiance.

@onready var player: CharacterBody2D = $Player if has_node("Player") else null


func _ready() -> void:
	# Configure player camera to map bounds
	if player != null and player.has_node("Camera2D"):
		var cam: Camera2D = player.get_node("Camera2D") as Camera2D
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 1672
		cam.limit_bottom = 940

	print("[CHECK] Glowing Crystal Cavern ready, bounds=(0,0,1672,940)")
