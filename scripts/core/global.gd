extends Node

var total_gold: int = 0
var max_health: int = 20
var attack_damage: int = 1
var unlocked_items: Array = []
var unlocked_spells: Array = []
var max_unlocked_level: int = 30
var selected_level: int = 1

var endless_mode: bool = false
var endless_depth: int = 1

var autocomplete_enabled: bool = true
var fast_execution: bool = false
var fullscreen: bool = false
var ide_on_left: bool = false
var last_code: String = ""
var level_codes: Dictionary = {}
var script_inventory: Dictionary = {}

var gold: int = 500
var wood: int = 500
var meat: int = 500
var max_gold: int = 1000
var max_wood: int = 1000
var max_meat: int = 1000
var choosed_colour: String = "black"
var game_over: bool = false
var level_exit_unlocked: bool = false
var current_wave: int = 0
var max_waves: int = 2
var wave_timer: float = 0.0
var wave_interval: float = 60.0
var wave_active: bool = false
var Goblin_house: int = 0
var pawn_tool: String = ""


var levels: Array = [
	{
		"name": "Level 1",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(100, 300),
		"par_loc": 2,
		"par_cycles": 10
	},
	{
		"name": "Level 2",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(300, 450),
		"par_loc": 4,
		"par_cycles": 15
	},
	{
		"name": "Level 3",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(500, 150),
		"par_loc": 5,
		"par_cycles": 20
	},
	{
		"name": "Level 4",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(700, 300)
	},
	{
		"name": "Level 5",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(900, 150)
	},
	{
		"name": "Level 6",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(1100, 450)
	},
	{
		"name": "Level 7",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(1300, 300)
	},
	{
		"name": "Level 8",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(1500, 450)
	},
	{
		"name": "Level 9",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(1700, 150)
	},
	{
		"name": "Level 10",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(1900, 300)
	},
	{
		"name": "Level 11",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(2100, 150)
	},
	{
		"name": "Level 12",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(2300, 450)
	},
	{
		"name": "Level 13",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(2500, 300)
	},
	{
		"name": "Level 14",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(2700, 450)
	},
	{
		"name": "Level 15",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(2900, 150)
	},
	{
		"name": "Level 16",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(3100, 300)
	},
	{
		"name": "Level 17",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(3300, 450)
	},
	{
		"name": "Level 18",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(3500, 150)
	},
	{
		"name": "Level 19",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(3700, 300)
	},
	{
		"name": "Level 20",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(3900, 150)
	},
	{
		"name": "Level 21",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(4100, 450)
	},
	{
		"name": "Level 22",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(4300, 300)
	},
	{
		"name": "Level 23",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(4500, 450)
	},
	{
		"name": "Level 24",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(4700, 150)
	},
	{
		"name": "Level 25",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(4900, 300)
	},
	{
		"name": "Level 26",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House1.png",
		"pos": Vector2(5100, 150)
	},
	{
		"name": "Level 27",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Barracks.png",
		"pos": Vector2(5300, 450)
	},
	{
		"name": "Level 28",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Tower.png",
		"pos": Vector2(5500, 300)
	},
	{
		"name": "Level 29",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/House2.png",
		"pos": Vector2(5700, 450)
	},
	{
		"name": "Level 30",
		"icon": "res://assets/Tiny Swords (Free Pack)/Buildings/Blue Buildings/Castle.png",
		"pos": Vector2(5900, 450)
	}
]

func _ready() -> void:
	load_game()

func save_game() -> void:
	var data = {
		"total_gold": total_gold,
		"max_health": max_health,
		"unlocked_items": unlocked_items,
		"attack_damage": attack_damage,
		"max_unlocked_level": max_unlocked_level,
		"autocomplete_enabled": autocomplete_enabled,
		"fast_execution": fast_execution,
		"fullscreen": fullscreen,
		"ide_on_left": ide_on_left,
		"last_code": last_code,
		"level_codes": level_codes
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json = JSON.new()
			var err = json.parse(content)
			if err == OK:
				var data = json.get_data()
				if data.has("total_gold"): total_gold = data["total_gold"]
				if data.has("max_health"): max_health = data["max_health"]
				if data.has("attack_damage"): attack_damage = data["attack_damage"]
				if data.has("max_unlocked_level"): max_unlocked_level = data["max_unlocked_level"]
				if data.has("autocomplete_enabled"): autocomplete_enabled = data["autocomplete_enabled"]
				if data.has("fast_execution"): fast_execution = data["fast_execution"]
				if data.has("fullscreen"): fullscreen = data["fullscreen"]
				if data.has("ide_on_left"): ide_on_left = data["ide_on_left"]
				if data.has("last_code"): last_code = data["last_code"]
				if data.has("level_codes"): level_codes = data["level_codes"]

func get_level_code(lvl: int) -> String:
	if level_codes.has(str(lvl)):
		return level_codes[str(lvl)]
	return ""
	
func save_level_code(lvl: int, code: String) -> void:
	level_codes[str(lvl)] = code
	save_game()

func save_colour() -> void:
	pass

func load_colour() -> void:
	pass

func can_spawn_pawn() -> bool:
	return meat > 0

func consume_meat(amount: int) -> bool:
	if meat < amount: return false
	meat -= amount
	return true
