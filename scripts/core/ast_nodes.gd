class_name ASTNodes
extends RefCounted

# Base Node
class ASTNode:
	var line_number: int
	func _init(line: int):
		line_number = line

# Represents a block of code enclosed in { }
class BlockNode extends ASTNode:
	var statements: Array[ASTNode] = []
	func _init(line: int):
		super(line)

# Represents a function call, e.g., move_forward() or check_left("enemy")
class FunctionCallNode extends ASTNode:
	var function_name: String
	var arguments: Array[ASTNode] = []
	func _init(line: int, name: String):
		super(line)
		function_name = name

# Represents if (...) { ... } else { ... }
class IfNode extends ASTNode:
	var condition: ASTNode
	var true_block: BlockNode
	var false_block: BlockNode # Can be null
	func _init(line: int):
		super(line)

# Represents while (...) { ... }
class WhileNode extends ASTNode:
	var condition: ASTNode
	var body: BlockNode
	func _init(line: int):
		super(line)

# Represents for (count) { ... }
class ForNode extends ASTNode:
	var count_expression: ASTNode
	var body: BlockNode
	func _init(line: int):
		super(line)

# Represents variable declaration: var x = 5
class VarDeclNode extends ASTNode:
	var var_name: String
	var value_expression: ASTNode
	func _init(line: int, name: String):
		super(line)
		var_name = name

# Literals and Identifiers (for math and variable retrieval)
class NumberNode extends ASTNode:
	var value: float
	func _init(line: int, v: float):
		super(line)
		value = v

class StringNode extends ASTNode:
	var value: String
	func _init(line: int, v: String):
		super(line)
		value = v

class IdentifierNode extends ASTNode:
	var name: String
	func _init(line: int, n: String):
		super(line)
		name = n
