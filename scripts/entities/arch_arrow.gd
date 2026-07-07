extends Path2D

@export var speed = 500
@export var targetPosition: Vector2

@onready var path_follow_2d = $PathFollow2D

func _ready():
	path_follow_2d.loop = false
	var dist = targetPosition.length()
	curve.set_point_out(0,Vector2(targetPosition.x / 2, - abs(targetPosition.x)))
	curve.set_point_position(1, targetPosition)
	
	var area = $PathFollow2D/Area2D
	if area and not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)
	
func _process(delta):
	if not targetPosition: return
	
	path_follow_2d.progress += speed * delta
	if path_follow_2d.progress_ratio >= 0.99 or not path_follow_2d.is_inside_tree(): 
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not body.is_in_group("archer"):
		var dmg = 1
		if Global: dmg = Global.attack_damage
		body.take_damage(dmg, self)
		queue_free()
