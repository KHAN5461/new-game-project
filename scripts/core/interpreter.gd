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
var environment: Dictionary = {}
var functions: Dictionary = {}

func execute(ast: Dictionary, target_unit: Node):  
	context_unit = target_unit  
	is_running = true  
	current_cycles = 0  
	environment.clear()
	functions.clear()
	  
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
	
	if Global.is_debugging_paused:
		get_tree().paused = true
		await SignalBus.debugger_step_requested
		get_tree().paused = false
		
	if is_inside_tree():
		while get_tree().paused and is_running and not Global.is_debugging_paused:
			await get_tree().process_frame

			
	if not is_running: return
	  
	current_cycles += 1  
	emit_signal("execution_cycle_completed", node)  
	  
	if current_cycles > max_cycles_guard:  
		emit_signal("runtime_error", "Complexity safety limit exceeded! Check for infinite loops.", node.get("line", 0))  
		force_stop()  
		return

	match node.get("type"):  
		"FunctionDeclaration":
			functions[node.name] = node
		"CommandCall":  
			if functions.has(node.name):
				await _call_custom_function(node.name, node.arguments)
			else:
				await _run_command(node.name, node.arguments)  
		"WhileLoop":  
			while await _eval_expression(node.condition) and is_running:  
				for inner_node in node.body:  
					await _evaluate_node(inner_node)  
				# Brief, non-blocking frame yield inside loop blocks  
				if is_inside_tree():
					await get_tree().process_frame  
		"IfStatement":  
			if await _eval_expression(node.condition):  
				for inner_node in node.then:  
					await _evaluate_node(inner_node)  
			elif node["else"].size() > 0:  
				for inner_node in node["else"]:  
					await _evaluate_node(inner_node)
		"VarDeclaration":
			var val = null
			if node.initializer:
				val = await _eval_expression(node.initializer)
			environment[node.name] = val
		"Assignment":
			var val = await _eval_expression(node.value)
			if environment.has(node.name):
				environment[node.name] = val
			else:
				# Implicit declaration or error? Let's auto-declare for pythonic feel
				environment[node.name] = val
		"ExpressionStatement":
			await _eval_expression(node.expression)

func _call_custom_function(func_name: String, args: Array):
	var func_node = functions[func_name]
	# Stash current environment
	var old_env = environment.duplicate()
	
	# Bind parameters
	var evaluated_args = []
	for arg in args:
		evaluated_args.append(await _eval_expression(arg))
		
	for i in range(func_node.parameters.size()):
		if i < evaluated_args.size():
			environment[func_node.parameters[i]] = evaluated_args[i]
		else:
			environment[func_node.parameters[i]] = null
			
	# Execute body
	for inner_node in func_node.body:
		await _evaluate_node(inner_node)
		if not is_running: break
		
	# Restore environment
	environment = old_env


func _eval_sensor(sensor_name: String, args: Array = []) -> Variant:
	if context_unit and context_unit.has_method("eval_sensor"):
		return await context_unit.eval_sensor(sensor_name, args)
	return null

func _run_command(command_name: String, args: Array):  

	var evaluated_args = []  
	for arg in args:  
		evaluated_args.append(await _eval_expression(arg))
		  
	if context_unit and context_unit.has_method("execute_instruction"):  
		# Dispatch block directly back to Godot physics nodes and await execution completion  
		await context_unit.execute_instruction(command_name, evaluated_args)  
	else:  
		emit_signal("console_print", "Unsupported unit instruction error: " + command_name)

func _eval_expression(expr: Dictionary) -> Variant:
	if not is_running: return false
	
	match expr.get("type"):
		"Literal":
			return expr.value
		"Variable":
			if expr.name.to_lower() == "true": return true
			if expr.name.to_lower() == "false": return false
			if environment.has(expr.name):
				return environment[expr.name]
			else:
				emit_signal("runtime_error", "Undefined variable: " + expr.name, expr.get("line", 0))
				force_stop()
				return null
		"MemberExpression":
			if expr.object.name == "memory":
				if context_unit and "memory" in context_unit:
					if context_unit.memory.has(expr.property):
						return context_unit.memory[expr.property]
					return null
			emit_signal("runtime_error", "Undefined property: " + expr.property, expr.get("line", 0))
			force_stop()
			return null
		"SensorCheck", "CommandCall":
			if functions.has(expr.name):
				return false # Custom functions do not return values yet
			var args_eval = []
			for arg in expr.get("arguments", []):
				args_eval.append(await _eval_expression(arg))
			var sensor_val = await _eval_sensor(expr.name, args_eval)
			return sensor_val
		"Binary":
			var left = await _eval_expression(expr.left)
			var right = await _eval_expression(expr.right)
			if left == null or right == null: return null
			match expr.operator:
				"+": return left + right
				"-": return left - right
				"*": return left * right
				"/": 
					if right == 0:
						emit_signal("runtime_error", "Division by zero.", expr.get("line", 0))
						force_stop()
						return 0
					return left / right
				"==": return left == right
				"!=": return left != right
				"<": return left < right
				"<=": return left <= right
				">": return left > right
				">=": return left >= right
		"Logical":
			# Short-circuit evaluation
			var left = await _eval_expression(expr.left)
			if expr.operator == "&&" or expr.operator == "and":
				if not left: return false
				return await _eval_expression(expr.right)
			if expr.operator == "||" or expr.operator == "or":
				if left: return true
				return await _eval_expression(expr.right)
		"Unary":
			var right = await _eval_expression(expr.right)
			match expr.operator:
				"-": return -right
				"!", "not": return not right
	return null
