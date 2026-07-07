extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var wrapper = $DialogueWrapper
@onready var text_label = $DialogueWrapper/TextLabel
@onready var name_label = $DialogueWrapper/NameLabel
@onready var avatar_rect = $DialogueWrapper/Avatar
@onready var skip_button = $DialogueWrapper/SkipButton
@onready var type_timer = $TypeTimer

const CHARACTER_DB = {
	"Archer": {"tex": "res://assets/Tiny Swords (Free Pack)/Units/Blue Units/Archer/Archer_Idle.png", "rect": Rect2(32, 32, 128, 128), "flip": false},
	"Warrior": {"tex": "res://assets/Tiny Swords (Update 010)/Factions/Knights/Troops/Warrior/Blue/Warrior_Blue.png", "rect": Rect2(32, 32, 128, 128), "flip": false},
	"Goblin": {"tex": "res://assets/Tiny Swords (Update 010)/Factions/Goblins/Troops/Torch/Red/Torch_Red.png", "rect": Rect2(32, 32, 128, 128), "flip": false},
	"Knight": {"tex": "res://assets/Avatars/knight.png", "flip": false},
	"Pawn": {"tex": "res://assets/Avatars/pawn.png", "flip": false},
	"Wizard": {"tex": "res://assets/Avatars/wizard.png", "flip": false},
	"Woman": {"tex": "res://assets/Avatars/woman.png", "flip": false}
}

var current_queue = []
var is_active = false
var is_typing = false
var avatar_tween: Tween

func _ready() -> void:
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	hide()
	
	type_timer.timeout.connect(_on_type_timer_timeout)

func show_dialogue(messages: Array) -> void:
	current_queue = messages
	is_active = true
	show()
	
	color_rect.modulate.a = 0
	wrapper.position.y = 1000
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(color_rect, "modulate:a", 1.0, 0.4)
	t.tween_property(wrapper, "position:y", get_viewport().get_visible_rect().size.y - 300, 0.4)
	
	_next_message()

func hide_dialogue() -> void:
	is_active = false
	var t = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_property(color_rect, "modulate:a", 0.0, 0.3)
	t.tween_property(wrapper, "position:y", 1000, 0.3)
	t.chain().tween_callback(func():
		hide()
	)

func _next_message() -> void:
	if current_queue.size() > 0:
		var msg = current_queue.pop_front()
		
		var speaker = msg.get("speaker", "Unknown")
		var text = msg.get("text", "")
		
		name_label.text = speaker
		text_label.text = text
		text_label.visible_characters = 0
		
		if CHARACTER_DB.has(speaker):
			var db_info = CHARACTER_DB[speaker]
			var tex = load(db_info.tex)
			if db_info.has("rect"):
				var atlas = AtlasTexture.new()
				atlas.atlas = tex
				atlas.region = db_info.rect
				avatar_rect.texture = atlas
			else:
				avatar_rect.texture = tex
			avatar_rect.flip_h = db_info.get("flip", false)
		else:
			avatar_rect.texture = null
			
		
		is_typing = true
		type_timer.start()
		_start_avatar_bounce()
	else:
		hide_dialogue()

func _start_avatar_bounce() -> void:
	pass

func _stop_avatar_bounce() -> void:
	pass

func _on_type_timer_timeout() -> void:
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
	else:
		type_timer.stop()
		is_typing = false
		
		_stop_avatar_bounce()

func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_accept"):
		if is_typing:
			type_timer.stop()
			text_label.visible_characters = -1
			is_typing = false
			
			_stop_avatar_bounce()
		else:
			_next_message()
		get_viewport().set_input_as_handled()

func _on_skip_pressed() -> void:
	if not is_active: return
	current_queue.clear()
	if is_typing:
		type_timer.stop()
		is_typing = false
		_stop_avatar_bounce()
	hide_dialogue()
