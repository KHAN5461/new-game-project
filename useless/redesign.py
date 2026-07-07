import re
import os

def update_node_pos(content, node_name, new_pos):
    # Find [node name="NODE_NAME" ...]
    # Next line might be position, if not, insert it
    pattern = r'(\[node name="' + node_name + r'".*?\]\n)(?:position = Vector2\([^\)]+\)\n)?'
    replacement = r'\g<1>position = Vector2(' + str(new_pos[0]) + ', ' + str(new_pos[1]) + r')\n'
    return re.sub(pattern, replacement, content)

def process_level(file_path, warrior_pos, goal_pos, enemy_pos, coin_pos):
    if not os.path.exists(file_path): return
    with open(file_path, "r") as f:
        content = f.read()
    
    content = update_node_pos(content, "warrior", warrior_pos)
    content = update_node_pos(content, "Goal", goal_pos)
    
    # We might have Enemy or Enemy2, Coin etc.
    content = update_node_pos(content, "Enemy", enemy_pos)
    content = update_node_pos(content, "Coin", coin_pos)
    
    with open(file_path, "w") as f:
        f.write(content)

# Redesign Game (Level 1)
# Grid size is 64x64
process_level("game.tscn", (128, 128), (800, 128), (500, 128), (300, 128))

# Redesign Level 2
process_level("level_2.tscn", (64, 256), (900, 256), (400, 256), (400, 100))

# Redesign Level 3
process_level("level_3.tscn", (128, 500), (900, 100), (500, 300), (600, 300))

print("Levels redesigned successfully.")
