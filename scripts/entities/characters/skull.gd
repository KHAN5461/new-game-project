extends AnimatedSprite2D
@onready var skull: AnimatedSprite2D = $"."

func _ready() -> void:
	skull.animation="sp"
	var timer=get_tree().create_timer(2.5)
	timer.timeout.connect(self.desapear)

func desapear():
	skull.animation="die"
	await skull.animation_finished
	die()
	
func die():
	queue_free()
