extends CharacterBody3D

var speed
const WALK_SPEED = 27.6
const SPRINT_SPEED = 31.2
const SLIDE_BOOST_MULTIPLIER = 1.5  # Multiplier for initial sliding speed
const SLIDE_SPEED = 20  # Base speed while sliding
const JUMP_VELOCITY = 6.8
const SENSITIVITY = 0.004
const GRAVITY = 10 # Custom gravity constant

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var capsule = $Capsule
@onready var collision_shape = $CollisionShape3D
@onready var animation = $Head/Camera3D/Lowpolyarms4/AnimationPlayer

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Crouching and Sliding Variables
var is_crouching = false
var is_sliding = false # Can we Wallrun
var can_wallrun = false
var wallrun_delay = 0.2

var stand_height = 1.75
var crouch_height = 1.0
var current_height = stand_height
var slide_duration = 2.0
const MAX_SLIDE_DURATION = 2.75
var slide_initial_speed = 0.0
var spawn_point = Vector3(100, 100, 30)  # Replace with the actual desired spawn point coordinates

func die():
	print("Player has died.")
	global_transform.origin = spawn_point  # Reset to the stored spawn point
	velocity = Vector3.ZERO  # Reset velocity to prevent carryover motion



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	# Add custom gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if global_transform.origin.y < 100:
		die()  # Call a function to handle player death

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

	# Handle Crouch and Slide
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Input.is_action_just_pressed("crouch"):
		if not is_crouching and direction.length() > 0:
			is_crouching = true
			current_height = crouch_height
			is_sliding = true
			slide_initial_speed = velocity.length()  # Capture the player's speed before sliding
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

	# Adjust Capsule and Collision Shape Height
	if is_crouching:
		capsule.scale.y = crouch_height / stand_height
		capsule.transform.origin.y = -stand_height * 0.5 + (crouch_height * 0.5)
		collision_shape.scale.y = crouch_height / stand_height
		collision_shape.transform.origin.y = -stand_height * 0.5 + (crouch_height * 0.5)
	else:
		capsule.scale.y = 1.0
		capsule.transform.origin.y = 0.0
		collision_shape.scale.y = 1.0
		collision_shape.transform.origin.y = 0.0

	# FOV Adjustment
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2.0)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Handle movement and deceleration
	if is_on_floor():
		if is_sliding:
			# Apply sliding speed with gradual deceleration
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 0.5)  # Gradual deceleration
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 0.5)  # Gradual deceleration
		else:
			if direction.length() > 0:
				animation.play("Run")
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = lerp(velocity.x, 0.0, delta * 10.0)  # More snappy deceleration
				velocity.z = lerp(velocity.z, 0.0, delta * 10.0)  # More snappy deceleration
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
