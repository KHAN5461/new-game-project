extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior"):
		if AudioManager: AudioManager.play_coin()
		if body.has_method("add_gold"):
			body.add_gold(1)
		# Add a subtle animation/effect here later!
		queue_free()
