extends StaticBody2D
## Dynamic Animated Water Rock (splashing water waves around rocks in the sea)

@export_range(1, 4) var rock_type: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	z_index = -7
	var path: String = Assets.WATER_ROCK_1
	match rock_type:
		1: path = Assets.WATER_ROCK_1
		2: path = Assets.WATER_ROCK_2
		3: path = Assets.WATER_ROCK_3
		4: path = Assets.WATER_ROCK_4

	var sf := Assets.sprite_frames(path, 64, 64, 16, 8.0)
	if sf != null:
		anim.sprite_frames = sf
		anim.speed_scale = randf_range(0.85, 1.15)
		anim.frame = randi() % 16
		anim.play("default")

	if col != null:
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		col.shape = circle
		col.position = Vector2(0, 0)

