extends CharacterBody2D
@onready var goblin_tnt: CharacterBody2D = $"."
@onready var anim: AnimatedSprite2D = $anim
@onready var marker: Marker2D = $anim/Marker2D
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var progress_bar: ProgressBar = $ProgressBar



var life=5
var speed=150

# Timer for throwing dynamite
var shoot_interval: float =1.5
var shoot_timer: float = 0.0
var warrior_in_range: bool = false
var mine_in_range: bool = false
var tower_in_range: bool = false
var house_in_range: bool = false
var castle_in_range: bool = false


# targets
@export var tower:Node2D
@export var house:Node2D
@export var castle:Node2D
@export var warrior:Node2D
@export var mine:Node2D

func seeker_warrior():
	if is_instance_valid(warrior):
		navigation.target_position=warrior.global_position
	else:
		for warrior in get_tree().get_nodes_in_group("warriors"):
			if is_instance_valid(warrior):
				var target= warrior
				navigation.target_position=target.global_position
func seeker_tower():
	if is_instance_valid(tower):
		navigation.target_position=tower.global_position
	else:
		for tower in get_tree().get_nodes_in_group("towers"):
			if is_instance_valid(tower):
				var target= tower
				navigation.target_position=target.global_position
func seeker_house():
	if is_instance_valid(house):
		navigation.target_position=house.global_position
	else:
		for house in get_tree().get_nodes_in_group("houses"):
			if is_instance_valid(house):
				var target= house
				navigation.target_position=target.global_position
func seeker_castle():
	if is_instance_valid(castle):
		navigation.target_position=castle.global_position
	else:
		for castle in get_tree().get_nodes_in_group("castles"):
			if is_instance_valid(castle):
				var target= castle
				navigation.target_position=target.global_position
func seeker_mine():
	if is_instance_valid(mine):
		navigation.target_position=mine.global_position
	else:
		for mine in get_tree().get_nodes_in_group("mines"):
			if is_instance_valid(mine):
				var target= mine
				navigation.target_position=target.global_position




func find_closest_target():
	var closest_enemy = null
	var shortest_distance = INF  # Start with a very large number
	var groups_to_check = ["warriors", "towers","houses","castle","mine"]
	
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
	update_animation()

	
# timer attack
	if warrior_in_range==true:
		shoot_timer -= delta
		if shoot_timer <= 0 and warrior_in_range==true:
			shoot_timer = shoot_interval
			throw_warrior()
	if house_in_range==true:
		shoot_timer -= delta
		if shoot_timer <= 0 and house_in_range==true :
			shoot_timer = shoot_interval
			throw_house()
	if castle_in_range==true:
		shoot_timer -= delta
		if shoot_timer <= 0 and castle_in_range==true:
			shoot_timer = shoot_interval
			throw_castle()
	if tower_in_range==true:
		shoot_timer -= delta
		if shoot_timer <= 0 and tower_in_range==true :
			shoot_timer = shoot_interval
			throw_tower()
	if mine_in_range==true:
		shoot_timer -= delta
		if shoot_timer <= 0 :
			shoot_timer = shoot_interval
	
	
	
	
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
	
	anim.flip_h=false if velocity.x>0 else true

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
		find_closest_target()

func _on_attack_zone_area_entered(area: Area2D) -> void:
	if area.name.begins_with("house"):
		house_in_range=true
		find_closest_target()
	if area.name.begins_with("tower"):
		tower_in_range=true
		find_closest_target()
	if area.name.begins_with("castle"):
		castle_in_range=true
		find_closest_target()
	if area.name.begins_with("mine"):
		mine_in_range=true
		find_closest_target()
func _on_attack_zone_area_exited(area: Area2D) -> void:
	if area.name.begins_with("house"):
		house_in_range=false
		find_closest_target()
	if area.name.begins_with("tower"):
		tower_in_range=false
		find_closest_target()
	if area.name.begins_with("castle"):
		castle_in_range=false
		find_closest_target()
	if area.name.begins_with("mine"):
		mine_in_range=false
		find_closest_target()




var is_attacking: bool = false
func update_animation():
	# Attack state 
	if is_attacking:
		anim.animation = "attack"
		return
	# Check if the navigation is active
	if not navigation.is_navigation_finished():
		var distance_to_target = global_position.distance_to(navigation.target_position)

		if distance_to_target > 10:
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

func _on_zone_detector_area_entered(area: Area2D) -> void:
	if area.name.begins_with("house"):
		seeker_house()
		find_closest_target()
	if area.name.begins_with("tower"):
		seeker_tower()
		find_closest_target()
	if area.name.begins_with("castle"):
		seeker_castle()
		find_closest_target()
	if area.name.begins_with("mine"):
		seeker_mine()
		find_closest_target()



func throw_warrior():
	anim.animation="throw"
	var direction=(warrior.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func throw_house():
	anim.animation="throw"
	var direction=(house.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func throw_tower():
	anim.animation="throw"
	var direction=(tower.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func throw_castle():
	anim.animation="throw"
	var direction=(castle.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func throw_mine():
	anim.animation="throw"
	var direction=(mine.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)
func throw_knight():
	anim.animation="throw"
	var direction=(warrior.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/tnt.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)

func life_goblin_tnt():
	life-=1
	if life<=0:
		die()

func die():
	var skull=preload("res://scenes/entities/characters/skull.tscn")
	var scene=skull.instantiate()
	get_parent().add_child(scene)
	scene.global_position=global_position
	queue_free()


func _on_dammage_box_area_entered(area: Area2D) -> void:
	if area.name.begins_with("arrow"):
		life_goblin_tnt()
