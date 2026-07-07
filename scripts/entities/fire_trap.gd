extends Area2D

@export var is_active: bool = false
@onready var sprite = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visuals()
	
func _on_ai_tick() -> void:
	is_active = not is_active
	_update_visuals()
	if is_active:
		for body in get_overlapping_bodies():
			if body.is_in_group("warrior") and body.has_method("take_damage"):
				body.take_damage(1, self)

func _on_body_entered(body: Node2D) -> void:
	if is_active and body.is_in_group("warrior") and body.has_method("take_damage"):
		body.take_damage(1, self)

func _update_visuals() -> void:
	if is_active:
		sprite.modulate = Color(1, 1, 1, 1)
		sprite.frame = randi() % 7
	else:
		sprite.modulate = Color(1, 1, 1, 0.3)
		sprite.frame = 0
