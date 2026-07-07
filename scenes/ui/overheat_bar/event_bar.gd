extends TextureRect

@onready var indicator: TextureRect = $Indicator

var start_x: float
var end_x: float

func _ready() -> void:
	# Left side of the bar is 0, Right side is size.x
	end_x = indicator.size.x / 2
	start_x = size.x - indicator.size.x / 2
	
	set_progress(0.0)

# Progress is 0.0 to 1.0 (0% to 100%)
func set_progress(progress: float):
	# Clamp between 0 and 1
	progress = max(0.0, min(1.0, progress))
	
	# The bar fills from left to right normally, but the original graphic moves right to left?
	# Let's just linearly interpolate between start and end.
	# 0.0 = start_x (empty), 1.0 = end_x (full)
	var current_x = lerp(start_x, end_x, progress)
	indicator.position.x = current_x
	
	if progress > 0.8:
		# Flash red when critical
		indicator.modulate = Color(1, 0.2, 0.2)
	else:
		indicator.modulate = Color(1, 1, 1)
