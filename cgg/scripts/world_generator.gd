@tool
extends Node2D

func _ready() -> void:
	print("[WORLD GEN] Starting massive world redesign (5120x2304) with rich village, road network, and authentic props...")

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
	# River inlet cut at south-central: gx: 28..31, gy: 27..33
	for gx in range(2, 78):
		for gy in range(2, 34):
			# River inlet in the south (water shows through)
			if (gx >= 28 and gx <= 31) and gy >= 27:
				continue

			var atlas := Vector2i(1, 1) # default center grass

			var is_top := (gy == 2)
			var is_bottom := (gy == 33) or ((gx >= 28 and gx <= 31) and gy == 26)
			var is_left := (gx == 2) or (gx == 32 and gy >= 27)
			var is_right := (gx == 77) or (gx == 27 and gy >= 27)

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

	# --- Layer 2: Authentic Wooden Bridge over River at gy: 27 ---
	terrain.set_cell(2, Vector2i(27, 27), 2, Vector2i(0, 0)) # Left bridge pier connector
	terrain.set_cell(2, Vector2i(28, 27), 2, Vector2i(1, 0)) # Span 1
	terrain.set_cell(2, Vector2i(29, 27), 2, Vector2i(1, 0)) # Span 2
	terrain.set_cell(2, Vector2i(30, 27), 2, Vector2i(1, 0)) # Span 3
	terrain.set_cell(2, Vector2i(31, 27), 2, Vector2i(1, 0)) # Span 4
	terrain.set_cell(2, Vector2i(32, 27), 2, Vector2i(2, 0)) # Right bridge pier connector

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
	# ZONE 1: SNOWY'S COASTAL HAVEN (West, X: 150-900, Y: 900-1400)
	# =========================================================================
	_add_building(objects, world, bld_sc, 0, Vector2(380, 960), "SnowyCottage")
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(300, 1030), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_medium.png", Vector2(460, 1030), Vector2(70, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(460, 970), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(490, 970), Vector2(24, 24), Vector2(0, -5))

	# Fishing Pier extending into west sea
	_add_prop(objects, world, "res://assets/props/wooden_bridge_pier.png", Vector2(170, 1040), Vector2(130, 30), Vector2(0, -15))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(160, 1010), Vector2(24, 24), Vector2(0, -5))

	# Trees & nature around cottage
	_add_tree(objects, world, tree_sc, 1, Vector2(260, 880))
	_add_tree(objects, world, tree_sc, 2, Vector2(520, 860))
	_add_tree(objects, world, tree_sc, 3, Vector2(250, 1180))
	_add_tree(objects, world, tree_sc, 4, Vector2(560, 1180))
	_add_bush(objects, world, bush_sc, 1, Vector2(340, 1040))
	_add_bush(objects, world, bush_sc, 2, Vector2(430, 1040))
	_add_bush(objects, world, bush_sc, 3, Vector2(210, 940))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(360, 1070))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(440, 1070))

	# West Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(130, 850))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1040))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1230))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(100, 920))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(90, 1120))

	# Highway to Crossroads & Sign
	_add_tree(objects, world, tree_sc, 1, Vector2(800, 920))
	_add_tree(objects, world, tree_sc, 2, Vector2(980, 930))
	_add_bush(objects, world, bush_sc, 1, Vector2(860, 1060))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(740, 1000), Vector2(16, 16), Vector2(0, -6))
	_add_sign(objects, world, Vector2(1100, 1000), "CrossroadsSign", [
		"Oakhaven Crossroads Signpost:",
		"⬆ North: High Mountain Pass & Combat Training Grounds",
		"⬇ South: Whispering Shores & Mystic Cavern",
		"➔ East: Mossveil Village & Royal Citadel"
	], "Crossroads")

	# =========================================================================
	# ZONE 2: NORTHERN MOUNTAIN TRAINING GROUNDS (X: 1400-2600, Y: 250-750)
	# =========================================================================
	_add_building(objects, world, bld_sc, 4, Vector2(1850, 360), "TrainingTower")
	_add_building(objects, world, bld_sc, 6, Vector2(2250, 380), "ArcheryRange")
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1780, 480), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Wood/Trees/Stump 1.png", Vector2(2150, 470), Vector2(30, 20), Vector2(0, -5))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Tools/Tool_01.png", Vector2(2170, 465))
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(2200, 470), Vector2(30, 20), Vector2(0, -5))

	_add_tree(objects, world, tree_sc, 1, Vector2(1600, 260))
	_add_tree(objects, world, tree_sc, 2, Vector2(2050, 260))
	_add_tree(objects, world, tree_sc, 2, Vector2(2450, 280))
	_add_tree(objects, world, tree_sc, 1, Vector2(1500, 420))
	_add_bush(objects, world, bush_sc, 2, Vector2(1950, 480))
	_add_bush(objects, world, bush_sc, 4, Vector2(2350, 470))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1720, 390))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(2380, 410))

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
	# ZONE 3: MOSSVEIL VILLAGE & TOWN SQUARE (X: 1500-3600, Y: 800-1600)
	# =========================================================================
	# Village Entrance Archway & Guard
	_add_prop(objects, world, "res://assets/props/archway_lantern.png", Vector2(1620, 1024), Vector2(90, 24), Vector2(0, -10))
	_add_sign(objects, world, Vector2(1540, 1070), "VillageGateSign", [
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
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(2060, 1310), Vector2(30, 24), Vector2(0, -8))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Wood/Trees/Stump 2.png", Vector2(2100, 1315), Vector2(30, 20), Vector2(0, -5))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Tools/Tool_02.png", Vector2(2110, 1310))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(2140, 1310), Vector2(24, 24), Vector2(0, -5))
	var ravi_sc: PackedScene = load("res://scenes/npc_ravi.tscn")
	var ravi := ravi_sc.instantiate()
	ravi.name = "NPC_Ravi"
	ravi.position = Vector2(2080, 1220)
	objects.add_child(ravi)
	ravi.owner = world

	# Central Town Square & Grand Plaza (X: 2496, Y: 1088)
	# Ancient Village Oak in the center
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
	_add_tree(objects, world, tree_sc, 4, Vector2(3300, 840))
	_add_bush(objects, world, bush_sc, 1, Vector2(2280, 830))
	_add_bush(objects, world, bush_sc, 2, Vector2(2620, 830))
	_add_bush(objects, world, bush_sc, 3, Vector2(2950, 850))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2350, 870))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2650, 870))

	# =========================================================================
	# ZONE 4: FARMLAND, SHEEP PASTURE & RIVER CROSSING (X: 1300-2400, Y: 1350-2000)
	# =========================================================================
	# River Inlet (gx: 28..31, gy: 27..33 -> X: 1792..2048, Y: 1728..2112)
	# Lanterns at Bridge Ends
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1730, 1720), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2080, 1720), Vector2(16, 16), Vector2(0, -6))

	# River foam and splash rocks
	_add_water_foam(objects, world, foam_sc, Vector2(1920, 1850))
	_add_water_foam(objects, world, foam_sc, Vector2(1920, 2020))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(1890, 1880))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(1950, 2060))

	# Fenced Crop Field (West of River, X: 1400, Y: 1450)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1360, 1400), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1480, 1400), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1360, 1550), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1480, 1550), Vector2(120, 20), Vector2(0, -10))
	# Scarecrow in crop field!
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/18.png", Vector2(1420, 1470), Vector2(24, 20), Vector2(0, -6))
	# Pumpkins and vegetables in crop field!
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/12.png", Vector2(1360, 1480))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/13.png", Vector2(1480, 1480))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(1380, 1510))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(1460, 1510))

	# Fenced Sheep Pasture (South of Farmland, X: 1450, Y: 1750)
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1320, 1680), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1440, 1680), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1560, 1680), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1320, 1880), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1440, 1880), Vector2(120, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/fence_long.png", Vector2(1560, 1880), Vector2(120, 20), Vector2(0, -10))

	# 8 Fluffy Autonomous Grazing Sheep!
	_add_sheep(objects, world, sheep_sc, Vector2(1360, 1740))
	_add_sheep(objects, world, sheep_sc, Vector2(1440, 1760))
	_add_sheep(objects, world, sheep_sc, Vector2(1520, 1730))
	_add_sheep(objects, world, sheep_sc, Vector2(1380, 1820))
	_add_sheep(objects, world, sheep_sc, Vector2(1470, 1810))
	_add_sheep(objects, world, sheep_sc, Vector2(1540, 1840))
	_add_sheep(objects, world, sheep_sc, Vector2(1410, 1780))
	_add_sheep(objects, world, sheep_sc, Vector2(1490, 1760))

	_add_tree(objects, world, tree_sc, 3, Vector2(1300, 1640))
	_add_tree(objects, world, tree_sc, 4, Vector2(1620, 1640))
	_add_bush(objects, world, bush_sc, 1, Vector2(1310, 1750))
	_add_bush(objects, world, bush_sc, 2, Vector2(1590, 1790))

	# =========================================================================
	# ZONE 5: SOUTH WHISPERING SHORES & MYSTIC CAVERN (X: 800-1600, Y: 1850-2200)
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
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1150, 1910), Vector2(16, 16), Vector2(0, -6))

	# South Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(1000, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(1200, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(1400, 2140))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(950, 2180))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(1250, 2190))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(1450, 2180))

	# =========================================================================
	# ZONE 6: THE ROYAL CITADEL (East, X: 3500-4800, Y: 300-1600)
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

	# Trees & nature around Citadel
	_add_tree(objects, world, tree_sc, 1, Vector2(4000, 360))
	_add_tree(objects, world, tree_sc, 2, Vector2(4450, 380))
	_add_tree(objects, world, tree_sc, 1, Vector2(4600, 520))
	_add_tree(objects, world, tree_sc, 2, Vector2(3950, 1040))
	_add_tree(objects, world, tree_sc, 3, Vector2(4250, 1100))
	_add_bush(objects, world, bush_sc, 3, Vector2(3680, 880))
	_add_bush(objects, world, bush_sc, 4, Vector2(4050, 680))
	_add_bush(objects, world, bush_sc, 2, Vector2(4350, 660))

	# Eastern Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 500))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 800))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1100))
	_add_water_foam(objects, world, foam_sc, Vector2(4950, 1400))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(5000, 620))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(5020, 950))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(5000, 1280))

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

	# 1. Main West Highway (from Snowy's house to crossroads)
	for x in range(6, 19):
		roads[Vector2i(x, 16)] = true

	# 2. Crossroads Hub & Branches
	for x in range(17, 20):
		for y in range(15, 18):
			roads[Vector2i(x, y)] = true
	# North branch (to Training Grounds)
	for y in range(7, 16):
		roads[Vector2i(18, y)] = true
	# South branch (to Caverns)
	for y in range(17, 31):
		roads[Vector2i(18, y)] = true

	# 3. Village Main Avenue (2 tiles wide!)
	for x in range(19, 36):
		roads[Vector2i(x, 16)] = true
		roads[Vector2i(x, 17)] = true

	# 4. Grand Town Plaza (8 cols x 6 rows around ancient center oak)
	for px in range(35, 43):
		for py in range(14, 20):
			roads[Vector2i(px, py)] = true

	# 5. Road South from Plaza to River Bridge
	for py in range(19, 28):
		roads[Vector2i(30, py)] = true
		roads[Vector2i(31, py)] = true
	# Road leading across river (approaches on both sides of bridge)
	for px in range(24, 28):
		roads[Vector2i(px, 27)] = true
	for px in range(32, 36):
		roads[Vector2i(px, 27)] = true

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
	spr.position = Vector2(0, -32)
	sign_node.add_child(spr)
	spr.owner = owner_node

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
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
		col.position = col_offset
		body.add_child(col)
		col.owner = owner_node

		node = body
	else:
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = pos + Vector2(0, -tex.get_height() * 0.5)
		spr.z_index = z_idx
		parent.add_child(spr)
		spr.owner = owner_node
		node = spr

	return node
