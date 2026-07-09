class_name CustomParser  
extends RefCounted

var tokens: Array[CustomLexer.Token] = []  
var index: int = 0  
var language_mode: CustomLexer.LanguageMode = CustomLexer.LanguageMode.PYTHON

func parse(_tokens: Array[CustomLexer.Token], mode: CustomLexer.LanguageMode = CustomLexer.LanguageMode.PYTHON) -> Dictionary:  
	tokens = _tokens  
	index = 0  
	language_mode = mode  
	  
	var ast: Array = []  
	while not _is_at_end():  
		var stmt = _parse_statement()  
		if not stmt.is_empty():  
			ast.append(stmt)  
			  
	return {"type": "Program", "body": ast}

func _parse_statement() -> Dictionary:  
	if _match([CustomLexer.TokenType.WHILE]):  
		return _parse_while_statement()  
	if _match([CustomLexer.TokenType.IF]):  
		return _parse_if_statement()  
	if _match([CustomLexer.TokenType.IDENTIFIER]):  
		return _parse_expression_statement()  
	if _match([CustomLexer.TokenType.PASS]):  
		_consume(CustomLexer.TokenType.SEMICOLON, "Expected end of statement.")  
		return {"type": "Pass"}  
	  
	_advance() # Parse fallback skip  
	return {}

func _parse_while_statement() -> Dictionary:  
	# C++ / Java mandates parentheses around conditions  
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
		else_branch = _parse_block()  
	elif _match([CustomLexer.TokenType.ELIF]): # Pythonic elseif  
		else_branch = [_parse_if_statement()]  
		  
	return {"type": "IfStatement", "condition": condition, "then": then_branch, "else": else_branch}

func _parse_block() -> Array:  
	var body: Array = []  
	if language_mode == CustomLexer.LanguageMode.PYTHON:  
		_consume(CustomLexer.TokenType.COLON, "Expected ':' to initialize Python block.")  
		_match([CustomLexer.TokenType.SEMICOLON]) # consume newline
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
	var identifier_token = _previous()  
	  
	# Handles action calls: unit_action(...)  
	if _match([CustomLexer.TokenType.LPAREN]):  
		var args: Array = []  
		if not _check(CustomLexer.TokenType.RPAREN):  
			args.append(_parse_expression())  
			while _match([CustomLexer.TokenType.COMMA]):  
				args.append(_parse_expression())  
		_consume(CustomLexer.TokenType.RPAREN, "Expected closing ')' on function call.")  
		  
		# Optional/Mandatory Semicolon match-clearing  
		_match([CustomLexer.TokenType.SEMICOLON])  
		return {"type": "CommandCall", "name": identifier_token.value, "arguments": args, "line": identifier_token.line}  
	return {}

func _parse_expression() -> Dictionary:  
	# Basic literal parse. Expand this recursively for algebraic operators if required.  
	if _match([CustomLexer.TokenType.NUMBER]):  
		return {"type": "Literal", "value": _previous().value.to_float()}  
	if _match([CustomLexer.TokenType.IDENTIFIER]):  
		var name = _previous().value
		var args: Array = []
		# If it's a function call like check_forward("enemy")
		if _match([CustomLexer.TokenType.LPAREN]):
			if not _check(CustomLexer.TokenType.RPAREN):
				args.append(_parse_expression())
				while _match([CustomLexer.TokenType.COMMA]):
					args.append(_parse_expression())
			_consume(CustomLexer.TokenType.RPAREN, "Expected ')' after sensor call.")
		return {"type": "SensorCheck", "name": name, "arguments": args}  
	if _match([CustomLexer.TokenType.STRING]):
		return {"type": "Literal", "value": _previous().value}
	return {"type": "Literal", "value": 0}

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
	push_error("Compilation Error at line " + str(tokens[index].line) + ": " + err_msg)
