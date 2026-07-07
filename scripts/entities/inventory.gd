class_name Inventory extends Resource

enum ItemTypes {
	POTION,
	KEY,
	APPLE,
	TNT
}

var items: Dictionary = {}

static func restore() -> Inventory:
	return Inventory.new()

func get_item_count(type: int) -> int:
	return items.get(type, 0)

func remove(type: int) -> void:
	if items.has(type) and items[type] > 0:
		items[type] -= 1
		
func add(type: int, amount: int = 1) -> void:
	if items.has(type):
		items[type] += amount
	else:
		items[type] = amount
