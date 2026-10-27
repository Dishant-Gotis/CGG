import os
from PIL import Image

atlas_path = r"d:\GIT-REPOS\CGG\cgg\Tiny Swords (Update 010)\everything\Cave Dungeon Pixel Art Tileset Atlas.png"
atlas = Image.open(atlas_path).convert("RGBA")

MAP_W, MAP_H = 1600, 960
canvas = Image.new("RGBA", (MAP_W, MAP_H), (10, 12, 20, 255))

# --- Extract Tiles & Props ---
def crop(box):
    return atlas.crop((box[0], box[1], box[0] + box[2], box[1] + box[3]))

# 64x64 Floor tiles
t_plain = crop((8, 9, 76, 76)).resize((64, 64), Image.Resampling.LANCZOS)
t_pebble = crop((93, 9, 79, 76)).resize((64, 64), Image.Resampling.LANCZOS)
t_cryst = crop((183, 9, 79, 76)).resize((64, 64), Image.Resampling.LANCZOS)
t_dark = crop((271, 9, 72, 76)).resize((64, 64), Image.Resampling.LANCZOS)

# Props
lantern_post = crop((11, 450, 106, 113))
wall_torch = crop((133, 449, 65, 126))
hanging_lantern = crop((223, 455, 20, 65))
crate = crop((324, 520, 33, 49))
barrel = crop((191, 533, 47, 58))
mine_cart = crop((15, 569, 69, 70))
ladder = crop((13, 650, 57, 70))
wooden_bridge = crop((95, 692, 139, 81))
mine_rails = crop((85, 786, 273, 62))
water_pool = crop((556, 450, 128, 111))
waterfall = crop((700, 450, 81, 111))
giant_crystal = crop((600, 667, 93, 107))
crystal_cluster = crop((454, 705, 72, 83))
crystal_single = crop((367, 718, 65, 67))

# Cave walls
cliff_wall_top = crop((440, 8, 92, 75))
cliff_tall = crop((832, 8, 118, 159))
cliff_vine = crop((676, 9, 62, 126))
stalactites = atlas.crop((998, 8, 1530, 138))

wall_straight_h = crop((972, 623, 226, 170))
wall_straight_v = crop((1310, 573, 216, 277))
wall_corner_br = crop((1293, 400, 233, 212))
wall_bend = crop((971, 406, 227, 205))
wall_pillar = crop((972, 801, 86, 208))

web1 = crop((267, 854, 45, 65))
mush_blue = crop((7, 807, 40, 62))
mush_purp = crop((128, 930, 30, 30))

# --- Global Walkable Grid Tiling ---
# Define polygon/rectangle walkable masks
walk_rects = [
    (65, 80, 495, 380, "plain"),       # Room 1: Entrance Cavern
    (65, 475, 495, 885, "pebble"),      # Room 2: Grimm's Hollow
    (365, 300, 515, 600, "plain"),      # West Corridor connector
    (485, 80, 1100, 345, "plain"),      # Room 3a: Upper Mine Tunnel
    (465, 440, 1100, 885, "pebble"),    # Room 3b: Central Area & Lower Guard Path
    (1070, 405, 1210, 595, "cryst"),    # Gateway Archway
    (1175, 80, 1540, 885, "cryst"),     # Room 4: Sacred Crystal Sanctuary
]

tile_dict = {
    "plain": [t_plain, t_plain, t_pebble, t_plain],
    "pebble": [t_pebble, t_pebble, t_dark, t_pebble],
    "cryst": [t_cryst, t_cryst, t_plain, t_cryst],
    "dark": [t_dark, t_dark, t_plain, t_dark]
}

print("1. Tiling global aligned floors...")
for gx in range(0, MAP_W, 64):
    for gy in range(0, MAP_H, 64):
        # Check if (gx, gy) intersects any walkable zone
        zone_type = None
        for rx1, ry1, rx2, ry2, ttype in walk_rects:
            if not (gx + 64 <= rx1 or gx >= rx2 or gy + 64 <= ry1 or gy >= ry2):
                zone_type = ttype
                break
        if zone_type is not None:
            tiles = tile_dict[zone_type]
            t = tiles[(gx // 64 + (gy // 64) * 3) % len(tiles)]
            canvas.paste(t, (gx, gy), t)

# --- 2. Northern Ceiling & Stalactites ---
print("2. Pasting northern stalactite border...")
for x in range(0, MAP_W, stalactites.width):
    canvas.paste(stalactites, (x, 0), stalactites)

# --- 3. Perimeter Boundaries ---
print("3. Pasting perimeter walls...")
# West Wall:
for y in range(0, MAP_H, 120):
    w_seg = cliff_tall.resize((75, 135), Image.Resampling.LANCZOS)
    canvas.paste(w_seg, (0, y), w_seg)

# East Wall:
for y in range(0, MAP_H, 120):
    w_seg = cliff_tall.resize((75, 135), Image.Resampling.LANCZOS).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    canvas.paste(w_seg, (MAP_W - 75, y), w_seg)

# South Wall:
for x in range(0, MAP_W, 110):
    w_seg = cliff_wall_top.resize((125, 95), Image.Resampling.LANCZOS)
    canvas.paste(w_seg, (x, MAP_H - 95), w_seg)

# --- 4. Dividing Walls ---
print("4. Pasting internal dividing walls...")
# Wall 1 (Entrance / Grimm's Hollow): x: 65..375, y: 380..505
w1 = wall_straight_h.resize((315, 125), Image.Resampling.LANCZOS)
canvas.paste(w1, (65, 380), w1)

# Wall 2 (Upper Mine / Pool): x: 495..1065, y: 345..465
w2 = wall_straight_h.resize((575, 125), Image.Resampling.LANCZOS)
canvas.paste(w2, (495, 345), w2)

# Gateway Wall North: x: 1080..1195, y: 50..415
g_top = wall_straight_v.resize((115, 365), Image.Resampling.LANCZOS)
canvas.paste(g_top, (1080, 50), g_top)

# Gateway Wall South: x: 1080..1195, y: 585..910
g_bot = wall_straight_v.resize((115, 335), Image.Resampling.LANCZOS)
canvas.paste(g_bot, (1080, 580), g_bot)

# Gateway Entrance Pillars
pill1 = wall_pillar.resize((48, 120), Image.Resampling.LANCZOS)
pill2 = wall_pillar.resize((48, 120), Image.Resampling.LANCZOS)
canvas.paste(pill1, (1075, 370), pill1)
canvas.paste(pill2, (1075, 570), pill2)

# --- 5. Azure Pool, Waterfall, and Wooden Bridge ---
print("5. Rendering Azure Pool, Waterfall, and Bridge...")
pool_scaled = water_pool.resize((275, 165), Image.Resampling.LANCZOS)
canvas.paste(pool_scaled, (575, 520), pool_scaled)

wfall_scaled = waterfall.resize((100, 120), Image.Resampling.LANCZOS)
canvas.paste(wfall_scaled, (660, 435), wfall_scaled)

# Wooden bridge crossing over the pool: x: 640..780, y: 580..645
bridge_scaled = wooden_bridge.resize((150, 75), Image.Resampling.LANCZOS)
canvas.paste(bridge_scaled, (640, 580), bridge_scaled)

# Dock steps leading to bridge
dock_step = ladder.resize((35, 45), Image.Resampling.LANCZOS)
canvas.paste(dock_step, (515, 650), dock_step)
canvas.paste(dock_step, (515, 680), dock_step)

# --- 6. Mine Tracks & Minecart ---
print("6. Rendering Mine Tracks...")
rail_scaled = mine_rails.resize((195, 48), Image.Resampling.LANCZOS)
for rx in range(485, 1050, 190):
    canvas.paste(rail_scaled, (rx, 210), rail_scaled)

cart_scaled = mine_cart.resize((68, 66), Image.Resampling.LANCZOS)
canvas.paste(cart_scaled, (740, 190), cart_scaled)

# --- 7. Entrance Stairway Landing ---
stair_arch = crop((355, 10, 72, 74)).resize((85, 85), Image.Resampling.LANCZOS)
canvas.paste(stair_arch, (105, 120), stair_arch)

# --- 8. Giant Crystals in Sacred Sanctuary ---
print("7. Rendering Crystals...")
gc_tl = giant_crystal.resize((120, 138), Image.Resampling.LANCZOS)
gc_tr = giant_crystal.resize((120, 138), Image.Resampling.LANCZOS).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
gc_bl = giant_crystal.resize((120, 138), Image.Resampling.LANCZOS)
gc_br = giant_crystal.resize((120, 138), Image.Resampling.LANCZOS).transpose(Image.Transpose.FLIP_LEFT_RIGHT)

canvas.paste(gc_tl, (1210, 110), gc_tl)
canvas.paste(gc_tr, (1450, 110), gc_tr)
canvas.paste(gc_bl, (1210, 745), gc_bl)
canvas.paste(gc_br, (1450, 745), gc_br)

# Sanctuary Altar Flanking Crystals (at y ~ 360 and y ~ 600)
altar_cryst_n = crystal_cluster.resize((85, 95), Image.Resampling.LANCZOS)
altar_cryst_s = crystal_cluster.resize((85, 95), Image.Resampling.LANCZOS).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
canvas.paste(altar_cryst_n, (1380, 340), altar_cryst_n)
canvas.paste(altar_cryst_s, (1380, 590), altar_cryst_s)

# Pool crystals
pool_cryst1 = crystal_cluster.resize((70, 80), Image.Resampling.LANCZOS)
pool_cryst2 = crystal_single.resize((60, 65), Image.Resampling.LANCZOS)
canvas.paste(pool_cryst1, (545, 630), pool_cryst1)
canvas.paste(pool_cryst2, (835, 630), pool_cryst2)

# --- 9. Lantern Posts, Crates, Barrels & Atmospheric Details ---
lp1 = lantern_post.resize((64, 70), Image.Resampling.LANCZOS)
canvas.paste(lp1, (260, 150), lp1)   # Entrance post
canvas.paste(lp1, (510, 420), lp1)   # Crossroads post
canvas.paste(lp1, (1055, 360), lp1)  # Gateway north post
canvas.paste(lp1, (1055, 570), lp1)  # Gateway south post
canvas.paste(lp1, (180, 650), lp1)   # Grimm's campfire lantern

cr1 = crate.resize((32, 44), Image.Resampling.LANCZOS)
bar1 = barrel.resize((40, 50), Image.Resampling.LANCZOS)
canvas.paste(bar1, (100, 230), bar1)
canvas.paste(cr1, (135, 235), cr1)
canvas.paste(bar1, (120, 680), bar1)
canvas.paste(cr1, (150, 685), cr1)

# Cobwebs & Glowing Mushrooms
canvas.paste(web1, (65, 85), web1)
canvas.paste(web1.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (1500, 85), web1)
mush_b = mush_blue.resize((32, 48), Image.Resampling.LANCZOS)
mush_p = mush_purp.resize((26, 26), Image.Resampling.LANCZOS)
canvas.paste(mush_b, (270, 780), mush_b)
canvas.paste(mush_p, (310, 795), mush_p)
canvas.paste(mush_b, (850, 720), mush_b)
canvas.paste(mush_p, (890, 730), mush_p)
canvas.paste(mush_b, (1300, 250), mush_b)
canvas.paste(mush_p, (1340, 260), mush_p)

# Save high-res map image
map_out_path = r"d:\GIT-REPOS\CGG\cgg\assets\cave\cave_dungeon_map.png"
canvas.save(map_out_path)
print(f"[SUCCESS] Saved final cave dungeon map: {map_out_path}")

# --- Generate Godot 4 cave.tscn Scene ---
scene_content = """[gd_scene format=3 uid="uid://5ww1p0ko40rq"]

[ext_resource type="Script" uid="uid://gnoxhwau82xr" path="res://scripts/cave.gd" id="1_cave"]
[ext_resource type="Texture2D" path="res://assets/cave/cave_dungeon_map.png" id="2_map"]
[ext_resource type="Script" uid="uid://0464131g3ejx" path="res://scripts/entities/cave_exit.gd" id="3_exit"]
[ext_resource type="PackedScene" uid="uid://0sam6i1k5f6e" path="res://scenes/player.tscn" id="4_player"]
[ext_resource type="PackedScene" path="res://scenes/companion_fox.tscn" id="5_fox"]
[ext_resource type="PackedScene" path="res://scenes/npc_goblin_grimm.tscn" id="6_grimm"]
[ext_resource type="PackedScene" path="res://scenes/crystal_altar.tscn" id="7_altar"]
[ext_resource type="PackedScene" path="res://scenes/enemy_torch_goblin.tscn" id="8_goblin"]

[sub_resource type="RectangleShape2D" id="BorderTop"]
size = Vector2(1600, 85)

[sub_resource type="RectangleShape2D" id="BorderBottom"]
size = Vector2(1600, 75)

[sub_resource type="RectangleShape2D" id="BorderLeft"]
size = Vector2(65, 960)

[sub_resource type="RectangleShape2D" id="BorderRight"]
size = Vector2(65, 960)

[sub_resource type="RectangleShape2D" id="WallDividing1"]
size = Vector2(310, 125)

[sub_resource type="RectangleShape2D" id="WallDividing2"]
size = Vector2(570, 120)

[sub_resource type="RectangleShape2D" id="WallGatewayNorth"]
size = Vector2(115, 365)

[sub_resource type="RectangleShape2D" id="WallGatewaySouth"]
size = Vector2(115, 325)

[sub_resource type="RectangleShape2D" id="PoolNorthWater"]
size = Vector2(265, 60)

[sub_resource type="RectangleShape2D" id="PoolSouthWater"]
size = Vector2(265, 40)

[sub_resource type="RectangleShape2D" id="PoolWestWater"]
size = Vector2(60, 65)

[sub_resource type="RectangleShape2D" id="PoolEastWater"]
size = Vector2(65, 65)

[sub_resource type="RectangleShape2D" id="CartObstacle"]
size = Vector2(54, 38)

[sub_resource type="RectangleShape2D" id="BarrelsEntrance"]
size = Vector2(50, 35)

[sub_resource type="RectangleShape2D" id="BarrelsGrimm"]
size = Vector2(55, 35)

[sub_resource type="CircleShape2D" id="CrystalTL"]
radius = 35.0

[sub_resource type="CircleShape2D" id="CrystalTR"]
radius = 35.0

[sub_resource type="CircleShape2D" id="CrystalBL"]
radius = 35.0

[sub_resource type="CircleShape2D" id="CrystalBR"]
radius = 35.0

[sub_resource type="CircleShape2D" id="ShapeExit"]
radius = 55.0

[sub_resource type="Gradient" id="GradAmbient"]
colors = PackedColorArray(0.3, 0.85, 1, 1, 0, 0, 0, 0)

[sub_resource type="GradientTexture2D" id="GradTexCyan"]
gradient = SubResource("GradAmbient")
width = 128
height = 128
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(0.5, 0)

[sub_resource type="Gradient" id="GradWarm"]
colors = PackedColorArray(1, 0.78, 0.35, 1, 0, 0, 0, 0)

[sub_resource type="GradientTexture2D" id="GradTexWarm"]
gradient = SubResource("GradWarm")
width = 128
height = 128
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(0.5, 0)

[sub_resource type="Gradient" id="GradViolet"]
colors = PackedColorArray(0.75, 0.35, 1, 1, 0, 0, 0, 0)

[sub_resource type="GradientTexture2D" id="GradTexViolet"]
gradient = SubResource("GradViolet")
width = 128
height = 128
fill = 1
fill_from = Vector2(0.5, 0.5)
fill_to = Vector2(0.5, 0)

[node name="Cave" type="Node2D" unique_id=1355284263]
script = ExtResource("1_cave")

[node name="CanvasModulate" type="CanvasModulate" parent="." unique_id=1384167259]
color = Color(0.20, 0.22, 0.34, 1)

[node name="Background" type="Sprite2D" parent="." unique_id=1756621926]
texture = ExtResource("2_map")
centered = false

[node name="Collisions" type="StaticBody2D" parent="." unique_id=4001]
collision_layer = 1
collision_mask = 0

[node name="ColBorderTop" type="CollisionShape2D" parent="Collisions"]
position = Vector2(800, 42.5)
shape = SubResource("BorderTop")

[node name="ColBorderBottom" type="CollisionShape2D" parent="Collisions"]
position = Vector2(800, 922.5)
shape = SubResource("BorderBottom")

[node name="ColBorderLeft" type="CollisionShape2D" parent="Collisions"]
position = Vector2(32.5, 480)
shape = SubResource("BorderLeft")

[node name="ColBorderRight" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1567.5, 480)
shape = SubResource("BorderRight")

[node name="ColDividingWall1" type="CollisionShape2D" parent="Collisions"]
position = Vector2(220, 442.5)
shape = SubResource("WallDividing1")

[node name="ColDividingWall2" type="CollisionShape2D" parent="Collisions"]
position = Vector2(780, 405)
shape = SubResource("WallDividing2")

[node name="ColGatewayNorth" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1137.5, 232.5)
shape = SubResource("WallGatewayNorth")

[node name="ColGatewaySouth" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1137.5, 747.5)
shape = SubResource("WallGatewaySouth")

[node name="ColPoolNorthWater" type="CollisionShape2D" parent="Collisions"]
position = Vector2(712.5, 550)
shape = SubResource("PoolNorthWater")

[node name="ColPoolSouthWater" type="CollisionShape2D" parent="Collisions"]
position = Vector2(712.5, 665)
shape = SubResource("PoolSouthWater")

[node name="ColPoolWestWater" type="CollisionShape2D" parent="Collisions"]
position = Vector2(610, 612.5)
shape = SubResource("PoolWestWater")

[node name="ColPoolEastWater" type="CollisionShape2D" parent="Collisions"]
position = Vector2(812.5, 612.5)
shape = SubResource("PoolEastWater")

[node name="ColCart" type="CollisionShape2D" parent="Collisions"]
position = Vector2(775, 225)
shape = SubResource("CartObstacle")

[node name="ColBarrelsEntrance" type="CollisionShape2D" parent="Collisions"]
position = Vector2(125, 255)
shape = SubResource("BarrelsEntrance")

[node name="ColBarrelsGrimm" type="CollisionShape2D" parent="Collisions"]
position = Vector2(150, 700)
shape = SubResource("BarrelsGrimm")

[node name="ColCrystalTL" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1270, 180)
shape = SubResource("CrystalTL")

[node name="ColCrystalTR" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1510, 180)
shape = SubResource("CrystalTR")

[node name="ColCrystalBL" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1270, 810)
shape = SubResource("CrystalBL")

[node name="ColCrystalBR" type="CollisionShape2D" parent="Collisions"]
position = Vector2(1510, 810)
shape = SubResource("CrystalBR")

[node name="CaveExit" type="Area2D" parent="." unique_id=1418728551]
position = Vector2(150, 160)
collision_layer = 64
collision_mask = 2
script = ExtResource("3_exit")

[node name="CollisionShape2D" type="CollisionShape2D" parent="CaveExit" unique_id=2082260172]
shape = SubResource("ShapeExit")

[node name="ExitSign" type="Label" parent="CaveExit"]
offset_left = -60.0
offset_top = -45.0
offset_right = 60.0
offset_bottom = -25.0
theme_override_font_sizes/font_size = 11
theme_override_colors/font_color = Color(1, 0.95, 0.7, 0.9)
theme_override_colors/font_outline_color = Color(0, 0, 0, 0.9)
theme_override_constants/outline_size = 3
text = "▲ Exit to Surface"
horizontal_alignment = 1

[node name="Spawn_entrance" type="Marker2D" parent="."]
position = Vector2(230, 240)

[node name="Player" parent="." unique_id=1498188185 instance=ExtResource("4_player")]
position = Vector2(230, 240)

[node name="CompanionFox" parent="." unique_id=1557022830 instance=ExtResource("5_fox")]
position = Vector2(190, 260)

[node name="NPC_Grimm" parent="." unique_id=2014022067 instance=ExtResource("6_grimm")]
position = Vector2(200, 720)

[node name="CrystalAltar" parent="." unique_id=1054944983 instance=ExtResource("7_altar")]
position = Vector2(1420, 480)

[node name="GoblinMineTunnel" parent="." instance=ExtResource("8_goblin")]
position = Vector2(750, 240)

[node name="GoblinSouthPath" parent="." instance=ExtResource("8_goblin")]
position = Vector2(880, 780)

[node name="GoblinSanctuaryGuard" parent="." instance=ExtResource("8_goblin")]
position = Vector2(1140, 490)

[node name="Lights" type="Node2D" parent="."]

[node name="LightEntrance" type="PointLight2D" parent="Lights"]
position = Vector2(290, 180)
color = Color(1, 0.78, 0.4, 1)
energy = 1.35
texture = SubResource("GradTexWarm")
texture_scale = 3.6

[node name="LightExitStairs" type="PointLight2D" parent="Lights"]
position = Vector2(150, 160)
color = Color(0.4, 0.85, 1, 1)
energy = 1.4
texture = SubResource("GradTexCyan")
texture_scale = 3.2

[node name="LightGrimmCamp" type="PointLight2D" parent="Lights"]
position = Vector2(210, 680)
color = Color(1, 0.75, 0.35, 1)
energy = 1.45
texture = SubResource("GradTexWarm")
texture_scale = 3.8

[node name="LightMineShaft" type="PointLight2D" parent="Lights"]
position = Vector2(740, 190)
color = Color(1, 0.8, 0.45, 1)
energy = 1.2
texture = SubResource("GradTexWarm")
texture_scale = 3.2

[node name="LightAzurePool" type="PointLight2D" parent="Lights"]
position = Vector2(710, 600)
color = Color(0.25, 0.88, 1, 1)
energy = 1.8
texture = SubResource("GradTexCyan")
texture_scale = 4.2

[node name="LightGateway" type="PointLight2D" parent="Lights"]
position = Vector2(1140, 490)
color = Color(0.7, 0.4, 1, 1)
energy = 1.5
texture = SubResource("GradTexViolet")
texture_scale = 3.6

[node name="LightSanctuaryAltar" type="PointLight2D" parent="Lights"]
position = Vector2(1420, 480)
color = Color(0.35, 0.9, 1, 1)
energy = 2.2
texture = SubResource("GradTexCyan")
texture_scale = 5.2

[node name="LightCrystalTL" type="PointLight2D" parent="Lights"]
position = Vector2(1270, 180)
color = Color(0.3, 0.85, 1, 1)
energy = 1.6
texture = SubResource("GradTexCyan")
texture_scale = 3.5

[node name="LightCrystalTR" type="PointLight2D" parent="Lights"]
position = Vector2(1510, 180)
color = Color(0.3, 0.85, 1, 1)
energy = 1.6
texture = SubResource("GradTexCyan")
texture_scale = 3.5

[node name="LightCrystalBL" type="PointLight2D" parent="Lights"]
position = Vector2(1270, 810)
color = Color(0.3, 0.85, 1, 1)
energy = 1.6
texture = SubResource("GradTexCyan")
texture_scale = 3.5

[node name="LightCrystalBR" type="PointLight2D" parent="Lights"]
position = Vector2(1510, 810)
color = Color(0.3, 0.85, 1, 1)
energy = 1.6
texture = SubResource("GradTexCyan")
texture_scale = 3.5
"""

scene_path = r"d:\GIT-REPOS\CGG\cgg\scenes\cave.tscn"
with open(scene_path, "w", encoding="utf-8") as f:
    f.write(scene_content.strip() + "\n")

print(f"[SUCCESS] Updated cave scene: {scene_path}")
