extends Control

@export var enable_profiler : bool
@export var custom_res_text_box : LineEdit
@export var fps_text : Label
@export var custom_res: Array[Control]
@export var profiler: Array[Control]

const UPPER_RES_LIMIT = 8640.0
const LOWER_RES_LIMIT = 96.0

var renderTargetVertical = 1080.0

var fps
var frametime
var draw_calls
var memory
var vram

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_performance()
	
	_on_res_selected(2)
	get_viewport().connect("size_changed", _on_viewport_resize)
	
	if !enable_profiler:
		for control in profiler:
			control.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_viewport_resize():
	var yToUse
	var project_width = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var project_height = float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	var viewport_width = float(get_viewport().size.x)
	var viewport_height = float(get_viewport().size.y)
	if viewport_width/viewport_height < project_width/project_height:
		yToUse = (viewport_width/project_width) * project_height
	else:
		yToUse = viewport_height
	RenderingServer.viewport_set_scaling_3d_scale(get_viewport().get_viewport_rid(), renderTargetVertical/yToUse)

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
		custom_res_text_box.text = str(int(renderTargetVertical))
		for control in custom_res:
			control.visible = true
	else:
		match index:
			0:
				renderTargetVertical = 480.0
			1:
				renderTargetVertical = 720.0
			2:
				renderTargetVertical = 1080.0
			3:
				renderTargetVertical = 1440.0
			4:
				renderTargetVertical = 2160.0
		_on_viewport_resize()
		for control in custom_res:
			control.visible = false

func _on_custom_res_input(input_string):
	custom_res_text_box.release_focus()
	renderTargetVertical = clamp(float(input_string), LOWER_RES_LIMIT, UPPER_RES_LIMIT)
	custom_res_text_box.text = str(int(renderTargetVertical))
	_on_viewport_resize()
