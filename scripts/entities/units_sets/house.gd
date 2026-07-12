extends PanelContainer

@onready var game_manager: Node = $"../.."


var is_dragging = false
var scene = preload("res://scenes/entities/buildings/house.tscn")  # Path to the house scene
var ghost_preview: Node2D = null

func _ready():
	# Connect signals from the TextureRect (house icon)
	if not $"Panel/banner/house icon".is_connected("gui_input", Callable(self, "_on_house_icon_gui_input")):
		$"Panel/banner/house icon".connect("gui_input",Callable(self, "_on_house_icon_gui_input"))


	
func _on_house_icon_gui_input(event):
	# Start dragging on mouse press and release
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			start_dragging()
		else:
			stop_dragging()

func start_dragging():
	is_dragging = true
	create_ghost_preview()

func stop_dragging():
	if is_dragging:
		place_building()
	is_dragging = false
	if ghost_preview:
		ghost_preview.queue_free()  # Remove ghost preview
		ghost_preview = null

var is_overlapping = false  # Track if ghost preview is overlapping with any objects

func create_ghost_preview():
	# Create a semi-transparent preview of the house
	ghost_preview =scene.instantiate()
	ghost_preview.modulate = Color(1, 1, 1, 0.5)  # Make semi-transparent
	game_manager.add_child(ghost_preview)
	
	# Create an Area2D node for collision detection
	var collision_checker = Area2D.new()
	ghost_preview.add_child(collision_checker)
	
	# Create and set up the CollisionShape2D
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = RectangleShape2D.new()  # Change to appropriate shape (e.g., Rectangle, Circle)
	collision_shape.shape.extents = Vector2(32,32)  # Adjust size to match building size
	collision_checker.add_child(collision_shape)
	game_manager.add_child(collision_checker)
	
	# Connect signals for collision checking
	collision_checker.connect("area_entered", Callable(self, "_on_area_entered"))
	collision_checker.connect("area_exited", Callable(self, "_on_area_exited"))

	# Set collision layers/masks so that it detects only relevant objects (like StaticBody2D, CharacterBody2D)
	collision_checker.collision_layer = 1 # Set to a specific layer if needed
	collision_checker.collision_mask = 1  # Change this to match layers of StaticBody2D, CharacterBody2D, etc.


func _on_area_entered(area):
	if area.name=="tree" or area.name=="house" or area.name=="tower" or area.name=="castle" or area.name=="limits":
		is_overlapping = true
		print("building collide")
func _on_area_exited(area):
	if area.name=="tree" or area.name=="house" or area.name=="tower" or area.name=="castle" or area.name=="limits":
		is_overlapping = false

func _on_area_entered_static(StaticBody2D):
	if  StaticBody2D:
		is_overlapping = true
		print("limit collide")
func _on_area_exited_static(StaticBody2D):
	if  StaticBody2D:
		is_overlapping = false

func _on_body_entered(body):
	if body.name.begin_with("pawn") or body.name.begin_with("goblin_barrel")or body.name.begin_with("goblin_tnt") or body.name.begin_with("goblin_torch") or body.name=="limits":
		is_overlapping = true
		print("building collide")
func _on_body_exited(body):
	if body.name.begin_with("pawn") or body.name.begin_with("goblin_barrel")or body.name.begin_with("goblin_tnt") or body.name.begin_with("goblin_torch")or body.name=="limits":
		is_overlapping = false

func place_building():
	# Only place building if no overlap is detected
	if ghost_preview and not is_overlapping:
		var building =scene.instantiate()
		building.position = ghost_preview.position


		# Add the building to the Buildings node inside GameManager
		if game_manager and is_overlapping ==false:
			game_manager.add_child(building)
		else:
			print("Buildings node not found!")

func _input(event):
	# Update the ghost preview position with mouse motion while dragging
	if is_dragging and event is InputEventMouseMotion:
		if ghost_preview:
			# Convert global mouse position to the local position of the PanelContainer
			ghost_preview.global_position = get_global_mouse_position()
