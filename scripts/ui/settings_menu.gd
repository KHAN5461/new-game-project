extends CanvasLayer

signal closed

@onready var auto_check: CheckButton = $CenterContainer/NinePatchRect/VBoxContainer/Row1/HBox/AutocompleteCheck
@onready var fast_check: CheckButton = $CenterContainer/NinePatchRect/VBoxContainer/Row2/HBox/FastExecutionCheck
@onready var full_check: CheckButton = $CenterContainer/NinePatchRect/VBoxContainer/Row3/HBox/FullscreenCheck
@onready var ide_left_check: CheckButton = $CenterContainer/NinePatchRect/VBoxContainer/Row4/HBox/IDEOnLeftCheck
@onready var back_btn: TextureButton = $CenterContainer/NinePatchRect/VBoxContainer/BackBtn

func _ready() -> void:
	back_btn.pressed.connect(func(): hide(); closed.emit())
	
	_add_language_dropdown()
	
	if Global:
		auto_check.button_pressed = Global.autocomplete_enabled
		fast_check.button_pressed = Global.fast_execution
		full_check.button_pressed = Global.fullscreen
		ide_left_check.button_pressed = Global.ide_on_left
		
	auto_check.toggled.connect(_on_auto_toggled)
	fast_check.toggled.connect(_on_fast_toggled)
	full_check.toggled.connect(_on_full_toggled)
	ide_left_check.toggled.connect(_on_ide_left_toggled)

func _on_auto_toggled(toggled_on: bool) -> void:
	if Global: Global.autocomplete_enabled = toggled_on
	if Global: Global.save_game()

func _on_fast_toggled(toggled_on: bool) -> void:
	if Global: Global.fast_execution = toggled_on
	if Global: Global.save_game()

func _on_full_toggled(toggled_on: bool) -> void:
	if Global: Global.fullscreen = toggled_on
	if Global: Global.save_game()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_ide_left_toggled(toggled_on: bool) -> void:
	if Global: Global.ide_on_left = toggled_on
	if Global: Global.save_game()

func _add_language_dropdown():
	var vbox = $CenterContainer/NinePatchRect/VBoxContainer
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = "Language: "
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	
	var lang_option = OptionButton.new()
	lang_option.add_item("Python", 0)
	lang_option.add_item("C++", 1)
	lang_option.add_item("Java", 2)
	
	if GlobalSettings:
		lang_option.select(GlobalSettings.active_language)
	
	lang_option.item_selected.connect(_on_language_selected)
	
	hbox.add_child(label)
	hbox.add_child(lang_option)
	vbox.add_child(hbox)
	vbox.move_child(hbox, 0) # Move to the top

func _on_language_selected(index: int):
	if GlobalSettings:
		GlobalSettings.active_language = index
		GlobalSettings.save_settings()
