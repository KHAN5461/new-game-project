extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior") or body.name == "warrior":
		if AudioManager: AudioManager.play_coin()
		if body.has_method("add_gold"):
			body.add_gold(1)
		Stats.add_cash()
		queue_free()
	elif body.is_in_group("pawns"):
		if AudioManager: AudioManager.play_coin()
		if body.has_method("add_to_inventory"):
			body.add_to_inventory("cash", 1)
		queue_free()
