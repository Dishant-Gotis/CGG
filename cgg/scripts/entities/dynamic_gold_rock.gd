extends StaticBody2D
## Dynamic Gold Resource Stone with animated glint

@onready var base_sprite: Sprite2D = $Sprite2D
@onready var glint_anim: AnimatedSprite2D = $GlintAnim
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	base_sprite.texture = Assets.tex(Assets.GOLD_STONE_1)
	base_sprite.position = Vector2(0, -32)

	var sf := Assets.sprite_frames(Assets.GOLD_STONE_1_HL, 128, 128, 6, 6.0)
	if sf != null:
		glint_anim.sprite_frames = sf
		glint_anim.position = Vector2(0, -32)
		glint_anim.speed_scale = randf_range(0.85, 1.15)
		glint_anim.play("default")

	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 24)
	col.shape = shape
	col.position = Vector2(0, -12)

