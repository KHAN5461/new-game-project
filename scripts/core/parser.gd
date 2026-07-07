class_name CustomParser
extends RefCounted

var tokens: Array[CustomLexer.Token] = []
var pos: int = 0
var has_error: bool = false

signal parse_error(line_number: int, message: String)

func parse(input_tokens: Array[CustomLexer.Token]) -> ASTNodes.BlockNode:
	tokens = input_tokens
	pos = 0
	var root = ASTNodes.BlockNode.new(0)
	
	while not is_at_end() and not has_error:
		var stmt = parse_statement()
		if stmt:
			root.statements.append(stmt)
		else:
			break
			
	return root

func parse_statement() -> ASTNodes.ASTNode:
	if has_error: return null
	if match_keyword("if"): return parse_if()
	if match_keyword("while"): return parse_while()
	if match_keyword("for"): return parse_for()
	if match_keyword("var"): return parse_var_decl()
	if match_keyword("break"):
		var line = previous().line
		match_symbol(";")
		return ASTNodes.IdentifierNode.new(line, "break")
		
	if check(CustomLexer.TokenType.IDENTIFIER):
		var id_tok = peek()
		if pos + 1 < tokens.size() and tokens[pos+1].type == CustomLexer.TokenType.SYMBOL and tokens[pos+1].value == "(":
			var func_call = parse_function_call()
			match_symbol(";")
			return func_call
		elif pos + 1 < tokens.size() and tokens[pos+1].type == CustomLexer.TokenType.SYMBOL and tokens[pos+1].value == "=":
			advance()
			advance()
			var expr = parse_expression()
			match_symbol(";")
			var node = ASTNodes.VarDeclNode.new(id_tok.line, id_tok.value)
			node.value_expression = expr
			return node
			
	error("Expected statement, found " + str(peek().type))
	advance()
	return null

func parse_if() -> ASTNodes.IfNode:
	var line = previous().line
	var node = ASTNodes.IfNode.new(line)
	consume_symbol("(")
	node.condition = parse_expression()
	consume_symbol(")")
	node.true_block = parse_block()
	
	if match_keyword("else"):
		if match_keyword("if"):
			var else_if_node = parse_if()
			var wrapper = ASTNodes.BlockNode.new(else_if_node.line_number)
			wrapper.statements.append(else_if_node)
			node.false_block = wrapper
		else:
			node.false_block = parse_block()
			
	return node

func parse_while() -> ASTNodes.WhileNode:
	var line = previous().line
	var node = ASTNodes.WhileNode.new(line)
	consume_symbol("(")
	node.condition = parse_expression()
	consume_symbol(")")
	node.body = parse_block()
	return node
	
func parse_for() -> ASTNodes.ForNode:
	var line = previous().line
	consume_symbol("(")
	var count_expr = parse_expression()
	consume_symbol(")")
	var body = parse_block()
	var node = ASTNodes.ForNode.new(line)
	node.count_expression = count_expr
	node.body = body
	return node

func parse_var_decl() -> ASTNodes.VarDeclNode:
	var line = previous().line
	var name_tok = consume_type(CustomLexer.TokenType.IDENTIFIER, "Expected variable name.")
	consume_symbol("=")
	var expr = parse_expression()
	match_symbol(";")
	var node = ASTNodes.VarDeclNode.new(line, name_tok.value)
	node.value_expression = expr
	return node

func parse_function_call() -> ASTNodes.FunctionCallNode:
	var name_tok = consume_type(CustomLexer.TokenType.IDENTIFIER, "Expected function name.")
	var node = ASTNodes.FunctionCallNode.new(name_tok.line, name_tok.value)
	consume_symbol("(")
	
	if not check_symbol(")"):
		node.arguments.append(parse_expression())
		while match_symbol(","):
			node.arguments.append(parse_expression())
			
	consume_symbol(")")
	
	return node

func parse_block() -> ASTNodes.BlockNode:
	consume_symbol("{")
	var node = ASTNodes.BlockNode.new(previous().line)
	while not check_symbol("}") and not is_at_end() and not has_error:
		var stmt = parse_statement()
		if stmt: node.statements.append(stmt)
	if not has_error:
		consume_symbol("}")
	return node

func parse_expression() -> ASTNodes.ASTNode:
	var is_not = false
	if match_symbol("!"):
		is_not = true
		
	var left = parse_primary()
	
	if match_symbol("==") or match_symbol("!=") or match_symbol("<") or match_symbol(">") or match_symbol("<=") or match_symbol(">="):
		var op = previous().value
		var right = parse_primary()
		var func_call = ASTNodes.FunctionCallNode.new(left.line_number, op)
		func_call.arguments.append(left)
		func_call.arguments.append(right)
		left = func_call
		
	if is_not:
		var func_call = ASTNodes.FunctionCallNode.new(left.line_number, "!")
		func_call.arguments.append(left)
		return func_call
		
	return left

func parse_primary() -> ASTNodes.ASTNode:
	if match_type(CustomLexer.TokenType.NUMBER):
		return ASTNodes.NumberNode.new(previous().line, previous().value.to_float())
	if match_type(CustomLexer.TokenType.STRING):
		return ASTNodes.StringNode.new(previous().line, previous().value)
	if match_keyword("true"):
		return ASTNodes.IdentifierNode.new(previous().line, "true")
	if match_keyword("false"):
		return ASTNodes.IdentifierNode.new(previous().line, "false")
	if check(CustomLexer.TokenType.IDENTIFIER):
		if pos + 1 < tokens.size() and tokens[pos+1].type == CustomLexer.TokenType.SYMBOL and tokens[pos+1].value == "(":
			return parse_function_call()
		var id = consume_type(CustomLexer.TokenType.IDENTIFIER, "")
		return ASTNodes.IdentifierNode.new(id.line, id.value)
		
	error("Expected expression")
	advance()
	return ASTNodes.IdentifierNode.new(0, "error")

func is_at_end() -> bool: return peek().type == CustomLexer.TokenType.EOF
func peek() -> CustomLexer.Token: return tokens[pos]
func previous() -> CustomLexer.Token: return tokens[pos - 1]
func advance() -> CustomLexer.Token:
	if not is_at_end(): pos += 1
	return previous()
func check(type: int) -> bool: return not is_at_end() and peek().type == type
func check_symbol(sym: String) -> bool: return not is_at_end() and peek().type == CustomLexer.TokenType.SYMBOL and peek().value == sym
func check_keyword(kw: String) -> bool: return not is_at_end() and peek().type == CustomLexer.TokenType.KEYWORD and peek().value == kw
func match_type(type: int) -> bool:
	if check(type):
		advance()
		return true
	return false
func match_symbol(sym: String) -> bool:
	if check_symbol(sym):
		advance()
		return true
	return false
func match_keyword(kw: String) -> bool:
	if check_keyword(kw):
		advance()
		return true
	return false
func consume_type(type: int, msg: String) -> CustomLexer.Token:
	if check(type): return advance()
	error(msg)
	return advance() if not is_at_end() else peek()
	
func consume_symbol(sym: String) -> CustomLexer.Token:
	if check_symbol(sym): return advance()
	error("Expected '" + sym + "'")
	return advance() if not is_at_end() else peek()
	
func error(msg: String) -> void:
	if has_error: return
	has_error = true
	parse_error.emit(peek().line, msg)
