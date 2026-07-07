extends Control

@onready var anim: AnimatedSprite2D = $Mask/items/anim
@onready var left_button: TextureButton = $"Mask/items/choose icon/LeftButton"
@onready var right_button: TextureButton = $"Mask/items/choose icon/rightButton"
@onready var click: AudioStreamPlayer = $"../../../sound fx/click audio"
@onready var swoosh: AudioStreamPlayer = $"../../../sound fx/swoosh audio"

var animations := ["black", "red", "blue", "yellow", "purple"]
var current_index := 0
var is_animating := false
const SLIDE_DISTANCE := 80
const TRANSITION_TIME := 0.25

func _ready() -> void:
	if anim:
		anim.play(animations[current_index])
	if left_button:
		left_button.pressed.connect(_on_left_button_pressed)
	if right_button:
		right_button.pressed.connect(_on_right_button_pressed)
	var choose_btn = $"Mask/items/choose icon/choose"
	if choose_btn:
		choose_btn.pressed.connect(_on_choose_pressed)

func _on_left_button_pressed() -> void:
	if is_animating: return
	change_player(-1)

func _on_right_button_pressed() -> void:
	if is_animating: return
	change_player(1)

func change_player(direction: int) -> void:
	is_animating = true
	if click and not click.playing: click.play()
	if swoosh and not swoosh.playing: swoosh.play()
	
	var old_pos := anim.position
	var exit_dir := -direction
	
	var tween := create_tween()
	tween.tween_property(
		anim, 
		"position", 
		old_pos + Vector2(exit_dir * SLIDE_DISTANCE, 0), 
		TRANSITION_TIME
	)
	tween.parallel().tween_property(anim, "modulate:a", 0.0, TRANSITION_TIME)
	await tween.finished
	
	current_index = (current_index + direction) % animations.size()
	if current_index < 0:
		current_index = animations.size() - 1
		
	anim.play(animations[current_index])
	anim.position = old_pos + Vector2(direction * SLIDE_DISTANCE, 0)
	anim.modulate.a = 0.0
	
	var tween_in := create_tween()
	tween_in.tween_property(anim, "position", old_pos, TRANSITION_TIME)
	tween_in.parallel().tween_property(anim, "modulate:a", 1.0, TRANSITION_TIME)
	await tween_in.finished
	is_animating = false

func _on_choose_pressed() -> void:
	Global.choosed_colour = animations[current_index]
	Global.save_colour()
	await get_tree().create_timer(0.2).timeout
