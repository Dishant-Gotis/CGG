extends Sprite2D
## Dynamic Soft Cloud drifting across the sky

@export_range(1, 3) var cloud_type: int = 1
@export var speed: float = 12.0
@export var map_width: float = 4096.0

func _ready() -> void:
	z_index = 20 # Render high above gameplay layer
	modulate = Color(1.0, 1.0, 1.0, randf_range(0.40, 0.65))
	match cloud_type:
		1: texture = Assets.tex(Assets.CLOUD_1)
		2: texture = Assets.tex(Assets.CLOUD_2)
		3: texture = Assets.tex(Assets.CLOUD_3)
	speed = randf_range(8.0, 16.0)

func _process(delta: float) -> void:
	position.x += speed * delta
	if position.x > map_width + 200.0:
		position.x = -200.0

