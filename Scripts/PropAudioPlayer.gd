extends Node3D

@export_category("ceiling/floor to play audio")
@export var impulse_force_ceiling_for_prop_impact_play: float = 1200.0
@export_range (0.0, 1.0) var attenuation_percent_threshold_to_play: float = 0.2

@export_category("sounds to use")
@export var prop_sounds: Array[AudioStreamWAV]
@export var scrape_sound: AudioStreamWAV

@export_category("system")
@export var helper_script: GDScript

#set to 99999 to mute prop audio
const AUDIO_START_TIMEOUT = 0.75
const PROP_PLAY_TIMEOUT = 0.15
const VELOCITY_CEILING_FOR_SCRAPE_PLAY = 10.0
const SCRAPE_PLAY_TIMEOUT = 0.15

var prop_sounds_loaded = []

var on_cooldown = false
var scraping_on_cooldown = false
var audio_lock = true

@onready var parent_with_helper = $"../"
@onready var phys_sound_player = $"Prop"
@onready var scrape_sound_player = $"Scrape"

func _ready():
	parent_with_helper.set_script(load(helper_script.resource_path))
	for resource in prop_sounds:
		prop_sounds_loaded.append(load(resource.resource_path))
	scrape_sound_player.stream = load(scrape_sound.resource_path)
	scrape_sound_player.play()
	await get_tree().create_timer(AUDIO_START_TIMEOUT).timeout
	audio_lock = false

func _process(delta):
	pass

func recieve_physics_process(delta):
	if audio_lock:
		return
	
	var scrape_attenuation
	
	if parent_with_helper.get_contact_count() > 0:
		scrape_attenuation = parent_with_helper.linear_velocity.length()/VELOCITY_CEILING_FOR_SCRAPE_PLAY
		scrape_attenuation = clamp(scrape_attenuation, 0.0, 1.0)
	else:
		scrape_attenuation = 0.0
	
	set_scraping_pause(scrape_attenuation)

func set_scraping_pause(attenuation):
	if scraping_on_cooldown:
		return
	
	#the scraping sound needs to fade in and out?
	scraping_on_cooldown = true
	scrape_sound_player.volume_db = lerp(-80.0, 0.0, ease_out_circ(attenuation))
	await get_tree().create_timer(SCRAPE_PLAY_TIMEOUT).timeout
	scraping_on_cooldown = false

func recieve_integrate_forces(state):
	if audio_lock:
		return
	if on_cooldown:
		return
		
	var strongest_contact_impulse = 0.0
	for index in state.get_contact_count():
		if state.get_contact_impulse(index).length() > strongest_contact_impulse:
			strongest_contact_impulse = state.get_contact_impulse(index).length()
	
	var loud_scale = strongest_contact_impulse/(impulse_force_ceiling_for_prop_impact_play * state.step)
	loud_scale = clamp(loud_scale, 0.0, 1.0)
	
	if loud_scale > attenuation_percent_threshold_to_play:
		on_cooldown = true
		phys_sound_player.stream = prop_sounds_loaded.pick_random()
		phys_sound_player.volume_db = lerp(-80.0, 0.0, ease_out_circ(loud_scale))
		phys_sound_player.play()
		await get_tree().create_timer(PROP_PLAY_TIMEOUT).timeout
		on_cooldown = false

func ease_out_circ(lerp: float) -> float:
	return sqrt(1.0 - pow(lerp - 1.0, 2.0))
