import os

tscn_content = """[gd_scene load_steps=5 format=3 uid="uid://cx6m1q1w2e3r4"]

[ext_resource type="Script" path="res://ide_controller.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Banners/Banner_Vertical.png" id="2_banner"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides.png" id="3_btn_n"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides_Pressed.png" id="4_btn_p"]

[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_bg"]
texture = ExtResource("2_banner")
texture_margin_left = 64.0
texture_margin_top = 64.0
texture_margin_right = 64.0
texture_margin_bottom = 64.0
content_margin_left = 10.0
content_margin_top = 0.0
content_margin_right = 10.0
content_margin_bottom = 15.0

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_title"]

[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_btn"]
texture = ExtResource("3_btn_n")
texture_margin_left = 32.0
texture_margin_top = 16.0
texture_margin_right = 32.0
texture_margin_bottom = 32.0

[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_btn_p"]
texture = ExtResource("4_btn_p")
texture_margin_left = 32.0
texture_margin_top = 16.0
texture_margin_right = 32.0
texture_margin_bottom = 32.0

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_code"]

[node name="IDE_UI" type="PanelContainer"]
offset_left = 30.0
offset_top = 30.0
offset_right = 350.0
offset_bottom = 450.0
theme_override_styles/panel = SubResource("StyleBoxTexture_bg")
script = ExtResource("1_script")

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 5

[node name="TitleBar" type="PanelContainer" parent="VBoxContainer"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
mouse_default_cursor_shape = 13
theme_override_styles/panel = SubResource("StyleBoxEmpty_title")

[node name="HBox" type="HBoxContainer" parent="VBoxContainer/TitleBar"]
layout_mode = 2
mouse_filter = 2

[node name="Icon" type="Label" parent="VBoxContainer/TitleBar/HBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.25, 0.15, 0.05, 1)
theme_override_font_sizes/font_size = 20
text = " 📜"

[node name="Title" type="Label" parent="VBoxContainer/TitleBar/HBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.25, 0.15, 0.05, 1)
theme_override_font_sizes/font_size = 18
text = " Spell Scroll"
vertical_alignment = 1

[node name="MinimizeBtn" type="Button" parent="VBoxContainer/TitleBar/HBox"]
custom_minimum_size = Vector2(40, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.25, 0.15, 0.05, 1)
theme_override_colors/font_hover_color = Color(0.5, 0.15, 0.05, 1)
theme_override_font_sizes/font_size = 24
text = "-"
flat = true

[node name="Body" type="MarginContainer" parent="VBoxContainer"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/margin_left = 10
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 5

[node name="VBox" type="VBoxContainer" parent="VBoxContainer/Body"]
layout_mode = 2

[node name="CodeEdit" type="CodeEdit" parent="VBoxContainer/Body/VBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_colors/background_color = Color(0, 0, 0, 0)
theme_override_colors/font_color = Color(0.2, 0.1, 0.05, 1)
theme_override_colors/line_number_color = Color(0.5, 0.3, 0.15, 0.8)
theme_override_font_sizes/font_size = 14
theme_override_styles/normal = SubResource("StyleBoxEmpty_code")
theme_override_styles/focus = SubResource("StyleBoxEmpty_code")
text = "move_right(3)
attack()
move_up(2)"
draw_executing_lines = true
draw_line_numbers = true
auto_brace_completion_enabled = true
auto_brace_completion_highlight_matching = true

[node name="RunButton" type="Button" parent="VBoxContainer/Body/VBox"]
custom_minimum_size = Vector2(160, 50)
layout_mode = 2
size_flags_horizontal = 4
theme_override_styles/normal = SubResource("StyleBoxTexture_btn")
theme_override_styles/hover = SubResource("StyleBoxTexture_btn")
theme_override_styles/pressed = SubResource("StyleBoxTexture_btn_p")
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 18
text = "Cast Spell"
"""

with open("ide_ui.tscn", "w", encoding="utf-8") as f:
    f.write(tscn_content)

gd_content = """class_name IDEController
extends PanelContainer

@onready var title_bar: PanelContainer = $VBoxContainer/TitleBar
@onready var minimize_btn: Button = $VBoxContainer/TitleBar/HBox/MinimizeBtn
@onready var body_container: MarginContainer = $VBoxContainer/Body
@onready var run_button: Button = $VBoxContainer/Body/VBox/RunButton
@onready var code_edit: CodeEdit = $VBoxContainer/Body/VBox/CodeEdit

var dragging: bool = false
var drag_offset: Vector2 = Vector2()
var is_minimized: bool = false
var current_interpreter: Interpreter

func _ready() -> void:
	_setup_syntax_highlighting()
	
	if run_button:
		run_button.pressed.connect(_on_run_button_pressed)
	if minimize_btn:
		minimize_btn.pressed.connect(_on_minimize_pressed)
	if title_bar:
		title_bar.gui_input.connect(_on_title_bar_gui_input)

func _setup_syntax_highlighting() -> void:
	if not code_edit: return
	
	var highlighter = CodeHighlighter.new()
	
	# Numbers
	highlighter.number_color = Color("#8a4b22") # Dark orange/brown
	
	# Keywords
	var dark_red = Color("#7a1a1a")
	var keywords = ["if", "elif", "else", "while", "for", "func", "def", "break", "continue", "true", "false", "and", "or", "not"]
	for kw in keywords: highlighter.add_keyword_color(kw, dark_red)
		
	# Functions
	var dark_blue = Color("#1c3b6b")
	var api_funcs = [
		"move_up", "move_down", "move_left", "move_right", "move_forward", "attack",
		"turn_left", "turn_right", "turn_around", "unlock_gate",
		"check_forward", "check_left", "check_right", "check_backward",
		"get_health", "get_gold", "get_x", "get_y", "wait", "print",
		"distance_to_goal", "is_enemy_near"
	]
	for api_func in api_funcs: highlighter.add_keyword_color(api_func, dark_blue)
		
	# Known Variables
	var dark_green = Color("#225c27")
	highlighter.add_keyword_color("gold", dark_green)
	highlighter.add_keyword_color("step", dark_green)
		
	code_edit.syntax_highlighter = highlighter

func _on_run_button_pressed() -> void:
	if not code_edit: return
	
	var code_text = code_edit.text
	if code_text.is_empty():
		print_error(1, "No code to execute!")
		return
		
	var warrior = get_tree().get_first_node_in_group("warrior")
	if not warrior:
		print_error(0, "CRITICAL: Could not find warrior.")
		return
		
	if current_interpreter:
		current_interpreter.stop_execution()
		current_interpreter.queue_free()
		
	current_interpreter = Interpreter.new()
	add_child(current_interpreter)
	
	current_interpreter.error_occurred.connect(_on_interpreter_error)
	current_interpreter.finished_execution.connect(_on_interpreter_finished)
	current_interpreter.print_requested.connect(_on_interpreter_print)
	
	current_interpreter.execute_code(code_text, warrior)

func _on_interpreter_error(line: int, msg: String):
	print_error(line, msg)

func _on_interpreter_print(msg: String):
	pass

func _on_interpreter_finished():
	pass

func print_error(line_number: int, message: String) -> void:
	print("ERROR (Line " + str(line_number) + "): " + message)

func _on_title_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			drag_offset = get_global_mouse_position() - global_position
		else:
			dragging = false
	elif event is InputEventMouseMotion and dragging:
		var new_pos = get_global_mouse_position() - drag_offset
		# Optional: Clamp to screen
		var screen_size = get_viewport_rect().size
		new_pos.x = clamp(new_pos.x, 0, screen_size.x - size.x)
		new_pos.y = clamp(new_pos.y, 0, screen_size.y - size.y)
		global_position = new_pos

func _on_minimize_pressed() -> void:
	is_minimized = not is_minimized
	if body_container:
		body_container.visible = not is_minimized
	if minimize_btn:
		minimize_btn.text = "+" if is_minimized else "-"
"""

with open("ide_controller.gd", "w", encoding="utf-8") as f:
    f.write(gd_content)

print("IDE rebuilt successfully.")
