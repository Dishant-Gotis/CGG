extends Area2D
class_name ManaProjectile
## Radiant Mana Bolt thrown by the player.
## Illuminates dark caverns, flies towards the target, and deals 2 damage + knockback.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var damage: int = 2
var lifetime: float = 2.0

var _light: PointLight2D
var _hit: bool = false
var _pulse_t: float = 0.0


func _ready() -> void:
	# Layer 8 (Attack hitboxes), Mask 1 (world walls) + 4 (enemies) + 16 (enemy hurtboxes)
	collision_layer = 8
	collision_mask = 1 | 4 | 16
	monitoring = true
	monitorable = true

	var col := CollisionShape2D.new()
	var cshape := CircleShape2D.new()
	cshape.radius = 12.0
	col.shape = cshape
	add_child(col)

	# Dedicated PointLight2D so the projectile actively illuminates dark caves
	_light = PointLight2D.new()
	_light.color = Color(0.28, 0.78, 1.0, 1.0)
	_light.energy = 1.6
	_light.shadow_enabled = false

	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y_px: int in range(64):
		for x_px: int in range(64):
			var dist := Vector2(x_px - 32, y_px - 32).length() / 32.0
			var a := clampf(1.0 - dist, 0.0, 1.0)
			a = a * a
			img.set_pixel(x_px, y_px, Color(1, 1, 1, a))
	var tex := ImageTexture.create_from_image(img)
	_light.texture = tex
	_light.texture_scale = 2.8
	add_child(_light)

	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_pulse_t += delta * 12.0
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		_fade_and_free()


func _draw() -> void:
	var pulse := 1.0 + 0.15 * sin(_pulse_t)
	# Outer mystical aura
	draw_circle(Vector2.ZERO, 13.0 * pulse, Color(0.12, 0.55, 1.0, 0.35))
	# Inner glowing cyan ring
	draw_circle(Vector2.ZERO, 8.5 * pulse, Color(0.35, 0.85, 1.0, 0.85))
	# Core celestial white star
	draw_circle(Vector2.ZERO, 4.5, Color(0.95, 0.98, 1.0, 1.0))


func _on_area_entered(area: Area2D) -> void:
	if _hit:
		return
	var target: Node = area.get_parent()
	if target != null and target.has_method("take_damage"):
		_hit = true
		target.take_damage(damage, direction)
		_fade_and_free()


func _on_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body == self or body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		_hit = true
		body.take_damage(damage, direction)
		_fade_and_free()
	elif body is TileMap or body is StaticBody2D:
		# Hit wall / obstacle
		_hit = true
		_fade_and_free()


func _fade_and_free() -> void:
	set_physics_process(false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)
