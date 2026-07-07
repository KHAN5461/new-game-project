class_name CommandParser
extends RefCounted

## Parses a string like "move_right(3)\nattack()" into an array of commands
static func parse_commands(input_text: String) -> Array[String]:
	var command_queue: Array[String] = []
	var regex = RegEx.new()
	
	regex.compile("([a-zA-Z_]+)(?:\\s*\\(\\s*(\\d*)\\s*\\))?")
	
	var matches = regex.search_all(input_text)
	for match_data in matches:
		var cmd_name = match_data.get_string(1)
		var arg_str = match_data.get_string(2)
		
		var count = 1
		if arg_str != "":
			count = int(arg_str)
			
		for i in range(count):
			command_queue.append(cmd_name)
			
	return command_queue
