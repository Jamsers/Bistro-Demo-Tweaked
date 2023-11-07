extends Area3D

var collider_audio_pair = []

@export var rustle_sounds: PackedScene

@onready var rustle_sounds_loaded = load(rustle_sounds.resource_path)

func _ready():
	var colliders = find_children("*", "CollisionShape3D", true)
	for collider in colliders:
		collider.reparent(self, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta):
	for pair in collider_audio_pair:
		pair["audio"].global_position = pair["collider"].global_position
		
		var collider_velocity
		if pair["collider"] is CharacterBody3D:
			collider_velocity = pair["collider"].get_real_velocity()
		else:
			collider_velocity = pair["collider"].linear_velocity
		
		if collider_velocity.length() > 2.0:
			pair["audio"].stream_paused = false
		else:
			pair["audio"].stream_paused = true
		
		#consider checking rotational velocity as well

func _on_body_entered(body):
	if body is RigidBody3D or CharacterBody3D:
		var rustle_sounds = rustle_sounds_loaded.instantiate()
		get_tree().root.get_child(0).add_child(rustle_sounds)
		rustle_sounds.global_position = body.global_position
		collider_audio_pair.append({"collider": body, "audio": rustle_sounds})

func _on_body_exited(body):
	for pair in collider_audio_pair:
		if pair["collider"] == body:
			pair["audio"].queue_free()
			collider_audio_pair.erase(pair)
			break
