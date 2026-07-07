extends Path2D

@export var speed := 0.2

@onready var path_follow_2d: PathFollow2D = $PathFollow2D

var forwardDirection = 1
@onready var animatable_body = $AnimatableBody2D
@onready var rider_area = $AnimatableBody2D/RiderArea

func _ready():
	rider_area.body_entered.connect(_on_rider_entered)
	rider_area.body_exited.connect(_on_rider_exited)

func _on_rider_entered(body: Node2D):
	if body.is_in_group("warrior") or body.is_in_group("pushable"):
		var old_parent = body.get_parent()
		var g_pos = body.global_position
		old_parent.remove_child(body)
		animatable_body.add_child(body)
		body.global_position = g_pos
		if body.has_method("get") and "target_position" in body:
			body.target_position = body.position # update local target position

func _on_rider_exited(body: Node2D):
	if body.is_in_group("warrior") or body.is_in_group("pushable"):
		if body.get_parent() == animatable_body:
			var main_level = get_tree().get_first_node_in_group("game_level")
			if not main_level:
				main_level = get_tree().current_scene
			var g_pos = body.global_position
			animatable_body.remove_child(body)
			main_level.add_child(body)
			body.global_position = g_pos
			if body.has_method("get") and "target_position" in body:
				body.target_position = body.position

func _physics_process(delta: float) -> void:
	path_follow_2d.progress_ratio += speed * delta * forwardDirection
	
	if forwardDirection == 1 and path_follow_2d.progress_ratio == 1:
		forwardDirection = -1
	elif forwardDirection == -1 and path_follow_2d.progress_ratio == 0: 
		forwardDirection = 1
