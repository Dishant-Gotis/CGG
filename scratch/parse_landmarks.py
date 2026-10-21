with open('cgg/scenes/world.tscn', 'r', encoding='utf-8') as f:
    lines = f.readlines()

curr_node = None
curr_parent = None

for line in lines:
    line_s = line.strip()
    if line_s.startswith('[node name='):
        # Extract name="..."
        parts = line_s[len('[node '):-1].split()
        d = {}
        for p in parts:
            if '=' in p:
                k, v = p.split('=', 1)
                d[k] = v.strip('"')
        curr_node = d.get('name')
        curr_parent = d.get('parent')
    elif line_s.startswith('position = Vector2(') and curr_node:
        val = line_s.split('(')[1].split(')')[0]
        pts = [float(x.strip()) for x in val.split(',')]
        x, y = pts[0], pts[1]
        if any(k in curr_node for k in ['Sign', 'Hut', 'player', 'NPC', 'Enemy', 'Tower', 'Pond', 'Cave', 'Stump', 'Hall', 'Plaza', 'House', 'Fox']):
            z = int(x // 1024) + 1
            print(f"Zone {z} (x={x:4.0f}, y={y:4.0f}): {curr_node:<18} (parent={curr_parent})")
        curr_node = None
    elif line_s.startswith('['):
        curr_node = None
