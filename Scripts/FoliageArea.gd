extends Area3D

var collider_audio_pair = []

@export var rustle_sounds: PackedScene
@export var placeholder: CollisionShape3D

const VELOCITY_ATTENUATION_THRESHOLD = 3.0
const ATTENUATION_ADJUST_SPEED = 200.0
const FADE_IN_OUT = 0.15

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
		var atten_speed = ATTENUATION_ADJUST_SPEED * delta
		var atten_target = set_atten(pair["collider"], pair["audio"], true)
		if pair["audio"].volume_db > atten_target:
			atten_speed = atten_speed / 3.0
		pair["audio"].volume_db = move_toward(pair["audio"].volume_db, atten_target, atten_speed)

# should change to get_atten sometime
func set_atten(phys_obj, audio, get_vol := false):
	var collider_velocity
	if phys_obj is CharacterBody3D:
		collider_velocity = phys_obj.get_real_velocity().length()
	else:
		if phys_obj.linear_velocity.length() > phys_obj.angular_velocity.length():
			collider_velocity = phys_obj.linear_velocity.length()
		else:
			collider_velocity = phys_obj.angular_velocity.length()
	
	var rustle_atten = collider_velocity/VELOCITY_ATTENUATION_THRESHOLD
	rustle_atten = clamp(rustle_atten, 0.0, 1.0)
	
	var vol = lerp(-80.0, 0.0, ease_out_circ(rustle_atten))
	if get_vol:
		return vol
	else:
		audio.volume_db = vol

func _on_body_entered(body):
	if body is RigidBody3D or CharacterBody3D:
		var rustle_sounds = rustle_sounds_loaded.instantiate()
		get_tree().root.get_child(0).add_child(rustle_sounds)
		
		var fade_time = FADE_IN_OUT
		while fade_time > 0.0:
			rustle_sounds.global_position = body.global_position
			rustle_sounds.volume_db = lerp(-80.0, set_atten(body, rustle_sounds, true), (FADE_IN_OUT-fade_time)/FADE_IN_OUT)
			await get_tree().process_frame
			fade_time -= get_process_delta_time()
		
		if overlaps_body(body):
			# this check sometimes fails because godot doesn't guarantee up to date results
			# so sometimes you'll get the bug where the foliage noise keeps on playing after you get out of foliage
			# i'm too tired to fix this, this script is bloated enough as it is
			# interestingly enough i've run into this bug in other AAA games as well
			collider_audio_pair.append({"collider": body, "audio": rustle_sounds})
		else:
			var fade_time2 = FADE_IN_OUT * 1.5
			while fade_time2 > 0.0:
				rustle_sounds.global_position = body.global_position
				rustle_sounds.volume_db = lerp(set_atten(body, rustle_sounds, true), -80.0, (FADE_IN_OUT-fade_time2)/FADE_IN_OUT)
				await get_tree().process_frame
				fade_time2 -= get_process_delta_time()
			rustle_sounds.queue_free()

func _on_body_exited(body):
	for pair in collider_audio_pair:
		if pair["collider"] == body:
			var temp_audio = pair["audio"]
			var temp_obj = pair["collider"]
			collider_audio_pair.erase(pair)
			
			var fade_time = FADE_IN_OUT * 1.5
			while fade_time > 0.0:
				temp_audio.global_position = temp_obj.global_position
				temp_audio.volume_db = lerp(set_atten(temp_obj, temp_audio, true), -80.0, (FADE_IN_OUT-fade_time)/FADE_IN_OUT)
				await get_tree().process_frame
				fade_time -= get_process_delta_time()
			
			temp_audio.queue_free()
			break

func ease_out_circ(lerp: float) -> float:
	return sqrt(1.0 - pow(lerp - 1.0, 2.0))
