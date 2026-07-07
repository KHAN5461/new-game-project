import os

levels = ["game.tscn", "level_2.tscn", "level_3.tscn"]

for lvl in levels:
    if not os.path.exists(lvl): continue
    
    with open(lvl, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    new_lines = []
    skip_camera = False
    skip_ide_offsets = False
    
    for i, line in enumerate(lines):
        if skip_camera:
            if line.startswith("[node") or line.startswith("[connection") or line.strip() == "":
                skip_camera = False
            else:
                continue
                
        if skip_ide_offsets:
            if line.startswith("offset_") or line.startswith("layout_mode"):
                continue
            elif line.startswith("[node") or line.startswith("[connection") or line.strip() == "":
                skip_ide_offsets = False
            
        if '[node name="Camera2D"' in line:
            skip_camera = True
            continue
            
        if '[node name="IDE_UI"' in line:
            # Insert CanvasLayer
            new_lines.append('[node name="IDECanvasLayer" type="CanvasLayer" parent="."]\n\n')
            # Modify IDE_UI parent
            modified_line = line.replace('parent="."', 'parent="IDECanvasLayer"')
            new_lines.append(modified_line)
            skip_ide_offsets = True
            continue
            
        new_lines.append(line)
        
    with open(lvl, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

print("Modified levels successfully.")
