extends Area2D

func _ready() -> void:
	var t = create_tween().set_loops()
	t.tween_property($ColorRect, "color:a", 0.1, 0.2)
	t.tween_property($ColorRect, "color:a", 0.6, 0.2)

func explode() -> void:
	var explosion = preload("res://scenes/entities/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(3, 3)
	get_tree().current_scene.call_deferred("add_child", explosion)
	
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(2, self)
	queue_free()
