extends AnimatedSprite2D
@onready var fire: AnimatedSprite2D = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fire.animation="fire"
	fire.scale = Vector2(0.5, 0.5)
	var timer=get_tree().create_timer(1.5)
	await timer.timeout
	destroy()


func _physics_process(delta: float) -> void:
	
		position += direction * speed * delta
	
		# Get the angle to the target
		var target_angle: float = direction.angle()
	# Snap to the nearest cardinal direction
		var closest_angle:float=snap_to_nearest_angle(target_angle)
	
	
	# stop the dynamite
		var times = get_tree().create_timer(0.05)
		await times.timeout
		speed=0




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


func _on_fire_body_entered(body: Node2D) -> void:
	if body.name.begins_with("warrior"):
		var time=get_tree().create_timer(0.5)
		await time.timeout
		destroy()
