extends Control

class_name UIController

@export_category("Toggles")
@export var enable_profiler : bool
@export var enable_music : bool

@export_category("Resources")
@export var settings: ScalabilitySettings
@export var lighting_scenarios: LightingScenarios

@export_category("")
@export var custom_res_text_box : LineEdit
@export var fps_text : Label
@export var custom_res: Array[Control]
@export var profiler: Array[Control]
@export var sun_light: DirectionalLight3D
@export var environment: WorldEnvironment
@export var night_lights: Array[Node3D]
@export var day_lights: Node3D
@export var lamp_mesh_containers: Array[Node3D]
@export var lamp_meshes: Array[MeshInstance3D]
@export var emissives: Array[StandardMaterial3D]
@export var scalable_night_lights: Node3D
@export var day_ambient_audio: AudioStreamPlayer
@export var night_ambient_audio: AudioStreamPlayer
@export var day_music: AudioStreamPlayer
@export var night_music: AudioStreamPlayer

const UPPER_RES_LIMIT = 8640.0
const LOWER_RES_LIMIT = 96.0
const TIME_CHANGE_DURATION = 4.0
const NIGHT_SHADOW_RES = 512

var renderTargetVertical = 1080.0
var is_time_changing = false
var is_ui_hidden = false
var ui_cooldown = false

var fps
var frametime
var draw_calls
var memory
var vram

@onready var sun_orig_res = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size")
@onready var sun_shadow_bits = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/16_bits")

func _ready():
	refresh_performance()
	
	_on_res_selected(2)
	_on_quality_selected(1)
	_on_time_selected(2)
	
	get_viewport().connect("size_changed", _on_viewport_resize)
	
	if !enable_profiler:
		for control in profiler:
			control.visible = false

func _process(delta):
	pass

func _on_viewport_resize():
	if renderTargetVertical == 0.0:
		RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), 1)
		return
	
	RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), renderTargetVertical/float(get_resolution_actual()))

func get_resolution_actual():
	var yToUse
	var project_width = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var project_height = float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var viewport_width = float(get_viewport().size.x)
	var viewport_height = float(get_viewport().size.y)
	if viewport_width/viewport_height < project_width/project_height:
		yToUse = (viewport_width/project_width) * project_height
	else:
		yToUse = viewport_height
	return int(yToUse)

func refresh_performance():
	fps = "FPS: " + str(Performance.get_monitor(Performance.TIME_FPS))
	frametime = "Frame time: " + str(snapped(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, 0.01)) + " ms"
	draw_calls = "Draw calls: " + str(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	memory = "RAM: " + str(snapped(Performance.get_monitor(Performance.MEMORY_STATIC) * 0.000001, 0.01)) + " MB"
	vram = "VRAM: " + str(snapped(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) * 0.000001, 0.01)) + " MB"
	
	fps_text.text = fps + "\n" + frametime + "\n" + draw_calls + "\n" + memory + "\n" + vram
	
	await get_tree().create_timer(0.75).timeout
	
	refresh_performance()

func _on_res_selected(index):
	if index == 6:
		if renderTargetVertical == 0.0:
			custom_res_text_box.text = str(get_resolution_actual())
		else:
			custom_res_text_box.text = str(int(renderTargetVertical))
		for control in custom_res:
			control.visible = true
	else:
		match index:
			0:
				renderTargetVertical = 0.0
			1:
				renderTargetVertical = 480.0
			2:
				renderTargetVertical = 720.0
			3:
				renderTargetVertical = 1080.0
			4:
				renderTargetVertical = 1440.0
			5:
				renderTargetVertical = 2160.0
		_on_viewport_resize()
		for control in custom_res:
			control.visible = false

func _on_custom_res_input(input_string):
	custom_res_text_box.release_focus()
	renderTargetVertical = clamp(float(input_string), LOWER_RES_LIMIT, UPPER_RES_LIMIT)
	custom_res_text_box.text = str(int(renderTargetVertical))
	_on_viewport_resize()

func _on_quality_selected(index):
	match index:
		0:
			apply_settings(settings.low)
		1:
			apply_settings(settings.normal)
		2:
			apply_settings(settings.high)

func _on_time_selected(index):
	match index:
		0:
			apply_time(lighting_scenarios.dusk)
		1:
			apply_time(lighting_scenarios.noon)
		2:
			apply_time(lighting_scenarios.afternoon)
		3:
			apply_time(lighting_scenarios.night)

func _on_quit_selected():
	get_tree().quit()

func apply_settings(settings):
	sun_light.light_angular_distance = settings.sun_angle
	environment.environment.ssr_enabled = settings.ssr
	environment.environment.ssao_enabled = settings.ssao
	environment.environment.ssil_enabled = settings.ssil
	environment.environment.sdfgi_enabled = settings.sdfgi
	RenderingServer.viewport_set_msaa_3d(get_viewport().get_viewport_rid(), settings.msaa)
	RenderingServer.viewport_set_screen_space_aa(get_viewport().get_viewport_rid(), settings.fxaa)
	RenderingServer.viewport_set_scaling_3d_mode(get_viewport().get_viewport_rid(), settings.scaling)
	for light in scalable_night_lights.get_children():
		if light is Light3D:
			light.shadow_enabled = settings.night_shadows

func apply_time(lighting):
	is_time_changing = false
	
	await get_tree().process_frame
	
	var time = Time.get_ticks_msec() / 1000.0
	var orig_lux = sun_light.light_intensity_lux
	var orig_light = sun_light.light_temperature
	var orig_rot = sun_light.quaternion
	var orig_sky = environment.environment.background_intensity
	var orig_exp_mult = environment.camera_attributes.exposure_sensitivity
	var orig_min_sens = environment.camera_attributes.auto_exposure_min_sensitivity
	var orig_day_volume = day_ambient_audio.volume_db
	var orig_night_volume = night_ambient_audio.volume_db
	var orig_day_music_volume = day_music.volume_db
	var orig_night_music_volume = night_music.volume_db
	
	var target_music_audio
	if enable_music:
		target_music_audio = 0.0
	else:
		target_music_audio = -80.0
	
	if lighting.night_lights:
		if day_music.playing:
			night_music.stop()
	else:
		for node in night_lights:
			node.visible = false
		change_shadow_casters(true)
		RenderingServer.directional_shadow_atlas_set_size(sun_orig_res, sun_shadow_bits)
		for mat in emissives:
			mat.emission_enabled = false
		if night_music.playing:
			day_music.stop()
	
	is_time_changing = true
	
	while is_time_changing:
		var current_time = Time.get_ticks_msec() / 1000.0
		var lerp = (current_time - time)/TIME_CHANGE_DURATION
		
		if lerp > 1:
			sun_light.light_intensity_lux = lighting.lux
			sun_light.light_temperature = lighting.temp
			sun_light.quaternion = lighting.rotation
			environment.environment.background_intensity = lighting.sky_nits
			environment.camera_attributes.exposure_sensitivity = lighting.exposure_mult
			environment.camera_attributes.auto_exposure_min_sensitivity = lighting.exposure_min_sens
			
			if lighting.night_lights:
				for node in night_lights:
					node.visible = true
				change_shadow_casters(false)
				RenderingServer.directional_shadow_atlas_set_size(NIGHT_SHADOW_RES, sun_shadow_bits)
				for mat in emissives:
					mat.emission_enabled = true
				
				day_ambient_audio.volume_db = -80.0
				night_ambient_audio.volume_db = 0.0
				day_music.volume_db = -80.0
				night_music.volume_db = target_music_audio
				if day_music.playing:
					day_music.stop()
					night_music.play()
			else:
				day_ambient_audio.volume_db = 0.0
				night_ambient_audio.volume_db = -80.0
				day_music.volume_db = target_music_audio
				night_music.volume_db = -80.0
				if night_music.playing:
					night_music.stop()
					day_music.play()
			
			is_time_changing = false
			break
		
		sun_light.light_intensity_lux = lerp(orig_lux, lighting.lux, easeInOutSine(lerp))
		sun_light.light_temperature = lerp(orig_light, lighting.temp, easeInOutSine(lerp))
		sun_light.quaternion = orig_rot.slerp(lighting.rotation, easeInOutSine(lerp))
		environment.environment.background_intensity = lerp(orig_sky, lighting.sky_nits, easeInOutSine(lerp))
		
		if orig_exp_mult < lighting.exposure_mult:
			environment.camera_attributes.exposure_sensitivity = lerp(orig_exp_mult, lighting.exposure_mult, easeInExp(lerp, 150))
			environment.camera_attributes.auto_exposure_min_sensitivity = lerp(orig_min_sens, lighting.exposure_min_sens, easeInExp(lerp, 150))
		else:
			environment.camera_attributes.exposure_sensitivity = lerp(orig_exp_mult, lighting.exposure_mult, easeOutExp(lerp, 150))
			environment.camera_attributes.auto_exposure_min_sensitivity = lerp(orig_min_sens, lighting.exposure_min_sens, easeOutExp(lerp, 150))
		
		var music_lerp_exp = 5
		
		if lighting.night_lights:
			day_ambient_audio.volume_db = lerp(orig_day_volume, -80.0, easeInExp(lerp, 4))
			night_ambient_audio.volume_db = lerp(orig_night_volume, 0.0, easeOutExp(lerp, 4))
			day_music.volume_db = lerp(orig_day_music_volume, -80.0, easeInExp(lerp, music_lerp_exp))
			night_music.volume_db = lerp(orig_night_music_volume, target_music_audio, easeOutExp(lerp, music_lerp_exp))
		else:
			day_ambient_audio.volume_db = lerp(orig_day_volume, 0.0, easeOutExp(lerp, 4))
			night_ambient_audio.volume_db = lerp(orig_night_volume, -80.0, easeInExp(lerp, 4))
			day_music.volume_db = lerp(orig_day_music_volume, target_music_audio, easeOutExp(lerp, music_lerp_exp))
			night_music.volume_db = lerp(orig_night_music_volume, -80.0, easeInExp(lerp, music_lerp_exp))
		
		await get_tree().process_frame

func change_shadow_casters(is_cast_on):
	var shadow_mode
	
	if is_cast_on:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	for node in lamp_mesh_containers:
		for mesh in node.get_children():
			if mesh is MeshInstance3D:
				mesh.cast_shadow = shadow_mode
	for mesh in lamp_meshes:
		mesh.cast_shadow = shadow_mode

func switch_visibility():
	ui_cooldown = true
	visible = !is_ui_hidden
	await get_tree().create_timer(0.5).timeout
	ui_cooldown = false

func _unhandled_input(event):
	if event is InputEventKey:
		match event.keycode:
			KEY_H:
				if !ui_cooldown:
					is_ui_hidden = !is_ui_hidden
					switch_visibility()

func easeInOutSine(lerp: float) -> float:
	return clamp(-(cos(PI * lerp) - 1.0) / 2.0, 0.0, 1.0)

func easeInExp(x: float, exp: int) -> float:
	return clamp(pow(x, exp), 0.0, 1.0)

func easeOutExp(x: float, exp: int) -> float:
	return clamp(1.0 - pow(1.0 - x, exp), 0.0, 1.0)
