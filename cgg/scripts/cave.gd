extends Node2D
## Glowing Crystal Cavern controller (spec §9):
## Dark moody ambient light, camera limits matching map dimensions,
## exit back to surface, and crystal cavern ambiance.

@onready var player: CharacterBody2D = $Player if has_node("Player") else null
var _cave_lights: Array[PointLight2D] = []


func _ready() -> void:
	# Configure player camera to map bounds
	if player != null and player.has_node("Camera2D"):
		var cam: Camera2D = player.get_node("Camera2D") as Camera2D
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 1672
		cam.limit_bottom = 940

	# Gather crystal and ambient lights for atmospheric glow
	for child: Node in get_children():
		if child is PointLight2D:
			_cave_lights.append(child as PointLight2D)

	if player != null and player.has_method("_update_torch_light"):
		player._update_torch_light()

	print("[CHECK] Glowing Crystal Cavern ready with ", _cave_lights.size(), " radiant light sources")


func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.003
	for i: int in range(_cave_lights.size()):
		var lt: PointLight2D = _cave_lights[i]
		if lt != null:
			lt.energy = 1.35 + 0.22 * sin(t + i * 1.3)

