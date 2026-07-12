@tool
extends StaticBody2D

@export_enum("Rock1", "Rock2", "Rock3", "Rock4") var decor_type: String = "Rock1":
	set(val):
		decor_type = val
		_update_texture()

@onready var sprite = $Sprite2D

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("obstacles")
	_update_texture()

func _update_texture() -> void:
	if not is_inside_tree(): return
	if not sprite: sprite = get_node_or_null("Sprite2D")
	if not sprite: return
	
	var path = ""
	if decor_type.begins_with("Rock"):
		path = "res://assets/Tiny Swords (Free Pack)/Terrain/Decorations/Rocks/" + decor_type + ".png"
	
	if path != "" and ResourceLoader.exists(path):
		sprite.texture = load(path)
