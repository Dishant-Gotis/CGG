
extends CharacterBody2D

@export var speed: float = 100.0

var current_dir: String = "down"
var is_attacking: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	anim.scale = Vector2(4, 4)
	anim.play("idle")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			print("Q KEY DETECTED")
			attack()


func _physics_process(_delta: float) -> void:
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if Input.is_key_pressed(KEY_A):
		direction.x = -1
	elif Input.is_key_pressed(KEY_D):
		direction.x = 1

	if Input.is_key_pressed(KEY_W):
		direction.y = -1
	elif Input.is_key_pressed(KEY_S):
		direction.y = 1

	direction = direction.normalized()
	velocity = direction * speed
	move_and_slide()

	if direction != Vector2.ZERO:
		if abs(direction.x) > abs(direction.y):
			current_dir = "right" if direction.x > 0 else "left"
		else:
			current_dir = "down" if direction.y > 0 else "up"

		play_walk()
	else:
		play_idle()


func attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	velocity = Vector2.ZERO

	match current_dir:
		"up":
			anim.play("back_attack")
		"down":
			anim.play("front_attack")
		"left", "right":
			anim.flip_h = current_dir == "left"
			anim.play("side_attack")

	print("Current animation: ", anim.animation)


func play_walk() -> void:
	match current_dir:
		"right":
			anim.flip_h = false
			anim.play("idle_side_walk")
		"left":
			anim.flip_h = true
			anim.play("idle_side_walk")
		"down":
			anim.flip_h = false
			anim.play("idle_front_walk")
		"up":
			anim.flip_h = false
			anim.play("idle_back_walk")


func play_idle() -> void:
	match current_dir:
		"right":
			anim.flip_h = false
			anim.play("idle_side")
		"left":
			anim.flip_h = true
			anim.play("idle_side")
		"down":
			anim.flip_h = false
			anim.play("idle")
		"up":
			anim.flip_h = false
			anim.play("idle_back")


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation in ["back_attack", "front_attack", "side_attack"]:
		is_attacking = false
		play_idle()
