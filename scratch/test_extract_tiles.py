import os
import random
from PIL import Image, ImageEnhance, ImageDraw

random.seed(1337)

grounds_path = 'cgg/Tiny Swords (Update 010)/everything/grounds.png'
wood_path = 'cgg/Tiny Swords (Update 010)/everything/wooden_ground.png'

im_grounds = Image.open(grounds_path).convert('RGBA')
im_wood = Image.open(wood_path).convert('RGBA')

MAP_W = 256  # 256 * 16 = 4096 px
MAP_H = 40   # 40 * 16 = 640 px

def get_tile(col, row):
    return im_grounds.crop((col * 16, row * 16, (col + 1) * 16, (row + 1) * 16))

def get_wood_tile(col, row):
    # wood is 192x256 -> 12 cols x 16 rows of 16px
    c = col % 12
    r = row % 16
    return im_wood.crop((c * 16, r * 16, (c + 1) * 16, (r + 1) * 16))

# Extract all 10 edge variations to eliminate repetition!
SAND_T_VARS = [get_tile(c, 0) for c in range(21, 31)]
SAND_B_VARS = [get_tile(c, 11) for c in range(21, 31)]
SAND_L_VARS = [get_tile(20, r) for r in range(1, 11)]
SAND_R_VARS = [get_tile(31, r) for r in range(1, 11)]

SAND_TL = get_tile(20, 0)
SAND_TR = get_tile(31, 0)
SAND_BL = get_tile(20, 11)
SAND_BR = get_tile(31, 11)

# All 100 center sand variations
SAND_CENTERS = [get_tile(c, r) for c in range(21, 31) for r in range(1, 11)]

# Base grass tiles
GRASS_TILES = [get_tile(c, r) for c in range(1, 4) for r in range(1, 4)]

# Decals
TUFT = get_tile(18, 3)
FLOWER_WHITE = get_tile(17, 3)
FLOWER_YELLOW = get_tile(16, 3)
FLOWER_GROUP = get_tile(19, 3)

print("Tiles extracted successfully.")
