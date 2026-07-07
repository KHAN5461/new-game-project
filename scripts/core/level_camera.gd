extends Camera2D

var warrior: Node2D

var shake_intensity: float = 0.0
var shake_decay: float = 5.0

func shake(intensity: float = 10.0) -> void:
    shake_intensity = intensity

var base_pos: Vector2

func _ready() -> void:
    zoom = Vector2(0.6, 0.6)
    position_smoothing_enabled = true
    position_smoothing_speed = 3.0
    
    global_position = Vector2(800, 200)
    base_pos = global_position
    
func _process(delta: float) -> void:
    if not warrior:
        var warriors = get_tree().get_nodes_in_group("warrior")
        if warriors.size() > 0:
            warrior = warriors[0]
            
    var target_pos = base_pos
    if warrior:
        var offset_to_player = (warrior.global_position - base_pos) * 0.2
        if offset_to_player.length() > 300:
            offset_to_player = offset_to_player.normalized() * 300
        target_pos = base_pos + offset_to_player

    if shake_intensity > 0:
        shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta * 10.0)
        var offset_x = randf_range(-shake_intensity, shake_intensity)
        var offset_y = randf_range(-shake_intensity, shake_intensity)
        global_position = target_pos + Vector2(offset_x, offset_y)
    else:
        global_position = global_position.lerp(target_pos, 5.0 * delta)
