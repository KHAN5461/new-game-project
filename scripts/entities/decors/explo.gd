extends AnimatedSprite2D
@onready var explo: AnimatedSprite2D = $"."



func _ready() -> void:
	explo.animation="default"



func _process(delta: float) -> void:
	pass


func _on_animation_finished() -> void:
	queue_free()
