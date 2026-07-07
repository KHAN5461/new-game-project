class_name IDEController
extends Control

@onready var body_container: MarginContainer = find_child("Body", true, false)
@onready var run_button: Button = find_child("RunButton", true, false)
@onready var stop_button: Button = find_child("EmergencyHaltBtn", true, false)
@onready var cpu_heat_bar = find_child("CPUHeatBar", true, false)
@onready var unit_list: Control = find_child("TabsArea", true, false)
@onready var step_btn: Button = find_child("StepButton", true, false)
@onready var toggle_btn: Button = find_child("ToggleBtn", true, false)
@onready var code_edit: CodeEdit = find_child("CodeEdit", true, false)
@onready var console: RichTextLabel = find_child("Console", true, false)

var is_minimized: bool = false
var active_interpreters: Dictionary = {}
var selected_unit_group: String = ""
var last_highlighted_line: int = -1

var expanded_x: float = 0.0
var minimized_x: float = 0.0
var has_stored_x: bool = false

signal toggled_state(is_open: bool)

func _ready() -> void:
	print("--- IDE_CONTROLLER _READY ---")
	print("code_edit is ", code_edit)
	_setup_syntax_highlighting()
	_populate_unit_list()
	if LevelManager:
		LevelManager.level_started.connect(func(_idx): 
			_populate_unit_list()
			_on_stop_button_pressed()
		)
		
	if SignalBus:
		if not SignalBus.goal_reached.is_connected(_on_goal_reached_ide):
			SignalBus.goal_reached.connect(_on_goal_reached_ide)
			
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.executing_line.connect(_on_swarm_executing_line)
	
	if run_button:
		run_button.pressed.connect(_on_run_button_pressed)
	if step_btn:
		step_btn.pressed.connect(_on_step_button_pressed)
	if stop_button:
		stop_button.pressed.connect(_on_stop_button_pressed)
	if toggle_btn:
		toggle_btn.pressed.connect(_on_toggle_pressed)
		toggle_btn.text = "<"


	if code_edit:
		if Global and "last_code" in Global and Global.last_code != "":
			code_edit.text = Global.last_code
			
		code_edit.text_changed.connect(_on_code_changed)
		code_edit.code_completion_requested.connect(_on_code_completion_requested)
		code_edit.set_script(load("res://scripts/core/code_edit_drop.gd"))

func _on_code_changed() -> void:
	code_edit.request_code_completion(true)
	if Global and "last_code" in Global:
		Global.last_code = code_edit.text
		Global.script_inventory[selected_unit_group] = code_edit.text
		Global.save_game()
	if AudioManager:
		AudioManager.play_type()

func _process(_delta: float) -> void:
	pass
	
	
	if Global and code_edit:
		code_edit.code_completion_enabled = Global.autocomplete_enabled
		
func minimize_ide() -> void:
	if is_minimized: return
	is_minimized = true
	toggled_state.emit(false)
	if toggle_btn:
		toggle_btn.text = ">"
	var main_panel = find_child("MainPanel", true, false)
	if main_panel:
		main_panel.hide()
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

func maximize_ide() -> void:
	if not is_minimized: return
	is_minimized = false
	toggled_state.emit(true)
	if toggle_btn:
		toggle_btn.text = "<"
	var main_panel = find_child("MainPanel", true, false)
	if main_panel:
		main_panel.show()
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _setup_syntax_highlighting() -> void:
	if not code_edit: return
	
	var highlighter = CodeHighlighter.new()
	
	highlighter.number_color = Color("#8a4b22")
	
	code_edit.code_completion_enabled = true
	var prefixes = []
	for i in range(97, 123): prefixes.append(String.chr(i))
	for i in range(65, 91): prefixes.append(String.chr(i))
	prefixes.append("_")
	code_edit.code_completion_prefixes = prefixes
	
	code_edit.auto_brace_completion_enabled = true
	code_edit.highlight_all_occurrences = true
	code_edit.highlight_current_line = true
	code_edit.add_theme_color_override("current_line_color", Color(1.0, 1.0, 1.0, 0.1))
	
	code_edit.add_theme_color_override("completion_background_color", Color(0.1, 0.1, 0.15, 0.95))
	code_edit.add_theme_color_override("completion_selected_color", Color(0.3, 0.25, 0.6))
	code_edit.add_theme_color_override("completion_existing_color", Color(0.5, 0.5, 0.7))
	code_edit.add_theme_color_override("completion_font_color", Color(0.9, 0.9, 1.0))
	code_edit.add_theme_constant_override("completion_lines", 7)
	code_edit.add_theme_constant_override("completion_max_width", 350)
	
	# Removed nested IDE texture override to let MainPanel texture show through
	
	# Fix font size
	code_edit.add_theme_font_size_override("font_size", 20)
	
	var dark_red = Color("#7a1a1a")
	var keywords = ["if", "else", "while", "for", "break", "true", "false"]
	for kw in keywords: 
		highlighter.add_keyword_color(kw, dark_red)
		
	var dark_blue = Color("#1c3b6b")
	var api_funcs = [
		"move_up", "move_down", "move_left", "move_right", "move_forward", "attack",
		"ranged_attack", "turn_left", "turn_right", "turn_around", "wait", "print"
	]
	for api_func in api_funcs: 
		highlighter.add_keyword_color(api_func, dark_blue)
		
	var dark_green = Color("#225c27")
	var vars = ["is_enemy_near", "check_forward", "check_left", "check_right", "check_backward"]
	for v in vars:
		highlighter.add_keyword_color(v, dark_green)
		
	var comment_color = Color("#666666")
	highlighter.add_color_region("//", "", comment_color, true)
	highlighter.add_color_region("/*", "*/", comment_color, true)
	
	code_edit.syntax_highlighter = highlighter
	
	var popup = code_edit.get_menu()
	if popup:
		popup.add_theme_color_override("font_color", Color("#e6d5b8"))
		popup.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		popup.add_theme_color_override("font_separator_color", Color("#8a6b4e"))
		
		var panel_style = StyleBoxFlat.new()
		panel_style.bg_color = Color("#2b1e16")
		panel_style.border_width_left = 2
		panel_style.border_width_right = 2
		panel_style.border_width_top = 2
		panel_style.border_width_bottom = 2
		panel_style.border_color = Color("#4a3525")
		panel_style.corner_radius_top_left = 4
		panel_style.corner_radius_top_right = 4
		panel_style.corner_radius_bottom_left = 4
		panel_style.corner_radius_bottom_right = 4
		popup.add_theme_stylebox_override("panel", panel_style)
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color("#4a3525")
		hover_style.corner_radius_top_left = 2
		hover_style.corner_radius_top_right = 2
		hover_style.corner_radius_bottom_left = 2
		hover_style.corner_radius_bottom_right = 2
		popup.add_theme_stylebox_override("hover", hover_style)
		
		var sep_style = StyleBoxLine.new()
		sep_style.color = Color("#4a3525")
		sep_style.thickness = 2
		popup.add_theme_stylebox_override("separator", sep_style)
		
		popup.add_separator("Logic Snippets")
		popup.add_item("Insert if() {...}", 100)
		popup.add_item("Insert else {...}", 101)
		popup.add_item("Insert while() {...}", 102)
		popup.add_item("Insert for() {...}", 103)
		popup.add_item("Insert print()", 104)
		
		if not popup.id_pressed.is_connected(_on_context_menu_pressed):
			popup.id_pressed.connect(_on_context_menu_pressed)

func _on_context_menu_pressed(id: int) -> void:
	if not code_edit: return
	match id:
		100:
			code_edit.insert_text_at_caret("if (is_enemy_near()) {\n\t\n}\n")
		101:
			code_edit.insert_text_at_caret("else {\n\t\n}\n")
		102:
			code_edit.insert_text_at_caret("while (true) {\n\t\n}\n")
		103:
			code_edit.insert_text_at_caret("for (5) {\n\t\n}\n")
		104:
			code_edit.insert_text_at_caret("print(\"\")\n")

func _on_code_completion_requested() -> void:
	var lvl = 1
	if LevelManager:
		lvl = LevelManager.current_level_index
		
	var keywords = []
	if lvl >= 6: 
		keywords.append_array(["for (5) {\n\t\n}", "break"])
	if lvl >= 11:
		keywords.append_array(["while (true) {\n\t\n}"])
	if lvl >= 16: 
		keywords.append_array(["if (is_enemy_near()) {\n\t\n}", "else {\n\t\n}"])
		
	for kw in keywords: 
		var disp = kw.split("(")[0].strip_edges() if "(" in kw else kw
		code_edit.add_code_completion_option(CodeEdit.KIND_KEYWORD, disp, kw, Color(0.8, 0.4, 0.4))
		
	var api_funcs = [
		"move_forward()", "move_up()", "move_down()", "move_left()", "move_right()", "attack()",
		"shield_block()", "ranged_attack()", "turn_left()", "turn_right()", "turn_around()", "wait()"
	]
	for api_func in api_funcs: 
		code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, api_func, api_func, Color(0.4, 0.6, 1.0))
		
	var bool_funcs = [
		"is_enemy_near()", "!is_enemy_near()",
		"get_health()", "scan_distance()",
		"check_forward()", "!check_forward()",
		"check_left()", "!check_left()",
		"check_right()", "!check_right()",
		"check_backward()", "!check_backward()"
	]
	for b_func in bool_funcs:
		code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, b_func, b_func, Color(0.4, 0.8, 0.4))

		
	code_edit.update_code_completion_options(true)

func _on_run_button_pressed() -> void:
	if not code_edit: return
	if console: console.text = "> Executing Swarm..."
	
	var code_text = code_edit.text
	if code_text.is_empty() and Global.script_inventory.values().all(func(x): return x.strip_edges() == ""):
		print_error(1, "No code to execute!")
		return
		
	var warrior = get_tree().get_first_node_in_group("warrior")
	if not warrior:
		print_error(0, "CRITICAL: Could not find warrior.")
		return
		
	if GameManager:
		GameManager.state = "RUNNING"
		if Global and Global.fast_execution:
			Engine.time_scale = 2.0
		else:
			Engine.time_scale = 1.0
		GameManager.lines_of_code = code_text.strip_edges().split("\n").size()
		GameManager.execution_cycles = 0
	
	# Make sure the currently visible code is in the inventory before running
	if selected_unit_group != "":
		Global.script_inventory[selected_unit_group] = code_text
		
	print_error(2, "Running Swarm...")
	
	var any_ran = false
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		any_ran = swarm.run_swarm(Global.script_inventory)
			
	if not any_ran:
		print_error(1, "No programmed units found.")

func _on_step_button_pressed() -> void:
	if not code_edit: return
	var swarm = get_node_or_null("/root/SwarmManager")
	if not swarm: return
	
	if GameManager and GameManager.state == "RUNNING":
		print_error(1, "Stepping...")
		swarm.step_swarm()
	else:
		if console: console.text = "> Starting Swarm in Step Mode..."
		
		var code_text = code_edit.text
		if code_text.is_empty() and Global.script_inventory.values().all(func(x): return x.strip_edges() == ""):
			print_error(1, "No code to execute!")
			return
			
		var warrior = get_tree().get_first_node_in_group("warrior")
		if not warrior:
			print_error(0, "CRITICAL: Could not find warrior.")
			return
			
		if GameManager:
			GameManager.state = "RUNNING"
			Engine.time_scale = 1.0
			GameManager.lines_of_code = code_text.strip_edges().split("\n").size()
			GameManager.execution_cycles = 0
		
		if selected_unit_group != "":
			Global.script_inventory[selected_unit_group] = code_text
			
		print_error(2, "Running Swarm (Step Mode)...")
		
		var any_ran = swarm.run_swarm(Global.script_inventory, true)
		if not any_ran:
			print_error(1, "No programmed units found.")
			
		# Automatically fire the first step so it enters the first line!
		await get_tree().process_frame
		swarm.step_swarm()

func _on_stop_button_pressed() -> void:
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.stop_swarm()
	
	if GameManager:
		GameManager.state = "IDLE"
		Engine.time_scale = 1.0
		
	if code_edit:
		_clear_all_highlights()
		
	print_error(2, "Execution Stopped.")

func _on_execution_finished() -> void:
	if GameManager:
		GameManager.state = "IDLE"
		Engine.time_scale = 1.0
		
	if code_edit:
		_clear_all_highlights()
		
	print_error(2, "Execution Finished Successfully.")

func _on_execution_error(msg: String, line: int = -1) -> void:
	if GameManager:
		GameManager.state = "IDLE"
		Engine.time_scale = 1.0
	if code_edit and line > 0:
		code_edit.set_line_background_color(line - 1, Color(0.8, 0.2, 0.2, 0.5))
	print_error(0, "ERROR: " + msg)

func _on_swarm_executing_line(group_name: String, line: int) -> void:
	if group_name == selected_unit_group:
		_on_executing_line(line)

func _on_executing_line(line: int) -> void:
	if not code_edit: return
	_clear_all_highlights()
	code_edit.set_line_background_color(line - 1, Color(0.2, 0.6, 1.0, 0.4))
	last_highlighted_line = line - 1

func _clear_all_highlights() -> void:
	if not code_edit: return
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0, 0, 0, 0))
	last_highlighted_line = -1

func print_error(level: int, msg: String) -> void:
	if not console: return
	var color = "white"
	if level == 0: color = "red"
	elif level == 1: color = "yellow"
	elif level == 2: color = "green"
	console.text += "\n[color=" + color + "]" + msg + "[/color]"

func _on_toggle_pressed() -> void:
	if is_minimized:
		maximize_ide()
	else:
		minimize_ide()

func _populate_unit_list() -> void:
	if not unit_list: return
	for child in unit_list.get_children():
		child.queue_free()
			
	var groups = ["warrior", "archer", "builder"]
	var tab_index = 0
	for g in groups:
		if get_tree().has_group(g) and get_tree().get_nodes_in_group(g).size() > 0:
			var btn = Button.new()
			btn.name = "Tab_" + g
			btn.text = g.capitalize()
			
			
			
			btn.add_theme_font_size_override("font_size", 16)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			
			btn.custom_minimum_size = Vector2(100, 50)
			
			btn.pressed.connect(func(): _on_unit_selected(g))
			unit_list.add_child(btn)
			
			if selected_unit_group == "":
				_on_unit_selected(g)
			tab_index += 1

func _update_tabs_ui() -> void:
	if not unit_list: return
	for child in unit_list.get_children():
		if child is Button:
			var g = child.name.replace("Tab_", "")
			
			if g == selected_unit_group:
				child.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			else:
				child.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1))

func _on_unit_selected(group_name: String) -> void:
	print("--- _on_unit_selected called with: ", group_name, " ---")
	print("code_edit is ", code_edit)
	if selected_unit_group != "" and selected_unit_group != group_name:
		if code_edit:
			Global.script_inventory[selected_unit_group] = code_edit.text
		else:
			print("WARNING: code_edit is null!")
		
	selected_unit_group = group_name
	if Global.script_inventory.has(group_name):
		if code_edit: code_edit.text = Global.script_inventory[group_name]
	else:
		if Global.last_code != "":
			if code_edit: code_edit.text = Global.last_code
			Global.script_inventory[group_name] = Global.last_code
		else:
			if code_edit: code_edit.text = ""
			
	_update_tabs_ui()

func _on_goal_reached_ide() -> void:
	_clear_all_highlights()
	if console: console.text += "\n[color=yellow]> Level Complete. IDE Halted.[/color]"
