extends CharacterBody2D
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var hitbox: Area2D = $hitbox
@onready var attack_zone: Area2D = $"attack zone"
@onready var dectector_zone: Area2D = $"dectector zone"
@onready var anim: AnimatedSprite2D = $anim
@onready var goblin_barrel: CharacterBody2D = $"."
@onready var game_manager: Node = $"../.."


var state=0
var speed=100
var dir=0

# variables for targets
@export var tower:Node2D=null
@export var house:Node2D=null
@export var castle:Node2D=null
@export var pawn:Node2D=null
@export var warrior:Node2D=null
@export var mine:Node2D=null

func seeker_warrior():
	if is_instance_valid(warrior):
		navigation.target_position=warrior.global_position
	else:
		for warrior in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(warrior):
				var target= warrior
				navigation.target_position=target.global_position
func seeker_pawn():
	if is_instance_valid(pawn):
		navigation.target_position=pawn.global_position
	else:
		for pawn in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(pawn):
				var target= pawn
				navigation.target_position=target.global_position
func seeker_tower():
	if is_instance_valid(tower):
		navigation.target_position=tower.global_position
	else:
		for tower in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(tower):
				var target= tower
				navigation.target_position=target.global_position
func seeker_house():
	if is_instance_valid(house):
		navigation.target_position=house.global_position
	else:
		for house in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(house):
				var target= house
				navigation.target_position=target.global_position
func seeker_castle():
	if is_instance_valid(castle):
		navigation.target_position=castle.global_position
	else:
		for castle in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(castle):
				var target= castle
				navigation.target_position=target.global_position
func seeker_mine():
	if is_instance_valid(mine):
		navigation.target_position=mine.global_position
	else:
		for mine in get_tree().get_nodes_in_group("pawns"):
			if is_instance_valid(mine):
				var target= mine
				navigation.target_position=target.global_position




func find_closest_target():
	var closest_enemy = null
	var shortest_distance = INF  # Start with a very large number
	var groups_to_check = ["warriors", "pawns"]
	
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

func _physics_process(delta: float) -> void:
	find_closest_target()
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
	
	
	# state
	if state==0 and anim.animation!="explo":
		anim.animation="idle"
	if state!=2 and state!=0 and state==1  and anim.animation!="explo":
		anim.animation="run"
	if state==2:
		anim.animation="explo"
		goblin_barrel_attack()


# goblin death function
func goblin_barrel_life():
	death_goblin()


# player enter the area
func _on_dectector_zone_body_entered(body: Node2D) -> void:
	if body.name=="warrior":
		state=1
		seeker_warrior()
		anim.animation="explo"
	if body.name=="pawn":
		state=1
		seeker_pawn()
		anim.animation="explo"

func _on_dectector_zone_body_exited(body: Node2D) -> void:
	if body.name=="warrior":
		state=0
		seeker_warrior()
	if body.name=="pawn":
		state=0
		seeker_pawn()



# goblin attack player
func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.name=="warrior":
		state=2
		anim.animation="explo"
	if body.name=="pawn":
		state=2

func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.name=="warrior":
		seeker_warrior()
	if body.name=="pawn":
		seeker_pawn()


# goblin barrel die
func death_goblin():
	anim.animation="explo"
	var explo_scene=preload("res://scenes/entities/decors/explo.tscn")
	var explo_instance=explo_scene.instantiate()
	get_parent().add_child(explo_instance)
	explo_instance.global_position=global_position
	throw()
	queue_free()


func throw():
	anim.animation="explo"
	var direction=(warrior.global_position-global_position).normalized()
	var tnt=preload("res://scenes/entities/decors/fire.tscn")
	var tnt_instance=tnt.instantiate()
	get_parent().add_child(tnt_instance)
	tnt_instance.global_position=global_position
	tnt_instance.directions(direction)


# goblin barrel attack
func goblin_barrel_attack():
	death_goblin()
	var explo_scene=preload("res://scenes/entities/decors/explo.tscn")
	var explo_instance=explo_scene.instantiate()
	get_parent().add_child(explo_instance)
	explo_instance.global_position=global_position
	if is_instance_valid(warrior):
		game_manager.player_life()
	if is_instance_valid(pawn):
		game_manager.pawn_attacked_barrel()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name=="warrior":
		game_manager.player_life()
	if body.name=="pawn" or body.is_in_group("pawns"):
		game_manager.pawn_attacked_barrel()


#check collision with arrow
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.name=="arrow":
		goblin_barrel_life()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity=safe_velocity
