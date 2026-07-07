extends CanvasLayer

var state = "CODING"

var lines_of_code: int = 0
var execution_cycles: int = 0
var hud_container: VBoxContainer
var hud_health: Label
var hud_gold: Label
var hud_backpack: HBoxContainer
var pause_menu: CanvasLayer
var hud_root: CanvasLayer

var objective_panel: PanelContainer
var objective_label: Label

# New EndGameUI refs
var end_game_ui: CanvasLayer
var end_title: Label
var end_gold: Label
var end_loc: Label
var end_cycles: Label
var end_rating: Label
var skip_tally: bool = false

func _ready() -> void:
	layer = 100 # Put it on top of everything
	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when paused
	
	if SignalBus:
		SignalBus.warrior_died.connect(_on_warrior_died)
		SignalBus.goal_reached.connect(_on_goal_reached)
		
	if LevelManager:
		LevelManager.level_started.connect(_on_level_started)
	
	_setup_hud()
	_setup_objective_ui()

func set_game_viewport(_vp: Viewport) -> void:
	# Intentionally NOT setting custom_viewport so UI covers full screen
	pass

func _on_warrior_died() -> void:
	state = "GAMEOVER"
	await get_tree().create_timer(2.0, true, true).timeout
	if state == "GAMEOVER":
		_on_restart_pressed()

func _on_goal_reached() -> void:
	state = "VICTORY"
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.stop_swarm()
		
	var warrior = get_tree().get_first_node_in_group("warrior")
	if warrior:
		if warrior.get("anim"):
			warrior.anim.play("idle")
		if warrior.get("stats") and warrior.stats.has_method("save"):
			warrior.stats.save()
		if warrior.get("inventory") and warrior.inventory.has_method("save"):
			warrior.inventory.save()
	await get_tree().create_timer(2.0, true, true).timeout
	_on_next_pressed()

func _on_restart_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if end_game_ui: end_game_ui.hide()
	state = "CODING"
	LevelManager.restart_level()

func _on_next_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if end_game_ui: end_game_ui.hide()
	state = "CODING"
	if Global and Global.endless_mode:
		Global.endless_depth += 1
		LevelManager.restart_level()
	else:
		if LevelManager:
			LevelManager.current_level_index += 1
			if LevelManager.current_level_index > Global.levels.size():
				SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")
			else:
				LevelManager.restart_level()
		else:
			SceneTransition.change_scene("res://scenes/ui/main_menu.tscn")


func _setup_hud() -> void:
	var dialog_scene = load("res://scenes/ui/dialogue_ui.tscn")
	if dialog_scene:
		var dialog_inst = dialog_scene.instantiate()
		add_child(dialog_inst)
		
	var hud_scene = load("res://scenes/ui/stats/stats.tscn")
	if hud_scene:
		var control = hud_scene.instantiate()
		hud_root = CanvasLayer.new()
		hud_root.add_child(control)
		add_child(hud_root)
		
	var pm_scene = load("res://scenes/ui/pause_menu.tscn")
	if pm_scene:
		pause_menu = pm_scene.instantiate()
		add_child(pause_menu)

func _setup_objective_ui() -> void:
	objective_panel = PanelContainer.new()
	var style = StyleBoxTexture.new()
	style.texture = load("res://assets/Tiny Swords (Update 010)/UI/Banners/Banner_Vertical.png")
	style.texture_margin_left = 64
	style.texture_margin_right = 64
	style.texture_margin_top = 64
	style.texture_margin_bottom = 64
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.content_margin_left = 30
	style.content_margin_right = 30
	objective_panel.add_theme_stylebox_override("panel", style)
	
	objective_label = Label.new()
	objective_label.add_theme_font_size_override("font_size", 24)
	objective_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_panel.add_child(objective_label)
	
	objective_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	objective_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	objective_panel.position.y = -400 # Start hidden above screen
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.z_index = 50
	
	if hud_root:
		hud_root.add_child(objective_panel)

func _on_level_started(index: int) -> void:
	if index == 1:
		var d = get_tree().get_first_node_in_group("dialogue")
		if d: d.show_dialogue([{"speaker": "Knight", "text": "Welcome to the realm of code!"}, {"speaker": "Archer", "text": "We need your help. The Goblins are multiplying!"}, {"speaker": "Knight", "text": "Use your IDE below to control the warrior. Type [color=gold]move_right()[/color] and click [color=red]RUN![/color]"}])

	if index == 1:
		objective_label.text = "LEVEL 1\nReach the Goal!"
	elif index == 2:
		objective_label.text = "LEVEL 2\nDefeat the Goblins & Reach the Goal!"
	else:
		objective_label.text = "LEVEL " + str(index) + "\nSurvive and escape!"
		
	# Epic bounce in
	objective_panel.position.y = -400
	var tween = create_tween()
	tween.tween_property(objective_panel, "position:y", 60.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(4.0) # Wait 4 seconds
	tween.tween_property(objective_panel, "position:y", -400.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

func _process(_delta: float) -> void:
	if get_tree().current_scene and (get_tree().current_scene.name in ["MainMenu", "EndScreen", "Overworld", "OverworldMap", "Shop", "LevelSelect"]):
		if hud_root: hud_root.hide()
		if objective_panel: objective_panel.hide()
		return
	else:
		if hud_root: hud_root.show()
		if objective_panel and objective_panel.position.y > -150: objective_panel.show()
		
	if state == "CODING" or state == "RUNNING":
		var warrior = get_tree().get_first_node_in_group("warrior")
			
		if warrior and warrior.has_method("get_backpack") and hud_backpack != null:
			var pack = warrior.get_backpack()
			for child in hud_backpack.get_children():
				child.queue_free()
			for item in pack:
				var tex = TextureRect.new()
				tex.texture = load("res://assets/Tiny Swords (Update 010)/UI/Icons/Regular_01.png")
				tex.custom_minimum_size = Vector2(24, 24)
				tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				hud_backpack.add_child(tex)
