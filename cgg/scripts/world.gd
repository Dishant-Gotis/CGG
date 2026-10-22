extends Node2D

func _ready() -> void:
	AudioManager.play_music()
	print("[CHECK] World scene loaded, BGM playing")
