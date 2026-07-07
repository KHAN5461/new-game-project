extends Control

@onready var health_btn = $PanelContainer/VBoxContainer/HealthBtn
@onready var attack_btn = $PanelContainer/VBoxContainer/AttackBtn
@onready var key_btn = $PanelContainer/VBoxContainer/KeyBtn
@onready var back_btn = $PanelContainer/VBoxContainer/BackBtn
@onready var gold_label = $GoldLabel
@onready var npc: Sprite2D = get_node_or_null("MerchantNPC")

var anim_timer: float = 0.0
var frame_duration: float = 0.1
var current_frame: int = 0

func _process(delta: float) -> void:
	if npc:
		anim_timer += delta
		if anim_timer >= frame_duration:
			anim_timer -= frame_duration
			current_frame = (current_frame + 1) % 6
			npc.frame = current_frame

func _ready() -> void:
	health_btn.pressed.connect(_on_health_pressed)
	attack_btn.pressed.connect(_on_attack_pressed)
	key_btn.pressed.connect(_on_key_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	_update_ui()

func _update_ui() -> void:
	gold_label.text = "Gold: " + str(Global.total_gold)
	
	health_btn.text = "Buy Max Health (+10) - 50 Gold\nCurrent Max: " + str(Global.max_health)
	if Global.total_gold < 50:
		health_btn.disabled = true
	else:
		health_btn.disabled = false
		
	attack_btn.text = "Buy Attack Damage (+1) - 100 Gold\nCurrent Damage: " + str(Global.attack_damage)
	if Global.total_gold < 100:
		attack_btn.disabled = true
	else:
		attack_btn.disabled = false
	key_btn.text = "Buy Master Key - 150 Gold"
	if Global.total_gold < 150 or ("master_key" in Global.unlocked_items):
		key_btn.disabled = true
		if "master_key" in Global.unlocked_items:
			key_btn.text = "Master Key (OWNED)"
	else:
		key_btn.disabled = false

func _on_health_pressed() -> void:
	if Global.total_gold >= 50:
		Global.total_gold -= 50
		Global.max_health += 10
		Global.save_game()
		_update_ui()

func _on_attack_pressed() -> void:
	if Global.total_gold >= 100:
		Global.total_gold -= 100
		Global.attack_damage += 1
		Global.save_game()
		_update_ui()


func _on_key_pressed() -> void:
	if Global.total_gold >= 150 and not ("master_key" in Global.unlocked_items):
		Global.total_gold -= 150
		Global.unlocked_items.append("master_key")
		Global.save_game()
		_update_ui()

func _on_back_pressed() -> void:
	SceneTransition.change_scene("res://scenes/ui/level_select.tscn")
