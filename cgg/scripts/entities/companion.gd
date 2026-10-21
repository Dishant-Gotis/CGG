extends CharacterBody2D
## Companion pet that follows the player around the world. Uses a position
## history queue (bread-crumb trail) so the companion walks WHERE the player
## already walked instead of cutting corners or clipping through walls.

@export var follow_speed: float = 260.0
@export var min_distance: float = 50.0   ## Stops following if closer than this
@export var max_distance: float = 500.0  ## Teleport if farther than this
@export var trail_delay: int = 12        ## Number of frames to lag behind player

var _player: Node2D
var _trail: Array[Vector2] = []
var _target: Vector2 = Vector2.ZERO
var facing: String = "down"
var facing_left: bool = false
var _is_moving: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("companion")
	collision_layer = 0    # Ghost – no physics collision with world
	collision_mask = 0
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player != null:
		global_position = _player.global_position + Vector2(40, 20)
		_target = global_position
		# Pre-fill trail so the companion doesn't warp on first frames
		for i in range(trail_delay + 5):
			_trail.append(_player.global_position)
	_play_idle()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return

	# Record player position each physics frame
	_trail.append(_player.global_position)
	# Keep trail bounded
	while _trail.size() > trail_delay + 60:
		_trail.pop_front()

	# Target is where the player was N frames ago
	var trail_idx: int = maxi(0, _trail.size() - 1 - trail_delay)
	_target = _trail[trail_idx]

	var dist: float = global_position.distance_to(_target)

	# Teleport if too far (scene transitions / respawn)
	if dist > max_distance:
		global_position = _target
		velocity = Vector2.ZERO
		_is_moving = false
		_play_idle()
		return

	# Pause during dialogue
	if UI.dialogue_open:
		velocity = Vector2.ZERO
		_is_moving = false
		_play_idle()
		move_and_slide()
		return

	if dist > min_distance:
		var dir: Vector2 = ((_target - global_position).normalized())
		# Speed up slightly when far, slow down when close
		var speed_mult: float = clampf(remap(dist, min_distance, 250.0, 0.5, 1.3), 0.5, 1.3)
		velocity = dir * follow_speed * speed_mult
		_update_facing(dir)
		if not _is_moving:
			_is_moving = true
			_play_walk()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 600.0 * delta)
		if _is_moving and velocity.length() < 10.0:
			_is_moving = false
			velocity = Vector2.ZERO
			_play_idle()

	move_and_slide()


func _update_facing(dir: Vector2) -> void:
	var prev_facing := facing
	var prev_left := facing_left
	if absf(dir.x) > absf(dir.y):
		facing = "side"
		facing_left = dir.x < 0.0
	elif dir.y > 0.0:
		facing = "down"
	else:
		facing = "up"
	if facing != prev_facing or facing_left != prev_left:
		_play_walk()


func _play_idle() -> void:
	if anim == null:
		return
	match facing:
		"up":
			anim.play("idle_back")
		"side":
			anim.play("idle_side")
			anim.flip_h = facing_left
		_:
			anim.play("idle_front")


func _play_walk() -> void:
	if anim == null:
		return
	match facing:
		"up":
			if anim.sprite_frames.has_animation("walk_back"):
				anim.play("walk_back")
			else:
				anim.play("idle_back")
		"side":
			anim.play("walk_side")
			anim.flip_h = facing_left
		_:
			if anim.sprite_frames.has_animation("walk_front"):
				anim.play("walk_front")
			else:
				anim.play("idle_front")
