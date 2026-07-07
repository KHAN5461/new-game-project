extends CodeEdit

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) == TYPE_STRING: return true
	if typeof(data) == TYPE_DICTIONARY and data.has("type") and data["type"] == "code_stamp": return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var line_col = get_line_column_at_pos(at_position)
	set_caret_line(line_col.y)
	set_caret_column(line_col.x)
	var drop_text = ""
	if typeof(data) == TYPE_STRING: drop_text = data
	elif typeof(data) == TYPE_DICTIONARY: drop_text = data.get("code", "")
	insert_text_at_caret(drop_text)
