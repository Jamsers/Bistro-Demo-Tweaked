extends Resource

class_name Lighting

# For night time, we use non realistic "filmic" values.
# Real night time values are 0.3 lux for the moon with a 4000k temp, and 0.09 nits for the sky.
# Godot can handle those values just fine... it's just that they don't look very good.

@export var rotation: Quaternion = Quaternion.IDENTITY
@export var temp: float = 0.0
@export var lux: float = 0.0
@export var sky_nits: float = 0.0
@export var night_lights: bool = false
@export var exposure_mult: float = 0.0
@export var exposure_min_sens: float = 0.0
