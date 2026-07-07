extends Control

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var viewport: SubViewport = $HBoxContainer/SubViewportContainer/SubViewport
@onready var ide_ui = $HBoxContainer/IDE_UI

func _ready() -> void:
	if LevelManager:
		LevelManager.main_viewport = viewport
		
		if Global and Global.endless_mode:
			LevelManager._load_level("")
		else:
			if Global and Global.selected_level > 0:
				LevelManager.current_level_index = Global.selected_level
			LevelManager._load_level(LevelManager.get_level_path(LevelManager.current_level_index))
			if LevelManager.current_level_index == 0:
				ide_ui.hide()
			else:
				ide_ui.show()

	if ide_ui and ide_ui.has_signal("toggled_state"):
		ide_ui.toggled_state.connect(_on_ide_toggled)
		
	LevelManager.level_started.connect(_on_level_started)

func _on_level_started(index: int) -> void:
	if index == 0:
		ide_ui.hide()
	else:
		ide_ui.show()

func _process(_delta: float) -> void:
	if Global and ide_ui:
		if Global.ide_on_left:
			hbox.move_child(ide_ui, 0)
		else:
			hbox.move_child(ide_ui, 1)

func _on_ide_toggled(_is_open: bool) -> void:
	pass
