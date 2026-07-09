extends Node

var active_language: int = CustomLexer.LanguageMode.PYTHON
var settings_file_path: String = "user://game_settings.cfg"

func _ready():
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(settings_file_path)
	if err == OK:
		active_language = config.get_value("Compiler", "Language", CustomLexer.LanguageMode.PYTHON)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Compiler", "Language", active_language)
	config.save(settings_file_path)
