extends Node2D

@onready var pawn: CharacterBody2D = $characters/pawn
@onready var warrior: CharacterBody2D = $characters/warrior


@onready var goblin_barrel: CharacterBody2D = $goblins/goblin_barrel
@onready var goblin_tnt: CharacterBody2D = $goblins/goblin_tnt
@onready var goblin_torch: CharacterBody2D = $goblins/goblin_torch


@onready var stats: Control = $ui/stats



# characters vs the goblins
func goblin_torch_death():
	goblin_torch.life_goblin_torch()
func player_life():
	warrior.life_check()
func goblin_barrel_death():
	goblin_barrel.goblin_barrel_life()
func goblin_tnt_death():
	goblin_tnt.life_goblin_tnt()
func pawn_life():
	pawn.life_pawn()
func pawn_attacked_barrel():
	pawn.life_pawn_barrel()
func pawn_attacked_torch():
	pawn.life_pawn_torch()
