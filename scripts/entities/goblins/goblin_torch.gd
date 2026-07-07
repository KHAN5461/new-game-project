extends CharacterBody2D

@onready var goblin_torch: CharacterBody2D = $"."
@onready var anim: AnimatedSprite2D = $anim
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var progress_bar: ProgressBar = $ProgressBar




var life=5
var speed=150
var direction=0
# Timer for attacking
var attack_interval: float =1.5
var attack_timer: float = 0.0
var warrior_in_range: bool = false


# target
@export var warrior:Node2D

func seeker_warrior():
	if is_instance_valid(warrior):
		navigation.target_position=warrior.global_position
	else:
		for warrior in get_tree().get_nodes_in_group("warriors"):
			if is_instance_valid(warrior):
				var target= warrior
				navigation.target_position=target.global_position



func find_closest_target():
	var closest_enemy = null
	var shortest_distance = INF  # Start with a very large number
	var groups_to_check = ["warriors"]
	
	for group in groups_to_check:
		for enemy in get_tree().get_nodes_in_group(group):
			if is_instance_valid(enemy):
				var distance = global_position.distance_to(enemy.global_position)
				if distance < shortest_distance:
					shortest_distance = distance
					closest_enemy = enemy

	if closest_enemy:
		navigation.target_position = closest_enemy.global_position




func _ready() -> void:
	add_to_group("obstacles")
	add_to_group("goblins")
	progress_bar.max_value=life


func _physics_process(delta: float) -> void:
	progress_bar.value=life

	anim.flip_h=false if velocity.x>0 else true
# timer attack
	if warrior_in_range==true:
		attack_timer -= delta
		if attack_timer <= 0 :
			attack_timer=attack_interval
			attack_warrior()
	if navigation.is_navigation_finished():
		return
	
	var current_agent_position=global_position
	var next_path_position=navigation.get_next_path_position()
	var new_velocity=current_agent_position.direction_to(next_path_position)*speed


	if navigation.avoidance_enabled:
			navigation.set_velocity(new_velocity)
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)
	move_and_slide()

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity=safe_velocity

# attack the player
func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		warrior_in_range=true
		find_closest_target()
func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		warrior_in_range=false
		update_animation()
		find_closest_target()


var is_attacking: bool = false
func update_animation():
	# Check if the navigation is active
	if not navigation.is_navigation_finished():
		var distance_to_target = global_position.distance_to(navigation.target_position)

		if distance_to_target >5:
			anim.animation = "run"
		else:
			anim.animation = "idle"
	else:
		anim.animation = "idle"


#seek for the target
func _on_zone_detector_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		seeker_warrior()
		find_closest_target()

func attack_warrior():
	throw()
	if direction==1:
		anim.animation="up"
	elif direction==-1:
		anim.animation="down"
	elif direction==0:
		anim.animation="side"
func throw():
	var direction=(warrior.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/fire.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func life_goblin_torch():
	life-=1
	if life<=0:
		die()

func die():
	var skull=preload("res://scenes/entities/characters/skull.tscn")
	var scene=skull.instantiate()
	get_parent().add_child(scene)
	scene.global_position=global_position
	queue_free()


# takes directions
func _on_up_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		direction=1
func _on_down_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		direction=-1

func _on_left_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		direction=0
		anim.flip_h=true

func _on_right_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		direction=0
		anim.flip_h=false


func _on_dammage_box_area_entered(area: Area2D) -> void:
	if area.name.begins_with("arrow"):
		life_goblin_torch()
