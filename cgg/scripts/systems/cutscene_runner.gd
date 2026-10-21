extends Node
class_name CutsceneRunner
## Data-driven cutscene player (spec §4): one runner, steps come from JSON,
## story content never lives in engine code. Skippable at any point.

signal step_finished(step: Dictionary)

var running: bool = false
var skipped: bool = false

var _bg: TextureRect
var _tint: ColorRect
var _stage_root: Control
var _sprite: AnimatedSprite2D
var _title: Label


func setup(bg: TextureRect, tint: ColorRect, stage_root: Control,
		sprite: AnimatedSprite2D, title: Label) -> void:
	_bg = bg
	_tint = tint
	_stage_root = stage_root
	_sprite = sprite
	_title = title


## Returns true when the cutscene played to the end, false when skipped.
func play(steps: Array) -> bool:
	running = true
	skipped = false
	UI.show_skip_hint(true)
	UI.set_hud_visible(false)
	for step: Variant in steps:
		if skipped:
			break
		if step is Dictionary:
			await _run_step(step as Dictionary)
	if UI.dialogue_open:
		UI.close_dialogue()
	running = false
	UI.show_skip_hint(false)
	UI.set_hud_visible(true)
	return not skipped


## Resolved at runtime — autoload consts are not compile-time constants.
func _background_path(key: String) -> String:
	match key:
		"dream": return Assets.PROLOGUE_DREAM
		"apartment": return Assets.PROLOGUE_APARTMENT
		"office": return Assets.PROLOGUE_OFFICE
		"bus": return Assets.PROLOGUE_BUS
		"village": return Assets.PROLOGUE_VILLAGE
		"room": return Assets.PROLOGUE_ROOM
		"castle_sky": return Assets.PROLOGUE_SKY
	return ""


func _input(event: InputEvent) -> void:
	if running and event.is_action_pressed("skip"):
		skipped = true
		get_viewport().set_input_as_handled()


func _run_step(step: Dictionary) -> void:
	match str(step.get("type", "")):
		"background":
			var key := str(step.get("value", ""))
			var path := _background_path(key)
			if not path.is_empty():
				var tex := Assets.tex(path)
				if tex != null:
					_bg.texture = tex
		"caption":
			UI.start_dialogue([str(step.get("text", ""))], str(step.get("speaker", "")))
			await _wait(float(step.get("hold", 3.0)), true)
			if UI.dialogue_open:
				UI.close_dialogue()
		"wait":
			await _wait(float(step.get("dur", 1.0)), true)
		"fade":
			var target := clampf(float(step.get("to", 1.0)), 0.0, 1.0)
			await UI.fade_to(target, float(step.get("dur", 0.5)))
		"tint":
			_tween_tint(float(step.get("gray", 0.0)), str(step.get("tint", "#ffffff")),
					float(step.get("amount", 0.0)), float(step.get("dur", 1.0)))
			if step.has("dur"):
				await _wait(float(step["dur"]), false)
		"flash":
			await UI.flash(float(step.get("dur", 0.3)))
		"sprite":
			var who := str(step.get("who", "arjun"))
			if who == "arjun" and _sprite != null:
				_sprite.visible = bool(step.get("visible", true))
				if step.has("x") and step.has("y"):
					_sprite.position = Vector2(float(step["x"]), float(step["y"]))
				if step.has("anim"):
					_sprite.play(str(step["anim"]))
		"move":
			if _sprite != null and step.has("x") and step.has("y"):
				var tw := create_tween()
				tw.tween_property(_sprite, "position",
						Vector2(float(step["x"]), float(step["y"])),
						float(step.get("dur", 1.0)))
				await tw.finished
		"shake":
			await _shake(float(step.get("dur", 0.5)), float(step.get("amp", 6.0)))
		"title":
			if _title != null:
				_title.visible = bool(step.get("visible", true))
		"end":
			pass  # loop ends naturally
		_:
			push_warning("[Cutscene] unknown step type: " + str(step.get("type")))
	step_finished.emit(step)


## Frame-based wait that aborts on skip and can end early on `advance`
## (E/Space) — no awaited timer can outlive a skip (spec §4).
func _wait(duration: float, advanceable: bool) -> void:
	var elapsed := 0.0
	while elapsed < duration and not skipped:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if advanceable and Input.is_action_just_pressed("advance"):
			return


func _tween_tint(gray: float, tint_hex: String, amount: float, dur: float) -> void:
	if _tint == null or _tint.material == null:
		return
	var mat := _tint.material as ShaderMaterial
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("gray", v),
		float(mat.get_shader_parameter("gray")), gray, dur)
	tw.tween_method(
		func(v: float) -> void: mat.set_shader_parameter("tint_amount", v),
		float(mat.get_shader_parameter("tint_amount")), amount, dur)
	mat.set_shader_parameter("tint_color", Color(tint_hex))


func _shake(duration: float, amp: float) -> void:
	var base := _stage_root.position
	var elapsed := 0.0
	while elapsed < duration and not skipped:
		_stage_root.position = base + Vector2(
			randf_range(-amp, amp), randf_range(-amp, amp))
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	_stage_root.position = base
