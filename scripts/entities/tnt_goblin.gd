extends CharacterBody2D

@export var tile_size: int = 64
@export var speed: float = 150.0
@export var detection_radius_tiles: int = 4

var life: int = 1
@onready var sprite: Sprite2D = $Sprite2D

var anim_timer: float = 0.0
var frame_duration: float = 0.1
var current_frame: int = 0
var anim_row: int = 0 # 0=Idle, 1=Run, 2=Attack

var ray: RayCast2D
var current_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false
var target_position: Vector2
var state: int = 0 # 0=idle, 1=moving, 2=attacking

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("obstacles")
	target_position = position
	if sprite: sprite.frame = 0
		
	ray = RayCast2D.new()
	add_child(ray)
	ray.enabled = true
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = 7 # Environment(1) + Player(2) + Enemy(4)
	
	call_deferred("_connect_to_warrior")
	
	_pick_random_direction()

func _connect_to_warrior() -> void:
	var warrior = get_tree().get_first_node_in_group("warrior")
	if warrior and warrior.has_signal("finished_action"):
		warrior.finished_action.connect(_on_ai_tick)

func _pick_random_direction() -> void:
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	dirs.shuffle()
	for d in dirs:
		if _can_move_in_direction(d):
			current_direction = d
			return
	current_direction = dirs[0]

func _can_move_in_direction(dir: Vector2) -> bool:
	ray.target_position = dir * tile_size
	ray.force_raycast_update()
	if ray.is_colliding() and not ray.get_collider() is Area2D: return false
	return true

var alerted: bool = false

func _on_ai_tick() -> void:
	if GameManager and GameManager.state != GameManager.GameState.RUNNING: return
	if is_moving or state == 2: return
	
	var warrior = get_tree().get_first_node_in_group("warrior")
	if warrior:
		var dx = abs(warrior.position.x - position.x)
		var dy = abs(warrior.position.y - position.y)
		var dist_tiles_manhattan = (dx + dy) / tile_size
		
		# TNT Goblin prefers to stay at a distance and throw TNT
		if dist_tiles_manhattan <= 3.5 and dist_tiles_manhattan >= 1.5:
			if alerted:
				_throw_tnt(warrior)
				alerted = false
			else:
				alerted = true
				var t = create_tween()
				t.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
				t.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
			return
		else:
			alerted = false
			
		if dist_tiles_manhattan <= detection_radius_tiles:
			_chase_warrior(warrior)
			return
			
	if _can_move_in_direction(current_direction): _start_move()
	else:
		_pick_random_direction()
		anim_row = 0
		state = 0

func _chase_warrior(warrior: Node2D) -> void:
	var dx = warrior.position.x - position.x
	var dy = warrior.position.y - position.y
	
	# Run AWAY if too close!
	var multiplier = 1
	if abs(dx) + abs(dy) <= tile_size * 1.5:
		multiplier = -1 # Flee!
		
	var best_dir = Vector2.ZERO
	var alt_dir = Vector2.ZERO
	
	if abs(dx) > abs(dy):
		best_dir = Vector2(sign(dx), 0) * multiplier
		alt_dir = (Vector2(0, sign(dy)) if dy != 0 else Vector2(0, 1)) * multiplier
	else:
		best_dir = Vector2(0, sign(dy)) * multiplier
		alt_dir = (Vector2(sign(dx), 0) if dx != 0 else Vector2(1, 0)) * multiplier
		
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
	if current_direction.x != 0: sprite.flip_h = current_direction.x < 0

func _throw_tnt(warrior: Node2D) -> void:
	state = 2
	anim_row = 2
	current_frame = 0
	
	var throw_dir = (warrior.position - position).normalized()
	if throw_dir.x < 0: sprite.flip_h = true
	else: sprite.flip_h = false
	
	# Instantiate TNT in front of the goblin
	var tnt = preload("res://scenes/entities/tnt.tscn").instantiate()
	
	# Snap the direction to grid
	var snapped_dir = Vector2.ZERO
	if abs(throw_dir.x) > abs(throw_dir.y):
		snapped_dir = Vector2(sign(throw_dir.x), 0)
	else:
		snapped_dir = Vector2(0, sign(throw_dir.y))
		
	tnt.position = position + (snapped_dir * tile_size)
	get_parent().add_child(tnt)
	tnt.ignite()
		
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
		
		var coin = preload("res://scenes/entities/coin.tscn").instantiate()
		coin.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", coin)
		queue_free()
