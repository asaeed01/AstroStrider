extends CharacterBody3D

var speed
const WALK_SPEED = 12.5
const SPRINT_SPEED = 30
const SLIDE_BOOST_MULTIPLIER = 1.5  # Multiplier for initial sliding speed
const SLIDE_SPEED = 20  # Base speed while sliding
const JUMP_VELOCITY = 9.5
const SENSITIVITY = 0.004

@onready var head = $Head
@onready var camera = $Head/Camera3D

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Crouching and Sliding Variables
var is_crouching = false
var is_sliding = false
var stand_height = 1.75
var crouch_height = 1.0
var current_height = stand_height
var slide_duration = 0.0
const MAX_SLIDE_DURATION = 2.75
var slide_initial_speed = 0.0

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
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		if is_sliding:
			is_sliding = false

	# Handle Sprint
	if Input.is_action_pressed("sprint") and not is_crouching:
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Get the input direction and handle the movement
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Handle Crouch and Slide
	if Input.is_action_just_pressed("crouch"):
		if not is_crouching and direction.length() > 0:
			is_crouching = true
			current_height = crouch_height
			is_sliding = true
			slide_initial_speed = direction.length()  # Capture the player's speed before sliding
			slide_duration = min(slide_initial_speed / SPRINT_SPEED * MAX_SLIDE_DURATION, MAX_SLIDE_DURATION)
		else:
			is_crouching = true
			current_height = crouch_height
	elif Input.is_action_just_released("crouch"):
		is_crouching = false
		current_height = stand_height

	# Sliding logic
	if is_sliding:
		slide_duration -= delta
		if slide_duration <= 0:
			is_sliding = false
		speed = slide_initial_speed * SLIDE_BOOST_MULTIPLIER  # Apply initial sliding speed boost

	# Adjust Camera Height
	camera.transform.origin.y = lerp(camera.transform.origin.y, current_height, delta * 10.0)

	# Handle movement and deceleration
	if is_on_floor():
		if is_sliding:
			# Apply sliding speed with gradual deceleration
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)  # Gradual deceleration
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)  # Gradual deceleration
		else:
			if direction.length() > 0:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = lerp(velocity.x, 0.0, delta * 3.0)  # More gradual deceleration
				velocity.z = lerp(velocity.z, 0.0, delta * 3.0)  # More gradual deceleration
	else:
		# Air control
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)  # More gradual deceleration
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)  # More gradual deceleration

	# Debug information
	print("Velocity:", velocity)
	print("Direction:", direction)
	print("Camera Position:", camera.transform.origin)

	# Move and slide
	move_and_slide()
