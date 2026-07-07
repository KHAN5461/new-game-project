extends Node
class_name Interpreter

signal error_occurred(line_number: int, message: String)
signal print_requested(message: String)
signal finished_execution()
signal executing_line(line_number: int)

var is_stopped: bool = false
var warrior: Node2D = null
var is_step_mode: bool = false

var ops_this_frame: int = 0
const OPS_PER_FRAME: int = 50

var total_operations: int = 0
var max_operations: int = 2000

var scope_stack: Array[Dictionary] = [{}]

func set_variable(var_name: String, value: Variant) -> void:
	scope_stack.back()[var_name] = value

func has_variable(var_name: String) -> bool:
	for i in range(scope_stack.size() - 1, -1, -1):
		if scope_stack[i].has(var_name):
			return true
	return false

func get_variable(var_name: String) -> Variant:
	for i in range(scope_stack.size() - 1, -1, -1):
		if scope_stack[i].has(var_name):
			return scope_stack[i][var_name]
	return null

var lexer = CustomLexer.new()
var parser = CustomParser.new()

func _ready():
	parser.parse_error.connect(_on_parse_error)

func _on_parse_error(line_number: int, message: String):
	error_occurred.emit(line_number, message)
	is_stopped = true

func execute_ast(root_ast, target_warrior: Node2D, step_mode: bool = false) -> void:
	is_stopped = false
	is_step_mode = step_mode
	ops_this_frame = 0
	total_operations = 0
	scope_stack = [{}]
	warrior = target_warrior
	
	if root_ast == null:
		finished_execution.emit()
		return
		
	print("AST Received. Beginning Execution...")
	
	await get_tree().create_timer(0.1).timeout # Give physics a frame
	
	await execute_block(root_ast)
	
	if not is_stopped:
		finished_execution.emit()

func execute_code(code: String, target_warrior: Node2D) -> void:
	is_stopped = false
	ops_this_frame = 0
	scope_stack = [{}]
	warrior = target_warrior
	
	# 1. Lexical Analysis
	var tokens = lexer.tokenize(code)
	if tokens.size() == 0:
		finished_execution.emit()
		return
		
	# 2. Parsing
	var ast_root = parser.parse(tokens)
	
	if is_stopped: # Error occurred during parsing
		return
		
	print("AST Parsed Successfully. Beginning Execution...")
	
	await get_tree().create_timer(0.1).timeout # Give physics a frame
	
	await execute_block(ast_root)
	
	if not is_stopped:
		finished_execution.emit()

func stop_execution() -> void:
	is_stopped = true
	if is_instance_valid(warrior):
		if "state" in warrior: warrior.state = 0
		if "is_moving" in warrior: warrior.is_moving = false
		if "target_position" in warrior: warrior.target_position = warrior.position
		if warrior.has_node("anim"):
			var anim = warrior.get_node("anim")
			if anim and anim.animation != "idle":
				anim.play("idle")

func execute_block(block: ASTNodes.BlockNode) -> String:
	scope_stack.push_back({})
	for stmt in block.statements:
		if is_stopped or not is_inside_tree() or not is_instance_valid(warrior):
			scope_stack.pop_back()
			return ""
			
		var res = await execute_statement(stmt)
		if res == "BREAK":
			scope_stack.pop_back()
			return "BREAK"
		if res == "ERROR":
			scope_stack.pop_back()
			return "ERROR"
			
	scope_stack.pop_back()
	return "NORMAL"

func execute_node(node: Dictionary) -> Variant:
	if is_stopped:
		return null
		
	ops_this_frame += 1
	total_operations += 1
	if total_operations > max_operations:
		_on_parse_error(node.get("line", -1), "CPU OVERHEATED! (Infinite Loop)")
		return null
		
	if ops_this_frame >= OPS_PER_FRAME:
		ops_this_frame = 0
		await get_tree().process_frame
		
	if is_stopped: return "ERROR"
	
	return null

func execute_statement(stmt: ASTNodes.ASTNode) -> String:
	ops_this_frame += 1
	total_operations += 1
	if total_operations > max_operations:
		_on_parse_error(stmt.line_number, "CPU OVERHEATED! (Infinite Loop)")
		return "ERROR"

	if ops_this_frame >= OPS_PER_FRAME:
		ops_this_frame = 0
		if get_tree(): await get_tree().process_frame
		
	if is_stopped: return "ERROR"
	executing_line.emit(stmt.line_number)
	
	if is_step_mode:
		var swarm = get_node_or_null("/root/SwarmManager")
		if swarm:
			await swarm.global_step
			if is_stopped: return "ERROR"
	
	if stmt is ASTNodes.IfNode:
		var cond_val = await evaluate_expression(stmt.condition)
		if typeof(cond_val) == TYPE_BOOL and cond_val == true:
			return await execute_block(stmt.true_block)
		elif stmt.false_block != null:
			return await execute_block(stmt.false_block)
			
	elif stmt is ASTNodes.WhileNode:
		while true:
			ops_this_frame += 1
			if ops_this_frame >= OPS_PER_FRAME:
				ops_this_frame = 0
				if get_tree(): await get_tree().process_frame
				
			if is_stopped or not is_inside_tree(): return ""
				
			var cond_val = await evaluate_expression(stmt.condition)
			if typeof(cond_val) == TYPE_BOOL and cond_val == false:
				break
			if typeof(cond_val) != TYPE_BOOL and float(cond_val) <= 0.0:
				break
				
			var res = await execute_block(stmt.body)
			if res == "BREAK":
				break
			if res == "ERROR":
				return "ERROR"
			
	elif stmt is ASTNodes.ForNode:
		var count_val = await evaluate_expression(stmt.count_expression)
		if typeof(count_val) == TYPE_INT or typeof(count_val) == TYPE_FLOAT:
			var iterations = int(count_val)
			for i in range(iterations):
				ops_this_frame += 1
				if ops_this_frame >= OPS_PER_FRAME:
					ops_this_frame = 0
					if get_tree(): await get_tree().process_frame
					
				if is_stopped or not is_inside_tree(): return ""
				
				var res = await execute_block(stmt.body)
				if res == "BREAK":
					break
				if res == "ERROR":
					return "ERROR"
		else:
			error_occurred.emit(stmt.line_number, "For loop requires a number.")
			is_stopped = true
			return "ERROR"
			
	elif stmt is ASTNodes.FunctionCallNode:
		await evaluate_expression(stmt)
		
	elif stmt is ASTNodes.VarDeclNode:
		var val = await evaluate_expression(stmt.value_expression)
		set_variable(stmt.var_name, val)
		
	elif stmt is ASTNodes.IdentifierNode and stmt._name == "break":
		return "BREAK"
		
	return "NORMAL"

func evaluate_expression(expr: ASTNodes.ASTNode) -> Variant:
	if expr is ASTNodes.NumberNode:
		return expr.value
	if expr is ASTNodes.StringNode:
		return expr.value
	if expr is ASTNodes.IdentifierNode:
		if expr.name == "true": return true
		if expr.name == "false": return false
		if has_variable(expr.name):
			return get_variable(expr.name)
		error_occurred.emit(expr.line_number, "Unknown variable: " + expr.name)
		is_stopped = true
		return false
		
	if expr is ASTNodes.FunctionCallNode:
		var func_name = expr.function_name
		
		# Operators
		if func_name == "!":
			var val = await evaluate_expression(expr.arguments[0])
			return not val
		if func_name == "==":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return l == r
		if func_name == "!=":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return l != r
		if func_name == "<":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return float(l) < float(r)
		if func_name == ">":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return float(l) > float(r)
		if func_name == "<=":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return float(l) <= float(r)
		if func_name == ">=":
			var l = await evaluate_expression(expr.arguments[0])
			var r = await evaluate_expression(expr.arguments[1])
			return float(l) >= float(r)
			
		# Functions
		if not is_instance_valid(warrior):
			is_stopped = true
			return false
			
		var arg_vals = []
		for arg in expr.arguments:
			arg_vals.append(await evaluate_expression(arg))
			
		if func_name == "print":
			if arg_vals.size() > 0:
				var msg = str(arg_vals[0])
				if warrior.has_method("speak"): warrior.speak(msg)
				print_requested.emit(msg)
				if get_tree(): await get_tree().create_timer(1.5).timeout
			return true
			
		if func_name == "is_enemy_near":
			return warrior.is_enemy_near()
			
		if func_name == "get_health":
			if warrior.has_method("get_health"): return warrior.get_health()
			return 0
			
		if func_name == "scan_distance":
			var arg = "obstacle"
			if arg_vals.size() > 0:
				arg = str(arg_vals[0]).replace("\"", "").replace("'", "")
			if warrior.has_method("scan_distance"): return warrior.scan_distance(arg)
			return -1
			
		if func_name.begins_with("check_"):
			var arg = "obstacle"
			if arg_vals.size() > 0:
				arg = str(arg_vals[0]).replace("\"", "").replace("'", "")
			if warrior.has_method(func_name):
				return warrior.call(func_name, arg)
			return false
			
		match func_name:
			"move_forward": warrior.move_forward()
			"move_up": warrior.move_up()
			"move_down": warrior.move_down()
			"move_left": warrior.move_left()
			"move_right": warrior.move_right()
			"attack": warrior.attack()
			"ranged_attack": 
				if warrior.has_method("ranged_attack"):
					warrior.ranged_attack()
				else:
					warrior.attack() # Fallback for units without ranged_attack
			"shield_block": warrior.shield_block()
			"turn_left": warrior.turn_left()
			"turn_right": warrior.turn_right()
			"turn_around": warrior.turn_around()
			"wait": 
				if get_tree(): await get_tree().create_timer(1.0).timeout
				return true
			_:
				error_occurred.emit(expr.line_number, "Unknown function or operator: " + func_name)
				is_stopped = true
				return false
				
		await warrior.finished_action
		return true

	return false
