extends StaticBody2D

@export var spawn_interval: float = 8.0
@export var tile_size: int = 64

var timer: Timer
var enemy_scenes = [
	preload("res://scenes/entities/enemy_goblin.tscn")
]

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(_spawn_enemy)
	add_child(timer)

func _spawn_enemy() -> void:
	
	var dirs = [Vector2.DOWN] # Spawn exactly one tile down (in front)
	
	for dir in dirs:
		var spawn_pos = global_position + (dir * tile_size)
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = spawn_pos
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_point(query)
		if result.is_empty():
			var enemy_scene = enemy_scenes[randi() % enemy_scenes.size()]
			var enemy = enemy_scene.instantiate()
			enemy.global_position = spawn_pos
			get_tree().current_scene.add_child(enemy)
			return # Only spawn 1 at a time
