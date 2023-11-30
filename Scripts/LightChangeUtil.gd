@tool

extends Node

@export_category("Set Lighting Scenario")
@export var set_dusk: bool = false : set = apply_dusk
@export var set_noon: bool = false : set = apply_noon
@export var set_afternoon: bool = false : set = apply_afternoon
@export var set_night: bool = false : set = apply_night

@export_category("")
@export var UI: UIController

@onready var sun_orig_res = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/size")
@onready var sun_shadow_bits = ProjectSettings.get_setting("rendering/lights_and_shadows/directional_shadow/16_bits")

func apply_dusk(dummy: bool) -> void:
	apply_lighting(UI.lighting_scenarios.dusk)

func apply_noon(dummy: bool) -> void:
	apply_lighting(UI.lighting_scenarios.noon)

func apply_afternoon(dummy: bool) -> void:
	apply_lighting(UI.lighting_scenarios.afternoon)

func apply_night(dummy: bool) -> void:
	apply_lighting(UI.lighting_scenarios.night)

func apply_lighting(lighting):
	UI.sun_light.light_intensity_lux = lighting.lux
	UI.sun_light.light_temperature = lighting.temp
	UI.sun_light.quaternion = lighting.rotation
	UI.environment.environment.background_intensity = lighting.sky_nits
	UI.environment.camera_attributes.exposure_sensitivity = lighting.exposure_mult
	UI.environment.camera_attributes.auto_exposure_min_sensitivity = lighting.exposure_min_sens
	if lighting.night_lights:
		for node in UI.night_lights:
			node.visible = true
		change_shadow_casters(false)
		RenderingServer.directional_shadow_atlas_set_size(UI.NIGHT_SHADOW_RES, sun_shadow_bits)
		for mat in UI.emissives:
			mat.emission_enabled = true
	else:
		for node in UI.night_lights:
			node.visible = false
		change_shadow_casters(true)
		RenderingServer.directional_shadow_atlas_set_size(sun_orig_res, sun_shadow_bits)
		for mat in UI.emissives:
			mat.emission_enabled = false
	
	UI.environment.environment.sdfgi_enabled = false
	await get_tree().create_timer(0.1).timeout
	UI.environment.environment.sdfgi_enabled = true

func change_shadow_casters(is_cast_on):
	var shadow_mode
	
	if is_cast_on:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	else:
		shadow_mode = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	for node in UI.lamp_mesh_containers:
		for mesh in node.get_children():
			if mesh is MeshInstance3D:
				mesh.cast_shadow = shadow_mode
	for mesh in UI.lamp_meshes:
		mesh.cast_shadow = shadow_mode
