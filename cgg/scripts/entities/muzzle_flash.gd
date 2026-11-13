extends Node2D
class_name MuzzleFlash
## High-energy muzzle blast flare spawned at the weapon / casting point.
## Flashes directional plasma cone, side exhaust vents, expanding shock ring, and bright light.

var lifetime: float = 0.14
var _age: float = 0.0
var _light: PointLight2D


func _ready() -> void:
	z_as_relative = false
	z_index = 20
	top_level = false

	# Dynamic PointLight2D flash illuminating player and nearby tiles
	_light = PointLight2D.new()
	_light.color = Color(0.35, 0.85, 1.0, 1.0)
	_light.energy = 3.2
	_light.shadow_enabled = false
	_light.texture = _create_flash_texture()
	_light.texture_scale = 2.4
	add_child(_light)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	if is_instance_valid(_light):
		var t := _age / lifetime
		_light.energy = lerpf(3.2, 0.0, t * t)
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_age / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var ease_out := 1.0 - (1.0 - progress) * (1.0 - progress)

	# 1. Expanding circular plasma shockwave ring
	var ring_r := lerpf(6.0, 32.0, ease_out)
	draw_arc(Vector2.ZERO, ring_r, 0.0, TAU, 32, Color(0.2, 0.8, 1.0, alpha * 0.8), 2.4)

	# 2. Main directional forward muzzle blast cone (+X is firing direction)
	var cone_len := lerpf(38.0, 12.0, progress)
	var cone_w := lerpf(8.0, 22.0, progress)
	var cone_outer := PackedVector2Array([
		Vector2(-4.0, 0.0),
		Vector2(cone_len * 0.55, -cone_w * 0.5),
		Vector2(cone_len * 1.25, 0.0),
		Vector2(cone_len * 0.55, cone_w * 0.5)
	])
	draw_colored_polygon(cone_outer, Color(0.12, 0.65, 1.0, alpha * 0.88))

	# Inner hot white blast core
	var cone_inner := PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(cone_len * 0.5, -cone_w * 0.25),
		Vector2(cone_len * 0.9, 0.0),
		Vector2(cone_len * 0.5, cone_w * 0.25)
	])
	draw_colored_polygon(cone_inner, Color(0.96, 0.99, 1.0, alpha))

	# 3. Lateral exhaust vent flares (diagonal muzzle vents at ±65 degrees)
	var vent_len := lerpf(22.0, 5.0, progress)
	var vent_upper := Vector2(vent_len * 0.4, -vent_len * 0.9)
	var vent_lower := Vector2(vent_len * 0.4, vent_len * 0.9)
	draw_line(Vector2.ZERO, vent_upper, Color(0.3, 0.85, 1.0, alpha * 0.85), 2.8)
	draw_line(Vector2.ZERO, vent_lower, Color(0.3, 0.85, 1.0, alpha * 0.85), 2.8)
	# Lateral white hot sparks
	draw_line(Vector2.ZERO, vent_upper * 0.65, Color(1.0, 1.0, 1.0, alpha), 1.8)
	draw_line(Vector2.ZERO, vent_lower * 0.65, Color(1.0, 1.0, 1.0, alpha), 1.8)

	# 4. Central starburst flare / diamond flash at muzzle origin
	var star_size := lerpf(14.0, 2.5, progress)
	draw_line(Vector2(-star_size * 0.7, 0), Vector2(star_size * 1.6, 0), Color(1.0, 1.0, 1.0, alpha), 3.0)
	draw_line(Vector2(0, -star_size), Vector2(0, star_size), Color(1.0, 1.0, 1.0, alpha), 3.0)
	draw_circle(Vector2.ZERO, star_size * 0.55, Color(1.0, 1.0, 1.0, alpha))
	draw_circle(Vector2.ZERO, star_size * 0.95, Color(0.35, 0.9, 1.0, alpha * 0.55))


func _create_flash_texture() -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y: int in range(64):
		for x: int in range(64):
			var dist := Vector2(x - 32, y - 32).length() / 32.0
			var a := clampf(1.0 - dist, 0.0, 1.0)
			a = a * a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)
