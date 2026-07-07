class_name BattlerStats extends Resource

signal health_changed(new_health)

@export var base_max_health: int = 10
@export var health: int = 10:
	set(value):
		health = clamp(value, 0, max_health)
		health_changed.emit(health)

@export var attack: int = 1
@export var defense: int = 0

var max_health: int:
	get:
		return base_max_health

func initialize() -> void:
	health = max_health

static func restore() -> BattlerStats:
	return BattlerStats.new()
