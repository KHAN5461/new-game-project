import os
import re

project_dir = r"c:\Users\Admin\Documents\new-game-project"
resource_pattern = re.compile(r'\[ext_resource.*?path="(res://.*?)"')

broken = []

for root, dirs, files in os.walk(project_dir):
    for file in files:
        if file.endswith('.tscn') or file.endswith('.tres'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                matches = resource_pattern.findall(content)
                for match in matches:
                    # convert res:// to local path
                    local_path = match.replace('res://', '')
                    full_path = os.path.join(project_dir, local_path)
                    if not os.path.exists(full_path):
                        broken.append((filepath, match))

for filepath, broken_path in broken:
    print(f"Broken in {os.path.basename(filepath)}: {broken_path}")

print(f"Total broken links: {len(broken)}")
