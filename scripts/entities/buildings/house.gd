extends StaticBody2D

@export var construction_time: float = 5.0
@export var max_life: int = 10
@export var pawn_scene: PackedScene
@export var max_pawns: int = 3
var current_life: int
var is_built: bool = false
var countdown_timer: float = 0.0
var spawned_pawns: int = 0

@onready var anim: AnimatedSprite2D = $anim
@onready var house: Area2D = $house
@onready var marker: Marker2D = $Marker2D

func _ready():
	# Initialize house state
	current_life = max_life
	set_process(false)

func _on_house_body_entered(body):
	if body.is_in_group("pawns") and not is_built:
		# Start the countdown and the construction animation
		countdown_timer = construction_time
		anim.animation="under_construction"
		set_process(true)
	if body is StaticBody2D and body.name == "limits":
		Stats.overlap=true
	else:
		Stats.overlap=false

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
	var time=get_tree().create_timer(1.5)
	time.timeout.connect(spawn_pawns)
	

func spawn_pawns():
	Stats.add_pawn()
	
	var spawn_offset: Vector2 = Vector2(50, 0)
	for i in range(max_pawns):
		if spawned_pawns < max_pawns:
			var pawn = pawn_scene.instantiate()
			# Calculate spawn position with offset
			var spawn_position = marker.position + spawn_offset * i
			pawn.position = spawn_position
			add_child(pawn) # Alternatively, add to the main scene or a specific node
			spawned_pawns += 1
			
func take_damage(amount: int):
	if current_life > 0:
		current_life -= amount
		if current_life <= 0:
			die()

func die():
	anim.animation="destroyed"
	set_process(false)
	queue_free() 
