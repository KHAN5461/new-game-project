extends Panel

signal confirmed
signal cancelled

@onready var alert_label: Label = $PanelContainer/VBoxContainer/alert
@onready var confirm_button: Button = $PanelContainer/VBoxContainer/Buttons/confirms
@onready var cancel_button: Button = $PanelContainer/VBoxContainer/Buttons/cancels

func _ready() -> void:
	if confirm_button:
		confirm_button.pressed.connect(_on_confirm_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

func set_alert_text(text: String) -> void:
	if alert_label:
		alert_label.text = text

func _on_confirm_pressed() -> void:
	emit_signal("confirmed")
	hide()

func _on_cancel_pressed() -> void:
	emit_signal("cancelled")
	hide()
