extends Area2D

signal toggled(is_on: bool)

@export var is_on: bool = false
@export var target_gate_path: NodePath

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	update_visuals()

func interact() -> void:
	is_on = not is_on
	update_visuals()
	toggled.emit(is_on)
	
	if audio:
		audio.play()
		
	if not target_gate_path.is_empty():
		var gate = get_node_or_null(target_gate_path)
		if gate:
			if is_on and gate.has_method("open_gate"):
				gate.open_gate()
			elif not is_on and gate.has_method("close_gate"):
				gate.close_gate()

func update_visuals() -> void:
	if is_on:
		sprite.flip_h = true
		sprite.modulate = Color(0.5, 1.0, 0.5)
	else:
		sprite.flip_h = false
		sprite.modulate = Color(1.0, 0.5, 0.5)
