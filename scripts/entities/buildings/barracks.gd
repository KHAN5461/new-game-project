class_name Barracks
extends StaticBody2D

var plank_count: int = 0
var processing: bool = false

func _ready() -> void:
	add_to_group("barracks")

func insert_item(item: String, pawn: Node2D) -> void:
	if item == "plank" or pawn.inventory.get("plank", 0) > 0:
		if pawn.inventory.get("plank", 0) > 0: pawn.inventory["plank"] -= 1
		plank_count += 1
		pawn._spawn_floating_text("- Plank", Color(0.8, 0.6, 0.3))
		if not processing:
			process_plank()

func process_plank() -> void:
	if plank_count >= 2: # Requires 2 planks
		processing = true
		plank_count -= 2
		await get_tree().create_timer(2.5).timeout
		spawn_warrior()
		processing = false
		process_plank()

func spawn_warrior() -> void:
	var warrior = preload("res://scenes/entities/characters/warrior.tscn").instantiate()
	warrior.global_position = global_position + Vector2(0, 64) # Spawn below
	get_tree().current_scene.add_child(warrior)
