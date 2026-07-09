extends Node

var is_running: bool = false
var class_asts: Dictionary = {}
var active_interpreters: Array = []

signal global_step
signal executing_line(group_name: String, line_number: int)
signal swarm_finished

var completed_interpreters: int = 0

func step_swarm() -> void:
	global_step.emit()

func run_swarm(scripts: Dictionary, step_mode: bool = false) -> bool:
	stop_swarm()
	
	is_running = true
	var any_ran = false
	completed_interpreters = 0
	var active_lang = GlobalSettings.active_language if GlobalSettings else 0
	var parser = CustomParser.new()
	var lexer = CustomLexer.new()
	
	for group_name in scripts.keys():
		var code = scripts[group_name]
		var ast = null
		
		if code.strip_edges() == "":
			# Create a default "Idle" AST to prevent crashes
			var idle_code = ""
			if active_lang == 0:
				idle_code = "while True:\n    wait()"
			else:
				idle_code = "while (true) {\n\twait();\n}"
			var tokens = lexer.tokenize(idle_code, active_lang)
			ast = parser.parse(tokens, active_lang)
		else:
			var tokens = lexer.tokenize(code, active_lang)
			ast = parser.parse(tokens, active_lang)
			
		class_asts[group_name] = ast
		
		if ast != null:
			var units = get_tree().get_nodes_in_group(group_name)
			for unit in units:
				assign_interpreter(unit, group_name, step_mode)
				any_ran = true
				
	return any_ran

func assign_interpreter(unit: Node2D, group_name: String, step_mode: bool = false) -> CustomInterpreter:
	if not class_asts.has(group_name) or class_asts[group_name] == null:
		return null
		
	var interp = CustomInterpreter.new()
	add_child(interp)
	
	if interp.has_signal("runtime_error"):
		interp.runtime_error.connect(func(msg, line): _on_execution_error(line, msg))
	if interp.has_signal("execution_cycle_completed"):
		interp.execution_cycle_completed.connect(func(node): 
			if node.has("line"):
				executing_line.emit(group_name, node.line)
		)
	if interp.has_signal("finished_execution"):
		interp.finished_execution.connect(_on_interpreter_finished)
		
	# Execute asynchronously but don't await here to allow swarm concurrency
	interp.execute(class_asts[group_name], unit)
	active_interpreters.append(interp)
	return interp

func register_unit(unit: Node2D, group_name: String) -> void:
	if is_running and class_asts.has(group_name):
		assign_interpreter(unit, group_name)

func stop_swarm() -> void:
	is_running = false
	for interp in active_interpreters:
		if is_instance_valid(interp):
			interp.force_stop()
			interp.queue_free()
	active_interpreters.clear()
	class_asts.clear()

func get_interpreters_for_group(group_name: String) -> Array:
	var res = []
	for interp in active_interpreters:
		if is_instance_valid(interp) and interp.context_unit and interp.context_unit.is_in_group(group_name):
			res.append(interp)
	return res

func _on_execution_finished() -> void:
	pass

func _on_execution_error(line_number: int, message: String) -> void:
	print("Swarm Error on line ", line_number, ": ", message)

func _on_interpreter_finished() -> void:
	completed_interpreters += 1
	if completed_interpreters >= active_interpreters.size():
		emit_signal("swarm_finished")
