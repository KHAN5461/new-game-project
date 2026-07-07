extends Control

@onready var pawn_number: Label = $VBoxContainer/TextureRect/pawn/pawn_number
@onready var wood_number: Label = $VBoxContainer/wood_icon/wood/wood_number
@onready var cash_number: Label = $VBoxContainer/gold_icon/cash/cash_number
@onready var meat_number: Label = $VBoxContainer/meat_icon/meat/meat_number


func _physics_process(delta: float) -> void:
	pawn_number.text = "pawn : " + str(Stats.pawn_no)
	wood_number.text = "wood : " + str(Stats.wood_no)
	cash_number.text = "cash : " + str(Stats.cash_no)
	meat_number.text = "Meat : " + str(Stats.meat_no)

