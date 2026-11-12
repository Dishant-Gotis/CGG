extends StaticBody2D
## Authentic Tree from Game Assets(NEW) (Tree1, Tree2, Tree3, Tree4)
## Static pixel-art tree with trunk collision (no animation FPS).

@export_range(1, 4) var tree_type: int = 1

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var col: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	var path: String = ""
	var frame_w: int = 192
	var frame_h: int = 256
	var col_radius: float = 16.0
	var col_offset_y: float = -8.0

	match tree_type:
		1:
			path = Assets.TREE_1
			frame_w = 192
			frame_h = 256
			col_radius = 16.0
			col_offset_y = -8.0
		2:
			path = Assets.TREE_2
			frame_w = 192
			frame_h = 256
			col_radius = 16.0
			col_offset_y = -8.0
		3:
			path = Assets.TREE_3
			frame_w = 192
			frame_h = 192
			col_radius = 14.0
			col_offset_y = -6.0
		4:
			path = Assets.TREE_4
			frame_w = 192
			frame_h = 192
			col_radius = 14.0
			col_offset_y = -6.0

	var texture := Assets.tex(path)
	if texture != null:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(0, 0, frame_w, frame_h)
		if sprite != null:
			sprite.texture = atlas
			sprite.position = Vector2(0, -frame_h * 0.42)
		elif anim_sprite != null:
			anim_sprite.queue_free()
			var s := Sprite2D.new()
			s.name = "Sprite2D"
			s.texture = atlas
			s.position = Vector2(0, -frame_h * 0.42)
			add_child(s)

	if col != null:
		var circle := CircleShape2D.new()
		circle.radius = col_radius
		col.shape = circle
		col.position = Vector2(0, col_offset_y)
