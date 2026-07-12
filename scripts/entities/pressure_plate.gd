extends Area2D

signal state_changed(is_pressed: bool)

@export var is_pressed: bool = false
@export var target_gate_path: NodePath

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D

var bodies_on_plate: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	update_visuals()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("warrior") or body.is_in_group("enemies") or body.is_in_group("pushable") or body.is_in_group("pawn") or body.is_in_group("builder"):
		bodies_on_plate += 1
		if bodies_on_plate > 0 and not is_pressed:
			is_pressed = true
			_trigger_state()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("warrior") or body.is_in_group("enemies") or body.is_in_group("pushable") or body.is_in_group("pawn") or body.is_in_group("builder"):
		bodies_on_plate -= 1
		if bodies_on_plate <= 0 and is_pressed:
			bodies_on_plate = 0
			is_pressed = false
			_trigger_state()

func _trigger_state() -> void:
	update_visuals()
	state_changed.emit(is_pressed)
	if audio:
		audio.play()
		
	if not target_gate_path.is_empty():
		var gate = get_node_or_null(target_gate_path)
		if gate:
			if is_pressed and gate.has_method("open_gate"):
				gate.open_gate()
			elif not is_pressed and gate.has_method("close_gate"):
				gate.close_gate()

func update_visuals() -> void:
	if is_pressed:
		sprite.scale = Vector2(0.9, 0.8)
		sprite.modulate = Color(0.7, 0.7, 0.7)
	else:
		sprite.scale = Vector2(1.0, 1.0)
		sprite.modulate = Color(1.0, 1.0, 1.0)
