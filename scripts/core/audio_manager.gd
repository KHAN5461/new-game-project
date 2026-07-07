extends Node

## AAA Audio Manager - Prevents audio fatigue by randomly varying the pitch
func play_sound(stream: AudioStream, pitch_variance: float = 0.1) -> void:
	if not stream: 
		return
		
	var player = AudioStreamPlayer.new()
	player.stream = stream
	# Randomize the pitch slightly so repetitive sounds (like footsteps) sound organic
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	
	add_child(player)
	player.play()
	
	# Automatically clean up the player when the sound finishes
	player.finished.connect(player.queue_free)

# Assign these in the editor or load them here once you have audio assets!
var sfx_type: AudioStream = preload("res://assets/audio/type.wav")
var sfx_hit: AudioStream = preload("res://assets/audio/hit.wav")
var sfx_coin: AudioStream = preload("res://assets/audio/coin.wav")

func play_type() -> void:
	play_sound(sfx_type, 0.2)

func play_hit() -> void:
	play_sound(sfx_hit, 0.3)

func play_coin() -> void:
	play_sound(sfx_coin, 0.1)
