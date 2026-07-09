extends SceneTree

func _init():
	print("--- Running Compiler Test Suite ---")
	
	var lexer = CustomLexer.new()
	var parser = CustomParser.new()
	
	# Test 1: Python Loop
	var py_code = """while is_enemy_near():
    attack()
    move_forward()"""
	var tokens_py = lexer.tokenize(py_code, CustomLexer.LanguageMode.PYTHON)
	var ast_py = parser.parse(tokens_py, CustomLexer.LanguageMode.PYTHON)
	
	assert(ast_py.has("body"), "Python AST failed to generate body")
	assert(ast_py.body.size() > 0, "Python AST body is empty")
	assert(ast_py.body[0].type == "WhileLoop", "Python AST failed to parse WhileLoop")
	assert(ast_py.body[0].body.size() == 2, "Python AST failed to parse block contents")
	print("Python Test Passed.")
	
	# Test 2: C++ Loop
	var cpp_code = """while (is_enemy_near()) {
    attack();
    move_forward();
}"""
	var tokens_cpp = lexer.tokenize(cpp_code, CustomLexer.LanguageMode.CPP)
	var ast_cpp = parser.parse(tokens_cpp, CustomLexer.LanguageMode.CPP)
	
	assert(ast_cpp.has("body"), "C++ AST failed to generate body")
	assert(ast_cpp.body.size() > 0, "C++ AST body is empty")
	assert(ast_cpp.body[0].type == "WhileLoop", "C++ AST failed to parse WhileLoop")
	assert(ast_cpp.body[0].body.size() == 2, "C++ AST failed to parse block contents")
	print("C++ Test Passed.")
	
	print("--- All Tests Passed! ---")
	quit()
