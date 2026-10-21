with open('cgg/scenes/world.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

for line in text.splitlines():
    if '19_wood' in line or 'wood' in line.lower():
        print(line)
