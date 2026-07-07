extends CanvasLayer

signal finished

@onready var text_label: RichTextLabel = %TextLabel
@onready var portrait_rect: TextureRect = %Portrait

var is_animating: bool = false
var full_text: String = ""

func start_dialogue(text: String, portrait: Texture2D = null) -> void:
    full_text = text
    text_label.text = text
    text_label.visible_characters = 0
    
    if portrait:
        portrait_rect.texture = portrait
        portrait_rect.show()
    else:
        portrait_rect.hide()
        
    is_animating = true
    
    var tween = create_tween()
    tween.tween_property(text_label, "visible_ratio", 1.0, text.length() * 0.02)
    tween.finished.connect(func(): is_animating = false)

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
        get_viewport().set_input_as_handled()
        if is_animating:
            # Skip animation
            is_animating = false
            text_label.visible_ratio = 1.0
        else:
            # End dialogue
            finished.emit()
