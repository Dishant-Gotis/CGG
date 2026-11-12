extends StaticBody2D
## Dynamic Animated Bush (rustling foliage)

@export_range(1, 4) var bush_type: int = 1

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var path: String = Assets.BUSH_NEW_1
	match bush_type:
		1: path = Assets.BUSH_NEW_1
		2: path = Assets.BUSH_NEW_2
		3: path = Assets.BUSH_NEW_3
		4: path = Assets.BUSH_NEW_4

	var sf := Assets.sprite_frames(path, 128, 128, 8, 5.0)
	if sf != null:
		anim.sprite_frames = sf
		anim.speed_scale = randf_range(0.85, 1.15)
		anim.frame = randi() % 8
		anim.play("default")

	anim.position = Vector2(0, -24)

	if col != null:
		var circle := CircleShape2D.new()
		circle.radius = 16.0
		col.shape = circle
		col.position = Vector2(0, -6)

