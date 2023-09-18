extends Control

@export var custom_res_text_box : LineEdit
@export var custom_res: Array[Control]

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_res_selected(index):
	if index == 5:
		for control in custom_res:
			control.visible = true
	else:
		for control in custom_res:
			control.visible = false

func _on_custom_res_input(input_string):
	custom_res_text_box.release_focus()
