extends StaticBody2D
## Authentic Tree from Game Assets(NEW) (Tree1, Tree2, Tree3, Tree4)
## Static pixel-art tree with pixel-accurate root grounding and trunk collision.

@export_range(1, 4) var tree_type: int = 1

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var path: String = ""
	var frame_w: int = 192
	var frame_h: int = 256
	var base_y: float = 241.0
	var col_w: float = 44.0
	var col_h: float = 22.0

	match tree_type:
		1:
			path = Assets.TREE_1
			frame_w = 192
			frame_h = 256
			base_y = 241.0
			col_w = 44.0
			col_h = 22.0
		2:
			path = Assets.TREE_2
			frame_w = 192
			frame_h = 256
			base_y = 249.0
			col_w = 40.0
			col_h = 22.0
		3:
			path = Assets.TREE_3
			frame_w = 192
			frame_h = 192
			base_y = 170.0
			col_w = 34.0
			col_h = 20.0
		4:
			path = Assets.TREE_4
			frame_w = 192
			frame_h = 192
			base_y = 168.0
			col_w = 32.0
			col_h = 20.0

	var texture := Assets.tex(path)
	if texture != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0, 0, frame_w, frame_h)
		# Exact alignment so the bottom roots touch ground at local y = 0.0
		var spr_offset_y: float = frame_h * 0.5 - base_y
		if sprite != null:
			sprite.texture = atlas
			sprite.position = Vector2(0, spr_offset_y)
		elif anim_sprite != null:
			anim_sprite.queue_free()
			var s := Sprite2D.new()
			s.name = "Sprite2D"
			s.texture = atlas
			s.position = Vector2(0, spr_offset_y)
			add_child(s)

	if col != null:
		var cap := CapsuleShape2D.new()
		cap.radius = col_h * 0.5
		cap.height = col_w
		col.shape = cap
		col.rotation = PI * 0.5
		col.position = Vector2(0, -col_h * 0.5)
