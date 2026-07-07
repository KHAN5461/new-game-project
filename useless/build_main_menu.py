import os

tscn_content = """[gd_scene load_steps=6 format=3 uid="uid://mainmenu123"]

[ext_resource type="Script" path="res://main_menu.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Banners/Banner_Horizontal.png" id="2_banner"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides.png" id="3_btn"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Blue_3Slides_Pressed.png" id="4_btn_p"]
[ext_resource type="Texture2D" path="res://assets/Tiny Swords (Update 010)/UI/Buttons/Button_Red_3Slides.png" id="5_btn_red"]

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

[sub_resource type="StyleBoxTexture" id="StyleBoxTexture_quit"]
texture = ExtResource("5_btn_red")
texture_margin_left = 32.0
texture_margin_top = 16.0
texture_margin_right = 32.0
texture_margin_bottom = 32.0

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_script")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.35, 0.55, 0.45, 1)

[node name="TitleBanner" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 5
anchor_left = 0.5
anchor_right = 0.5
offset_left = -280.0
offset_top = 80.0
offset_right = 280.0
offset_bottom = 240.0
grow_horizontal = 2
texture = ExtResource("2_banner")
expand_mode = 1

[node name="TitleText" type="Label" parent="TitleBanner"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -200.0
offset_top = -40.0
offset_right = 200.0
offset_bottom = 20.0
grow_horizontal = 2
grow_vertical = 2
theme_override_colors/font_color = Color(0.2, 0.1, 0.05, 1)
theme_override_font_sizes/font_size = 48
text = "TINY SWORDS"
horizontal_alignment = 1
vertical_alignment = 1

[node name="VBoxContainer" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -100.0
offset_top = 30.0
offset_right = 100.0
offset_bottom = 190.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 15

[node name="PlayBtn" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
theme_override_styles/normal = SubResource("StyleBoxTexture_btn")
theme_override_styles/hover = SubResource("StyleBoxTexture_btn")
theme_override_styles/pressed = SubResource("StyleBoxTexture_btn_p")
text = "PLAY"

[node name="QuitBtn" type="Button" parent="VBoxContainer"]
custom_minimum_size = Vector2(200, 60)
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 24
theme_override_styles/normal = SubResource("StyleBoxTexture_quit")
theme_override_styles/hover = SubResource("StyleBoxTexture_quit")
theme_override_styles/pressed = SubResource("StyleBoxTexture_quit")
text = "QUIT"
"""

with open("main_menu.tscn", "w", encoding="utf-8") as f:
    f.write(tscn_content)

gd_content = """extends Control

@onready var play_btn: Button = $VBoxContainer/PlayBtn
@onready var quit_btn: Button = $VBoxContainer/QuitBtn

func _ready() -> void:
	play_btn.pressed.connect(_on_play_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
"""

with open("main_menu.gd", "w", encoding="utf-8") as f:
    f.write(gd_content)

print("Main Menu rebuilt successfully.")
