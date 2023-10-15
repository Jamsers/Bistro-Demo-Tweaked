extends CharacterBody3D

@export var enable_depth_of_field: bool = false
@export var disable_shadow_in_first_person: bool = false

# --- Stuff you might be interested in tweaking ---
const LOOK_SENSITIVITY = 0.0025
const MOVE_MULT = 1.4
const RUN_MULT = 1.25
const FP_FOV = 75.0
const TP_FOV = 60.0
const ZOOM_MULT = 0.35
const DOF_AREA_SOFTNESS = 1.15
const DOF_AREA_SIZE_MULTIPLIER = 0.0
# --- Stuff you might be interested in tweaking ---

const FP_CAMERA_HEIGHT = 1.655
const TP_CAMERA_HEIGHT = 1.544
const TP_CAMERA_OFFSET = 0.5
const TP_CAMERA_DISTANCE = 2.1
const TRANSITION_SPEED = 0.25
const LOOK_LIMIT_UPPER = 1.25
const LOOK_LIMIT_LOWER = -1.25
const ANIM_MOVE_SPEED = 3
const ANIM_RUN_SPEED = 5.5
const NOCLIP_MULT = 4
const ROTATE_SPEED = 12.0
const JUMP_FORCE = 15.0
const GRAVITY_FORCE = 50.0
const COLLIDE_FORCE = 0.05
const DIRECTIONAL_FORCE_DIV = 30.0
const TOGGLE_COOLDOWN = 0.5
const DOF_MOVE_SPEED = 40
const DOF_INTENSITY = 0.25

var move_direction = Vector3.ZERO
var move_direction_no_y = Vector3.ZERO
var camera_rotation = Quaternion.IDENTITY
var camera_rotation_no_y = Quaternion.IDENTITY
var noclip_on = false
var noclip_toggle_cooldown = 0.0
var cam_is_fp = false
var cam_toggle_cooldown = 0.0
var cam_is_zoomed = false
var cam_zoom_cooldown = 0.0
var shoulder_is_swapped = false
var shoulder_cooldown = 0.0
var mousecapture_on = true
var mousecapture_toggle_cooldown = 0.0
var rigidbody_collisions = []
var input_velocity = Vector3.ZERO
var is_cam_transitioning = false

var mouse_movement = Vector2.ZERO
var forward_isdown = false
var backward_isdown = false
var left_isdown = false
var right_isdown = false
var cam_toggle_isdown = false
var noclip_isdown = false
var sprint_isdown = false
var jump_isdown = false
var mousecapture_isdown = false
var zoom_isdown = false
var shoulder_isdown = false

@onready var camera_pivot = $"CameraPivot"
@onready var spring_arm = $"CameraPivot/SpringArm"
@onready var camera = $"CameraPivot/SpringArm/Camera"
@onready var focus_ray = $"CameraPivot/SpringArm/Camera/RayCast3D"
@onready var player_mesh = $"ModelRoot/mannequiny-0_3_0/root/Skeleton3D/mannequiny"
@onready var anim_player = $"ModelRoot/mannequiny-0_3_0/AnimationPlayer"

func _ready():
	basis = Basis.IDENTITY
	anim_player.playback_default_blend_time = 0.2
	if enable_depth_of_field:
		hijack_camera_attributes()

func hijack_camera_attributes():
	var cams_or_envs = []
	cams_or_envs += get_tree().current_scene.find_children("*", "WorldEnvironment", true)
	cams_or_envs += get_tree().current_scene.find_children("*", "Camera3D", true)
	
	for node in cams_or_envs:
		if node is WorldEnvironment:
			if node.camera_attributes != null:
				camera.attributes = node.camera_attributes.duplicate()
				break
		if node is Camera3D:
			if node.attributes != null:
				camera.attributes = node.attributes.duplicate()
				break
	
	if camera.attributes == null:
		camera.attributes = CameraAttributesPractical.new()
		camera.attributes.auto_exposure_enabled = true

func _process(delta):
	process_mousecapture(delta)
	process_camera()
	process_movement()
	process_animation(delta)
	process_noclip(delta)
	process_cam_toggle(delta)
	process_cam_zoom(delta)
	process_shoulder_swap(delta)
	process_dof(delta)
	
	var move_speed = ANIM_MOVE_SPEED * MOVE_MULT
	if sprint_isdown:
		move_speed = ANIM_RUN_SPEED * RUN_MULT
	
	if noclip_on:
		velocity = move_direction * (move_speed * NOCLIP_MULT)
	else:
		velocity.x = move_direction_no_y.x * move_speed 
		velocity.z = move_direction_no_y.z * move_speed
		if not is_on_floor():
			velocity.y -= GRAVITY_FORCE * delta
		if jump_isdown and is_on_floor():
			velocity.y = JUMP_FORCE
	
	input_velocity = velocity
	
	move_and_slide()
	
	rigidbody_collisions = []
	
	for index in get_slide_collision_count():
		var collision = get_slide_collision(index)
		if collision.get_collider() is RigidBody3D:
			rigidbody_collisions.append(collision)

func _physics_process(delta):
	var central_multiplier = input_velocity.length() * COLLIDE_FORCE
	var directional_multiplier = input_velocity.length() * (COLLIDE_FORCE/DIRECTIONAL_FORCE_DIV)
	
	for collision in rigidbody_collisions:
		var direction = -collision.get_normal()
		var location = collision.get_position()
		collision.get_collider().apply_central_impulse(direction * central_multiplier)
		collision.get_collider().apply_impulse(direction * directional_multiplier, location)

func process_mousecapture(delta):
	if mousecapture_isdown and mousecapture_toggle_cooldown == 0:
		mousecapture_on = !mousecapture_on
		mousecapture_toggle_cooldown = TOGGLE_COOLDOWN
	
	if mousecapture_on:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	mousecapture_toggle_cooldown -= delta
	mousecapture_toggle_cooldown = clamp(mousecapture_toggle_cooldown, 0, TOGGLE_COOLDOWN)

func process_camera():
	var camera_rotation_euler = camera_rotation.get_euler()
	
	if mousecapture_on:
		camera_rotation_euler += Vector3(mouse_movement.y, mouse_movement.x, 0) * LOOK_SENSITIVITY
		camera_rotation_euler.x = clamp(camera_rotation_euler.x, LOOK_LIMIT_LOWER, LOOK_LIMIT_UPPER)
	
	camera_rotation = Quaternion.from_euler(camera_rotation_euler)
	$CameraPivot.basis = Basis(camera_rotation)
	camera_rotation_no_y = Basis($CameraPivot.basis.x, Vector3.UP, $CameraPivot.basis.z).get_rotation_quaternion()
	
	mouse_movement = Vector2.ZERO

func process_movement():
	var input_direction = Vector3.ZERO
	
	if forward_isdown:
		input_direction.z -= 1.0
	if backward_isdown:
		input_direction.z += 1.0
	if left_isdown:
		input_direction.x -= 1.0
	if right_isdown:
		input_direction.x += 1.0
	
	move_direction = camera_rotation * input_direction
	move_direction_no_y = camera_rotation_no_y * input_direction
	move_direction = move_direction.normalized()
	move_direction_no_y = move_direction_no_y.normalized()

func process_animation(delta):
	if !is_on_floor():
		switch_anim("Fall")
	elif move_direction != Vector3.ZERO:
		if sprint_isdown:
			switch_anim("Run", RUN_MULT)
		else:
			switch_anim("Jog", MOVE_MULT)
	else:
		switch_anim("Idle")
	
	if move_direction != Vector3.ZERO:
		$ModelRoot.basis = basis_rotate_toward($ModelRoot.basis, Basis.looking_at(move_direction_no_y), ROTATE_SPEED * delta)

func process_noclip(delta):
	if noclip_isdown and noclip_toggle_cooldown == 0:
		noclip_on = !noclip_on
		$CollisionShape.disabled = !$CollisionShape.disabled
		noclip_toggle_cooldown = TOGGLE_COOLDOWN
	
	noclip_toggle_cooldown -= delta
	noclip_toggle_cooldown = clamp(noclip_toggle_cooldown, 0, TOGGLE_COOLDOWN)

func process_cam_toggle(delta):
	if cam_toggle_isdown and cam_toggle_cooldown == 0 and !is_cam_transitioning:
		cam_is_fp = !cam_is_fp
		cam_toggle_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	cam_toggle_cooldown -= delta
	cam_toggle_cooldown = clamp(cam_toggle_cooldown, 0, TOGGLE_COOLDOWN)

func process_cam_zoom(delta):
	if zoom_isdown and cam_zoom_cooldown == 0 and !is_cam_transitioning:
		cam_is_zoomed = !cam_is_zoomed
		cam_zoom_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	cam_zoom_cooldown -= delta
	cam_zoom_cooldown = clamp(cam_zoom_cooldown, 0, TOGGLE_COOLDOWN)

func process_shoulder_swap(delta):
	if shoulder_isdown and shoulder_cooldown == 0 and !is_cam_transitioning and !cam_is_fp:
		shoulder_is_swapped = !shoulder_is_swapped
		shoulder_cooldown = TOGGLE_COOLDOWN
		cam_transition()
	
	shoulder_cooldown -= delta
	shoulder_cooldown = clamp(shoulder_cooldown, 0, TOGGLE_COOLDOWN)

func cam_transition():
	if is_cam_transitioning:
		return
	
	var fov
	var offset
	
	if cam_is_zoomed:
		if cam_is_fp:
			fov = FP_FOV * ZOOM_MULT
		else:
			fov = TP_FOV * ZOOM_MULT
	else:
		if cam_is_fp:
			fov = FP_FOV
		else:
			fov = TP_FOV
	
	if shoulder_is_swapped:
		offset = -TP_CAMERA_OFFSET
	else:
		offset = TP_CAMERA_OFFSET
	
	if cam_is_fp:
		cam_transitioning(FP_CAMERA_HEIGHT, 0.0, 0.0, fov, false)
	else:
		cam_transitioning(TP_CAMERA_HEIGHT, offset, TP_CAMERA_DISTANCE, fov, true)

func cam_transitioning(height, offset, length, fov, mesh_visible):
	is_cam_transitioning = true
	
	var time = Time.get_ticks_msec()
	var orig_height = camera_pivot.position.y
	var orig_offset = spring_arm.position.x
	var orig_length = spring_arm.spring_length
	var orig_fov = camera.fov
	
	if mesh_visible:
		if disable_shadow_in_first_person:
			player_mesh.visible = true
		else:
			player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	while is_cam_transitioning:
		var current_time = Time.get_ticks_msec()
		var lerp = (current_time - time)/(TRANSITION_SPEED * 1000.0)
		
		if lerp > 1:
			camera_pivot.position.y = height
			spring_arm.position.x = offset
			spring_arm.spring_length = length
			camera.fov = fov
			if !mesh_visible:
				if disable_shadow_in_first_person:
					player_mesh.visible = false
				else:
					player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			is_cam_transitioning = false
			break
		
		camera_pivot.position.y = lerp(orig_height, height, ease_in_out_sine(lerp))
		spring_arm.position.x = lerp(orig_offset, offset, ease_in_out_sine(lerp))
		# Adjusting spring_length is jittery. Likely only updates on physics process.
		spring_arm.spring_length = lerp(orig_length, length, lerp)
		# So if you're noticing jitter when switching cams, ^ this lerp is responsible.
		camera.fov = lerp(orig_fov, fov, ease_in_out_sine(lerp))
		
		await get_tree().process_frame

func process_dof(delta):
	if camera.attributes == null:
		return
	
	var near_distance = 0.5
	var near_transition = 0.25
	var far_distance = 50
	var far_transition = 50
	var blur_amount = 0.1
	
	if !cam_is_zoomed:
		camera.attributes.dof_blur_near_enabled = true
		near_distance = 0.5
		near_transition = 0.25
		camera.attributes.dof_blur_far_enabled = false
		far_distance = 50
		far_transition = 50
		blur_amount = 0.1
	else:
		var hit_distance = camera.global_position.distance_to(focus_ray.get_collision_point())
		camera.attributes.dof_blur_near_enabled = true
		near_distance = hit_distance - (hit_distance * DOF_AREA_SIZE_MULTIPLIER)
		near_transition = hit_distance * DOF_AREA_SOFTNESS
		camera.attributes.dof_blur_far_enabled = true
		far_distance =  hit_distance + (hit_distance * DOF_AREA_SIZE_MULTIPLIER)
		far_transition = hit_distance * DOF_AREA_SOFTNESS
		blur_amount = DOF_INTENSITY
	
	camera.attributes.dof_blur_near_distance = move_toward(camera.attributes.dof_blur_near_distance, near_distance, delta * DOF_MOVE_SPEED) 
	camera.attributes.dof_blur_near_transition = move_toward(camera.attributes.dof_blur_near_transition, near_transition, delta * DOF_MOVE_SPEED) 
	camera.attributes.dof_blur_far_distance =  move_toward(camera.attributes.dof_blur_far_distance, far_distance, delta * DOF_MOVE_SPEED)
	camera.attributes.dof_blur_far_transition = move_toward(camera.attributes.dof_blur_far_transition, far_transition, delta * DOF_MOVE_SPEED)
	camera.attributes.dof_blur_amount = move_toward(camera.attributes.dof_blur_amount, blur_amount, delta * (DOF_MOVE_SPEED/10))

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement -= event.relative
	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				zoom_isdown = event.pressed
	
	if event is InputEventKey:
		match event.keycode:
			KEY_W:
				forward_isdown = event.pressed
			KEY_S:
				backward_isdown = event.pressed
			KEY_A:
				left_isdown = event.pressed
			KEY_D:
				right_isdown = event.pressed
			KEY_V:
				cam_toggle_isdown = event.pressed
			KEY_F:
				noclip_isdown = event.pressed
			KEY_SHIFT:
				sprint_isdown = event.pressed
			KEY_SPACE:
				jump_isdown = event.pressed
			KEY_ESCAPE:
				mousecapture_isdown = event.pressed
			KEY_TAB:
				shoulder_isdown = event.pressed

func switch_anim(anim, speed = 1):
	if anim_player.current_animation != anim:
		anim_player.play(anim, -1, speed)

static func quat_rotate_toward(from: Quaternion, to: Quaternion, delta: float) -> Quaternion:
	return from.slerp(to, clamp(delta / from.angle_to(to), 0.0, 1.0)).normalized()

static func basis_rotate_toward(from: Basis, to: Basis, delta: float) -> Basis:
	return Basis(quat_rotate_toward(from.get_rotation_quaternion(), to.get_rotation_quaternion(), delta)).orthonormalized()

func ease_in_out_sine(lerp):
	return -(cos(PI * lerp) - 1) / 2;
