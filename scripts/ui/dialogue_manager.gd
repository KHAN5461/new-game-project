extends Node

signal dialogue_finished

var dialogue_box_scene = preload("res://scenes/ui/dialogue_box.tscn")
var current_box: Control = null

func show_dialogue(text: String, portrait: Texture2D = null) -> void:
    if current_box:
        current_box.queue_free()
    
    current_box = dialogue_box_scene.instantiate()
    get_tree().root.add_child(current_box)
    
    # Pause game while dialogue is active
    get_tree().paused = true
    
    current_box.start_dialogue(text, portrait)
    current_box.finished.connect(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
    if current_box:
        current_box.queue_free()
        current_box = null
    
    # Resume game
    get_tree().paused = false
    dialogue_finished.emit()
