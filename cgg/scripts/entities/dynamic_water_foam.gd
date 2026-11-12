extends AnimatedSprite2D
## Dynamic Animated Water Foam (rolling coastal waves)

func _ready() -> void:
	z_index = -8
	var sf := Assets.sprite_frames(Assets.WATER_FOAM, 192, 192, 16, 9.0)
	if sf != null:
		sprite_frames = sf
		speed_scale = randf_range(0.9, 1.1)
		frame = randi() % 16
		play("default")
