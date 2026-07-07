extends StaticBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func activate(boolean: bool):
	if boolean:
		animated_sprite_2d.play("open")
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		animated_sprite_2d.play_backwards("open")
		$CollisionShape2D.set_deferred("disabled", false)
