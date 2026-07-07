extends CanvasLayer

@onready var resume_btn: Button = $CenterContainer/TextureRect/VBoxContainer/ResumeBtn
@onready var restart_btn: Button = $CenterContainer/TextureRect/VBoxContainer/RestartBtn
@onready var quit_btn: Button = $CenterContainer/TextureRect/VBoxContainer/QuitBtn

func _ready() -> void:
	hide()
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	quit_btn.pressed.connect(_on_quit)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if visible:
				_on_resume()
			else:
				# Don't pause if the game is over
				var gm = get_node_or_null("/root/MainGame/GameManager")
				if gm and (gm.state == "GAMEOVER" or gm.state == "VICTORY"): return
				
				show()
				get_tree().paused = true

func _on_resume() -> void:
	hide()
	get_tree().paused = false

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
