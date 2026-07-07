extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior"):
		if body.has_method("heal"):
			body.heal(5)
		queue_free()
