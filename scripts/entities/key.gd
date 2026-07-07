extends Area2D

@export var key_id: String = "gold_key"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior") and body.has_method("add_to_backpack"):
		body.add_to_backpack(key_id)
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(queue_free)
