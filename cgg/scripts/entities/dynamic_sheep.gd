extends CharacterBody2D
## Dynamic Animated Sheep (village pasture livestock)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var col: CollisionShape2D = $CollisionShape2D

var _home_pos: Vector2
var _wander_radius: float = 80.0
var _timer: float = 0.0
var _state: String = "grass" # "grass", "idle", "move"
var _move_dir: Vector2 = Vector2.ZERO
var _move_speed: float = 24.0

func _ready() -> void:
	_home_pos = global_position
	var sf := SpriteFrames.new()
	_add_anim_to_sf(sf, "idle", Assets.SHEEP_IDLE, 128, 128, 6, 4.0)
	_add_anim_to_sf(sf, "grass", Assets.SHEEP_GRASS, 128, 128, 12, 5.0)
	_add_anim_to_sf(sf, "move", Assets.SHEEP_MOVE, 128, 128, 4, 6.0)

	anim.sprite_frames = sf
	_pick_new_state()

	if col != null:
		var circle := CircleShape2D.new()
		circle.radius = 12.0
		col.shape = circle
		col.position = Vector2(0, -6)

func _add_anim_to_sf(sf: SpriteFrames, anim_name: String, path: String, fw: int, fh: int, count: int, fps: float) -> void:
	var tex := Assets.tex(path)
	if tex == null:
		return
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, true)
	for i: int in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * fw, 0, fw, fh)
		sf.add_frame(anim_name, atlas)

func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_pick_new_state()

	if _state == "move":
		velocity = _move_dir * _move_speed
		move_and_slide()
		if velocity.x != 0.0:
			anim.flip_h = velocity.x < 0.0
	else:
		velocity = Vector2.ZERO

func _pick_new_state() -> void:
	var roll := randf()
	if roll < 0.55:
		_state = "grass"
		_timer = randf_range(4.0, 8.0)
		anim.play("grass")
	elif roll < 0.80:
		_state = "idle"
		_timer = randf_range(2.5, 5.0)
		anim.play("idle")
	else:
		_state = "move"
		_timer = randf_range(1.5, 3.0)
		# Wander towards a random point near home
		var target := _home_pos + Vector2(randf_range(-_wander_radius, _wander_radius), randf_range(-_wander_radius, _wander_radius))
		_move_dir = (target - global_position).normalized()
		anim.play("move")

