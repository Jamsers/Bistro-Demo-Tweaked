extends Node3D

@export var prop_sounds: Array[AudioStreamWAV]
@export var scrape_sound: AudioStreamWAV

@export var helper_script: GDScript

var prop_sounds_loaded = []

var on_cooldown = false
var scraping_on_cooldown = false

@onready var parent_with_helper = $"../"
@onready var phys_sound_player = $"Prop"
@onready var scrape_sound_player = $"Scrape"

func _ready():
	parent_with_helper.set_script(load(helper_script.resource_path))
	for resource in prop_sounds:
		prop_sounds_loaded.append(load(resource.resource_path))
	scrape_sound_player.stream = load(scrape_sound.resource_path)
	scrape_sound_player.play()
	await get_tree().create_timer(0.25).timeout
	phys_sound_player.volume_db = -10
	scrape_sound_player.volume_db = -15

func _process(delta):
	pass

func recieve_physics_process(delta):
	var is_scraping = false
	
	if parent_with_helper.get_contact_count() > 0:
		if parent_with_helper.linear_velocity.length() > 2.0:
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

func recieve_integrate_forces(state):
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

