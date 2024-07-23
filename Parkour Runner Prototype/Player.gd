extends CharacterBody3D

const WALK_SPEED = 12.5
const SPRINT_SPEED = 30
const JUMP_VELOCITY = 9.5
const SENSITIVITY = 0.004

# Head Bob Variables
const BOB_FREQ = 1
const BOB_AMP = 0.08
var t_bob = 0.0

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = 9.8

var direction = Vector3()
var h_velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()
var speed = 4
var current_speed = 0
var snap_vector = Vector3.ZERO

# Floor Sliding Variables
var fall_distance = 0
var slide_speed = 0
var can_slide = false
var sliding = false
var falling = false

@onready var slide_check = $Slide_Check

@onready var head = $Head
@onready var camera = $Head/Camera3D


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))


func _physics_process(delta):
	if falling and is_on_floor() and sliding:
		slide_speed += fall_distance / 10
	fall_distance = -gravity_vec.y
	
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle Sprint.
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration
	var input_dir = Input.get_vector("left", "right", "forwards", "backwards")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
	
	if Input.is_action_pressed("slide") and current_speed > 3:
		can_slide = true
		
	if Input.is_action_just_pressed("slide") and is_on_floor() and Input.is_action_pressed("forward") and can_slide:
		slide()
	
	if Input.is_action_just_released("slide"):
		can_slide = false
		sliding = false
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func slide():
	if not sliding:
		if slide_check.is_colliding() or get_floor_angle() < 0.2:
			slide_speed = 5
			slide_speed += fall_distance / 10
		else:
			slide_speed = 2
	sliding = true
	
	if slide_check.is_colliding():
		slide_speed += get_floor_angle() / 10
	else:
		slide_speed -= (get_floor_angle() / 5) + 0.03
		
	if slide_speed < 0:
		slide_speed = 0
		can_slide = false
		sliding = false
		
	speed = slide_speed
