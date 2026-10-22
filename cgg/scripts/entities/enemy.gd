extends CharacterBody2D
## Basic enemy (slime sheet, measured 7x13 @32px, rows per characters/README.txt:
## 0-2 idle, 3-5 move, 6-8 attack, 9-11 damaged, 12 death — each group down/side/up).
## Keeps AI deliberately simple (spec §9 enemy baseline).

enum EState { IDLE, CHASE, ATTACK, HURT, DEAD }

signal died(enemy: Node)

const ROWS := {
	"idle": 0, "move": 3, "attack": 6, "hurt": 9, "death": 12,
}
## Frames per row — measured offline from the sheet's alpha coverage:
## idle 4, move 6, attack 7, hurt 3, death 5 (remaining cols are empty).
const ROW_FRAMES := { "idle": 4, "move": 6, "attack": 7, "hurt": 3, "death": 5 }
const FRAME_PX := 32
const SPRITE_SCALE := 4  # integer scale, matches the player's 48px-frame x4 look

var state: EState = EState.IDLE
var hp: int = 2
var speed: float = 70.0
var detection: float = 300.0
var stop_distance: float = 42.0
var damage: int = 1
var facing: String = "down"
var facing_left: bool = false

var _player: Node2D
var _attack_cd: float = 0.0
var _attack_applied: bool = false
var _hurt_left: float = 0.0
var _knockback: Vector2 = Vector2.ZERO
var _death_seen: bool = false

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	speed = float(GameState.combat["slime_speed"])
	hp = int(GameState.combat["slime_hp"])
	detection = float(GameState.combat["enemy_detection"])
	stop_distance = float(GameState.combat["enemy_stop_distance"])
	damage = int(GameState.combat["enemy_damage"])
	hitbox_shape.set_deferred("disabled", true)
	if anim.sprite_frames == null or anim.sprite_frames.get_animation_names().is_empty():
		anim.sprite_frames = _build_frames()
		anim.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		anim.position = Vector2(0, -30)
	_play_anim("idle")
	print("[CHECK] enemy (slime) ready, hp=", hp, ", anim=", anim.animation)


func _play_anim(action: String) -> void:
	if anim == null or anim.sprite_frames == null:
		return
	if anim.sprite_frames.has_animation("slime_front_idle"):
		match action:
			"idle":
				match facing:
					"up":
						anim.play("slime_back_idle")
					"side":
						anim.play("slime_side_idle")
						anim.flip_h = facing_left
					_:
						anim.play("slime_front_idle")
			"move":
				match facing:
					"up":
						if anim.sprite_frames.has_animation("slime_walk_back"):
							anim.play("slime_walk_back")
						else:
							anim.play("slime_back_idle")
					"side":
						anim.play("slime_side_walk")
						anim.flip_h = facing_left
					_:
						anim.play("slime_walk_front")
			"attack":
				if anim.sprite_frames.has_animation("slime_attack"):
					anim.play("slime_attack")
				else:
					anim.play("slime_walk_front")
			"hurt":
				if anim.sprite_frames.has_animation("slime_hurt"):
					anim.play("slime_hurt")
			"death":
				anim.play("slime_die")
	else:
		if anim.sprite_frames.has_animation(action):
			anim.play(action)
			anim.flip_h = facing_left


func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var sheet := Assets.tex(Assets.SLIME_SHEET)
	for anim_name: String in ROWS:
		var row: int = ROWS[anim_name]
		var count: int = int(ROW_FRAMES[anim_name])
		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 9.0)
		var loop := anim_name in ["idle", "move"]
		sf.set_animation_loop(anim_name, loop)
		for i: int in range(count):
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(i * FRAME_PX, row * FRAME_PX, FRAME_PX, FRAME_PX)
			sf.add_frame(anim_name, at)
	return sf


func _physics_process(delta: float) -> void:
	if state == EState.DEAD:
		velocity = Vector2.ZERO
		return
	_attack_cd = maxf(0.0, _attack_cd - delta)

	if UI.dialogue_open:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		velocity = Vector2.ZERO
		return

	var dist := global_position.distance_to(_player.global_position)

	match state:
		EState.HURT:
			_hurt_left -= delta
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 700.0 * delta)
			if _hurt_left <= 0.0:
				state = EState.IDLE
				_play_anim("idle")
		EState.ATTACK:
			velocity = Vector2.ZERO
			_tick_attack()
		_:
			if dist > detection:
				state = EState.IDLE
				velocity = Vector2.ZERO
				_play_anim("idle")
			elif dist > stop_distance:
				state = EState.CHASE
				var dir := (_player.global_position - global_position).normalized()
				velocity = dir * speed
				_update_facing(dir)
				_play_anim("move")
			else:
				if _attack_cd <= 0.0:
					_start_attack()
				else:
					velocity = Vector2.ZERO
					var toward := (_player.global_position - global_position).normalized()
					_update_facing(toward)
					_play_anim("idle")
	move_and_slide()


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) > absf(dir.y):
		facing = "side"
		facing_left = dir.x < 0.0
	elif dir.y > 0.0:
		facing = "down"
	else:
		facing = "up"


func _start_attack() -> void:
	state = EState.ATTACK
	velocity = Vector2.ZERO
	_attack_cd = 1.1
	_attack_applied = false
	_play_anim("attack")
	var tw := create_tween()
	tw.tween_callback(_enable_hitbox).set_delay(0.3)
	tw.tween_callback(_disable_hitbox).set_delay(0.15)


func _tick_attack() -> void:
	if anim.animation != "attack" and not anim.is_playing():
		state = EState.IDLE


func _enable_hitbox() -> void:
	if state == EState.ATTACK:
		hitbox_shape.set_deferred("disabled", false)


func _disable_hitbox() -> void:
	hitbox_shape.set_deferred("disabled", true)


## Called by the player's hitbox (player.gd) — spec §9 feedback + knockback.
func take_damage(amount: int, from_dir: Vector2) -> void:
	if state == EState.DEAD:
		return
	hp -= amount
	_flash_hurt()
	if hp <= 0:
		_die()
		return
	state = EState.HURT
	_hurt_left = 0.25
	_knockback = from_dir * float(GameState.combat["knockback"]) * 0.6
	_play_anim("hurt")
	_disable_hitbox()


func _flash_hurt() -> void:
	anim.modulate = Color(2.0, 2.0, 2.0)
	var tw := create_tween()
	tw.tween_property(anim, "modulate", Color.WHITE, 0.2)


func _die() -> void:
	if _death_seen:
		return
	_death_seen = true
	AudioManager.play_slime_death()
	state = EState.DEAD
	velocity = Vector2.ZERO
	# Disable collision safely, then play the death row (spec §9).
	hurtbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 1)
	_play_anim("death")
	died.emit(self)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(anim, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
