extends CharacterBody3D

const NORMAL_SPEED = 8.0
const SPRINT_SPEED = 14.0
const JUMP_VELOCITY = 6
@export var coin_scene: PackedScene   # Assign Coin.tscn in the inspector
@export var shoot_force: float = 10.0
@export var spin_strength: float = 6.0

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
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

	# Left click to shoot
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot_coin()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump: allow holding the jump key so the player will jump again on landing while the key is held
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement (WASD)
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	# Only normalize when there's input to avoid producing NaNs/zero-ops
	if direction.length() > 0.001:
		direction = direction.normalized()
	else:
		direction = Vector3.ZERO

	# Use an input action for sprinting (configure "sprint" in Project Settings -> Input Map)
	var is_sprinting = Input.is_action_pressed("sprint")
	var real_speed = SPRINT_SPEED if is_sprinting else NORMAL_SPEED

	# Smooth acceleration / deceleration instead of snapping. Use a higher accel on ground.
	var accel = 50.0 if is_on_floor() else 20.0

	var target = direction * real_speed

	# Smooth the horizontal velocity as a vector to avoid axis-wise artifacts
	var horizontal = Vector3(velocity.x, 0, velocity.z)
	horizontal = horizontal.move_toward(target, accel * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

func shoot_coin():
	if not coin_scene:
		return

	var coin = coin_scene.instantiate()
	# Add to the scene first, then set transform/velocity deferred so the physics server sees a clean spawn
	get_tree().current_scene.add_child(coin)

	# Compute forward direction from the pipe
	var direction = -pipe.global_transform.basis.z.normalized()

	# Spawn a bit further out and slightly above the pipe to avoid initial overlaps with geometry or the player
	var spawn_pos = pipe.global_position + (direction * 1.0) + Vector3(0, 0.45, 0)

	# Use deferred sets so the engine applies them safely in the next idle/physics step.
	# This avoids lost impulses or spawning already intersecting other colliders which can cause noclip/tunneling.
	coin.set_deferred("global_position", spawn_pos)
	coin.set_deferred("linear_velocity", direction * shoot_force)
	coin.set_deferred("sleeping", false)

	# Give the coin a random angular velocity so it spins when shot
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var rand_dir = Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
	if rand_dir.length() < 0.001:
		rand_dir = Vector3(0, 1, 0)
	else:
		rand_dir = rand_dir.normalized()
	var spin_speed = rng.randf_range(0.4, 1.0) * spin_strength
	coin.set_deferred("angular_velocity", rand_dir * spin_speed)
