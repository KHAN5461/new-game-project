extends Button

var currentBattleSpeed = 1

func _ready() -> void:
	pressed.connect(_change_battle_speed)

func _change_battle_speed():
	match currentBattleSpeed:
		1: currentBattleSpeed = 2
		2: currentBattleSpeed = 3
		3: currentBattleSpeed = 1
	
	Engine.time_scale = currentBattleSpeed
	
	_change_text()
	
func _change_text():
	text = "x" + str(currentBattleSpeed) + " Speed"

func _exit_tree() -> void:
	Engine.time_scale = 1
