extends CanvasLayer

func _ready() -> void:
	if Global: Global.save_game()
	var btn = get_node("PanelContainer/VBoxContainer/MainMenuButton")
	if btn:
		btn.pressed.connect(_on_main_menu_pressed)

func _on_main_menu_pressed() -> void:
	LevelManager.current_level_index = 1
	get_tree().paused = false
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
