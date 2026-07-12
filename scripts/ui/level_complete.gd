extends CanvasLayer

@onready var loc_label = $PanelContainer/VBoxContainer/GridContainer/LOCValue
@onready var cycles_label = $PanelContainer/VBoxContainer/GridContainer/CyclesValue
@onready var loc_par_label = $PanelContainer/VBoxContainer/GridContainer/LOCPar
@onready var cycles_par_label = $PanelContainer/VBoxContainer/GridContainer/CyclesPar
@onready var stars_label = $PanelContainer/VBoxContainer/StarsLabel
@onready var next_btn = $PanelContainer/VBoxContainer/NextButton

func _ready() -> void:
	next_btn.pressed.connect(_on_next)

func setup(total_loc: int, par_loc: int, total_cycles: int, par_cycles: int, stars: int) -> void:
	if not loc_label: return
	
	loc_label.text = str(total_loc)
	loc_par_label.text = "Par: " + str(par_loc)
	if total_loc <= par_loc: loc_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else: loc_label.add_theme_color_override("font_color", Color(1, 0, 0))
	
	cycles_label.text = str(total_cycles)
	cycles_par_label.text = "Par: " + str(par_cycles)
	if total_cycles <= par_cycles: cycles_label.add_theme_color_override("font_color", Color(0, 1, 0))
	else: cycles_label.add_theme_color_override("font_color", Color(1, 0, 0))
	
	var star_str = ""
	for i in range(3):
		if i < stars: star_str += "★"
		else: star_str += "☆"
	stars_label.text = star_str

func _on_next() -> void:
	if GameManager:
		GameManager._on_next_pressed()
	queue_free()
