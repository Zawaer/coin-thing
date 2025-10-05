extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var coin_scene: PackedScene   # Assign Coin.tscn in the inspector
@export var shoot_force: float = 10.0

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var pipe := $Neck/Camera3D/Pipe   # Make sure this Node3D exists

func _unhandled_input(event):
	if event is InputEventMouseButton:
		# Capture or release mouse
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Mouse look
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.01)
			camera.rotate_x(-event.relative.y * 0.01)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

	# Left click to shoot
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot_coin()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement (WASD)
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func shoot_coin():
	if not coin_scene:
		return

	var coin = coin_scene.instantiate()
	get_tree().current_scene.add_child(coin)

	# Spawn in front of the pipe
	var spawn_pos = pipe.global_position + (-pipe.global_transform.basis.z.normalized() * 0.5)
	coin.global_position = spawn_pos

	# Apply impulse forward
	var direction = -pipe.global_transform.basis.z.normalized()
	coin.apply_central_impulse(direction * shoot_force)
