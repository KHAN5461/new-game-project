class_name CustomInterpreter  
extends Node

signal runtime_error(msg: String, line: int)  
signal console_print(msg: String)  
signal execution_cycle_completed(node: Dictionary)
signal finished_execution

var context_unit: Node = null  
var is_running: bool = false  
var current_cycles: int = 0  
var max_cycles_guard: int = 4000

func execute(ast: Dictionary, target_unit: Node):  
	context_unit = target_unit  
	is_running = true  
	current_cycles = 0  
	  
	if ast.get("type") != "Program":  
		emit_signal("runtime_error", "Invalid program tree hierarchy received.", 1)  
		return  
		  
	for node in ast.get("body", []):  
		if not is_running:  
			break  
		if not node.is_empty():  
			await _evaluate_node(node)  
			  
	is_running = false
	emit_signal("finished_execution")

func force_stop():  
	is_running = false

func _evaluate_node(node: Dictionary):  
	if not is_running: return  
	  
	current_cycles += 1  
	emit_signal("execution_cycle_completed", node)  
	  
	if current_cycles > max_cycles_guard:  
		emit_signal("runtime_error", "Complexity safety limit exceeded! Check for infinite loops.", node.get("line", 0))  
		force_stop()  
		return

	match node.get("type"):  
		"CommandCall":  
			await _run_command(node.name, node.arguments)  
		"WhileLoop":  
			while _eval_condition(node.condition) and is_running:  
				for inner_node in node.body:  
					await _evaluate_node(inner_node)  
				# Brief, non-blocking frame yield inside loop blocks  
				if context_unit and context_unit.is_inside_tree():
					await context_unit.get_tree().process_frame  
		"IfStatement":  
			if _eval_condition(node.condition):  
				for inner_node in node.then:  
					await _evaluate_node(inner_node)  
			elif node["else"].size() > 0:  
				for inner_node in node["else"]:  
					await _evaluate_node(inner_node)

func _run_command(command_name: String, args: Array):  
	var evaluated_args = []  
	for arg in args:  
		evaluated_args.append(arg.value) # Extract literal value  
		  
	if context_unit and context_unit.has_method("execute_instruction"):  
		# Dispatch block directly back to Godot physics nodes and await execution completion  
		await context_unit.execute_instruction(command_name, evaluated_args)  
	else:  
		emit_signal("console_print", "Unsupported unit instruction error: " + command_name)

func _eval_condition(cond: Dictionary) -> bool:  
	if cond.get("type") == "Literal":  
		return bool(cond.value)  
	if cond.get("type") == "SensorCheck":  
		if cond.name.to_lower() == "true":
			return true
		if cond.name.to_lower() == "false":
			return false
		if context_unit and context_unit.has_method("eval_sensor"):  
			var evaluated_args = []
			for arg in cond.get("arguments", []):
				evaluated_args.append(arg.value)
			return context_unit.eval_sensor(cond.name, evaluated_args)  
	return false
