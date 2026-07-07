extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $anim
@onready var attack_zone: Area2D = $"attack zone"
@onready var up: Area2D = $up
@onready var down: Area2D = $down
@onready var left: Area2D = $left
@onready var right: Area2D = $right
@onready var up_left: Area2D = $up_left
@onready var up_right: Area2D = $up_right
@onready var down_left: Area2D = $down_left
@onready var down_right: Area2D = $down_right

# makers
@onready var marker_up: Marker2D = $up/Marker_up
@onready var marker_down: Marker2D = $down/Marker_down
@onready var marker_2_left: Marker2D = $left/Marker2_left
@onready var marker_right: Marker2D = $right/Marker_right
@onready var marker_2_upleft: Marker2D = $up_left/Marker2_upleft
@onready var marker_upright: Marker2D = $up_right/Marker_upright
@onready var marker_downleft: Marker2D = $down_left/Marker_downleft
@onready var marker_downright: Marker2D = $down_right/Marker_downright


# enemy check
var goblin_torch=false
var goblin_tnt=false
var goblin_barrel=false


# create array target
@export var targets: Array[CharacterBody2D] = []

# Timer for throwing dynamite
var shoot_interval: float =0.6
var shoot_timer: float = 0.0
var goblin_in_range: bool = false

var new_direction=Vector2.ZERO

# attack area entered
func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		goblin_torch=true
		goblin_tnt=true
		goblin_barrel=true
		goblin_in_range=true
func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		goblin_torch=false
		goblin_tnt=false
		goblin_barrel=false
		goblin_in_range=false

func _ready() -> void:
	if goblin_in_range==false:
		anim.animation=="idle"


func _physics_process(delta: float) -> void:
		# timer attack
	if goblin_in_range:
		shoot_timer -= delta
		if shoot_timer <= 0 :
			shoot_timer = shoot_interval
			shoot()
	elif goblin_in_range==false:
		anim.animation=="idle"


# directions for shooting

func _on_up_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="up"
		new_direction=Vector2(0, -1)

func _on_down_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="down"
		new_direction=Vector2(0,1)


func _on_left_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="side"
		anim.flip_h=true
		new_direction=Vector2(-1, 0)


func _on_right_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="side"
		anim.flip_h=false
		new_direction=Vector2(1, 0)

func _on_up_left_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="up_side"
		anim.flip_h=true
		new_direction=Vector2(-1, -1).normalized()


func _on_up_right_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="up_side"
		anim.flip_h=false
		new_direction=Vector2(1, -1).normalized()



func _on_down_left_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="down_side"
		anim.flip_h=true
		new_direction=Vector2(-1, 1).normalized()


func _on_down_right_body_entered(body: Node2D) -> void:
	if body.name=="goblin_torch" or body.name=="goblin_tnt" or body.name=="goblin_barrel":
		anim.animation="down_side"
		anim.flip_h=false
		new_direction=Vector2(1, 1).normalized()

func shoot():
	anim.animation_looped
	var new_direction=new_direction
	var arrows=preload("res://scenes/entities/characters/arrow.tscn")
	var arrows_instance=arrows.instantiate()
	add_child(arrows_instance)
	arrows_instance.global_position=global_position
	arrows_instance.directions(new_direction)
