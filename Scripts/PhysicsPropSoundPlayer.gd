extends RigidBody3D

@export var phys_sound_player: AudioStreamPlayer3D

@export var prop_sounds: Array[AudioStreamWAV]

var prop_sounds_loaded = []

var on_cooldown = false

func _ready():
	for resource in prop_sounds:
		prop_sounds_loaded.append(load(resource.resource_path))

func _process(delta):
	pass

func _physics_process(delta):
	pass

func _integrate_forces(state):
	if on_cooldown:
		return
	for index in state.get_contact_count():
		if state.get_contact_impulse(index).length() > 10.0:
			on_cooldown = true
			phys_sound_player.stream = prop_sounds_loaded.pick_random()
			phys_sound_player.play()
			await get_tree().create_timer(0.1).timeout
			on_cooldown = false
			break

