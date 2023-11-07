extends RigidBody3D

@export var phys_sound_player: AudioStreamPlayer3D

@export var prop_sounds: Array[AudioStreamWAV]

var prop_sounds_loaded = []

func _ready():
	for resource in prop_sounds:
		prop_sounds_loaded.append(load(resource.resource_path))

func _process(delta):
	pass
