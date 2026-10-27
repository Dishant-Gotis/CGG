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
var mana_bar: ProgressBar
var mana_label: Label

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

# Game Over Screen
var game_over_panel: PanelContainer
var game_over_open: bool = false

var dialogue_open: bool = false
var dialogue_closed_at_ms: int = 0
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
	_build_game_over_modal()
	_build_toast()
	_build_skip_hint()

	GameState.health_changed.connect(_on_health_changed)
	GameState.mana_changed.connect(_on_mana_changed)
	GameState.hotbar_changed.connect(_on_hotbar_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)

	_on_health_changed(GameState.health, GameState.max_health)
	_on_mana_changed(GameState.mana, GameState.max_mana)
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


# --- HUD (Health Hearts + Mana Bar + Satchel Key Hint) ------------------------

func _build_hud() -> void:
	hud_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 0.88)
	style.border_color = Color(0.35, 0.40, 0.55, 0.75)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 6
	hud_panel.add_theme_stylebox_override("panel", style)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	# Row 1: Health Hearts
	var hearts_box := HBoxContainer.new()
	hearts_box.add_theme_constant_override("separation", 2)
	hud_hearts = HBoxContainer.new()
	hud_hearts.add_theme_constant_override("separation", 3)
	hearts_box.add_child(hud_hearts)
	vbox.add_child(hearts_box)

	# Row 2: Mana Bar (Below the 6 hearts)
	var mana_vbox := VBoxContainer.new()
	mana_vbox.add_theme_constant_override("separation", 2)

	var mana_header := HBoxContainer.new()
	var mana_title := Label.new()
	mana_title.text = "MANA"
	mana_title.add_theme_font_size_override("font_size", 9)
	mana_title.add_theme_color_override("font_color", Color(0.40, 0.80, 1.0, 0.95))
	mana_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	mana_title.add_theme_constant_override("outline_size", 2)
	mana_header.add_child(mana_title)

	mana_label = Label.new()
	mana_label.text = "100/100"
	mana_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mana_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mana_label.add_theme_font_size_override("font_size", 9)
	mana_label.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 0.9))
	mana_header.add_child(mana_label)
	mana_vbox.add_child(mana_header)

	mana_bar = ProgressBar.new()
	mana_bar.custom_minimum_size = Vector2(136, 8)
	mana_bar.max_value = 100.0
	mana_bar.value = 100.0
	mana_bar.show_percentage = false

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.04, 0.07, 0.12, 0.9)
	bar_bg.border_color = Color(0.2, 0.35, 0.55, 0.8)
	bar_bg.set_border_width_all(1)
	bar_bg.set_corner_radius_all(3)
	mana_bar.add_theme_stylebox_override("background", bar_bg)

	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.18, 0.65, 1.0, 0.95)
	bar_fill.border_color = Color(0.65, 0.9, 1.0, 0.8)
	bar_fill.set_border_width_all(1)
	bar_fill.set_corner_radius_all(3)
	mana_bar.add_theme_stylebox_override("fill", bar_fill)

	mana_vbox.add_child(mana_bar)
	vbox.add_child(mana_vbox)

	hud_panel.add_child(vbox)
	root_ui.add_child(hud_panel)
	hud_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hud_panel.position = Vector2(12, 12)


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


# --- Adventurer's Bag (Stardew Valley Rustic Inventory Modal at 'B') ---------

func _build_bag_modal() -> void:
	bag_modal = PanelContainer.new()
	var wood_style := StyleBoxFlat.new()
	wood_style.bg_color = Color(0.99, 0.91, 0.74, 1.0) # Warm Stardew parchment cream
	wood_style.border_color = Color(0.44, 0.22, 0.08, 1.0) # Deep carved wood outer border
	wood_style.set_border_width_all(5)
	wood_style.set_corner_radius_all(10)
	wood_style.content_margin_left = 16
	wood_style.content_margin_right = 16
	wood_style.content_margin_top = 10
	wood_style.content_margin_bottom = 14
	wood_style.shadow_color = Color(0, 0, 0, 0.7)
	wood_style.shadow_size = 16
	bag_modal.add_theme_stylebox_override("panel", wood_style)
	bag_modal.custom_minimum_size = Vector2(670, 440)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 8)

	# 1. Top Bar: Stardew Navigation Tabs + Signature Red Close Button [X]
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 6)

	var tabs_info := [
		["🎒", "Inventory", true],
		["🧑", "Skills", false],
		["❤️", "Social", false],
		["🗺️", "Map", false],
		["🔨", "Crafting", false],
		["⚙️", "Options", false]
	]

	for tab_data: Array in tabs_info:
		var tab_btn := PanelContainer.new()
		tab_btn.custom_minimum_size = Vector2(36, 28)
		var t_style := StyleBoxFlat.new()
		var is_active: bool = bool(tab_data[2])
		if is_active:
			t_style.bg_color = Color(0.85, 0.38, 0.18, 1.0) # Active warm tab
			t_style.border_color = Color(0.44, 0.22, 0.08, 1.0)
		else:
			t_style.bg_color = Color(0.82, 0.68, 0.48, 0.9) # Inactive tab
			t_style.border_color = Color(0.52, 0.36, 0.20, 0.9)
		t_style.set_border_width_all(2)
		t_style.corner_radius_top_left = 6
		t_style.corner_radius_top_right = 6
		t_style.corner_radius_bottom_left = 2
		t_style.corner_radius_bottom_right = 2
		tab_btn.add_theme_stylebox_override("panel", t_style)

		var tab_icon := Label.new()
		tab_icon.text = str(tab_data[0])
		tab_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tab_icon.add_theme_font_size_override("font_size", 14)
		tab_btn.add_child(tab_icon)
		top_bar.add_child(tab_btn)

	var top_spacer := Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	# Stardew Signature Red Square Close Button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(28, 28)
	var cb_style := StyleBoxFlat.new()
	cb_style.bg_color = Color(0.85, 0.26, 0.20, 1.0)
	cb_style.border_color = Color(0.46, 0.12, 0.08, 1.0)
	cb_style.set_border_width_all(2)
	cb_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", cb_style)
	close_btn.add_theme_stylebox_override("hover", cb_style)
	close_btn.add_theme_stylebox_override("pressed", cb_style)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	close_btn.pressed.connect(func() -> void: toggle_bag(false))
	top_bar.add_child(close_btn)
	main_vbox.add_child(top_bar)

	# 2. Upper Section: 36 Stardew Slots (12 Cols x 3 Rows) + Organize & Trash Can
	var upper_hbox := HBoxContainer.new()
	upper_hbox.add_theme_constant_override("separation", 12)

	var grid_vbox := VBoxContainer.new()
	grid_vbox.add_theme_constant_override("separation", 3)

	# Hotbar number headers: 1 2 3 4 5 6 7 8 9 0 - =
	var num_row := HBoxContainer.new()
	num_row.add_theme_constant_override("separation", 4)
	var hotbar_keys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="]
	for k: String in hotbar_keys:
		var n_lbl := Label.new()
		n_lbl.text = k
		n_lbl.custom_minimum_size = Vector2(40, 14)
		n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n_lbl.add_theme_font_size_override("font_size", 9)
		n_lbl.add_theme_color_override("font_color", Color(0.48, 0.32, 0.16, 0.85))
		num_row.add_child(n_lbl)
	grid_vbox.add_child(num_row)

	# 36 Inventory Slots Grid (12 columns x 3 rows)
	bag_grid = GridContainer.new()
	bag_grid.columns = 12
	bag_grid.add_theme_constant_override("h_separation", 4)
	bag_grid.add_theme_constant_override("v_separation", 4)
	bag_slots.clear()

	for i: int in range(36):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(40, 40)
		var sstyle := StyleBoxFlat.new()
		sstyle.bg_color = Color(0.88, 0.77, 0.58, 1.0) # Inset parchment cell
		sstyle.border_color = Color(0.64, 0.48, 0.30, 1.0) # Beveled wood rim
		sstyle.set_border_width_all(2)
		sstyle.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("panel", sstyle)

		var icon := Label.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.add_theme_font_size_override("font_size", 20)
		slot.add_child(icon)

		var slot_idx: int = i
		slot.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				if slot_idx < GameState.inventory.size():
					_inspect_item(GameState.inventory[slot_idx])
				else:
					_inspect_empty()
				AudioManager.play_select()
		)

		bag_grid.add_child(slot)
		bag_slots.append(slot)

	grid_vbox.add_child(bag_grid)
	upper_hbox.add_child(grid_vbox)

	# Right Side: Organize Button + Stardew Purple Trash Can
	var side_tools := VBoxContainer.new()
	side_tools.add_theme_constant_override("separation", 10)

	var org_btn := Button.new()
	org_btn.text = "📋"
	org_btn.tooltip_text = "Organize Satchel"
	org_btn.custom_minimum_size = Vector2(36, 36)
	var org_style := StyleBoxFlat.new()
	org_style.bg_color = Color(0.88, 0.74, 0.52, 1.0)
	org_style.border_color = Color(0.55, 0.36, 0.18, 1.0)
	org_style.set_border_width_all(2)
	org_style.set_corner_radius_all(6)
	org_btn.add_theme_stylebox_override("normal", org_style)
	org_btn.add_theme_stylebox_override("hover", org_style)
	org_btn.pressed.connect(func() -> void:
		GameState.inventory.sort()
		_update_bag_ui()
		AudioManager.play_select()
	)
	side_tools.add_child(org_btn)

	var side_spacer := Control.new()
	side_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_tools.add_child(side_spacer)

	# Stardew Purple Trash Can
	var trash_btn := Button.new()
	trash_btn.text = "🗑️"
	trash_btn.tooltip_text = "Trash Can"
	trash_btn.custom_minimum_size = Vector2(38, 44)
	var tr_style := StyleBoxFlat.new()
	tr_style.bg_color = Color(0.48, 0.35, 0.65, 1.0) # Stardew purple trash can body
	tr_style.border_color = Color(0.28, 0.18, 0.42, 1.0)
	tr_style.set_border_width_all(2)
	tr_style.set_corner_radius_all(6)
	trash_btn.add_theme_stylebox_override("normal", tr_style)
	trash_btn.add_theme_stylebox_override("hover", tr_style)
	trash_btn.pressed.connect(func() -> void:
		UI.show_toast("🗑️ Discard items by selecting and tossing into the trash can.")
		AudioManager.play_select()
	)
	side_tools.add_child(trash_btn)
	upper_hbox.add_child(side_tools)
	main_vbox.add_child(upper_hbox)

	# 3. Carved Wood Divider Bar
	var div := PanelContainer.new()
	div.custom_minimum_size = Vector2(0, 4)
	var div_style := StyleBoxFlat.new()
	div_style.bg_color = Color(0.55, 0.32, 0.14, 1.0)
	div_style.border_color = Color(0.82, 0.60, 0.32, 1.0)
	div_style.border_width_top = 1
	div_style.border_width_bottom = 1
	div.add_theme_stylebox_override("panel", div_style)
	main_vbox.add_child(div)

	# 4. Lower Section: Character Portrait & Equipment + Farm / Lore Showcase
	var lower_hbox := HBoxContainer.new()
	lower_hbox.add_theme_constant_override("separation", 14)
	lower_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Left Column: Equipment Slots + Character Portrait
	var equip_hbox := HBoxContainer.new()
	equip_hbox.add_theme_constant_override("separation", 6)

	# Left Accessory Column (Ring 1, Ring 2, Boots)
	var left_acc := VBoxContainer.new()
	left_acc.add_theme_constant_override("separation", 4)
	for acc_icon: String in ["💍", "💎", "👢"]:
		var acc_slot := PanelContainer.new()
		acc_slot.custom_minimum_size = Vector2(32, 32)
		var as_style := StyleBoxFlat.new()
		as_style.bg_color = Color(0.84, 0.72, 0.52, 1.0)
		as_style.border_color = Color(0.60, 0.44, 0.28, 1.0)
		as_style.set_border_width_all(2)
		as_style.set_corner_radius_all(4)
		acc_slot.add_theme_stylebox_override("panel", as_style)
		var a_lbl := Label.new()
		a_lbl.text = acc_icon
		a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		a_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		a_lbl.add_theme_font_size_override("font_size", 14)
		acc_slot.add_child(a_lbl)
		left_acc.add_child(acc_slot)
	equip_hbox.add_child(left_acc)

	# Center: Framed Character Portrait (Stardew Meadow & Arjun Avatar)
	var port_vbox := VBoxContainer.new()
	port_vbox.add_theme_constant_override("separation", 2)

	var port_frame := PanelContainer.new()
	port_frame.custom_minimum_size = Vector2(74, 82)
	var pf_style := StyleBoxFlat.new()
	pf_style.bg_color = Color(0.48, 0.72, 0.94, 1.0) # Sky background
	pf_style.border_color = Color(0.44, 0.22, 0.08, 1.0) # Wooden portrait frame
	pf_style.set_border_width_all(3)
	pf_style.set_corner_radius_all(6)
	port_frame.add_theme_stylebox_override("panel", pf_style)

	var port_inner := VBoxContainer.new()
	port_inner.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Meadow grass bottom layer in portrait
	var grass_strip := ColorRect.new()
	grass_strip.color = Color(0.35, 0.75, 0.35, 0.9)
	grass_strip.custom_minimum_size = Vector2(0, 24)

	# Player Avatar (Arjun's front idle frame from Tiny Swords)
	var avatar := TextureRect.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var atlas_tex := AtlasTexture.new()
	var player_sheet: Texture2D = load("res://Tiny Swords (Update 010)/characters/player.png") as Texture2D
	if player_sheet != null:
		atlas_tex.atlas = player_sheet
		atlas_tex.region = Rect2(0, 0, 48, 48)
		avatar.texture = atlas_tex
	port_frame.add_child(avatar)
	port_vbox.add_child(port_frame)

	var name_lbl := Label.new()
	name_lbl.text = "Arjun"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.38, 0.20, 0.08, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(1, 0.95, 0.85, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 2)
	port_vbox.add_child(name_lbl)
	equip_hbox.add_child(port_vbox)

	# Right Accessory Column (Hat, Shirt, Pants)
	var right_acc := VBoxContainer.new()
	right_acc.add_theme_constant_override("separation", 4)
	for acc_icon: String in ["🤠", "🥋", "👖"]:
		var acc_slot := PanelContainer.new()
		acc_slot.custom_minimum_size = Vector2(32, 32)
		var as_style := StyleBoxFlat.new()
		as_style.bg_color = Color(0.84, 0.72, 0.52, 1.0)
		as_style.border_color = Color(0.60, 0.44, 0.28, 1.0)
		as_style.set_border_width_all(2)
		as_style.set_corner_radius_all(4)
		acc_slot.add_theme_stylebox_override("panel", as_style)
		var a_lbl := Label.new()
		a_lbl.text = acc_icon
		a_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		a_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		a_lbl.add_theme_font_size_override("font_size", 14)
		acc_slot.add_child(a_lbl)
		right_acc.add_child(acc_slot)
	equip_hbox.add_child(right_acc)
	lower_hbox.add_child(equip_hbox)

	# Right Column: Stardew Valley Farm Stats & Lore Card
	var inspect_panel := PanelContainer.new()
	inspect_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ip_style := StyleBoxFlat.new()
	ip_style.bg_color = Color(0.95, 0.86, 0.68, 1.0) # Inset parchment note
	ip_style.border_color = Color(0.68, 0.50, 0.30, 1.0)
	ip_style.set_border_width_all(2)
	ip_style.set_corner_radius_all(6)
	ip_style.content_margin_left = 14
	ip_style.content_margin_right = 14
	ip_style.content_margin_top = 8
	ip_style.content_margin_bottom = 8
	inspect_panel.add_theme_stylebox_override("panel", ip_style)

	var ivbox := VBoxContainer.new()
	ivbox.add_theme_constant_override("separation", 3)

	var header_hbox := HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 8)

	inspect_icon = Label.new()
	inspect_icon.text = "🏡"
	inspect_icon.add_theme_font_size_override("font_size", 28)
	header_hbox.add_child(inspect_icon)

	var titles_vbox := VBoxContainer.new()
	titles_vbox.add_theme_constant_override("separation", 1)

	inspect_title = Label.new()
	inspect_title.text = "Mossveil Farm & Caverns"
	inspect_title.add_theme_font_size_override("font_size", 15)
	inspect_title.add_theme_color_override("font_color", Color(0.38, 0.18, 0.06, 1.0))
	titles_vbox.add_child(inspect_title)

	inspect_badge = Label.new()
	inspect_badge.text = "◆ ADVENTURE LEVEL 1 • DAY 7 OF FALL ◆"
	inspect_badge.add_theme_font_size_override("font_size", 10)
	inspect_badge.add_theme_color_override("font_color", Color(0.68, 0.36, 0.12, 1.0))
	titles_vbox.add_child(inspect_badge)
	header_hbox.add_child(titles_vbox)
	ivbox.add_child(header_hbox)

	inspect_desc = Label.new()
	inspect_desc.text = "Your Funds: 1,250g\nFarm Value: 387,770g\nDay 7 of Fall, Year 1"
	inspect_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspect_desc.add_theme_font_size_override("font_size", 12)
	inspect_desc.add_theme_color_override("font_color", Color(0.34, 0.18, 0.06, 0.95))
	inspect_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ivbox.add_child(inspect_desc)

	inspect_panel.add_child(ivbox)
	lower_hbox.add_child(inspect_panel)
	main_vbox.add_child(lower_hbox)

	bag_modal.add_child(main_vbox)
	root_ui.add_child(bag_modal)
	bag_modal.visible = false
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
		# Open with Stardew Valley Farm & Character Overview by default
		_inspect_empty()


func _update_bag_ui() -> void:
	for i: int in range(bag_slots.size()):
		var icon_label: Label = bag_slots[i].get_child(0) as Label
		var s := StyleBoxFlat.new()
		s.set_border_width_all(2)
		s.set_corner_radius_all(4)

		if i < GameState.inventory.size():
			var item_id: String = GameState.inventory[i]
			var info: Dictionary = GameState.get_item_info(item_id)
			icon_label.text = str(info.get("icon", "📦"))
			s.bg_color = Color(0.94, 0.84, 0.66, 1.0) # Active slot parchment
			s.border_color = Color(0.68, 0.48, 0.26, 1.0) # Wood border
		else:
			icon_label.text = ""
			s.bg_color = Color(0.88, 0.77, 0.58, 1.0) # Inset empty cell
			s.border_color = Color(0.64, 0.48, 0.30, 0.7)

		bag_slots[i].add_theme_stylebox_override("panel", s)


func _inspect_item(item_id: String) -> void:
	var info: Dictionary = GameState.get_item_info(item_id)
	inspect_icon.text = str(info.get("icon", "📦"))
	inspect_title.text = str(info.get("name", item_id))
	inspect_badge.text = "◆ " + str(info.get("type", "Item")).to_upper() + " ◆"
	inspect_desc.text = str(info.get("desc", "A curious adventure item.")) + "\n\n(Click any empty slot to return to farm overview)"


func _inspect_empty() -> void:
	inspect_icon.text = "🏡"
	inspect_title.text = "Mossveil Farm & Caverns"
	inspect_badge.text = "◆ ADVENTURE LEVEL 1 • DAY 7 OF FALL ◆"
	var relic_status := "✨ Sacred Piece of Elixir recovered!" if GameState.has_item("elixir_shard") else "🗡️ Quest: Explore the Cavern for the Sacred Elixir Shard"
	inspect_desc.text = "Your Funds: 1,250g  •  Farm Value: 387,770g\nVitals: %d/%d Hearts  •  %d/%d MP\n%s\n[Tip: Click any item to inspect lore, or click 📋 to organize]" % [
		GameState.health, GameState.max_health, int(GameState.mana), int(GameState.max_mana), relic_status
	]


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

func start_dialogue(lines: Array, speaker: String = "", force: bool = false) -> void:
	if not force and (dialogue_open or (Time.get_ticks_msec() - dialogue_closed_at_ms < 400)):
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
	dialogue_closed_at_ms = Time.get_ticks_msec()
	dialogue_panel.visible = false
	hotbar_panel.visible = true  # Restore hotbar
	_lines.clear()
	AudioManager.play_select()
	dialogue_finished.emit(_speaker)


# --- Input Handling -----------------------------------------------------------

func _input(event: InputEvent) -> void:
	# If Game Over modal is open, consume all keyboard/gameplay events so they don't leak
	if game_over_open:
		if event is InputEventKey:
			get_viewport().set_input_as_handled()
		return

	# Dialogue Advance & Close (handled with absolute priority)
	if dialogue_open:
		var is_adv: bool = event.is_action_pressed("advance") or event.is_action_pressed("interact")
		if not is_adv and event is InputEventKey:
			var key_ev := event as InputEventKey
			if key_ev.pressed and not key_ev.echo:
				if key_ev.keycode == KEY_E or key_ev.keycode == KEY_SPACE or key_ev.keycode == KEY_ENTER:
					is_adv = true
		var is_click: bool = false
		if event is InputEventMouseButton:
			var mb_ev := event as InputEventMouseButton
			if mb_ev.pressed and mb_ev.button_index == MOUSE_BUTTON_LEFT:
				is_click = true
		if is_adv or is_click:
			get_viewport().set_input_as_handled()
			if Time.get_ticks_msec() - _opened_at_ms < OPEN_GUARD_MS:
				return
			_line_index += 1
			_opened_at_ms = Time.get_ticks_msec()
			if _line_index >= _lines.size():
				close_dialogue()
			else:
				AudioManager.play_select()
				_render_current_line()
			return

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
	var total_hearts: int = maxi(max_hp, 6)
	for i: int in range(total_hearts):
		var heart := Label.new()
		heart.text = "❤️" if i < hp else "🖤"
		heart.add_theme_font_size_override("font_size", 16)
		if i >= hp:
			heart.modulate = Color(0.4, 0.42, 0.5, 0.55)
		else:
			heart.modulate = Color(1.0, 1.0, 1.0, 1.0)
		hud_hearts.add_child(heart)
	hud_panel.visible = max_hp > 0 and not cutscene_caption


func _on_mana_changed(cur_mana: float, max_m: float) -> void:
	if mana_bar != null:
		mana_bar.max_value = max_m
		mana_bar.value = cur_mana
	if mana_label != null:
		mana_label.text = "%d/%d" % [int(round(cur_mana)), int(round(max_m))]


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
			hint.text = "Esc — Resume\nWASD/Arrows — Move   Shift — Sprint   Q — Attack   E — Interact   B — Bag   1-5 — Tools"
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


# --- Game Over Modal Screen ---------------------------------------------------

func _build_game_over_modal() -> void:
	game_over_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.13, 0.96)
	style.border_color = Color(0.85, 0.22, 0.22, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	style.shadow_color = Color(0.8, 0.1, 0.1, 0.35)
	style.shadow_size = 18
	game_over_panel.add_theme_stylebox_override("panel", style)
	game_over_panel.custom_minimum_size = Vector2(440, 290)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)

	# Skull & Header
	var title_lbl := Label.new()
	title_lbl.text = "💀 YOU FELL IN BATTLE"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35, 1.0))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	title_lbl.add_theme_constant_override("outline_size", 4)
	vbox.add_child(title_lbl)

	# Subtitle / Lore
	var sub_lbl := Label.new()
	sub_lbl.text = "The shadows overtook you, but your journey is not finished.\nAll inventory items and relics remain safely in your Satchel."
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.add_theme_font_size_override("font_size", 13)
	sub_lbl.add_theme_color_override("font_color", Color(0.88, 0.85, 0.80, 0.9))
	vbox.add_child(sub_lbl)

	# Divider line
	var sep := HSeparator.new()
	var sep_style := StyleBoxLine.new()
	sep_style.color = Color(0.85, 0.22, 0.22, 0.4)
	sep_style.thickness = 1
	sep.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(sep)

	# Action Buttons Container
	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 10)

	# Option 1: Respawn at Entrance
	var respawn_btn := Button.new()
	respawn_btn.text = "🔄  Respawn at Area Entrance"
	respawn_btn.custom_minimum_size = Vector2(320, 40)
	respawn_btn.add_theme_font_size_override("font_size", 14)
	var r_style := StyleBoxFlat.new()
	r_style.bg_color = Color(0.20, 0.45, 0.28, 0.95)
	r_style.border_color = Color(0.40, 0.85, 0.45, 0.95)
	r_style.set_border_width_all(2)
	r_style.set_corner_radius_all(6)
	respawn_btn.add_theme_stylebox_override("normal", r_style)
	var r_hov := r_style.duplicate() as StyleBoxFlat
	r_hov.bg_color = Color(0.26, 0.58, 0.35, 1.0)
	respawn_btn.add_theme_stylebox_override("hover", r_hov)
	respawn_btn.pressed.connect(_on_respawn_pressed)
	btn_vbox.add_child(respawn_btn)

	# Option 2: Return to Mossveil Village
	var village_btn := Button.new()
	village_btn.text = "🏡  Return to Mossveil Village"
	village_btn.custom_minimum_size = Vector2(320, 40)
	village_btn.add_theme_font_size_override("font_size", 14)
	var v_style := StyleBoxFlat.new()
	v_style.bg_color = Color(0.22, 0.30, 0.48, 0.95)
	v_style.border_color = Color(0.45, 0.65, 0.95, 0.95)
	v_style.set_border_width_all(2)
	v_style.set_corner_radius_all(6)
	village_btn.add_theme_stylebox_override("normal", v_style)
	var v_hov := v_style.duplicate() as StyleBoxFlat
	v_hov.bg_color = Color(0.30, 0.42, 0.65, 1.0)
	village_btn.add_theme_stylebox_override("hover", v_hov)
	village_btn.pressed.connect(_on_village_pressed)
	btn_vbox.add_child(village_btn)

	vbox.add_child(btn_vbox)
	game_over_panel.add_child(vbox)

	root_ui.add_child(game_over_panel)
	game_over_panel.visible = false
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)


func show_game_over() -> void:
	if game_over_open:
		return
	game_over_open = true
	get_tree().paused = true
	AudioManager.play_select()
	if bag_open:
		toggle_bag(false)
	game_over_panel.visible = true
	game_over_panel.reset_size()


func hide_game_over() -> void:
	if not game_over_open:
		return
	game_over_open = false
	game_over_panel.visible = false
	get_tree().paused = false


func _on_respawn_pressed() -> void:
	AudioManager.play_select()
	hide_game_over()
	GameState.set_health(GameState.max_health)
	GameState.set_mana(GameState.max_mana)
	await fade_out(0.3)
	get_tree().reload_current_scene()
	await get_tree().process_frame
	await get_tree().process_frame
	await fade_in(0.3)


func _on_village_pressed() -> void:
	AudioManager.play_select()
	hide_game_over()
	GameState.set_health(GameState.max_health)
	GameState.set_mana(GameState.max_mana)
	SceneManager.change_scene("res://scenes/world.tscn")
