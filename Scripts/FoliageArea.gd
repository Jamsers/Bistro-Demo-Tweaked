extends Area3D

var collider_audio_pair = []

@export var rustle_sounds: PackedScene
@export var placeholder: CollisionShape3D

const VELOCITY_ATTENUATION_THRESHOLD = 3.0

@onready var rustle_sounds_loaded = load(rustle_sounds.resource_path)

func _ready():
	placeholder.queue_free()
	var colliders = find_children("*", "CollisionShape3D", true)
	for collider in colliders:
		collider.reparent(self, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta):
	for pair in collider_audio_pair:
		pair["audio"].global_position = pair["collider"].global_position
		
		var collider_velocity
		if pair["collider"] is CharacterBody3D:
			collider_velocity = pair["collider"].get_real_velocity().length()
		else:
			if pair["collider"].linear_velocity.length() > pair["collider"].angular_velocity.length():
				collider_velocity = pair["collider"].linear_velocity.length()
			else:
				collider_velocity = pair["collider"].angular_velocity.length()
		
		var rustle_atten = collider_velocity/VELOCITY_ATTENUATION_THRESHOLD
		rustle_atten = clamp(rustle_atten, 0.0, 1.0)
		pair["audio"].volume_db = lerp(-80.0, 0.0, ease_out_circ(rustle_atten))

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

func ease_out_circ(lerp: float) -> float:
	return sqrt(1.0 - pow(lerp - 1.0, 2.0))
