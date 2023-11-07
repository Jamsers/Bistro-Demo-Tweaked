extends RigidBody3D

@export var phys_sound_player: AudioStreamPlayer3D
@export var scrape_sound_player: AudioStreamPlayer3D

@export var prop_sounds: Array[AudioStreamWAV]

var prop_sounds_loaded = []

var on_cooldown = false
var scraping_on_cooldown = false

func _ready():
	for resource in prop_sounds:
		prop_sounds_loaded.append(load(resource.resource_path))
	scrape_sound_player.stream_paused = true

func _process(delta):
	pass

func _physics_process(delta):
	var is_scraping = false
	
	if get_contact_count() > 0:
		if linear_velocity.length() > 2.0:
			#higher speed, higher volume
			is_scraping = true
	
	set_scraping_pause(is_scraping)

func set_scraping_pause(play):
	if scraping_on_cooldown:
		return
	#the scraping sound needs to fade in and out
	scraping_on_cooldown = true
	scrape_sound_player.stream_paused = !play
	await get_tree().create_timer(0.15).timeout
	scraping_on_cooldown = false

func _integrate_forces(state):
	if on_cooldown:
		return
	for index in state.get_contact_count():
		# 10.0 should probably be a percentage of this rigidbody weight
		# lerp volume between 0 and (rigidbody weight * IMPULSE_FORCE_MAX_VOLUME_CAP)
		#lerp between -80? -40? and 0? 20?
		if state.get_contact_impulse(index).length() > 10.0:
			on_cooldown = true
			phys_sound_player.stream = prop_sounds_loaded.pick_random()
			phys_sound_player.play()
			await get_tree().create_timer(0.15).timeout
			on_cooldown = false
			break

