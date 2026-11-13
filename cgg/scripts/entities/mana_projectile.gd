extends Area2D
class_name ManaProjectile

const BeamImpactClass = preload("res://scripts/entities/beam_impact.gd")

## High-velocity Muzzle Beam Shot cast by the player.
## Pierces through the air as an elongated luminous laser lance,
## leaving a radiant plasma wake, dynamic lighting, and dealing 2 damage + knockback.

var direction: Vector2 = Vector2.RIGHT
var target: Node2D = null
var speed: float = 620.0
var damage: int = 2
var lifetime: float = 1.6

var _light: PointLight2D
var _hit: bool = false
var _pulse_t: float = 0.0
var _trail: Array[Vector2] = []
const MAX_TRAIL_POINTS := 14


func _ready() -> void:
	# Layer 8 (Attack hitboxes), Mask 1 (world walls) + 4 (enemies) + 16 (enemy hurtboxes)
	collision_layer = 8
	collision_mask = 1 | 4 | 16
	monitoring = true
	monitorable = true
	z_as_relative = false
	z_index = 20

	# Capsule collider aligned with beam axis (height 48, radius 8.5)
	var col := CollisionShape2D.new()
	var cshape := CapsuleShape2D.new()
	cshape.radius = 8.5
	cshape.height = 48.0
	col.shape = cshape
	col.rotation = PI * 0.5 # Aligned horizontally with local +X
	add_child(col)

	# Dedicated PointLight2D illuminating dark caverns and surroundings
	_light = PointLight2D.new()
	_light.color = Color(0.35, 0.85, 1.0, 1.0)
	_light.energy = 2.4
	_light.shadow_enabled = false
	_light.texture = _create_light_texture()
	_light.texture_scale = 3.4
	add_child(_light)

	rotation = direction.angle()
	_trail.append(global_position)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_t += delta * 20.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	# Auto-aim homing towards target if available
	if is_instance_valid(target):
		var target_pos := target.global_position
		if target.has_node("CollisionShape2D"):
			target_pos = (target.get_node("CollisionShape2D") as Node2D).global_position
		var desired_dir := (target_pos - global_position).normalized()
		if desired_dir != Vector2.ZERO:
			direction = direction.slerp(desired_dir, 6.0 * delta).normalized()

	rotation = direction.angle()
	global_position += direction * speed * delta

	# Record trailing positions for plasma wake
	_trail.push_front(global_position)
	if _trail.size() > MAX_TRAIL_POINTS:
		_trail.pop_back()

	lifetime -= delta
	if lifetime <= 0.0:
		_fade_and_free(false)


func _draw() -> void:
	var pulse := 1.0 + 0.12 * sin(_pulse_t)

	# 1. Trailing Plasma Wake / Beam Ribbon (drawn in global space transformed to local)
	if _trail.size() > 1:
		for i: int in range(_trail.size() - 1):
			var pt_a: Vector2 = to_local(_trail[i])
			var pt_b: Vector2 = to_local(_trail[i + 1])
			var t := float(i) / float(_trail.size())
			var trail_a := (1.0 - t) * 0.65
			var w := lerpf(10.0, 2.0, t) * pulse
			# Outer cyan glow wake
			draw_line(pt_a, pt_b, Color(0.12, 0.6, 1.0, trail_a), w)
			# Inner bright cyan sheath
			draw_line(pt_a, pt_b, Color(0.35, 0.85, 1.0, trail_a * 1.2), maxf(1.5, w * 0.55))
			# Core white hot wake streak
			draw_line(pt_a, pt_b, Color(0.95, 0.98, 1.0, trail_a * 1.5), maxf(1.0, w * 0.25))

	# 2. Outer Beam Plasma Corona / Aura Glow (Local +X is forward, -X is rear)
	# Spans from rear (-38) to front tip (+26)
	var glow_pts := PackedVector2Array([
		Vector2(-40.0, 0.0),
		Vector2(-24.0, -9.0 * pulse),
		Vector2(14.0, -8.0 * pulse),
		Vector2(28.0, 0.0),
		Vector2(14.0, 8.0 * pulse),
		Vector2(-24.0, 9.0 * pulse)
	])
	draw_colored_polygon(glow_pts, Color(0.1, 0.5, 1.0, 0.38))

	# 3. Main Beam Lance / Energy Sheath (Aerodynamic laser spearhead)
	var lance_pts := PackedVector2Array([
		Vector2(-34.0, 0.0),
		Vector2(-18.0, -5.5),
		Vector2(12.0, -5.5),
		Vector2(26.0, 0.0),
		Vector2(12.0, 5.5),
		Vector2(-18.0, 5.5)
	])
	draw_colored_polygon(lance_pts, Color(0.25, 0.85, 1.0, 0.95))

	# 4. Core Laser Spine (Blinding pure white energy line)
	draw_line(Vector2(-30.0, 0.0), Vector2(22.0, 0.0), Color(1.0, 1.0, 1.0, 1.0), 3.8)
	# Secondary white energy cap at beam head
	draw_circle(Vector2(20.0, 0.0), 2.8, Color(1.0, 1.0, 1.0, 1.0))

	# 5. Piercing Leading Needle Spike (+X forward tip)
	draw_line(Vector2(20.0, 0.0), Vector2(34.0, 0.0), Color(0.9, 0.98, 1.0, 0.95), 2.0)

	# 6. Periodic Shock Diamonds / Energy Ribs (chevrons along the spine)
	var ribs := [10.0, -4.0, -18.0]
	for rx: float in ribs:
		draw_line(Vector2(rx - 2.0, -5.0), Vector2(rx + 2.0, 0.0), Color(0.95, 0.99, 1.0, 0.9), 1.8)
		draw_line(Vector2(rx + 2.0, 0.0), Vector2(rx - 2.0, 5.0), Color(0.95, 0.99, 1.0, 0.9), 1.8)

	# 7. Energy Head Diamond Starburst at beam apex
	var star_sz := 4.5 * pulse
	draw_line(Vector2(22.0 - star_sz, 0.0), Vector2(22.0 + star_sz, 0.0), Color(1.0, 1.0, 1.0, 0.95), 2.0)
	draw_line(Vector2(22.0, -star_sz), Vector2(22.0, star_sz), Color(1.0, 1.0, 1.0, 0.95), 2.0)


func _create_light_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y_px: int in range(64):
		for x_px: int in range(64):
			# Elongated oval light
			var dx := (x_px - 32) / 32.0
			var dy := (y_px - 32) / 20.0
			var dist := sqrt(dx * dx + dy * dy)
			var a := clampf(1.0 - dist, 0.0, 1.0)
			a = a * a
			img.set_pixel(x_px, y_px, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)


func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	var tgt: Node = area.get_parent()
	if tgt != null and tgt.has_method("take_damage"):
		_hit = true
		tgt.take_damage(damage, direction)
		_fade_and_free(true)


func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body == self or body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit = true
		body.take_damage(damage, direction)
		_fade_and_free(true)
	elif body is TileMap or body is StaticBody2D:
		_hit = true
		_fade_and_free(true)


func _fade_and_free(spawn_impact: bool) -> void:
	set_physics_process(false)
	set_process(false)

	if spawn_impact and get_parent() != null:
		var imp: Node2D = BeamImpactClass.new()
		imp.global_position = global_position
		get_parent().add_child(imp)
		AudioManager.play_beam_impact()

	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.08)
	tw.tween_callback(queue_free)
