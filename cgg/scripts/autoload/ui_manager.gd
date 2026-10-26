extends Node
## All screen-space UI in one autoload: fade/flash layers, dialogue + caption
## band, interaction prompt, HUD, Minecraft-style hotbar, Bag (Inventory) modal,
## and item pickup toast banners.
## Built cleanly in code for maximum reliability and responsive anchoring.

const OPEN_GUARD_MS := 150

var layer: CanvasLayer
var root_ui: Control
var fade_rect: ColorRect
var flash_rect: ColorRect

# Dialogue
var dialogue_panel: PanelContainer
var speaker_badge: PanelContainer
var speaker_label: Label
var text_label: Label
var advance_hint: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var skip_label: Label
var hud_panel: PanelContainer
var hud_hearts: HBoxContainer

# Minecraft-style Hotbar (Bottom-center, slots 1-5)
var hotbar_panel: PanelContainer
var hotbar_slots: Array[PanelContainer] = []
var hotbar_icons: Array[Label] = []
var hotbar_nums: Array[Label] = []
var hotbar_tooltip: Label

# Bag (Inventory Modal toggled by 'B')
var bag_modal: PanelContainer
var bag_open: bool = false
var bag_grid: GridContainer
var bag_slots: Array[PanelContainer] = []
var inspect_icon: Label
var inspect_title: Label
var inspect_badge: Label
var inspect_desc: Label

# Item Pickup Toast Banner
var toast_panel: PanelContainer
var toast_label: Label
var _toast_tween: Tween

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
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root_ui)

	fade_rect = _fullscreen_rect(Color(0, 0, 0, 0))
	flash_rect = _fullscreen_rect(Color(1, 1, 1, 0))
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_hud()
	_build_hotbar()
	_build_dialogue()
	_build_prompt()
	_build_bag_modal()
	_build_toast()
	_build_skip_hint()

	GameState.health_changed.connect(_on_health_changed)
	GameState.hotbar_changed.connect(_on_hotbar_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)

	_on_health_changed(GameState.health, GameState.max_health)
	_update_hotbar_ui()
	_update_bag_ui()

	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	print("[CHECK] UI ready with Hotbar and Bag")


func _fullscreen_rect(c: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = c
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(r)
	return r


# --- HUD (Health Hearts + Satchel Key Hint) -----------------------------------

func _build_hud() -> void:
	hud_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.8)
	style.border_color = Color(0.3, 0.35, 0.45, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	hud_panel.add_theme_stylebox_override("panel", style)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)

	var hud_box := HBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 4)
	hud_hearts = HBoxContainer.new()
	hud_hearts.add_theme_constant_override("separation", 3)
	hud_box.add_child(hud_hearts)
	vbox.add_child(hud_box)

	var bag_hint := Label.new()
	bag_hint.text = "🎒 [B] Bag"
	bag_hint.add_theme_font_size_override("font_size", 11)
	bag_hint.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6, 0.9))
	vbox.add_child(bag_hint)

	hud_panel.add_child(vbox)
	root_ui.add_child(hud_panel)
	hud_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_panel.position = Vector2(10, 10)


# --- Minecraft-style Hotbar (Vertical on Right Side) -------------------------

func _build_hotbar() -> void:
	hotbar_panel = PanelContainer.new()
	var hstyle := StyleBoxFlat.new()
	hstyle.bg_color = Color(0.05, 0.06, 0.10, 0.88)
	hstyle.border_color = Color(0.40, 0.45, 0.58, 0.85)
	hstyle.set_border_width_all(2)
	hstyle.set_corner_radius_all(8)
	hstyle.content_margin_left = 6
	hstyle.content_margin_right = 6
	hstyle.content_margin_top = 6
	hstyle.content_margin_bottom = 6
	hstyle.shadow_color = Color(0, 0, 0, 0.5)
	hstyle.shadow_size = 6
	hotbar_panel.add_theme_stylebox_override("panel", hstyle)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 5)

	# Active Item Name Tooltip Label (compact & autowrapped)
	hotbar_tooltip = Label.new()
	hotbar_tooltip.text = "Hero's Blade"
	hotbar_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotbar_tooltip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hotbar_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hotbar_tooltip.custom_minimum_size = Vector2(50, 24)
	hotbar_tooltip.add_theme_font_size_override("font_size", 9)
	hotbar_tooltip.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	hotbar_tooltip.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	hotbar_tooltip.add_theme_constant_override("outline_size", 2)
	col.add_child(hotbar_tooltip)

	# Vertical list of 5 item slots
	var slots_vbox := VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 5)

	hotbar_slots.clear()
	hotbar_icons.clear()
	hotbar_nums.clear()

	for i: int in range(5):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(44, 44)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		var sstyle := _make_hotbar_slot_style(i == GameState.active_hotbar_index)
		slot.add_theme_stylebox_override("panel", sstyle)

		# Slot index number in top-left
		var num := Label.new()
		num.text = str(i + 1)
		num.add_theme_font_size_override("font_size", 9)
		num.add_theme_color_override("font_color", Color(0.75, 0.75, 0.82, 0.8))
		num.position = Vector2(3, 1)
		slot.add_child(num)

		# Item Icon in center
		var icon := Label.new()
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.add_theme_font_size_override("font_size", 20)
		slot.add_child(icon)

		# Click event on slot
		var slot_idx: int = i
		slot.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				GameState.select_hotbar_slot(slot_idx)
				AudioManager.play_select()
		)

		slots_vbox.add_child(slot)
		hotbar_slots.append(slot)
		hotbar_icons.append(icon)
		hotbar_nums.append(num)

	col.add_child(slots_vbox)

	# Bag shortcut hint at bottom
	var bag_hint := Label.new()
	bag_hint.text = "[B] Bag"
	bag_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_hint.add_theme_font_size_override("font_size", 9)
	bag_hint.add_theme_color_override("font_color", Color(0.7, 0.76, 0.88, 0.85))
	bag_hint.mouse_filter = Control.MOUSE_FILTER_STOP
	bag_hint.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			toggle_bag()
	)
	col.add_child(bag_hint)

	hotbar_panel.add_child(col)
	root_ui.add_child(hotbar_panel)

	# Anchor Vertically to Right Center
	hotbar_panel.anchor_left = 1.0
	hotbar_panel.anchor_right = 1.0
	hotbar_panel.anchor_top = 0.5
	hotbar_panel.anchor_bottom = 0.5
	hotbar_panel.offset_left = -70.0
	hotbar_panel.offset_right = -10.0
	hotbar_panel.offset_top = -155.0
	hotbar_panel.offset_bottom = 155.0


func _make_hotbar_slot_style(is_active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if is_active:
		s.bg_color = Color(0.18, 0.20, 0.32, 0.95)
		s.border_color = Color(1.0, 0.84, 0.28, 1.0)
		s.set_border_width_all(2)
		s.shadow_color = Color(1.0, 0.85, 0.3, 0.4)
		s.shadow_size = 4
	else:
		s.bg_color = Color(0.08, 0.10, 0.15, 0.85)
		s.border_color = Color(0.28, 0.32, 0.42, 0.75)
		s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s


func _update_hotbar_ui() -> void:
	for i: int in range(hotbar_slots.size()):
		var is_active := (i == GameState.active_hotbar_index)
		hotbar_slots[i].add_theme_stylebox_override("panel", _make_hotbar_slot_style(is_active))
		var item_id := GameState.hotbar[i] if i < GameState.hotbar.size() else ""
		if item_id.is_empty():
			hotbar_icons[i].text = ""
		else:
			var info: Dictionary = GameState.get_item_info(item_id)
			hotbar_icons[i].text = str(info.get("icon", "📦"))

	var active_item_id: String = GameState.get_active_item()
	if active_item_id.is_empty():
		hotbar_tooltip.text = "[%d] Empty" % [GameState.active_hotbar_index + 1]
	else:
		var info: Dictionary = GameState.get_item_info(active_item_id)
		hotbar_tooltip.text = str(info.get("name", active_item_id))


func _on_hotbar_changed(_idx: int) -> void:
	_update_hotbar_ui()


# --- Dialogue Window (Fixed Bottom Anchored, Strict 124px Height) -------------

func _build_dialogue() -> void:
	dialogue_panel = PanelContainer.new()
	var dstyle := StyleBoxFlat.new()
	dstyle.bg_color = Color(0.07, 0.09, 0.14, 0.96)
	dstyle.border_color = Color(0.85, 0.72, 0.38, 0.95)
	dstyle.set_border_width_all(2)
	dstyle.set_corner_radius_all(8)
	dstyle.content_margin_left = 18
	dstyle.content_margin_right = 18
	dstyle.content_margin_top = 10
	dstyle.content_margin_bottom = 10
	dstyle.shadow_color = Color(0, 0, 0, 0.7)
	dstyle.shadow_size = 8
	dialogue_panel.add_theme_stylebox_override("panel", dstyle)
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Speaker Badge
	speaker_badge = PanelContainer.new()
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0.18, 0.16, 0.28, 0.95)
	bstyle.border_color = Color(0.92, 0.80, 0.45, 0.95)
	bstyle.set_border_width_all(1)
	bstyle.set_corner_radius_all(4)
	bstyle.content_margin_left = 10
	bstyle.content_margin_right = 10
	bstyle.content_margin_top = 2
	bstyle.content_margin_bottom = 2
	speaker_badge.add_theme_stylebox_override("panel", bstyle)
	speaker_badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 14)
	speaker_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	speaker_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	speaker_label.add_theme_constant_override("outline_size", 2)
	speaker_badge.add_child(speaker_label)
	vbox.add_child(speaker_badge)
	speaker_badge.visible = false

	# Text Label
	text_label = Label.new()
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.98))
	text_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	text_label.add_theme_constant_override("outline_size", 3)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.max_lines_visible = 3
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(text_label)

	# Advance Hint
	advance_hint = Label.new()
	advance_hint.text = "▼ Press [E / Space / Click] to continue"
	advance_hint.add_theme_font_size_override("font_size", 12)
	advance_hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.65, 0.85))
	advance_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	advance_hint.add_theme_constant_override("outline_size", 2)
	advance_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(advance_hint)

	dialogue_panel.add_child(vbox)
	root_ui.add_child(dialogue_panel)
	dialogue_panel.visible = false

	_layout_dialogue()


func _layout_dialogue() -> void:
	if dialogue_panel == null or not is_inside_tree():
		return
	var vp_size := get_viewport().get_visible_rect().size
	var panel_w: float = minf(vp_size.x - 80.0, 840.0)
	var half_w: float = panel_w * 0.5

	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -half_w
	dialogue_panel.offset_right = half_w
	dialogue_panel.offset_top = -142.0
	dialogue_panel.offset_bottom = -16.0
	dialogue_panel.custom_minimum_size = Vector2(panel_w, 126.0)


# --- Interaction Prompt -------------------------------------------------------

func _build_prompt() -> void:
	prompt_panel = PanelContainer.new()
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.08, 0.10, 0.16, 0.92)
	pstyle.border_color = Color(0.92, 0.80, 0.45, 0.9)
	pstyle.set_border_width_all(1)
	pstyle.set_corner_radius_all(6)
	pstyle.content_margin_left = 14
	pstyle.content_margin_right = 14
	pstyle.content_margin_top = 5
	pstyle.content_margin_bottom = 5
	pstyle.shadow_color = Color(0, 0, 0, 0.5)
	pstyle.shadow_size = 4
	prompt_panel.add_theme_stylebox_override("panel", pstyle)
	prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 3)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_panel.add_child(prompt_label)
	root_ui.add_child(prompt_panel)
	prompt_panel.visible = false
	_layout_prompt()


func _layout_prompt() -> void:
	if prompt_panel == null or not is_inside_tree():
		return
	var vp_size := get_viewport().get_visible_rect().size
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.reset_size()
	var pw: float = prompt_panel.size.x
	var half_w: float = maxf(pw * 0.5, 120.0)
	prompt_panel.offset_left = -half_w
	prompt_panel.offset_right = half_w
	prompt_panel.offset_top = -186.0
	prompt_panel.offset_bottom = -150.0


# --- Adventurer's Bag (Inventory Modal at 'B') --------------------------------

func _build_bag_modal() -> void:
	bag_modal = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.13, 0.96)
	style.border_color = Color(0.85, 0.72, 0.38, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 14
	bag_modal.add_theme_stylebox_override("panel", style)
	bag_modal.custom_minimum_size = Vector2(560, 360)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)

	# Header bar: Title + [X] Button
	var head_bar := HBoxContainer.new()
	var title := Label.new()
	title.text = "🎒 ADVENTURER'S SATCHEL"
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("outline_size", 3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_bar.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.pressed.connect(func() -> void: toggle_bag(false))
	head_bar.add_child(close_btn)
	main_vbox.add_child(head_bar)

	# Subtitle instructions
	var sub := Label.new()
	sub.text = "Press [B] or [Esc] to Close • Click an item to inspect lore"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85, 0.8))
	main_vbox.add_child(sub)

	# Body: 2 Columns (Left: Inventory Grid, Right: Item Inspector)
	var body_hbox := HBoxContainer.new()
	body_hbox.add_theme_constant_override("separation", 16)
	body_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Left: 4 columns x 3 rows = 12 slots grid
	bag_grid = GridContainer.new()
	bag_grid.columns = 4
	bag_grid.add_theme_constant_override("h_separation", 6)
	bag_grid.add_theme_constant_override("v_separation", 6)
	bag_slots.clear()

	for i: int in range(12):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(54, 54)
		var sstyle := StyleBoxFlat.new()
		sstyle.bg_color = Color(0.10, 0.12, 0.18, 0.9)
		sstyle.border_color = Color(0.28, 0.32, 0.44, 0.8)
		sstyle.set_border_width_all(1)
		sstyle.set_corner_radius_all(6)
		slot.add_theme_stylebox_override("panel", sstyle)

		var icon := Label.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 24)
		slot.add_child(icon)

		var slot_idx: int = i
		slot.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if slot_idx < GameState.inventory.size():
					_inspect_item(GameState.inventory[slot_idx])
					AudioManager.play_select()
		)

		bag_grid.add_child(slot)
		bag_slots.append(slot)

	body_hbox.add_child(bag_grid)

	# Right: Item Inspector Panel
	var inspect_panel := PanelContainer.new()
	inspect_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ip_style := StyleBoxFlat.new()
	ip_style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	ip_style.border_color = Color(0.35, 0.40, 0.52, 0.7)
	ip_style.set_border_width_all(1)
	ip_style.set_corner_radius_all(6)
	ip_style.content_margin_left = 12
	ip_style.content_margin_right = 12
	ip_style.content_margin_top = 10
	ip_style.content_margin_bottom = 10
	inspect_panel.add_theme_stylebox_override("panel", ip_style)

	var ivbox := VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 6)

	inspect_icon = Label.new()
	inspect_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_icon.add_theme_font_size_override("font_size", 36)
	ivbox.add_child(inspect_icon)

	inspect_title = Label.new()
	inspect_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_title.add_theme_font_size_override("font_size", 16)
	inspect_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	ivbox.add_child(inspect_title)

	inspect_badge = Label.new()
	inspect_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inspect_badge.add_theme_font_size_override("font_size", 11)
	inspect_badge.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	ivbox.add_child(inspect_badge)

	inspect_desc = Label.new()
	inspect_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_desc.add_theme_font_size_override("font_size", 13)
	inspect_desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	inspect_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ivbox.add_child(inspect_desc)

	inspect_panel.add_child(ivbox)
	body_hbox.add_child(inspect_panel)
	main_vbox.add_child(body_hbox)

	bag_modal.add_child(main_vbox)
	root_ui.add_child(bag_modal)
	bag_modal.visible = false

	# Center Modal
	bag_modal.set_anchors_preset(Control.PRESET_CENTER)


func toggle_bag(force_val: Variant = null) -> void:
	if dialogue_open:
		return
	if force_val is bool:
		bag_open = force_val
	else:
		bag_open = not bag_open

	bag_modal.visible = bag_open
	if bag_open:
		AudioManager.play_select()
		_update_bag_ui()
		# Inspect the first item by default
		if not GameState.inventory.is_empty():
			_inspect_item(GameState.inventory[0])
		else:
			_inspect_empty()


func _update_bag_ui() -> void:
	for i: int in range(bag_slots.size()):
		var icon_label: Label = bag_slots[i].get_child(0) as Label
		if i < GameState.inventory.size():
			var item_id: String = GameState.inventory[i]
			var info: Dictionary = GameState.get_item_info(item_id)
			icon_label.text = str(info.get("icon", "📦"))
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.14, 0.16, 0.24, 0.95)
			s.border_color = Color(0.85, 0.72, 0.38, 0.8)
			s.set_border_width_all(1)
			s.set_corner_radius_all(6)
			bag_slots[i].add_theme_stylebox_override("panel", s)
		else:
			icon_label.text = ""
			var s := StyleBoxFlat.new()
			s.bg_color = Color(0.08, 0.10, 0.14, 0.6)
			s.border_color = Color(0.2, 0.23, 0.3, 0.5)
			s.set_border_width_all(1)
			s.set_corner_radius_all(6)
			bag_slots[i].add_theme_stylebox_override("panel", s)


func _inspect_item(item_id: String) -> void:
	var info: Dictionary = GameState.get_item_info(item_id)
	inspect_icon.text = str(info.get("icon", "📦"))
	inspect_title.text = str(info.get("name", item_id))
	inspect_badge.text = "◆ " + str(info.get("type", "Item")).to_upper() + " ◆"
	inspect_desc.text = str(info.get("desc", "A curious adventure item."))


func _inspect_empty() -> void:
	inspect_icon.text = "🎒"
	inspect_title.text = "Empty Satchel"
	inspect_badge.text = "No items yet"
	inspect_desc.text = "Explore the forest, complete quests, and vanquish monsters to collect tools, relics, and treasures."


func _on_inventory_changed() -> void:
	_update_bag_ui()
	_update_hotbar_ui()


# --- Floating Item Toast Banner -----------------------------------------------

func _build_toast() -> void:
	toast_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.20, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 8
	toast_panel.add_theme_stylebox_override("panel", style)

	toast_label = Label.new()
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	toast_label.add_theme_constant_override("outline_size", 2)
	toast_panel.add_child(toast_label)

	root_ui.add_child(toast_panel)
	toast_panel.visible = false
	toast_panel.anchor_left = 0.5
	toast_panel.anchor_right = 0.5
	toast_panel.anchor_top = 0.0
	toast_panel.anchor_bottom = 0.0


func show_toast(text: String, duration: float = 3.0) -> void:
	toast_label.text = text
	toast_panel.reset_size()
	var half_w: float = toast_panel.size.x * 0.5
	toast_panel.offset_left = -half_w
	toast_panel.offset_right = half_w
	toast_panel.offset_top = 24.0
	toast_panel.offset_bottom = 24.0 + toast_panel.size.y
	toast_panel.modulate.a = 0.0
	toast_panel.visible = true

	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.35)
	_toast_tween.tween_callback(func() -> void: toast_panel.visible = false)


# --- Skip Hint ----------------------------------------------------------------

func _build_skip_hint() -> void:
	skip_label = Label.new()
	skip_label.text = "Enter / Esc — Skip"
	skip_label.add_theme_font_size_override("font_size", 13)
	skip_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	skip_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	skip_label.add_theme_constant_override("outline_size", 4)
	skip_label.visible = false
	root_ui.add_child(skip_label)
	skip_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_label.offset_left = -220
	skip_label.offset_right = -12
	skip_label.offset_top = 8
	skip_label.offset_bottom = 30


func _on_viewport_size_changed() -> void:
	_layout_dialogue()
	if prompt_panel != null and prompt_panel.visible:
		_layout_prompt()


# --- Fades / Flash -----------------------------------------------------------

func fade_out(duration: float = 0.35) -> void:
	await _fade_to(Color(0, 0, 0, 1), duration)


func fade_in(duration: float = 0.35) -> void:
	await _fade_to(Color(0, 0, 0, 0), duration)


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


# --- Dialogue Flow -----------------------------------------------------------

func start_dialogue(lines: Array, speaker: String = "") -> void:
	if dialogue_open:
		return
	_lines.clear()
	for entry: Variant in lines:
		_lines.append(str(entry))
	if _lines.is_empty():
		return
	hide_prompt()
	if bag_open:
		toggle_bag(false)
	dialogue_open = true
	_line_index = 0
	_speaker = speaker
	_opened_at_ms = Time.get_ticks_msec()
	_render_current_line()
	dialogue_panel.visible = true
	hotbar_panel.visible = false  # Hide hotbar during dialogue so screen is crystal clean
	AudioManager.play_select()


func await_dialogue(lines: Array, speaker: String = "") -> void:
	start_dialogue(lines, speaker)
	if dialogue_open:
		await dialogue_finished


func _render_current_line() -> void:
	var line := _lines[_line_index]
	var current_spk := _speaker
	if line.contains(":") and _speaker.is_empty():
		var split := line.split(":", true, 1)
		current_spk = split[0].strip_edges()
		text_label.text = split[1].strip_edges()
	else:
		text_label.text = line

	if current_spk.is_empty():
		speaker_badge.visible = false
	else:
		speaker_label.text = current_spk
		speaker_badge.visible = true

	if _line_index == _lines.size() - 1:
		advance_hint.text = "✓ [E / Space / Click] to Close"
	else:
		advance_hint.text = "▼ [E / Space / Click] to Continue (%d/%d)" % [_line_index + 1, _lines.size()]

	_layout_dialogue()


func close_dialogue() -> void:
	if not dialogue_open:
		return
	dialogue_open = false
	dialogue_panel.visible = false
	hotbar_panel.visible = true  # Restore hotbar
	_lines.clear()
	AudioManager.play_select()
	dialogue_finished.emit(_speaker)


# --- Input Handling -----------------------------------------------------------

func _input(event: InputEvent) -> void:
	# Bag Toggle ('B')
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		if not dialogue_open and not cutscene_caption:
			toggle_bag()
			get_viewport().set_input_as_handled()
			return

	# If Bag is open, Esc closes Bag
	if bag_open and (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE)):
		toggle_bag(false)
		get_viewport().set_input_as_handled()
		return

	# Hotbar number keys 1 to 5
	if not dialogue_open and not bag_open and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			GameState.select_hotbar_slot(0)
			AudioManager.play_select()
		elif event.keycode == KEY_2:
			GameState.select_hotbar_slot(1)
			AudioManager.play_select()
		elif event.keycode == KEY_3:
			GameState.select_hotbar_slot(2)
			AudioManager.play_select()
		elif event.keycode == KEY_4:
			GameState.select_hotbar_slot(3)
			AudioManager.play_select()
		elif event.keycode == KEY_5:
			GameState.select_hotbar_slot(4)
			AudioManager.play_select()

	# Hotbar Mouse Wheel Cycling
	if not dialogue_open and not bag_open and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var prev_slot := (GameState.active_hotbar_index - 1 + 5) % 5
			GameState.select_hotbar_slot(prev_slot)
			AudioManager.play_select()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var next_slot := (GameState.active_hotbar_index + 1) % 5
			GameState.select_hotbar_slot(next_slot)
			AudioManager.play_select()

	# Pause Menu Toggle (Esc)
	if event.is_action_pressed("pause") and not dialogue_open and not cutscene_caption:
		toggle_pause()
		get_viewport().set_input_as_handled()
		return

	# Dialogue Advance
	if dialogue_open:
		var is_adv := event.is_action_pressed("advance")
		var is_click := event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed
		if is_adv or is_click:
			if Time.get_ticks_msec() - _opened_at_ms < OPEN_GUARD_MS:
				return
			_line_index += 1
			_opened_at_ms = Time.get_ticks_msec()
			if _line_index >= _lines.size():
				close_dialogue()
			else:
				AudioManager.play_select()
				_render_current_line()
			get_viewport().set_input_as_handled()


# --- Prompt / Health / Pause -------------------------------------------------

func show_prompt(text: String) -> void:
	if prompt_label.text != text:
		prompt_label.text = text
	prompt_panel.visible = not dialogue_open and not text.is_empty()
	if prompt_panel.visible:
		_layout_prompt()


func hide_prompt() -> void:
	prompt_panel.visible = false


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


func set_hud_visible(v: bool) -> void:
	hud_panel.visible = v
	hotbar_panel.visible = v


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
			hint.text = "Esc — Resume\nWASD/Arrows — Move   Q — Attack   E — Interact   B — Bag   1-5 — Tools"
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
