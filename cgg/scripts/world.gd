extends Node2D

func _ready() -> void:
	UI.set_hud_visible(true)
	AudioManager.play_music()
	print("[CHECK] World scene loaded, BGM playing")
