extends StaticBody2D

@onready var sprite = $Sprite2D

var ignited = false

func _ready() -> void:
	# Add to enemy group so warrior can target and attack it
	add_to_group("enemy")

func take_damage() -> void:
	if not ignited:
		ignited = true
		ignite()

func ignite() -> void:
	# Flash red and white rapidly
	var tween = create_tween()
	for i in range(5):
		tween.tween_property(sprite, "modulate", Color(2, 0.5, 0.5), 0.15)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.15)
	
	await tween.finished
	explode()

func explode() -> void:
	# Spawn particle explosion
	var explosion = preload("res://scenes/entities/explosion.tscn").instantiate()
	explosion.global_position = global_position
	explosion.scale = Vector2(2, 2) # Massive explosion!
	get_parent().add_child(explosion)
	
	# Damage everything in a 128px radius
	var space_state = get_world_2d().direct_space_state
	var shape = CircleShape2D.new()
	shape.radius = 128.0
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query)
	for result in results:
		var collider = result.collider
		if collider.has_method("take_damage") and collider != self:
			collider.take_damage(1, self)
			collider.take_damage(1, self) # Deal double damage
			collider.take_damage(1, self)
	
	queue_free()
