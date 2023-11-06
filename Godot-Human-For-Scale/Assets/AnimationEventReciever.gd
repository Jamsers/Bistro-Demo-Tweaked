extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_right_footstep():
	$"root/Skeleton3D/RightFootLocation/FootstepPlayer".play()

func _on_left_footstep():
	$"root/Skeleton3D/LeftFootLocation/FootstepPlayer".play()
