class_name CustomLexer  
extends RefCounted

enum LanguageMode { PYTHON, CPP, JAVA }

enum TokenType {  
	# Literals & Names  
	IDENTIFIER, NUMBER, STRING,  
	# Operators  
	ASSIGN, EQUALS, NOT_EQUALS, LESS_THAN, GREATER_THAN, LESS_EQUAL, GREATER_EQUAL,  
	AND, OR, NOT,  
	# Keywords  
	IF, ELIF, ELSE, WHILE, FOR, IN, PASS, BREAK, CONTINUE,  
	# Structure  
	LPAREN, RPAREN, LBRACE, RBRACE, COLON, COMMA, SEMICOLON,  
	# Indentation (Python only)  
	INDENT, DEDENT,  
	# Control  
	EOF  
}

class Token:  
	var type: TokenType  
	var value: String  
	var line: int  
	var column: int  
	  
	func _init(_type: TokenType, _value: String, _line: int, _col: int):  
		self.type = _type  
		self.value = _value  
		self.line = _line  
		self.column = _col

var language_mode: LanguageMode = LanguageMode.PYTHON  
var source: String = ""  
var cursor: int = 0  
var line: int = 1  
var column: int = 1

# Indentation stack tracker for Python  
var indent_stack: Array[int] = [0]  
var is_at_line_start: bool = true

const KEYWORDS_PYTHON = {  
	"if": TokenType.IF, "elif": TokenType.ELIF, "else": TokenType.ELSE,  
	"while": TokenType.WHILE, "for": TokenType.FOR, "in": TokenType.IN,  
	"pass": TokenType.PASS, "break": TokenType.BREAK, "continue": TokenType.CONTINUE,  
	"and": TokenType.AND, "or": TokenType.OR, "not": TokenType.NOT  
}

const KEYWORDS_CPP_JAVA = {  
	"if": TokenType.IF, "else": TokenType.ELSE, "while": TokenType.WHILE,  
	"for": TokenType.FOR, "break": TokenType.BREAK, "continue": TokenType.CONTINUE,  
	"and": TokenType.AND, "or": TokenType.OR, "not": TokenType.NOT,  
	"void": TokenType.PASS, "int": TokenType.PASS, "float": TokenType.PASS, "boolean": TokenType.PASS  
}

func tokenize(_source: String, mode: LanguageMode = LanguageMode.PYTHON) -> Array[Token]:  
	language_mode = mode  
	source = _source  
	cursor = 0  
	line = 1  
	column = 1  
	indent_stack = [0]  
	is_at_line_start = true  
	  
	var tokens: Array[Token] = []  
	  
	while cursor < source.length():  
		# --- Python Indentation Handling ---  
		if language_mode == LanguageMode.PYTHON and is_at_line_start:  
			var indent_spaces = _evaluate_indentation()  
			if indent_spaces == -1: # Empty line or comment, skip handling indent  
				_skip_to_newline()  
				continue  
				  
			var current_indent = indent_stack.back()  
			if indent_spaces > current_indent:  
				indent_stack.append(indent_spaces)  
				tokens.append(Token.new(TokenType.INDENT, "", line, column))  
			elif indent_spaces < current_indent:  
				while indent_stack.size() > 1 and indent_stack.back() > indent_spaces:  
					indent_stack.pop_back()  
					tokens.append(Token.new(TokenType.DEDENT, "", line, column))  
				if indent_stack.back() != indent_spaces:  
					push_error("Indentation Error: Unmatched Python dedent at line " + str(line))  
			is_at_line_start = false  
			continue

		var current_char = source[cursor]  
		  
		# Handle Newlines  
		if current_char == "\n":  
			tokens.append(Token.new(TokenType.SEMICOLON, ";", line, column)) # Synthesize end-of-statement  
			line += 1  
			cursor += 1  
			column = 1  
			is_at_line_start = true  
			continue  
			  
		# Skip Whitespace  
		if current_char == " " or current_char == "\t" or current_char == "\r":  
			_advance()  
			continue  
			  
		# Handle Comments  
		if current_char == "#" or (current_char == "/" and _peek() == "/"):  
			_skip_to_newline()  
			continue

		# Structure Symbols  
		if current_char == "(":  
			tokens.append(Token.new(TokenType.LPAREN, "(", line, column))  
			_advance()  
			continue  
		if current_char == ")":  
			tokens.append(Token.new(TokenType.RPAREN, ")", line, column))  
			_advance()  
			continue  
		if current_char == "{":  
			tokens.append(Token.new(TokenType.LBRACE, "{", line, column))  
			_advance()  
			continue  
		if current_char == "}":  
			tokens.append(Token.new(TokenType.RBRACE, "}", line, column))  
			_advance()  
			continue  
		if current_char == ":":  
			tokens.append(Token.new(TokenType.COLON, ":", line, column))  
			_advance()  
			continue  
		if current_char == ",":  
			tokens.append(Token.new(TokenType.COMMA, ",", line, column))  
			_advance()  
			continue  
		if current_char == ";":  
			tokens.append(Token.new(TokenType.SEMICOLON, ";", line, column))  
			_advance()  
			continue

		# C-Style Operators  
		if current_char == "&" and _peek() == "&":  
			tokens.append(Token.new(TokenType.AND, "&&", line, column))  
			_advance(2)  
			continue  
		if current_char == "|" and _peek() == "|":  
			tokens.append(Token.new(TokenType.OR, "||", line, column))  
			_advance(2)  
			continue  
		if current_char == "!":  
			if _peek() == "=":  
				tokens.append(Token.new(TokenType.NOT_EQUALS, "!=", line, column))  
				_advance(2)  
			else:  
				tokens.append(Token.new(TokenType.NOT, "!", line, column))  
				_advance()  
			continue

		# Compare Operators (= vs ==)  
		if current_char == "=":  
			if _peek() == "=":  
				tokens.append(Token.new(TokenType.EQUALS, "==", line, column))  
				_advance(2)  
			else:  
				tokens.append(Token.new(TokenType.ASSIGN, "=", line, column))  
				_advance()  
			continue

		# Relational Operators  
		if current_char == "<":  
			if _peek() == "=":  
				tokens.append(Token.new(TokenType.LESS_EQUAL, "<=", line, column))  
				_advance(2)  
			else:  
				tokens.append(Token.new(TokenType.LESS_THAN, "<", line, column))  
				_advance()  
			continue  
		if current_char == ">":  
			if _peek() == "=":  
				tokens.append(Token.new(TokenType.GREATER_EQUAL, ">=", line, column))  
				_advance(2)  
			else:  
				tokens.append(Token.new(TokenType.GREATER_THAN, ">", line, column))  
				_advance()  
			continue

		# Identifiers & Keywords  
		if current_char.is_valid_identifier() and not current_char.is_valid_int():  
			var start_col = column  
			var val = ""  
			while cursor < source.length() and source[cursor].is_valid_identifier():  
				val += source[cursor]  
				_advance()  
			  
			var lookup_table = KEYWORDS_PYTHON if language_mode == LanguageMode.PYTHON else KEYWORDS_CPP_JAVA  
			var type = lookup_table.get(val, TokenType.IDENTIFIER)  
			tokens.append(Token.new(type, val, line, start_col))  
			continue

		# Strings
		if current_char == "\"" or current_char == "'":
			var quote_char = current_char
			var start_col = column
			var val = ""
			_advance()
			while cursor < source.length() and source[cursor] != quote_char:
				val += source[cursor]
				_advance()
			if cursor < source.length() and source[cursor] == quote_char:
				_advance() # consume closing quote
			tokens.append(Token.new(TokenType.STRING, val, line, start_col))
			continue

		# Numbers  
		if current_char.is_valid_int():  
			var start_col = column  
			var val = ""  
			while cursor < source.length() and (source[cursor].is_valid_int() or source[cursor] == "."):  
				val += source[cursor]  
				_advance()  
			tokens.append(Token.new(TokenType.NUMBER, val, line, start_col))  
			continue

		_advance() # Defensive catch-all skip

	# Clear out remaining indentation for Python at EOF  
	if language_mode == LanguageMode.PYTHON:  
		while indent_stack.size() > 1:  
			indent_stack.pop_back()  
			tokens.append(Token.new(TokenType.DEDENT, "", line, column))

	tokens.append(Token.new(TokenType.EOF, "", line, column))  
	return tokens

func _advance(steps: int = 1):  
	cursor += steps  
	column += steps

func _peek() -> String:  
	if cursor + 1 < source.length():  
		return source[cursor + 1]  
	return ""

func _skip_to_newline():  
	while cursor < source.length() and source[cursor] != "\n":  
		cursor += 1  
	column = 1

func _evaluate_indentation() -> int:  
	var temp_cursor = cursor  
	var spaces = 0  
	while temp_cursor < source.length():  
		var char = source[temp_cursor]  
		if char == " ":  
			spaces += 1  
			temp_cursor += 1  
		elif char == "\t":  
			spaces += 4 # Standardize tabs as 4 spaces  
			temp_cursor += 1  
		elif char == "\n" or char == "\r":  
			return -1 # Skip evaluating empty lines  
		elif char == "#":  
			return -1 # Skip evaluating purely commented lines  
		else:  
			break  
	cursor = temp_cursor  
	column += spaces  
	return spaces
