extends Area2D
@onready var anim: AnimatedSprite2D = $anim
@onready var explo: AnimatedSprite2D = $explo

var speed=500
var direction=Vector2.ZERO


# Define cardinal and intercardinal angles in radians
var direction_rad: Array = [
	Vector2(0, -1),  # North (0 radians)
	Vector2(1, -1).normalized(),  # Northeast (45 degrees)
	Vector2(1, 0),  # East (90 degrees)
	Vector2(1, 1).normalized(),  # Southeast (135 degrees)
	Vector2(0, 1),  # South (180 degrees)
	Vector2(-1, 1).normalized(),  # Southwest (225 degrees)
	Vector2(-1, 0),  # West (270 degrees)
	Vector2(-1, -1).normalized()  # Northwest (315 degrees)
]
func rotate_towards(target_position: Vector2) -> void:
	#Calculate the direction to the target
	var direction: Vector2 = (target_position - global_position).normalized()

var time_alive: float = 0.0
func _physics_process(delta: float) -> void:
	time_alive += delta
	position += direction * speed * delta
	
	# Get the angle to the target
	var target_angle: float = direction.angle()
	# Snap to the nearest cardinal direction
	var closest_angle:float=snap_to_nearest_angle(target_angle)
	# Set the rotation of the arrow
	rotation = closest_angle
	
	# stop the dynamite
	if time_alive > 0.5:
		stop()

# stop the tnt after a define time
func stop():
	speed=0


# function to normalize the arrow direction
func snap_to_nearest_angle(angle: float) -> float:
	var closest_angle: float = 0
	var closest_distance: float = INF
	for dir in direction_rad:
		var dir_angle: float = dir.angle()
		var distance: float = abs(angle - dir_angle)
		if distance < closest_distance:
			closest_distance = distance
			closest_angle = dir_angle
	return closest_angle
	
func directions(direction:Vector2):
	self.direction=direction
	
func destroy():
	var explo_scene = preload("res://scenes/entities/decors/explo.tscn")
	var explo_instance = explo_scene.instantiate()
	get_parent().add_child(explo_instance)
	explo_instance.global_position = global_position
	queue_free()
	

func _on_detector_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		var timer=get_tree().create_timer(0.05)
		timer.timeout.connect(self.destroy)
	if body.name.begins_with("pawn"):
		var timer=get_tree().create_timer(0.05)
		timer.timeout.connect(self.destroy)
	if body.name=="limits":
		queue_free()
	


func _on_detector_area_entered(area: Area2D) -> void:
	if area.name.begins_with("house"):
		destroy()
	if area.name.begins_with("tower"):
		destroy()
	if area.name.begins_with("castle"):
		destroy()
	if area.name.begins_with("mine"):
		destroy()
