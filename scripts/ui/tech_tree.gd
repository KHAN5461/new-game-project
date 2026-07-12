extends Control

@onready var stars_label = $StarsLabel
@onready var respec_btn = $RespecBtn
@onready var back_btn = $BackBtn
@onready var nodes_container = $NodesContainer

# Tech Tree node definition
var tech_nodes = {
	"while": {
		"name": "while loop",
		"desc": "Allows repeating instructions based on a condition.",
		"cost": 1,
		"prereqs": [],
		"pos": Vector2(250, 250)
	},
	"if": {
		"name": "if condition",
		"desc": "Enables conditional execution of statements.",
		"cost": 1,
		"prereqs": [],
		"pos": Vector2(550, 250)
	},
	"var": {
		"name": "variables",
		"desc": "Stores dynamic numeric variables.",
		"cost": 1,
		"prereqs": ["if", "while"],
		"pos": Vector2(400, 380)
	},
	"radar": {
		"name": "radar check",
		"desc": "Check if an enemy is in proximity.",
		"cost": 2,
		"prereqs": ["if"],
		"pos": Vector2(700, 380)
	},
	"build": {
		"name": "build structure",
		"desc": "Deploy houses, sawmills, or storage structures.",
		"cost": 2,
		"prereqs": ["var"],
		"pos": Vector2(250, 510)
	},
	"def": {
		"name": "functions",
		"desc": "Define custom reusable code functions.",
		"cost": 3,
		"prereqs": ["var"],
		"pos": Vector2(550, 510)
	},
	"send_message": {
		"name": "send message",
		"desc": "Broadcast numeric swarm signals to adjacent pawns.",
		"cost": 3,
		"prereqs": ["radar"],
		"pos": Vector2(850, 510)
	},
	"receive_message": {
		"name": "receive message",
		"desc": "Listen to and process numeric swarm signals.",
		"cost": 3,
		"prereqs": ["send_message"],
		"pos": Vector2(850, 640)
	}
}

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	respec_btn.pressed.connect(_on_respec_pressed)
	
	# Apply premium styling to buttons
	_style_btn(back_btn, "Button_Red_9Slides.png", "Button_Red_9Slides_Pressed.png")
	_style_btn(respec_btn, "Button_Yellow_9Slides.png", "Button_Yellow_9Slides_Pressed.png")
	
	_create_tree_buttons()
	_update_ui()

func _draw() -> void:
	# Draw connecting lines between nodes based on prerequisite relationships
	for key in tech_nodes.keys():
		var node = tech_nodes[key]
		var button = nodes_container.get_node_or_null(key)
		if not button: continue
		
		# Draw paths from prerequisites
		for prereq in node["prereqs"]:
			var prereq_node = tech_nodes[prereq]
			var prereq_btn = nodes_container.get_node_or_null(prereq)
			if not prereq_btn: continue
			
			# Decide color based on if both are unlocked
			var is_unlocked = (key in Global.unlocked_keywords) and (prereq in Global.unlocked_keywords)
			var color = Color(0.2, 0.8, 0.2, 0.8) if is_unlocked else Color(0.3, 0.3, 0.3, 0.5)
			var width = 6.0 if is_unlocked else 3.0
			
			draw_line(button.position + button.size / 2, prereq_btn.position + prereq_btn.size / 2, color, width)

func _create_tree_buttons() -> void:
	for key in tech_nodes.keys():
		var data = tech_nodes[key]
		var btn = Button.new()
		btn.name = key
		btn.text = data["name"].to_upper() + "\n" + str(data["cost"]) + " Star" + ("s" if data["cost"] > 1 else "")
		btn.custom_minimum_size = Vector2(180, 70)
		btn.position = data["pos"] - btn.custom_minimum_size / 2
		btn.alignment = HorizontalAlignment.CENTER
		
		# Premium theme/styling setup
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(_on_node_pressed.bind(key))
		
		# Tooltip description
		btn.tooltip_text = data["desc"]
		
		nodes_container.add_child(btn)

func _update_ui() -> void:
	# Update Star Labels
	var total = Global.get_total_stars()
	var available = Global.get_available_stars()
	stars_label.text = "STAR RESEARCH TREE\nTotal Stars Earned: " + str(total) + " ★   |   Available: " + str(available) + " ★"
	
	# Update Node Buttons
	for key in tech_nodes.keys():
		var btn = nodes_container.get_node_or_null(key)
		if not btn: continue
		
		var node = tech_nodes[key]
		var is_unlocked = key in Global.unlocked_keywords
		var is_unlocked_prereq = true
		
		# Prerequisite check
		if key == "var":
			is_unlocked_prereq = ("if" in Global.unlocked_keywords) or ("while" in Global.unlocked_keywords)
		else:
			for prereq in node["prereqs"]:
				if not prereq in Global.unlocked_keywords:
					is_unlocked_prereq = false
					break
		
		# Styling Box
		var style_normal = StyleBoxTexture.new()
		style_normal.texture_margin_left = 10
		style_normal.texture_margin_top = 10
		style_normal.texture_margin_right = 10
		style_normal.texture_margin_bottom = 10
		
		var style_hover = StyleBoxTexture.new()
		style_hover.texture_margin_left = 10
		style_hover.texture_margin_top = 10
		style_hover.texture_margin_right = 10
		style_hover.texture_margin_bottom = 10
		
		if is_unlocked:
			btn.disabled = false
			style_normal.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_9Slides.png")
			style_hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Hover_9Slides.png")
			btn.text = node["name"].to_upper() + "\n(UNLOCKED)"
			btn.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		elif is_unlocked_prereq:
			btn.disabled = false
			style_normal.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Yellow_9Slides.png")
			style_hover.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Yellow_9Slides.png")
			style_hover.modulate = Color(1.2, 1.2, 1.2)
			btn.text = node["name"].to_upper() + "\n" + str(node["cost"]) + " ★"
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.disabled = true
			style_normal.texture = load("res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Disable_9Slides.png")
			btn.text = node["name"].to_upper() + "\n(LOCKED)"
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
			
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("disabled", style_normal)
	
	queue_redraw()

func _on_node_pressed(key: String) -> void:
	if key in Global.unlocked_keywords: return
	
	var node = tech_nodes[key]
	var cost = node["cost"]
	if Global.get_available_stars() >= cost:
		Global.spent_stars += cost
		Global.unlocked_keywords.append(key)
		Global.save_game()
		_update_ui()

func _on_respec_pressed() -> void:
	Global.reset_tech_tree()
	_update_ui()

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/level_select.tscn")

func _style_btn(btn: Button, normal_tex: String, pressed_tex: String) -> void:
	var path_normal = "res://assets/Tiny Swords (Update 010)/UI/Buttons/" + normal_tex
	var path_pressed = "res://assets/Tiny Swords (Update 010)/UI/Buttons/" + pressed_tex
	
	var style = StyleBoxTexture.new()
	style.texture = load(path_normal)
	style.texture_margin_left = 20
	style.texture_margin_top = 20
	style.texture_margin_right = 20
	style.texture_margin_bottom = 20
	
	var style_hover = StyleBoxTexture.new()
	style_hover.texture = load(path_normal)
	style_hover.texture_margin_left = 20
	style_hover.texture_margin_top = 20
	style_hover.texture_margin_right = 20
	style_hover.texture_margin_bottom = 20
	style_hover.modulate = Color(1.2, 1.2, 1.2)
	
	var style_press = StyleBoxTexture.new()
	style_press.texture = load(path_pressed)
	style_press.texture_margin_left = 20
	style_press.texture_margin_top = 20
	style_press.texture_margin_right = 20
	style_press.texture_margin_bottom = 20
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_press)
