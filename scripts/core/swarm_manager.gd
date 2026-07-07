extends Node

var is_running: bool = false
var class_asts: Dictionary = {}
var active_interpreters: Array = []

signal global_step
signal executing_line(group_name: String, line_number: int)

func step_swarm() -> void:
	global_step.emit()

func run_swarm(scripts: Dictionary, step_mode: bool = false) -> bool:
	stop_swarm()
	
	is_running = true
	var any_ran = false
	var parser = CustomParser.new()
	var lexer = CustomLexer.new()
	
	for group_name in scripts.keys():
		var code = scripts[group_name]
		var ast = null
		
		if code.strip_edges() == "":
			# Create a default "Idle" AST to prevent crashes
			var idle_code = "while (true) {\n\twait()\n}"
			var tokens = lexer.tokenize(idle_code)
			ast = parser.parse(tokens)
		else:
			var tokens = lexer.tokenize(code)
			ast = parser.parse(tokens)
			
		class_asts[group_name] = ast
		
		if ast != null:
			var units = get_tree().get_nodes_in_group(group_name)
			for unit in units:
				assign_interpreter(unit, group_name, step_mode)
				any_ran = true
				
	return any_ran

func assign_interpreter(unit: Node2D, group_name: String, step_mode: bool = false) -> Interpreter:
	if not class_asts.has(group_name) or class_asts[group_name] == null:
		return null
		
	var interp = Interpreter.new()
	add_child(interp)
	
	if interp.has_signal("finished_execution"):
		interp.finished_execution.connect(_on_execution_finished)
	if interp.has_signal("error_occurred"):
		interp.error_occurred.connect(_on_execution_error)
	if interp.has_signal("executing_line"):
		interp.executing_line.connect(func(line): executing_line.emit(group_name, line))
		
	interp.execute_ast(class_asts[group_name], unit, step_mode)
	active_interpreters.append(interp)
	return interp

func register_unit(unit: Node2D, group_name: String) -> void:
	if is_running and class_asts.has(group_name):
		assign_interpreter(unit, group_name)

func stop_swarm() -> void:
	is_running = false
	for interp in active_interpreters:
		if is_instance_valid(interp):
			interp.stop_execution()
			interp.queue_free()
	active_interpreters.clear()
	class_asts.clear()

func get_interpreters_for_group(group_name: String) -> Array:
	var res = []
	for interp in active_interpreters:
		if is_instance_valid(interp) and interp.warrior and interp.warrior.is_in_group(group_name):
			res.append(interp)
	return res

func _on_execution_finished() -> void:
	pass

func _on_execution_error(line_number: int, message: String) -> void:
	print("Swarm Error on line ", line_number, ": ", message)
