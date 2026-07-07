class_name TNTBarrel
extends StaticBody2D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("TNTBarrel")

func explode() -> void:
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("shake"):
		cam.shake(20.0)
	
	if anim_player and anim_player.has_animation("explode"):
		anim_player.play("explode")
		await anim_player.animation_finished
	else:
		if get_tree():
			await get_tree().create_timer(0.5).timeout
		
	queue_free()
