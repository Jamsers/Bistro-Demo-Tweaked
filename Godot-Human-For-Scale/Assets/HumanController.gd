extends CharacterBody3D

const FP_CAMERA_HEIGHT = 1.655
const FP_FOV = 75.0
const TP_CAMERA_HEIGHT = 1.544
const TP_FOV = 60.0
const TP_CAMERA_OFFSET = 0.5
const TP_CAMERA_DISTANCE = 2.1
const LOOK_SENSITIVITY = 0.0025
const LOOK_LIMIT_UPPER = 1.15
const LOOK_LIMIT_LOWER = -1.15
const ANIM_MOVE_SPEED = 3
const ANIM_RUN_SPEED = 5.5
const MOVE_MULT = 1.4
const RUN_MULT = 1.25
const NOCLIP_MULT = 4
const ROTATE_SPEED = 12.0
const JUMP_FORCE = 15.0
const GRAVITY_FORCE = 50.0
const COLLIDE_FORCE = 0.05
const DIRECTIONAL_FORCE_DIV = 30.0
const TOGGLE_COOLDOWN = 0.5

var move_direction = Vector3.ZERO
var move_direction_no_y = Vector3.ZERO
var camera_rotation = Quaternion.IDENTITY
var camera_rotation_no_y = Quaternion.IDENTITY
var noclip_on = false
var noclip_toggle_cooldown = 0.0
var cam_is_fp = false
var cam_toggle_cooldown = 0.0
var mousecapture_on = true
var mousecapture_toggle_cooldown = 0.0
var rigidbody_collisions = []
var input_velocity = Vector3.ZERO

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

@onready var camera_pivot = $"CameraPivot"
@onready var spring_arm = $"CameraPivot/SpringArm"
@onready var camera = $"CameraPivot/SpringArm/Camera"
@onready var player_mesh = $"ModelRoot/mannequiny-0_3_0/root/Skeleton3D/mannequiny"
@onready var anim_player = $"ModelRoot/mannequiny-0_3_0/AnimationPlayer"

func _ready():
	basis = Basis.IDENTITY
	anim_player.playback_default_blend_time = 0.2

func _process(delta):
	process_mousecapture(delta)
	process_camera()
	process_movement()
	process_animation(delta)
	process_noclip(delta)
	process_cam_toggle(delta)
	
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
	if cam_toggle_isdown and cam_toggle_cooldown == 0:
		cam_is_fp = !cam_is_fp
		cam_toggle_cooldown = TOGGLE_COOLDOWN
		
		if cam_is_fp:
			camera_pivot.position.y = FP_CAMERA_HEIGHT
			spring_arm.position.x = 0.0
			spring_arm.spring_length = 0.0
			camera.fov = FP_FOV
			player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		else:
			camera_pivot.position.y = TP_CAMERA_HEIGHT
			spring_arm.position.x = TP_CAMERA_OFFSET
			spring_arm.spring_length = TP_CAMERA_DISTANCE
			camera.fov = TP_FOV
			player_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	cam_toggle_cooldown -= delta
	cam_toggle_cooldown = clamp(cam_toggle_cooldown, 0, TOGGLE_COOLDOWN)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		mouse_movement -= event.relative
	
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

func switch_anim(anim, speed = 1):
	if anim_player.current_animation != anim:
		anim_player.play(anim, -1, speed)

static func quat_rotate_toward(from: Quaternion, to: Quaternion, delta: float) -> Quaternion:
	return from.slerp(to, clamp(delta / from.angle_to(to), 0.0, 1.0)).normalized()

static func basis_rotate_toward(from: Basis, to: Basis, delta: float) -> Basis:
	return Basis(quat_rotate_toward(from.get_rotation_quaternion(), to.get_rotation_quaternion(), delta)).orthonormalized()
