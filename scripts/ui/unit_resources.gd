extends Panel

@onready var label_gold: Label = $"Gidle/Label gold"
@onready var label_wood: Label = $"Widle/Label wood"
@onready var label_meat: Label = $"Midle/Label meat"

func _process(_delta: float) -> void:
	update_labels()
	check_resources()

func update_labels() -> void:
	if label_gold: label_gold.text = " " + str(Global.gold)
	if label_wood: label_wood.text = " " + str(Global.wood)
	if label_meat: label_meat.text = " " + str(Global.meat)

func check_resources() -> void:
	if label_gold: check_resource(label_gold, Global.gold, Global.max_gold)
	if label_wood: check_resource(label_wood, Global.wood, Global.max_wood)
	if label_meat: check_resource(label_meat, Global.meat, Global.max_meat)

func check_resource(label: Label, value: int, max_value: int) -> void:
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	if value <= 0:
		label.add_theme_color_override("font_color", Color.RED)
	elif value >= max_value:
		label.add_theme_color_override("font_color", Color.GREEN)

func flash_label_red(label: Label) -> void:
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(label, "theme_override_colors/font_color", Color.RED, 0.1)
	tween.tween_property(label, "theme_override_colors/font_color", Color.WHITE, 0.1)
