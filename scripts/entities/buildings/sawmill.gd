class_name Sawmill
extends StaticBody2D

var wood_count: int = 0
var processing: bool = false

func _ready() -> void:
	add_to_group("sawmill")

func insert_item(item: String, pawn: Node2D) -> void:
	if item == "wood" or pawn.inventory.get("wood", 0) > 0:
		if pawn.inventory.get("wood", 0) > 0: pawn.inventory["wood"] -= 1
		wood_count += 1
		pawn._spawn_floating_text("- Wood", Color(0.6, 0.4, 0.2))
		if not processing:
			process_wood()

func process_wood() -> void:
	if wood_count > 0:
		processing = true
		wood_count -= 1
		await get_tree().create_timer(1.5).timeout
		spawn_plank()
		processing = false
		process_wood()

func spawn_plank() -> void:
	var plank = preload("res://scenes/entities/decors/plank.tscn").instantiate()
	plank.global_position = global_position + Vector2(64, 0) # Spawn to the right
	get_tree().current_scene.add_child(plank)
