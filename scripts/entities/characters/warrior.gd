extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $anim
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var shield_bar: ProgressBar = $shieldbar
@onready var camera_2d: Camera2D = $Camera2D
@onready var hitbox: Area2D = $hitbox
@onready var attack_zone: Area2D = $"attack zone"
@onready var warrior: CharacterBody2D = $"."
@onready var game_manager: Node2D = $"../.."


#timer for attacking
@export var attack_interval:float=0.3
var attack_timer:float=0.0
var player_in_range:bool=false

var goblin_torch=false
var goblin_tnt=false

@export var speed = 200.0
@export var acceleration=20
var state=0 # state =0(idle)=1(run)=2(attack)...
var dir=1
var life=20
var is_dead: bool = false
var is_shielding: bool = false
func _ready() -> void:
	progress_bar.max_value=life
	add_to_group("warrior")
	add_to_group("obstacles")
	print("DEBUG: Force killing warrior in 0.5s")
	get_tree().create_timer(0.5).timeout.connect(func():
		life = 0
		_check_death()
	)

func _physics_process(delta: float) -> void:
	# progress bar life set up
	if progress_bar: progress_bar.value = life
	update_overhead_bars(life, 20, 0, 0)
	
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	var direction :Vector2=Input.get_vector("left","right","up","down")
	
	# player movement 
	velocity.x=move_toward(velocity.x,speed*direction.x,acceleration)
	velocity.y=move_toward(velocity.y,speed*direction.y,acceleration)
	
	
	
	
	# timer for attack
	if player_in_range:
		attack_timer-=delta
		if attack_timer<=0:
			attack_timer=attack_interval
	
	#player animations
	if Input.is_action_just_pressed("left"):
		dir=1
		state=1
		anim.animation="run"
		anim.flip_h=true
	if Input.is_action_just_pressed("right"):
		dir=1
		state=1
		anim.animation="run"
		anim.flip_h=false
	if Input.is_action_just_pressed("up"):
		dir=2
		state=1
		anim.animation="run"
	if Input.is_action_just_pressed("down"):
		dir=-2
		state=1
		anim.animation="run"
		
		#player idle state
	else:
		if velocity.x==0 and velocity.y==0 and state!=2 and not is_shielding:
			anim.animation="idle"
			
	# shield logic
	if Input.is_action_pressed("shield") or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_shielding = true
		if anim:
			if anim.sprite_frames and anim.sprite_frames.has_animation("shield"):
				anim.play("shield")
			elif anim.sprite_frames and anim.sprite_frames.has_animation("Shield"):
				anim.play("Shield")
		velocity = Vector2.ZERO # Optional: stop movement while shielding
	else:
		is_shielding = false

	# player is attacking
	if Input.is_action_just_pressed("attack1"):
		state=2
		if goblin_torch==true and attack_timer>=0:
			game_manager.goblin_tnt_death()
		if state==2:
			if dir==1:
				anim.animation="side_swing"
			if dir==2:
				anim.animation="upper_swing"
			if dir==-2:
				anim.animation="down_swing"
	if Input.is_action_just_pressed("attack2"):
		state=2
		if goblin_torch==true and attack_timer>=0:
			game_manager.goblin_tnt_death()
		if state==2:
			if dir==1:
				anim.animation="side_swing_up"
			if dir==2:
				anim.animation="upper_swing_right"
			if dir==-2:
				anim.animation="down_swing_right"
	move_and_slide()


# player progress bar 
func life_check():
	if is_shielding or is_dead: return
	life-=1
	_check_death()

func life_tnt_attacked():
	if is_shielding or is_dead: return
	life-=2
	_check_death()

func _check_death():
	if life<=0 and not is_dead:
		is_dead = true
		remove_from_group("warrior")
		if SignalBus:
			SignalBus.warrior_died.emit()
			
		if anim and anim.sprite_frames:
			var anim_name = ""
			if anim.sprite_frames.has_animation("death"): anim_name = "death"
			elif anim.sprite_frames.has_animation("Death"): anim_name = "Death"
			elif anim.sprite_frames.has_animation("die"): anim_name = "die"
			
			if anim_name != "":
				anim.play(anim_name)
				# Use a timer instead of animation_finished to avoid instant deletion bugs
				await get_tree().create_timer(1.5, false).timeout
			else:
				print("DEBUG: Could not find any animation named 'death', 'Death', or 'die' in the AnimatedSprite2D!")
		queue_free()


func _on_timer_timeout() -> void:
	state=0


# player detecting enemies
func _on_dammage_box_body_entered(body: Node2D) -> void:
	if body.name.begins_with("goblin_torch"):
		if state==2:
			player_in_range=true
			goblin_torch=true
			game_manager.goblin_torch_death()
	if body.name.begins_with("goblin_tnt"):
		if state==2:
			player_in_range=true
			goblin_tnt=true
			game_manager.goblin_tnt_death()

func _on_dammage_box_body_exited(body: Node2D) -> void:
	if body.name.begins_with("goblin_torch"):
		player_in_range=false
		goblin_torch=false
	if body.name.begins_with("goblin_tnt"):
		player_in_range=false
		goblin_tnt=false

#check collision with the dynamite
func _on_dammage_box_area_entered(area: Area2D) -> void:
	if area.name.begins_with("TNT"):
		life_check()
	if area.name.begins_with("fire"):
		life_check()


func _on_dammage_box_area_exited(area: Area2D) -> void:
	if area.name.begins_with("TNT"):
		life_check()
	if area.name.begins_with("fire"):
		life_check()

func update_overhead_bars(current_hp: int, max_hp: int, current_shield: int, max_shield: int) -> void:
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current_hp
		progress_bar.visible = current_hp < max_hp
	if shield_bar:
		shield_bar.max_value = max_shield
		shield_bar.value = current_shield
		shield_bar.visible = current_shield > 0
