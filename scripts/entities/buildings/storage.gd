class_name StorageHouse
extends StaticBody2D

func _ready() -> void:
	add_to_group("storage")
	add_to_group("house") # Pawns look for house/storage groups to drop off items

func insert_item(item: String, pawn: Node2D) -> void:
	if item == "wood" or pawn.inventory.get("wood", 0) > 0:
		if pawn.inventory.get("wood", 0) > 0: pawn.inventory["wood"] -= 1
		Stats.add_wood()
		pawn._spawn_floating_text("- Wood", Color(0.6, 0.4, 0.2))
	elif item == "meat" or pawn.inventory.get("meat", 0) > 0:
		if pawn.inventory.get("meat", 0) > 0: pawn.inventory["meat"] -= 1
		Stats.add_meat()
		pawn._spawn_floating_text("- Meat", Color(0.9, 0.3, 0.3))
	elif item == "gold" or pawn.inventory.get("gold", 0) > 0:
		if pawn.inventory.get("gold", 0) > 0: pawn.inventory["gold"] -= 1
		Stats.add_gold()
		pawn._spawn_floating_text("- Gold", Color(1.0, 0.9, 0.2))
