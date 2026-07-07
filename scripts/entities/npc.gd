extends Area2D

@export var dialogue_lines: Array[String] = ["Hello there!", "Welcome to our village!"]
@export var talk_radius: float = 120.0
@export var required_quest_level: int = 0
@export var reward_gold: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog_box: NinePatchRect = $DialogBox
@onready var dialog_label: Label = $DialogBox/MarginContainer/Label
@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var dialog_timer: Timer = $DialogTimer

var current_line: int = 0
var has_rewarded: bool = false
var is_talking: bool = false

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("obstacles")
	dialog_box.hide()
	dialog_timer.timeout.connect(_on_dialog_timeout)
	
	if sprite:
		sprite.texture = preload("res://assets/Tiny Swords (Update 010)/Factions/Knights/Troops/Pawn/Red/Pawn_Red.png")
		sprite.hframes = 6
		sprite.vframes = 6
		
	var anim_t = create_tween().set_loops()
	anim_t.tween_property(sprite, "frame", 5, 0.6).from(0)

func interact() -> void:
	if is_talking:
		_next_line()
	else:
		_start_talking()

func _start_talking() -> void:
	is_talking = true
	current_line = 0
	_show_line()

func _next_line() -> void:
	current_line += 1
	if current_line >= dialogue_lines.size():
		_finish_talking()
	else:
		_show_line()

func _show_line() -> void:
	if current_line < dialogue_lines.size():
		dialog_label.text = dialogue_lines[current_line]
		dialog_box.show()
		dialog_box.scale = Vector2.ZERO
		
		var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(dialog_box, "scale", Vector2.ONE, 0.3)
		
		if audio:
			audio.pitch_scale = randf_range(0.9, 1.1)
			audio.play()
			
		dialog_timer.start(3.0)

func _finish_talking() -> void:
	is_talking = false
	var t = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(dialog_box, "scale", Vector2.ZERO, 0.2)
	await t.finished
	dialog_box.hide()
	
	if reward_gold > 0 and not has_rewarded:
		if Global and Global.max_unlocked_level >= required_quest_level:
			Global.total_gold += reward_gold
			Global.save_game()
			has_rewarded = true
			
			dialog_label.text = "You received " + str(reward_gold) + " Gold!"
			dialog_box.show()
			dialog_box.scale = Vector2.ONE
			dialog_timer.start(2.0)
			
			var coin_sound = AudioStreamPlayer2D.new()
			coin_sound.stream = preload("res://assets/audio/coin.wav")
			add_child(coin_sound)
			coin_sound.play()
			coin_sound.finished.connect(coin_sound.queue_free)

func _on_dialog_timeout() -> void:
	if is_talking:
		_next_line()
	else:
		_finish_talking()
