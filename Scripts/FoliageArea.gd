extends Area3D


# Called when the node enters the scene tree for the first time.
func _ready():
	var colliders = find_children("*", "CollisionShape3D", true)
	for collider in colliders:
		collider.reparent(self, true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
