extends SceneTree
func _init():
    var img = Image.load_from_file("res://assets/ide.png")
    print("IMAGE_SIZE:", img.get_size())
    quit()
