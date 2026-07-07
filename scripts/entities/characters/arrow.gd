extends Area2D
@onready var arrow: Area2D = $"."



var speed=700
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

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
		# Get the angle to the target
	var target_angle: float = direction.angle()
	# Snap to the nearest cardinal direction
	var closest_angle:float=snap_to_nearest_angle(target_angle)
	# Set the rotation of the arrow
	rotation = closest_angle


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
	arrow.look_at(direction)
	

func destroy():
	var timer=get_tree().create_timer(0.5)
	timer.timeout.connect(self.die)

func die():
	queue_free()


# functions to check what collide with the arrow

func _on_body_entered(body: Node2D) -> void:
	if body.name=="limits":
		die()
	if body.name=="warrior":
		die()
	if body.name=="archer":
		destroy()
	if body.name=="goblin_barrel":
		die()
	if body.name=="goblin_tnt":
		die()
	if body.name=="goblin_torch":
		die()
