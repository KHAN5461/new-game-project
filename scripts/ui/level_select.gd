extends Control

@onready var grid = $MarginContainer/GridContainer
@onready var back_btn = $BackBtn

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	back_btn.custom_minimum_size = Vector2(250, 70)
	var back_style = StyleBoxTexture.new()
	back_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides.png")
	back_style.texture_margin_left = 20
	back_style.texture_margin_top = 20
	back_style.texture_margin_right = 20
	back_style.texture_margin_bottom = 20
	
	var back_hover = StyleBoxTexture.new()
	back_hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides.png")
	back_hover.texture_margin_left = 20
	back_hover.texture_margin_top = 20
	back_hover.texture_margin_right = 20
	back_hover.texture_margin_bottom = 20
	back_hover.modulate_color = Color(1.2, 1.2, 1.2)
	
	var back_pressed = StyleBoxTexture.new()
	back_pressed.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_9Slides_Pressed.png")
	back_pressed.texture_margin_left = 20
	back_pressed.texture_margin_top = 20
	back_pressed.texture_margin_right = 20
	back_pressed.texture_margin_bottom = 20
	
	back_btn.add_theme_stylebox_override("normal", back_style)
	back_btn.add_theme_stylebox_override("hover", back_hover)
	back_btn.add_theme_stylebox_override("pressed", back_pressed)
	
	# Instantiate Tech Tree Button
	var tech_tree_btn = Button.new()
	tech_tree_btn.text = "RESEARCH"
	tech_tree_btn.custom_minimum_size = Vector2(250, 70)
	tech_tree_btn.position = Vector2(1152 - 280, 30)
	tech_tree_btn.add_theme_font_size_override("font_size", 20)
	
	var tech_style = StyleBoxTexture.new()
	tech_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides.png")
	tech_style.texture_margin_left = 20
	tech_style.texture_margin_top = 20
	tech_style.texture_margin_right = 20
	tech_style.texture_margin_bottom = 20
	
	var tech_hover = StyleBoxTexture.new()
	tech_hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Hover_9Slides.png")
	tech_hover.texture_margin_left = 20
	tech_hover.texture_margin_top = 20
	tech_hover.texture_margin_right = 20
	tech_hover.texture_margin_bottom = 20
	
	var tech_pressed = StyleBoxTexture.new()
	tech_pressed.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides_Pressed.png")
	tech_pressed.texture_margin_left = 20
	tech_pressed.texture_margin_top = 20
	tech_pressed.texture_margin_right = 20
	tech_pressed.texture_margin_bottom = 20
	
	tech_tree_btn.add_theme_stylebox_override("normal", tech_style)
	tech_tree_btn.add_theme_stylebox_override("hover", tech_hover)
	tech_tree_btn.add_theme_stylebox_override("pressed", tech_pressed)
	
	tech_tree_btn.pressed.connect(func(): SceneTransition.change_scene("res://scenes/ui/tech_tree.tscn"))
	add_child(tech_tree_btn)
	

	
	for i in range(Global.levels.size()):
		var btn = Button.new()
		var level_data = Global.levels[i]
		
		btn.text = str(i + 1)
		
		var unlocked = true
		if Global and i >= Global.max_unlocked_level:
			unlocked = false
			
		if unlocked and Global and Global.level_stars.has(str(i + 1)):
			var stars = Global.level_stars[str(i + 1)]
			var star_str = ""
			for s in range(3):
				if s < stars: star_str += "★"
				else: star_str += "☆"
			btn.text += "\n" + star_str
			
		btn.custom_minimum_size = Vector2(100, 100)
		btn.add_theme_font_size_override("font_size", 32)
		
		var normal_style = StyleBoxTexture.new()
		normal_style.texture_margin_left = 20
		normal_style.texture_margin_top = 20
		normal_style.texture_margin_right = 20
		normal_style.texture_margin_bottom = 20
		
		var hover_style = StyleBoxTexture.new()
		hover_style.texture_margin_left = 20
		hover_style.texture_margin_top = 20
		hover_style.texture_margin_right = 20
		hover_style.texture_margin_bottom = 20
		
		var pressed_style = StyleBoxTexture.new()
		pressed_style.texture_margin_left = 20
		pressed_style.texture_margin_top = 20
		pressed_style.texture_margin_right = 20
		pressed_style.texture_margin_bottom = 20
			
		if not unlocked:
			btn.disabled = true
			normal_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Disable_9Slides.png")
			btn.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		else:
			normal_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides.png")
			hover_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Hover_9Slides.png")
			pressed_style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides_Pressed.png")
			btn.add_theme_color_override("font_color", Color(1, 1, 1))
			

			
			btn.pressed.connect(_on_level_selected.bind(i + 1))
			
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_stylebox_override("disabled", normal_style)
			
		grid.add_child(btn)

func _on_level_selected(index: int) -> void:
	if Global:
		Global.selected_level = index
		Global.endless_mode = false
	SceneTransition.change_scene("res://scenes/levels/main_game.tscn")

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
