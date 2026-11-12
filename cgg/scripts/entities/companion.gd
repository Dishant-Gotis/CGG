extends CharacterBody2D
## Companion pet that follows the player around the world. Uses a position
## history queue (bread-crumb trail) so the companion walks WHERE the player
## already walked instead of cutting corners or clipping through walls.
## Enforces polite personal space so Kitsu NEVER overlaps or walks over Snowy.

@export var follow_speed: float = 260.0
@export var min_distance: float = 70.0    ## Stops following if closer than this
@export var retreat_distance: float = 58.0  ## Backs up if player walks towards companion
@export var min_separation: float = 52.0   ## Absolute minimum clearance to player
@export var max_distance: float = 500.0   ## Teleport if farther than this
@export var trail_delay: int = 15         ## Number of frames to lag behind player

var _player: Node2D
var _trail: Array[Vector2] = []
var _target: Vector2 = Vector2.ZERO
var facing: String = "down"
var facing_left: bool = false
var _is_moving: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("companion")
	collision_layer = 0    # Ghost – does not physically block player movement
	collision_mask = 1     # Collide with world obstacles / trees / fences
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player != null:
		global_position = _player.global_position + Vector2(48, 24)
		_target = global_position
		for i in range(trail_delay + 5):
			_trail.append(_player.global_position)
	_play_idle()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		if _player == null:
			return

	var p_pos := _player.global_position
	var to_companion := global_position - p_pos
	var dist_to_player := to_companion.length()

	# Pause during dialogue, but maintain safe clearance
	if UI.dialogue_open:
		velocity = Vector2.ZERO
		_is_moving = false
		_play_idle()
		_enforce_separation(p_pos, to_companion)
		move_and_slide()
		return

	# Teleport if too far (e.g. scene transition or warp)
	if dist_to_player > max_distance:
		var spawn_offset := Vector2(48, 24)
		if "facing" in _player:
			match str(_player.get("facing")):
				"down": spawn_offset = Vector2(36, -48)
				"up": spawn_offset = Vector2(36, 48)
				"left": spawn_offset = Vector2(48, 0)
				"right": spawn_offset = Vector2(-48, 0)
		global_position = p_pos + spawn_offset
		_trail.clear()
		for i in range(trail_delay + 5):
			_trail.append(global_position)
		velocity = Vector2.ZERO
		_is_moving = false
		_play_idle()
		return

	# 1. Active Personal Space / Retreat:
	# If Snowy approaches Kitsu, Kitsu yields and steps away politely so they never overlap.
	if dist_to_player < retreat_distance:
		var away_dir := to_companion.normalized()
		if to_companion.is_zero_approx():
			away_dir = Vector2(0, 1)
		var push_factor := clampf(remap(dist_to_player, 0.0, retreat_distance, 1.4, 0.6), 0.6, 1.4)
		velocity = away_dir * (follow_speed * push_factor)
		_update_facing(away_dir)
		if not _is_moving:
			_is_moving = true
			_play_walk()
		move_and_slide()
		_enforce_separation(p_pos, to_companion)
		return

	# Record breadcrumb trail
	_trail.append(p_pos)
	while _trail.size() > trail_delay + 60:
		_trail.pop_front()

	var trail_idx: int = maxi(0, _trail.size() - 1 - trail_delay)
	_target = _trail[trail_idx]

	var dist_to_target := global_position.distance_to(_target)

	# 2. Normal following along breadcrumb trail
	if dist_to_player > min_distance and dist_to_target > 16.0:
		var dir := (_target - global_position).normalized()
		var speed_mult := clampf(remap(dist_to_player, min_distance, 250.0, 0.6, 1.3), 0.6, 1.3)
		velocity = dir * follow_speed * speed_mult
		_update_facing(dir)
		if not _is_moving:
			_is_moving = true
			_play_walk()
	else:
		# Rapid deceleration to avoid sliding into player
		velocity = velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
		if _is_moving and velocity.length() < 10.0:
			_is_moving = false
			velocity = Vector2.ZERO
			_play_idle()

	move_and_slide()
	_enforce_separation(p_pos, to_companion)


func _enforce_separation(p_pos: Vector2, to_companion: Vector2) -> void:
	# Absolute mathematical guarantee: Kitsu is NEVER inside Snowy's personal radius
	var final_dist := global_position.distance_to(p_pos)
	if final_dist < min_separation:
		var away := to_companion.normalized()
		if away.is_zero_approx():
			away = Vector2(0, 1)
		global_position = p_pos + away * min_separation


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
