extends CharacterBody2D
## Player controller (spec §8, §9): typed, action-driven, one explicit state
## machine. Attack uses a bounded hitbox window and finishes via a single rule
## (animation_finished, with a time safety net).

enum State { IDLE, WALK, ATTACK, HURT, DEAD }

const ATTACK_ANIMS := {
	"up": "back_attack",
	"down": "front_attack",
	"side": "side_attack",
}
const WALK_ANIMS := {
	"up": "idle_back_walk",
	"down": "idle_front_walk",
	"side": "idle_side_walk",
}
const IDLE_ANIMS := {
	"up": "idle_back",
	"down": "idle",
	"side": "idle_side",
}

var state: State = State.IDLE
## "down" / "up" / "side"; horizontal facing is the sprite flip (README: flip side).
var facing: String = "down"
var facing_left: bool = false

var speed: float = 250.0
var attack_window_left: float = 0.0
var attack_safety_left: float = 0.0
var attack_cd_left: float = 0.0
var invuln_left: float = 0.0
var hurt_left: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var _hit_this_swing: Array[int] = []
var _interact_targets: Array[Area2D] = []
var _step_timer: float = 0.0
const STEP_INTERVAL: float = 0.35

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $AttackHitbox
@onready var hitbox_shape: CollisionShape2D = $AttackHitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var probe: Area2D = $InteractProbe
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	speed = float(GameState.combat["player_speed"])
	hitbox.area_entered.connect(_on_hitbox_area)
	hurtbox.area_entered.connect(_on_hurtbox_area)
	probe.area_entered.connect(_on_probe_entered)
	probe.area_exited.connect(_on_probe_exited)
	anim.animation_finished.connect(_on_anim_finished)
	_set_hitbox_active(false)
	state = State.IDLE
	anim.play(IDLE_ANIMS[facing])
	print("[CHECK] player ready at ", global_position)


func _physics_process(delta: float) -> void:
	attack_cd_left = maxf(0.0, attack_cd_left - delta)
	invuln_left = maxf(0.0, invuln_left - delta)
	if invuln_left > 0.0:
		# Readable blink during the invulnerability window (spec §8).
		anim.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() * 0.02))
	else:
		anim.modulate.a = 1.0

	if state == State.DEAD:
		velocity = Vector2.ZERO
		return

	# Dialogue/cutscenes fully own the controls (spec §10: no input leakage).
	if UI.dialogue_open:
		velocity = Vector2.ZERO
		if state == State.IDLE or state == State.WALK:
			state = State.IDLE
			anim.play(IDLE_ANIMS[facing])
			anim.flip_h = facing_left
		move_and_slide()
		return

	match state:
		State.IDLE, State.WALK:
			_tick_move()
		State.ATTACK:
			_tick_attack(delta)
		State.HURT:
			hurt_left -= delta
			velocity = knockback
			knockback = knockback.move_toward(Vector2.ZERO, 900.0 * delta)
			if hurt_left <= 0.0:
				state = State.IDLE
				anim.play(IDLE_ANIMS[facing])
				anim.flip_h = facing_left
		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()


func _tick_move() -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	if dir != Vector2.ZERO:
		if absf(dir.x) > absf(dir.y):
			facing = "side"
			facing_left = dir.x < 0.0
		elif dir.y > 0.0:
			facing = "down"
			facing_left = false
		else:
			facing = "up"
			facing_left = false
		state = State.WALK
		anim.play(WALK_ANIMS[facing])
		anim.flip_h = facing_left
		_step_timer -= get_physics_process_delta_time()
		if _step_timer <= 0.0:
			AudioManager.play_step()
			_step_timer = STEP_INTERVAL
	else:
		state = State.IDLE
		# Idle keeps the last meaningful facing (spec §8) — _update_facing not called.
		anim.play(IDLE_ANIMS[facing])
		anim.flip_h = facing_left
		_step_timer = 0.08

	if Input.is_action_just_pressed("attack") and attack_cd_left <= 0.0:
		_start_attack()
		return
	if Input.is_action_just_pressed("interact"):
		_try_interact()
		return
	_update_prompt()


func _start_attack() -> void:
	AudioManager.play_sword()
	state = State.ATTACK
	velocity = Vector2.ZERO
	attack_cd_left = float(GameState.combat["attack_cooldown"])
	attack_window_left = float(GameState.combat["attack_window"])
	attack_safety_left = 1.2  # safety net only; the real end is animation_finished
	_hit_this_swing.clear()
	_place_hitbox()
	_set_hitbox_active(true)
	anim.play(ATTACK_ANIMS[facing])
	anim.flip_h = facing_left


func _tick_attack(delta: float) -> void:
	attack_window_left -= delta
	attack_safety_left -= delta
	if attack_window_left <= 0.0:
		_set_hitbox_active(false)
	if attack_safety_left <= 0.0:
		_end_attack()  # only reachable if the animation never finished


func _end_attack() -> void:
	_set_hitbox_active(false)
	_hit_this_swing.clear()
	state = State.IDLE
	anim.play(IDLE_ANIMS[facing])
	anim.flip_h = facing_left


func _place_hitbox() -> void:
	var reach: float = float(GameState.combat["attack_reach"])
	match facing:
		"down":
			hitbox.position = Vector2(0, reach)
		"up":
			hitbox.position = Vector2(0, -reach)
		"side":
			hitbox.position = Vector2(reach if not facing_left else -reach, -6)


func _set_hitbox_active(active: bool) -> void:
	# Toggling the shape (not `monitoring`) avoids "flushing queries" errors.
	hitbox_shape.set_deferred("disabled", not active)


func _on_hitbox_area(area: Area2D) -> void:
	if state != State.ATTACK or attack_window_left <= 0.0:
		return
	var target := area.get_parent() as Node2D
	if target == null or not target.has_method("take_damage"):
		return
	var id: int = target.get_instance_id()
	if id in _hit_this_swing:
		return  # one hit per enemy per swing (spec §9)
	_hit_this_swing.append(id)
	var dir: Vector2 = (target.global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	target.take_damage(int(GameState.combat["attack_damage"]), dir)


func _on_hurtbox_area(area: Area2D) -> void:
	if invuln_left > 0.0 or state == State.ATTACK or state == State.DEAD:
		return
	var source: Node = area.get_parent()
	var dmg := int(GameState.combat["enemy_damage"])
	if source != null and "damage" in source:
		dmg = int(source.damage)
	_take_damage(dmg, area.global_position)


func _take_damage(dmg: int, from_pos: Vector2) -> void:
	GameState.set_health(GameState.health - dmg)
	if GameState.health <= 0:
		_die()
		return
	state = State.HURT
	hurt_left = 0.25
	invuln_left = float(GameState.combat["invuln_time"])
	var away := (global_position - from_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.UP
	knockback = away * float(GameState.combat["knockback"])
	_flash_hurt()


func _flash_hurt() -> void:
	anim.modulate = Color(1, 0.45, 0.45)
	var tw := create_tween()
	tw.tween_property(anim, "modulate", Color.WHITE, 0.3)


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_set_hitbox_active(false)
	print("[CHECK] player died — respawning at region start")
	GameState.set_health(GameState.max_health)  # retry: spec §12 restart on game over
	await UI.fade_out()
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await UI.fade_in()


func _on_anim_finished() -> void:
	# THE single rule ending an attack (spec §8: never stick on one frame).
	if state == State.ATTACK:
		_end_attack()


# --- interaction -------------------------------------------------------------

const MAX_INTERACT_DISTANCE: float = 75.0


func _get_interactable(node: Node) -> Node:
	if node == null or not is_instance_valid(node):
		return null
	if node.has_method("interact"):
		return node
	var parent := node.get_parent()
	if parent != null and is_instance_valid(parent) and parent.has_method("interact"):
		return parent
	return null


func _get_prompt_text(target: Node) -> String:
	if target == null:
		return ""
	if "prompt_text" in target:
		return str(target.prompt_text)
	var parent := target.get_parent()
	if parent != null and "prompt_text" in parent:
		return str(parent.prompt_text)
	return "Talk"


func _on_probe_entered(area: Area2D) -> void:
	if area not in _interact_targets:
		_interact_targets.append(area)


func _on_probe_exited(area: Area2D) -> void:
	_interact_targets.erase(area)


func _nearest_target() -> Node:
	var best: Node = null
	var best_d := INF
	var still_valid: Array[Area2D] = []

	for area: Area2D in _interact_targets:
		if not is_instance_valid(area):
			continue
		var obj := _get_interactable(area)
		if obj == null:
			continue
		var target_pos: Vector2 = (obj as Node2D).global_position if obj is Node2D else area.global_position
		var d := global_position.distance_to(target_pos)
		if d <= MAX_INTERACT_DISTANCE:
			still_valid.append(area)
			if d < best_d:
				best_d = d
				best = obj

	_interact_targets = still_valid
	return best


func _update_prompt() -> void:
	var target := _nearest_target()
	if target != null and not UI.dialogue_open:
		var raw_text := _get_prompt_text(target)
		var display_text := raw_text
		if raw_text.begins_with("E - ") or raw_text.begins_with("E -"):
			var subject := raw_text.substr(raw_text.find("-") + 1).strip_edges()
			display_text = "[E / Space / Click] " + subject
		elif not raw_text.begins_with("["):
			display_text = "[E / Space / Click] " + raw_text
		UI.show_prompt(display_text)
	else:
		UI.hide_prompt()


func _try_interact() -> void:
	if UI.dialogue_open:
		return
	var target := _nearest_target()
	if target == null or not target.has_method("interact"):
		return
	UI.hide_prompt()
	AudioManager.play_select()
	target.interact(self)


func _unhandled_input(event: InputEvent) -> void:
	if UI.dialogue_open:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target := _nearest_target()
		if target != null:
			_try_interact()
			get_viewport().set_input_as_handled()
