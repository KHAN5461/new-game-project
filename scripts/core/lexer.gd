class_name CustomLexer
extends RefCounted

enum TokenType {
	KEYWORD,
	IDENTIFIER,
	NUMBER,
	STRING,
	SYMBOL,
	EOF
}

const KEYWORDS = ["if", "else", "while", "for", "var", "break"]
# Multi-character symbols must be matched before single-character ones
const SYMBOLS = ["==", "!=", "<=", ">=", "{", "}", "(", ")", ";", "=", "<", ">", "+", "-", ","]

class Token:
	var type: int
	var value: String
	var line: int
	
	func _init(t: int, v: String, l: int):
		type = t
		value = v
		line = l

var source_code: String = ""
var position: int = 0
var current_line: int = 1
var tokens: Array[Token] = []

func tokenize(code: String) -> Array[Token]:
	source_code = code
	position = 0
	current_line = 1
	tokens.clear()
	
	while position < source_code.length():
		var current_char = source_code[position]
		
		# 1. Skip Whitespace and track lines
		if current_char == " " or current_char == "\t" or current_char == "\r":
			position += 1
			continue
		elif current_char == "\n":
			current_line += 1
			position += 1
			continue
			
		# Skip single-line comments
		if current_char == "/" and position + 1 < source_code.length() and source_code[position + 1] == "/":
			while position < source_code.length() and source_code[position] != "\n":
				position += 1
			continue
			
		# 2. Match Numbers
		if current_char.is_valid_float() or current_char == ".":
			tokens.append(_consume_number())
			continue
			
		# 3. Match Identifiers & Keywords (e.g., check_forward, var, if)
		if _is_alpha(current_char):
			tokens.append(_consume_identifier())
			continue
			
		# 4. Match Strings
		if current_char == '"' or current_char == "'":
			tokens.append(_consume_string(current_char))
			continue
			
		# 5. Match Symbols
		var matched_symbol = false
		for sym in SYMBOLS:
			if source_code.substr(position, sym.length()) == sym:
				tokens.append(Token.new(TokenType.SYMBOL, sym, current_line))
				position += sym.length()
				matched_symbol = true
				break
				
		if matched_symbol:
			continue
			
		# If we get here, it's an unrecognized character
		push_error("Lexer Error on line %d: Unrecognized character '%s'" % [current_line, current_char])
		position += 1
		
	# End of File token
	tokens.append(Token.new(TokenType.EOF, "", current_line))
	return tokens

# --- Helper Functions ---

func _consume_number() -> Token:
	var start = position
	while position < source_code.length() and (source_code[position].is_valid_float() or source_code[position] == "."):
		position += 1
	var num_str = source_code.substr(start, position - start)
	return Token.new(TokenType.NUMBER, num_str, current_line)

func _consume_identifier() -> Token:
	var start = position
	# Identifiers can contain letters, numbers, and underscores
	while position < source_code.length() and (_is_alpha(source_code[position]) or source_code[position].is_valid_float() or source_code[position] == "_"):
		position += 1
	var text = source_code.substr(start, position - start)
	
	if text in KEYWORDS:
		return Token.new(TokenType.KEYWORD, text, current_line)
	return Token.new(TokenType.IDENTIFIER, text, current_line)

func _consume_string(quote_type: String) -> Token:
	position += 1 # skip opening quote
	var start = position
	while position < source_code.length() and source_code[position] != quote_type:
		if source_code[position] == "\n":
			current_line += 1
		position += 1
	var str_val = source_code.substr(start, position - start)
	position += 1 # skip closing quote
	return Token.new(TokenType.STRING, str_val, current_line)

func _is_alpha(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z")
