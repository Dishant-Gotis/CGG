import os
import random
from PIL import Image

# Deterministic seed for reproducible, beautiful map
random.seed(42)

grounds_path = 'cgg/Tiny Swords (Update 010)/everything/grounds.png'
water_path = 'cgg/Tiny Swords (Update 010)/everything/water.png'

im_grounds = Image.open(grounds_path).convert('RGBA')
im_water = Image.open(water_path).convert('RGBA')

MAP_W = 256  # 256 * 16 = 4096 px
MAP_H = 40   # 40 * 16 = 640 px

def get_tile(col, row):
    return im_grounds.crop((col * 16, row * 16, (col + 1) * 16, (row + 1) * 16))

def get_water_tile(col, row):
    return im_water.crop(((col % 4) * 16, (row % 4) * 16, ((col % 4) + 1) * 16, ((row % 4) + 1) * 16))

# 1. Tile Extraction
# -----------------
# Uniform base grass
GRASS_BASE = [get_tile(c, r) for c in range(1, 4) for r in range(1, 4)]

# Sand edge variations (10 variations each to eliminate repetition)
SAND_T_VARS = [get_tile(c, 0) for c in range(21, 31)]
SAND_B_VARS = [get_tile(c, 11) for c in range(21, 31)]
SAND_L_VARS = [get_tile(20, r) for r in range(1, 11)]
SAND_R_VARS = [get_tile(31, r) for r in range(1, 11)]

# Corners
SAND_TL = get_tile(20, 0)
SAND_TR = get_tile(31, 0)
SAND_BL = get_tile(20, 11)
SAND_BR = get_tile(31, 11)

# All 100 center sand variations
SAND_CENTERS = [get_tile(c, r) for c in range(21, 31) for r in range(1, 11)]

# Decals
TUFT = get_tile(18, 3)
FLOWER_WHITE = get_tile(17, 3)
FLOWER_YELLOW = get_tile(16, 3)
FLOWER_GROUP = get_tile(19, 3)

# 2. Build Base Grass Canvas (100% uniform, NO color tinting, 100% solid alpha)
# -----------------------------------------------------------------------------
canvas = Image.new('RGBA', (MAP_W * 16, MAP_H * 16), (145, 175, 89, 255))

for y in range(MAP_H):
    for x in range(MAP_W):
        t = random.choice(GRASS_BASE)
        canvas.paste(t, (x * 16, y * 16))

# 3. Grid Map Layout
# ------------------
# 0 = grass
# 1 = continuous golden sand road
# 2 = garden tilled soil (Zone 1 only)
# 3 = whispering pond water (Zone 2 only)
grid = [[0 for _ in range(MAP_W)] for _ in range(MAP_H)]

# ==============================================================================
# ZONE 1: COTTAGE FARM (cols 0 .. 63, x: 0 .. 1024)
# ==============================================================================
# Cottage clearing around (240, 240) -> cols 11..24, rows 17..24
for y in range(17, 25):
    for x in range(11, 24):
        grid[y][x] = 1

# Tilled garden plot in the south (cols 12..21, rows 27..34) - ONLY IN ZONE 1!
for y in range(27, 34):
    for x in range(12, 21):
        grid[y][x] = 2

# Main road starting from clearing (col 22) heading East to Zone boundary (col 63)
# Gentle natural curves passing Signpost at (560, 320) -> col 35, row 20
for x in range(22, 64):
    wave = 1 if ((x - 22) % 24 < 12) else 0
    for y in range(20 + wave, 24 + wave):
        grid[y][x] = 1

# Ensure boundary col 63 is rows 20..23
for y in range(20, 24):
    grid[y][63] = 1

# ==============================================================================
# ZONE 2: CROSSROADS & FOREST (cols 64 .. 127, x: 1024 .. 2048)
# ==============================================================================
# Connects seamlessly from Zone 1 at col 64, rows 20..23!
for x in range(64, 76):
    for y in range(20, 24):
        grid[y][x] = 1

# Crossroads junction around Crossroads Sign at (1120, 310) -> col 70, row 19..20
for y in range(19, 25):
    for x in range(68, 77):
        grid[y][x] = 1

# Main road continues East towards Zone 3 (cols 76..128)
for x in range(76, 128):
    wave = 1 if ((x - 76) % 28 >= 14) else 0
    for y in range(20 + wave, 24 + wave):
        grid[y][x] = 1

# Ensure boundary col 127 is rows 20..23
for y in range(20, 24):
    grid[y][127] = 1

# Whispering Pond at (1200, 500) -> cols 71..81, rows 28..36
for y in range(28, 36):
    for x in range(71, 81):
        dx = (x - 76.0) / 4.5
        dy = (y - 32.0) / 3.5
        if dx*dx + dy*dy <= 1.0:
            grid[y][x] = 3

# Trail winding along the east bank of Whispering Pond:
for y in range(24, 33):
    for x in range(81, 85):
        grid[y][x] = 1

# Trail to CaveSign (col 94, row 34) and CaveEntrance (col 98, row 36):
for x in range(85, 101):
    ty = int(32 + (x - 85) * 0.3)
    for y in range(ty - 1, ty + 2):
        if y < MAP_H:
            grid[y][x] = 1

# North branch to High Pass:
for y in range(0, 21):
    for x in range(94, 98):
        grid[y][x] = 1

# ==============================================================================
# ZONE 3: COMBAT TRAINING GROUND (cols 128 .. 191, x: 2048 .. 3072)
# ==============================================================================
# Connects seamlessly from Zone 2 at col 128, rows 20..23!
for x in range(128, 136):
    for y in range(20, 24):
        grid[y][x] = 1

# Combat Sign at (2120, 320) -> col 132, row 20
# Combat Arena: wide training ground for slimes (cols 136..184, rows 16..27)
for y in range(16, 28):
    for x in range(136, 185):
        dx = (x - 160.0) / 24.0
        dy = (y - 21.5) / 5.5
        if dx*dx + dy*dy <= 1.0:
            grid[y][x] = 1
        elif 19 <= y <= 24:
            grid[y][x] = 1

# Avenue narrows back towards Village Gate (cols 185..192, rows 19..23)
for x in range(185, 192):
    for y in range(19, 24):
        grid[y][x] = 1

# Ensure boundary col 191 is rows 19..23
for y in range(19, 24):
    grid[y][191] = 1

# ==============================================================================
# ZONE 4: MEDIEVAL VILLAGE (cols 192 .. 255, x: 3072 .. 4096)
# ==============================================================================
# Connects seamlessly through Village Gate Towers at col 195 (3120 px), rows 19..23
# Main Village Avenue:
for x in range(192, 222):
    for y in range(19, 24):
        grid[y][x] = 1

# Village Town Square & Plaza:
# Around TownSquareSign (3580, 330 -> col 223), Maya (3520, 370 -> col 220), Elder (3660, 270 -> col 228)
for y in range(18, 26):
    for x in range(218, 235):
        grid[y][x] = 1

# North Street to Elder's Great Hall at (3660, 200) -> col 228, row 12..18
for y in range(12, 19):
    for x in range(226, 231):
        grid[y][x] = 1

# Street to North-West House (VHouse_0 at 3380, 220 -> col 211, row 14)
for x in range(210, 228):
    for y in range(14, 17):
        grid[y][x] = 1

# Street to North-East House (VHouse_1 at 3940, 220 -> col 246, row 14)
for x in range(228, 248):
    for y in range(14, 17):
        grid[y][x] = 1

# South Street towards South Cottages, Maya, and Ravi (3820, 470 -> col 238, row 29)
for y in range(25, 33):
    for x in range(226, 231):
        grid[y][x] = 1

# Street to South-West House (VHouse_2 at 3380, 490 -> col 211, row 30)
for x in range(210, 228):
    for y in range(29, 32):
        grid[y][x] = 1

# Street to South-East House (VHouse_4 at 3920, 490 -> col 245, row 30) and Ravi (col 238)
for x in range(228, 247):
    for y in range(29, 32):
        grid[y][x] = 1

# East Avenue leading past Town Square towards Watchtowers (4020 px -> col 251)
for x in range(234, 255):
    for y in range(20, 24):
        grid[y][x] = 1

# Spur up to EastTowerNorth (col 251, row 9)
for y in range(9, 21):
    for x in range(249, 253):
        grid[y][x] = 1

# Spur down to EastTowerSouth (col 251, row 34)
for y in range(23, 35):
    for x in range(249, 253):
        grid[y][x] = 1


# 4. Render Autotiled Path with Complete Continuity (Zero Holes, 100% Solid)
# -------------------------------------------------------------------------
print("Rendering continuous golden path...")

for y in range(MAP_H):
    for x in range(MAP_W):
        val = grid[y][x]
        pos = (x * 16, y * 16)
        
        if val == 1:
            # Check 4 orthogonal neighbors
            t_open = (y > 0 and grid[y - 1][x] == 1)
            b_open = (y < MAP_H - 1 and grid[y + 1][x] == 1)
            l_open = (x > 0 and grid[y][x - 1] == 1)
            r_open = (x < MAP_W - 1 and grid[y][x + 1] == 1)

            # Pick edge or center variant
            if not t_open and not l_open:
                tile = SAND_TL
            elif not t_open and not r_open:
                tile = SAND_TR
            elif not b_open and not l_open:
                tile = SAND_BL
            elif not b_open and not r_open:
                tile = SAND_BR
            elif not t_open:
                idx = (x * 7 + y * 13) % len(SAND_T_VARS)
                tile = SAND_T_VARS[idx]
            elif not b_open:
                idx = (x * 11 + y * 17) % len(SAND_B_VARS)
                tile = SAND_B_VARS[idx]
            elif not l_open:
                idx = (y * 7 + x * 19) % len(SAND_L_VARS)
                tile = SAND_L_VARS[idx]
            elif not r_open:
                idx = (y * 13 + x * 23) % len(SAND_R_VARS)
                tile = SAND_R_VARS[idx]
            else:
                idx = (x * 31 + y * 37) % len(SAND_CENTERS)
                tile = SAND_CENTERS[idx]

            # ALWAYS paste with tile as mask so alpha=255 base grass is never overwritten!
            canvas.paste(tile, pos, tile)

        elif val == 2:
            # Zone 1 Garden soil: rich dark earth
            idx = (x * 17 + y * 23) % len(SAND_CENTERS)
            tile = SAND_CENTERS[idx].copy()
            r, g, b, a = tile.split()
            r = r.point(lambda p: int(p * 0.80))
            g = g.point(lambda p: int(p * 0.74))
            b = b.point(lambda p: int(p * 0.62))
            soil = Image.merge('RGBA', (r, g, b, a))
            canvas.paste(soil, pos, soil)
            # Crop furrows
            if y % 2 == 1 and x % 3 == 0:
                canvas.paste(TUFT, pos, TUFT)

        elif val == 3:
            # Whispering Pond water
            wt = get_water_tile(x, y)
            canvas.paste(wt, pos)


# 5. Scatter Floral & Grass Details (Uniform Nature)
# -------------------------------------------------
print("Adding natural foliage details...")
for y in range(MAP_H):
    for x in range(MAP_W):
        if grid[y][x] == 0:
            r = random.random()
            pos = (x * 16, y * 16)
            if r < 0.04:
                canvas.paste(FLOWER_WHITE, pos, FLOWER_WHITE)
            elif r < 0.08:
                canvas.paste(FLOWER_YELLOW, pos, FLOWER_YELLOW)
            elif r < 0.13:
                canvas.paste(TUFT, pos, TUFT)
            elif r < 0.16:
                canvas.paste(FLOWER_GROUP, pos, FLOWER_GROUP)

# 6. Safety Check: Verify 100% Solid Alpha
# ----------------------------------------
alphas = [p[3] for p in canvas.getdata()]
min_alpha = min(alphas)
max_alpha = max(alphas)
print(f"Alpha check: min={min_alpha}, max={max_alpha}")
assert min_alpha == 255, f"ERROR: Found transparent pixels! min={min_alpha}"

# 7. Save to Ground Assets
# ------------------------
for path in ['cgg/assets/world/ground.png', 'cgg/assets/world/ground_extended.png']:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    canvas.save(path)
    print(f"Saved: {path} ({canvas.size[0]}x{canvas.size[1]})")
