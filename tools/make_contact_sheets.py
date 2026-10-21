"""Build labeled contact sheets for the terrain/prop tilesets (grid + coords overlaid)."""
from PIL import Image, ImageDraw, ImageFont
import os, math

BASE = os.path.join(os.path.dirname(__file__), "..", "cgg", "Tiny Swords (Update 010)", "everything")
OUT = os.path.dirname(__file__)

def font(sz):
    for p in [r"C:\Windows\Fonts\consola.ttf", r"C:\Windows\Fonts\arialbd.ttf"]:
        if os.path.exists(p):
            return ImageFont.truetype(p, sz)
    return ImageFont.load_default()

def sheet(src, tile, out, zoom=3, label_every=1, max_w=1700):
    im = Image.open(os.path.join(BASE, src)).convert("RGBA")
    w, h = im.size
    cols, rows = w // tile, h // tile
    # choose zoom so sheet fits
    zoom = min(zoom, max_w // (cols * (tile * zoom // max(zoom,1)) or 1))
    zoom = max(1, min(zoom, max_w // (cols * tile) or 1))
    z = max(1, min(3, (max_w - 60) // (cols * tile) or 1))
    big = im.resize((w * z, h * z), Image.NEAREST).convert("RGBA")
    pad_l, pad_t = 46, 24
    canvas = Image.new("RGBA", (big.width + pad_l + 4, big.height + pad_t + 4), (30, 30, 34, 255))
    canvas.paste(big, (pad_l, pad_t), big)
    d = ImageDraw.Draw(canvas)
    f = font(9 if cols > 40 else 11)
    # grid
    for c in range(cols + 1):
        x = pad_l + c * tile * z
        d.line([(x, pad_t), (x, pad_t + big.height)], fill=(255, 60, 60, 110), width=1)
        if c % label_every == 0:
            d.text((x + 1, 4), str(c), font=f, fill=(255, 220, 90, 255))
    for r in range(rows + 1):
        y = pad_t + r * tile * z
        d.line([(pad_l, y), (pad_l + big.width, y)], fill=(255, 60, 60, 110), width=1)
        if r % label_every == 0:
            d.text((2, y + 1), str(r), font=f, fill=(120, 220, 255, 255))
    # row headers every 4
    d.text((pad_l, big.height + pad_t + 6), f"{src}  tile={tile}px  {cols}x{rows}  zoom={z}x", font=font(12), fill=(255, 255, 255, 255))
    canvas.save(os.path.join(OUT, out))
    print("wrote", out, canvas.size, f"{cols}x{rows}")

sheet("gr-2.png", 16, "sheet_gr2.png", label_every=2)
sheet("grounds.png", 16, "sheet_grounds.png")
sheet("trees.png", 16, "sheet_trees.png", label_every=2)

# props montage: individual images with labels
props = ["bush_1.png", "bush_2.png", "bush_3.png", "stone_1.png", "stone_2.png", "stone_3.png",
         "hut.png", "hut_blue.png", "tower.png", "tower_red.png", "water.png", "wooden_ground.png",
         "log.png" if os.path.exists(os.path.join(BASE, "log.png")) else "money_bag.png",
         "cave_down.png", "cave_light.png", "monster-1.png"]
props = [p for p in props if os.path.exists(os.path.join(BASE, p))]
tiny = sorted(f for f in os.listdir(BASE) if f.startswith("tiny-swords-") and f.endswith(".png"))
cell = 200
cols_n = 6
allp = props + tiny
rows_n = math.ceil(len(allp) / cols_n)
canvas = Image.new("RGBA", (cols_n * cell, rows_n * (cell + 18)), (30, 30, 34, 255))
d = ImageDraw.Draw(canvas)
f = font(11)
for i, p in enumerate(allp):
    im = Image.open(os.path.join(BASE, p)).convert("RGBA")
    sc = min((cell - 8) / im.width, (cell - 8) / im.height, 3)
    sc = max(sc, 0.5)
    im2 = im.resize((int(im.width * sc), int(im.height * sc)), Image.NEAREST)
    gx, gy = (i % cols_n) * cell, (i // cols_n) * (cell + 18)
    canvas.paste(im2, (gx + 4, gy + 16), im2)
    # checker bg
    d.rectangle([gx + 4, gy + 16, gx + 4 + im2.width, gy + 16 + im2.height], outline=(90, 90, 100, 255))
    d.text((gx + 4, gy + 2), f"{p} {im.width}x{im.height}", font=f, fill=(255, 220, 90, 255))
canvas.save(os.path.join(OUT, "sheet_props.png"))
print("wrote sheet_props.png", canvas.size, len(allp), "images")
