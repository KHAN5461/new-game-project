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

	
var speed_slider: HSlider
var state_inspector: RichTextLabel

signal toggled_state(is_open: bool)

func _ready() -> void:
	_setup_debugger_ui()
	print("--- IDE_CONTROLLER _READY ---")
	print("code_edit is ", code_edit)
	_populate_api_docs()
	_populate_shop()
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
		if swarm.has_signal("swarm_error"):
			swarm.swarm_error.connect(_on_swarm_error)
	
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
		code_edit.caret_changed.connect(_update_cursor_status)
		code_edit.code_completion_requested.connect(_on_code_completion_requested)
		code_edit.set_script(load("res://scripts/core/code_edit_drop.gd"))
		
	# Make IDE slightly transparent to see the game world beneath
	modulate = Color(1.0, 1.0, 1.0, 0.85)


func _update_cursor_status() -> void:
	var cursor_label = get_node_or_null("%CursorPosLabel")
	if cursor_label and code_edit:
		var line = code_edit.get_caret_line() + 1
		var col = code_edit.get_caret_column() + 1
		cursor_label.text = "Ln " + str(line) + ", Col " + str(col)
		
	var lang_label = get_node_or_null("%LanguageLabel")
	if lang_label and Global:
		lang_label.text = "Python" if Global.language_mode == 0 else "C++"

func _on_code_changed() -> void:
	code_edit.request_code_completion(true)
	if Global and "last_code" in Global:
		Global.last_code = code_edit.text
		Global.script_inventory[selected_unit_group] = code_edit.text
		Global.save_game()
	if AudioManager:
		AudioManager.play_type()

func _setup_debugger_ui() -> void:
	var header_bar = find_child("HeaderHBox", true, false)
	if header_bar:
		var speed_lbl = Label.new()
		speed_lbl.text = " Speed: 1x "
		header_bar.add_child(speed_lbl)
		
		speed_slider = HSlider.new()
		speed_slider.min_value = 0.5
		speed_slider.max_value = 4.0
		speed_slider.step = 0.5
		speed_slider.value = 1.0
		speed_slider.custom_minimum_size = Vector2(100, 20)
		
		speed_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		speed_slider.value_changed.connect(func(v):
			Engine.time_scale = v
			speed_lbl.text = " Speed: " + str(v) + "x "
		)
		header_bar.add_child(speed_slider)

		var pause_btn = Button.new()
		pause_btn.text = "⏸ Pause"
		pause_btn.pressed.connect(func(): 
			Global.is_debugging_paused = true
			get_tree().paused = true
		)
		header_bar.add_child(pause_btn)
		
		var play_btn = Button.new()
		play_btn.text = "▶ Play"
		play_btn.pressed.connect(func():
			Global.is_debugging_paused = false
			get_tree().paused = false
		)
		header_bar.add_child(play_btn)
		
		var step_btn = Button.new()
		step_btn.text = "⏭ Step"
		step_btn.pressed.connect(func():
			if Global.is_debugging_paused:
				SignalBus.debugger_step_requested.emit()
		)
		header_bar.add_child(step_btn)


	var tabs_area = find_child("TabsArea", true, false)
	if tabs_area and tabs_area.get_parent():
		state_inspector = RichTextLabel.new()
		state_inspector.bbcode_enabled = true
		state_inspector.text = "[color=gray]No unit active[/color]"
		state_inspector.custom_minimum_size = Vector2(0, 120)
		tabs_area.get_parent().add_child(state_inspector)

func _process(_delta: float) -> void:
	_update_state_inspector()
	if Global and code_edit:
		code_edit.code_completion_enabled = Global.autocomplete_enabled

func _update_state_inspector() -> void:
	if not state_inspector or selected_unit_group == "": return
	
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		var interps = swarm.get_interpreters_for_group(selected_unit_group)
		if interps.size() > 0:
			var interp = interps[0]
			if interp and interp.context_unit:
				var unit = interp.context_unit
				var hp = unit.health if "health" in unit else 0
				var meat = Global.meat
				var wood = Global.wood
				var gold = Global.gold
				
				var env_str = ""
				if not has_meta("prev_env"): set_meta("prev_env", {})
				var prev_env = get_meta("prev_env")
				for k in interp.environment.keys():
					var v = interp.environment[k]
					if prev_env.has(k) and prev_env[k] != v:
						env_str += "[color=green]" + str(k) + ": " + str(v) + "[/color]\n"
					else:
						env_str += str(k) + ": " + str(v) + "\n"
				if env_str == "": env_str = "None"
				set_meta("prev_env", interp.environment.duplicate())
				
				state_inspector.text = "[color=yellow]--- State Inspector ---[/color]\n" + \
					"HP: " + str(hp) + " | Meat: " + str(meat) + " | Wood: " + str(wood) + "\n" + \
					"[color=cyan]--- Variables ---[/color]\n" + env_str

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
	
	highlighter.number_color = Color("#B5CEA8")
	
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
	
	code_edit.minimap_draw = true
	code_edit.minimap_width = 80
	code_edit.draw_control_chars = true
	code_edit.draw_tabs = true
	code_edit.gutters_draw_line_numbers = true
	code_edit.gutters_draw_fold_gutter = true
	code_edit.auto_brace_completion_highlight_matching = true
	
	code_edit.add_theme_color_override("completion_background_color", Color(0.1, 0.1, 0.15, 0.95))
	code_edit.add_theme_color_override("completion_selected_color", Color(0.3, 0.25, 0.6))
	code_edit.add_theme_color_override("completion_existing_color", Color(0.5, 0.5, 0.7))
	code_edit.add_theme_color_override("completion_font_color", Color(0.9, 0.9, 1.0))
	code_edit.add_theme_constant_override("completion_lines", 7)
	code_edit.add_theme_constant_override("completion_max_width", 350)
	
	# Removed nested IDE texture override to let MainPanel texture show through
	
	# Fix font size
	code_edit.add_theme_font_size_override("font_size", 20)
	
	var keyword_color = Color("#569CD6")
	var keywords = ["if", "else", "elif", "while", "for", "break", "true", "false", "var", "not", "and", "or", "True", "False", "def"]
	for kw in keywords: 
		highlighter.add_keyword_color(kw, keyword_color)
		
	var func_color = Color("#DCDCAA")
	var api_funcs = [
		"move_up", "move_down", "move_left", "move_right", "move_forward", "attack",
		"ranged_attack", "turn_left", "turn_right", "turn_around", "wait", "print",
		"chop", "drop_off", "build", "repair", "mine", "radar", "scan", "send_message", "receive_message"
	]
	for api_func in api_funcs: 
		highlighter.add_keyword_color(api_func, func_color)
		
	var var_color = Color("#9CDCFE")
	var vars = ["is_enemy_near", "check_forward", "check_left", "check_right", "check_backward"]
	for v in vars:
		highlighter.add_keyword_color(v, var_color)
		
	var comment_color = Color("#6A9955")
	highlighter.add_color_region("//", "", comment_color, true)
	highlighter.add_color_region("/*", "*/", comment_color, true)
	highlighter.add_color_region("#", "", comment_color, true)
	var string_color = Color("#CE9178")
	highlighter.add_color_region("\"", "\"", string_color, false)
	highlighter.add_color_region("'", "'", string_color, false)
	
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
		popup.add_separator("Help")
		popup.add_item("Show Documentation", 200)
		
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
		200:
			var doc_window = Window.new()
			doc_window.title = "API Documentation"
			doc_window.size = Vector2(400, 500)
			
			var bg = ColorRect.new()
			bg.color = Color("#1e1e1e")
			bg.set_anchors_preset(Control.PRESET_FULL_RECT)
			doc_window.add_child(bg)
			
			var rtl = RichTextLabel.new()
			rtl.bbcode_enabled = true
			rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
			rtl.text = "[color=yellow]Movement:[/color]\nmove_forward()\nturn_left()\nturn_right()\nturn_around()\n\n[color=red]Combat:[/color]\nattack()\nranged_attack()\nshield_block()\n\n[color=green]Sensors:[/color]\nis_enemy_near() -> bool\ncheck_forward() -> bool\n\n[color=cyan]Utility (Pawn):[/color]\nchop()\nmine()\nbuild()\nrepair()\ndrop_off()"
			doc_window.add_child(rtl)
			
			add_child(doc_window)
			doc_window.popup_centered()
			doc_window.close_requested.connect(doc_window.queue_free)

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
		"shield_block()", "ranged_attack()", "turn_left()", "turn_right()", "turn_around()", "wait()",
		"chop()", "mine()", "build()", "repair()", "drop_off()"
	]
	for api_func in api_funcs: 
		code_edit.add_code_completion_option(CodeEdit.KIND_FUNCTION, api_func, api_func, Color(0.4, 0.6, 1.0))
		
	var bool_funcs = [
		"is_enemy_near()", "!is_enemy_near()",
		"get_health()", "scan_distance()", "radar()", "scan()",
		"check_forward()", "!check_forward()",
		"check_left()", "!check_left()",
		"check_right()", "!check_right()",
		"check_backward()", "!check_backward()",
		"is_carrying_wood()", "is_carrying_gold()", "is_carrying_meat()", "memory"
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
		
	var objective = get_tree().get_first_node_in_group("level_objective")
	if objective and objective.max_lines > 0:
		var line_count = 0 if code_text.strip_edges() == "" else code_text.strip_edges().split("\n").size()
		if line_count > objective.max_lines:
			print_error(0, "ERROR: Code exceeds maximum allowed lines (" + str(objective.max_lines) + ")!")
			return
			
	var active_unit = null
	var groups_to_check = ["warrior", "archer", "builder", "pawn", "pawns"]
	for g in groups_to_check:
		var u = get_tree().get_first_node_in_group(g)
		if u:
			active_unit = u
			break
			
	if not active_unit:
		print_error(0, "CRITICAL: Could not find any unit to control.")
		return
		
	if GameManager:
		GameManager.transition_to(2) # RUNNING
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
		var scripts = Global.script_inventory.duplicate()
		if LevelManager.current_level_index == 5:
			scripts["enemy"] = "while True:\n\tbuild('warrior')\n\tattack()"
		any_ran = swarm.run_swarm(scripts)
			
	if not any_ran:
		print_error(1, "No programmed units found.")
		_on_execution_finished()
	elif swarm:
		if swarm.has_signal("swarm_finished") and not swarm.swarm_finished.is_connected(_on_execution_finished):
			swarm.swarm_finished.connect(_on_execution_finished, CONNECT_ONE_SHOT)

func _on_step_button_pressed() -> void:
	if not code_edit: return
	var swarm = get_node_or_null("/root/SwarmManager")
	if not swarm: return
	
	if GameManager and GameManager.state == 2: # RUNNING
		print_error(1, "Stepping...")
		swarm.step_swarm()
	else:
		if console: console.text = "> Starting Swarm in Step Mode..."
		
		var code_text = code_edit.text
		if code_text.is_empty() and Global.script_inventory.values().all(func(x): return x.strip_edges() == ""):
			print_error(1, "No code to execute!")
			return
			
		var objective = get_tree().get_first_node_in_group("level_objective")
		if objective and objective.max_lines > 0:
			var line_count = 0 if code_text.strip_edges() == "" else code_text.strip_edges().split("\n").size()
			if line_count > objective.max_lines:
				print_error(0, "ERROR: Code exceeds maximum allowed lines (" + str(objective.max_lines) + ")!")
				return
				
		var active_unit = null
		var groups_to_check = ["warrior", "archer", "builder", "pawn", "pawns"]
		for g in groups_to_check:
			var u = get_tree().get_first_node_in_group(g)
			if u:
				active_unit = u
				break
		if not active_unit:
			print_error(0, "CRITICAL: Could not find any unit to control.")
			return
			
		if GameManager:
			GameManager.transition_to(2) # RUNNING
			Engine.time_scale = 1.0
			GameManager.lines_of_code = code_text.strip_edges().split("\n").size()
			GameManager.execution_cycles = 0
		
		if selected_unit_group != "":
			Global.script_inventory[selected_unit_group] = code_text
			
		print_error(2, "Running Swarm (Step Mode)...")
		
		var scripts = Global.script_inventory.duplicate()
		if LevelManager.current_level_index == 5:
			scripts["enemy"] = "while True:\n\tbuild('warrior')\n\tattack()"
		var any_ran = swarm.run_swarm(scripts, true)
		if not any_ran:
			print_error(1, "No programmed units found.")
			_on_execution_finished()
		else:
			if swarm.has_signal("swarm_finished") and not swarm.swarm_finished.is_connected(_on_execution_finished):
				swarm.swarm_finished.connect(_on_execution_finished, CONNECT_ONE_SHOT)
			
		# Automatically fire the first step so it enters the first line!
		await get_tree().process_frame
		swarm.step_swarm()

func _on_stop_button_pressed() -> void:
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.stop_swarm()
	
	if GameManager:
		GameManager.transition_to(0) # CODING
		Engine.time_scale = 1.0
		
	if code_edit:
		_clear_all_highlights()
		
	print_error(2, "Execution Stopped.")

func _on_execution_finished() -> void:
	if GameManager:
		GameManager.transition_to(0) # CODING
		Engine.time_scale = 1.0
		
	if code_edit:
		_clear_all_highlights()
		
	print_error(2, "Execution Finished Successfully.")

func _on_execution_error(msg: String, line: int = -1) -> void:
	if GameManager:
		GameManager.transition_to(0) # CODING
		Engine.time_scale = 1.0
	if code_edit and line > 0:
		var line_idx = line - 1
		if line_idx >= 0 and line_idx < code_edit.get_line_count():
			code_edit.set_line_background_color(line_idx, Color(0.8, 0.2, 0.2, 0.5))
	print_error(0, "ERROR: " + msg)

func _on_swarm_executing_line(group_name: String, line: int) -> void:
	if group_name == selected_unit_group:
		_on_executing_line(line)

func _on_executing_line(line: int) -> void:
	if not code_edit: return
	_clear_all_highlights()
	var line_idx = line - 1
	if line_idx >= 0 and line_idx < code_edit.get_line_count():
		code_edit.set_line_background_color(line_idx, Color(0.2, 0.6, 1.0, 0.4))
		last_highlighted_line = line_idx

func _clear_all_highlights() -> void:
	if not code_edit: return
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0, 0, 0, 0))
	last_highlighted_line = -1

func _on_swarm_error(group_name: String, line: int, msg: String) -> void:
	if group_name == selected_unit_group:
		print_error(0, "Error on line " + str(line) + ": " + msg)
		if line > 0 and code_edit:
			var line_idx = line - 1
			if line_idx >= 0 and line_idx < code_edit.get_line_count():
				code_edit.set_line_background_color(line_idx, Color(1, 0, 0, 0.4))
				last_highlighted_line = line_idx

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
			
	var groups = ["warrior", "archer", "builder", "pawn", "pawns"]
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

func highlight_error_line(line_num: int) -> void:
	if not code_edit: return
	# Zero indexed internally
	code_edit.set_line_background_color(line_num - 1, Color(0.8, 0.1, 0.1, 0.4))
	
func clear_error_highlights() -> void:
	if not code_edit: return
	for i in range(code_edit.get_line_count()):
		code_edit.set_line_background_color(i, Color(0,0,0,0))


func _populate_api_docs():
	var docs_vbox = get_node_or_null("%DocsVBox")
	if not docs_vbox: return
	
	# Clear existing docs except the header Label
	for child in docs_vbox.get_children():
		if child is Label and child.text == "Available Commands:":
			continue
		child.queue_free()
		
	var cmds = [
		{"name": "move_forward()", "desc": "Moves the unit 1 tile in the direction it faces.", "key": "move_forward"},
		{"name": "turn_left()", "desc": "Rotates the unit 90 degrees left.", "key": "turn_left"},
		{"name": "turn_right()", "desc": "Rotates the unit 90 degrees right.", "key": "turn_right"},
		{"name": "attack()", "desc": "Attacks an enemy directly in front.", "key": "attack"},
		{"name": "chop()", "desc": "Chops down a tree directly in front.", "key": "chop"},
		{"name": "check_forward()", "desc": "Returns what is in front ('tree', 'enemy', 'wall', 'empty').", "key": "check_forward"},
		{"name": "is_enemy_near()", "desc": "Returns True if an enemy is adjacent.", "key": "is_enemy_near"},
		{"name": "while", "desc": "Loops code as long as condition is true.", "key": "while"},
		{"name": "if", "desc": "Executes code if condition is true.", "key": "if"},
		{"name": "build()", "desc": "Builds a structure.", "key": "build"}
	]
	
	for cmd in cmds:
		if not cmd["key"] in Global.unlocked_keywords:
			continue

		var btn = Button.new()
		btn.text = cmd["name"]
		btn.tooltip_text = cmd["desc"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		btn.pressed.connect(_insert_command.bind(cmd["name"]))
		docs_vbox.add_child(btn)

func _insert_command(cmd: String):
	if code_edit:
		code_edit.insert_text_at_caret(cmd)


func _populate_shop():
	var shop_vbox = get_node_or_null("%ShopVBox")
	if not shop_vbox: return
	
	for child in shop_vbox.get_children():
		child.queue_free()
		
	if not Global: return
	
	var research_btn = Button.new()
	research_btn.text = "OPEN RESEARCH TREE"
	research_btn.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
	research_btn.pressed.connect(func():
		if code_edit:
			Global.save_level_code(Global.selected_level, code_edit.text)
		SceneTransition.change_scene("res://scenes/ui/tech_tree.tscn")
	)
	shop_vbox.add_child(research_btn)
	
	var space = Control.new()
	space.custom_minimum_size = Vector2(0, 10)
	shop_vbox.add_child(space)
	
	var label = Label.new()
	label.text = "Keyword Unlocks:"
	shop_vbox.add_child(label)
	
	var research_keys = ["while", "if", "var", "radar", "build", "def", "send_message", "receive_message"]
	for key in research_keys:
		var lbl = Label.new()
		var unlocked = key in Global.unlocked_keywords
		lbl.text = "  • " + key.to_upper() + ": " + ("Unlocked" if unlocked else "Locked")
		lbl.modulate = Color(0.6, 1.0, 0.6) if unlocked else Color(0.6, 0.6, 0.6)
		shop_vbox.add_child(lbl)

func _buy_upgrade(key: String):
	pass
