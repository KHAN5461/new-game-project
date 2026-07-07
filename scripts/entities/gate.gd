extends StaticBody2D

func _ready() -> void:
	add_to_group("gates")
	add_to_group("obstacles")

@export var required_keys: Array[String] = []
var provided_keys: Array[String] = []

func try_unlock(key_name: String) -> bool:
	if required_keys.size() == 0 and key_name == "":
		unlock()
		return true
		
	if key_name in required_keys:
		if not key_name in provided_keys:
			provided_keys.append(key_name)
		
		var all_good = true
		for k in required_keys:
			if not k in provided_keys:
				all_good = false
				
		if all_good:
			unlock()
		return true
	return false

func unlock() -> void:
	var explosion = preload("res://scenes/entities/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.modulate = Color(0.6, 0.4, 0.2)
	get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()

func open_gate() -> void:
	# Hide and disable collision instead of destroying
	visible = false
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", true)
	if is_in_group("obstacles"):
		remove_from_group("obstacles")

func close_gate() -> void:
	# Show and enable collision
	visible = true
	if has_node("CollisionShape2D"):
		get_node("CollisionShape2D").set_deferred("disabled", false)
	if not is_in_group("obstacles"):
		add_to_group("obstacles")

