extends Node2D
class_name BeamImpact
## Impact burst spawned when the muzzle beam shot strikes a target or barrier.
## Emits radial plasma sparks, expanding shockwave, and flash glow.

var lifetime: float = 0.18
var _age: float = 0.0
var _sparks: Array[Dictionary] = []


func _ready() -> void:
	z_index = 10
	# Seed 8 radial sparks with random angles and speeds
	for i: int in range(8):
		var angle := randf_range(0.0, TAU)
		var spd := randf_range(70.0, 160.0)
		_sparks.append({
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"pos": Vector2.ZERO,
			"len": randf_range(4.0, 8.0)
		})


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	for s: Dictionary in _sparks:
		s["pos"] += s["vel"] * delta
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_age / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var ease_out := 1.0 - (1.0 - progress) * (1.0 - progress)

	# 1. Expanding shockwave ring
	var r := lerpf(4.0, 22.0, ease_out)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, Color(0.3, 0.85, 1.0, alpha * 0.8), 2.0)

	# 2. Central white-hot flash
	var flash_r := lerpf(8.0, 1.0, progress)
	draw_circle(Vector2.ZERO, flash_r, Color(1.0, 1.0, 1.0, alpha))
	draw_circle(Vector2.ZERO, flash_r * 1.6, Color(0.2, 0.7, 1.0, alpha * 0.45))

	# 3. Flying spark particles
	for s: Dictionary in _sparks:
		var spos: Vector2 = s["pos"]
		var svel: Vector2 = s["vel"].normalized()
		var slen: float = s["len"] * alpha
		draw_line(spos, spos + svel * slen, Color(0.85, 0.95, 1.0, alpha), 1.8)
		draw_circle(spos, 1.5, Color(0.3, 0.85, 1.0, alpha))
