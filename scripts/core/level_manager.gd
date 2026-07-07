extends Node

var current_level_index: int = 0
var levels = [] # Kept for compatibility if anything checks it

signal level_started(level_index: int)

var main_viewport: SubViewport

func get_level_path(index: int) -> String:
	if index == 0:
		return "res://scenes/ui/level_select.tscn"
	if index == 1:
		return "res://scenes/levels/level_01.tscn"
	return "res://scenes/levels/level_" + str(index) + ".tscn"

func advance_level() -> void:
	current_level_index += 1
	if Global and current_level_index > Global.levels.size():
		SceneTransition.change_scene("res://scenes/ui/end_screen.tscn")
	else:
		_load_level(get_level_path(current_level_index))

func restart_level() -> void:
	_load_level(get_level_path(current_level_index))

func _load_level(path: String) -> void:
	if not main_viewport:
		# Fallback if no viewport (e.g. testing scene directly)
		SceneTransition.change_scene(path)
		call_deferred("_emit_level_started")
		return
		
	# Clear old level
	for c in main_viewport.get_children():
		c.queue_free()
		
	var instance = null
	var level_scene = load(path)
	if level_scene:
		instance = level_scene.instantiate()
	else:
		print("Error: Could not load level ", path)
			
	if instance:
		main_viewport.add_child(instance)
		_scatter_coins(instance)
		call_deferred("_emit_level_started")

func _scatter_coins(level: Node) -> void:
	var tilemap = level.get_node_or_null("TileMap")
	if not tilemap: return
	var coin_scene = load("res://scenes/entities/coin.tscn")
	if not coin_scene: return
	
	var cells = tilemap.get_used_cells(0)
	if cells.size() == 0: return
	
	cells.shuffle()
	var spawned = 0
	for cell in cells:
		if spawned >= 8: break
		var pos = tilemap.map_to_local(cell)
		if pos.length() < 200: continue # Don't spawn too close to start
		
		var coin = coin_scene.instantiate()
		coin.position = pos
		level.add_child(coin)
		spawned += 1

func _emit_level_started() -> void:
	level_started.emit(current_level_index)
