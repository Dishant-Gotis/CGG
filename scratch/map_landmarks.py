import re

with open('cgg/scenes/world.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# Pattern matching node definitions and position
pattern = re.compile(r'\[node name="([^"]+)"[^\]]*parent="([^"]*)"\](?:[^\[]*?position = Vector2\(([^)]+)\))?', re.MULTILINE)
matches = pattern.findall(text)

print(f"Total nodes found: {len(matches)}")
for name, parent, pos in matches:
    if pos and any(k in name for k in ['Sign', 'Hut', 'player', 'NPC', 'Enemy', 'Tower', 'Pond', 'Cave', 'Stump', 'Hall', 'Plaza', 'House', 'Fox']):
        parts = [float(v.strip()) for v in pos.split(',')]
        x, y = parts[0], parts[1]
        zone = int(x // 1024) + 1
        print(f"Zone {zone} (x={x:4.0f}, y={y:4.0f}): {name:<20} in {parent}")
