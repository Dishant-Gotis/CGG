@tool
extends Node2D

func _ready() -> void:
	print("[WORLD GEN] Generating dense, rich, handcrafted fantasy world (6400x2304)...")

	var world := Node2D.new()
	world.name = "World"
	world.set_script(load("res://scripts/world.gd"))

	# 1. Background Ocean Water (Deep Turquoise)
	var bg_water := TextureRect.new()
	bg_water.name = "WaterBackground"
	bg_water.texture = load(Assets.WATER_BG)
	bg_water.stretch_mode = TextureRect.STRETCH_TILE
	bg_water.size = Vector2(6400, 2304)
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

	# --- Layer 0: Ground Landmass (100 cols x 36 rows) ---
	# Island spans from gx: 2 to 97, gy: 2 to 33.
	# River cut at south-central: gx: 48..51, gy: 26..33
	for gx in range(2, 98):
		for gy in range(2, 34):
			# River inlet in the south (water shows through)
			if (gx >= 48 and gx <= 51) and gy >= 26:
				continue

			var atlas := Vector2i(1, 1) # default center grass

			var is_top := (gy == 2)
			var is_bottom := (gy == 33) or ((gx >= 48 and gx <= 51) and gy == 25)
			var is_left := (gx == 2) or (gx == 52 and gy >= 26)
			var is_right := (gx == 97) or (gx == 47 and gy >= 26)

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
	terrain.set_cell(2, Vector2i(47, 26), 2, Vector2i(0, 0)) # Left bridge pier connector
	terrain.set_cell(2, Vector2i(48, 26), 2, Vector2i(1, 0)) # Span 1
	terrain.set_cell(2, Vector2i(49, 26), 2, Vector2i(1, 0)) # Span 2
	terrain.set_cell(2, Vector2i(50, 26), 2, Vector2i(1, 0)) # Span 3
	terrain.set_cell(2, Vector2i(51, 26), 2, Vector2i(1, 0)) # Span 4
	terrain.set_cell(2, Vector2i(52, 26), 2, Vector2i(2, 0)) # Right bridge pier connector

	# 3. World Boundaries
	var bounds := StaticBody2D.new()
	bounds.name = "WorldBounds"
	bounds.collision_mask = 0
	world.add_child(bounds)
	bounds.owner = world

	_add_wall(bounds, world, Vector2(3200, 0), Vector2(6400, 24))
	_add_wall(bounds, world, Vector2(3200, 2304), Vector2(6400, 24))
	_add_wall(bounds, world, Vector2(0, 1152), Vector2(24, 2304))
	_add_wall(bounds, world, Vector2(6400, 1152), Vector2(24, 2304))

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
	spawn_cave.position = Vector2(2430, 1960)
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
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(470, 960), Vector2(24, 24), Vector2(0, -5))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(500, 960), Vector2(24, 24), Vector2(0, -5))

	# Fishing Pier extending into west sea
	_add_prop(objects, world, "res://assets/props/wooden_bridge_pier.png", Vector2(170, 1040), Vector2(130, 30), Vector2(0, -15))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(160, 1010), Vector2(24, 24), Vector2(0, -5))

	# Trees framing the haven safely behind and to the sides (NO overlap with player spawn or road)
	_add_tree(objects, world, tree_sc, 1, Vector2(240, 840)) # NW of house
	_add_tree(objects, world, tree_sc, 2, Vector2(540, 840)) # NE of house
	_add_tree(objects, world, tree_sc, 3, Vector2(200, 1180)) # West by shore
	_add_bush(objects, world, bush_sc, 1, Vector2(230, 1030))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(320, 1010))

	# West Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(130, 850))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1040))
	_add_water_foam(objects, world, foam_sc, Vector2(130, 1230))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(100, 920))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(90, 1120))

	# =========================================================================
	# ZONE 1: THE WHISPERING FOREST TRAIL & SLIME COMBAT TUTORIAL (X: 384-2816)
	# A 2,432-pixel long, straight east-west forest highway connecting Snowy's Haven
	# to the Oakhaven Crossroads and Mossveil Village Gate.
	#
	# FIRST HALF (X: 384-1600):
	#   - Completely peaceful woodland journey, NO SLIMES!
	#   - Flanked north and south by dense pine and oak trees, bushes, and flowers.
	#
	# MIDPOINT (X: 1600):
	#   - Woodcutter's Rest Point (stump bench, logs, axe, lantern).
	#   - Wildwoods Border Sign & Combat Guide Sign warning of infested deep forest ahead.
	#
	# SECOND HALF (X: 1600-2816):
	#   - SLIMES APPEAR!
	#   - 8 Progressive slime encounters spaced out along the straight road.
	#   - Hero learns battle mechanics ([Q] attack, spacing, knockback) before reaching
	#     the Oakhaven Crossroads and Village Gate.
	# =========================================================================

	# Trailhead near Kitsu (X: 520, Y: 1060)
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(580, 1000), Vector2(16, 16), Vector2(0, -6))
	_add_sign(objects, world, Vector2(560, 1010), "TrailheadSign", [
		"Whispering Forest Trail ➔: Scenic path east to Mossveil Village.",
		"The journey ahead is long. Take your time to enjoy the calm woodland air.",
		"Stay on the path to keep your bearings."
	], "Trail Guide")

	# --- FIRST HALF (X: 384 to 1600): PEACEFUL FOREST (NO SLIMES) ---
	# North Forest Trees (Y: 900..930 front, Y: 780..820 deep)
	var fh_north_trees := [
		Vector2(600, 920), Vector2(720, 900), Vector2(840, 930), Vector2(960, 910),
		Vector2(1080, 930), Vector2(1200, 900), Vector2(1320, 920), Vector2(1440, 910), Vector2(1560, 930),
		Vector2(660, 800), Vector2(780, 780), Vector2(900, 810), Vector2(1020, 770),
		Vector2(1140, 800), Vector2(1260, 780), Vector2(1380, 810), Vector2(1500, 790)
	]
	var fh_nt_idx := 0
	for tpos in fh_north_trees:
		_add_tree(objects, world, tree_sc, (fh_nt_idx % 4) + 1, tpos)
		fh_nt_idx += 1

	# South Forest Trees (Y: 1220..1250 front, Y: 1330..1360 deep)
	var fh_south_trees := [
		Vector2(580, 1220), Vector2(700, 1240), Vector2(820, 1220), Vector2(940, 1240),
		Vector2(1060, 1220), Vector2(1180, 1240), Vector2(1300, 1220), Vector2(1420, 1240), Vector2(1540, 1220),
		Vector2(640, 1340), Vector2(760, 1360), Vector2(880, 1330), Vector2(1000, 1360),
		Vector2(1120, 1340), Vector2(1240, 1360), Vector2(1360, 1330), Vector2(1480, 1350)
	]
	var fh_st_idx := 0
	for tpos in fh_south_trees:
		_add_tree(objects, world, tree_sc, (fh_st_idx % 4) + 1, tpos)
		fh_st_idx += 1

	# First half bushes, rocks, flowers & lanterns
	var fh_bushes := [
		Vector2(640, 940), Vector2(760, 930), Vector2(880, 945), Vector2(1000, 930),
		Vector2(1120, 945), Vector2(1240, 930), Vector2(1360, 940), Vector2(1480, 935),
		Vector2(620, 1115), Vector2(740, 1120), Vector2(860, 1115), Vector2(980, 1120),
		Vector2(1100, 1115), Vector2(1220, 1120), Vector2(1340, 1115), Vector2(1460, 1120)
	]
	var fh_b_idx := 0
	for bpos in fh_bushes:
		_add_bush(objects, world, bush_sc, (fh_b_idx % 4) + 1, bpos)
		fh_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(680, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(820, 945))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(1040, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(1280, 945))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1420, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(670, 1135))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(910, 1130))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(1140, 1135))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1390, 1130))

	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(590, 970))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(800, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1160, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(1390, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(650, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(850, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1070, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(1280, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1510, 1115))

	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(860, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1120, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1380, 1005), Vector2(16, 16), Vector2(0, -6))

	# First half peaceful rest spot (woodcutter's bench)
	_add_prop(objects, world, "res://assets/props/stump_3.png", Vector2(1100, 940), Vector2(24, 20), Vector2(0, -10))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(1140, 940), Vector2(40, 18), Vector2(0, -9))

	# --- MIDPOINT (X: 1600): WILDWOODS BORDER & COMBAT TUTORIAL GUIDE ---
	_add_prop(objects, world, "res://assets/props/stump_4.png", Vector2(1580, 940), Vector2(26, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/tool_04.png", Vector2(1595, 935))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(1620, 940), Vector2(40, 18), Vector2(0, -9))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1600, 1005), Vector2(16, 16), Vector2(0, -6))

	_add_sign(objects, world, Vector2(1570, 1010), "BorderWarningSign", [
		"Wildwoods Border:",
		"Danger: Wild slimes have infested the road ahead!",
		"Arm yourself with the Hero's Blade before venturing further."
	], "Border Sign")

	_add_sign(objects, world, Vector2(1660, 990), "CombatTutorialSign", [
		"Combat Guide — Hero's Blade:",
		"Press [Q] to swing your sword at nearby adversaries.",
		"Slimes take 2 decisive strikes. Time your attacks and keep moving!",
		"Defeat the slimes to clear the road forward."
	], "Combat Guide")

	# --- SECOND HALF (X: 1600 to 2816): SLIMES APPEAR! ---
	_add_enemy(objects, world, enemy_sc, Vector2(1760, 1056))   # Slime 1 (Introductory 1v1 right after sign)
	_add_enemy(objects, world, enemy_sc, Vector2(1960, 1056))   # Slime 2 (Open trail encounter)
	_add_enemy(objects, world, enemy_sc, Vector2(2160, 1040))   # Slime 3 (Mid-trail pack member 1)
	_add_enemy(objects, world, enemy_sc, Vector2(2210, 1070))   # Slime 4 (Mid-trail pack member 2)
	_add_enemy(objects, world, enemy_sc, Vector2(2400, 1056))   # Slime 5 (Deep forest encounter)
	_add_enemy(objects, world, enemy_sc, Vector2(2580, 1040))   # Slime 6 (Deep woods pack member 1)
	_add_enemy(objects, world, enemy_sc, Vector2(2630, 1070))   # Slime 7 (Deep woods pack member 2)
	_add_enemy(objects, world, enemy_sc, Vector2(2760, 1056))   # Slime 8 (Crossroads gateway guardian)

	# Second half lanterns
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(1880, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2140, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2380, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2600, 1005), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2800, 1005), Vector2(16, 16), Vector2(0, -6))

	# Second half North Trees (Y: 900..930 front, Y: 780..820 deep)
	var sh_north_trees := [
		Vector2(1680, 920), Vector2(1800, 900), Vector2(1920, 930), Vector2(2040, 910),
		Vector2(2160, 930), Vector2(2280, 900), Vector2(2400, 920), Vector2(2520, 910), Vector2(2640, 930), Vector2(2760, 910),
		Vector2(1740, 800), Vector2(1860, 780), Vector2(1980, 810), Vector2(2100, 770),
		Vector2(2220, 800), Vector2(2340, 780), Vector2(2460, 810), Vector2(2580, 790), Vector2(2700, 810)
	]
	var sh_nt_idx := 0
	for tpos in sh_north_trees:
		_add_tree(objects, world, tree_sc, (sh_nt_idx % 4) + 1, tpos)
		sh_nt_idx += 1

	# Second half South Trees (Y: 1220..1250 front, Y: 1330..1360 deep)
	var sh_south_trees := [
		Vector2(1660, 1220), Vector2(1780, 1240), Vector2(1900, 1220), Vector2(2020, 1240),
		Vector2(2140, 1220), Vector2(2260, 1240), Vector2(2380, 1220), Vector2(2500, 1240), Vector2(2620, 1220), Vector2(2740, 1240),
		Vector2(1720, 1340), Vector2(1840, 1360), Vector2(1960, 1330), Vector2(2080, 1360),
		Vector2(2200, 1340), Vector2(2320, 1360), Vector2(2440, 1330), Vector2(2560, 1350), Vector2(2680, 1330)
	]
	var sh_st_idx := 0
	for tpos in sh_south_trees:
		_add_tree(objects, world, tree_sc, (sh_st_idx % 4) + 1, tpos)
		sh_st_idx += 1

	# Second half bushes, rocks & flowers
	var sh_bushes := [
		Vector2(1720, 940), Vector2(1840, 930), Vector2(1960, 945), Vector2(2080, 930),
		Vector2(2200, 945), Vector2(2320, 930), Vector2(2440, 940), Vector2(2560, 935), Vector2(2680, 940),
		Vector2(1700, 1115), Vector2(1820, 1120), Vector2(1940, 1115), Vector2(2060, 1120),
		Vector2(2180, 1115), Vector2(2300, 1120), Vector2(2420, 1115), Vector2(2540, 1120), Vector2(2660, 1115), Vector2(2780, 1120)
	]
	var sh_b_idx := 0
	for bpos in sh_bushes:
		_add_bush(objects, world, bush_sc, (sh_b_idx % 4) + 1, bpos)
		sh_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(1780, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(2020, 945))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(2260, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(2480, 945))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2700, 950))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(1770, 1135))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(2010, 1130))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(2250, 1135))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2490, 1130))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(2730, 1135))

	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(1820, 970))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2060, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2300, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2520, 965))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2720, 970))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(1850, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2070, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2280, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2510, 1115))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2730, 1115))

	# --- OAKHAVEN CROSSROADS (Village Threshold, X: 2816-2944) ---
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2850, 980), Vector2(16, 16), Vector2(0, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2930, 980), Vector2(16, 16), Vector2(0, -6))
	_add_sign(objects, world, Vector2(2870, 990), "CrossroadsSign", [
		"Oakhaven Crossroads Signpost:",
		"⬆ North: High Mountain Pass & Combat Training Grounds",
		"⬇ South: Whispering Shores & Mystic Cavern",
		"➔ East: Mossveil Village & Royal Citadel",
		"⬅ West: Whispering Forest Trail to Snowy's Haven"
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
	_add_building(objects, world, bld_sc, 4, Vector2(3130, 360), "TrainingTower")
	_add_building(objects, world, bld_sc, 6, Vector2(3530, 380), "ArcheryRange")
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3060, 480), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/stump_1.png", Vector2(3430, 470), Vector2(1316, 22), Vector2(1280, -11))
	_add_prop(objects, world, "res://assets/props/tool_01.png", Vector2(3450, 465))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(3480, 470), Vector2(1320, 18), Vector2(1280, -9))

	_add_tree(objects, world, tree_sc, 1, Vector2(2680, 260))
	_add_tree(objects, world, tree_sc, 2, Vector2(2880, 250))
	_add_tree(objects, world, tree_sc, 1, Vector2(3080, 240))
	_add_tree(objects, world, tree_sc, 2, Vector2(3330, 250))
	_add_tree(objects, world, tree_sc, 1, Vector2(3530, 240))
	_add_tree(objects, world, tree_sc, 2, Vector2(3730, 260))
	_add_tree(objects, world, tree_sc, 3, Vector2(2600, 360))
	_add_tree(objects, world, tree_sc, 4, Vector2(2780, 420))
	_add_tree(objects, world, tree_sc, 1, Vector2(2960, 280))
	_add_tree(objects, world, tree_sc, 2, Vector2(3200, 260))
	_add_tree(objects, world, tree_sc, 3, Vector2(3440, 280))
	_add_tree(objects, world, tree_sc, 4, Vector2(3660, 290))
	_add_tree(objects, world, tree_sc, 1, Vector2(3830, 380))
	_add_bush(objects, world, bush_sc, 1, Vector2(2730, 460))
	_add_bush(objects, world, bush_sc, 2, Vector2(3230, 480))
	_add_bush(objects, world, bush_sc, 3, Vector2(3380, 440))
	_add_bush(objects, world, bush_sc, 4, Vector2(3630, 470))
	_add_bush(objects, world, bush_sc, 1, Vector2(3780, 450))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3000, 390))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(3660, 410))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(2860, 320))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(3300, 340))

	_add_sign(objects, world, Vector2(3030, 500), "TrainingSign", [
		"High Mountain Training Grounds:",
		"Press [Q] to swing your sword at nearby adversaries.",
		"Armored and shadowy beasts require decisive strikes.",
		"Master your skills before proceeding deeper into the realm!"
	], "Training Sign")

	# Enemies
	_add_enemy(objects, world, enemy_sc, Vector2(3200, 520))
	_add_enemy(objects, world, enemy_sc, Vector2(3400, 530))
	_add_enemy(objects, world, torch_sc, Vector2(3580, 500))

	# =========================================================================
	# ZONE 3B: NORTH-EAST WHISPERING WILDERNESS & BANDIT RUINS (X: 2700-4900, Y: 150-750)
	# Fills vast empty northern plateau with pine wilderness, ruined watchtower & bandit campsite
	# =========================================================================
	_add_building(objects, world, bld_sc, 4, Vector2(4630, 360), "WildernessWatchtower")
	_add_prop(objects, world, "res://assets/props/stump_1.png", Vector2(4720, 420), Vector2(1316, 22), Vector2(1280, -11))
	_add_prop(objects, world, "res://assets/props/tool_01.png", Vector2(4735, 415))
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(4760, 420), Vector2(1320, 18), Vector2(1280, -9))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(4540, 410), Vector2(1304, 24), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(4630, 440), Vector2(1296, 16), Vector2(1280, -6))
	_add_enemy(objects, world, torch_sc, Vector2(4700, 460))

	var ne_trees := [
		Vector2(4030, 240), Vector2(4260, 220), Vector2(4480, 250), Vector2(4730, 220), Vector2(4980, 240), Vector2(5230, 220), Vector2(5480, 240), Vector2(5730, 220), Vector2(5980, 250),
		Vector2(4130, 400), Vector2(4380, 420), Vector2(4860, 400), Vector2(5100, 420), Vector2(5360, 390), Vector2(5620, 410), Vector2(5880, 390), Vector2(6080, 420),
		Vector2(4000, 560), Vector2(4230, 580), Vector2(4500, 560), Vector2(4760, 580), Vector2(5000, 560), Vector2(5260, 590), Vector2(5520, 570), Vector2(5780, 590), Vector2(6020, 570),
		Vector2(4120, 720), Vector2(4340, 700), Vector2(4560, 730), Vector2(4800, 710)
	]
	var ne_t_idx := 0
	for tpos in ne_trees:
		_add_tree(objects, world, tree_sc, (ne_t_idx % 4) + 1, tpos)
		ne_t_idx += 1

	var ne_bushes := [
		Vector2(4100, 320), Vector2(4580, 280), Vector2(5060, 330), Vector2(5530, 310), Vector2(5960, 330),
		Vector2(4200, 490), Vector2(4900, 480), Vector2(5430, 490), Vector2(5930, 480),
		Vector2(4080, 650), Vector2(4660, 650)
	]
	var ne_b_idx := 0
	for bpos in ne_bushes:
		_add_bush(objects, world, bush_sc, (ne_b_idx % 4) + 1, bpos)
		ne_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(4180, 260))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4880, 270))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(5580, 260))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(4430, 480))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(5180, 470))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(6030, 490))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(4280, 660))

	# Northern Ocean Coastline Foam & Water Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(4080, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(4480, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(4880, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(5280, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(5680, 130))
	_add_water_foam(objects, world, foam_sc, Vector2(6080, 130))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(4280, 90))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(4680, 90))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(5080, 90))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(5480, 90))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(5880, 90))

	# =========================================================================
	# ZONE 4: MOSSVEIL VILLAGE & TOWN SQUARE (X: 1650-3600, Y: 800-1600)
	# =========================================================================
	# Village Entrance Archway & Guard
	_add_prop(objects, world, "res://assets/props/archway_lantern.png", Vector2(2970, 1024), Vector2(1370, 24), Vector2(1280, -10))
	_add_sign(objects, world, Vector2(2930, 980), "VillageGateSign", [
		"Welcome to Mossveil Village!",
		"You are protected by the royal decree of King Aldous.",
		"Follow the main avenue east to reach the town square and citadel."
	], "Village Gate")

	var guard_sc: PackedScene = load("res://scenes/npc_guard.tscn")
	var guard := guard_sc.instantiate()
	guard.name = "NPC_Guard"
	guard.position = Vector2(3060, 1024)
	objects.add_child(guard)
	guard.owner = world

	# Residential Quarter (West Village)
	_add_building(objects, world, bld_sc, 0, Vector2(3230, 860), "VillageHouse_West1")
	_add_building(objects, world, bld_sc, 1, Vector2(3460, 840), "VillageHouse_West2")
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(3540, 890), Vector2(1304, 24), Vector2(1280, -5))

	# Maya's Residence
	_add_building(objects, world, bld_sc, 2, Vector2(4030, 820), "VillageHouse_Maya")
	var maya_sc: PackedScene = load("res://scenes/npc_maya.tscn")
	var maya := maya_sc.instantiate()
	maya.name = "NPC_Maya"
	maya.position = Vector2(3980, 900)
	objects.add_child(maya)
	maya.owner = world

	# Ravi's Woodcraft Workshop (South-West Village)
	_add_building(objects, world, bld_sc, 7, Vector2(3260, 1260), "BarracksWorkshop")
	_add_prop(objects, world, "res://assets/props/wood_log.png", Vector2(3340, 1310), Vector2(1320, 18), Vector2(1280, -9))
	_add_prop(objects, world, "res://assets/props/stump_2.png", Vector2(3380, 1315), Vector2(1316, 20), Vector2(1280, -10))
	_add_prop(objects, world, "res://assets/props/tool_02.png", Vector2(3390, 1310))
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(3420, 1310), Vector2(1304, 24), Vector2(1280, -5))
	var ravi_sc: PackedScene = load("res://scenes/npc_ravi.tscn")
	var ravi := ravi_sc.instantiate()
	ravi.name = "NPC_Ravi"
	ravi.position = Vector2(3360, 1220)
	objects.add_child(ravi)
	ravi.owner = world

	# Central Town Square & Grand Plaza (X: 2496, Y: 1088)
	_add_tree(objects, world, tree_sc, 4, Vector2(3776, 1050))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3600, 980), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3940, 980), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3600, 1180), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3940, 1180), Vector2(1296, 16), Vector2(1280, -6))

	_add_sign(objects, world, Vector2(3660, 1140), "TownSquareSign", [
		"Mossveil Town Square:",
		"North: Residential Quarter & Flower Gardens",
		"East: High Bridge to Royal Citadel",
		"South: River Cross, Farm Fields & Pastures",
		"West: Village Gate & Forest Road"
	], "Town Square")

	# Market Stalls & Produce (South of Plaza)
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(3700, 1250), Vector2(1304, 24), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(3730, 1250), Vector2(1304, 24), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(3765, 1250), Vector2(1310, 20), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/crate_box.png", Vector2(3800, 1250), Vector2(1310, 20), Vector2(1280, -5))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/12.png", Vector2(3830, 1255))

	# Additional Village Houses (East Village)
	_add_building(objects, world, bld_sc, 0, Vector2(4330, 840), "VillageHouse_East1")
	_add_building(objects, world, bld_sc, 1, Vector2(4130, 1260), "VillageHouse_East2")
	_add_building(objects, world, bld_sc, 2, Vector2(4460, 1240), "VillageHouse_East3")

	# Trees & nature around village
	_add_tree(objects, world, tree_sc, 3, Vector2(3280, 720))
	_add_tree(objects, world, tree_sc, 4, Vector2(3580, 720))
	_add_tree(objects, world, tree_sc, 3, Vector2(3860, 710))
	_add_tree(objects, world, tree_sc, 4, Vector2(4160, 710))
	_add_tree(objects, world, tree_sc, 1, Vector2(4380, 720))
	_add_tree(objects, world, tree_sc, 4, Vector2(4580, 840))
	_add_tree(objects, world, tree_sc, 2, Vector2(4660, 1020))
	_add_tree(objects, world, tree_sc, 3, Vector2(4630, 1260))
	_add_tree(objects, world, tree_sc, 1, Vector2(3980, 1380))
	_add_tree(objects, world, tree_sc, 2, Vector2(3630, 1380))
	_add_bush(objects, world, bush_sc, 1, Vector2(3560, 830))
	_add_bush(objects, world, bush_sc, 2, Vector2(3900, 830))
	_add_bush(objects, world, bush_sc, 3, Vector2(4230, 850))
	_add_bush(objects, world, bush_sc, 4, Vector2(4530, 960))
	_add_bush(objects, world, bush_sc, 1, Vector2(3800, 1360))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3400, 750))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4280, 750))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(3630, 870))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(3930, 870))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(4180, 920))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(4400, 920))

	# =========================================================================
	# ZONE 5: ENCLOSED FARMLAND & ENCLOSED SHEEP PASTURE (SQUARE FENCE PENS)
	# =========================================================================
	# Lanterns at Bridge Ends
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3010, 1660), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(3360, 1660), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2530, 1660), Vector2(1296, 16), Vector2(1280, -6))

	# River foam and splash rocks
	_add_water_foam(objects, world, foam_sc, Vector2(3200, 1800))
	_add_water_foam(objects, world, foam_sc, Vector2(3200, 2020))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(3170, 1840))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(3230, 2060))

	# --- 1. CROP GARDEN PLOT (X: 1300..1480, Y: 1400..1540) ---
	# Garden crops neatly organized with scarecrow and pumpkins
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/18.png", Vector2(2670, 1420), Vector2(1304, 20), Vector2(1280, -6)) # Scarecrow!
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/12.png", Vector2(2620, 1450)) # Pumpkin
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/13.png", Vector2(2720, 1450)) # Pumpkin cluster
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(2610, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(2650, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(2690, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(2730, 1480)) # Green crop row 1
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(2610, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(2650, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/10.png", Vector2(2690, 1510)) # Green crop row 2
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/11.png", Vector2(2730, 1510)) # Green crop row 2

	# --- 2. SHEEP PASTURE (X: 1300..1480, Y: 1780..1960) ---
	# 8 Fluffy Autonomous Grazing Sheep in lush green meadow
	_add_sheep(objects, world, sheep_sc, Vector2(2620, 1820))
	_add_sheep(objects, world, sheep_sc, Vector2(2680, 1810))
	_add_sheep(objects, world, sheep_sc, Vector2(2730, 1820))
	_add_sheep(objects, world, sheep_sc, Vector2(2630, 1870))
	_add_sheep(objects, world, sheep_sc, Vector2(2700, 1860))
	_add_sheep(objects, world, sheep_sc, Vector2(2620, 1920))
	_add_sheep(objects, world, sheep_sc, Vector2(2670, 1930))
	_add_sheep(objects, world, sheep_sc, Vector2(2730, 1920))
	# Pasture flowers
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(2650, 1840))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(2710, 1900))

	# Trees & nature framing the farm perimeter
	_add_tree(objects, world, tree_sc, 3, Vector2(2490, 1420))
	_add_tree(objects, world, tree_sc, 4, Vector2(2840, 1420))
	_add_tree(objects, world, tree_sc, 1, Vector2(2490, 1620))
	_add_tree(objects, world, tree_sc, 2, Vector2(2860, 1620))
	_add_tree(objects, world, tree_sc, 3, Vector2(2490, 1820))
	_add_tree(objects, world, tree_sc, 4, Vector2(2860, 1820))
	_add_tree(objects, world, tree_sc, 1, Vector2(2490, 1980))
	_add_tree(objects, world, tree_sc, 2, Vector2(2860, 1980))
	_add_bush(objects, world, bush_sc, 1, Vector2(2500, 1500))
	_add_bush(objects, world, bush_sc, 2, Vector2(2840, 1500))
	_add_bush(objects, world, bush_sc, 3, Vector2(2500, 1720))
	_add_bush(objects, world, bush_sc, 4, Vector2(2840, 1720))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(2490, 1560))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(2860, 1560))

	# =========================================================================
	# ZONE 6: SOUTH WHISPERING SHORES & MYSTIC CAVERN (X: 800-1600, Y: 1850-2200)
	# =========================================================================
	_add_cave_entrance(objects, world, Vector2(2430, 1980))
	_add_sign(objects, world, Vector2(2330, 2020), "CaveSign", [
		"Mystic Cavern Signpost:",
		"Warning: Deep subterranean crystal chasms ahead.",
		"The descent is pitch black and fatal without a continuous source of light.",
		"A Cave Torch is required to enter. Seek Elder Oakhaven in Mossveil Village!"
	], "Cave Sign", true)

	_add_gold_rock(objects, world, gold_sc, Vector2(2550, 2010))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png", Vector2(2510, 2030))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 2.png", Vector2(2580, 2030))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 1.png", Vector2(2700, 2060))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Resources/Gold/Gold Stones/Gold Stone 2.png", Vector2(2760, 2050))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(2430, 1910), Vector2(1296, 16), Vector2(1280, -6))

	# Shoreline Pines & Coastal Nature
	_add_tree(objects, world, tree_sc, 1, Vector2(2260, 2050))
	_add_tree(objects, world, tree_sc, 2, Vector2(2640, 2060))
	_add_tree(objects, world, tree_sc, 1, Vector2(2800, 2050))
	_add_tree(objects, world, tree_sc, 2, Vector2(2920, 2040))
	_add_bush(objects, world, bush_sc, 1, Vector2(2300, 2100))
	_add_bush(objects, world, bush_sc, 2, Vector2(2600, 2110))
	_add_bush(objects, world, bush_sc, 3, Vector2(2880, 2100))

	# South Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(2280, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2480, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2680, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(2880, 2140))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(2230, 2180))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(2530, 2190))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(2730, 2180))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(2930, 2180))

	# =========================================================================
	# ZONE 6B: SOUTH-EAST WHISPERING MEADOW & FISHER'S SHORE (X: 2100-3600, Y: 1650-2250)
	# Fills vast empty south-east green with Riverside Cottage, Fishing Pier, Stone Relic, and Orchard
	# =========================================================================
	# Meadow Haven / Fisherman's Cottage
	_add_building(objects, world, bld_sc, 2, Vector2(4080, 1850), "MeadowCottage")
	_add_prop(objects, world, "res://assets/props/barrel_wood.png", Vector2(4160, 1910), Vector2(1304, 24), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/crate_box.png", Vector2(4190, 1910), Vector2(1310, 20), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(4080, 1930), Vector2(1296, 16), Vector2(1280, -6))

	# Riverside Fishing Pier extending into the central river inlet
	_add_prop(objects, world, "res://assets/props/wooden_bridge_pier.png", Vector2(3400, 1920), Vector2(1410, 30), Vector2(1280, -15))
	_add_prop(objects, world, "res://assets/props/barrel_sack.png", Vector2(3420, 1890), Vector2(1304, 24), Vector2(1280, -5))
	_add_prop(objects, world, "res://assets/props/crate_wood.png", Vector2(3450, 1890), Vector2(1310, 20), Vector2(1280, -5))

	# Ancient Sunken Monolith & Relic Stone Circle
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(4540, 1930))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4620, 1930))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(4540, 1970))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(4620, 1970))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/07.png", Vector2(4580, 1950))
	_add_prop(objects, world, "res://Tiny Swords (Update 010)/Decoration/08.png", Vector2(4595, 1955))

	# Beautifully spaced orchard and meadow trees
	var se_trees := [
		Vector2(3530, 1740), Vector2(3760, 1720), Vector2(4000, 1740), Vector2(4240, 1710), Vector2(4480, 1740), Vector2(4720, 1710),
		Vector2(3640, 1880), Vector2(3860, 1860), Vector2(4340, 1880), Vector2(4760, 1870),
		Vector2(3520, 2020), Vector2(3740, 2040), Vector2(3960, 2010), Vector2(4220, 2030), Vector2(4420, 2020), Vector2(4740, 2020),
		Vector2(3600, 2130), Vector2(3840, 2120), Vector2(4080, 2140), Vector2(4320, 2120), Vector2(4560, 2130), Vector2(4800, 2120)
	]
	var se_t_idx := 0
	for tpos in se_trees:
		_add_tree(objects, world, tree_sc, (se_t_idx % 4) + 1, tpos)
		se_t_idx += 1

	var se_bushes := [
		Vector2(3660, 1780), Vector2(4130, 1770), Vector2(4600, 1770),
		Vector2(3760, 1940), Vector2(3930, 1950),
		Vector2(3660, 2070), Vector2(4160, 2080), Vector2(4630, 2080)
	]
	var se_b_idx := 0
	for bpos in se_bushes:
		_add_bush(objects, world, bush_sc, (se_b_idx % 4) + 1, bpos)
		se_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(3900, 1760))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(4380, 1750))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(3640, 1980))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(4280, 2100))

	# South Coastline & River Inlet Water Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(3530, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(3780, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(4030, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(4280, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(4530, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(4780, 2140))
	_add_water_foam(objects, world, foam_sc, Vector2(3340, 1750))
	_add_water_foam(objects, world, foam_sc, Vector2(3340, 1920))
	_add_water_foam(objects, world, foam_sc, Vector2(3340, 2080))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(3630, 2180))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(3980, 2180))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(4380, 2180))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(4730, 2180))

	# =========================================================================
	# ZONE 7: THE ROYAL CITADEL & EASTERN HIGHLANDS (East, X: 3500-4800, Y: 300-2200)
	# =========================================================================
	# Grand Royal Castle (320x256) atop the high eastern plateau
	_add_building(objects, world, bld_sc, 3, Vector2(5480, 480), "RoyalCastle")
	_add_building(objects, world, bld_sc, 4, Vector2(5030, 440), "CitadelTowerNorth")
	_add_building(objects, world, bld_sc, 4, Vector2(5930, 680), "CitadelTowerEast")
	_add_building(objects, world, bld_sc, 4, Vector2(5680, 1200), "CitadelTowerSouth")

	# Grand Royal Monastery / Cathedral (192x320)
	_add_building(objects, world, bld_sc, 5, Vector2(5030, 920), "Monastery")

	# Royal NPCs
	var elder_sc: PackedScene = load("res://scenes/npc_elder.tscn")
	var elder := elder_sc.instantiate()
	elder.name = "NPC_Elder"
	elder.position = Vector2(4940, 1000)
	objects.add_child(elder)
	elder.owner = world

	var lancer_sc: PackedScene = load("res://scenes/npc_lancer.tscn")
	var lancer := lancer_sc.instantiate()
	lancer.name = "NPC_Lancer"
	lancer.position = Vector2(5230, 680)
	objects.add_child(lancer)
	lancer.owner = world

	# Street Lanterns lining the Grand Avenue
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(4780, 1000), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(5130, 680), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(5380, 640), Vector2(1296, 16), Vector2(1280, -6))
	_add_prop(objects, world, "res://assets/props/lantern_post.png", Vector2(5630, 640), Vector2(1296, 16), Vector2(1280, -6))

	# Trees & nature around Citadel and Highland Plateau
	var citadel_trees := [
		Vector2(5160, 360), Vector2(5330, 340), Vector2(5630, 340), Vector2(5780, 380),
		Vector2(5880, 520), Vector2(5980, 600), Vector2(6030, 820), Vector2(5980, 1020),
		Vector2(5830, 1200), Vector2(5680, 1380), Vector2(5380, 1400), Vector2(5080, 1350),
		Vector2(4880, 1280), Vector2(5230, 1040), Vector2(5530, 1100),
		Vector2(5030, 1520), Vector2(5280, 1500), Vector2(5530, 1530), Vector2(5830, 1510), Vector2(6030, 1520),
		Vector2(5130, 1680), Vector2(5380, 1660), Vector2(5630, 1690), Vector2(5880, 1670), Vector2(6080, 1680),
		Vector2(5030, 1850), Vector2(5300, 1830), Vector2(5560, 1860), Vector2(5800, 1840), Vector2(6060, 1850),
		Vector2(5130, 2020), Vector2(5380, 2000), Vector2(5640, 2030), Vector2(5900, 2010), Vector2(6100, 2020),
		Vector2(5230, 2130), Vector2(5480, 2140), Vector2(5730, 2120), Vector2(5980, 2140)
	]
	var cit_t_idx := 0
	for tpos in citadel_trees:
		_add_tree(objects, world, tree_sc, (cit_t_idx % 4) + 1, tpos)
		cit_t_idx += 1

	var citadel_bushes := [
		Vector2(4960, 880), Vector2(5330, 680), Vector2(5630, 660), Vector2(5880, 750), Vector2(5780, 1100),
		Vector2(5180, 1500), Vector2(5760, 1500), Vector2(5230, 1860), Vector2(5680, 1880), Vector2(5430, 2050), Vector2(5930, 2050)
	]
	var cit_b_idx := 0
	for bpos in citadel_bushes:
		_add_bush(objects, world, bush_sc, (cit_b_idx % 4) + 1, bpos)
		cit_b_idx += 1

	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(5230, 380))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(5930, 580))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(5760, 1250))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(5430, 1500))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock2.png", Vector2(5930, 1510))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock3.png", Vector2(5200, 1850))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock4.png", Vector2(5730, 1860))
	_add_prop(objects, world, "res://Game Assets(NEW)/Terrain/Decorations/Rocks/Rock1.png", Vector2(5580, 2070))

	# Eastern Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 500))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 800))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 1100))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 1400))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 1650))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 1900))
	_add_water_foam(objects, world, foam_sc, Vector2(6230, 2100))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(6280, 620))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(6300, 950))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(6280, 1280))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(6280, 1520))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(6300, 1800))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(6280, 2050))

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

	# 1. Straight Whispering Forest Trail (px: 6 to 44, py: 16) — 2,432px straight highway!
	for x in range(6, 45):
		roads[Vector2i(x, 16)] = true

	# 2. Oakhaven Crossroads Hub & Branches (px: 44 to 47, py: 15 to 17)
	for x in range(44, 47):
		for y in range(15, 18):
			roads[Vector2i(x, y)] = true
	# North branch (to Training Grounds)
	for y in range(7, 16):
		roads[Vector2i(45, y)] = true
	# South branch (to River Bridge & Caverns)
	for y in range(17, 27):
		roads[Vector2i(45, y)] = true

	# 3. Village Main Avenue (2 tiles wide, px: 46 to 56, py: 16..17)
	for x in range(46, 56):
		roads[Vector2i(x, 16)] = true
		roads[Vector2i(x, 17)] = true

	# 4. Grand Town Plaza (8 cols x 6 rows around ancient center oak)
	for px in range(55, 63):
		for py in range(14, 20):
			roads[Vector2i(px, py)] = true

	# 5. Road South from Plaza to River Bridge (farm lane passing between crop field and sheep pen)
	# West approach: connects from Cavern highway (px = 38) across to Bridge left pier (px = 47)
	for px in range(38, 48):
		roads[Vector2i(px, 26)] = true
	# South highway to Mystic Cavern
	for py in range(26, 32):
		roads[Vector2i(38, py)] = true

	# East approach: connects from Bridge right pier (px = 52) eastward to px = 58
	for px in range(52, 58):
		roads[Vector2i(px, 26)] = true

	# South avenue connecting Plaza (px: 56, 57) to Bridge approach
	for py in range(19, 27):
		roads[Vector2i(56, py)] = true
		roads[Vector2i(57, py)] = true

	# 5B. Meadow Trail extending east from bridge into South-East Meadow to the Cottage
	for px in range(58, 65):
		roads[Vector2i(px, 26)] = true
	for py in range(26, 31):
		roads[Vector2i(64, py)] = true

	# 6. Road East from Plaza towards Royal Citadel (2 tiles wide avenue)
	for px in range(62, 82):
		roads[Vector2i(px, 16)] = true
		roads[Vector2i(px, 17)] = true

	# 7. Citadel Castle Avenue (ascending north)
	for py in range(8, 17):
		roads[Vector2i(80, py)] = true
		roads[Vector2i(81, py)] = true
	for px in range(80, 88):
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
