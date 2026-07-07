extends CharacterBody2D
@onready var anim: AnimatedSprite2D = $anim
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var camera_2d: Camera2D = get_node_or_null("Camera2D")
@onready var hitbox: Area2D = $hitbox
@onready var attack_zone: Area2D = $"attack zone"
@onready var game_manager = get_tree().current_scene

signal finished_action
signal life_changed(current, max_val)
signal gold_changed(current)

#timer for attacking
@export var attack_interval: float = 0.5
var attack_timer: float = 0.0
var player_in_range: bool = false
var is_invulnerable: bool = false

var goblin_torch: bool = false
var goblin_tnt: bool = false
var gold: int = 0
var backpack: Array = []

@export var speed: float = 200.0
var state: int = 0 # state =0(idle)=1(run)=2(attack)...
var dir: int = 1
var life: int = 20

# GRID MOVEMENT VARIABLES
@export var tile_size: int = 64
var target_position: Vector2
var is_moving: bool = false
var shake_strength: float = 0.0
var movement_direction: Vector2 = Vector2.ZERO

var interaction_ray: RayCast2D

func _ready() -> void:
	if Global:
		life = Global.max_health
	progress_bar.max_value = life
	call_deferred("emit_signal", "life_changed", life, Global.max_health)
	call_deferred("emit_signal", "gold_changed", gold)
	add_to_group("archer")
	add_to_group("obstacles")
	var swarm = get_node_or_null("/root/SwarmManager")
	if swarm:
		swarm.register_unit(self, "archer")
	target_position = position
	
	interaction_ray = RayCast2D.new()
	add_child(interaction_ray)
	
	interaction_ray.enabled = false
	interaction_ray.collide_with_areas = true
	interaction_ray.collide_with_bodies = true
	interaction_ray.add_exception(self)
	for child in get_children():
		if child is CollisionObject2D:
			interaction_ray.add_exception(child)
	
	_setup_dialog_box()

var dialog_box: PanelContainer
var dialog_label: Label
var dialog_timer: Timer
var dialog_tail: Polygon2D

func _setup_dialog_box() -> void:
	dialog_box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#f4f4f4") # Off-white like the images
	style.border_color = Color("#2c2c3e") # Dark blue/purple pixel art border
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.anti_aliasing = false
	
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	
	# Add a soft drop shadow to the bubble
	style.shadow_color = Color(0, 0, 0, 0.15)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 4)
	
	dialog_box.add_theme_stylebox_override("panel", style)
	
	dialog_box.size = Vector2(100, 40)
	dialog_box.position = Vector2(-50, -100)
	dialog_box.visible = false
	dialog_box.z_index = 50
	
	dialog_label = Label.new()
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialog_label.add_theme_color_override("font_color", Color("#2c2c3e"))
	
	# Text shadow for better readability
	dialog_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.1))
	dialog_label.add_theme_constant_override("shadow_offset_x", 1)
	dialog_label.add_theme_constant_override("shadow_offset_y", 1)
	
	# Pixel-art style bold text, preventing blurriness when zoomed!
	dialog_label.add_theme_font_size_override("font_size", 16)
	dialog_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Removed autowrap so it perfectly fits the text naturally
	
	dialog_box.add_child(dialog_label)
	
	# Add the classic speech bubble tail
	dialog_tail = Polygon2D.new()
	dialog_tail.color = Color("#f4f4f4")
	dialog_tail.polygon = PackedVector2Array([Vector2(0, -2), Vector2(16, -2), Vector2(8, 12)])
	
	var tail_border = Line2D.new()
	tail_border.points = PackedVector2Array([Vector2(-2, -2), Vector2(8, 14), Vector2(18, -2)])
	tail_border.width = 4
	tail_border.default_color = Color("#2c2c3e")
	tail_border.closed = false
	dialog_tail.add_child(tail_border)
	
	dialog_box.add_child(dialog_tail)
	add_child(dialog_box)
	
	dialog_timer = Timer.new()
	dialog_timer.one_shot = true
	dialog_timer.timeout.connect(func(): dialog_box.visible = false)
	add_child(dialog_timer)

func speak(text: String) -> void:
	dialog_label.text = text.to_upper() # Make it uppercase like the Tiny Swords assets!
	
	# Let Godot calculate the exact required size based on the text and padding!
	var actual_size = dialog_box.get_minimum_size()
	dialog_box.size = actual_size
	dialog_box.position = Vector2(-actual_size.x / 2, -100)
	
	# Keep the tail anchored to the bottom center
	dialog_tail.position = Vector2((actual_size.x / 2) - 8, actual_size.y - 4)
	
	# Pop-in animation
	dialog_box.pivot_offset = Vector2(actual_size.x / 2, actual_size.y + 10)
	dialog_box.scale = Vector2.ZERO
	dialog_box.visible = true
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(dialog_box, "scale", Vector2.ONE, 0.3)
	
	# Play blip sound
	var blip = AudioStreamPlayer.new()
	blip.stream = preload("res://assets/audio/type.wav")
	blip.pitch_scale = randf_range(0.8, 1.2)
	blip.volume_db = -5.0
	add_child(blip)
	blip.play()
	blip.finished.connect(blip.queue_free)
	
	dialog_timer.start(2.5)

func _physics_process(delta: float) -> void:
	if GameManager and GameManager.state != "RUNNING":
		if anim and anim.animation != "idle" and anim.animation != "dead":
			anim.play("idle")
			
	progress_bar.value = life
	if camera_2d:
		if shake_strength > 0:
			shake_strength = lerpf(shake_strength, 0, 10 * delta)
			camera_2d.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
			if shake_strength < 0.1:
				shake_strength = 0
				camera_2d.offset = Vector2.ZERO

	
	if player_in_range:
		attack_timer -= delta
		if attack_timer <= 0:
			attack_timer = attack_interval
	
	if is_moving:
		var distance = position.distance_to(target_position)
		var step = speed * delta
		
		if distance <= step:
			position = target_position
			is_moving = false
			is_invulnerable = false
			if state == 1:
				state = 0
				finished_action.emit()
				get_tree().create_timer(0.05).timeout.connect(func():
					if state == 0 and not is_moving and anim.animation != "idle":
						anim.play("idle")
				)
		else:
			position = position.move_toward(target_position, step)
			
	elif state == 0 and anim.animation != "idle" and not is_moving:
		pass # Handled by the timer above


# --- ADVANCED SENSORY & MOVEMENT API ---

func get_facing_vector() -> Vector2:
	if dir == 1: return Vector2.LEFT if anim.flip_h else Vector2.RIGHT
	if dir == 2: return Vector2.UP
	if dir == -2: return Vector2.DOWN
	return Vector2.RIGHT

func set_facing_vector(v: Vector2) -> void:
	if v == Vector2.RIGHT: dir = 1; anim.flip_h = false
	elif v == Vector2.LEFT: dir = 1; anim.flip_h = true
	elif v == Vector2.UP: dir = 2
	elif v == Vector2.DOWN: dir = -2

func turn_left() -> void:
	var v = get_facing_vector()
	set_facing_vector(Vector2(v.y, -v.x))
	call_deferred("emit_signal", "finished_action")

func turn_right() -> void:
	var v = get_facing_vector()
	set_facing_vector(Vector2(-v.y, v.x))
	call_deferred("emit_signal", "finished_action")

func turn_around() -> void:
	var v = get_facing_vector()
	set_facing_vector(-v)
	call_deferred("emit_signal", "finished_action")

func _check_direction(target_type: String, v_dir: Vector2) -> bool:
	interaction_ray.target_position = v_dir * tile_size
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if target_type == "danger" and collider.is_in_group("danger"): return true
		if target_type == "trap" and collider.is_in_group("Traps"): return true
		if target_type == "enemy" and collider.is_in_group("enemies"): return true
		if target_type == "obstacle":
			if collider.is_in_group("obstacles") or not collider is Area2D: return true
	return false

func check_forward(target_type: String = "obstacle") -> bool: return _check_direction(target_type, get_facing_vector())
func check_left(target_type: String = "obstacle") -> bool: return _check_direction(target_type, Vector2(get_facing_vector().y, -get_facing_vector().x))
func check_right(target_type: String = "obstacle") -> bool: return _check_direction(target_type, Vector2(-get_facing_vector().y, get_facing_vector().x))
func check_backward(type: String = "obstacle") -> bool:
	return _check_direction(type, -get_facing_vector())

func scan_distance(type: String = "obstacle") -> int:
	var facing_vec = get_facing_vector()
	
	# Raycast up to 10 tiles away
	for i in range(1, 11):
		interaction_ray.target_position = facing_vec * (tile_size * i)
		interaction_ray.force_raycast_update()
		
		if interaction_ray.is_colliding():
			var collider = interaction_ray.get_collider()
			if type == "danger" and collider.is_in_group("danger"): return i
			if type == "obstacle" and collider.is_in_group("obstacles"):
				return i
			elif type == "enemy" and collider.is_in_group("enemies"):
				return i
			elif type == "gate" and collider.is_in_group("gates"):
				return i
			elif type == "coin" and collider.is_in_group("coins"):
				return i
			elif type == "meat" and collider.is_in_group("meats"):
				return i
			elif type == "goal" and collider.is_in_group("goals"):
				return i
			
			# If it hits an obstacle but we're looking for an enemy, our vision is blocked
			if collider.is_in_group("obstacles"):
				return -1
	return -1

func get_health() -> int:
	return life

func is_enemy_near() -> bool:
	return check_forward("enemy") or check_left("enemy") or check_right("enemy") or check_backward("enemy")
func heal(amount: int) -> void:
	life += amount
	if Global and life > Global.max_health: life = Global.max_health
	elif life > 20: life = 20
	speak("HEALED! (+" + str(amount) + ")")
func get_gold() -> int: return gold
func add_gold(amount: int) -> void:
	gold += amount
	if Global: Global.total_gold += amount
	gold_changed.emit(gold)

func add_to_backpack(item: String) -> void:
	if not item in backpack:
		backpack.append(item)
		speak("GOT " + item.replace("_", " ").to_upper() + "!")

func wait(seconds: float = 0.3) -> void:
	speak("WAITING ⏳")
	if get_tree():
		await get_tree().create_timer(seconds).timeout
	finished_action.emit()

func move_right() -> void: move_direction(Vector2.RIGHT)
func move_left() -> void: move_direction(Vector2.LEFT)
func move_up() -> void: move_direction(Vector2.UP)
func move_down() -> void: move_direction(Vector2.DOWN)
func move_forward() -> void: move_direction(get_facing_vector())

func move_direction(direction: Vector2) -> void:
	if is_moving or state == 2:
		call_deferred("emit_signal", "finished_action")
		return
		
	if abs(direction.x) > abs(direction.y):
		movement_direction = Vector2(sign(direction.x), 0)
	else:
		movement_direction = Vector2(0, sign(direction.y))
		
	if movement_direction == Vector2.ZERO:
		call_deferred("emit_signal", "finished_action")
		return
		
	# Check for walls/solid objects before moving
	interaction_ray.target_position = movement_direction * tile_size
	interaction_ray.force_raycast_update()
	
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		# Allow walking through Area2Ds (traps, triggers), but block solid bodies (TileMaps, grass, barrels)
		if not collider is Area2D:
			# Auto-unlock gates if we bump into them
			if collider.is_in_group("gates"):
				var opened = false
				if collider.has_method("try_unlock"):
					for k in backpack:
						if collider.try_unlock(k):
							opened = true
							speak("UNLOCKED!")
							break
					if not opened and gold >= 3:
						collider.unlock()
						gold -= 3
						speak("GATE UNLOCKED! (-3 GOLD)")
						opened = true
				if opened:
					# Let the explosion finish before moving next turn
					call_deferred("emit_signal", "finished_action")
					return
				else:
					speak("LOCKED!")
					
			# Turn to face the wall without walking
			if movement_direction.x > 0: dir = 1; anim.flip_h = false
			elif movement_direction.x < 0: dir = 1; anim.flip_h = true
			elif movement_direction.y < 0: dir = 2
			elif movement_direction.y > 0: dir = -2
			
			call_deferred("emit_signal", "finished_action")
			return
		
	spawn_dust()
	target_position = position + (movement_direction * tile_size)
	is_moving = true
	state = 1
	
	if movement_direction.x > 0:
		dir = 1
		anim.play("run")
		anim.flip_h = false
	elif movement_direction.x < 0:
		dir = 1
		anim.play("run")
		anim.flip_h = true
	elif movement_direction.y < 0:
		dir = 2
		anim.play("run")
	elif movement_direction.y > 0:
		dir = -2
		anim.play("run")

func unlock_gate(key_name: String = "") -> void:
	if is_moving or state == 2:
		call_deferred("emit_signal", "finished_action")
		return
	
	var facing_vec = get_facing_vector()
	interaction_ray.target_position = facing_vec * tile_size
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.is_in_group("gates"):
			if collider.has_method("try_unlock"):
				if collider.try_unlock(key_name):
					speak("UNLOCKED!")
				else:
					speak("WRONG KEY!")
			else:
				if gold >= 3:
					collider.unlock()
					gold -= 3
					speak("GATE UNLOCKED! (-3 GOLD)")
				else:
					speak("NEED 3 GOLD!")
		else:
			speak("NO GATE AHEAD!")
	else:
		speak("NOTHING AHEAD!")
		
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	finished_action.emit()

func attack() -> void:
	perform_attack()

func perform_attack(_attack_type: int = 1) -> void:
	if is_moving or state == 2:
		call_deferred("emit_signal", "finished_action")
		return
	state = 2
	is_invulnerable = true
	
	if goblin_torch == true and attack_timer >= 0:
		if game_manager and game_manager.has_method("goblin_tnt_death"):
			game_manager.goblin_tnt_death()
			
	anim.play("shoot")
	
	var facing_vec = Vector2.ZERO
	if dir == 1: facing_vec = Vector2.LEFT if anim.flip_h else Vector2.RIGHT
	elif dir == 2: facing_vec = Vector2.UP
	elif dir == -2: facing_vec = Vector2.DOWN
		
	# Spawn arrow projectile
	# Spawn arch arrow projectile
	var arrow = preload("res://scenes/entities/arch_arrow.tscn").instantiate()
	arrow.global_position = global_position + (facing_vec * tile_size * 0.5)
	arrow.targetPosition = facing_vec * tile_size * 5
	get_parent().add_child(arrow)
	
	# Rotate the arrow sprite to face the correct direction
	var path_follow = arrow.get_node("PathFollow2D")
	if facing_vec.x > 0:
		path_follow.rotation = 0
	elif facing_vec.x < 0:
		path_follow.rotation = PI
	elif facing_vec.y < 0:
		path_follow.rotation = -PI/2
	elif facing_vec.y > 0:
		path_follow.rotation = PI/2
		
	if AudioManager and AudioManager.has_method("play_hit"): 
		# If there is a shoot sound, play it here, else just reuse hit
		pass
			
	# Emulate animation finish delay
	if get_tree():
		await get_tree().create_timer(attack_interval).timeout
	state = 0
	is_invulnerable = false
	finished_action.emit()

func shield_block() -> void:
	if is_moving or state == 2:
		call_deferred("emit_signal", "finished_action")
		return
	
	state = 2
	is_invulnerable = true
	anim.play("idle") # Or a block animation if one exists
	speak("SHIELD BLOCK!")
	
	# Block lasts for a short duration
	if get_tree():
		await get_tree().create_timer(1.0).timeout
		
	state = 0
	finished_action.emit()
	is_invulnerable = false

# ---------------------------------

func life_check():
	take_damage(1)
		
func life_tnt_attacked():
	take_damage(2)

func _on_timer_timeout() -> void:
	if state == 2:
		state = 0

func _on_dammage_box_body_entered(body: Node2D) -> void:
	if body.name.begins_with("goblin_torch"):
		if state == 2:
			player_in_range = true
			goblin_torch = true
			if game_manager and game_manager.has_method("goblin_torch_death"):
				game_manager.goblin_torch_death()
	if body.name.begins_with("goblin_tnt"):
		if state == 2:
			player_in_range = true
			goblin_tnt = true
			if game_manager and game_manager.has_method("goblin_tnt_death"):
				game_manager.goblin_tnt_death()

func _on_dammage_box_body_exited(body: Node2D) -> void:
	if body.name.begins_with("goblin_torch"):
		player_in_range = false
		goblin_torch = false
	if body.name.begins_with("goblin_tnt"):
		player_in_range = false
		goblin_tnt = false

func _on_dammage_box_area_entered(_area: Area2D) -> void:
	pass

func _on_dammage_box_area_exited(_area: Area2D) -> void:
	pass


func take_damage(amount: int) -> void:
	if is_invulnerable: return
	if life <= 0: return
	
	if amount > 0:
		if AudioManager: AudioManager.play_hit()
		life -= amount
		life_changed.emit(life, Global.max_health if Global else 20)
		modulate = Color(1, 0, 0)
		hit_stop(0.1, 0.05)
		await get_tree().create_timer(0.2).timeout
		modulate = Color(1, 1, 1)
		
	if life <= 0:
		Engine.time_scale = 1.0 # Ensure time scale is reset
		if SignalBus:
			SignalBus.warrior_died.emit()
		die()

func die() -> void:
	queue_free()


func hit_stop(duration: float, time_scale: float) -> void:
	Engine.time_scale = time_scale
	if get_tree():
		await get_tree().create_timer(duration * time_scale).timeout
	if GameManager and GameManager.state == "RUNNING" and Global and Global.fast_execution:
		Engine.time_scale = 2.0
	else:
		Engine.time_scale = 1.0

func spawn_dust():
	var dust = CPUParticles2D.new()
	dust.emitting = true
	dust.one_shot = true
	dust.amount = 8
	dust.lifetime = 0.4
	dust.explosiveness = 0.8
	dust.direction = Vector2.UP
	dust.spread = 60
	dust.initial_velocity_min = 20
	dust.initial_velocity_max = 50
	dust.scale_amount_min = 4.0
	dust.scale_amount_max = 8.0
	dust.color = Color(0.8, 0.8, 0.8, 0.6)
	
	dust.position = position + Vector2(0, 16)
	get_parent().add_child(dust)
	
	var t = create_tween()
	t.tween_property(dust, "color:a", 0.0, 0.4)
	
	if get_tree():
		await get_tree().create_timer(0.5).timeout
	if is_instance_valid(dust): dust.queue_free()

func ranged_attack() -> void:
	if is_moving or state == 2:
		call_deferred("emit_signal", "finished_action")
		return
	state = 2
	is_invulnerable = true
	
	anim.play("shoot")
	
	var facing_vec = get_facing_vector()

	
	if get_tree():
		await get_tree().create_timer(0.2).timeout # Windup
	var arrow = preload("res://scenes/entities/arch_arrow.tscn").instantiate()
	arrow.global_position = global_position
	arrow.targetPosition = facing_vec * tile_size * 5
	
	var path_follow = arrow.get_node("PathFollow2D")
	if facing_vec.x < 0:
		path_follow.rotation = PI
	elif facing_vec.y < 0:
		path_follow.rotation = -PI/2
	elif facing_vec.y > 0:
		path_follow.rotation = PI/2
		
	if get_tree() and get_tree().current_scene:
		get_tree().current_scene.add_child(arrow)
		
	if get_tree():
		await get_tree().create_timer(attack_interval).timeout
	state = 0
	is_invulnerable = false
	finished_action.emit()
