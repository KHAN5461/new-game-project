import os

files = ["c:/Users/Admin/Documents/new-game-project/game.tscn", 
         "c:/Users/Admin/Documents/new-game-project/level_2.tscn",
         "c:/Users/Admin/Documents/new-game-project/level_3.tscn"]

for f in files:
    if not os.path.exists(f): continue
    lines = open(f, "r").readlines()
    new_lines = []
    skip = False
    for line in lines:
        if line.startswith("[node name=\"IDE_UI\""):
            skip = True
        elif skip and line.startswith("[node "):
            skip = False
            
        if not skip:
            new_lines.append(line)
            
    with open(f, "w") as out:
        out.writelines(new_lines)
    print(f"Cleaned {f}")
