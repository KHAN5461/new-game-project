import os

tscn_content = """[gd_scene load_steps=5 format=3 uid="uid://pausemenu123"]

[ext_resource type="Script" path="res://pause_menu.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Banners/Banner_Vertical.png" id="2_banner"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides.png" id="3_btn"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides_Pressed.png" id="4_btn_p"]

[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_btn"]
texture = ExtResource("3_btn")
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

[node name="PauseMenu" type="CanvasLayer"]
process_mode = 3
layer = 120
script = ExtResource("1_script")

[node name="ColorRect" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.5)

[node name="CenterContainer" type="CenterContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="TextureRect" type="TextureRect" parent="CenterContainer"]
custom_minimum_size = Vector2(300, 400)
layout_mode = 2
texture = ExtResource("2_banner")

[node name="VBoxContainer" type="VBoxContainer" parent="CenterContainer/TextureRect"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = -100.0
offset_right = 100.0
offset_bottom = 100.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 20

[node name="Label" type="Label" parent="CenterContainer/TextureRect/VBoxContainer"]
layout_mode = 2
theme_override_colors/font_color = Color(0.25, 0.15, 0.05, 1)
theme_override_font_sizes/font_size = 32
text = "PAUSED"
horizontal_alignment = 1

[node name="ResumeBtn" type="Button" parent="CenterContainer/TextureRect/VBoxContainer"]
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 20
theme_override_styles/normal = SubResource("StyleBoxTexture_btn")
theme_override_styles/hover = SubResource("StyleBoxTexture_btn")
theme_override_styles/pressed = SubResource("StyleBoxTexture_btn_p")
text = "RESUME"

[node name="RestartBtn" type="Button" parent="CenterContainer/TextureRect/VBoxContainer"]
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 20
theme_override_styles/normal = SubResource("StyleBoxTexture_btn")
theme_override_styles/hover = SubResource("StyleBoxTexture_btn")
theme_override_styles/pressed = SubResource("StyleBoxTexture_btn_p")
text = "RESTART"

[node name="QuitBtn" type="Button" parent="CenterContainer/TextureRect/VBoxContainer"]
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 20
theme_override_styles/normal = SubResource("StyleBoxTexture_btn")
theme_override_styles/hover = SubResource("StyleBoxTexture_btn")
theme_override_styles/pressed = SubResource("StyleBoxTexture_btn_p")
text = "MAIN MENU"
"""

with open("pause_menu.tscn", "w", encoding="utf-8") as f:
    f.write(tscn_content)

gd_content = """extends CanvasLayer

@onready var resume_btn: Button = $CenterContainer/TextureRect/VBoxContainer/ResumeBtn
@onready var restart_btn: Button = $CenterContainer/TextureRect/VBoxContainer/RestartBtn
@onready var quit_btn: Button = $CenterContainer/TextureRect/VBoxContainer/QuitBtn

func _ready() -> void:
	hide()
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	quit_btn.pressed.connect(_on_quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_on_resume()
		else:
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
	get_tree().change_scene_to_file("res://main_menu.tscn")
"""

with open("pause_menu.gd", "w", encoding="utf-8") as f:
    f.write(gd_content)

print("Pause Menu built successfully.")
