# TODO: add targets

extends CharacterBody3D

const NORMAL_SPEED = 8.0
const SPRINT_SPEED = 14.0
const JUMP_VELOCITY = 6
@export var coin_scene: PackedScene   # Assign Coin.tscn in the inspector
@export var shoot_force: float = 50.0
@export var spin_strength: float = 6.0

# Rapid fire settings
@export var rapid_fire_rate: float = 0.04  # seconds between shots
@onready var GameState = get_node("/root/GameState")
var _rapid_fire_timer: Timer


@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var pipe := $Neck/Camera3D/Pipe   # Make sure this Node3D exists

func _ready():
	# create a Timer for rapid fire so we don't rely on editor nodes
	_rapid_fire_timer = Timer.new()
	_rapid_fire_timer.wait_time = rapid_fire_rate
	_rapid_fire_timer.one_shot = false
	add_child(_rapid_fire_timer)
	_rapid_fire_timer.timeout.connect(_on_rapid_fire_timeout)

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

	# Right click to start/stop rapid fire (only if unlocked)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			if GameState.rapid_fire_unlocked:
				# start immediate shot and then the repeating timer
				shoot_coin()
				_rapid_fire_timer.start()
		else:
			_rapid_fire_timer.stop()

func _on_rapid_fire_timeout():
	# Only fire while unlocked
	if GameState.rapid_fire_unlocked:
		shoot_coin()
	else:
		_rapid_fire_timer.stop()

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

	# Spawn a bit in front of the pipe so it doesn't overlap the player.
	var spawn_distance := 1.0  # tweak as needed (units)
	var forward: Vector3 = -pipe.global_transform.basis.z.normalized()
	var spawn_transform: Transform3D = pipe.global_transform
	spawn_transform.origin += forward * spawn_distance
	coin.global_transform = spawn_transform

	# Add to scene root (or current_scene) after transform is set
	get_tree().current_scene.add_child(coin)

	# Give the coin initial linear velocity away from the player
	if coin.has_method("set_linear_velocity"):
		coin.set_linear_velocity(forward * shoot_force)
	elif "linear_velocity" in coin:
		coin.linear_velocity = forward * shoot_force

	# Optional: set spin/ang velocity if your coin supports it
	if "angular_velocity" in coin:
		coin.angular_velocity = Vector3(randf(), randf(), randf()) * spin_strength

	# Prevent immediate collision with the player: temporarily clear collision mask
	# NOTE: change PLAYER_LAYER_BIT if your player uses a different layer (0-based bit index)
	var PLAYER_LAYER_BIT := 0  # usually layer 1 => bit 0
	if "collision_mask" in coin and "collision_mask" in self:
		var orig_mask: int = coin.collision_mask
		coin.collision_mask = coin.collision_mask & ~(1 << PLAYER_LAYER_BIT)
		# restore after short delay so coin collides with world/targets normally
		# use a short timer so the coin can't push the player before moving away
		call_deferred("_restore_coin_mask", coin, orig_mask, 0.08)

# helper deferred restore (keeps shoot_coin tidy)
func _restore_coin_mask(coin, orig_mask, delay):
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(coin):
		coin.collision_mask = orig_mask
