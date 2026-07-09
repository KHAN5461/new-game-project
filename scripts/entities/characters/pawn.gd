extends CharacterBody2D
@onready var pawn: CharacterBody2D = $"."
@onready var anim: AnimatedSprite2D = $anim
@onready var detector_zone: Area2D = $"detector zone"
@onready var hitbox: Area2D = $hitbox
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var marker: Marker2D = $Marker
@onready var game_manager: Node2D = $"../.."


# target enemies
@export var goblin_torch:Node2D=null
@export var goblin_tnt:Node2D=null
@export var goblin_barrel:Node2D=null



# basic var
var life=10
var speed=200
var state=0

# var for the last mouse position
var previous_click_position: Vector2 = Vector2.ZERO
var current_click_position: Vector2 = Vector2.ZERO

# var to do an action
var busy=false
var do=false
@onready var button: Button = $Button
@onready var select: Label = $select

# Variables
var is_moving = false

var starting_position: Vector2
var starting_rotation_degrees: float
var initial_hp: int = 10
func seeker_setup():
	if current_click_position:
		navigation.target_position=current_click_position

func _ready() -> void:
	progress_bar.max_value=life
	starting_position = global_position
	starting_rotation_degrees = rotation_degrees
	initial_hp = life
	add_to_group("pawns")
	add_to_group("obstacles")
	# Add this pawn to the list of all pawns when it enters the scene
	all_pawns.append(self)


func _physics_process(delta: float) -> void:

	# Check if the pawn is moving
	is_moving =navigation.get_velocity().length() > 0
	if is_moving:
		if anim.animation!="run":
			anim.animation=="run"
	else:
		if anim.animation!="idle":
			anim.animation=="idle"
	select.visible=do
	add_to_group("pawns")
	progress_bar.value=life
	
	if do==true:
		if navigation.is_navigation_finished():
			return
		previous_click_position = current_click_position
		var current_agent_position=global_position
		var next_path_position=navigation.get_next_path_position()
		var new_velocity=current_agent_position.direction_to(next_path_position)*speed
		if navigation.avoidance_enabled:
			navigation.set_velocity(new_velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(new_velocity)
		
		move_and_slide()
	anim.flip_h=false if velocity.x>0 else true

	# state machine
	if state==0:
		anim.animation="idle"
	if state==1:
		anim.animation="run"
	if state==2:
		anim.animation="chop"
	if state==3:
		anim.animation="repair"
	if state==4:
		anim.animation="lift"
	if state==5:
		anim.animation="lift_run"


# move the player on a click toward a position
func _input(event: InputEvent) -> void:
		if Input.is_action_just_pressed("click"):
			seeker_setup()
			if do==true and busy==false:
				current_click_position =get_global_mouse_position()
		



# detect the area that entering
func _on_detector_zone_area_entered(area: Area2D) -> void:
	if area.name.begins_with("tree"):
		anim.animation=="chop"
	if area.name.begins_with("house"):
		Stats.build=true
	if area.name.begins_with("tower"):
		Stats.build=true
	if area.name.begins_with("tree"):
		Stats.build=true
func _on_detector_zone_area_exited(area: Area2D) -> void:
		if area.name.begins_with("tree"):
			pass


func life_pawn():
	life-=1
	if life<=0:
		die()
func life_pawn_barrel():
	life-=5
	if life<=0:
		die()
func life_pawn_torch():
	if is_instance_valid(pawn):
		knockback_torch()
		life-=2
	if life<=0:
		die()
func die():
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

#detect the bodies entering
@warning_ignore("unused_parameter")
func _on_detector_zone_body_entered(body: Node2D) -> void:
	pass
@warning_ignore("unused_parameter")
func _on_detector_zone_body_exited(body: Node2D) -> void:
	pass


func _on_button_pressed() -> void:
	activate()
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity=safe_velocity
#knockback function
func knockback_torch():
	# Calculate the direction of the knockback
	var knockback_direction = (global_position-goblin_torch.global_position).normalized()
	# Apply impulse in the opposite direction of the attacker
	velocity = knockback_direction *500

# Static variables to track all pawns and the last active pawn
static var all_pawns = []
static var last_active_index = -1  # Index of the last active pawn in the all_pawns array

func activate():
	# Deactivate the current last active pawn if it's different from this one
	if last_active_index >= 0 and last_active_index < all_pawns.size():
		var last_active_pawn = all_pawns[last_active_index]
		if last_active_pawn != self and is_instance_valid(last_active_pawn):
			last_active_pawn.do = false
	
	# Activate this pawn
	do= true
	# Update the last active pawn to this one
	last_active_index = all_pawns.find(self)

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
	state = 0
	is_moving = false
	show()
	process_mode = Node.PROCESS_MODE_INHERIT
	_configure_physics_layers()
