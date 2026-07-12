class_name LevelObjective
extends Node

enum ObjectiveType {
	REACH_GOAL,
	COLLECT_WOOD,
	COLLECT_CASH,
	COLLECT_MEAT,
	KILL_ENEMIES
}

@export var objective_type: ObjectiveType = ObjectiveType.REACH_GOAL
@export var target_amount: int = 1
@export var objective_description: String = "Reach the Goal"
@export var max_lines: int = -1 # -1 means no limit
@export var gold_lines: int = -1 # 3 stars if <= gold_lines
@export var silver_lines: int = -1 # 2 stars if <= silver_lines


var current_amount: int = 0
var completed: bool = false
var initial_stats: Dictionary = {}

func _ready() -> void:
	max_lines = -1
	add_to_group("level_objective")
	
	if Stats:
		initial_stats = {
			"wood": Stats.wood_no,
			"cash": Stats.cash_no,
			"meat": Stats.meat_no,
		}
	
	if GameManager and GameManager.has_method("update_objective_ui"):
		GameManager.update_objective_ui(get_progress_string())
		
	# Wait for player to touch a goal if REACH_GOAL
	if objective_type == ObjectiveType.REACH_GOAL:
		if SignalBus.has_signal("goal_reached"):
			SignalBus.goal_reached.connect(_on_goal_reached)
		
	# If KILL_ENEMIES, connect to enemy_killed
	if objective_type == ObjectiveType.KILL_ENEMIES:
		if SignalBus.has_signal("enemy_killed"):
			SignalBus.enemy_killed.connect(_on_enemy_killed)

func _process(_delta: float) -> void:
	if completed: return
	if not Stats: return
	
	var changed = false
	if objective_type == ObjectiveType.COLLECT_WOOD:
		var collected = Stats.wood_no - initial_stats.get("wood", 0)
		if collected != current_amount:
			current_amount = collected
			changed = true
	elif objective_type == ObjectiveType.COLLECT_CASH:
		var collected = Stats.cash_no - initial_stats.get("cash", 0)
		if collected != current_amount:
			current_amount = collected
			changed = true
	elif objective_type == ObjectiveType.COLLECT_MEAT:
		var collected = Stats.meat_no - initial_stats.get("meat", 0)
		if collected != current_amount:
			current_amount = collected
			changed = true
			
	if changed:
		_check_goal()

func _on_enemy_killed() -> void:
	if completed: return
	if objective_type == ObjectiveType.KILL_ENEMIES:
		current_amount += 1
		_check_goal()

func _on_goal_reached() -> void:
	if completed: return
	if objective_type == ObjectiveType.REACH_GOAL:
		current_amount = 1
		_check_goal()

func get_progress_string() -> String:
	var s = ""
	if objective_type == ObjectiveType.REACH_GOAL:
		s = objective_description
	else:
		s = "%s: %d / %d" % [objective_description, current_amount, target_amount]
		
	if max_lines > 0:
		s += "\n(Max Lines: " + str(max_lines) + ")"
		
	return s

func _check_goal() -> void:
	if GameManager and GameManager.has_method("update_objective_ui"):
		GameManager.update_objective_ui(get_progress_string())
		
	if current_amount >= target_amount:
		completed = true
		if objective_type != ObjectiveType.REACH_GOAL:
			if SignalBus.has_signal("goal_reached"):
				SignalBus.goal_reached.emit()
