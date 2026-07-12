extends StaticBody2D

var hp: int = 3
var is_dead: bool = false
@onready var sprite = $Sprite2D

func _ready() -> void:
	add_to_group("mine")
	add_to_group("gold")
	collision_layer = 4 # Environment
	collision_mask = 0

func take_damage(amount: int) -> void:
	if is_dead: return
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	if is_dead: return
	is_dead = true
	var destroyed_tex = load("res://assets/Tiny Swords (Update 010)/Resources/Gold Mine/GoldMine_Destroyed.png")
	if destroyed_tex:
		sprite.texture = destroyed_tex
	
	$CollisionShape2D.set_deferred("disabled", true)
	remove_from_group("mine")
	remove_from_group("gold")
	
	var coin_scene = load("res://scenes/entities/coin.tscn")
	if coin_scene:
		var coin = coin_scene.instantiate()
		coin.global_position = global_position
		get_parent().add_child(coin)
