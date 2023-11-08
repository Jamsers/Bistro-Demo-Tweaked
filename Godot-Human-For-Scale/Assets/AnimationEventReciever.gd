extends Node3D

func _on_right_footstep():
	$"../../"._on_right_footstep()

func _on_left_footstep():
	$"../../"._on_left_footstep()
