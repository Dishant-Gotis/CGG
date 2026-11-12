extends Node
## Comprehensive World Generator: rebuilds scenes/world.tscn natively using Game Assets(NEW)

func _ready() -> void:
	print("[WORLD GEN] Starting world redesign with Game Assets(NEW)...")
	var world := Node2D.new()
	world.name = "world"
	world.set_script(load("res://scripts/world.gd"))

	# 1. Turquoise Ocean Background
	var water_bg := TextureRect.new()
	water_bg.name = "OceanWater"
	water_bg.texture = load(Assets.WATER_BG)
	water_bg.stretch_mode = TextureRect.STRETCH_TILE
	water_bg.size = Vector2(4096, 896)
	water_bg.z_index = -12
	world.add_child(water_bg)
	water_bg.owner = world

	# 2. Island Terrain (TileMapLayer)
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(64, 64)
	var source := TileSetAtlasSource.new()
	source.texture = load(Assets.TILES_TERRAIN_COLOR1)
	source.texture_region_size = Vector2i(64, 64)
	for r in range(6):
		for c in range(9):
			source.create_tile(Vector2i(c, r))
	tile_set.add_source(source, 0)

	var terrain := TileMapLayer.new()
	terrain.name = "Terrain"
	terrain.tile_set = tile_set
	world.add_child(terrain)
	terrain.owner = world

	# Paint the main island landmass
	# Grid is 64 cols x 14 rows.
	# Island spans from col 2 to 61, row 2 to 11.
	for gx in range(2, 62):
		for gy in range(2, 12):
			var atlas := Vector2i(1, 1) # default seamless center grass

			var is_top := (gy == 2)
			var is_bottom := (gy == 11)
			var is_left := (gx == 2)
			var is_right := (gx == 61)

			if is_top and is_left:
				atlas = Vector2i(0, 0)
			elif is_top and is_right:
				atlas = Vector2i(2, 0)
			elif is_bottom and is_left:
				atlas = Vector2i(0, 2)
			elif is_bottom and is_right:
				atlas = Vector2i(2, 2)
			elif is_top:
				atlas = Vector2i(1, 0)
			elif is_bottom:
				atlas = Vector2i(1, 2)
			elif is_left:
				atlas = Vector2i(0, 1)
			elif is_right:
				atlas = Vector2i(2, 1)

			terrain.set_cell(Vector2i(gx, gy), 0, atlas)

	# 3. World Boundaries
	var bounds := StaticBody2D.new()
	bounds.name = "WorldBounds"
	bounds.collision_mask = 0
	world.add_child(bounds)
	bounds.owner = world

	_add_wall(bounds, world, Vector2(2048, 0), Vector2(4096, 24))
	_add_wall(bounds, world, Vector2(2048, 896), Vector2(4096, 24))
	_add_wall(bounds, world, Vector2(0, 448), Vector2(24, 896))
	_add_wall(bounds, world, Vector2(4096, 448), Vector2(24, 896))

	# 4. Objects (Y-Sorted Gameplay Layer)
	var objects := Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	world.add_child(objects)
	objects.owner = world

	# Spawn Markers
	var spawn_def := Marker2D.new()
	spawn_def.name = "Spawn_default"
	spawn_def.position = Vector2(260, 420)
	objects.add_child(spawn_def)
	spawn_def.owner = world

	var spawn_cave := Marker2D.new()
	spawn_cave.name = "Spawn_cave_exit"
	spawn_cave.position = Vector2(1350, 740)
	objects.add_child(spawn_cave)
	spawn_cave.owner = world

	# Player & Companions
	var player_sc: PackedScene = load("res://scenes/player.tscn")
	var player := player_sc.instantiate()
	player.name = "player"
	player.position = Vector2(260, 420)
	objects.add_child(player)
	player.owner = world

	var fox_sc: PackedScene = load("res://scenes/companion_fox.tscn")
	var fox := fox_sc.instantiate()
	fox.name = "CompanionFox"
	fox.position = Vector2(300, 430)
	objects.add_child(fox)
	fox.owner = world

	var kitsu_sc: PackedScene = load("res://scenes/npc_kitsu.tscn")
	var kitsu := kitsu_sc.instantiate()
	kitsu.name = "NPC_Kitsu"
	kitsu.position = Vector2(350, 420)
	objects.add_child(kitsu)
	kitsu.owner = world

	# Dynamic Building Scenes
	var bld_sc: PackedScene = load("res://scenes/entities/dynamic_building.tscn")
	var tree_sc: PackedScene = load("res://scenes/entities/dynamic_tree.tscn")
	var bush_sc: PackedScene = load("res://scenes/entities/dynamic_bush.tscn")
	var foam_sc: PackedScene = load("res://scenes/entities/dynamic_water_foam.tscn")
	var wrock_sc: PackedScene = load("res://scenes/entities/dynamic_water_rock.tscn")
	var sheep_sc: PackedScene = load("res://scenes/entities/dynamic_sheep.tscn")
	var gold_sc: PackedScene = load("res://scenes/entities/dynamic_gold_rock.tscn")

	# === ZONE 1: SNOWY'S HAVEN ===
	_add_building(objects, world, bld_sc, 0, Vector2(260, 360), "SnowyCottage") # House 1
	_add_tree(objects, world, tree_sc, 4, Vector2(150, 280)) # Birch
	_add_tree(objects, world, tree_sc, 1, Vector2(140, 520)) # Oak
	_add_tree(objects, world, tree_sc, 4, Vector2(420, 260)) # Birch
	_add_tree(objects, world, tree_sc, 1, Vector2(520, 560)) # Oak
	_add_bush(objects, world, bush_sc, 1, Vector2(210, 440))
	_add_bush(objects, world, bush_sc, 2, Vector2(360, 460))
	_add_bush(objects, world, bush_sc, 1, Vector2(460, 350))
	_add_sign(objects, world, Vector2(480, 420), "HomeSign", [
		"Signpost: East leads to the Crossroads & Mossveil Village.",
		"Signpost: West leads to your peaceful cottage."
	], "Home Signpost")

	# West Coast Water Foam & Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(120, 320))
	_add_water_foam(objects, world, foam_sc, Vector2(120, 480))
	_add_water_foam(objects, world, foam_sc, Vector2(120, 640))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(70, 360))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(60, 560))

	# === ZONE 2: WHISPERING WOODS & CROSSROADS ===
	_add_tree(objects, world, tree_sc, 2, Vector2(740, 240)) # Pine
	_add_tree(objects, world, tree_sc, 3, Vector2(860, 220)) # Autumn
	_add_tree(objects, world, tree_sc, 2, Vector2(720, 580)) # Pine
	_add_tree(objects, world, tree_sc, 3, Vector2(880, 620)) # Autumn
	_add_tree(objects, world, tree_sc, 2, Vector2(1020, 250)) # Pine
	_add_tree(objects, world, tree_sc, 3, Vector2(1150, 210)) # Autumn
	_add_bush(objects, world, bush_sc, 3, Vector2(780, 400))
	_add_bush(objects, world, bush_sc, 4, Vector2(980, 420))
	_add_bush(objects, world, bush_sc, 3, Vector2(1100, 520))
	_add_sign(objects, world, Vector2(1200, 420), "CrossroadsSign", [
		"Crossroads Sign:",
		"⬆ North: High Pass & Training Grounds",
		"⬇ South: Whispering Cove & Mystic Caves",
		"➔ East: Mossveil Village & Citadel"
	], "Crossroads")

	# Zone 2B: South Cove & Cave Entrance
	_add_cave_entrance(objects, world, Vector2(1350, 660))
	_add_sign(objects, world, Vector2(1260, 710), "CaveSign", [
		"Mystic Cavern Signpost:",
		"Warning: Treacherous crystal precipices ahead.",
		"A burning Cave Torch is required to safely descend into the darkness.",
		"Seek Elder Oakhaven in Mossveil Village if you need guidance!"
	], "Cave Sign", true)
	_add_gold_rock(objects, world, gold_sc, Vector2(1460, 690))
	_add_water_foam(objects, world, foam_sc, Vector2(1250, 780))
	_add_water_foam(objects, world, foam_sc, Vector2(1450, 780))
	_add_water_rock(objects, world, wrock_sc, 3, Vector2(1180, 810))
	_add_water_rock(objects, world, wrock_sc, 4, Vector2(1480, 820))

	# === ZONE 3: HIGH TRAINING GROUNDS ===
	_add_building(objects, world, bld_sc, 4, Vector2(1750, 180), "TrainingTower") # Tower with Archer
	_add_building(objects, world, bld_sc, 6, Vector2(2050, 200), "ArcheryRange") # Archery
	_add_tree(objects, world, tree_sc, 2, Vector2(1620, 160))
	_add_tree(objects, world, tree_sc, 2, Vector2(2200, 160))
	_add_bush(objects, world, bush_sc, 2, Vector2(1880, 240))
	_add_bush(objects, world, bush_sc, 1, Vector2(2120, 250))
	_add_sign(objects, world, Vector2(1680, 320), "TrainingSign", [
		"Combat Training Ground: Prove your strength!",
		"Press Q to swing your sword at nearby enemies.",
		"Slimes will chase and damage you on contact.",
		"Defeat the slimes and proceed east to Mossveil Village!"
	], "Training Sign")

	# Enemies in Training Grounds
	var enemy_sc: PackedScene = load("res://scenes/enemy.tscn")
	var torch_sc: PackedScene = load("res://scenes/enemy_torch_goblin.tscn")
	_add_enemy(objects, world, enemy_sc, Vector2(1820, 260))
	_add_enemy(objects, world, enemy_sc, Vector2(1980, 280))
	_add_enemy(objects, world, torch_sc, Vector2(2140, 270))

	# === ZONE 4: MOSSVEIL VILLAGE & SHEEP PASTURE ===
	_add_building(objects, world, bld_sc, 0, Vector2(2480, 360), "VillageHouse1") # House 1
	_add_building(objects, world, bld_sc, 1, Vector2(2720, 330), "VillageHouse2") # House 2
	_add_building(objects, world, bld_sc, 2, Vector2(2960, 360), "VillageHouse3") # House 3
	_add_building(objects, world, bld_sc, 7, Vector2(2520, 560), "Barracks")     # Barracks
	_add_sign(objects, world, Vector2(2360, 440), "VillageGateSign", [
		"Welcome to Mossveil Village!",
		"The great hall and town square lie ahead.",
		"You are safe within these walls, traveler."
	], "Village Gate")
	_add_sign(objects, world, Vector2(2800, 450), "TownSquareSign", [
		"Mossveil Town Square:",
		"North: Great Hall of the Elder",
		"East: Royal Guard Watchtowers & Citadel",
		"West: Return to Forest Road"
	], "Town Square")

	# Villager NPCs
	var maya_sc: PackedScene = load("res://scenes/npc_maya.tscn")
	var maya := maya_sc.instantiate()
	maya.name = "NPC_Maya"
	maya.position = Vector2(2640, 440)
	objects.add_child(maya)
	maya.owner = world

	var ravi_sc: PackedScene = load("res://scenes/npc_ravi.tscn")
	var ravi := ravi_sc.instantiate()
	ravi.name = "NPC_Ravi"
	ravi.position = Vector2(2880, 440)
	objects.add_child(ravi)
	ravi.owner = world

	# Green Meadow Pasture with Animated Sheep!
	_add_sheep(objects, world, sheep_sc, Vector2(2680, 620))
	_add_sheep(objects, world, sheep_sc, Vector2(2820, 640))
	_add_sheep(objects, world, sheep_sc, Vector2(2960, 610))
	_add_sheep(objects, world, sheep_sc, Vector2(3100, 650))
	_add_tree(objects, world, tree_sc, 4, Vector2(2760, 680)) # Birch
	_add_tree(objects, world, tree_sc, 4, Vector2(3040, 690)) # Birch
	_add_bush(objects, world, bush_sc, 1, Vector2(2620, 640))
	_add_bush(objects, world, bush_sc, 2, Vector2(2900, 670))

	# === ZONE 5: MOSSVEIL CITADEL & HIGH CLIFFS ===
	_add_building(objects, world, bld_sc, 3, Vector2(3720, 240), "RoyalCastle") # Castle
	_add_building(objects, world, bld_sc, 4, Vector2(3420, 220), "CitadelTowerNorth") # Tower with Archer
	_add_building(objects, world, bld_sc, 4, Vector2(3920, 460), "CitadelTowerEast")  # Tower with Archer
	_add_building(objects, world, bld_sc, 5, Vector2(3520, 520), "Monastery")         # Monastery

	# Royal NPCs
	var elder_sc: PackedScene = load("res://scenes/npc_elder.tscn")
	var elder := elder_sc.instantiate()
	elder.name = "NPC_Elder"
	elder.position = Vector2(3420, 580)
	objects.add_child(elder)
	elder.owner = world

	var guard_sc: PackedScene = load("res://scenes/npc_guard.tscn")
	var guard := guard_sc.instantiate()
	guard.name = "NPC_Guard"
	guard.position = Vector2(3360, 420)
	objects.add_child(guard)
	guard.owner = world

	var lancer_sc: PackedScene = load("res://scenes/npc_lancer.tscn")
	var lancer := lancer_sc.instantiate()
	lancer.name = "NPC_Lancer"
	lancer.position = Vector2(3580, 380)
	objects.add_child(lancer)
	lancer.owner = world

	_add_tree(objects, world, tree_sc, 1, Vector2(3580, 210))
	_add_tree(objects, world, tree_sc, 2, Vector2(3860, 210))
	_add_tree(objects, world, tree_sc, 2, Vector2(3700, 600))
	_add_bush(objects, world, bush_sc, 3, Vector2(3460, 440))
	_add_bush(objects, world, bush_sc, 4, Vector2(3660, 420))

	# Eastern Coastline Foam & Splash Rocks
	_add_water_foam(objects, world, foam_sc, Vector2(4000, 300))
	_add_water_foam(objects, world, foam_sc, Vector2(4000, 480))
	_add_water_foam(objects, world, foam_sc, Vector2(4000, 660))
	_add_water_rock(objects, world, wrock_sc, 1, Vector2(4040, 360))
	_add_water_rock(objects, world, wrock_sc, 2, Vector2(4050, 540))

	# === SKY LAYER: DRIFTING CLOUDS ===
	var cloud_sc: PackedScene = load("res://scenes/entities/dynamic_cloud.tscn")
	for i in range(6):
		var cloud := cloud_sc.instantiate() as Sprite2D
		cloud.name = "Cloud_%d" % i
		cloud.position = Vector2(randf_range(100, 3800), randf_range(40, 260))
		world.add_child(cloud)
		cloud.owner = world

	# Pack and save to res://scenes/world.tscn!
	var packed := PackedScene.new()
	var pack_err := packed.pack(world)
	print("[WORLD GEN] Pack result:", pack_err)
	var save_err := ResourceSaver.save(packed, "res://scenes/world.tscn")
	print("[WORLD GEN] Save scenes/world.tscn result:", save_err)

	get_tree().quit()


# --- Helper Builder Functions ------------------------------------------------

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
	spr.texture = load("res://Tiny Swords (Update 010)/everything/tiny-swords-22.png")
	spr.position = Vector2(0, -20)
	sign_node.add_child(spr)
	spr.owner = owner_node

	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	col.shape = shape
	col.position = Vector2(0, -10)
	sign_node.add_child(col)
	col.owner = owner_node
