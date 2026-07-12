extends CanvasLayer

enum GameState {
	CODING,
	COMPILING,
	RUNNING,
	PAUSED,
	OVERHEATED,
	VICTORY,
	DEFEAT,
	GAMEOVER
}

signal state_changed(old_state, new_state)
signal compilation_failed(err_msg: String, line: int)

var state = GameState.CODING
var active_interpreter: CustomInterpreter = null

var level_origin_state: Dictionary = {}

var lines_of_code: int = 0
var execution_cycles: int = 0
var max_allowed_cycles: int = 2500
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

signal placement_selected(pos: Vector2)
var is_placing: bool = false
var placing_type: String = ""
var ghost_sprite: Sprite2D = null

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
	transition_to(GameState.GAMEOVER)
	await get_tree().create_timer(2.0, true, false, true).timeout
	if state == GameState.GAMEOVER:
		_on_restart_pressed()

func _on_goal_reached() -> void:
	transition_to(GameState.VICTORY)
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.stop_swarm()
		
	var total_loc = 0
	var total_cycles = 0
	var par_loc = 10
	var par_cycles = 50
	var stars = 1
		
	if Global and LevelManager:
		if LevelManager.current_level_index >= Global.max_unlocked_level:
			Global.max_unlocked_level = LevelManager.current_level_index + 1
			
		# Calculate stats
		for script in Global.script_inventory.values():
			if typeof(script) == TYPE_STRING:
				total_loc += script.split("\n").size()
		
		if swarm:
			for interp in swarm.active_interpreters:
				total_cycles += interp.current_cycles
				
		var lvl_data = Global.levels[LevelManager.current_level_index - 1]
		if lvl_data.has("par_loc"): par_loc = lvl_data["par_loc"]
		if lvl_data.has("par_cycles"): par_cycles = lvl_data["par_cycles"]
		
		if total_loc <= par_loc: stars += 1
		if total_cycles <= par_cycles: stars += 1

		var level_str = str(LevelManager.current_level_index)
		if not Global.level_stars.has(level_str) or Global.level_stars[level_str] < stars:
			Global.level_stars[level_str] = stars
			
		Global.save_game()
		
	var warrior = get_tree().get_first_node_in_group("warrior")
	if warrior:
		if warrior.get("anim"):
			warrior.anim.play("idle")
		if warrior.get("stats") and warrior.stats.has_method("save"):
			warrior.stats.save()
		if warrior.get("inventory") and warrior.inventory.has_method("save"):
			warrior.inventory.save()
	await get_tree().create_timer(2.0, true, false, true).timeout
	var level_complete_ui = load("res://scenes/ui/level_complete.tscn").instantiate()
	level_complete_ui.setup(total_loc, par_loc, total_cycles, par_cycles, stars)
	add_child(level_complete_ui)

func request_placement(structure_type: String) -> Vector2:
	if is_placing: return Vector2.ZERO
	is_placing = true
	placing_type = structure_type
	
	ghost_sprite = Sprite2D.new()
	var tex_path = "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png"
	if structure_type == "wall":
		tex_path = "res://assets/Tiny Swords (Free Pack)/Decors/17.png"
	elif structure_type == "tower":
		tex_path = "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png"
	elif structure_type == "sawmill":
		tex_path = "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png"
	elif structure_type == "storage":
		tex_path = "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House3.png"
	elif structure_type == "barracks":
		tex_path = "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png"
		
	if ResourceLoader.exists(tex_path):
		ghost_sprite.texture = load(tex_path)
	ghost_sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)
	add_child(ghost_sprite)
	
	var pos = await self.placement_selected
	
	if is_instance_valid(ghost_sprite):
		ghost_sprite.queue_free()
	is_placing = false
	return pos



func _unhandled_input(event: InputEvent) -> void:
	if is_placing:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var mouse_pos = get_viewport().get_mouse_position()
				var camera = get_viewport().get_camera_2d()
				var world_mouse = mouse_pos
				if camera:
					world_mouse = camera.get_screen_center_position() + (mouse_pos - get_viewport().size / 2.0)
				var snapped_pos = (world_mouse / 64).round() * 64
				placement_selected.emit(snapped_pos)
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				placement_selected.emit(Vector2.ZERO)
				get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			placement_selected.emit(Vector2.ZERO)
			get_viewport().set_input_as_handled()

func _on_restart_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if end_game_ui: end_game_ui.hide()
	transition_to(GameState.CODING)
	restore_level_state()
	# LevelManager.restart_level()

func _on_next_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	if end_game_ui: end_game_ui.hide()
	transition_to(GameState.CODING)
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

func update_objective_ui(text: String) -> void:
	if objective_label:
		objective_label.text = text
	if objective_panel:
		objective_panel.position.y = -400
		var tween = create_tween()
		tween.tween_property(objective_panel, "position:y", 60.0, 0.8).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_interval(4.0)
		tween.tween_property(objective_panel, "position:y", -400.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)


func _process(_delta: float) -> void:
	if is_placing and is_instance_valid(ghost_sprite):
		var mouse_pos = get_viewport().get_mouse_position()
		var camera = get_viewport().get_camera_2d()
		var world_mouse = mouse_pos
		if camera:
			world_mouse = camera.get_screen_center_position() + (mouse_pos - get_viewport().size / 2.0)
		var snapped_pos = (world_mouse / 64).round() * 64
		ghost_sprite.global_position = snapped_pos

	if get_tree().current_scene and (get_tree().current_scene.name in ["MainMenu", "EndScreen", "Overworld", "OverworldMap", "Shop", "LevelSelect"]):
		if hud_root: hud_root.hide()
		if objective_panel: objective_panel.hide()
		if pause_menu: pause_menu.hide()
		return
	else:
		if hud_root: hud_root.show()
		if objective_panel and objective_panel.position.y > -150: objective_panel.show()
		
	if state == GameState.CODING or state == GameState.RUNNING:
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

func transition_to(new_state):
	if state == new_state: return
	
	var old_state = state
	state = new_state
	
	match state:
		GameState.CODING:
			Engine.time_scale = 0.0
			_set_ide_visibility(true)
			if active_interpreter: active_interpreter.force_stop()
			
		GameState.RUNNING:
			Engine.time_scale = 1.0
			_set_ide_visibility(false)
			execution_cycles = 0
			
		GameState.PAUSED:
			Engine.time_scale = 0.0
			
		GameState.OVERHEATED:
			Engine.time_scale = 0.0
			_display_defeat_modal("CPU Overheat! Optimization threshold exceeded.")
			
		GameState.VICTORY:
			Engine.time_scale = 0.0
			_display_victory_modal()
			
		GameState.DEFEAT, GameState.GAMEOVER:
			var swarm = get_node_or_null("/root/SwarmManager")
			if swarm: swarm.stop_swarm()
			_display_defeat_modal("Your unit took critical damage on the field.")

	emit_signal("state_changed", old_state, state)

func compile_and_run(code: String, target_unit: Node):
	if code.contains("OS.execute") or code.contains("get_tree().quit"):
		emit_signal("compilation_failed", "Security Violation: Unauthorized execution denied.", 1)
		return

	transition_to(GameState.COMPILING)
	
	_snapshot_entire_active_level()
	
	var raw_lines = code.split("\n")
	var loc_count = 0
	for l in raw_lines:
		var txt = l.strip_edges()
		if txt != "" and not txt.begins_with("#") and not txt.begins_with("//"):
			loc_count += 1
	lines_of_code = loc_count
	
	var active_lang = GlobalSettings.active_language if GlobalSettings else 0
	var lexer = CustomLexer.new()
	var parser = CustomParser.new()
	
	var tokens = lexer.tokenize(code, active_lang)
	var ast = parser.parse(tokens, active_lang)
	
	if lexer.tokens and lexer.tokens.size() > 0 and ast.get("body").size() == 0:
		emit_signal("compilation_failed", "Syntax processing returned empty structures. Double check formatting rules.", 1)
		transition_to(GameState.CODING)
		return
		
	transition_to(GameState.RUNNING)
	active_interpreter = CustomInterpreter.new()
	add_child(active_interpreter)
	
	active_interpreter.execution_cycle_completed.connect(_on_cycle_processed)
	active_interpreter.runtime_error.connect(_on_runtime_error)
	
	await active_interpreter.execute(ast, target_unit)
	
	if state == GameState.RUNNING:
		transition_to(GameState.CODING)

func _on_cycle_processed(_node_info: Dictionary):
	execution_cycles += 1
	if SignalBus:
		SignalBus.emit_signal("overheat_gauge_updated", float(execution_cycles) / max_allowed_cycles)
	
	if execution_cycles >= max_allowed_cycles:
		transition_to(GameState.OVERHEATED)

func _on_runtime_error(msg: String, line: int):
	var detailed_msg = "[Runtime Error] Line " + str(line) + ": " + msg
	emit_signal("compilation_failed", detailed_msg, line)
	transition_to(GameState.CODING)

func _set_ide_visibility(is_visible: bool):
	var root = get_tree().current_scene
	if root and root.has_node("WorkspaceUI/IDE_UI"):
		root.get_node("WorkspaceUI/IDE_UI").visible = is_visible

func _display_defeat_modal(message: String):
	if SignalBus and SignalBus.has_signal("level_ended"):
		SignalBus.emit_signal("level_ended", false, message)

func _display_victory_modal():
	if SignalBus and SignalBus.has_signal("level_ended"):
		SignalBus.emit_signal("level_ended", true, "Level Complete!")
	if SignalBus and SignalBus.has_signal("show_metrics"):
		SignalBus.emit_signal("show_metrics", lines_of_code, execution_cycles)

func _snapshot_entire_active_level() -> void:
	level_origin_state.clear()
	# programmable is not a group, let's use all possible units
	for entity in get_tree().get_nodes_in_group("obstacles") + get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("pawns") + get_tree().get_nodes_in_group("warrior") + get_tree().get_nodes_in_group("archer"):
		if entity.has_method("get_save_state"):
			level_origin_state[entity.get_path()] = entity.get_save_state()

func restore_level_state() -> void:
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.stop_swarm()
		
	for node_path in level_origin_state:
		var node = get_node_or_null(node_path)
		if node and node.has_method("rollback_to_start"):
			node.rollback_to_start()
