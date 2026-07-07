extends Area2D
class_name Teleporter

@export var link_id: int = 1
var is_active: bool = true

func _ready() -> void:
	add_to_group("teleporters")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not is_active: return
	if body.is_in_group("warrior") or body.is_in_group("archer"):
		var all_teleporters = get_tree().get_nodes_in_group("teleporters")
		for t in all_teleporters:
			if t != self and t.link_id == self.link_id:
				t.is_active = false # Prevent instant bounce-back
				body.position = t.position
				if body.has_method("spawn_dust"): body.spawn_dust()
				# Re-activate after a short delay
				get_tree().create_timer(1.0).timeout.connect(func(): t.is_active = true)
				break
