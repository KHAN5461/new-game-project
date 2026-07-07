extends RefCounted
class_name ProceduralGenerator

static func generate_level(depth: int) -> Node:
	var base_scene = load("res://scenes/levels/game.tscn")
	var instance = base_scene.instantiate()
	var tilemap = instance.get_node_or_null("TileMap")
	var saved_tileset = null
	
	if not tilemap:
		# Maybe it uses TileMapLayer, let's grab the tileset from 'Green grass' or any TileMapLayer
		for child in instance.get_children():
			if child is TileMapLayer and child.tile_set:
				saved_tileset = child.tile_set
				break
		tilemap = TileMap.new()
		tilemap.name = "TileMap"
		tilemap.tile_set = saved_tileset
		instance.add_child(tilemap)
	
	for child in instance.get_children():
		if child != tilemap:
			child.queue_free()
			
	tilemap.clear()
	
	var width = 25 + min(depth * 2, 20)
	var height = 20 + min(depth * 2, 20)
	
	var floor_id = 2
	var wall_id = 4
	if depth > 10:
		wall_id = 3
		floor_id = 1
	elif depth > 5:
		wall_id = 4
		floor_id = 3
		
	# Fill with walls
	for x in range(-2, width + 2):
		for y in range(-2, height + 2):
			tilemap.set_cell(0, Vector2i(x, y), wall_id, Vector2i(0, 0))
			
	var rooms = []
	var num_rooms = 4 + min(depth, 6)
	
	var final_floor = []
	var corridors = []
	
	var attempts = 0
	while rooms.size() < num_rooms and attempts < 100:
		attempts += 1
		var rw = randi_range(4, 7)
		var rh = randi_range(4, 7)
		var rx = randi_range(2, width - rw - 2)
		var ry = randi_range(2, height - rh - 2)
		var room = Rect2i(rx, ry, rw, rh)
		
		# Prevent overlap
		var overlap = false
		for other in rooms:
			if room.grow(1).intersects(other):
				overlap = true
				break
		if overlap and rooms.size() > 0:
			continue
			
		rooms.append(room)
		for x in range(rx, rx + rw):
			for y in range(ry, ry + rh):
				if not Vector2i(x,y) in final_floor:
					final_floor.append(Vector2i(x,y))
					
		if rooms.size() > 1:
			var prev = rooms[rooms.size() - 2]
			var start = prev.get_center()
			var end = room.get_center()
			
			var cur = start
			var r = randf()
			if r < 0.5:
				while cur.x != end.x:
					cur.x += sign(end.x - cur.x)
					if not cur in final_floor: final_floor.append(cur)
					corridors.append(cur)
				while cur.y != end.y:
					cur.y += sign(end.y - cur.y)
					if not cur in final_floor: final_floor.append(cur)
					corridors.append(cur)
			else:
				while cur.y != end.y:
					cur.y += sign(end.y - cur.y)
					if not cur in final_floor: final_floor.append(cur)
					corridors.append(cur)
				while cur.x != end.x:
					cur.x += sign(end.x - cur.x)
					if not cur in final_floor: final_floor.append(cur)
					corridors.append(cur)
					
	for p in final_floor:
		tilemap.set_cell(0, p, floor_id, Vector2i(0, 0))

	# Map Collision Cage
	var cage = StaticBody2D.new()
	var rect_h = RectangleShape2D.new()
	rect_h.size = Vector2(10000, 200)
	var col_top = CollisionShape2D.new()
	col_top.shape = rect_h
	col_top.position = Vector2(0, -3 * 64)
	cage.add_child(col_top)
	var col_bot = CollisionShape2D.new()
	col_bot.shape = rect_h.duplicate()
	col_bot.position = Vector2(0, (height + 3) * 64)
	cage.add_child(col_bot)
	var rect_v = RectangleShape2D.new()
	rect_v.size = Vector2(200, 10000)
	var col_left = CollisionShape2D.new()
	col_left.shape = rect_v
	col_left.position = Vector2(-3 * 64, 0)
	cage.add_child(col_left)
	var col_right = CollisionShape2D.new()
	col_right.shape = rect_v.duplicate()
	col_right.position = Vector2((width + 3) * 64, 0)
	cage.add_child(col_right)
	instance.add_child(cage)

	var start_pos = rooms[0].get_center()
	var goal_pos = rooms[-1].get_center()
	
	var is_boss_level = (depth % 3 == 0)
	
	if is_boss_level:
		_spawn(instance, "res://scenes/entities/boss_goblin.tscn", "boss_goblin", Vector2(goal_pos.x, goal_pos.y))
		# Push goal up slightly so boss doesn't stand exactly on it initially
		goal_pos.y -= 1

	_spawn(instance, "res://scenes/entities/warrior.tscn", "warrior", Vector2(start_pos.x, start_pos.y))
	_spawn(instance, "res://scenes/entities/goal.tscn", "goal", Vector2(goal_pos.x, goal_pos.y))
	
	var gate_pos = Vector2i.ZERO
	for i in range(corridors.size() - 1, -1, -1):
		var c = corridors[i]
		if not rooms[-1].has_point(c):
			gate_pos = c
			break
			
	if gate_pos != Vector2i.ZERO:
		var gate = _spawn(instance, "res://scenes/entities/gate.tscn", "gate", Vector2(gate_pos.x, gate_pos.y))
		if gate:
			gate.required_keys.clear()
			gate.required_keys.append("gold_key")
			var key_room = rooms[0]
			if rooms.size() > 2:
				var candidate_rooms = rooms.slice(1, rooms.size() - 1)
				key_room = candidate_rooms[randi() % candidate_rooms.size()]
			var key_p = key_room.get_center()
			_spawn(instance, "res://scenes/entities/key.tscn", "gold_key", Vector2(key_p.x, key_p.y))
			
	for i in range(depth * 2):
		var p = final_floor[randi() % final_floor.size()]
		if p.distance_to(start_pos) > 3 and p.distance_to(goal_pos) > 3 and p != gate_pos:
			var r = randf()
			if r < 0.2 and depth >= 3:
				_spawn(instance, "res://scenes/entities/tnt_goblin.tscn", "tnt_goblin_" + str(i), Vector2(p.x, p.y))
			elif r < 0.8:
				_spawn(instance, "res://scenes/entities/enemy.tscn", "goblin_" + str(i), Vector2(p.x, p.y))
				
	var cam = Camera2D.new()
	cam.name = "LevelCamera"
	var script = load("res://scripts/core/level_camera.gd")
	cam.set_script(script)
	instance.add_child(cam)
	
	return instance

static func _spawn(parent: Node, path: String, node_name: String, grid_pos: Vector2) -> Node:
	var res = load(path)
	if res:
		var inst = res.instantiate()
		inst.name = node_name
		inst.position = grid_pos * 64
		parent.add_child(inst)
		return inst
	return null
