extends Node
## All screen-space UI in one autoload: fade/flash layers, dialogue + caption
## band (one shared component, spec §4), interaction prompt, HUD, skip hint.
## Built in code on purpose: spec §11 prefers script-built nodes over fragile
## hand-edited .tscn files.

const OPEN_GUARD_MS := 150  # ignore advance presses right after opening (one press = one line)

var layer: CanvasLayer
var fade_rect: ColorRect
var flash_rect: ColorRect
var dialogue_panel: PanelContainer
var speaker_label: Label
var text_label: Label
var prompt_label: Label
var skip_label: Label
var hud_panel: PanelContainer
var hud_hearts: HBoxContainer

var dialogue_open: bool = false
var cutscene_caption: bool = false

var _lines: Array[String] = []
var _line_index: int = 0
var _speaker: String = ""
var _opened_at_ms: int = 0
var _fade_tween: Tween
var _pause_panel: PanelContainer
var paused: bool = false
signal dialogue_finished(speaker: String)


func _ready() -> void:
	# ALWAYS so fades, dialogue and pause react even while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	fade_rect = _fullscreen_rect(Color(0, 0, 0, 0))
	flash_rect = _fullscreen_rect(Color(1, 1, 1, 0))
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# HUD (top-left): placeholder heart blocks, no art needed.
	hud_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	hud_panel.add_theme_stylebox_override("panel", style)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud_box := HBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 4)
	hud_hearts = HBoxContainer.new()
	hud_hearts.add_theme_constant_override("separation", 3)
	hud_box.add_child(hud_hearts)
	hud_panel.add_child(hud_box)
	layer.add_child(hud_panel)
	hud_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_panel.position = Vector2(8, 8)
	GameState.health_changed.connect(_on_health_changed)
	_on_health_changed(GameState.health, GameState.max_health)

	# Dialogue / caption band (bottom).
	dialogue_panel = PanelContainer.new()
	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = Color(0.06, 0.07, 0.11, 0.92)
	dstyle.border_color = Color(0.75, 0.78, 0.85, 0.6)
	dstyle.set_border_width_all(2)
	dstyle.set_corner_radius_all(6)
	dstyle.set_content_margin_all(10)
	dialogue_panel.add_theme_stylebox_override("panel", dstyle)
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 13)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	speaker_label.visible = false
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(speaker_label)
	vbox.add_child(text_label)
	dialogue_panel.add_child(vbox)
	layer.add_child(dialogue_panel)
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = 40
	dialogue_panel.offset_right = -40
	dialogue_panel.offset_top = -120
	dialogue_panel.offset_bottom = -16
	dialogue_panel.visible = false

	# Interaction prompt (above the dialogue band).
	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1, 1, 1))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 4)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.visible = false
	layer.add_child(prompt_label)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.anchor_bottom = 1.0
	prompt_label.offset_top = -160
	prompt_label.offset_bottom = -132

	# Skip hint (top-right, cutscenes).
	skip_label = Label.new()
	skip_label.text = "Enter / Esc — Skip"
	skip_label.add_theme_font_size_override("font_size", 13)
	skip_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	skip_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	skip_label.add_theme_constant_override("outline_size", 4)
	skip_label.visible = false
	layer.add_child(skip_label)
	skip_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_label.offset_left = -220
	skip_label.offset_right = -12
	skip_label.offset_top = 8
	skip_label.offset_bottom = 30
	print("[CHECK] UI ready")


func _fullscreen_rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(r)
	return r


# --- fades / flash -----------------------------------------------------------

func fade_out(duration: float = 0.35) -> void:
	await _fade_to(Color(0, 0, 0, 1), duration)


func fade_in(duration: float = 0.35) -> void:
	await _fade_to(Color(0, 0, 0, 0), duration)


## Generic fade used by cutscene steps (spec §4).
func fade_to(alpha: float, duration: float = 0.35) -> void:
	await _fade_to(Color(0, 0, 0, clampf(alpha, 0.0, 1.0)), duration)


func _fade_to(target: Color, duration: float) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_rect, "color", target, duration)
	await _fade_tween.finished


func flash(duration: float = 0.25) -> void:
	flash_rect.color = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(flash_rect, "color", Color(1, 1, 1, 0), duration)
	await tw.finished


# --- dialogue ----------------------------------------------------------------

## Opens the dialogue band and steps through every line internally.
## One press of `advance` shows exactly one line (input guard below).
func start_dialogue(lines: Array, speaker: String = "") -> void:
	if dialogue_open:
		return
	_lines.clear()
	for entry: Variant in lines:
		_lines.append(str(entry))
	if _lines.is_empty():
		return
	_lines.resize(_lines.size())
	dialogue_open = true
	_line_index = 0
	_speaker = speaker
	_opened_at_ms = Time.get_ticks_msec()
	_render_current_line()
	dialogue_panel.visible = true


func await_dialogue(lines: Array, speaker: String = "") -> void:
	start_dialogue(lines, speaker)
	if dialogue_open:
		await dialogue_finished


func _render_current_line() -> void:
	var line := _lines[_line_index]
	# Lines may carry "Speaker: text" to show a per-line speaker.
	if line.contains(":") and _speaker.is_empty():
		var split := line.split(":", true, 1)
		speaker_label.text = split[0].strip_edges()
		text_label.text = split[1].strip_edges()
		speaker_label.visible = true
	else:
		speaker_label.text = _speaker
		speaker_label.visible = not _speaker.is_empty()
		text_label.text = line
	# Resize band height to content, keep it inside the window.
	dialogue_panel.reset_size()


func _input(event: InputEvent) -> void:
	# Pause toggle (spec §8/§12): Esc, only while nobody else owns input.
	if event.is_action_pressed("pause") and not dialogue_open and not cutscene_caption:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if not dialogue_open:
		return
	if event.is_action_pressed("advance"):
		if Time.get_ticks_msec() - _opened_at_ms < OPEN_GUARD_MS:
			return  # same press that opened the dialogue must not advance it
		_line_index += 1
		_opened_at_ms = Time.get_ticks_msec()  # also rate-limits held keys
		if _line_index >= _lines.size():
			close_dialogue()
		else:
			_render_current_line()
		get_viewport().set_input_as_handled()


func close_dialogue() -> void:
	if not dialogue_open:
		return
	dialogue_open = false
	dialogue_panel.visible = false
	_lines.clear()
	dialogue_finished.emit(_speaker)


# --- prompt / skip hint / HUD ------------------------------------------------

func show_prompt(text: String) -> void:
	if prompt_label.text != text:
		prompt_label.text = text
	prompt_label.visible = not dialogue_open


func hide_prompt() -> void:
	prompt_label.visible = false


func show_skip_hint(visible_flag: bool) -> void:
	skip_label.visible = visible_flag


func _on_health_changed(hp: int, max_hp: int) -> void:
	for child: Node in hud_hearts.get_children():
		child.queue_free()
	for i: int in range(max_hp):
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(14, 14)
		heart.color = Color(0.95, 0.25, 0.3) if i < hp else Color(0.25, 0.25, 0.28)
		hud_hearts.add_child(heart)
	hud_panel.visible = max_hp > 0 and not cutscene_caption


## Cutscenes hide gameplay HUD (spec §4 palette/clean scenes).
func set_hud_visible(v: bool) -> void:
	hud_panel.visible = v


func toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	if paused:
		if _pause_panel == null:
			_pause_panel = PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.05, 0.06, 0.1, 0.95)
			style.border_color = Color(0.75, 0.78, 0.85, 0.6)
			style.set_border_width_all(2)
			style.set_corner_radius_all(6)
			style.set_content_margin_all(16)
			_pause_panel.add_theme_stylebox_override("panel", style)
			var box := VBoxContainer.new()
			box.add_theme_constant_override("separation", 8)
			var head := Label.new()
			head.text = "PAUSED"
			head.add_theme_font_size_override("font_size", 22)
			head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var hint := Label.new()
			hint.text = "Esc — Resume\nWASD/Arrows — Move   Q — Attack   E — Interact"
			hint.add_theme_font_size_override("font_size", 14)
			hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(head)
			box.add_child(hint)
			_pause_panel.add_child(box)
			layer.add_child(_pause_panel)
			_pause_panel.set_anchors_preset(Control.PRESET_CENTER)
		_pause_panel.visible = true
		_pause_panel.reset_size()
	else:
		if _pause_panel != null:
			_pause_panel.visible = false
