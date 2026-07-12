
extends SceneTree

func _init():
	var lexer = load("res://scripts/core/lexer.gd").new()
	var parser = load("res://scripts/core/parser.gd").new()
	var code = """
def gather_resources():
	move_forward()
	chop()
	send_message("found_wood", 1)

gather_resources()
var loc = receive_message("found_wood")
"""
	
	var tokens = lexer.tokenize(code, lexer.LanguageMode.PYTHON)
	var ast = parser.parse(tokens, lexer.LanguageMode.PYTHON)
	
	if ast.has("type") and ast["type"] == "Error":
		print("PARSER ERROR:", ast.get("message"))
	else:
		print("PARSER SUCCESS!")
		# print(ast)
		
	quit()
