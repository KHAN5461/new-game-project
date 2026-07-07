extends  StaticBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var health= 2
@onready var section: Area2D = $tree
@onready var game_manager: Node2D = $"../.."
@onready var tree: StaticBody2D = $"."


var chopped=false

@export var interval: float =0.1

# Timer for throwing dynamite
var timer: float = 0.0
var player_in_range: bool = false

var last_pos=Vector2.ZERO
func _ready() -> void:
	add_to_group("obstacles")
func _physics_process(delta: float) -> void:
	
# timer attack
	if player_in_range:
		timer -= delta
		if timer <= 0 :
			timer =interval
			anim.animation="attacked"
			if Stats.chop==true:
				attacked()
	add_to_group("trees")
	if health<=0:
		die()




func attacked():
	anim.animation="attacked"
	health-=1
	

func die():
	chopped=true
	last_pos=global_position
	spawn_wood()



func spawn_wood():
	if health==0 and not health<0:
		var wood_scene = preload("res://scenes/entities/decors/wood.tscn")
		var wood_instance = wood_scene.instantiate()
		get_parent().add_child(wood_instance)
		wood_instance.global_position = global_position
		queue_free()




func _on_section_body_entered(body: Node2D) -> void:
	if body.is_in_group("pawns"):
		player_in_range=true
	if body.name=="warrior":
		if Input.is_action_just_pressed("attack1") or Input.is_action_just_pressed("attack2"):
			player_in_range=true
func _on_section_body_exited(body: Node2D) -> void:
	if body.name=="pawn" and health>0:
		player_in_range=false
		anim.animation="idle"
	elif health<0:
		anim.animation="idle"



func state():
	health=3
	anim.animation="idle"
func sp_tree():
		var tree_scene = preload("res://scenes/entities/decors/tree.tscn")
		var tree_instance = tree_scene.instantiate()
		get_parent().add_child(tree_instance)
		tree_instance.global_position =global_position

