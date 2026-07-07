extends Sprite2D

func _ready() -> void:
	if $AnimationPlayer.has_animation("explode"):
		$AnimationPlayer.play("explode")
		await $AnimationPlayer.animation_finished
	queue_free()
