
extends CharacterBody2D

@export var speed: float = 500.0
@export var detection_range: float = 600.0
@export var stop_distance: float = 100.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D = null


func _ready() -> void:
	add_to_group("enemy")
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D


func _physics_process(_delta: float) -> void:
	# Find the player if not found yet.
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		velocity = Vector2.ZERO
		return

	# Calculate distance between enemy and player.
	var distance: float = global_position.distance_to(
		player.global_position
	)

	# Stop when outside detection range or close enough.
	if distance > detection_range or distance <= stop_distance:
		velocity = Vector2.ZERO
		return

	# Move toward the player.
	var chase_direction: Vector2 = (
		player.global_position - global_position
	).normalized()

	velocity = chase_direction * speed
	move_and_slide()

	# Play the appropriate walking animation.
	play_walk_animation(chase_direction)


func play_walk_animation(chase_direction: Vector2) -> void:
	if not is_instance_valid(anim):
		return

	if abs(chase_direction.x) > abs(chase_direction.y):
		anim.flip_h = chase_direction.x < 0
		anim.play("idle_side_walk")
	elif chase_direction.y > 0:
		anim.flip_h = false
		anim.play("idle_front_walk")
	else:
		anim.flip_h = false
		anim.play("idle_back_walk")
