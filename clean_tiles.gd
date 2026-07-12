extends SceneTree

func _init():
	var level_paths = [
		"res://scenes/levels/level_01.tscn",
		"res://scenes/levels/level_2.tscn",
		"res://scenes/levels/level_3.tscn",
		"res://scenes/levels/level_4.tscn",
		"res://scenes/levels/level_5.tscn",
		"res://scenes/levels/level_6.tscn",
		"res://scenes/levels/level_7.tscn",
		"res://scenes/levels/level_8.tscn",
		"res://scenes/levels/level_9.tscn",
		"res://scenes/levels/level_10.tscn",
		"res://scenes/levels/level_11.tscn",
		"res://scenes/levels/level_12.tscn",
		"res://scenes/levels/level_13.tscn",
		"res://scenes/levels/level_14.tscn",
		"res://scenes/levels/level_15.tscn",
		"res://scenes/levels/level_16.tscn",
		"res://scenes/levels/level_17.tscn",
		"res://scenes/levels/level_18.tscn",
		"res://scenes/levels/level_19.tscn",
		"res://scenes/levels/level_20.tscn",
		"res://scenes/levels/level_21.tscn",
		"res://scenes/levels/level_22.tscn",
		"res://scenes/levels/level_23.tscn",
		"res://scenes/levels/level_24.tscn",
		"res://scenes/levels/level_25.tscn",
		"res://scenes/levels/level_26.tscn",
		"res://scenes/levels/level_27.tscn",
		"res://scenes/levels/level_28.tscn",
		"res://scenes/levels/level_29.tscn",
		"res://scenes/levels/level_30.tscn",
		"res://scenes/levels/fallen_kingdom_scene.tscn"
	]
	
	for path in level_paths:
		if not ResourceLoader.exists(path): continue
		var scene = load(path)
		if not scene: continue
		var inst = scene.instantiate()
		var changed = false
		
		# Find all TileMap and TileMapLayer nodes recursively
		var nodes_to_check = []
		_find_tile_nodes(inst, nodes_to_check)
		
		for node in nodes_to_check:
			if node is TileMap:
				for layer in range(node.get_layers_count()):
					var cells = node.get_used_cells(layer)
					for cell in cells:
						var atlas_coords = node.get_cell_atlas_coords(layer, cell)
						if atlas_coords == Vector2i(5, 5):
							node.set_cell(layer, cell, -1)
							changed = true
							print("Erased invalid TileMap tile (5,5) in ", path, " cell: ", cell)
			elif node.is_class("TileMapLayer"):
				var cells = node.get_used_cells()
				for cell in cells:
					var atlas_coords = node.get_cell_atlas_coords(cell)
					if atlas_coords == Vector2i(5, 5):
						node.set_cell(cell, -1)
						changed = true
						print("Erased invalid TileMapLayer tile (5,5) in ", path, " node: ", node.name, " cell: ", cell)
						
		if changed:
			var packed = PackedScene.new()
			_set_owners(inst, inst)
			var err = packed.pack(inst)
			if err == OK:
				ResourceSaver.save(packed, path)
				print("Saved cleaned scene: ", path)
			else:
				print("Failed to pack scene: ", path, " error: ", err)
		inst.free()
	quit()

func _find_tile_nodes(node: Node, arr: Array):
	if node is TileMap or node.is_class("TileMapLayer"):
		arr.append(node)
	for child in node.get_children():
		_find_tile_nodes(child, arr)

func _set_owners(node: Node, root: Node):
	if node != root:
		node.owner = root
	for child in node.get_children():
		_set_owners(child, root)
