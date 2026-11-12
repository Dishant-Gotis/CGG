extends Node
## Single source of truth for asset paths (spec §6.1: no scattered res:// paths).

const TS := "res://Tiny Swords (Update 010)"
const EVERYTHING := TS + "/everything"
const CHARACTERS := TS + "/characters"

# --- characters -------------------------------------------------------------
const PLAYER_SHEET := CHARACTERS + "/player.png"       # 6x10 grid, 48px frames
const SLIME_SHEET := CHARACTERS + "/slime.png"         # 7x13 grid, 32px frames
const SKELETON_SHEET := CHARACTERS + "/skeleton.png"   # has opaque bg, see MISSING_ASSETS.md

# --- ground / terrain -------------------------------------------------------
const GROUNDS := EVERYTHING + "/grounds.png"           # 40x16 @16px autotile sheet
const WOODEN_GROUND := EVERYTHING + "/wooden_ground.png"

# --- props (named files, verified present) ----------------------------------
const TREE_SHEET := EVERYTHING + "/trees.png"
const BUSH_1 := EVERYTHING + "/bush_1.png"
const BUSH_2 := EVERYTHING + "/bush_2.png"
const BUSH_3 := EVERYTHING + "/bush_3.png"
const STONE_1 := EVERYTHING + "/stone_1.png"
const STONE_2 := EVERYTHING + "/stone_2.png"
const STONE_3 := EVERYTHING + "/stone_3.png"
const HUT := EVERYTHING + "/hut.png"
const HUT_BLUE := EVERYTHING + "/hut_blue.png"
const TOWER := EVERYTHING + "/tower.png"
const TOWER_RED := EVERYTHING + "/tower_red.png"
const MONEY_BAG := EVERYTHING + "/money_bag.png"

# --- npc placeholder art (Tiny Swords units, spec §6.2 allows temporarily) ---
const PAWN_BLUE := TS + "/Factions/Knights/Troops/Pawn/Blue/Pawn_Blue.png"
const WARRIOR_BLUE := TS + "/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png"

# --- generated placeholders (listed in MISSING_ASSETS.md) -------------------
const PLACEHOLDER_DIR := "res://assets/cutscenes"
const PLACEHOLDER_SPRITES := "res://assets/sprites"
const KITSU := PLACEHOLDER_DIR + "/PLACEHOLDER_kitsu.png"
const PROLOGUE_DREAM := PLACEHOLDER_DIR + "/PLACEHOLDER_dream.png"
const PROLOGUE_APARTMENT := PLACEHOLDER_DIR + "/PLACEHOLDER_apartment.png"
const PROLOGUE_OFFICE := PLACEHOLDER_DIR + "/PLACEHOLDER_office.png"
const PROLOGUE_BUS := PLACEHOLDER_DIR + "/PLACEHOLDER_bus.png"
const PROLOGUE_VILLAGE := PLACEHOLDER_DIR + "/PLACEHOLDER_village_gate.png"
const PROLOGUE_ROOM := PLACEHOLDER_DIR + "/PLACEHOLDER_room.png"
const PROLOGUE_SKY := PLACEHOLDER_DIR + "/PLACEHOLDER_castle_sky.png"
const PROLOGUE_VIDEO := EVERYTHING + "/1112_1_.ogv"
const PROLOGUE_BGM := EVERYTHING + "/starlight-arpeggio.mp3"
const PROLOGUE_TRANSITION_SFX := EVERYTHING + "/transition.mp3"

# --- Tiny Swords UI Assets --------------------------------------------------
const UI_DIR := TS + "/UI"
const UI_BANNER_HORIZONTAL := UI_DIR + "/Banners/Banner_Horizontal.png"
const UI_BANNER_VERTICAL := UI_DIR + "/Banners/Banner_Vertical.png"
const UI_CARVED_9SLIDES := UI_DIR + "/Banners/Carved_9Slides.png"
const UI_CARVED_3SLIDES := UI_DIR + "/Banners/Carved_3Slides.png"
const UI_CARVED_REGULAR := UI_DIR + "/Banners/Carved_Regular.png"

const UI_BUTTON_BLUE := UI_DIR + "/Buttons/Button_Blue.png"
const UI_BUTTON_BLUE_3SLIDES := UI_DIR + "/Buttons/Button_Blue_3Slides.png"
const UI_BUTTON_BLUE_9SLIDES := UI_DIR + "/Buttons/Button_Blue_9Slides.png"
const UI_BUTTON_BLUE_PRESSED := UI_DIR + "/Buttons/Button_Blue_Pressed.png"
const UI_BUTTON_HOVER := UI_DIR + "/Buttons/Button_Hover.png"
const UI_BUTTON_HOVER_3SLIDES := UI_DIR + "/Buttons/Button_Hover_3Slides.png"
const UI_BUTTON_HOVER_9SLIDES := UI_DIR + "/Buttons/Button_Hover_9Slides.png"
const UI_BUTTON_DISABLE := UI_DIR + "/Buttons/Button_Disable.png"
const UI_BUTTON_DISABLE_3SLIDES := UI_DIR + "/Buttons/Button_Disable_3Slides.png"
const UI_BUTTON_DISABLE_9SLIDES := UI_DIR + "/Buttons/Button_Disable_9Slides.png"
const UI_BUTTON_RED := UI_DIR + "/Buttons/Button_Red.png"
const UI_BUTTON_RED_3SLIDES := UI_DIR + "/Buttons/Button_Red_3Slides.png"
const UI_BUTTON_RED_9SLIDES := UI_DIR + "/Buttons/Button_Red_9Slides.png"

const UI_RIBBON_BLUE := UI_DIR + "/Ribbons/Ribbon_Blue_3Slides.png"
const UI_RIBBON_YELLOW := UI_DIR + "/Ribbons/Ribbon_Yellow_3Slides.png"
const UI_RIBBON_RED := UI_DIR + "/Ribbons/Ribbon_Red_3Slides.png"

const UI_POINTER_01 := UI_DIR + "/Pointers/01.png"
const UI_HEART_FULL := "res://assets/ui/heart_full.png"
const UI_HEART_EMPTY := "res://assets/ui/heart_empty.png"
const UI_DIALOGUE_SNOWY := EVERYTHING + "/Snowy RPG Dialogue Overlay.png"
const UI_DIALOGUE_KITSU := EVERYTHING + "/Kitsu’s Mystical Fox Dialogue UI.png"
const UI_DIALOGUE_GUARD := EVERYTHING + "/Mossveil Guard Dialogue Portrait.png"
const FONT_MEDIEVAL := "res://assets/fonts/MedievalSharp.ttf"

# --- data -------------------------------------------------------------------
const COMBAT_JSON := "res://data/combat.json"
const PROLOGUE_JSON := "res://data/prologue.json"
const DIALOGUE_JSON := "res://data/dialogue.json"
const WAVES_JSON := "res://data/waves.json"

# --- scenes -----------------------------------------------------------------
const MAIN_SCENE := "res://scenes/main/main.tscn"
const PROLOGUE_SCENE := "res://scenes/cutscenes/prologue.tscn"
const WHISPERING_WOODS := "res://scenes/world/whispering_woods.tscn"
const MOSSVEIL_VILLAGE := "res://scenes/world/mossveil_village.tscn"
const PLAYER_SCENE := "res://scenes/entities/player.tscn"
const ENEMY_SCENE := "res://scenes/entities/enemy.tscn"

var _texture_cache: Dictionary = {}
var _font_cache: Dictionary = {}


func font(path: String) -> Font:
	if _font_cache.has(path):
		return _font_cache[path] as Font
	var f: Font = null
	if ResourceLoader.exists(path):
		f = load(path) as Font
	if f == null:
		var global_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(global_path):
			var ff := FontFile.new()
			var err := ff.load_dynamic_font(global_path)
			if err == OK:
				f = ff
	if f == null:
		push_error("[Assets] FAILED TO LOAD FONT: " + path)
		return null
	_font_cache[path] = f
	return f


func font_bold(path: String, embolden_val: float = 0.35) -> Font:
	var cache_key := "%s_bold_%.2f" % [path, embolden_val]
	if _font_cache.has(cache_key):
		return _font_cache[cache_key] as Font
	var base_f := font(path)
	if base_f == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base_f
	fv.variation_embolden = embolden_val
	_font_cache[cache_key] = fv
	return fv


func tex(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path) as Texture2D
	if t == null:
		var global_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(global_path):
			var img := Image.load_from_file(global_path)
			if img != null:
				t = ImageTexture.create_from_image(img)
		elif FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null:
				t = ImageTexture.create_from_image(img)
	if t == null:
		push_error("[Assets] FAILED TO LOAD: " + path)
		return null
	_texture_cache[path] = t
	return t


func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("[Assets] missing data file: " + path)
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("[Assets] invalid JSON: " + path)
	return parsed


## Largest opaque bounding box of a texture (used to place prop sprites by
## their visual foot rather than the raw canvas).
func content_rect(t: Texture2D) -> Rect2i:
	var img := t.get_image()
	if img == null:
		return Rect2i(0, 0, t.get_width(), t.get_height())
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return Rect2i(0, 0, t.get_width(), t.get_height())
	return used
