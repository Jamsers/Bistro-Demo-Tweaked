extends RigidBody3D

func _physics_process(delta):
	$"PropAudioPlayer".recieve_physics_process(delta)

func _integrate_forces(state):
	$"PropAudioPlayer".recieve_integrate_forces(state)
