extends StaticBody2D
@onready var anim: AnimatedSprite2D = $anim
@onready var marker: Marker2D = $Marker2D
@export var construction_time: float = 2.0
@export var max_life: int = 10
var current_life: int
var is_built: bool = false
var countdown_timer: float = 0.0


func _ready():
	# Initialize house state
	current_life = max_life
	set_process(false)

func _on_tower_body_entered(body):
	if body.is_in_group("pawns") and not is_built:
		# Start the countdown and the construction animation
		countdown_timer = construction_time
		anim.animation="under_construction"
		set_process(true)

func _process(delta):
	# Handle construction countdown
	if countdown_timer > 0:
		countdown_timer -= delta
		if countdown_timer <= 0:
			finish_construction()

func finish_construction():
	is_built = true
	anim.animation="idle"
	set_process(false)
	var time=get_tree().create_timer(0.5)
	time.timeout.connect(sp)
func sp():
	$archer.show()
func take_damage(amount: int):
	if current_life > 0:
		current_life -= amount
		if current_life <= 0:
			die()

func die():
	anim.animation="destroyed"
	set_process(false)
	queue_free() 
