extends SceneTree

func _init():
	print("Starting level generation...")
	
	# Create Level 1
	_generate_level("res://scenes/levels/game.tscn", 15, 10, Vector2(2, 5), Vector2(12, 5), 1)
	
	# Create Level 2
	_generate_level("res://scenes/levels/level_2.tscn", 18, 12, Vector2(2, 10), Vector2(15, 2), 2)
	
	# Create Level 3
	_generate_level("res://scenes/levels/level_3.tscn", 22, 14, Vector2(2, 7), Vector2(19, 7), 3)
	
	print("Level generation complete.")
	quit()

func _generate_level(path: String, width: int, height: int, start_pos: Vector2, goal_pos: Vector2, level_num: int):
	var packed_scene = load(path) as PackedScene
	if not packed_scene:
		print("Failed to load: ", path)
		return
		
	var scene = packed_scene.instantiate()
	var tilemap = scene.get_node("TileMap")
	
	if not tilemap:
		print("No TileMap found in: ", path)
		return
		
	tilemap.clear()
	
	# Clean up old entities (warrior, enemies, coins, goals)
	for child in scene.get_children():
		if child.name.begins_with("warrior") or child.name.begins_with("goblin") or child.name.begins_with("coin") or child.name.begins_with("goal") or child.name.begins_with("LevelCamera"):
			child.queue_free()
			
	# Add the global camera
	var cam = Camera2D.new()
	cam.name = "LevelCamera"
	var script = load("res://scripts/core/level_camera.gd")
	cam.set_script(script)
	scene.add_child(cam)
	cam.owner = scene
			
	# Basic IDs: 2 is grass, 1 is walls/elevation, 4 is water
	# Coordinates for grass: (0,0) is usually a solid grass tile in Tilemap_Flat
	# For elevation: (0,0) might be the top-left corner
	
	for x in range(-2, width + 2):
		for y in range(-2, height + 2):
			if x < 0 or y < 0 or x >= width or y >= height:
				# Water border
				tilemap.set_cell(0, Vector2i(x, y), 4, Vector2i(0, 0))
			else:
				# Grass floor
				tilemap.set_cell(0, Vector2i(x, y), 2, Vector2i(0, 0))
				
	# Build puzzle elements based on level
	if level_num == 1:
		# Simple wall in the middle
		for y in range(2, 8):
			tilemap.set_cell(0, Vector2i(7, y), 1, Vector2i(0, 0))
		_spawn_entity(scene, "res://scenes/entities/enemy.tscn", "goblin_torch", Vector2(9, 5))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin", Vector2(7, 1))
		
	elif level_num == 2:
		# Maze-like
		for y in range(0, 9):
			tilemap.set_cell(0, Vector2i(6, y), 1, Vector2i(0, 0))
		for y in range(3, 12):
			tilemap.set_cell(0, Vector2i(12, y), 1, Vector2i(0, 0))
			
		_spawn_entity(scene, "res://scenes/entities/enemy.tscn", "goblin_torch", Vector2(9, 2))
		_spawn_entity(scene, "res://scenes/entities/enemy.tscn", "goblin_tnt", Vector2(15, 10))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin1", Vector2(3, 2))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin2", Vector2(9, 10))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin3", Vector2(15, 6))
		
	elif level_num == 3:
		# Winding Maze to test Wall Follower logic
		for x in range(0, width):
			for y in range(0, height):
				# Fill everything with walls initially (except borders, they are water)
				if x >= 1 and x < width - 1 and y >= 1 and y < height - 1:
					tilemap.set_cell(0, Vector2i(x, y), 1, Vector2i(0, 0))
					
		# Carve out the maze path
		var path_points = [
			Vector2i(2, 7), Vector2i(3, 7), Vector2i(4, 7),
			Vector2i(4, 6), Vector2i(4, 5), Vector2i(4, 4), Vector2i(4, 3), Vector2i(4, 2),
			Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2),
			Vector2i(9, 3), Vector2i(9, 4), Vector2i(9, 5), Vector2i(9, 6), Vector2i(9, 7), Vector2i(9, 8), Vector2i(9, 9), Vector2i(9, 10), Vector2i(9, 11),
			Vector2i(10, 11), Vector2i(11, 11), Vector2i(12, 11), Vector2i(13, 11), Vector2i(14, 11), Vector2i(15, 11),
			Vector2i(15, 10), Vector2i(15, 9), Vector2i(15, 8), Vector2i(15, 7), Vector2i(16, 7), Vector2i(17, 7), Vector2i(18, 7), Vector2i(19, 7)
		]
		
		for p in path_points:
			tilemap.set_cell(0, p, 2, Vector2i(0, 0)) # 2 is grass
			
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin1", Vector2(4, 2))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin2", Vector2(9, 11))
		_spawn_entity(scene, "res://scenes/entities/coin.tscn", "coin3", Vector2(15, 11))
		
	# Spawn player and goal
	_spawn_entity(scene, "res://scenes/entities/warrior.tscn", "warrior", start_pos)
	_spawn_entity(scene, "res://scenes/entities/goal.tscn", "goal", goal_pos)
	
	# Note: to ensure children are owned by the root so they save properly:
	# _spawn_entity already handles this.
	
	var packed = PackedScene.new()
	packed.pack(scene)
	ResourceSaver.save(packed, path)
	print("Saved level: ", path)

func _spawn_entity(scene: Node, path: String, node_name: String, grid_pos: Vector2):
	var res = load(path) as PackedScene
	if res:
		var inst = res.instantiate()
		inst.name = node_name
		inst.position = grid_pos * 64 # tile size is 64
		scene.add_child(inst)
		inst.owner = scene
