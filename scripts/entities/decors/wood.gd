extends Area2D
@onready var anim: AnimatedSprite2D = $Anim



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.animation="sp"
	



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("pawns"):
		if body.has_method("add_to_inventory"):
			body.add_to_inventory("wood", 1)
		queue_free()
	elif body.name == "warrior":
		Stats.add_wood()
		queue_free()

