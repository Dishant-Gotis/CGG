extends StaticBody2D
## Dynamic Medieval Building (Houses, Castle, Towers with Archer)

enum BuildingType {
	HOUSE_1,
	HOUSE_2,
	HOUSE_3,
	CASTLE,
	TOWER,
	MONASTERY,
	ARCHERY,
	BARRACKS
}

@export var building_type: BuildingType = BuildingType.HOUSE_1
@export var has_tower_archer: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var col: CollisionShape2D = $CollisionShape2D
@onready var tower_archer: AnimatedSprite2D = $TowerArcher

func _ready() -> void:
	var path: String = ""
	var col_size: Vector2 = Vector2(80, 50)
	var col_offset_y: float = -25.0
	var sprite_offset_y: float = -96.0

	match building_type:
		BuildingType.HOUSE_1:
			path = Assets.BUILDING_HOUSE_1
			col_size = Vector2(88, 54)
			col_offset_y = -27.0
			sprite_offset_y = -96.0
		BuildingType.HOUSE_2:
			path = Assets.BUILDING_HOUSE_2
			col_size = Vector2(88, 54)
			col_offset_y = -27.0
			sprite_offset_y = -96.0
		BuildingType.HOUSE_3:
			path = Assets.BUILDING_HOUSE_3
			col_size = Vector2(88, 54)
			col_offset_y = -27.0
			sprite_offset_y = -96.0
		BuildingType.CASTLE:
			path = Assets.BUILDING_CASTLE
			col_size = Vector2(240, 80)
			col_offset_y = -40.0
			sprite_offset_y = -128.0
		BuildingType.TOWER:
			path = Assets.BUILDING_TOWER
			col_size = Vector2(72, 54)
			col_offset_y = -27.0
			sprite_offset_y = -128.0
		BuildingType.MONASTERY:
			path = Assets.BUILDING_MONASTERY
			col_size = Vector2(180, 80)
			col_offset_y = -40.0
			sprite_offset_y = -160.0
		BuildingType.ARCHERY:
			path = Assets.BUILDING_ARCHERY
			col_size = Vector2(130, 60)
			col_offset_y = -30.0
			sprite_offset_y = -128.0
		BuildingType.BARRACKS:
			path = Assets.BUILDING_BARRACKS
			col_size = Vector2(130, 60)
			col_offset_y = -30.0
			sprite_offset_y = -128.0

	sprite.texture = Assets.tex(path)
	sprite.position = Vector2(0, sprite_offset_y)

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = col_size
	col.shape = rect_shape
	col.position = Vector2(0, col_offset_y)

	# Optional Archer on top of watchtower
	if building_type == BuildingType.TOWER and has_tower_archer and tower_archer != null:
		var archer_sf := Assets.sprite_frames(Assets.ARCHER_BLUE_IDLE, 192, 192, 6, 5.0)
		if archer_sf != null:
			tower_archer.sprite_frames = archer_sf
			tower_archer.position = Vector2(0, -188)
			tower_archer.speed_scale = randf_range(0.9, 1.1)
			tower_archer.play("default")
			tower_archer.visible = true
	else:
		if tower_archer != null:
			tower_archer.visible = false
