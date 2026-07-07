extends Area2D
class_name ConveyorBelt

@export var direction: Vector2 = Vector2.RIGHT
@export var speed: float = 1.0

func _ready() -> void:
	add_to_group("conveyors")
	
func get_push_direction() -> Vector2:
	return direction
