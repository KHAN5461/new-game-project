extends "res://scripts/entities/enemy.gd"

var boss_actions: int = 0
var max_life: int = 25
var is_charging: bool = false
var active_danger_zone: Node2D = null

func _ready() -> void:
	super._ready()
	life = max_life
	sprite.modulate = Color(1.0, 0.5, 0.5)
	sprite.scale = Vector2(1.5, 1.5)

func _on_ai_tick() -> void:
	if is_charging and is_instance_valid(active_danger_zone):
		# Explode!
		active_danger_zone.explode()
		active_danger_zone = null
		is_charging = false
		return
		
	boss_actions += 1
	if boss_actions % 3 == 0:
		# Telegraph an attack ahead
		var facing = Vector2.DOWN # Default direction, or whatever
		var danger = preload("res://scenes/entities/danger_zone.tscn").instantiate()
		danger.global_position = global_position + Vector2(0, 128) # Attack south of boss
		get_tree().current_scene.call_deferred("add_child", danger)
		active_danger_zone = danger
		is_charging = true
		
		# Boss jumps slightly to indicate cast
		var t = create_tween()
		t.tween_property(sprite, "position:y", -20, 0.1)
		t.tween_property(sprite, "position:y", 0, 0.1)
		return
	
	# Small chance to spawn a TNT barrel
	if boss_actions % 5 == 0:
		#const TNTBarrel = preload("res://scenes/entities/goblins/goblin_barrel.tscn")
		const TNTBarrel = preload("res://scenes/entities/tnt.tscn")
		var tnt = TNTBarrel.instantiate()
		tnt.global_position = global_position + Vector2(64, 0)
		get_tree().current_scene.call_deferred("add_child", tnt)
		return

	super._on_ai_tick()

func take_damage(amount: int = 1) -> void:
	if AudioManager: AudioManager.play_hit()
	life -= amount

	var ft = preload("res://scenes/ui/floating_text.tscn").instantiate()
	ft.text = str(amount)
	ft.color = Color(1, 1, 1)
	ft.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", ft)

	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.5), 0.1)
	
	if life <= 0:
		if is_instance_valid(windup_indicator):
			windup_indicator.queue_free()
		var explosion = preload("res://scenes/entities/explosion.tscn").instantiate()
		explosion.global_position = global_position
		explosion.scale = Vector2(4.0, 4.0)
		get_tree().current_scene.call_deferred("add_child", explosion)
		
		for i in range(10):
			var coin = preload("res://scenes/entities/coin.tscn").instantiate()
			coin.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			get_tree().current_scene.call_deferred("add_child", coin)
		
		if get_tree().current_scene.has_node("Goal"):
			get_tree().current_scene.get_node("Goal").unlock()
			
		queue_free()
