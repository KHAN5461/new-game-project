extends Area2D
@onready var anim: AnimatedSprite2D = $Anim



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim.animation="sp"
	



func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("pawns"):
		var timer=get_tree().create_timer(0.5)
		timer.timeout.connect(self.die)
	if body.name=="warrior":
		var timer=get_tree().create_timer(0.5)
		timer.timeout.connect(self.die)

func die():
		queue_free()
		Stats.add_wood()

