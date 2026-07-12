extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior") or body.name == "warrior":
		if body.has_method("heal"):
			body.heal(5)
		Stats.add_meat()
		queue_free()
	elif body.is_in_group("pawns"):
		if body.has_method("add_to_inventory"):
			body.add_to_inventory("meat", 1)
		queue_free()
