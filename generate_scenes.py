import uuid
import os

def gen_uid():
    return 'uid://' + uuid.uuid4().hex[:12]

player_tscn = f'''[gd_scene load_steps=5 format=3 uid="{gen_uid()}"]

[ext_resource type="Script" path="res://scenes/overworld/player_overworld.gd" id="1_script"]
[ext_resource type="Texture2D" uid="uid://djq1g2r52k47c" path="res://assets/Tiny Swords (Update 010)/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png" id="2_tex"]

[sub_resource type="AtlasTexture" id="AtlasTexture_1"]
atlas = ExtResource("2_tex")
region = Rect2(0, 0, 192, 192)

[sub_resource type="SpriteFrames" id="SpriteFrames_1"]
animations = [{{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_1")
}}],
"loop": true,
"name": &"idle",
"speed": 5.0
}}, {{
"frames": [{{
"duration": 1.0,
"texture": SubResource("AtlasTexture_1")
}}],
"loop": true,
"name": &"run",
"speed": 5.0
}}]

[node name="PlayerOverworld" type="CharacterBody2D"]
script = ExtResource("1_script")

[node name="AnimatedSprite2D" type="AnimatedSprite2D" parent="."]
position = Vector2(0, -16)
sprite_frames = SubResource("SpriteFrames_1")
animation = &"idle"
'''

level_node_tscn = f'''[gd_scene load_steps=3 format=3 uid="{gen_uid()}"]

[ext_resource type="Script" path="res://scenes/overworld/level_node.gd" id="1_script"]

[sub_resource type="CircleShape2D" id="CircleShape2D_1"]
radius = 8.0

[node name="LevelNode" type="Area2D"]
script = ExtResource("1_script")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_1")
'''

overworld_tscn = f'''[gd_scene load_steps=3 format=3 uid="{gen_uid()}"]

[ext_resource type="Script" path="res://scenes/overworld/overworld.gd" id="1_script"]
[ext_resource type="PackedScene" uid="uid://cxb3u5u32w0xj" path="res://scenes/overworld/player_overworld.tscn" id="2_player"]

[node name="Overworld" type="Node2D"]
script = ExtResource("1_script")

[node name="TileMap" type="TileMap" parent="."]
format = 2

[node name="Camera2D" type="Camera2D" parent="."]
position = Vector2(320, 180)

[node name="PlayerOverworld" parent="." instance=ExtResource("2_player")]
'''

# Hardcode the player UID so we can reference it in overworld_tscn
player_uid = gen_uid()
player_tscn = player_tscn.replace(player_tscn.split('uid="')[1].split('"]')[0], player_uid)
overworld_tscn = overworld_tscn.replace('uid://cxb3u5u32w0xj', player_uid)


with open('c:/Users/Admin/Documents/new-game-project/scenes/overworld/player_overworld.tscn', 'w') as f: f.write(player_tscn)
with open('c:/Users/Admin/Documents/new-game-project/scenes/overworld/level_node.tscn', 'w') as f: f.write(level_node_tscn)
with open('c:/Users/Admin/Documents/new-game-project/scenes/overworld/overworld.tscn', 'w') as f: f.write(overworld_tscn)
