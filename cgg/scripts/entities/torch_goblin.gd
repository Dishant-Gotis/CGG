extends CharacterBody2D
## Torch Goblin Enemy AI (spec §9):
## Uses Red Torch Goblin sprite sheet (192x192 cells),
## carries a burning torch with dynamic 2D lighting,
## patrols territory, chases the player, and swings flaming torch.

enum State { PATROL, CHASE, ATTACK, HURT, DEAD }

signal died(enemy: Node)

const SHEET_PATH := "res://Tiny Swords (Update 010)/Factions/Goblins/Troops/Torch/Red/Torch_Red.png"
const CELL_SIZE := 192

var state: State = State.PATROL
var hp: int = 3
var max_hp: int = 3
var move_speed: float = 75.0
var detection_radius: float = 230.0
var attack_reach: float = 42.0
var damage: int = 1

var home_pos: Vector2 = Vector2.ZERO
var patrol_target: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0

var _player: Node2D = null
var _attack_cooldown: float = 0.0
var _hurt_timer: float = 0.0
var _knockback: Vector2 = Vector2.ZERO

var anim: AnimatedSprite2D
var torch_light: PointLight2D
var hurtbox: Area2D
var hitbox: Area2D
var hitbox_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	home_pos = global_position
	patrol_target = home_pos

	_build_components()
	_build_torch_light()

	state = State.PATROL
	_play_anim("idle")
	print("[CHECK] Torch Goblin ready at ", global_position)


func _build_components() -> void:
	# Main physical collision
	collision_layer = 4  # Enemy layer
	collision_mask = 1   # Collides with world walls

	var col := CollisionShape2D.new()
	var cshape := CircleShape2D.new()
	cshape.radius = 16.0
	col.shape = cshape
	col.position = Vector2(0, -10)
	add_child(col)

	# AnimatedSprite2D
	anim = AnimatedSprite2D.new()
	anim.sprite_frames = _generate_sprite_frames()
	anim.position = Vector2(0, -32)
	anim.scale = Vector2(0.9, 0.9)
	anim.animation_finished.connect(_on_anim_finished)
	anim.frame_changed.connect(_on_frame_changed)
	add_child(anim)

	# Hurtbox: must be on layer 16 so player's AttackHitbox (mask=16) detects it.
	# Damage is handled player-side via take_damage() — no area_entered needed here.
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 16  # Matches player AttackHitbox mask=16
	hurtbox.collision_mask = 0    # Goblin doesn't self-monitor its hurtbox
	var hb_col := CollisionShape2D.new()
	var hb_shape := CircleShape2D.new()
	hb_shape.radius = 24.0
	hb_col.shape = hb_shape
	hb_col.position = Vector2(0, -20)
	hurtbox.add_child(hb_col)
	add_child(hurtbox)

	# Hitbox: fires onto player's Hurtbox (layer 128).
	hitbox = Area2D.new()
	hitbox.collision_layer = 32   # Goblin attack hitbox
	hitbox.collision_mask = 128   # Player Hurtbox layer
	hitbox.area_entered.connect(_on_hitbox_hit_player)
	hitbox_shape = CollisionShape2D.new()
	var hit_shape := CircleShape2D.new()
	hit_shape.radius = 28.0
	hitbox_shape.shape = hit_shape
	hitbox_shape.position = Vector2(24, -18)
	hitbox_shape.disabled = true
	hitbox.add_child(hitbox_shape)
	add_child(hitbox)


func _build_torch_light() -> void:
	torch_light = PointLight2D.new()
	torch_light.color = Color(1.0, 0.58, 0.22, 1.0) # Fiery orange-amber
	torch_light.energy = 1.3
	torch_light.shadow_enabled = false

	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for y_px: int in range(128):
		for x_px: int in range(128):
			var dist := Vector2(x_px - 64, y_px - 64).length() / 64.0
			var a := clampf(1.0 - dist, 0.0, 1.0)
			a = a * a
			img.set_pixel(x_px, y_px, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	torch_light.texture = tex
	torch_light.texture_scale = 2.4
	torch_light.position = Vector2(16, 12)
	add_child(torch_light)


func _generate_sprite_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	var tex: Texture2D = load(SHEET_PATH)
	if tex == null:
		push_error("[TorchGoblin] Failed to load sheet: ", SHEET_PATH)
		return sf

	# Row 0: Idle (7 frames)
	sf.add_animation("idle")
	sf.set_animation_speed("idle", 8.0)
	sf.set_animation_loop("idle", true)
	for c: int in range(7):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * CELL_SIZE, 0, CELL_SIZE, CELL_SIZE)
		sf.add_frame("idle", atlas)

	# Row 1: Run (6 frames)
	sf.add_animation("run")
	sf.set_animation_speed("run", 10.0)
	sf.set_animation_loop("run", true)
	for c: int in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * CELL_SIZE, CELL_SIZE, CELL_SIZE, CELL_SIZE)
		sf.add_frame("run", atlas)

	# Row 2: Attack Down (6 frames)
	sf.add_animation("attack_down")
	sf.set_animation_speed("attack_down", 12.0)
	sf.set_animation_loop("attack_down", false)
	for c: int in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * CELL_SIZE, CELL_SIZE * 2, CELL_SIZE, CELL_SIZE)
		sf.add_frame("attack_down", atlas)

	# Row 3: Attack Side (6 frames)
	sf.add_animation("attack_side")
	sf.set_animation_speed("attack_side", 12.0)
	sf.set_animation_loop("attack_side", false)
	for c: int in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * CELL_SIZE, CELL_SIZE * 3, CELL_SIZE, CELL_SIZE)
		sf.add_frame("attack_side", atlas)

	# Row 4: Attack Up (6 frames)
	sf.add_animation("attack_up")
	sf.set_animation_speed("attack_up", 12.0)
	sf.set_animation_loop("attack_up", false)
	for c: int in range(6):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c * CELL_SIZE, CELL_SIZE * 4, CELL_SIZE, CELL_SIZE)
		sf.add_frame("attack_up", atlas)

	return sf


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)

	# Flicker torch flame light
	if torch_light != null:
		torch_light.energy = 1.25 + 0.15 * sin(Time.get_ticks_msec() * 0.012)

	# Find player if null or invalid
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D

	match state:
		State.PATROL:
			_tick_patrol(delta)
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide()
		State.HURT:
			_hurt_timer -= delta
			velocity = _knockback
			_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta)
			move_and_slide()
			if _hurt_timer <= 0.0:
				anim.modulate = Color.WHITE
				state = State.CHASE


func _tick_patrol(delta: float) -> void:
	if _player != null and is_instance_valid(_player):
		var dist_to_player := global_position.distance_to(_player.global_position)
		if dist_to_player <= detection_radius:
			state = State.CHASE
			return

	patrol_timer -= delta
	if patrol_timer <= 0.0:
		patrol_timer = randf_range(2.5, 4.5)
		var offset := Vector2(randf_range(-70.0, 70.0), randf_range(-50.0, 50.0))
		patrol_target = home_pos + offset

	var to_target := patrol_target - global_position
	if to_target.length() > 10.0:
		var dir := to_target.normalized()
		velocity = dir * (move_speed * 0.6)
		_update_facing(dir.x)
		_play_anim("run")
	else:
		velocity = Vector2.ZERO
		_play_anim("idle")

	move_and_slide()


func _tick_chase(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		state = State.PATROL
		return

	var to_player := _player.global_position - global_position
	var dist := to_player.length()

	if dist > detection_radius * 1.4:
		# Lost player, return to patrol
		state = State.PATROL
		return

	_update_facing(to_player.x)

	if dist <= attack_reach and _attack_cooldown <= 0.0:
		_start_attack(to_player)
		return

	var dir := to_player.normalized()
	velocity = dir * move_speed
	_play_anim("run")
	move_and_slide()


func _start_attack(dir: Vector2) -> void:
	state = State.ATTACK
	_attack_cooldown = 1.6
	velocity = Vector2.ZERO

	# Choose attack direction animation
	if absf(dir.y) > absf(dir.x) * 1.2:
		if dir.y > 0.0:
			_play_anim("attack_down")
			hitbox_shape.position = Vector2(0, 10)
		else:
			_play_anim("attack_up")
			hitbox_shape.position = Vector2(0, -36)
	else:
		_play_anim("attack_side")
		var side_x: float = -28.0 if anim.flip_h else 28.0
		hitbox_shape.position = Vector2(side_x, -18)


func _on_frame_changed() -> void:
	if state == State.ATTACK:
		# Attack frames 2, 3, 4 swing the torch
		var f := anim.frame
		hitbox_shape.disabled = not (f >= 2 and f <= 4)


func _on_anim_finished() -> void:
	if state == State.ATTACK:
		hitbox_shape.disabled = true
		state = State.CHASE
		_play_anim("idle")


func _update_facing(dir_x: float) -> void:
	if absf(dir_x) > 2.0:
		var left := dir_x < 0.0
		anim.flip_h = left
		if torch_light != null:
			torch_light.position.x = -16.0 if left else 16.0


func _play_anim(anim_name: String) -> void:
	if anim != null and anim.animation != anim_name:
		anim.play(anim_name)


## Called by player.gd _on_hitbox_area() — player sword detected this goblin's hurtbox.
func take_damage(amount: int, from_dir: Vector2) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	AudioManager.play_sword()
	anim.modulate = Color(1.0, 0.25, 0.25)
	_hurt_timer = 0.28
	state = State.HURT
	var tw := create_tween()
	tw.tween_property(anim, "modulate", Color.WHITE, 0.3)

	if from_dir == Vector2.ZERO:
		_knockback = Vector2.UP * 240.0
	else:
		_knockback = from_dir * 240.0

	if hp <= 0:
		_die()


## Called when goblin's Hitbox hits the player's Hurtbox.
func _on_hitbox_hit_player(area: Area2D) -> void:
	if state == State.DEAD or hitbox_shape.disabled:
		return
	var player := area.get_parent() as Node2D
	if player != null and player.has_method("_take_damage"):
		player._take_damage(damage, global_position)


func _die() -> void:
	state = State.DEAD
	hitbox_shape.disabled = true
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0
	AudioManager.play_slime_death()
	died.emit(self)

	# Death tween: dissolve and drop ember
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(anim, "modulate:a", 0.0, 0.45)
	tw.tween_property(anim, "scale", Vector2(0.3, 0.3), 0.45)
	if torch_light != null:
		tw.tween_property(torch_light, "energy", 0.0, 0.4)
	tw.chain().tween_callback(queue_free)
