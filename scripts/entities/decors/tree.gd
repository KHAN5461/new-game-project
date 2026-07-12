extends  StaticBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@export var health= 2
@onready var section: Area2D = $tree
@onready var game_manager: Node = $"../.."
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
	add_to_group("trees")
	if chopped: return
	
	if player_in_range:
		timer -= delta
		if timer <= 0:
			timer = interval
			if anim.animation != "attacked":
				anim.play("attacked")
			if Stats.chop == true:
				attacked()
	
	if health <= 0:
		die()

func attacked():
	if anim.animation != "attacked":
		anim.play("attacked")
	health -= 1

func die():
	if chopped: return
	chopped = true
	
	# Play chopped animation (stump/falling)
	anim.play("chopped")
	
	# Disable collisions so units can cross immediately
	collision_layer = 0
	collision_mask = 0
	if section:
		section.monitoring = false
		section.monitorable = false
		
	# Wait for animation to finish before spawning wood
	get_tree().create_timer(0.6).timeout.connect(func():
		spawn_wood()
	)

func spawn_wood():
	var wood_scene = load("res://scenes/entities/decors/wood.tscn")
	if wood_scene:
		var wood_instance = wood_scene.instantiate()
		get_parent().add_child(wood_instance)
		wood_instance.global_position = global_position
	queue_free()

func _on_section_body_entered(body: Node2D) -> void:
	if body.is_in_group("pawns") or body.name == "warrior" or body.name == "archer":
		player_in_range = true

func _on_section_body_exited(body: Node2D) -> void:
	if body.is_in_group("pawns") or body.name == "warrior" or body.name == "archer":
		player_in_range = false
		if not chopped:
			anim.play("idle")

func state():
	health = 3
	chopped = false
	anim.play("idle")

func sp_tree():
	var tree_scene = load("res://scenes/entities/decors/tree.tscn")
	if tree_scene:
		var tree_instance = tree_scene.instantiate()
		get_parent().add_child(tree_instance)
		tree_instance.global_position = global_position
