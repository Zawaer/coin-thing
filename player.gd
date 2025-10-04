extends CharacterBody3D

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
var rotation_x = 0.0
var rotation_y = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # hide and capture cursor

func _physics_process(delta):
	# Movement
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir -= transform.basis.z
	if Input.is_action_pressed("move_back"):
		input_dir += transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_dir -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_dir += transform.basis.x
	
	input_dir = input_dir.normalized()
	velocity.x = input_dir.x * speed
	velocity.z = input_dir.z * speed
	
	# Gravity
	#velocity.y += ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	move_and_slide()

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion:
		rotation_y -= event.relative.x * mouse_sensitivity
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sensitivity, -1.5, 1.5)
		rotation_degrees.y = rotation_y * 57.2958  # convert radians to degrees
		$Camera3D.rotation.x = rotation_x
