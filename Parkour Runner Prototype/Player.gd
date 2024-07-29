extends CharacterBody3D

var speed
const WALK_SPEED = 12.5
const SPRINT_SPEED = 30
const JUMP_VELOCITY = 9.5
const SENSITIVITY = 0.004

@onready var head = $Head
@onready var camera = $Head/Camera3D

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Crouching Variables
var is_crouching = false
var stand_height = 1.75
var crouch_height = 1.0
var current_height = stand_height

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	# Handle Sprint
	if Input.is_action_pressed("sprint") and not is_crouching:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Handle Crouch
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		current_height = crouch_height
	else:
		is_crouching = false
		current_height = stand_height

	# Adjust Camera Height
	camera.transform.origin.y = lerp(camera.transform.origin.y, current_height, delta * 10.0)

	# Get the input direction and handle the movement
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction.length() > 0:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Debug information
	print("Velocity:", velocity)
	print("Direction:", direction)
	print("Camera Position:", camera.transform.origin)

	# Move and slide
	move_and_slide()

