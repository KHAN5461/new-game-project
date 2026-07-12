extends StaticBody2D

var hp: int = 3
@onready var meat_scene = preload("res://scenes/entities/meat.tscn")

func _ready() -> void:
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")

func take_damage(amount: int = 1) -> void:
	hp -= amount
	if hp <= 0:
		die()
	else:
		if has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.modulate = Color(1, 0, 0)
			var t = get_tree().create_timer(0.2)
			t.timeout.connect(func(): $AnimatedSprite2D.modulate = Color(1, 1, 1))

func die() -> void:
	if Global:
		# Only pawns carry and drop off meat now
		print("Gained 1 meat from sheep!")
	queue_free()
