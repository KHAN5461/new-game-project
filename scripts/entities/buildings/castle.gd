extends StaticBody2D
@onready var anim: AnimatedSprite2D = $anim
@onready var marker_2d: Marker2D = $Marker2D


var health=20

func castle_health():
	health-=1
	if health<=0:
		anim.animation=="destroyed"


func destroyed():
	if health<=0:
		anim.animation=="destroyed"


func under_construction():
	anim.animation=="under_construction"
	var timer=get_tree().create_timer(5.0)
	timer.timeout.connect(self.idle)

func idle():
	if health>0:
		anim.animation=="idle"


func archer_create():
	var archer_scene=preload("res://scenes/entities/characters/archer.tscn")
	var archer_instance=archer_scene.instantiate()
	add_child(archer_instance)
	archer_instance.global_position=marker_2d.global_position


func _on_castle_body_entered(body: Node2D) -> void:
	if body is StaticBody2D and body.name == "limits":
		Stats.overlap=true
	else:
		Stats.overlap=false
