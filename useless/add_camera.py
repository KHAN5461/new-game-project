import os
import re

levels = ["game.tscn", "level_2.tscn", "level_3.tscn"]

for level in levels:
    if not os.path.exists(level): continue
    
    with open(level, "r") as f:
        content = f.read()
        
    if 'path="res://level_camera.gd"' in content:
        print(f"Skipping {level}, already has camera script.")
        continue
        
    # Find the last ext_resource
    last_ext_index = content.rfind('[ext_resource')
    if last_ext_index == -1: continue
    
    end_of_line = content.find('\n', last_ext_index)
    
    # Insert new resource
    res_str = '\n[ext_resource type="Script" path="res://level_camera.gd" id="level_camera_script"]'
    content = content[:end_of_line] + res_str + content[end_of_line:]
    
    # Add node to end of file
    node_str = '\n[node name="LevelCamera" type="Camera2D" parent="."]\nscript = ExtResource("level_camera_script")\n'
    content += node_str
    
    with open(level, "w") as f:
        f.write(content)
        
    print(f"Injected camera into {level}")
