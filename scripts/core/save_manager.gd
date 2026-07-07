extends Node

const SAVE_PATH = "user://save_data.tres"
const SaveDataScript = preload("res://scripts/core/save_data.gd")

var current_save

func _ready() -> void:
    load_game()

func save_game() -> void:
    if current_save == null:
        current_save = SaveDataScript.new()
    
    ResourceSaver.save(current_save, SAVE_PATH)
    print("Game saved to ", SAVE_PATH)

func load_game() -> void:
    if ResourceLoader.exists(SAVE_PATH):
        current_save = ResourceLoader.load(SAVE_PATH)
        print("Game loaded successfully.")
    else:
        current_save = SaveDataScript.new()
        print("No save found, creating new save data.")

func add_gold(amount: int) -> void:
    current_save.gold += amount
    save_game()

func get_gold() -> int:
    return current_save.gold
