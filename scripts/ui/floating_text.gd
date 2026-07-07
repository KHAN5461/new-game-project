extends Node2D

var text: String = ""
var color: Color = Color(1, 1, 1)

func _ready() -> void:
	$Label.text = text
	$Label.add_theme_color_override("font_color", color)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 32, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN).set_delay(0.2)
	
	await get_tree().create_timer(0.6).timeout
	queue_free()
