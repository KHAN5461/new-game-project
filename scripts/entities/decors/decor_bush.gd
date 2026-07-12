@tool
extends Node2D

@export_enum("Bush1", "Bush2", "Bush3", "Bush4") var bush_type: String = "Bush1":
	set(val):
		bush_type = val
		_update_sprite()

@onready var anim_sprite = $AnimatedSprite2D

func _ready() -> void:
	_update_sprite()

func _update_sprite() -> void:
	if not is_inside_tree(): return
	if not anim_sprite: anim_sprite = get_node_or_null("AnimatedSprite2D")
	if not anim_sprite: return
	
	var anim_name = bush_type.to_lower()
	if anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation(anim_name):
		anim_sprite.animation = anim_name
		anim_sprite.play(anim_name)
