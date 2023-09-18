extends Control

@export var enable_profiler : bool
@export var custom_res_text_box : LineEdit
@export var fps_text : Label
@export var custom_res: Array[Control]
@export var profiler: Array[Control]

var fps
var frametime
var draw_calls
var memory
var vram

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_performance()
	
	if !enable_profiler:
		for control in profiler:
			control.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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
	if index == 5:
		for control in custom_res:
			control.visible = true
	else:
		for control in custom_res:
			control.visible = false

func _on_custom_res_input(input_string):
	custom_res_text_box.release_focus()
