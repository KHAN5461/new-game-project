class_name CustomParser  
extends RefCounted

var tokens: Array[CustomLexer.Token] = []  
var index: int = 0  
var language_mode: CustomLexer.LanguageMode = CustomLexer.LanguageMode.PYTHON
var has_error: bool = false
var error_msg: String = ""
var error_line: int = -1
var defined_functions: Array = []

func parse(_tokens: Array[CustomLexer.Token], mode: CustomLexer.LanguageMode = CustomLexer.LanguageMode.PYTHON) -> Dictionary:  
	tokens = _tokens  
	index = 0  
	language_mode = mode  
	has_error = false
	error_msg = ""
	error_line = -1
	defined_functions = []
	  
	var ast: Array = []  
	while not _is_at_end() and not has_error:  
		var stmt = _parse_statement()  
		if not stmt.is_empty():  
			ast.append(stmt)  
			  
	if has_error:
		return {"type": "Error", "message": error_msg, "line": error_line}

	return {"type": "Program", "body": ast}

func _parse_statement() -> Dictionary:  
	if _match([CustomLexer.TokenType.DEF]):
		return _parse_function_declaration()
	if _match([CustomLexer.TokenType.VAR]):
		return _parse_var_declaration()
	if _match([CustomLexer.TokenType.WHILE]):  
		return _parse_while_statement()  
	if _match([CustomLexer.TokenType.IF]):  
		return _parse_if_statement()  
	if _match([CustomLexer.TokenType.PASS]):  
		_consume(CustomLexer.TokenType.SEMICOLON, "Expected end of statement.")  
		return {"type": "Pass"}  
	if _check(CustomLexer.TokenType.IDENTIFIER):
		return _parse_expression_statement()  
	  
	_advance() # Parse fallback skip  
	return {}

func _parse_var_declaration() -> Dictionary:
	var name_token = _consume(CustomLexer.TokenType.IDENTIFIER, "Expected variable name.")
	if has_error: return {}
	
	var initializer = null
	if _match([CustomLexer.TokenType.ASSIGN]):
		initializer = _parse_expression()
	
	_match([CustomLexer.TokenType.SEMICOLON])
	return {"type": "VarDeclaration", "name": name_token.value, "initializer": initializer, "line": name_token.line}

func _parse_function_declaration() -> Dictionary:
	var name_token = _consume(CustomLexer.TokenType.IDENTIFIER, "Expected function name.")
	if has_error: return {}
	
	defined_functions.append(name_token.value)
	
	_consume(CustomLexer.TokenType.LPAREN, "Expected '(' after function name.")
	var parameters: Array = []
	if not _check(CustomLexer.TokenType.RPAREN) and not _is_at_end():
		var param_token = _consume(CustomLexer.TokenType.IDENTIFIER, "Expected parameter name.")
		parameters.append(param_token.value)
		while _match([CustomLexer.TokenType.COMMA]):
			param_token = _consume(CustomLexer.TokenType.IDENTIFIER, "Expected parameter name.")
			parameters.append(param_token.value)
			
	_consume(CustomLexer.TokenType.RPAREN, "Expected ')' after parameters.")
	
	var body = _parse_block()
	return {"type": "FunctionDeclaration", "name": name_token.value, "parameters": parameters, "body": body, "line": name_token.line}

func _parse_while_statement() -> Dictionary:  
	var has_parens = (language_mode != CustomLexer.LanguageMode.PYTHON)  
	if has_parens:  
		_consume(CustomLexer.TokenType.LPAREN, "Expected '(' starting while condition.")  
	var condition = _parse_expression()  
	if has_parens:  
		_consume(CustomLexer.TokenType.RPAREN, "Expected ')' ending while condition.")  
	var body = _parse_block()  
	return {"type": "WhileLoop", "condition": condition, "body": body}

func _parse_if_statement() -> Dictionary:  
	var has_parens = (language_mode != CustomLexer.LanguageMode.PYTHON)  
	if has_parens:  
		_consume(CustomLexer.TokenType.LPAREN, "Expected '(' starting condition block.")  
	var condition = _parse_expression()  
	if has_parens:  
		_consume(CustomLexer.TokenType.RPAREN, "Expected ')' ending condition block.")  
	var then_branch = _parse_block()  
	var else_branch: Array = []  
	  
	if _match([CustomLexer.TokenType.ELSE]):  
		if not (language_mode == CustomLexer.LanguageMode.PYTHON) and _match([CustomLexer.TokenType.IF]):
			else_branch = [_parse_if_statement()]
		else:
			else_branch = _parse_block()  
	elif _match([CustomLexer.TokenType.ELIF]): 
		else_branch = [_parse_if_statement()]  
		  
	return {"type": "IfStatement", "condition": condition, "then": then_branch, "else": else_branch}

func _parse_block() -> Array:  
	var body: Array = []  
	if language_mode == CustomLexer.LanguageMode.PYTHON:  
		_consume(CustomLexer.TokenType.COLON, "Expected ':' to initialize Python block.")  
		while _match([CustomLexer.TokenType.SEMICOLON]):
			pass
		_consume(CustomLexer.TokenType.INDENT, "Expected indented sequence block.")  
		while not _check(CustomLexer.TokenType.DEDENT) and not _is_at_end():  
			var stmt = _parse_statement()  
			if not stmt.is_empty(): body.append(stmt)  
		_consume(CustomLexer.TokenType.DEDENT, "Expected block exit alignment (dedent).")  
	else:  
		_consume(CustomLexer.TokenType.LBRACE, "Expected '{' scoping logic block.")  
		while not _check(CustomLexer.TokenType.RBRACE) and not _is_at_end():  
			var stmt = _parse_statement()  
			if not stmt.is_empty(): body.append(stmt)  
		_consume(CustomLexer.TokenType.RBRACE, "Expected '}' scoping logic block.")  
	return body

func _parse_expression_statement() -> Dictionary:  
	var expr = _parse_expression()
	if has_error: return {}
	_match([CustomLexer.TokenType.SEMICOLON])
	if expr.has("type") and (expr["type"] == "CommandCall" or expr["type"] == "Assignment"):
		return expr
	return {"type": "ExpressionStatement", "expression": expr}

func _parse_expression() -> Dictionary:  
	return _parse_assignment()

func _parse_assignment() -> Dictionary:
	var expr = _parse_logical_or()
	if _match([CustomLexer.TokenType.ASSIGN]):
		var equals_token = _previous()
		var value = _parse_assignment()
		
		if expr.has("type") and expr["type"] == "Variable":
			var name = expr["name"]
			return {"type": "Assignment", "name": name, "value": value, "line": equals_token.line}
		elif expr.has("type") and expr["type"] == "MemberExpression":
			return {"type": "Assignment", "target": expr, "value": value, "line": equals_token.line}
		else:
			has_error = true
			error_msg = "Invalid assignment target."
			error_line = equals_token.line
	return expr

func _parse_logical_or() -> Dictionary:
	var expr = _parse_logical_and()
	while _match([CustomLexer.TokenType.OR]):
		var op = _previous()
		var right = _parse_logical_and()
		expr = {"type": "Logical", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_logical_and() -> Dictionary:
	var expr = _parse_equality()
	while _match([CustomLexer.TokenType.AND]):
		var op = _previous()
		var right = _parse_equality()
		expr = {"type": "Logical", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_equality() -> Dictionary:
	var expr = _parse_comparison()
	while _match([CustomLexer.TokenType.EQUALS, CustomLexer.TokenType.NOT_EQUALS]):
		var op = _previous()
		var right = _parse_comparison()
		expr = {"type": "Binary", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_comparison() -> Dictionary:
	var expr = _parse_term()
	while _match([CustomLexer.TokenType.LESS_THAN, CustomLexer.TokenType.LESS_EQUAL, CustomLexer.TokenType.GREATER_THAN, CustomLexer.TokenType.GREATER_EQUAL]):
		var op = _previous()
		var right = _parse_term()
		expr = {"type": "Binary", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_term() -> Dictionary:
	var expr = _parse_factor()
	while _match([CustomLexer.TokenType.PLUS, CustomLexer.TokenType.MINUS]):
		var op = _previous()
		var right = _parse_factor()
		expr = {"type": "Binary", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_factor() -> Dictionary:
	var expr = _parse_unary()
	while _match([CustomLexer.TokenType.MULTIPLY, CustomLexer.TokenType.DIVIDE]):
		var op = _previous()
		var right = _parse_unary()
		expr = {"type": "Binary", "operator": op.value, "left": expr, "right": right}
	return expr

func _parse_unary() -> Dictionary:
	if _match([CustomLexer.TokenType.NOT, CustomLexer.TokenType.MINUS]):
		var op = _previous()
		var right = _parse_unary()
		return {"type": "Unary", "operator": op.value, "right": right}
	return _parse_primary()

func _parse_primary() -> Dictionary:
	if _match([CustomLexer.TokenType.NUMBER]):
		return {"type": "Literal", "value": _previous().value.to_float()}
	if _match([CustomLexer.TokenType.STRING]):
		return {"type": "Literal", "value": _previous().value}
	if _match([CustomLexer.TokenType.LPAREN]):
		var expr = _parse_expression()
		_consume(CustomLexer.TokenType.RPAREN, "Expected ')' after expression.")
		return expr
	if _match([CustomLexer.TokenType.IDENTIFIER]):
		var name_token = _previous()
		# Function call
		if _match([CustomLexer.TokenType.LPAREN]):
			var args: Array = []
			if not _check(CustomLexer.TokenType.RPAREN):
				args.append(_parse_expression())
				while _match([CustomLexer.TokenType.COMMA]):
					args.append(_parse_expression())
			_consume(CustomLexer.TokenType.RPAREN, "Expected ')' after arguments.")
			
			if not name_token.value in Global.unlocked_keywords and not name_token.value in defined_functions:
				has_error = true
				error_msg = "Command '" + name_token.value + "' is locked or undefined!"
				error_line = name_token.line
				push_error(error_msg)
				return {}
			
			return {"type": "CommandCall", "name": name_token.value, "arguments": args, "line": name_token.line}
			
		# Member Expression (memory.role)
		if _match([CustomLexer.TokenType.DOT]):
			_consume(CustomLexer.TokenType.IDENTIFIER, "Expected property name after '.'.")
			var prop_token = _previous()
			return {"type": "MemberExpression", "object": {"type": "Variable", "name": name_token.value}, "property": prop_token.value, "line": name_token.line}
		
		# Variable
		return {"type": "Variable", "name": name_token.value}

	has_error = true
	error_msg = "Expected expression."
	error_line = _previous().line if index > 0 else 0
	return {}

# Helper Parsing Pipeline Utilities  
func _match(types: Array) -> bool:  
	for type in types:  
		if _check(type):  
			_advance()  
			return true  
	return false

func _check(type: CustomLexer.TokenType) -> bool:  
	if _is_at_end(): return false  
	return tokens[index].type == type

func _advance() -> CustomLexer.Token:  
	if not _is_at_end(): index += 1  
	return _previous()

func _is_at_end() -> bool:  
	return tokens[index].type == CustomLexer.TokenType.EOF

func _previous() -> CustomLexer.Token:  
	return tokens[index - 1]

func _consume(type: CustomLexer.TokenType, err_msg: String):  
	if _check(type): return _advance()  
	has_error = true
	error_msg = err_msg
	error_line = tokens[index].line if index < tokens.size() else tokens[tokens.size()-1].line
	push_error("Compilation Error at line " + str(error_line) + ": " + err_msg)
	return null
