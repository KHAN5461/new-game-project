extends CharacterBody2D

@onready var pawn: CharacterBody2D = $"."
@onready var anim: AnimatedSprite2D = $anim
@onready var detector_zone: Area2D = $"detector zone"
@onready var hitbox: Area2D = $hitbox
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var marker: Marker2D = $Marker
@onready var game_manager: Node = get_tree().current_scene

signal finished_action
signal life_changed(current, max_val)

var life: int = 3
@export var speed: float = 200.0
enum State { IDLE, MOVING, INTERACTING, BUILDING }
var state: State = State.IDLE
var dir: int = 1
var memory: Dictionary = {}
@export var vision_radius: float = 600.0

# GRID MOVEMENT VARIABLES
@export var tile_size: int = 64
var target_position: Vector2
var is_moving: bool = false
var is_dead: bool = false

var starting_position: Vector2
var starting_rotation_degrees: float
var initial_hp: int = 3
var interaction_ray: RayCast2D
var inventory: Dictionary = {"wood": 0, "meat": 0, "cash": 0}

# To track all pawns for UI (if needed)
static var all_pawns = []

func _ready() -> void:
	progress_bar.max_value = life
	starting_position = global_position
	starting_rotation_degrees = rotation_degrees
	initial_hp = life
	
	add_to_group("pawns")
	add_to_group("obstacles")
	all_pawns.append(self)
	
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.register_unit(self, "pawn")
		
	target_position = position
	
	interaction_ray = RayCast2D.new()
	add_child(interaction_ray)
	interaction_ray.enabled = true
	interaction_ray.collide_with_areas = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.collision_mask = 31 # Player/Tilemap(1) + Enemies(2) + Environment(4) + Pickups(8) + Interactables(16)
	interaction_ray.add_exception(self)
	for child in get_children():
		if child is CollisionObject2D:
			interaction_ray.add_exception(child)
	
	_configure_physics_layers()

var carry_state: String = ""

func _get_anim_name(base: String) -> String:
	if carry_state != "":
		var specialized = base + "_" + carry_state
		if anim.sprite_frames.has_animation(specialized):
			return specialized
	return base

func _physics_process(delta: float) -> void:
	if is_dead: return
	progress_bar.value = life
	
	if is_moving:
		var distance = position.distance_to(target_position)
		var step = speed * delta
		
		if distance <= step:
			position = target_position
			velocity = Vector2.ZERO
			is_moving = false
			if state == State.MOVING:
				state = State.IDLE
				finished_action.emit()
				get_tree().create_timer(0.05).timeout.connect(func():
					var idle_anim = _get_anim_name("idle")
					if state == State.IDLE and not is_moving and anim.animation != idle_anim:
						anim.play(idle_anim)
				)
		else:
			velocity = position.direction_to(target_position) * speed
			position = position.move_toward(target_position, step)
			
	elif state == State.IDLE and not is_moving:
		var idle_anim = _get_anim_name("idle")
		if anim.animation != idle_anim:
			anim.play(idle_anim)
			
	_check_automatic_drop_off()

# --- PROGRAMMABLE API ---

func get_facing_vector() -> Vector2:
	if dir == 1: return Vector2.LEFT if anim.flip_h else Vector2.RIGHT
	if dir == 2: return Vector2.UP
	if dir == -2: return Vector2.DOWN
	return Vector2.RIGHT

func set_facing_vector(v: Vector2) -> void:
	if v == Vector2.RIGHT: dir = 1; anim.flip_h = false
	elif v == Vector2.LEFT: dir = 1; anim.flip_h = true
	elif v == Vector2.UP: dir = 2
	elif v == Vector2.DOWN: dir = -2

func turn_left() -> void:
	var v = get_facing_vector()
	set_facing_vector(Vector2(v.y, -v.x))
	call_deferred("emit_signal", "finished_action")

func turn_right() -> void:
	var v = get_facing_vector()
	set_facing_vector(Vector2(-v.y, v.x))
	call_deferred("emit_signal", "finished_action")

func move_forward() -> void:
	var fwd = get_facing_vector()
	interaction_ray.target_position = fwd * tile_size
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		# Wall/obstacle, do not move. Wait a tiny bit so while loops don't lock up instantly.
		if get_tree(): await get_tree().create_timer(0.1).timeout
		call_deferred("emit_signal", "finished_action")
	else:
		target_position = position + (fwd * tile_size)
		is_moving = true
		state = State.MOVING
		anim.play(_get_anim_name("run"))

func eval_sensor(sensor_name: String, args: Array = []) -> Variant:

	if sensor_name == "receive_message":
		var tag = str(args[0]) if args.size() > 0 else ""
		return Global.swarm_messages.get(tag, null)
	if sensor_name == "radar":

		var tag = str(args[0]).to_lower() if args.size() > 0 else "enemy"
		var nodes = get_tree().get_nodes_in_group(tag)
		for node in nodes:
			if node != self and global_position.distance_to(node.global_position) <= vision_radius:
				return true
		return false
	if sensor_name == "scan_distance":
		var tag = str(args[0]).to_lower() if args.size() > 0 else "enemy"
		var nodes = get_tree().get_nodes_in_group(tag)
		var min_dist = 99999.0
		for node in nodes:
			if node != self:
				var dist = global_position.distance_to(node.global_position)
				if dist <= vision_radius and dist < min_dist:
					min_dist = dist
		return min_dist if min_dist < 99999.0 else -1.0
	if sensor_name == "check_forward":
		var fwd = get_facing_vector()
		interaction_ray.target_position = fwd * tile_size
		interaction_ray.force_raycast_update()
		if interaction_ray.is_colliding():
			var collider = interaction_ray.get_collider()
			if args.size() > 0:
				var expected_tag = str(args[0]).to_lower()
				return _collider_matches_tag(collider, expected_tag)
			return true # Colliding with anything
		return false
	return false

func _get_adjacent_target(tags: Array) -> Dictionary:
	var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	var min_dist = tile_size * 1.5
	
	# Look through all potential targets
	var all_nodes = get_tree().get_nodes_in_group("obstacles")
	all_nodes.append_array(get_tree().get_nodes_in_group("sheep"))
	all_nodes.append_array(get_tree().get_nodes_in_group("mine"))
	all_nodes.append_array(get_tree().get_nodes_in_group("gold"))
	all_nodes.append_array(get_tree().get_nodes_in_group("house"))
	all_nodes.append_array(get_tree().get_nodes_in_group("enemy"))
	# Fallback: check children of parent
	if get_parent():
		for child in get_parent().get_children():
			if child not in all_nodes:
				all_nodes.append(child)
				
	for node in all_nodes:
		if not node is Node2D or node == self: continue
		var dist = global_position.distance_to(node.global_position)
		if dist < min_dist:
			for tag in tags:
				if _collider_matches_tag(node, tag):
					# Found a matching adjacent node! Determine direction.
					var diff = (node.global_position - global_position).snapped(Vector2(1,1))
					var best_d = Vector2.RIGHT
					var max_dot = -1.0
					for d in directions:
						var dot = diff.normalized().dot(d)
						if dot > max_dot:
							max_dot = dot
							best_d = d
					return {"target": node, "dir": best_d}
	return {}

func _collider_matches_tag(collider: Object, tag: String) -> bool:
	var t = tag.to_lower()
	if collider.is_in_group(t): return true
	
	if t == "stone" or t == "rock":
		if collider.is_in_group("obstacles"):
			if "decor_type" in collider and collider.decor_type.begins_with("Rock"):
				return true
		if "rock" in collider.name.to_lower() or "stone" in collider.name.to_lower():
			return true
			
	if t == "building":
		for g in ["house", "storage", "sawmill", "building"]:
			if collider.is_in_group(g) or g in collider.name.to_lower():
				return true
				
	if t == "tree":
		if collider.is_in_group("trees") or "tree" in collider.name.to_lower():
			return true
			
	if t in collider.name.to_lower(): return true
	if collider.get_parent() and t in collider.get_parent().name.to_lower(): return true
	return false

func chop() -> void:
	if is_carrying_resources():
		_spawn_floating_text("Inventory Full", Color.RED)
		call_deferred("emit_signal", "finished_action")
		return
	var res = _get_adjacent_target(["tree"])
	if res.is_empty():
		call_deferred("emit_signal", "finished_action")
	else:
		set_facing_vector(res.dir)
		perform_action("chop", res.target)

func attack() -> void:
	if is_carrying_resources():
		_spawn_floating_text("Inventory Full", Color.RED)
		call_deferred("emit_signal", "finished_action")
		return
	var res = _get_adjacent_target(["sheep", "enemy"])
	if res.is_empty():
		call_deferred("emit_signal", "finished_action")
	else:
		set_facing_vector(res.dir)
		perform_action("attack", res.target)

func mine() -> void:
	if is_carrying_resources():
		_spawn_floating_text("Inventory Full", Color.RED)
		call_deferred("emit_signal", "finished_action")
		return
	var res = _get_adjacent_target(["gold", "mine"])
	if res.is_empty():
		call_deferred("emit_signal", "finished_action")
	else:
		set_facing_vector(res.dir)
		perform_action("mine", res.target)

func drop_off() -> void:
	var res = _get_adjacent_target(["house", "sawmill", "barracks", "storage"])
	if res.is_empty():
		call_deferred("emit_signal", "finished_action")
	else:
		set_facing_vector(res.dir)
		perform_action("drop_off", res.target)

func repair() -> void:
	if is_carrying_resources():
		_spawn_floating_text("Inventory Full", Color.RED)
		call_deferred("emit_signal", "finished_action")
		return
	perform_action("repair")

func build(type: String = "wall") -> void:
	if is_carrying_resources():
		_spawn_floating_text("Inventory Full", Color.RED)
		call_deferred("emit_signal", "finished_action")
		return
	perform_action("build", null, type)


func send_message(tag: String, value: Variant) -> void:
	Global.swarm_messages[tag] = value
	call_deferred("emit_signal", "finished_action")

func wait(time_sec: float = 1.0) -> void:

	var failsafe = get_tree().create_timer(time_sec)
	failsafe.timeout.connect(func():
		call_deferred("emit_signal", "finished_action")
	)


func execute_instruction(command: String, args: Array) -> void:
	if has_method(command):
		var method_args = args if args.size() > 0 else []
		var is_finished = [false] # using array as reference
		var failsafe = get_tree().create_timer(3.0)
		failsafe.timeout.connect(func():
			if not is_finished[0]:
				is_finished[0] = true
				call_deferred("emit_signal", "finished_action")
		)
		callv(command, method_args)
		await self.finished_action
		is_finished[0] = true
	else:
		call_deferred("emit_signal", "finished_action")

func perform_action(action_name: String, target: Node = null, extra_arg: String = "") -> void:
	var collider = target
	if not collider:
		var fwd = get_facing_vector()
		interaction_ray.target_position = fwd * tile_size
		interaction_ray.force_raycast_update()
		collider = interaction_ray.get_collider()
	
	if action_name == "chop":
		state = State.INTERACTING
		anim.play("interact_exe")
		if collider and _collider_matches_tag(collider, "tree"):
			if collider.has_method("take_damage"): collider.take_damage(1)
			carry_state = "wood"
			_spawn_floating_text("+ Wood", Color(0.6, 0.4, 0.2))
		
		var t = get_tree().create_timer(0.6)
		t.timeout.connect(func():
			state = State.IDLE
			anim.play(_get_anim_name("idle"))
			finished_action.emit()
		)
	elif action_name == "attack":
		state = State.INTERACTING
		anim.play("interact_knife")
		if collider and (_collider_matches_tag(collider, "sheep") or _collider_matches_tag(collider, "enemy")):
			var is_sheep = _collider_matches_tag(collider, "sheep")
			var sheep_will_die = false
			if is_sheep and "hp" in collider and collider.hp <= 1:
				sheep_will_die = true
				
			if collider.has_method("take_damage"): 
				collider.take_damage(1)
			elif collider.has_method("die"): 
				collider.die()
				
			if is_sheep and sheep_will_die:
				carry_state = "meat"
				_spawn_floating_text("+ Meat", Color(0.9, 0.3, 0.3))
		
		var t = get_tree().create_timer(0.6)
		t.timeout.connect(func():
			state = State.IDLE
			anim.play(_get_anim_name("idle"))
			finished_action.emit()
		)
	elif action_name == "mine":
		state = State.INTERACTING
		anim.play("interact_pickaxe")
		if collider and (_collider_matches_tag(collider, "gold") or _collider_matches_tag(collider, "mine")):
			if collider.has_method("take_damage"): collider.take_damage(1)
			carry_state = "gold"
			_spawn_floating_text("+ Gold", Color(1.0, 0.9, 0.2))
		
		var t = get_tree().create_timer(0.6)
		t.timeout.connect(func():
			state = State.IDLE
			anim.play(_get_anim_name("idle"))
			finished_action.emit()
		)
	elif action_name == "drop_off":
		state = State.IDLE
		var dropped = carry_state
		carry_state = ""
		anim.play("idle")
		if collider and collider.has_method("insert_item"):
			collider.insert_item(dropped, self)
		elif collider and _collider_matches_tag(collider, "house"):
			if inventory["wood"] > 0:
				for i in range(inventory["wood"]): 
					Stats.add_wood()
				inventory["wood"] = 0
				_spawn_floating_text("- Wood", Color(0.6, 0.4, 0.2))
			if inventory["meat"] > 0:
				for i in range(inventory["meat"]): 
					Stats.add_meat()
				inventory["meat"] = 0
				_spawn_floating_text("- Meat", Color(0.9, 0.3, 0.3))
			if inventory["gold"] > 0:
				for i in range(inventory["gold"]): 
					Stats.add_gold()
				inventory["gold"] = 0
				_spawn_floating_text("- Gold", Color(1.0, 0.9, 0.2))
			
			if dropped != "":
				if dropped == "wood": 
					Stats.add_wood()
					_spawn_floating_text("- Wood", Color(0.6, 0.4, 0.2))
				elif dropped == "meat": 
					Stats.add_meat()
					_spawn_floating_text("- Meat", Color(0.9, 0.3, 0.3))
				elif dropped == "gold": 
					Stats.add_gold()
					_spawn_floating_text("- Gold", Color(1.0, 0.9, 0.2))
			
			if inventory["cash"] > 0:
				for i in range(inventory["cash"]): 
					Stats.add_cash()
				inventory["cash"] = 0
			if GameManager and GameManager.has_method("update_objective_ui"):
				pass
		finished_action.emit()
	elif action_name == "repair" or action_name == "build":
		var is_building = (action_name == "build")
		var build_type = extra_arg if extra_arg != "" else "wall"
		var build_time = 0.6
		var scene_path = ""
		
		# Check space and costs
		var build_pos = Vector2.ZERO
		if is_building:
			if GameManager and GameManager.has_method("request_placement"):
				build_pos = await GameManager.request_placement(build_type)
				if build_pos == Vector2.ZERO:
					_spawn_floating_text("Build Cancelled", Color.RED)
					call_deferred("emit_signal", "finished_action")
					return
			else:
				build_pos = global_position + (get_facing_vector() * tile_size)
				
			# Pathfind to adjacent position
			var path = _find_grid_path(global_position, build_pos)
			if path.size() > 0:
				for step in path:
					var diff = step - global_position
					set_facing_vector(diff.normalized())
					move_forward()
					await self.finished_action
					
			# Verify we are adjacent to build_pos
			var dist = global_position.distance_to(build_pos)
			if dist > tile_size * 1.5:
				_spawn_floating_text("Target Unreachable!", Color.RED)
				call_deferred("emit_signal", "finished_action")
				return
				
			# Turn to face build_pos
			var dir_to_build = (build_pos - global_position).normalized().round()
			set_facing_vector(dir_to_build)
			
			# Space check at final location
			interaction_ray.target_position = dir_to_build * tile_size
			interaction_ray.force_raycast_update()
			if interaction_ray.is_colliding():
				_spawn_floating_text("Space Blocked!", Color.RED)
				call_deferred("emit_signal", "finished_action")
				return
				
			var cost_wood = 0
			var cost_gold = 0
			var cost_meat = 0
			
			if build_type == "wall":
				cost_wood = 10
				build_time = 1.0
				scene_path = "res://scenes/entities/buildings/wall.tscn"
			elif build_type == "tower":
				cost_wood = 50
				cost_gold = 20
				build_time = 2.0
				scene_path = "res://scenes/entities/buildings/tower.tscn"
			elif build_type == "sawmill":
				cost_wood = 80
				cost_gold = 40
				build_time = 3.0
				scene_path = "res://scenes/entities/buildings/sawmill.tscn"
			elif build_type == "storage":
				cost_wood = 60
				cost_gold = 20
				build_time = 2.5
				scene_path = "res://scenes/entities/buildings/storage.tscn"
			elif build_type == "barracks":
				cost_wood = 100
				cost_gold = 80
				cost_meat = 50
				build_time = 4.0
				scene_path = "res://scenes/entities/buildings/barracks.tscn"
			else:
				_spawn_floating_text("Unknown Building!", Color.RED)
				call_deferred("emit_signal", "finished_action")
				return
				
			# Check resource availability
			if Global.wood < cost_wood or Global.gold < cost_gold or Global.meat < cost_meat:
				var missing = []
				if Global.wood < cost_wood: missing.append("Wood")
				if Global.gold < cost_gold: missing.append("Gold")
				if Global.meat < cost_meat: missing.append("Meat")
				_spawn_floating_text("Need " + ", ".join(missing) + "!", Color.RED)
				call_deferred("emit_signal", "finished_action")
				return
				
			# Deduct costs
			Global.wood -= cost_wood
			Global.gold -= cost_gold
			Global.meat -= cost_meat
			
		state = State.BUILDING
		if anim.sprite_frames.has_animation("interact_hammer"):
			anim.play("interact_hammer")
		elif anim.sprite_frames.has_animation("repair"):
			anim.play("repair")
		Stats.build = true
		
		var t = get_tree().create_timer(build_time)
		t.timeout.connect(func():
			if is_building and scene_path != "":
				# Spawn structure
				var spawn_pos = build_pos
				if ResourceLoader.exists(scene_path):
					var struct_scene = load(scene_path)
					var struct = struct_scene.instantiate()
					struct.global_position = spawn_pos
					get_tree().current_scene.call_deferred("add_child", struct)
					
			state = State.IDLE
			anim.play(_get_anim_name("idle"))
			finished_action.emit()
		)
	else:
		call_deferred("emit_signal", "finished_action")


func _find_grid_path(start: Vector2, target: Vector2) -> Array[Vector2]:
	var astar = AStarGrid2D.new()
	var min_x = min(start.x, target.x) - 10 * tile_size
	var max_x = max(start.x, target.x) + 10 * tile_size
	var min_y = min(start.y, target.y) - 10 * tile_size
	var max_y = max(start.y, target.y) + 10 * tile_size
	
	astar.region = Rect2i(min_x / tile_size, min_y / tile_size, (max_x - min_x) / tile_size + 1, (max_y - min_y) / tile_size + 1)
	astar.cell_size = Vector2(tile_size, tile_size)
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	for obstacle in get_tree().get_nodes_in_group("obstacles"):
		if obstacle != self and obstacle.global_position.distance_to(target) > 5:
			var obs_cell = (obstacle.global_position / tile_size).round()
			if astar.region.has_point(obs_cell):
				astar.set_point_solid(obs_cell, true)
				
	var start_cell = (start / tile_size).round()
	var target_cell = (target / tile_size).round()
	
	var best_cell = start_cell
	var best_dist = 99999
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in directions:
		var adj = target_cell + d
		if astar.region.has_point(adj) and not astar.is_point_solid(adj):
			var dist = start_cell.distance_to(adj)
			if dist < best_dist:
				best_dist = dist
				best_cell = adj
				
	if best_cell == start_cell:
		return []
		
	var path_cells = astar.get_id_path(start_cell, best_cell)
	var path: Array[Vector2] = []
	for cell in path_cells:
		path.append(Vector2(cell.x * tile_size, cell.y * tile_size))
	return path

func add_to_inventory(item_type: String, amount: int = 1) -> void:
	if inventory.has(item_type):
		inventory[item_type] += amount

func _spawn_floating_text(text: String, color: Color) -> void:
	var ft = preload("res://scenes/ui/floating_text.tscn").instantiate()
	ft.text = text
	ft.color = color
	var jitter = Vector2(randf_range(-15, 15), randf_range(-15, 15))
	ft.global_position = global_position + jitter
	get_tree().current_scene.call_deferred("add_child", ft)

# --- DAMAGE AND DEATH ---

func take_damage(amount: int = 1) -> void:
	if is_dead: return
	life -= amount
	life_changed.emit(life, initial_hp)
	_spawn_floating_text("-" + str(amount) + " HP", Color(1, 0, 0))
	if life <= 0:
		die()

func die():
	is_dead = true
	Stats.sub_pawn()
	remove_from_group("pawns")
	var skull_scene = preload("res://scenes/entities/characters/skull.tscn")
	var skull_instance = skull_scene.instantiate()
	get_parent().add_child(skull_instance)
	skull_instance.global_position = global_position
	hide()
	process_mode = Node.PROCESS_MODE_DISABLED
	collision_layer = 0
	collision_mask = 0

func get_save_state() -> Dictionary:
	return {
		"position": starting_position,
		"rotation": starting_rotation_degrees,
		"hp": initial_hp
	}

func rollback_to_start() -> void:
	global_position = starting_position
	rotation_degrees = starting_rotation_degrees
	life = initial_hp
	state = State.IDLE
	is_moving = false
	is_dead = false
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	_configure_physics_layers()

func _configure_physics_layers() -> void:
	collision_layer = 2  # Player layer
	collision_mask = 1 | 4 | 8 | 16 # Env, Enemy, Interactable, Hazard

# --- SENSOR FUNCTIONS ---
func is_carrying_wood() -> bool:
	return carry_state == "wood" or inventory.get("wood", 0) > 0

func is_carrying_gold() -> bool:
	return carry_state == "gold" or inventory.get("cash", 0) > 0

func is_carrying_meat() -> bool:
	return carry_state == "meat" or inventory.get("meat", 0) > 0

func is_carrying_resources() -> bool:
	if carry_state in ["wood", "meat", "gold", "cash"]:
		return true
	for k in ["wood", "meat", "gold", "cash"]:
		if inventory.get(k, 0) > 0:
			return true
	return false

func _check_automatic_drop_off() -> void:
	var has_items = carry_state != ""
	if not has_items:
		for k in inventory:
			if inventory[k] > 0:
				has_items = true
				break
	if not has_items:
		return
		
	var res = _get_adjacent_target(["house", "storage"])
	if not res.is_empty():
		var building = res.target
		var dropped = carry_state
		carry_state = ""
		
		if building.has_method("insert_item"):
			if dropped != "":
				building.insert_item(dropped, self)
			for item_type in inventory.keys():
				while inventory[item_type] > 0:
					inventory[item_type] -= 1
					building.insert_item(item_type, self)
		else:
			for item_type in inventory.keys():
				if inventory[item_type] > 0:
					for i in range(inventory[item_type]):
						_deposit_stat(item_type)
					inventory[item_type] = 0
			if dropped != "":
				_deposit_stat(dropped)

func _deposit_stat(item_type: String) -> void:
	if item_type == "wood":
		Stats.add_wood()
		_spawn_floating_text("- Wood", Color(0.6, 0.4, 0.2))
	elif item_type == "meat":
		Stats.add_meat()
		_spawn_floating_text("- Meat", Color(0.9, 0.3, 0.3))
	elif item_type == "gold" or item_type == "cash":
		Stats.add_gold()
		_spawn_floating_text("- Gold", Color(1.0, 0.9, 0.2))
