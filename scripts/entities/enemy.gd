extends CharacterBody2D

signal finished_action
var is_guarding: bool = false
var is_dead: bool = false


@export var tile_size: int = 64
@export var speed: float = 150.0
@export var detection_radius_tiles: int = 4

var life: int = 1
@onready var sprite: Sprite2D = $Sprite2D

var anim_timer: float = 0.0
var frame_duration: float = 0.1
var current_frame: int = 0
var anim_row: int = 0 # 0=Idle, 1=Run, 2=Attack

var ai_timer: Timer
var ray: RayCast2D

@export_enum("Random", "Bounce", "Clockwise", "CounterClockwise") var patrol_mode: int = 0

var current_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false
var target_position: Vector2
var state: int = 0 # 0=idle, 1=moving, 2=attacking

var starting_position: Vector2
var starting_rotation_degrees: float
var initial_hp: int = 30
var current_hp: int = 30

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("obstacles")
	
	starting_position = global_position
	starting_rotation_degrees = rotation_degrees
	
	_configure_physics_layers()
	
	target_position = position
	
	if sprite:
		sprite.frame = 0
		
	ray = RayCast2D.new()
	add_child(ray)
	ray.enabled = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = collision_mask # Use the body's mask so it stays on grass
	
	ai_timer = Timer.new()
	ai_timer.wait_time = 0.6
	ai_timer.autostart = true
	ai_timer.timeout.connect(_on_ai_tick)
	add_child(ai_timer)
	
	_pick_next_direction()



func _pick_next_direction() -> void:
	if patrol_mode == 0: # Random
		var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		dirs.shuffle()
		for d in dirs:
			if _can_move_in_direction(d):
				current_direction = d
				return
		current_direction = dirs[0]
	elif patrol_mode == 1: # Bounce
		current_direction = -current_direction
	elif patrol_mode == 2: # Clockwise
		current_direction = Vector2(-current_direction.y, current_direction.x)
	elif patrol_mode == 3: # CounterClockwise
		current_direction = Vector2(current_direction.y, -current_direction.x)

func _can_move_in_direction(dir: Vector2) -> bool:
	ray.target_position = dir * (tile_size * 1.5)
	ray.force_raycast_update()
	if ray.is_colliding() and not ray.get_collider() is Area2D:
		return false
	return true

func _on_ai_tick() -> void:
	if is_moving or state == 2: return
	
	var warrior = get_tree().get_first_node_in_group("warrior")
	if warrior:
		var dx = abs(warrior.position.x - position.x)
		var dy = abs(warrior.position.y - position.y)
		
		var is_adjacent = false
		if (dx < 10 and dy <= tile_size * 1.2) or (dy < 10 and dx <= tile_size * 1.2):
			is_adjacent = true
			
		if is_adjacent:
			_attack_warrior(warrior)
			return
				
		var dist_tiles = position.distance_to(warrior.position) / tile_size
		if dist_tiles <= detection_radius_tiles:
			_chase_warrior(warrior)
			return
			
	if _can_move_in_direction(current_direction):
		_start_move()
	else:
		_pick_next_direction()
		anim_row = 0
		state = 0

func _chase_warrior(warrior: Node2D) -> void:
	var dx = warrior.position.x - position.x
	var dy = warrior.position.y - position.y
	
	var best_dir = Vector2.ZERO
	var alt_dir = Vector2.ZERO
	
	if abs(dx) > abs(dy):
		best_dir = Vector2(sign(dx), 0)
		alt_dir = Vector2(0, sign(dy)) if dy != 0 else Vector2(0, 1)
	else:
		best_dir = Vector2(0, sign(dy))
		alt_dir = Vector2(sign(dx), 0) if dx != 0 else Vector2(1, 0)
		
	if _can_move_in_direction(best_dir):
		current_direction = best_dir
		_start_move()
	elif _can_move_in_direction(alt_dir):
		current_direction = alt_dir
		_start_move()
	else:
		anim_row = 0
		state = 0

func _start_move() -> void:
	target_position = position + (current_direction * tile_size)
	is_moving = true
	state = 1
	anim_row = 1
	if current_direction.x != 0:
		sprite.flip_h = current_direction.x < 0
		
	# Squash and stretch
	if sprite:
		sprite.scale = Vector2(1, 1)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.08)
		tween.tween_property(sprite, "scale", Vector2(0.9, 1.1), 0.08)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.08)

func _attack_warrior(warrior: Node2D) -> void:
	state = 2
	anim_row = 2
	current_frame = 0
	if warrior.position.x < position.x: sprite.flip_h = true
	elif warrior.position.x > position.x: sprite.flip_h = false
	
	if warrior.has_method("take_damage"):
		warrior.take_damage(1, self)
		
	if get_tree():
		await get_tree().create_timer(0.6).timeout
	state = 0
	anim_row = 0

func _physics_process(delta: float) -> void:
		
	if is_moving:
		var distance = position.distance_to(target_position)
		var step = speed * delta
		if distance <= step:
			position = target_position
			velocity = Vector2.ZERO
			is_moving = false
			state = 0
			anim_row = 0
		else:
			velocity = position.direction_to(target_position) * speed
			move_and_slide()
			
	if sprite:
		anim_timer += delta
		if anim_timer >= frame_duration:
			anim_timer -= frame_duration
			current_frame = (current_frame + 1) % 6
			sprite.frame = (anim_row * sprite.hframes) + current_frame

func take_damage(amount: int = 1) -> void:
	if AudioManager: AudioManager.play_hit()
	life -= amount

	var ft = preload("res://scenes/ui/floating_text.tscn").instantiate()
	ft.text = str(amount)
	ft.color = Color(1, 1, 1)
	ft.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", ft)

	if life <= 0:
		var explosion = preload("res://scenes/entities/explosion.tscn").instantiate()
		explosion.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", explosion)
		
		if randf() < 0.5:
			var coin = preload("res://scenes/entities/coin.tscn").instantiate()
			coin.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", coin)
		elif randf() < 0.3:
			var meat = preload("res://scenes/entities/meat.tscn").instantiate()
			meat.global_position = global_position
			get_tree().current_scene.call_deferred("add_child", meat)
		hide()
		process_mode = Node.PROCESS_MODE_DISABLED
		collision_layer = 0
		collision_mask = 0

func _configure_physics_layers() -> void:
	collision_layer = 0
	set_collision_layer_value(3, true) # Layer 3: Enemies
	
	collision_mask = 0
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)

func get_save_state() -> Dictionary:
	return {
		"position": starting_position,
		"rotation": starting_rotation_degrees,
		"hp": initial_hp
	}

func rollback_to_start() -> void:
	global_position = starting_position
	rotation_degrees = starting_rotation_degrees
	current_hp = initial_hp
	state = 0
	is_moving = false
	target_position = position
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	_configure_physics_layers()
	if sprite: 
		sprite.frame = 0
		anim_row = 0


func eval_sensor(sensor: String, args: Array = []) -> bool:
	return false

func execute_instruction(command: String, args: Array) -> void:
	if is_dead:
		call_deferred("emit_signal", "finished_action")
		return
		
	if has_method(command):
		var method_args = args if args.size() > 0 else []
		callv(command, method_args)
		await self.finished_action
	else:
		match command:
			"guard":
				is_guarding = true
				await get_tree().create_timer(0.2).timeout
				call_deferred("emit_signal", "finished_action")
			"unstance":
				is_guarding = false
				await get_tree().create_timer(0.1).timeout
				call_deferred("emit_signal", "finished_action")
			"wait":
				await get_tree().create_timer(1.0).timeout
				call_deferred("emit_signal", "finished_action")
			_:
				call_deferred("emit_signal", "finished_action")
