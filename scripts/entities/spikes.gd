extends Area2D

@onready var sprite = $Sprite2D
@onready var timer = $Timer

@export var is_deadly: bool = false
@export var toggle_interval: float = 2.0
@export var deadly_frame: int = 1
@export var safe_frame: int = 0

func _ready() -> void:
    add_to_group("spikes")
    add_to_group("obstacles") # Safe to pass through when safe? Actually we might only want to kill on touch.
    timer.wait_time = toggle_interval
    timer.start()
    _update_state()

func _on_timer_timeout() -> void:
    is_deadly = not is_deadly
    _update_state()
    _check_overlapping_bodies()

func _update_state() -> void:
    if is_deadly:
        sprite.frame = deadly_frame
    else:
        sprite.frame = safe_frame

func _check_overlapping_bodies() -> void:
    if not is_deadly: return
    for body in get_overlapping_bodies():
        _deal_damage(body)

func _on_body_entered(body: Node2D) -> void:
    if not is_deadly: return
    _deal_damage(body)

func _deal_damage(body: Node2D) -> void:
    if body.has_method("take_damage") and not body.is_dead:
        body.take_damage(9999) # Instant kill
    elif "life" in body and not body.is_dead:
        body.life = 0
        body.is_dead = true
        if body.has_node("anim"):
            body.get_node("anim").play("death" if body.get_node("anim").sprite_frames.has_animation("death") else "idle")
