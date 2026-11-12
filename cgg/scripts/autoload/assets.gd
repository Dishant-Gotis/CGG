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

# --- Game Assets (NEW) Pack ------------------------------------------------
const NEW_ASSETS := "res://Game Assets(NEW)"
const NEW_BUILDINGS_BLUE := NEW_ASSETS + "/Buildings/Blue Buildings"
const NEW_BUILDINGS_RED := NEW_ASSETS + "/Buildings/Red Buildings"
const NEW_TERRAIN_TILES := NEW_ASSETS + "/Terrain/Tileset"
const NEW_TERRAIN_TREES := NEW_ASSETS + "/Terrain/Resources/Wood/Trees"
const NEW_TERRAIN_BUSHES := NEW_ASSETS + "/Terrain/Decorations/Bushes"
const NEW_TERRAIN_SHEEP := NEW_ASSETS + "/Terrain/Resources/Meat/Sheep"
const NEW_TERRAIN_GOLD := NEW_ASSETS + "/Terrain/Resources/Gold/Gold Stones"
const NEW_TERRAIN_ROCKS := NEW_ASSETS + "/Terrain/Decorations/Rocks"
const NEW_TERRAIN_WATER_ROCKS := NEW_ASSETS + "/Terrain/Decorations/Rocks in the Water"
const NEW_TERRAIN_CLOUDS := NEW_ASSETS + "/Terrain/Decorations/Clouds"
const NEW_UNITS_BLUE := NEW_ASSETS + "/Units/Blue Units"
const NEW_UNITS_RED := NEW_ASSETS + "/Units/Red Units"

# Terrain & Water
const TILES_TERRAIN_COLOR1 := NEW_TERRAIN_TILES + "/Tilemap_color1.png"
const WATER_BG := NEW_TERRAIN_TILES + "/Water Background color.png"
const WATER_FOAM := NEW_TERRAIN_TILES + "/Water Foam.png"
const SHADOW_TEX := NEW_TERRAIN_TILES + "/Shadow.png"

# Animated Trees
const TREE_1 := NEW_TERRAIN_TREES + "/Tree1.png" # 256x256, 6 frames
const TREE_2 := NEW_TERRAIN_TREES + "/Tree2.png" # 256x256, 6 frames
const TREE_3 := NEW_TERRAIN_TREES + "/Tree3.png" # 192x192, 8 frames
const TREE_4 := NEW_TERRAIN_TREES + "/Tree4.png" # 192x192, 8 frames
const STUMP_1 := NEW_TERRAIN_TREES + "/Stump 1.png"
const STUMP_2 := NEW_TERRAIN_TREES + "/Stump 2.png"

# Animated Bushes
const BUSH_NEW_1 := NEW_TERRAIN_BUSHES + "/Bushe1.png" # 128x128, 8 frames
const BUSH_NEW_2 := NEW_TERRAIN_BUSHES + "/Bushe2.png" # 128x128, 8 frames
const BUSH_NEW_3 := NEW_TERRAIN_BUSHES + "/Bushe3.png" # 128x128, 8 frames
const BUSH_NEW_4 := NEW_TERRAIN_BUSHES + "/Bushe4.png" # 128x128, 8 frames

# Animated Sheep
const SHEEP_IDLE := NEW_TERRAIN_SHEEP + "/Sheep_Idle.png"   # 128x128, 6 frames
const SHEEP_GRASS := NEW_TERRAIN_SHEEP + "/Sheep_Grass.png" # 128x128, 12 frames
const SHEEP_MOVE := NEW_TERRAIN_SHEEP + "/Sheep_Move.png"   # 128x128, 4 frames

# Water Rocks
const WATER_ROCK_1 := NEW_TERRAIN_WATER_ROCKS + "/Water Rocks_01.png" # 64x64, 16 frames
const WATER_ROCK_2 := NEW_TERRAIN_WATER_ROCKS + "/Water Rocks_02.png"
const WATER_ROCK_3 := NEW_TERRAIN_WATER_ROCKS + "/Water Rocks_03.png"
const WATER_ROCK_4 := NEW_TERRAIN_WATER_ROCKS + "/Water Rocks_04.png"

# Rocks & Gold
const ROCK_1 := NEW_TERRAIN_ROCKS + "/Rock1.png"
const ROCK_2 := NEW_TERRAIN_ROCKS + "/Rock2.png"
const ROCK_3 := NEW_TERRAIN_ROCKS + "/Rock3.png"
const ROCK_4 := NEW_TERRAIN_ROCKS + "/Rock4.png"
const GOLD_STONE_1 := NEW_TERRAIN_GOLD + "/Gold Stone 1.png"
const GOLD_STONE_1_HL := NEW_TERRAIN_GOLD + "/Gold Stone 1_Highlight.png" # 128x128, 6 frames

# Clouds
const CLOUD_1 := NEW_TERRAIN_CLOUDS + "/Clouds_01.png"
const CLOUD_2 := NEW_TERRAIN_CLOUDS + "/Clouds_02.png"
const CLOUD_3 := NEW_TERRAIN_CLOUDS + "/Clouds_03.png"

# Blue Buildings
const BUILDING_CASTLE := NEW_BUILDINGS_BLUE + "/Castle.png"
const BUILDING_TOWER := NEW_BUILDINGS_BLUE + "/Tower.png"
const BUILDING_HOUSE_1 := NEW_BUILDINGS_BLUE + "/House1.png"
const BUILDING_HOUSE_2 := NEW_BUILDINGS_BLUE + "/House2.png"
const BUILDING_HOUSE_3 := NEW_BUILDINGS_BLUE + "/House3.png"
const BUILDING_MONASTERY := NEW_BUILDINGS_BLUE + "/Monastery.png"
const BUILDING_ARCHERY := NEW_BUILDINGS_BLUE + "/Archery.png"
const BUILDING_BARRACKS := NEW_BUILDINGS_BLUE + "/Barracks.png"

# Animated Units
const WARRIOR_BLUE_IDLE := NEW_UNITS_BLUE + "/Warrior/Warrior_Idle.png" # 192x192, 8 frames
const WARRIOR_BLUE_RUN := NEW_UNITS_BLUE + "/Warrior/Warrior_Run.png"   # 192x192, 6 frames
const ARCHER_BLUE_IDLE := NEW_UNITS_BLUE + "/Archer/Archer_Idle.png"   # 192x192, 6 frames
const LANCER_BLUE_IDLE := NEW_UNITS_BLUE + "/Lancer/Lancer_Idle.png"   # 320x320, 12 frames
const MONK_BLUE_IDLE := NEW_UNITS_BLUE + "/Monk/Idle.png"              # 192x192, 6 frames
const PAWN_BLUE_IDLE := NEW_UNITS_BLUE + "/Pawn/Pawn_Idle.png"         # 192x192, 8 frames
const PAWN_BLUE_RUN := NEW_UNITS_BLUE + "/Pawn/Pawn_Run.png"           # 192x192, 6 frames
const PAWN_BLUE_AXE := NEW_UNITS_BLUE + "/Pawn/Pawn_Interact Axe.png"

# Red Units
const WARRIOR_RED_IDLE := NEW_UNITS_RED + "/Warrior/Warrior_Idle.png"
const ARCHER_RED_IDLE := NEW_UNITS_RED + "/Archer/Archer_Idle.png"

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


var _sprite_frames_cache: Dictionary = {}

## Programmatic SpriteFrames factory for authentic animated strips from Game Assets(NEW).
func sprite_frames(path: String, frame_w: int, frame_h: int, count: int, fps: float = 6.0, loop: bool = true, anim_name: String = "default") -> SpriteFrames:
	var key := "%s_%d_%d_%d_%.1f_%s" % [path, frame_w, frame_h, count, fps, anim_name]
	if _sprite_frames_cache.has(key):
		return _sprite_frames_cache[key]
	var texture := tex(path)
	if texture == null:
		return null
	var sf := SpriteFrames.new()
	if not sf.has_animation(anim_name):
		sf.add_animation(anim_name)
	sf.clear(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	for i: int in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
		sf.add_frame(anim_name, atlas)
	_sprite_frames_cache[key] = sf
	return sf

