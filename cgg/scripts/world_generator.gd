@tool
extends Node2D

func _ready() -> void:
	print("[WORLD GEN] Generating dense, rich, handcrafted fantasy world (5120x2304)...")

	var world := Node2D.new()
	world.name = "World"
	world.set_script(load("res://scripts/world.gd"))

	# 1. Background Ocean Water (Deep Turquoise)
	var bg_water := TextureRect.new()
	bg_water.name = "WaterBackground"
	bg_water.texture = load(Assets.WATER_BG)
	bg_water.stretch_mode = TextureRect.STRETCH_TILE
	bg_water.size = Vector2(5120, 2304)
	bg_water.z_index = -10
	world.add_child(bg_water)
	bg_water.owner = world

	# 2. TileMap with Ground (Layer 0), Roads (Layer 1), and Bridge (Layer 2)
	var terrain := TileMap.new()
	terrain.name = "TileMap"

	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(64, 64)

	# Source 0: Game Assets(NEW) Tilemap_color1 (Lush green grass + shores)
	var src0 := TileSetAtlasSource.new()
	src0.texture = load(Assets.TILES_TERRAIN_COLOR1)
	src0.texture_region_size = Vector2i(64, 64)
	for cx in range(9):
		for cy in range(6):
			src0.create_tile(Vector2i(cx, cy))
	tileset.add_source(src0, 0)

	# Source 1: Tiny Swords Tilemap_Flat (Yellow Dirt Paths with 3x3 Autotiling)
	var src1 := TileSetAtlasSource.new()
	src1.texture = load("res://Tiny Swords (Update 010)/Terrain/Ground/Tilemap_Flat.png")
	src1.texture_region_size = Vector2i(64, 64)
	for cx in range(10):
		for cy in range(4):
			src1.create_tile(Vector2i(cx, cy))
	tileset.add_source(src1, 1)

	# Source 2: Tiny Swords Bridge_All (Seamless 64x64 Wooden Bridge Tiles)
	var src2 := TileSetAtlasSource.new()
	src2.texture = load("res://Tiny Swords (Update 010)/Terrain/Bridge/Bridge_All.png")
	src2.texture_region_size = Vector2i(64, 64)
	for cx in range(3):
		for cy in range(4):
			src2.create_tile(Vector2i(cx, cy))
	tileset.add_source(src2, 2)

	terrain.tile_set = tileset
	terrain.add_layer(1) # Layer 1 for Roads
	terrain.add_layer(2) # Layer 2 for Bridge
	world.add_child(terrain)
	terrain.owner = world

	# --- Layer 0: Ground Landmass (80 cols x 36 rows) ---
	# Island spans from gx: 2 to 77, gy: 2 to 33.
	# River cut at south-central: gx: 28..31, gy: 26..33
	for gx in range(2, 78):
		for gy in range(2, 34):
			# River inlet in the south (water shows through)
			if (gx >= 28 and gx <= 31) and gy >= 26:
				continue

			var atlas := Vector2i(1, 1) # default center grass

			var is_top := (gy == 2)
			var is_bottom := (gy == 33) or ((gx >= 28 and gx <= 31) and gy == 25)
			var is_left := (gx == 2) or (gx == 32 and gy >= 26)
			var is_right := (gx == 77) or (gx == 27 and gy >= 26)

			if is_top and is_left: atlas = Vector2i(0, 0)
			elif is_top and is_right: atlas = Vector2i(2, 0)
			elif is_bottom and is_left: atlas = Vector2i(0, 2)
			elif is_bottom and is_right: atlas = Vector2i(2, 2)
			elif is_top: atlas = Vector2i(1, 0)
			elif is_bottom: atlas = Vector2i(1, 2)
			elif is_left: atlas = Vector2i(0, 1)
			elif is_right: atlas = Vector2i(2, 1)

			terrain.set_cell(0, Vector2i(gx, gy), 0, atlas)

	# --- Layer 1: Smooth Dirt Roads with Autotiling ---
	_build_roads(terrain)

	# --- Layer 2: Authentic Wooden Bridge over River at gy: 26 ---
	terrain.set_cell(2, Vector2i(27, 26), 2, Vector2i(0, 0)) # Left bridge pier connector
	terrain.set_cell(2, Vector2i(28, 26), 2, Vector2i(1, 0)) # Span 1
	terrain.set_cell(2, Vector2i(29, 26), 2, Vector2i(1, 0)) # Span 2
	terrain.set_cell(2, Vector2i(30, 26), 2, Vector2i(1, 0)) # Span 3
	terrain.set_cell(2, Vector2i(31, 26), 2, Vector2i(1, 0)) # Span 4
	terrain.set_cell(2, Vector2i(32, 26), 2, Vector2i(2, 0)) # Right bridge pier connector

	# 3. World Boundaries
	var bounds := StaticBody2D.new()
	bounds.name = "WorldBounds"
	bounds.collision_mask = 0
	world.add_child(bounds)
	bounds.owner = world

	_add_wall(bounds, world, Vector2(2560, 0), Vector2(5120, 24))
	_add_wall(bounds, world, Vector2(2560, 2304), Vector2(5120, 24))
	_add_wall(bounds, world, Vector2(0, 1152), Vector2(24, 2304))
	_add_wall(bounds, world, Vector2(5120, 1152), Vector2(24, 2304))

	# 4. Objects (Y-Sorted Gameplay Layer)
	var objects := Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	world.add_child(objects)
	objects.owner = world

	# Spawn Markers
	var spawn_def := Marker2D.new()
	spawn_def.name = "Spawn_default"
	spawn_def.position = Vector2(420, 1060)
	objects.add_child(spawn_def)
	spawn_def.owner = world

	var spawn_cave := Marker2D.new()
	spawn_cave.name = "Spawn_cave_exit"
	spawn_cave.position = Vector2(1150, 1960)
	objects.add_child(spawn_cave)
	spawn_cave.owner = world

	# Player & Companions
	var player_sc: PackedScene = load("res://scenes/player.tscn")
	var player := player_sc.instantiate()
	player.name = "player"
	player.position = Vector2(420, 1060)
	objects.add_child(player)
	player.owner = world

	var fox_sc: PackedScene = load("res://scenes/companion_fox.tscn")
	var fox := fox_sc.instantiate()
	fox.name = "CompanionFox"
	fox.position = Vector2(470, 1070)
	objects.add_child(fox)
	fox.owner = world

	var kitsu_sc: PackedScene = load("res://scenes/npc_kitsu.tscn")
	var kitsu := kitsu_sc.instantiate()
	kitsu.name = "NPC_Kitsu"
	kitsu.position = Vector2(520, 1060)
	objects.add_child(kitsu)
	kitsu.owner = world

	# Entity Packed Scenes
	var bld_sc: PackedScene = load("res://scenes/entities/dynamic_building.tscn")
	var tree_sc: PackedScene = load("res://scenes/entities/dynamic_tree.tscn")
	var bush_sc: PackedScene = load("res://scenes/entities/dynamic_bush.tscn")
	var sheep_sc: PackedScene = load("res://scenes/entities/dynamic_sheep.tscn")
	var foam_sc: PackedScene = load("res://scenes/entities/dynamic_water_foam.tscn")
	var wrock_sc: PackedScene = load("res://scenes/entities/dynamic_water_rock.tscn")
	var gold_sc: PackedScene = load("res://scenes/entities/dynamic_gold_rock.tscn")
	var enemy_sc: PackedScene = load("res://scenes/enemy.tscn")
	var torch_sc: PackedScene = load("res://scenes/enemy_torch_goblin.tscn")

	# =========================================================================
	# ZONE 1: SNOWY'S COASTAL HAVEN (West, X: 150-900, Y: 850-1300)
	# Clean, spacious starting haven with clear sightlines on the player
	# =========================================================================
	_add_building(objects, world, bld_sc, 0, Vector2(380, 960), "SnowyCottage")
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(300, 1030), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_medium.png", Vector2(480, 1000), Vector2(70, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(470, 960), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(500, 960), Vector2(24, 24), Vector2(0, -5))

	# Fishing Pier extending into west sea
	_add_prop(objects, world, "res://assets/props/wooden_bridge_pier.png", Vector2(170, 1040), Vector2(130, 30), Vector2(0, -15))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(160, 1010), Vector2(24, 24), Vector2(0, -5))

	# Trees framing the haven safely behind and to the sides (NO overlap with player spawn or road)
	_add_tree(objects, world, tree_sc, 1, Vector2(240, 840)) # NW of house
	_add_tree(objects, world, tree_sc, 2, Vector2(540, 840)) # NE of house
	_add_tree(objects, world, tree_sc, 3, Vector2(200, 1180)) # West by shore
	_add_bush(objects, world, bush_sc, 1, Vector2(230, 1030)) # By garden fence
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(320, 1010))

	# West Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(130, 850))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1040))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1230))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(100, 920))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(90, 1120))

	# =========================================================================
	# ZONE 1: THE HIGH ROAD & SLIME TUTORIAL TRAIL (West, X: 500-1250, Y: 700-1150)
	# Extended winding mountain trail connecting Snowy's Haven to Mossveil Village.
	# Hero encounters wild slimes along this trail to learn battle mechanics ([Q] attack,
	# spacing, knockback) before reaching the village gates.
	# =========================================================================

	# Trailhead & Gateway (near Kitsu at 520, 1060)
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(610, 1020), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/fence_medium.png", Vector2(590, 1110), Vector2(70, 20), Vector2(0, -10))
	_add_sign(objects, world, Vector2(570, 1020), "TrailheadSign", [
		"The High Road ⬆: Scenic mountain trail to Mossveil Village.",
		"Warning: Wild slimes have been sighted along the mountain pass!",
		"Draw your Hero's Blade with [Q] to defend yourself."
	], "Trail Guide")

	# Encounter 1: The Ascending Glade (Tutorial Slime & Combat Guide Sign)
	_add_sign(objects, world, Vector2(610, 860), "CombatTutorialSign", [
		"Combat Guide — Hero's Blade:",
		"Press [Q] to swing your sword at nearby adversaries.",
		"Slimes take 2 decisive strikes. Keep moving to avoid getting cornered!",
		"Defeat the slimes to clear the road forward."
	], "Combat Guide")
	_add_enemy(objects, world, enemy_sc, Vector2(740, 860)) # Lone tutorial slime
	_add_tree(objects, world, tree_sc, 3, Vector2(580, 920))
	_add_tree(objects, world, tree_sc, 4, Vector2(780, 990))
	_add_bush(objects, world, bush_sc, 1, Vector2(590, 820))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(670, 890))

	# Encounter 2: High Ridge Pass & Rocky Defile (Slime Duo)
	_add_enemy(objects, world, enemy_sc, Vector2(920, 740))  # Slime 2
	_add_enemy(objects, world, enemy_sc, Vector2(1040, 750)) # Slime 3
	_add_tree(objects, world, tree_sc, 2, Vector2(950, 650))
	_add_bush(objects, world, bush_sc, 2, Vector2(880, 790))
	_add_bush(objects, world, bush_sc, 3, Vector2(1050, 790))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(850, 660))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(1010, 650))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(1080, 780))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(910, 760))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(970, 760))

	# Encounter 3: Valley Descent & Traveler's Overlook (Slime Duo)
	_add_enemy(objects, world, enemy_sc, Vector2(1180, 860)) # Slime 4
	_add_enemy(objects, world, enemy_sc, Vector2(1140, 950)) # Slime 5
	_add_tree(objects, world, tree_sc, 1, Vector2(1250, 810))
	# Traveler's Rest Overlook (on the grassy terrace east of the road)
	_add_prop(objects, world, "res://assets/props/stump_4.png", Vector2(1260, 900), Vector2(26, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/tool_04.png", Vector2(1275, 895))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1270, 860), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1280, 930))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(1220, 870))

	# Central Nature Reserve (The Meadow inside the High Road loop)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(840, 1040), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(980, 1040), Vector2(120, 20), Vector2(0, -10))
	_add_tree(objects, world, tree_sc, 4, Vector2(910, 910))
	_add_bush(objects, world, bush_sc, 1, Vector2(850, 940))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(860, 940))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(960, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(810, 960))
	_add_sheep(objects, world, sheep_sc, Vector2(920, 970)) # Peaceful grazing sheep

	# Crossroads Waypoint
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1060, 1000), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1240, 1000), Vector2(16, 16), Vector2(0, -6))
	_add_sign(objects, world, Vector2(1060, 1030), "CrossroadsSign", [
		"Oakhaven Crossroads Signpost:",
		"⬆ North: High Mountain Pass & Combat Training Grounds",
		"⬇ South: Whispering Shores & Mystic Cavern",
		"➔ East: Mossveil Village & Royal Citadel",
		"⬅ West: The High Road to Snowy's Haven"
	], "Crossroads")

	# =========================================================================
	# ZONE 1B: NORTH-WEST PINE RIDGE & OVERLOOK (X: 150-1300, Y: 150-850)
	# High mountain pine forest and scenic ridge overlooking Snowy's haven
	# =========================================================================
	var nw_trees := [
		Vector2(180, 220), Vector2(360, 200), Vector2(540, 230), Vector2(720, 210), Vector2(900, 230), Vector2(1080, 220), Vector2(1240, 240),
		Vector2(240, 360), Vector2(440, 380), Vector2(660, 340), Vector2(860, 370), Vector2(1060, 350), Vector2(1220, 400),
		Vector2(180, 520), Vector2(360, 540), Vector2(540, 500), Vector2(740, 530), Vector2(940, 510), Vector2(1120, 560),
		Vector2(220, 680), Vector2(420, 710), Vector2(640, 690), Vector2(840, 720), Vector2(1040, 700)
	]
	var nw_t_idx := 0
	for tpos in nw_trees:
		_add_tree(objects, world, tree_sc, (nw_t_idx % 4) + 1, tpos)
		nw_t_idx += 1

	var nw_bushes := [
		Vector2(280, 280), Vector2(600, 260), Vector2(980, 290),
		Vector2(320, 450), Vector2(780, 440), Vector2(1150, 470),
		Vector2(280, 620), Vector2(700, 620), Vector2(980, 630)
	]
	var nw_b_idx := 0
	for bpos in nw_bushes:
		_add_bush(objects, world, bush_sc, (nw_b_idx % 4) + 1, bpos)
		nw_b_idx += 1

	# Mountain Ridge Overlook with Camp Bench and Wildflowers
	_add_prop(objects, world, "res://assets/props/stump_4.png", Vector2(620, 420), Vector2(26, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/tool_04.png", Vector2(635, 415))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(580, 430), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(660, 430))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(550, 440))

	# Ridge Boulders
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(480, 260))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(820, 280))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(380, 480))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(880, 460))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(520, 650))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(1100, 480))

	# Northern Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(200, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(450, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(700, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(950, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(1200, 130))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(320, 90))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(600, 90))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(850, 90))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(1100, 90))

	# =========================================================================
	# ZONE 2: SOUTH-WEST WHISPERING WOODS (ORGANICALLY SPACED & BALANCED NATURE)
	# Beautiful, breathable woodland between X: 150-1150, Y: 1250-2150
	# =========================================================================
	var sw_trees := [
		Vector2(220, 1340), Vector2(440, 1400), Vector2(660, 1330), Vector2(880, 1310), Vector2(1050, 1330),
		Vector2(320, 1480), Vector2(540, 1460), Vector2(760, 1490), Vector2(960, 1470),
		Vector2(200, 1620), Vector2(380, 1650), Vector2(600, 1620), Vector2(820, 1650), Vector2(1040, 1630),
		Vector2(280, 1800), Vector2(480, 1780), Vector2(700, 1810), Vector2(900, 1790), Vector2(1060, 1810),
		Vector2(220, 1960), Vector2(420, 1980), Vector2(640, 1960), Vector2(840, 1980)
	]
	var tree_idx := 0
	for tpos in sw_trees:
		var ttype := (tree_idx % 4) + 1
		_add_tree(objects, world, tree_sc, ttype, tpos)
		tree_idx += 1

	var sw_bushes := [
		Vector2(260, 1380), Vector2(580, 1360), Vector2(920, 1370),
		Vector2(360, 1540), Vector2(800, 1530),
		Vector2(240, 1720), Vector2(620, 1720), Vector2(960, 1720),
		Vector2(340, 1880), Vector2(780, 1890)
	]
	var b_idx := 0
	for bpos in sw_bushes:
		_add_bush(objects, world, bush_sc, (b_idx % 4) + 1, bpos)
		b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(400, 1400))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(750, 1420))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(320, 1680))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(880, 1670))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(520, 1900))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(950, 1910))

	# Woodcutter's Secluded Camp & Fairy Circle in the Woods
	_add_prop(objects, world, "res://assets/props/stump_3.png", Vector2(500, 1600), Vector2(24, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/tool_03.png", Vector2(515, 1595))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(540, 1600), Vector2(40, 18), Vector2(0, -9))
	# Magical Mushroom Ring
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/01.png", Vector2(700, 1600))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/02.png", Vector2(730, 1585))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/03.png", Vector2(760, 1600))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/02.png", Vector2(745, 1625))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/01.png", Vector2(715, 1625))
	# Wildflowers in the glade
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(670, 1560))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(790, 1560))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(430, 1680))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(610, 1780))

	# South-West Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1420))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1620))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1820))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 2020))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(100, 1500))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(90, 1720))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(100, 1920))

	# =========================================================================
	# ZONE 3: NORTHERN FOREST & MOUNTAIN TRAINING GROUNDS (X: 1400-2600, Y: 250-750)
	# =========================================================================
	_add_building(objects, world, bld_sc, 4, Vector2(1850, 360), "TrainingTower")
	_add_building(objects, world, bld_sc, 6, Vector2(2250, 380), "ArcheryRange")
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1780, 480), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/stump_1.png", Vector2(2150, 470), Vector2(36, 22), Vector2(0, -11))
	_add_prop(objects, world, "res://assets/props/tool_01.png", Vector2(2170, 465))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(2200, 470), Vector2(40, 18), Vector2(0, -9))

	_add_tree(objects, world, tree_sc, 1, Vector2(1400, 260))
	_add_tree(objects, world, tree_sc, 2, Vector2(1600, 250))
	_add_tree(objects, world, tree_sc, 1, Vector2(1800, 240))
	_add_tree(objects, world, tree_sc, 2, Vector2(2050, 250))
	_add_tree(objects, world, tree_sc, 1, Vector2(2250, 240))
	_add_tree(objects, world, tree_sc, 2, Vector2(2450, 260))
	_add_tree(objects, world, tree_sc, 3, Vector2(1320, 360))
	_add_tree(objects, world, tree_sc, 4, Vector2(1500, 420))
	_add_tree(objects, world, tree_sc, 1, Vector2(1680, 280))
	_add_tree(objects, world, tree_sc, 2, Vector2(1920, 260))
	_add_tree(objects, world, tree_sc, 3, Vector2(2160, 280))
	_add_tree(objects, world, tree_sc, 4, Vector2(2380, 290))
	_add_tree(objects, world, tree_sc, 1, Vector2(2550, 380))
	_add_bush(objects, world, bush_sc, 1, Vector2(1450, 460))
	_add_bush(objects, world, bush_sc, 2, Vector2(1950, 480))
	_add_bush(objects, world, bush_sc, 3, Vector2(2100, 440))
	_add_bush(objects, world, bush_sc, 4, Vector2(2350, 470))
	_add_bush(objects, world, bush_sc, 1, Vector2(2500, 450))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1720, 390))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(2380, 410))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(1580, 320))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(2020, 340))

	_add_sign(objects, world, Vector2(1750, 500), "TrainingSign", [
		"High Mountain Training Grounds:",
		"Press [Q] to swing your sword at nearby adversaries.",
		"Armored and shadowy beasts require decisive strikes.",
		"Master your skills before proceeding deeper into the realm!"
	], "Training Sign")

	# Enemies
	_add_enemy(objects, world, enemy_sc, Vector2(1920, 520))
	_add_enemy(objects, world, enemy_sc, Vector2(2120, 530))
	_add_enemy(objects, world, torch_sc, Vector2(2300, 500))

	# =========================================================================
	# ZONE 3B: NORTH-EAST WHISPERING WILDERNESS & BANDIT RUINS (X: 2700-4900, Y: 150-750)
	# Fills vast empty northern plateau with pine wilderness, ruined watchtower & bandit campsite
	# =========================================================================
	_add_building(objects, world, bld_sc, 4, Vector2(3350, 360), "WildernessWatchtower")
	_add_prop(objects, world, "res://assets/props/stump_1.png", Vector2(3440, 420), Vector2(36, 22), Vector2(0, -11))
	_add_prop(objects, world, "res://assets/props/tool_01.png", Vector2(3455, 415))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(3480, 420), Vector2(40, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(3260, 410), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3350, 440), Vector2(16, 16), Vector2(0, -6))
	_add_enemy(objects, world, torch_sc, Vector2(3420, 460))

	var ne_trees := [
		Vector2(2750, 240), Vector2(2980, 220), Vector2(3200, 250), Vector2(3450, 220), Vector2(3700, 240), Vector2(3950, 220), Vector2(4200, 240), Vector2(4450, 220), Vector2(4700, 250),
		Vector2(2850, 400), Vector2(3100, 420), Vector2(3580, 400), Vector2(3820, 420), Vector2(4080, 390), Vector2(4340, 410), Vector2(4600, 390), Vector2(4800, 420),
		Vector2(2720, 560), Vector2(2950, 580), Vector2(3220, 560), Vector2(3480, 580), Vector2(3720, 560), Vector2(3980, 590), Vector2(4240, 570), Vector2(4500, 590), Vector2(4740, 570),
		Vector2(2840, 720), Vector2(3060, 700), Vector2(3280, 730), Vector2(3520, 710)
	]
	var ne_t_idx := 0
	for tpos in ne_trees:
		_add_tree(objects, world, tree_sc, (ne_t_idx % 4) + 1, tpos)
		ne_t_idx += 1

	var ne_bushes := [
		Vector2(2820, 320), Vector2(3300, 280), Vector2(3780, 330), Vector2(4250, 310), Vector2(4680, 330),
		Vector2(2920, 490), Vector2(3620, 480), Vector2(4150, 490), Vector2(4650, 480),
		Vector2(2800, 650), Vector2(3380, 650)
	]
	var ne_b_idx := 0
	for bpos in ne_bushes:
		_add_bush(objects, world, bush_sc, (ne_b_idx % 4) + 1, bpos)
		ne_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2900, 260))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(3600, 270))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(4300, 260))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(3150, 480))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3900, 470))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4750, 490))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(3000, 660))

	# Northern Ocean Coastline Foam & Water Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(2800, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(3200, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(3600, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(4000, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(4400, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(4800, 130))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(3000, 90))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(3400, 90))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(3800, 90))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(4200, 90))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(4600, 90))

	# =========================================================================
	# ZONE 4: MOSSVEIL VILLAGE & TOWN SQUARE (X: 1500-3600, Y: 800-1600)
	# =========================================================================
	# Village Entrance Archway & Guard
	_add_prop(objects, world, "res://assets/props/archway_lantern.png", Vector2(1620, 1024), Vector2(90, 24), Vector2(0, -10))
	_add_sign(objects, world, Vector2(1540, 1000), "VillageGateSign", [
		"Welcome to Mossveil Village!",
		"You are protected by the royal decree of King Aldous.",
		"Follow the main avenue east to reach the town square and citadel."
	], "Village Gate")

	var guard_sc: PackedScene = load("res://scenes/npc_guard.tscn")
	var guard := guard_sc.instantiate()
	guard.name = "NPC_Guard"
	guard.position = Vector2(1720, 1024)
	objects.add_child(guard)
	guard.owner = world

	# Residential Quarter (West Village)
	_add_building(objects, world, bld_sc, 0, Vector2(1900, 860), "VillageHouse_West1")
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1820, 930), Vector2(120, 20), Vector2(0, -10))
	_add_building(objects, world, bld_sc, 1, Vector2(2150, 840), "VillageHouse_West2")
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(2230, 890), Vector2(24, 24), Vector2(0, -5))

	# Maya's Residence
	_add_building(objects, world, bld_sc, 2, Vector2(2750, 820), "VillageHouse_Maya")
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(2830, 880), Vector2(120, 20), Vector2(0, -10))
	var maya_sc: PackedScene = load("res://scenes/npc_maya.tscn")
	var maya := maya_sc.instantiate()
	maya.name = "NPC_Maya"
	maya.position = Vector2(2700, 900)
	objects.add_child(maya)
	maya.owner = world

	# Ravi's Woodcraft Workshop (South-West Village)
	_add_building(objects, world, bld_sc, 7, Vector2(1980, 1260), "BarracksWorkshop")
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(2060, 1310), Vector2(40, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/stump_2.png", Vector2(2100, 1315), Vector2(36, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/tool_02.png", Vector2(2110, 1310))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(2140, 1310), Vector2(24, 24), Vector2(0, -5))
	var ravi_sc: PackedScene = load("res://scenes/npc_ravi.tscn")
	var ravi := ravi_sc.instantiate()
	ravi.name = "NPC_Ravi"
	ravi.position = Vector2(2080, 1220)
	objects.add_child(ravi)
	ravi.owner = world

	# Central Town Square & Grand Plaza (X: 2496, Y: 1088)
	_add_tree(objects, world, tree_sc, 4, Vector2(2496, 1050))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2320, 980), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2660, 980), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2320, 1180), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2660, 1180), Vector2(16, 16), Vector2(0, -6))

	_add_sign(objects, world, Vector2(2380, 1140), "TownSquareSign", [
		"Mossveil Town Square:",
		"North: Residential Quarter & Flower Gardens",
		"East: High Bridge to Royal Citadel",
		"South: River Cross, Farm Fields & Pastures",
		"West: Village Gate & Forest Road"
	], "Town Square")

	# Market Stalls & Produce (South of Plaza)
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(2420, 1250), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(2450, 1250), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(2485, 1250), Vector2(30, 20), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/crate_box.png", Vector2(2520, 1250), Vector2(30, 20), Vector2(0, -5))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/12.png", Vector2(2550, 1255))

	# Additional Village Houses (East Village)
	_add_building(objects, world, bld_sc, 0, Vector2(3050, 840), "VillageHouse_East1")
	_add_building(objects, world, bld_sc, 1, Vector2(2850, 1260), "VillageHouse_East2")
	_add_building(objects, world, bld_sc, 2, Vector2(3180, 1240), "VillageHouse_East3")

	# Trees & nature around village
	_add_tree(objects, world, tree_sc, 3, Vector2(2000, 720))
	_add_tree(objects, world, tree_sc, 4, Vector2(2300, 720))
	_add_tree(objects, world, tree_sc, 3, Vector2(2580, 710))
	_add_tree(objects, world, tree_sc, 4, Vector2(2880, 710))
	_add_tree(objects, world, tree_sc, 1, Vector2(3100, 720))
	_add_tree(objects, world, tree_sc, 4, Vector2(3300, 840))
	_add_tree(objects, world, tree_sc, 2, Vector2(3380, 1020))
	_add_tree(objects, world, tree_sc, 3, Vector2(3350, 1260))
	_add_tree(objects, world, tree_sc, 1, Vector2(2700, 1380))
	_add_tree(objects, world, tree_sc, 2, Vector2(2350, 1380))
	_add_bush(objects, world, bush_sc, 1, Vector2(2280, 830))
	_add_bush(objects, world, bush_sc, 2, Vector2(2620, 830))
	_add_bush(objects, world, bush_sc, 3, Vector2(2950, 850))
	_add_bush(objects, world, bush_sc, 4, Vector2(3250, 960))
	_add_bush(objects, world, bush_sc, 1, Vector2(2520, 1360))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2120, 750))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(3000, 750))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2350, 870))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2650, 870))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2900, 920))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(3120, 920))

	# =========================================================================
	# ZONE 5: ENCLOSED FARMLAND & ENCLOSED SHEEP PASTURE (SQUARE FENCE PENS)
	# =========================================================================
	# Lanterns at Bridge Ends
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1730, 1660), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2080, 1660), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1250, 1660), Vector2(16, 16), Vector2(0, -6))

	# River foam and splash rocks
	_add_water_foam(objects, world, foam_sc, Vector2(1920, 1800))
	_add_water_foam(objects, world, foam_sc, Vector2(1920, 2020))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(1890, 1840))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(1950, 2060))

	# --- 1. ENCLOSED CROP GARDEN PLOT (SQUARE PEN: X: 1292..1494, Y: 1380..1540) ---
	# Width = 202 (2 horizontal fences, left post at 1292, right post at 1494)
	# Height = 160 (from 1380 to 1540)
	# North fence (horizontal span)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1340, 1380), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1441, 1380), Vector2(120, 20), Vector2(0, -10))
	# South fence (horizontal span)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1340, 1540), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1441, 1540), Vector2(120, 20), Vector2(0, -10))
	# West fence (vertical, height 210, base at Y: 1540, bridging down from top fence)
	_add_prop(objects, world, "res://assets/props/fence_vert_160.png", Vector2(1292, 1540), Vector2(20, 160), Vector2(0, -80))
	# East fence (vertical, height 210, base at Y: 1540, bridging down from top fence)
	_add_prop(objects, world, "res://assets/props/fence_vert_160.png", Vector2(1494, 1540), Vector2(20, 160), Vector2(0, -80))

	# Garden crops neatly placed inside the enclosed plot
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/18.png", Vector2(1390, 1420), Vector2(24, 20), Vector2(0, -6)) # Scarecrow!
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/12.png", Vector2(1340, 1450)) # Pumpkin
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/13.png", Vector2(1440, 1450)) # Pumpkin cluster
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(1330, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(1370, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(1410, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(1450, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(1330, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(1370, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(1410, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(1450, 1510)) # Green crop row 2

	# --- 2. ENCLOSED SHEEP PASTURE (SQUARE FENCE CORRAL: X: 1292..1494, Y: 1770..1970) ---
	# Width = 202 (2 horizontal fences, left post at 1292, right post at 1494)
	# Height = 200 (from 1770 to 1970)
	# North fence (top horizontal span from 1292 to 1494)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1340, 1770), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1441, 1770), Vector2(120, 20), Vector2(0, -10))
	# South fence (bottom horizontal span from 1292 to 1494)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1340, 1970), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1441, 1970), Vector2(120, 20), Vector2(0, -10))
	# West fence (left vertical span, height 250, base at Y: 1970, bridging down from top fence)
	_add_prop(objects, world, "res://assets/props/fence_vert_200.png", Vector2(1292, 1970), Vector2(20, 200), Vector2(0, -100))
	# East fence (right vertical span, height 250, base at Y: 1970, bridging down from top fence)
	_add_prop(objects, world, "res://assets/props/fence_vert_200.png", Vector2(1494, 1970), Vector2(20, 200), Vector2(0, -100))

	# 8 Fluffy Autonomous Grazing Sheep SNUGLY INSIDE the Square Pen!
	_add_sheep(objects, world, sheep_sc, Vector2(1340, 1820))
	_add_sheep(objects, world, sheep_sc, Vector2(1400, 1810))
	_add_sheep(objects, world, sheep_sc, Vector2(1450, 1820))
	_add_sheep(objects, world, sheep_sc, Vector2(1350, 1870))
	_add_sheep(objects, world, sheep_sc, Vector2(1420, 1860))
	_add_sheep(objects, world, sheep_sc, Vector2(1340, 1920))
	_add_sheep(objects, world, sheep_sc, Vector2(1390, 1930))
	_add_sheep(objects, world, sheep_sc, Vector2(1450, 1920))
	# Pasture flowers
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1370, 1840))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(1430, 1900))

	# Trees & nature framing the farm perimeter
	_add_tree(objects, world, tree_sc, 3, Vector2(1210, 1420))
	_add_tree(objects, world, tree_sc, 4, Vector2(1560, 1420))
	_add_tree(objects, world, tree_sc, 1, Vector2(1210, 1620))
	_add_tree(objects, world, tree_sc, 2, Vector2(1580, 1620))
	_add_tree(objects, world, tree_sc, 3, Vector2(1210, 1820))
	_add_tree(objects, world, tree_sc, 4, Vector2(1580, 1820))
	_add_tree(objects, world, tree_sc, 1, Vector2(1210, 1980))
	_add_tree(objects, world, tree_sc, 2, Vector2(1580, 1980))
	_add_bush(objects, world, bush_sc, 1, Vector2(1220, 1500))
	_add_bush(objects, world, bush_sc, 2, Vector2(1560, 1500))
	_add_bush(objects, world, bush_sc, 3, Vector2(1220, 1720))
	_add_bush(objects, world, bush_sc, 4, Vector2(1560, 1720))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1210, 1560))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(1580, 1560))

	# =========================================================================
	# ZONE 6: SOUTH WHISPERING SHORES & MYSTIC CAVERN (X: 800-1600, Y: 1850-2200)
	# =========================================================================
	_add_cave_entrance(objects, world, Vector2(1150, 1980))
	_add_sign(objects, world, Vector2(1050, 2020), "CaveSign", [
		"Mystic Cavern Signpost:",
		"Warning: Deep subterranean crystal chasms ahead.",
		"The descent is pitch black and fatal without a continuous source of light.",
		"A Cave Torch is required to enter. Seek Elder Oakhaven in Mossveil Village!"
	], "Cave Sign", true)

	_add_gold_rock(objects, world, gold_sc, Vector2(1270, 2010))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png", Vector2(1230, 2030))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 2.png", Vector2(1300, 2030))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png", Vector2(1420, 2060))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 2.png", Vector2(1480, 2050))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1150, 1910), Vector2(16, 16), Vector2(0, -6))

	# Shoreline Pines & Coastal Nature
	_add_tree(objects, world, tree_sc, 1, Vector2(980, 2050))
	_add_tree(objects, world, tree_sc, 2, Vector2(1360, 2060))
	_add_tree(objects, world, tree_sc, 1, Vector2(1520, 2050))
	_add_tree(objects, world, tree_sc, 2, Vector2(1640, 2040))
	_add_bush(objects, world, bush_sc, 1, Vector2(1020, 2100))
	_add_bush(objects, world, bush_sc, 2, Vector2(1320, 2110))
	_add_bush(objects, world, bush_sc, 3, Vector2(1600, 2100))

	# South Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(1000, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(1200, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(1400, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(1600, 2140))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(950, 2180))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(1250, 2190))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(1450, 2180))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(1650, 2180))

	# =========================================================================
	# ZONE 6B: SOUTH-EAST WHISPERING MEADOW & FISHER'S SHORE (X: 2100-3600, Y: 1650-2250)
	# Fills vast empty south-east green with Riverside Cottage, Fishing Pier, Stone Relic, and Orchard
	# =========================================================================
	# Meadow Haven / Fisherman's Cottage
	_add_building(objects, world, bld_sc, 2, Vector2(2800, 1850), "MeadowCottage")
	_add_prop(objects, world, "res://assets/props/fence_medium.png", Vector2(2720, 1920), Vector2(70, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(2880, 1910), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/crate_box.png", Vector2(2910, 1910), Vector2(30, 20), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2800, 1930), Vector2(16, 16), Vector2(0, -6))

	# Riverside Fishing Pier extending into the central river inlet
	_add_prop(objects, world, "res://assets/props/wooden_bridge_pier.png", Vector2(2120, 1920), Vector2(130, 30), Vector2(0, -15))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(2140, 1890), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(2170, 1890), Vector2(30, 20), Vector2(0, -5))

	# Ancient Sunken Monolith & Relic Stone Circle
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3260, 1930))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(3340, 1930))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(3260, 1970))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(3340, 1970))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(3300, 1950))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(3315, 1955))

	# Beautifully spaced orchard and meadow trees
	var se_trees := [
		Vector2(2250, 1740), Vector2(2480, 1720), Vector2(2720, 1740), Vector2(2960, 1710), Vector2(3200, 1740), Vector2(3440, 1710),
		Vector2(2360, 1880), Vector2(2580, 1860), Vector2(3060, 1880), Vector2(3480, 1870),
		Vector2(2240, 2020), Vector2(2460, 2040), Vector2(2680, 2010), Vector2(2940, 2030), Vector2(3140, 2020), Vector2(3460, 2020),
		Vector2(2320, 2130), Vector2(2560, 2120), Vector2(2800, 2140), Vector2(3040, 2120), Vector2(3280, 2130), Vector2(3520, 2120)
	]
	var se_t_idx := 0
	for tpos in se_trees:
		_add_tree(objects, world, tree_sc, (se_t_idx % 4) + 1, tpos)
		se_t_idx += 1

	var se_bushes := [
		Vector2(2380, 1780), Vector2(2850, 1770), Vector2(3320, 1770),
		Vector2(2480, 1940), Vector2(2650, 1950),
		Vector2(2380, 2070), Vector2(2880, 2080), Vector2(3350, 2080)
	]
	var se_b_idx := 0
	for bpos in se_bushes:
		_add_bush(objects, world, bush_sc, (se_b_idx % 4) + 1, bpos)
		se_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2620, 1760))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(3100, 1750))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(2360, 1980))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(3000, 2100))

	# South Coastline & River Inlet Water Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(2250, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2500, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2750, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(3000, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(3250, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(3500, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2060, 1750))
	_add_water_foam(objects, world, foam_sc, Vector2(2060, 1920))
	_add_water_foam(objects, world, foam_sc, Vector2(2060, 2080))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(2350, 2180))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(2700, 2180))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(3100, 2180))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(3450, 2180))

	# =========================================================================
	# ZONE 7: THE ROYAL CITADEL & EASTERN HIGHLANDS (East, X: 3500-4800, Y: 300-2200)
	# =========================================================================
	# Grand Royal Castle (320x256) atop the high eastern plateau
	_add_building(objects, world, bld_sc, 3, Vector2(4200, 480), "RoyalCastle")
	_add_building(objects, world, bld_sc, 4, Vector2(3750, 440), "CitadelTowerNorth")
	_add_building(objects, world, bld_sc, 4, Vector2(4650, 680), "CitadelTowerEast")
	_add_building(objects, world, bld_sc, 4, Vector2(4400, 1200), "CitadelTowerSouth")

	# Grand Royal Monastery / Cathedral (192x320)
	_add_building(objects, world, bld_sc, 5, Vector2(3750, 920), "Monastery")

	# Royal NPCs
	var elder_sc: PackedScene = load("res://scenes/npc_elder.tscn")
	var elder := elder_sc.instantiate()
	elder.name = "NPC_Elder"
	elder.position = Vector2(3660, 1000)
	objects.add_child(elder)
	elder.owner = world

	var lancer_sc: PackedScene = load("res://scenes/npc_lancer.tscn")
	var lancer := lancer_sc.instantiate()
	lancer.name = "NPC_Lancer"
	lancer.position = Vector2(3950, 680)
	objects.add_child(lancer)
	lancer.owner = world

	# Street Lanterns lining the Grand Avenue
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3500, 1000), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3850, 680), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(4100, 640), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(4350, 640), Vector2(16, 16), Vector2(0, -6))

	# Trees & nature around Citadel and Highland Plateau
	var citadel_trees := [
		Vector2(3880, 360), Vector2(4050, 340), Vector2(4350, 340), Vector2(4500, 380),
		Vector2(4600, 520), Vector2(4700, 600), Vector2(4750, 820), Vector2(4700, 1020),
		Vector2(4550, 1200), Vector2(4400, 1380), Vector2(4100, 1400), Vector2(3800, 1350),
		Vector2(3600, 1280), Vector2(3950, 1040), Vector2(4250, 1100),
		Vector2(3750, 1520), Vector2(4000, 1500), Vector2(4250, 1530), Vector2(4550, 1510), Vector2(4750, 1520),
		Vector2(3850, 1680), Vector2(4100, 1660), Vector2(4350, 1690), Vector2(4600, 1670), Vector2(4800, 1680),
		Vector2(3750, 1850), Vector2(4020, 1830), Vector2(4280, 1860), Vector2(4520, 1840), Vector2(4780, 1850),
		Vector2(3850, 2020), Vector2(4100, 2000), Vector2(4360, 2030), Vector2(4620, 2010), Vector2(4820, 2020),
		Vector2(3950, 2130), Vector2(4200, 2140), Vector2(4450, 2120), Vector2(4700, 2140)
	]
	var cit_t_idx := 0
	for tpos in citadel_trees:
		_add_tree(objects, world, tree_sc, (cit_t_idx % 4) + 1, tpos)
		cit_t_idx += 1

	var citadel_bushes := [
		Vector2(3680, 880), Vector2(4050, 680), Vector2(4350, 660), Vector2(4600, 750), Vector2(4500, 1100),
		Vector2(3900, 1500), Vector2(4480, 1500), Vector2(3950, 1860), Vector2(4400, 1880), Vector2(4150, 2050), Vector2(4650, 2050)
	]
	var cit_b_idx := 0
	for bpos in citadel_bushes:
		_add_bush(objects, world, bush_sc, (cit_b_idx % 4) + 1, bpos)
		cit_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3950, 380))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4650, 580))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(4480, 1250))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(4150, 1500))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4650, 1510))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(3920, 1850))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(4450, 1860))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(4300, 2070))

	# Eastern Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 500))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 800))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1100))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1400))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1650))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1900))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 2100))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(5000, 620))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(5020, 950))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(5000, 1280))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(5000, 1520))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(5020, 1800))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(5000, 2050))

	# =========================================================================
	# SKY LAYER: DRIFTING PARALLAX CLOUDS
	# =========================================================================
	var cloud_sc: PackedScene = load("res://scenes/entities/dynamic_cloud.tscn")
	for i in range(12):
		var cloud := cloud_sc.instantiate() as Sprite2D
		cloud.name = "Cloud_%d" % i
		cloud.position = Vector2(randf_range(100, 5000), randf_range(50, 500))
		world.add_child(cloud)
		cloud.owner = world

	# Pack and save to res://scenes/world.tscn!
	var packed := PackedScene.new()
	var pack_err := packed.pack(world)
	print("[WORLD GEN] Pack result:", pack_err)
	var save_err := ResourceSaver.save(packed, "res://scenes/world.tscn")
	print("[WORLD GEN] Save scenes/world.tscn result:", save_err)

	get_tree().quit()


# --- Road Autotiling Generator -----------------------------------------------

func _build_roads(terrain: TileMap) -> void:
	var roads: Dictionary = {}

	# 1. Snowy's Haven Trailhead (px: 6 to 11, py: 16)
	for x in range(6, 12):
		roads[Vector2i(x, 16)] = true

	# 2. The High Road - Ascending Branch (2-tiles wide, px: 10..11, py: 12..16)
	for y in range(12, 17):
		roads[Vector2i(10, y)] = true
		roads[Vector2i(11, y)] = true

	# 3. The High Road - Scenic Ridge Pass (2-tiles wide, px: 10..18, py: 11..12)
	for x in range(10, 19):
		roads[Vector2i(x, 11)] = true
		roads[Vector2i(x, 12)] = true

	# 4. The High Road - Valley Descent (2-tiles wide, px: 17..18, py: 12..16)
	for y in range(12, 17):
		roads[Vector2i(17, y)] = true
		roads[Vector2i(18, y)] = true

	# 5. Crossroads Hub & Branches (px: 17 to 20, py: 15 to 18)
	for x in range(17, 21):
		for y in range(15, 18):
			roads[Vector2i(x, y)] = true
	# North branch (to Training Grounds)
	for y in range(7, 16):
		roads[Vector2i(18, y)] = true
	# South branch (to Caverns)
	for y in range(17, 31):
		roads[Vector2i(18, y)] = true

	# 6. Village Main Avenue (2 tiles wide!)
	for x in range(19, 36):
		roads[Vector2i(x, 16)] = true
		roads[Vector2i(x, 17)] = true

	# 4. Grand Town Plaza (8 cols x 6 rows around ancient center oak)
	for px in range(35, 43):
		for py in range(14, 20):
			roads[Vector2i(px, py)] = true

	# 5. Road South from Plaza to River Bridge (farm lane passing between crop field and sheep pen)
	# West approach: connects from Cavern highway (px = 18) all the way across to Bridge left pier (px = 27)
	for px in range(18, 28):
		roads[Vector2i(px, 26)] = true

	# East approach: connects from Bridge right pier (px = 32) eastward to px = 37
	for px in range(32, 38):
		roads[Vector2i(px, 26)] = true

	# South avenue connecting Plaza (px: 36, 37) to Bridge approach
	for py in range(19, 27):
		roads[Vector2i(36, py)] = true
		roads[Vector2i(37, py)] = true

	# 5B. Meadow Trail extending east from bridge into South-East Meadow to the Cottage
	for px in range(38, 45):
		roads[Vector2i(px, 26)] = true
	for py in range(26, 31):
		roads[Vector2i(44, py)] = true

	# 6. Road East from Plaza towards Royal Citadel (2 tiles wide avenue)
	for px in range(42, 62):
		roads[Vector2i(px, 16)] = true
		roads[Vector2i(px, 17)] = true

	# 7. Citadel Castle Avenue (ascending north)
	for py in range(8, 17):
		roads[Vector2i(60, py)] = true
		roads[Vector2i(61, py)] = true
	for px in range(60, 68):
		roads[Vector2i(px, 8)] = true
		roads[Vector2i(px, 9)] = true

	# Autotile every cell on Layer 1
	for cell: Vector2i in roads.keys():
		var u := roads.has(cell + Vector2i(0, -1))
		var d := roads.has(cell + Vector2i(0, 1))
		var l := roads.has(cell + Vector2i(-1, 0))
		var r := roads.has(cell + Vector2i(1, 0))

		var atlas := Vector2i(6, 1) # Default solid center

		# Single-width linear paths
		if not u and not d and l and r:
			atlas = Vector2i(6, 3) # horizontal continuous
		elif not u and not d and not l and r:
			atlas = Vector2i(5, 3) # horizontal left end
		elif not u and not d and l and not r:
			atlas = Vector2i(7, 3) # horizontal right end
		elif u and d and not l and not r:
			atlas = Vector2i(8, 1) # vertical continuous
		elif not u and d and not l and not r:
			atlas = Vector2i(8, 0) # vertical top end
		elif u and not d and not l and not r:
			atlas = Vector2i(8, 2) # vertical bottom end
		elif not u and not d and not l and not r:
			atlas = Vector2i(8, 3) # 1x1 isolated
		# Outer corners of wide roads/plazas
		elif not u and not l:
			atlas = Vector2i(5, 0) # top-left corner
		elif not u and not r:
			atlas = Vector2i(7, 0) # top-right corner
		elif not d and not l:
			atlas = Vector2i(5, 2) # bottom-left corner
		elif not d and not r:
			atlas = Vector2i(7, 2) # bottom-right corner
		# Outer edges of wide roads/plazas
		elif not u:
			atlas = Vector2i(6, 0) # top edge
		elif not d:
			atlas = Vector2i(6, 2) # bottom edge
		elif not l:
			atlas = Vector2i(5, 1) # left edge
		elif not r:
			atlas = Vector2i(7, 1) # right edge
		else:
			atlas = Vector2i(6, 1) # solid center

		terrain.set_cell(1, cell, 1, atlas)


# --- Helper Functions --------------------------------------------------------

func _add_wall(parent: Node2D, owner_node: Node, pos: Vector2, size: Vector2) -> void:
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	parent.add_child(col)
	col.owner = owner_node

func _add_tree(parent: Node2D, owner_node: Node, sc: PackedScene, type: int, pos: Vector2) -> void:
	var t := sc.instantiate()
	t.tree_type = type
	t.position = pos
	parent.add_child(t)
	t.owner = owner_node

func _add_bush(parent: Node2D, owner_node: Node, sc: PackedScene, type: int, pos: Vector2) -> void:
	var b := sc.instantiate()
	b.bush_type = type
	b.position = pos
	parent.add_child(b)
	b.owner = owner_node

func _add_water_foam(parent: Node2D, owner_node: Node, sc: PackedScene, pos: Vector2) -> void:
	var f := sc.instantiate()
	f.position = pos
	parent.add_child(f)
	f.owner = owner_node

func _add_water_rock(parent: Node2D, owner_node: Node, sc: PackedScene, type: int, pos: Vector2) -> void:
	var r := sc.instantiate()
	r.rock_type = type
	r.position = pos
	parent.add_child(r)
	r.owner = owner_node

func _add_sheep(parent: Node2D, owner_node: Node, sc: PackedScene, pos: Vector2) -> void:
	var s := sc.instantiate()
	s.position = pos
	parent.add_child(s)
	s.owner = owner_node

func _add_building(parent: Node2D, owner_node: Node, sc: PackedScene, type: int, pos: Vector2, bname: String) -> void:
	var b := sc.instantiate()
	b.name = bname
	b.building_type = type
	b.position = pos
	parent.add_child(b)
	b.owner = owner_node

func _add_gold_rock(parent: Node2D, owner_node: Node, sc: PackedScene, pos: Vector2) -> void:
	var g := sc.instantiate()
	g.position = pos
	parent.add_child(g)
	g.owner = owner_node

func _add_enemy(parent: Node2D, owner_node: Node, sc: PackedScene, pos: Vector2) -> void:
	var e := sc.instantiate()
	e.position = pos
	parent.add_child(e)
	e.owner = owner_node

func _add_cave_entrance(parent: Node2D, owner_node: Node, pos: Vector2) -> void:
	var cave := StaticBody2D.new()
	cave.name = "CaveEntrance"
	cave.set_script(load("res://scripts/entities/cave_entrance.gd"))
	cave.position = pos
	cave.collision_layer = 1
	cave.collision_mask = 0

	parent.add_child(cave)
	cave.owner = owner_node

	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = load("res://Tiny Swords (Update 010)/everything/cave_dark.png")
	spr.position = Vector2(0, -32)
	cave.add_child(spr)
	spr.owner = owner_node

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100, 48)
	col.shape = shape
	col.position = Vector2(0, -16)
	cave.add_child(col)
	col.owner = owner_node

func _add_sign(parent: Node2D, owner_node: Node, pos: Vector2, sname: String, lines: Array, speaker: String, is_cave: bool = false) -> void:
	var sign_node := Area2D.new()
	sign_node.name = sname
	sign_node.position = pos
	sign_node.collision_layer = 64
	sign_node.collision_mask = 0
	sign_node.set_script(load("res://scripts/entities/world_sign.gd"))
	sign_node.set("speaker", speaker)
	var typed_lines: Array[String] = []
	for l in lines:
		typed_lines.append(str(l))
	sign_node.set("lines", typed_lines)
	sign_node.set("is_cave_sign", is_cave)

	parent.add_child(sign_node)
	sign_node.owner = owner_node

	var spr := Sprite2D.new()
	spr.texture = load("res://Tiny Swords (Update 010)/Decoration/17.png")
	spr.position = Vector2(0, -41)
	sign_node.add_child(spr)
	spr.owner = owner_node

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	col.position = Vector2(0, -10)
	sign_node.add_child(col)
	col.owner = owner_node

func _add_prop(parent: Node2D, owner_node: Node, tex_path: String, pos: Vector2, col_size: Vector2 = Vector2.ZERO, col_offset: Vector2 = Vector2.ZERO, z_idx: int = 0) -> Node2D:
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return null
	var node: Node2D
	if col_size != Vector2.ZERO:
		var body := StaticBody2D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		body.position = pos
		body.z_index = z_idx
		parent.add_child(body)
		body.owner = owner_node

		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = Vector2(0, -tex.get_height() * 0.5)
		body.add_child(spr)
		spr.owner = owner_node

		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = col_size
		col.shape = shape
		if col_offset == Vector2.ZERO:
			col.position = Vector2(0, -col_size.y * 0.5)
		else:
			col.position = col_offset
		body.add_child(col)
		col.owner = owner_node

		node = body
	else:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = pos
		spr.offset = Vector2(0, -tex.get_height() * 0.5)
		spr.z_index = z_idx
		parent.add_child(spr)
		spr.owner = owner_node
		node = spr

	return node
