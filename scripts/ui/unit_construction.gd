extends Panel

@onready var selector: Sprite2D = $selector
@onready var buttons := [
	$BuildHouse1Btn,
	$BuildHouse2Btn,
	$BuildHouse3Btn,
	$BuildTowerBtn,
	$BuildmonasteryBtn,
	$BuildbarracksBtn,
	$BuildarcheryBtn
]
@onready var markers := [
	$BuildHouse1Btn/Marker2D if $BuildHouse1Btn else null,
	$BuildHouse2Btn/Marker2D if $BuildHouse2Btn else null,
	$BuildHouse3Btn/Marker2D if $BuildHouse3Btn else null,
	$BuildTowerBtn/Marker2D if $BuildTowerBtn else null,
	$BuildmonasteryBtn/Marker2D if $BuildmonasteryBtn else null,
	$BuildbarracksBtn/Marker2D if $BuildbarracksBtn else null,
	$BuildarcheryBtn/Marker2D if $BuildarcheryBtn else null
]
@onready var icons := [
	$BuildHouse1Btn/anim if $BuildHouse1Btn else null,
	$BuildHouse2Btn/anim if $BuildHouse2Btn else null,
	$BuildHouse3Btn/anim if $BuildHouse3Btn else null,
	$BuildTowerBtn/anim if $BuildTowerBtn else null,
	$BuildmonasteryBtn/anim if $BuildmonasteryBtn else null,
	$BuildbarracksBtn/anim if $BuildbarracksBtn else null,
	$BuildarcheryBtn/anim if $BuildarcheryBtn else null
]

var costs := [
	{"gold": 20, "wood": 30},
	{"gold": 25, "wood": 35},
	{"gold": 30, "wood": 40},
	{"gold": 40, "wood": 60},
	{"gold": 35, "wood": 50},
	{"gold": 45, "wood": 70},
	{"gold": 50, "wood": 80}
]

signal build_requested(building_name: String)

func _ready() -> void:
	for i in buttons.size():
		if buttons[i]:
			buttons[i].pressed.connect(_on_any_button_pressed.bind(i))
	if selector:
		selector.visible = false

func _on_any_button_pressed(index: int) -> void:
	var icon = icons[index]
	var cost = costs[index]
	if selector and markers[index]:
		selector.visible = true
		selector.global_position = markers[index].global_position
	
	if icon:
		_scale_bump(icon)
	
	if Global.gold >= cost.gold and Global.wood >= cost.wood:
		if icon: _flash_green(icon)
		var building = buttons[index].name
		Global.pawn_tool = building
		emit_signal("build_requested", building)
	else:
		if icon:
			_flash_red(icon)
			_shake_node(icon)

func _scale_bump(node: Node2D) -> void:
	var tween = create_tween()
	var original = node.scale
	tween.tween_property(node, "scale", original * 1.15, 0.08)
	tween.tween_property(node, "scale", original, 0.12)

func _flash_green(node: CanvasItem) -> void:
	var original = node.modulate
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color.GREEN, 0.15)
	tween.tween_property(node, "modulate", original, 0.15)

func _flash_red(node: CanvasItem) -> void:
	var original = node.modulate
	var tween = create_tween()
	tween.tween_property(node, "modulate", Color.RED, 0.15)
	tween.tween_property(node, "modulate", original, 0.15)

func _shake_node(node: Node2D) -> void:
	var original_pos = node.position
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "position", original_pos + Vector2(4, 0), 0.05)
	tween.tween_property(node, "position", original_pos - Vector2(4, 0), 0.05)
	tween.tween_property(node, "position", original_pos, 0.05)
